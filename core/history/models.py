from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from pydantic import BaseModel, Field


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


class Message(BaseModel):
    """A single message in a conversation."""

    role: str
    text: str
    timestamp: str = Field(default_factory=_now)


class Conversation(BaseModel):
    """A conversation session containing an ordered list of messages."""

    id: str = Field(default_factory=lambda: str(uuid4()))
    title: str = "Nova conversa"
    messages: list[Message] = Field(default_factory=list)
    created_at: str = Field(default_factory=_now)
    updated_at: str = Field(default_factory=_now)
