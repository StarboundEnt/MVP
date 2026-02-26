"""FastAPI router for accepting user feedback submissions."""
from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, Optional

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from backend.services.feedback_repository import (
    FeedbackRepository,
    FeedbackRepositoryError,
)

router = APIRouter(tags=["feedback"])

_repository: Optional[FeedbackRepository] = None


def configure_repository(repository: FeedbackRepository) -> None:
    global _repository
    _repository = repository


def get_repository() -> FeedbackRepository:
    if _repository is None:  # pragma: no cover - configuration error
        raise RuntimeError("Feedback repository has not been configured")
    return _repository


class FeedbackSubmission(BaseModel):
    category: str = Field(..., min_length=1)
    message: str = Field(..., min_length=1)
    metadata: Optional[Dict[str, Any]] = None
    user_id: Optional[int] = None
    submitted_at: Optional[datetime] = None


class FeedbackResponse(BaseModel):
    status: str = Field(default="received")
    id: Optional[int] = None


@router.post("/feedback", response_model=FeedbackResponse, status_code=status.HTTP_202_ACCEPTED)
def submit_feedback(payload: FeedbackSubmission) -> FeedbackResponse:
    repository = get_repository()

    submitted_at = payload.submitted_at or datetime.utcnow()
    try:
        record = repository.submit_feedback(
            category=payload.category,
            message=payload.message,
            metadata=payload.metadata or {},
            user_id=payload.user_id,
            submitted_at=submitted_at.isoformat(),
        )
    except FeedbackRepositoryError as exc:
        raise HTTPException(  # pragma: no cover - error path
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from exc

    return FeedbackResponse(
        status=str(record.get("status", "received")),
        id=record.get("id"),
    )
