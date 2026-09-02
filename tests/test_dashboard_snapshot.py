import importlib.util
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
GENERATOR_PATH = PROJECT_DIR / "scripts" / "generate_dashboard.py"
SPEC = importlib.util.spec_from_file_location("dashboard_generator", GENERATOR_PATH)
assert SPEC and SPEC.loader
generator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(generator)


def walk_keys(value):
    if isinstance(value, dict):
        for key, nested in value.items():
            yield key
            yield from walk_keys(nested)
    elif isinstance(value, list):
        for item in value:
            yield from walk_keys(item)


class DashboardSnapshotTest(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.database = Path(self.temporary_directory.name) / "health.sqlite3"
        connection = sqlite3.connect(self.database)
        connection.executescript((PROJECT_DIR / "db" / "schema.sql").read_text())
        for _ in range(2):
            connection.executescript((PROJECT_DIR / "db" / "seed.sql").read_text())
            connection.executescript((PROJECT_DIR / "db" / "nutrition_components.sql").read_text())
        self.assertEqual(connection.execute("PRAGMA integrity_check").fetchone()[0], "ok")
        connection.close()
        self.payload = generator.build_payload(
            self.database,
            generated_at="2026-08-26T12:00:00+03:00",
            commit="test-commit",
        )

    def tearDown(self):
        self.temporary_directory.cleanup()

    def test_idempotent_source_counts_and_calendar_gaps(self):
        counts = self.payload["quality"]["counts"]
        self.assertEqual(counts["calendarRows"], 26)
        self.assertEqual(counts["calendarDates"], 30)
        self.assertEqual(counts["nutritionEntries"], 214)
        self.assertEqual(counts["components"], 579)
        self.assertEqual(counts["linkedComponents"], 335)
        missing = [day["date"] for day in self.payload["days"] if day["status"] == "missing_date"]
        self.assertEqual(missing, ["2026-08-14", "2026-08-15", "2026-08-16", "2026-08-17"])

    def test_only_unconfirmed_august_12_mass_mismatch_remains(self):
        issues = self.payload["quality"]["massBalance"]
        self.assertEqual(len(issues), 1)
        self.assertEqual(issues[0]["date"], "2026-08-12")
        self.assertEqual(issues[0]["differenceG"], 90.0)

    def test_missing_is_not_zero_and_axes_are_independent(self):
        missing_day = next(day for day in self.payload["days"] if day["date"] == "2026-08-14")
        self.assertIsNone(missing_day["energy"]["value"])
        self.assertEqual(missing_day["energy"]["valueStatus"], "missing")
        day_without_workout = next(day for day in self.payload["days"] if day["date"] == "2026-08-10")
        self.assertIsNone(day_without_workout["workoutCount"]["value"])
        self.assertEqual(day_without_workout["workoutCount"]["valueStatus"], "missing")
        august_four = next(day for day in self.payload["days"] if day["date"] == "2026-08-04")
        self.assertEqual(august_four["protein"]["provenance"], "estimated")
        self.assertEqual(august_four["protein"]["completeness"], "known_minimum")

    def test_per_nutrient_coverage_and_conservative_gate(self):
        self.assertEqual(len(self.payload["nutrients"]), 30 * 11)
        covered = [item for item in self.payload["nutrients"] if item["metric"]["value"] is not None]
        self.assertTrue(covered)
        for item in covered:
            coverage = item["metric"]["coverage"]
            self.assertIsNotNone(coverage["count"])
            self.assertIsNotNone(coverage["mass"])
            self.assertIsNone(coverage["energy"])
            self.assertEqual(item["metric"]["completeness"], "known_minimum")
        self.assertTrue(self.payload["contract"]["nutrientCoverageGates"]["requiresEnergyCoverage"])

    def test_privacy_allowlist_excludes_finance_notes_and_chess(self):
        forbidden = {"notes", "expenses", "amount_rub", "amountRub", "chess", "chessSessions"}
        self.assertTrue(forbidden.isdisjoint(set(walk_keys(self.payload))))
        serialized = json.dumps(self.payload, ensure_ascii=False).lower()
        self.assertNotIn("groceries", serialized)
        self.assertNotIn("transport", serialized)

    def test_fixed_metadata_makes_generation_deterministic(self):
        second = generator.build_payload(
            self.database,
            generated_at="2026-08-26T12:00:00+03:00",
            commit="test-commit",
        )
        self.assertEqual(
            json.dumps(self.payload, ensure_ascii=False, sort_keys=True),
            json.dumps(second, ensure_ascii=False, sort_keys=True),
        )

    def test_structured_food_groups_are_exported(self):
        september_two = [meal for meal in self.payload["meals"] if meal["date"] == "2026-09-02"]
        groups = {component["foodGroup"] for meal in september_two for component in meal["components"]}
        self.assertTrue({"fish", "vegetables", "fruit", "grains", "nuts", "unknown"}.issubset(groups))

    def test_every_component_on_september_one_and_two_has_a_food_group(self):
        meals = [meal for meal in self.payload["meals"] if meal["date"] in {"2026-09-01", "2026-09-02"}]
        self.assertTrue(meals)
        self.assertTrue(all(component["foodGroup"] is not None for meal in meals for component in meal["components"]))

    def test_september_two_photo_corrections_reach_snapshot(self):
        september_two = [meal for meal in self.payload["meals"] if meal["date"] == "2026-09-02"]
        by_title = {meal["title"]: meal for meal in september_two}
        self.assertEqual(by_title["Салат из квашеной капусты и салата «Венеция»"]["energy"]["value"], 203.2)
        self.assertEqual(by_title["Сливочный рыбный суп"]["protein"]["value"], 10.7)
        self.assertEqual(by_title["Пельмени, 10 штук"]["weightG"], 200.0)


if __name__ == "__main__":
    unittest.main()
