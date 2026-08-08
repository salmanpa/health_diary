from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path

from healthbot.events import EventProjector, EventStore, iter_events


PROJECT_DIR = Path(__file__).resolve().parent.parent


def event(event_id: str, event_type: str, payload: dict, diary_date: str = "2026-08-09") -> dict:
    return {
        "event_id": event_id,
        "event_type": event_type,
        "diary_date": diary_date,
        "occurred_at": "12:30",
        "received_at": datetime.now(timezone.utc).isoformat(),
        "source": "test",
        "raw_text": "test",
        "payload": payload,
        "analysis": {
            "summary_ru": "Тестовая запись.",
            "confidence": "medium",
            "uncertainty_drivers": ["масса"],
        },
    }


class EventProjectionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.database = self.root / "health.sqlite3"
        connection = sqlite3.connect(self.database)
        connection.executescript((PROJECT_DIR / "db" / "schema.sql").read_text(encoding="utf-8"))
        connection.close()
        self.events_dir = self.root / "events"
        self.store = EventStore(self.events_dir)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def project(self) -> None:
        EventProjector(self.database).project_directory(self.events_dir)

    def test_nutrition_projection_is_idempotent(self) -> None:
        nutrition = event(
            "event-nutrition-1",
            "nutrition",
            {
                "meal_type": "lunch",
                "meal_rating": 8,
                "food_bases": ["fish"],
                "nutrition_items": [
                    {
                        "food_name": "Лосось",
                        "weight_g": 200,
                        "weight_min_g": 180,
                        "weight_max_g": 220,
                        "calories_kcal": 416,
                        "calories_min_kcal": 370,
                        "calories_max_kcal": 460,
                        "protein_g": 40,
                        "fat_g": 28,
                        "carbs_g": 0,
                        "notes": "Оценка по фото.",
                    },
                    {
                        "food_name": "Фасоль",
                        "weight_g": 150,
                        "weight_min_g": 120,
                        "weight_max_g": 180,
                        "calories_kcal": 50,
                        "calories_min_kcal": 40,
                        "calories_max_kcal": 65,
                        "protein_g": 3,
                        "fat_g": 0.5,
                        "carbs_g": 9,
                        "notes": "Без соуса.",
                    },
                ],
            },
        )
        self.store.append(nutrition)
        self.store.append(nutrition)
        first = EventProjector(self.database).project_directory(self.events_dir)
        second = EventProjector(self.database).project_directory(self.events_dir)
        self.assertEqual((first.imported, first.skipped), (1, 0))
        self.assertEqual((second.imported, second.skipped), (0, 1))
        connection = sqlite3.connect(self.database)
        self.assertEqual(connection.execute("SELECT COUNT(*) FROM health_events").fetchone()[0], 1)
        self.assertEqual(connection.execute("SELECT COUNT(*) FROM nutrition_entries").fetchone()[0], 2)
        self.assertEqual(connection.execute("SELECT COUNT(*) FROM daily_food_bases").fetchone()[0], 1)
        total = connection.execute(
            "SELECT calories_kcal FROM daily_health_summary WHERE diary_date = '2026-08-09'"
        ).fetchone()[0]
        self.assertEqual(total, 466.0)
        connection.close()

    def test_sleep_and_completed_checkin(self) -> None:
        self.store.append(
            event(
                "event-sleep-1",
                "sleep",
                {
                    "sleep": {
                        "sleep_started_at": "00:30",
                        "sleep_ended_at": "07:00",
                        "duration_minutes": 390,
                        "quality_score": 4,
                        "awakenings_count": 1,
                        "morning_energy_score": 3,
                    }
                },
            )
        )
        self.store.append(
            event(
                "event-checkin-1",
                "daily_checkin",
                {
                    "daily_checkin": {
                        "day_rating": 5,
                        "energy_score": 4,
                        "mood_score": 5,
                        "stress_score": 2,
                        "digestion_score": 4,
                        "water_ml": 2000,
                        "caffeine_servings": 2,
                        "caffeine_last_at": "15:00",
                        "alcohol_units": 0,
                        "day_complete": True,
                    }
                },
            )
        )
        self.project()
        connection = sqlite3.connect(self.database)
        row = connection.execute(
            "SELECT status, sleep_minutes, sleep_quality, day_rating, energy_score, water_ml "
            "FROM daily_health_summary WHERE diary_date = '2026-08-09'"
        ).fetchone()
        self.assertEqual(row, ("complete", 390, 4, 5, 4, 2000))
        connection.close()

    def test_expenses_are_aggregated_by_category(self) -> None:
        for index, amount in enumerate((100, 250), start=1):
            self.store.append(
                event(
                    f"event-expense-{index}",
                    "expense",
                    {"expense": {"category": "groceries", "amount_rub": amount, "notes": "Еда"}},
                )
            )
        self.project()
        connection = sqlite3.connect(self.database)
        self.assertEqual(connection.execute("SELECT amount_rub FROM expenses").fetchone()[0], 350)
        connection.close()

    def test_jsonl_round_trip(self) -> None:
        original = event(
            "event-workout-1",
            "workout",
            {
                "workout": {
                    "workout_type": "running",
                    "duration_minutes": 30,
                    "distance_km": 5,
                }
            },
        )
        path = self.store.append(original)
        self.assertEqual(path.name, "2026-08-09.jsonl")
        loaded = list(iter_events(self.events_dir))
        self.assertEqual(loaded[0]["event_id"], original["event_id"])
        json.loads(path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
