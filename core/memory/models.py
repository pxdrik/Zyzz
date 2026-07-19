from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from pydantic import BaseModel, Field


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


class MemoryEntry(BaseModel):
    """A single piece of long-term memory about the user."""

    id: str = Field(default_factory=lambda: str(uuid4()))
    content: str
    created_at: str = Field(default_factory=_now)
