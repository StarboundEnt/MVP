"""Health utilities exposing active vocabulary and mapping versions."""
from __future__ import annotations

from typing import Any, Dict

from backend.mappings.question_mapping import load_question_registry
from backend.validators.vocabulary_registry import load_registry


def build_health_payload() -> Dict[str, Any]:
    """Return a dictionary suitable for use in a /health endpoint."""
    vocab = load_registry()
    questions = load_question_registry()

    return {
        "status": "ok",
        "vocabulary": {
            "version": vocab.metadata.get("version"),
            "summary": vocab.summary(),
        },
        "question_mapping": {
            "version": questions.version,
            "instrument_count": len(questions.instruments()),
        },
    }


try:  # pragma: no cover - optional dependency
    from fastapi import APIRouter

    router = APIRouter()

    @router.get("/health", tags=["health"])  # type: ignore[misc]
    def health_endpoint() -> Dict[str, Any]:
        """FastAPI-ready health endpoint."""
        return build_health_payload()

except ImportError:  # pragma: no cover - FastAPI not required for core logic
    router = None
