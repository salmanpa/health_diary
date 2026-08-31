import { describe, expect, it } from "vitest";
import { energyProfile, macroProfile, mealMacroHighlight, sleepSummary, trainingSummary } from "./dashboardModel";
import { snapshot } from "./snapshot";

describe("dashboard presentation model", () => {
  const completeDays = snapshot.days.filter((day) => day.status === "complete");

  it("classifies energy only as a relative period signal", () => {
    const result = energyProfile(completeDays);
    expect(result.n).toBe(23);
    expect(result.average).toBeCloseTo(2003.7, 1);
    expect(result.lowBoundary).toBeCloseTo((result.average as number) * 0.85, 5);
    expect(result.highBoundary).toBeCloseTo((result.average as number) * 1.15, 5);
    expect(result.bands.get("2026-08-11")).toBe("below");
    expect(result.bands.get("2026-08-27")).toBe("above");
  });

  it("does not classify a short period", () => {
    const result = energyProfile(completeDays.slice(0, 6));
    expect(result.bands.size).toBe(6);
    expect([...result.bands.values()].every((value) => value === "unclassified")).toBe(true);
  });

  it("calculates macro shares using 4/9/4 and marks only reproducible stable days", () => {
    const result = macroProfile(completeDays);
    expect(result.days).toHaveLength(22);
    expect((result.shares?.protein ?? 0) + (result.shares?.fat ?? 0) + (result.shares?.carbs ?? 0)).toBeCloseTo(100, 8);
    expect(result.stableDates.size).toBeGreaterThan(0);
    expect(result.stableDates.size).toBeLessThanOrEqual(result.days.length);
  });

  it("reports median, spread and sleep denominator", () => {
    const result = sleepSummary(completeDays);
    expect(result.n).toBe(23);
    expect(result.medianMinutes).toBe(420);
    expect(result.minimumMinutes).toBe(300);
    expect(result.maximumMinutes).toBe(720);
  });

  it("normalizes training frequency to observed calendar days and preserves coverage", () => {
    const result = trainingSummary(snapshot.workouts, snapshot.days.length);
    expect(result.sessions).toBe(14);
    expect(result.minutes).toBeCloseTo(608.7, 1);
    expect(result.distanceKm).toBeCloseTo(43.87, 2);
    expect(result.rpeN).toBe(0);
    expect(result.heartRateN).toBe(1);
  });

  it("highlights protein and fat from their shares of macro energy", () => {
    const chicken = snapshot.meals.find((meal) => meal.title === "Куриная грудка на пару");
    const coleslaw = snapshot.meals.find((meal) => meal.title === "Салат коул-слоу");
    expect(chicken).toBeDefined();
    expect(coleslaw).toBeDefined();
    expect(mealMacroHighlight(chicken as NonNullable<typeof chicken>)).toMatchObject({ highProtein: true, highFat: false });
    expect(mealMacroHighlight(coleslaw as NonNullable<typeof coleslaw>)).toMatchObject({ highProtein: false, highFat: true });
  });
});
