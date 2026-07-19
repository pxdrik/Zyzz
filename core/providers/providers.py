from __future__ import annotations

import os
from abc import ABC, abstractmethod
from collections.abc import Generator

import anthropic
from google import genai
import openai

from core.router.models import Provider


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

    def generate(self, prompt: str) -> str:
        """Send the prompt to Claude Sonnet and return the response."""
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            return "Claude API key not configured."
        try:
            client = anthropic.Anthropic(api_key=api_key)
            message = client.messages.create(
                model="claude-sonnet-4-6",
                max_tokens=1024,
                messages=[{"role": "user", "content": prompt}],
            )
            return message.content[0].text
        except Exception as e:
            return f"Claude API error: {e}"

    def stream(self, prompt: str) -> Generator[str, None, None]:
        """Stream the response from Claude Sonnet, yielding text chunks."""
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            yield "Claude API key not configured."
            return
        try:
            client = anthropic.Anthropic(api_key=api_key)
            with client.messages.stream(
                model="claude-sonnet-4-6",
                max_tokens=1024,
                messages=[{"role": "user", "content": prompt}],
            ) as s:
                for text in s.text_stream:
                    yield text
        except Exception as e:
            yield f"Claude API error: {e}"


class ChatGPTProvider(BaseProvider):
    """ChatGPT provider backed by the OpenAI API."""

    def generate(self, prompt: str) -> str:
        """Send the prompt to GPT-4o-mini and return the response."""
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            return "ChatGPT API key not configured."
        try:
            client = openai.OpenAI(api_key=api_key)
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=1024,
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"ChatGPT API error: {e}"

    def stream(self, prompt: str) -> Generator[str, None, None]:
        """Stream the response from GPT-4o-mini, yielding text chunks."""
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            yield "ChatGPT API key not configured."
            return
        try:
            client = openai.OpenAI(api_key=api_key)
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=1024,
                stream=True,
            )
            for chunk in response:
                content = chunk.choices[0].delta.content
                if content is not None:
                    yield content
        except Exception as e:
            yield f"ChatGPT API error: {e}"


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
        except Exception as e:
            return f"Gemini API error: {e}"

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
        except Exception as e:
            yield f"Gemini API error: {e}"


_PROVIDERS: dict[Provider, BaseProvider] = {
    Provider.CLAUDE: ClaudeProvider(),
    Provider.CHATGPT: ChatGPTProvider(),
    Provider.GEMINI: GeminiProvider(),
}


def get_provider(provider: Provider) -> BaseProvider:
    """Return the provider instance for the given Provider enum value."""
    return _PROVIDERS[provider]
