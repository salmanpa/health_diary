import { z } from "zod";
import rawSnapshot from "../data/snapshot.json";
import type { DashboardSnapshot } from "./types";

const ratioSchema = z.object({
  covered: z.number(), total: z.number(), percent: z.number().nullable(),
}).strict();
const coverageSchema = z.object({
  count: ratioSchema.nullable(), mass: ratioSchema.nullable(), energy: ratioSchema.nullable(),
}).strict();
const metricSchema = z.object({
  value: z.number().nullable(), low: z.number().nullable(), high: z.number().nullable(),
  unit: z.string(),
  valueStatus: z.enum(["present", "explicit_zero", "missing"]),
  provenance: z.enum(["measured", "labelled", "calculated", "estimated", "unknown"]),
  completeness: z.enum(["complete", "known_minimum"]),
  confidence: z.enum(["high", "medium", "low", "unknown"]),
  source: z.string().nullable(), coverage: coverageSchema.nullable(),
  n: z.object({ included: z.number().int().nonnegative(), total: z.number().int().nonnegative() }).strict(),
}).strict();

const daySchema = z.object({
  date: z.iso.date(), status: z.enum(["complete", "in_progress", "missing_date"]),
  energy: metricSchema, protein: metricSchema, fat: metricSchema, carbs: metricSchema,
  sleepMinutes: metricSchema, workoutCount: metricSchema, workoutMinutes: metricSchema,
  workoutDistance: metricSchema, rating: metricSchema,
  foodBases: z.array(z.enum(["meat", "chicken", "fish"])),
  completeness: z.object({
    nutrition: z.enum(["present", "missing", "known_minimum"]),
    components: z.enum(["present", "missing", "known_minimum"]),
    sleep: z.enum(["present", "missing", "known_minimum"]),
    workout: z.enum(["present", "missing", "known_minimum"]),
    rating: z.enum(["present", "missing", "known_minimum"]),
    overallPercent: z.number().nullable(), reasons: z.array(z.string()),
  }).strict(),
}).strict();

const rootSchema = z.object({
  meta: z.object({
    contractVersion: z.literal("2.0"), schemaVersion: z.string(), calculationVersion: z.string(),
    generatedAt: z.iso.datetime({ offset: true }), timezone: z.string(),
    latestSourceDate: z.iso.date().nullable(), sourceCommit: z.string().nullable(), sourceHash: z.string(),
    period: z.object({ from: z.iso.date().nullable(), to: z.iso.date().nullable() }).strict(),
    baselineWeightKg: z.number(), baselineWeightEffectiveDate: z.iso.date().nullable(),
  }).strict(),
  contract: z.object({
    dayStatus: z.array(z.enum(["complete", "in_progress", "missing_date"])),
    valueStatus: z.array(z.enum(["present", "explicit_zero", "missing"])),
    provenance: z.array(z.enum(["measured", "labelled", "calculated", "estimated", "unknown"])),
    completeness: z.array(z.enum(["complete", "known_minimum"])),
    confidence: z.array(z.enum(["high", "medium", "low", "unknown"])),
    nutrientCoverageGates: z.object({
      insufficientBelowPercent: z.number(), comparisonAtOrAbovePercent: z.number(),
      requiresEnergyCoverage: z.boolean(),
    }).strict(),
    trendGates: z.object({ descriptiveBelowDays: z.number(), provisionalBelowDays: z.number() }).strict(),
  }).strict(),
  days: z.array(daySchema),
  meals: z.array(z.object({ id: z.string(), date: z.iso.date() }).passthrough()),
  workouts: z.array(z.object({ id: z.string(), date: z.iso.date() }).passthrough()),
  sleep: z.array(z.object({ id: z.string(), date: z.iso.date() }).passthrough()),
  nutrientDefinitions: z.array(z.object({ id: z.string(), unit: z.string(), mode: z.string() }).passthrough()),
  nutrients: z.array(z.object({ date: z.iso.date(), nutrientId: z.string(), metric: metricSchema }).passthrough()),
  quality: z.object({
    counts: z.object({
      calendarRows: z.number(), calendarDates: z.number(), nutritionEntries: z.number(),
      components: z.number(), linkedComponents: z.number(), unlinkedComponents: z.number(),
      workouts: z.number(), sleepEntries: z.number(), ratings: z.number(),
    }).strict(),
    confidence: z.record(z.string(), z.number()), provenance: z.record(z.string(), z.number()),
    profileCoverage: coverageSchema, issues: z.array(z.unknown()), massBalance: z.array(z.unknown()),
    unlinkedComponents: z.array(z.unknown()),
  }).strict(),
}).strict();

function assertPrivacyAllowlist(value: unknown, path = "snapshot"): void {
  const forbidden = new Set(["notes", "expenses", "amount_rub", "amountRub", "chess", "chessSessions"]);
  if (Array.isArray(value)) {
    value.forEach((item, index) => assertPrivacyAllowlist(item, `${path}[${index}]`));
    return;
  }
  if (value && typeof value === "object") {
    for (const [key, nested] of Object.entries(value)) {
      if (forbidden.has(key)) throw new Error(`Приватное поле ${path}.${key} не разрешено в health snapshot`);
      assertPrivacyAllowlist(nested, `${path}.${key}`);
    }
  }
}

assertPrivacyAllowlist(rawSnapshot);
const result = rootSchema.safeParse(rawSnapshot);
if (!result.success) {
  const details = z.prettifyError(result.error);
  throw new Error(`DashboardSnapshotV2 несовместим с интерфейсом:\n${details}`);
}

export const snapshot = result.data as unknown as DashboardSnapshot;
