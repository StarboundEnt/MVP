import unittest
from datetime import datetime

from backend.ingestion.question_mapper import map_response_to_payload, ResponseMappingError
from backend.mappings.question_mapping import load_question_registry, QuestionMappingError


class QuestionMapperTests(unittest.TestCase):
    def setUp(self) -> None:
        # Ensure registry loads without error for baseline coverage
        self.registry = load_question_registry()

    def test_map_likert_response(self) -> None:
        payload = map_response_to_payload(
            instrument_id="onboarding_survey_v1",
            question_id="q_sleep_schedule",
            answer=4,
            recorded_at=datetime(2024, 6, 15, 8, 0),
        )

        self.assertEqual(payload["target"], {"type": "choice", "id": "sleep_hygiene", "modality": "sleep"})
        observation = payload["observation"]
        self.assertEqual(observation["observation_type"], "survey")
        self.assertEqual(observation["choice_modality"], "sleep")
        self.assertAlmostEqual(observation["value"], 0.7)
        self.assertEqual(observation["metadata"]["score"], 0.7)
        self.assertTrue(observation["recorded_at"].startswith("2024-06-15T08:00:00"))

    def test_map_numeric_response_converts_units(self) -> None:
        payload = map_response_to_payload(
            instrument_id="daily_journal",
            question_id="followup_hydration",
            answer=8,
        )

        observation = payload["observation"]
        self.assertEqual(observation["observation_type"], "self_report")
        self.assertEqual(observation["choice_modality"], "hydration")
        self.assertAlmostEqual(observation["value"], 8 * 0.236588, places=5)
        self.assertEqual(observation["units"], "litres")

    def test_unknown_question_raises(self) -> None:
        with self.assertRaises(QuestionMappingError):
            self.registry.get_question("daily_journal", "not_real")

    def test_invalid_option_raises(self) -> None:
        with self.assertRaises(ResponseMappingError):
            map_response_to_payload(
                instrument_id="onboarding_survey_v1",
                question_id="q_housing_security",
                answer="not_valid",
            )


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
