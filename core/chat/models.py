from __future__ import annotations

from pydantic import BaseModel


class ChatResponse(BaseModel):
    """The assistant's response to a single user message."""

    text: str
    provider: str
