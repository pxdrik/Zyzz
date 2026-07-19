from __future__ import annotations

import json
import sys
from pathlib import Path

from core.automations.models import Automation

AUTOMATIONS_FILE = Path.home() / ".zyzz" / "automations.json"


class AutomationService:
    """Persists and retrieves saved automations from disk."""

    def __init__(self) -> None:
        AUTOMATIONS_FILE.parent.mkdir(parents=True, exist_ok=True)

    def create(self, name: str, description: str, prompt: str) -> Automation:
        """Create a new automation and persist it to disk."""
        automations = self._load()
        # Replace if one with the same name already exists
        automations = [a for a in automations if a.name.lower() != name.lower()]
        automation = Automation(name=name, description=description, prompt=prompt)
        automations.append(automation)
        self._save(automations)
        return automation

    def list(self) -> list[Automation]:
        """Return all saved automations."""
        return self._load()

    def get(self, name: str) -> Automation | None:
        """Return the automation with the given name (case-insensitive), or None."""
        return next((a for a in self._load() if a.name.lower() == name.lower()), None)

    def delete(self, name: str) -> bool:
        """Delete the automation with the given name. Returns True if it was found."""
        automations = self._load()
        filtered = [a for a in automations if a.name.lower() != name.lower()]
        if len(filtered) == len(automations):
            return False
        self._save(filtered)
        return True

    def _load(self) -> list[Automation]:
        if not AUTOMATIONS_FILE.exists():
            return []
        try:
            data = json.loads(AUTOMATIONS_FILE.read_text(encoding="utf-8"))
            return [Automation.model_validate(item) for item in data]
        except Exception as exc:
            print(f"AutomationService: failed to load {AUTOMATIONS_FILE}: {exc}", file=sys.stderr)
            return []

    def _save(self, automations: list[Automation]) -> None:
        AUTOMATIONS_FILE.write_text(
            json.dumps([a.model_dump() for a in automations], indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
