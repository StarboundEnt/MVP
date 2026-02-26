import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system.dart';

/// Cosmic Button - Enhanced button with retro-futuristic styling and stellar effects
/// 
/// Features:
/// - Smooth animations with cosmic timing
/// - Stellar glow effects
/// - Haptic feedback
/// - Accessibility support
/// - Multiple variants (primary, secondary, ghost)
class CosmicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final CosmicButtonVariant variant;
  final CosmicButtonSize size;
  final bool isLoading;
  final bool hapticFeedback;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final IconData? icon;
  final bool iconTrailing;
  final Color? accentColor;
  final String? loadingLabel;
  final Color? foregroundColor;

  const CosmicButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.variant = CosmicButtonVariant.primary,
    this.size = CosmicButtonSize.medium,
    this.isLoading = false,
    this.hapticFeedback = true,
    this.padding,
    this.width,
    this.icon,
    this.iconTrailing = false,
    this.accentColor,
    this.loadingLabel,
    this.foregroundColor,
  }) : super(key: key);

  /// Primary button with stellar glow
  const CosmicButton.primary({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    CosmicButtonSize size = CosmicButtonSize.medium,
    bool isLoading = false,
    bool hapticFeedback = true,
    EdgeInsetsGeometry? padding,
    double? width,
    IconData? icon,
    bool iconTrailing = false,
    Color? accentColor,
    String? loadingLabel,
    Color? foregroundColor,
  }) : this(
          key: key,
          child: child,
          onPressed: onPressed,
          variant: CosmicButtonVariant.primary,
          size: size,
          isLoading: isLoading,
          hapticFeedback: hapticFeedback,
          padding: padding,
          width: width,
          icon: icon,
          iconTrailing: iconTrailing,
          accentColor: accentColor,
          loadingLabel: loadingLabel,
          foregroundColor: foregroundColor,
        );

  /// Secondary button with border
  const CosmicButton.secondary({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    CosmicButtonSize size = CosmicButtonSize.medium,
    bool isLoading = false,
    bool hapticFeedback = true,
    EdgeInsetsGeometry? padding,
    double? width,
    IconData? icon,
    bool iconTrailing = false,
    Color? accentColor,
    String? loadingLabel,
    Color? foregroundColor,
  }) : this(
          key: key,
          child: child,
          onPressed: onPressed,
          variant: CosmicButtonVariant.secondary,
          size: size,
          isLoading: isLoading,
          hapticFeedback: hapticFeedback,
          padding: padding,
          width: width,
          icon: icon,
          iconTrailing: iconTrailing,
          accentColor: accentColor,
          loadingLabel: loadingLabel,
          foregroundColor: foregroundColor,
        );

  /// Ghost button with minimal styling
  const CosmicButton.ghost({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    CosmicButtonSize size = CosmicButtonSize.medium,
    bool isLoading = false,
    bool hapticFeedback = true,
    EdgeInsetsGeometry? padding,
    double? width,
    IconData? icon,
    bool iconTrailing = false,
    Color? accentColor,
    String? loadingLabel,
    Color? foregroundColor,
  }) : this(
          key: key,
          child: child,
          onPressed: onPressed,
          variant: CosmicButtonVariant.ghost,
          size: size,
          isLoading: isLoading,
          hapticFeedback: hapticFeedback,
          padding: padding,
          width: width,
          icon: icon,
          iconTrailing: iconTrailing,
          accentColor: accentColor,
          loadingLabel: loadingLabel,
          foregroundColor: foregroundColor,
        );

  @override
  State<CosmicButton> createState() => _CosmicButtonState();
}

class _CosmicButtonState extends State<CosmicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = StarboundAnimations.createCosmicController(
      vsync: this,
      duration: StarboundAnimations.fast,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: StarboundAnimations.buttonPressScale,
    ).animate(StarboundAnimations.createStellarCurve(parent: _controller));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(StarboundAnimations.createStellarCurve(parent: _controller));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
      
      if (widget.hapticFeedback) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleHover(bool isHovering) {
    setState(() => _isHovered = isHovering);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final buttonStyle = _getButtonStyle();
    
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                padding: widget.padding ?? buttonStyle.padding,
                decoration: BoxDecoration(
                  color: buttonStyle.backgroundColor,
                  borderRadius: buttonStyle.borderRadius,
                  border: buttonStyle.border,
                  boxShadow: _buildShadow(buttonStyle),
                ),
                child: _buildContent(buttonStyle),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(_ButtonStyle style) {
    if (widget.isLoading) {
      return _buildLoadingContent(style);
    }

    final children = <Widget>[];
    
    // Add icon if provided and not trailing
    if (widget.icon != null && !widget.iconTrailing) {
      children.add(Icon(
        widget.icon,
        size: style.iconSize,
        color: style.textColor,
      ));
      children.add(StarboundSpacing.hSpaceSM);
    }
    
    // Add main content
    children.add(
      Flexible(
        child: DefaultTextStyle(
          style: style.textStyle.copyWith(color: style.textColor),
          textAlign: TextAlign.center,
          child: widget.child,
        ),
      ),
    );
    
    // Add trailing icon if provided
    if (widget.icon != null && widget.iconTrailing) {
      children.add(StarboundSpacing.hSpaceSM);
      children.add(Icon(
        widget.icon,
        size: style.iconSize,
        color: style.textColor,
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  Widget _buildLoadingContent(_ButtonStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: style.iconSize,
          height: style.iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(style.textColor),
          ),
        ),
        StarboundSpacing.hSpaceSM,
        DefaultTextStyle(
          style: style.textStyle,
          child: Text(widget.loadingLabel ?? 'Loading...'),
        ),
      ],
    );
  }

  List<BoxShadow> _buildShadow(_ButtonStyle style) {
    final baseShadow = style.shadow;
    
    if (widget.variant == CosmicButtonVariant.primary && (_isHovered || _isPressed)) {
      // Add stellar glow effect
      return [
        ...baseShadow,
        ...StarboundColors.cosmicGlow(
          _accentColor,
          intensity: 0.3 + (0.2 * _glowAnimation.value),
        ),
      ];
    }
    
    return baseShadow;
  }

  Color get _accentColor => widget.accentColor ?? StarboundColors.stellarAqua;

  Color _resolveTextColor(bool isEnabled, Color accent, bool shouldUseLightText) {
    if (widget.foregroundColor != null) return widget.foregroundColor!;
    if (!isEnabled) return StarboundColors.textDisabled;
    return shouldUseLightText ? StarboundColors.cosmicWhite : StarboundColors.deepSpace;
  }

  _ButtonStyle _getButtonStyle() {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final accent = _accentColor;
    final disabledAccent = accent.withValues(alpha: 0.4);
    final shouldUseLightText = accent.computeLuminance() < 0.45;
    final primaryTextColor = _resolveTextColor(isEnabled, accent, shouldUseLightText);
    
    switch (widget.variant) {
      case CosmicButtonVariant.primary:
        return _ButtonStyle(
          backgroundColor: isEnabled 
            ? accent
            : disabledAccent,
          textColor: primaryTextColor,
          textStyle: widget.size.textStyle,
          padding: widget.size.padding,
          borderRadius: StarboundSpacing.radiusMD,
          iconSize: widget.size.iconSize,
          shadow: StarboundColors.elevatedShadow,
        );
        
      case CosmicButtonVariant.secondary:
        return _ButtonStyle(
          backgroundColor: Colors.transparent,
          textColor: isEnabled
            ? (widget.foregroundColor ?? accent)
            : StarboundColors.textDisabled,
          textStyle: widget.size.textStyle,
          padding: widget.size.padding,
          borderRadius: StarboundSpacing.radiusMD,
          border: Border.all(
            color: isEnabled 
              ? accent 
              : StarboundColors.borderDefault,
            width: 1.5,
          ),
          iconSize: widget.size.iconSize,
          shadow: [],
        );
        
      case CosmicButtonVariant.ghost:
        return _ButtonStyle(
          backgroundColor: _isHovered 
            ? accent.withValues(alpha: 0.12)
            : Colors.transparent,
          textColor: isEnabled
            ? (widget.foregroundColor ?? accent)
            : StarboundColors.textDisabled,
          textStyle: widget.size.textStyle,
          padding: widget.size.padding,
          borderRadius: StarboundSpacing.radiusMD,
          iconSize: widget.size.iconSize,
          shadow: [],
        );
    }
  }
}

/// Button variants
enum CosmicButtonVariant {
  primary,
  secondary,
  ghost,
}

/// Button sizes
enum CosmicButtonSize {
  small,
  medium,
  large,
}

extension CosmicButtonSizeExtension on CosmicButtonSize {
  TextStyle get textStyle {
    switch (this) {
      case CosmicButtonSize.small:
        return StarboundTypography.caption.copyWith(fontWeight: FontWeight.w600);
      case CosmicButtonSize.medium:
        return StarboundTypography.button;
      case CosmicButtonSize.large:
        return StarboundTypography.buttonLarge;
    }
  }
  
  EdgeInsetsGeometry get padding {
    switch (this) {
      case CosmicButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case CosmicButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case CosmicButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 14);
    }
  }
  
  double get iconSize {
    switch (this) {
      case CosmicButtonSize.small:
        return 16;
      case CosmicButtonSize.medium:
        return 20;
      case CosmicButtonSize.large:
        return 24;
    }
  }
}

/// Internal button style configuration
class _ButtonStyle {
  final Color backgroundColor;
  final Color textColor;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Border? border;
  final double iconSize;
  final List<BoxShadow> shadow;

  const _ButtonStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.textStyle,
    required this.padding,
    required this.borderRadius,
    this.border,
    required this.iconSize,
    required this.shadow,
  });
}
