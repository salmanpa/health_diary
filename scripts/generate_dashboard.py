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
BASELINE_WEIGHT_KG = 64.0


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
                s.workout_calories_kcal,
                s.sleep_minutes,
                s.sleep_quality,
                s.food_bases,
                s.day_rating,
                (SELECT COUNT(*) FROM nutrition_entries AS n
                 WHERE n.calendar_day_id = d.id) AS nutrition_entry_count,
                (SELECT COUNT(DISTINCT n.meal_type) FROM nutrition_entries AS n
                 WHERE n.calendar_day_id = d.id) AS meal_type_count,
                (SELECT COUNT(*) FROM nutrition_entries AS n
                 WHERE n.calendar_day_id = d.id
                   AND n.calories_kcal > 0
                   AND n.protein_g = 0
                   AND n.fat_g = 0
                   AND n.carbs_g = 0) AS incomplete_macro_entry_count,
                (SELECT COUNT(*) FROM nutrition_entries AS n
                 WHERE n.calendar_day_id = d.id
                   AND (n.notes LIKE '%оцен%' OR n.notes LIKE '%предполож%'))
                    AS estimated_nutrition_entry_count,
                EXISTS(SELECT 1 FROM sleep_entries AS sl
                       WHERE sl.calendar_day_id = d.id) AS has_sleep,
                EXISTS(SELECT 1 FROM workouts AS w
                       WHERE w.calendar_day_id = d.id) AS has_workout,
                EXISTS(SELECT 1 FROM daily_ratings AS r
                       WHERE r.calendar_day_id = d.id) AS has_rating
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
                w.time_of_day,
                w.duration_minutes,
                w.distance_km,
                w.average_pace_seconds_per_km,
                w.calories_burned_kcal,
                w.notes
            FROM workouts AS w
            JOIN calendar_days AS d ON d.id = w.calendar_day_id
            ORDER BY d.diary_date, w.id
            """
        )
    )

    for workout in workouts:
        reported = workout["calories_burned_kcal"]
        duration = float(workout["duration_minutes"] or 0)
        distance = float(workout["distance_km"] or 0)
        if reported is not None:
            workout["energy_kcal"] = round(float(reported), 1)
            workout["energy_source"] = "reported"
        elif workout["workout_type"] == "running" and duration > 0 and distance > 0:
            speed_m_per_min = distance * 1000 / duration
            oxygen_ml_per_kg_min = 0.2 * speed_m_per_min + 3.5
            workout["energy_kcal"] = round(
                oxygen_ml_per_kg_min * BASELINE_WEIGHT_KG / 200 * duration,
                1,
            )
            workout["energy_source"] = "estimated_level_running"
        else:
            workout["energy_kcal"] = None
            workout["energy_source"] = "unknown"

    nutrients = rows_as_dicts(
        connection.execute(
            """
            SELECT *
            FROM daily_nutrient_summary
            ORDER BY diary_date
            """
        )
    )

    nutrient_references = rows_as_dicts(
        connection.execute(
            """
            SELECT *
            FROM nutrient_reference_values
            ORDER BY sort_order
            """
        )
    )

    components = rows_as_dicts(
        connection.execute(
            """
            SELECT
                d.diary_date,
                n.meal_type,
                c.component_name,
                c.estimated_weight_g,
                c.confidence,
                p.fdc_id,
                p.food_name AS reference_food_name,
                ROUND(c.estimated_weight_g * p.fiber_g_per_100g / 100.0, 3) AS fiber_g,
                ROUND(c.estimated_weight_g * p.calcium_mg_per_100g / 100.0, 2) AS calcium_mg,
                ROUND(c.estimated_weight_g * p.iron_mg_per_100g / 100.0, 3) AS iron_mg,
                ROUND(c.estimated_weight_g * p.magnesium_mg_per_100g / 100.0, 2) AS magnesium_mg,
                ROUND(c.estimated_weight_g * p.potassium_mg_per_100g / 100.0, 2) AS potassium_mg,
                ROUND(c.estimated_weight_g * p.sodium_mg_per_100g / 100.0, 2) AS sodium_mg,
                ROUND(c.estimated_weight_g * p.vitamin_c_mg_per_100g / 100.0, 2) AS vitamin_c_mg,
                ROUND(c.estimated_weight_g * p.vitamin_d_mcg_per_100g / 100.0, 3) AS vitamin_d_mcg,
                ROUND(c.estimated_weight_g * p.vitamin_b12_mcg_per_100g / 100.0, 3) AS vitamin_b12_mcg,
                ROUND(c.estimated_weight_g * p.folate_dfe_mcg_per_100g / 100.0, 2) AS folate_dfe_mcg,
                ROUND(c.estimated_weight_g * p.omega3_g_per_100g / 100.0, 4) AS omega3_g
            FROM nutrition_components AS c
            JOIN nutrition_entries AS n ON n.id = c.nutrition_entry_id
            JOIN calendar_days AS d ON d.id = n.calendar_day_id
            LEFT JOIN food_reference_profiles AS p
              ON p.fdc_id = c.reference_fdc_id
            ORDER BY d.diary_date, n.id, c.id
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
            "baseline_weight_kg": BASELINE_WEIGHT_KG,
        },
        "daily": daily,
        "meals": meals,
        "workouts": workouts,
        "nutrients": nutrients,
        "nutrient_references": nutrient_references,
        "components": components,
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
