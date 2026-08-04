PRAGMA foreign_keys = ON;

INSERT INTO calendar_days (diary_date, notes)
VALUES ('2026-08-04', 'Питание и сон пока не заполнены.')
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
