import copy
import unittest
from typing import List
from unittest.mock import patch

from backend.api.user_profile import (
    UserProfileNotFoundError,
    UserProfileService,
)


class _FakeStore:
    def __init__(self, payload=None):
        self._payload = payload or {}
        self.saved: List[dict] = []

    def fetch_user_profile(self, *, user_id: str):
        if not self._payload or user_id != self._payload.get("id"):
            return None
        return copy.deepcopy(self._payload)

    def save_user_profile(self, *, user_id: str, profile: dict):
        self.saved.append(copy.deepcopy(profile))
        self._payload = copy.deepcopy(profile)


class UserProfileServiceTests(unittest.TestCase):
    def test_get_profile_normalises_payload(self) -> None:
        raw_profile = {
            "id": "demo-user",
            "displayName": " ",
            "account": {
                "role": "admin",
                "organization": {"id": "org-1", "name": "Org"},
                "teams": [
                    {"id": "team-1", "name": "Research"},
                    {"name": "Missing id"},
                ],
                "managedByOrganization": True,
                "planTier": "enterprise",
                "joinDate": "2024-01-01T00:00:00Z",
                "lastActiveAt": "",
            },
            "security": {
                "mfa": {"enabled": True, "methods": ["totp", ""]},
                "ssoProviders": [
                    {"id": "google", "name": "google", "connectedAt": "2024-01-02T00:00:00Z"},
                    {"id": None, "name": "bad"},
                ],
                "activeSessions": [
                    {
                        "id": "session-1",
                        "device": "Laptop",
                        "platform": "macOS",
                        "ip": "127.0.0.1",
                        "createdAt": "2024-01-03T00:00:00Z",
                        "lastSeenAt": "2024-01-03T01:00:00Z",
                        "isCurrent": True,
                        "riskLevel": "medium",
                    },
                    {"id": None},
                ],
            },
            "personalization": {"timeZone": "Europe/London"},
            "integrations": {
                "connectedApps": [
                    {
                        "id": "notion",
                        "name": "Notion",
                        "status": "active",
                        "connectedAt": "2024-01-10T00:00:00Z",
                    },
                    {"id": "slack"},
                ],
                "apiTokens": [
                    {
                        "id": "token-1",
                        "label": "Prototype",
                        "createdAt": "2024-01-11T00:00:00Z",
                        "status": "active",
                        "scopes": ["read"],
                    }
                ],
            },
            "compliance": {
                "consents": [
                    {
                        "id": "consent-1",
                        "label": "Terms",
                        "grantedAt": "2024-01-01T00:00:00Z",
                        "status": "granted",
                    },
                    {"id": None},
                ]
            },
            "activity": {
                "recentEvents": [
                    {
                        "id": "evt-1",
                        "type": "login",
                        "occurredAt": "2024-01-04T00:00:00Z",
                        "summary": "Logged in",
                        "actor": "self",
                    }
                ],
                "trustedDevices": [
                    {
                        "id": "device-1",
                        "agent": "Chrome",
                        "lastSeenAt": "2024-01-04T01:00:00Z",
                        "isCurrent": True,
                    }
                ],
            },
            "featureFlags": ["beta", "beta", ""],
            "lastUpdatedAt": "2024-01-04T02:00:00Z",
        }
        service = UserProfileService(store=_FakeStore(payload=raw_profile))

        profile = service.get_profile("demo-user")

        self.assertEqual(profile["id"], "demo-user")
        self.assertEqual(profile["displayName"], "User")  # falls back when blank
        self.assertEqual(len(profile["account"]["teams"]), 1)
        self.assertEqual(profile["security"]["mfa"]["methods"], ["totp"])
        self.assertEqual(len(profile["security"]["activeSessions"]), 1)
        self.assertEqual(len(profile["security"]["ssoProviders"]), 1)
        self.assertEqual(profile["featureFlags"], ["beta"])

    def test_update_profile_mutates_allowed_fields_and_updates_timestamp(self) -> None:
        service = UserProfileService(
            store=_FakeStore(
                payload={
                    "id": "demo-user",
                    "displayName": "Existing",
                    "personalization": {"timeZone": "UTC"},
                    "lastUpdatedAt": "2024-01-01T00:00:00Z",
                }
            )
        )

        with patch("backend.api.user_profile._iso_now", return_value="2024-05-30T00:00:00Z"):
            updated = service.update_profile(
                "demo-user",
                {
                    "displayName": "Ada",
                    "personalization": {"timeZone": "Europe/Paris"},
                },
            )

        self.assertEqual(updated["displayName"], "Ada")
        self.assertEqual(updated["personalization"]["timeZone"], "Europe/Paris")
        self.assertEqual(updated["lastUpdatedAt"], "2024-05-30T00:00:00Z")

    def test_revoke_sessions_filters_requested_ids(self) -> None:
        service = UserProfileService(
            store=_FakeStore(
                payload={
                    "id": "demo-user",
                    "displayName": "Sample",
                    "security": {
                        "activeSessions": [
                            {
                                "id": "session-1",
                                "device": "Laptop",
                                "platform": "macOS",
                                "createdAt": "2024-01-03T00:00:00Z",
                                "lastSeenAt": "2024-01-03T01:00:00Z",
                            },
                            {
                                "id": "session-2",
                                "device": "Phone",
                                "platform": "iOS",
                                "createdAt": "2024-01-02T00:00:00Z",
                                "lastSeenAt": "2024-01-02T01:00:00Z",
                            },
                        ]
                    },
                }
            )
        )

        with patch("backend.api.user_profile._iso_now", return_value="2024-05-30T00:10:00Z"):
            result = service.revoke_sessions("demo-user", ["session-2"])

        self.assertEqual(result["revokedSessionIds"], ["session-2"])
        self.assertEqual(len(result["activeSessions"]), 1)
        self.assertEqual(result["activeSessions"][0]["id"], "session-1")
        self.assertEqual(service.store.saved[-1]["lastUpdatedAt"], "2024-05-30T00:10:00Z")

    def test_request_data_export_updates_last_export_and_returns_job(self) -> None:
        service = UserProfileService(
            store=_FakeStore(
                payload={
                    "id": "demo-user",
                    "displayName": "Sample",
                    "compliance": {},
                }
            )
        )

        with patch("backend.api.user_profile._iso_now", return_value="2024-05-30T00:15:00Z"), patch(
            "backend.api.user_profile.uuid.uuid4"
        ) as mock_uuid:
            mock_uuid.return_value.hex = "deadbeef"
            response = service.request_data_export("demo-user")

        self.assertEqual(response["requestedAt"], "2024-05-30T00:15:00Z")
        self.assertTrue(response["jobId"].startswith("export-"))
        saved = service.store.saved[-1]
        self.assertEqual(saved["compliance"]["lastExportAt"], "2024-05-30T00:15:00Z")

    def test_raises_when_user_missing(self) -> None:
        service = UserProfileService(store=_FakeStore(payload={}))

        with self.assertRaises(UserProfileNotFoundError):
            service.get_profile("missing")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
