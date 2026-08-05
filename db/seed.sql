PRAGMA foreign_keys = ON;

INSERT INTO calendar_days (diary_date, notes)
VALUES (
    '2026-08-04',
    'Питание внесено по оценочным значениям; сон — 5,5 часа; оценка и расходы внесены пользователем.'
)
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

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'chicken', 'Курица присутствует в блинчике и котлете по-киевски.'
FROM calendar_days
WHERE diary_date = '2026-08-04'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба присутствует на ужин: лосось.'
FROM calendar_days
WHERE diary_date = '2026-08-04'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 4, 'Оценка дня пользователем: 4 из 5.'
FROM calendar_days
WHERE diary_date = '2026-08-04'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    rating = excluded.rating,
    notes = excluded.notes;

WITH expense_data (category, amount_rub, notes) AS (
    VALUES
        ('groceries', 1050, 'Продукты'),
        ('home', 200, 'Дом'),
        ('transport', 800, 'Транспорт')
)
INSERT INTO expenses (calendar_day_id, category, amount_rub, notes)
SELECT d.id, e.category, e.amount_rub, e.notes
FROM calendar_days AS d
CROSS JOIN expense_data AS e
WHERE d.diary_date = '2026-08-04'
ON CONFLICT (calendar_day_id, category) DO UPDATE SET
    amount_rub = excluded.amount_rub,
    notes = excluded.notes;

INSERT INTO calendar_days (diary_date, notes)
VALUES (
    '2026-08-05',
    'Внесены сон, функционально-силовая тренировка и питание. Порции части блюд оценочные. Траты: 0 ₽; категория не указана.'
)
ON CONFLICT (diary_date) DO UPDATE SET notes = excluded.notes;

INSERT INTO workouts (
    calendar_day_id,
    workout_type,
    duration_minutes,
    calories_burned_kcal,
    notes
)
SELECT
    id,
    'functional_strength_training',
    48,
    355,
    'Функционально-силовая тренировка в зале; расход калорий указан пользователем.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
  AND NOT EXISTS (
      SELECT 1
      FROM workouts
      WHERE calendar_day_id = calendar_days.id
        AND workout_type = 'functional_strength_training'
        AND duration_minutes = 48
        AND calories_burned_kcal = 355
  );

INSERT INTO sleep_entries (
    calendar_day_id,
    duration_minutes,
    notes
)
SELECT
    id,
    300,
    'Продолжительность сна — 5 часов; время засыпания и пробуждения не указано.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    notes = excluded.notes;

INSERT INTO nutrition_entries (
    calendar_day_id,
    meal_type,
    food_name,
    weight_g,
    calories_kcal,
    protein_g,
    fat_g,
    carbs_g,
    notes
)
SELECT
    id,
    'breakfast',
    'Яичница из 1 яйца; салат из помидоров, огурцов и перца; скрэмбл со шпинатом и томатами; блинчик с яблоком; 2 мини-сосиски молочные',
    540,
    753,
    31.8,
    36.3,
    50.6,
    'Середина оценки 660–850 ккал. Скрэмбл: 150 г, по фото ценника 171,92 ккал, Б 8,36 г, Ж 7,13 г, У 2,82 г на 100 г (всего 258 ккал, Б 12,5 г, Ж 10,7 г, У 4,2 г). Для салата принята порция 250 г без заметной заправки; для блинчика с яблоком — около 90 г; для двух мини-сосисок — около 50 г. Главные неопределённости: масло в салате/яичнице, размер и рецепт блинчика, вес и состав сосисок. База питания не отмечена: вид мяса в молочных сосисках не указан.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = 'Яичница из 1 яйца; салат из помидоров, огурцов и перца; скрэмбл со шпинатом и томатами; блинчик с яблоком; 2 мини-сосиски молочные'
  );

INSERT INTO nutrition_entries (
    calendar_day_id,
    meal_type,
    food_name,
    weight_g,
    calories_kcal,
    protein_g,
    fat_g,
    carbs_g,
    notes
)
SELECT
    id,
    'lunch',
    'Сливочный рыбный суп; паста с курицей и шампиньонами; салат «Венеция»',
    660,
    743.6,
    45.2,
    42.3,
    44.7,
    'Середина оценки 640–850 ккал. По фото: суп около 300 г (на 100 г: Б 4,64 г, Ж 3,57 г, У 4,48 г; 68,8 ккал рассчитано по БЖУ); паста около 200 г (на 100 г: 175,68 ккал, Б 14,16 г, Ж 7,55 г, У 12,7 г); салат около 160 г (на 100 г: 116,2 ккал, Б 1,85 г, Ж 10,33 г, У 3,66 г). Диапазон зависит в основном от фактической глубины супа, массы пасты и количества масла/песто в салате.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'lunch'
        AND food_name = 'Сливочный рыбный суп; паста с курицей и шампиньонами; салат «Венеция»'
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'chicken', 'Куриное филе присутствует в пасте с курицей и шампиньонами.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба присутствует в сливочном рыбном супе: сайда и минтай.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO nutrition_entries (
    calendar_day_id,
    meal_type,
    food_name,
    weight_g,
    calories_kcal,
    protein_g,
    fat_g,
    carbs_g,
    notes
)
SELECT
    id,
    'dinner',
    'Обжаренное филе; сыр маасдам; руккола с песто; томаты; зелёные оливки',
    470,
    595,
    62.3,
    33.1,
    9.8,
    'Середина оценки 520–700 ккал. По фото приняты: обжаренное филе около 150 г, маасдам около 50 г, руккола 70 г, томаты 150 г, зелёные оливки 35 г и песто 15 г. Для БЖУ филе использовано как куриное; вид мяса по фото не подтверждён. Главные неопределённости: вид и масса филе, масса сыра, масло при жарке и точное количество песто.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'dinner'
        AND food_name = 'Обжаренное филе; сыр маасдам; руккола с песто; томаты; зелёные оливки'
  );

INSERT INTO nutrition_entries (
    calendar_day_id,
    meal_type,
    food_name,
    weight_g,
    calories_kcal,
    protein_g,
    fat_g,
    carbs_g,
    notes
)
SELECT
    id,
    'snack',
    'Яблоко; банан; нектарин',
    440,
    262,
    3.3,
    1.2,
    67,
    'Оценка для одного среднего яблока (около 180 г), банана без кожуры (около 118 г) и нектарина (около 140 г). Диапазон 220–310 ккал зависит от размера фруктов.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'snack'
        AND food_name = 'Яблоко; банан; нектарин'
  );

INSERT INTO chess_sessions (
    calendar_day_id,
    games_played,
    wins,
    notes
)
SELECT
    id,
    2,
    2,
    'Сыграно 2 партии, одержано 2 победы.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    games_played = excluded.games_played,
    wins = excluded.wins,
    notes = excluded.notes;
