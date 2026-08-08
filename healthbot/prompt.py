"""Prompt and strict JSON schema for turning Telegram messages into drafts."""

from __future__ import annotations


def nullable(kind: str) -> dict[str, object]:
    return {"anyOf": [{"type": kind}, {"type": "null"}]}


NUTRITION_ITEM_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "food_name": {"type": "string"},
        "weight_g": nullable("number"),
        "weight_min_g": nullable("number"),
        "weight_max_g": nullable("number"),
        "calories_kcal": nullable("number"),
        "calories_min_kcal": nullable("number"),
        "calories_max_kcal": nullable("number"),
        "protein_g": nullable("number"),
        "fat_g": nullable("number"),
        "carbs_g": nullable("number"),
        "notes": {"type": "string"},
    },
    "required": [
        "food_name",
        "weight_g",
        "weight_min_g",
        "weight_max_g",
        "calories_kcal",
        "calories_min_kcal",
        "calories_max_kcal",
        "protein_g",
        "fat_g",
        "carbs_g",
        "notes",
    ],
}


SLEEP_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "sleep_started_at": nullable("string"),
        "sleep_ended_at": nullable("string"),
        "duration_minutes": nullable("integer"),
        "quality_score": nullable("integer"),
        "awakenings_count": nullable("integer"),
        "morning_energy_score": nullable("integer"),
    },
    "required": [
        "sleep_started_at",
        "sleep_ended_at",
        "duration_minutes",
        "quality_score",
        "awakenings_count",
        "morning_energy_score",
    ],
}


WORKOUT_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "workout_type": {"type": "string"},
        "time_of_day": {
            "anyOf": [
                {"type": "string", "enum": ["morning", "afternoon", "evening", "night"]},
                {"type": "null"},
            ]
        },
        "duration_minutes": nullable("number"),
        "distance_km": nullable("number"),
        "average_pace_seconds_per_km": nullable("integer"),
        "calories_burned_kcal": nullable("number"),
        "perceived_exertion": nullable("integer"),
        "average_heart_rate_bpm": nullable("integer"),
        "max_heart_rate_bpm": nullable("integer"),
    },
    "required": [
        "workout_type",
        "time_of_day",
        "duration_minutes",
        "distance_km",
        "average_pace_seconds_per_km",
        "calories_burned_kcal",
        "perceived_exertion",
        "average_heart_rate_bpm",
        "max_heart_rate_bpm",
    ],
}


CHECKIN_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "day_rating": nullable("integer"),
        "energy_score": nullable("integer"),
        "mood_score": nullable("integer"),
        "stress_score": nullable("integer"),
        "digestion_score": nullable("integer"),
        "water_ml": nullable("integer"),
        "caffeine_servings": nullable("number"),
        "caffeine_last_at": nullable("string"),
        "alcohol_units": nullable("number"),
        "day_complete": {"type": "boolean"},
    },
    "required": [
        "day_rating",
        "energy_score",
        "mood_score",
        "stress_score",
        "digestion_score",
        "water_ml",
        "caffeine_servings",
        "caffeine_last_at",
        "alcohol_units",
        "day_complete",
    ],
}


EXPENSE_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "category": {
            "anyOf": [
                {"type": "string", "enum": ["groceries", "home", "transport", "other"]},
                {"type": "null"},
            ]
        },
        "amount_rub": nullable("number"),
        "notes": {"type": "string"},
    },
    "required": ["category", "amount_rub", "notes"],
}


DRAFT_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "event_type": {
            "type": "string",
            "enum": ["nutrition", "sleep", "workout", "daily_checkin", "expense", "unknown"],
        },
        "diary_date": {"type": "string"},
        "occurred_at": nullable("string"),
        "summary_ru": {"type": "string"},
        "question": nullable("string"),
        "observations": {"type": "array", "items": {"type": "string"}},
        "assumptions": {"type": "array", "items": {"type": "string"}},
        "confidence": {"type": "string", "enum": ["high", "medium", "low"]},
        "uncertainty_drivers": {"type": "array", "items": {"type": "string"}},
        "recommendations": {"type": "array", "items": {"type": "string"}},
        "payload": {
            "type": "object",
            "additionalProperties": False,
            "properties": {
                "meal_type": {
                    "anyOf": [
                        {"type": "string", "enum": ["breakfast", "lunch", "dinner", "snack"]},
                        {"type": "null"},
                    ]
                },
                "nutrition_items": {"type": "array", "items": NUTRITION_ITEM_SCHEMA},
                "food_bases": {
                    "type": "array",
                    "items": {"type": "string", "enum": ["meat", "chicken", "fish"]},
                },
                "meal_rating": nullable("integer"),
                "sleep": {"anyOf": [SLEEP_SCHEMA, {"type": "null"}]},
                "workout": {"anyOf": [WORKOUT_SCHEMA, {"type": "null"}]},
                "daily_checkin": {"anyOf": [CHECKIN_SCHEMA, {"type": "null"}]},
                "expense": {"anyOf": [EXPENSE_SCHEMA, {"type": "null"}]},
            },
            "required": [
                "meal_type",
                "nutrition_items",
                "food_bases",
                "meal_rating",
                "sleep",
                "workout",
                "daily_checkin",
                "expense",
            ],
        },
    },
    "required": [
        "event_type",
        "diary_date",
        "occurred_at",
        "summary_ru",
        "question",
        "observations",
        "assumptions",
        "confidence",
        "uncertainty_drivers",
        "recommendations",
        "payload",
    ],
}


SYSTEM_PROMPT = """
Ты превращаешь одно Telegram-сообщение владельца личного health_diary в один
структурированный черновик. Отвечай по-русски и только по заданной JSON-схеме.

Профиль: мужчина, 28 лет, 170 см, 64 кг, бегает и ходит в зал, офисная работа.
Не придумывай цель, диагноз, ограничения или аллергию.

Тип события: nutrition, sleep, workout, daily_checkin или expense. Если данных
недостаточно даже для выбора типа — unknown. Дата должна быть YYYY-MM-DD,
время HH:MM или null. Если дата не названа, используй текущую локальную дату.

Для еды:
- факты пользователя и читаемая этикетка важнее визуальной оценки;
- разделяй каждый компонент в nutrition_items;
- не выдумывай скрытые ингредиенты;
- учитывай перспективу и глубину; неизвестный размер посуды не является точным
  масштабом; для супа и горки еды площадь сверху не даёт массу;
- давай low/central/high для веса и калорий; визуальные числа округляй до
  5–10 г/ккал, БЖУ до 0,5–1 г;
- масло, заправку и несъеденную часть учитывай только по фактам или как явный
  сценарий неопределённости;
- проверь совместимость калорий с 4*Б + 9*Ж + 4*У; объясни заметное расхождение;
- meal_rating 1–10 оценивает состав приёма пищи, а не пользователя;
- food_bases содержит только явно подтверждённые meat/chicken/fish.

Задай ровно один короткий вопрос только если ответ, вероятно, изменит оценку
больше чем на 20% или 150 ккал либо нужен обязательный факт (например,
длительность сна/тренировки). Иначе question=null. После ответа на уже заданный
вопрос финализируй черновик с честной низкой уверенностью, не устраивай анкету.

Для сна: duration_minutes обязательно перед сохранением. Для тренировки:
workout_type и duration_minutes обязательны. Для expense: amount_rub обязателен,
категорию не угадывай. daily_checkin.day_complete=true только если пользователь
явно завершает день.

Observations — только факты пользователя/фото. Assumptions — допущения.
Summary_ru — компактная карточка с итогом. Recommendations — 0–3 практичных,
неосуждающих совета. Это общий коучинг, не медицинский диагноз.
""".strip()
