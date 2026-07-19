from __future__ import annotations

import json
import os
from abc import ABC, abstractmethod
from collections.abc import Generator

import anthropic
from google import genai
import openai

from core.router.models import Provider
from core.tools.builtin import build_registry
from core.tools.registry import ToolRegistry


class BaseProvider(ABC):
    """Common interface for all AI providers."""

    @abstractmethod
    def generate(self, prompt: str) -> str:
        """Generate a complete response for the given prompt."""

    @abstractmethod
    def stream(self, prompt: str) -> Generator[str, None, None]:
        """Stream the response for the given prompt, yielding text chunks."""


class ClaudeProvider(BaseProvider):
    """Claude provider backed by the Anthropic API."""

    def __init__(self, registry: ToolRegistry | None = None) -> None:
        self._registry = registry

    def generate(self, prompt: str) -> str:
        """Send the prompt to Claude Sonnet and return the response, invoking tools if needed."""
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            return "Claude API key not configured."
        try:
            client = anthropic.Anthropic(api_key=api_key)
            messages: list[dict] = [{"role": "user", "content": prompt}]

            if self._registry and not self._registry.is_empty():
                tools = self._claude_tool_defs()
                while True:
                    response = client.messages.create(
                        model="claude-sonnet-4-6", max_tokens=4096, tools=tools, messages=messages
                    )
                    if response.stop_reason == "tool_use":
                        messages = self._apply_claude_tool_calls(messages, response)
                    else:
                        return "".join(b.text for b in response.content if hasattr(b, "text"))
            else:
                response = client.messages.create(
                    model="claude-sonnet-4-6",
                    max_tokens=1024,
                    messages=messages,
                )
                return response.content[0].text
        except Exception as exc:
            return f"Claude API error: {exc}"

    def stream(self, prompt: str) -> Generator[str, None, None]:
        """Stream the response from Claude Sonnet, invoking tools if needed."""
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            yield "Claude API key not configured."
            return
        try:
            client = anthropic.Anthropic(api_key=api_key)
            messages: list[dict] = [{"role": "user", "content": prompt}]

            if self._registry and not self._registry.is_empty():
                tools = self._claude_tool_defs()
                while True:
                    response = client.messages.create(
                        model="claude-sonnet-4-6", max_tokens=4096, tools=tools, messages=messages
                    )
                    if response.stop_reason == "tool_use":
                        messages = self._apply_claude_tool_calls(messages, response)
                    else:
                        for block in response.content:
                            if hasattr(block, "text"):
                                yield block.text
                        return
            else:
                with client.messages.stream(
                    model="claude-sonnet-4-6",
                    max_tokens=1024,
                    messages=messages,
                ) as s:
                    for text in s.text_stream:
                        yield text
        except Exception as exc:
            yield f"Claude API error: {exc}"

    def _claude_tool_defs(self) -> list[dict]:
        assert self._registry is not None
        return [
            {"name": s.name, "description": s.description, "input_schema": s.parameters}
            for s in self._registry.specs()
        ]

    def _apply_claude_tool_calls(self, messages: list[dict], response: object) -> list[dict]:
        """Execute tool calls from a Claude response and append results to the message list."""
        assert self._registry is not None
        tool_results = []
        for block in response.content:  # type: ignore[attr-defined]
            if block.type == "tool_use":
                result = self._registry.execute(block.name, dict(block.input))
                tool_results.append(
                    {"type": "tool_result", "tool_use_id": block.id, "content": result.output}
                )
        return [
            *messages,
            {"role": "assistant", "content": response.content},  # type: ignore[attr-defined]
            {"role": "user", "content": tool_results},
        ]


class ChatGPTProvider(BaseProvider):
    """ChatGPT provider backed by the OpenAI API."""

    def __init__(self, registry: ToolRegistry | None = None) -> None:
        self._registry = registry

    def generate(self, prompt: str) -> str:
        """Send the prompt to GPT-4o-mini and return the response, invoking tools if needed."""
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            return "ChatGPT API key not configured."
        try:
            client = openai.OpenAI(api_key=api_key)
            messages: list[dict] = [{"role": "user", "content": prompt}]

            if self._registry and not self._registry.is_empty():
                tools = self._openai_tool_defs()
                while True:
                    response = client.chat.completions.create(
                        model="gpt-4o-mini", messages=messages, tools=tools, max_tokens=4096
                    )
                    choice = response.choices[0]
                    if choice.finish_reason == "tool_calls":
                        messages = self._apply_openai_tool_calls(messages, choice)
                    else:
                        return choice.message.content or ""
            else:
                response = client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=messages,
                    max_tokens=1024,
                )
                return response.choices[0].message.content or ""
        except Exception as exc:
            return f"ChatGPT API error: {exc}"

    def stream(self, prompt: str) -> Generator[str, None, None]:
        """Stream the response from GPT-4o-mini, invoking tools if needed."""
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            yield "ChatGPT API key not configured."
            return
        try:
            client = openai.OpenAI(api_key=api_key)
            messages: list[dict] = [{"role": "user", "content": prompt}]

            if self._registry and not self._registry.is_empty():
                tools = self._openai_tool_defs()
                while True:
                    response = client.chat.completions.create(
                        model="gpt-4o-mini", messages=messages, tools=tools, max_tokens=4096
                    )
                    choice = response.choices[0]
                    if choice.finish_reason == "tool_calls":
                        messages = self._apply_openai_tool_calls(messages, choice)
                    else:
                        yield choice.message.content or ""
                        return
            else:
                response = client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=messages,
                    max_tokens=1024,
                    stream=True,
                )
                for chunk in response:
                    content = chunk.choices[0].delta.content
                    if content is not None:
                        yield content
        except Exception as exc:
            yield f"ChatGPT API error: {exc}"

    def _openai_tool_defs(self) -> list[dict]:
        assert self._registry is not None
        return [
            {"type": "function", "function": {"name": s.name, "description": s.description, "parameters": s.parameters}}
            for s in self._registry.specs()
        ]

    def _apply_openai_tool_calls(self, messages: list[dict], choice: object) -> list[dict]:
        """Execute tool calls from an OpenAI response and append results to the message list."""
        assert self._registry is not None
        messages = [*messages, choice.message]  # type: ignore[attr-defined]
        for tc in choice.message.tool_calls:  # type: ignore[attr-defined]
            params = json.loads(tc.function.arguments)
            result = self._registry.execute(tc.function.name, params)
            messages.append({"role": "tool", "tool_call_id": tc.id, "content": result.output})
        return messages


class GeminiProvider(BaseProvider):
    """Gemini provider backed by the Google Generative AI SDK."""

    def generate(self, prompt: str) -> str:
        """Send the prompt to Gemini 2.0 Flash and return the response."""
        api_key = os.environ.get("GOOGLE_API_KEY")
        if not api_key:
            return "Gemini API key not configured."
        try:
            client = genai.Client(api_key=api_key)
            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=prompt,
            )
            return response.text
        except Exception as exc:
            return f"Gemini API error: {exc}"

    def stream(self, prompt: str) -> Generator[str, None, None]:
        """Stream the response from Gemini 2.0 Flash, yielding text chunks."""
        api_key = os.environ.get("GOOGLE_API_KEY")
        if not api_key:
            yield "Gemini API key not configured."
            return
        try:
            client = genai.Client(api_key=api_key)
            for chunk in client.models.generate_content_stream(
                model="gemini-2.0-flash",
                contents=prompt,
            ):
                if chunk.text:
                    yield chunk.text
        except Exception as exc:
            yield f"Gemini API error: {exc}"


_registry = build_registry()

_PROVIDERS: dict[Provider, BaseProvider] = {
    Provider.CLAUDE: ClaudeProvider(registry=_registry),
    Provider.CHATGPT: ChatGPTProvider(registry=_registry),
    Provider.GEMINI: GeminiProvider(),
}


def get_provider(provider: Provider) -> BaseProvider:
    """Return the provider instance for the given Provider enum value."""
    return _PROVIDERS[provider]
