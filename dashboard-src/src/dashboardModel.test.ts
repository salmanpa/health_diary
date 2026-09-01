import { describe, expect, it } from "vitest";
import { energyProfile, groupMealsByType, macroProfile, mealMacroHighlight, sleepSummary, trainingSummary } from "./dashboardModel";
import { snapshot } from "./snapshot";

describe("dashboard presentation model", () => {
  const completeDays = snapshot.days.filter((day) => day.status === "complete");

  it("classifies energy only as a relative period signal", () => {
    const result = energyProfile(completeDays);
    expect(result.n).toBe(24);
    expect(result.average).toBeCloseTo(1991.1, 1);
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
    expect(result.days).toHaveLength(23);
    expect((result.shares?.protein ?? 0) + (result.shares?.fat ?? 0) + (result.shares?.carbs ?? 0)).toBeCloseTo(100, 8);
    expect(result.stableDates.size).toBeGreaterThan(0);
    expect(result.stableDates.size).toBeLessThanOrEqual(result.days.length);
  });

  it("reports median, spread and sleep denominator", () => {
    const result = sleepSummary(completeDays);
    expect(result.n).toBe(24);
    expect(result.medianMinutes).toBe(420);
    expect(result.minimumMinutes).toBe(90);
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

  it("highlights protein when it exceeds both fat and carbohydrates", () => {
    const chicken = snapshot.meals.find((meal) => meal.title === "Куриная грудка на пару");
    expect(chicken).toBeDefined();
    expect(mealMacroHighlight(chicken as NonNullable<typeof chicken>)).toMatchObject({ highProtein: true, highFat: false, highCarbs: false });

    const equalProteinAndFat = {
      protein: { value: 20 }, fat: { value: 20 }, carbs: { value: 5 },
    } as Parameters<typeof mealMacroHighlight>[0];
    expect(mealMacroHighlight(equalProteinAndFat).highProtein).toBe(false);
  });

  it("highlights leading fat and strongly leading carbs", () => {
    const meal = (protein: number, fat: number, carbs: number) => ({
      protein: { value: protein }, fat: { value: fat }, carbs: { value: carbs },
    }) as Parameters<typeof mealMacroHighlight>[0];

    expect(mealMacroHighlight(meal(20, 21, 5))).toMatchObject({ highFat: true, highCarbs: false });
    expect(mealMacroHighlight(meal(20, 10, 30))).toMatchObject({ highCarbs: false });
    expect(mealMacroHighlight(meal(20, 10, 31))).toMatchObject({ highCarbs: true });
  });

  it("groups meals by category and highlights the aggregated energy above 800 kcal", () => {
    const meals = snapshot.meals.filter((meal) => meal.date === "2026-08-26");
    const groups = groupMealsByType(meals);
    expect(groups.map((group) => group.mealType)).toEqual(["breakfast", "lunch", "dinner", "snack"]);
    const breakfast = groups.find((group) => group.mealType === "breakfast");
    expect(breakfast).toMatchObject({ energyValue: 829.4, energyStatus: "complete", highEnergy: true });
    expect(breakfast?.meals).toHaveLength(7);

    const missingEnergyMeal = {
      ...breakfast!.meals[1],
      energy: { ...breakfast!.meals[1].energy, value: null, valueStatus: "missing" as const },
    };
    const incompleteGroup = groupMealsByType([breakfast!.meals[0], missingEnergyMeal])[0];
    expect(incompleteGroup.energyStatus).toBe("known_minimum");
    expect(incompleteGroup.energyValue).toBe(breakfast!.meals[0].energy.value);
  });
});
