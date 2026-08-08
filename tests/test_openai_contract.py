from __future__ import annotations

import json
import unittest
from types import SimpleNamespace
from zoneinfo import ZoneInfo

from healthbot.app import coalesce_media_groups
from healthbot.events import EventValidationError
from healthbot.openai_client import OpenAIHealthAnalyzer, validate_draft
from healthbot.prompt import DRAFT_SCHEMA


def nutrition_draft() -> dict:
    return {
        "event_type": "nutrition",
        "diary_date": "2026-08-09",
        "occurred_at": "13:10",
        "summary_ru": "Обед.",
        "question": None,
        "observations": ["Виден лосось"],
        "assumptions": ["Тарелка 26 см"],
        "confidence": "medium",
        "uncertainty_drivers": ["масса"],
        "recommendations": [],
        "payload": {
            "meal_type": "lunch",
            "nutrition_items": [
                {
                    "food_name": "Лосось",
                    "weight_g": 200,
                    "weight_min_g": 180,
                    "weight_max_g": 220,
                    "calories_kcal": 416,
                    "calories_min_kcal": 370,
                    "calories_max_kcal": 460,
                    "protein_g": 40,
                    "fat_g": 28,
                    "carbs_g": 0,
                    "notes": "Оценка.",
                }
            ],
            "food_bases": ["fish"],
            "meal_rating": 8,
            "sleep": None,
            "workout": None,
            "daily_checkin": None,
            "expense": None,
        },
    }


class OpenAIContractTests(unittest.TestCase):
    def test_schema_is_json_serializable(self) -> None:
        serialized = json.dumps(DRAFT_SCHEMA)
        self.assertIn("nutrition_items", serialized)
        self.assertEqual(DRAFT_SCHEMA["type"], "object")

    def test_valid_nutrition_draft(self) -> None:
        draft = nutrition_draft()
        self.assertEqual(validate_draft(draft)["event_type"], "nutrition")

    def test_rejects_inverted_range(self) -> None:
        draft = nutrition_draft()
        draft["payload"]["nutrition_items"][0]["weight_min_g"] = 230
        with self.assertRaises(EventValidationError):
            validate_draft(draft)

    def test_unknown_requires_question(self) -> None:
        draft = nutrition_draft()
        draft["event_type"] = "unknown"
        draft["question"] = None
        with self.assertRaises(EventValidationError):
            validate_draft(draft)

    def test_responses_request_uses_private_structured_multimodal_input(self) -> None:
        class FakeAnalyzer(OpenAIHealthAnalyzer):
            def _json_request(self, path, body):
                self.path = path
                self.body = body
                return {
                    "output": [
                        {
                            "type": "message",
                            "content": [
                                {"type": "output_text", "text": json.dumps(nutrition_draft())}
                            ],
                        }
                    ]
                }

        config = SimpleNamespace(
            timezone=ZoneInfo("Europe/Moscow"),
            openai_model="gpt-5.6-sol",
            image_detail="auto",
            safety_identifier="test-user-hash",
            openai_api_key="not-used",
        )
        analyzer = FakeAnalyzer(config)
        result = analyzer.analyze(
            "обед",
            image_bytes=b"one",
            additional_images=[(b"two", "image/jpeg"), (b"three", "image/jpeg")],
        )
        self.assertEqual(result["event_type"], "nutrition")
        self.assertEqual(analyzer.path, "/responses")
        self.assertFalse(analyzer.body["store"])
        self.assertEqual(analyzer.body["text"]["format"]["type"], "json_schema")
        image_inputs = [
            item
            for item in analyzer.body["input"][1]["content"]
            if item["type"] == "input_image"
        ]
        self.assertEqual(len(image_inputs), 3)

    def test_media_group_is_combined(self) -> None:
        updates = [
            {
                "update_id": 10,
                "message": {
                    "message_id": 1,
                    "media_group_id": "album",
                    "chat": {"id": 5},
                    "photo": [{"file_id": "small-a"}, {"file_id": "large-a"}],
                    "caption": "обед",
                },
            },
            {
                "update_id": 11,
                "message": {
                    "message_id": 2,
                    "media_group_id": "album",
                    "chat": {"id": 5},
                    "photo": [{"file_id": "large-b"}],
                },
            },
        ]
        combined = coalesce_media_groups(updates)
        self.assertEqual(len(combined), 1)
        self.assertEqual(combined[0]["update_id"], 11)
        self.assertEqual(combined[0]["message"]["photo_album"], ["large-a", "large-b"])


if __name__ == "__main__":
    unittest.main()
