"""Utilities to map instrument responses onto ontology-aware ingestion payloads."""
from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, Optional, Tuple

from backend.mappings.question_mapping import (
    QuestionInfo,
    load_question_registry,
)
from backend.validators.vocabulary_registry import load_registry


class ResponseMappingError(ValueError):
    """Raised when an instrument response cannot be transformed."""


def map_response_to_payload(
    *,
    instrument_id: str,
    question_id: str,
    answer: Any,
    recorded_at: Optional[datetime | str] = None,
    extra_metadata: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Translate a raw response into a canonical ingestion-ready payload."""
    question_registry = load_question_registry()
    vocab_registry = load_registry()

    question = question_registry.get_question(instrument_id, question_id)
    vocab_registry.validate_observation_type(question.observation_type)

    value, units, transform_metadata = _apply_transforms(question, answer)

    observation: Dict[str, Any] = {
        "observation_type": question.observation_type,
        "value": value,
    }
    if question.target.modality:
        observation["choice_modality"] = question.target.modality
    if question.target.domain:
        observation["chance_domain"] = question.target.domain
    if units:
        observation["units"] = units

    metadata: Dict[str, Any] = {}
    if extra_metadata:
        metadata.update(extra_metadata)
    metadata.update(transform_metadata)
    if metadata:
        observation["metadata"] = metadata

    if recorded_at is not None:
        observation["recorded_at"] = _normalise_timestamp(recorded_at)

    payload: Dict[str, Any] = {"observation": observation}

    target_type = question.target.type
    target_id = question.target.id

    target_payload = {"type": target_type, "id": target_id}
    if question.target.modality:
        target_payload["modality"] = question.target.modality
    if question.target.domain:
        target_payload["domain"] = question.target.domain
    payload["target"] = target_payload
    if target_type == "choice":
        choice_payload = {"id": target_id}
        if question.target.modality:
            choice_payload["modality"] = question.target.modality
        payload["choice"] = choice_payload
    elif target_type == "chance":
        chance_payload = {"id": target_id}
        if question.target.domain:
            chance_payload["domain"] = question.target.domain
        payload["chance"] = chance_payload
    else:
        raise ResponseMappingError(f"Unsupported target type '{target_type}'")

    return payload


def _apply_transforms(question: QuestionInfo, answer: Any) -> Tuple[Any, Optional[str], Dict[str, Any]]:
    transforms = question.transforms or {}
    response_type = question.response_type

    if response_type.startswith("likert"):
        mapping = transforms.get("score_mapping") or {}
        key = str(answer)
        if key not in mapping:
            raise ResponseMappingError(
                f"Answer '{answer}' not present in score mapping for question '{question}'"
            )
        score = mapping[key]
        metadata = {"score": score}
        if transforms.get("store_raw"):
            metadata["raw_value"] = answer
        return score, None, metadata

    if response_type == "multiple_choice":
        option_scores = transforms.get("option_scores") or {}
        option_key = str(answer)
        if option_key not in option_scores:
            raise ResponseMappingError(
                f"Answer '{answer}' not present in option scores for question '{question}'"
            )
        score = option_scores[option_key]
        metadata = {"selected_option": option_key, "score": score}
        return score, None, metadata

    if response_type == "numeric":
        try:
            numeric_value = float(answer)
        except (TypeError, ValueError) as exc:
            raise ResponseMappingError(f"Expected numeric answer, received '{answer}'") from exc

        conversion_factor = transforms.get("conversion_factor")
        units = transforms.get("output_unit") or transforms.get("input_unit")
        metadata: Dict[str, Any] = {}
        if conversion_factor is not None:
            numeric_value = numeric_value * float(conversion_factor)
            metadata["conversion_factor"] = conversion_factor
            if transforms.get("input_unit"):
                metadata["input_unit"] = transforms.get("input_unit")
        if transforms.get("store_raw"):
            metadata["raw_value"] = answer

        return numeric_value, units, metadata

    if response_type == "free_text":
        metadata = {
            "raw_text": str(answer),
        }
        metadata.update(transforms)
        return str(answer), None, metadata

    raise ResponseMappingError(f"Unsupported response type '{response_type}'")


def _normalise_timestamp(value: datetime | str) -> str:
    if isinstance(value, datetime):
        return value.isoformat()
    # assume ISO 8601 strings and pass through
    if not isinstance(value, str):
        raise ResponseMappingError(f"Unsupported timestamp value {value!r}")
    return value
