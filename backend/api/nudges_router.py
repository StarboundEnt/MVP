"""Nudges router — nudge banking and personalised recommendations."""
from __future__ import annotations

import json
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

DEFAULT_NUDGES = [
    {"id": 1, "theme": "hydration", "title": "Drink a glass of water", "description": "Small sips throughout the day add up.", "energy_required": "low", "complexity_profile": "stable"},
    {"id": 2, "theme": "movement", "title": "Take a 5-minute walk", "description": "A short walk can reset your energy.", "energy_required": "low", "complexity_profile": "stable"},
    {"id": 3, "theme": "sleep", "title": "Wind down 30 minutes earlier", "description": "A consistent bedtime improves sleep quality.", "energy_required": "low", "complexity_profile": "trying"},
    {"id": 4, "theme": "nutrition", "title": "Add one vegetable to your next meal", "description": "Incremental changes to nutrition work best.", "energy_required": "low", "complexity_profile": "stable"},
    {"id": 5, "theme": "mood", "title": "Check in with how you're feeling", "description": "Noticing your mood is the first step.", "energy_required": "low", "complexity_profile": "survival"},
    {"id": 6, "theme": "focus", "title": "Try a 2-minute breathing exercise", "description": "Deep breaths calm the nervous system.", "energy_required": "low", "complexity_profile": "overloaded"},
    {"id": 7, "theme": "energy", "title": "Step outside for natural light", "description": "Daylight helps regulate your energy.", "energy_required": "low", "complexity_profile": "trying"},
    {"id": 8, "theme": "hydration", "title": "Keep a water bottle visible", "description": "Visual cues increase water intake.", "energy_required": "low", "complexity_profile": "stable"},
]


class NudgesStore:
    """JSON-backed store for banked nudges."""

    def __init__(self, path: Path) -> None:
        self._path = path
        self._lock = threading.Lock()

    def _load(self) -> List[Dict[str, Any]]:
        if not self._path.exists():
            return []
        with self._path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        return data if isinstance(data, list) else []

    def _save(self, records: List[Dict[str, Any]]) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._path.write_text(json.dumps(records, indent=2), encoding="utf-8")

    def get_banked(self, user_id: int) -> List[Dict[str, Any]]:
        with self._lock:
            return [r for r in self._load() if r.get("user_id") == user_id]

    def bank(self, user_id: int, nudge_id: int) -> Dict[str, Any]:
        nudge = next((n for n in DEFAULT_NUDGES if n["id"] == nudge_id), None)
        if nudge is None:
            raise ValueError(f"Nudge {nudge_id} not found")
        with self._lock:
            records = self._load()
            already = any(
                r.get("user_id") == user_id and r.get("nudge_id") == nudge_id
                for r in records
            )
            if not already:
                records.append({
                    "user_id": user_id,
                    "nudge_id": nudge_id,
                    "nudge": nudge,
                    "banked_at": _iso_now(),
                })
                self._save(records)
        return nudge

    def get_current(self, user_id: int) -> Optional[Dict[str, Any]]:
        banked = self.get_banked(user_id)
        return banked[-1]["nudge"] if banked else None


def _iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


_store: Optional[NudgesStore] = None


def configure_store(store: NudgesStore) -> None:
    global _store
    _store = store


def get_store() -> NudgesStore:
    if _store is None:
        raise RuntimeError("NudgesStore has not been configured")
    return _store


try:
    from fastapi import APIRouter, Body, HTTPException, Query, status
    from pydantic import BaseModel

    router = APIRouter(prefix="/api/v1/nudges", tags=["nudges"])

    class BankNudgeRequest(BaseModel):
        user_id: int
        nudge_id: int

    class RecommendRequest(BaseModel):
        user_id: int
        current_habits: Dict[str, Optional[str]]
        complexity_profile: str = "stable"

    @router.get("/")
    def get_nudges(
        theme: Optional[str] = Query(default=None),
        complexity_profile: Optional[str] = Query(default=None),
        energy_required: Optional[str] = Query(default=None),
    ) -> List[Dict[str, Any]]:
        nudges = DEFAULT_NUDGES
        if theme:
            nudges = [n for n in nudges if n.get("theme") == theme]
        if complexity_profile:
            nudges = [n for n in nudges if n.get("complexity_profile") == complexity_profile]
        if energy_required:
            nudges = [n for n in nudges if n.get("energy_required") == energy_required]
        return nudges

    @router.post("/recommend")
    def get_personalised_recommendation(request: RecommendRequest = Body(...)) -> Dict[str, Any]:
        profile_nudges = [n for n in DEFAULT_NUDGES if n.get("complexity_profile") == request.complexity_profile]
        if not profile_nudges:
            profile_nudges = DEFAULT_NUDGES
        filled_habits = {k for k, v in request.current_habits.items() if v}
        for nudge in profile_nudges:
            if nudge["theme"] not in filled_habits:
                return nudge
        return profile_nudges[0]

    @router.get("/user/{user_id}/current")
    def get_current_nudge(user_id: int) -> Dict[str, Any]:
        nudge = get_store().get_current(user_id)
        if nudge is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No banked nudge found")
        return nudge

    @router.post("/bank")
    def bank_nudge(request: BankNudgeRequest = Body(...)) -> Dict[str, Any]:
        try:
            return get_store().bank(request.user_id, request.nudge_id)
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))

    @router.get("/bank/user/{user_id}")
    def get_banked_nudges(user_id: int) -> List[Dict[str, Any]]:
        return get_store().get_banked(user_id)

except ImportError:
    router = None
