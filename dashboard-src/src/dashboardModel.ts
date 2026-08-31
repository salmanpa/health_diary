import { PRESENTATION_RULES } from "./presentationRules";
import type { DiaryDay, WorkoutEvent } from "./types";

export type EnergyBand = "below" | "typical" | "above" | "unclassified";

function mean(values: number[]): number | null {
  return values.length ? values.reduce((sum, value) => sum + value, 0) / values.length : null;
}

function median(values: number[]): number | null {
  if (!values.length) return null;
  const ordered = [...values].sort((left, right) => left - right);
  const middle = Math.floor(ordered.length / 2);
  return ordered.length % 2 ? ordered[middle] : (ordered[middle - 1] + ordered[middle]) / 2;
}

function standardDeviation(values: number[]): number | null {
  const average = mean(values);
  if (average === null || values.length < 2) return null;
  return Math.sqrt(values.reduce((sum, value) => sum + (value - average) ** 2, 0) / values.length);
}

export interface EnergyProfile {
  average: number | null;
  lowBoundary: number | null;
  highBoundary: number | null;
  n: number;
  bands: Map<string, EnergyBand>;
  counts: Record<EnergyBand, number>;
}

export function energyProfile(days: DiaryDay[]): EnergyProfile {
  const observed = days.filter((day) => day.status === "complete" && day.energy.value !== null);
  const average = mean(observed.map((day) => day.energy.value as number));
  const canClassify = observed.length >= PRESENTATION_RULES.energy.minimumDays && average !== null;
  const delta = canClassify ? average * PRESENTATION_RULES.energy.relativeBandPercent / 100 : null;
  const lowBoundary = delta === null || average === null ? null : average - delta;
  const highBoundary = delta === null || average === null ? null : average + delta;
  const bands = new Map<string, EnergyBand>();
  const counts: Record<EnergyBand, number> = { below: 0, typical: 0, above: 0, unclassified: 0 };
  for (const day of days) {
    let band: EnergyBand = "unclassified";
    if (canClassify && day.status === "complete" && day.energy.value !== null) {
      band = day.energy.value < (lowBoundary as number)
        ? "below"
        : day.energy.value > (highBoundary as number)
          ? "above"
          : "typical";
    }
    bands.set(day.date, band);
    counts[band] += 1;
  }
  return { average, lowBoundary, highBoundary, n: observed.length, bands, counts };
}

export interface MacroDay {
  date: string;
  proteinKcal: number;
  fatKcal: number;
  carbsKcal: number;
  totalKcal: number;
  proteinShare: number;
  fatShare: number;
  carbsShare: number;
  energyDiscrepancyPercent: number | null;
}

export interface MacroProfile {
  days: MacroDay[];
  totals: { proteinKcal: number; fatKcal: number; carbsKcal: number; totalKcal: number };
  shares: { protein: number; fat: number; carbs: number } | null;
  medianShares: { protein: number; fat: number; carbs: number } | null;
  stableDates: Set<string>;
}

export function macroProfile(days: DiaryDay[]): MacroProfile {
  const macroDays = days.flatMap((day): MacroDay[] => {
    if (
      day.status !== "complete"
      || day.protein.value === null
      || day.fat.value === null
      || day.carbs.value === null
      || day.protein.completeness !== "complete"
      || day.fat.completeness !== "complete"
      || day.carbs.completeness !== "complete"
    ) return [];
    const proteinKcal = day.protein.value * 4;
    const fatKcal = day.fat.value * 9;
    const carbsKcal = day.carbs.value * 4;
    const totalKcal = proteinKcal + fatKcal + carbsKcal;
    if (totalKcal <= 0) return [];
    const energyDiscrepancyPercent = day.energy.value && day.energy.value > 0
      ? Math.abs(totalKcal - day.energy.value) / day.energy.value * 100
      : null;
    return [{
      date: day.date, proteinKcal, fatKcal, carbsKcal, totalKcal,
      proteinShare: proteinKcal / totalKcal * 100,
      fatShare: fatKcal / totalKcal * 100,
      carbsShare: carbsKcal / totalKcal * 100,
      energyDiscrepancyPercent,
    }];
  });
  const totals = macroDays.reduce((sum, day) => ({
    proteinKcal: sum.proteinKcal + day.proteinKcal,
    fatKcal: sum.fatKcal + day.fatKcal,
    carbsKcal: sum.carbsKcal + day.carbsKcal,
    totalKcal: sum.totalKcal + day.totalKcal,
  }), { proteinKcal: 0, fatKcal: 0, carbsKcal: 0, totalKcal: 0 });
  const shares = totals.totalKcal > 0 ? {
    protein: totals.proteinKcal / totals.totalKcal * 100,
    fat: totals.fatKcal / totals.totalKcal * 100,
    carbs: totals.carbsKcal / totals.totalKcal * 100,
  } : null;
  const medianShares = macroDays.length ? {
    protein: median(macroDays.map((day) => day.proteinShare)) as number,
    fat: median(macroDays.map((day) => day.fatShare)) as number,
    carbs: median(macroDays.map((day) => day.carbsShare)) as number,
  } : null;
  const stableDates = new Set<string>();
  if (macroDays.length >= PRESENTATION_RULES.macros.minimumDays && medianShares) {
    for (const day of macroDays) {
      const stableShares = Math.abs(day.proteinShare - medianShares.protein) <= PRESENTATION_RULES.macros.shareTolerancePercentagePoints
        && Math.abs(day.fatShare - medianShares.fat) <= PRESENTATION_RULES.macros.shareTolerancePercentagePoints
        && Math.abs(day.carbsShare - medianShares.carbs) <= PRESENTATION_RULES.macros.shareTolerancePercentagePoints;
      const reconciled = day.energyDiscrepancyPercent !== null
        && day.energyDiscrepancyPercent <= PRESENTATION_RULES.macros.maximumEnergyReconciliationPercent;
      if (stableShares && reconciled) stableDates.add(day.date);
    }
  }
  return { days: macroDays, totals, shares, medianShares, stableDates };
}

export interface SleepSummary {
  averageMinutes: number | null;
  medianMinutes: number | null;
  standardDeviationMinutes: number | null;
  minimumMinutes: number | null;
  maximumMinutes: number | null;
  consistentNights: number;
  n: number;
}

export function sleepSummary(days: DiaryDay[]): SleepSummary {
  const values = days.flatMap((day) => day.sleepMinutes.value === null ? [] : [day.sleepMinutes.value]);
  const middle = median(values);
  return {
    averageMinutes: mean(values),
    medianMinutes: middle,
    standardDeviationMinutes: standardDeviation(values),
    minimumMinutes: values.length ? Math.min(...values) : null,
    maximumMinutes: values.length ? Math.max(...values) : null,
    consistentNights: middle === null ? 0 : values.filter((value) => Math.abs(value - middle) <= PRESENTATION_RULES.sleep.consistencyWindowMinutes).length,
    n: values.length,
  };
}

export interface TrainingSummary {
  sessions: number;
  activeDays: number;
  minutes: number;
  distanceKm: number;
  sessionsPerObservedWeek: number | null;
  averageSessionMinutes: number | null;
  runningPaceSecondsPerKm: number | null;
  runningPaceN: number;
  rpeN: number;
  heartRateN: number;
}

export function trainingSummary(workouts: WorkoutEvent[], observedCalendarDays: number): TrainingSummary {
  const durations = workouts.flatMap((item) => item.durationMinutes === null ? [] : [item.durationMinutes]);
  const paceRuns = workouts.filter((item) => item.paceSecondsPerKm !== null && item.distanceKm !== null && item.distanceKm > 0);
  const paceDistance = paceRuns.reduce((sum, item) => sum + (item.distanceKm as number), 0);
  const weightedPace = paceDistance > 0
    ? paceRuns.reduce((sum, item) => sum + (item.paceSecondsPerKm as number) * (item.distanceKm as number), 0) / paceDistance
    : null;
  return {
    sessions: workouts.length,
    activeDays: new Set(workouts.map((item) => item.date)).size,
    minutes: durations.reduce((sum, value) => sum + value, 0),
    distanceKm: workouts.reduce((sum, item) => sum + (item.distanceKm ?? 0), 0),
    sessionsPerObservedWeek: observedCalendarDays > 0 ? workouts.length / observedCalendarDays * 7 : null,
    averageSessionMinutes: mean(durations),
    runningPaceSecondsPerKm: weightedPace,
    runningPaceN: paceRuns.length,
    rpeN: workouts.filter((item) => item.rpe !== null).length,
    heartRateN: workouts.filter((item) => item.averageHeartRate !== null).length,
  };
}
