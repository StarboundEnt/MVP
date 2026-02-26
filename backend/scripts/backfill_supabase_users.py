"""Backfill or seed app_public.users via Supabase REST."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, Iterable

from backend.config.settings import SupabaseSettings
from backend.utils.http_client import HttpClient


def load_users(path: Path | None) -> Iterable[Dict[str, Any]]:
    if path is None:
        return [
            {
                "username": "demo-user",
                "display_name": "Demo User",
                "complexity_profile": "stable",
                "onboarding_complete": True,
            }
        ]

    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise ValueError("Input file must contain a list of user objects")
    return data


def upsert_users(users: Iterable[Dict[str, Any]], settings: SupabaseSettings) -> None:
    if not settings.url or not settings.service_key:
        raise RuntimeError("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be configured")

    client = HttpClient()
    url = f"{settings.url.rstrip('/')}/rest/v1/users"
    headers = {
        "apikey": settings.service_key,
        "Authorization": f"Bearer {settings.service_key}",
        "Prefer": "return=representation,resolution=merge-duplicates",
        "Accept-Profile": settings.schema,
        "Content-Profile": settings.schema,
    }

    payload = [
        {
            "username": user["username"],
            "display_name": user.get("display_name", user["username"].title()),
            "complexity_profile": user.get("complexity_profile", "stable"),
            "onboarding_complete": bool(user.get("onboarding_complete", False)),
        }
        for user in users
    ]

    response = client.post(url, headers=headers, json_payload=payload, timeout=15)
    if not 200 <= response.status_code < 300:
        raise RuntimeError(f"Failed to upsert users: {response.text}")


def main() -> None:  # pragma: no cover - CLI entrypoint
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        help="Path to a JSON file containing a list of user objects",
    )
    args = parser.parse_args()

    settings = SupabaseSettings()
    users = load_users(args.input)
    upsert_users(users, settings)


if __name__ == "__main__":  # pragma: no cover
    main()
