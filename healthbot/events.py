"""Append-only health events and their idempotent SQLite projection."""

from __future__ import annotations

import json
import os
import sqlite3
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import Any, Iterable, Iterator


EVENT_TYPES = {"nutrition", "sleep", "workout", "daily_checkin", "expense"}
MEAL_TYPES = {"breakfast", "lunch", "dinner", "snack"}
FOOD_BASES = {"meat", "chicken", "fish"}
EXPENSE_CATEGORIES = {"groceries", "home", "transport", "other"}
CONFIDENCE_LEVELS = {"high", "medium", "low"}


class EventValidationError(ValueError):
    """Raised when an event cannot be safely projected."""


@dataclass(frozen=True)
class ProjectionResult:
    imported: int = 0
    skipped: int = 0


def _iso_date(value: Any, field: str = "diary_date") -> str:
    if not isinstance(value, str):
        raise EventValidationError(f"{field} must be an ISO date string")
    try:
        return date.fromisoformat(value).isoformat()
    except ValueError as exc:
        raise EventValidationError(f"invalid {field}: {value}") from exc


def _optional_time(value: Any, field: str) -> str | None:
    if value in (None, ""):
        return None
    if not isinstance(value, str):
        raise EventValidationError(f"{field} must be HH:MM or null")
    try:
        return datetime.strptime(value, "%H:%M").strftime("%H:%M")
    except ValueError as exc:
        raise EventValidationError(f"invalid {field}: {value}") from exc


def _number(
    value: Any,
    field: str,
    *,
    minimum: float = 0,
    maximum: float | None = None,
    required: bool = False,
) -> float | None:
    if value is None:
        if required:
            raise EventValidationError(f"{field} is required")
        return None
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise EventValidationError(f"{field} must be numeric or null")
    numeric = float(value)
    if numeric < minimum or (maximum is not None and numeric > maximum):
        raise EventValidationError(f"{field} is outside the allowed range")
    return numeric


def validate_event(event: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(event, dict):
        raise EventValidationError("event must be a JSON object")
    event_id = event.get("event_id")
    if not isinstance(event_id, str) or not (8 <= len(event_id) <= 100):
        raise EventValidationError("event_id must be an 8-100 character string")
    if not all(character.isalnum() or character in "-_" for character in event_id):
        raise EventValidationError("event_id contains unsupported characters")
    event_type = event.get("event_type")
    if event_type not in EVENT_TYPES:
        raise EventValidationError(f"unsupported event_type: {event_type}")
    event["diary_date"] = _iso_date(event.get("diary_date"))
    event["occurred_at"] = _optional_time(event.get("occurred_at"), "occurred_at")
    received_at = event.get("received_at")
    if not isinstance(received_at, str):
        raise EventValidationError("received_at is required")
    try:
        datetime.fromisoformat(received_at.replace("Z", "+00:00"))
    except ValueError as exc:
        raise EventValidationError("received_at must be an ISO datetime") from exc
    source = event.get("source")
    if not isinstance(source, str) or not source:
        raise EventValidationError("source is required")
    payload = event.get("payload")
    if not isinstance(payload, dict):
        raise EventValidationError("payload must be an object")
    return event


def iter_events(events_dir: Path) -> Iterator[dict[str, Any]]:
    if not events_dir.exists():
        return
    for path in sorted(events_dir.glob("*.jsonl")):
        with path.open(encoding="utf-8") as stream:
            for line_number, line in enumerate(stream, start=1):
                if not line.strip():
                    continue
                try:
                    event = json.loads(line)
                    yield validate_event(event)
                except (json.JSONDecodeError, EventValidationError) as exc:
                    raise EventValidationError(f"{path}:{line_number}: {exc}") from exc


class EventStore:
    def __init__(self, events_dir: Path) -> None:
        self.events_dir = events_dir

    def append(self, event: dict[str, Any]) -> Path:
        event = validate_event(event)
        self.events_dir.mkdir(parents=True, exist_ok=True)
        path = self.events_dir / f"{event['diary_date']}.jsonl"
        if path.exists():
            with path.open(encoding="utf-8") as stream:
                for line in stream:
                    if line.strip() and json.loads(line).get("event_id") == event["event_id"]:
                        return path
        serialized = json.dumps(event, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        with path.open("a", encoding="utf-8") as stream:
            stream.write(serialized + "\n")
            stream.flush()
            os.fsync(stream.fileno())
        return path


class EventProjector:
    def __init__(self, database: Path) -> None:
        self.database = database

    def project(self, events: Iterable[dict[str, Any]]) -> ProjectionResult:
        connection = sqlite3.connect(self.database)
        connection.execute("PRAGMA foreign_keys = ON")
        imported = 0
        skipped = 0
        try:
            for event in events:
                event = validate_event(event)
                if connection.execute(
                    "SELECT 1 FROM health_events WHERE event_id = ?", (event["event_id"],)
                ).fetchone():
                    skipped += 1
                    continue
                with connection:
                    day_id = self._ensure_day(connection, event["diary_date"])
                    connection.execute(
                        """
                        INSERT INTO health_events (
                            event_id, calendar_day_id, event_type, occurred_at,
                            received_at, source, payload_json
                        ) VALUES (?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            event["event_id"],
                            day_id,
                            event["event_type"],
                            event.get("occurred_at"),
                            event["received_at"],
                            event["source"],
                            json.dumps(event, ensure_ascii=False, sort_keys=True),
                        ),
                    )
                    handler = getattr(self, f"_project_{event['event_type']}")
                    handler(connection, day_id, event)
                imported += 1
        finally:
            connection.close()
        return ProjectionResult(imported=imported, skipped=skipped)

    def project_directory(self, events_dir: Path) -> ProjectionResult:
        return self.project(iter_events(events_dir))

    @staticmethod
    def _ensure_day(connection: sqlite3.Connection, diary_date: str) -> int:
        connection.execute(
            "INSERT INTO calendar_days (diary_date) VALUES (?) ON CONFLICT DO NOTHING",
            (diary_date,),
        )
        row = connection.execute(
            "SELECT id FROM calendar_days WHERE diary_date = ?", (diary_date,)
        ).fetchone()
        if row is None:
            raise EventValidationError(f"could not create calendar day {diary_date}")
        return int(row[0])

    @staticmethod
    def _analysis_notes(event: dict[str, Any]) -> str:
        analysis = event.get("analysis") or {}
        fragments: list[str] = []
        summary = analysis.get("summary_ru")
        if summary:
            fragments.append(str(summary))
        uncertainty = analysis.get("uncertainty_drivers") or []
        if uncertainty:
            fragments.append("Неопределённость: " + "; ".join(map(str, uncertainty)))
        return " ".join(fragments)

    def _project_nutrition(
        self, connection: sqlite3.Connection, day_id: int, event: dict[str, Any]
    ) -> None:
        payload = event["payload"]
        meal_type = payload.get("meal_type")
        if meal_type not in MEAL_TYPES:
            raise EventValidationError("nutrition payload needs a valid meal_type")
        items = payload.get("nutrition_items")
        if not isinstance(items, list) or not items:
            raise EventValidationError("nutrition payload needs at least one item")
        meal_rating = _number(
            payload.get("meal_rating"), "meal_rating", minimum=1, maximum=10
        )
        confidence = event.get("analysis", {}).get("confidence")
        if confidence not in CONFIDENCE_LEVELS:
            confidence = "low"
        shared_notes = self._analysis_notes(event)

        for index, item in enumerate(items):
            if not isinstance(item, dict) or not str(item.get("food_name") or "").strip():
                raise EventValidationError("every nutrition item needs food_name")
            weight = _number(item.get("weight_g"), "weight_g")
            weight_min = _number(item.get("weight_min_g"), "weight_min_g")
            weight_max = _number(item.get("weight_max_g"), "weight_max_g")
            calories = _number(item.get("calories_kcal"), "calories_kcal")
            calories_min = _number(item.get("calories_min_kcal"), "calories_min_kcal")
            calories_max = _number(item.get("calories_max_kcal"), "calories_max_kcal")
            protein = _number(item.get("protein_g"), "protein_g")
            fat = _number(item.get("fat_g"), "fat_g")
            carbs = _number(item.get("carbs_g"), "carbs_g")
            unknown: list[str] = []
            for name, value in (("калории", calories), ("белки", protein), ("жиры", fat), ("углеводы", carbs)):
                if value is None:
                    unknown.append(name)
            notes = [str(item.get("notes") or "").strip(), shared_notes]
            if unknown:
                notes.append("Неизвестные значения записаны как 0: " + ", ".join(unknown) + ".")
            connection.execute(
                """
                INSERT INTO nutrition_entries (
                    calendar_day_id, meal_type, eaten_at, food_name,
                    weight_g, weight_min_g, weight_max_g,
                    calories_kcal, calories_min_kcal, calories_max_kcal,
                    protein_g, fat_g, carbs_g, confidence, meal_rating,
                    source_event_id, source_item_index, notes
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    day_id,
                    meal_type,
                    event.get("occurred_at"),
                    str(item["food_name"]).strip(),
                    weight,
                    weight_min,
                    weight_max,
                    calories or 0,
                    calories_min,
                    calories_max,
                    protein or 0,
                    fat or 0,
                    carbs or 0,
                    confidence,
                    int(meal_rating) if meal_rating is not None and index == 0 else None,
                    event["event_id"],
                    index,
                    " ".join(fragment for fragment in notes if fragment),
                ),
            )

        for base in payload.get("food_bases") or []:
            if base not in FOOD_BASES:
                continue
            connection.execute(
                """
                INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
                VALUES (?, ?, ?)
                ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET
                    notes = CASE
                        WHEN INSTR(daily_food_bases.notes, excluded.notes) > 0
                        THEN daily_food_bases.notes
                        ELSE daily_food_bases.notes || ' ' || excluded.notes
                    END
                """,
                (day_id, base, f"Подтверждено событием {event['event_id']}."),
            )

    def _project_sleep(
        self, connection: sqlite3.Connection, day_id: int, event: dict[str, Any]
    ) -> None:
        sleep = event["payload"].get("sleep")
        if not isinstance(sleep, dict):
            raise EventValidationError("sleep payload is required")
        duration = _number(
            sleep.get("duration_minutes"), "duration_minutes", required=True
        )
        quality = _number(sleep.get("quality_score"), "quality_score", minimum=1, maximum=5)
        awakenings = _number(sleep.get("awakenings_count"), "awakenings_count")
        energy = _number(
            sleep.get("morning_energy_score"), "morning_energy_score", minimum=1, maximum=5
        )
        connection.execute(
            """
            INSERT INTO sleep_entries (
                calendar_day_id, sleep_started_at, sleep_ended_at,
                duration_minutes, quality_score, awakenings_count,
                morning_energy_score, source_event_id, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT (calendar_day_id) DO UPDATE SET
                sleep_started_at = excluded.sleep_started_at,
                sleep_ended_at = excluded.sleep_ended_at,
                duration_minutes = excluded.duration_minutes,
                quality_score = COALESCE(excluded.quality_score, sleep_entries.quality_score),
                awakenings_count = COALESCE(excluded.awakenings_count, sleep_entries.awakenings_count),
                morning_energy_score = COALESCE(excluded.morning_energy_score, sleep_entries.morning_energy_score),
                source_event_id = excluded.source_event_id,
                notes = excluded.notes
            """,
            (
                day_id,
                _optional_time(sleep.get("sleep_started_at"), "sleep_started_at"),
                _optional_time(sleep.get("sleep_ended_at"), "sleep_ended_at"),
                int(duration or 0),
                int(quality) if quality is not None else None,
                int(awakenings) if awakenings is not None else None,
                int(energy) if energy is not None else None,
                event["event_id"],
                self._analysis_notes(event),
            ),
        )

    def _project_workout(
        self, connection: sqlite3.Connection, day_id: int, event: dict[str, Any]
    ) -> None:
        workout = event["payload"].get("workout")
        if not isinstance(workout, dict):
            raise EventValidationError("workout payload is required")
        workout_type = str(workout.get("workout_type") or "").strip()
        if not workout_type:
            raise EventValidationError("workout_type is required")
        duration = _number(
            workout.get("duration_minutes"), "duration_minutes", minimum=0.1, required=True
        )
        rpe = _number(workout.get("perceived_exertion"), "perceived_exertion", minimum=1, maximum=10)
        connection.execute(
            """
            INSERT INTO workouts (
                calendar_day_id, workout_type, time_of_day, started_at,
                duration_minutes, distance_km, average_pace_seconds_per_km,
                calories_burned_kcal, perceived_exertion,
                average_heart_rate_bpm, max_heart_rate_bpm,
                source_event_id, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                day_id,
                workout_type,
                workout.get("time_of_day"),
                event.get("occurred_at"),
                duration,
                _number(workout.get("distance_km"), "distance_km"),
                int(_number(workout.get("average_pace_seconds_per_km"), "average_pace_seconds_per_km") or 0) or None,
                _number(workout.get("calories_burned_kcal"), "calories_burned_kcal"),
                int(rpe) if rpe is not None else None,
                int(_number(workout.get("average_heart_rate_bpm"), "average_heart_rate_bpm") or 0) or None,
                int(_number(workout.get("max_heart_rate_bpm"), "max_heart_rate_bpm") or 0) or None,
                event["event_id"],
                self._analysis_notes(event),
            ),
        )

    def _project_daily_checkin(
        self, connection: sqlite3.Connection, day_id: int, event: dict[str, Any]
    ) -> None:
        checkin = event["payload"].get("daily_checkin")
        if not isinstance(checkin, dict):
            raise EventValidationError("daily_checkin payload is required")
        rating = _number(checkin.get("day_rating"), "day_rating", minimum=1, maximum=5)
        notes = self._analysis_notes(event)
        if rating is not None:
            connection.execute(
                """
                INSERT INTO daily_ratings (calendar_day_id, rating, notes)
                VALUES (?, ?, ?)
                ON CONFLICT (calendar_day_id) DO UPDATE SET
                    rating = excluded.rating,
                    notes = excluded.notes
                """,
                (day_id, int(rating), notes),
            )
        wellbeing_fields = {
            "energy_score": _number(checkin.get("energy_score"), "energy_score", minimum=1, maximum=5),
            "mood_score": _number(checkin.get("mood_score"), "mood_score", minimum=1, maximum=5),
            "stress_score": _number(checkin.get("stress_score"), "stress_score", minimum=1, maximum=5),
            "digestion_score": _number(checkin.get("digestion_score"), "digestion_score", minimum=1, maximum=5),
            "water_ml": _number(checkin.get("water_ml"), "water_ml"),
            "caffeine_servings": _number(checkin.get("caffeine_servings"), "caffeine_servings"),
            "alcohol_units": _number(checkin.get("alcohol_units"), "alcohol_units"),
        }
        if any(value is not None for value in wellbeing_fields.values()) or checkin.get("caffeine_last_at"):
            connection.execute(
                """
                INSERT INTO daily_wellbeing (
                    calendar_day_id, energy_score, mood_score, stress_score,
                    digestion_score, water_ml, caffeine_servings,
                    caffeine_last_at, alcohol_units, source_event_id, notes
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT (calendar_day_id) DO UPDATE SET
                    energy_score = COALESCE(excluded.energy_score, daily_wellbeing.energy_score),
                    mood_score = COALESCE(excluded.mood_score, daily_wellbeing.mood_score),
                    stress_score = COALESCE(excluded.stress_score, daily_wellbeing.stress_score),
                    digestion_score = COALESCE(excluded.digestion_score, daily_wellbeing.digestion_score),
                    water_ml = COALESCE(excluded.water_ml, daily_wellbeing.water_ml),
                    caffeine_servings = COALESCE(excluded.caffeine_servings, daily_wellbeing.caffeine_servings),
                    caffeine_last_at = COALESCE(excluded.caffeine_last_at, daily_wellbeing.caffeine_last_at),
                    alcohol_units = COALESCE(excluded.alcohol_units, daily_wellbeing.alcohol_units),
                    source_event_id = excluded.source_event_id,
                    notes = excluded.notes
                """,
                (
                    day_id,
                    wellbeing_fields["energy_score"],
                    wellbeing_fields["mood_score"],
                    wellbeing_fields["stress_score"],
                    wellbeing_fields["digestion_score"],
                    wellbeing_fields["water_ml"],
                    wellbeing_fields["caffeine_servings"],
                    _optional_time(checkin.get("caffeine_last_at"), "caffeine_last_at"),
                    wellbeing_fields["alcohol_units"],
                    event["event_id"],
                    notes,
                ),
            )
        if checkin.get("day_complete") is True:
            connection.execute(
                "UPDATE calendar_days SET status = 'complete' WHERE id = ?", (day_id,)
            )

    def _project_expense(
        self, connection: sqlite3.Connection, day_id: int, event: dict[str, Any]
    ) -> None:
        expense = event["payload"].get("expense")
        if not isinstance(expense, dict):
            raise EventValidationError("expense payload is required")
        amount = _number(expense.get("amount_rub"), "amount_rub", required=True)
        category = expense.get("category")
        if category is not None and category not in EXPENSE_CATEGORIES:
            raise EventValidationError("invalid expense category")
        notes = str(expense.get("notes") or self._analysis_notes(event))
        if category is None:
            row = connection.execute(
                "SELECT id, amount_rub FROM expenses WHERE calendar_day_id = ? AND category IS NULL",
                (day_id,),
            ).fetchone()
            if row:
                connection.execute(
                    "UPDATE expenses SET amount_rub = ?, notes = ? WHERE id = ?",
                    (float(row[1]) + float(amount or 0), notes, row[0]),
                )
            else:
                connection.execute(
                    "INSERT INTO expenses (calendar_day_id, category, amount_rub, notes) VALUES (?, NULL, ?, ?)",
                    (day_id, amount, notes),
                )
        else:
            connection.execute(
                """
                INSERT INTO expenses (calendar_day_id, category, amount_rub, notes)
                VALUES (?, ?, ?, ?)
                ON CONFLICT (calendar_day_id, category) DO UPDATE SET
                    amount_rub = expenses.amount_rub + excluded.amount_rub,
                    notes = excluded.notes
                """,
                (day_id, category, amount, notes),
            )
