from __future__ import annotations

from abc import ABC, abstractmethod

from core.router.models import Provider


class BaseProvider(ABC):
    """Common interface for all AI providers."""

    @abstractmethod
    def generate(self, prompt: str) -> str:
        """Generate a response for the given prompt."""


class ClaudeProvider(BaseProvider):
    """Mocked Claude provider."""

    def generate(self, prompt: str) -> str:
        return f"[Claude] Response to: {prompt}"


class ChatGPTProvider(BaseProvider):
    """Mocked ChatGPT provider."""

    def generate(self, prompt: str) -> str:
        return f"[ChatGPT] Response to: {prompt}"


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
