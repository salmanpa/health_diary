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
