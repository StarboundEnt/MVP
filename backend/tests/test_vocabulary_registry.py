import unittest
from pathlib import Path

from backend.validators.vocabulary_registry import (
    VocabularyError,
    load_registry,
    validate_payload,
)


REGISTRY_PATH = Path(__file__).resolve().parents[1] / "config" / "graph_vocab.json"


class VocabularyRegistryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.registry = load_registry(REGISTRY_PATH)

    def test_summary_lists_existing_vocab(self) -> None:
        summary = self.registry.summary()
        self.assertIn("choice_modalities", summary)
        self.assertIn("sleep", summary["choice_modalities"])

    def test_validate_payload_happy_path(self) -> None:
        payload = {
            "choice": {"modality": "sleep"},
            "chance": {"domain": "housing"},
            "observation": {
                "observation_type": "self_report",
                "choice_modality": "sleep",
            },
            "metric": {"metric_type": "capacity_score"},
            "facet": {"facet_type": "choice"},
            "intervention": {"effort_level": "medium"},
        }
        validate_payload(payload)

    def test_validate_payload_raises_for_unknown_values(self) -> None:
        payload = {
            "choice": {"modality": "unknown_modality"},
        }
        with self.assertRaises(VocabularyError):
            validate_payload(payload)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
