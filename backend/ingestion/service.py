"""High-level ingestion service enforcing vocabulary validation before graph writes."""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any, Dict, Iterable, Protocol

from backend.ingestion.question_mapper import (
    ResponseMappingError,
    map_response_to_payload,
)
from backend.validators.vocabulary_registry import VocabularyError, validate_payload

logger = logging.getLogger(__name__)


class GraphWriter(Protocol):
    """Minimal protocol for writing payloads to the knowledge graph."""

    def write(self, payload: Dict[str, Any]) -> None:  # pragma: no cover - behaviour is injected
        ...

    def write_many(self, payloads: Iterable[Dict[str, Any]]) -> None:  # pragma: no cover
        ...


@dataclass
class IngestionResult:
    status: str
    payload: Dict[str, Any]
    reason: str | None = None


class IngestionService:
    def __init__(self, graph_writer: GraphWriter) -> None:
        self._graph_writer = graph_writer

    def ingest_question_response(
        self,
        *,
        instrument_id: str,
        question_id: str,
        answer: Any,
        recorded_at: Any | None = None,
        metadata: Dict[str, Any] | None = None,
    ) -> IngestionResult:
        try:
            payload = map_response_to_payload(
                instrument_id=instrument_id,
                question_id=question_id,
                answer=answer,
                recorded_at=recorded_at,
                extra_metadata=metadata,
            )
        except ResponseMappingError as exc:
            reason = f"mapping_error: {exc}"
            self._log_rejection(reason, instrument_id, question_id, answer)
            return IngestionResult(status="rejected", payload={}, reason=reason)

        return self.ingest_payload(payload)

    def ingest_payload(self, payload: Dict[str, Any]) -> IngestionResult:
        try:
            validate_payload(payload)
        except VocabularyError as exc:
            reason = f"vocabulary_error: {exc}"
            self._log_rejection(reason, payload=payload)
            return IngestionResult(status="rejected", payload=payload, reason=reason)

        self._graph_writer.write(payload)
        return IngestionResult(status="accepted", payload=payload)

    def ingest_batch(self, payloads: Iterable[Dict[str, Any]]) -> list[IngestionResult]:
        accepted: list[Dict[str, Any]] = []
        results: list[IngestionResult] = []

        for payload in payloads:
            try:
                validate_payload(payload)
            except VocabularyError as exc:
                reason = f"vocabulary_error: {exc}"
                self._log_rejection(reason, payload=payload)
                results.append(IngestionResult(status="rejected", payload=payload, reason=reason))
            else:
                accepted.append(payload)
                results.append(IngestionResult(status="accepted", payload=payload))

        if accepted:
            self._graph_writer.write_many(accepted)

        return results

    def _log_rejection(
        self,
        reason: str,
        instrument_id: str | None = None,
        question_id: str | None = None,
        answer: Any | None = None,
        payload: Dict[str, Any] | None = None,
    ) -> None:
        logger.warning(
            "ingestion_rejected",
            extra={
                "reason": reason,
                "instrument_id": instrument_id,
                "question_id": question_id,
                "answer": answer,
                "payload": payload,
            },
        )
