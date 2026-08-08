PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS calendar_days (
    id INTEGER PRIMARY KEY,
    diary_date TEXT NOT NULL UNIQUE
        CHECK (diary_date = date(diary_date)),
    status TEXT NOT NULL DEFAULT 'in_progress'
        CHECK (status IN ('in_progress', 'complete')),
    notes TEXT
);

CREATE TABLE IF NOT EXISTS health_events (
    event_id TEXT PRIMARY KEY,
    calendar_day_id INTEGER NOT NULL
        REFERENCES calendar_days(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL
        CHECK (event_type IN ('nutrition', 'sleep', 'workout', 'daily_checkin', 'expense')),
    occurred_at TEXT,
    received_at TEXT NOT NULL,
    source TEXT NOT NULL,
    payload_json TEXT NOT NULL CHECK (json_valid(payload_json))
);

CREATE INDEX IF NOT EXISTS idx_health_events_day
    ON health_events(calendar_day_id);

CREATE TABLE IF NOT EXISTS nutrition_entries (
    id INTEGER PRIMARY KEY,
    calendar_day_id INTEGER NOT NULL
        REFERENCES calendar_days(id) ON DELETE CASCADE,
    meal_type TEXT NOT NULL
        CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    eaten_at TEXT,
    food_name TEXT NOT NULL,
    weight_g REAL CHECK (weight_g IS NULL OR weight_g >= 0),
    weight_min_g REAL CHECK (weight_min_g IS NULL OR weight_min_g >= 0),
    weight_max_g REAL CHECK (weight_max_g IS NULL OR weight_max_g >= 0),
    calories_kcal REAL NOT NULL DEFAULT 0 CHECK (calories_kcal >= 0),
    calories_min_kcal REAL
        CHECK (calories_min_kcal IS NULL OR calories_min_kcal >= 0),
    calories_max_kcal REAL
        CHECK (calories_max_kcal IS NULL OR calories_max_kcal >= 0),
    protein_g REAL NOT NULL DEFAULT 0 CHECK (protein_g >= 0),
    fat_g REAL NOT NULL DEFAULT 0 CHECK (fat_g >= 0),
    carbs_g REAL NOT NULL DEFAULT 0 CHECK (carbs_g >= 0),
    confidence TEXT
        CHECK (confidence IS NULL OR confidence IN ('high', 'medium', 'low')),
    meal_rating INTEGER
        CHECK (meal_rating IS NULL OR meal_rating BETWEEN 1 AND 10),
    source_event_id TEXT REFERENCES health_events(event_id),
    source_item_index INTEGER CHECK (source_item_index IS NULL OR source_item_index >= 0),
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_nutrition_entries_day
    ON nutrition_entries(calendar_day_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_nutrition_entries_source_item
    ON nutrition_entries(source_event_id, source_item_index)
    WHERE source_event_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS workouts (
    id INTEGER PRIMARY KEY,
    calendar_day_id INTEGER NOT NULL
        REFERENCES calendar_days(id) ON DELETE CASCADE,
    workout_type TEXT NOT NULL,
    time_of_day TEXT
        CHECK (time_of_day IS NULL OR time_of_day IN ('morning', 'afternoon', 'evening', 'night')),
    started_at TEXT,
    duration_minutes REAL NOT NULL CHECK (duration_minutes > 0),
    distance_km REAL CHECK (distance_km IS NULL OR distance_km >= 0),
    average_pace_seconds_per_km INTEGER
        CHECK (average_pace_seconds_per_km IS NULL OR average_pace_seconds_per_km > 0),
    calories_burned_kcal REAL
        CHECK (calories_burned_kcal IS NULL OR calories_burned_kcal >= 0),
    perceived_exertion INTEGER
        CHECK (perceived_exertion IS NULL OR perceived_exertion BETWEEN 1 AND 10),
    average_heart_rate_bpm INTEGER
        CHECK (average_heart_rate_bpm IS NULL OR average_heart_rate_bpm > 0),
    max_heart_rate_bpm INTEGER
        CHECK (max_heart_rate_bpm IS NULL OR max_heart_rate_bpm > 0),
    source_event_id TEXT UNIQUE REFERENCES health_events(event_id),
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_workouts_day
    ON workouts(calendar_day_id);

CREATE TABLE IF NOT EXISTS sleep_entries (
    id INTEGER PRIMARY KEY,
    calendar_day_id INTEGER NOT NULL UNIQUE
        REFERENCES calendar_days(id) ON DELETE CASCADE,
    sleep_started_at TEXT,
    sleep_ended_at TEXT,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes >= 0),
    quality_score INTEGER
        CHECK (quality_score IS NULL OR quality_score BETWEEN 1 AND 5),
    awakenings_count INTEGER
        CHECK (awakenings_count IS NULL OR awakenings_count >= 0),
    morning_energy_score INTEGER
        CHECK (morning_energy_score IS NULL OR morning_energy_score BETWEEN 1 AND 5),
    source_event_id TEXT REFERENCES health_events(event_id),
    notes TEXT
);

CREATE TABLE IF NOT EXISTS daily_food_bases (
    id INTEGER PRIMARY KEY,
    calendar_day_id INTEGER NOT NULL
        REFERENCES calendar_days(id) ON DELETE CASCADE,
    base_type TEXT NOT NULL
        CHECK (base_type IN ('meat', 'chicken', 'fish')),
    notes TEXT,
    UNIQUE (calendar_day_id, base_type)
);

CREATE INDEX IF NOT EXISTS idx_daily_food_bases_day
    ON daily_food_bases(calendar_day_id);

CREATE TABLE IF NOT EXISTS chess_sessions (
    id INTEGER PRIMARY KEY,
    calendar_day_id INTEGER NOT NULL UNIQUE
        REFERENCES calendar_days(id) ON DELETE CASCADE,
    games_played INTEGER NOT NULL CHECK (games_played > 0),
    wins INTEGER NOT NULL DEFAULT 0
        CHECK (wins >= 0 AND wins <= games_played),
    draws INTEGER NOT NULL DEFAULT 0
        CHECK (draws >= 0 AND wins + draws <= games_played),
    notes TEXT
);

CREATE TABLE IF NOT EXISTS daily_ratings (
    id INTEGER PRIMARY KEY,
    calendar_day_id INTEGER NOT NULL UNIQUE
        REFERENCES calendar_days(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    notes TEXT
);

CREATE TABLE IF NOT EXISTS daily_wellbeing (
    id INTEGER PRIMARY KEY,
    calendar_day_id INTEGER NOT NULL UNIQUE
        REFERENCES calendar_days(id) ON DELETE CASCADE,
    energy_score INTEGER
        CHECK (energy_score IS NULL OR energy_score BETWEEN 1 AND 5),
    mood_score INTEGER
        CHECK (mood_score IS NULL OR mood_score BETWEEN 1 AND 5),
    stress_score INTEGER
        CHECK (stress_score IS NULL OR stress_score BETWEEN 1 AND 5),
    digestion_score INTEGER
        CHECK (digestion_score IS NULL OR digestion_score BETWEEN 1 AND 5),
    water_ml INTEGER CHECK (water_ml IS NULL OR water_ml >= 0),
    caffeine_servings REAL
        CHECK (caffeine_servings IS NULL OR caffeine_servings >= 0),
    caffeine_last_at TEXT,
    alcohol_units REAL CHECK (alcohol_units IS NULL OR alcohol_units >= 0),
    source_event_id TEXT REFERENCES health_events(event_id),
    notes TEXT
);

CREATE TABLE IF NOT EXISTS expenses (
    id INTEGER PRIMARY KEY,
    calendar_day_id INTEGER NOT NULL
        REFERENCES calendar_days(id) ON DELETE CASCADE,
    category TEXT
        CHECK (category IS NULL OR category IN ('groceries', 'home', 'transport', 'other')),
    amount_rub REAL NOT NULL CHECK (amount_rub >= 0),
    notes TEXT,
    UNIQUE (calendar_day_id, category)
);

CREATE INDEX IF NOT EXISTS idx_expenses_day
    ON expenses(calendar_day_id);

DROP VIEW IF EXISTS daily_health_summary;

CREATE VIEW daily_health_summary AS
SELECT
    d.diary_date,
    d.status,
    ROUND(COALESCE(n.calories_kcal, 0), 1) AS calories_kcal,
    ROUND(COALESCE(n.protein_g, 0), 1) AS protein_g,
    ROUND(COALESCE(n.fat_g, 0), 1) AS fat_g,
    ROUND(COALESCE(n.carbs_g, 0), 1) AS carbs_g,
    COALESCE(w.workout_count, 0) AS workout_count,
    ROUND(COALESCE(w.workout_minutes, 0), 1) AS workout_minutes,
    ROUND(COALESCE(w.distance_km, 0), 2) AS distance_km,
    COALESCE(c.games_played, 0) AS chess_games,
    COALESCE(c.wins, 0) AS chess_wins,
    COALESCE(c.draws, 0) AS chess_draws,
    s.duration_minutes AS sleep_minutes,
    s.quality_score AS sleep_quality,
    s.awakenings_count AS sleep_awakenings,
    s.morning_energy_score AS morning_energy,
    b.food_bases,
    r.rating AS day_rating,
    wb.energy_score,
    wb.mood_score,
    wb.stress_score,
    wb.digestion_score,
    wb.water_ml,
    wb.caffeine_servings,
    wb.caffeine_last_at,
    wb.alcohol_units,
    ROUND(COALESCE(e.expenses_rub, 0), 2) AS expenses_rub,
    d.notes
FROM calendar_days AS d
LEFT JOIN (
    SELECT
        calendar_day_id,
        SUM(calories_kcal) AS calories_kcal,
        SUM(protein_g) AS protein_g,
        SUM(fat_g) AS fat_g,
        SUM(carbs_g) AS carbs_g
    FROM nutrition_entries
    GROUP BY calendar_day_id
) AS n ON n.calendar_day_id = d.id
LEFT JOIN (
    SELECT
        calendar_day_id,
        COUNT(*) AS workout_count,
        SUM(duration_minutes) AS workout_minutes,
        SUM(COALESCE(distance_km, 0)) AS distance_km
    FROM workouts
    GROUP BY calendar_day_id
) AS w ON w.calendar_day_id = d.id
LEFT JOIN chess_sessions AS c ON c.calendar_day_id = d.id
LEFT JOIN sleep_entries AS s ON s.calendar_day_id = d.id
LEFT JOIN (
    SELECT calendar_day_id, GROUP_CONCAT(base_type, ', ') AS food_bases
    FROM daily_food_bases
    GROUP BY calendar_day_id
) AS b ON b.calendar_day_id = d.id
LEFT JOIN daily_ratings AS r ON r.calendar_day_id = d.id
LEFT JOIN daily_wellbeing AS wb ON wb.calendar_day_id = d.id
LEFT JOIN (
    SELECT calendar_day_id, SUM(amount_rub) AS expenses_rub
    FROM expenses
    GROUP BY calendar_day_id
) AS e ON e.calendar_day_id = d.id;

DROP VIEW IF EXISTS monthly_health_summary;

CREATE VIEW monthly_health_summary AS
SELECT
    SUBSTR(d.diary_date, 1, 7) AS diary_month,
    COUNT(*) AS tracked_days,
    SUM(CASE WHEN d.status = 'complete' THEN 1 ELSE 0 END) AS complete_days,
    ROUND(AVG(CASE WHEN d.status = 'complete' THEN s.calories_kcal END), 1)
        AS avg_calories_kcal_complete,
    ROUND(AVG(CASE WHEN d.status = 'complete' THEN s.protein_g END), 1)
        AS avg_protein_g_complete,
    ROUND(AVG(CASE WHEN d.status = 'complete' THEN s.fat_g END), 1)
        AS avg_fat_g_complete,
    ROUND(AVG(CASE WHEN d.status = 'complete' THEN s.carbs_g END), 1)
        AS avg_carbs_g_complete,
    ROUND(AVG(CASE WHEN s.sleep_minutes IS NOT NULL
        THEN s.sleep_minutes / 60.0 END), 2) AS avg_sleep_hours_recorded,
    SUM(s.workout_count) AS workout_count,
    ROUND(SUM(s.workout_minutes), 1) AS workout_minutes,
    ROUND(SUM(s.distance_km), 2) AS distance_km,
    ROUND(AVG(s.day_rating), 2) AS avg_day_rating,
    ROUND(AVG(s.energy_score), 2) AS avg_energy_score,
    ROUND(AVG(s.mood_score), 2) AS avg_mood_score,
    ROUND(AVG(s.stress_score), 2) AS avg_stress_score,
    ROUND(AVG(s.water_ml), 0) AS avg_water_ml,
    ROUND(SUM(s.expenses_rub), 2) AS expenses_rub
FROM calendar_days AS d
JOIN daily_health_summary AS s ON s.diary_date = d.diary_date
GROUP BY SUBSTR(d.diary_date, 1, 7);
