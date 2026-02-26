import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system.dart';

/// Cosmic Chip - Selection chips with orbital animations and stellar styling
/// 
/// Features:
/// - Orbital selection animations
/// - Stellar glow effects when selected
/// - Smooth transitions
/// - Haptic feedback
/// - Multiple variants (choice, filter, action)
class CosmicChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;
  final CosmicChipVariant variant;
  final bool hapticFeedback;
  final bool enabled;

  const CosmicChip({
    Key? key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.color,
    this.variant = CosmicChipVariant.choice,
    this.hapticFeedback = true,
    this.enabled = true,
  }) : super(key: key);

  /// Choice chip for single/multiple selection
  const CosmicChip.choice({
    Key? key,
    required String label,
    bool isSelected = false,
    VoidCallback? onTap,
    IconData? icon,
    Color? color,
    bool hapticFeedback = true,
    bool enabled = true,
  }) : this(
          key: key,
          label: label,
          isSelected: isSelected,
          onTap: onTap,
          icon: icon,
          color: color,
          variant: CosmicChipVariant.choice,
          hapticFeedback: hapticFeedback,
          enabled: enabled,
        );

  /// Filter chip for filtering content
  const CosmicChip.filter({
    Key? key,
    required String label,
    bool isSelected = false,
    VoidCallback? onTap,
    IconData? icon,
    Color? color,
    bool hapticFeedback = true,
    bool enabled = true,
  }) : this(
          key: key,
          label: label,
          isSelected: isSelected,
          onTap: onTap,
          icon: icon,
          color: color,
          variant: CosmicChipVariant.filter,
          hapticFeedback: hapticFeedback,
          enabled: enabled,
        );

  /// Action chip for triggering actions
  const CosmicChip.action({
    Key? key,
    required String label,
    VoidCallback? onTap,
    IconData? icon,
    Color? color,
    bool hapticFeedback = true,
    bool enabled = true,
  }) : this(
          key: key,
          label: label,
          isSelected: false,
          onTap: onTap,
          icon: icon,
          color: color,
          variant: CosmicChipVariant.action,
          hapticFeedback: hapticFeedback,
          enabled: enabled,
        );

  @override
  State<CosmicChip> createState() => _CosmicChipState();
}

class _CosmicChipState extends State<CosmicChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _orbitalAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _controller = StarboundAnimations.createCosmicController(
      vsync: this,
      duration: StarboundAnimations.medium,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(StarboundAnimations.createStellarCurve(parent: _controller));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(StarboundAnimations.createStellarCurve(parent: _controller));
    
    _orbitalAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: StarboundAnimations.nebulaEase,
    ));

    // Animate to selected state if initially selected
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CosmicChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate selection changes
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onTap != null) {
      setState(() => _isPressed = true);
      
      if (widget.hapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleHover(bool isHovering) {
    setState(() => _isHovered = isHovering);
  }

  @override
  Widget build(BuildContext context) {
    final chipStyle = _getChipStyle();
    
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: Container(
                padding: StarboundSpacing.paddingSM.copyWith(
                  left: StarboundSpacing.md,
                  right: StarboundSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: chipStyle.backgroundColor,
                  borderRadius: StarboundSpacing.radiusPill,
                  border: chipStyle.border,
                  boxShadow: _buildShadow(chipStyle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      _buildIcon(chipStyle),
                      StarboundSpacing.hSpaceXS,
                    ],
                    Text(
                      widget.label,
                      style: chipStyle.textStyle,
                    ),
                    if (widget.isSelected && widget.variant == CosmicChipVariant.choice) ...[
                      StarboundSpacing.hSpaceXS,
                      _buildSelectionIndicator(chipStyle),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIcon(_ChipStyle style) {
    return AnimatedBuilder(
      animation: _orbitalAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.isSelected ? _orbitalAnimation.value * 0.5 : 0.0,
          child: Icon(
            widget.icon,
            size: 16,
            color: style.iconColor,
          ),
        );
      },
    );
  }

  Widget _buildSelectionIndicator(_ChipStyle style) {
    return AnimatedBuilder(
      animation: _orbitalAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _orbitalAnimation.value,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.iconColor,
              boxShadow: StarboundColors.cosmicGlow(
                style.iconColor,
                intensity: 0.3 * _orbitalAnimation.value,
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 12,
              color: style.backgroundColor,
            ),
          ),
        );
      },
    );
  }

  List<BoxShadow> _buildShadow(_ChipStyle style) {
    final baseShadow = style.shadow;
    
    if (widget.isSelected || _isHovered) {
      final glowColor = widget.color ?? StarboundColors.stellarAqua;
      return [
        ...baseShadow,
        ...StarboundColors.cosmicGlow(
          glowColor,
          intensity: widget.isSelected 
            ? 0.2 + (0.1 * _glowAnimation.value)
            : 0.1,
        ),
      ];
    }
    
    return baseShadow;
  }

  _ChipStyle _getChipStyle() {
    final isEnabled = widget.enabled;
    final accentColor = widget.color ?? StarboundColors.stellarAqua;
    
    if (!isEnabled) {
      return _ChipStyle(
        backgroundColor: StarboundColors.surface.withValues(alpha: 0.5),
        textStyle: StarboundTypography.caption.copyWith(
          color: StarboundColors.textDisabled,
        ),
        iconColor: StarboundColors.textDisabled,
        border: Border.all(
          color: StarboundColors.borderSubtle,
          width: 1,
        ),
        shadow: [],
      );
    }
    
    switch (widget.variant) {
      case CosmicChipVariant.choice:
        if (widget.isSelected) {
          return _ChipStyle(
            backgroundColor: accentColor.withValues(alpha: 0.15),
            textStyle: StarboundTypography.caption.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
            iconColor: accentColor,
            border: Border.all(
              color: accentColor,
              width: 1.5,
            ),
            shadow: StarboundColors.subtleShadow,
          );
        } else {
          return _ChipStyle(
            backgroundColor: StarboundColors.surface,
            textStyle: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
            ),
            iconColor: StarboundColors.textTertiary,
            border: Border.all(
              color: _isHovered 
                ? StarboundColors.borderEmphasis 
                : StarboundColors.borderDefault,
              width: 1,
            ),
            shadow: [],
          );
        }
        
      case CosmicChipVariant.filter:
        if (widget.isSelected) {
          return _ChipStyle(
            backgroundColor: accentColor,
            textStyle: StarboundTypography.caption.copyWith(
              color: StarboundColors.deepSpace,
              fontWeight: FontWeight.w600,
            ),
            iconColor: StarboundColors.deepSpace,
            border: null,
            shadow: StarboundColors.elevatedShadow,
          );
        } else {
          return _ChipStyle(
            backgroundColor: Colors.transparent,
            textStyle: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
            ),
            iconColor: StarboundColors.textTertiary,
            border: Border.all(
              color: _isHovered 
                ? accentColor 
                : StarboundColors.borderDefault,
              width: 1,
            ),
            shadow: [],
          );
        }
        
      case CosmicChipVariant.action:
        return _ChipStyle(
          backgroundColor: _isHovered 
            ? accentColor.withValues(alpha: 0.1)
            : Colors.transparent,
          textStyle: StarboundTypography.caption.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w500,
          ),
          iconColor: accentColor,
          border: Border.all(
            color: accentColor,
            width: 1,
          ),
          shadow: [],
        );
    }
  }
}

/// Chip variants
enum CosmicChipVariant {
  choice,
  filter,
  action,
}

/// Internal chip style configuration
class _ChipStyle {
  final Color backgroundColor;
  final TextStyle textStyle;
  final Color iconColor;
  final Border? border;
  final List<BoxShadow> shadow;

  const _ChipStyle({
    required this.backgroundColor,
    required this.textStyle,
    required this.iconColor,
    this.border,
    required this.shadow,
  });
}