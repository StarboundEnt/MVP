import 'package:flutter/material.dart';
import '../design_system/design_system.dart';
import '../models/home_response.dart';

class HomeResponseCard extends StatelessWidget {
  final HomeResponseData response;
  final VoidCallback? onWhyThis;

  const HomeResponseCard({
    Key? key,
    required this.response,
    this.onWhyThis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CosmicGlassPanel.surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT MATTERS',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textTertiary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            response.whatMatters,
            style: StarboundTypography.bodyLarge.copyWith(
              color: StarboundColors.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NEXT STEP',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textTertiary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            response.nextStep,
            style: StarboundTypography.bodyLarge.copyWith(
              color: StarboundColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (onWhyThis != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onWhyThis,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: StarboundColors.starlightBlue,
                ),
                child: const Text('Why this?'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
