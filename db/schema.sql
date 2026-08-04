PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS calendar_days (
    id INTEGER PRIMARY KEY,
    diary_date TEXT NOT NULL UNIQUE
        CHECK (diary_date = date(diary_date)),
    notes TEXT
);

CREATE TABLE IF NOT EXISTS nutrition_entries (
    id INTEGER PRIMARY KEY,
    calendar_day_id INTEGER NOT NULL
        REFERENCES calendar_days(id) ON DELETE CASCADE,
    meal_type TEXT NOT NULL
        CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    eaten_at TEXT,
    food_name TEXT NOT NULL,
    weight_g REAL CHECK (weight_g IS NULL OR weight_g >= 0),
    calories_kcal REAL NOT NULL DEFAULT 0 CHECK (calories_kcal >= 0),
    protein_g REAL NOT NULL DEFAULT 0 CHECK (protein_g >= 0),
    fat_g REAL NOT NULL DEFAULT 0 CHECK (fat_g >= 0),
    carbs_g REAL NOT NULL DEFAULT 0 CHECK (carbs_g >= 0),
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_nutrition_entries_day
    ON nutrition_entries(calendar_day_id);

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
    notes TEXT
);

CREATE VIEW IF NOT EXISTS daily_health_summary AS
SELECT
    d.diary_date,
    ROUND(COALESCE(n.calories_kcal, 0), 1) AS calories_kcal,
    ROUND(COALESCE(n.protein_g, 0), 1) AS protein_g,
    ROUND(COALESCE(n.fat_g, 0), 1) AS fat_g,
    ROUND(COALESCE(n.carbs_g, 0), 1) AS carbs_g,
    COALESCE(w.workout_count, 0) AS workout_count,
    ROUND(COALESCE(w.workout_minutes, 0), 1) AS workout_minutes,
    ROUND(COALESCE(w.distance_km, 0), 2) AS distance_km,
    s.duration_minutes AS sleep_minutes,
    s.quality_score AS sleep_quality,
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
LEFT JOIN sleep_entries AS s ON s.calendar_day_id = d.id;
