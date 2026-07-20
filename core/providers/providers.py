from __future__ import annotations

import json
import os
import sys
from abc import ABC, abstractmethod
from collections.abc import Generator

import anthropic
from google import genai
import openai

from core.router.models import Provider
from core.tools.builtin import build_registry
from core.tools.registry import ToolRegistry

_SYSTEM_PROMPT = (
    "Você é o ZYZZ, assistente pessoal de IA do usuário. "
    "Seu papel é de Chief of Staff pessoal — ajudar o usuário a pensar, planejar, organizar e executar tarefas.\n\n"
    "Você tem acesso a ferramentas externas como Google Agenda, calculadora, leitura de arquivos, "
    "execução de comandos e envio de e-mails.\n\n"
    "Diretrizes:\n"
    "- Responda sempre em português do Brasil, a menos que o usuário peça outro idioma.\n"
    "- Seja direto, objetivo e útil. Evite respostas genéricas ou excessivamente longas.\n"
    "- Use as ferramentas disponíveis quando necessário para dar respostas precisas e atualizadas.\n"
    "- Mantenha o contexto da conversa e lembre-se do que o usuário compartilhou anteriormente."
)


class BaseProvider(ABC):
    """Common interface for all AI providers."""

    @abstractmethod
    def generate(self, messages: list[dict]) -> str:
        """Generate a complete response for the given message history."""

    @abstractmethod
    def stream(self, messages: list[dict]) -> Generator[str, None, None]:
        """Stream the response for the given message history, yielding text chunks."""


class ClaudeProvider(BaseProvider):
    """Claude provider backed by the Anthropic API."""

    def __init__(self, registry: ToolRegistry | None = None) -> None:
        self._registry = registry
        self._client: anthropic.Anthropic | None = None

    def _get_client(self) -> anthropic.Anthropic | None:
        """Return a cached Anthropic client, or None if no API key is set."""
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            return None
        if self._client is None:
            self._client = anthropic.Anthropic(api_key=api_key)
        return self._client

    def generate(self, messages: list[dict]) -> str:
        """Send the messages to Claude Sonnet and return the response, invoking tools if needed."""
        client = self._get_client()
        if not client:
            return "Claude API key not configured."
        try:

            if self._registry and not self._registry.is_empty():
                tools = self._claude_tool_defs()
                while True:
                    response = client.messages.create(
                        model="claude-sonnet-4-6",
                        max_tokens=4096,
                        system=_SYSTEM_PROMPT,
                        tools=tools,
                        messages=messages,
                    )
                    if response.stop_reason == "tool_use":
                        messages = self._apply_claude_tool_calls(messages, response)
                    else:
                        return "".join(b.text for b in response.content if hasattr(b, "text"))
            else:
                response = client.messages.create(
                    model="claude-sonnet-4-6",
                    max_tokens=1024,
                    system=_SYSTEM_PROMPT,
                    messages=messages,
                )
                return response.content[0].text
        except Exception as exc:
            return f"Claude API error: {exc}"

    def stream(self, messages: list[dict]) -> Generator[str, None, None]:
        """Stream the response from Claude Sonnet token by token, invoking tools if needed.

        Uses the Anthropic streaming API for the initial request. If the model invokes
        tools, executes them and issues a second streaming request for the final answer.
        """
        client = self._get_client()
        if not client:
            yield "Claude API key not configured."
            return
        try:
            tools = self._claude_tool_defs() if self._registry and not self._registry.is_empty() else []

            while True:
                kwargs: dict = {
                    "model": "claude-sonnet-4-6",
                    "max_tokens": 4096,
                    "system": _SYSTEM_PROMPT,
                    "messages": messages,
                }
                if tools:
                    kwargs["tools"] = tools

                with client.messages.stream(**kwargs) as s:
                    for text in s.text_stream:
                        yield text
                    final = s.get_final_message()

                if final.stop_reason == "tool_use" and tools:
                    messages = self._apply_claude_tool_calls(messages, final)
                else:
                    return
        except Exception as exc:
            yield f"Claude API error: {exc}"

    def _claude_tool_defs(self) -> list[dict]:
        if self._registry is None:
            raise RuntimeError("Tool definitions requested but no registry is configured.")
        return [
            {"name": s.name, "description": s.description, "input_schema": s.parameters}
            for s in self._registry.specs()
        ]

    def _apply_claude_tool_calls(self, messages: list[dict], response: object) -> list[dict]:
        """Execute tool calls from a Claude response and append results to the message list."""
        if self._registry is None:
            raise RuntimeError("Tool execution requested but no registry is configured.")
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
        self._client: openai.OpenAI | None = None

    def _get_client(self) -> openai.OpenAI | None:
        """Return a cached OpenAI client, or None if no API key is set."""
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            return None
        if self._client is None:
            self._client = openai.OpenAI(api_key=api_key)
        return self._client

    def generate(self, messages: list[dict]) -> str:
        """Send the messages to GPT-4o-mini and return the response, invoking tools if needed."""
        client = self._get_client()
        if not client:
            return "ChatGPT API key not configured."
        try:
            messages = [{"role": "system", "content": _SYSTEM_PROMPT}, *messages]

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

    def stream(self, messages: list[dict]) -> Generator[str, None, None]:
        """Stream the response from GPT-4o-mini token by token, invoking tools if needed.

        Accumulates tool call deltas during streaming. If tool calls are detected,
        executes them and issues a second streaming request for the final answer.
        """
        client = self._get_client()
        if not client:
            yield "ChatGPT API key not configured."
            return
        try:
            messages = [{"role": "system", "content": _SYSTEM_PROMPT}, *messages]
            tools = self._openai_tool_defs() if self._registry and not self._registry.is_empty() else []

            while True:
                kwargs: dict = {
                    "model": "gpt-4o-mini",
                    "messages": messages,
                    "max_tokens": 4096,
                    "stream": True,
                }
                if tools:
                    kwargs["tools"] = tools

                response = client.chat.completions.create(**kwargs)

                finish_reason: str | None = None
                text_chunks: list[str] = []
                tool_calls_raw: dict[int, dict] = {}

                for chunk in response:
                    choice = chunk.choices[0]
                    finish_reason = choice.finish_reason or finish_reason
                    delta = choice.delta

                    if delta.content:
                        text_chunks.append(delta.content)
                        yield delta.content

                    if delta.tool_calls:
                        for tc in delta.tool_calls:
                            idx = tc.index
                            if idx not in tool_calls_raw:
                                tool_calls_raw[idx] = {
                                    "id": tc.id or "",
                                    "type": "function",
                                    "function": {"name": tc.function.name or "", "arguments": ""},
                                }
                            if tc.id:
                                tool_calls_raw[idx]["id"] = tc.id
                            if tc.function.name:
                                tool_calls_raw[idx]["function"]["name"] = tc.function.name
                            if tc.function.arguments:
                                tool_calls_raw[idx]["function"]["arguments"] += tc.function.arguments

                if finish_reason == "tool_calls" and tools and tool_calls_raw:
                    ordered_calls = [tool_calls_raw[i] for i in sorted(tool_calls_raw.keys())]
                    messages = [
                        *messages,
                        {
                            "role": "assistant",
                            "content": "".join(text_chunks) or None,
                            "tool_calls": ordered_calls,
                        },
                    ]
                    for tc in ordered_calls:
                        params = json.loads(tc["function"]["arguments"])
                        result = self._registry.execute(tc["function"]["name"], params)  # type: ignore[union-attr]
                        messages.append({
                            "role": "tool",
                            "tool_call_id": tc["id"],
                            "content": result.output,
                        })
                else:
                    return
        except Exception as exc:
            yield f"ChatGPT API error: {exc}"

    def _openai_tool_defs(self) -> list[dict]:
        if self._registry is None:
            raise RuntimeError("Tool definitions requested but no registry is configured.")
        return [
            {
                "type": "function",
                "function": {
                    "name": s.name,
                    "description": s.description,
                    "parameters": s.parameters,
                },
            }
            for s in self._registry.specs()
        ]

    def _apply_openai_tool_calls(self, messages: list[dict], choice: object) -> list[dict]:
        """Execute tool calls from an OpenAI response and append results to the message list."""
        if self._registry is None:
            raise RuntimeError("Tool execution requested but no registry is configured.")
        messages = [*messages, choice.message]  # type: ignore[attr-defined]
        for tc in choice.message.tool_calls:  # type: ignore[attr-defined]
            params = json.loads(tc.function.arguments)
            result = self._registry.execute(tc.function.name, params)
            messages.append({"role": "tool", "tool_call_id": tc.id, "content": result.output})
        return messages


class GeminiProvider(BaseProvider):
    """Gemini provider backed by the Google Generative AI SDK.

    Note: Gemini uses only the last user message as the prompt. Full conversation
    history is not yet supported in this implementation.
    """

    def __init__(self) -> None:
        self._client: genai.Client | None = None

    def _get_client(self) -> genai.Client | None:
        """Return a cached Gemini client, or None if no API key is set."""
        api_key = os.environ.get("GOOGLE_API_KEY")
        if not api_key:
            return None
        if self._client is None:
            self._client = genai.Client(api_key=api_key)
        return self._client

    def generate(self, messages: list[dict]) -> str:
        """Send the last user message to Gemini 2.0 Flash and return the response."""
        client = self._get_client()
        if not client:
            return "Gemini API key not configured."
        prompt = messages[-1]["content"] if messages else ""
        try:
            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=prompt,
                config=genai.types.GenerateContentConfig(system_instruction=_SYSTEM_PROMPT),
            )
            return response.text
        except Exception as exc:
            return f"Gemini API error: {exc}"

    def stream(self, messages: list[dict]) -> Generator[str, None, None]:
        """Stream the response from Gemini 2.0 Flash, yielding text chunks."""
        client = self._get_client()
        if not client:
            yield "Gemini API key not configured."
            return
        prompt = messages[-1]["content"] if messages else ""
        try:
            for chunk in client.models.generate_content_stream(
                model="gemini-2.0-flash",
                contents=prompt,
                config=genai.types.GenerateContentConfig(system_instruction=_SYSTEM_PROMPT),
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
