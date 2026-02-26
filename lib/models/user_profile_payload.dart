DateTime? _parseDateTime(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim())?.toUtc();
  }
  return null;
}

String? _formatDateTime(DateTime? value) {
  return value?.toUtc().toIso8601String();
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

class UserProfilePayload {
  final String id;
  final String displayName;
  final AccountDetails account;
  final SecurityOverview security;
  final PersonalizationSettings personalization;
  final IntegrationState integrations;
  final ComplianceCenter compliance;
  final ActivitySnapshot? activity;
  final List<String> featureFlags;
  final DateTime lastUpdatedAt;

  UserProfilePayload({
    required this.id,
    required this.displayName,
    required this.account,
    required this.security,
    required this.personalization,
    required this.integrations,
    required this.compliance,
    this.activity,
    required this.featureFlags,
    required this.lastUpdatedAt,
  });

  factory UserProfilePayload.fromJson(Map<String, dynamic> json) {
    return UserProfilePayload(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      account: AccountDetails.fromJson(
        (json['account'] as Map<String, dynamic>?) ?? const {},
      ),
      security: SecurityOverview.fromJson(
        (json['security'] as Map<String, dynamic>?) ?? const {},
      ),
      personalization: PersonalizationSettings.fromJson(
        (json['personalization'] as Map<String, dynamic>?) ?? const {},
      ),
      integrations: IntegrationState.fromJson(
        (json['integrations'] as Map<String, dynamic>?) ?? const {},
      ),
      compliance: ComplianceCenter.fromJson(
        (json['compliance'] as Map<String, dynamic>?) ?? const {},
      ),
      activity: json['activity'] != null
          ? ActivitySnapshot.fromJson(
              (json['activity'] as Map<String, dynamic>) ,
            )
          : null,
      featureFlags: _stringList(json['featureFlags']),
      lastUpdatedAt:
          _parseDateTime(json['lastUpdatedAt']) ?? DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'account': account.toJson(),
      'security': security.toJson(),
      'personalization': personalization.toJson(),
      'integrations': integrations.toJson(),
      'compliance': compliance.toJson(),
      if (activity != null) 'activity': activity!.toJson(),
      'featureFlags': featureFlags,
      'lastUpdatedAt': _formatDateTime(lastUpdatedAt),
    };
  }

  UserProfilePayload copyWith({
    String? displayName,
    PersonalizationSettings? personalization,
    IntegrationState? integrations,
    ComplianceCenter? compliance,
    ActivitySnapshot? activity,
    List<String>? featureFlags,
    DateTime? lastUpdatedAt,
    AccountDetails? account,
    SecurityOverview? security,
  }) {
    return UserProfilePayload(
      id: id,
      displayName: displayName ?? this.displayName,
      account: account ?? this.account,
      security: security ?? this.security,
      personalization: personalization ?? this.personalization,
      integrations: integrations ?? this.integrations,
      compliance: compliance ?? this.compliance,
      activity: activity ?? this.activity,
      featureFlags: featureFlags ?? this.featureFlags,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

class AccountDetails {
  final String role;
  final OrganizationSummary? organization;
  final List<TeamSummary> teams;
  final DateTime? joinDate;
  final String planTier;
  final String? billingContactEmail;
  final bool managedByOrganization;
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;

  const AccountDetails({
    required this.role,
    required this.organization,
    required this.teams,
    required this.joinDate,
    required this.planTier,
    required this.billingContactEmail,
    required this.managedByOrganization,
    required this.lastLoginAt,
    required this.lastActiveAt,
  });

  factory AccountDetails.fromJson(Map<String, dynamic> json) {
    final teams = (json['teams'] as List<dynamic>?)
            ?.map((team) => TeamSummary.fromJson(team as Map<String, dynamic>))
            .toList() ??
        const [];
    return AccountDetails(
      role: json['role'] as String? ?? 'member',
      organization: json['organization'] != null
          ? OrganizationSummary.fromJson(
              json['organization'] as Map<String, dynamic>,
            )
          : null,
      teams: teams,
      joinDate: _parseDateTime(json['joinDate']),
      planTier: json['planTier'] as String? ?? 'free',
      billingContactEmail: json['billingContactEmail'] as String?,
      managedByOrganization:
          json['managedByOrganization'] as bool? ?? false,
      lastLoginAt: _parseDateTime(json['lastLoginAt']),
      lastActiveAt: _parseDateTime(json['lastActiveAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      if (organization != null) 'organization': organization!.toJson(),
      'teams': teams.map((team) => team.toJson()).toList(),
      'joinDate': _formatDateTime(joinDate),
      'planTier': planTier,
      if (billingContactEmail != null)
        'billingContactEmail': billingContactEmail,
      'managedByOrganization': managedByOrganization,
      'lastLoginAt': _formatDateTime(lastLoginAt),
      'lastActiveAt': _formatDateTime(lastActiveAt),
    };
  }
}

class OrganizationSummary {
  final String id;
  final String name;

  const OrganizationSummary({
    required this.id,
    required this.name,
  });

  factory OrganizationSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class TeamSummary {
  final String id;
  final String name;
  final String? slug;

  const TeamSummary({
    required this.id,
    required this.name,
    this.slug,
  });

  factory TeamSummary.fromJson(Map<String, dynamic> json) {
    return TeamSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (slug != null) 'slug': slug,
    };
  }
}

class SecurityOverview {
  final DateTime? passwordLastChangedAt;
  final MfaState mfa;
  final List<ConnectedSsoProvider> ssoProviders;
  final List<SessionSummary> activeSessions;

  const SecurityOverview({
    required this.passwordLastChangedAt,
    required this.mfa,
    required this.ssoProviders,
    required this.activeSessions,
  });

  factory SecurityOverview.fromJson(Map<String, dynamic> json) {
    final providers = (json['ssoProviders'] as List<dynamic>?)
            ?.map(
              (provider) =>
                  ConnectedSsoProvider.fromJson(provider as Map<String, dynamic>),
            )
            .toList() ??
        const [];
    final sessions = (json['activeSessions'] as List<dynamic>?)
            ?.map(
              (session) => SessionSummary.fromJson(session as Map<String, dynamic>),
            )
            .toList() ??
        const [];
    return SecurityOverview(
      passwordLastChangedAt: _parseDateTime(json['passwordLastChangedAt']),
      mfa: MfaState.fromJson(
        (json['mfa'] as Map<String, dynamic>?) ?? const {},
      ),
      ssoProviders: providers,
      activeSessions: sessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passwordLastChangedAt': _formatDateTime(passwordLastChangedAt),
      'mfa': mfa.toJson(),
      'ssoProviders': ssoProviders.map((provider) => provider.toJson()).toList(),
      'activeSessions': activeSessions.map((session) => session.toJson()).toList(),
    };
  }

  SecurityOverview copyWith({
    DateTime? passwordLastChangedAt,
    MfaState? mfa,
    List<ConnectedSsoProvider>? ssoProviders,
    List<SessionSummary>? activeSessions,
  }) {
    return SecurityOverview(
      passwordLastChangedAt: passwordLastChangedAt ?? this.passwordLastChangedAt,
      mfa: mfa ?? this.mfa,
      ssoProviders: ssoProviders ?? List<ConnectedSsoProvider>.from(this.ssoProviders),
      activeSessions: activeSessions ?? List<SessionSummary>.from(this.activeSessions),
    );
  }
}

class MfaState {
  final bool enabled;
  final bool? enforced;
  final List<String> methods;

  const MfaState({
    required this.enabled,
    required this.enforced,
    required this.methods,
  });

  factory MfaState.fromJson(Map<String, dynamic> json) {
    return MfaState(
      enabled: json['enabled'] as bool? ?? false,
      enforced: json['enforced'] as bool?,
      methods: _stringList(json['methods']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      if (enforced != null) 'enforced': enforced,
      'methods': methods,
    };
  }
}

class ConnectedSsoProvider {
  final String id;
  final String name;
  final DateTime connectedAt;
  final DateTime? lastUsedAt;

  const ConnectedSsoProvider({
    required this.id,
    required this.name,
    required this.connectedAt,
    this.lastUsedAt,
  });

  factory ConnectedSsoProvider.fromJson(Map<String, dynamic> json) {
    return ConnectedSsoProvider(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      connectedAt: _parseDateTime(json['connectedAt']) ?? DateTime.now().toUtc(),
      lastUsedAt: _parseDateTime(json['lastUsedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'connectedAt': _formatDateTime(connectedAt),
      if (lastUsedAt != null) 'lastUsedAt': _formatDateTime(lastUsedAt),
    };
  }
}

class SessionSummary {
  final String id;
  final String device;
  final String platform;
  final String? ip;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final bool isCurrent;
  final String riskLevel;

  const SessionSummary({
    required this.id,
    required this.device,
    required this.platform,
    this.ip,
    required this.createdAt,
    required this.lastSeenAt,
    required this.isCurrent,
    required this.riskLevel,
  });

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      id: json['id'] as String? ?? '',
      device: json['device'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      ip: json['ip'] as String?,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now().toUtc(),
      lastSeenAt: _parseDateTime(json['lastSeenAt']) ?? DateTime.now().toUtc(),
      isCurrent: json['isCurrent'] as bool? ?? false,
      riskLevel: json['riskLevel'] as String? ?? 'low',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device': device,
      'platform': platform,
      if (ip != null) 'ip': ip,
      'createdAt': _formatDateTime(createdAt),
      'lastSeenAt': _formatDateTime(lastSeenAt),
      'isCurrent': isCurrent,
      'riskLevel': riskLevel,
    };
  }
}

class PersonalizationSettings {
  final String timeZone;

  const PersonalizationSettings({
    required this.timeZone,
  });

  factory PersonalizationSettings.fromJson(Map<String, dynamic> json) {
    return PersonalizationSettings(
      timeZone: json['timeZone'] as String? ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeZone': timeZone,
    };
  }

  PersonalizationSettings copyWith({String? timeZone}) {
    return PersonalizationSettings(timeZone: timeZone ?? this.timeZone);
  }
}

class IntegrationState {
  final List<IntegrationSummary> connectedApps;
  final List<ApiTokenSummary> apiTokens;

  const IntegrationState({
    required this.connectedApps,
    required this.apiTokens,
  });

  factory IntegrationState.fromJson(Map<String, dynamic> json) {
    final apps = (json['connectedApps'] as List<dynamic>?)
            ?.map(
              (app) => IntegrationSummary.fromJson(app as Map<String, dynamic>),
            )
            .toList() ??
        const [];
    final tokens = (json['apiTokens'] as List<dynamic>?)
            ?.map(
              (token) => ApiTokenSummary.fromJson(token as Map<String, dynamic>),
            )
            .toList() ??
        const [];
    return IntegrationState(
      connectedApps: apps,
      apiTokens: tokens,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectedApps': connectedApps.map((app) => app.toJson()).toList(),
      'apiTokens': apiTokens.map((token) => token.toJson()).toList(),
    };
  }

  IntegrationState copyWith({
    List<IntegrationSummary>? connectedApps,
    List<ApiTokenSummary>? apiTokens,
  }) {
    return IntegrationState(
      connectedApps: connectedApps ?? List<IntegrationSummary>.from(this.connectedApps),
      apiTokens: apiTokens ?? List<ApiTokenSummary>.from(this.apiTokens),
    );
  }
}

class IntegrationSummary {
  final String id;
  final String name;
  final String status;
  final DateTime connectedAt;
  final DateTime? lastSyncAt;

  const IntegrationSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.connectedAt,
    this.lastSyncAt,
  });

  factory IntegrationSummary.fromJson(Map<String, dynamic> json) {
    return IntegrationSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      connectedAt: _parseDateTime(json['connectedAt']) ?? DateTime.now().toUtc(),
      lastSyncAt: _parseDateTime(json['lastSyncAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'connectedAt': _formatDateTime(connectedAt),
      if (lastSyncAt != null) 'lastSyncAt': _formatDateTime(lastSyncAt),
    };
  }
}

class ApiTokenSummary {
  final String id;
  final String label;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final String status;
  final List<String> scopes;

  const ApiTokenSummary({
    required this.id,
    required this.label,
    required this.createdAt,
    this.lastUsedAt,
    required this.status,
    required this.scopes,
  });

  factory ApiTokenSummary.fromJson(Map<String, dynamic> json) {
    return ApiTokenSummary(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now().toUtc(),
      lastUsedAt: _parseDateTime(json['lastUsedAt']),
      status: json['status'] as String? ?? 'active',
      scopes: _stringList(json['scopes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'createdAt': _formatDateTime(createdAt),
      if (lastUsedAt != null) 'lastUsedAt': _formatDateTime(lastUsedAt),
      'status': status,
      'scopes': scopes,
    };
  }
}

class ComplianceCenter {
  final DateTime? lastExportAt;
  final PendingDeletion? pendingDeletion;
  final List<ConsentRecord> consents;
  final String? dataResidency;

  const ComplianceCenter({
    required this.lastExportAt,
    required this.pendingDeletion,
    required this.consents,
    required this.dataResidency,
  });

  factory ComplianceCenter.fromJson(Map<String, dynamic> json) {
    final consents = (json['consents'] as List<dynamic>?)
            ?.map(
              (consent) => ConsentRecord.fromJson(consent as Map<String, dynamic>),
            )
            .toList() ??
        const [];
    return ComplianceCenter(
      lastExportAt: _parseDateTime(json['lastExportAt']),
      pendingDeletion: json['pendingDeletion'] != null
          ? PendingDeletion.fromJson(
              json['pendingDeletion'] as Map<String, dynamic>,
            )
          : null,
      consents: consents,
      dataResidency: json['dataResidency'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastExportAt': _formatDateTime(lastExportAt),
      if (pendingDeletion != null) 'pendingDeletion': pendingDeletion!.toJson(),
      'consents': consents.map((consent) => consent.toJson()).toList(),
      if (dataResidency != null) 'dataResidency': dataResidency,
    };
  }

  ComplianceCenter updateLastExport(DateTime value) {
    return ComplianceCenter(
      lastExportAt: value,
      pendingDeletion: pendingDeletion,
      consents: consents,
      dataResidency: dataResidency,
    );
  }

  ComplianceCenter copyWith({
    DateTime? lastExportAt,
    PendingDeletion? pendingDeletion,
    List<ConsentRecord>? consents,
    String? dataResidency,
  }) {
    return ComplianceCenter(
      lastExportAt: lastExportAt ?? this.lastExportAt,
      pendingDeletion: pendingDeletion ?? this.pendingDeletion,
      consents: consents ?? List<ConsentRecord>.from(this.consents),
      dataResidency: dataResidency ?? this.dataResidency,
    );
  }
}

class PendingDeletion {
  final DateTime requestedAt;
  final DateTime effectiveAt;
  final String status;

  const PendingDeletion({
    required this.requestedAt,
    required this.effectiveAt,
    required this.status,
  });

  factory PendingDeletion.fromJson(Map<String, dynamic> json) {
    return PendingDeletion(
      requestedAt:
          _parseDateTime(json['requestedAt']) ?? DateTime.now().toUtc(),
      effectiveAt:
          _parseDateTime(json['effectiveAt']) ?? DateTime.now().toUtc(),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestedAt': _formatDateTime(requestedAt),
      'effectiveAt': _formatDateTime(effectiveAt),
      'status': status,
    };
  }
}

class ConsentRecord {
  final String id;
  final String label;
  final String? description;
  final DateTime grantedAt;
  final DateTime? expiresAt;
  final String status;

  const ConsentRecord({
    required this.id,
    required this.label,
    this.description,
    required this.grantedAt,
    this.expiresAt,
    required this.status,
  });

  factory ConsentRecord.fromJson(Map<String, dynamic> json) {
    return ConsentRecord(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String?,
      grantedAt: _parseDateTime(json['grantedAt']) ?? DateTime.now().toUtc(),
      expiresAt: _parseDateTime(json['expiresAt']),
      status: json['status'] as String? ?? 'granted',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      if (description != null) 'description': description,
      'grantedAt': _formatDateTime(grantedAt),
      if (expiresAt != null) 'expiresAt': _formatDateTime(expiresAt),
      'status': status,
    };
  }
}

class ActivitySnapshot {
  final List<ActivityEvent> recentEvents;
  final List<DeviceSummary> trustedDevices;

  const ActivitySnapshot({
    required this.recentEvents,
    required this.trustedDevices,
  });

  factory ActivitySnapshot.fromJson(Map<String, dynamic> json) {
    final events = (json['recentEvents'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ActivityEvent.fromJson)
            .toList(growable: false) ??
        const [];
    final devices = (json['trustedDevices'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(DeviceSummary.fromJson)
            .toList(growable: false) ??
        const [];
    return ActivitySnapshot(
      recentEvents: events,
      trustedDevices: devices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recentEvents': recentEvents.map((event) => event.toJson()).toList(),
      'trustedDevices': trustedDevices.map((device) => device.toJson()).toList(),
    };
  }
}

class ActivityEvent {
  final String id;
  final String type;
  final DateTime occurredAt;
  final String summary;
  final String? actor;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.summary,
    this.actor,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'activity',
      occurredAt: _parseDateTime(json['occurredAt']) ?? DateTime.now().toUtc(),
      summary: json['summary'] as String? ?? '',
      actor: json['actor'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'occurredAt': _formatDateTime(occurredAt),
      'summary': summary,
      if (actor != null) 'actor': actor,
    };
  }
}

class DeviceSummary {
  final String id;
  final String agent;
  final DateTime lastSeenAt;
  final String? location;
  final bool isCurrent;

  const DeviceSummary({
    required this.id,
    required this.agent,
    required this.lastSeenAt,
    this.location,
    required this.isCurrent,
  });

  factory DeviceSummary.fromJson(Map<String, dynamic> json) {
    return DeviceSummary(
      id: json['id'] as String? ?? '',
      agent: json['agent'] as String? ?? '',
      lastSeenAt: _parseDateTime(json['lastSeenAt']) ?? DateTime.now().toUtc(),
      location: json['location'] as String?,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent': agent,
      'lastSeenAt': _formatDateTime(lastSeenAt),
      if (location != null) 'location': location,
      'isCurrent': isCurrent,
    };
  }
}
