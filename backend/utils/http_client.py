"""Minimal HTTP client abstraction using the Python standard library."""
from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any, Dict, Iterable, Optional
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


@dataclass
class HttpResponse:
    status_code: int
    body: bytes
    headers: Dict[str, Any]

    def json(self) -> Any:
        return json.loads(self.body.decode("utf-8"))

    @property
    def text(self) -> str:
        return self.body.decode("utf-8")


class HttpClient:
    """Tiny helper for issuing JSON HTTP requests."""

    def post(
        self,
        url: str,
        *,
        headers: Dict[str, str],
        json_payload: Any,
        timeout: float,
    ) -> HttpResponse:
        body = json.dumps(json_payload).encode("utf-8")
        request = Request(url, data=body, headers=self._with_json_headers(headers), method="POST")
        return self._execute(request, timeout)

    def get(
        self,
        url: str,
        *,
        headers: Dict[str, str],
        params: Optional[Dict[str, Any]],
        timeout: float,
    ) -> HttpResponse:
        if params:
            query = "&".join(f"{key}={value}" for key, value in params.items())
            separator = "&" if "?" in url else "?"
            url = f"{url}{separator}{query}"
        request = Request(url, headers=self._with_accept_headers(headers), method="GET")
        return self._execute(request, timeout)

    def _execute(self, request: Request, timeout: float) -> HttpResponse:
        try:
            with urlopen(request, timeout=timeout) as response:
                body = response.read()
                headers = dict(response.headers.items())
                return HttpResponse(status_code=response.getcode(), body=body, headers=headers)
        except HTTPError as exc:
            return HttpResponse(
                status_code=exc.code,
                body=exc.read() or b"",
                headers=dict(exc.headers.items()) if exc.headers else {},
            )
        except URLError as exc:  # pragma: no cover - network failures
            raise RuntimeError(f"HTTP request failed: {exc}") from exc

    @staticmethod
    def _with_json_headers(headers: Dict[str, str]) -> Dict[str, str]:
        merged = dict(headers)
        merged.setdefault("Content-Type", "application/json")
        merged.setdefault("Accept", "application/json")
        return merged

    @staticmethod
    def _with_accept_headers(headers: Dict[str, str]) -> Dict[str, str]:
        merged = dict(headers)
        merged.setdefault("Accept", "application/json")
        return merged
