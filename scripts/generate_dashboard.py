#!/usr/bin/env python3
"""Generate the private, versioned DashboardSnapshotV2 JSON bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
import sqlite3
import subprocess
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any, Iterable
from zoneinfo import ZoneInfo


PROJECT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_DATABASE = PROJECT_DIR / "data" / "health_diary.sqlite3"
DEFAULT_OUTPUT = PROJECT_DIR / "dashboard-src" / "data" / "snapshot.json"
TIMEZONE = "Europe/Moscow"
CONTRACT_VERSION = "2.0"
SCHEMA_VERSION = "2"
CALCULATION_VERSION = "2.0.0"
BASELINE_WEIGHT_KG = 64.0

NUTRIENT_COLUMNS = {
    "fiber_g": "fiber_g_per_100g",
    "calcium_mg": "calcium_mg_per_100g",
    "iron_mg": "iron_mg_per_100g",
    "magnesium_mg": "magnesium_mg_per_100g",
    "potassium_mg": "potassium_mg_per_100g",
    "sodium_mg": "sodium_mg_per_100g",
    "vitamin_c_mg": "vitamin_c_mg_per_100g",
    "vitamin_d_mcg": "vitamin_d_mcg_per_100g",
    "vitamin_b12_mcg": "vitamin_b12_mcg_per_100g",
    "folate_dfe_mcg": "folate_dfe_mcg_per_100g",
    "omega3_g": "omega3_g_per_100g",
}

SHORT_NUTRIENT_LABELS = {
    "fiber_g": "Клетчатка",
    "calcium_mg": "Ca",
    "iron_mg": "Fe",
    "magnesium_mg": "Mg",
    "potassium_mg": "K",
    "sodium_mg": "Na",
    "vitamin_c_mg": "C",
    "vitamin_d_mcg": "D",
    "vitamin_b12_mcg": "B12",
    "folate_dfe_mcg": "Фолат",
    "omega3_g": "ω-3",
}

CONFIDENCE_ORDER = {"unknown": 0, "low": 1, "medium": 2, "high": 3}


def rows_as_dicts(cursor: sqlite3.Cursor) -> list[dict[str, Any]]:
    return [dict(row) for row in cursor.fetchall()]


def round_or_none(value: Any, digits: int = 1) -> float | None:
    if value is None:
        return None
    return round(float(value), digits)


def weakest_confidence(values: Iterable[str | None]) -> str:
    normalized = [value if value in CONFIDENCE_ORDER else "unknown" for value in values]
    return min(normalized, key=CONFIDENCE_ORDER.get) if normalized else "unknown"


def ratio_coverage(covered: float | int, total: float | int, digits: int = 1) -> dict[str, Any]:
    percent = round(float(covered) / float(total) * 100.0, digits) if total else None
    return {"covered": covered, "total": total, "percent": percent}


def metric(
    value: float | int | None,
    unit: str,
    *,
    value_status: str | None = None,
    provenance: str = "unknown",
    completeness: str = "complete",
    confidence: str = "unknown",
    source: str | None = None,
    low: float | None = None,
    high: float | None = None,
    coverage: dict[str, Any] | None = None,
    included: int = 0,
    total: int = 1,
) -> dict[str, Any]:
    if value_status is None:
        value_status = "missing" if value is None else "present"
    return {
        "value": value,
        "low": low,
        "high": high,
        "unit": unit,
        "valueStatus": value_status,
        "provenance": provenance,
        "completeness": completeness,
        "confidence": confidence,
        "source": source,
        "coverage": coverage,
        "n": {"included": included, "total": total},
    }


def missing_metric(unit: str) -> dict[str, Any]:
    return metric(None, unit, included=0, total=1)


def enumerate_dates(first: str, last: str) -> list[str]:
    start = date.fromisoformat(first)
    end = date.fromisoformat(last)
    return [(start + timedelta(days=offset)).isoformat() for offset in range((end - start).days + 1)]


def source_commit() -> str | None:
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=PROJECT_DIR,
        check=False,
        capture_output=True,
        text=True,
    )
    value = result.stdout.strip()
    return value if result.returncode == 0 and value else None


def source_hash() -> str:
    digest = hashlib.sha256()
    for relative_path in (
        "db/schema.sql",
        "db/seed.sql",
        "db/nutrition_components.sql",
        "scripts/generate_dashboard.py",
    ):
        digest.update(relative_path.encode("utf-8"))
        digest.update((PROJECT_DIR / relative_path).read_bytes())
    return digest.hexdigest()


def workout_energy(workout: dict[str, Any]) -> tuple[float | None, str, str | None]:
    reported = workout["calories_burned_kcal"]
    if reported is not None:
        return round(float(reported), 1), "measured", "reported_by_user_or_device"

    duration = float(workout["duration_minutes"] or 0)
    distance = float(workout["distance_km"] or 0)
    if workout["workout_type"] == "running" and duration > 0 and distance > 0:
        speed_m_per_min = distance * 1000.0 / duration
        oxygen_ml_per_kg_min = 0.2 * speed_m_per_min + 3.5
        energy = oxygen_ml_per_kg_min * BASELINE_WEIGHT_KG / 200.0 * duration
        return round(energy, 1), "calculated", "ACSM_level_running_64kg_baseline"
    return None, "unknown", None


def build_payload(
    database: Path,
    *,
    generated_at: str | None = None,
    commit: str | None = None,
) -> dict[str, Any]:
    connection = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row

    calendar_rows = rows_as_dicts(
        connection.execute(
            "SELECT id, diary_date, status FROM calendar_days ORDER BY diary_date"
        )
    )
    nutrition_rows = rows_as_dicts(
        connection.execute(
            """
            SELECT n.id, n.calendar_day_id, d.diary_date, n.meal_type,
                   n.eaten_at, n.food_name, n.weight_g, n.calories_kcal,
                   n.protein_g, n.fat_g, n.carbs_g
            FROM nutrition_entries AS n
            JOIN calendar_days AS d ON d.id = n.calendar_day_id
            ORDER BY d.diary_date, n.id
            """
        )
    )

    profile_select = ",\n                ".join(
        f"p.{column} AS {code}" for code, column in NUTRIENT_COLUMNS.items()
    )
    component_rows = rows_as_dicts(
        connection.execute(
            f"""
            SELECT c.id, c.nutrition_entry_id, d.diary_date, c.component_name,
                   c.estimated_weight_g, c.reference_fdc_id, c.confidence,
                   c.food_group,
                   p.food_name AS profile_name,
                   {profile_select}
            FROM nutrition_components AS c
            JOIN nutrition_entries AS n ON n.id = c.nutrition_entry_id
            JOIN calendar_days AS d ON d.id = n.calendar_day_id
            LEFT JOIN food_reference_profiles AS p ON p.fdc_id = c.reference_fdc_id
            ORDER BY d.diary_date, n.id, c.id
            """
        )
    )
    workout_rows = rows_as_dicts(
        connection.execute(
            """
            SELECT w.id, w.calendar_day_id, d.diary_date, w.workout_type,
                   w.time_of_day, w.started_at, w.duration_minutes, w.distance_km,
                   w.average_pace_seconds_per_km, w.calories_burned_kcal,
                   w.perceived_exertion, w.average_heart_rate_bpm,
                   w.max_heart_rate_bpm
            FROM workouts AS w
            JOIN calendar_days AS d ON d.id = w.calendar_day_id
            ORDER BY d.diary_date, w.id
            """
        )
    )
    sleep_rows = rows_as_dicts(
        connection.execute(
            """
            SELECT s.id, s.calendar_day_id, d.diary_date, s.sleep_started_at,
                   s.sleep_ended_at, s.duration_minutes, s.quality_score
            FROM sleep_entries AS s
            JOIN calendar_days AS d ON d.id = s.calendar_day_id
            ORDER BY d.diary_date
            """
        )
    )
    rating_rows = rows_as_dicts(
        connection.execute(
            """
            SELECT r.id, r.calendar_day_id, d.diary_date, r.rating
            FROM daily_ratings AS r
            JOIN calendar_days AS d ON d.id = r.calendar_day_id
            ORDER BY d.diary_date
            """
        )
    )
    base_rows = rows_as_dicts(
        connection.execute(
            """
            SELECT d.diary_date, b.base_type
            FROM daily_food_bases AS b
            JOIN calendar_days AS d ON d.id = b.calendar_day_id
            ORDER BY d.diary_date, b.base_type
            """
        )
    )
    nutrient_reference_rows = rows_as_dicts(
        connection.execute(
            """
            SELECT nutrient_code, nutrient_name, unit, daily_reference,
                   reference_type, comparison_mode, source_url, sort_order
            FROM nutrient_reference_values
            ORDER BY sort_order
            """
        )
    )
    connection.close()

    if not calendar_rows:
        first_date = last_date = None
        date_axis: list[str] = []
    else:
        first_date = str(calendar_rows[0]["diary_date"])
        last_date = str(calendar_rows[-1]["diary_date"])
        date_axis = enumerate_dates(first_date, last_date)

    calendar_by_date = {row["diary_date"]: row for row in calendar_rows}
    nutrition_by_date: dict[str, list[dict[str, Any]]] = defaultdict(list)
    components_by_entry: dict[int, list[dict[str, Any]]] = defaultdict(list)
    components_by_date: dict[str, list[dict[str, Any]]] = defaultdict(list)
    workouts_by_date: dict[str, list[dict[str, Any]]] = defaultdict(list)
    sleep_by_date = {row["diary_date"]: row for row in sleep_rows}
    rating_by_date = {row["diary_date"]: row for row in rating_rows}
    bases_by_date: dict[str, list[str]] = defaultdict(list)

    for row in nutrition_rows:
        nutrition_by_date[row["diary_date"]].append(row)
    for row in component_rows:
        components_by_entry[int(row["nutrition_entry_id"])].append(row)
        components_by_date[row["diary_date"]].append(row)
    for row in workout_rows:
        workouts_by_date[row["diary_date"]].append(row)
    for row in base_rows:
        bases_by_date[row["diary_date"]].append(row["base_type"])

    meals: list[dict[str, Any]] = []
    for row in nutrition_rows:
        components = components_by_entry[int(row["id"])]
        confidence = weakest_confidence(component["confidence"] for component in components)
        macro_unknown = (
            float(row["calories_kcal"]) > 0
            and float(row["protein_g"]) == 0
            and float(row["fat_g"]) == 0
            and float(row["carbs_g"]) == 0
        )
        component_payload = [
            {
                "id": f"component-{component['id']}",
                "name": component["component_name"],
                "weightG": round_or_none(component["estimated_weight_g"], 1),
                "confidence": component["confidence"],
                "profileName": component["profile_name"],
                "referenceId": component["reference_fdc_id"],
                "linked": component["reference_fdc_id"] is not None,
                "foodGroup": component["food_group"],
            }
            for component in components
        ]
        meals.append(
            {
                "id": f"meal-{row['id']}",
                "date": row["diary_date"],
                "eatenAt": row["eaten_at"],
                "mealType": row["meal_type"],
                "title": row["food_name"],
                "weightG": round_or_none(row["weight_g"], 1),
                "provenance": "estimated",
                "confidence": confidence,
                "energy": metric(
                    round_or_none(row["calories_kcal"], 1),
                    "kcal",
                    provenance="estimated",
                    confidence=confidence,
                    source="nutrition_entries",
                    included=1,
                ),
                "protein": metric(
                    round_or_none(row["protein_g"], 1),
                    "g",
                    provenance="estimated",
                    completeness="known_minimum" if macro_unknown else "complete",
                    confidence=confidence,
                    source="nutrition_entries",
                    included=1,
                ),
                "fat": metric(
                    round_or_none(row["fat_g"], 1),
                    "g",
                    provenance="estimated",
                    completeness="known_minimum" if macro_unknown else "complete",
                    confidence=confidence,
                    source="nutrition_entries",
                    included=1,
                ),
                "carbs": metric(
                    round_or_none(row["carbs_g"], 1),
                    "g",
                    provenance="estimated",
                    completeness="known_minimum" if macro_unknown else "complete",
                    confidence=confidence,
                    source="nutrition_entries",
                    included=1,
                ),
                "components": component_payload,
            }
        )

    workouts: list[dict[str, Any]] = []
    for row in workout_rows:
        energy_value, energy_provenance, energy_method = workout_energy(row)
        workouts.append(
            {
                "id": f"workout-{row['id']}",
                "date": row["diary_date"],
                "type": row["workout_type"],
                "timeOfDay": row["time_of_day"],
                "startedAt": row["started_at"],
                "durationMinutes": round_or_none(row["duration_minutes"], 1),
                "distanceKm": round_or_none(row["distance_km"], 2),
                "paceSecondsPerKm": row["average_pace_seconds_per_km"],
                "rpe": row["perceived_exertion"],
                "averageHeartRate": row["average_heart_rate_bpm"],
                "maximumHeartRate": row["max_heart_rate_bpm"],
                "energy": metric(
                    energy_value,
                    "kcal",
                    provenance=energy_provenance,
                    confidence="high" if energy_provenance == "measured" else "medium" if energy_value is not None else "unknown",
                    source=energy_method,
                    included=1 if energy_value is not None else 0,
                ),
                "energyMethod": energy_method,
            }
        )

    sleep = [
        {
            "id": f"sleep-{row['id']}",
            "date": row["diary_date"],
            "startedAt": row["sleep_started_at"],
            "endedAt": row["sleep_ended_at"],
            "durationMinutes": row["duration_minutes"],
            "quality": row["quality_score"],
            "provenance": "measured",
        }
        for row in sleep_rows
    ]

    nutrient_definitions = [
        {
            "id": row["nutrient_code"],
            "label": row["nutrient_name"],
            "shortLabel": SHORT_NUTRIENT_LABELS.get(row["nutrient_code"], row["nutrient_name"]),
            "unit": row["unit"],
            "mode": row["comparison_mode"],
            "referenceValue": round_or_none(row["daily_reference"], 3),
            "referenceLabel": row["reference_type"],
            "sourceUrl": row["source_url"],
            "sortOrder": row["sort_order"],
        }
        for row in nutrient_reference_rows
    ]

    nutrients: list[dict[str, Any]] = []
    for diary_date in date_axis:
        day_components = components_by_date.get(diary_date, [])
        total_count = len(day_components)
        total_mass = sum(float(component["estimated_weight_g"]) for component in day_components)
        for definition in nutrient_definitions:
            nutrient_id = definition["id"]
            covered = [
                component
                for component in day_components
                if component["reference_fdc_id"] is not None and component[nutrient_id] is not None
            ]
            covered_mass = sum(float(component["estimated_weight_g"]) for component in covered)
            value = sum(
                float(component["estimated_weight_g"]) * float(component[nutrient_id]) / 100.0
                for component in covered
            )
            mass_coverage = ratio_coverage(covered_mass, total_mass) if total_count else None
            count_coverage = ratio_coverage(len(covered), total_count) if total_count else None
            coverage = {
                "count": count_coverage,
                "mass": mass_coverage,
                "energy": None,
            } if total_count else None
            contributor_rows = []
            for component in covered:
                contribution = float(component["estimated_weight_g"]) * float(component[nutrient_id]) / 100.0
                if contribution > 0:
                    contributor_rows.append(
                        {
                            "name": component["component_name"],
                            "value": round(contribution, 3),
                            "unit": definition["unit"],
                        }
                    )
            contributor_rows.sort(key=lambda item: float(item["value"]), reverse=True)
            unknown = sorted(
                (
                    {
                        "name": component["component_name"],
                        "weightG": round_or_none(component["estimated_weight_g"], 1),
                        "confidence": component["confidence"],
                    }
                    for component in day_components
                    if component["reference_fdc_id"] is None or component[nutrient_id] is None
                ),
                key=lambda item: float(item["weightG"] or 0),
                reverse=True,
            )[:5]
            confidence_distribution = {
                level: sum(1 for component in covered if component["confidence"] == level)
                for level in ("high", "medium", "low")
            }
            nutrients.append(
                {
                    "date": diary_date,
                    "nutrientId": nutrient_id,
                    "metric": metric(
                        round(value, 3) if covered else None,
                        definition["unit"],
                        provenance="calculated" if covered else "unknown",
                        completeness="known_minimum" if covered else "complete",
                        confidence=weakest_confidence(component["confidence"] for component in covered),
                        source="food_reference_profiles" if covered else None,
                        coverage=coverage,
                        included=1 if covered else 0,
                    ),
                    "contributors": contributor_rows[:5],
                    "unknownContributors": unknown,
                    "confidenceDistribution": confidence_distribution,
                }
            )

    nutrient_by_date: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for observation in nutrients:
        nutrient_by_date[observation["date"]].append(observation)

    days: list[dict[str, Any]] = []
    for diary_date in date_axis:
        calendar = calendar_by_date.get(diary_date)
        if calendar is None:
            days.append(
                {
                    "date": diary_date,
                    "status": "missing_date",
                    "energy": missing_metric("kcal"),
                    "protein": missing_metric("g"),
                    "fat": missing_metric("g"),
                    "carbs": missing_metric("g"),
                    "sleepMinutes": missing_metric("min"),
                    "workoutCount": missing_metric("count"),
                    "workoutMinutes": missing_metric("min"),
                    "workoutDistance": missing_metric("km"),
                    "rating": missing_metric("score"),
                    "foodBases": [],
                    "completeness": {
                        "nutrition": "missing",
                        "components": "missing",
                        "sleep": "missing",
                        "workout": "missing",
                        "rating": "missing",
                        "overallPercent": None,
                        "reasons": ["Нет записи за дату"],
                    },
                }
            )
            continue

        day_nutrition = nutrition_by_date.get(diary_date, [])
        day_components = components_by_date.get(diary_date, [])
        day_workouts = workouts_by_date.get(diary_date, [])
        day_sleep = sleep_by_date.get(diary_date)
        day_rating = rating_by_date.get(diary_date)
        confidence = weakest_confidence(component["confidence"] for component in day_components)
        macro_unknown = any(
            float(row["calories_kcal"]) > 0
            and float(row["protein_g"]) == 0
            and float(row["fat_g"]) == 0
            and float(row["carbs_g"]) == 0
            for row in day_nutrition
        )

        def nutrition_metric(column: str, unit: str, *, known_minimum: bool = False) -> dict[str, Any]:
            if not day_nutrition:
                return missing_metric(unit)
            return metric(
                round(sum(float(row[column]) for row in day_nutrition), 1),
                unit,
                provenance="estimated",
                completeness="known_minimum" if known_minimum else "complete",
                confidence=confidence,
                source="nutrition_entries",
                included=1,
            )

        workout_count_metric = (
            metric(
                len(day_workouts),
                "count",
                provenance="measured",
                confidence="high",
                source="workouts",
                included=1,
            )
            if day_workouts
            else missing_metric("count")
        )
        workout_minutes_metric = (
            metric(
                round(sum(float(row["duration_minutes"]) for row in day_workouts), 1),
                "min",
                provenance="measured",
                confidence="high",
                source="workouts",
                included=1,
            )
            if day_workouts
            else missing_metric("min")
        )
        known_distances = [float(row["distance_km"]) for row in day_workouts if row["distance_km"] is not None]
        workout_distance_metric = (
            metric(
                round(sum(known_distances), 2),
                "km",
                provenance="measured",
                completeness="known_minimum" if len(known_distances) < len(day_workouts) else "complete",
                confidence="high",
                source="workouts",
                included=1,
            )
            if known_distances
            else missing_metric("km")
        )
        sleep_metric = (
            metric(
                int(day_sleep["duration_minutes"]),
                "min",
                provenance="measured",
                confidence="high",
                source="sleep_entries",
                included=1,
            )
            if day_sleep
            else missing_metric("min")
        )
        rating_metric = (
            metric(
                int(day_rating["rating"]),
                "score",
                provenance="measured",
                confidence="high",
                source="daily_ratings",
                included=1,
            )
            if day_rating
            else missing_metric("score")
        )

        domain_values = [bool(day_nutrition), bool(day_components), bool(day_sleep), bool(day_rating)]
        reasons: list[str] = []
        if not day_nutrition:
            reasons.append("Питание не записано")
        if macro_unknown:
            reasons.append("Часть БЖУ неизвестна; итог — известный минимум")
        if not day_components:
            reasons.append("Компоненты питания отсутствуют")
        if not day_sleep:
            reasons.append("Сон не записан")
        if not day_rating:
            reasons.append("Оценка дня не записана")
        linked_mass = sum(
            float(component["estimated_weight_g"])
            for component in day_components
            if component["reference_fdc_id"] is not None
        )
        total_mass = sum(float(component["estimated_weight_g"]) for component in day_components)
        if total_mass and linked_mass / total_mass < 0.8:
            reasons.append("Покрытие массы микронутриентными профилями ниже 80%")

        days.append(
            {
                "date": diary_date,
                "status": calendar["status"],
                "energy": nutrition_metric("calories_kcal", "kcal"),
                "protein": nutrition_metric("protein_g", "g", known_minimum=macro_unknown),
                "fat": nutrition_metric("fat_g", "g", known_minimum=macro_unknown),
                "carbs": nutrition_metric("carbs_g", "g", known_minimum=macro_unknown),
                "sleepMinutes": sleep_metric,
                "workoutCount": workout_count_metric,
                "workoutMinutes": workout_minutes_metric,
                "workoutDistance": workout_distance_metric,
                "rating": rating_metric,
                "foodBases": bases_by_date.get(diary_date, []),
                "completeness": {
                    "nutrition": "known_minimum" if macro_unknown else "present" if day_nutrition else "missing",
                    "components": "present" if day_components else "missing",
                    "sleep": "present" if day_sleep else "missing",
                    "workout": "present" if day_workouts else "missing",
                    "rating": "present" if day_rating else "missing",
                    "overallPercent": round(sum(domain_values) / len(domain_values) * 100.0, 1),
                    "reasons": reasons,
                },
            }
        )

    confidence_counts = {
        level: sum(1 for component in component_rows if component["confidence"] == level)
        for level in ("high", "medium", "low")
    }
    confidence_counts["unknown"] = sum(
        1 for component in component_rows if component["confidence"] not in ("high", "medium", "low")
    )

    mass_balance: list[dict[str, Any]] = []
    for row in nutrition_rows:
        if row["weight_g"] is None:
            continue
        component_weight = sum(
            float(component["estimated_weight_g"])
            for component in components_by_entry[int(row["id"])]
        )
        entry_weight = float(row["weight_g"])
        difference = component_weight - entry_weight
        if abs(difference) > max(20.0, entry_weight * 0.10):
            mass_balance.append(
                {
                    "entryId": f"meal-{row['id']}",
                    "date": row["diary_date"],
                    "title": row["food_name"],
                    "entryWeightG": round(entry_weight, 1),
                    "componentWeightG": round(component_weight, 1),
                    "differenceG": round(difference, 1),
                }
            )

    unlinked_aggregate: dict[str, dict[str, Any]] = {}
    for component in component_rows:
        if component["reference_fdc_id"] is not None:
            continue
        name = component["component_name"]
        current = unlinked_aggregate.setdefault(
            name,
            {"name": name, "weightG": 0.0, "occurrences": 0, "dates": set()},
        )
        current["weightG"] += float(component["estimated_weight_g"])
        current["occurrences"] += 1
        current["dates"].add(component["diary_date"])
    unlinked_components = sorted(
        (
            {
                "name": item["name"],
                "weightG": round(item["weightG"], 1),
                "occurrences": item["occurrences"],
                "dates": sorted(item["dates"]),
            }
            for item in unlinked_aggregate.values()
        ),
        key=lambda item: float(item["weightG"]),
        reverse=True,
    )

    linked_components = [row for row in component_rows if row["reference_fdc_id"] is not None]
    total_component_mass = sum(float(row["estimated_weight_g"]) for row in component_rows)
    linked_component_mass = sum(float(row["estimated_weight_g"]) for row in linked_components)
    issue_payload = [
        {
            "id": "mass_balance",
            "label": "Расхождение массы записи и компонентов",
            "count": len(mass_balance),
            "severity": "review",
            "dates": sorted({item["date"] for item in mass_balance}),
        },
        {
            "id": "macro_minimum",
            "label": "Записи с калориями и неизвестными БЖУ",
            "count": sum(
                1
                for row in nutrition_rows
                if float(row["calories_kcal"]) > 0
                and float(row["protein_g"]) == 0
                and float(row["fat_g"]) == 0
                and float(row["carbs_g"]) == 0
            ),
            "severity": "review",
            "dates": sorted(
                {
                    row["diary_date"]
                    for row in nutrition_rows
                    if float(row["calories_kcal"]) > 0
                    and float(row["protein_g"]) == 0
                    and float(row["fat_g"]) == 0
                    and float(row["carbs_g"]) == 0
                }
            ),
        },
        {
            "id": "unlinked_components",
            "label": "Компоненты без микронутриентного профиля",
            "count": len(component_rows) - len(linked_components),
            "severity": "review",
            "dates": sorted(
                {row["diary_date"] for row in component_rows if row["reference_fdc_id"] is None}
            ),
        },
        {
            "id": "meal_time_missing",
            "label": "Записи питания без времени",
            "count": sum(1 for row in nutrition_rows if row["eaten_at"] is None),
            "severity": "info",
            "dates": sorted({row["diary_date"] for row in nutrition_rows if row["eaten_at"] is None}),
        },
        {
            "id": "workout_rpe_missing",
            "label": "Тренировки без RPE",
            "count": sum(1 for row in workout_rows if row["perceived_exertion"] is None),
            "severity": "info",
            "dates": sorted({row["diary_date"] for row in workout_rows if row["perceived_exertion"] is None}),
        },
    ]

    generated_value = generated_at or datetime.now(ZoneInfo(TIMEZONE)).isoformat(timespec="seconds")
    payload = {
        "meta": {
            "contractVersion": CONTRACT_VERSION,
            "schemaVersion": SCHEMA_VERSION,
            "calculationVersion": CALCULATION_VERSION,
            "generatedAt": generated_value,
            "timezone": TIMEZONE,
            "latestSourceDate": last_date,
            "sourceCommit": commit if commit is not None else source_commit(),
            "sourceHash": source_hash(),
            "period": {"from": first_date, "to": last_date},
            "baselineWeightKg": BASELINE_WEIGHT_KG,
            "baselineWeightEffectiveDate": None,
        },
        "contract": {
            "dayStatus": ["complete", "in_progress", "missing_date"],
            "valueStatus": ["present", "explicit_zero", "missing"],
            "provenance": ["measured", "labelled", "calculated", "estimated", "unknown"],
            "completeness": ["complete", "known_minimum"],
            "confidence": ["high", "medium", "low", "unknown"],
            "nutrientCoverageGates": {
                "insufficientBelowPercent": 50,
                "comparisonAtOrAbovePercent": 80,
                "requiresEnergyCoverage": True,
            },
            "trendGates": {"descriptiveBelowDays": 7, "provisionalBelowDays": 14},
        },
        "days": days,
        "meals": meals,
        "workouts": workouts,
        "sleep": sleep,
        "nutrientDefinitions": nutrient_definitions,
        "nutrients": nutrients,
        "quality": {
            "counts": {
                "calendarRows": len(calendar_rows),
                "calendarDates": len(date_axis),
                "nutritionEntries": len(nutrition_rows),
                "components": len(component_rows),
                "linkedComponents": len(linked_components),
                "unlinkedComponents": len(component_rows) - len(linked_components),
                "workouts": len(workout_rows),
                "sleepEntries": len(sleep_rows),
                "ratings": len(rating_rows),
            },
            "confidence": confidence_counts,
            "provenance": {"estimated": len(nutrition_rows), "unknown": 0},
            "profileCoverage": {
                "count": ratio_coverage(len(linked_components), len(component_rows)),
                "mass": ratio_coverage(linked_component_mass, total_component_mass),
                "energy": None,
            },
            "issues": issue_payload,
            "massBalance": mass_balance,
            "unlinkedComponents": unlinked_components[:30],
        },
    }
    return payload


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, default=DEFAULT_DATABASE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--generated-at")
    parser.add_argument("--source-commit")
    parser.add_argument("--compact", action="store_true")
    args = parser.parse_args()

    if not args.database.exists():
        raise SystemExit(
            f"Database not found: {args.database}. Run ./scripts/init_db.sh first."
        )

    payload = build_payload(
        args.database,
        generated_at=args.generated_at,
        commit=args.source_commit,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(
            payload,
            ensure_ascii=False,
            indent=None if args.compact else 2,
            sort_keys=False,
            allow_nan=False,
        ) + "\n",
        encoding="utf-8",
    )
    print(
        "DashboardSnapshotV2 generated: "
        f"{args.output} (latest source date: {payload['meta']['latestSourceDate']})"
    )


if __name__ == "__main__":
    main()
