export type DayStatus = "complete" | "in_progress" | "missing_date";
export type ValueStatus = "present" | "explicit_zero" | "missing";
export type Provenance = "measured" | "labelled" | "calculated" | "estimated" | "unknown";
export type Completeness = "complete" | "known_minimum";
export type Confidence = "high" | "medium" | "low" | "unknown";
export type PeriodKey = "7" | "14" | "30" | "all";

export interface RatioCoverage {
  covered: number;
  total: number;
  percent: number | null;
}

export interface Coverage {
  count: RatioCoverage | null;
  mass: RatioCoverage | null;
  energy: RatioCoverage | null;
}

export interface Metric {
  value: number | null;
  low: number | null;
  high: number | null;
  unit: string;
  valueStatus: ValueStatus;
  provenance: Provenance;
  completeness: Completeness;
  confidence: Confidence;
  source: string | null;
  coverage: Coverage | null;
  n: { included: number; total: number };
}

export type DomainState = "present" | "missing" | "known_minimum";

export interface DiaryDay {
  date: string;
  status: DayStatus;
  energy: Metric;
  protein: Metric;
  fat: Metric;
  carbs: Metric;
  sleepMinutes: Metric;
  workoutCount: Metric;
  workoutMinutes: Metric;
  workoutDistance: Metric;
  rating: Metric;
  foodBases: Array<"meat" | "chicken" | "fish">;
  completeness: {
    nutrition: DomainState;
    components: DomainState;
    sleep: DomainState;
    workout: DomainState;
    rating: DomainState;
    overallPercent: number | null;
    reasons: string[];
  };
}

export interface MealComponent {
  id: string;
  name: string;
  weightG: number | null;
  confidence: Confidence;
  profileName: string | null;
  referenceId: number | null;
  linked: boolean;
}

export interface MealEvent {
  id: string;
  date: string;
  eatenAt: string | null;
  mealType: string;
  title: string;
  weightG: number | null;
  provenance: Provenance;
  confidence: Confidence;
  energy: Metric;
  protein: Metric;
  fat: Metric;
  carbs: Metric;
  components: MealComponent[];
}

export interface WorkoutEvent {
  id: string;
  date: string;
  type: string;
  timeOfDay: string | null;
  startedAt: string | null;
  durationMinutes: number | null;
  distanceKm: number | null;
  paceSecondsPerKm: number | null;
  rpe: number | null;
  averageHeartRate: number | null;
  maximumHeartRate: number | null;
  energy: Metric;
  energyMethod: string | null;
}

export interface SleepEvent {
  id: string;
  date: string;
  startedAt: string | null;
  endedAt: string | null;
  durationMinutes: number | null;
  quality: number | null;
  provenance: Provenance;
}

export type NutrientMode = "minimum" | "upper" | "informational";

export interface NutrientDefinition {
  id: string;
  label: string;
  shortLabel: string;
  unit: string;
  mode: NutrientMode;
  referenceValue: number | null;
  referenceLabel: string | null;
  sourceUrl: string;
  sortOrder: number;
}

export interface NutrientObservation {
  date: string;
  nutrientId: string;
  metric: Metric;
  contributors: Array<{ name: string; value: number; unit: string }>;
  unknownContributors: Array<{ name: string; weightG: number | null; confidence: Confidence }>;
  confidenceDistribution: Record<"high" | "medium" | "low", number>;
}

export interface QualityIssue {
  id: string;
  label: string;
  count: number;
  severity: "info" | "review";
  dates: string[];
}

export interface DashboardSnapshot {
  meta: {
    contractVersion: string;
    schemaVersion: string;
    calculationVersion: string;
    generatedAt: string;
    timezone: string;
    latestSourceDate: string | null;
    sourceCommit: string | null;
    sourceHash: string;
    period: { from: string | null; to: string | null };
    baselineWeightKg: number;
    baselineWeightEffectiveDate: string | null;
  };
  contract: {
    dayStatus: DayStatus[];
    valueStatus: ValueStatus[];
    provenance: Provenance[];
    completeness: Completeness[];
    confidence: Confidence[];
    nutrientCoverageGates: {
      insufficientBelowPercent: number;
      comparisonAtOrAbovePercent: number;
      requiresEnergyCoverage: boolean;
    };
    trendGates: { descriptiveBelowDays: number; provisionalBelowDays: number };
  };
  days: DiaryDay[];
  meals: MealEvent[];
  workouts: WorkoutEvent[];
  sleep: SleepEvent[];
  nutrientDefinitions: NutrientDefinition[];
  nutrients: NutrientObservation[];
  quality: {
    counts: {
      calendarRows: number;
      calendarDates: number;
      nutritionEntries: number;
      components: number;
      linkedComponents: number;
      unlinkedComponents: number;
      workouts: number;
      sleepEntries: number;
      ratings: number;
    };
    confidence: Record<Confidence, number>;
    provenance: Record<string, number>;
    profileCoverage: Coverage;
    issues: QualityIssue[];
    massBalance: Array<{
      entryId: string;
      date: string;
      title: string;
      entryWeightG: number;
      componentWeightG: number;
      differenceG: number;
    }>;
    unlinkedComponents: Array<{
      name: string;
      weightG: number;
      occurrences: number;
      dates: string[];
    }>;
  };
}

export interface PeriodWindow {
  from: string | null;
  to: string | null;
  dates: string[];
  days: DiaryDay[];
  observedDays: number;
  completeDays: number;
}

export interface MetricAggregate extends Metric {
  rangeMin: number | null;
  rangeMax: number | null;
}
