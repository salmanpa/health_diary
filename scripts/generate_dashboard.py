#!/usr/bin/env python3
"""Build the dashboard data bundle from the local health diary database."""

from __future__ import annotations

import argparse
import json
import sqlite3
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_DATABASE = PROJECT_DIR / "data" / "health_diary.sqlite3"
DEFAULT_OUTPUT = PROJECT_DIR / "dashboard" / "data.js"


def rows_as_dicts(cursor: sqlite3.Cursor) -> list[dict[str, object]]:
    return [dict(row) for row in cursor.fetchall()]


def build_payload(database: Path) -> dict[str, object]:
    connection = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row

    daily = rows_as_dicts(
        connection.execute(
            """
            SELECT
                s.diary_date,
                s.status,
                s.calories_kcal,
                s.protein_g,
                s.fat_g,
                s.carbs_g,
                s.workout_count,
                s.workout_minutes,
                s.distance_km,
                s.sleep_minutes,
                s.sleep_quality,
                s.food_bases,
                s.day_rating,
                s.expenses_rub,
                (SELECT COUNT(*) FROM nutrition_entries AS n
                 WHERE n.calendar_day_id = d.id) AS nutrition_entry_count,
                (SELECT COUNT(DISTINCT n.meal_type) FROM nutrition_entries AS n
                 WHERE n.calendar_day_id = d.id) AS meal_type_count,
                EXISTS(SELECT 1 FROM sleep_entries AS sl
                       WHERE sl.calendar_day_id = d.id) AS has_sleep,
                EXISTS(SELECT 1 FROM workouts AS w
                       WHERE w.calendar_day_id = d.id) AS has_workout,
                EXISTS(SELECT 1 FROM daily_ratings AS r
                       WHERE r.calendar_day_id = d.id) AS has_rating,
                EXISTS(SELECT 1 FROM expenses AS e
                       WHERE e.calendar_day_id = d.id) AS has_expenses
            FROM daily_health_summary AS s
            JOIN calendar_days AS d ON d.diary_date = s.diary_date
            ORDER BY s.diary_date
            """
        )
    )

    meals = rows_as_dicts(
        connection.execute(
            """
            SELECT
                d.diary_date,
                n.meal_type,
                ROUND(SUM(n.calories_kcal), 1) AS calories_kcal,
                ROUND(SUM(n.protein_g), 1) AS protein_g,
                ROUND(SUM(n.fat_g), 1) AS fat_g,
                ROUND(SUM(n.carbs_g), 1) AS carbs_g,
                GROUP_CONCAT(n.food_name, ' • ') AS foods
            FROM nutrition_entries AS n
            JOIN calendar_days AS d ON d.id = n.calendar_day_id
            GROUP BY d.diary_date, n.meal_type
            ORDER BY d.diary_date, n.meal_type
            """
        )
    )

    workouts = rows_as_dicts(
        connection.execute(
            """
            SELECT
                d.diary_date,
                w.workout_type,
                w.duration_minutes,
                w.distance_km,
                w.average_pace_seconds_per_km,
                w.calories_burned_kcal
            FROM workouts AS w
            JOIN calendar_days AS d ON d.id = w.calendar_day_id
            ORDER BY d.diary_date, w.id
            """
        )
    )

    food_bases = rows_as_dicts(
        connection.execute(
            """
            SELECT b.base_type, COUNT(*) AS day_count
            FROM daily_food_bases AS b
            GROUP BY b.base_type
            ORDER BY b.base_type
            """
        )
    )

    quality = rows_as_dicts(
        connection.execute(
            """
            SELECT
                SUBSTR(d.diary_date, 1, 7) AS diary_month,
                COUNT(*) AS nutrition_entries,
                SUM(CASE WHEN n.notes LIKE '%оцен%' OR n.notes LIKE '%предполож%'
                         THEN 1 ELSE 0 END) AS estimated_entries,
                SUM(CASE WHEN protein_g = 0 AND fat_g = 0 AND carbs_g = 0
                         THEN 1 ELSE 0 END) AS incomplete_macro_entries
            FROM nutrition_entries AS n
            JOIN calendar_days AS d ON d.id = n.calendar_day_id
            GROUP BY SUBSTR(d.diary_date, 1, 7)
            """
        )
    )

    connection.close()
    months = sorted({str(day["diary_date"])[:7] for day in daily})
    return {
        "meta": {
            "months": months,
            "latest_date": daily[-1]["diary_date"] if daily else None,
        },
        "daily": daily,
        "meals": meals,
        "workouts": workouts,
        "food_bases": food_bases,
        "quality": quality,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, default=DEFAULT_DATABASE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    if not args.database.exists():
        raise SystemExit(
            f"Database not found: {args.database}. Run ./scripts/init_db.sh first."
        )

    payload = build_payload(args.database)
    serialized = json.dumps(payload, ensure_ascii=False, indent=2)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        "// Generated by scripts/generate_dashboard.py; do not edit.\n"
        f"window.HEALTH_DIARY_DATA = {serialized};\n",
        encoding="utf-8",
    )
    print(f"Dashboard data generated: {args.output}")


if __name__ == "__main__":
    main()
