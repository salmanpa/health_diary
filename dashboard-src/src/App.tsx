import { useMemo, useState } from "react";
import * as Dialog from "@radix-ui/react-dialog";
import {
  Activity,
  Apple,
  CalendarDays,
  ChartPie,
  Check,
  ChevronRight,
  CircleAlert,
  Dumbbell,
  Gauge,
  HeartPulse,
  LayoutDashboard,
  MoonStar,
  ShieldCheck,
  Sparkles,
  Timer,
  TrendingUp,
  Utensils,
  X,
} from "lucide-react";
import type { EChartsCoreOption } from "echarts/core";
import { Chart } from "./Chart";
import {
  aggregateMetric,
  eligibleDays,
  formatNumber,
  fullDate,
  getPeriodWindow,
  rollingNutrientAverage,
  shortDate,
} from "./analytics";
import {
  energyProfile,
  groupMealsByType,
  macroProfile,
  mealMacroHighlight,
  sleepSummary,
  trainingSummary,
  type EnergyBand,
  type EnergyProfile,
  type MacroProfile,
  type SleepSummary,
  type TrainingSummary,
} from "./dashboardModel";
import { PRESENTATION_RULES } from "./presentationRules";
import { snapshot } from "./snapshot";
import type { DiaryDay, Metric, PeriodKey } from "./types";

const PERIODS: Array<{ key: PeriodKey; label: string }> = [
  { key: "7", label: "7 дней" },
  { key: "14", label: "14 дней" },
  { key: "30", label: "30 дней" },
  { key: "all", label: "Всё" },
];

const MEAL_GROUP_LABELS: Record<string, string> = {
  breakfast: "Завтрак", lunch: "Обед", dinner: "Ужин", snack: "Перекусы",
};

const WORKOUT_LABELS: Record<string, string> = {
  running: "Бег",
  gym: "Зал",
  walking: "Ходьба",
  functional_strength: "Функциональная силовая",
  functional_strength_training: "Функциональная силовая",
  "Функциональная силовая тренировка": "Функциональная силовая",
};

const ENERGY_BAND_LABELS: Record<EnergyBand, string> = {
  below: "ниже личного диапазона",
  typical: "около среднего",
  above: "выше личного диапазона",
  unclassified: "нет классификации",
};

const CHART_PALETTE = {
  ink: "#17231e",
  muted: "#66736c",
  grid: "#dce4df",
  green: "#17785b",
  blue: "#326f9d",
  violet: "#7462a4",
  amber: "#aa701e",
  red: "#b64e45",
  surface: "#ffffff",
} as const;

function metricValue(metric: Metric, digits = 0): string {
  return metric.valueStatus === "missing" ? "—" : formatNumber(metric.value, digits);
}

function mealGroupCountLabel(count: number): string {
  return `${count} ${count === 1 ? "приём пищи" : count < 5 ? "приёма пищи" : "приёмов пищи"}`;
}

function dishCountLabel(count: number): string {
  const mod100 = count % 100;
  const mod10 = count % 10;
  const noun = mod100 >= 11 && mod100 <= 14 ? "блюд" : mod10 === 1 ? "блюдо" : mod10 >= 2 && mod10 <= 4 ? "блюда" : "блюд";
  return `${count} ${noun}`;
}

function paceLabel(seconds: number | null): string {
  if (seconds === null) return "—";
  const minutes = Math.floor(seconds / 60);
  return `${minutes}:${String(Math.round(seconds % 60)).padStart(2, "0")} /км`;
}

function confidenceLabel(value: string): string {
  return ({ high: "высокая", medium: "средняя", low: "низкая", unknown: "неизвестна" } as Record<string, string>)[value] ?? value;
}

function provenanceLabel(value: string): string {
  return ({ measured: "измерено", labelled: "по этикетке", calculated: "расчёт", estimated: "оценка", unknown: "источник неизвестен" } as Record<string, string>)[value] ?? value;
}

function statusLabel(value: DiaryDay["status"]): string {
  return value === "complete" ? "завершён" : value === "in_progress" ? "в процессе" : "нет записи";
}

function SectionHeading({ kicker, title, description, aside }: {
  kicker: string;
  title: string;
  description: string;
  aside?: React.ReactNode;
}) {
  return <div className="section-heading">
    <div><div className="eyebrow">{kicker}</div><h2>{title}</h2><p>{description}</p></div>
    {aside ? <div className="section-aside">{aside}</div> : null}
  </div>;
}

function KpiCard({ icon, label, value, detail, meta, tone = "green" }: {
  icon: React.ReactNode;
  label: string;
  value: React.ReactNode;
  detail: React.ReactNode;
  meta: React.ReactNode;
  tone?: "green" | "blue" | "violet" | "amber";
}) {
  return <article className={`kpi-card tone-${tone}`}>
    <div className="kpi-top"><span className="icon-tile" aria-hidden="true">{icon}</span><span className="eyebrow">{label}</span></div>
    <div className="kpi-value">{value}</div>
    <div className="kpi-detail">{detail}</div>
    <div className="kpi-meta">{meta}</div>
  </article>;
}

function StateLegend() {
  return <div className="state-legend" aria-label="Легенда состояний данных">
    <span><i className="legend-dot measured" /> значение</span>
    <span><i className="legend-dot estimated" /> оценка</span>
    <span><i className="legend-dot minimum" /> известный минимум</span>
    <span><i className="legend-gap" /> нет данных</span>
  </div>;
}

function averageMarkLine(value: number | null, label: string, color: string) {
  if (value === null) return undefined;
  return {
    silent: true,
    symbol: "none",
    lineStyle: { color, type: "dashed", width: 1.5, opacity: 0.8 },
    label: { show: true, formatter: `${label} ${formatNumber(value, value < 10 ? 1 : 0)}`, color, fontSize: 10, position: "insideEndTop" },
    data: [{ yAxis: value }],
  };
}

function DayDrawer({ date, onOpenChange }: { date: string | null; onOpenChange: (open: boolean) => void }) {
  const day = snapshot.days.find((item) => item.date === date) ?? null;
  const meals = snapshot.meals.filter((item) => item.date === date);
  const mealGroups = groupMealsByType(meals);
  const workouts = snapshot.workouts.filter((item) => item.date === date);
  const sleep = snapshot.sleep.find((item) => item.date === date) ?? null;
  const nutrients = snapshot.nutrients.filter((item) => item.date === date && item.metric.value !== null);
  const plateParts = meals.flatMap((meal) => meal.components).reduce<Record<string, number>>((sum, component) => {
    const key = component.foodGroup ?? "unclassified";
    sum[key] = (sum[key] ?? 0) + (component.weightG ?? 0);
    return sum;
  }, {});
  const plateTotal = Object.values(plateParts).reduce((sum, value) => sum + value, 0);
  const plateColors: Record<string, string> = { vegetables: "#63a56f", fruit: "#e8a54b", meat: "#b9675d", chicken: "#d4a84f", fish: "#5996b2", other: "#9d88b5", unclassified: "#c9cec9" };
  let plateOffset = 0;
  const plateGradient = Object.entries(plateParts).map(([key, value]) => {
    const start = plateOffset; plateOffset += plateTotal ? value / plateTotal * 100 : 0;
    return `${plateColors[key]} ${start}% ${plateOffset}%`;
  }).join(", ");

  return <Dialog.Root open={Boolean(date)} onOpenChange={onOpenChange}>
    <Dialog.Portal>
      <Dialog.Overlay className="drawer-overlay" />
      <Dialog.Content className="day-drawer" aria-describedby="day-drawer-description">
        <div className="drawer-header">
          <div><div className="eyebrow">Детали дня</div><Dialog.Title>{date ? fullDate(date) : "Дата"}</Dialog.Title>
            <Dialog.Description id="day-drawer-description">{day ? `Статус: ${statusLabel(day.status)} · заполнено ${day.completeness.overallPercent ?? 0}%` : "Запись отсутствует"}</Dialog.Description>
          </div>
          <Dialog.Close className="icon-button" aria-label="Закрыть детали дня"><X size={20} /></Dialog.Close>
        </div>
        {day ? <div className="drawer-body">
          <div className="drawer-kpis">
            <div><span>Энергия</span><strong>{metricValue(day.energy)} ккал</strong></div>
            <div><span>Б / Ж / У</span><strong>{metricValue(day.protein)} / {metricValue(day.fat)} / {metricValue(day.carbs)} г</strong></div>
            <div><span>Сон</span><strong>{day.sleepMinutes.value === null ? "—" : `${formatNumber(day.sleepMinutes.value / 60, 1)} ч`}</strong></div>
            <div><span>Оценка дня</span><strong>{metricValue(day.rating, 1)} / 5</strong></div>
          </div>
          {day.completeness.reasons.length ? <section className="drawer-section notice-list">
            <h3><CircleAlert size={18} /> Что не заполнено</h3><ul>{day.completeness.reasons.map((reason) => <li key={reason}>{reason}</li>)}</ul>
          </section> : null}
          <section className="drawer-section"><h3><Utensils size={18} /> Питание <span>{mealGroupCountLabel(mealGroups.length)}</span></h3>
            {mealGroups.length ? <div className="meal-groups">{mealGroups.map((group) => <section className="meal-group" key={group.mealType}>
              <div className="meal-group-header">
                <div><h4>{MEAL_GROUP_LABELS[group.mealType] ?? group.mealType}</h4><span>{dishCountLabel(group.meals.length)}</span></div>
                <strong className={`meal-group-total${group.highEnergy ? " energy-highlight" : ""}`}>{group.energyValue === null ? "—" : `${group.energyStatus === "known_minimum" ? "≥ " : ""}${formatNumber(group.energyValue)} ккал`}</strong>
              </div>
              <div className="meal-list">{group.meals.map((meal) => {
                const highlight = mealMacroHighlight(meal);
                return <article className="meal-card" key={meal.id}>
                  <div className="meal-title"><div>{meal.eatenAt ? <span>{meal.eatenAt}</span> : null}<h5>{meal.title}</h5></div><strong>{formatNumber(meal.energy.value)} ккал</strong></div>
                  <div className="meal-macros">
                    <span className={highlight.highProtein ? "protein-highlight" : ""}>Б {formatNumber(meal.protein.value, 1)}</span>
                    <span className={highlight.highFat ? "fat-highlight" : ""}>Ж {formatNumber(meal.fat.value, 1)}</span>
                    <span className={highlight.highCarbs ? "carbs-highlight" : ""}>У {formatNumber(meal.carbs.value, 1)}</span><span>{formatNumber(meal.weightG)} г</span>
                  </div>
                  <div className="source-row">{provenanceLabel(meal.provenance)} · уверенность {confidenceLabel(meal.confidence)}</div>
                  {meal.components.length ? <ul className="component-list">{meal.components.map((component) => <li key={component.id}><span>{component.name}<small>{component.linked ? component.profileName ?? "есть профиль" : "без профиля микронутриентов"}</small></span><strong>{formatNumber(component.weightG)} г</strong></li>)}</ul> : <p className="empty-inline">Компоненты не реконструированы</p>}
                </article>;
              })}</div>
            </section>)}</div> : <p className="empty-state">Питание за этот день не записано.</p>}
          </section>
          {plateTotal > 0 ? <section className="drawer-section food-plate-section"><h3><ChartPie size={18} /> Тарелка дня <span>по массе компонентов</span></h3>
            <div className="food-plate-layout"><div className="food-plate" role="img" aria-label={`Соотношение записанных компонентов по массе: ${Object.entries(plateParts).map(([key,value]) => `${key} ${Math.round(value / plateTotal * 100)}%`).join(", ")}`} style={{ background: `conic-gradient(${plateGradient})` }}><div>100%<small>{formatNumber(plateTotal)} г</small></div></div>
            <ul className="plate-legend">{Object.entries(plateParts).map(([key,value]) => <li key={key}><i style={{background:plateColors[key]}} /><span>{{vegetables:"Овощи",fruit:"Фрукты",meat:"Мясо",chicken:"Курица",fish:"Рыба",other:"Другое",unclassified:"Не классифицировано"}[key]}</span><strong>{Math.round(value / plateTotal * 100)}%</strong></li>)}</ul></div>
            <p className="plate-note">Это состав всех записанных компонентов дня по съедобной массе, а не норматив «здоровой тарелки». Жидкость и смешанные блюда могут визуально доминировать.</p>
          </section> : null}
          <section className="drawer-section two-columns"><div><h3><MoonStar size={18} /> Сон</h3>
            {sleep ? <dl className="fact-list"><div><dt>Длительность</dt><dd>{formatNumber((sleep.durationMinutes ?? 0) / 60, 1)} ч</dd></div><div><dt>Интервал</dt><dd>{sleep.startedAt ?? "—"} — {sleep.endedAt ?? "—"}</dd></div><div><dt>Качество</dt><dd>{sleep.quality ?? "—"}</dd></div></dl> : <p className="empty-inline">Нет записи</p>}
          </div><div><h3><Dumbbell size={18} /> Тренировки</h3>
            {workouts.length ? workouts.map((workout) => <dl className="fact-list workout-fact" key={workout.id}><div><dt>{WORKOUT_LABELS[workout.type] ?? workout.type}</dt><dd>{formatNumber(workout.durationMinutes)} мин</dd></div><div><dt>Дистанция / темп</dt><dd>{workout.distanceKm === null ? "—" : `${formatNumber(workout.distanceKm, 2)} км`} · {paceLabel(workout.paceSecondsPerKm)}</dd></div><div><dt>RPE / пульс</dt><dd>{workout.rpe ?? "—"} · {workout.averageHeartRate ?? "—"} bpm</dd></div><div><dt>Энергия</dt><dd>{metricValue(workout.energy)} ккал · {provenanceLabel(workout.energy.provenance)}</dd></div></dl>) : <p className="empty-inline">Нет записи; это не подтверждённый день отдыха.</p>}
          </div></section>
          <section className="drawer-section"><h3><Sparkles size={18} /> Нутриенты <span>известный оценённый минимум</span></h3>
            <div className="nutrient-drawer-grid">{nutrients.map((item) => {
              const definition = snapshot.nutrientDefinitions.find((entry) => entry.id === item.nutrientId);
              return <div key={item.nutrientId}><span>{definition?.label ?? item.nutrientId}</span><strong>{formatNumber(item.metric.value, item.metric.value && item.metric.value < 10 ? 2 : 1)} {item.metric.unit}</strong><small>покрытие массы {formatNumber(item.metric.coverage?.mass?.percent, 0)}%</small></div>;
            })}</div>
          </section>
        </div> : <div className="drawer-body"><p className="empty-state">На календарной оси есть дата, но дневная запись отсутствует. Она не считается нулём.</p></div>}
      </Dialog.Content>
    </Dialog.Portal>
  </Dialog.Root>;
}

function ProductGroupsPanel({ days }: { days: DiaryDay[] }) {
  const dates = new Set(days.map((day) => day.date));
  const groups = [
    { id: "meat", icon: "🥩", label: "Мясо" }, { id: "chicken", icon: "🍗", label: "Курица" },
    { id: "fish", icon: "🐟", label: "Рыба" }, { id: "seafood", icon: "🦐", label: "Морепродукты" },
    { id: "vegetables", icon: "🥦", label: "Овощи" }, { id: "fruit", icon: "🍎", label: "Фрукты" },
    { id: "grains", icon: "🌾", label: "Крупы" }, { id: "nuts", icon: "🥜", label: "Орехи" },
    { id: "unknown", icon: "❔", label: "Неизвестно" },
  ] as const;
  const completed = days.filter((day) => day.status === "complete").length;
  const components = snapshot.meals.filter((meal) => dates.has(meal.date)).flatMap((meal) => meal.components);
  const taggedMass = components.filter((item) => item.foodGroup).reduce((sum,item) => sum + (item.weightG ?? 0), 0);
  const totalMass = components.reduce((sum,item) => sum + (item.weightG ?? 0), 0);
  return <section id="products" className="panel span-12 product-panel"><SectionHeading kicker="Основные продукты" title="Что появляется в рационе" description="Каждый компонент 1–2 сентября отнесён к одной из восьми основных категорий либо к «неизвестно». Карточки показывают центральную массу и частоту по дням; оценка «достаточно / много / мало» появится только при ≥7 завершённых днях и хорошем покрытии." />
    <div className="product-grid">{groups.map((group) => {
      const mass = components.filter((item) => item.foodGroup === group.id).reduce((sum,item) => sum + (item.weightG ?? 0), 0);
      const dayCount = group.id === "meat" || group.id === "fish" || group.id === "chicken"
        ? days.filter((day) => day.foodBases.includes(group.id)).length
        : new Set(snapshot.meals.filter((meal) => dates.has(meal.date) && meal.components.some((item) => item.foodGroup === group.id)).map((meal) => meal.date)).size;
      return <article key={group.id}><span className="product-icon" aria-hidden="true">{group.icon}</span><div><h3>{group.label}</h3><strong>{mass ? `${formatNumber(mass)} г` : "масса не размечена"}</strong><p>{dayCount}/{days.length} дней · <b>{completed < 7 || !totalMass || taggedMass / totalMass < .8 ? "данных мало для оценки" : "описательная частота"}</b></p></div></article>;
    })}</div><p className="coverage-line">Покрытие структурными тегами: {totalMass ? formatNumber(taggedMass / totalMass * 100) : "—"}% массы · завершено {completed}/{days.length} дней.</p>
  </section>;
}

function EnergyPanel({ days, profile, openDay }: { days: DiaryDay[]; profile: EnergyProfile; openDay: (date: string) => void }) {
  const palette = CHART_PALETTE;
  const colors: Record<EnergyBand, string> = { below: palette.green, typical: palette.blue, above: palette.red, unclassified: palette.grid };
  const option = useMemo<EChartsCoreOption>(() => ({
    animationDuration: 300,
    aria: { enabled: true, decal: { show: true }, description: "Калорийность по завершённым дням с относительным сравнением и линией среднего" },
    tooltip: { trigger: "axis", valueFormatter: (value: unknown) => `${formatNumber(Number(value))} ккал` },
    grid: { left: 48, right: 20, top: 36, bottom: 48 },
    xAxis: { type: "category", data: days.map((day) => day.date), axisLabel: { formatter: (value: string) => shortDate(value), color: palette.muted, rotate: days.length > 14 ? 38 : 0 }, axisTick: { show: false }, axisLine: { lineStyle: { color: palette.grid } } },
    yAxis: { type: "value", name: "ккал", nameTextStyle: { color: palette.muted }, axisLabel: { color: palette.muted }, splitLine: { lineStyle: { color: palette.grid } } },
    series: [{
      name: "Энергия", type: "bar", barMaxWidth: 34,
      data: days.map((day) => ({ value: day.energy.value, itemStyle: { color: colors[profile.bands.get(day.date) ?? "unclassified"], borderRadius: [4, 4, 0, 0] } })),
      label: { show: true, position: "top", color: palette.ink, fontSize: 9, formatter: (params: { value?: unknown }) => formatNumber(Number(params.value)) },
      labelLayout: { hideOverlap: true },
      markLine: averageMarkLine(profile.average, "Среднее", palette.amber),
    }],
  }), [days, profile, palette, colors]);

  return <section id="timeline" className="panel span-12 energy-panel">
    <SectionHeading kicker="Динамика" title="Энергия по дням" description={`Цвет сравнивает день только с личным средним выбранного периода. Диапазон «около среднего» — ±${PRESENTATION_RULES.energy.relativeBandPercent}%; это не норма и не цель.`} aside={<span className="interaction-hint"><TrendingUp size={16} /> среднее по {profile.n} дням</span>} />
    <div className="energy-band-legend" aria-label="Относительная классификация калорий"><span className="below">↓ ниже диапазона · {profile.counts.below}</span><span className="typical">• около среднего · {profile.counts.typical}</span><span className="above">↑ выше диапазона · {profile.counts.above}</span></div>
    <Chart option={option} className="chart chart-energy" onDateSelect={openDay} />
    <p className="chart-summary">Среднее {formatNumber(profile.average)} ккал; личный диапазон {formatNumber(profile.lowBoundary)}–{formatNumber(profile.highBoundary)} ккал; классифицировано {profile.n} завершённых дней.</p>
    <details className="table-disclosure"><summary>Таблица калорий по дням</summary><div className="table-scroll"><table>
      <caption>Калорийность и относительная позиция каждого дня</caption><thead><tr><th scope="col">Дата</th><th scope="col">Ккал</th><th scope="col">Сравнение</th><th scope="col">Статус</th><th scope="col">Детали</th></tr></thead>
      <tbody>{days.map((day) => { const band = profile.bands.get(day.date) ?? "unclassified"; return <tr key={day.date}><th scope="row">{shortDate(day.date)}</th><td>{metricValue(day.energy)}</td><td>{ENERGY_BAND_LABELS[band]}</td><td>{statusLabel(day.status)}</td><td><button className="table-action" onClick={() => openDay(day.date)} aria-label={`Открыть детали ${fullDate(day.date)}`}><ChevronRight size={17} /></button></td></tr>; })}</tbody>
    </table></div></details>
  </section>;
}

function MacroPanel({ days, profile, openDay }: { days: DiaryDay[]; profile: MacroProfile; openDay: (date: string) => void }) {
  const palette = CHART_PALETTE;
  const macroSpecs = [
    { key: "protein" as const, label: "Белки", color: palette.green, selector: (day: DiaryDay) => day.protein.value },
    { key: "fat" as const, label: "Жиры", color: palette.amber, selector: (day: DiaryDay) => day.fat.value },
    { key: "carbs" as const, label: "Углеводы", color: palette.blue, selector: (day: DiaryDay) => day.carbs.value },
  ];
  const completeDays = days.filter((day) => day.status === "complete");
  const macroAverages = {
    protein: aggregateMetric(completeDays, (day) => day.protein, days.length).value,
    fat: aggregateMetric(completeDays, (day) => day.fat, days.length).value,
    carbs: aggregateMetric(completeDays, (day) => day.carbs, days.length).value,
  };
  const donutOption = useMemo<EChartsCoreOption>(() => ({
    animationDuration: 300,
    aria: { enabled: true, decal: { show: true }, description: "Доли энергии из белков, жиров и углеводов за выбранный период" },
    color: [palette.green, palette.amber, palette.blue],
    tooltip: { trigger: "item", valueFormatter: (value: unknown) => `${formatNumber(Number(value))} ккал` },
    legend: { bottom: 0, textStyle: { color: palette.muted }, itemWidth: 10, itemHeight: 10 },
    series: [{ name: "Энергия из БЖУ", type: "pie", radius: ["48%", "72%"], center: ["50%", "43%"], avoidLabelOverlap: true,
      label: { color: palette.ink, fontSize: 11, formatter: "{b}\n{d}%" },
      labelLine: { length: 10, length2: 8 },
      data: [{ name: "Белки", value: profile.totals.proteinKcal }, { name: "Жиры", value: profile.totals.fatKcal }, { name: "Углеводы", value: profile.totals.carbsKcal }],
    }],
  }), [profile, palette]);
  return <section id="nutrition" className="panel span-12 nutrition-panel">
    <SectionHeading kicker="Питание" title="Макронутриенты без пересечения линий" description="Доли рассчитаны по энергии 4/9/4 для завершённых дней. Это описание рациона, а не персональная цель." aside={<span className="interaction-hint"><ChartPie size={16} /> {profile.days.length}/{days.length} дней</span>} />
    <div className="macro-layout">
      <div className="macro-donut-card"><h3>Структура БЖУ за период</h3><Chart option={donutOption} className="chart chart-donut" />
        <div className="macro-share-summary">{profile.shares ? <><span><i className="protein" />Б {formatNumber(profile.shares.protein, 1)}%</span><span><i className="fat" />Ж {formatNumber(profile.shares.fat, 1)}%</span><span><i className="carbs" />У {formatNumber(profile.shares.carbs, 1)}%</span></> : <span>Недостаточно данных</span>}</div>
      </div>
      <div className="macro-trends">
        <div className="macro-series-grid">{macroSpecs.map((spec) => {
          const option: EChartsCoreOption = {
            animationDuration: 250, aria: { enabled: true, description: `${spec.label} по дням и среднее` },
            tooltip: { trigger: "axis", valueFormatter: (value: unknown) => `${formatNumber(Number(value), 1)} г` },
            grid: { left: 38, right: 14, top: 22, bottom: 32 },
            xAxis: { type: "category", data: days.map((day) => day.date), axisLabel: { formatter: (value: string) => shortDate(value), show: spec.key === "carbs", color: palette.muted, rotate: days.length > 14 ? 38 : 0 }, axisTick: { show: false }, axisLine: { lineStyle: { color: palette.grid } } },
            yAxis: { type: "value", name: "г", nameTextStyle: { color: palette.muted }, axisLabel: { color: palette.muted }, splitLine: { lineStyle: { color: palette.grid } } },
            series: [{ name: spec.label, type: "line", data: days.map(spec.selector), connectNulls: false, symbolSize: 6, lineStyle: { color: spec.color, width: 2 }, itemStyle: { color: spec.color }, label: { show: true, position: "top", color: palette.ink, fontSize: 9, formatter: (params: { value?: unknown }) => formatNumber(Number(params.value), 0) }, labelLayout: { hideOverlap: true }, markLine: averageMarkLine(macroAverages[spec.key], "Среднее", spec.color) }],
          };
          return <article className="macro-series-card" key={spec.key}><h3>{spec.label}</h3><Chart option={option} className="chart chart-macro-row" onDateSelect={openDay} /></article>;
        })}</div>
      </div>
    </div>
    <div className="stable-days"><div><strong>Стабильная структура</strong><span>БЖУ близки к личной медиане периода (±{PRESENTATION_RULES.macros.shareTolerancePercentagePoints} п.п.) и сходятся с калориями по 4/9/4.</span></div><div className="stable-day-list">{profile.days.map((day) => <span key={day.date} className={profile.stableDates.has(day.date) ? "stable" : ""} title={`${shortDate(day.date)}: ${profile.stableDates.has(day.date) ? "стабильная структура" : "вне правила"}`}>{profile.stableDates.has(day.date) ? <Check size={13} /> : "·"}<small>{shortDate(day.date)}</small></span>)}</div></div>
    <details className="table-disclosure"><summary>Таблица состава БЖУ</summary><div className="table-scroll"><table><caption>Энергетическая структура БЖУ по завершённым дням</caption><thead><tr><th scope="col">Дата</th><th scope="col">Белки</th><th scope="col">Жиры</th><th scope="col">Углеводы</th><th scope="col">Структура</th></tr></thead><tbody>{profile.days.map((day) => <tr key={day.date}><th scope="row">{shortDate(day.date)}</th><td>{formatNumber(day.proteinShare, 1)}%</td><td>{formatNumber(day.fatShare, 1)}%</td><td>{formatNumber(day.carbsShare, 1)}%</td><td>{profile.stableDates.has(day.date) ? "стабильная" : "вне правила"}</td></tr>)}</tbody></table></div></details>
  </section>;
}

function RecoveryPanel({ days, sleep, training, openDay }: { days: DiaryDay[]; sleep: SleepSummary; training: TrainingSummary; openDay: (date: string) => void }) {
  const palette = CHART_PALETTE;
  const sleepOption = useMemo<EChartsCoreOption>(() => ({
    animationDuration: 250, aria: { enabled: true, description: "Продолжительность сна по дням с линией среднего" },
    tooltip: { trigger: "axis", valueFormatter: (value: unknown) => `${formatNumber(Number(value), 1)} ч` },
    grid: { left: 42, right: 14, top: 34, bottom: 42 },
    xAxis: { type: "category", data: days.map((day) => day.date), axisLabel: { formatter: (value: string) => shortDate(value), rotate: days.length > 14 ? 38 : 0, color: palette.muted }, axisLine: { lineStyle: { color: palette.grid } } },
    yAxis: { type: "value", name: "ч", nameTextStyle: { color: palette.muted }, axisLabel: { color: palette.muted }, splitLine: { lineStyle: { color: palette.grid } } },
    series: [{ name: "Сон", type: "line", data: days.map((day) => day.sleepMinutes.value === null ? null : day.sleepMinutes.value / 60), connectNulls: false, symbolSize: 7, lineStyle: { width: 2.5, color: palette.violet }, itemStyle: { color: palette.violet }, label: { show: true, position: "top", color: palette.ink, fontSize: 9, formatter: (params: { value?: unknown }) => formatNumber(Number(params.value), 1) }, labelLayout: { hideOverlap: true }, markLine: averageMarkLine(sleep.averageMinutes === null ? null : sleep.averageMinutes / 60, "Среднее", palette.violet) }],
  }), [days, sleep, palette]);
  const workoutAverage = training.activeDays ? training.minutes / training.activeDays : null;
  const workoutOption = useMemo<EChartsCoreOption>(() => ({
    animationDuration: 250, aria: { enabled: true, description: "Записанная длительность тренировок по дням" },
    tooltip: { trigger: "axis", valueFormatter: (value: unknown) => `${formatNumber(Number(value))} мин` },
    grid: { left: 42, right: 14, top: 34, bottom: 42 },
    xAxis: { type: "category", data: days.map((day) => day.date), axisLabel: { formatter: (value: string) => shortDate(value), rotate: days.length > 14 ? 38 : 0, color: palette.muted }, axisLine: { lineStyle: { color: palette.grid } } },
    yAxis: { type: "value", name: "мин", nameTextStyle: { color: palette.muted }, axisLabel: { color: palette.muted }, splitLine: { lineStyle: { color: palette.grid } } },
    series: [{ name: "Тренировка", type: "bar", data: days.map((day) => day.workoutMinutes.value), barMaxWidth: 30, itemStyle: { color: palette.blue, borderRadius: [4, 4, 0, 0] }, label: { show: true, position: "top", color: palette.ink, fontSize: 9, formatter: (params: { value?: unknown }) => formatNumber(Number(params.value)) }, labelLayout: { hideOverlap: true }, markLine: averageMarkLine(workoutAverage, "Среднее активного дня", palette.blue) }],
  }), [days, workoutAverage, palette]);
  const ratingValues = days.flatMap((day) => day.rating.value === null ? [] : [day.rating.value]);
  const ratingAverage = ratingValues.length ? ratingValues.reduce((sum, value) => sum + value, 0) / ratingValues.length : null;
  const ratingOption = useMemo<EChartsCoreOption>(() => ({
    animationDuration: 250, aria: { enabled: true, description: "Пользовательская оценка дня с линией среднего" },
    tooltip: { trigger: "axis", valueFormatter: (value: unknown) => `${formatNumber(Number(value), 1)} из 5` },
    grid: { left: 38, right: 14, top: 34, bottom: 42 },
    xAxis: { type: "category", data: days.map((day) => day.date), axisLabel: { formatter: (value: string) => shortDate(value), rotate: days.length > 14 ? 38 : 0, color: palette.muted }, axisLine: { lineStyle: { color: palette.grid } } },
    yAxis: { type: "value", min: 1, max: 5, interval: 1, axisLabel: { color: palette.muted }, splitLine: { lineStyle: { color: palette.grid } } },
    series: [{ name: "Оценка дня", type: "line", data: days.map((day) => day.rating.value), connectNulls: false, symbolSize: 7, lineStyle: { width: 2, color: palette.green }, itemStyle: { color: palette.green }, label: { show: true, position: "top", color: palette.ink, fontSize: 9, formatter: (params: { value?: unknown }) => formatNumber(Number(params.value), 0) }, labelLayout: { hideOverlap: true }, markLine: averageMarkLine(ratingAverage, "Среднее", palette.green) }],
  }), [days, ratingAverage, palette]);

  return <section id="recovery" className="panel span-12 recovery-panel">
    <SectionHeading kicker="Восстановление и нагрузка" title="Полезные показатели сна и тренировок" description="Средние дополнены разбросом, регулярностью и знаменателями. Отсутствие тренировки в журнале не считается подтверждённым отдыхом." aside={<span className="interaction-hint"><Timer size={16} /> {sleep.n}/{days.length} ночей</span>} />
    <div className="recovery-stat-grid">
      <div><span>Медиана сна</span><strong>{sleep.medianMinutes === null ? "—" : `${formatNumber(sleep.medianMinutes / 60, 1)} ч`}</strong><small>диапазон {sleep.minimumMinutes === null ? "—" : formatNumber(sleep.minimumMinutes / 60, 1)}–{sleep.maximumMinutes === null ? "—" : formatNumber(sleep.maximumMinutes / 60, 1)} ч</small></div>
      <div><span>Разброс сна</span><strong>{sleep.standardDeviationMinutes === null ? "—" : `± ${formatNumber(sleep.standardDeviationMinutes / 60, 1)} ч`}</strong><small>{sleep.consistentNights}/{sleep.n} ночей в пределах ±30 мин от медианы</small></div>
      <div><span>Активные дни</span><strong>{training.activeDays}</strong><small>{training.sessions} сессий · {formatNumber(training.sessionsPerObservedWeek, 1)} сессии на 7 наблюдаемых дней</small></div>
      <div><span>Бег</span><strong>{formatNumber(training.distanceKm, 1)} км</strong><small>темп {paceLabel(training.runningPaceSecondsPerKm)} · n={training.runningPaceN}</small></div>
    </div>
    <div className="recovery-chart-grid"><article><h3>Длительность сна</h3><Chart option={sleepOption} className="chart chart-recovery" onDateSelect={openDay} /></article><article><h3>Записанная нагрузка</h3><Chart option={workoutOption} className="chart chart-recovery" onDateSelect={openDay} /></article><article><h3>Оценка дня</h3><Chart option={ratingOption} className="chart chart-recovery" onDateSelect={openDay} /></article></div>
    <p className="chart-summary">Сон: среднее {sleep.averageMinutes === null ? "—" : `${formatNumber(sleep.averageMinutes / 60, 1)} ч`} ({sleep.n}/{days.length}). Тренировки: {training.sessions} сессий, {formatNumber(training.minutes)} мин, RPE {training.rpeN}/{training.sessions}, средний пульс {training.heartRateN}/{training.sessions}.</p>
    <details className="table-disclosure"><summary>Таблица сна и нагрузки</summary><div className="table-scroll"><table><caption>Сон и записанная тренировочная нагрузка по дням</caption><thead><tr><th scope="col">Дата</th><th scope="col">Сон</th><th scope="col">Тренировка</th><th scope="col">Дистанция</th><th scope="col">Оценка дня</th></tr></thead><tbody>{days.map((day) => <tr key={day.date}><th scope="row">{shortDate(day.date)}</th><td>{day.sleepMinutes.value === null ? "—" : `${formatNumber(day.sleepMinutes.value / 60, 1)} ч`}</td><td>{day.workoutMinutes.value === null ? "—" : `${formatNumber(day.workoutMinutes.value)} мин`}</td><td>{day.workoutDistance.value === null ? "—" : `${formatNumber(day.workoutDistance.value, 1)} км`}</td><td>{metricValue(day.rating, 1)}</td></tr>)}</tbody></table></div></details>
  </section>;
}

function NutrientPanel({ dates, allowedDates }: { dates: string[]; allowedDates: Set<string> }) {
  const definitions = snapshot.nutrientDefinitions;
  const [selected, setSelected] = useState(definitions[0]?.id ?? "fiber_g");
  const [rollingWindow, setRollingWindow] = useState<7 | 14>(7);
  const observations = snapshot.nutrients.filter((item) => allowedDates.has(item.date));
  const selectedDefinition = definitions.find((item) => item.id === selected) ?? definitions[0];
  const selectedObservations = observations.filter((item) => item.nutrientId === selected);
  const rolling = rollingNutrientAverage(dates, observations, selected, rollingWindow);
  const lastRolling = [...rolling].reverse().find((item) => item.value !== null) ?? null;
  const option = useMemo<EChartsCoreOption>(() => ({
    animationDuration: 250, aria: { enabled: true, description: `Скользящее среднее: ${selectedDefinition?.label ?? selected}` }, tooltip: { trigger: "axis" },
    grid: { left: 48, right: 14, top: 32, bottom: 42 },
    xAxis: { type: "category", data: dates, axisLabel: { formatter: (value: string) => shortDate(value), rotate: dates.length > 14 ? 38 : 0, color: CHART_PALETTE.muted }, axisLine: { lineStyle: { color: CHART_PALETTE.grid } } },
    yAxis: { type: "value", name: selectedDefinition?.unit, nameTextStyle: { color: CHART_PALETTE.muted }, axisLabel: { color: CHART_PALETTE.muted }, splitLine: { lineStyle: { color: CHART_PALETTE.grid } } },
    series: [{ type: "line", data: rolling.map((item) => item.value), connectNulls: false, symbolSize: 7, lineStyle: { width: 2.5, color: CHART_PALETTE.green }, itemStyle: { color: CHART_PALETTE.green }, label: { show: true, position: "top", color: CHART_PALETTE.ink, fontSize: 9, formatter: (params: { value?: unknown }) => formatNumber(Number(params.value), Number(params.value) < 10 ? 1 : 0) }, labelLayout: { hideOverlap: true } }],
  }), [dates, rolling, selected, selectedDefinition]);
  return <section id="nutrients" className="panel span-12 nutrient-panel">
    <SectionHeading kicker="Микронутриенты" title="Известный минимум с покрытием" description="В суммы входят только связанные компоненты. Низкое значение здесь не является диагнозом дефицита." aside={<span className="interaction-hint"><ShieldCheck size={16} /> профили {formatNumber(snapshot.quality.profileCoverage.mass?.percent)}% массы</span>} />
    <div className="nutrient-layout"><div className="nutrient-controls"><label>Нутриент<select value={selected} onChange={(event) => setSelected(event.target.value)}>{definitions.map((item) => <option key={item.id} value={item.id}>{item.label}</option>)}</select></label><label>Окно<select value={rollingWindow} onChange={(event) => setRollingWindow(Number(event.target.value) as 7 | 14)}><option value={7}>7 дней</option><option value={14}>14 дней</option></select></label></div>
      <div className="nutrient-number"><span>{rollingWindow}-дневное среднее</span><strong>{formatNumber(lastRolling?.value, (lastRolling?.value ?? 0) < 10 ? 2 : 1)} <small>{selectedDefinition?.unit}</small></strong><p>{lastRolling ? `${lastRolling.n}/${lastRolling.total} дней · покрытие массы ${formatNumber(lastRolling.coverage)}%` : "Недостаточно данных"}</p></div>
      <Chart option={option} className="chart chart-nutrient" /></div>
    <details className="table-disclosure"><summary>Таблица выбранного нутриента</summary><div className="table-scroll"><table><caption>{selectedDefinition?.label}: известный минимум и покрытие по дням</caption><thead><tr><th scope="col">Дата</th><th scope="col">Значение</th><th scope="col">Покрытие массы</th><th scope="col">Уверенность</th></tr></thead><tbody>{selectedObservations.map((item) => <tr key={item.date}><th scope="row">{shortDate(item.date)}</th><td>{formatNumber(item.metric.value, (item.metric.value ?? 0) < 10 ? 2 : 1)} {item.metric.unit}</td><td>{formatNumber(item.metric.coverage?.mass?.percent)}%</td><td>{confidenceLabel(item.metric.confidence)}</td></tr>)}</tbody></table></div></details>
  </section>;
}

function RecommendationPanel({ energy, macros, sleep, training, days }: { energy: EnergyProfile; macros: MacroProfile; sleep: SleepSummary; training: TrainingSummary; days: DiaryDay[] }) {
  const spread = sleep.standardDeviationMinutes === null ? null : sleep.standardDeviationMinutes / 60;
  const cards = [
    { icon: <Gauge size={18} />, title: "Энергия", fact: `${energy.counts.below} ниже · ${energy.counts.typical} около · ${energy.counts.above} выше личного диапазона`, action: "Чтобы цвет означал реальный дефицит или избыток, сначала зафиксируйте персональную цель." },
    { icon: <MoonStar size={18} />, title: "Ритм сна", fact: spread === null ? "Недостаточно ночей для разброса" : `Разброс длительности ±${formatNumber(spread, 1)} ч; записано ${sleep.n}/${days.length} ночей`, action: "Самое полезное дополнение к дневнику — время отхода ко сну и подъёма." },
    { icon: <Dumbbell size={18} />, title: "Нагрузка", fact: `${training.sessions} сессий · ${formatNumber(training.minutes)} мин · RPE ${training.rpeN}/${training.sessions}`, action: training.sessions && training.rpeN < training.sessions ? "После тренировки добавляйте RPE: так нагрузка станет сопоставимой по ощущениям." : "Продолжайте записывать RPE вместе с длительностью." },
    { icon: <Apple size={18} />, title: "Структура питания", fact: `${macros.stableDates.size}/${macros.days.length} дней близки к личной структуре периода`, action: "Это показатель стабильности, а не оценка качества; персональные диапазоны БЖУ зависят от цели." },
  ];
  return <section id="summary" className="panel span-12 recommendations">
    <SectionHeading kicker="Саммари периода" title="Что видно и что улучшить следующим" description="Наблюдения описывают журнал и помогают сделать следующую запись полезнее; они не заменяют медицинскую оценку." />
    <div className="recommendation-grid">{cards.map((card) => <article key={card.title}><span className="recommendation-icon">{card.icon}</span><div><h3>{card.title}</h3><strong>{card.fact}</strong><p>{card.action}</p></div></article>)}</div>
  </section>;
}

function DailyTable({ days, openDay }: { days: DiaryDay[]; openDay: (date: string) => void }) {
  return <section id="days" className="panel span-12 daily-table-panel"><SectionHeading kicker="Календарь" title="Все дни выбранного периода" description="Пропуск остаётся пропуском; неизвестное не превращается в ноль." />
    <div className="table-scroll"><table className="daily-table"><caption>Сводка по датам выбранного периода</caption><thead><tr><th scope="col">Дата</th><th scope="col">Статус</th><th scope="col">Энергия</th><th scope="col">Б / Ж / У</th><th scope="col">Сон</th><th scope="col">Нагрузка</th><th scope="col">Оценка</th><th scope="col">Полнота</th><th scope="col"><span className="sr-only">Детали</span></th></tr></thead>
      <tbody>{[...days].reverse().map((day) => <tr key={day.date}><th scope="row">{fullDate(day.date)}</th><td><span className={`status-pill ${day.status}`}>{statusLabel(day.status)}</span></td><td>{metricValue(day.energy)} {day.energy.value !== null ? "ккал" : ""}</td><td>{metricValue(day.protein)} / {metricValue(day.fat)} / {metricValue(day.carbs)}</td><td>{day.sleepMinutes.value === null ? "—" : `${formatNumber(day.sleepMinutes.value / 60, 1)} ч`}</td><td>{day.workoutMinutes.value === null ? "—" : `${formatNumber(day.workoutMinutes.value)} мин`}</td><td>{metricValue(day.rating, 1)}</td><td><div className="mini-progress"><span style={{ width: `${day.completeness.overallPercent ?? 0}%` }} /><b>{day.completeness.overallPercent === null ? "—" : `${day.completeness.overallPercent}%`}</b></div></td><td><button className="table-action" onClick={() => openDay(day.date)} aria-label={`Открыть детали ${fullDate(day.date)}`}><ChevronRight size={18} /></button></td></tr>)}</tbody>
    </table></div>
  </section>;
}

export function App() {
  const [period, setPeriod] = useState<PeriodKey>("all");
  const [completeOnly, setCompleteOnly] = useState(true);
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const window = useMemo(() => getPeriodWindow(snapshot.days, period, snapshot.meta.period), [period]);
  const includedDays = useMemo(() => eligibleDays(window.days, completeOnly), [window.days, completeOnly]);
  const includedDateSet = useMemo(() => new Set(includedDays.map((day) => day.date)), [includedDays]);
  const dayByDate = useMemo(() => new Map(window.days.map((day) => [day.date, day])), [window.days]);
  const chartDays = window.dates.map((date) => dayByDate.get(date) ?? snapshot.days.find((day) => day.date === date)).filter((day): day is DiaryDay => Boolean(day));
  const visibleDays = chartDays.map((day) => completeOnly && day.status !== "complete" ? {
    ...day,
    energy: { ...day.energy, value: null, valueStatus: "missing" as const },
    protein: { ...day.protein, value: null, valueStatus: "missing" as const },
    fat: { ...day.fat, value: null, valueStatus: "missing" as const },
    carbs: { ...day.carbs, value: null, valueStatus: "missing" as const },
  } : day);
  const denominator = window.dates.length;
  const energy = aggregateMetric(includedDays, (day) => day.energy, denominator);
  const protein = aggregateMetric(includedDays, (day) => day.protein, denominator);
  const fat = aggregateMetric(includedDays, (day) => day.fat, denominator);
  const carbs = aggregateMetric(includedDays, (day) => day.carbs, denominator);
  const rating = aggregateMetric(includedDays, (day) => day.rating, denominator);
  const energyStats = energyProfile(visibleDays);
  const macroStats = macroProfile(visibleDays);
  const sleepStats = sleepSummary(visibleDays);
  const selectedWorkouts = snapshot.workouts.filter((item) => includedDateSet.has(item.date));
  const trainingStats = trainingSummary(selectedWorkouts, window.dates.length);
  const latestLabel = snapshot.meta.latestSourceDate ? fullDate(snapshot.meta.latestSourceDate) : "—";
  const periodLabel = window.from && window.to ? `${shortDate(window.from)} — ${shortDate(window.to)}` : "период не выбран";

  const timeline = <EnergyPanel key="energy" days={visibleDays} profile={energyStats} openDay={setSelectedDate} />;
  const nutrition = <MacroPanel key="macros" days={visibleDays} profile={macroStats} openDay={setSelectedDate} />;
  const recovery = <RecoveryPanel key="recovery" days={visibleDays} sleep={sleepStats} training={trainingStats} openDay={setSelectedDate} />;
  const recommendations = <RecommendationPanel key="summary" energy={energyStats} macros={macroStats} sleep={sleepStats} training={trainingStats} days={visibleDays} />;
  const nutrients = <NutrientPanel key="nutrients" dates={window.dates} allowedDates={includedDateSet} />;
  const dailyTable = <DailyTable key="days" days={chartDays} openDay={setSelectedDate} />;
  const products = <ProductGroupsPanel key="products" days={chartDays} />;

  return <div className="app-shell">
    <a className="skip-link" href="#main-content">Перейти к основному содержимому</a>
    <aside className="sidebar">
      <div className="brand-mark"><HeartPulse size={23} /><span>Health Diary</span></div>
      <nav aria-label="Основная навигация"><a href="#overview"><LayoutDashboard size={18} /><span>Обзор</span></a><a href="#timeline"><Activity size={18} /><span>Энергия</span></a><a href="#nutrition"><Apple size={18} /><span>БЖУ</span></a><a href="#recovery"><MoonStar size={18} /><span>Ритм</span></a><a href="#summary"><Sparkles size={18} /><span>Саммари</span></a><a href="#days"><CalendarDays size={18} /><span>Дни</span></a></nav>
      <div className="sidebar-footer"><ShieldCheck size={16} /><span>локально · без сети</span></div>
    </aside>

    <main id="main-content">
      <header className="utility-header">
        <div className="dashboard-title"><span className="analytics-badge">Аналитика</span><div><h1>Дневник здоровья</h1><p>Питание, сон и тренировочная нагрузка</p></div></div>
        <dl className="snapshot-meta"><div><dt>Период</dt><dd>{periodLabel}</dd></div><div><dt>Данные по</dt><dd>{latestLabel}</dd></div><div><dt>Версия расчёта</dt><dd>{snapshot.meta.calculationVersion}</dd></div></dl>
      </header>

      <div className="control-bar" aria-label="Фильтры периода"><div className="period-tabs" role="group" aria-label="Период">{PERIODS.map((item) => <button key={item.key} className={period === item.key ? "active" : ""} aria-pressed={period === item.key} onClick={() => setPeriod(item.key)}>{item.label}</button>)}</div><label className="switch"><input type="checkbox" checked={completeOnly} onChange={(event) => setCompleteOnly(event.target.checked)} /><span aria-hidden="true" /><b>Только завершённые</b></label><div className="period-meta"><CalendarDays size={16} /> {window.completeDays}/{window.dates.length} завершено</div></div>

      <section id="overview" className="overview-section"><SectionHeading kicker="Обзор периода" title="Средние и диапазоны" description={`${window.completeDays}/${window.dates.length} завершённых дней. Каждый показатель сохраняет собственный знаменатель.`} aside={<StateLegend />} />
        <div className="kpi-grid">
          <KpiCard icon={<Gauge size={19} />} label="Энергия / день" value={<>{formatNumber(energy.value)} <small>ккал</small></>} detail={`${formatNumber(energy.rangeMin)}–${formatNumber(energy.rangeMax)} ккал`} meta={`${energy.n.included}/${energy.n.total} дней · ${energy.completeness === "known_minimum" ? "известный минимум" : provenanceLabel(energy.provenance)}`} />
          <KpiCard icon={<Utensils size={19} />} label="Средние Б / Ж / У" value={<><span>{formatNumber(protein.value)}</span><i>/</i><span>{formatNumber(fat.value)}</span><i>/</i><span>{formatNumber(carbs.value)}</span></>} detail="граммов в день" meta={`${protein.n.included}/${protein.n.total} дней · ${provenanceLabel(protein.provenance)}`} tone="blue" />
          <KpiCard icon={<MoonStar size={19} />} label="Медиана сна" value={<>{sleepStats.medianMinutes === null ? "—" : formatNumber(sleepStats.medianMinutes / 60, 1)} <small>ч</small></>} detail={`${sleepStats.minimumMinutes === null ? "—" : formatNumber(sleepStats.minimumMinutes / 60, 1)}–${sleepStats.maximumMinutes === null ? "—" : formatNumber(sleepStats.maximumMinutes / 60, 1)} ч`} meta={`${sleepStats.n}/${denominator} ночей`} tone="violet" />
          <KpiCard icon={<Timer size={19} />} label="Стабильность сна" value={<>{sleepStats.consistentNights} <small>ночей</small></>} detail="в пределах ±30 мин от медианы" meta={`разброс ${sleepStats.standardDeviationMinutes === null ? "—" : `±${formatNumber(sleepStats.standardDeviationMinutes / 60, 1)} ч`}`} tone="violet" />
          <KpiCard icon={<Dumbbell size={19} />} label="Тренировки" value={<>{trainingStats.sessions} <small>сессий</small></>} detail={`${formatNumber(trainingStats.minutes)} мин · ${formatNumber(trainingStats.distanceKm, 1)} км`} meta={`${formatNumber(trainingStats.sessionsPerObservedWeek, 1)} сессии на 7 наблюдаемых дней`} tone="amber" />
          <KpiCard icon={<Sparkles size={19} />} label="Оценка дня" value={<>{formatNumber(rating.value, 1)} <small>/ 5</small></>} detail="оценка пользователя" meta={`${rating.n.included}/${rating.n.total} дней`} tone="violet" />
        </div>
      </section>

      <div className="dashboard-grid">
        {timeline}
        {nutrition}
        {products}
        {recovery}
        {nutrients}
        {recommendations}
        {dailyTable}
      </div>

      <footer className="page-footer"><span><ShieldCheck size={15} /> Приватный статический снимок · без CDN, API и телеметрии</span><span>Контракт {snapshot.meta.contractVersion} · UI-правила {PRESENTATION_RULES.version} · источник {snapshot.meta.sourceHash.slice(0, 8)}</span></footer>
    </main>

    <nav className="mobile-nav" aria-label="Мобильная навигация"><a href="#overview"><LayoutDashboard size={19} /><span>Обзор</span></a><a href="#timeline"><Activity size={19} /><span>Энергия</span></a><a href="#nutrition"><Apple size={19} /><span>БЖУ</span></a><a href="#summary"><Sparkles size={19} /><span>Саммари</span></a></nav>
    <DayDrawer date={selectedDate} onOpenChange={(open) => { if (!open) setSelectedDate(null); }} />
  </div>;
}
