"""Environment-backed bot configuration without third-party dependencies."""

from __future__ import annotations

import hashlib
import os
from dataclasses import dataclass
from pathlib import Path
from zoneinfo import ZoneInfo


PROJECT_DIR = Path(__file__).resolve().parent.parent


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        os.environ.setdefault(key.strip(), value)


def _bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


@dataclass(frozen=True)
class BotConfig:
    telegram_token: str
    allowed_user_ids: frozenset[int]
    openai_api_key: str
    openai_model: str
    transcription_model: str
    image_detail: str
    timezone: ZoneInfo
    safety_identifier: str
    poll_timeout_seconds: int
    max_media_bytes: int
    auto_git_sync: bool
    git_remote: str
    git_branch: str
    project_dir: Path = PROJECT_DIR

    @classmethod
    def from_environment(cls) -> "BotConfig":
        load_env_file(PROJECT_DIR / ".env")
        token = os.getenv("TELEGRAM_BOT_TOKEN", "").strip()
        api_key = os.getenv("OPENAI_API_KEY", "").strip()
        raw_ids = os.getenv("ALLOWED_TELEGRAM_USER_IDS", "")
        try:
            allowed = frozenset(
                int(value.strip()) for value in raw_ids.split(",") if value.strip()
            )
        except ValueError as exc:
            raise SystemExit("ALLOWED_TELEGRAM_USER_IDS must contain integer IDs") from exc
        if not token:
            raise SystemExit("TELEGRAM_BOT_TOKEN is required; copy .env.example to .env")
        if not api_key:
            raise SystemExit("OPENAI_API_KEY is required; copy .env.example to .env")
        image_detail = os.getenv("OPENAI_IMAGE_DETAIL", "auto").strip().lower()
        if image_detail not in {"low", "high", "auto", "original"}:
            raise SystemExit("OPENAI_IMAGE_DETAIL must be low, high, auto, or original")
        timezone_name = os.getenv("HEALTH_DIARY_TIMEZONE", "Europe/Moscow")
        try:
            timezone = ZoneInfo(timezone_name)
        except Exception as exc:
            raise SystemExit(f"Unknown HEALTH_DIARY_TIMEZONE: {timezone_name}") from exc
        safety_identifier = os.getenv("OPENAI_SAFETY_IDENTIFIER", "").strip()
        if not safety_identifier:
            digest = hashlib.sha256(
                ("health_diary:" + ",".join(map(str, sorted(allowed))) or "setup").encode()
            ).hexdigest()[:32]
            safety_identifier = f"health-diary-{digest}"
        return cls(
            telegram_token=token,
            allowed_user_ids=allowed,
            openai_api_key=api_key,
            openai_model=os.getenv("OPENAI_MODEL", "gpt-5.6-sol").strip(),
            transcription_model=os.getenv(
                "OPENAI_TRANSCRIPTION_MODEL", "gpt-4o-transcribe"
            ).strip(),
            image_detail=image_detail,
            timezone=timezone,
            safety_identifier=safety_identifier,
            poll_timeout_seconds=int(os.getenv("TELEGRAM_POLL_TIMEOUT", "30")),
            max_media_bytes=int(os.getenv("MAX_MEDIA_BYTES", str(20 * 1024 * 1024))),
            auto_git_sync=_bool("AUTO_GIT_SYNC", False),
            git_remote=os.getenv("GIT_REMOTE", "origin").strip(),
            git_branch=os.getenv("GIT_BRANCH", "main").strip(),
        )
