"""Save confirmed events, rebuild projections, and optionally sync one daily commit."""

from __future__ import annotations

import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .config import BotConfig
from .events import EventProjector, EventStore


class RepositoryError(RuntimeError):
    pass


class ProjectionAfterSaveError(RepositoryError):
    """The append-only source is safe, but derived artifacts need rebuilding."""

    def __init__(self, event_path: Path, detail: str) -> None:
        super().__init__(detail)
        self.event_path = event_path


@dataclass(frozen=True)
class SaveResult:
    event_path: Path
    imported: int
    skipped: int


class HealthRepository:
    def __init__(self, config: BotConfig) -> None:
        self.config = config
        self.project_dir = config.project_dir
        self.events_dir = self.project_dir / "db" / "events"
        self.database = self.project_dir / "data" / "health_diary.sqlite3"
        self.store = EventStore(self.events_dir)

    def save(self, event: dict[str, Any]) -> SaveResult:
        path = self.store.append(event)
        try:
            result = EventProjector(self.database).project_directory(self.events_dir)
            subprocess.run(
                [sys.executable, str(self.project_dir / "scripts" / "generate_dashboard.py")],
                cwd=self.project_dir,
                check=True,
                capture_output=True,
                text=True,
            )
        except Exception as exc:
            raise ProjectionAfterSaveError(path, str(exc)) from exc
        return SaveResult(path, result.imported, result.skipped)

    def sync_day(self, diary_date: str, *, force: bool = False) -> str:
        if not self.config.auto_git_sync and not force:
            return "Автосинхронизация отключена; данные сохранены локально."
        event_path = self.events_dir / f"{diary_date}.jsonl"
        if not event_path.exists():
            raise RepositoryError(f"Нет событий за {diary_date}")
        allowed = {
            str(event_path.relative_to(self.project_dir)),
            "dashboard/data.js",
        }
        staged = self._git("diff", "--cached", "--name-only").splitlines()
        unexpected = [path for path in staged if path not in allowed]
        if unexpected:
            raise RepositoryError(
                "Git-синхронизация остановлена: уже staged посторонние файлы: "
                + ", ".join(unexpected)
            )
        self._git("add", "--", *sorted(allowed))
        diff = subprocess.run(
            ["git", "diff", "--cached", "--quiet"],
            cwd=self.project_dir,
            check=False,
        )
        if diff.returncode == 0:
            self._git("push", self.config.git_remote, self.config.git_branch)
            return "Новых изменений для коммита нет; локальные коммиты синхронизированы."
        if diff.returncode != 1:
            raise RepositoryError("Не удалось проверить staged-изменения")
        self._git("commit", "-m", f"Обновить дневник за {diary_date}")
        self._git("push", self.config.git_remote, self.config.git_branch)
        return f"Данные за {diary_date} отправлены одним коммитом."

    def _git(self, *arguments: str) -> str:
        completed = subprocess.run(
            ["git", *arguments],
            cwd=self.project_dir,
            check=False,
            capture_output=True,
            text=True,
        )
        if completed.returncode != 0:
            detail = (completed.stderr or completed.stdout).strip()
            raise RepositoryError(detail or f"git {' '.join(arguments)} failed")
        return completed.stdout.strip()
