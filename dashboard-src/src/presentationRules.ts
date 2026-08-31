/**
 * Presentation-only relative signals. They compare the selected period with
 * itself and are not calorie or macro targets.
 */
export const PRESENTATION_RULES = {
  version: "relative-signals-1.0",
  energy: {
    minimumDays: 7,
    relativeBandPercent: 15,
  },
  macros: {
    minimumDays: 7,
    shareTolerancePercentagePoints: 8,
    maximumEnergyReconciliationPercent: 10,
  },
  sleep: {
    consistencyWindowMinutes: 30,
  },
} as const;
