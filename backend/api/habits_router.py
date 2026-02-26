"""Habits tracking router — daily habit entries and analytics."""
from __future__ import annotations

import json
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

HABIT_CATEGORIES = [
    {"id": 1, "key": "hydration", "label": "Hydration", "type": "choice"},
    {"id": 2, "key": "nutrition", "label": "Nutrition", "type": "choice"},
    {"id": 3, "key": "focus", "label": "Focus", "type": "choice"},
    {"id": 4, "key": "sleep", "label": "Sleep", "type": "choice"},
    {"id": 5, "key": "movement", "label": "Movement", "type": "choice"},
    {"id": 6, "key": "energy", "label": "Energy", "type": "choice"},
    {"id": 7, "key": "mood", "label": "Mood", "type": "choice"},
    {"id": 8, "key": "outdoor", "label": "Outdoor", "type": "choice"},
    {"id": 9, "key": "safety", "label": "Safety", "type": "chance"},
    {"id": 10, "key": "meals", "label": "Meals", "type": "chance"},
    {"id": 11, "key": "sleepIssues", "label": "Sleep Issues", "type": "chance"},
    {"id": 12, "key": "financial", "label": "Financial", "type": "chance"},
]


class HabitsStore:
    """JSON-backed store for habit entries."""

    def __init__(self, path: Path) -> None:
        self._path = path
        self._lock = threading.Lock()

    def _load(self) -> List[Dict[str, Any]]:
        if not self._path.exists():
            return []
        with self._path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        return data if isinstance(data, list) else []

    def _save(self, entries: List[Dict[str, Any]]) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._path.write_text(json.dumps(entries, indent=2), encoding="utf-8")

    def get_user_entries(self, user_id: int) -> List[Dict[str, Any]]:
        with self._lock:
            return [e for e in self._load() if e.get("user_id") == user_id]

    def upsert_daily(self, user_id: int, habits: Dict[str, Optional[str]]) -> Dict[str, Any]:
        today = datetime.now(timezone.utc).date().isoformat()
        with self._lock:
            entries = self._load()
            for i, e in enumerate(entries):
                if e.get("user_id") == user_id and e.get("date") == today:
                    entries[i]["habits"].update(habits)
                    entries[i]["updated_at"] = _iso_now()
                    self._save(entries)
                    return entries[i]
            new_entry: Dict[str, Any] = {
                "user_id": user_id,
                "date": today,
                "habits": habits,
                "created_at": _iso_now(),
                "updated_at": _iso_now(),
            }
            entries.append(new_entry)
            self._save(entries)
            return new_entry

    def get_streaks(self, user_id: int) -> Dict[str, Any]:
        entries = self.get_user_entries(user_id)
        if not entries:
            return {"current_streak": 0, "longest_streak": 0, "total_entries": 0}
        dates = sorted({e["date"] for e in entries}, reverse=True)
        current = 0
        longest = 0
        prev = None
        run = 0
        for d in reversed(dates):
            dt = datetime.fromisoformat(d).date()
            if prev is None or (dt - prev).days == 1:
                run += 1
                longest = max(longest, run)
            else:
                run = 1
            prev = dt
        today = datetime.now(timezone.utc).date()
        if dates and (today - datetime.fromisoformat(dates[0]).date()).days <= 1:
            streak_dates = sorted(dates, reverse=True)
            current = 0
            check = today
            for d in streak_dates:
                if (check - datetime.fromisoformat(d).date()).days <= 1:
                    current += 1
                    check = datetime.fromisoformat(d).date()
                else:
                    break
        return {"current_streak": current, "longest_streak": longest, "total_entries": len(entries)}

    def get_trends(self, user_id: int) -> Dict[str, Any]:
        entries = sorted(self.get_user_entries(user_id), key=lambda e: e["date"])
        last_7 = entries[-7:] if len(entries) >= 7 else entries
        habit_totals: Dict[str, int] = {}
        habit_counts: Dict[str, int] = {}
        for entry in last_7:
            for key, val in entry.get("habits", {}).items():
                if val:
                    habit_counts[key] = habit_counts.get(key, 0) + 1
        completion_rate = len(last_7) / 7.0 if last_7 else 0.0
        return {
            "habit_frequency": habit_counts,
            "completion_rate_7d": round(completion_rate, 2),
            "entries_count": len(entries),
        }


def _iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


_store: Optional[HabitsStore] = None


def configure_store(store: HabitsStore) -> None:
    global _store
    _store = store


def get_store() -> HabitsStore:
    if _store is None:
        raise RuntimeError("HabitsStore has not been configured")
    return _store


try:
    from fastapi import APIRouter, Body, HTTPException, status
    from pydantic import BaseModel

    router = APIRouter(prefix="/api/v1/habits", tags=["habits"])

    class DailyHabitsRequest(BaseModel):
        habits: Dict[str, Optional[str]]

    @router.get("/categories")
    def get_habit_categories() -> List[Dict[str, Any]]:
        return HABIT_CATEGORIES

    @router.get("/entries/user/{user_id}")
    def get_user_habit_entries(user_id: int) -> List[Dict[str, Any]]:
        return get_store().get_user_entries(user_id)

    @router.post("/entries/user/{user_id}/daily")
    def update_daily_habits(user_id: int, request: DailyHabitsRequest = Body(...)) -> Dict[str, Any]:
        return get_store().upsert_daily(user_id, request.habits)

    @router.get("/analytics/user/{user_id}/streaks")
    def get_habit_streaks(user_id: int) -> Dict[str, Any]:
        return get_store().get_streaks(user_id)

    @router.get("/analytics/user/{user_id}/trends")
    def get_habit_trends(user_id: int) -> Dict[str, Any]:
        return get_store().get_trends(user_id)

except ImportError:
    router = None
