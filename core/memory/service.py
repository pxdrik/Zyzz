from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from core.memory.models import MemoryEntry

MEMORY_FILE = Path.home() / ".zyzz" / "memory.json"

# Patterns that trigger storing a memory. Group 1 captures the content.
_TRIGGER_PATTERNS: list[str] = [
    r"^remember that (.+)",
    r"^remember: (.+)",
    r"^lembra que (.+)",
    r"^lembre que (.+)",
    r"^lembra: (.+)",
    r"^/remember (.+)",
]


class MemoryService:
    """Persists and retrieves long-term memory entries from disk."""

    def __init__(self) -> None:
        MEMORY_FILE.parent.mkdir(parents=True, exist_ok=True)

    def extract_from_message(self, text: str) -> str | None:
        """Return the memory content if the message matches a trigger, else None."""
        for pattern in _TRIGGER_PATTERNS:
            match = re.match(pattern, text.strip(), re.IGNORECASE)
            if match:
                return match.group(1).strip()
        return None

    def add(self, content: str) -> MemoryEntry:
        """Store a new memory entry and persist to disk."""
        entries = self._load()
        entry = MemoryEntry(content=content)
        entries.append(entry)
        self._save(entries)
        return entry

    def list(self) -> list[MemoryEntry]:
        """Return all stored memory entries."""
        return self._load()

    def delete(self, entry_id: str) -> None:
        """Delete a memory entry by id."""
        self._save([e for e in self._load() if e.id != entry_id])

    def build_context(self) -> str:
        """Return a formatted context string to prepend to prompts, or empty string."""
        entries = self._load()
        if not entries:
            return ""
        items = "\n".join(f"- {e.content}" for e in entries)
        return f"[What I know about the user:\n{items}]\n\n"

    def _load(self) -> list[MemoryEntry]:
        if not MEMORY_FILE.exists():
            return []
        try:
            data = json.loads(MEMORY_FILE.read_text(encoding="utf-8"))
            return [MemoryEntry.model_validate(item) for item in data]
        except Exception as exc:
            print(f"MemoryService: failed to load {MEMORY_FILE}: {exc}", file=sys.stderr)
            return []

    def _save(self, entries: list[MemoryEntry]) -> None:
        MEMORY_FILE.write_text(
            json.dumps([e.model_dump() for e in entries], indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
