"""Repositories for persisting feedback submissions."""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any, Dict, Optional, Protocol

from backend.config.settings import SupabaseSettings
from backend.utils.http_client import HttpClient, HttpResponse

logger = logging.getLogger(__name__)


class FeedbackRepository(Protocol):
    """Persistence contract for storing feedback submissions."""

    def submit_feedback(
        self,
        *,
        category: str,
        message: str,
        metadata: Dict[str, Any],
        user_id: Optional[int],
        submitted_at: Optional[str],
    ) -> Dict[str, Any]:
        ...


class FeedbackRepositoryError(RuntimeError):
    """Raised when a feedback submission cannot be persisted."""


@dataclass
class SupabaseFeedbackRepository:
    """Feedback repository that delegates to Supabase REST."""

    settings: SupabaseSettings
    client: HttpClient = HttpClient()

    def submit_feedback(
        self,
        *,
        category: str,
        message: str,
        metadata: Dict[str, Any],
        user_id: Optional[int],
        submitted_at: Optional[str],
    ) -> Dict[str, Any]:
        if not self.settings.url or not self.settings.service_key:
            raise FeedbackRepositoryError("Supabase URL and service key must be configured")

        payload: Dict[str, Any] = {
            "category": category,
            "message": message,
            "metadata": metadata or {},
        }
        if user_id is not None:
            payload["user_id"] = user_id
        if submitted_at is not None:
            payload["submitted_at"] = submitted_at

        response = self.client.post(
            self._feedback_url(),
            headers=self._headers(),
            json_payload=payload,
            timeout=10,
        )

        if not 200 <= response.status_code < 300:
            self._log_failure(response)
            raise FeedbackRepositoryError(
                f"Supabase feedback insert failed with status {response.status_code}"
            )

        try:
            data = response.json()
        except ValueError as exc:  # pragma: no cover - defensive guard
            raise FeedbackRepositoryError("Unexpected response payload from Supabase") from exc

        if isinstance(data, list) and data:
            return data[0]
        if isinstance(data, dict):
            return data
        return {"status": "received"}

    def _feedback_url(self) -> str:
        base = self.settings.url.rstrip("/")
        return f"{base}/rest/v1/{self.settings.feedback_table}"

    def _headers(self) -> Dict[str, str]:
        key = self.settings.service_key
        assert key  # validated earlier
        return {
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Prefer": "return=representation",
            "Accept-Profile": self.settings.schema,
            "Content-Profile": self.settings.schema,
        }

    def _log_failure(self, response: HttpResponse) -> None:
        body: Any
        try:
            body = response.json()
        except ValueError:
            body = response.text
        logger.error(
            "Supabase feedback submission failed (status=%s, body=%s)",
            response.status_code,
            body,
        )
