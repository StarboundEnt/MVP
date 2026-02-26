"""Send a synthetic journaling response through the ingestion service."""
from __future__ import annotations

import argparse
from datetime import datetime
from typing import Any, Dict

from backend.ingestion.service import IngestionService, IngestionResult
from backend.ingestion.question_mapper import map_response_to_payload
from backend.validators.vocabulary_registry import validate_payload


class EchoGraphWriter:
    """Graph writer that just prints payload instead of calling real backend."""

    def write(self, payload: Dict[str, Any]) -> None:  # pragma: no cover - CLI helper
        print("== payload accepted ==")
        print(payload)

    def write_many(self, payloads):  # pragma: no cover
        for payload in payloads:
            self.write(payload)


def run_simulation(instrument_id: str, question_id: str, answer: str) -> IngestionResult:
    writer = EchoGraphWriter()
    service = IngestionService(writer)

    try:
        # Use service pipeline to map and validate payload
        result = service.ingest_question_response(
            instrument_id=instrument_id,
            question_id=question_id,
            answer=answer,
            recorded_at=datetime.utcnow(),
        )
    except Exception as exc:  # pragma: no cover - CLI safety
        print(f"Error during ingestion: {exc}")
        raise

    return result


def main() -> None:  # pragma: no cover - CLI entrypoint
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("instrument_id", help="Instrument identifier, e.g., onboarding_survey_v1")
    parser.add_argument("question_id", help="Question identifier, e.g., q_sleep_schedule")
    parser.add_argument("answer", help="Answer text/value (string)")
    args = parser.parse_args()

    result = run_simulation(args.instrument_id, args.question_id, args.answer)
    print(f"Status: {result.status}")
    if result.reason:
        print(f"Reason: {result.reason}")


if __name__ == "__main__":
    main()
