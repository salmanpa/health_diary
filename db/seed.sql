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
    'Внесены сон, функционально-силовая тренировка и питание. Порции части блюд оценочные. Траты: 430 ₽ за напиток; категория не указана.'
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

INSERT INTO daily_ratings (
    calendar_day_id,
    rating,
    notes
)
SELECT
    id,
    4,
    'Оценка дня пользователем: 4 из 5.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    rating = excluded.rating,
    notes = excluded.notes;

INSERT INTO expenses (
    calendar_day_id,
    category,
    amount_rub,
    notes
)
SELECT
    id,
    NULL,
    430,
    'Напиток; категория не указана пользователем.'
FROM calendar_days
WHERE diary_date = '2026-08-05'
  AND NOT EXISTS (
      SELECT 1
      FROM expenses
      WHERE calendar_day_id = calendar_days.id
        AND category IS NULL
        AND notes = 'Напиток; категория не указана пользователем.'
  );

INSERT INTO calendar_days (diary_date, notes)
VALUES (
    '2026-08-06',
    'Внесены сон, бег, все перечисленные приёмы пищи, шахматы, пользовательская оценка дня и отсутствие расходов. Размеры порций, калории и БЖУ оценочные.'
)
ON CONFLICT (diary_date) DO UPDATE SET notes = excluded.notes;

INSERT INTO workouts (
    calendar_day_id,
    workout_type,
    duration_minutes,
    distance_km,
    average_pace_seconds_per_km,
    notes
)
SELECT
    id,
    'running',
    30,
    5.52,
    326,
    'Пробежка; средний темп около 5:26 мин/км рассчитан из указанной дистанции и времени. Время суток не указано.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1
      FROM workouts
      WHERE calendar_day_id = calendar_days.id
        AND workout_type = 'running'
        AND duration_minutes = 30
        AND distance_km = 5.52
  );

INSERT INTO sleep_entries (
    calendar_day_id,
    duration_minutes,
    notes
)
SELECT
    id,
    360,
    'Продолжительность сна — 6 часов; время засыпания, пробуждения и качество сна не указаны.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
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
    '2 небольших варёных яйца',
    88,
    126,
    11.1,
    8.4,
    0.6,
    'Центральная оценка для двух небольших яиц: около 88 г съедобной части. Оценочный диапазон: 120–140 ккал; Б 10,5–12 г, Ж 8–9,5 г, У 0,5–1 г.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = '2 небольших варёных яйца'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'lunch',
    'Макароны-ракушки; филе куриного бедра на пару; салат «Табуле» с запечёнными овощами; морковь и сельдерей',
    620, 735, 42, 19, 97,
    'Центральная оценка для макарон 220 г, куриного филе 120 г, табуле 180 г и овощных палочек 100 г. Ориентировочный диапазон всего обеда: 630–850 ккал; Б 36–49 г, Ж 15–25 г, У 82–112 г. Данные с карточек: куриное филе — 150 ккал, Б 21 г, Ж 6 г, У 1,5 г на 100 г; табуле — 107,1 ккал, Б 2,31 г, Ж 5,44 г, У 12,23 г на 100 г. Морковь и сельдерей указаны пользователем; заправка не видна. Основные источники неопределённости: фактическая масса и глубина порций, возможное масло в макаронах, количество масла в табуле и соотношение моркови и сельдерея. Уверенность средняя.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'lunch'
        AND food_name = 'Макароны-ракушки; филе куриного бедра на пару; салат «Табуле» с запечёнными овощами; морковь и сельдерей'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'snack', 'Яблоко; банан', 298, 200, 1.6, 0.8, 52,
    'Центральная оценка для одного среднего яблока около 180 г и одного среднего банана без кожуры около 118 г. Ориентировочный диапазон 170–240 ккал зависит от размера фруктов.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'snack' AND food_name = 'Яблоко; банан'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'dinner',
    'Лосось; руккола без заправки; стручковая фасоль; голубика',
    635, 642, 50.5, 30.5, 41.6,
    'Уточнено по фото. При допущении, что диаметр прозрачной обеденной тарелки около 26–28 см, центральная оценка: приготовленный кусок лосося 200 г (примерно 180–220 г), стручковая фасоль 200 г (примерно 170–230 г), руккола 60 г (примерно 45–80 г) и отдельно указанная голубика 175 г (150–200 г). Ориентировочно 540–750 ккал, Б 44–57 г, Ж 23–39 г, У 35–49 г. На лососе и фасоли виден блеск, поэтому в центральной оценке учтено около 5 г возможного масла; руккола учтена без заправки по сообщению пользователя. Главные неопределённости: реальный диаметр тарелки и глубина порций, масса и жирность лосося, а также количество масла при приготовлении.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'dinner'
        AND food_name = 'Лосось; руккола без заправки; стручковая фасоль; голубика'
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'chicken', 'Куриное филе бедра на пару присутствует в обеде.'
FROM calendar_days WHERE diary_date = '2026-08-06'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба присутствует на ужин: лосось.'
FROM calendar_days WHERE diary_date = '2026-08-06'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO chess_sessions (calendar_day_id, games_played, wins, draws, notes)
SELECT id, 1, 0, 1, 'Сыграна 1 партия: ничья (0 побед).'
FROM calendar_days WHERE diary_date = '2026-08-06'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    games_played = excluded.games_played,
    wins = excluded.wins,
    draws = excluded.draws,
    notes = excluded.notes;

INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 3, 'Итоговая оценка дня пользователем: 3 из 5. Скорректировано с ранее указанной оценки 4 из 5 по новому сообщению пользователя.'
FROM calendar_days WHERE diary_date = '2026-08-06'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    rating = excluded.rating,
    notes = excluded.notes;

INSERT INTO expenses (calendar_day_id, category, amount_rub, notes)
SELECT id, NULL, 0, 'Расходы за день: 0 ₽; категория неприменима.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1 FROM expenses
      WHERE calendar_day_id = calendar_days.id
        AND category IS NULL
        AND notes = 'Расходы за день: 0 ₽; категория неприменима.'
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
    'breakfast',
    'Овощной салат без заправки с мини-моцареллой',
    250,
    145,
    8.5,
    7.8,
    11,
    'Пользователь подтвердил 3 шарика мини-моцареллы и помидор черри. По ним как масштабу диаметр миски оценён примерно в 17–18 см. Центральная оценка: около 210 г овощей (помидоры, включая 1 черри, огурец, сладкий перец и листовой салат) и 40 г моцареллы. Заправка не учитывалась согласно описанию пользователя. Диапазон общей массы 210–280 г; 115–180 ккал, Б 7–11 г, Ж 5,5–10,5 г, У 9–14 г. Основная неопределённость — глубина порции, точная масса шариков и возможное масло на поверхности моцареллы.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = 'Овощной салат без заправки с мини-моцареллой'
  );

UPDATE nutrition_entries
SET
    weight_g = 250,
    calories_kcal = 145,
    protein_g = 8.5,
    fat_g = 7.8,
    carbs_g = 11,
    notes = 'Пользователь подтвердил 3 шарика мини-моцареллы и помидор черри. По ним как масштабу диаметр миски оценён примерно в 17–18 см. Центральная оценка: около 210 г овощей (помидоры, включая 1 черри, огурец, сладкий перец и листовой салат) и 40 г моцареллы. Заправка не учитывалась согласно описанию пользователя. Диапазон общей массы 210–280 г; 115–180 ккал, Б 7–11 г, Ж 5,5–10,5 г, У 9–14 г. Основная неопределённость — глубина порции, точная масса шариков и возможное масло на поверхности моцареллы.'
WHERE calendar_day_id = (
        SELECT id
        FROM calendar_days
        WHERE diary_date = '2026-08-06'
    )
  AND meal_type = 'breakfast'
  AND food_name = 'Овощной салат без заправки с мини-моцареллой';

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
    'Банан',
    120,
    107,
    1.3,
    0.4,
    27.6,
    'Центральная оценка для съедобной части около 120 г. По фотографии размер выглядит средним или крупным; диапазон 90–120 ккал, Б 1–1,5 г, Ж 0,3–0,5 г, У 23–31 г.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1
      FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = 'Банан'
  );

INSERT INTO calendar_days (diary_date, notes)
VALUES (
    '2026-08-07',
    'Внесены утренний сон, пробежка, завтрак, обед и перекус по описанию и фотографиям пользователя. Порции, калории и БЖУ приёмов пищи оценочные.'
)
ON CONFLICT (diary_date) DO UPDATE SET notes = excluded.notes;

INSERT INTO sleep_entries (calendar_day_id, duration_minutes, notes)
SELECT
    id,
    330,
    'Продолжительность сна — 5,5 часа; время засыпания, пробуждения и качество сна не указаны.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    notes = excluded.notes;

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
    31,
    5.7,
    326,
    'Утренняя пробежка; средний темп около 5:26 мин/км рассчитан из указанных дистанции и времени.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
  AND NOT EXISTS (
      SELECT 1
      FROM workouts
      WHERE calendar_day_id = calendar_days.id
        AND workout_type = 'running'
        AND time_of_day = 'morning'
        AND duration_minutes = 31
        AND distance_km = 5.7
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'breakfast', '2 варёных яйца', 100,
    156, 12.6, 10.6, 1.1,
    'На фотографии видны 2 варёных куриных яйца. Центральная оценка — 100 г съедобной части; ориентировочно 140–175 ккал, Б 11,5–14 г, Ж 9,5–12 г, У 0,8–1,3 г. Неопределённость связана с размером яиц.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = '2 варёных яйца'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'breakfast', 'Овощи без указанной заправки: помидор, сладкий перец, огурец и листья салата', 235,
    43, 2.1, 0.5, 9,
    'По описанию и фотографии: небольшой помидор, пара ломтиков сладкого перца, половина огурца и листья салата. Центральная оценка массы — 235 г (примерно 190–280 г); 35–55 ккал, Б 1,5–2,7 г, Ж 0,3–0,7 г, У 7–12 г. Заправка пользователем не указана и в расчёт не включена; главные неопределённости — глубина миски, размеры овощей и возможная заправка.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = 'Овощи без указанной заправки: помидор, сладкий перец, огурец и листья салата'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'breakfast', 'Банан', 140,
    125, 1.5, 0.5, 32,
    'На фотографии банан выглядит крупным. Центральная оценка — 140 г съедобной части (примерно 120–160 г); 105–145 ккал, Б 1,3–1,8 г, Ж 0,4–0,6 г, У 27–37 г. Неопределённость связана с фактическим размером и массой без кожуры.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = 'Банан'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'lunch',
    'Овощной салат без указанной заправки; картофельное пюре; 2 тефтели из щуки на пару; картофельный суп с куриными фрикадельками',
    885, 646, 39.5, 22.3, 74.4,
    'Скорректировано по фотографиям блюда, табличкам состава и уточнению пользователя о массе супа. Салат указан как точно такой же, как на завтрак: центральная оценка 235 г и 43 ккал (примерно 190–280 г и 35–55 ккал), без учтённой заправки. По одноразовой тарелке предполагаемого диаметра 22–24 см и столовым приборам как масштабу оценены: картофельное пюре 260 г (220–310 г) и 2 крупные паровые тефтели из щуки суммарно 190 г (160–220 г). Для тефтелей использованы данные с таблички на 100 г: 106 ккал, Б 13,8 г, Ж 3,7 г, У 4,3 г; центрально 201 ккал, Б 26,2 г, Ж 7 г, У 8,2 г. Масса супа принята равной примерно 200 г по уточнению пользователя (ориентировочно 180–220 г); на фото и в составе указаны картофель, рис и куриные фрикадельки. По табличке на 100 г: около 57,6 ккал, Б 3 г, Ж 2,2 г, У 6,5 г; центрально для супа 115 ккал, Б 6 г, Ж 4,4 г, У 13 г. Пюре центрально: 286 ккал, Б 5,2 г, Ж 10,4 г, У 44,2 г. Весь обед ориентировочно 535–750 ккал, Б 33–46 г, Ж 17–28 г, У 63–88 г. Главные неопределённости: фактические масса пюре и тефтелей, рецептура пюре и возможное масло; значения табличек читаются по фотографии и применены к оценочной массе.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'lunch'
        AND food_name = 'Овощной салат без указанной заправки; картофельное пюре; 2 тефтели из щуки на пару; картофельный суп с куриными фрикадельками'
  );

UPDATE nutrition_entries
SET weight_g = 885,
    calories_kcal = 646,
    protein_g = 39.5,
    fat_g = 22.3,
    carbs_g = 74.4,
    notes = 'Скорректировано по фотографиям блюда, табличкам состава и уточнению пользователя о массе супа. Салат указан как точно такой же, как на завтрак: центральная оценка 235 г и 43 ккал (примерно 190–280 г и 35–55 ккал), без учтённой заправки. По одноразовой тарелке предполагаемого диаметра 22–24 см и столовым приборам как масштабу оценены: картофельное пюре 260 г (220–310 г) и 2 крупные паровые тефтели из щуки суммарно 190 г (160–220 г). Для тефтелей использованы данные с таблички на 100 г: 106 ккал, Б 13,8 г, Ж 3,7 г, У 4,3 г; центрально 201 ккал, Б 26,2 г, Ж 7 г, У 8,2 г. Масса супа принята равной примерно 200 г по уточнению пользователя (ориентировочно 180–220 г); на фото и в составе указаны картофель, рис и куриные фрикадельки. По табличке на 100 г: около 57,6 ккал, Б 3 г, Ж 2,2 г, У 6,5 г; центрально для супа 115 ккал, Б 6 г, Ж 4,4 г, У 13 г. Пюре центрально: 286 ккал, Б 5,2 г, Ж 10,4 г, У 44,2 г. Весь обед ориентировочно 535–750 ккал, Б 33–46 г, Ж 17–28 г, У 63–88 г. Главные неопределённости: фактические масса пюре и тефтелей, рецептура пюре и возможное масло; значения табличек читаются по фотографии и применены к оценочной массе.'
WHERE calendar_day_id = (SELECT id FROM calendar_days WHERE diary_date = '2026-08-07')
  AND meal_type = 'lunch'
  AND food_name = 'Овощной салат без указанной заправки; картофельное пюре; 2 тефтели из щуки на пару; картофельный суп с куриными фрикадельками';

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'snack', 'Яблоко', 180,
    94, 0.5, 0.3, 25,
    'Центральная оценка для одного среднего яблока: около 180 г съедобной части. Ориентировочно 70–120 ккал, Б 0,3–0,7 г, Ж 0,2–0,4 г, У 19–32 г; неопределённость связана с сортом и фактическим размером.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'snack'
        AND food_name = 'Яблоко'
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба присутствует в обеде: 2 паровые тефтели из щуки.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'chicken', 'Курица присутствует в обеде: куриные фрикадельки в картофельном супе, согласно табличке состава.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'dinner',
    'Салат «Цезарь» с креветками и заправкой «Оливковое масло» из «Вкусно — и точка»',
    230, 330, 17, 24, 16,
    'Записано по описанию пользователя; точная масса порции и пищевая ценность с упаковки не предоставлены. Центральная оценка для одной ресторанной порции около 230 г, включая всю заправку: 330 ккал, Б 17 г, Ж 24 г, У 16 г. Ориентировочный диапазон: 200–260 г; 270–410 ккал, Б 14–21 г, Ж 18–32 г, У 11–23 г. Основные источники неопределённости — количество использованной масляной заправки, масса креветок, сыра и сухариков. Креветки не отмечены как база fish: схема учитывает только meat, chicken и fish, а креветки относятся к морепродуктам.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'dinner'
        AND food_name = 'Салат «Цезарь» с креветками и заправкой «Оливковое масло» из «Вкусно — и точка»'
  );

INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 5, 'Оценка дня пользователем: 5 из 5.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    rating = excluded.rating,
    notes = excluded.notes;

UPDATE calendar_days
SET notes = 'Внесены сон, утренняя пробежка, завтрак, обед, два перекуса и ужин по описанию и фотографиям пользователя. Порции, калории и БЖУ приёмов пищи оценочные; пользовательская оценка дня — 5 из 5.'
WHERE diary_date = '2026-08-07';

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'snack',
    '1,5 ржаных хлебца с консервированным тунцом; киви; маленькая груша',
    270, 236, 18.2, 1.5, 39.5,
    'Вечерний перекус по описанию пользователя. Центральные оценки: 1,5 ржаных хлебца — 15 г, 52 ккал, Б 1,5 г, Ж 0,3 г, У 10,5 г; консервированный тунец — 60 г в слитом виде, 70 ккал, Б 15,5 г, Ж 0,6 г, У 0 г; 1 киви — 75 г съедобной части, 46 ккал, Б 0,8 г, Ж 0,4 г, У 11 г; 1 маленькая груша — 120 г съедобной части, 68 ккал, Б 0,4 г, Ж 0,2 г, У 18 г. Весь перекус ориентировочно 180–330 ккал, Б 13–25 г, Ж 1–10 г, У 31–49 г. Главные неопределённости — размер хлебцев и фруктов, количество тунца, а также был ли он в собственном соку или в масле и насколько тщательно слита жидкость. Оценка перекуса ассистентом: 8/10 — много белка, есть фрукты и клетчатка, умеренная энергетическая плотность; возможны повышенные соль и жирность консервов. Значение fish отмечено из-за явно указанного тунца.'
FROM calendar_days
WHERE diary_date = '2026-08-07'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'snack'
        AND food_name = '1,5 ржаных хлебца с консервированным тунцом; киви; маленькая груша'
  );

UPDATE daily_food_bases
SET notes = 'Рыба присутствует в обеде (2 паровые тефтели из щуки) и вечернем перекусе (консервированный тунец).'
WHERE calendar_day_id = (SELECT id FROM calendar_days WHERE diary_date = '2026-08-07')
  AND base_type = 'fish';

WITH expense_data (category, amount_rub, notes) AS (
    VALUES
        ('other', 323, 'Ресторан'),
        ('groceries', 448, 'Продукты')
)
INSERT INTO expenses (calendar_day_id, category, amount_rub, notes)
SELECT d.id, e.category, e.amount_rub, e.notes
FROM calendar_days AS d
CROSS JOIN expense_data AS e
WHERE d.diary_date = '2026-08-07'
ON CONFLICT (calendar_day_id, category) DO UPDATE SET
    amount_rub = excluded.amount_rub,
    notes = excluded.notes;

UPDATE calendar_days
SET notes = 'Внесены сон, утренняя пробежка, завтрак, обед, два перекуса и ужин по описанию и фотографиям пользователя. Порции, калории и БЖУ приёмов пищи оценочные; пользовательская оценка дня — 5 из 5. Траты: ресторан — 323 ₽; продукты — 448 ₽.'
WHERE diary_date = '2026-08-07';

INSERT INTO calendar_days (diary_date, notes)
VALUES (
    '2026-08-08',
    'Внесены сон и завтрак по описанию и фотографии пользователя. Порции, калории и БЖУ завтрака оценочные.'
)
ON CONFLICT (diary_date) DO UPDATE SET notes = excluded.notes;

INSERT INTO sleep_entries (calendar_day_id, duration_minutes, notes)
SELECT
    id,
    510,
    'Продолжительность сна — 8,5 часа; время засыпания, пробуждения и качество сна не указаны.'
FROM calendar_days
WHERE diary_date = '2026-08-08'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    notes = excluded.notes;

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'breakfast',
    'Яичница из 2 яиц; мини-салат из помидора и огурца; 2 ржаных хлебца с тунцом; небольшая груша; 3 кусочка сыра маасдам',
    678, 725, 50, 37.1, 47.3,
    'Скорректировано по фотографии и описанию пользователя. На фото уверенно видны 2 жареных яйца, крупно нарезанные помидор и огурец с рукколой и тыквенными семечками, 2 ржаных хлебца и 3 ломтика маасдама; груша и тунец учтены по описанию, поскольку их порции по фото надёжно не измерить. Для масштаба принята стандартная обеденная тарелка диаметром около 25–27 см. Центральные оценки: яичница из 2 яиц с 3 г масла — 103 г, 183 ккал, Б 12,6 г, Ж 13,6 г, У 1,1 г; салат без учтённой заправки (220 г помидора, 75 г огурца, 10 г рукколы и 10 г семечек) — 315 г, 114 ккал, Б 4,5 г, Ж 5,4 г, У 13,7 г; 2 хлебца — 20 г, 70 ккал, Б 2 г, Ж 0,6 г, У 14 г; тунец в собственном соку в слитом виде — 60 г, 70 ккал, Б 15,5 г, Ж 0,6 г, У 0 г; небольшая груша — 120 г съедобной части, 68 ккал, Б 0,4 г, Ж 0,2 г, У 18 г; 3 крупных тонких ломтика маасдама — 60 г, 220 ккал, Б 15 г, Ж 16,7 г, У 0,5 г. Эта часть завтрака ориентировочно 620–850 ккал, Б 43–58 г, Ж 29–48 г, У 39–57 г. Главные неопределённости — реальный диаметр тарелки и глубина салата, количество масла, масса семечек, тунца и сыра, а также вид консервированного тунца. С учётом отдельной записи киви весь завтрак: центрально 771 ккал, Б 50,8 г, Ж 37,5 г, У 58,3 г; ориентировочно 655–910 ккал, Б 44–59 г, Ж 29–49 г, У 47–71 г. Оценка завтрака ассистентом: 8/10 — много белка, овощей и фруктов, есть клетчатка и разнообразие; сыр, тунец и семечки повышают энергетическую плотность, соль и долю жиров.'
FROM calendar_days
WHERE diary_date = '2026-08-08'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = 'Яичница из 2 яиц; мини-салат из помидора и огурца; 2 ржаных хлебца с тунцом; небольшая груша; 3 кусочка сыра маасдам'
  );

UPDATE nutrition_entries
SET
    weight_g = 678,
    calories_kcal = 725,
    protein_g = 50,
    fat_g = 37.1,
    carbs_g = 47.3,
    notes = 'Скорректировано по фотографии и описанию пользователя. На фото уверенно видны 2 жареных яйца, крупно нарезанные помидор и огурец с рукколой и тыквенными семечками, 2 ржаных хлебца и 3 ломтика маасдама; груша и тунец учтены по описанию, поскольку их порции по фото надёжно не измерить. Для масштаба принята стандартная обеденная тарелка диаметром около 25–27 см. Центральные оценки: яичница из 2 яиц с 3 г масла — 103 г, 183 ккал, Б 12,6 г, Ж 13,6 г, У 1,1 г; салат без учтённой заправки (220 г помидора, 75 г огурца, 10 г рукколы и 10 г семечек) — 315 г, 114 ккал, Б 4,5 г, Ж 5,4 г, У 13,7 г; 2 хлебца — 20 г, 70 ккал, Б 2 г, Ж 0,6 г, У 14 г; тунец в собственном соку в слитом виде — 60 г, 70 ккал, Б 15,5 г, Ж 0,6 г, У 0 г; небольшая груша — 120 г съедобной части, 68 ккал, Б 0,4 г, Ж 0,2 г, У 18 г; 3 крупных тонких ломтика маасдама — 60 г, 220 ккал, Б 15 г, Ж 16,7 г, У 0,5 г. Эта часть завтрака ориентировочно 620–850 ккал, Б 43–58 г, Ж 29–48 г, У 39–57 г. Главные неопределённости — реальный диаметр тарелки и глубина салата, количество масла, масса семечек, тунца и сыра, а также вид консервированного тунца. С учётом отдельной записи киви весь завтрак: центрально 771 ккал, Б 50,8 г, Ж 37,5 г, У 58,3 г; ориентировочно 655–910 ккал, Б 44–59 г, Ж 29–49 г, У 47–71 г. Оценка завтрака ассистентом: 8/10 — много белка, овощей и фруктов, есть клетчатка и разнообразие; сыр, тунец и семечки повышают энергетическую плотность, соль и долю жиров.'
WHERE calendar_day_id = (SELECT id FROM calendar_days WHERE diary_date = '2026-08-08')
  AND meal_type = 'breakfast'
  AND food_name = 'Яичница из 2 яиц; мини-салат из помидора и огурца; 2 ржаных хлебца с тунцом; небольшая груша; 3 кусочка сыра маасдам';

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'breakfast', 'Киви', 75,
    46, 0.8, 0.4, 11,
    'Добавлено по уточнению пользователя. Центральная оценка для одного среднего киви: 75 г съедобной части; ориентировочно 35–60 ккал, Б 0,6–1,1 г, Ж 0,3–0,5 г, У 8–14 г. Главная неопределённость — фактический размер плода.'
FROM calendar_days
WHERE diary_date = '2026-08-08'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = 'Киви'
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба присутствует на завтрак: тунец на ржаных хлебцах.'
FROM calendar_days
WHERE diary_date = '2026-08-08'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO workouts (
    calendar_day_id, workout_type, time_of_day, started_at,
    duration_minutes, calories_burned_kcal, average_heart_rate_bpm, notes
)
SELECT
    id, 'functional_strength_training', 'afternoon', '2026-08-08 16:43:00',
    49.7167, 277, 108,
    'Функционально-силовая тренировка по данным Apple Fitness: 16:43–17:33, точная длительность 49:43; активные калории — 277 ккал, всего — 348 ккал, средний пульс — 108 уд/мин. В calories_burned_kcal сохранены активные калории; RPE и максимальный пульс не указаны, поэтому субъективная интенсивность не определена.'
FROM calendar_days
WHERE diary_date = '2026-08-08'
  AND NOT EXISTS (
      SELECT 1 FROM workouts
      WHERE calendar_day_id = calendar_days.id
        AND workout_type = 'functional_strength_training'
        AND started_at = '2026-08-08 16:43:00'
        AND duration_minutes = 49.7167
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'snack', 'Банан', 120,
    105, 1.3, 0.4, 27,
    'Пользователь сообщил об одном банане без массы и фотографии. Принят средний банан: центрально 120 г съедобной части; ориентировочно 90–150 г, 80–135 ккал, Б 1–2 г, Ж 0–0,5 г, У 20–35 г. Уверенность средняя; главная неопределённость — фактический размер и масса без кожуры. Оценка перекуса: 7/10 — удобный источник углеводов и калия после тренировки, но почти без белка.'
FROM calendar_days
WHERE diary_date = '2026-08-08'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'snack'
        AND food_name = 'Банан'
  );

UPDATE calendar_days
SET notes = 'Внесены сон, завтрак, функционально-силовая тренировка и перекус (банан). Порции, калории и БЖУ питания оценочные; день остаётся в процессе заполнения.'
WHERE diary_date = '2026-08-08';

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'lunch',
    'Салат «Филадельфия»; хлебцы с тыквой и морковью; хумус; салат со шпинатом, помидором, авокадо, песто, тунцом, тыквенными семечками и оливками',
    543, 820, 39, 40, 84,
    'Пользователь сообщил состав домашнего салата, половину авокадо, 1 ч. л. песто, половину банки тунца, немного тыквенных семечек, 7 оливок, 1/4 пачки хлебцев и 1/12 банки хумуса. По читаемым этикеткам: «Филадельфия» — упаковка 180 г, на 100 г 164,1 ккал, Б 5,3 г, Ж 6,9 г, У 20,2 г; хлебцы — пачка 150 г, на 100 г 408,1 ккал, Б 11,1 г, Ж 5,7 г, У 78,1 г; хумус — на 100 г 184,7 ккал, Б 12 г, Ж 11,1 г, У 9,2 г, но масса банки на фото не читается. Центрально: «Филадельфия» 180 г — 295 ккал, Б 9,5 г, Ж 12,4 г, У 36,4 г; хлебцы 37,5 г — 153 ккал, Б 4,2 г, Ж 2,1 г, У 29,3 г; хумус около 17 г (допущение: банка 200 г) — 31 ккал, Б 2 г, Ж 1,9 г, У 1,6 г; домашний салат около 309 г — 341 ккал, Б 23,3 г, Ж 23,6 г, У 16,7 г. Для домашнего салата приняты: шпинат 30 г, помидор 120 г, съедобная часть половины авокадо 75 г, песто 5 г, тунец в слитом виде 60 г, семечки 8 г и оливки 11 г. Весь обед ориентировочно 720–950 ккал, Б 34–45 г, Ж 32–49 г, У 75–95 г. Уверенность средняя; главные неопределённости — масса банки хумуса, размер авокадо и фактические порции тунца/семечек. Оценка обеда ассистентом: 8/10 — много белка, овощей и источников ненасыщенных жиров; одновременно готовый салат, тунец, оливки и хлебцы могут дать заметно соли, а авокадо, песто и семечки повышают энергетическую плотность.'
FROM calendar_days
WHERE diary_date = '2026-08-08'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'lunch'
        AND food_name = 'Салат «Филадельфия»; хлебцы с тыквой и морковью; хумус; салат со шпинатом, помидором, авокадо, песто, тунцом, тыквенными семечками и оливками'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'snack', 'Половина манго', 100,
    60, 0.8, 0.4, 15,
    'Пользователь сообщил о половине манго без массы и фотографии. Центрально приняты 100 г съедобной мякоти; ориентировочно 75–140 г и 45–85 ккал, Б 0,5–1,2 г, Ж 0,2–0,6 г, У 11–21 г. Уверенность средняя; главная неопределённость — размер плода и масса кожуры с косточкой. Оценка перекуса: 7/10 — фрукт добавляет витамин C и разнообразие, но почти не содержит белка.'
FROM calendar_days
WHERE diary_date = '2026-08-08'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'snack'
        AND food_name = 'Половина манго'
  );

UPDATE daily_food_bases
SET notes = 'Рыба присутствует на завтрак и в обед: консервированный тунец; в салате «Филадельфия» указан слабосолёный лосось.'
WHERE calendar_day_id = (SELECT id FROM calendar_days WHERE diary_date = '2026-08-08')
  AND base_type = 'fish';

UPDATE calendar_days
SET notes = 'Внесены сон, завтрак, функционально-силовая тренировка, обед и перекусы (банан и половина манго). Порции, калории и БЖУ питания оценочные; день остаётся в процессе заполнения.'
WHERE diary_date = '2026-08-08';

-- Дополнение к ужину и завершение дневника за 6 августа.
INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'dinner', '2 варёных яйца', 100,
    156, 12.6, 10.6, 1.1,
    'Количество указано пользователем; масса не указана. Центрально приняты 2 средних яйца и 100 г съедобной части. Ориентировочно 88–110 г, 140–175 ккал, Б 11,5–14 г, Ж 9,5–12 г, У 0,8–1,3 г. Уверенность средняя; главная неопределённость — размер яиц.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'dinner'
        AND food_name = '2 варёных яйца'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'dinner', 'Киви', 75,
    46, 0.8, 0.4, 11,
    'Количество указано пользователем; масса не указана. Центрально принят 1 средний киви и 75 г съедобной части. Ориентировочно 60–100 г, 35–60 ккал, Б 0,6–1,1 г, Ж 0,3–0,5 г, У 8–14 г. Уверенность средняя; главная неопределённость — размер плода.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'dinner'
        AND food_name = 'Киви'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'dinner', '3 ореха пекана', 9,
    62, 0.8, 6.5, 1.3,
    'Количество указано пользователем; масса и то, считались ли половинки ядра отдельными орехами, не указаны. Центрально приняты 3 целых ядра (6 половинок), около 9 г. Ориентировочно 5–12 г, 35–85 ккал, Б 0,5–1,1 г, Ж 3,5–8,5 г, У 0,7–1,7 г. Уверенность низкая; главная неопределённость — способ подсчёта и размер ядер.'
FROM calendar_days
WHERE diary_date = '2026-08-06'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'dinner'
        AND food_name = '3 ореха пекана'
  );

UPDATE calendar_days
SET notes = 'Внесены сон, бег, все перечисленные приёмы пищи, включая дополнение к ужину из 2 варёных яиц, киви и 3 орехов пекана, шахматы, итоговая пользовательская оценка дня 3 из 5 и отсутствие расходов. Размеры порций, калории и БЖУ оценочные; день завершён.'
WHERE diary_date = '2026-08-06';

UPDATE calendar_days
SET status = CASE
    WHEN diary_date BETWEEN '2026-08-04' AND '2026-08-07' THEN 'complete'
    ELSE 'in_progress'
END
WHERE diary_date BETWEEN '2026-08-04' AND '2026-08-08';

-- Утро 9 августа: сон и завтрак по описанию пользователя.
INSERT INTO calendar_days (diary_date, status, notes)
VALUES (
    '2026-08-09', 'in_progress',
    'Внесены сон и завтрак по описанию пользователя. Порции, калории и БЖУ завтрака оценочные; день остаётся в процессе заполнения.'
)
ON CONFLICT (diary_date) DO UPDATE SET
    status = 'in_progress',
    notes = excluded.notes;

INSERT INTO sleep_entries (
    calendar_day_id, duration_minutes, quality_score, notes
)
SELECT
    id, 480, 4,
    'Пользователь сообщил 8 часов сна и хорошее состояние утром. Quality score 4/5 сохранён как отображение словесной оценки «хорошее», а не как отдельная числовая оценка пользователя; время засыпания и пробуждения не указано.'
FROM calendar_days
WHERE diary_date = '2026-08-09'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    quality_score = excluded.quality_score,
    notes = excluded.notes;

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'breakfast',
    'Салат со шпинатом, помидором, авокадо, тыквенными семечками и оливковым маслом; яичница из 2 яиц; 3 слайса сыра маасдам; хлебцы с хумусом; яблоко',
    526, 696, 29.4, 42.6, 54.1,
    'Пользователь указал: шпинат 30 г, один небольшой помидор, половину авокадо, немного тыквенных семечек, чуть-чуть оливкового масла, яичницу из 2 яиц, 3 слайса маасдама, яблоко и хлебцы с хумусом в количестве половины порции от 8 августа. Центральные допущения: помидор 100 г, съедобная часть авокадо 75 г, семечки 8 г, масло в салате 3 г, яйца 100 г плюс 3 г масла для жарки, сыр 30 г, яблоко 150 г съедобной части. Половина прежней порции — 18,75 г хлебцев и 8,25 г хумуса; для них применена та же этикетка. Компоненты центрально: салат — 216 ккал, Б 5,7 г, Ж 18,1 г, У 12,2 г; яичница — 183 ккал, Б 12,6 г, Ж 13,6 г, У 1,1 г; маасдам — 110 ккал, Б 7,5 г, Ж 8,4 г, У 0,3 г; хлебцы с хумусом — 92 ккал, Б 3,1 г, Ж 2 г, У 15,4 г; яблоко — 95 ккал, Б 0,5 г, Ж 0,5 г, У 25,1 г. Весь завтрак ориентировочно 575–835 ккал, Б 25–35 г, Ж 32–53 г, У 45–68 г. Уверенность средняя; главные неопределённости — масса сыра и авокадо, количество масла и семечек. Оценка завтрака ассистентом: 8/10 — достаточно белка, есть овощи, фрукт, семечки и источники ненасыщенных жиров; сыр, авокадо, семечки и масла одновременно делают завтрак довольно энергоёмким, а сыр и хумус могут добавить соли. Проверка по БЖУ даёт около 717 ккал; расхождение с табличной суммой около 3% связано с округлением и клетчаткой.'
FROM calendar_days
WHERE diary_date = '2026-08-09'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = 'Салат со шпинатом, помидором, авокадо, тыквенными семечками и оливковым маслом; яичница из 2 яиц; 3 слайса сыра маасдам; хлебцы с хумусом; яблоко'
  );

-- Остальная часть 9 августа: тренировка, обед, ужин и перекусы.
UPDATE calendar_days
SET notes = 'Внесены сон, завтрак, обед, ужин, перекусы и 60-минутная новичковая тренировка по скалолазанию. Обед рассчитан по читаемой этикетке; остальные порции, калории и БЖУ оценочные. День остаётся в процессе заполнения.'
WHERE diary_date = '2026-08-09';

-- 10 августа: сон, завтрак и обед по описанию и фотографиям пользователя.
INSERT INTO calendar_days (diary_date, status, notes)
VALUES (
    '2026-08-10', 'in_progress',
    'Внесены сон, завтрак и обед по описанию и фотографиям пользователя. Масса двух салатов и их БЖУ взяты с читаемых карточек; остальные порции оценочные. День остаётся в процессе заполнения.'
)
ON CONFLICT (diary_date) DO UPDATE SET
    status = 'in_progress',
    notes = excluded.notes;

INSERT INTO sleep_entries (calendar_day_id, duration_minutes, notes)
SELECT id, 420,
    'Пользователь сообщил 7 часов сна; время засыпания, пробуждения и субъективная оценка качества не указаны.'
FROM calendar_days
WHERE diary_date = '2026-08-10'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    quality_score = NULL,
    notes = excluded.notes;

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'breakfast',
    'Овощной салат; яичница из 2 яиц; куриная грудка су-вид; фасоль; яблоко',
    655, 545, 43.4, 17.3, 57.4,
    'Пользователь указал салат из айсберга, помидора, огурца, небольшого количества моркови и перца, яичницу из 2 яиц, кусок куриной грудки су-вид, немного фасоли и яблоко. На фото видны перечисленные овощи, 2 яйца, белая фасоль и кусок грудки; яблоко вне кадра. На карточке грудки читаются состав (филе грудки, подсолнечное масло, соль, перец) и значения на 100 г: 133 ккал, Б 27 г, Ж 2,6 г, У 0,5 г. Центрально принято: овощи 250 г — 70 ккал, Б 3 г, Ж 1 г, У 13 г; яйца 100 г и около 3 г масла — 180 ккал, Б 12,6 г, Ж 13,5 г, У 1 г; грудка 75 г — 100 ккал, Б 20,3 г, Ж 2 г, У 0,4 г; фасоль 80 г — 100 ккал, Б 7 г, Ж 0,5 г, У 18 г; яблоко 150 г — 95 ккал, Б 0,5 г, Ж 0,3 г, У 25 г. Ориентировочно весь завтрак: 465–650 ккал, Б 37–51 г, Ж 13–24 г, У 47–70 г. Сценарий без масла для яиц — примерно на 27 ккал и 3 г жира меньше. Уверенность средняя; главные неопределённости — масса грудки и фасоли, количество масла и размер яблока. Проверка по БЖУ даёт около 559 ккал; расхождение около 3% связано с округлением и клетчаткой. Оценка завтрака ассистентом: 9/10 — высокая доля белка, бобовые, фрукт и разнообразные овощи; вероятные соль в готовой грудке и неизвестное масло немного снижают оценку.'
FROM calendar_days
WHERE diary_date = '2026-08-10'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = 'Овощной салат; яичница из 2 яиц; куриная грудка су-вид; фасоль; яблоко'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'lunch',
    'Грибной суп; салат «Свежесть»; салат «Нисуаз» с тунцом; булгур с овощами; куриная кнель на пару',
    1065, 795, 29, 38.7, 76.4,
    'Пользователь сообщил грибной суп, два салата по 165 г, булгур с овощами и одну куриную кнель на пару. На фото видны все блюда. Для салата «Свежесть» на карточке читаются Б 1,16 г, Ж 9,03 г, У 6,10 г и 110,33 ккал на 100 г; на 165 г это 182 ккал, Б 1,9 г, Ж 14,9 г, У 10,1 г. Для «Нисуаза» читаются Б 6,8 г, Ж 8,35 г, У 5,87 г и 128,78 ккал на 100 г; на 165 г это 212 ккал, Б 11,2 г, Ж 13,8 г, У 9,7 г. Центрально также принято: суп 300 г — 90 ккал, Б 3 г, Ж 3 г, У 10 г; булгур с овощами 345 г — 260 ккал, Б 6 г, Ж 5 г, У 45 г; кнель 90 г — 51 ккал, Б 6,9 г, Ж 2 г, У 1,6 г по читаемой карточке (57 ккал, Б 7,7 г, Ж 2,2 г, У 1,8 г на 100 г). Ориентировочно весь обед: 675–930 ккал, Б 25–35 г, Ж 31–48 г, У 63–91 г. Уверенность средняя: точные массы и карточки двух салатов повышают надёжность, основные неопределённости — объём и рецепт супа, масса булгура и кнели. Проверка по БЖУ даёт около 770 ккал; расхождение около 3% связано с округлением и клетчаткой. Оценка обеда ассистентом: 8/10 — есть цельное зерно, овощи и белок из курицы, тунца и яйца; две заправленные салатные порции заметно увеличивают жирность и, вероятно, соль.'
FROM calendar_days
WHERE diary_date = '2026-08-10'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'lunch'
        AND food_name = 'Грибной суп; салат «Свежесть»; салат «Нисуаз» с тунцом; булгур с овощами; куриная кнель на пару'
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'chicken', 'Курица присутствует на завтрак (грудка су-вид) и в обед (кнель на пару).'
FROM calendar_days WHERE diary_date = '2026-08-10'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба присутствует в обеде: тунец в салате «Нисуаз».'
FROM calendar_days WHERE diary_date = '2026-08-10'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

-- Вечер 10 августа: перекус, ужин и итоговая пользовательская оценка дня.
INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'snack',
    'Зелёное яблоко; банан; 60 г сэндвича «Цезарь»',
    330, 330, 8.2, 6.5, 65.0,
    'Пользователь указал зелёное яблоко, банан и ровно 60 г сэндвича. На этикетке сэндвича «Цезарь» читаются масса целого изделия 150 г и значения на 100 г: 217 ккал, Б 10,7 г, Ж 9,6 г, У 21,7 г; для съеденных 60 г это 130 ккал, Б 6,4 г, Ж 5,8 г, У 13 г. Для фруктов приняты типовые съедобные порции: яблоко 150 г — 95 ккал, Б 0,5 г, Ж 0,3 г, У 25 г; банан 120 г — 105 ккал, Б 1,3 г, Ж 0,4 г, У 27 г. Ориентировочно весь перекус: 290–375 ккал, Б 7,5–9 г, Ж 6–7 г, У 54–75 г; центрально 330 ккал, Б 8,2 г, Ж 6,5 г, У 65 г. Уверенность средняя: порция и этикетка сэндвича известны точно, основные неопределённости — размеры фруктов. Проверка по БЖУ даёт около 351 ккал; расхождение около 6% объясняется клетчаткой, округлением фруктов и маркировки. Оценка перекуса ассистентом: 7/10 — два фрукта добавляют клетчатку и калий, сэндвич даёт немного белка, но также вероятно заметное количество соли и соуса.'
FROM calendar_days
WHERE diary_date = '2026-08-10'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'snack'
        AND food_name = 'Зелёное яблоко; банан; 60 г сэндвича «Цезарь»'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'dinner',
    '4 стебля сельдерея; морковь; хлебцы с хумусом; овощное рагу с креветками; киви',
    849, 611, 41.8, 16.9, 76.3,
    'Пользователь указал 4 стебля сельдерея, одну морковь, немного хлебцев с хумусом, овощное рагу с креветками и киви. На фото отчётливо видны очищенные креветки и рагу с брокколи, сладким перцем, морковью, сельдереем и другими мягкими овощами в соусе; точная глубина порции, рецепт, масло и вес не известны. Центрально принято: сельдерей 160 г — 25 ккал, Б 1,1 г, Ж 0,3 г, У 4,8 г; морковь 80 г — 33 ккал, Б 0,7 г, Ж 0,2 г, У 7,7 г; небольшая прежняя порция хлебцев 37,5 г и хумуса 16,5 г — 184 ккал, Б 6,2 г, Ж 4 г, У 30,8 г; креветки 140 г — 140 ккал, Б 29 г, Ж 2 г, У 0 г; овощи рагу 280 г — 120 ккал, Б 4 г, Ж 3 г, У 21 г; возможное масло/соус 7 г — 63 ккал и 7 г жира; киви 75 г — 46 ккал, Б 0,8 г, Ж 0,4 г, У 12 г. Ориентировочно весь ужин: 475–780 ккал, Б 32–51 г, Ж 9–26 г, У 60–94 г; центрально 611 ккал, Б 41,8 г, Ж 16,9 г, У 76,3 г. Сценарий без учтённого масла/жирного соуса — около 548 ккал и 9,9 г жира. Уверенность низкая; главные неопределённости — масса креветок и глубина овощной порции, количество хлебцев с хумусом, масло и состав соуса. Проверка по БЖУ даёт около 624 ккал; расхождение около 2% связано с клетчаткой и округлением. Оценка ужина ассистентом: 9/10 — много овощей и фрукт, креветки обеспечивают полноценный белок; возможные масло, соус, хумус и хлебцы повышают энергоёмкость и соль.'
FROM calendar_days
WHERE diary_date = '2026-08-10'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'dinner'
        AND food_name = '4 стебля сельдерея; морковь; хлебцы с хумусом; овощное рагу с креветками; киви'
  );

INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 3, 'Итоговая оценка дня 3 из 5 сообщена пользователем.'
FROM calendar_days
WHERE diary_date = '2026-08-10'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    rating = excluded.rating,
    notes = excluded.notes;

UPDATE calendar_days
SET status = 'complete',
    notes = 'Внесены сон, завтрак, обед, вечерний перекус, ужин и итоговая пользовательская оценка дня 3 из 5. Этикетки салатов и сэндвича учтены; остальные порции, калории и БЖУ оценочные. День завершён.'
WHERE diary_date = '2026-08-10';

INSERT INTO workouts (
    calendar_day_id, workout_type, duration_minutes, notes
)
SELECT
    id, 'Скалолазание', 60,
    'Новичковая тренировка по сообщению пользователя. RPE, пульс и время суток не указаны, поэтому физиологическая интенсивность остаётся неизвестной. Калории не оценивались: продолжительности и общего описания недостаточно для надёжного определения фактической нагрузки и времени активного лазания.'
FROM calendar_days
WHERE diary_date = '2026-08-09'
  AND NOT EXISTS (
      SELECT 1 FROM workouts
      WHERE calendar_day_id = calendar_days.id
        AND workout_type = 'Скалолазание'
        AND duration_minutes = 60
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'lunch', 'Ролл с лососем «Филадельфия»', 160,
    365, 15.2, 16, 40,
    'Пользователь сообщил, что ролл с лососем съеден полностью. На фотографии этикетки читаются масса порции 160 г, 365 ккал на порцию и значения на 100 г: белки 9,5 г, жиры 10 г, углеводы 25 г; отсюда для 160 г: Б 15,2 г, Ж 16 г, У 40 г. Проверка 4×Б + 9×Ж + 4×У = 364,8 ккал согласуется с этикеткой. Диапазон равен центральной оценке (160 г и 365 ккал), поскольку масса, полное употребление и этикетка известны. Уверенность высокая; остаточная неопределённость — только допустимое округление маркировки и не полностью видимое название продукта. Оценка обеда ассистентом: 7/10 — есть рыба и умеренная порция, но мало овощей и клетчатки, а рис, сливочный компонент и соль повышают долю быстрых углеводов, жира и натрия.'
FROM calendar_days
WHERE diary_date = '2026-08-09'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'lunch'
        AND food_name = 'Ролл с лососем «Филадельфия»'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'dinner', 'Лосось с тушёными овощами и укропом', 445,
    515, 44, 28, 19,
    'Пользователь указал лосось и тушёные баклажан, кабачок, помидор, перец, морковь и сельдерей, посыпанные укропом. На фото видны один кусок приготовленного лосося, порция разноцветных тушёных овощей, укроп, лимон и несколько соцветий брокколи; брокколи учтена как отдельно видимый компонент, лимон — как гарнир с пренебрежимо малой съеденной долей. Центрально принято: лосось 180 г — 375 ккал, Б 40 г, Ж 23 г; овощи и укроп 260 г — 95 ккал, Б 4 г, Ж 0,5 г, У 19 г; возможное масло 5 г — 45 ккал. Ориентировочно весь ужин: 400–650 ккал, Б 34–53 г, Ж 19–39 г, У 14–27 г. Без добавленного масла центральная оценка была бы около 470 ккал и 23 г жира. Уверенность средняя; главные неопределённости — масса лосося, глубина овощной порции и количество масла при тушении/жарке. Проверка по БЖУ даёт около 504 ккал; расхождение около 2% связано с округлением и клетчаткой. Оценка ужина ассистентом: 9/10 — много белка, рыба с омега-3 и разнообразные овощи; основной переменный фактор энергетической плотности — масло.'
FROM calendar_days
WHERE diary_date = '2026-08-09'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'dinner'
        AND food_name = 'Лосось с тушёными овощами и укропом'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'snack', 'Манго; хлебцы с хумусом; тыквенные семечки; миндаль', 197,
    290, 8.5, 12.5, 39,
    'Пользователь указал манго, хлебцы с хумусом «как в прошлый раз», чуть-чуть тыквенных семечек и миндаля; массы не указаны. «Как в прошлый раз» трактовано как наиболее недавняя порция хлебцев с хумусом в завтраке этого дня: 18,75 г хлебцев и 8,25 г хумуса. Центрально также принято 150 г съедобной части манго, 10 г тыквенных семечек и 10 г миндаля. Компоненты: манго — около 90 ккал, Б 1 г, Ж 0,5 г, У 22,5 г; хлебцы с хумусом — 92 ккал, Б 3,1 г, Ж 2 г, У 15,4 г; семечки — 56 ккал, Б 3 г, Ж 4,9 г, У 1,1 г; миндаль — 58 ккал, Б 2,1 г, Ж 5 г, У 2,2 г. Из-за округления запись сохранена как 290 ккал. Ориентировочно: 210–410 ккал, Б 6–12 г, Ж 8–21 г, У 27–54 г. Уверенность низкая; главные неопределённости — порция манго, смысл «как в прошлый раз» и размер двух небольших горстей. Оценка перекусов ассистентом: 8/10 — фрукты, цельнозерновые хлебцы, бобовые, орехи и семечки дают разнообразие и клетчатку, но орехи и семечки легко увеличивают калорийность при большей горсти.'
FROM calendar_days
WHERE diary_date = '2026-08-09'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'snack'
        AND food_name = 'Манго; хлебцы с хумусом; тыквенные семечки; миндаль'
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба присутствует в обеде и ужине: ролл с лососем и порция приготовленного лосося.'
FROM calendar_days
WHERE diary_date = '2026-08-09'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

-- Завершение 9 августа по уточнению пользователя.
INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT
    id, 'snack', 'Киви', 75,
    46, 0.8, 0.4, 11,
    'Один киви добавлен по сообщению пользователя; масса не указана. Центрально приняты 75 г съедобной части, 46 ккал, Б 0,8 г, Ж 0,4 г, У 11 г; ориентировочно 35–60 ккал, Б 0,6–1,1 г, Ж 0,3–0,5 г, У 8–14 г. Уверенность средняя; основная неопределённость — размер плода. Оценка перекуса ассистентом: 9/10 — фрукт добавляет клетчатку и витамин C при умеренной энергетической плотности.'
FROM calendar_days
WHERE diary_date = '2026-08-09'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'snack'
        AND food_name = 'Киви'
  );

INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 3, 'Пользовательская итоговая оценка дня — 3 из 5.'
FROM calendar_days
WHERE diary_date = '2026-08-09'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    rating = excluded.rating,
    notes = excluded.notes;

UPDATE calendar_days
SET
    status = 'complete',
    notes = 'День завершён пользователем. Внесены сон, завтрак, обед, ужин, перекусы, включая киви, и 60-минутная новичковая тренировка по скалолазанию. Обед рассчитан по читаемой этикетке; остальные порции, калории и БЖУ оценочные. Пользовательская итоговая оценка дня — 3 из 5.'
WHERE diary_date = '2026-08-09';

-- 11 августа: сон, завтрак и обед по описанию пользователя.
INSERT INTO calendar_days (diary_date, status, notes)
VALUES (
    '2026-08-11', 'in_progress',
    'Внесены неспокойный сон продолжительностью 7 часов, завтрак и обед по описанию пользователя. Точные массы обеда сохранены; порции завтрака и состав смешанных блюд оценочные. День остаётся в процессе заполнения.'
)
ON CONFLICT (diary_date) DO UPDATE SET
    status = 'in_progress',
    notes = excluded.notes;

INSERT INTO sleep_entries (calendar_day_id, duration_minutes, notes)
SELECT id, 420,
    'Пользователь сообщил 7 часов неспокойного сна с кошмарами; время засыпания и пробуждения не указано. Числовая оценка качества не выводилась из описания.'
FROM calendar_days
WHERE diary_date = '2026-08-11'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    quality_score = NULL,
    notes = excluded.notes;

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'breakfast',
    'Яичница из 2 яиц; овощной салат; куриная грудка су-вид; фриттата из кабачков и моркови; яблоко',
    568, 508, 38.4, 21.5, 42.4,
    'Наблюдаемые факты (со слов пользователя): яичница из 2 яиц, стандартный небольшой салат из свежих овощей как в прошлые будние завтраки, ранее встречавшийся кусок грудки су-вид, небольшой кусок фриттаты из кабачков и моркови и одно яблоко. Фото и новые массы не предоставлены. Уточнение пользователя: утренний салат весил около 170 г; первоначальная оценка 250 г пересмотрена, исходное основание оценки сохранено в этой заметке. Допущения: состав салата перенесён из наиболее близкой записи 10 августа, а его компоненты пропорционально уменьшены до 170 г (айсберг 68 г, помидор 48 г, огурец 34 г, морковь 10 г, сладкий перец 10 г); для грудки повторены 75 г по прежней этикетке; для яиц приняты 100 г съедобной части и 3 г масла; для небольшого куска фриттаты — 70 г; для яблока — 150 г съедобной части. Центрально: салат 48 ккал, Б 2 г, Ж 0,7 г, У 9 г; яйца с маслом 180 ккал, Б 12,6 г, Ж 13,5 г, У 1 г; грудка 100 ккал, Б 20,3 г, Ж 2 г, У 0,4 г; фриттата 85 ккал, Б 3 г, Ж 5 г, У 7 г; яблоко 95 ккал, Б 0,5 г, Ж 0,3 г, У 25 г. Ориентировочно весь завтрак: 410–620 ккал, Б 32–46 г, Ж 14–30 г, У 33–56 г. Сценарий без учтённого масла для яичницы — примерно на 27 ккал и 3 г жира меньше. Уверенность средняя-низкая; главные неопределённости — размер и рецепт фриттаты, фактическая порция салата и количество масла. Проверка 4×Б + 9×Ж + 4×У даёт около 517 ккал; расхождение около 2% связано с округлением и клетчаткой. Оценка завтрака ассистентом: 9/10 — много белка, овощное разнообразие и фрукт; возможные масло и соль в готовой грудке остаются переменными факторами.'
FROM calendar_days
WHERE diary_date = '2026-08-11'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'breakfast'
        AND food_name = 'Яичница из 2 яиц; овощной салат; куриная грудка су-вид; фриттата из кабачков и моркови; яблоко'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'lunch',
    'Салат коул-слоу; филе трески на пару; рис отварной',
    295, 355, 23.0, 7.5, 48.0,
    'Наблюдаемые факты (со слов пользователя): 65 г салата коул-слоу, 80 г филе трески на пару и 150 г отварного риса. Фото, этикетка и рецепт салата не предоставлены. Допущения: коул-слоу рассчитан как капустно-морковный салат с умеренной майонезной заправкой — центрально 90 ккал, Б 1 г, Ж 7 г, У 6 г; треска 80 г — 70 ккал, Б 18 г, Ж 0 г, У 0 г; белый отварной рис 150 г — 195 ккал, Б 4 г, Ж 0,5 г, У 42 г. Ориентировочно весь обед: 300–430 ккал, Б 21–26 г, Ж 3–14 г, У 44–53 г. Для коул-слоу без жирной заправки итог может быть примерно на 45–60 ккал ниже. Уверенность средняя: массы всех блюд указаны точно; главная неопределённость — рецепт и количество заправки коул-слоу, затем разновидность риса. Проверка 4×Б + 9×Ж + 4×У даёт около 352 ккал и согласуется с центральной оценкой. Оценка обеда ассистентом: 8/10 — треска даёт нежирный белок, салат добавляет овощи, а рис — углеводы; количество клетчатки умеренное, а жирность и соль зависят главным образом от заправки.'
FROM calendar_days
WHERE diary_date = '2026-08-11'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id
        AND meal_type = 'lunch'
        AND food_name = 'Салат коул-слоу; филе трески на пару; рис отварной'
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'chicken', 'Курица присутствует на завтрак: грудка су-вид.'
FROM calendar_days WHERE diary_date = '2026-08-11'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба присутствует в обеде: филе трески на пару.'
FROM calendar_days WHERE diary_date = '2026-08-11'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

-- Итоговая пользовательская оценка 11 августа.
INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 1,
    'Пользователь сообщил итоговую оценку 1 из 10. Для обязательной шкалы дневника 1–5 сохранено значение 1 из 5 как соответствующая минимальная оценка; исходная формулировка 1/10 сохранена дословно.'
FROM calendar_days
WHERE diary_date = '2026-08-11'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    rating = excluded.rating,
    notes = excluded.notes;

UPDATE calendar_days
SET status = 'complete',
    notes = 'День завершён после итоговой пользовательской оценки 1 из 10. В дневниковой шкале 1–5 сохранена соответствующая минимальная оценка 1 из 5; исходная оценка 1/10 сохранена в примечании. Внесены неспокойный сон продолжительностью 7 часов, завтрак и обед; точные массы обеда и уточнённая масса утреннего салата 170 г сохранены, остальные порции и смешанные блюда оценочные.'
WHERE diary_date = '2026-08-11';

-- Данные за 12 августа: день остаётся открытым до итоговой оценки пользователя.
INSERT INTO calendar_days (diary_date, status, notes)
VALUES (
    '2026-08-12', 'in_progress',
    'Записаны сон, завтрак, обед, ужин и перекусы. День остаётся открытым: итоговая пользовательская оценка не сообщена.'
)
ON CONFLICT (diary_date) DO UPDATE SET
    status = excluded.status,
    notes = excluded.notes;

INSERT INTO sleep_entries (calendar_day_id, duration_minutes, notes)
SELECT id, 720, 'Пользователь сообщил продолжительность сна 12 часов; время начала, окончания и качество не указаны.'
FROM calendar_days WHERE diary_date = '2026-08-12'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    notes = excluded.notes;

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'breakfast', '2 варёных яйца; рис отварной', 170,
    246, 14.5, 10.8, 20.8,
    'Со слов пользователя: 2 варёных яйца и 70 г отварного риса. Центрально принята съедобная масса яиц 100 г (примерно 90–120 г): 155 ккал, Б 12,6 г, Ж 10,6 г, У 1,1 г; рис по указанной массе: 91 ккал, Б 1,9 г, Ж 0,2 г, У 19,7 г. Итого ориентировочно 230–280 ккал, Б 13–17 г, Ж 9–13 г, У 19–23 г. Уверенность высокая; основная неопределённость — фактический размер яиц и сорт риса. Проверка по БЖУ даёт около 239 ккал; небольшая разница связана с округлением и особенностями справочного профиля. Оценка завтрака ассистентом: 7/10 — есть белок и углеводы, но почти нет овощей, фруктов и клетчатки.'
FROM calendar_days WHERE diary_date = '2026-08-12'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'breakfast'
        AND food_name = '2 варёных яйца; рис отварной'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'lunch', 'Куриный бульон', 350,
    70, 7.0, 3.5, 2.0,
    'Со слов пользователя: 350 г куриного бульона. Фото, рецепт, количество мяса, кожи, жира, овощей и лапши не предоставлены. Центрально принят преимущественно прозрачный бульон с небольшим количеством курицы: 70 ккал, Б 7 г, Ж 3,5 г, У 2 г. Реалистичный диапазон 35–160 ккал, Б 3–15 г, Ж 1–10 г, У 0–8 г; вариант с заметным мясом или лапшой ближе к верхней границе. Уверенность низкая; основные неопределённости — количество курицы, снят ли жир и были ли крахмалистые добавки. Проверка по БЖУ даёт около 68 ккал. Оценка обеда ассистентом: 5/10 — порция даёт жидкость и немного белка, но как самостоятельный обед, вероятно, малосытна и бедна клетчаткой.'
FROM calendar_days WHERE diary_date = '2026-08-12'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'lunch'
        AND food_name = 'Куриный бульон'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'dinner', 'Рис; стручковая фасоль; варёные яйца — двойная порция', 705,
    695, 26.4, 17.4, 109.4,
    'Со слов пользователя: рис, стручковая фасоль и яйцо, двойная порция. Массы, число яиц, способ приготовления и масло не указаны. Допущение для центральной оценки: одна порция — 150 г отварного риса, 150 г отварной стручковой фасоли и 1 яйцо; двойная порция — 300 г риса, 300 г фасоли, 2 яйца (100 г съедобной части), плюс 5 г возможного масла отдельно. Центрально: рис 390 ккал, Б 8,1 г, Ж 0,9 г, У 84,6 г; фасоль 105 ккал, Б 5,7 г, Ж 0,9 г, У 23,7 г; яйца 155 ккал, Б 12,6 г, Ж 10,6 г, У 1,1 г; масло 45 ккал и 5 г жира. Ориентировочно 500–900 ккал, Б 20–35 г, Ж 11–30 г, У 75–145 г; без масла центральный итог 650 ккал. Уверенность низкая; главные неопределённости — значение «порции», количество яиц и масла. Проверка по БЖУ даёт около 699 ккал. Оценка ужина ассистентом: 7/10 — фасоль добавляет овощи и клетчатку, яйца дают белок, но двойная порция риса делает блюдо углеводно-плотным.'
FROM calendar_days WHERE diary_date = '2026-08-12'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'dinner'
        AND food_name = 'Рис; стручковая фасоль; варёные яйца — двойная порция'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'snack',
    'Овсяное печенье; 3 фруктовых пюре; 2 упаковки фруктовых кусочков; мультизлаковые хрустящие кусочки; банан',
    426, 788, 8.0, 23.4, 139.1,
    'Пользователь указал перекусы на фото и банан; принято, что съедены все семь сфотографированных целых упаковок. По читаемым этикеткам: овсяное печенье 85 г, 443 ккал/100 г, Б 5 г, Ж 26,5 г, У 46 г — 377 ккал, Б 4,3 г, Ж 22,5 г, У 39,1 г; яблочно-черничное пюре с печеньем 90 г, 51,6 ккал/100 г, Б 0,5 г, У 12,4 г — 46 ккал, Б 0,5 г, У 11,2 г; фруктовые кусочки яблоко–персик–маракуйя 15 г, 280 ккал и У 70 г/100 г — 42 ккал, У 10,5 г; пюре яблоко–банан–клубника–киви 90 г, 52 ккал и У 13 г/100 г — 47 ккал, У 11,7 г; пюре яблоко–клубника–земляника–клюква 80 г, 60 ккал и У 15 г/100 г — 48 ккал, У 12 г; фруктовые кусочки яблоко–вишня 15 г, 277,2 ккал и У 69,3 г/100 г — 42 ккал, У 10,4 г; мультизлаковые хрустящие кусочки 21 г, 377 ккал, Б 9,3 г, Ж 2,2 г, У 80 г/100 г — 79 ккал, Б 2 г, Ж 0,5 г, У 16,8 г. Банан без указанной массы принят как 120 г съедобной части: 107 ккал, Б 1,3 г, Ж 0,4 г, У 27,4 г. Диапазон всего перекуса примерно 760–830 ккал, Б 7–10 г, Ж 22–25 г, У 132–149 г; диапазон отражает главным образом размер банана и округление этикеток, но не неполное употребление упаковок. Уверенность высокая для упаковок и средняя для банана. Калорийность печенья выше расчёта 4×Б + 9×Ж + 4×У примерно на 18%; вероятная причина — нераскрытые на этикетке углеводные фракции/округление, поэтому сохранена заявленная производителем энергия. Оценка перекуса ассистентом: 4/10 — есть фруктовое разнообразие, но почти половина дневной энергии перекуса приходится на жирное печенье, а большая часть остальных углеводов поступает из переработанных фруктовых продуктов с невысокой сытостью.'
FROM calendar_days WHERE diary_date = '2026-08-12'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'snack'
        AND food_name = 'Овсяное печенье; 3 фруктовых пюре; 2 упаковки фруктовых кусочков; мультизлаковые хрустящие кусочки; банан'
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'chicken', 'Курица явно указана в обеде: куриный бульон.'
FROM calendar_days WHERE diary_date = '2026-08-12'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

-- Итоговая пользовательская оценка за 12 августа завершает день.
INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 3, 'Оценка дня пользователем: 3 из 5.'
FROM calendar_days WHERE diary_date = '2026-08-12'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    rating = excluded.rating,
    notes = excluded.notes;

UPDATE calendar_days
SET status = 'complete',
    notes = 'Записаны сон, завтрак, обед, ужин и перекусы. День завершён после итоговой пользовательской оценки 3 из 5.'
WHERE diary_date = '2026-08-12';

-- Данные за 13 августа: день остаётся открытым для возможных дополнений.
INSERT INTO calendar_days (diary_date, status, notes)
VALUES (
    '2026-08-13', 'in_progress',
    'Записаны сон и питание за день. Массы сыра, супа, зелени, хумуса, хлебцев, риета и банки тунца сообщил пользователь; остальные порции оценочные. День остаётся открытым: итоговая пользовательская оценка не сообщена.'
)
ON CONFLICT (diary_date) DO UPDATE SET
    status = excluded.status,
    notes = excluded.notes;

INSERT INTO sleep_entries (calendar_day_id, duration_minutes, notes)
SELECT id, 480, 'Пользователь сообщил продолжительность сна 8 часов; время начала, окончания и качество не указаны.'
FROM calendar_days WHERE diary_date = '2026-08-13'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    notes = excluded.notes;

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'breakfast', 'Половина порции риса со стручковой фасолью и яйцом; сыр маасдам', 373,
    425, 18.6, 14.9, 55.0,
    'Со слов пользователя: половина порции риса со стручковой фасолью и яйцом и 20 г сыра маасдам. «Половина порции» сопоставлена с половиной двойной порции 12 августа: центрально 150 г отварного риса, 150 г фасоли, 1 яйцо (50 г съедобной части) и 2,5 г возможного масла; сыр измерен пользователем. Компоненты: рис 195 ккал, Б 4,1 г, Ж 0,5 г, У 42,3 г; фасоль 53 ккал, Б 2,9 г, Ж 0,5 г, У 11,9 г; яйцо 78 ккал, Б 6,3 г, Ж 5,3 г, У 0,6 г; масло 23 ккал; сыр 79 ккал, Б 5,4 г, Ж 6,2 г, У 0,3 г. Ориентировочный диапазон 330–540 ккал; главные неопределённости — фактический размер исходной порции и масло. Уверенность средняя для сыра и низкая для остального. Проверка по БЖУ даёт около 429 ккал. Оценка завтрака ассистентом: 7/10 — есть белок и овощной компонент, но умеренно много крахмалистых углеводов и мало фруктов/разнообразия.'
FROM calendar_days WHERE diary_date = '2026-08-13'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'breakfast'
        AND food_name = 'Половина порции риса со стручковой фасолью и яйцом; сыр маасдам'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'lunch', 'Куриный бульон с вермишелью и курицей; руккола и шпинат', 500,
    290, 31.5, 4.7, 28.4,
    'Пользователь указал 400 г куриного бульона с вермишелью и курицей и 100 г смеси рукколы со шпинатом. Для центральной оценки суп условно разделён на 250 г бульона, 80 г приготовленной вермишели и 70 г курицы; зелень — поровну по 50 г. Центрально около 290 ккал, Б 31,5 г, Ж 4,7 г, У 28,4 г. Реалистичный диапазон 190–430 ккал, Б 19–42 г, Ж 3–13 г, У 16–42 г. Уверенность низкая; главные неопределённости — доли курицы и вермишели, жирность/солёность бульона. Проверка по БЖУ даёт около 282 ккал; разница объясняется округлением и справочными пищевыми волокнами. Оценка обеда ассистентом: 8/10 — достаточно белка и много листовой зелени, а энергетическая плотность умеренная; возможен высокий натрий бульона.'
FROM calendar_days WHERE diary_date = '2026-08-13'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'lunch'
        AND food_name = 'Куриный бульон с вермишелью и курицей; руккола и шпинат'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'dinner', 'Хумус; консервированный тунец; хлебцы; риет из кеты; тыквенные семечки; руккола', 199,
    360, 30.5, 9.2, 36.0,
    'Пользователь уточнил: хумус 30 г, хлебцы 40 г, риет из кеты 10 г, 15 тыквенных семечек и 2/3 банки тунца массой 130 г. Тунец принят как 86,7 г съедобной/слитой массы; 15 семечек оценены в 2 г, руккола без указанной массы — 30 г. Центрально: хумус 71 ккал, тунец 101 ккал, хлебцы 146 ккал, риет 25 ккал, семечки 11 ккал, руккола 8 ккал. Ориентировочный диапазон 320–420 ккал, Б 27–34 г, Ж 7–14 г, У 32–41 г. Уверенность средняя; главные неопределённости — означает ли 130 г массу слитого тунца, состав хумуса/риета и масса рукколы. Проверка по БЖУ даёт около 349 ккал; остаточная разница связана с клетчаткой и округлением. Оценка ужина ассистентом: 8/10 — много белка, есть бобовые, семечки и зелень; риет, тунец и хлебцы могут заметно повышать натрий.'
FROM calendar_days WHERE diary_date = '2026-08-13'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'dinner'
        AND food_name = 'Хумус; консервированный тунец; хлебцы; риет из кеты; тыквенные семечки; руккола'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'snack', 'Яблоко; банан; груша; 3 фруктовых пюре «Агуша»', 718,
    430, 3.5, 1.5, 105.0,
    'Со слов пользователя: яблоко, банан, груша и 3 пюре «Агуша». Массы и вкусы не указаны. Центрально приняты съедобные массы: яблоко 150 г (78 ккал), банан 120 г (107 ккал), груша 178 г (101 ккал), три фруктовых пюре по 90 г и около 53 ккал/100 г (143 ккал). Ориентировочный диапазон 350–520 ккал, Б 2–5 г, Ж 1–3 г, У 85–128 г. Уверенность низкая; главные неопределённости — размер фруктов, масса упаковок и состав пюре. Проверка по БЖУ даёт около 448 ккал; расхождение около 4% связано с клетчаткой и округлением. Оценка перекуса ассистентом: 6/10 — большое фруктовое разнообразие, но почти весь перекус углеводный и пюре обычно насыщают слабее цельных фруктов.'
FROM calendar_days WHERE diary_date = '2026-08-13'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'snack'
        AND food_name = 'Яблоко; банан; груша; 3 фруктовых пюре «Агуша»'
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'chicken', 'Курица явно указана в обеде: куриный бульон с курицей.'
FROM calendar_days WHERE diary_date = '2026-08-13'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба явно указана в ужине: консервированный тунец и риет из кеты.'
FROM calendar_days WHERE diary_date = '2026-08-13'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

-- Итоговая пользовательская оценка за 13 августа завершает день.
INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 2, 'Оценка дня пользователем: 2 из 5.'
FROM calendar_days WHERE diary_date = '2026-08-13'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    rating = excluded.rating,
    notes = excluded.notes;

UPDATE calendar_days
SET status = 'complete',
    notes = 'Записаны сон и питание за день. Массы сыра, супа, зелени, хумуса, хлебцев, риета и банки тунца сообщил пользователь; остальные порции оценочные. День завершён после итоговой пользовательской оценки 2 из 5.'
WHERE diary_date = '2026-08-13';

-- Данные за 18 августа: пользователь перечислил рацион, тренировку и сон;
-- день остаётся открытым без итоговой пользовательской оценки.
INSERT INTO calendar_days (diary_date, status, notes)
VALUES (
    '2026-08-18', 'in_progress',
    'Записаны все перечисленные пользователем приёмы пищи, 6 часов сна и функциональная силовая тренировка 75 минут. Итоговая пользовательская оценка дня не сообщена, поэтому день остаётся открытым.'
)
ON CONFLICT (diary_date) DO UPDATE SET
    status = excluded.status,
    notes = excluded.notes;

INSERT INTO sleep_entries (calendar_day_id, duration_minutes, notes)
SELECT id, 360,
    'Пользователь сообщил продолжительность сна 6 часов; время начала, окончания и качество сна не указаны.'
FROM calendar_days WHERE diary_date = '2026-08-18'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    quality_score = NULL,
    notes = excluded.notes;

INSERT INTO workouts (
    calendar_day_id, workout_type, duration_minutes, calories_burned_kcal,
    perceived_exertion, average_heart_rate_bpm, max_heart_rate_bpm, notes
)
SELECT id, 'Функциональная силовая тренировка', 75, 550, NULL, NULL, NULL,
    'Продолжительность сообщил пользователь; 550 ккал — оценка часов, сохранённая как значение устройства, а не расчёт ассистента. RPE и пульс не сообщены, поэтому интенсивность не выводилась.'
FROM calendar_days
WHERE diary_date = '2026-08-18'
  AND NOT EXISTS (
      SELECT 1 FROM workouts
      WHERE calendar_day_id = calendar_days.id
        AND workout_type = 'Функциональная силовая тренировка'
        AND duration_minutes = 75
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'breakfast', 'Хлебцы тыквенно-морковные «ВкусВилл»; домашнее гуакамоле из четверти авокадо с лимоном', 81,
    225, 5.5, 8.3, 34.5,
    'Со слов пользователя: 40 г тыквенно-морковных хлебцев «ВкусВилл» и домашняя намазка из четверти авокадо с лимоном; фото и этикетка не предоставлены. Центрально: хлебцы 40 г — 163 ккал, Б 4,4 г, Ж 2,3 г, У 31,2 г по ранее прочитанной этикетке этого продукта (408,1 ккал, Б 11,1 г, Ж 5,7 г, У 78,1 г на 100 г); авокадо 37,5 г съедобной части — 60 ккал, Б 0,8 г, Ж 5,5 г, У 3,2 г; лимонный сок 3 г — около 1 ккал. Диапазон порции 70–95 г и 205–255 ккал, главным образом из-за размера авокадо. Уверенность средняя. Проверка 4×Б + 9×Ж + 4×У даёт около 235 ккал; разница около 4% связана с клетчаткой и округлением. Оценка завтрака ассистентом: 6/10 — есть клетчатка и ненасыщенные жиры, но мало белка и общая порция невелика для дня с силовой тренировкой.'
FROM calendar_days WHERE diary_date = '2026-08-18'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'breakfast'
        AND food_name = 'Хлебцы тыквенно-морковные «ВкусВилл»; домашнее гуакамоле из четверти авокадо с лимоном'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'lunch', 'Салат «Тосканский» с зеленью, помидорами и баклажаном; картофельное пюре; куриная грудка на пару', 625,
    680, 55.0, 19.0, 69.0,
    'Со слов пользователя: около 200 г салата, предположительно «Тосканского», из зелени, помидоров и баклажана; 250–300 г пюре; около 150 г куриной грудки на пару. Фото, рецепт салата и количество масла не предоставлены. Центрально: салат 200 г — 120 ккал, Б 3 г, Ж 8 г, У 12 г (диапазон 60–220 ккал в зависимости от масла); пюре 275 г — 310 ккал, Б 5,5 г, Ж 11 г, У 47 г (250–300 г, примерно 250–390 ккал по рецепту); грудка 150 г — 250 ккал, Б 46,5 г, Ж 5,5 г, У 0 г (130–170 г, 215–280 ккал). Весь обед ориентировочно 525–890 ккал, Б 47–63 г, Ж 10–32 г, У 54–83 г. Уверенность средняя-низкая; основные неопределённости — масло/заправка салата и рецепт пюре. Проверка по БЖУ даёт около 667 ккал; расхождение около 2% связано с округлением и клетчаткой. Оценка обеда ассистентом: 8/10 — много белка, есть овощи и углеводы для восстановления; итоговая энергоёмкость и соль зависят от масла, молока/масла в пюре и заправки.'
FROM calendar_days WHERE diary_date = '2026-08-18'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'lunch'
        AND food_name = 'Салат «Тосканский» с зеленью, помидорами и баклажаном; картофельное пюре; куриная грудка на пару'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'snack', 'Большая груша; банан', 340,
    235, 2.0, 0.7, 61.0,
    'Со слов пользователя: достаточно большая груша и один банан; массы не измерялись. Центрально приняты 220 г съедобной части груши — 125 ккал и 120 г банана — 107 ккал. Диапазон 280–410 г и 190–285 ккал. Уверенность средняя-низкая; главная неопределённость — размер и съедобная масса плодов. Проверка по БЖУ даёт около 258 ккал; более высокое расхождение с табличной энергией объясняется округлением углеводов и пищевыми волокнами. Оценка перекуса ассистентом: 7/10 — два цельных фрукта дают клетчатку и углеводы, но почти не дают белка для восстановления после силовой нагрузки.'
FROM calendar_days WHERE diary_date = '2026-08-18'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'snack'
        AND food_name = 'Большая груша; банан'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'snack', 'Хлебцы с риетом из горбуши и другой рыбы и Almette с вялеными томатами; половина авокадо; помидор; половина сладкого перца', 315,
    378, 10.1, 18.2, 43.6,
    'Со слов пользователя: примерно 60 г хлебцев с двумя намазками суммарно, половина авокадо, помидор и дополнительно половина сладкого перца. Формулировка 60 г интерпретирована как общая масса хлебцев вместе с намазками, а не масса одних хлебцев. Центрально условно разделено: хлебцы 35 г — 143 ккал, риет 12,5 г — 30 ккал, Almette 12,5 г — 30 ккал; авокадо 75 г съедобной части — 120 ккал; помидор 120 г — 22 ккал; половина перца 60 г — 18 ккал. Ориентировочно 315–465 ккал, Б 8–14 г, Ж 13–25 г, У 35–53 г. Уверенность низкая; главные неопределённости — доли хлебцев и намазок в 60 г, рецептура двух готовых намазок и размеры авокадо, помидора и перца. Проверка по БЖУ даёт около 379 ккал. Оценка перекуса ассистентом: 8/10 — два овоща, авокадо и немного рыбного белка улучшают разнообразие и клетчатку, но белка умеренно, а готовые намазки и хлебцы могут давать много соли.'
FROM calendar_days WHERE diary_date = '2026-08-18'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'snack'
        AND food_name = 'Хлебцы с риетом из горбуши и другой рыбы и Almette с вялеными томатами; половина авокадо; помидор; половина сладкого перца'
  );

INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT id, 'dinner', '7 крупных креветок; брокколи; киноа; хлебцы с Almette; тыквенные семечки', 225,
    305, 33.5, 9.5, 25.0,
    'Первоначально пользователь сообщил 6 крупных креветок, затем добавил ещё одну креветку, 40 г брокколи, 50 г приготовленной киноа, 20 г хлебцев с Almette и 10 г тыквенных семечек. Исходный факт о 6 креветках сохранён в этой заметке. Центрально: 7 креветок — 105 г съедобной приготовленной части, 105 ккал, Б 25 г, Ж 1 г; брокколи 40 г — 15 ккал, Б 1 г, Ж 0 г, У 3 г; приготовленная киноа 50 г — 60 ккал, Б 2 г, Ж 1 г, У 11 г; общие 20 г хлебцев с Almette условно разделены на 12 г хлебцев и 8 г сыра — около 68 ккал, Б 2 г, Ж 2,5 г, У 10 г; семечки 10 г — 57 ккал, Б 3,5 г, Ж 5 г, У 1 г. Ориентировочно весь ужин 255–365 ккал, Б 28–39 г, Ж 7–13 г, У 20–31 г. Уверенность средняя-низкая; главные неопределённости — съедобная масса креветок и соотношение хлебцев с Almette в 20 г. Проверка по БЖУ даёт около 316 ккал; расхождение около 4% связано с клетчаткой и округлением. Оценка ужина ассистентом: 8/10 — много белка, появились овощи и умеренная порция углеводов для восстановления; готовая намазка, хлебцы и креветки могут повышать натрий.'
FROM calendar_days WHERE diary_date = '2026-08-18'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries
      WHERE calendar_day_id = calendar_days.id AND meal_type = 'dinner'
        AND food_name = '7 крупных креветок; брокколи; киноа; хлебцы с Almette; тыквенные семечки'
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'chicken', 'Курица явно указана в обеде: куриная грудка на пару.'
FROM calendar_days WHERE diary_date = '2026-08-18'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба явно указана во втором перекусе: риет из горбуши и другой рыбы. Креветки относятся к морепродуктам и сами по себе не использованы как основание fish.'
FROM calendar_days WHERE diary_date = '2026-08-18'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

-- Итоговая пользовательская оценка за 18 августа завершает день.
INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 3, 'Оценка дня пользователем: 3 из 5.'
FROM calendar_days WHERE diary_date = '2026-08-18'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    rating = excluded.rating,
    notes = excluded.notes;

UPDATE calendar_days
SET status = 'complete',
    notes = 'Записаны питание, 6 часов сна и функциональная силовая тренировка 75 минут. День завершён после итоговой пользовательской оценки 3 из 5.'
WHERE diary_date = '2026-08-18';

-- Данные за 19 августа создаются как открытый день; итоговый статус обновляется
-- ниже после добавления всего питания и пользовательской оценки.
INSERT INTO calendar_days (diary_date, status, notes)
VALUES (
    '2026-08-19', 'in_progress',
    'Записаны завтрак, 5,5 часа сна и беговая тренировка 30 минут на 6 км. День остаётся открытым: другие приёмы пищи и итоговая пользовательская оценка пока не сообщены.'
)
ON CONFLICT (diary_date) DO UPDATE SET
    status = excluded.status,
    notes = excluded.notes;

-- Завтрак 19 августа. Компоненты разделены, чтобы сохранить измеренные массы
-- салата и скрэмбла и не выдавать оценочные порции остальных блюд за измеренные.
WITH breakfast_entries (food_name, weight_g, calories_kcal, protein_g, fat_g, carbs_g, notes) AS (
    VALUES
        ('Овощной салат без заправки', 170, 35, 2.0, 0.5, 7.0,
         'Со слов пользователя: овощной салат без заправки, масса 170 г. Состав не перечислен; для центральной оценки принят типичный салат из помидора, огурца, сладкого перца и листовой зелени. Оценочный диапазон 30–50 ккал, Б 1,5–2,5 г, Ж 0–1 г, У 5–10 г. Уверенность средняя: масса и отсутствие заправки известны, состав и пропорции овощей — допущение.'),
        ('Скрэмбл с помидорами и шпинатом', 100, 150, 10.0, 11.0, 3.0,
         'Со слов пользователя: скрэмбл с помидорами и шпинатом, масса 100 г. Рецепт, число яиц и количество масла не сообщены. Центрально принят яичный скрэмбл с небольшими долями томата и шпината и около 2 г кулинарного жира. Оценочный диапазон 120–190 ккал, Б 8–12 г, Ж 8–15 г, У 2–5 г. Уверенность низкая; главная неопределённость — доли яйца и масла.'),
        ('Яичница из 1 яйца', 50, 90, 6.5, 7.0, 0.5,
         'Пользователь указал одно яйцо; съедобная масса центрально оценена в 50 г. Центральная калорийность включает около 2 г возможного масла для жарки. Диапазон порции 45–60 г и 70–110 ккал; нижняя граница соответствует приготовлению почти без дополнительного жира. Уверенность средняя.'),
        ('2 мини-сосиски молочные', 25, 65, 3.0, 5.5, 1.0,
         'Пользователь описал две мини-сосиски вместе как половину стандартной сосиски. Центрально приняты 25 г; реалистичный диапазон 20–35 г и 50–95 ккал. Бренд, этикетка и мясной состав неизвестны, поэтому meat/chicken/fish не отмечены. Уверенность низкая.'),
        ('Блинчик с яблочной начинкой', 90, 180, 3.5, 5.0, 31.0,
         'Масса, рецепт и этикетка не сообщены. Центрально принят один небольшой готовый блинчик 90 г, включая около 35 г яблочной начинки. Диапазон порции 70–120 г и 140–270 ккал; больше всего влияют размер, сахар в начинке и масло. Уверенность низкая.')
)
INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT d.id, 'breakfast', b.food_name, b.weight_g,
       b.calories_kcal, b.protein_g, b.fat_g, b.carbs_g, b.notes
FROM calendar_days AS d
CROSS JOIN breakfast_entries AS b
WHERE d.diary_date = '2026-08-19'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries AS n
      WHERE n.calendar_day_id = d.id
        AND n.meal_type = 'breakfast'
        AND n.food_name = b.food_name
  );

INSERT INTO sleep_entries (calendar_day_id, duration_minutes, notes)
SELECT id, 330,
    'Пользователь сообщил продолжительность сна 5,5 часа; время начала, окончания и качество сна не указаны.'
FROM calendar_days WHERE diary_date = '2026-08-19'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    quality_score = NULL,
    notes = excluded.notes;

INSERT INTO workouts (
    calendar_day_id, workout_type, duration_minutes, distance_km,
    calories_burned_kcal, perceived_exertion,
    average_heart_rate_bpm, max_heart_rate_bpm, notes
)
SELECT id, 'running', 30, 6.0, NULL, NULL, NULL, NULL,
    'Пользователь сообщил бег 30 минут и дистанцию 6 км (средний темп 5:00 мин/км). Калории, RPE и пульс не сообщены; расход калорий не оценивался, физиологическая интенсивность не выводилась.'
FROM calendar_days
WHERE diary_date = '2026-08-19'
  AND NOT EXISTS (
      SELECT 1 FROM workouts
      WHERE calendar_day_id = calendar_days.id
        AND workout_type = 'running'
        AND duration_minutes = 30
        AND distance_km = 6.0
  );

-- Остальное питание за 19 августа. Фотографии в текущем сообщении недоступны для
-- повторной проверки, поэтому использованы только текст пользователя и явные допущения.
WITH meal_entries (meal_type, food_name, weight_g, calories_kcal, protein_g, fat_g, carbs_g, notes) AS (
    VALUES
        ('lunch', 'Сливочный рыбный суп', 200, 180, 10.0, 11.0, 10.0, 'Пользователь указал блюдо и массу 200 г. Фото упомянуто, но не было доступно в текущем сообщении; вид рыбы, сливочность и рецепт неизвестны. Центрально: 180 ккал; диапазон 130–260 ккал, Б 7–14 г, Ж 6–19 г, У 7–16 г. Уверенность низкая.'),
        ('lunch', 'Квашеная капуста', 120, 25, 1.2, 0.2, 5.0, 'Масса 120 г сообщена пользователем. Центрально 25 ккал; диапазон 20–45 ккал из-за возможного сахара или масла. Б 1–2 г, Ж 0–2 г, У 4–8 г. Уверенность средняя; вероятно много добавленной соли.'),
        ('lunch', 'Салат из помидоров с брокколи', 120, 45, 2.5, 1.0, 7.0, 'Состав и масса 120 г сообщены пользователем; заправка не описана. Центрально учтён преимущественно овощной салат почти без масла. Диапазон 30–120 ккал; верхняя граница допускает около 10 г масла. Уверенность средняя-низкая.'),
        ('lunch', 'Картофель жареный', 80, 160, 2.5, 7.0, 23.0, 'Блюдо и масса 80 г сообщены пользователем. Центрально 160 ккал; диапазон 130–220 ккал, главным образом из-за впитанного масла. Уверенность средняя-низкая.'),
        ('lunch', 'Филе минтая в кляре', 150, 300, 25.0, 15.0, 17.0, 'Блюдо и масса 150 г сообщены пользователем. Центрально учтены около 105 г минтая и 45 г кляра с маслом. Диапазон 240–390 ккал, Б 21–30 г, Ж 9–24 г, У 12–25 г. Уверенность средняя-низкая; рецепт кляра и масло неизвестны.'),
        ('snack', 'Груша', 170, 95, 0.5, 0.2, 25.0, 'Одна груша без указанной массы; центрально принята съедобная часть 170 г. Диапазон 130–220 г и 75–125 ккал. Уверенность низкая.'),
        ('snack', 'Банан', 120, 105, 1.5, 0.5, 27.0, 'Один банан без указанной массы; центрально принята съедобная часть 120 г. Диапазон 90–150 г и 80–135 ккал. Уверенность низкая.'),
        ('dinner', 'Салат с рукколой, помидором, перцем, моцареллой, оливковым маслом, песто и тыквенными семечками', 307, 365, 19.0, 28.0, 14.0, 'Ингредиенты сообщил пользователь; массы не указаны. Центрально: руккола 30 г, помидор 120 г, перец 70 г, моцарелла 60 г, масло 7 г, песто 10 г и семечки 10 г. Диапазон порции 230–390 г и 250–520 ккал. Уверенность низкая; больше всего влияют моцарелла, масло, песто и семечки.'),
        ('dinner', 'Стейк мачете', 200, 450, 52.0, 27.0, 0.0, 'Пользователь указал стейк мачете 200 г; не уточнено, относится масса к готовому или сырому продукту. Центрально масса трактуется как готовая съедобная порция. Диапазон 380–600 ккал, Б 45–58 г, Ж 20–42 г. Уверенность средняя-низкая; влияют жирность, обрезка и масло при жарке.'),
        ('dinner', 'Шампиньоны, 2 штуки', 40, 15, 1.5, 0.5, 2.0, 'Пользователь указал две штуки без массы и способа приготовления. Центрально приняты 40 г и небольшое количество жира; диапазон 25–70 г и 5–45 ккал. Уверенность низкая.'),
        ('dinner', '4 хлебца с Almette', 80, 250, 6.0, 10.0, 33.0, 'Пользователь указал 4 хлебца с Almette; массы и этикетки не сообщены. Центрально приняты хлебцы 40 г и сливочный сыр 40 г. Диапазон общей порции 60–110 г и 190–340 ккал. Уверенность низкая.'),
        ('dinner', '2 финика и 3 миндальных ореха', 24, 80, 1.0, 2.5, 15.0, 'Количество сообщил пользователь; масса оценена как 20 г фиников и 4 г миндаля. Диапазон 18–35 г и 60–115 ккал. Уверенность низкая; размер фиников сильно варьирует.')
)
INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT d.id, m.meal_type, m.food_name, m.weight_g,
       m.calories_kcal, m.protein_g, m.fat_g, m.carbs_g, m.notes
FROM calendar_days AS d CROSS JOIN meal_entries AS m
WHERE d.diary_date = '2026-08-19'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries AS n
      WHERE n.calendar_day_id = d.id AND n.meal_type = m.meal_type
        AND n.food_name = m.food_name
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Рыба явно указана в обеде: сливочный рыбный суп и филе минтая в кляре.'
FROM calendar_days WHERE diary_date = '2026-08-19'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'meat', 'Мясо явно указано в ужине: стейк мачете из говядины.'
FROM calendar_days WHERE diary_date = '2026-08-19'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 2, 'Оценка дня пользователем: 2 из 5.'
FROM calendar_days WHERE diary_date = '2026-08-19'
ON CONFLICT (calendar_day_id) DO UPDATE SET rating = excluded.rating, notes = excluded.notes;

UPDATE calendar_days
SET status = 'complete',
    notes = 'Записаны питание за день, 5,5 часа сна и беговая тренировка 30 минут на 6 км. День завершён после итоговой пользовательской оценки 2 из 5.'
WHERE diary_date = '2026-08-19';

-- Полная запись за 20 августа. Пользователь сообщил итоговую оценку дня,
-- поэтому после идемпотентного добавления всех данных день закрывается.
INSERT INTO calendar_days (diary_date, status, notes)
VALUES (
    '2026-08-20', 'in_progress',
    'Записаны сон, беговая тренировка и питание за день; итоговая оценка пользователя будет сохранена ниже.'
)
ON CONFLICT (diary_date) DO UPDATE SET
    status = excluded.status,
    notes = excluded.notes;

INSERT INTO sleep_entries (calendar_day_id, duration_minutes, notes)
SELECT id, 440,
    'Пользователь сообщил продолжительность сна 7 часов 20 минут; время начала, окончания и качество сна не указаны.'
FROM calendar_days WHERE diary_date = '2026-08-20'
ON CONFLICT (calendar_day_id) DO UPDATE SET
    duration_minutes = excluded.duration_minutes,
    quality_score = NULL,
    notes = excluded.notes;

INSERT INTO workouts (
    calendar_day_id, workout_type, duration_minutes, distance_km,
    average_pace_seconds_per_km, calories_burned_kcal,
    perceived_exertion, average_heart_rate_bpm, max_heart_rate_bpm, notes
)
SELECT id, 'running', 29, 6.0, 290, 395, NULL, NULL, NULL,
    'Пользователь сообщил бег 29 минут, дистанцию 6 км и расход 395 ккал. Средний темп 4:50 мин/км рассчитан из времени и дистанции. Калории сохранены как сообщённое значение; RPE и пульс не сообщены, физиологическая интенсивность не выводилась.'
FROM calendar_days
WHERE diary_date = '2026-08-20'
  AND NOT EXISTS (
      SELECT 1 FROM workouts
      WHERE calendar_day_id = calendar_days.id
        AND workout_type = 'running'
        AND duration_minutes = 29
        AND distance_km = 6.0
  );

WITH meal_entries (meal_type, food_name, weight_g, calories_kcal, protein_g, fat_g, carbs_g, notes) AS (
    VALUES
        ('breakfast', 'Салат из рукколы, половины авокадо, помидора и сладкого перца', 240, 158, 3.5, 11.5, 14.0, 'Состав и общая масса 240 г сообщены пользователем; заправка не указана и в центральной оценке отсутствует. Центрально приняты руккола 25 г, съедобная часть половины авокадо 75 г, помидор 90 г и перец 50 г. Диапазон 130–210 ккал, Б 3–5 г, Ж 8–17 г, У 11–18 г. Уверенность средняя; главные неопределённости — размер авокадо и пропорции овощей.'),
        ('breakfast', 'Тунец консервированный', 20, 23, 5.0, 0.2, 0.0, 'Название и масса 20 г сообщены пользователем. Центрально принят тунец в воде в слитом виде. Диапазон 20–40 ккал, Б 4–6 г, Ж 0–2 г, У 0 г. Уверенность средняя: заливка и этикетка неизвестны.'),
        ('breakfast', 'Яичница из 2 яиц с шампиньонами, перцем, помидором и брокколи', 270, 268, 17.0, 15.5, 11.0, 'Общая масса 270 г, два яйца, два шампиньона и овощи сообщены пользователем. Центрально приняты яйца 100 г, шампиньоны 40 г, перец 40 г, помидор 50 г, брокколи 37 г и 3 г масла. Диапазон 220–360 ккал, Б 14–21 г, Ж 11–25 г, У 7–15 г. Уверенность средняя-низкая; больше всего влияют количество масла и доли овощей.'),
        ('lunch', 'Куриный бульон', 300, 90, 9.0, 4.0, 4.0, 'Название и масса 300 г сообщены пользователем. Наличие мяса, лапши, овощей и жирность не уточнены; центрально принят умеренно жирный прозрачный бульон с небольшим количеством курицы. Диапазон 40–180 ккал, Б 4–18 г, Ж 1–10 г, У 0–10 г. Уверенность низкая.'),
        ('lunch', 'Десерт «Пешка» из кафе Move в Лужниках', NULL, 320, 5.0, 20.0, 30.0, 'Название и место покупки сообщены пользователем; масса, состав, фото и этикетка отсутствуют. Центрально условно принят один порционный кондитерский десерт. Диапазон порции 70–150 г и 220–500 ккал, Б 3–8 г, Ж 12–34 г, У 20–50 г. Уверенность низкая; рецепт и размер порции могут существенно изменить итог. Компонент не связан со справочным профилем.'),
        ('snack', 'Круассан с сыром, ветчиной, солёным огурцом и сырным соусом', 100, 330, 11.0, 21.0, 26.0, 'Общая масса 100 г и начинка сообщены пользователем. Пропорции теста, ветчины, сыра и соуса неизвестны. Диапазон 280–410 ккал, Б 8–14 г, Ж 16–29 г, У 22–32 г. Уверенность средняя-низкая; главные неопределённости — количество сырного соуса и масла в тесте.'),
        ('dinner', 'Салат из рукколы, половины авокадо, помидора и сладкого перца', 290, 174, 4.0, 12.0, 17.0, 'Состав и общая масса 290 г сообщены пользователем; заправка не указана и в центральной оценке отсутствует. Центрально приняты руккола 30 г, авокадо 75 г, помидор 115 г и перец 70 г. Диапазон 145–225 ккал, Б 3–5 г, Ж 8–17 г, У 14–21 г. Уверенность средняя.'),
        ('dinner', 'Тунец консервированный', 50, 58, 13.0, 0.5, 0.0, 'Название и масса 50 г сообщены пользователем. Центрально принят тунец в воде в слитом виде. Диапазон 50–95 ккал, Б 11–14 г, Ж 0–4 г, У 0 г. Уверенность средняя: заливка и этикетка неизвестны.'),
        ('dinner', '4 хлебца с Almette', 80, 246, 6.5, 10.0, 30.5, 'Пользователь указал четыре хлебца с Almette без массы. Центрально приняты хлебцы 40 г и сливочный сыр 40 г; общая масса является оценкой. Диапазон 60–110 г и 190–340 ккал. Б 5–9 г, Ж 6–17 г, У 23–40 г. Уверенность низкая.'),
        ('dinner', '2 финика', 20, 56, 0.5, 0.0, 15.0, 'Количество сообщено пользователем; центрально приняты два небольших финика общей съедобной массой 20 г. Диапазон 14–48 г и 40–135 ккал. Уверенность низкая: размер и сорт фиников неизвестны.'),
        ('dinner', '8 миндальных орехов', 10, 58, 2.0, 5.0, 2.0, 'Количество сообщено пользователем; центрально принята съедобная масса около 10 г. Диапазон 8–12 г и 45–70 ккал. Уверенность средняя.' )
)
INSERT INTO nutrition_entries (
    calendar_day_id, meal_type, food_name, weight_g,
    calories_kcal, protein_g, fat_g, carbs_g, notes
)
SELECT d.id, m.meal_type, m.food_name, m.weight_g,
       m.calories_kcal, m.protein_g, m.fat_g, m.carbs_g, m.notes
FROM calendar_days AS d CROSS JOIN meal_entries AS m
WHERE d.diary_date = '2026-08-20'
  AND NOT EXISTS (
      SELECT 1 FROM nutrition_entries AS n
      WHERE n.calendar_day_id = d.id
        AND n.meal_type = m.meal_type
        AND n.food_name = m.food_name
  );

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'fish', 'Консервированный тунец явно указан на завтрак и ужин.'
FROM calendar_days WHERE diary_date = '2026-08-20'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'chicken', 'Курица явно указана в названии куриного бульона; фактическое количество мяса не сообщено.'
FROM calendar_days WHERE diary_date = '2026-08-20'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_food_bases (calendar_day_id, base_type, notes)
SELECT id, 'meat', 'Ветчина явно указана в начинке круассана; вид мяса и состав продукта не сообщены.'
FROM calendar_days WHERE diary_date = '2026-08-20'
ON CONFLICT (calendar_day_id, base_type) DO UPDATE SET notes = excluded.notes;

INSERT INTO daily_ratings (calendar_day_id, rating, notes)
SELECT id, 2, 'Оценка дня пользователем: 2 из 5.'
FROM calendar_days WHERE diary_date = '2026-08-20'
ON CONFLICT (calendar_day_id) DO UPDATE SET rating = excluded.rating, notes = excluded.notes;

UPDATE calendar_days
SET status = 'complete',
    notes = 'Записаны питание, сон 7 часов 20 минут и бег 29 минут на 6 км с сообщённым расходом 395 ккал. День завершён после итоговой пользовательской оценки 2 из 5.'
WHERE diary_date = '2026-08-20';
