import unittest

from backend.api.health import build_health_payload


class HealthPayloadTests(unittest.TestCase):
    def test_build_health_payload_contains_versions(self) -> None:
        payload = build_health_payload()

        self.assertEqual(payload["status"], "ok")
        self.assertIn("vocabulary", payload)
        self.assertIn("question_mapping", payload)
        self.assertTrue(payload["vocabulary"]["summary"])  # non-empty
        self.assertGreaterEqual(payload["question_mapping"]["instrument_count"], 1)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
