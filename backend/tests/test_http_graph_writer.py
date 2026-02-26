import unittest
from typing import Any, Dict

from backend.ingestion.http_writer import GraphWriteError, HttpGraphWriter


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
        self.next_response = _Response(202, {})

    def post(self, url: str, *, headers: Dict[str, str], json_payload: Any, timeout: float):
        self.requests.append(
            {"url": url, "headers": headers, "json": json_payload, "timeout": timeout}
        )
        return self.next_response


class HttpGraphWriterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = _Client()
        self.writer = HttpGraphWriter(
            base_url="https://api.example.com",
            ingest_path="/ingest",
            batch_path="/ingest/batch",
            api_key="secret",
            timeout_seconds=5,
            client=self.client,
        )

    def test_write_sends_payload_to_single_endpoint(self) -> None:
        payload = {"choice": {"modality": "sleep"}}
        self.writer.write(payload)

        request = self.client.requests[0]
        self.assertEqual(request["url"], "https://api.example.com/ingest")
        self.assertEqual(request["headers"]["Authorization"], "Bearer secret")
        self.assertEqual(request["json"], payload)
        self.assertEqual(request["timeout"], 5)

    def test_write_many_sends_payloads_to_batch_endpoint(self) -> None:
        payloads = [{"choice": {"modality": "sleep"}}]
        self.writer.write_many(payloads)

        request = self.client.requests[0]
        self.assertEqual(request["url"], "https://api.example.com/ingest/batch")
        self.assertEqual(request["json"], {"payloads": payloads})

    def test_error_response_raises_graph_write_error(self) -> None:
        self.client.next_response = _Response(500, text="boom")

        with self.assertRaises(GraphWriteError):
            self.writer.write({"choice": {}})

    def test_absolute_path_not_joined_with_base_url(self) -> None:
        client = _Client()
        writer = HttpGraphWriter(
            base_url="https://api.example.com",
            ingest_path="https://other.service/custom",
            batch_path="https://other.service/custom/batch",
            client=client,
        )

        writer.write({"choice": {"modality": "sleep"}})

        self.assertEqual(client.requests[0]["url"], "https://other.service/custom")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
