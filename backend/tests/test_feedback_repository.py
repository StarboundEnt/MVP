import unittest

from backend.config.settings import SupabaseSettings
from backend.services.feedback_repository import (
    FeedbackRepositoryError,
    SupabaseFeedbackRepository,
)


class _Response:
    def __init__(self, status_code: int, payload):
        self.status_code = status_code
        self._payload = payload
        self.text = str(payload)

    def json(self):
        if isinstance(self._payload, Exception):
            raise self._payload
        return self._payload


class _Client:
    def __init__(self):
        self.requests = []
        self.next_response = _Response(201, [{"id": 42, "status": "received"}])

    def post(self, url, *, headers, json_payload, timeout):
        self.requests.append(
            {
                "url": url,
                "headers": headers,
                "json": json_payload,
                "timeout": timeout,
            }
        )
        return self.next_response


class SupabaseFeedbackRepositoryTests(unittest.TestCase):
    def setUp(self) -> None:
        settings = SupabaseSettings(
            url="https://example.supabase.co",
            service_key="service-key",
            schema="app_public",
            feedback_table="feedback",
        )
        self.client = _Client()
        self.repository = SupabaseFeedbackRepository(settings=settings, client=self.client)

    def test_submit_feedback_sends_payload(self) -> None:
        record = self.repository.submit_feedback(
            category="General",
            message="Great app!",
            metadata={"rating": 5},
            user_id=123,
            submitted_at="2024-07-01T10:00:00Z",
        )

        self.assertEqual(record["id"], 42)
        request = self.client.requests[0]
        self.assertEqual(
            request["url"], "https://example.supabase.co/rest/v1/feedback"
        )
        self.assertEqual(request["json"]["message"], "Great app!")
        self.assertEqual(request["headers"]["Authorization"], "Bearer service-key")

    def test_missing_configuration_raises(self) -> None:
        settings = SupabaseSettings()
        repo = SupabaseFeedbackRepository(settings=settings)

        with self.assertRaises(FeedbackRepositoryError):
            repo.submit_feedback(
                category="General",
                message="Hello",
                metadata={},
                user_id=None,
                submitted_at=None,
            )

    def test_non_success_response_raises(self) -> None:
        self.client.next_response = _Response(500, {"message": "error"})

        with self.assertRaises(FeedbackRepositoryError):
            self.repository.submit_feedback(
                category="Bug",
                message="Something broke",
                metadata={},
                user_id=None,
                submitted_at=None,
            )


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
