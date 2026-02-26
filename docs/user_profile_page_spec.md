# User Profile Page Spec

## Overview
- Provide a privacy-conscious profile surface with only the required identity, account, security, personalization, integration, and compliance details.
- Avoid optional self-identifying fields (avatar, bio, phone, etc.) while keeping operational metadata available to admins.
- Support future insights page linkage without overloading this view.

## Data Model
- Root payload keeps immutable identity separate from mutable settings to simplify partial updates.
- Date strings are ISO 8601 and server-sourced; client never uses local clocks for audits.
- Minimal PII; fields marked optional should be omitted rather than returned empty.

### Root Schema
```ts
export interface UserProfilePayload {
  id: string;
  displayName: string;
  account: AccountDetails;
  security: SecurityOverview;
  personalization: PersonalizationSettings;
  integrations: IntegrationState;
  compliance: ComplianceCenter;
  activity?: ActivitySnapshot;
  featureFlags?: string[];
  lastUpdatedAt: string;
}
```

### Account Details
```ts
export interface AccountDetails {
  role: 'member' | 'admin' | 'owner';
  organization?: {
    id: string;
    name: string;
  };
  teams: TeamSummary[];
  joinDate: string;
  planTier: 'free' | 'pro' | 'enterprise';
  billingContactEmail?: string;
  managedByOrganization: boolean;
  lastLoginAt?: string;
  lastActiveAt: string;
}

export interface TeamSummary {
  id: string;
  name: string;
  slug?: string;
}
```

### Security
```ts
export interface SecurityOverview {
  passwordLastChangedAt?: string;
  mfa: {
    enabled: boolean;
    enforced?: boolean;
    methods: Array<'totp' | 'sms' | 'webauthn' | 'backup-codes'>;
  };
  ssoProviders: ConnectedSSOProvider[];
  activeSessions: SessionSummary[];
}

export interface ConnectedSSOProvider {
  id: string;
  name: 'google' | 'microsoft' | 'okta' | 'custom';
  connectedAt: string;
  lastUsedAt?: string;
}

export interface SessionSummary {
  id: string;
  device: string;
  platform: string;
  ip: string;
  createdAt: string;
  lastSeenAt: string;
  isCurrent: boolean;
  riskLevel: 'low' | 'medium' | 'high';
}
```

### Personalization
```ts
export interface PersonalizationSettings {
  timeZone: string; // IANA identifier, e.g., "Europe/London"
}
```

### Integrations
```ts
export interface IntegrationState {
  connectedApps: IntegrationSummary[];
  apiTokens: ApiTokenSummary[];
}

export interface IntegrationSummary {
  id: string;
  name: string;
  status: 'active' | 'error' | 'revoked';
  connectedAt: string;
  lastSyncAt?: string;
}

export interface ApiTokenSummary {
  id: string;
  label: string;
  createdAt: string;
  lastUsedAt?: string;
  status: 'active' | 'revoked' | 'expiring';
  scopes: string[];
}
```

### Compliance & Data
```ts
export interface ComplianceCenter {
  lastExportAt?: string;
  pendingDeletion?: {
    requestedAt: string;
    effectiveAt: string;
    status: 'pending' | 'completed' | 'cancelled';
  };
  consents: ConsentRecord[];
  dataResidency?: 'us' | 'eu' | 'apac' | 'other';
}

export interface ConsentRecord {
  id: string;
  label: string;
  description?: string;
  grantedAt: string;
  expiresAt?: string;
  status: 'granted' | 'revoked';
}
```

### Activity Snapshot (Optional)
```ts
export interface ActivitySnapshot {
  recentEvents: ActivityEvent[];
  trustedDevices: DeviceSummary[];
}

export interface ActivityEvent {
  id: string;
  type: 'login' | 'role-change' | 'integration-sync' | 'security';
  occurredAt: string;
  summary: string;
  actor: string;
}

export interface DeviceSummary {
  id: string;
  agent: string;
  lastSeenAt: string;
  location?: string;
  isCurrent: boolean;
}
```

### API Considerations
- `GET /api/user/profile` returns the payload above; optional sub-resources omitted when empty.
- `PATCH /api/user/profile`: partial updates by section (`displayName`, `personalization.timeZone`).
- `POST /api/user/profile/sessions/revoke`: revoke target session IDs.
- `POST /api/user/profile/data-export`: initiates export job and returns tracking ID.
- All mutating routes require recent re-auth if `security.sensitiveOperationWindow` > 15 minutes (handled server-side).

## React Component Architecture

### Page Shell
- `UserProfilePage`: route-level container; owns data fetching (React Query), suspense boundary, and optimistic toasts.
- `ProfileLayout`: shared layout wrapper (breadcrumbs, heading, affordance to navigate to Insights).

### Identity & Account
- `ProfileIdentityCard`: renders display name with inline edit and form state; shows account role and organization badges.
- `AccountMetadataPanel`: lists join date, plan tier, and team chips; exposes “View billing” CTA when `managedByOrganization` is false.

### Security
- `SecurityOverviewCard`: summarizes password age, MFA, SSO state; surfaces warnings.
- `MFAStatusList`: details enabled methods, lets user manage MFA via modal (`ManageMFAModal`).
- `ActiveSessionsTable`: paginated list with revoke buttons; highlights current session.
- `LinkedSSOProviders`: shows providers with disconnect actions (respecting enforced flag).

### Personalization
- `TimeZoneSelectorCard`: single field card with searchable dropdown (IANA zones) and preview of how it affects timestamps; optimistic update with rollback on failure.

### Integrations
- `ConnectedIntegrationsCard`: grid/list of third-party apps; actions to reconnect or remove.
- `ApiTokenTable`: collapsible table of tokens with masked values, copy/regenerate flows via `ApiTokenModal`.

### Compliance & Data
- `ComplianceCenterCard`: presents export status, consents, and deletion flow entry.
- `DataExportButton`: triggers export request, shows job progress via toast/pill.
- `ConsentHistoryList`: timeline view of consents for transparency.
- `AccountDeletionBanner`: conditionally rendered when `pendingDeletion` exists with cancel option.

### Activity (Optional)
- `ActivitySnapshotCard`: displays recent events and trusted devices, collapsible if feed is long.

### Cross-Cutting Concerns
- Shared `ProfileSection` wrapper enforces consistent spacing, headings, and “Edit” affordances.
- Use `ProfileSkeleton` while data loads; fallback error state encourages refresh or contact support.
- Central mutation hook (`useUserProfileMutations`) encapsulates API calls, toast messaging, and invalidation.

### Accessibility & Privacy Notes
- All destructive actions require confirmation modals with explicit outcomes.
- Do not cache session IPs client-side beyond render cycle; fetched when tables open.
- Avoid exposing raw IDs in the DOM when not necessary; prefer data attributes for testing.

### Open Questions
- Should organization admins see additional compliance controls (e.g., export others' data)?
- Do we need audit logging for profile changes initiated via this page?
- Confirm whether plan tier is sourced from billing service or Supabase profile record.
