from __future__ import annotations

from pydantic import BaseModel


class CalendarEvent(BaseModel):
    """A single event on a Google Calendar."""

    id: str | None = None
    title: str
    start: str  # ISO 8601 datetime or date string
    end: str    # ISO 8601 datetime or date string
    description: str = ""
    location: str = ""
