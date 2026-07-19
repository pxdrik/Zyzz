from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from pydantic import BaseModel, Field


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


class Automation(BaseModel):
    """A saved, reusable workflow that is dispatched to the AI on demand."""

    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str
    description: str
    prompt: str
    created_at: str = Field(default_factory=_now)
