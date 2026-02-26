import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../models/complexity_profile.dart';
import '../design_system/design_system.dart';

class ComplexityBadge extends StatelessWidget {
  final ComplexityLevel level;
  final VoidCallback? onTap;
  final bool showLabel;
  final bool showDescription;

  const ComplexityBadge({
    Key? key,
    required this.level,
    this.onTap,
    this.showLabel = true,
    this.showDescription = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor(level);
    final levelMessage = ComplexityProfileService.getComplexityLevelMessage(level);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: showDescription ? 16 : 12, 
                vertical: showDescription ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: showDescription
                  ? _buildExpandedBadge(color, levelMessage)
                  : _buildCompactBadge(color, levelMessage),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBadge(Color color, String levelMessage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getLevelIcon(level),
            size: 14,
            color: color,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              levelMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StarboundTypography.bodyLarge.copyWith(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (onTap != null) ...[
          const SizedBox(width: 6),
          Icon(
            LucideIcons.chevronRight,
            size: 12,
            color: color.withValues(alpha: 0.7),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedBadge(Color color, String levelMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getLevelIcon(level),
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                levelMessage,
                style: StarboundTypography.heading3.copyWith(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: color.withValues(alpha: 0.7),
              ),
          ],
        ),

      ],
    );
  }

  Color _getLevelColor(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return StarboundColors.success;
      case ComplexityLevel.trying:
        return StarboundColors.stellarYellow;
      case ComplexityLevel.overloaded:
        return StarboundColors.warning;
      case ComplexityLevel.survival:
        return StarboundColors.error;
    }
  }

  IconData _getLevelIcon(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return LucideIcons.check;
      case ComplexityLevel.trying:
        return LucideIcons.trendingUp;
      case ComplexityLevel.overloaded:
        return LucideIcons.zap;
      case ComplexityLevel.survival:
        return LucideIcons.shield;
    }
  }

}

/// Animated complexity badge that pulses gently
class AnimatedComplexityBadge extends StatefulWidget {
  final ComplexityLevel level;
  final VoidCallback? onTap;
  final bool showLabel;
  final bool showDescription;

  const AnimatedComplexityBadge({
    Key? key,
    required this.level,
    this.onTap,
    this.showLabel = true,
    this.showDescription = false,
  }) : super(key: key);

  @override
  State<AnimatedComplexityBadge> createState() => _AnimatedComplexityBadgeState();
}

class _AnimatedComplexityBadgeState extends State<AnimatedComplexityBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: ComplexityBadge(
            level: widget.level,
            onTap: widget.onTap,
            showLabel: widget.showLabel,
            showDescription: widget.showDescription,
          ),
        );
      },
    );
  }
}
