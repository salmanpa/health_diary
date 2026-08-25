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
  const nutrientDigits = {
    fiber_g: 1,
    calcium_mg: 0,
    iron_mg: 1,
    magnesium_mg: 0,
    potassium_mg: 0,
    sodium_mg: 0,
    vitamin_c_mg: 0,
    vitamin_d_mcg: 1,
    vitamin_b12_mcg: 1,
    folate_dfe_mcg: 0,
    omega3_g: 1,
  };
  const monthSelect = document.getElementById("monthSelect");
  let selectedMonth = payload.meta.months[payload.meta.months.length - 1];
  let currentDays = [];
  const chartHits = new Map();
  const mealNames = { breakfast: "Завтрак", lunch: "Обед", dinner: "Ужин", snack: "Перекус" };

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

  function macroChip(type, value, incomplete = false, compact = false) {
    const labels = {
      protein: { short: "Б", full: "Белки", symbol: "●" },
      fat: { short: "Ж", full: "Жиры", symbol: "◆" },
      carbs: { short: "У", full: "Углеводы", symbol: "■" },
    };
    const label = labels[type];
    const chip = element("span", `macro-chip ${type}`);
    chip.setAttribute("aria-label", `${label.full}: ${incomplete ? "не менее " : ""}${format(value, 1)} грамма`);
    chip.append(
      element("b", "macro-symbol", label.symbol),
      element("span", "macro-label", compact ? label.short : label.full),
      element("strong", "macro-value", `${incomplete ? "≥ " : ""}${format(value, 1)}`),
      element("small", "macro-unit", "г")
    );
    return chip;
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

  function nutrientsForMonth() {
    return payload.nutrients.filter((item) => item.diary_date.startsWith(selectedMonth));
  }

  function mondayKey(date) {
    const value = new Date(`${date}T12:00:00`);
    const offset = (value.getDay() + 6) % 7;
    value.setDate(value.getDate() - offset);
    return value.toISOString().slice(0, 10);
  }

  function completed(days) {
    return days.filter((day) => day.status === "complete");
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
    const trackedWeeks = new Set(days.map((day) => mondayKey(day.diary_date))).size;
    const workoutsPerWeek = trackedWeeks ? workoutCount / trackedWeeks : null;
    const workoutEnergy = sum(workoutsForMonth().map((workout) => workout.energy_kcal));

    setText("periodLabel", monthLabel(selectedMonth));
    setText("latestDate", latest ? dateLabel(latest.diary_date) : "—");
    setText("footerFreshness", latest ? `В снимке данные по ${dateLabel(latest.diary_date)}` : "Нет записей");
    setText("daysKpi", `${days.length} / ${full.length}`);
    setText("daysMeta", `${days.length - full.length} ${plural(days.length - full.length, ["день заполняется", "дня заполняются", "дней заполняются"])}`);
    setText("caloriesKpi", calorieAverage === null ? "—" : `${format(calorieAverage)} ккал`);
    const macrosKpi = document.getElementById("macrosKpi");
    macrosKpi.replaceChildren();
    if (proteinAverage === null) macrosKpi.textContent = "—";
    else macrosKpi.append(
      macroChip("protein", proteinAverage, false, true),
      macroChip("fat", fatAverage, false, true),
      macroChip("carbs", carbsAverage, false, true)
    );
    setText("sleepKpi", sleepAverage === null ? "—" : formatHours(sleepAverage));
    setText("sleepMeta", `${sleepValues.length} ${plural(sleepValues.length, ["ночь", "ночи", "ночей"])} с данными`);
    setText("trainingKpi", workoutsPerWeek === null ? "—" : format(workoutsPerWeek, trackedWeeks > 1 ? 1 : 0));
    setText(
      "trainingMeta",
      `${workoutCount} ${plural(workoutCount, ["тренировка", "тренировки", "тренировок"])} · ${format(workoutMinutes)} мин · ≈${format(workoutEnergy)} ккал`
    );

    const estimated = sum(days.map((day) => day.estimated_nutrition_entry_count));
    const nutritionEntries = sum(days.map((day) => day.nutrition_entry_count));
    const latestSuffix = latest && latest.status !== "complete"
      ? ` ${dateLabel(latest.diary_date)} ещё заполняется.`
      : "";
    setText(
      "summaryText",
      `${full.length} завершённых ${plural(full.length, ["день", "дня", "дней"])}; ${format(workoutsPerWeek, trackedWeeks > 1 ? 1 : 0)} ${plural(Math.round(workoutsPerWeek || 0), ["тренировка", "тренировки", "тренировок"])} в неделю; ${estimated} из ${nutritionEntries} записей питания явно оценочные.${latestSuffix}`
    );
  }

  function renderDailyTable(days) {
    const body = document.getElementById("dailyTableBody");
    body.replaceChildren();
    [...days].reverse().forEach((day) => {
      const workouts = workoutsForDate(day.diary_date);
      const row = element("tr", day.status === "complete" ? "" : "is-in-progress");
      row.tabIndex = 0;
      row.setAttribute("aria-label", `Открыть питание за ${dateLabel(day.diary_date)}`);
      row.addEventListener("click", () => openDay(day));
      row.addEventListener("keydown", (event) => {
        if (event.key === "Enter" || event.key === " ") { event.preventDefault(); openDay(day); }
      });

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
        const macroTypes = [null, "protein", "fat", "carbs"];
        const cell = element("td", index === 0 ? "value-strong" : macroTypes[index] ? "macro-cell" : "", value);
        if (macroTypes[index]) {
          cell.replaceChildren(macroChip(macroTypes[index], day[`${macroTypes[index]}_g`], incompleteMacros, true));
        }
        row.appendChild(cell);
      });

      const workoutCell = element("td", "workout-cell", workoutText(workouts));
      const ratingCell = element("td", "rating-cell", day.day_rating ? `${day.day_rating} / 5` : "—");
      row.append(workoutCell, ratingCell);
      body.appendChild(row);
    });
  }

  function openDay(day) {
    const dialog = document.getElementById("dayDialog");
    const content = document.getElementById("dayDialogContent");
    const entries = (payload.nutrition_entries || []).filter((item) => item.diary_date === day.diary_date);
    setText("dayDialogTitle", dateLabel(day.diary_date));
    content.replaceChildren();
    const total = element("div", "day-total");
    total.append(
      element("span", "energy-chip", `${format(day.calories_kcal)} ккал`),
      macroChip("protein", day.protein_g),
      macroChip("fat", day.fat_g),
      macroChip("carbs", day.carbs_g)
    );
    content.appendChild(total);
    Object.keys(mealNames).forEach((mealType) => {
      const mealEntries = entries.filter((item) => item.meal_type === mealType);
      if (!mealEntries.length) return;
      const section = element("section", "meal-detail");
      section.appendChild(element("h3", "", mealNames[mealType]));
      mealEntries.forEach((item) => {
        const food = element("div", "food-detail");
        food.append(
          element("strong", "", item.food_name),
          element("span", "", item.weight_g === null ? "масса —" : `${format(item.weight_g, 1)} г`),
          element("span", "", `${format(item.calories_kcal)} ккал`),
          macroChip("protein", item.protein_g, false, true),
          macroChip("fat", item.fat_g, false, true),
          macroChip("carbs", item.carbs_g, false, true)
        );
        if (item.notes) food.appendChild(element("small", "", item.notes));
        section.appendChild(food);
      });
      content.appendChild(section);
    });
    if (!entries.length) content.appendChild(element("p", "", "Питание за этот день не записано."));
    dialog.showModal();
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
      const pace = formatPace(workout.average_pace_seconds_per_km);
      name.append(
        element("strong", "", workoutNames[workout.workout_type] || workout.workout_type),
        element("span", "", [workout.distance_km ? `${format(workout.distance_km, 2)} км` : null, pace].filter(Boolean).join(" · ") || "без дистанции")
      );
      const duration = element("div", "workout-detail");
      duration.append(element("span", "", "Время тренировки"), element("strong", "", `${format(workout.duration_minutes)} мин`));
      const energy = element("div", `workout-detail${workout.energy_kcal === null ? " is-missing" : ""}`);
      const energyValue = workout.energy_kcal === null
        ? "нет данных"
        : `${workout.energy_source === "estimated_level_running" ? "≈" : ""}${format(workout.energy_kcal)} ккал`;
      const energyLabel = workout.energy_source === "estimated_level_running" ? "Потрачено · расчёт" : "Потрачено";
      energy.append(element("span", "", energyLabel), element("strong", "", energyValue));
      item.append(date, name, duration, energy);
      container.appendChild(item);
    });
  }

  function nutrientValue(row, code) {
    if (!row || row[code] === null || row[code] === undefined) return null;
    const value = Number(row[code]);
    return Number.isFinite(value) ? value : null;
  }

  function nutrientAmount(value, reference) {
    if (value === null) return "—";
    return `${format(value, nutrientDigits[reference.nutrient_code] || 0)} ${reference.unit}`;
  }

  function nutrientPercent(value, reference) {
    if (value === null || !Number(reference.daily_reference)) return null;
    return value / Number(reference.daily_reference) * 100;
  }

  function renderNutrients(days) {
    const references = payload.nutrient_references || [];
    const rows = nutrientsForMonth();
    const completeDates = new Set(completed(days).map((day) => day.diary_date));
    const completeRows = rows.filter((row) => completeDates.has(row.diary_date));
    const summary = document.getElementById("nutrientSummary");
    summary.replaceChildren();

    references.forEach((reference) => {
      const values = completeRows.map((row) => nutrientValue(row, reference.nutrient_code));
      const mean = average(values);
      const percent = nutrientPercent(mean, reference);
      const card = element("article", "nutrient-card");
      let signal = "информационно";
      let state = "neutral";
      if (reference.comparison_mode === "minimum" && percent !== null) {
        signal = `≈${format(percent)}% ориентира`;
        state = percent < 75 ? "low" : percent < 100 ? "watch" : "reached";
      } else if (reference.comparison_mode === "upper" && percent !== null) {
        signal = `≈${format(percent)}% верхнего ориентира`;
        state = percent > 100 ? "watch" : "neutral";
      }
      card.dataset.state = state;
      card.append(
        element("span", "nutrient-name", reference.nutrient_name),
        element("strong", "", nutrientAmount(mean, reference)),
        element("small", "nutrient-signal", signal),
        element("p", "", reference.comparison_mode === "upper"
          ? "Известный минимум: добавленная соль учтена не полностью."
          : `Среднее по ${completeRows.length} завершённым ${plural(completeRows.length, ["дню", "дням", "дням"])}.`)
      );
      summary.appendChild(card);
    });

    const head = document.getElementById("nutrientTableHead");
    const body = document.getElementById("nutrientTableBody");
    head.replaceChildren();
    body.replaceChildren();
    const headerRow = element("tr");
    headerRow.appendChild(element("th", "", "Показатель"));
    days.forEach((day) => {
      const cell = element("th", day.status === "complete" ? "" : "is-in-progress", String(Number(day.diary_date.slice(-2))));
      cell.title = day.status === "complete" ? dateLabel(day.diary_date) : `${dateLabel(day.diary_date)} · день заполняется`;
      headerRow.appendChild(cell);
    });
    headerRow.appendChild(element("th", "", "Среднее"));
    head.appendChild(headerRow);

    const rowByDate = new Map(rows.map((row) => [row.diary_date, row]));
    references.forEach((reference) => {
      const row = element("tr");
      const label = element("td", "nutrient-row-label");
      label.append(element("strong", "", reference.nutrient_name), element("span", "", reference.unit));
      row.appendChild(label);
      days.forEach((day) => {
        const value = nutrientValue(rowByDate.get(day.diary_date), reference.nutrient_code);
        const percent = nutrientPercent(value, reference);
        const cell = element("td", day.status === "complete" ? "" : "is-in-progress");
        if (value === null) {
          cell.textContent = "—";
        } else {
          cell.appendChild(element("strong", "", format(value, nutrientDigits[reference.nutrient_code] || 0)));
          if (percent !== null) cell.appendChild(element("span", "", `${format(percent)}%`));
          if (reference.comparison_mode === "minimum" && percent !== null) {
            cell.dataset.state = percent < 75 ? "low" : percent < 100 ? "watch" : "reached";
          }
        }
        row.appendChild(cell);
      });
      const mean = average(completeRows.map((item) => nutrientValue(item, reference.nutrient_code)));
      const averageCell = element("td", "nutrient-average");
      averageCell.appendChild(element("strong", "", nutrientAmount(mean, reference)));
      const meanPercent = nutrientPercent(mean, reference);
      if (meanPercent !== null) averageCell.appendChild(element("span", "", `≈${format(meanPercent)}%`));
      row.appendChild(averageCell);
      body.appendChild(row);
    });

    const componentWeight = sum(completeRows.map((row) => row.component_weight_g));
    const analyzedWeight = sum(completeRows.map((row) => row.analyzed_component_weight_g));
    const weightCoverage = componentWeight ? analyzedWeight / componentWeight * 100 : null;
    setText(
      "nutrientCoverageNote",
      weightCoverage === null ? "Нет компонентных данных" : `Справочником покрыто ≈${format(weightCoverage)}% восстановленной массы`
    );

    renderNutrientSources(completeDates, references);
  }

  function renderNutrientSources(completeDates, references) {
    const container = document.getElementById("nutrientSources");
    container.replaceChildren();
    const focusCodes = ["fiber_g", "calcium_mg", "magnesium_mg", "vitamin_d_mcg"];
    focusCodes.forEach((code) => {
      const reference = references.find((item) => item.nutrient_code === code);
      if (!reference) return;
      const totals = new Map();
      payload.components
        .filter((item) => completeDates.has(item.diary_date))
        .forEach((item) => {
          const value = Number(item[code]);
          if (!Number.isFinite(value) || value <= 0) return;
          totals.set(item.component_name, (totals.get(item.component_name) || 0) + value);
        });
      const sources = [...totals.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3);
      const group = element("div", "source-group");
      group.appendChild(element("strong", "", reference.nutrient_name));
      sources.forEach(([name, value]) => {
        const source = element("div", "source-row");
        source.append(element("span", "", name), element("b", "", nutrientAmount(value, reference)));
        group.appendChild(source);
      });
      if (!sources.length) group.appendChild(element("p", "empty-state", "Нет рассчитанных источников."));
      container.appendChild(group);
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
    const nutrientRows = new Map(nutrientsForMonth().map((row) => [row.diary_date, row]));
    ["День", "Еда", "Состав", "Сон", "Трен.", "Оценка"].forEach((label) => grid.appendChild(element("div", "coverage-head", label)));
    days.forEach((day) => {
      grid.appendChild(element("div", "coverage-date", String(Number(day.diary_date.slice(-2)))));
      [
        Number(day.nutrition_entry_count) > 0,
        Number((nutrientRows.get(day.diary_date) || {}).component_count) > 0,
        Boolean(day.has_sleep),
        Boolean(day.has_workout),
        Boolean(day.has_rating),
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
    const componentCount = sum([...nutrientRows.values()].map((row) => row.component_count));
    const analyzedCount = sum([...nutrientRows.values()].map((row) => row.analyzed_component_count));
    const cards = [
      [`${estimated} / ${entries}`, "записей питания явно оценочные"],
      [`${incomplete}`, "записей с калориями, но неизвестными БЖУ"],
      [`${days.filter((day) => day.sleep_quality !== null).length} / ${days.filter((day) => day.has_sleep).length}`, "записей сна с субъективным качеством"],
      [`${analyzedCount} / ${componentCount}`, "компонентов питания связаны со справочником"],
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
    const hits = [];
    days.forEach((day, index) => {
      const value = Number(day.calories_kcal) || 0;
      const barHeight = (value / ceiling) * plotHeight;
      const x = padding.left + slot * index + (slot - barWidth) / 2;
      const y = padding.top + plotHeight - barHeight;
      hits.push({ x: x + barWidth / 2, y, day, text: `${dateLabel(day.diary_date)}<br><b>${format(value)} ккал</b>` });
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
    chartHits.set("calorieChart", hits);
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
    chartHits.set("macroChart", days.map((day, index) => ({
      x: xFor(index), y: padding.top + plotHeight / 2, day,
      text: `${dateLabel(day.diary_date)}<br><b>Б ${format(day.protein_g, 1)} · Ж ${format(day.fat_g, 1)} · У ${format(day.carbs_g, 1)} г</b>`,
    })));
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
    chartHits.set("sleepChart", points.filter((point) => point.value !== null).map((point, index) => ({
      x: point.x, y: padding.top + plotHeight - (point.value / ceiling) * plotHeight,
      day: days.filter((day) => day.sleep_minutes !== null)[index], text: `${format(point.value, 1)} ч сна`,
    })));
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
    const hits = [];
    days.forEach((day, index) => {
      const value = Number(day.workout_minutes) || 0;
      const x = padding.left + slot * index + (slot - barWidth) / 2;
      const barHeight = (value / ceiling) * plotHeight;
      const y = padding.top + plotHeight - barHeight;
      hits.push({ x: x + barWidth / 2, y, day, text: `${dateLabel(day.diary_date)}<br><b>${format(value)} мин тренировки</b>` });
      context.fillStyle = COLORS.blue;
      context.fillRect(x, y, barWidth, barHeight);
    });
    drawDayLabels(context, days, width, height, padding);
    chartHits.set("activityChart", hits);
  }

  function drawAll(days) {
    drawCalorieChart(days);
    drawMacroChart(days);
    drawSleepChart(days);
    drawActivityChart(days);
  }

  function render() {
    currentDays = daysForMonth();
    renderHeader(currentDays);
    renderDailyTable(currentDays);
    renderNutritionSignals(currentDays);
    renderWorkouts();
    renderNutrients(currentDays);
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

  document.getElementById("dayDialogClose").addEventListener("click", () => document.getElementById("dayDialog").close());
  document.getElementById("dayDialog").addEventListener("click", (event) => {
    if (event.target === event.currentTarget) event.currentTarget.close();
  });
  const tooltip = document.getElementById("chartTooltip");
  document.querySelectorAll("canvas").forEach((canvas) => {
    canvas.addEventListener("mousemove", (event) => {
      const rect = canvas.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const hits = chartHits.get(canvas.id) || [];
      const hit = hits.reduce((best, item) => !best || Math.abs(item.x - x) < Math.abs(best.x - x) ? item : best, null);
      if (!hit || Math.abs(hit.x - x) > Math.max(22, rect.width / Math.max(currentDays.length, 1) / 2)) {
        tooltip.classList.remove("is-visible"); return;
      }
      tooltip.innerHTML = hit.text.includes("<br>") ? hit.text : `${dateLabel(hit.day.diary_date)}<br><b>${hit.text}</b>`;
      tooltip.style.left = `${Math.min(event.clientX + 14, window.innerWidth - 245)}px`;
      tooltip.style.top = `${Math.max(8, event.clientY - 55)}px`;
      tooltip.classList.add("is-visible");
    });
    canvas.addEventListener("mouseleave", () => tooltip.classList.remove("is-visible"));
    canvas.addEventListener("click", (event) => {
      const rect = canvas.getBoundingClientRect();
      const hits = chartHits.get(canvas.id) || [];
      const hit = hits.reduce((best, item) => !best || Math.abs(item.x - (event.clientX - rect.left)) < Math.abs(best.x - (event.clientX - rect.left)) ? item : best, null);
      if (hit && hit.day) openDay(hit.day);
    });
  });

  let resizeFrame = null;
  window.addEventListener("resize", () => {
    if (resizeFrame) cancelAnimationFrame(resizeFrame);
    resizeFrame = requestAnimationFrame(() => drawAll(currentDays));
  });

  render();
})();
