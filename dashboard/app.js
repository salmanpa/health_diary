(function () {
  "use strict";

  const payload = window.HEALTH_DIARY_DATA;
  if (!payload || !Array.isArray(payload.daily)) {
    document.body.insertAdjacentHTML(
      "afterbegin",
      '<div class="notice">Нет данных для аналитики. Снимок дашборда ещё не собран.</div>'
    );
    return;
  }

  const COLORS = {
    ink: "#1f2925",
    muted: "#738079",
    grid: "rgba(31,41,37,.11)",
    green: "#1d7663",
    greenSoft: "#9fcdbd",
    blue: "#5278d7",
    orange: "#e0774f",
    yellow: "#d2a83f",
    red: "#bd5b5b",
    white: "#fbfcf8",
  };

  const workoutNames = {
    running: "Бег",
    functional_strength_training: "Функционально-силовая",
  };

  const baseNames = { meat: "Мясо", chicken: "Курица", fish: "Рыба" };
  const monthSelect = document.getElementById("monthSelect");
  let selectedMonth = payload.meta.months[payload.meta.months.length - 1];
  let currentDays = [];

  function numeric(values) {
    return values
      .filter((value) => value !== null && value !== undefined && value !== "")
      .map(Number)
      .filter(Number.isFinite);
  }

  function average(values) {
    const data = numeric(values);
    return data.length ? data.reduce((total, value) => total + value, 0) / data.length : null;
  }

  function sum(values) {
    return numeric(values).reduce((total, value) => total + value, 0);
  }

  function format(value, digits = 0) {
    if (value === null || value === undefined || !Number.isFinite(Number(value))) return "—";
    return new Intl.NumberFormat("ru-RU", {
      maximumFractionDigits: digits,
      minimumFractionDigits: digits,
    }).format(Number(value));
  }

  function formatHours(minutes) {
    if (minutes === null || minutes === undefined || !Number.isFinite(Number(minutes))) return "—";
    const value = Math.round(Number(minutes));
    const hours = Math.floor(value / 60);
    const remainder = value % 60;
    return remainder ? `${hours} ч ${remainder} мин` : `${hours} ч`;
  }

  function formatPace(seconds) {
    if (!Number(seconds)) return null;
    const rounded = Math.round(Number(seconds));
    return `${Math.floor(rounded / 60)}:${String(rounded % 60).padStart(2, "0")}/км`;
  }

  function monthLabel(month) {
    const value = new Intl.DateTimeFormat("ru-RU", { month: "long", year: "numeric" })
      .format(new Date(`${month}-01T12:00:00`));
    return value.charAt(0).toUpperCase() + value.slice(1);
  }

  function dateLabel(date, short = false) {
    return new Intl.DateTimeFormat("ru-RU", short
      ? { day: "2-digit", month: "2-digit" }
      : { day: "numeric", month: "long" }
    ).format(new Date(`${date}T12:00:00`));
  }

  function weekday(date) {
    return new Intl.DateTimeFormat("ru-RU", { weekday: "short" })
      .format(new Date(`${date}T12:00:00`)).replace(".", "");
  }

  function plural(number, forms) {
    const value = Math.abs(number) % 100;
    const last = value % 10;
    if (value > 10 && value < 20) return forms[2];
    if (last === 1) return forms[0];
    if (last > 1 && last < 5) return forms[1];
    return forms[2];
  }

  function setText(id, value) {
    const node = document.getElementById(id);
    if (node) node.textContent = value;
  }

  function element(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  }

  function daysForMonth() {
    return payload.daily.filter((day) => day.diary_date.startsWith(selectedMonth));
  }

  function workoutsForMonth() {
    return payload.workouts.filter((item) => item.diary_date.startsWith(selectedMonth));
  }

  function workoutsForDate(date) {
    return payload.workouts.filter((item) => item.diary_date === date);
  }

  function completed(days) {
    return days.filter((day) => day.status === "complete");
  }

  function intensityText(workouts) {
    if (!workouts.length) return "—";
    const labels = workouts.map((workout) => {
      if (workout.perceived_exertion !== null && workout.perceived_exertion !== undefined) {
        return `RPE ${format(workout.perceived_exertion)}/10`;
      }
      if (workout.average_heart_rate_bpm) return `ЧСС ${format(workout.average_heart_rate_bpm)}`;
      return null;
    }).filter(Boolean);
    return labels.length ? labels.join(" · ") : "не записана";
  }

  function workoutText(workouts) {
    if (!workouts.length) return "нет записи";
    return workouts.map((workout) => {
      const parts = [workoutNames[workout.workout_type] || workout.workout_type];
      if (workout.duration_minutes) parts.push(`${format(workout.duration_minutes)} мин`);
      if (workout.distance_km) parts.push(`${format(workout.distance_km, 1)} км`);
      return parts.join(" · ");
    }).join("; ");
  }

  function renderHeader(days) {
    const full = completed(days);
    const latest = days[days.length - 1];
    const calorieAverage = average(full.map((day) => day.calories_kcal));
    const proteinAverage = average(full.map((day) => day.protein_g));
    const fatAverage = average(full.map((day) => day.fat_g));
    const carbsAverage = average(full.map((day) => day.carbs_g));
    const sleepValues = days.filter((day) => day.has_sleep).map((day) => day.sleep_minutes);
    const sleepAverage = average(sleepValues);
    const workoutCount = sum(days.map((day) => day.workout_count));
    const workoutMinutes = sum(days.map((day) => day.workout_minutes));
    const distance = sum(days.map((day) => day.distance_km));
    const intensityRecords = sum(days.map((day) => day.intensity_record_count));

    setText("periodLabel", monthLabel(selectedMonth));
    setText("latestDate", latest ? dateLabel(latest.diary_date) : "—");
    setText("footerFreshness", latest ? `В снимке данные по ${dateLabel(latest.diary_date)}` : "Нет записей");
    setText("daysKpi", `${days.length} / ${full.length}`);
    setText("daysMeta", `${days.length - full.length} ${plural(days.length - full.length, ["день заполняется", "дня заполняются", "дней заполняются"])}`);
    setText("caloriesKpi", calorieAverage === null ? "—" : `${format(calorieAverage)} ккал`);
    setText("macrosKpi", proteinAverage === null
      ? "—"
      : `${format(proteinAverage)} / ${format(fatAverage)} / ${format(carbsAverage)}`);
    setText("sleepKpi", sleepAverage === null ? "—" : formatHours(sleepAverage));
    setText("sleepMeta", `${sleepValues.length} ${plural(sleepValues.length, ["ночь", "ночи", "ночей"])} с данными`);
    setText("trainingKpi", `${format(workoutMinutes)} мин`);
    setText("trainingMeta", `${workoutCount} ${plural(workoutCount, ["тренировка", "тренировки", "тренировок"])} · ${format(distance, 1)} км`);
    setText("intensityKpi", workoutCount ? `${intensityRecords} / ${workoutCount}` : "—");
    setText("intensityMeta", workoutCount
      ? "тренировок с RPE или ЧСС"
      : "RPE или пульс");

    const estimated = sum(days.map((day) => day.estimated_nutrition_entry_count));
    const nutritionEntries = sum(days.map((day) => day.nutrition_entry_count));
    const latestSuffix = latest && latest.status !== "complete"
      ? ` ${dateLabel(latest.diary_date)} ещё заполняется.`
      : "";
    setText(
      "summaryText",
      `${full.length} завершённых ${plural(full.length, ["день", "дня", "дней"])}; ${workoutCount} тренировок; ${estimated} из ${nutritionEntries} записей питания явно оценочные.${latestSuffix}`
    );
  }

  function renderDailyTable(days) {
    const body = document.getElementById("dailyTableBody");
    body.replaceChildren();
    [...days].reverse().forEach((day) => {
      const workouts = workoutsForDate(day.diary_date);
      const row = element("tr", day.status === "complete" ? "" : "is-in-progress");

      const dateCell = element("td", "date-cell");
      const date = element("strong", "", dateLabel(day.diary_date, true));
      const state = element("span", "status-label", day.status === "complete" ? weekday(day.diary_date) : `${weekday(day.diary_date)} · частично`);
      dateCell.append(date, state);
      row.appendChild(dateCell);

      const incompleteMacros = Number(day.incomplete_macro_entry_count) > 0;
      const values = [
        `${format(day.calories_kcal)} ккал`,
        `${incompleteMacros ? "≥ " : ""}${format(day.protein_g, 1)} г`,
        `${incompleteMacros ? "≥ " : ""}${format(day.fat_g, 1)} г`,
        `${incompleteMacros ? "≥ " : ""}${format(day.carbs_g, 1)} г`,
        day.has_sleep ? formatHours(day.sleep_minutes) : "нет записи",
      ];
      values.forEach((value, index) => {
        const cell = element("td", index === 0 ? "value-strong" : "", value);
        row.appendChild(cell);
      });

      const workoutCell = element("td", "workout-cell", workoutText(workouts));
      const intensityCell = element("td", intensityText(workouts) === "не записана" ? "missing-cell" : "", intensityText(workouts));
      const ratingCell = element("td", "rating-cell", day.day_rating ? `${day.day_rating} / 5` : "—");
      row.append(workoutCell, intensityCell, ratingCell);
      body.appendChild(row);
    });
  }

  function renderNutritionSignals(days) {
    const full = completed(days);
    const container = document.getElementById("nutritionSignals");
    container.replaceChildren();
    const calories = numeric(full.map((day) => day.calories_kcal));
    const incompleteDays = days.filter((day) => Number(day.incomplete_macro_entry_count) > 0).length;
    const completeMeals = full.filter((day) => Number(day.meal_type_count) === 4).length;
    const signals = [
      {
        label: "Разброс энергии",
        value: calories.length > 1 ? `${format(Math.min(...calories))}–${format(Math.max(...calories))} ккал` : "мало данных",
        note: "минимум и максимум завершённых дней",
      },
      {
        label: "Полный дневной набор",
        value: `${completeMeals} / ${full.length}`,
        note: "дней с завтраком, обедом, ужином и перекусом",
      },
      {
        label: "Неполные БЖУ",
        value: `${incompleteDays}`,
        note: "дней, где макросы являются известным минимумом",
      },
    ];
    signals.forEach((signal) => {
      const card = element("article", "signal-card");
      card.append(
        element("span", "", signal.label),
        element("strong", "", signal.value),
        element("small", "", signal.note)
      );
      container.appendChild(card);
    });
  }

  function renderWorkouts() {
    const workouts = workoutsForMonth();
    const container = document.getElementById("workoutList");
    container.replaceChildren();
    if (!workouts.length) {
      container.appendChild(element("p", "empty-state", "В выбранном периоде нет записанных тренировок."));
      return;
    }

    workouts.forEach((workout) => {
      const item = element("article", "workout-row");
      const date = element("div", "workout-date");
      date.append(element("strong", "", String(Number(workout.diary_date.slice(-2)))), element("span", "", weekday(workout.diary_date)));
      const name = element("div", "workout-name");
      name.append(
        element("strong", "", workoutNames[workout.workout_type] || workout.workout_type),
        element("span", "", `${format(workout.duration_minutes)} мин${workout.distance_km ? ` · ${format(workout.distance_km, 2)} км` : ""}`)
      );
      const pace = formatPace(workout.average_pace_seconds_per_km);
      const volume = element("div", "workout-detail");
      volume.append(element("span", "", "Объём"), element("strong", "", pace || (workout.calories_burned_kcal ? `${format(workout.calories_burned_kcal)} ккал` : "время")));
      const intensity = element("div", `workout-detail${intensityText([workout]) === "не записана" ? " is-missing" : ""}`);
      intensity.append(element("span", "", "Интенсивность"), element("strong", "", intensityText([workout])));
      item.append(date, name, volume, intensity);
      container.appendChild(item);
    });
  }

  function renderActivityNutrition(days) {
    const full = completed(days);
    const training = full.filter((day) => Number(day.workout_count) > 0);
    const rest = full.filter((day) => Number(day.workout_count) === 0);
    const container = document.getElementById("activityNutritionCards");
    container.replaceChildren();

    const cards = [
      {
        label: "Тренировочные дни",
        value: training.length ? `${format(average(training.map((day) => day.calories_kcal)))} ккал` : "нет данных",
        note: training.length ? `${format(average(training.map((day) => day.protein_g)), 1)} г белка · ${format(average(training.map((day) => day.carbs_g)), 1)} г углеводов` : "нет завершённых дней с нагрузкой",
      },
      {
        label: "Дни без тренировки",
        value: rest.length ? `${format(average(rest.map((day) => day.calories_kcal)))} ккал` : "нет базы",
        note: rest.length ? `${format(average(rest.map((day) => day.protein_g)), 1)} г белка · ${format(average(rest.map((day) => day.carbs_g)), 1)} г углеводов` : "нужен хотя бы один завершённый день без тренировки",
      },
      {
        label: "Сон в дни с нагрузкой",
        value: training.length ? formatHours(average(training.map((day) => day.sleep_minutes))) : "нет данных",
        note: "сон, записанный в тот же календарный день; не обязательно сон после тренировки",
      },
      {
        label: "Сила вывода",
        value: full.length < 14 ? "предварительно" : "можно сравнивать",
        note: `${full.length} завершённых ${plural(full.length, ["день", "дня", "дней"])}; причинные выводы не делаются`,
      },
    ];

    cards.forEach((card) => {
      const item = element("article", "comparison-card");
      item.append(element("span", "", card.label), element("strong", "", card.value), element("p", "", card.note));
      container.appendChild(item);
    });
  }

  function renderNutritionGaps(days) {
    const container = document.getElementById("nutritionGaps");
    container.replaceChildren();
    const entries = sum(days.map((day) => day.nutrition_entry_count));
    const estimated = sum(days.map((day) => day.estimated_nutrition_entry_count));
    const gaps = [
      { status: "нет данных", title: "Клетчатка", text: "Не хранится структурно. Нельзя сравнить поступление клетчатки по дням." },
      { status: "нет данных", title: "Витамины и минералы", text: "Кальций, железо, магний, калий, витамины D и B12 пока не считаются. Это не означает их дефицит." },
      { status: "нет данных", title: "Вода и электролиты", text: "Нет дневного объёма воды и натрия; связь с бегом и восстановлением пока не видна." },
      { status: `${estimated} / ${entries}`, title: "Оценочность питания", text: "Записей явно основаны на визуальной оценке. Диапазоны важнее точных десятых." },
    ];
    gaps.forEach((gap) => {
      const card = element("article", "gap-card");
      card.append(element("span", "gap-status", gap.status), element("h3", "", gap.title), element("p", "", gap.text));
      container.appendChild(card);
    });
  }

  function renderFoodBases(days) {
    const counts = { meat: 0, chicken: 0, fish: 0 };
    days.forEach((day) => {
      String(day.food_bases || "").split(",").map((item) => item.trim()).filter(Boolean)
        .forEach((base) => { counts[base] = (counts[base] || 0) + 1; });
    });
    const container = document.getElementById("foodBases");
    container.replaceChildren();
    Object.keys(counts).forEach((base) => {
      const item = element("div", "base-item");
      item.append(element("span", "", baseNames[base] || base), element("strong", "", `${counts[base]} / ${days.length}`));
      container.appendChild(item);
    });
    const note = element("div", "base-item base-note");
    note.append(element("span", "", "Ограничение"), element("p", "", "Яйца, молочные продукты, бобовые, орехи, овощи и фрукты пока не представлены отдельными структурными группами."));
    container.appendChild(note);
  }

  function renderQuality(days) {
    const coverage = document.getElementById("coverageTable");
    coverage.replaceChildren();
    const grid = element("div", "coverage-grid");
    ["День", "Еда", "Сон", "Трен.", "Интенс.", "Оценка", "Траты"].forEach((label) => grid.appendChild(element("div", "coverage-head", label)));
    days.forEach((day) => {
      grid.appendChild(element("div", "coverage-date", String(Number(day.diary_date.slice(-2)))));
      [
        Number(day.nutrition_entry_count) > 0,
        Boolean(day.has_sleep),
        Boolean(day.has_workout),
        Number(day.intensity_record_count) > 0,
        Boolean(day.has_rating),
        Boolean(day.has_expenses),
      ].forEach((present) => {
        const cell = element("div", "coverage-cell");
        const dot = element("span", `coverage-dot${present ? "" : " is-empty"}`);
        dot.title = present ? "Есть запись" : "Нет записи";
        cell.appendChild(dot);
        grid.appendChild(cell);
      });
    });
    coverage.appendChild(grid);

    const quality = document.getElementById("qualityCards");
    quality.replaceChildren();
    const monthQuality = payload.quality.find((item) => item.diary_month === selectedMonth) || {};
    const entries = Number(monthQuality.nutrition_entries) || 0;
    const estimated = Number(monthQuality.estimated_entries) || 0;
    const incomplete = Number(monthQuality.incomplete_macro_entries) || 0;
    const workouts = workoutsForMonth();
    const intensity = workouts.filter((workout) => workout.perceived_exertion || workout.average_heart_rate_bpm).length;
    const cards = [
      [`${estimated} / ${entries}`, "записей питания явно оценочные"],
      [`${incomplete}`, "записей с калориями, но неизвестными БЖУ"],
      [`${days.filter((day) => day.sleep_quality !== null).length} / ${days.filter((day) => day.has_sleep).length}`, "записей сна с субъективным качеством"],
      [`${intensity} / ${workouts.length}`, "тренировок с фактической интенсивностью"],
    ];
    cards.forEach(([value, text]) => {
      const card = element("article", "quality-card");
      card.append(element("strong", "", value), element("p", "", text));
      quality.appendChild(card);
    });
  }

  function prepareCanvas(id) {
    const canvas = document.getElementById(id);
    const ratio = Math.min(window.devicePixelRatio || 1, 2);
    const rect = canvas.getBoundingClientRect();
    const width = Math.max(rect.width, 300);
    const height = Math.max(rect.height, 260);
    canvas.width = Math.round(width * ratio);
    canvas.height = Math.round(height * ratio);
    const context = canvas.getContext("2d");
    context.setTransform(ratio, 0, 0, ratio, 0, 0);
    return { context, width, height };
  }

  function drawGrid(context, width, height, padding, maxValue, formatter, dark = false) {
    const plotHeight = height - padding.top - padding.bottom;
    context.font = "11px ui-sans-serif, system-ui";
    context.textAlign = "right";
    context.textBaseline = "middle";
    for (let index = 0; index <= 4; index += 1) {
      const y = padding.top + (plotHeight / 4) * index;
      const value = maxValue - (maxValue / 4) * index;
      context.strokeStyle = dark ? "rgba(251,252,248,.15)" : COLORS.grid;
      context.beginPath();
      context.moveTo(padding.left, y);
      context.lineTo(width - padding.right, y);
      context.stroke();
      context.fillStyle = dark ? "rgba(251,252,248,.58)" : COLORS.muted;
      context.fillText(formatter(value), padding.left - 8, y);
    }
  }

  function drawDayLabels(context, days, width, height, padding, dark = false) {
    const plotWidth = width - padding.left - padding.right;
    const slot = plotWidth / Math.max(days.length, 1);
    context.font = "11px ui-sans-serif, system-ui";
    context.fillStyle = dark ? "rgba(251,252,248,.65)" : COLORS.muted;
    context.textAlign = "center";
    context.textBaseline = "top";
    days.forEach((day, index) => {
      context.fillText(String(Number(day.diary_date.slice(-2))), padding.left + slot * index + slot / 2, height - padding.bottom + 13);
    });
  }

  function drawCalorieChart(days) {
    const { context, width, height } = prepareCanvas("calorieChart");
    context.clearRect(0, 0, width, height);
    if (!days.length) return;
    const padding = { top: 16, right: 12, bottom: 38, left: 52 };
    const plotWidth = width - padding.left - padding.right;
    const plotHeight = height - padding.top - padding.bottom;
    const maximum = Math.max(...days.map((day) => Number(day.calories_kcal) || 0), 500);
    const ceiling = Math.ceil(maximum / 500) * 500;
    drawGrid(context, width, height, padding, ceiling, (value) => format(value));
    const slot = plotWidth / days.length;
    const barWidth = Math.min(58, slot * 0.58);
    days.forEach((day, index) => {
      const value = Number(day.calories_kcal) || 0;
      const barHeight = (value / ceiling) * plotHeight;
      const x = padding.left + slot * index + (slot - barWidth) / 2;
      const y = padding.top + plotHeight - barHeight;
      context.fillStyle = day.status === "complete" ? COLORS.green : COLORS.greenSoft;
      context.fillRect(x, y, barWidth, barHeight);
      if (day.status !== "complete") {
        context.fillStyle = COLORS.orange;
        context.fillRect(x, y, barWidth, 4);
      }
      if (width > 520) {
        context.fillStyle = COLORS.ink;
        context.font = "11px ui-sans-serif, system-ui";
        context.textAlign = "center";
        context.textBaseline = "bottom";
        context.fillText(format(value), x + barWidth / 2, y - 6);
      }
    });
    drawDayLabels(context, days, width, height, padding);
    const avg = average(completed(days).map((day) => day.calories_kcal));
    setText("calorieChartTitle", avg === null ? "Калории по дням" : `Калории по дням · среднее ${format(avg)} ккал`);
  }

  function drawMacroChart(days) {
    const { context, width, height } = prepareCanvas("macroChart");
    context.clearRect(0, 0, width, height);
    if (!days.length) return;
    const padding = { top: 16, right: 14, bottom: 38, left: 46 };
    const plotWidth = width - padding.left - padding.right;
    const plotHeight = height - padding.top - padding.bottom;
    const series = [
      { key: "protein_g", color: COLORS.blue },
      { key: "fat_g", color: COLORS.orange },
      { key: "carbs_g", color: COLORS.yellow },
    ];
    const maximum = Math.max(...series.flatMap((item) => days.map((day) => Number(day[item.key]) || 0)), 50);
    const ceiling = Math.ceil(maximum / 50) * 50;
    drawGrid(context, width, height, padding, ceiling, (value) => `${format(value)}г`);
    const xFor = (index) => days.length === 1 ? padding.left + plotWidth / 2 : padding.left + (plotWidth / (days.length - 1)) * index;
    series.forEach((item) => {
      context.strokeStyle = item.color;
      context.lineWidth = 2.5;
      context.beginPath();
      days.forEach((day, index) => {
        const x = xFor(index);
        const y = padding.top + plotHeight - ((Number(day[item.key]) || 0) / ceiling) * plotHeight;
        if (index === 0) context.moveTo(x, y); else context.lineTo(x, y);
      });
      context.stroke();
      days.forEach((day, index) => {
        const x = xFor(index);
        const y = padding.top + plotHeight - ((Number(day[item.key]) || 0) / ceiling) * plotHeight;
        context.fillStyle = item.color;
        context.beginPath();
        context.arc(x, y, 4, 0, Math.PI * 2);
        context.fill();
      });
    });
    drawDayLabels(context, days, width, height, padding);
  }

  function drawSleepChart(days) {
    const { context, width, height } = prepareCanvas("sleepChart");
    context.clearRect(0, 0, width, height);
    if (!days.length) return;
    const padding = { top: 16, right: 14, bottom: 38, left: 44 };
    const plotWidth = width - padding.left - padding.right;
    const plotHeight = height - padding.top - padding.bottom;
    const maximumHours = Math.max(...days.map((day) => (Number(day.sleep_minutes) || 0) / 60), 8);
    const ceiling = Math.ceil(maximumHours / 2) * 2;
    drawGrid(context, width, height, padding, ceiling, (value) => `${format(value)}ч`, true);
    const slot = plotWidth / days.length;
    const points = days.map((day, index) => ({
      value: day.sleep_minutes === null ? null : Number(day.sleep_minutes) / 60,
      x: padding.left + slot * index + slot / 2,
    }));
    context.strokeStyle = "#bbf07b";
    context.lineWidth = 3;
    let drawing = false;
    context.beginPath();
    points.forEach((point) => {
      if (point.value === null) { drawing = false; return; }
      const y = padding.top + plotHeight - (point.value / ceiling) * plotHeight;
      if (!drawing) { context.moveTo(point.x, y); drawing = true; } else context.lineTo(point.x, y);
    });
    context.stroke();
    points.forEach((point) => {
      if (point.value === null) return;
      const y = padding.top + plotHeight - (point.value / ceiling) * plotHeight;
      context.fillStyle = "#bbf07b";
      context.beginPath();
      context.arc(point.x, y, 5, 0, Math.PI * 2);
      context.fill();
    });
    drawDayLabels(context, days, width, height, padding, true);
  }

  function drawActivityChart(days) {
    const { context, width, height } = prepareCanvas("activityChart");
    context.clearRect(0, 0, width, height);
    if (!days.length) return;
    const padding = { top: 16, right: 12, bottom: 38, left: 44 };
    const plotWidth = width - padding.left - padding.right;
    const plotHeight = height - padding.top - padding.bottom;
    const maximum = Math.max(...days.map((day) => Number(day.workout_minutes) || 0), 30);
    const ceiling = Math.ceil(maximum / 15) * 15;
    drawGrid(context, width, height, padding, ceiling, (value) => `${format(value)}м`);
    const slot = plotWidth / days.length;
    const barWidth = Math.min(54, slot * 0.5);
    days.forEach((day, index) => {
      const value = Number(day.workout_minutes) || 0;
      const x = padding.left + slot * index + (slot - barWidth) / 2;
      const barHeight = (value / ceiling) * plotHeight;
      const y = padding.top + plotHeight - barHeight;
      context.fillStyle = Number(day.intensity_record_count) > 0 ? COLORS.orange : COLORS.blue;
      context.fillRect(x, y, barWidth, barHeight);
      if (value > 0 && Number(day.intensity_record_count) === 0) {
        context.strokeStyle = COLORS.orange;
        context.setLineDash([4, 3]);
        context.strokeRect(x, y, barWidth, barHeight);
        context.setLineDash([]);
      }
    });
    drawDayLabels(context, days, width, height, padding);
  }

  function drawRelationshipChart(days) {
    const { context, width, height } = prepareCanvas("relationshipChart");
    context.clearRect(0, 0, width, height);
    const points = completed(days);
    if (!points.length) return;
    const padding = { top: 16, right: 22, bottom: 48, left: 52 };
    const plotWidth = width - padding.left - padding.right;
    const plotHeight = height - padding.top - padding.bottom;
    const maxMinutes = Math.max(...points.map((day) => Number(day.workout_minutes) || 0), 30);
    const maxCalories = Math.ceil(Math.max(...points.map((day) => Number(day.calories_kcal) || 0), 500) / 500) * 500;
    drawGrid(context, width, height, padding, maxCalories, (value) => format(value));
    context.fillStyle = COLORS.muted;
    context.font = "11px ui-sans-serif, system-ui";
    context.textAlign = "center";
    context.fillText("минуты тренировки", padding.left + plotWidth / 2, height - 10);
    [0, maxMinutes / 2, maxMinutes].forEach((value) => {
      const x = padding.left + (value / maxMinutes) * plotWidth;
      context.fillText(format(value), x, height - 30);
    });
    points.forEach((day) => {
      const x = padding.left + ((Number(day.workout_minutes) || 0) / maxMinutes) * plotWidth;
      const y = padding.top + plotHeight - ((Number(day.calories_kcal) || 0) / maxCalories) * plotHeight;
      const radius = 6 + Math.min((Number(day.protein_g) || 0) / 45, 4);
      context.fillStyle = Number(day.workout_count) > 0 ? "rgba(29,118,99,.82)" : "rgba(115,128,121,.7)";
      context.beginPath();
      context.arc(x, y, radius, 0, Math.PI * 2);
      context.fill();
      context.fillStyle = COLORS.ink;
      context.font = "11px ui-sans-serif, system-ui";
      context.textAlign = "center";
      context.textBaseline = "bottom";
      context.fillText(String(Number(day.diary_date.slice(-2))), x, y - radius - 4);
    });
  }

  function drawAll(days) {
    drawCalorieChart(days);
    drawMacroChart(days);
    drawSleepChart(days);
    drawActivityChart(days);
    drawRelationshipChart(days);
  }

  function render() {
    currentDays = daysForMonth();
    renderHeader(currentDays);
    renderDailyTable(currentDays);
    renderNutritionSignals(currentDays);
    renderWorkouts();
    renderActivityNutrition(currentDays);
    renderNutritionGaps(currentDays);
    renderFoodBases(currentDays);
    renderQuality(currentDays);
    drawAll(currentDays);
  }

  payload.meta.months.forEach((month) => {
    const option = element("option", "", monthLabel(month));
    option.value = month;
    monthSelect.appendChild(option);
  });
  monthSelect.value = selectedMonth;
  monthSelect.addEventListener("change", () => {
    selectedMonth = monthSelect.value;
    render();
  });

  let resizeFrame = null;
  window.addEventListener("resize", () => {
    if (resizeFrame) cancelAnimationFrame(resizeFrame);
    resizeFrame = requestAnimationFrame(() => drawAll(currentDays));
  });

  render();
})();
