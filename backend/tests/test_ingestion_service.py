import unittest

from backend.ingestion.service import IngestionService, IngestionResult


class MemoryGraphWriter:
    def __init__(self) -> None:
        self.written = []
        self.written_batches = []

    def write(self, payload):
        self.written.append(payload)

    def write_many(self, payloads):
        self.written_batches.append(list(payloads))
        self.written.extend(payloads)


class IngestionServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.writer = MemoryGraphWriter()
        self.service = IngestionService(self.writer)

    def test_ingest_question_response_validates_and_writes(self) -> None:
        result = self.service.ingest_question_response(
            instrument_id="daily_journal",
            question_id="followup_hydration",
            answer=4,
        )

        self.assertEqual(result.status, "accepted")
        self.assertEqual(len(self.writer.written), 1)
        self.assertIn("observation", self.writer.written[0])

    def test_ingest_payload_rejects_invalid_vocab(self) -> None:
        payload = {
            "choice": {"modality": "invalid_modality"},
            "observation": {"observation_type": "self_report"},
        }
        result = self.service.ingest_payload(payload)

        self.assertEqual(result.status, "rejected")
        self.assertEqual(len(self.writer.written), 0)

    def test_ingest_batch_mixes_accept_and_reject(self) -> None:
        payloads = [
            {
                "choice": {"modality": "sleep"},
                "observation": {
                    "observation_type": "self_report",
                    "choice_modality": "sleep",
                },
            },
            {
                "choice": {"modality": "not_real"},
                "observation": {"observation_type": "self_report"},
            },
        ]

        results = self.service.ingest_batch(payloads)

        statuses = [r.status for r in results]
        self.assertEqual(statuses, ["accepted", "rejected"])
        self.assertEqual(len(self.writer.written), 1)
        self.assertEqual(len(self.writer.written_batches), 1)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
