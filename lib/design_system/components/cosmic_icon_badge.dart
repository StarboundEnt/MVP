import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';

/// Circular icon badge with consistent glow and tint.
class CosmicIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final EdgeInsetsGeometry padding;
  final double glowIntensity;
  final Color? backgroundColor;

  const CosmicIconBadge({
    Key? key,
    required this.icon,
    this.color = StarboundColors.stellarAqua,
    this.size = 18,
    this.padding = const EdgeInsets.all(10),
    this.glowIntensity = 0.2,
    this.backgroundColor,
  }) : super(key: key);

  factory CosmicIconBadge.info({
    Key? key,
    required IconData icon,
  }) {
    return CosmicIconBadge(
      key: key,
      icon: icon,
      color: StarboundColors.starlightBlue,
    );
  }

  factory CosmicIconBadge.success({
    Key? key,
    required IconData icon,
  }) {
    return CosmicIconBadge(
      key: key,
      icon: icon,
      color: StarboundColors.stellarAqua,
    );
  }

  factory CosmicIconBadge.alert({
    Key? key,
    required IconData icon,
  }) {
    return CosmicIconBadge(
      key: key,
      icon: icon,
      color: StarboundColors.solarOrange,
      glowIntensity: 0.3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color badgeBackground =
        backgroundColor ?? color.withValues(alpha: 0.18);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: badgeBackground,
        boxShadow: StarboundColors.cosmicGlow(
          color,
          intensity: glowIntensity,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}
