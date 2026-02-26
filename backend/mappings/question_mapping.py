"""Loader and helpers for question-to-ontology mappings."""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional


class QuestionMappingError(KeyError):
    """Raised when a question mapping cannot be found."""


@dataclass(frozen=True)
class TargetInfo:
    type: str
    id: str
    modality: Optional[str] = None
    domain: Optional[str] = None


@dataclass(frozen=True)
class QuestionInfo:
    prompt: str
    response_type: str
    observation_type: str
    target: TargetInfo
    transforms: Dict[str, object]


class QuestionMappingRegistry:
    """Registry for instrument question mappings."""

    def __init__(self, *, version: str, instruments: Dict[str, Dict[str, QuestionInfo]]) -> None:
        self.version = version
        self._instruments = instruments

    @classmethod
    def from_file(cls, path: Path | str) -> "QuestionMappingRegistry":
        mapping_path = Path(path)
        if not mapping_path.exists():
            raise FileNotFoundError(f"Question mapping config not found at {mapping_path}")

        with mapping_path.open("r", encoding="utf-8") as fh:
            raw_data = json.load(fh)

        version = raw_data.get("version", "unknown")
        instruments: Dict[str, Dict[str, QuestionInfo]] = {}

        for instrument_id, questions in raw_data.get("instruments", {}).items():
            question_map: Dict[str, QuestionInfo] = {}
            for question_id, entry in questions.items():
                target_data = entry.get("target") or {}
                question_map[question_id] = QuestionInfo(
                    prompt=entry.get("prompt", ""),
                    response_type=entry.get("response_type", "unknown"),
                    observation_type=entry.get("observation_type", "survey"),
                    target=TargetInfo(
                        type=target_data.get("type", "unknown"),
                        id=target_data.get("id", ""),
                        modality=target_data.get("modality"),
                        domain=target_data.get("domain"),
                    ),
                    transforms=entry.get("transforms", {}),
                )
            instruments[instrument_id] = question_map

        return cls(version=version, instruments=instruments)

    def get_question(self, instrument_id: str, question_id: str) -> QuestionInfo:
        instrument = self._instruments.get(instrument_id)
        if instrument is None:
            raise QuestionMappingError(f"Unknown instrument '{instrument_id}'")
        question = instrument.get(question_id)
        if question is None:
            raise QuestionMappingError(
                f"Unknown question '{question_id}' for instrument '{instrument_id}'"
            )
        return question

    def get_target(self, instrument_id: str, question_id: str) -> TargetInfo:
        return self.get_question(instrument_id, question_id).target

    def instruments(self) -> Dict[str, Dict[str, QuestionInfo]]:
        return self._instruments


_registry_cache: Optional[QuestionMappingRegistry] = None


def load_question_registry(path: Path | str = Path(__file__).resolve().parents[1] / "config" / "question_mapping.json") -> QuestionMappingRegistry:
    global _registry_cache
    if _registry_cache is None:
        _registry_cache = QuestionMappingRegistry.from_file(path)
    return _registry_cache
