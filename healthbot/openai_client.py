"""Minimal OpenAI Responses and transcription clients over the standard library."""

from __future__ import annotations

import base64
import json
import mimetypes
import time
import urllib.error
import urllib.request
import uuid
from datetime import datetime
from typing import Any

from .config import BotConfig
from .events import (
    CONFIDENCE_LEVELS,
    EXPENSE_CATEGORIES,
    FOOD_BASES,
    MEAL_TYPES,
    EventValidationError,
)
from .prompt import DRAFT_SCHEMA, SYSTEM_PROMPT


class OpenAIRequestError(RuntimeError):
    pass


class OpenAIHealthAnalyzer:
    def __init__(self, config: BotConfig) -> None:
        self.config = config
        self.base_url = "https://api.openai.com/v1"

    def analyze(
        self,
        text: str,
        *,
        image_bytes: bytes | None = None,
        image_mime_type: str = "image/jpeg",
        additional_images: list[tuple[bytes, str]] | None = None,
        previous_draft: dict[str, Any] | None = None,
        followup: str | None = None,
    ) -> dict[str, Any]:
        now = datetime.now(self.config.timezone)
        context = (
            f"Текущее локальное время: {now.isoformat(timespec='minutes')}.\n"
            f"Сообщение пользователя: {text or '(без подписи)'}"
        )
        if previous_draft is not None:
            context += (
                "\nПредыдущий черновик и уже заданный вопрос:\n"
                + json.dumps(previous_draft, ensure_ascii=False)
                + f"\nОтвет/исправление пользователя: {followup or ''}\n"
                + "Обнови и финализируй этот же черновик."
            )
        content: list[dict[str, Any]] = [{"type": "input_text", "text": context}]
        images: list[tuple[bytes, str]] = []
        if image_bytes is not None:
            images.append((image_bytes, image_mime_type))
        images.extend(additional_images or [])
        for image, mime_type in images[:3]:
            encoded = base64.b64encode(image).decode("ascii")
            content.append(
                {
                    "type": "input_image",
                    "image_url": f"data:{mime_type};base64,{encoded}",
                    "detail": self.config.image_detail,
                }
            )
        body = {
            "model": self.config.openai_model,
            "store": False,
            "safety_identifier": self.config.safety_identifier,
            "reasoning": {"effort": "medium"},
            "input": [
                {"role": "developer", "content": [{"type": "input_text", "text": SYSTEM_PROMPT}]},
                {"role": "user", "content": content},
            ],
            "text": {
                "verbosity": "low",
                "format": {
                    "type": "json_schema",
                    "name": "health_diary_event_draft",
                    "strict": True,
                    "schema": DRAFT_SCHEMA,
                },
            },
            "max_output_tokens": 5000,
        }
        response = self._json_request("/responses", body)
        output_text = self._extract_output_text(response)
        try:
            draft = json.loads(output_text)
        except json.JSONDecodeError as exc:
            raise OpenAIRequestError("OpenAI returned invalid structured JSON") from exc
        return validate_draft(draft)

    def transcribe(self, audio: bytes, filename: str, mime_type: str | None = None) -> str:
        boundary = "----healthdiary" + uuid.uuid4().hex
        chunks: list[bytes] = []

        def add_field(name: str, value: str) -> None:
            chunks.extend(
                [
                    f"--{boundary}\r\n".encode(),
                    f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode(),
                    value.encode("utf-8"),
                    b"\r\n",
                ]
            )

        add_field("model", self.config.transcription_model)
        add_field("language", "ru")
        add_field("response_format", "json")
        safe_filename = filename.replace('"', "") or "voice.ogg"
        guessed = mime_type or mimetypes.guess_type(safe_filename)[0] or "application/octet-stream"
        chunks.extend(
            [
                f"--{boundary}\r\n".encode(),
                f'Content-Disposition: form-data; name="file"; filename="{safe_filename}"\r\n'.encode(),
                f"Content-Type: {guessed}\r\n\r\n".encode(),
                audio,
                b"\r\n",
                f"--{boundary}--\r\n".encode(),
            ]
        )
        response = self._raw_request(
            "/audio/transcriptions",
            b"".join(chunks),
            f"multipart/form-data; boundary={boundary}",
        )
        text = response.get("text")
        if not isinstance(text, str) or not text.strip():
            raise OpenAIRequestError("Transcription response did not contain text")
        return text.strip()

    def _json_request(self, path: str, body: dict[str, Any]) -> dict[str, Any]:
        return self._raw_request(
            path,
            json.dumps(body, ensure_ascii=False).encode("utf-8"),
            "application/json",
        )

    def _raw_request(self, path: str, body: bytes, content_type: str) -> dict[str, Any]:
        last_error: Exception | None = None
        for attempt in range(3):
            request = urllib.request.Request(
                self.base_url + path,
                data=body,
                method="POST",
                headers={
                    "Authorization": f"Bearer {self.config.openai_api_key}",
                    "Content-Type": content_type,
                    "User-Agent": "health-diary-telegram-bot/1.0",
                },
            )
            try:
                with urllib.request.urlopen(request, timeout=120) as response:
                    return json.loads(response.read().decode("utf-8"))
            except urllib.error.HTTPError as exc:
                detail = exc.read().decode("utf-8", errors="replace")
                last_error = OpenAIRequestError(f"OpenAI HTTP {exc.code}: {detail[:500]}")
                if exc.code not in {408, 409, 429, 500, 502, 503, 504}:
                    break
            except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
                last_error = exc
            if attempt < 2:
                time.sleep(2**attempt)
        raise OpenAIRequestError(str(last_error or "OpenAI request failed"))

    @staticmethod
    def _extract_output_text(response: dict[str, Any]) -> str:
        fragments: list[str] = []
        for item in response.get("output") or []:
            if item.get("type") != "message":
                continue
            for content in item.get("content") or []:
                if content.get("type") == "output_text" and isinstance(content.get("text"), str):
                    fragments.append(content["text"])
                if content.get("type") == "refusal":
                    raise OpenAIRequestError(str(content.get("refusal") or "Request refused"))
        if not fragments:
            raise OpenAIRequestError("OpenAI response did not contain output_text")
        return "".join(fragments)


def validate_draft(draft: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(draft, dict):
        raise EventValidationError("draft must be an object")
    event_type = draft.get("event_type")
    if event_type not in {"nutrition", "sleep", "workout", "daily_checkin", "expense", "unknown"}:
        raise EventValidationError("draft event_type is invalid")
    try:
        draft["diary_date"] = datetime.strptime(draft.get("diary_date", ""), "%Y-%m-%d").date().isoformat()
    except (TypeError, ValueError) as exc:
        raise EventValidationError("draft diary_date is invalid") from exc
    occurred_at = draft.get("occurred_at")
    if occurred_at is not None:
        try:
            draft["occurred_at"] = datetime.strptime(occurred_at, "%H:%M").strftime("%H:%M")
        except (TypeError, ValueError) as exc:
            raise EventValidationError("draft occurred_at is invalid") from exc
    payload = draft.get("payload")
    if not isinstance(payload, dict):
        raise EventValidationError("draft payload is missing")
    if event_type == "nutrition":
        if payload.get("meal_type") not in MEAL_TYPES:
            raise EventValidationError("nutrition draft has invalid meal_type")
        items = payload.get("nutrition_items")
        if not isinstance(items, list) or not items:
            raise EventValidationError("nutrition draft has no items")
        for item in items:
            if not isinstance(item, dict) or not str(item.get("food_name") or "").strip():
                raise EventValidationError("nutrition item needs food_name")
            _validate_range(item, "weight_g", "weight_min_g", "weight_max_g")
            _validate_range(item, "calories_kcal", "calories_min_kcal", "calories_max_kcal")
            for key in ("protein_g", "fat_g", "carbs_g"):
                _validate_optional_number(item.get(key), key)
        meal_rating = payload.get("meal_rating")
        if meal_rating is not None and (
            isinstance(meal_rating, bool)
            or not isinstance(meal_rating, int)
            or not 1 <= meal_rating <= 10
        ):
            raise EventValidationError("meal_rating must be 1-10 or null")
        if any(base not in FOOD_BASES for base in payload.get("food_bases") or []):
            raise EventValidationError("food_bases contains an invalid value")
    if event_type == "sleep" and not draft.get("question"):
        sleep = payload.get("sleep") or {}
        if sleep.get("duration_minutes") is None:
            raise EventValidationError("final sleep draft needs duration_minutes")
        _validate_optional_number(sleep.get("duration_minutes"), "duration_minutes", minimum=0)
        _validate_score(sleep.get("quality_score"), "quality_score", 5)
        _validate_score(sleep.get("morning_energy_score"), "morning_energy_score", 5)
    if event_type == "workout" and not draft.get("question"):
        workout = payload.get("workout") or {}
        if workout.get("duration_minutes") is None:
            raise EventValidationError("final workout draft needs duration_minutes")
        _validate_optional_number(workout.get("duration_minutes"), "duration_minutes", minimum=0.1)
        _validate_score(workout.get("perceived_exertion"), "perceived_exertion", 10)
    if event_type == "daily_checkin" and not draft.get("question"):
        checkin = payload.get("daily_checkin")
        if not isinstance(checkin, dict):
            raise EventValidationError("final daily_checkin draft needs payload")
        for key in ("day_rating", "energy_score", "mood_score", "stress_score", "digestion_score"):
            _validate_score(checkin.get(key), key, 5)
        if not checkin.get("day_complete") and not any(
            checkin.get(key) is not None
            for key in (
                "day_rating",
                "energy_score",
                "mood_score",
                "stress_score",
                "digestion_score",
                "water_ml",
                "caffeine_servings",
                "caffeine_last_at",
                "alcohol_units",
            )
        ):
            raise EventValidationError("daily_checkin draft contains no data")
    if event_type == "expense" and not draft.get("question"):
        expense = payload.get("expense") or {}
        if expense.get("amount_rub") is None:
            raise EventValidationError("final expense draft needs amount_rub")
        _validate_optional_number(expense.get("amount_rub"), "amount_rub", minimum=0)
        if expense.get("category") is not None and expense.get("category") not in EXPENSE_CATEGORIES:
            raise EventValidationError("expense category is invalid")
    if event_type == "unknown" and not draft.get("question"):
        raise EventValidationError("unknown draft must ask a question")
    if draft.get("confidence") not in CONFIDENCE_LEVELS:
        raise EventValidationError("draft confidence is invalid")
    return draft


def _validate_range(item: dict[str, Any], central_key: str, low_key: str, high_key: str) -> None:
    central = item.get(central_key)
    low = item.get(low_key)
    high = item.get(high_key)
    values = [value for value in (central, low, high) if value is not None]
    if any(isinstance(value, bool) or not isinstance(value, (int, float)) or value < 0 for value in values):
        raise EventValidationError(f"invalid numeric range for {central_key}")
    if low is not None and high is not None and low > high:
        raise EventValidationError(f"{low_key} exceeds {high_key}")
    if central is not None and low is not None and central < low:
        raise EventValidationError(f"{central_key} is below {low_key}")
    if central is not None and high is not None and central > high:
        raise EventValidationError(f"{central_key} exceeds {high_key}")


def _validate_optional_number(
    value: Any, field: str, *, minimum: float = 0, maximum: float | None = None
) -> None:
    if value is None:
        return
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise EventValidationError(f"{field} must be numeric or null")
    if value < minimum or (maximum is not None and value > maximum):
        raise EventValidationError(f"{field} is outside the allowed range")


def _validate_score(value: Any, field: str, maximum: int) -> None:
    if value is None:
        return
    if isinstance(value, bool) or not isinstance(value, int) or not 1 <= value <= maximum:
        raise EventValidationError(f"{field} must be 1-{maximum} or null")
