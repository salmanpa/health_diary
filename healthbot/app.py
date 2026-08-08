"""Private Telegram intake bot for health_diary."""

from __future__ import annotations

import logging
import mimetypes
import re
import time
import traceback
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any

from .config import BotConfig
from .events import validate_event
from .formatting import format_draft, format_today
from .openai_client import OpenAIHealthAnalyzer, validate_draft
from .repository import HealthRepository, ProjectionAfterSaveError, RepositoryError
from .state import OffsetStore, PendingStore
from .telegram import TelegramAPIError, TelegramClient


LOG = logging.getLogger("healthbot")


HELP_TEXT = """Отправляй обычный текст, фото еды с подписью или голосовое.

Примеры:
сон 00:40–07:10, качество 3/5, энергия 2/5
обед 13:20; тарелка 26 см; съел всё; салат без масла
бег 5,7 км, 31 мин, RPE 7/10

Я покажу черновик. Данные попадут в дневник только после кнопки «Сохранить».

/today — сводка за сегодня
/finish 4 — завершить день с оценкой 4/5
/sync — один Git-коммит за сегодня
/cancel — отменить текущий черновик
/whoami — показать Telegram user ID"""


def confirmation_keyboard(draft_id: str) -> dict[str, Any]:
    return {
        "inline_keyboard": [
            [
                {"text": "Сохранить", "callback_data": f"save:{draft_id}"},
                {"text": "Исправить", "callback_data": f"edit:{draft_id}"},
            ],
            [{"text": "Отмена", "callback_data": f"cancel:{draft_id}"}],
        ]
    }


class HealthDiaryBot:
    def __init__(self, config: BotConfig) -> None:
        self.config = config
        self.telegram = TelegramClient(config.telegram_token, config.max_media_bytes)
        self.analyzer = OpenAIHealthAnalyzer(config)
        self.repository = HealthRepository(config)
        state_dir = config.project_dir / "data" / "bot"
        self.pending = PendingStore(state_dir / "pending.json")
        self.offsets = OffsetStore(state_dir / "offset.txt")

    def run(self) -> None:
        self.telegram.set_commands()
        LOG.info("health_diary Telegram bot started")
        offset = self.offsets.get()
        while True:
            try:
                updates = self.telegram.get_updates(offset, self.config.poll_timeout_seconds)
                for update in coalesce_media_groups(updates):
                    update_id = int(update["update_id"])
                    try:
                        self.handle_update(update)
                    except Exception:
                        LOG.error("Update %s failed\n%s", update_id, traceback.format_exc())
                        self._notify_update_error(update)
                    finally:
                        offset = update_id + 1
                        self.offsets.set(offset)
            except KeyboardInterrupt:
                LOG.info("Bot stopped")
                return
            except Exception:
                LOG.error("Polling failed\n%s", traceback.format_exc())
                time.sleep(2)

    def handle_update(self, update: dict[str, Any]) -> None:
        if "callback_query" in update:
            self._handle_callback(update["callback_query"])
        elif "message" in update:
            self._handle_message(update["message"])

    def _authorized(self, user_id: int) -> bool:
        return user_id in self.config.allowed_user_ids

    def _handle_message(self, message: dict[str, Any]) -> None:
        chat = message.get("chat") or {}
        sender = message.get("from") or {}
        chat_id = int(chat.get("id"))
        user_id = int(sender.get("id"))
        text = str(message.get("text") or message.get("caption") or "").strip()
        command = text.split(maxsplit=1)[0].split("@", 1)[0].lower() if text.startswith("/") else ""
        if not self._authorized(user_id):
            if command == "/whoami":
                self.telegram.send_message(chat_id, f"Ваш Telegram user ID: {user_id}")
            else:
                self.telegram.send_message(chat_id, "Этот бот приватный. Используйте /whoami для настройки доступа.")
            return
        if chat.get("type") != "private":
            self.telegram.send_message(chat_id, "Пожалуйста, используй бота только в личном чате.")
            return
        if command:
            self._handle_command(chat_id, user_id, command, text)
            return

        pending = self.pending.get(chat_id)
        if pending and pending.get("mode") in {"question", "correction", "finish_rating"}:
            self._handle_followup(chat_id, message, pending, text)
            return
        if pending and pending.get("mode") == "confirmation":
            self.telegram.send_message(chat_id, "Сначала сохрани, исправь или отмени текущий черновик.")
            return
        self._analyze_new_message(chat_id, message, text)

    def _handle_command(self, chat_id: int, user_id: int, command: str, text: str) -> None:
        if command in {"/start", "/help"}:
            self.telegram.send_message(chat_id, HELP_TEXT)
        elif command == "/whoami":
            self.telegram.send_message(chat_id, f"Ваш Telegram user ID: {user_id}")
        elif command == "/cancel":
            self.pending.clear(chat_id)
            self.telegram.send_message(chat_id, "Черновик отменён.")
        elif command == "/today":
            today = datetime.now(self.config.timezone).date().isoformat()
            self.telegram.send_message(chat_id, format_today(self.repository.database, today))
        elif command == "/finish":
            match = re.search(r"(?:^|\s)([1-5])(?:\s|$)", text)
            if match:
                self._prepare_finish(chat_id, int(match.group(1)))
            else:
                self.pending.set(
                    chat_id,
                    {"mode": "finish_rating", "draft_id": uuid.uuid4().hex[:12]},
                )
                self.telegram.send_message(chat_id, "Как ты оцениваешь день по шкале 1–5?")
        elif command == "/sync":
            today = datetime.now(self.config.timezone).date().isoformat()
            try:
                result = self.repository.sync_day(today, force=True)
            except RepositoryError as exc:
                result = f"Синхронизация не выполнена: {exc}"
            self.telegram.send_message(chat_id, result)
        else:
            self.telegram.send_message(chat_id, "Неизвестная команда. Используй /help.")

    def _prepare_finish(self, chat_id: int, rating: int) -> None:
        today = datetime.now(self.config.timezone).date().isoformat()
        draft = {
            "event_type": "daily_checkin",
            "diary_date": today,
            "occurred_at": datetime.now(self.config.timezone).strftime("%H:%M"),
            "summary_ru": f"Пользователь завершил день с оценкой {rating}/5.",
            "question": None,
            "observations": [f"Оценка дня пользователем: {rating}/5"],
            "assumptions": [],
            "confidence": "high",
            "uncertainty_drivers": [],
            "recommendations": [],
            "payload": {
                "meal_type": None,
                "nutrition_items": [],
                "food_bases": [],
                "meal_rating": None,
                "sleep": None,
                "workout": None,
                "daily_checkin": {
                    "day_rating": rating,
                    "energy_score": None,
                    "mood_score": None,
                    "stress_score": None,
                    "digestion_score": None,
                    "water_ml": None,
                    "caffeine_servings": None,
                    "caffeine_last_at": None,
                    "alcohol_units": None,
                    "day_complete": True,
                },
                "expense": None,
            },
        }
        self._present_draft(chat_id, draft, original_text=f"/finish {rating}", content_type="command")

    def _analyze_new_message(self, chat_id: int, message: dict[str, Any], text: str) -> None:
        image: bytes | None = None
        image_mime = "image/jpeg"
        additional_images: list[tuple[bytes, str]] = []
        content_type = "text"
        album = message.get("photo_album") or []
        if album:
            content_type = "photo_album"
            self.telegram.send_action(chat_id, "typing")
            downloaded: list[tuple[bytes, str]] = []
            for file_id in album[:3]:
                content, path = self.telegram.get_file_bytes(file_id)
                downloaded.append((content, mimetypes.guess_type(path)[0] or "image/jpeg"))
            image, image_mime = downloaded[0]
            additional_images = downloaded[1:]
        elif message.get("photo"):
            content_type = "photo"
            photo = message["photo"][-1]
            self.telegram.send_action(chat_id, "typing")
            image, path = self.telegram.get_file_bytes(photo["file_id"])
            image_mime = mimetypes.guess_type(path)[0] or "image/jpeg"
        elif message.get("voice") or message.get("audio"):
            content_type = "voice"
            media = message.get("voice") or message.get("audio")
            self.telegram.send_action(chat_id, "typing")
            audio, path = self.telegram.get_file_bytes(media["file_id"])
            text = self.analyzer.transcribe(audio, Path(path).name, media.get("mime_type"))
            self.telegram.send_message(chat_id, f"Распознано: {text}")
        elif not text:
            self.telegram.send_message(chat_id, "Пришли текст, фотографию еды или голосовое сообщение.")
            return
        self.telegram.send_action(chat_id, "typing")
        draft = self.analyzer.analyze(
            text,
            image_bytes=image,
            image_mime_type=image_mime,
            additional_images=additional_images,
        )
        self._present_draft(chat_id, draft, original_text=text, content_type=content_type)

    def _present_draft(
        self,
        chat_id: int,
        draft: dict[str, Any],
        *,
        original_text: str,
        content_type: str,
    ) -> None:
        draft_id = uuid.uuid4().hex[:12]
        question = draft.get("question")
        if question:
            self.pending.set(
                chat_id,
                {
                    "mode": "question",
                    "draft_id": draft_id,
                    "draft": draft,
                    "original_text": original_text,
                    "content_type": content_type,
                },
            )
            self.telegram.send_message(chat_id, format_draft(draft))
            return
        self.pending.set(
            chat_id,
            {
                "mode": "confirmation",
                "draft_id": draft_id,
                "draft": draft,
                "original_text": original_text,
                "content_type": content_type,
            },
        )
        self.telegram.send_message(
            chat_id,
            format_draft(draft),
            reply_markup=confirmation_keyboard(draft_id),
        )

    def _handle_followup(
        self,
        chat_id: int,
        message: dict[str, Any],
        pending: dict[str, Any],
        text: str,
    ) -> None:
        if pending.get("mode") == "finish_rating":
            match = re.search(r"[1-5]", text)
            if not match:
                self.telegram.send_message(chat_id, "Нужна одна цифра от 1 до 5.")
                return
            self.pending.clear(chat_id)
            self._prepare_finish(chat_id, int(match.group(0)))
            return
        if not text:
            self.telegram.send_message(chat_id, "Пришли исправление или ответ текстом.")
            return
        self.telegram.send_action(chat_id, "typing")
        previous = pending.get("draft") or {}
        draft = self.analyzer.analyze(
            pending.get("original_text", ""),
            previous_draft=previous,
            followup=text,
        )
        draft["question"] = None
        if draft.get("event_type") == "unknown":
            self.pending.clear(chat_id)
            self.telegram.send_message(
                chat_id,
                "Не удалось надёжно определить тип записи. Отправь её заново с короткой подписью.",
            )
            return
        validate_draft(draft)
        self._present_draft(
            chat_id,
            draft,
            original_text=(pending.get("original_text", "") + f"\nУточнение: {text}").strip(),
            content_type=pending.get("content_type", "text"),
        )

    def _handle_callback(self, callback: dict[str, Any]) -> None:
        callback_id = str(callback.get("id"))
        sender = callback.get("from") or {}
        user_id = int(sender.get("id"))
        message = callback.get("message") or {}
        chat_id = int((message.get("chat") or {}).get("id"))
        if not self._authorized(user_id):
            self.telegram.answer_callback(callback_id, "Нет доступа")
            return
        data = str(callback.get("data") or "")
        action, separator, draft_id = data.partition(":")
        pending = self.pending.get(chat_id)
        if not separator or not pending or pending.get("draft_id") != draft_id:
            self.telegram.answer_callback(callback_id, "Черновик уже устарел")
            return
        self.telegram.answer_callback(callback_id)
        if action == "cancel":
            self.pending.clear(chat_id)
            self.telegram.edit_message(chat_id, message["message_id"], "Черновик отменён.")
        elif action == "edit":
            pending["mode"] = "correction"
            self.pending.set(chat_id, pending)
            self.telegram.edit_message(
                chat_id,
                message["message_id"],
                str(message.get("text") or format_draft(pending["draft"]))
                + "\n\nОжидаю исправление текстом.",
            )
            self.telegram.send_message(chat_id, "Напиши одним сообщением, что исправить.")
        elif action == "save":
            self._save_pending(chat_id, message, pending)

    def _save_pending(
        self, chat_id: int, message: dict[str, Any], pending: dict[str, Any]
    ) -> None:
        draft = pending["draft"]
        received_at = datetime.now(self.config.timezone).isoformat(timespec="seconds")
        event = validate_event(
            {
                "event_id": "tg-" + uuid.uuid4().hex,
                "event_type": draft["event_type"],
                "diary_date": draft["diary_date"],
                "occurred_at": draft.get("occurred_at"),
                "received_at": received_at,
                "source": "telegram:" + pending.get("content_type", "text"),
                "raw_text": pending.get("original_text", "")[:8000],
                "payload": draft["payload"],
                "analysis": {
                    "summary_ru": draft.get("summary_ru"),
                    "observations": draft.get("observations") or [],
                    "assumptions": draft.get("assumptions") or [],
                    "confidence": draft.get("confidence"),
                    "uncertainty_drivers": draft.get("uncertainty_drivers") or [],
                    "recommendations": draft.get("recommendations") or [],
                },
            }
        )
        try:
            result = self.repository.save(event)
        except ProjectionAfterSaveError as exc:
            self.pending.clear(chat_id)
            self.telegram.edit_message(
                chat_id,
                message["message_id"],
                format_draft(draft)
                + "\n\nИсходное событие сохранено, но SQLite/аналитика пока не обновились. "
                + "Запусти ./scripts/build_dashboard.sh. Ошибка: "
                + str(exc)[:500],
            )
            return
        self.pending.clear(chat_id)
        saved_text = format_draft(draft) + "\n\nСохранено. Аналитика обновлена."
        self.telegram.edit_message(chat_id, message["message_id"], saved_text)
        checkin = draft.get("payload", {}).get("daily_checkin") or {}
        if checkin.get("day_complete"):
            try:
                sync_message = self.repository.sync_day(draft["diary_date"])
            except RepositoryError as exc:
                sync_message = f"Данные сохранены, но Git-синхронизация не выполнена: {exc}"
            self.telegram.send_message(chat_id, sync_message)
        LOG.info(
            "Saved %s (%s imported, %s skipped)",
            event["event_id"],
            result.imported,
            result.skipped,
        )

    def _notify_update_error(self, update: dict[str, Any]) -> None:
        message = update.get("message") or (update.get("callback_query") or {}).get("message") or {}
        chat_id = (message.get("chat") or {}).get("id")
        if chat_id:
            try:
                self.telegram.send_message(
                    int(chat_id),
                    "Не удалось обработать запись. Черновик не сохранён; попробуй ещё раз или /cancel.",
                )
            except Exception:
                pass


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    config = BotConfig.from_environment()
    if not (config.project_dir / "data" / "health_diary.sqlite3").exists():
        raise SystemExit("Database missing. Run ./scripts/build_dashboard.sh first.")
    HealthDiaryBot(config).run()


def coalesce_media_groups(updates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Combine photos from the same Telegram album when they arrive in one poll."""
    groups: dict[tuple[int, str], list[dict[str, Any]]] = {}
    regular: list[dict[str, Any]] = []
    for update in updates:
        message = update.get("message") or {}
        group_id = message.get("media_group_id")
        chat_id = (message.get("chat") or {}).get("id")
        if group_id and chat_id is not None and message.get("photo"):
            groups.setdefault((int(chat_id), str(group_id)), []).append(update)
        else:
            regular.append(update)
    for grouped in groups.values():
        grouped.sort(key=lambda item: int(item["update_id"]))
        first_message = dict(grouped[0]["message"])
        first_message["photo_album"] = [
            item["message"]["photo"][-1]["file_id"] for item in grouped
        ]
        captions = [
            str(item["message"].get("caption") or "").strip()
            for item in grouped
            if item["message"].get("caption")
        ]
        if captions:
            first_message["caption"] = captions[0]
        regular.append(
            {
                "update_id": max(int(item["update_id"]) for item in grouped),
                "message": first_message,
            }
        )
    return sorted(regular, key=lambda item: int(item["update_id"]))


if __name__ == "__main__":
    main()
