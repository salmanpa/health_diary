PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS calendar_days (
    id INTEGER PRIMARY KEY,
    diary_date TEXT NOT NULL UNIQUE
        CHECK (diary_date = date(diary_date)),
    status TEXT NOT NULL DEFAULT 'in_progress'
        CHECK (status IN ('in_progress', 'complete')),
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

CREATE TABLE IF NOT EXISTS food_reference_profiles (
    fdc_id INTEGER PRIMARY KEY,
    food_name TEXT NOT NULL,
    fiber_g_per_100g REAL CHECK (fiber_g_per_100g IS NULL OR fiber_g_per_100g >= 0),
    calcium_mg_per_100g REAL CHECK (calcium_mg_per_100g IS NULL OR calcium_mg_per_100g >= 0),
    iron_mg_per_100g REAL CHECK (iron_mg_per_100g IS NULL OR iron_mg_per_100g >= 0),
    magnesium_mg_per_100g REAL CHECK (magnesium_mg_per_100g IS NULL OR magnesium_mg_per_100g >= 0),
    potassium_mg_per_100g REAL CHECK (potassium_mg_per_100g IS NULL OR potassium_mg_per_100g >= 0),
    sodium_mg_per_100g REAL CHECK (sodium_mg_per_100g IS NULL OR sodium_mg_per_100g >= 0),
    vitamin_c_mg_per_100g REAL CHECK (vitamin_c_mg_per_100g IS NULL OR vitamin_c_mg_per_100g >= 0),
    vitamin_d_mcg_per_100g REAL CHECK (vitamin_d_mcg_per_100g IS NULL OR vitamin_d_mcg_per_100g >= 0),
    vitamin_b12_mcg_per_100g REAL CHECK (vitamin_b12_mcg_per_100g IS NULL OR vitamin_b12_mcg_per_100g >= 0),
    folate_dfe_mcg_per_100g REAL CHECK (folate_dfe_mcg_per_100g IS NULL OR folate_dfe_mcg_per_100g >= 0),
    omega3_g_per_100g REAL CHECK (omega3_g_per_100g IS NULL OR omega3_g_per_100g >= 0),
    source_name TEXT NOT NULL,
    source_url TEXT NOT NULL,
    source_release TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS nutrition_components (
    id INTEGER PRIMARY KEY,
    nutrition_entry_id INTEGER NOT NULL
        REFERENCES nutrition_entries(id) ON DELETE CASCADE,
    component_name TEXT NOT NULL,
    estimated_weight_g REAL NOT NULL CHECK (estimated_weight_g > 0),
    reference_fdc_id INTEGER
        REFERENCES food_reference_profiles(fdc_id),
    confidence TEXT NOT NULL
        CHECK (confidence IN ('high', 'medium', 'low')),
    food_group TEXT
        CHECK (food_group IS NULL OR food_group IN (
            'meat', 'chicken', 'fish', 'seafood', 'vegetables', 'fruit',
            'grains', 'nuts', 'unknown', 'other'
        )),
    notes TEXT,
    UNIQUE (nutrition_entry_id, component_name)
);

CREATE INDEX IF NOT EXISTS idx_nutrition_components_entry
    ON nutrition_components(nutrition_entry_id);

CREATE TABLE IF NOT EXISTS nutrient_reference_values (
    nutrient_code TEXT PRIMARY KEY,
    nutrient_name TEXT NOT NULL,
    unit TEXT NOT NULL,
    daily_reference REAL,
    reference_type TEXT,
    comparison_mode TEXT NOT NULL DEFAULT 'minimum'
        CHECK (comparison_mode IN ('minimum', 'upper', 'informational')),
    source_url TEXT NOT NULL,
    notes TEXT,
    sort_order INTEGER NOT NULL UNIQUE
);

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
        CHECK (average_heart_rate_bpm IS NULL OR average_heart_rate_bpm BETWEEN 30 AND 240),
    max_heart_rate_bpm INTEGER
        CHECK (max_heart_rate_bpm IS NULL OR max_heart_rate_bpm BETWEEN 30 AND 250),
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
    ROUND(COALESCE(w.workout_calories_kcal, 0), 1) AS workout_calories_kcal,
    COALESCE(c.games_played, 0) AS chess_games,
    COALESCE(c.wins, 0) AS chess_wins,
    COALESCE(c.draws, 0) AS chess_draws,
    s.duration_minutes AS sleep_minutes,
    s.quality_score AS sleep_quality,
    b.food_bases,
    r.rating AS day_rating,
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
        SUM(COALESCE(distance_km, 0)) AS distance_km,
        SUM(COALESCE(calories_burned_kcal, 0)) AS workout_calories_kcal
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
;

DROP VIEW IF EXISTS daily_nutrient_summary;

CREATE VIEW daily_nutrient_summary AS
SELECT
    d.diary_date,
    COUNT(c.id) AS component_count,
    SUM(CASE WHEN c.reference_fdc_id IS NOT NULL THEN 1 ELSE 0 END)
        AS analyzed_component_count,
    ROUND(SUM(c.estimated_weight_g), 1) AS component_weight_g,
    ROUND(SUM(CASE WHEN c.reference_fdc_id IS NOT NULL
                   THEN c.estimated_weight_g ELSE 0 END), 1)
        AS analyzed_component_weight_g,
    ROUND(SUM(c.estimated_weight_g * p.fiber_g_per_100g / 100.0), 2) AS fiber_g,
    ROUND(SUM(c.estimated_weight_g * p.calcium_mg_per_100g / 100.0), 1) AS calcium_mg,
    ROUND(SUM(c.estimated_weight_g * p.iron_mg_per_100g / 100.0), 2) AS iron_mg,
    ROUND(SUM(c.estimated_weight_g * p.magnesium_mg_per_100g / 100.0), 1) AS magnesium_mg,
    ROUND(SUM(c.estimated_weight_g * p.potassium_mg_per_100g / 100.0), 1) AS potassium_mg,
    ROUND(SUM(c.estimated_weight_g * p.sodium_mg_per_100g / 100.0), 1) AS sodium_mg,
    ROUND(SUM(c.estimated_weight_g * p.vitamin_c_mg_per_100g / 100.0), 1) AS vitamin_c_mg,
    ROUND(SUM(c.estimated_weight_g * p.vitamin_d_mcg_per_100g / 100.0), 2) AS vitamin_d_mcg,
    ROUND(SUM(c.estimated_weight_g * p.vitamin_b12_mcg_per_100g / 100.0), 2) AS vitamin_b12_mcg,
    ROUND(SUM(c.estimated_weight_g * p.folate_dfe_mcg_per_100g / 100.0), 1) AS folate_dfe_mcg,
    ROUND(SUM(c.estimated_weight_g * p.omega3_g_per_100g / 100.0), 3) AS omega3_g
FROM calendar_days AS d
LEFT JOIN nutrition_entries AS n ON n.calendar_day_id = d.id
LEFT JOIN nutrition_components AS c ON c.nutrition_entry_id = n.id
LEFT JOIN food_reference_profiles AS p ON p.fdc_id = c.reference_fdc_id
GROUP BY d.id, d.diary_date;

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
    ROUND(SUM(s.workout_calories_kcal), 1) AS workout_calories_kcal,
    ROUND(AVG(s.day_rating), 2) AS avg_day_rating
FROM calendar_days AS d
JOIN daily_health_summary AS s ON s.diary_date = d.diary_date
GROUP BY SUBSTR(d.diary_date, 1, 7);
