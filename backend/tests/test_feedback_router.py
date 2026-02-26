import unittest
from datetime import datetime
from typing import Any, Dict, Optional

from backend.api.feedback_router import (
    FeedbackResponse,
    FeedbackSubmission,
    configure_repository,
    submit_feedback,
)


class _Repository:
    def __init__(self) -> None:
        self.calls: list[Dict[str, Any]] = []

    def submit_feedback(
        self,
        *,
        category: str,
        message: str,
        metadata: Dict[str, Any],
        user_id: Optional[int],
        submitted_at: Optional[str],
    ) -> Dict[str, Any]:
        self.calls.append(
            {
                "category": category,
                "message": message,
                "metadata": metadata,
                "user_id": user_id,
                "submitted_at": submitted_at,
            }
        )
        return {"id": 1, "status": "received"}


class FeedbackRouterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.repository = _Repository()
        configure_repository(self.repository)

    def test_submit_feedback_returns_response(self) -> None:
        payload = FeedbackSubmission(
            category="General",
            message="Thanks!",
            metadata={"rating": 5},
            user_id=10,
            submitted_at=datetime(2024, 6, 1, 12, 0, 0),
        )

        response: FeedbackResponse = submit_feedback(payload)

        self.assertEqual(response.status, "received")
        self.assertEqual(response.id, 1)
        self.assertEqual(len(self.repository.calls), 1)
        self.assertEqual(self.repository.calls[0]["user_id"], 10)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
