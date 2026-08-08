(function () {
  "use strict";

  const payload = window.HEALTH_DIARY_DATA;
  if (!payload || !Array.isArray(payload.daily)) {
    document.body.insertAdjacentHTML(
      "afterbegin",
      '<div class="noscript">Нет данных. Запустите ./scripts/generate_dashboard.py.</div>'
    );
    return;
  }

  const mealNames = {
    breakfast: "завтрак",
    lunch: "обед",
    dinner: "ужин",
    snack: "перекус",
  };

  const workoutNames = {
    running: "Бег",
    functional_strength_training: "Функционально-силовая",
  };

  const baseNames = {
    meat: "Мясо",
    chicken: "Курица",
    fish: "Рыба",
  };

  const monthSelect = document.getElementById("monthSelect");
  let selectedMonth = payload.meta.months[payload.meta.months.length - 1];
  let currentDays = [];

  function average(values) {
    const numeric = values
      .filter((value) => value !== null && value !== undefined && value !== "")
      .filter((value) => Number.isFinite(Number(value)))
      .map(Number);
    return numeric.length
      ? numeric.reduce((sum, value) => sum + value, 0) / numeric.length
      : null;
  }

  function sum(values) {
    return values.reduce((total, value) => total + (Number(value) || 0), 0);
  }

  function round(value, precision = 0) {
    if (value === null || value === undefined || Number.isNaN(Number(value))) return "—";
    return new Intl.NumberFormat("ru-RU", {
      maximumFractionDigits: precision,
      minimumFractionDigits: precision,
    }).format(Number(value));
  }

  function formatHours(minutes) {
    if (minutes === null || minutes === undefined || !Number.isFinite(Number(minutes))) return "—";
    const totalMinutes = Math.round(Number(minutes));
    const hours = Math.floor(totalMinutes / 60);
    const remainder = totalMinutes % 60;
    return remainder ? `${hours} ч ${remainder} мин` : `${hours} ч`;
  }

  function shortHours(minutes) {
    if (minutes === null || minutes === undefined || !Number.isFinite(Number(minutes))) return "—";
    const totalMinutes = Math.round(Number(minutes));
    const hours = Math.floor(totalMinutes / 60);
    const remainder = totalMinutes % 60;
    return `${hours}:${String(remainder).padStart(2, "0")}`;
  }

  function monthLabel(month) {
    const date = new Date(`${month}-01T12:00:00`);
    const value = new Intl.DateTimeFormat("ru-RU", {
      month: "long",
      year: "numeric",
    }).format(date);
    return value.charAt(0).toUpperCase() + value.slice(1);
  }

  function dayLabel(dateString) {
    return new Intl.DateTimeFormat("ru-RU", { weekday: "short" })
      .format(new Date(`${dateString}T12:00:00`))
      .replace(".", "");
  }

  function calendarDateLabel(dateString) {
    return new Intl.DateTimeFormat("ru-RU", { day: "numeric", month: "long" })
      .format(new Date(`${dateString}T12:00:00`));
  }

  function plural(number, forms) {
    const absolute = Math.abs(number) % 100;
    const last = absolute % 10;
    if (absolute > 10 && absolute < 20) return forms[2];
    if (last > 1 && last < 5) return forms[1];
    if (last === 1) return forms[0];
    return forms[2];
  }

  function setText(id, value) {
    const element = document.getElementById(id);
    if (element) element.textContent = value;
  }

  function daysForMonth() {
    return payload.daily.filter((day) => day.diary_date.startsWith(selectedMonth));
  }

  function mealsForDate(date) {
    return payload.meals.filter((meal) => meal.diary_date === date);
  }

  function workoutsForMonth() {
    return payload.workouts.filter((workout) => workout.diary_date.startsWith(selectedMonth));
  }

  function renderHeader(days) {
    const complete = days.filter((day) => day.status === "complete");
    const latest = days[days.length - 1];
    const completeSleep = complete.filter((day) => day.sleep_minutes !== null);
    const sleepAverage = average(completeSleep.map((day) => day.sleep_minutes));
    const allSleepAverage = average(days.map((day) => day.sleep_minutes));
    const calorieAverage = average(complete.map((day) => day.calories_kcal));
    const ratingAverage = average(days.map((day) => day.day_rating));
    const workoutMinutes = sum(days.map((day) => day.workout_minutes));
    const distance = sum(days.map((day) => day.distance_km));
    const workoutCount = sum(days.map((day) => day.workout_count));

    setText("trackedDays", days.length);
    setText("completeDays", complete.length);
    setText("sleepMetric", allSleepAverage === null ? "—" : shortHours(allSleepAverage));
    const sleepRecords = days.filter((day) => day.has_sleep).length;
    setText(
      "sleepMeta",
      `среднее по ${sleepRecords} ${plural(sleepRecords, ["записи", "записям", "записям"])}`
    );
    setText("calorieMetric", calorieAverage === null ? "—" : `${round(calorieAverage)} ккал`);
    setText("trainingMetric", `${round(workoutMinutes)} мин`);
    setText(
      "trainingMeta",
      `${workoutCount} ${plural(workoutCount, ["тренировка", "тренировки", "тренировок"])} · ${round(distance, 1)} км бега`
    );
    setText("ratingMetric", ratingAverage === null ? "—" : `${round(ratingAverage, 1)} / 5`);

    if (sleepAverage !== null) {
      setText("focusValue", shortHours(sleepAverage));
      setText("focusLabel", "средний сон в завершённые дни");
    } else {
      setText("focusValue", `${days.length}`);
      setText("focusLabel", "дней в первой выборке");
    }

    if (latest) {
      setText(
        "latestStatus",
        latest.status === "complete"
          ? `День за ${calendarDateLabel(latest.diary_date)} завершён`
          : `День за ${calendarDateLabel(latest.diary_date)} ещё заполняется и исключён из дневных средних`
      );
      setText("dataFreshness", `Последняя запись: ${latest.diary_date}`);
    }

    const sampleText = complete.length < 14
      ? "Выборка пока короткая: тренды — предварительные, но уже видно, где улучшить качество наблюдений."
      : "Данных достаточно для первых устойчивых сравнений внутри месяца.";
    setText("heroSummary", sampleText);

    const latestSleep = latest && latest.sleep_minutes;
    if (sleepAverage !== null && sleepAverage < 420) {
      const recoveryNote = latestSleep >= 450
        ? ` Последняя запись — ${formatHours(latestSleep)}, что похоже на компенсирующий более длинный сон.`
        : "";
      setText(
        "primaryInsight",
        `В завершённые дни средний сон — ${formatHours(sleepAverage)} при ${round(workoutMinutes)} минутах тренировок.${recoveryNote}`
      );
    } else {
      setText(
        "primaryInsight",
        `За период записано ${workoutCount} ${plural(workoutCount, ["тренировка", "тренировки", "тренировок"])} и ${round(distance, 1)} км бега. Продолжаем собирать базовую линию.`
      );
    }
  }

  function renderMacros(days) {
    const complete = days.filter((day) => day.status === "complete");
    const macros = [
      { name: "Белки", value: average(complete.map((day) => day.protein_g)) },
      { name: "Жиры", value: average(complete.map((day) => day.fat_g)) },
      { name: "Углеводы", value: average(complete.map((day) => day.carbs_g)) },
    ];
    const maxValue = Math.max(...macros.map((macro) => macro.value || 0), 1);
    const container = document.getElementById("macroList");
    container.replaceChildren();

    macros.forEach((macro) => {
      const row = document.createElement("div");
      row.className = "macro-row";
      const label = document.createElement("span");
      label.textContent = macro.name;
      const track = document.createElement("div");
      track.className = "macro-track";
      const fill = document.createElement("i");
      fill.style.width = `${((macro.value || 0) / maxValue) * 100}%`;
      track.appendChild(fill);
      const value = document.createElement("strong");
      value.textContent = macro.value === null ? "—" : `${round(macro.value, 1)} г`;
      row.append(label, track, value);
      container.appendChild(row);
    });
  }

  function renderFoodBases(days) {
    const container = document.getElementById("foodBases");
    container.replaceChildren();
    const counts = { meat: 0, chicken: 0, fish: 0 };
    days.forEach((day) => {
      String(day.food_bases || "")
        .split(",")
        .map((item) => item.trim())
        .filter(Boolean)
        .forEach((base) => { counts[base] = (counts[base] || 0) + 1; });
    });

    Object.keys(counts).forEach((base) => {
      const item = document.createElement("div");
      item.className = "base-item";
      const label = document.createElement("span");
      label.textContent = baseNames[base] || base;
      const value = document.createElement("strong");
      value.textContent = `${counts[base]} / ${days.length}`;
      item.append(label, value);
      container.appendChild(item);
    });
  }

  function renderActivity(days) {
    const workouts = workoutsForMonth();
    const container = document.getElementById("activityList");
    container.replaceChildren();
    setText(
      "activityTitle",
      workouts.length
        ? `${workouts.length} ${plural(workouts.length, ["тренировка", "тренировки", "тренировок"])}`
        : "Нет записей"
    );

    workouts.forEach((workout) => {
      const item = document.createElement("div");
      item.className = "activity-item";
      const date = document.createElement("div");
      date.className = "activity-day";
      date.textContent = Number(workout.diary_date.slice(-2));
      const copy = document.createElement("div");
      copy.className = "activity-copy";
      const name = document.createElement("strong");
      name.textContent = workoutNames[workout.workout_type] || workout.workout_type;
      const duration = document.createElement("span");
      duration.textContent = `${round(workout.duration_minutes)} минут`;
      copy.append(name, duration);
      const distance = document.createElement("span");
      distance.className = "activity-distance";
      distance.textContent = workout.distance_km
        ? `${round(workout.distance_km, 2)} км`
        : workout.calories_burned_kcal
          ? `${round(workout.calories_burned_kcal)} ккал`
          : "зал";
      item.append(date, copy, distance);
      container.appendChild(item);
    });

    if (!workouts.length) {
      const empty = document.createElement("p");
      empty.className = "panel-footnote";
      empty.textContent = "Отсутствие записи не означает отсутствие активности.";
      container.appendChild(empty);
    }
  }

  function renderDays(days) {
    const container = document.getElementById("dayList");
    container.replaceChildren();
    [...days].reverse().forEach((day) => {
      const row = document.createElement("article");
      row.className = "day-row";

      const date = document.createElement("div");
      date.className = "day-date";
      const number = document.createElement("strong");
      number.textContent = Number(day.diary_date.slice(-2));
      const weekday = document.createElement("span");
      weekday.textContent = dayLabel(day.diary_date);
      date.append(number, weekday);

      const primary = document.createElement("div");
      primary.className = "day-primary";
      const calories = document.createElement("strong");
      calories.textContent = `${round(day.calories_kcal)} ккал`;
      const details = document.createElement("span");
      details.className = "day-details";
      details.textContent = day.has_workout
        ? `${formatHours(day.sleep_minutes)} сна · ${round(day.workout_minutes)} мин нагрузки`
        : `${formatHours(day.sleep_minutes)} сна · нагрузка не записана`;
      const status = document.createElement("span");
      status.className = `day-status${day.status === "complete" ? "" : " in-progress"}`;
      status.textContent = day.status === "complete" ? "завершён" : "заполняется";
      primary.append(calories, details, status);

      const mealCopy = document.createElement("div");
      mealCopy.className = "day-meals";
      const meals = mealsForDate(day.diary_date);
      mealCopy.textContent = meals.length
        ? meals.map((meal) => `${mealNames[meal.meal_type] || meal.meal_type}: ${meal.foods}`).join(" · ")
        : "Питание не записано";

      const rating = document.createElement("div");
      rating.className = "day-rating";
      const ratingValue = document.createElement("strong");
      ratingValue.textContent = day.day_rating || "—";
      const ratingLabel = document.createElement("span");
      ratingLabel.textContent = "из 5";
      rating.append(ratingValue, ratingLabel);

      row.append(date, primary, mealCopy, rating);
      container.appendChild(row);
    });
  }

  function renderCoverage(days) {
    const container = document.getElementById("coverageTable");
    container.replaceChildren();
    const grid = document.createElement("div");
    grid.className = "coverage-grid";
    const headers = ["День", "Еда", "Сон", "Нагрузка", "Самочув.", "Оценка", "Траты"];
    headers.forEach((header) => {
      const cell = document.createElement("div");
      cell.className = "coverage-head";
      cell.textContent = header;
      grid.appendChild(cell);
    });

    days.forEach((day) => {
      const date = document.createElement("div");
      date.textContent = Number(day.diary_date.slice(-2));
      grid.appendChild(date);
      [
        day.nutrition_entry_count > 0,
        Boolean(day.has_sleep),
        Boolean(day.has_workout),
        Boolean(day.has_wellbeing),
        Boolean(day.has_rating),
        Boolean(day.has_expenses),
      ].forEach((present) => {
        const cell = document.createElement("div");
        const dot = document.createElement("span");
        dot.className = `coverage-dot${present ? "" : " is-empty"}`;
        dot.title = present ? "Есть запись" : "Нет записи";
        cell.appendChild(dot);
        grid.appendChild(cell);
      });
    });
    container.appendChild(grid);
  }

  function renderQuality(days) {
    const container = document.getElementById("qualityCards");
    container.replaceChildren();
    const sleepDays = days.filter((day) => day.has_sleep).length;
    const sleepQualityDays = days.filter((day) => day.sleep_quality !== null).length;
    const monthQuality = payload.quality.find((item) => item.diary_month === selectedMonth) || {};
    const estimated = Number(monthQuality.estimated_entries) || 0;
    const entries = Number(monthQuality.nutrition_entries) || 0;
    const incomplete = Number(monthQuality.incomplete_macro_entries) || 0;
    const cards = [
      {
        value: `${sleepQualityDays} / ${sleepDays}`,
        text: "записей сна содержат субъективную оценку качества",
      },
      {
        value: `${estimated} / ${entries}`,
        text: "записей питания явно помечены как оценочные",
      },
      {
        value: `${incomplete}`,
        text: "запись содержит калории, но неполные БЖУ",
      },
      {
        value: "0",
        text: "микронутриентов хранятся структурно — витаминный анализ пока преждевременен",
      },
    ];

    cards.forEach((card) => {
      const item = document.createElement("article");
      item.className = "quality-card";
      const value = document.createElement("strong");
      value.textContent = card.value;
      const text = document.createElement("p");
      text.textContent = card.text;
      item.append(value, text);
      container.appendChild(item);
    });

    if (sleepQualityDays === 0 && sleepDays > 0) {
      setText("nextStepTitle", "Добавлять качество сна утром");
      setText(
        "nextStepText",
        "Один ответ по шкале 1–5 и короткая отметка о пробуждениях дадут больше пользы, чем ещё одна приблизительная десятая грамма в оценке еды."
      );
    } else if (estimated > entries / 2) {
      setText("nextStepTitle", "Добавлять масштаб к фотографии еды");
      setText(
        "nextStepText",
        "Диаметр тарелки, масса с упаковки и количество масла сокращают главную погрешность фотооценки без усложнения дневника."
      );
    }
  }

  function prepareCanvas(canvas) {
    const ratio = Math.min(window.devicePixelRatio || 1, 2);
    const rect = canvas.getBoundingClientRect();
    const width = Math.max(rect.width, 280);
    const height = Math.max(rect.height, 220);
    canvas.width = Math.round(width * ratio);
    canvas.height = Math.round(height * ratio);
    const context = canvas.getContext("2d");
    context.setTransform(ratio, 0, 0, ratio, 0, 0);
    return { context, width, height };
  }

  function drawCalorieChart(days) {
    const canvas = document.getElementById("calorieChart");
    const { context, width, height } = prepareCanvas(canvas);
    context.clearRect(0, 0, width, height);
    if (!days.length) return;

    const padding = { top: 18, right: 8, bottom: 34, left: 48 };
    const plotWidth = width - padding.left - padding.right;
    const plotHeight = height - padding.top - padding.bottom;
    const maxValue = Math.max(...days.map((day) => Number(day.calories_kcal) || 0), 2400);
    const ceiling = Math.ceil(maxValue / 500) * 500;

    context.font = "11px ui-sans-serif, system-ui";
    context.textAlign = "right";
    context.textBaseline = "middle";
    for (let index = 0; index <= 4; index += 1) {
      const y = padding.top + (plotHeight / 4) * index;
      const value = ceiling - (ceiling / 4) * index;
      context.strokeStyle = "rgba(29,36,32,.10)";
      context.beginPath();
      context.moveTo(padding.left, y);
      context.lineTo(width - padding.right, y);
      context.stroke();
      context.fillStyle = "#7a817c";
      context.fillText(round(value), padding.left - 8, y);
    }

    const slot = plotWidth / days.length;
    const barWidth = Math.min(54, slot * 0.54);
    days.forEach((day, index) => {
      const value = Number(day.calories_kcal) || 0;
      const barHeight = (value / ceiling) * plotHeight;
      const x = padding.left + slot * index + (slot - barWidth) / 2;
      const y = padding.top + plotHeight - barHeight;
      context.fillStyle = day.status === "complete" ? "#246b59" : "#b9d4c7";
      context.fillRect(x, y, barWidth, barHeight);
      if (day.status !== "complete") {
        context.fillStyle = "#e36f45";
        context.fillRect(x, y, barWidth, 4);
      }
      context.fillStyle = "#68706a";
      context.textAlign = "center";
      context.textBaseline = "top";
      context.fillText(Number(day.diary_date.slice(-2)), x + barWidth / 2, height - 22);
    });

    const complete = days.filter((day) => day.status === "complete");
    const calorieAverage = average(complete.map((day) => day.calories_kcal));
    setText("calorieAverage", calorieAverage === null ? "—" : `${round(calorieAverage)} ккал`);
  }

  function drawSleepChart(days) {
    const canvas = document.getElementById("sleepChart");
    const { context, width, height } = prepareCanvas(canvas);
    context.clearRect(0, 0, width, height);
    const points = days.filter((day) => day.sleep_minutes !== null);
    if (!points.length) return;

    const padding = { top: 20, right: 16, bottom: 34, left: 40 };
    const plotWidth = width - padding.left - padding.right;
    const plotHeight = height - padding.top - padding.bottom;
    const ceiling = 10;

    context.font = "11px ui-sans-serif, system-ui";
    for (let hours = 2; hours <= ceiling; hours += 2) {
      const y = padding.top + plotHeight - (hours / ceiling) * plotHeight;
      context.strokeStyle = "rgba(255,253,248,.15)";
      context.beginPath();
      context.moveTo(padding.left, y);
      context.lineTo(width - padding.right, y);
      context.stroke();
      context.fillStyle = "rgba(255,253,248,.55)";
      context.textAlign = "right";
      context.textBaseline = "middle";
      context.fillText(`${hours}ч`, padding.left - 8, y);
    }

    const coords = points.map((day, index) => {
      const x = points.length === 1
        ? padding.left + plotWidth / 2
        : padding.left + (plotWidth / (points.length - 1)) * index;
      const y = padding.top + plotHeight - ((Number(day.sleep_minutes) / 60) / ceiling) * plotHeight;
      return { x, y, day };
    });

    context.strokeStyle = "#d8f56f";
    context.lineWidth = 3;
    context.beginPath();
    coords.forEach((point, index) => {
      if (index === 0) context.moveTo(point.x, point.y);
      else context.lineTo(point.x, point.y);
    });
    context.stroke();

    coords.forEach((point) => {
      context.fillStyle = "#d8f56f";
      context.beginPath();
      context.arc(point.x, point.y, 5, 0, Math.PI * 2);
      context.fill();
      context.fillStyle = "rgba(255,253,248,.7)";
      context.textAlign = "center";
      context.textBaseline = "top";
      context.fillText(Number(point.day.diary_date.slice(-2)), point.x, height - 22);
    });

    const sleepAverage = average(points.map((day) => day.sleep_minutes));
    setText("sleepAverage", formatHours(sleepAverage));
  }

  function render() {
    currentDays = daysForMonth();
    renderHeader(currentDays);
    renderMacros(currentDays);
    renderFoodBases(currentDays);
    renderActivity(currentDays);
    renderDays(currentDays);
    renderCoverage(currentDays);
    renderQuality(currentDays);
    drawCalorieChart(currentDays);
    drawSleepChart(currentDays);
  }

  payload.meta.months.forEach((month) => {
    const option = document.createElement("option");
    option.value = month;
    option.textContent = monthLabel(month);
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
    resizeFrame = requestAnimationFrame(() => {
      drawCalorieChart(currentDays);
      drawSleepChart(currentDays);
    });
  });

  const navLinks = Array.from(document.querySelectorAll(".section-nav a"));
  const observedSections = navLinks
    .map((link) => document.querySelector(link.getAttribute("href")))
    .filter(Boolean);
  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
        if (!visible) return;
        navLinks.forEach((link) => {
          link.classList.toggle("is-active", link.getAttribute("href") === `#${visible.target.id}`);
        });
      },
      { rootMargin: "-18% 0px -68% 0px", threshold: [0, 0.2, 0.6] }
    );
    observedSections.forEach((section) => observer.observe(section));
  }

  render();
})();
