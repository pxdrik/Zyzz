from __future__ import annotations

from core.chat.models import ChatResponse
from core.router.service import RouterService


class ChatEngine:
    """Processes a user message and produces an assistant response.

    Delegates routing to RouterService and formats the RouteDecision
    into a human-readable ChatResponse. This is the single entry point
    for the message flow between the UI and core business logic.
    """

    def __init__(self) -> None:
        self._router = RouterService()

    def process(self, prompt: str) -> ChatResponse:
        """Route the prompt and return a formatted assistant response."""
        decision = self._router.route(prompt)
        text = (
            f"Provider selected:\n{decision.provider.value}"
            f"\n\nReason:\n{decision.reason}"
        )
        return ChatResponse(text=text, provider=decision.provider.value)
