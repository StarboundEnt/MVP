"""Chat history router — stores Q&A history per user. AI responses handled on the client."""
from __future__ import annotations

import json
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

SUGGESTED_QUESTIONS = [
    "What free health services are available near me?",
    "How can I access mental health support?",
    "What is the Medicare Safety Net?",
    "How do I get a health care plan from my GP?",
    "What telehealth options are available?",
    "How can I reduce out-of-pocket medical costs?",
    "What support is available for chronic conditions?",
    "How do I access bulk billing?",
]


class ChatStore:
    """JSON-backed store for chat history."""

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

    def get_history(self, user_id: int, limit: int = 50) -> List[Dict[str, Any]]:
        with self._lock:
            history = [r for r in self._load() if r.get("user_id") == user_id]
        return sorted(history, key=lambda r: r.get("asked_at", ""), reverse=True)[:limit]

    def record(self, user_id: int, question: str, response: str) -> Dict[str, Any]:
        with self._lock:
            records = self._load()
            entry: Dict[str, Any] = {
                "user_id": user_id,
                "question": question,
                "response": response,
                "asked_at": _iso_now(),
            }
            records.append(entry)
            # Keep last 200 entries per user
            user_records = [r for r in records if r.get("user_id") == user_id]
            if len(user_records) > 200:
                oldest_to_remove = user_records[:-200]
                records = [r for r in records if r not in oldest_to_remove]
            self._save(records)
            return entry


def _iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


_store: Optional[ChatStore] = None


def configure_store(store: ChatStore) -> None:
    global _store
    _store = store


def get_store() -> ChatStore:
    if _store is None:
        raise RuntimeError("ChatStore has not been configured")
    return _store


try:
    from fastapi import APIRouter, Body, Query, status
    from pydantic import BaseModel

    router = APIRouter(prefix="/api/v1/chat", tags=["chat"])

    class AskRequest(BaseModel):
        query: str
        include_context: bool = True
        response: Optional[str] = None

    @router.post("/ask")
    def ask_question(
        user_id: int = Query(...),
        request: AskRequest = Body(...),
    ) -> Dict[str, Any]:
        response_text = request.response or ""
        entry = get_store().record(user_id, request.query, response_text)
        return {"stored": True, "asked_at": entry["asked_at"]}

    @router.get("/history/user/{user_id}")
    def get_chat_history(user_id: int, limit: int = Query(default=50, ge=1, le=200)) -> List[Dict[str, Any]]:
        return get_store().get_history(user_id, limit)

    @router.get("/suggestions/user/{user_id}")
    def get_suggested_questions(user_id: int) -> List[str]:
        return SUGGESTED_QUESTIONS

except ImportError:
    router = None
