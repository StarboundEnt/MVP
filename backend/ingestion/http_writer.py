"""HTTP-based graph writer that forwards payloads to the Complexity backend."""
from __future__ import annotations

import logging
from typing import Any, Dict, Iterable, Optional
from urllib.parse import urljoin

from backend.ingestion.service import GraphWriter
from backend.utils.http_client import HttpClient, HttpResponse

logger = logging.getLogger(__name__)


class GraphWriteError(RuntimeError):
    """Raised when the remote graph backend responds with an error."""


class HttpGraphWriter(GraphWriter):
    """Graph writer implementation that POSTs payloads to a remote HTTP endpoint."""

    def __init__(
        self,
        *,
        base_url: str,
        ingest_path: str,
        batch_path: str,
        api_key: Optional[str] = None,
        timeout_seconds: float = 10.0,
        client: Optional[HttpClient] = None,
    ) -> None:
        self._base_url = base_url.rstrip("/")
        self._ingest_url = self._build_url(ingest_path)
        self._batch_url = self._build_url(batch_path)
        self._api_key = api_key
        self._timeout = timeout_seconds
        self._client = client or HttpClient()

    def write(self, payload: Dict[str, Any]) -> None:
        response = self._client.post(
            self._ingest_url,
            headers=self._headers(),
            json_payload=payload,
            timeout=self._timeout,
        )
        self._handle_response(response, context="single")

    def write_many(self, payloads: Iterable[Dict[str, Any]]) -> None:
        response = self._client.post(
            self._batch_url,
            headers=self._headers(),
            json_payload={"payloads": list(payloads)},
            timeout=self._timeout,
        )
        self._handle_response(response, context="batch")

    def _headers(self) -> Dict[str, str]:
        headers = {"Content-Type": "application/json"}
        if self._api_key:
            headers["Authorization"] = f"Bearer {self._api_key}"
        return headers

    def _handle_response(self, response: HttpResponse, *, context: str) -> None:
        if 200 <= response.status_code < 300:
            return

        body: Any
        try:
            body = response.json()
        except ValueError:  # pragma: no cover - best effort logging
            body = response.text

        message = (
            f"Graph backend {context} ingestion failed "
            f"with status {response.status_code}: {body}"
        )
        logger.error(message)
        raise GraphWriteError(message)

    def _build_url(self, path: str) -> str:
        if path.startswith("http://") or path.startswith("https://"):
            return path
        normalized = path.lstrip("/")
        return urljoin(f"{self._base_url}/", normalized)
