import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../design_system/design_system.dart';
import '../models/user_profile_payload.dart';
import '../providers/user_profile_controller.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late final UserProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UserProfileController();
    scheduleMicrotask(() => _controller.loadProfile());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<UserProfileController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: StarboundColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Profile',
                style: StarboundTypography.heading2.copyWith(
                  color: StarboundColors.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: controller.isLoading
                      ? null
                      : () => controller.loadProfile(forceRefresh: true),
                ),
              ],
            ),
            body: _buildBody(context, controller),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserProfileController controller,
  ) {
    final profile = controller.profile;
    if (controller.isLoading && profile == null) {
      return const Center(
        child: CosmicLoading(
          style: CosmicLoadingStyle.orbital,
          message: 'Loading profile...',
        ),
      );
    }

    if (controller.error != null && profile == null) {
      return _ErrorView(
        message: controller.error!,
        onRetry: () => controller.loadProfile(forceRefresh: true),
      );
    }

    if (profile == null) {
      return _ErrorView(
        message: 'No profile information available.',
        onRetry: () => controller.loadProfile(forceRefresh: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadProfile(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
        children: [
          _IdentitySection(
            profile: profile,
            isMutating: controller.isMutating,
            onEditDisplayName: () => _showEditDisplayNameDialog(controller, profile),
          ),
          const SizedBox(height: 16),
          _AccountSection(account: profile.account),
          const SizedBox(height: 16),
          _SecuritySection(
            security: profile.security,
            isMutating: controller.isMutating,
            onRevokeSession: (session) =>
                _confirmRevokeSession(context, controller, session),
          ),
          const SizedBox(height: 16),
          _PersonalizationSection(
            personalization: profile.personalization,
            isMutating: controller.isMutating,
            onEditTimeZone: () => _showEditTimeZoneDialog(controller, profile),
          ),
          const SizedBox(height: 16),
          _IntegrationsSection(integrations: profile.integrations),
          const SizedBox(height: 16),
          _ComplianceSection(
            compliance: profile.compliance,
            isMutating: controller.isMutating,
            onRequestExport: () => _requestDataExport(context, controller),
          ),
          if (profile.activity != null) ...[
            const SizedBox(height: 16),
            _ActivitySection(activity: profile.activity!),
          ],
          const SizedBox(height: 24),
          Text(
            'Last updated ${_formatTimestamp(profile.lastUpdatedAt)}',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDisplayNameDialog(
    UserProfileController controller,
    UserProfilePayload profile,
  ) async {
    final textController = TextEditingController(text: profile.displayName);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: StarboundColors.deepSpace,
          title: Text(
            'Edit Display Name',
            style: StarboundTypography.heading3.copyWith(
              color: StarboundColors.textPrimary,
            ),
          ),
          content: CosmicInput(
            controller: textController,
            hintText: 'Enter display name',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CosmicButton.primary(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await controller.updateDisplayName(textController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Display name updated'),
            backgroundColor: StarboundColors.stellarAqua,
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not update display name'),
            backgroundColor: StarboundColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showEditTimeZoneDialog(
    UserProfileController controller,
    UserProfilePayload profile,
  ) async {
    final textController =
        TextEditingController(text: profile.personalization.timeZone);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: StarboundColors.deepSpace,
          title: Text(
            'Update Time Zone',
            style: StarboundTypography.heading3.copyWith(
              color: StarboundColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CosmicInput(
                controller: textController,
                hintText: 'e.g., America/Los_Angeles',
              ),
              const SizedBox(height: 12),
              Text(
                'Use IANA time zone format for consistency.',
                style: StarboundTypography.caption.copyWith(
                  color: StarboundColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CosmicButton.primary(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await controller.updateTimeZone(textController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Time zone updated'),
            backgroundColor: StarboundColors.stellarAqua,
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not update time zone'),
            backgroundColor: StarboundColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmRevokeSession(
    BuildContext context,
    UserProfileController controller,
    SessionSummary session,
  ) async {
    final shouldRevoke = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: StarboundColors.deepSpace,
          title: Text(
            'Revoke session?',
            style: StarboundTypography.heading3.copyWith(
              color: StarboundColors.textPrimary,
            ),
          ),
          content: Text(
            'Remove access for ${session.device} (${session.platform})?',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CosmicButton.primary(
              onPressed: () => Navigator.of(context).pop(true),
              accentColor: StarboundColors.error,
              child: const Text('Revoke'),
            ),
          ],
        );
      },
    );

    if (shouldRevoke != true) return;

    try {
      await controller.revokeSessions([session.id]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Revoked ${session.device} session'),
          backgroundColor: StarboundColors.stellarAqua,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not revoke session'),
          backgroundColor: StarboundColors.error,
        ),
      );
    }
  }

  Future<void> _requestDataExport(
    BuildContext context,
    UserProfileController controller,
  ) async {
    try {
      final job = await controller.requestDataExport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export requested · Job ${job.jobId}'),
          backgroundColor: StarboundColors.stellarAqua,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not request data export'),
          backgroundColor: StarboundColors.error,
        ),
      );
    }
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({
    required this.profile,
    required this.isMutating,
    required this.onEditDisplayName,
  });

  final UserProfilePayload profile;
  final bool isMutating;
  final VoidCallback onEditDisplayName;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Identity',
      trailing: CosmicButton.secondary(
        onPressed: isMutating ? null : onEditDisplayName,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 18),
            const SizedBox(width: 6),
            const Text('Edit name'),
          ],
        ),
      ),
      children: [
        Text(
          profile.displayName,
          style: StarboundTypography.heading2.copyWith(
            color: StarboundColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (profile.featureFlags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.featureFlags
                .map<Widget>(
                  (flag) => CosmicChip.choice(
                    label: flag,
                    icon: Icons.explore_outlined,
                    isSelected: true,
                    enabled: false,
                  ),
                )
                .toList(),
          )
        else
          Text(
            'No experimental features enabled.',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.account});

  final AccountDetails account;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Account',
      children: [
        _InfoRow(label: 'Role', value: account.role.toUpperCase()),
        if (account.organization != null)
          _InfoRow(
            label: 'Organization',
            value: account.organization!.name,
          ),
        _InfoRow(
          label: 'Managed by org',
          value: account.managedByOrganization ? 'Yes' : 'No',
        ),
        _InfoRow(
          label: 'Plan tier',
          value: account.planTier.toUpperCase(),
        ),
        if (account.joinDate != null)
          _InfoRow(
            label: 'Joined',
            value: _formatTimestamp(account.joinDate!),
          ),
        if (account.lastActiveAt != null)
          _InfoRow(
            label: 'Last active',
            value: _formatTimestamp(account.lastActiveAt!),
          ),
        if (account.teams.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Teams',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: account.teams
                .map(
                  (team) => CosmicChip.choice(
                    label: team.name,
                    isSelected: false,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection({
    required this.security,
    required this.isMutating,
    required this.onRevokeSession,
  });

  final SecurityOverview security;
  final bool isMutating;
  final ValueChanged<SessionSummary> onRevokeSession;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Security',
      children: [
        _InfoRow(
          label: 'Password updated',
          value: security.passwordLastChangedAt != null
              ? _formatTimestamp(security.passwordLastChangedAt!)
              : 'Not set',
        ),
        const SizedBox(height: 12),
        Text(
          'Multi-factor authentication',
          style: StarboundTypography.caption.copyWith(
            color: StarboundColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              security.mfa.enabled
                  ? Icons.verified_user_outlined
                  : Icons.warning_amber_outlined,
              color: security.mfa.enabled
                  ? StarboundColors.stellarAqua
                  : StarboundColors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                security.mfa.enabled
                    ? 'Enabled (${security.mfa.methods.join(', ')})'
                    : 'Disabled',
                style: StarboundTypography.body.copyWith(
                  color: StarboundColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (security.ssoProviders.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Linked SSO providers',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: security.ssoProviders
                .map(
                  (provider) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link_outlined),
                    title: Text(
                      provider.name.toUpperCase(),
                      style: StarboundTypography.body.copyWith(
                        color: StarboundColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Connected ${_formatTimestamp(provider.connectedAt)}',
                      style: StarboundTypography.caption.copyWith(
                        color: StarboundColors.textSecondary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        if (security.activeSessions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Active sessions',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: security.activeSessions
                .map(
                  (session) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: StarboundColors.deepSpace,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: session.isCurrent
                            ? StarboundColors.stellarAqua.withValues(alpha: 0.2)
                            : StarboundColors.cosmicWhite
                                .withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              session.isCurrent
                                  ? Icons.computer
                                  : Icons.devices_other_outlined,
                              color: session.isCurrent
                                  ? StarboundColors.stellarAqua
                                  : StarboundColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                session.device,
                                style: StarboundTypography.bodyLarge.copyWith(
                                  color: StarboundColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              session.riskLevel.toUpperCase(),
                              style: StarboundTypography.caption.copyWith(
                                color: session.riskLevel == 'high'
                                    ? StarboundColors.error
                                    : StarboundColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session.platform} · Last seen ${_formatTimestamp(session.lastSeenAt)}',
                          style: StarboundTypography.caption.copyWith(
                            color: StarboundColors.textSecondary,
                          ),
                        ),
                        if (session.ip != null)
                          Text(
                            'IP ${session.ip}',
                            style: StarboundTypography.caption.copyWith(
                              color: StarboundColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CosmicButton.secondary(
                            onPressed: isMutating || session.isCurrent
                                ? null
                                : () => onRevokeSession(session),
                            accentColor: StarboundColors.error,
                            child: const Text('Revoke'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ] else
          Text(
            'No active sessions detected.',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _PersonalizationSection extends StatelessWidget {
  const _PersonalizationSection({
    required this.personalization,
    required this.isMutating,
    required this.onEditTimeZone,
  });

  final PersonalizationSettings personalization;
  final bool isMutating;
  final VoidCallback onEditTimeZone;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Personalization',
      trailing: CosmicButton.secondary(
        onPressed: isMutating ? null : onEditTimeZone,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_outlined, size: 18),
            const SizedBox(width: 6),
            const Text('Change time zone'),
          ],
        ),
      ),
      children: [
        _InfoRow(
          label: 'Time zone',
          value: personalization.timeZone,
        ),
      ],
    );
  }
}

class _IntegrationsSection extends StatelessWidget {
  const _IntegrationsSection({required this.integrations});

  final IntegrationState integrations;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Integrations',
      children: [
        if (integrations.connectedApps.isNotEmpty) ...[
          Text(
            'Connected apps',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          ...integrations.connectedApps.map(
            (app) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.extension,
                color: app.status == 'active'
                    ? StarboundColors.stellarAqua
                    : StarboundColors.textSecondary,
              ),
              title: Text(
                app.name,
                style: StarboundTypography.body.copyWith(
                  color: StarboundColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Connected ${_formatTimestamp(app.connectedAt)}'
                '${app.lastSyncAt != null ? ' · Last sync ${_formatTimestamp(app.lastSyncAt!)}' : ''}',
                style: StarboundTypography.caption.copyWith(
                  color: StarboundColors.textSecondary,
                ),
              ),
            ),
          ),
        ] else
          Text(
            'No connected applications.',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
        const SizedBox(height: 16),
        if (integrations.apiTokens.isNotEmpty) ...[
          Text(
            'API tokens',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          ...integrations.apiTokens.map(
            (token) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.vpn_key_outlined),
              title: Text(
                token.label,
                style: StarboundTypography.body.copyWith(
                  color: StarboundColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Created ${_formatTimestamp(token.createdAt)}'
                '${token.lastUsedAt != null ? ' · Last used ${_formatTimestamp(token.lastUsedAt!)}' : ''}',
                style: StarboundTypography.caption.copyWith(
                  color: StarboundColors.textSecondary,
                ),
              ),
              trailing: Text(
                token.status.toUpperCase(),
                style: StarboundTypography.caption.copyWith(
                  color: token.status == 'active'
                      ? StarboundColors.stellarAqua
                      : StarboundColors.textSecondary,
                ),
              ),
            ),
          ),
        ] else
          Text(
            'No API tokens issued.',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _ComplianceSection extends StatelessWidget {
  const _ComplianceSection({
    required this.compliance,
    required this.isMutating,
    required this.onRequestExport,
  });

  final ComplianceCenter compliance;
  final bool isMutating;
  final VoidCallback onRequestExport;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Compliance & data',
      trailing: CosmicButton.secondary(
        onPressed: isMutating ? null : onRequestExport,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_outlined, size: 18),
            const SizedBox(width: 6),
            const Text('Request export'),
          ],
        ),
      ),
      children: [
        _InfoRow(
          label: 'Last export',
          value: compliance.lastExportAt != null
              ? _formatTimestamp(compliance.lastExportAt!)
              : 'No exports yet',
        ),
        if (compliance.pendingDeletion != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StarboundColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deletion scheduled',
                  style: StarboundTypography.body.copyWith(
                    color: StarboundColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Effective ${_formatTimestamp(compliance.pendingDeletion!.effectiveAt)}',
                  style: StarboundTypography.caption.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Consents',
          style: StarboundTypography.caption.copyWith(
            color: StarboundColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        if (compliance.consents.isNotEmpty)
          Column(
            children: compliance.consents
                .map(
                  (consent) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      consent.status == 'granted'
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: consent.status == 'granted'
                          ? StarboundColors.stellarAqua
                          : StarboundColors.error,
                    ),
                    title: Text(
                      consent.label,
                      style: StarboundTypography.body.copyWith(
                        color: StarboundColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Granted ${_formatTimestamp(consent.grantedAt)}'
                      '${consent.expiresAt != null ? ' · Expires ${_formatTimestamp(consent.expiresAt!)}' : ''}',
                      style: StarboundTypography.caption.copyWith(
                        color: StarboundColors.textSecondary,
                      ),
                    ),
                  ),
                )
                .toList(),
          )
        else
          Text(
            'No consent records found.',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.activity});

  final ActivitySnapshot activity;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent activity',
      children: [
        if (activity.recentEvents.isNotEmpty) ...[
          Text(
            'Events',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          ...activity.recentEvents.map(
            (event) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.timeline_outlined,
                color: StarboundColors.textSecondary,
              ),
              title: Text(
                event.summary,
                style: StarboundTypography.body.copyWith(
                  color: StarboundColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '${event.type.toUpperCase()} · ${_formatTimestamp(event.occurredAt)}',
                style: StarboundTypography.caption.copyWith(
                  color: StarboundColors.textSecondary,
                ),
              ),
            ),
          ),
        ] else
          Text(
            'No recent events.',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
        const SizedBox(height: 16),
        if (activity.trustedDevices.isNotEmpty) ...[
          Text(
            'Trusted devices',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          ...activity.trustedDevices.map(
            (device) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                device.isCurrent ? Icons.devices : Icons.devices_other_outlined,
                color: device.isCurrent
                    ? StarboundColors.stellarAqua
                    : StarboundColors.textSecondary,
              ),
              title: Text(
                device.agent,
                style: StarboundTypography.body.copyWith(
                  color: StarboundColors.textPrimary,
                ),
              ),
              subtitle: Text(
                [
                  if (device.location != null) device.location!,
                  'Last seen ${_formatTimestamp(device.lastSeenAt)}',
                ].join(' · '),
                style: StarboundTypography.caption.copyWith(
                  color: StarboundColors.textSecondary,
                ),
              ),
            ),
          ),
        ] else
          Text(
            'No trusted devices recorded.',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StarboundColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: StarboundColors.cosmicWhite.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: StarboundTypography.heading3.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          ..._addSpacing(children),
        ],
      ),
    );
  }

  List<Widget> _addSpacing(List<Widget> children) {
    if (children.isEmpty) return const [];
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i != children.length - 1) {
        spaced.add(const SizedBox(height: 12));
      }
    }
    return spaced;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: StarboundColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load profile',
              style: StarboundTypography.heading3.copyWith(
                color: StarboundColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: StarboundTypography.body.copyWith(
                color: StarboundColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CosmicButton.primary(
              onPressed: onRetry,
              child: const Text('Try again'),
            )
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime value) {
  final formatter = DateFormat('MMM d, yyyy · HH:mm');
  return formatter.format(value.toLocal());
}
