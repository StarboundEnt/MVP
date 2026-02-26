import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';
import '../typography.dart';

/// A reusable capsule-style header that keeps Starbound pages consistent.
class CosmicCapsuleHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? titleIcon;
  final Widget? leading;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final EdgeInsetsGeometry margin;
  final Color? accentColor;

  const CosmicCapsuleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleIcon,
    this.leading,
    this.onBack,
    this.actions,
    this.margin = const EdgeInsets.fromLTRB(24, 12, 24, 12),
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> trailingActions = actions ?? const [];
    final Widget? badge = leading ??
        (titleIcon != null
            ? _TitleBadge(
                icon: titleIcon!,
                accentColor: accentColor ?? StarboundColors.stellarAqua,
              )
            : null);

    final BoxDecoration capsuleDecoration = BoxDecoration(
      color: StarboundColors.surfaceElevated.withOpacity(0.68),
      borderRadius: BorderRadius.circular(36),
      border: Border.all(
        color: StarboundColors.cosmicWhite.withValues(alpha: 0.12),
      ),
      boxShadow: [
        BoxShadow(
          color: StarboundColors.nebulaPurple.withValues(alpha: 0.16),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: capsuleDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null)
            CosmicCapsuleIconButton.back(
              onPressed: onBack!,
            ),
          if (onBack != null) StarboundSpacing.hSpaceSM,
          if (badge != null) ...[
            badge,
            StarboundSpacing.hSpaceSM,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: StarboundTypography.heading2.copyWith(
                    color: StarboundColors.cosmicWhite,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  StarboundSpacing.spaceXS,
                  Text(
                    subtitle!,
                    style: StarboundTypography.bodySmall.copyWith(
                      color: StarboundColors.cosmicWhite.withValues(alpha: 0.72),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingActions.isNotEmpty) StarboundSpacing.hSpaceMD,
          if (trailingActions.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: trailingActions,
            ),
        ],
      ),
    );
  }
}

/// Standard icon button used inside [CosmicCapsuleHeader].
class CosmicCapsuleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color backgroundColor;
  final Color iconColor;

  const CosmicCapsuleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor = Colors.transparent,
    this.iconColor = StarboundColors.cosmicWhite,
  });

  const CosmicCapsuleIconButton.back({
    super.key,
    required VoidCallback onPressed,
  })  : icon = Icons.arrow_back_ios_new,
        onPressed = onPressed,
        tooltip = 'Back',
        backgroundColor = const Color(0x1AFAFBFC),
        iconColor = StarboundColors.cosmicWhite;

  factory CosmicCapsuleIconButton.glass({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return CosmicCapsuleIconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: StarboundColors.surfaceOverlay.withValues(alpha: 0.65),
      iconColor: StarboundColors.cosmicWhite,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget button = Ink(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: StarboundColors.cosmicWhite.withValues(alpha: 0.16),
          width: backgroundColor.opacity > 0 ? 1 : 0,
        ),
        boxShadow: backgroundColor.opacity > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
      ),
    );

    return Semantics(
      button: true,
      label: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: tooltip ?? '',
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: button,
          ),
        ),
      ),
    );
  }
}

class _TitleBadge extends StatelessWidget {
  final IconData icon;
  final Color accentColor;

  const _TitleBadge({
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StarboundColors.deepSpace,
            StarboundColors.surfaceElevated,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: accentColor.withValues(alpha: 0.65),
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: StarboundColors.cosmicWhite,
      ),
    );
  }
}
