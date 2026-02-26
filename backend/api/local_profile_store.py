"""Local JSON-backed store for complexity profile data."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, Optional


class LocalComplexityStore:
    """Simple repository loading complexity profiles from a JSON file."""

    def __init__(self, path: Path | str) -> None:
        self._path = Path(path)
        self._cache: Dict[str, Dict[str, Any]] | None = None

    def _load(self) -> Dict[str, Dict[str, Any]]:
        if self._cache is None:
            if not self._path.exists():
                raise FileNotFoundError(f"Complexity profiles file not found at {self._path}")
            with self._path.open("r", encoding="utf-8") as fh:
                data = json.load(fh)
            if not isinstance(data, dict):
                raise ValueError("Complexity profiles file must contain an object keyed by user id")
            self._cache = {str(key): value for key, value in data.items()}
        return self._cache

    def fetch_complexity_profile(
        self, *, user_id: str, as_of: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        data = self._load()
        return data.get(user_id)

    def upsert(self, user_id: str, payload: Dict[str, Any]) -> None:
        """Persist a complexity profile for local testing."""
        data = self._load()
        data[user_id] = payload
        self._path.write_text(json.dumps(data, indent=2), encoding="utf-8")
