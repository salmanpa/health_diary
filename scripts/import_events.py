#!/usr/bin/env python3
"""Project append-only JSONL health events into SQLite."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_DIR))

from healthbot.events import EventProjector  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--database",
        type=Path,
        default=PROJECT_DIR / "data" / "health_diary.sqlite3",
    )
    parser.add_argument(
        "--events-dir",
        type=Path,
        default=PROJECT_DIR / "db" / "events",
    )
    args = parser.parse_args()
    result = EventProjector(args.database).project_directory(args.events_dir)
    print(f"Health events imported: {result.imported}; already present: {result.skipped}")


if __name__ == "__main__":
    main()
