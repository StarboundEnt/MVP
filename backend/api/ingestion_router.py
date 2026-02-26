"""FastAPI router exposing ingestion endpoints backed by IngestionService."""
from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from backend.ingestion.service import IngestionResult, IngestionService

router = APIRouter(prefix="/ingestion", tags=["ingestion"])

_service: Optional[IngestionService] = None


def configure_service(service: IngestionService) -> None:
    global _service
    _service = service


def get_service() -> IngestionService:
    if _service is None:  # pragma: no cover - configuration error
        raise RuntimeError("IngestionService has not been configured")
    return _service


class QuestionResponseBody(BaseModel):
    instrument_id: str = Field(..., min_length=1)
    question_id: str = Field(..., min_length=1)
    answer: Any
    recorded_at: Optional[datetime] = None
    metadata: Optional[Dict[str, Any]] = None


class PayloadBody(BaseModel):
    payload: Dict[str, Any]


class BatchBody(BaseModel):
    payloads: List[Dict[str, Any]]


class IngestionResponse(BaseModel):
    status: str
    payload: Dict[str, Any]
    reason: Optional[str] = None

    @classmethod
    def from_result(cls, result: IngestionResult) -> "IngestionResponse":
        return cls(status=result.status, payload=result.payload, reason=result.reason)


@router.post("/question-response", response_model=IngestionResponse, status_code=status.HTTP_202_ACCEPTED)
def ingest_question_response(body: QuestionResponseBody) -> IngestionResponse:
    service = get_service()
    try:
        result = service.ingest_question_response(
            instrument_id=body.instrument_id,
            question_id=body.question_id,
            answer=body.answer,
            recorded_at=body.recorded_at,
            metadata=body.metadata,
        )
    except Exception as exc:  # pragma: no cover - defensive guard
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to process question response: {exc}",
        ) from exc

    return IngestionResponse.from_result(result)


@router.post("/payload", response_model=IngestionResponse, status_code=status.HTTP_202_ACCEPTED)
def ingest_payload(body: PayloadBody) -> IngestionResponse:
    service = get_service()
    try:
        result = service.ingest_payload(body.payload)
    except Exception as exc:  # pragma: no cover
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to ingest payload: {exc}",
        ) from exc
    return IngestionResponse.from_result(result)


@router.post("/batch", response_model=List[IngestionResponse], status_code=status.HTTP_202_ACCEPTED)
def ingest_batch(body: BatchBody) -> List[IngestionResponse]:
    service = get_service()

    try:
        results = service.ingest_batch(body.payloads)
    except Exception as exc:  # pragma: no cover
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Failed to ingest batch payloads: {exc}",
        ) from exc

    return [IngestionResponse.from_result(result) for result in results]
