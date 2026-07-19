from __future__ import annotations

import os
from abc import ABC, abstractmethod

import anthropic
import openai

from core.router.models import Provider


class BaseProvider(ABC):
    """Common interface for all AI providers."""

    @abstractmethod
    def generate(self, prompt: str) -> str:
        """Generate a response for the given prompt."""


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


class GeminiProvider(BaseProvider):
    """Mocked Gemini provider."""

    def generate(self, prompt: str) -> str:
        return f"[Gemini] Response to: {prompt}"


_PROVIDERS: dict[Provider, BaseProvider] = {
    Provider.CLAUDE: ClaudeProvider(),
    Provider.CHATGPT: ChatGPTProvider(),
    Provider.GEMINI: GeminiProvider(),
}


def get_provider(provider: Provider) -> BaseProvider:
    """Return the provider instance for the given Provider enum value."""
    return _PROVIDERS[provider]
