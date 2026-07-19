from __future__ import annotations

from enum import Enum

from pydantic import BaseModel


class Provider(str, Enum):
    CHATGPT = "ChatGPT"
    CLAUDE = "Claude"
    GEMINI = "Gemini"


class RouteDecision(BaseModel):
    """The result of routing a prompt to a provider, including metadata."""

    provider: Provider
    reason: str
    complexity: str = "medium"   # "simple" | "medium" | "complex"
    confidence: float = 1.0      # 0.0 – 1.0
