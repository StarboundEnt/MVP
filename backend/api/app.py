"""FastAPI application factory configured with remote complexity backend."""
from __future__ import annotations

import os
from pathlib import Path
from typing import Any, Dict, Iterable

from backend.api.complexity_profile import (
    ComplexityProfileService,
    configure_service,
    router as complexity_router,
)
from backend.api.local_user_profile_store import LocalUserProfileStore
from backend.api.feedback_router import (
    configure_repository as configure_feedback_repository,
    router as feedback_router,
)
from backend.api.ingestion_router import (
    configure_service as configure_ingestion_service,
    router as ingestion_router,
)
from backend.api.chat_router import (
    ChatStore,
    configure_store as configure_chat_store,
    router as chat_router,
)
from backend.api.habits_router import (
    HabitsStore,
    configure_store as configure_habits_store,
    router as habits_router,
)
from backend.api.health import router as health_router
from backend.api.local_profile_store import LocalComplexityStore
from backend.api.nudges_router import (
    NudgesStore,
    configure_store as configure_nudges_store,
    router as nudges_router,
)
from backend.api.remote_profile_store import RemoteComplexityStore
from backend.api.user_profile import (
    UserProfileService,
    configure_service as configure_user_profile_service,
    router as user_profile_router,
)
from backend.api.users_router import (
    UsersStore,
    configure_store as configure_users_store,
    router as users_router,
)
from backend.config.settings import ComplexityApiSettings, SupabaseSettings
from backend.ingestion.http_writer import HttpGraphWriter
from backend.ingestion.service import IngestionService
from backend.services.feedback_repository import (
    FeedbackRepositoryError,
    SupabaseFeedbackRepository,
)

try:  # pragma: no cover - FastAPI optional for tests
    from fastapi import FastAPI
    from fastapi.middleware.cors import CORSMiddleware
except ImportError:  # pragma: no cover
    FastAPI = None
    CORSMiddleware = None


def create_app() -> "FastAPI":
    if FastAPI is None:
        raise RuntimeError("FastAPI is not installed; install it to run the API server")

    app = FastAPI(title="Starbound Health Navigator API", version="mvp-1")

    # CORS — lets the Flutter web app call this API from the browser.
    # Set ALLOWED_ORIGINS env var to a comma-separated list of allowed domains
    # e.g. "https://starbound.netlify.app" to restrict in production.
    raw_origins = os.getenv("ALLOWED_ORIGINS", "*")
    if raw_origins.strip() == "*":
        allow_origins = ["*"]
        allow_credentials = False
    else:
        allow_origins = [o.strip() for o in raw_origins.split(",") if o.strip()]
        allow_credentials = True

    if CORSMiddleware is not None:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=allow_origins,
            allow_credentials=allow_credentials,
            allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
            allow_headers=["*"],
        )

    settings = ComplexityApiSettings()
    supabase_settings = SupabaseSettings()

    use_local_store = os.getenv("COMPLEXITY_API_USE_LOCAL_STORE", "0") == "1"

    if use_local_store:
        data_path = (
            Path(__file__).resolve().parents[1] / "data" / "complexity_profiles.json"
        )
        store = LocalComplexityStore(path=data_path)
        graph_writer = _LocalEchoGraphWriter()
    else:
        store = RemoteComplexityStore(
            base_url=settings.base_url,
            profile_path_template=settings.profile_path_template,
            api_key=settings.api_key,
            timeout_seconds=settings.timeout_seconds,
        )
        graph_writer = HttpGraphWriter(
            base_url=settings.base_url,
            ingest_path=settings.ingest_path,
            batch_path=settings.resolved_batch_path(),
            api_key=settings.api_key,
            timeout_seconds=settings.timeout_seconds,
        )

    service = ComplexityProfileService(store=store)
    configure_service(service)

    user_profile_path = Path(__file__).resolve().parents[1] / "data" / "user_profiles.json"
    user_profile_store = LocalUserProfileStore(path=user_profile_path)
    user_profile_service = UserProfileService(store=user_profile_store)
    configure_user_profile_service(user_profile_service)

    data_dir = Path(__file__).resolve().parents[1] / "data"
    configure_users_store(UsersStore(path=data_dir / "users.json"))
    configure_habits_store(HabitsStore(path=data_dir / "habits.json"))
    configure_nudges_store(NudgesStore(path=data_dir / "nudges.json"))
    configure_chat_store(ChatStore(path=data_dir / "chats.json"))

    ingestion_service = IngestionService(graph_writer)
    configure_ingestion_service(ingestion_service)

    if supabase_settings.url and supabase_settings.service_key:
        feedback_repository = SupabaseFeedbackRepository(settings=supabase_settings)
    else:
        feedback_repository = _NoopFeedbackRepository()

    configure_feedback_repository(feedback_repository)

    if health_router is not None:
        app.include_router(health_router)
    if complexity_router is not None:
        app.include_router(complexity_router)
    if user_profile_router is not None:
        app.include_router(user_profile_router)
    if users_router is not None:
        app.include_router(users_router)
    if habits_router is not None:
        app.include_router(habits_router)
    if nudges_router is not None:
        app.include_router(nudges_router)
    if chat_router is not None:
        app.include_router(chat_router)
    if ingestion_router is not None:
        app.include_router(ingestion_router)
    if feedback_router is not None:
        app.include_router(feedback_router)

    return app


class _LocalEchoGraphWriter:
    """Development graph writer that logs payloads instead of forwarding them."""

    def write(self, payload: Dict[str, Any]) -> None:  # pragma: no cover - dev helper
        print("~ Local graph write (single) ~", payload)

    def write_many(self, payloads: Iterable[Dict[str, Any]]) -> None:  # pragma: no cover
        for payload in payloads:
            self.write(payload)


class _NoopFeedbackRepository:
    def submit_feedback(self, **_: Any) -> Dict[str, Any]:  # pragma: no cover - simple guard
        raise FeedbackRepositoryError("Supabase feedback repository not configured")
