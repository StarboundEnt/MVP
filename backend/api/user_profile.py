"""User profile service and FastAPI integration."""
from __future__ import annotations

import copy
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Protocol, Sequence


class UserProfileNotFoundError(KeyError):
    """Raised when a user profile cannot be located."""


class UserProfileStore(Protocol):
    """Protocol describing persistence operations for user profiles."""

    def fetch_user_profile(self, *, user_id: str) -> Optional[Dict[str, Any]]:  # pragma: no cover - implemented by callers
        ...

    def save_user_profile(self, *, user_id: str, profile: Dict[str, Any]) -> None:  # pragma: no cover - implemented by callers
        ...


@dataclass
class UserProfileService:
    """High-level orchestration for profile reads and mutations."""

    store: UserProfileStore

    def get_profile(self, user_id: str) -> Dict[str, Any]:
        user_id = _normalise_user_id(user_id)
        raw = self.store.fetch_user_profile(user_id=user_id)
        if raw is None:
            raise UserProfileNotFoundError(user_id)
        return _normalise_profile(raw, default_user_id=user_id)

    def update_profile(self, user_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        user_id = _normalise_user_id(user_id)
        if not updates:
            raise ValueError("updates payload is required")

        allowed_fields = {"displayName", "personalization"}
        unsupported = sorted(field for field in updates if field not in allowed_fields)
        if unsupported:
            raise ValueError(f"Unsupported fields for update: {', '.join(unsupported)}")

        profile = self.get_profile(user_id)
        mutated = copy.deepcopy(profile)

        if "displayName" in updates:
            new_name = _clean_str(updates["displayName"])
            if not new_name:
                raise ValueError("displayName cannot be blank")
            mutated["displayName"] = new_name

        if "personalization" in updates:
            personalization_payload = updates["personalization"] or {}
            time_zone = personalization_payload.get("timeZone")
            tz_value = _clean_str(time_zone)
            if not tz_value:
                raise ValueError("personalization.timeZone must be a non-empty string")
            personalization = mutated.setdefault("personalization", {})
            personalization["timeZone"] = tz_value

        mutated["lastUpdatedAt"] = _iso_now()
        self.store.save_user_profile(user_id=user_id, profile=mutated)
        return mutated

    def revoke_sessions(self, user_id: str, session_ids: Sequence[str]) -> Dict[str, Any]:
        user_id = _normalise_user_id(user_id)
        session_set = {sid for sid in (s.strip() for s in session_ids if isinstance(s, str)) if sid}
        if not session_set:
            raise ValueError("session_ids must contain at least one valid id")

        profile = self.get_profile(user_id)
        mutated = copy.deepcopy(profile)
        security = mutated.setdefault("security", {})
        active_sessions = list(security.get("activeSessions") or [])

        remaining_sessions: List[Dict[str, Any]] = []
        revoked_ids: List[str] = []

        for session in active_sessions:
            session_id = _clean_str(session.get("id"))
            if session_id and session_id in session_set:
                revoked_ids.append(session_id)
                continue
            if session_id:
                remaining_sessions.append(session)

        security["activeSessions"] = remaining_sessions
        mutated["lastUpdatedAt"] = _iso_now()
        self.store.save_user_profile(user_id=user_id, profile=mutated)

        return {
            "revokedSessionIds": revoked_ids,
            "activeSessions": remaining_sessions,
        }

    def request_data_export(self, user_id: str) -> Dict[str, Any]:
        user_id = _normalise_user_id(user_id)
        profile = self.get_profile(user_id)
        mutated = copy.deepcopy(profile)

        requested_at = _iso_now()
        job_id = f"export-{uuid.uuid4().hex}"

        compliance = mutated.setdefault("compliance", {})
        compliance["lastExportAt"] = requested_at
        mutated["lastUpdatedAt"] = requested_at

        self.store.save_user_profile(user_id=user_id, profile=mutated)
        return {"jobId": job_id, "status": "queued", "requestedAt": requested_at}


def _normalise_user_id(user_id: str) -> str:
    value = _clean_str(user_id)
    if not value:
        raise ValueError("user_id is required")
    return value


def _normalise_profile(raw: Dict[str, Any], *, default_user_id: str) -> Dict[str, Any]:
    profile: Dict[str, Any] = {
        "id": _clean_str(raw.get("id")) or default_user_id,
        "displayName": _clean_str(raw.get("displayName")) or "User",
    }

    account = _normalise_account(raw.get("account"))
    if account:
        profile["account"] = account

    security = _normalise_security(raw.get("security"))
    if security:
        profile["security"] = security

    personalization = _normalise_personalization(raw.get("personalization"))
    if personalization:
        profile["personalization"] = personalization

    integrations = _normalise_integrations(raw.get("integrations"))
    if integrations:
        profile["integrations"] = integrations

    compliance = _normalise_compliance(raw.get("compliance"))
    if compliance:
        profile["compliance"] = compliance

    activity = _normalise_activity(raw.get("activity"))
    if activity:
        profile["activity"] = activity

    feature_flags = _normalise_feature_flags(raw.get("featureFlags"))
    if feature_flags:
        profile["featureFlags"] = feature_flags

    profile["lastUpdatedAt"] = _clean_str(raw.get("lastUpdatedAt")) or _iso_now()
    return profile


def _normalise_account(data: Any) -> Dict[str, Any]:
    account_data = _as_dict(data)
    organization = _normalise_organization(account_data.get("organization"))
    teams = [_normalise_team(team) for team in _as_list(account_data.get("teams"))]
    teams = [team for team in teams if team]

    account: Dict[str, Any] = {
        "role": _clean_str(account_data.get("role")) or "member",
        "managedByOrganization": bool(account_data.get("managedByOrganization", False)),
        "planTier": _clean_str(account_data.get("planTier")) or "free",
        "joinDate": _clean_str(account_data.get("joinDate")),
        "lastLoginAt": _clean_str(account_data.get("lastLoginAt")),
        "lastActiveAt": _clean_str(account_data.get("lastActiveAt")),
    }

    billing_email = _clean_str(account_data.get("billingContactEmail"))
    if billing_email:
        account["billingContactEmail"] = billing_email

    if organization:
        account["organization"] = organization
    if teams:
        account["teams"] = teams

    return _compact_dict(account)


def _normalise_organization(data: Any) -> Dict[str, Any]:
    organization = _as_dict(data)
    identifier = _clean_str(organization.get("id"))
    name = _clean_str(organization.get("name"))
    if not identifier or not name:
        return {}
    return {
        "id": identifier,
        "name": name,
    }


def _normalise_team(data: Any) -> Dict[str, Any]:
    team = _as_dict(data)
    identifier = _clean_str(team.get("id"))
    name = _clean_str(team.get("name"))
    if not identifier or not name:
        return {}
    payload: Dict[str, Any] = {
        "id": identifier,
        "name": name,
    }
    slug = _clean_str(team.get("slug"))
    if slug:
        payload["slug"] = slug
    return payload


def _normalise_security(data: Any) -> Dict[str, Any]:
    security = _as_dict(data)
    mfa = _as_dict(security.get("mfa"))
    methods = [_clean_str(method) for method in _as_list(mfa.get("methods"))]
    methods = [method for method in methods if method]

    mfa_payload = {
        "enabled": bool(mfa.get("enabled", False)),
        "methods": methods,
    }
    enforced = mfa.get("enforced")
    if isinstance(enforced, bool):
        mfa_payload["enforced"] = enforced

    sso_providers = [_normalise_sso_provider(provider) for provider in _as_list(security.get("ssoProviders"))]
    sso_providers = [provider for provider in sso_providers if provider]

    sessions = [_normalise_session(session) for session in _as_list(security.get("activeSessions"))]
    sessions = [session for session in sessions if session]

    payload: Dict[str, Any] = _compact_dict(
        {
            "passwordLastChangedAt": _clean_str(security.get("passwordLastChangedAt")),
            "mfa": _compact_dict(mfa_payload),
            "ssoProviders": sso_providers,
            "activeSessions": sessions,
        }
    )
    return payload


def _normalise_sso_provider(data: Any) -> Dict[str, Any]:
    provider = _as_dict(data)
    identifier = _clean_str(provider.get("id"))
    name = _clean_str(provider.get("name"))
    connected_at = _clean_str(provider.get("connectedAt"))
    if not identifier or not name or not connected_at:
        return {}
    payload: Dict[str, Any] = {
        "id": identifier,
        "name": name,
        "connectedAt": connected_at,
    }
    last_used_at = _clean_str(provider.get("lastUsedAt"))
    if last_used_at:
        payload["lastUsedAt"] = last_used_at
    return payload


def _normalise_session(data: Any) -> Dict[str, Any]:
    session = _as_dict(data)
    identifier = _clean_str(session.get("id"))
    device = _clean_str(session.get("device"))
    platform = _clean_str(session.get("platform"))
    created_at = _clean_str(session.get("createdAt"))
    last_seen_at = _clean_str(session.get("lastSeenAt"))
    if not identifier or not device or not platform or not created_at or not last_seen_at:
        return {}
    payload: Dict[str, Any] = {
        "id": identifier,
        "device": device,
        "platform": platform,
        "ip": _clean_str(session.get("ip")),
        "createdAt": created_at,
        "lastSeenAt": last_seen_at,
        "isCurrent": bool(session.get("isCurrent", False)),
        "riskLevel": _clean_str(session.get("riskLevel")) or "low",
    }
    return _compact_dict(payload)


def _normalise_personalization(data: Any) -> Dict[str, Any]:
    personalization = _as_dict(data)
    tz = _clean_str(personalization.get("timeZone"))
    if not tz:
        return {}
    return {"timeZone": tz}


def _normalise_integrations(data: Any) -> Dict[str, Any]:
    integrations = _as_dict(data)
    connected_apps = [_normalise_connected_app(app) for app in _as_list(integrations.get("connectedApps"))]
    connected_apps = [app for app in connected_apps if app]

    api_tokens = [_normalise_api_token(token) for token in _as_list(integrations.get("apiTokens"))]
    api_tokens = [token for token in api_tokens if token]

    payload = _compact_dict({"connectedApps": connected_apps, "apiTokens": api_tokens})
    return payload


def _normalise_connected_app(data: Any) -> Dict[str, Any]:
    app = _as_dict(data)
    identifier = _clean_str(app.get("id"))
    name = _clean_str(app.get("name"))
    status = _clean_str(app.get("status"))
    connected_at = _clean_str(app.get("connectedAt"))
    if not identifier or not name or not status or not connected_at:
        return {}
    payload: Dict[str, Any] = {
        "id": identifier,
        "name": name,
        "status": status,
        "connectedAt": connected_at,
    }
    last_sync_at = _clean_str(app.get("lastSyncAt"))
    if last_sync_at:
        payload["lastSyncAt"] = last_sync_at
    return payload


def _normalise_api_token(data: Any) -> Dict[str, Any]:
    token = _as_dict(data)
    identifier = _clean_str(token.get("id"))
    label = _clean_str(token.get("label"))
    created_at = _clean_str(token.get("createdAt"))
    status = _clean_str(token.get("status"))
    if not identifier or not label or not created_at or not status:
        return {}
    payload: Dict[str, Any] = {
        "id": identifier,
        "label": label,
        "createdAt": created_at,
        "status": status,
    }
    scopes = [_clean_str(scope) for scope in _as_list(token.get("scopes"))]
    scopes = [scope for scope in scopes if scope]
    if scopes:
        payload["scopes"] = scopes
    last_used_at = _clean_str(token.get("lastUsedAt"))
    if last_used_at:
        payload["lastUsedAt"] = last_used_at
    return payload


def _normalise_compliance(data: Any) -> Dict[str, Any]:
    compliance = _as_dict(data)
    pending = _as_dict(compliance.get("pendingDeletion"))
    pending_payload = {
        "requestedAt": _clean_str(pending.get("requestedAt")),
        "effectiveAt": _clean_str(pending.get("effectiveAt")),
        "status": _clean_str(pending.get("status")),
    }

    consents = [_normalise_consent(consent) for consent in _as_list(compliance.get("consents"))]
    consents = [consent for consent in consents if consent]

    payload: Dict[str, Any] = _compact_dict(
        {
            "lastExportAt": _clean_str(compliance.get("lastExportAt")),
            "pendingDeletion": _compact_dict(pending_payload),
            "consents": consents,
            "dataResidency": _clean_str(compliance.get("dataResidency")),
        }
    )
    return payload


def _normalise_consent(data: Any) -> Dict[str, Any]:
    consent = _as_dict(data)
    identifier = _clean_str(consent.get("id"))
    label = _clean_str(consent.get("label"))
    granted_at = _clean_str(consent.get("grantedAt"))
    status = _clean_str(consent.get("status"))
    if not identifier or not label or not granted_at or not status:
        return {}
    payload: Dict[str, Any] = {
        "id": identifier,
        "label": label,
        "grantedAt": granted_at,
        "status": status,
    }
    description = _clean_str(consent.get("description"))
    if description:
        payload["description"] = description
    expires_at = _clean_str(consent.get("expiresAt"))
    if expires_at:
        payload["expiresAt"] = expires_at
    return payload


def _normalise_activity(data: Any) -> Dict[str, Any]:
    activity = _as_dict(data)
    events = [_normalise_activity_event(event) for event in _as_list(activity.get("recentEvents"))]
    events = [event for event in events if event]

    devices = [_normalise_device(device) for device in _as_list(activity.get("trustedDevices"))]
    devices = [device for device in devices if device]

    payload = _compact_dict({"recentEvents": events, "trustedDevices": devices})
    return payload


def _normalise_activity_event(data: Any) -> Dict[str, Any]:
    event = _as_dict(data)
    identifier = _clean_str(event.get("id"))
    event_type = _clean_str(event.get("type"))
    occurred_at = _clean_str(event.get("occurredAt"))
    summary = _clean_str(event.get("summary"))
    actor = _clean_str(event.get("actor"))
    if not identifier or not event_type or not occurred_at or not summary:
        return {}
    payload: Dict[str, Any] = {
        "id": identifier,
        "type": event_type,
        "occurredAt": occurred_at,
        "summary": summary,
    }
    if actor:
        payload["actor"] = actor
    return payload


def _normalise_device(data: Any) -> Dict[str, Any]:
    device = _as_dict(data)
    identifier = _clean_str(device.get("id"))
    agent = _clean_str(device.get("agent"))
    last_seen_at = _clean_str(device.get("lastSeenAt"))
    if not identifier or not agent or not last_seen_at:
        return {}
    payload: Dict[str, Any] = {
        "id": identifier,
        "agent": agent,
        "lastSeenAt": last_seen_at,
        "isCurrent": bool(device.get("isCurrent", False)),
    }
    location = _clean_str(device.get("location"))
    if location:
        payload["location"] = location
    return payload


def _normalise_feature_flags(flags: Any) -> List[str]:
    values = {_clean_str(flag) for flag in _as_list(flags)}
    return sorted(flag for flag in values if flag)


def _compact_dict(payload: Dict[str, Any]) -> Dict[str, Any]:
    return {key: value for key, value in payload.items() if _has_value(value)}


def _has_value(value: Any) -> bool:
    if value is None:
        return False
    if isinstance(value, bool):
        return True
    if isinstance(value, (int, float)):
        return True
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, (list, dict, set, tuple)):
        return len(value) > 0
    return True


def _clean_str(value: Any) -> Optional[str]:
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def _as_dict(value: Any) -> Dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _as_list(value: Any) -> List[Any]:
    if isinstance(value, list):
        return value
    if isinstance(value, tuple):
        return list(value)
    return []


def _iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


_service: Optional[UserProfileService] = None


def configure_service(service: UserProfileService) -> None:
    global _service
    _service = service


def get_service() -> UserProfileService:
    if _service is None:
        raise RuntimeError("UserProfileService has not been configured")
    return _service


try:  # pragma: no cover - FastAPI optional for tests
    from fastapi import APIRouter, Body, HTTPException, Query, status
    from pydantic import BaseModel, Field

    router = APIRouter(prefix="/api/v1")

    DEFAULT_USER_ID = "demo-user"

    class _PersonalizationUpdate(BaseModel):
        timeZone: Optional[str] = Field(default=None, alias="timeZone")

    class ProfileUpdateRequest(BaseModel):
        displayName: Optional[str] = None
        personalization: Optional[_PersonalizationUpdate] = None

        def to_updates(self) -> Dict[str, Any]:
            payload: Dict[str, Any] = {}
            if self.displayName is not None:
                payload["displayName"] = self.displayName
            if self.personalization is not None:
                payload["personalization"] = self.personalization.dict(exclude_none=True, by_alias=True)
            return payload

    class RevokeSessionsRequest(BaseModel):
        sessionIds: List[str] = Field(..., min_items=1)

    @router.get("/user/profile", tags=["user"])
    def get_user_profile(user_id: Optional[str] = Query(default=None, alias="userId")) -> Dict[str, Any]:
        service = get_service()
        target_user = user_id or DEFAULT_USER_ID
        try:
            return service.get_profile(target_user)
        except UserProfileNotFoundError:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User profile not found")

    @router.patch("/user/profile", tags=["user"])
    def patch_user_profile(
        request: ProfileUpdateRequest = Body(...),
        user_id: Optional[str] = Query(default=None, alias="userId"),
    ) -> Dict[str, Any]:
        service = get_service()
        target_user = user_id or DEFAULT_USER_ID
        try:
            return service.update_profile(target_user, request.to_updates())
        except UserProfileNotFoundError:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User profile not found")
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))

    @router.post("/user/profile/sessions/revoke", tags=["user"])
    def revoke_sessions(
        request: RevokeSessionsRequest = Body(...),
        user_id: Optional[str] = Query(default=None, alias="userId"),
    ) -> Dict[str, Any]:
        service = get_service()
        target_user = user_id or DEFAULT_USER_ID
        try:
            return service.revoke_sessions(target_user, request.sessionIds)
        except UserProfileNotFoundError:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User profile not found")
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))

    @router.post("/user/profile/data-export", tags=["user"], status_code=status.HTTP_202_ACCEPTED)
    def request_data_export(user_id: Optional[str] = Query(default=None, alias="userId")) -> Dict[str, Any]:
        service = get_service()
        target_user = user_id or DEFAULT_USER_ID
        try:
            return service.request_data_export(target_user)
        except UserProfileNotFoundError:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User profile not found")

except ImportError:  # pragma: no cover
    router = None
