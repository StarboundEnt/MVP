"""Runtime configuration helpers for backend services."""
from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Optional


def _env(name: str, default: Optional[str] = None) -> Optional[str]:
    value = os.getenv(name)
    if value is None or value.strip() == "":
        return default
    return value.strip()


@dataclass
class ComplexityApiSettings:
    """Configuration for communicating with the Complexity Profile backend."""

    base_url: str = _env("COMPLEXITY_API_BASE_URL", "http://localhost:8080")
    ingest_path: str = _env("COMPLEXITY_API_INGEST_PATH", "/ingest")
    batch_path: Optional[str] = _env("COMPLEXITY_API_BATCH_PATH", None)
    profile_path_template: str = _env(
        "COMPLEXITY_API_PROFILE_PATH", "/users/{id}/complexity-profile"
    )
    api_key: Optional[str] = _env("COMPLEXITY_API_KEY")
    timeout_seconds: float = float(_env("COMPLEXITY_API_TIMEOUT", "10"))

    def resolved_batch_path(self) -> str:
        if self.batch_path:
            return self.batch_path
        trimmed = self.ingest_path.rstrip("/")
        return f"{trimmed}/batch"


@dataclass
class SupabaseSettings:
    """Configuration for accessing Supabase REST endpoints."""

    url: Optional[str] = _env("SUPABASE_URL")
    service_key: Optional[str] = _env("SUPABASE_SERVICE_ROLE_KEY") or _env("SUPABASE_SERVICE_KEY")
    schema: str = _env("SUPABASE_SCHEMA", "app_public") or "app_public"
    feedback_table: str = _env("SUPABASE_FEEDBACK_TABLE", "feedback") or "feedback"
