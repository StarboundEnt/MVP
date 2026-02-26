import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PolicySection(
              title: 'Your Data Stays on Your Device',
              body:
                  'Starbound stores all your personal health information — including journal entries, habit data, and health assessments — locally on your device. We do not upload your health data to external servers or third-party services without your explicit consent.',
            ),
            _PolicySection(
              title: 'What We Collect',
              body:
                  'To provide personalised health navigation support, Starbound collects:\n\n'
                  '• Your chosen display name\n'
                  '• Your suburb or neighbourhood (for finding local services)\n'
                  '• Languages you speak\n'
                  '• Healthcare barriers you have identified\n'
                  '• Health topics you are interested in\n'
                  '• Journal entries and habit check-ins you create\n'
                  '• Your responses to the onboarding assessment\n\n'
                  'This information is stored in encrypted local storage on your device.',
            ),
            _PolicySection(
              title: 'AI Responses',
              body:
                  'When you ask Starbound a health question, your query is sent to an AI language model (via OpenRouter) to generate a response. Your question text is transmitted but is not linked to your name or personal profile. Please do not include identifying information in your questions.',
            ),
            _PolicySection(
              title: 'How We Use Your Data',
              body:
                  'Your data is used solely to:\n\n'
                  '• Personalise health resource recommendations for your situation\n'
                  '• Track your health habits and journal entries over time\n'
                  '• Adapt the app experience to your complexity level\n'
                  '• Generate locally relevant resources based on your suburb\n\n'
                  'We do not sell, rent, or share your personal data with third parties.',
            ),
            _PolicySection(
              title: 'Data Export & Deletion',
              body:
                  'You can export a copy of all your data at any time via Settings → Export Data. '
                  'You can permanently delete all your data via Settings → Delete Everything. '
                  'Both actions are immediate and irreversible.',
            ),
            _PolicySection(
              title: 'QR Code Backup',
              body:
                  'If you use the QR backup feature, your data is encoded into a QR code that you control. '
                  'Starbound does not store backup data on any server. '
                  'Keep your backup QR codes private.',
            ),
            _PolicySection(
              title: 'Security',
              body:
                  'All locally stored data is encrypted using Flutter Secure Storage. '
                  'Network communications with the backend use HTTPS. '
                  'Biometric authentication (Face ID / Touch ID) is available as an additional layer of protection where supported by your device.',
            ),
            _PolicySection(
              title: 'Children',
              body:
                  'Starbound is not intended for use by children under 16. '
                  'We do not knowingly collect information from children.',
            ),
            _PolicySection(
              title: 'Changes to This Policy',
              body:
                  'If we make material changes to this privacy policy, we will notify you within the app before the changes take effect.',
            ),
            _PolicySection(
              title: 'Contact',
              body:
                  'If you have questions about your privacy or how your data is handled, please use the Send Feedback option in Settings.',
            ),
            SizedBox(height: 8),
            Text(
              'Last updated: February 2026',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4ECDC4),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
