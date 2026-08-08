"""Atomic local state for pending drafts and Telegram update offsets."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


class PendingStore:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)

    def _load(self) -> dict[str, Any]:
        if not self.path.exists():
            return {}
        try:
            loaded = json.loads(self.path.read_text(encoding="utf-8"))
            return loaded if isinstance(loaded, dict) else {}
        except (json.JSONDecodeError, OSError):
            return {}

    def get(self, chat_id: int) -> dict[str, Any] | None:
        value = self._load().get(str(chat_id))
        return value if isinstance(value, dict) else None

    def set(self, chat_id: int, value: dict[str, Any]) -> None:
        state = self._load()
        state[str(chat_id)] = value
        self._write(state)

    def clear(self, chat_id: int) -> None:
        state = self._load()
        state.pop(str(chat_id), None)
        self._write(state)

    def _write(self, state: dict[str, Any]) -> None:
        temporary = self.path.with_suffix(".tmp")
        temporary.write_text(
            json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        temporary.replace(self.path)


class OffsetStore:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)

    def get(self) -> int | None:
        if not self.path.exists():
            return None
        try:
            return int(self.path.read_text(encoding="utf-8").strip())
        except (OSError, ValueError):
            return None

    def set(self, offset: int) -> None:
        temporary = self.path.with_suffix(".tmp")
        temporary.write_text(str(offset), encoding="utf-8")
        temporary.replace(self.path)
