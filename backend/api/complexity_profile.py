"""Complexity Profile API service and FastAPI integration."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Protocol


class ComplexityProfileNotFoundError(KeyError):
    """Raised when no complexity profile could be found for a user."""


class ComplexityProfileStore(Protocol):
    """Protocol describing data access for complexity profiles."""

    def fetch_complexity_profile(
        self, *, user_id: str, as_of: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:  # pragma: no cover - implemented by callers
        ...


@dataclass
class ComplexityProfileService:
    """High-level service responsible for normalising profile payloads."""

    store: ComplexityProfileStore

    def get_profile(self, user_id: str, *, as_of: Optional[str] = None) -> Dict[str, Any]:
        user_id = (user_id or "").strip()
        if not user_id:
            raise ValueError("user_id is required")

        raw = self.store.fetch_complexity_profile(user_id=user_id, as_of=as_of)
        if raw is None:
            raise ComplexityProfileNotFoundError(user_id)

        return _normalise_profile(raw, default_user_id=user_id)


def _normalise_profile(raw: Dict[str, Any], *, default_user_id: str) -> Dict[str, Any]:
    """Ensure the complexity profile response has predictable, clean structure."""
    user_info = dict(raw.get("user") or {})
    if not user_info.get("id"):
        user_info["id"] = default_user_id

    profile_metric = raw.get("profile_metric")
    if isinstance(profile_metric, list):
        profile_metric = profile_metric[0] if profile_metric else None

    normalised: Dict[str, Any] = {
        "user": user_info,
        "profile_metric": profile_metric or None,
        "choices": _clean_items(raw.get("choices"), id_key="id"),
        "constraints": _clean_items(raw.get("constraints"), id_key="id"),
        "recommended_resources": _clean_items(
            raw.get("recommended_resources"), id_key="intervention_id"
        ),
    }

    return normalised


def _clean_items(items: Any, *, id_key: str) -> List[Dict[str, Any]]:
    if not items:
        return []

    clean: List[Dict[str, Any]] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        identifier = item.get(id_key)
        if not identifier:
            continue
        clean.append(dict(item))
    return clean


_service: Optional[ComplexityProfileService] = None


def configure_service(service: ComplexityProfileService) -> None:
    """Configure the module-level service used by the FastAPI router."""
    global _service
    _service = service


def get_service() -> ComplexityProfileService:
    if _service is None:
        raise RuntimeError("ComplexityProfileService has not been configured")
    return _service


try:  # pragma: no cover - optional FastAPI dependency
    from fastapi import APIRouter, HTTPException, Path

    router = APIRouter()

    @router.get("/users/{user_id}/complexity-profile", tags=["complexity"])
    def get_complexity_profile(user_id: str = Path(..., min_length=1)) -> Dict[str, Any]:
        service = get_service()
        try:
            return service.get_profile(user_id=user_id)
        except ComplexityProfileNotFoundError as exc:  # pragma: no cover - simple translation
            raise HTTPException(status_code=404, detail=f"No profile for user '{exc.args[0]}'") from exc

except ImportError:  # pragma: no cover - FastAPI not required in tests
    router = None
