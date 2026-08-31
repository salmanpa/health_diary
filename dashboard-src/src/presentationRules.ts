/**
 * Presentation-only relative signals. They compare the selected period with
 * itself and are not calorie or macro targets.
 */
export const PRESENTATION_RULES = {
  version: "relative-signals-1.1",
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
  mealHighlights: {
    proteinToOtherMacroRatioExclusive: 1,
    fatMinimumGramsExclusive: 30,
    fatToProteinRatioExclusive: 1.5,
  },
} as const;
