"""User-facing Russian cards for drafts and daily summaries."""

from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Any


EVENT_LABELS = {
    "nutrition": "Питание",
    "sleep": "Сон",
    "workout": "Тренировка",
    "daily_checkin": "Итог дня",
    "expense": "Расход",
    "unknown": "Нужно уточнение",
}

MEAL_LABELS = {
    "breakfast": "завтрак",
    "lunch": "обед",
    "dinner": "ужин",
    "snack": "перекус",
}


def _number(value: Any, precision: int = 0) -> str:
    if value is None:
        return "?"
    return f"{float(value):.{precision}f}".replace(".0", "")


def format_draft(draft: dict[str, Any]) -> str:
    event_type = draft.get("event_type", "unknown")
    title = EVENT_LABELS.get(event_type, event_type)
    time = f" · {draft['occurred_at']}" if draft.get("occurred_at") else ""
    lines = [f"{title} · {draft.get('diary_date', '?')}{time}", ""]
    payload = draft.get("payload") or {}
    if event_type == "nutrition":
        meal = MEAL_LABELS.get(payload.get("meal_type"), payload.get("meal_type") or "приём пищи")
        lines[0] = f"Питание · {meal} · {draft.get('diary_date', '?')}{time}"
        items = payload.get("nutrition_items") or []
        total_calories = 0.0
        total_min = 0.0
        total_max = 0.0
        protein = fat = carbs = 0.0
        has_calories = has_min = has_max = False
        for item in items:
            weight = f", ~{_number(item.get('weight_g'))} г" if item.get("weight_g") is not None else ""
            calories = item.get("calories_kcal")
            lines.append(
                f"• {item.get('food_name', '?')}{weight}: "
                + (f"{_number(calories)} ккал" if calories is not None else "ккал неизвестны")
            )
            if calories is not None:
                total_calories += float(calories)
                has_calories = True
            if item.get("calories_min_kcal") is not None:
                total_min += float(item["calories_min_kcal"])
                has_min = True
            if item.get("calories_max_kcal") is not None:
                total_max += float(item["calories_max_kcal"])
                has_max = True
            protein += float(item.get("protein_g") or 0)
            fat += float(item.get("fat_g") or 0)
            carbs += float(item.get("carbs_g") or 0)
        if has_calories:
            calorie_line = f"Итого: {_number(total_calories)} ккал"
            if has_min and has_max:
                calorie_line += f" ({_number(total_min)}–{_number(total_max)})"
            lines.extend(["", calorie_line, f"Б/Ж/У: {_number(protein, 1)} / {_number(fat, 1)} / {_number(carbs, 1)} г"])
        if payload.get("meal_rating"):
            lines.append(f"Оценка приёма пищи: {payload['meal_rating']}/10")
    elif event_type == "sleep":
        sleep = payload.get("sleep") or {}
        lines.append(f"Продолжительность: {_number(sleep.get('duration_minutes'))} мин")
        if sleep.get("quality_score"):
            lines.append(f"Качество: {sleep['quality_score']}/5")
        if sleep.get("morning_energy_score"):
            lines.append(f"Энергия утром: {sleep['morning_energy_score']}/5")
    elif event_type == "workout":
        workout = payload.get("workout") or {}
        lines.append(f"Тип: {workout.get('workout_type') or '?'}")
        lines.append(f"Продолжительность: {_number(workout.get('duration_minutes'))} мин")
        if workout.get("distance_km") is not None:
            lines.append(f"Дистанция: {_number(workout['distance_km'], 2)} км")
        if workout.get("perceived_exertion"):
            lines.append(f"RPE: {workout['perceived_exertion']}/10")
    elif event_type == "daily_checkin":
        checkin = payload.get("daily_checkin") or {}
        for key, label in (
            ("day_rating", "Оценка дня"),
            ("energy_score", "Энергия"),
            ("mood_score", "Настроение"),
            ("stress_score", "Стресс"),
        ):
            if checkin.get(key) is not None:
                lines.append(f"{label}: {checkin[key]}/5")
        lines.append("День будет завершён." if checkin.get("day_complete") else "Промежуточная отметка.")
    elif event_type == "expense":
        expense = payload.get("expense") or {}
        lines.append(f"Сумма: {_number(expense.get('amount_rub'))} ₽")
        if expense.get("category"):
            lines.append(f"Категория: {expense['category']}")
    else:
        lines.append(str(draft.get("summary_ru") or "Не удалось определить тип записи."))

    assumptions = draft.get("assumptions") or []
    if assumptions:
        lines.extend(["", "Допущения: " + "; ".join(map(str, assumptions[:3]))])
    uncertainty = draft.get("uncertainty_drivers") or []
    if uncertainty:
        lines.append("Главная погрешность: " + "; ".join(map(str, uncertainty[:3])))
    lines.append(f"Уверенность: {draft.get('confidence', 'low')}")
    question = draft.get("question")
    if question:
        lines.extend(["", f"Уточнение: {question}"])
    return "\n".join(lines)[:4000]


def format_today(database: Path, diary_date: str) -> str:
    connection = sqlite3.connect(database)
    connection.row_factory = sqlite3.Row
    row = connection.execute(
        "SELECT * FROM daily_health_summary WHERE diary_date = ?", (diary_date,)
    ).fetchone()
    if row is None:
        connection.close()
        return f"За {diary_date} пока нет записей."
    event_count = connection.execute(
        """
        SELECT COUNT(*) FROM health_events AS e
        JOIN calendar_days AS d ON d.id = e.calendar_day_id
        WHERE d.diary_date = ?
        """,
        (diary_date,),
    ).fetchone()[0]
    connection.close()
    status = "завершён" if row["status"] == "complete" else "заполняется"
    lines = [
        f"Сегодня · {diary_date} · {status}",
        "",
        f"Питание: {_number(row['calories_kcal'])} ккал",
        f"Б/Ж/У: {_number(row['protein_g'], 1)} / {_number(row['fat_g'], 1)} / {_number(row['carbs_g'], 1)} г",
        f"Сон: {_number(row['sleep_minutes'])} мин" if row["sleep_minutes"] is not None else "Сон: нет записи",
        f"Тренировки: {row['workout_count']} · {_number(row['workout_minutes'])} мин",
        f"Оценка дня: {row['day_rating']}/5" if row["day_rating"] else "Оценка дня: нет",
        f"Подтверждённых событий бота: {event_count}",
    ]
    return "\n".join(lines)
