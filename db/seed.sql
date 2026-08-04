PRAGMA foreign_keys = ON;

INSERT INTO calendar_days (diary_date, notes)
VALUES ('2026-08-04', 'Питание внесено по оценочным значениям; сон — 5,5 часа.')
ON CONFLICT (diary_date) DO UPDATE SET notes = excluded.notes;

INSERT INTO workouts (
    calendar_day_id,
    workout_type,
    time_of_day,
    duration_minutes,
    distance_km,
    average_pace_seconds_per_km,
    notes
)
SELECT
    id,
    'running',
    'morning',
    30,
    5.15,
    350,
    'Утренняя пробежка; средний темп рассчитан из дистанции и времени.'
FROM calendar_days
WHERE diary_date = '2026-08-04'
  AND NOT EXISTS (
      SELECT 1
      FROM workouts
      WHERE calendar_day_id = calendar_days.id
        AND workout_type = 'running'
        AND time_of_day = 'morning'
        AND duration_minutes = 30
        AND distance_km = 5.15
  );

INSERT INTO sleep_entries (
    calendar_day_id,
    duration_minutes,
    notes
)
SELECT
    id,
    330,
    'Продолжительность сна — 5,5 часа; время засыпания и пробуждения не указано.'
FROM calendar_days
WHERE diary_date = '2026-08-04'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    notes = excluded.notes;

INSERT INTO nutrition_entries (
    calendar_day_id,
    meal_type,
    food_name,
    calories_kcal,
    protein_g,
    fat_g,
    carbs_g,
    notes
)
SELECT
    id,
    'breakfast',
    '2 яйца; блинчик с курицей; овощной салат; банан; чай',
    610,
    35,
    28,
    61,
    'Оценочные значения.'
FROM calendar_days
WHERE diary_date = '2026-08-04'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = '2 яйца; блинчик с курицей; овощной салат; банан; чай'
  );

INSERT INTO nutrition_entries (
    calendar_day_id,
    meal_type,
    food_name,
    calories_kcal,
    protein_g,
    fat_g,
    carbs_g,
    notes
)
SELECT
    id,
    'lunch',
    'Салат с баклажанами, помидорами и зеленью; соба с овощами; котлета по-киевски',
    825,
    37.5,
    42.5,
    40,
    'Середина диапазонов: 780–870 ккал; белки 35–40 г; жиры 40–45 г; углеводы 35–45 г.'
FROM calendar_days
WHERE diary_date = '2026-08-04'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'lunch'
        AND food_name = 'Салат с баклажанами, помидорами и зеленью; соба с овощами; котлета по-киевски'
  );

INSERT INTO nutrition_entries (
    calendar_day_id,
    meal_type,
    food_name,
    calories_kcal,
    protein_g,
    fat_g,
    carbs_g,
    notes
)
SELECT
    id,
    'snack',
    '2 яблока',
    190,
    0,
    0,
    0,
    'Известна только калорийность; БЖУ не указаны и в сводке не учитываются.'
FROM calendar_days
WHERE diary_date = '2026-08-04'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'snack'
        AND food_name = '2 яблока'
  );

INSERT INTO nutrition_entries (
    calendar_day_id,
    meal_type,
    food_name,
    calories_kcal,
    protein_g,
    fat_g,
    carbs_g,
    notes
)
SELECT
    id,
    'dinner',
    'Лосось; стручковая фасоль; салат с помидорами, огурцами, оливками и рукколой',
    600,
    46,
    34,
    22.5,
    'Углеводы взяты по середине диапазона 20–25 г; в салате немного оливкового масла и бальзамического соуса.'
FROM calendar_days
WHERE diary_date = '2026-08-04'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'dinner'
        AND food_name = 'Лосось; стручковая фасоль; салат с помидорами, огурцами, оливками и рукколой'
  );
