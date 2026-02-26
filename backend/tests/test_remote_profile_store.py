import unittest
from typing import Any, Dict, Optional

from backend.api.remote_profile_store import RemoteComplexityStore


class _Response:
    def __init__(self, status_code: int, json_payload: Any = None, text: str = "") -> None:
        self.status_code = status_code
        self._json_payload = json_payload
        self.text = text

    def json(self) -> Any:
        if isinstance(self._json_payload, Exception):
            raise self._json_payload
        return self._json_payload


class _Client:
    def __init__(self) -> None:
        self.requests: list[Dict[str, Any]] = []
        self.next_response = _Response(200, {})

    def get(self, url: str, *, headers: Dict[str, str], params: Optional[Dict[str, Any]], timeout: float):
        self.requests.append(
            {"url": url, "headers": headers, "params": params, "timeout": timeout}
        )
        return self.next_response


class RemoteComplexityStoreTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = _Client()
        self.store = RemoteComplexityStore(
            base_url="https://api.example.com",
            profile_path_template="/users/{id}/complexity-profile",
            api_key="secret",
            timeout_seconds=7,
            client=self.client,
        )

    def test_fetch_profile_returns_json_payload(self) -> None:
        payload = {"user": {"id": "123"}}
        self.client.next_response = _Response(200, payload)

        result = self.store.fetch_complexity_profile(user_id="123")

        self.assertEqual(result, payload)
        request = self.client.requests[0]
        self.assertEqual(
            request["url"], "https://api.example.com/users/123/complexity-profile"
        )
        self.assertEqual(request["headers"]["Authorization"], "Bearer secret")
        self.assertIsNone(request["params"])
        self.assertEqual(request["timeout"], 7)

    def test_fetch_profile_with_as_of_parameter(self) -> None:
        self.client.next_response = _Response(200, {"user": {"id": "123"}})

        self.store.fetch_complexity_profile(user_id="123", as_of="2024-06-01")

        request = self.client.requests[0]
        self.assertEqual(request["params"], {"as_of": "2024-06-01"})

    def test_fetch_profile_returns_none_for_not_found(self) -> None:
        self.client.next_response = _Response(404)

        result = self.store.fetch_complexity_profile(user_id="missing")

        self.assertIsNone(result)

    def test_fetch_profile_raises_for_invalid_json(self) -> None:
        self.client.next_response = _Response(200, ValueError("boom"))

        with self.assertRaises(RuntimeError):
            self.store.fetch_complexity_profile(user_id="123")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
