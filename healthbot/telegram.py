"""Small Telegram Bot API client using long polling."""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from typing import Any


class TelegramAPIError(RuntimeError):
    pass


class TelegramClient:
    def __init__(self, token: str, max_media_bytes: int) -> None:
        self.api_url = f"https://api.telegram.org/bot{token}"
        self.file_url = f"https://api.telegram.org/file/bot{token}"
        self.max_media_bytes = max_media_bytes

    def call(self, method: str, payload: dict[str, Any] | None = None) -> Any:
        body = json.dumps(payload or {}, ensure_ascii=False).encode("utf-8")
        last_error: Exception | None = None
        for attempt in range(3):
            request = urllib.request.Request(
                f"{self.api_url}/{method}",
                data=body,
                method="POST",
                headers={"Content-Type": "application/json; charset=utf-8"},
            )
            try:
                with urllib.request.urlopen(request, timeout=45) as response:
                    result = json.loads(response.read().decode("utf-8"))
                if not result.get("ok"):
                    raise TelegramAPIError(str(result.get("description") or "Telegram API error"))
                return result.get("result")
            except urllib.error.HTTPError as exc:
                detail = exc.read().decode("utf-8", errors="replace")
                last_error = TelegramAPIError(f"Telegram HTTP {exc.code}: {detail[:500]}")
                if exc.code not in {429, 500, 502, 503, 504}:
                    break
            except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
                last_error = exc
            if attempt < 2:
                time.sleep(2**attempt)
        raise TelegramAPIError(str(last_error or "Telegram request failed"))

    def get_updates(self, offset: int | None, timeout: int) -> list[dict[str, Any]]:
        payload: dict[str, Any] = {
            "timeout": timeout,
            "allowed_updates": ["message", "callback_query"],
        }
        if offset is not None:
            payload["offset"] = offset
        result = self.call("getUpdates", payload)
        return result if isinstance(result, list) else []

    def send_message(
        self,
        chat_id: int,
        text: str,
        *,
        reply_markup: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        payload: dict[str, Any] = {"chat_id": chat_id, "text": text[:4096]}
        if reply_markup is not None:
            payload["reply_markup"] = reply_markup
        return self.call("sendMessage", payload)

    def edit_message(
        self,
        chat_id: int,
        message_id: int,
        text: str,
        *,
        reply_markup: dict[str, Any] | None = None,
    ) -> None:
        payload: dict[str, Any] = {
            "chat_id": chat_id,
            "message_id": message_id,
            "text": text[:4096],
        }
        if reply_markup is not None:
            payload["reply_markup"] = reply_markup
        self.call("editMessageText", payload)

    def answer_callback(self, callback_query_id: str, text: str | None = None) -> None:
        payload: dict[str, Any] = {"callback_query_id": callback_query_id}
        if text:
            payload["text"] = text[:200]
        self.call("answerCallbackQuery", payload)

    def send_action(self, chat_id: int, action: str = "typing") -> None:
        self.call("sendChatAction", {"chat_id": chat_id, "action": action})

    def get_file_bytes(self, file_id: str) -> tuple[bytes, str]:
        result = self.call("getFile", {"file_id": file_id})
        if not isinstance(result, dict) or not result.get("file_path"):
            raise TelegramAPIError("Telegram did not return a file_path")
        file_size = result.get("file_size")
        if isinstance(file_size, int) and file_size > self.max_media_bytes:
            raise TelegramAPIError("Файл слишком большой для обработки")
        file_path = str(result["file_path"])
        request = urllib.request.Request(f"{self.file_url}/{file_path}")
        with urllib.request.urlopen(request, timeout=60) as response:
            length = response.headers.get("Content-Length")
            if length and int(length) > self.max_media_bytes:
                raise TelegramAPIError("Файл слишком большой для обработки")
            content = response.read(self.max_media_bytes + 1)
        if len(content) > self.max_media_bytes:
            raise TelegramAPIError("Файл слишком большой для обработки")
        return content, file_path

    def set_commands(self) -> None:
        self.call(
            "setMyCommands",
            {
                "commands": [
                    {"command": "today", "description": "Сводка за сегодня"},
                    {"command": "finish", "description": "Завершить день: /finish 4"},
                    {"command": "sync", "description": "Один коммит за день"},
                    {"command": "cancel", "description": "Отменить текущий черновик"},
                    {"command": "help", "description": "Как пользоваться"},
                    {"command": "whoami", "description": "Показать Telegram user ID"},
                ]
            },
        )
