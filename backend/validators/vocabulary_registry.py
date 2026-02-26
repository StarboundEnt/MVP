"""Vocabulary registry loader and helpers for Complexity Profile ingestion guardrails."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Set


class VocabularyError(ValueError):
    """Raised when a payload contains values outside the approved vocabularies."""


@dataclass(frozen=True)
class VocabularyRegistry:
    choice_modalities: Set[str] = field(default_factory=set)
    chance_domains: Set[str] = field(default_factory=set)
    observation_types: Set[str] = field(default_factory=set)
    metric_types: Set[str] = field(default_factory=set)
    effort_levels: Set[str] = field(default_factory=set)
    facet_types: Set[str] = field(default_factory=set)
    metadata: Dict[str, str] = field(default_factory=dict)

    @classmethod
    def from_file(cls, path: Path | str) -> "VocabularyRegistry":
        """Load registry data from a JSON file."""
        registry_path = Path(path)
        if not registry_path.exists():
            raise FileNotFoundError(f"Vocabulary registry not found at {registry_path}")

        with registry_path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)

        return cls(
            choice_modalities=set(data.get("choice_modalities", [])),
            chance_domains=set(data.get("chance_domains", [])),
            observation_types=set(data.get("observation_types", [])),
            metric_types=set(data.get("metric_types", [])),
            effort_levels=set(data.get("effort_levels", [])),
            facet_types=set(data.get("facet_types", [])),
            metadata=data.get("metadata", {}),
        )

    # --- Primitive validators -------------------------------------------------
    def _require(self, value: Optional[object], allowed: Set[str], field_name: str) -> None:
        if value is None:
            raise VocabularyError(f"Missing value for {field_name}")
        candidate = value if isinstance(value, str) else str(value)
        if candidate not in allowed:
            raise VocabularyError(
                f"Unexpected {field_name} '{candidate}'. Allowed values: {sorted(allowed)}"
            )

    def validate_choice_modality(self, modality: str) -> None:
        self._require(modality, self.choice_modalities, "choice modality")

    def validate_chance_domain(self, domain: str) -> None:
        self._require(domain, self.chance_domains, "chance domain")

    def validate_observation_type(self, observation_type: str) -> None:
        self._require(observation_type, self.observation_types, "observation type")

    def validate_metric_type(self, metric_type: str) -> None:
        self._require(metric_type, self.metric_types, "metric type")

    def validate_effort_level(self, effort_level: str) -> None:
        self._require(effort_level, self.effort_levels, "effort level")

    def validate_facet_type(self, facet_type: str) -> None:
        self._require(facet_type, self.facet_types, "facet type")

    # --- Payload validators ---------------------------------------------------
    def validate_choice_payload(self, payload: Dict[str, object]) -> None:
        """Validate minimal fields for a choice ingestion payload."""
        self.validate_choice_modality(payload.get("modality"))

    def validate_chance_payload(self, payload: Dict[str, object]) -> None:
        self.validate_chance_domain(payload.get("domain"))

    def validate_observation_payload(self, payload: Dict[str, object]) -> None:
        errors: List[str] = []
        try:
            self.validate_observation_type(payload.get("observation_type"))
        except VocabularyError as exc:
            errors.append(str(exc))

        choice_modality = payload.get("choice_modality")
        if choice_modality is not None:
            try:
                self.validate_choice_modality(choice_modality)
            except VocabularyError as exc:
                errors.append(str(exc))

        chance_domain = payload.get("chance_domain")
        if chance_domain is not None:
            try:
                self.validate_chance_domain(chance_domain)
            except VocabularyError as exc:
                errors.append(str(exc))

        if errors:
            raise VocabularyError("; ".join(errors))

    def validate_metric_payload(self, payload: Dict[str, object]) -> None:
        self.validate_metric_type(payload.get("metric_type"))

    # --- Convenience methods --------------------------------------------------
    def validate(self, *, choice: Optional[Dict[str, object]] = None,
                 chance: Optional[Dict[str, object]] = None,
                 observation: Optional[Dict[str, object]] = None,
                 metric: Optional[Dict[str, object]] = None,
                 facet: Optional[Dict[str, object]] = None,
                 intervention: Optional[Dict[str, object]] = None) -> None:
        if choice:
            self.validate_choice_payload(choice)
        if chance:
            self.validate_chance_payload(chance)
        if observation:
            self.validate_observation_payload(observation)
        if metric:
            self.validate_metric_payload(metric)
        if facet:
            self.validate_facet_type(facet.get("facet_type"))
        if intervention:
            effort = intervention.get("effort_level")
            if effort is not None:
                self.validate_effort_level(effort)

    # --- Reporting utilities --------------------------------------------------
    def summary(self) -> Dict[str, Sequence[str]]:
        return {
            "choice_modalities": sorted(self.choice_modalities),
            "chance_domains": sorted(self.chance_domains),
            "observation_types": sorted(self.observation_types),
            "metric_types": sorted(self.metric_types),
            "effort_levels": sorted(self.effort_levels),
            "facet_types": sorted(self.facet_types),
        }


_registry_cache: Optional[VocabularyRegistry] = None


def load_registry(path: Path | str = Path(__file__).resolve().parents[1] / "config" / "graph_vocab.json") -> VocabularyRegistry:
    """Load the global registry. Results are cached for reuse within a process."""
    global _registry_cache
    if _registry_cache is None:
        _registry_cache = VocabularyRegistry.from_file(path)
    return _registry_cache


def validate_payload(payload: Dict[str, Dict[str, object]]) -> None:
    """Validate an ingestion payload with nested entities.

    Payload example:
        {
            "choice": {"modality": "sleep"},
            "observation": {"observation_type": "self_report", "choice_modality": "sleep"}
        }
    """
    registry = load_registry()
    registry.validate(
        choice=payload.get("choice"),
        chance=payload.get("chance"),
        observation=payload.get("observation"),
        metric=payload.get("metric"),
        facet=payload.get("facet"),
        intervention=payload.get("intervention"),
    )


def validate_many(payloads: Iterable[Dict[str, Dict[str, object]]]) -> List[Dict[str, object]]:
    """Validate a list of payloads, returning details about any failures."""
    results: List[Dict[str, object]] = []
    registry = load_registry()

    for payload in payloads:
        try:
            registry.validate(
                choice=payload.get("choice"),
                chance=payload.get("chance"),
                observation=payload.get("observation"),
                metric=payload.get("metric"),
                facet=payload.get("facet"),
                intervention=payload.get("intervention"),
            )
            results.append({"payload": payload, "status": "ok"})
        except VocabularyError as exc:
            results.append({"payload": payload, "status": "error", "reason": str(exc)})

    return results
