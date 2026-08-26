import { describe, expect, it } from "vitest";
import { aggregateMetric, eligibleDays, enumerateDates, getPeriodWindow, rollingNutrientAverage } from "./analytics";
import type { DiaryDay, Metric, NutrientObservation } from "./types";

const metric = (value: number | null, completeness: Metric["completeness"] = "complete"): Metric => ({
  value,
  low: value,
  high: value,
  unit: "kcal",
  valueStatus: value === null ? "missing" : value === 0 ? "explicit_zero" : "present",
  provenance: value === null ? "unknown" : "measured",
  completeness,
  source: null,
  confidence: value === null ? "unknown" : "high",
  coverage: null,
  n: { included: value === null ? 0 : 1, total: 1 },
});

const day = (date: string, status: DiaryDay["status"], value: number | null): DiaryDay => ({
  date,
  status,
  energy: metric(value),
  protein: metric(null), fat: metric(null), carbs: metric(null),
  sleepMinutes: metric(null), workoutCount: metric(null), workoutMinutes: metric(null),
  workoutDistance: metric(null), rating: metric(null), foodBases: [],
  completeness: {
    nutrition: "missing", components: "missing", sleep: "missing", workout: "missing",
    rating: "missing", overallPercent: null, reasons: [],
  },
});

describe("calendar period analytics", () => {
  it("enumerates gaps instead of dropping dates", () => {
    expect(enumerateDates("2026-08-01", "2026-08-04")).toEqual([
      "2026-08-01", "2026-08-02", "2026-08-03", "2026-08-04",
    ]);
  });

  it("keeps a seven-day denominator even with two observed days", () => {
    const window = getPeriodWindow(
      [day("2026-08-20", "complete", 1800), day("2026-08-25", "complete", 2000)],
      "7",
      { from: "2026-08-01", to: "2026-08-25" },
    );
    expect(window.dates).toHaveLength(7);
    expect(window.from).toBe("2026-08-19");
    expect(window.observedDays).toBe(2);
  });

  it("keeps an explicit zero and skips missing values", () => {
    const result = aggregateMetric(
      [day("2026-08-01", "complete", 0), day("2026-08-02", "complete", null)],
      (entry) => entry.energy,
      2,
    );
    expect(result.value).toBe(0);
    expect(result.n).toEqual({ included: 1, total: 2 });
  });

  it("keeps provenance and completeness as independent axes", () => {
    const estimatedMinimum = metric(20, "known_minimum");
    estimatedMinimum.provenance = "estimated";
    expect(estimatedMinimum).toMatchObject({ provenance: "estimated", completeness: "known_minimum" });
  });

  it("filters incomplete days only when requested", () => {
    const days = [day("2026-08-01", "complete", 1), day("2026-08-02", "in_progress", 2)];
    expect(eligibleDays(days, true)).toHaveLength(1);
    expect(eligibleDays(days, false)).toHaveLength(2);
  });
});

describe("rolling nutrients", () => {
  it("reports n/N without treating absent dates as zero", () => {
    const observations: NutrientObservation[] = ["2026-08-01", "2026-08-03"].map((date, index) => ({
      date,
      nutrientId: "fiber_g",
      metric: metric(index ? 30 : 20, "known_minimum"),
      contributors: [], unknownContributors: [],
      confidenceDistribution: { high: 0, medium: 0, low: 0 },
    }));
    const points = rollingNutrientAverage(
      ["2026-08-01", "2026-08-02", "2026-08-03"], observations, "fiber_g", 3,
    );
    expect(points.at(-1)).toMatchObject({ value: 25, n: 2, total: 3 });
  });
});
