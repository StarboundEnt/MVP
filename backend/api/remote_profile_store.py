"""Remote Complexity Profile store backed by the production API."""
from __future__ import annotations

import logging
from typing import Any, Dict, Optional
from urllib.parse import urljoin

from backend.utils.http_client import HttpClient, HttpResponse

logger = logging.getLogger(__name__)


class RemoteComplexityStore:
    """Fetch complexity profiles from the remote Complexity backend API."""

    def __init__(
        self,
        *,
        base_url: str,
        profile_path_template: str,
        api_key: str | None = None,
        timeout_seconds: float = 10.0,
        client: HttpClient | None = None,
    ) -> None:
        self._base_url = base_url.rstrip("/")
        self._template = profile_path_template
        self._api_key = api_key
        self._timeout = timeout_seconds
        self._client = client or HttpClient()

    def fetch_complexity_profile(
        self,
        *,
        user_id: str,
        as_of: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        path = self._template.format(id=user_id)
        url = self._build_url(path)

        params = {"as_of": as_of} if as_of else None
        response = self._client.get(
            url,
            headers=self._headers(),
            params=params,
            timeout=self._timeout,
        )

        if response.status_code == 404:
            return None

        if 200 <= response.status_code < 300:
            return self._decode_json(response, user_id=user_id)

        logger.error(
            "Complexity backend request failed (status=%s, body=%s)",
            response.status_code,
            response.text,
        )
        raise RuntimeError(
            f"Complexity backend returned {response.status_code} for user '{user_id}'"
        )

    def _headers(self) -> Dict[str, str]:
        headers: Dict[str, str] = {}
        if self._api_key:
            headers["Authorization"] = f"Bearer {self._api_key}"
        return headers

    def _decode_json(self, response: HttpResponse, *, user_id: str) -> Dict[str, Any]:
        try:
            return response.json()
        except ValueError as exc:
            logger.error("Invalid JSON from complexity backend for user %s", user_id)
            raise RuntimeError("Invalid JSON payload from complexity backend") from exc

    def _build_url(self, path: str) -> str:
        if path.startswith("http://") or path.startswith("https://"):
            return path
        normalized = path.lstrip("/")
        return urljoin(f"{self._base_url}/", normalized)
