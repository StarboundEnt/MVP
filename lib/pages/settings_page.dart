import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/health_navigation_profile.dart';
import '../providers/app_state.dart';
import 'complexity_test_page.dart';
import 'emergency_resources_page.dart';
import 'privacy_policy_page.dart';
import 'qr_backup_screen.dart';
import 'qr_restore_screen.dart';

/// Settings Page
/// Profile, barriers, privacy, preferences, and about
class SettingsPage extends StatelessWidget {
  final VoidCallback onGoBack;

  const SettingsPage({Key? key, required this.onGoBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: onGoBack,
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _ProfileCard(
              userName: appState.userName,
              location: appState.healthNavigationProfile?.neighborhood ?? 'Not set',
              languages: appState.healthNavigationProfile?.languages ?? [],
              onEditProfile: () => _showEditProfile(context, appState),
            ),
            const SizedBox(height: 24),

            // Barriers & Preferences Section
            const _SectionHeader(title: 'Barriers & Preferences'),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'Healthcare Barriers',
              subtitle: _formatBarriers(appState.healthNavigationProfile?.barriers),
              icon: Icons.block,
              iconColor: const Color(0xFFE74C3C),
              onTap: () => _showBarriersEditor(context),
            ),
            const SizedBox(height: 8),
            _SettingsCard(
              title: 'Health Interests',
              subtitle: _formatHealthInterests(appState.healthNavigationProfile?.healthInterests),
              icon: Icons.favorite_border,
              iconColor: const Color(0xFFE91E63),
              onTap: () => _showInterestsEditor(context),
            ),
            const SizedBox(height: 24),

            // Privacy & Data Section
            const _SectionHeader(title: 'Privacy & Data'),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'View My Data',
              subtitle: 'See what information is stored',
              icon: Icons.folder_outlined,
              iconColor: const Color(0xFF4ECDC4),
              onTap: () => _showDataViewer(context, appState),
            ),
            const SizedBox(height: 8),
            _SettingsCard(
              title: 'Export Data',
              subtitle: 'Download your health information',
              icon: Icons.download_outlined,
              iconColor: const Color(0xFF3498DB),
              onTap: () => _showExportOptions(context),
            ),
            const SizedBox(height: 8),
            _SettingsCard(
              title: 'Delete Everything',
              subtitle: 'Remove all your data from this app',
              icon: Icons.delete_outline,
              iconColor: const Color(0xFFE74C3C),
              onTap: () => _showDeleteConfirmation(context, appState),
              isDestructive: true,
            ),
            const SizedBox(height: 24),

            // Backup & Transfer Section
            const _SectionHeader(title: 'Backup & Transfer'),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'Create Backup',
              subtitle: 'Generate QR code to transfer data',
              icon: Icons.qr_code,
              iconColor: const Color(0xFF4ECDC4),
              onTap: () => _showBackupScreen(context),
            ),
            const SizedBox(height: 8),
            _SettingsCard(
              title: 'Restore from Backup',
              subtitle: 'Scan QR code from another device',
              icon: Icons.qr_code_scanner,
              iconColor: const Color(0xFF3498DB),
              onTap: () => _showRestoreScreen(context),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            const _SectionHeader(title: 'Preferences'),
            const SizedBox(height: 12),
            _SwitchSettingsCard(
              title: 'Check-in Reminders',
              subtitle: 'Weekly health check-in notifications',
              icon: Icons.notifications_outlined,
              iconColor: const Color(0xFFFFE66D),
              value: appState.notificationsEnabled,
              onChanged: (value) async {
                await appState.updateNotificationSettings(
                    value, appState.notificationTime);
              },
            ),
            const SizedBox(height: 8),
            _SwitchSettingsCard(
              title: 'Home Memory',
              subtitle: 'Remember context between sessions',
              icon: Icons.memory,
              iconColor: const Color(0xFF9B59B6),
              value: appState.homeMemoryEnabled,
              onChanged: (value) async {
                await appState.setHomeMemoryEnabled(value);
              },
            ),
            const SizedBox(height: 8),
            _SettingsCard(
              title: 'Test Complexity Levels',
              subtitle: 'Compare responses across profile capacities',
              icon: Icons.science_outlined,
              iconColor: const Color(0xFF9B59B6),
              onTap: () => _showComplexityTester(context),
            ),
            const SizedBox(height: 24),

            // About Section
            const _SectionHeader(title: 'About'),
            const SizedBox(height: 12),
            _SettingsCard(
              title: 'How This Works',
              subtitle: 'Learn about health navigation',
              icon: Icons.help_outline,
              iconColor: const Color(0xFF4ECDC4),
              onTap: () => _showHowItWorks(context),
            ),
            const SizedBox(height: 8),
            _SettingsCard(
              title: 'Privacy Policy',
              subtitle: 'How we protect your information',
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF3498DB),
              onTap: () => _showPrivacyPolicy(context),
            ),
            const SizedBox(height: 8),
            _SettingsCard(
              title: 'Send Feedback',
              subtitle: 'Help us improve',
              icon: Icons.feedback_outlined,
              iconColor: const Color(0xFF2ECC71),
              onTap: () => _showFeedback(context),
            ),
            const SizedBox(height: 24),

            // Emergency Resources
            _EmergencyButton(
              onTap: () => _showEmergencyResources(context),
            ),
            const SizedBox(height: 24),

            // Version info
            Center(
              child: Column(
                children: [
                  Text(
                    'Starbound Health Navigator',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 2.0.0 (Health Navigation)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: appState.userName);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2838),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await appState.updateUserName(controller.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showBarriersEditor(BuildContext context) {
    _showComingSoon(context, 'Barriers Editor');
  }

  void _showInterestsEditor(BuildContext context) {
    _showComingSoon(context, 'Health Interests');
  }

  void _showDataViewer(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2838),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Data',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _DataItem(
                      label: 'Saved Resources',
                      value: '${appState.savedResources.length} items',
                    ),
                    _DataItem(
                      label: 'Saved Conversations',
                      value: '${appState.savedConversations.length} items',
                    ),
                    _DataItem(
                      label: 'Journal Entries',
                      value: '${appState.freeFormEntries.length} entries',
                    ),
                    _DataItem(
                      label: 'Display Name',
                      value: appState.userName,
                    ),
                    _DataItem(
                      label: 'Notifications',
                      value: appState.notificationsEnabled
                          ? 'Enabled'
                          : 'Disabled',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'All data is stored locally on your device only.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    // Navigate to backup screen for export functionality
    _showBackupScreen(context);
  }

  void _showBackupScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRBackupScreen(),
      ),
    );
  }

  void _showRestoreScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRRestoreScreen(),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Color(0xFFE74C3C)),
            SizedBox(width: 8),
            Text('Delete All Data?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will permanently delete all your saved resources, conversations, journal entries, and preferences. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await appState.resetAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data has been deleted'),
                  backgroundColor: Color(0xFFE74C3C),
                ),
              );
            },
            child: const Text(
              'Delete Everything',
              style: TextStyle(color: Color(0xFFE74C3C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowItWorks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2838),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'How This Works',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    _HelpSection(
                      icon: Icons.home,
                      title: 'Home',
                      description:
                          'Ask any health question and get personalized guidance. The AI helps you understand your health concerns and suggests next steps.',
                    ),
                    SizedBox(height: 16),
                    _HelpSection(
                      icon: Icons.people,
                      title: 'Support Circle',
                      description:
                          'Find health services near you. Resources are matched to your needs based on barriers like cost, transportation, and language.',
                    ),
                    SizedBox(height: 16),
                    _HelpSection(
                      icon: Icons.calendar_today,
                      title: 'Journal',
                      description:
                          'Track your health journey. Log symptoms, medications, and how you\'re feeling to spot patterns over time.',
                    ),
                    SizedBox(height: 16),
                    _HelpSection(
                      icon: Icons.star,
                      title: 'Action Vault',
                      description:
                          'Save important resources and conversations for quick access later. Your personal health reference library.',
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Your Privacy',
                      style: TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All your data stays on your device. We don\'t collect, store, or share your health information. You have full control over your data.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBarriers(List<String>? barriers) {
    if (barriers == null || barriers.isEmpty) return 'None reported';
    return barriers
        .map((b) => HealthNavigationProfile.barrierIdToLabel(b).split('/').first.trim())
        .join(', ');
  }

  String _formatHealthInterests(List<String>? interests) {
    if (interests == null || interests.isEmpty) return 'None selected';
    return interests
        .map((i) => i
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' '))
        .join(', ');
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  void _showFeedback(BuildContext context) {
    _showComingSoon(context, 'Feedback');
  }

  void _showEmergencyResources(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmergencyResourcesPage(),
      ),
    );
  }

  void _showComplexityTester(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ComplexityTestPage(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        backgroundColor: const Color(0xFF1B2838),
      ),
    );
  }
}

/// Section header
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Profile card
class _ProfileCard extends StatelessWidget {
  final String userName;
  final String location;
  final List<String> languages;
  final VoidCallback onEditProfile;

  const _ProfileCard({
    required this.userName,
    required this.location,
    required this.languages,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4ECDC4).withOpacity(0.2),
            const Color(0xFF3498DB).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$location • ${languages.join(", ")}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
            onPressed: onEditProfile,
          ),
        ],
      ),
    );
  }
}

/// Settings card
class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive
              ? const Color(0xFFE74C3C).withOpacity(0.3)
              : Colors.white10,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive
                              ? const Color(0xFFE74C3C)
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDestructive
                      ? const Color(0xFFE74C3C).withOpacity(0.5)
                      : Colors.white38,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Switch settings card
class _SwitchSettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF4ECDC4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Emergency resources button
class _EmergencyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EmergencyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE74C3C).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE74C3C).withOpacity(0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emergency,
                    color: Color(0xFFE74C3C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Resources',
                        style: TextStyle(
                          color: Color(0xFFE74C3C),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Crisis lines, 000, and urgent help',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFE74C3C),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Data item for data viewer
class _DataItem extends StatelessWidget {
  final String label;
  final String value;

  const _DataItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Help section for How It Works
class _HelpSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4ECDC4), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
