import { useMemo, useState } from "react";
import * as Dialog from "@radix-ui/react-dialog";
import {
  Activity,
  Apple,
  CalendarDays,
  ChevronRight,
  CircleAlert,
  Database,
  Dumbbell,
  Gauge,
  HeartPulse,
  Info,
  LayoutDashboard,
  MoonStar,
  Scale,
  ShieldCheck,
  Sparkles,
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
import { snapshot } from "./snapshot";
import type {
  DiaryDay,
  Metric,
  NutrientDefinition,
  NutrientObservation,
  PeriodKey,
} from "./types";

const PERIODS: Array<{ key: PeriodKey; label: string }> = [
  { key: "7", label: "7 дней" },
  { key: "14", label: "14 дней" },
  { key: "30", label: "30 дней" },
  { key: "all", label: "Всё" },
];

const MEAL_LABELS: Record<string, string> = {
  breakfast: "Завтрак", lunch: "Обед", dinner: "Ужин", snack: "Перекус",
};

const WORKOUT_LABELS: Record<string, string> = {
  running: "Бег", gym: "Зал", walking: "Ходьба",
};

const prefersDark = typeof window !== "undefined"
  && typeof window.matchMedia === "function"
  && window.matchMedia("(prefers-color-scheme: dark)").matches;

const COLORS = {
  ink: prefersDark ? "#e4eae6" : "#25312b",
  muted: prefersDark ? "#a2ada7" : "#6f7a74",
  grid: prefersDark ? "#35423a" : "#dfe5e0",
  green: "#24735b",
  greenSoft: "#72a58f",
  blue: "#416f92",
  violet: "#7b689a",
  amber: "#b77a25",
  protein: "#2e7d63",
  fat: "#be7b32",
  carbs: "#557aa2",
};

function metricValue(metric: Metric, digits = 0): string {
  return metric.valueStatus === "missing" ? "—" : formatNumber(metric.value, digits);
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

function KpiCard({
  icon,
  label,
  value,
  detail,
  meta,
  tone = "green",
}: {
  icon: React.ReactNode;
  label: string;
  value: React.ReactNode;
  detail: React.ReactNode;
  meta: React.ReactNode;
  tone?: "green" | "blue" | "violet" | "amber";
}) {
  return (
    <article className={`kpi-card tone-${tone}`}>
      <div className="kpi-top">
        <span className="icon-tile" aria-hidden="true">{icon}</span>
        <span className="eyebrow">{label}</span>
      </div>
      <div className="kpi-value">{value}</div>
      <div className="kpi-detail">{detail}</div>
      <div className="kpi-meta">{meta}</div>
    </article>
  );
}

function SectionHeading({
  eyebrow,
  title,
  description,
  aside,
}: {
  eyebrow: string;
  title: string;
  description: string;
  aside?: React.ReactNode;
}) {
  return (
    <div className="section-heading">
      <div>
        <div className="eyebrow">{eyebrow}</div>
        <h2>{title}</h2>
        <p>{description}</p>
      </div>
      {aside ? <div className="section-aside">{aside}</div> : null}
    </div>
  );
}

function StateLegend() {
  return (
    <div className="state-legend" aria-label="Легенда состояний данных">
      <span><i className="legend-dot measured" /> измерено</span>
      <span><i className="legend-dot estimated" /> оценено</span>
      <span><i className="legend-dot minimum" /> известный минимум</span>
      <span><i className="legend-gap" /> нет данных</span>
    </div>
  );
}

function ChartSummaryTable({ days, openDay }: { days: DiaryDay[]; openDay: (date: string) => void }) {
  return (
    <details className="table-disclosure">
      <summary>Таблица значений графика</summary>
      <div className="table-scroll">
        <table>
          <caption>Дневные показатели на общей временной шкале</caption>
          <thead><tr>
            <th scope="col">Дата</th><th scope="col">Ккал</th><th scope="col">Сон</th>
            <th scope="col">Нагрузка</th><th scope="col">Оценка</th><th scope="col">Детали</th>
          </tr></thead>
          <tbody>{days.map((day) => (
            <tr key={day.date}>
              <th scope="row">{shortDate(day.date)}</th>
              <td>{metricValue(day.energy)}</td>
              <td>{day.sleepMinutes.value === null ? "—" : `${formatNumber(day.sleepMinutes.value / 60, 1)} ч`}</td>
              <td>{day.workoutMinutes.value === null ? "—" : `${formatNumber(day.workoutMinutes.value)} мин`}</td>
              <td>{metricValue(day.rating, 1)}</td>
              <td><button className="table-action" onClick={() => openDay(day.date)} aria-label={`Открыть детали ${fullDate(day.date)}`}><ChevronRight size={17} /></button></td>
            </tr>
          ))}</tbody>
        </table>
      </div>
    </details>
  );
}

function DayDrawer({ date, onOpenChange }: { date: string | null; onOpenChange: (open: boolean) => void }) {
  const day = snapshot.days.find((item) => item.date === date) ?? null;
  const meals = snapshot.meals.filter((item) => item.date === date);
  const workouts = snapshot.workouts.filter((item) => item.date === date);
  const sleep = snapshot.sleep.find((item) => item.date === date) ?? null;
  const nutrients = snapshot.nutrients.filter((item) => item.date === date && item.metric.value !== null);

  return (
    <Dialog.Root open={Boolean(date)} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="drawer-overlay" />
        <Dialog.Content className="day-drawer" aria-describedby="day-drawer-description">
          <div className="drawer-header">
            <div>
              <div className="eyebrow">Детали дня</div>
              <Dialog.Title>{date ? fullDate(date) : "Дата"}</Dialog.Title>
              <Dialog.Description id="day-drawer-description">
                {day ? `Статус: ${statusLabel(day.status)} · заполнено ${day.completeness.overallPercent ?? 0}%` : "Запись отсутствует"}
              </Dialog.Description>
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
              <h3><CircleAlert size={18} /> Что ограничивает интерпретацию</h3>
              <ul>{day.completeness.reasons.map((reason) => <li key={reason}>{reason}</li>)}</ul>
            </section> : null}

            <section className="drawer-section">
              <h3><Utensils size={18} /> Питание <span>{meals.length} событий</span></h3>
              {meals.length ? <div className="meal-list">{meals.map((meal) => (
                <article className="meal-card" key={meal.id}>
                  <div className="meal-title">
                    <div><span>{MEAL_LABELS[meal.mealType] ?? meal.mealType}{meal.eatenAt ? ` · ${meal.eatenAt}` : ""}</span><h4>{meal.title}</h4></div>
                    <strong>{formatNumber(meal.energy.value)} ккал</strong>
                  </div>
                  <div className="meal-macros">
                    <span>Б {formatNumber(meal.protein.value, 1)}</span>
                    <span>Ж {formatNumber(meal.fat.value, 1)}</span>
                    <span>У {formatNumber(meal.carbs.value, 1)}</span>
                    <span>{formatNumber(meal.weightG)} г</span>
                  </div>
                  <div className="source-row">{provenanceLabel(meal.provenance)} · уверенность {confidenceLabel(meal.confidence)}</div>
                  {meal.components.length ? <ul className="component-list">{meal.components.map((component) => (
                    <li key={component.id}>
                      <span>{component.name}<small>{component.linked ? component.profileName ?? "есть профиль" : "без профиля микронутриентов"}</small></span>
                      <strong>{formatNumber(component.weightG)} г</strong>
                    </li>
                  ))}</ul> : <p className="empty-inline">Компоненты не реконструированы</p>}
                </article>
              ))}</div> : <p className="empty-state">Питание за этот день не записано.</p>}
            </section>

            <section className="drawer-section two-columns">
              <div>
                <h3><MoonStar size={18} /> Сон</h3>
                {sleep ? <dl className="fact-list">
                  <div><dt>Длительность</dt><dd>{formatNumber((sleep.durationMinutes ?? 0) / 60, 1)} ч</dd></div>
                  <div><dt>Интервал</dt><dd>{sleep.startedAt ?? "—"} — {sleep.endedAt ?? "—"}</dd></div>
                  <div><dt>Качество</dt><dd>{sleep.quality ?? "—"}</dd></div>
                </dl> : <p className="empty-inline">Нет записи</p>}
              </div>
              <div>
                <h3><Dumbbell size={18} /> Тренировки</h3>
                {workouts.length ? workouts.map((workout) => <dl className="fact-list workout-fact" key={workout.id}>
                  <div><dt>{WORKOUT_LABELS[workout.type] ?? workout.type}</dt><dd>{formatNumber(workout.durationMinutes)} мин</dd></div>
                  <div><dt>Дистанция / темп</dt><dd>{workout.distanceKm === null ? "—" : `${formatNumber(workout.distanceKm, 2)} км`} · {paceLabel(workout.paceSecondsPerKm)}</dd></div>
                  <div><dt>RPE / пульс</dt><dd>{workout.rpe ?? "—"} · {workout.averageHeartRate ?? "—"} bpm</dd></div>
                  <div><dt>Энергия</dt><dd>{metricValue(workout.energy)} ккал · {provenanceLabel(workout.energy.provenance)}</dd></div>
                </dl>) : <p className="empty-inline">Нет записи; это не подтверждённый день отдыха.</p>}
              </div>
            </section>

            <section className="drawer-section">
              <h3><Sparkles size={18} /> Нутриенты <span>известный оценённый минимум</span></h3>
              <div className="nutrient-drawer-grid">{nutrients.map((item) => {
                const definition = snapshot.nutrientDefinitions.find((entry) => entry.id === item.nutrientId);
                return <div key={item.nutrientId}>
                  <span>{definition?.label ?? item.nutrientId}</span>
                  <strong>{formatNumber(item.metric.value, item.metric.value && item.metric.value < 10 ? 2 : 1)} {item.metric.unit}</strong>
                  <small>покрытие массы {formatNumber(item.metric.coverage?.mass?.percent, 0)}%</small>
                </div>;
              })}</div>
            </section>
          </div> : <div className="drawer-body"><p className="empty-state">На календарной оси есть дата, но дневная запись отсутствует. Она не считается нулём.</p></div>}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

function NutritionPanel({ days }: { days: DiaryDay[] }) {
  const includedDates = new Set(
    days.filter((day) => day.energy.valueStatus !== "missing").map((day) => day.date),
  );
  const option = useMemo<EChartsCoreOption>(() => ({
    animationDuration: 350,
    aria: { enabled: true, decal: { show: true }, description: "Линии белков, жиров и углеводов по дням" },
    color: [COLORS.blue, "#e0774f", "#d2a83f"],
    tooltip: { trigger: "axis", valueFormatter: (value: unknown) => `${formatNumber(Number(value), 1)} г` },
    legend: { top: 0, left: 0, itemWidth: 10, itemHeight: 10, textStyle: { color: COLORS.muted } },
    grid: { left: 38, right: 12, top: 38, bottom: 38 },
    xAxis: { type: "category", data: days.map((day) => day.date), axisLabel: { formatter: (value: string) => shortDate(value), color: COLORS.muted }, axisLine: { lineStyle: { color: COLORS.grid } } },
    yAxis: { type: "value", name: "г", nameTextStyle: { color: COLORS.muted }, axisLabel: { color: COLORS.muted }, splitLine: { lineStyle: { color: COLORS.grid } } },
    series: [
      { name: "Белки", type: "line", data: days.map((day) => day.protein.value), connectNulls: false, symbolSize: 7, lineStyle: { width: 2 } },
      { name: "Жиры", type: "line", data: days.map((day) => day.fat.value), connectNulls: false, symbolSize: 7, lineStyle: { width: 2 } },
      { name: "Углеводы", type: "line", data: days.map((day) => day.carbs.value), connectNulls: false, symbolSize: 7, lineStyle: { width: 2 } },
    ],
  }), [days]);

  const mealTypes = snapshot.meals.filter((meal) => includedDates.has(meal.date)).reduce<Record<string, { energy: number; protein: number; count: number }>>((acc, meal) => {
    const item = acc[meal.mealType] ?? { energy: 0, protein: 0, count: 0 };
    item.energy += meal.energy.value ?? 0;
    item.protein += meal.protein.value ?? 0;
    item.count += 1;
    acc[meal.mealType] = item;
    return acc;
  }, {});

  return <section id="nutrition" className="panel span-7">
    <SectionHeading eyebrow="Питание" title="Динамика макронутриентов" description="Линейный вид из предыдущей версии; разрывы по-прежнему означают отсутствие данных." />
    <Chart option={option} className="chart chart-medium" />
    <div className="meal-distribution" aria-label="Распределение по типам записей питания">
      {Object.entries(mealTypes).map(([type, item]) => <div key={type}>
        <span>{MEAL_LABELS[type] ?? type}</span>
        <strong>{formatNumber(item.energy)} ккал</strong>
        <small>{item.count} событий · {formatNumber(item.protein, 1)} г белка</small>
      </div>)}
    </div>
  </section>;
}

function NutrientPanel({ dates, allowedDates }: { dates: string[]; allowedDates: Set<string> }) {
  const definitions = snapshot.nutrientDefinitions;
  const [selected, setSelected] = useState(definitions[0]?.id ?? "fiber_g");
  const [rollingWindow, setRollingWindow] = useState<7 | 14>(7);
  const [showMobileHeatmap, setShowMobileHeatmap] = useState(false);
  const observations = snapshot.nutrients.filter((item) => allowedDates.has(item.date));
  const selectedDefinition = definitions.find((item) => item.id === selected) ?? definitions[0];
  const rolling = rollingNutrientAverage(dates, observations, selected, rollingWindow);
  const lastRolling = [...rolling].reverse().find((item) => item.value !== null) ?? null;

  const heatData = observations.flatMap((observation) => {
    const x = dates.indexOf(observation.date);
    const y = definitions.findIndex((definition) => definition.id === observation.nutrientId);
    const definition = definitions[y];
    if (x < 0 || y < 0 || observation.metric.value === null || !definition?.referenceValue) return [];
    return [[x, y, Math.min(180, observation.metric.value / definition.referenceValue * 100), observation.metric.coverage?.mass?.percent ?? null]];
  });
  const heatmapOption = useMemo<EChartsCoreOption>(() => ({
    animation: false,
    aria: { enabled: true, description: "Тепловая карта известных минимальных значений нутриентов относительно справочного ориентира" },
    tooltip: {
      formatter: (params: unknown) => {
        const value = (params as { value?: unknown[] }).value ?? [];
        const date = dates[Number(value[0])] ?? "";
        const definition = definitions[Number(value[1])];
        return `<strong>${definition?.label ?? "Нутриент"}</strong><br>${shortDate(date)} · ${formatNumber(Number(value[2]), 0)}% ориентира<br>покрытие массы ${value[3] == null ? "—" : `${formatNumber(Number(value[3]), 0)}%`}`;
      },
    },
    grid: { left: 76, right: 16, top: 8, bottom: 44 },
    xAxis: { type: "category", data: dates.map(shortDate), axisLabel: { color: COLORS.muted, rotate: dates.length > 14 ? 45 : 0 }, axisLine: { lineStyle: { color: COLORS.grid } } },
    yAxis: { type: "category", data: definitions.map((item) => item.shortLabel), axisLabel: { color: COLORS.muted }, axisLine: { show: false } },
    visualMap: { min: 0, max: 150, orient: "horizontal", left: "center", bottom: 0, calculable: false, text: ["150%+", "0%"], textStyle: { color: COLORS.muted }, inRange: { color: ["#edf1ef", "#b8cfca", "#4f897a"] } },
    series: [{ type: "heatmap", data: heatData, itemStyle: { borderWidth: 3, borderColor: "#fbfcfa", borderRadius: 4 }, emphasis: { itemStyle: { borderColor: COLORS.ink } } }],
  }), [dates, definitions, heatData]);

  const rollingOption = useMemo<EChartsCoreOption>(() => ({
    animationDuration: 300,
    aria: { enabled: true, description: `Скользящее среднее: ${selectedDefinition?.label ?? selected}` },
    tooltip: { trigger: "axis" },
    grid: { left: 46, right: 12, top: 18, bottom: 34 },
    xAxis: { type: "category", data: dates, axisLabel: { formatter: (value: string) => shortDate(value), color: COLORS.muted }, axisLine: { lineStyle: { color: COLORS.grid } } },
    yAxis: { type: "value", name: selectedDefinition?.unit, axisLabel: { color: COLORS.muted }, splitLine: { lineStyle: { color: COLORS.grid } } },
    series: [{ type: "line", data: rolling.map((item) => item.value), smooth: 0.25, connectNulls: false, symbolSize: 7, lineStyle: { width: 3, color: COLORS.green }, itemStyle: { color: COLORS.green }, areaStyle: { color: "rgba(36,115,91,.09)" } }],
  }), [dates, rolling, selected, selectedDefinition]);

  const gates = snapshot.contract.nutrientCoverageGates;
  const comparisonEnabled = !gates.requiresEnergyCoverage || snapshot.quality.profileCoverage.energy !== null;

  return <section id="nutrients" className="panel span-12 nutrient-panel">
    <SectionHeading
      eyebrow="Микронутриенты"
      title="Известный минимум и покрытие"
      description="Цвет показывает долю справочного ориентира, но не подтверждает достаточность: неизвестные компоненты исключены из суммы."
      aside={<span className={`gate-badge ${comparisonEnabled ? "ready" : "limited"}`}><ShieldCheck size={15} /> {comparisonEnabled ? "сравнение доступно" : "без вывода о достаточности"}</span>}
    />
    <div className="nutrient-layout">
      <button className="heatmap-toggle" type="button" aria-expanded={showMobileHeatmap} onClick={() => setShowMobileHeatmap((current) => !current)}>
        {showMobileHeatmap ? "Скрыть матрицу дней" : "Показать матрицу дней"}
      </button>
      <div className={`heatmap-wrap ${showMobileHeatmap ? "open" : ""}`}>
        <Chart option={heatmapOption} className="chart chart-heatmap" />
        <p className="chart-footnote">Energy coverage пока не рассчитывается; порог сравнения из контракта — {gates.comparisonAtOrAbovePercent}%.</p>
      </div>
      <aside className="nutrient-focus">
        <div className="field-row">
          <label>Нутриент<select value={selected} onChange={(event) => setSelected(event.target.value)}>{definitions.map((item) => <option key={item.id} value={item.id}>{item.label}</option>)}</select></label>
          <label>Окно<select value={rollingWindow} onChange={(event) => setRollingWindow(Number(event.target.value) as 7 | 14)}><option value={7}>7 дней</option><option value={14}>14 дней</option></select></label>
        </div>
        <div className="nutrient-focus-value">
          <span>{rollingWindow}-дневное среднее</span>
          <strong>{formatNumber(lastRolling?.value ?? null, (lastRolling?.value ?? 0) < 10 ? 2 : 1)} <small>{selectedDefinition?.unit}</small></strong>
          <p>{lastRolling ? `${lastRolling.n}/${lastRolling.total} дней · среднее покрытие массы ${formatNumber(lastRolling.coverage, 0)}%` : "Недостаточно данных"}</p>
        </div>
        <Chart option={rollingOption} className="chart chart-small" />
        <div className="data-caveat"><Info size={16} /><span>Это оценка поступления с едой, не диагностика дефицита.</span></div>
      </aside>
    </div>
  </section>;
}

function QualityPanel() {
  const coverage = snapshot.quality.profileCoverage;
  const totalConfidence = Object.values(snapshot.quality.confidence).reduce((sum, value) => sum + value, 0);
  return <section id="quality" className="panel span-12">
    <SectionHeading eyebrow="Качество данных" title="Где аналитика сильна, а где осторожна" description="Проверки показывают неполноту и неопределённость, не превращая неизвестное в ноль." />
    <div className="quality-grid">
      <div className="coverage-card">
        <div className="coverage-ring" style={{ "--coverage": `${coverage.mass?.percent ?? 0}%` } as React.CSSProperties}><strong>{formatNumber(coverage.mass?.percent, 0)}%</strong><span>массы</span></div>
        <div><h3>Покрытие профилями</h3><p>{formatNumber(coverage.count?.covered)} из {formatNumber(coverage.count?.total)} компонентов. Энергетическое покрытие ещё недоступно.</p></div>
      </div>
      <div className="confidence-card">
        <h3>Уверенность компонентов</h3>
        <div className="confidence-bar" aria-label="Распределение уверенности">
          {(["high", "medium", "low"] as const).map((key) => <span key={key} className={key} style={{ width: `${totalConfidence ? snapshot.quality.confidence[key] / totalConfidence * 100 : 0}%` }} />)}
        </div>
        <div className="confidence-legend">{(["high", "medium", "low"] as const).map((key) => <span key={key}><i className={key} />{confidenceLabel(key)}: {snapshot.quality.confidence[key]}</span>)}</div>
      </div>
      <div className="issue-list">{snapshot.quality.issues.map((issue) => <article key={issue.id} className={`issue ${issue.severity}`}>
        <span>{issue.severity === "review" ? <CircleAlert size={18} /> : <Info size={18} />}</span>
        <div><strong>{issue.count}</strong><p>{issue.label}</p><small>{issue.dates.length} дат</small></div>
      </article>)}</div>
    </div>
    <details className="table-disclosure quality-details">
      <summary>Крупнейшие компоненты без профиля</summary>
      <div className="table-scroll"><table>
        <caption>Компоненты, не вошедшие в микронутриентные суммы</caption>
        <thead><tr><th scope="col">Компонент</th><th scope="col">Масса</th><th scope="col">Случаев</th><th scope="col">Дат</th></tr></thead>
        <tbody>{snapshot.quality.unlinkedComponents.slice(0, 12).map((item) => <tr key={item.name}><th scope="row">{item.name}</th><td>{formatNumber(item.weightG)} г</td><td>{item.occurrences}</td><td>{item.dates.length}</td></tr>)}</tbody>
      </table></div>
    </details>
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
  const visibleChartDays = chartDays.map((day) => completeOnly && day.status !== "complete"
    ? { ...day, energy: { ...day.energy, value: null, valueStatus: "missing" as const }, protein: { ...day.protein, value: null, valueStatus: "missing" as const }, fat: { ...day.fat, value: null, valueStatus: "missing" as const }, carbs: { ...day.carbs, value: null, valueStatus: "missing" as const } }
    : day);

  const denominator = window.dates.length;
  const energy = aggregateMetric(includedDays, (day) => day.energy, denominator);
  const protein = aggregateMetric(includedDays, (day) => day.protein, denominator);
  const fat = aggregateMetric(includedDays, (day) => day.fat, denominator);
  const carbs = aggregateMetric(includedDays, (day) => day.carbs, denominator);
  const sleep = aggregateMetric(includedDays, (day) => day.sleepMinutes, denominator);
  const rating = aggregateMetric(includedDays, (day) => day.rating, denominator);
  const workouts = snapshot.workouts.filter((item) => includedDateSet.has(item.date));
  const workoutMinutes = workouts.reduce((sum, item) => sum + (item.durationMinutes ?? 0), 0);
  const workoutDistance = workouts.reduce((sum, item) => sum + (item.distanceKm ?? 0), 0);
  const fullEnough = window.completeDays >= snapshot.contract.trendGates.provisionalBelowDays;

  const legacyChart = (unit: string, description: string, series: EChartsCoreOption["series"], dark = false): EChartsCoreOption => ({
    animationDuration: 350,
    aria: { enabled: true, decal: { show: true }, description },
    tooltip: { trigger: "axis", axisPointer: { type: "line" } },
    grid: { left: 48, right: 16, top: 18, bottom: 40 },
    xAxis: { type: "category", data: visibleChartDays.map((day) => day.date), axisLabel: { formatter: (value: string) => shortDate(value), color: dark ? "rgba(251,252,248,.68)" : COLORS.muted, rotate: window.dates.length > 14 ? 35 : 0 }, axisTick: { show: false }, axisLine: { lineStyle: { color: dark ? "rgba(251,252,248,.2)" : COLORS.grid } } },
    yAxis: { type: "value", name: unit, nameTextStyle: { color: dark ? "rgba(251,252,248,.68)" : COLORS.muted }, axisLabel: { color: dark ? "rgba(251,252,248,.68)" : COLORS.muted }, splitLine: { lineStyle: { color: dark ? "rgba(251,252,248,.15)" : COLORS.grid } } },
    series,
  });
  const calorieOption = legacyChart("ккал", "Столбцы калорий по дням", [{ name: "Энергия", type: "bar", data: visibleChartDays.map((day) => day.energy.value), barMaxWidth: 34, itemStyle: { color: COLORS.green, borderRadius: [4, 4, 0, 0] } }]);
  const sleepOption = legacyChart("ч", "Линия продолжительности сна по дням", [{ name: "Сон", type: "line", data: visibleChartDays.map((day) => day.sleepMinutes.value === null ? null : Number((day.sleepMinutes.value / 60).toFixed(1))), connectNulls: false, symbolSize: 7, lineStyle: { width: 3, color: "#bbf07b" }, itemStyle: { color: "#bbf07b" } }], true);
  const activityOption = legacyChart("мин", "Столбцы продолжительности тренировок по дням", [{ name: "Тренировка", type: "bar", data: visibleChartDays.map((day) => day.workoutMinutes.value), barMaxWidth: 34, itemStyle: { color: COLORS.blue, borderRadius: [4, 4, 0, 0] } }]);
  const ratingOption = legacyChart("1–5", "Линия пользовательской оценки дня", [{ name: "Оценка", type: "line", data: visibleChartDays.map((day) => day.rating.value), connectNulls: false, symbolSize: 8, lineStyle: { width: 2, color: COLORS.violet }, itemStyle: { color: COLORS.violet } }]);

  return <div className="app-shell">
    <a className="skip-link" href="#main-content">Перейти к основному содержимому</a>
    <aside className="sidebar">
      <div className="brand-mark"><HeartPulse size={24} /><span>Health<br />Diary</span></div>
      <nav aria-label="Основная навигация">
        <a href="#overview"><LayoutDashboard size={19} /><span>Обзор</span></a>
        <a href="#timeline"><Activity size={19} /><span>Динамика</span></a>
        <a href="#nutrition"><Apple size={19} /><span>Питание</span></a>
        <a href="#nutrients"><Sparkles size={19} /><span>Нутриенты</span></a>
        <a href="#quality"><Database size={19} /><span>Качество</span></a>
      </nav>
      <div className="sidebar-footer"><ShieldCheck size={17} /><span>Локально<br />без сети</span></div>
    </aside>

    <main id="main-content">
      <header className="page-header">
        <div>
          <div className="header-kicker"><span className="live-dot" /> личная аналитика</div>
          <h1>Картина здоровья,<br /><em>без ложной точности</em></h1>
          <p>Питание, восстановление и нагрузка в одном приватном снимке.</p>
        </div>
        <div className="snapshot-card">
          <span>Данные по</span>
          <strong>{snapshot.meta.latestSourceDate ? fullDate(snapshot.meta.latestSourceDate) : "—"}</strong>
          <small>собрано {new Intl.DateTimeFormat("ru-RU", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }).format(new Date(snapshot.meta.generatedAt))} · расчёт {snapshot.meta.calculationVersion}</small>
        </div>
      </header>

      <div className="control-bar" aria-label="Фильтры периода">
        <div className="period-tabs" role="group" aria-label="Период">
          {PERIODS.map((item) => <button key={item.key} className={period === item.key ? "active" : ""} aria-pressed={period === item.key} onClick={() => setPeriod(item.key)}>{item.label}</button>)}
        </div>
        <label className="switch"><input type="checkbox" checked={completeOnly} onChange={(event) => setCompleteOnly(event.target.checked)} /><span aria-hidden="true" /><b>Только завершённые</b></label>
        <div className="period-meta"><CalendarDays size={16} /> {window.completeDays} завершённых из {window.dates.length} дней</div>
      </div>

      <section id="overview" className="overview-section">
        <SectionHeading
          eyebrow="Обзор периода"
          title="Главное — на одном экране"
          description={fullEnough ? "Данных достаточно для осторожного описания повторяющихся паттернов." : `Пока доступно ${window.completeDays} завершённых дней: выводы считаются предварительными.`}
          aside={<StateLegend />}
        />
        <div className="kpi-grid">
          <KpiCard icon={<Gauge size={20} />} label="Энергия / день" value={<>{formatNumber(energy.value)} <small>ккал</small></>} detail={energy.completeness === "known_minimum" ? "известный минимум" : "центральная оценка"} meta={`${energy.n.included}/${energy.n.total} календарных дней`} />
          <KpiCard icon={<Utensils size={20} />} label="Средние Б / Ж / У" value={<><span>{formatNumber(protein.value)}</span><i>/</i><span>{formatNumber(fat.value)}</span><i>/</i><span>{formatNumber(carbs.value)}</span></>} detail="граммов в день" meta={`${protein.n.included}/${protein.n.total} дней · ${provenanceLabel(protein.provenance)}`} tone="blue" />
          <KpiCard icon={<MoonStar size={20} />} label="Сон" value={<>{sleep.value === null ? "—" : formatNumber(sleep.value / 60, 1)} <small>ч</small></>} detail="средняя длительность" meta={`${sleep.n.included}/${sleep.n.total} ночей`} tone="violet" />
          <KpiCard icon={<Dumbbell size={20} />} label="Нагрузка" value={<>{workouts.length} <small>сессий</small></>} detail={`${formatNumber(workoutMinutes)} мин · ${formatNumber(workoutDistance, 1)} км`} meta={`на ${window.dates.length} календарных дней`} tone="amber" />
          <KpiCard icon={<Sparkles size={20} />} label="Оценка дня" value={<>{formatNumber(rating.value, 1)} <small>/ 5</small></>} detail="оценка пользователя" meta={`${rating.n.included}/${rating.n.total} дней`} tone="violet" />
          <KpiCard icon={<ShieldCheck size={20} />} label="Покрытие профилями" value={<>{formatNumber(snapshot.quality.profileCoverage.mass?.percent, 0)}<small>% массы</small></>} detail={`${snapshot.quality.counts.linkedComponents}/${snapshot.quality.counts.components} компонентов`} meta="нутриенты — известный минимум" />
        </div>
      </section>

      <div className="dashboard-grid">
        <section id="timeline" className="panel span-12 timeline-panel">
          <SectionHeading eyebrow="Общая динамика" title="Графики в прежнем виде" description="Показатели снова разделены на четыре простых графика. Нажмите на столбец или точку для деталей; разрыв означает отсутствие данных." aside={<span className="interaction-hint"><Scale size={16} /> единая календарная ось</span>} />
          <div className="legacy-chart-grid">
            <article className="legacy-chart-card"><h3>Калории</h3><Chart option={calorieOption} className="chart chart-legacy" onDateSelect={setSelectedDate} /></article>
            <article className="legacy-chart-card sleep"><h3>Сон</h3><Chart option={sleepOption} className="chart chart-legacy" onDateSelect={setSelectedDate} /></article>
            <article className="legacy-chart-card"><h3>Тренировки</h3><Chart option={activityOption} className="chart chart-legacy" onDateSelect={setSelectedDate} /></article>
            <article className="legacy-chart-card"><h3>Оценка дня</h3><Chart option={ratingOption} className="chart chart-legacy" onDateSelect={setSelectedDate} /></article>
          </div>
          <ChartSummaryTable days={chartDays} openDay={setSelectedDate} />
        </section>

        <NutritionPanel days={visibleChartDays} />

        <section className="panel span-5 recovery-panel">
          <SectionHeading eyebrow="Восстановление" title="Сон и нагрузка" description="Совместное наблюдение — не причинный вывод." />
          <div className="recovery-hero"><MoonStar size={24} /><div><strong>{sleep.value === null ? "—" : `${formatNumber(sleep.value / 60, 1)} ч`}</strong><span>средний сон · {sleep.n.included}/{sleep.n.total}</span></div></div>
          <div className="recovery-list">
            <div><span>Тренировочных сессий</span><strong>{workouts.length}</strong></div>
            <div><span>Суммарная длительность</span><strong>{formatNumber(workoutMinutes)} мин</strong></div>
            <div><span>Дистанция с данными</span><strong>{formatNumber(workoutDistance, 1)} км</strong></div>
            <div><span>С RPE</span><strong>{workouts.filter((item) => item.rpe !== null).length}/{workouts.length}</strong></div>
            <div><span>Со средним пульсом</span><strong>{workouts.filter((item) => item.averageHeartRate !== null).length}/{workouts.length}</strong></div>
          </div>
          <div className="data-caveat"><Info size={16} /><span>Нет тренировки в журнале ≠ подтверждённый день отдыха.</span></div>
        </section>

        <NutrientPanel dates={window.dates} allowedDates={includedDateSet} />
        <QualityPanel />

        <section className="panel span-12 daily-table-panel">
          <SectionHeading eyebrow="Календарь" title="Дни и полнота записи" description="Отсутствующие даты остаются в знаменателе и никогда не отображаются как нулевые." />
          <div className="table-scroll"><table className="daily-table">
            <caption>Сводка по датам выбранного периода</caption>
            <thead><tr><th scope="col">Дата</th><th scope="col">Статус</th><th scope="col">Энергия</th><th scope="col">Сон</th><th scope="col">Нагрузка</th><th scope="col">Оценка</th><th scope="col">Полнота</th><th scope="col"><span className="sr-only">Детали</span></th></tr></thead>
            <tbody>{[...chartDays].reverse().map((day) => <tr key={day.date}>
              <th scope="row">{fullDate(day.date)}</th>
              <td><span className={`status-pill ${day.status}`}>{statusLabel(day.status)}</span></td>
              <td>{metricValue(day.energy)} {day.energy.value !== null ? "ккал" : ""}</td>
              <td>{day.sleepMinutes.value === null ? "—" : `${formatNumber(day.sleepMinutes.value / 60, 1)} ч`}</td>
              <td>{day.workoutMinutes.value === null ? "—" : `${formatNumber(day.workoutMinutes.value)} мин`}</td>
              <td>{metricValue(day.rating, 1)}</td>
              <td><div className="mini-progress"><span style={{ width: `${day.completeness.overallPercent ?? 0}%` }} /><b>{day.completeness.overallPercent === null ? "—" : `${day.completeness.overallPercent}%`}</b></div></td>
              <td><button className="table-action" onClick={() => setSelectedDate(day.date)} aria-label={`Открыть детали ${fullDate(day.date)}`}><ChevronRight size={18} /></button></td>
            </tr>)}</tbody>
          </table></div>
        </section>
      </div>

      <footer className="page-footer"><span><ShieldCheck size={16} /> Приватный статический снимок · без CDN, API и телеметрии</span><span>Контракт {snapshot.meta.contractVersion} · источник {snapshot.meta.sourceHash.slice(0, 8)}</span></footer>
    </main>

    <nav className="mobile-nav" aria-label="Мобильная навигация">
      <a href="#overview"><LayoutDashboard size={20} /><span>Обзор</span></a>
      <a href="#timeline"><Activity size={20} /><span>Динамика</span></a>
      <a href="#nutrients"><Sparkles size={20} /><span>Нутриенты</span></a>
      <a href="#quality"><Database size={20} /><span>Данные</span></a>
    </nav>
    <DayDrawer date={selectedDate} onOpenChange={(open) => { if (!open) setSelectedDate(null); }} />
  </div>;
}
