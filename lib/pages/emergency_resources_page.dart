import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Emergency Resources Page
/// Quick access to emergency services and crisis support
class EmergencyResourcesPage extends StatelessWidget {
  final VoidCallback? onClose;

  const EmergencyResourcesPage({Key? key, this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: onClose ?? () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Color(0xFFE74C3C), size: 24),
            SizedBox(width: 8),
            Text(
              'Emergency Resources',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE74C3C).withOpacity(0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Color(0xFFE74C3C), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'If you or someone else is in immediate danger, call 000 now.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Triple Zero
            _EmergencyCard(
              title: 'Triple Zero (000)',
              subtitle: 'Police, Fire, Ambulance',
              description: 'For life-threatening emergencies requiring immediate response.',
              phone: '000',
              color: const Color(0xFFE74C3C),
              icon: Icons.emergency,
              isPrimary: true,
            ),
            const SizedBox(height: 16),

            // Section: Crisis Support
            const _SectionHeader(title: 'Crisis Support'),
            const SizedBox(height: 12),

            _EmergencyCard(
              title: 'Lifeline',
              subtitle: '24/7 crisis support',
              description: 'Confidential telephone crisis support for anyone in Australia.',
              phone: '13 11 14',
              color: const Color(0xFF4ECDC4),
              icon: Icons.phone_in_talk,
            ),
            const SizedBox(height: 12),

            _EmergencyCard(
              title: 'Beyond Blue',
              subtitle: 'Mental health support',
              description: 'Immediate support for anxiety, depression and suicide prevention.',
              phone: '1300 22 4636',
              color: const Color(0xFF3498DB),
              icon: Icons.psychology,
            ),
            const SizedBox(height: 12),

            _EmergencyCard(
              title: 'Suicide Call Back Service',
              subtitle: '24/7 support',
              description: 'Professional telephone and online counselling for suicide prevention.',
              phone: '1300 659 467',
              color: const Color(0xFF9B59B6),
              icon: Icons.support_agent,
            ),
            const SizedBox(height: 24),

            // Section: Health Advice
            const _SectionHeader(title: 'Health Advice'),
            const SizedBox(height: 12),

            _EmergencyCard(
              title: 'healthdirect',
              subtitle: '24/7 health advice',
              description: 'Speak to a registered nurse about any health concern.',
              phone: '1800 022 222',
              color: const Color(0xFF2ECC71),
              icon: Icons.medical_services,
            ),
            const SizedBox(height: 12),

            _EmergencyCard(
              title: 'Poisons Information',
              subtitle: '24/7 poison advice',
              description: 'Expert advice on poisoning, overdose, or toxic exposures.',
              phone: '13 11 26',
              color: const Color(0xFFFFE66D),
              icon: Icons.science,
            ),
            const SizedBox(height: 24),

            // Section: Specialised Support
            const _SectionHeader(title: 'Specialised Support'),
            const SizedBox(height: 12),

            _EmergencyCard(
              title: '1800RESPECT',
              subtitle: 'Family & domestic violence',
              description: 'Confidential support for people experiencing domestic or sexual violence.',
              phone: '1800 737 732',
              color: const Color(0xFFE91E63),
              icon: Icons.shield,
            ),
            const SizedBox(height: 12),

            _EmergencyCard(
              title: 'Kids Helpline',
              subtitle: 'For young people 5-25',
              description: 'Counselling and support for children and young adults.',
              phone: '1800 55 1800',
              color: const Color(0xFFFF9800),
              icon: Icons.child_care,
            ),
            const SizedBox(height: 12),

            _EmergencyCard(
              title: 'MensLine Australia',
              subtitle: "Men's support service",
              description: 'Support for men dealing with relationship and family concerns.',
              phone: '1300 78 99 78',
              color: const Color(0xFF00BCD4),
              icon: Icons.person,
            ),
            const SizedBox(height: 12),

            _EmergencyCard(
              title: 'QLife',
              subtitle: 'LGBTIQ+ support',
              description: 'Peer support and referral for LGBTIQ+ Australians.',
              phone: '1800 184 527',
              color: const Color(0xFF9C27B0),
              icon: Icons.favorite,
            ),
            const SizedBox(height: 24),

            // Section: Find Emergency Department
            const _SectionHeader(title: 'Find Help Nearby'),
            const SizedBox(height: 12),

            _ActionCard(
              title: 'Find Nearest Hospital',
              subtitle: 'Emergency department locations',
              icon: Icons.local_hospital,
              color: const Color(0xFF4ECDC4),
              onTap: () => _openMaps('hospital emergency department near me'),
            ),
            const SizedBox(height: 12),

            _ActionCard(
              title: 'Find Nearest Pharmacy',
              subtitle: 'For urgent medication needs',
              icon: Icons.medication,
              color: const Color(0xFF2ECC71),
              onTap: () => _openMaps('pharmacy near me'),
            ),
            const SizedBox(height: 32),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2838),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'This app provides information resources only. It does not provide medical advice, diagnosis, or treatment. Always seek professional medical advice for health concerns.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openMaps(String query) async {
    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse('https://maps.google.com/?q=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

/// Emergency service card with call action
class _EmergencyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String phone;
  final Color color;
  final IconData icon;
  final bool isPrimary;

  const _EmergencyCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.phone,
    required this.color,
    required this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? color.withOpacity(0.2) : const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary ? color.withOpacity(0.5) : Colors.white10,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _makeCall(phone),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isPrimary ? color : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isPrimary ? color.withOpacity(0.8) : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _makeCall(String number) async {
    final cleanNumber = number.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// Action card for maps/navigation
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
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
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
