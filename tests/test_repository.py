from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from healthbot.repository import HealthRepository, RepositoryError


def git(root: Path, *arguments: str) -> str:
    completed = subprocess.run(
        ["git", *arguments],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    )
    return completed.stdout.strip()


class RepositorySyncTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.repo = self.root / "repo"
        self.remote = self.root / "remote.git"
        self.repo.mkdir()
        subprocess.run(["git", "init", "--bare", str(self.remote)], check=True, capture_output=True)
        git(self.repo, "init", "-b", "main")
        git(self.repo, "config", "user.name", "Health Diary Test")
        git(self.repo, "config", "user.email", "health-diary-test@example.invalid")
        git(self.repo, "config", "commit.gpgsign", "false")
        git(self.repo, "remote", "add", "origin", str(self.remote))
        (self.repo / "db" / "events").mkdir(parents=True)
        (self.repo / "dashboard").mkdir()
        (self.repo / "dashboard" / "data.js").write_text("baseline\n", encoding="utf-8")
        git(self.repo, "add", "dashboard/data.js")
        git(self.repo, "commit", "-m", "baseline")
        git(self.repo, "push", "-u", "origin", "main")
        config = SimpleNamespace(
            project_dir=self.repo,
            auto_git_sync=False,
            git_remote="origin",
            git_branch="main",
        )
        self.repository = HealthRepository(config)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_sync_commits_only_daily_files_and_pushes(self) -> None:
        event = self.repo / "db" / "events" / "2026-08-09.jsonl"
        event.write_text('{"event_id":"test"}\n', encoding="utf-8")
        (self.repo / "dashboard" / "data.js").write_text("updated\n", encoding="utf-8")
        result = self.repository.sync_day("2026-08-09", force=True)
        self.assertIn("одним коммитом", result)
        self.assertEqual(git(self.repo, "status", "--short"), "")
        self.assertEqual(git(self.remote, "rev-list", "--count", "main"), "2")
        retry = self.repository.sync_day("2026-08-09", force=True)
        self.assertIn("Новых изменений", retry)

    def test_sync_refuses_unrelated_staged_file(self) -> None:
        event = self.repo / "db" / "events" / "2026-08-09.jsonl"
        event.write_text('{"event_id":"test"}\n', encoding="utf-8")
        (self.repo / "unrelated.txt").write_text("user work\n", encoding="utf-8")
        git(self.repo, "add", "unrelated.txt")
        with self.assertRaises(RepositoryError):
            self.repository.sync_day("2026-08-09", force=True)


if __name__ == "__main__":
    unittest.main()
