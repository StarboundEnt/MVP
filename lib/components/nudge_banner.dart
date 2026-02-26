import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NudgeBanner extends StatelessWidget {
  final String nudge;
  final VoidCallback onBankNudge;

  const NudgeBanner({
    Key? key,
    required this.nudge,
    required this.onBankNudge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nudge,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onBankNudge,
              icon: const Icon(Icons.bookmark_outline, size: 16, color: Colors.white),
              label: const Text(
                "Save to Vault",
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}