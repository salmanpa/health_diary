import type {
  Completeness,
  Confidence,
  DiaryDay,
  Metric,
  MetricAggregate,
  NutrientObservation,
  PeriodKey,
  PeriodWindow,
  Provenance,
} from "./types";

const DAY_MS = 86_400_000;

function parseIsoDate(value: string): Date | null {
  const parsed = new Date(`${value}T12:00:00Z`);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export function addDays(value: string, amount: number): string | null {
  const parsed = parseIsoDate(value);
  if (!parsed) return null;
  parsed.setUTCDate(parsed.getUTCDate() + amount);
  return parsed.toISOString().slice(0, 10);
}

export function enumerateDates(from: string, to: string): string[] {
  const start = parseIsoDate(from);
  const end = parseIsoDate(to);
  if (!start || !end || start > end) return [];
  const count = Math.floor((end.getTime() - start.getTime()) / DAY_MS) + 1;
  return Array.from({ length: count }, (_, index) =>
    new Date(start.getTime() + index * DAY_MS).toISOString().slice(0, 10),
  );
}

export function getPeriodWindow(
  days: DiaryDay[],
  period: PeriodKey,
  snapshotPeriod: { from: string | null; to: string | null },
): PeriodWindow {
  const observed = days.map((day) => day.date).sort();
  const to = snapshotPeriod.to ?? observed.at(-1) ?? null;
  if (!to) return { from: null, to: null, dates: [], days: [], observedDays: 0, completeDays: 0 };
  const from =
    period === "all"
      ? snapshotPeriod.from ?? observed[0] ?? to
      : addDays(to, -(Number(period) - 1)) ?? to;
  const dates = enumerateDates(from, to);
  const allowed = new Set(dates);
  const selected = days
    .filter((day) => allowed.has(day.date))
    .sort((left, right) => left.date.localeCompare(right.date));
  return {
    from,
    to,
    dates,
    days: selected,
    observedDays: selected.filter((day) => day.status !== "missing_date").length,
    completeDays: selected.filter((day) => day.status === "complete").length,
  };
}

export function eligibleDays(days: DiaryDay[], completeOnly: boolean): DiaryDay[] {
  return days.filter(
    (day) => day.status !== "missing_date" && (!completeOnly || day.status === "complete"),
  );
}

const confidenceRank: Record<Confidence, number> = { unknown: 0, low: 1, medium: 2, high: 3 };

function weakestConfidence(values: Confidence[]): Confidence {
  return values.length
    ? values.reduce((left, right) =>
        confidenceRank[left] <= confidenceRank[right] ? left : right,
      )
    : "unknown";
}

function weakestCompleteness(values: Completeness[]): Completeness {
  return values.includes("known_minimum") ? "known_minimum" : "complete";
}

function weakestProvenance(values: Provenance[]): Provenance {
  const rank: Record<Provenance, number> = {
    unknown: 0,
    estimated: 1,
    calculated: 2,
    labelled: 3,
    measured: 4,
  };
  return values.length
    ? values.reduce((left, right) => (rank[left] <= rank[right] ? left : right))
    : "unknown";
}

function mean(values: number[]): number | null {
  return values.length ? values.reduce((sum, value) => sum + value, 0) / values.length : null;
}

export function metricCoveragePercent(metric: Metric): number | null {
  return metric.coverage?.energy?.percent ?? metric.coverage?.mass?.percent ?? metric.coverage?.count?.percent ?? null;
}

export function aggregateMetric(
  days: DiaryDay[],
  selector: (day: DiaryDay) => Metric,
  denominator: number,
): MetricAggregate {
  const metrics = days.map(selector);
  const included = metrics.filter(
    (item) => item.valueStatus !== "missing" && item.value !== null,
  );
  const values = included.map((item) => item.value as number);
  const lows = included.map((item) => item.low ?? (item.value as number));
  const highs = included.map((item) => item.high ?? (item.value as number));
  const first = included[0] ?? metrics[0];
  return {
    value: mean(values),
    low: mean(lows),
    high: mean(highs),
    rangeMin: lows.length ? Math.min(...lows) : null,
    rangeMax: highs.length ? Math.max(...highs) : null,
    unit: first?.unit ?? "",
    valueStatus: included.length ? (values.every((value) => value === 0) ? "explicit_zero" : "present") : "missing",
    provenance: weakestProvenance(included.map((item) => item.provenance)),
    completeness: weakestCompleteness(included.map((item) => item.completeness)),
    confidence: weakestConfidence(included.map((item) => item.confidence)),
    source: null,
    coverage: null,
    n: { included: included.length, total: denominator },
  };
}

export interface RollingPoint {
  date: string;
  value: number | null;
  n: number;
  total: number;
  completeness: Completeness;
  coverage: number | null;
}

export function rollingNutrientAverage(
  dates: string[],
  observations: NutrientObservation[],
  nutrientId: string,
  windowSize: number,
): RollingPoint[] {
  const byDate = new Map(
    observations
      .filter((entry) => entry.nutrientId === nutrientId)
      .map((entry) => [entry.date, entry.metric] as const),
  );
  return dates.map((date, index) => {
    const windowDates = dates.slice(Math.max(0, index - windowSize + 1), index + 1);
    const metrics = windowDates
      .map((windowDate) => byDate.get(windowDate))
      .filter(
        (item): item is Metric => Boolean(item && item.valueStatus !== "missing" && item.value !== null),
      );
    const coverages = metrics
      .map(metricCoveragePercent)
      .filter((value): value is number => value !== null);
    return {
      date,
      value: mean(metrics.map((item) => item.value as number)),
      n: metrics.length,
      total: windowDates.length,
      completeness: weakestCompleteness(metrics.map((item) => item.completeness)),
      coverage: mean(coverages),
    };
  });
}

export function formatNumber(value: number | null | undefined, digits = 0): string {
  if (value == null || !Number.isFinite(value)) return "—";
  return new Intl.NumberFormat("ru-RU", {
    maximumFractionDigits: digits,
    minimumFractionDigits: digits,
  }).format(value);
}

export function shortDate(value: string): string {
  return new Intl.DateTimeFormat("ru-RU", { day: "2-digit", month: "short" }).format(
    new Date(`${value}T12:00:00Z`),
  );
}

export function fullDate(value: string): string {
  return new Intl.DateTimeFormat("ru-RU", {
    weekday: "long",
    day: "numeric",
    month: "long",
  }).format(new Date(`${value}T12:00:00Z`));
}
