from __future__ import annotations

from pathlib import Path

from core.history.models import Conversation

DATA_DIR = Path.home() / ".zyzz" / "conversations"


class ConversationService:
    """Persists and retrieves conversations from disk as JSON files."""

    def __init__(self) -> None:
        DATA_DIR.mkdir(parents=True, exist_ok=True)

    def create(self) -> Conversation:
        """Create and persist a new empty conversation."""
        conv = Conversation()
        self._write(conv)
        return conv

    def save(self, conversation: Conversation) -> None:
        """Persist an existing conversation."""
        self._write(conversation)

    def load(self, conv_id: str) -> Conversation:
        """Load a conversation by id."""
        return Conversation.model_validate_json(
            (DATA_DIR / f"{conv_id}.json").read_text(encoding="utf-8")
        )

    def list(self) -> list[Conversation]:
        """Return all conversations sorted by most recently updated."""
        result = []
        for path in DATA_DIR.glob("*.json"):
            try:
                result.append(Conversation.model_validate_json(path.read_text(encoding="utf-8")))
            except Exception:
                pass
        return sorted(result, key=lambda c: c.updated_at, reverse=True)

    def rename(self, conv_id: str, title: str) -> None:
        """Rename a conversation."""
        conv = self.load(conv_id)
        conv.title = title
        self._write(conv)

    def delete(self, conv_id: str) -> None:
        """Delete a conversation from disk."""
        (DATA_DIR / f"{conv_id}.json").unlink(missing_ok=True)

    def _write(self, conversation: Conversation) -> None:
        path = DATA_DIR / f"{conversation.id}.json"
        path.write_text(conversation.model_dump_json(indent=2), encoding="utf-8")
