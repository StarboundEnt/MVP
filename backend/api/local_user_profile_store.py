"""Local JSON-backed store for user profile payloads."""
from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any, Dict, Optional


class LocalUserProfileStore:
    """Simple repository loading user profiles from a JSON file for development."""

    def __init__(self, path: Path | str) -> None:
        self._path = Path(path)
        self._cache: Dict[str, Dict[str, Any]] | None = None

    def _load(self) -> Dict[str, Dict[str, Any]]:
        if self._cache is None:
            if not self._path.exists():
                raise FileNotFoundError(f"User profiles file not found at {self._path}")
            with self._path.open("r", encoding="utf-8") as fh:
                payload = json.load(fh)
            if not isinstance(payload, dict):
                raise ValueError("User profiles file must contain an object keyed by user id")
            self._cache = {str(key): value for key, value in payload.items()}
        return self._cache

    def fetch_user_profile(self, *, user_id: str) -> Optional[Dict[str, Any]]:
        data = self._load()
        profile = data.get(user_id)
        if profile is None:
            return None
        return copy.deepcopy(profile)

    def save_user_profile(self, *, user_id: str, profile: Dict[str, Any]) -> None:
        data = self._load()
        data[user_id] = copy.deepcopy(profile)
        self._path.write_text(json.dumps(data, indent=2), encoding="utf-8")
