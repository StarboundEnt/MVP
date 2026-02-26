import json
import tempfile
import unittest
from pathlib import Path

from backend.api.local_profile_store import LocalComplexityStore


class LocalComplexityStoreTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path = Path(self.tmp.name) / "profiles.json"
        self.path.write_text(
            json.dumps({"user-1": {"user": {"id": "user-1"}}}, indent=2), encoding="utf-8"
        )

    def test_fetch_returns_profile(self) -> None:
        store = LocalComplexityStore(self.path)
        profile = store.fetch_complexity_profile(user_id="user-1")
        self.assertEqual(profile["user"]["id"], "user-1")

    def test_fetch_unknown_user_returns_none(self) -> None:
        store = LocalComplexityStore(self.path)
        self.assertIsNone(store.fetch_complexity_profile(user_id="missing"))

    def test_upsert_persists_to_disk(self) -> None:
        store = LocalComplexityStore(self.path)
        store.upsert("user-2", {"user": {"id": "user-2"}, "choices": []})
        data = json.loads(self.path.read_text(encoding="utf-8"))
        self.assertIn("user-2", data)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
