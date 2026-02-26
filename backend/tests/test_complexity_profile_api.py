import unittest

from backend.api.complexity_profile import (
    ComplexityProfileNotFoundError,
    ComplexityProfileService,
)


class _FakeStore:
    def __init__(self, payload=None):
        self.payload = payload
        self.calls = []

    def fetch_complexity_profile(self, *, user_id: str, as_of=None):
        self.calls.append({"user_id": user_id, "as_of": as_of})
        return self.payload


class ComplexityProfileServiceTests(unittest.TestCase):
    def test_normalises_profile_and_filters_empty_entries(self) -> None:
        store = _FakeStore(
            payload={
                "user": {"id": "user-123", "consent_status": "active"},
                "profile_metric": [{"id": "metric-1", "value": 0.7}],
                "choices": [
                    {"id": "sleep", "name": "Sleep Hygiene"},
                    {"id": None, "name": "Bad entry"},
                ],
                "constraints": [
                    {"id": "housing", "constraint_score": 0.9},
                    {"name": "missing id"},
                ],
                "recommended_resources": [
                    {"intervention_id": "int-1", "name": "Housing support"},
                    {"intervention_id": None, "name": "Unknown"},
                ],
            }
        )
        service = ComplexityProfileService(store=store)

        profile = service.get_profile("user-123")

        self.assertEqual(profile["user"]["id"], "user-123")
        self.assertEqual(profile["profile_metric"]["id"], "metric-1")
        self.assertEqual(profile["choices"], [{"id": "sleep", "name": "Sleep Hygiene"}])
        self.assertEqual(
            profile["constraints"],
            [{"id": "housing", "constraint_score": 0.9}],
        )
        self.assertEqual(
            profile["recommended_resources"],
            [{"intervention_id": "int-1", "name": "Housing support"}],
        )
        self.assertEqual(store.calls[0]["user_id"], "user-123")

    def test_uses_default_user_id_when_missing(self) -> None:
        store = _FakeStore(payload={"user": {}, "choices": []})
        service = ComplexityProfileService(store=store)

        profile = service.get_profile("abc")

        self.assertEqual(profile["user"]["id"], "abc")
        self.assertEqual(profile["choices"], [])
        self.assertIsNone(profile["profile_metric"])

    def test_rejects_blank_user_id(self) -> None:
        store = _FakeStore()
        service = ComplexityProfileService(store=store)

        with self.assertRaises(ValueError):
            service.get_profile("  ")

    def test_raises_not_found_when_store_returns_none(self) -> None:
        store = _FakeStore(payload=None)
        service = ComplexityProfileService(store=store)

        with self.assertRaises(ComplexityProfileNotFoundError):
            service.get_profile("missing-user")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
