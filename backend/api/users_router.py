"""Users management router — device-based identity, no passwords."""
from __future__ import annotations

import json
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional


class UsersStore:
    """Simple JSON-backed store for user records."""

    def __init__(self, path: Path) -> None:
        self._path = path
        self._lock = threading.Lock()

    def _load(self) -> List[Dict[str, Any]]:
        if not self._path.exists():
            return []
        with self._path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        return data if isinstance(data, list) else []

    def _save(self, users: List[Dict[str, Any]]) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._path.write_text(json.dumps(users, indent=2), encoding="utf-8")

    def get_all(self) -> List[Dict[str, Any]]:
        with self._lock:
            return self._load()

    def get_by_id(self, user_id: int) -> Optional[Dict[str, Any]]:
        with self._lock:
            for u in self._load():
                if u.get("id") == user_id:
                    return u
        return None

    def get_by_username(self, username: str) -> Optional[Dict[str, Any]]:
        with self._lock:
            for u in self._load():
                if u.get("username") == username:
                    return u
        return None

    def create(self, username: str, display_name: str, complexity_profile: str) -> Dict[str, Any]:
        with self._lock:
            users = self._load()
            new_id = max((u.get("id", 0) for u in users), default=0) + 1
            user: Dict[str, Any] = {
                "id": new_id,
                "username": username,
                "display_name": display_name,
                "complexity_profile": complexity_profile,
                "onboarding_complete": False,
                "notifications_enabled": True,
                "notification_time": "09:00",
                "created_at": _iso_now(),
                "updated_at": _iso_now(),
            }
            users.append(user)
            self._save(users)
            return user

    def update(self, user_id: int, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        with self._lock:
            users = self._load()
            for i, u in enumerate(users):
                if u.get("id") == user_id:
                    allowed = {
                        "display_name", "complexity_profile",
                        "notifications_enabled", "notification_time", "onboarding_complete",
                    }
                    for key, value in updates.items():
                        if key in allowed:
                            users[i][key] = value
                    users[i]["updated_at"] = _iso_now()
                    self._save(users)
                    return users[i]
        return None


def _iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


_store: Optional[UsersStore] = None


def configure_store(store: UsersStore) -> None:
    global _store
    _store = store


def get_store() -> UsersStore:
    if _store is None:
        raise RuntimeError("UsersStore has not been configured")
    return _store


try:
    from fastapi import APIRouter, Body, HTTPException, status
    from pydantic import BaseModel

    router = APIRouter(prefix="/api/v1/users", tags=["users"])

    class CreateUserRequest(BaseModel):
        username: str
        display_name: str
        complexity_profile: str = "stable"

    class UpdateUserRequest(BaseModel):
        display_name: Optional[str] = None
        complexity_profile: Optional[str] = None
        notifications_enabled: Optional[bool] = None
        notification_time: Optional[str] = None

    @router.post("/", status_code=status.HTTP_201_CREATED)
    def create_user(request: CreateUserRequest = Body(...)) -> Dict[str, Any]:
        store = get_store()
        existing = store.get_by_username(request.username)
        if existing:
            return existing
        return store.create(
            username=request.username,
            display_name=request.display_name,
            complexity_profile=request.complexity_profile,
        )

    @router.get("/username/{username}")
    def get_user_by_username(username: str) -> Dict[str, Any]:
        store = get_store()
        user = store.get_by_username(username)
        if user is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        return user

    @router.get("/{user_id}")
    def get_user(user_id: int) -> Dict[str, Any]:
        store = get_store()
        user = store.get_by_id(user_id)
        if user is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        return user

    @router.put("/{user_id}")
    def update_user(user_id: int, request: UpdateUserRequest = Body(...)) -> Dict[str, Any]:
        store = get_store()
        updates = {k: v for k, v in request.dict().items() if v is not None}
        user = store.update(user_id, updates)
        if user is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        return user

    @router.post("/{user_id}/onboarding-complete")
    def complete_onboarding(user_id: int) -> Dict[str, Any]:
        store = get_store()
        user = store.update(user_id, {"onboarding_complete": True})
        if user is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        return user

except ImportError:
    router = None
