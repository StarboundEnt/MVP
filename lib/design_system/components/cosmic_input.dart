import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system.dart';

/// Cosmic Input Field - Enhanced input with stellar focus states and space-themed styling
/// 
/// Features:
/// - Stellar focus animations
/// - Cosmic background styling
/// - Error state handling
/// - Accessibility support
/// - Multiple variants (standard, search, multiline)
class CosmicInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final CosmicInputVariant variant;

  const CosmicInput({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.inputFormatters,
    this.textInputAction,
    this.onEditingComplete,
    this.onSubmitted,
    this.variant = CosmicInputVariant.standard,
  }) : super(key: key);

  /// Search input with cosmic search styling
  const CosmicInput.search({
    Key? key,
    TextEditingController? controller,
    String? hintText = 'Search...',
    String? labelText,
    String? errorText,
    bool enabled = true,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted,
  }) : this(
          key: key,
          controller: controller,
          hintText: hintText,
          labelText: labelText,
          errorText: errorText,
          prefixIcon: Icons.search_rounded,
          enabled: enabled,
          onChanged: onChanged,
          onTap: onTap,
          focusNode: focusNode,
          onSubmitted: onSubmitted,
          variant: CosmicInputVariant.search,
          textInputAction: TextInputAction.search,
        );

  /// Multiline input for longer text
  const CosmicInput.multiline({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    String? errorText,
    bool enabled = true,
    int maxLines = 4,
    int? minLines = 2,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    FocusNode? focusNode,
    VoidCallback? onEditingComplete,
  }) : this(
          key: key,
          controller: controller,
          hintText: hintText,
          labelText: labelText,
          errorText: errorText,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          onTap: onTap,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          variant: CosmicInputVariant.multiline,
        );

  @override
  State<CosmicInput> createState() => _CosmicInputState();
}

class _CosmicInputState extends State<CosmicInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _focusAnimation;
  late Animation<Color?> _borderColorAnimation;
  
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    
    _controller = StarboundAnimations.createCosmicController(
      vsync: this,
      duration: StarboundAnimations.medium,
    );
    
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(StarboundAnimations.createStellarCurve(parent: _controller));
    
    _borderColorAnimation = ColorTween(
      begin: StarboundColors.borderDefault,
      end: StarboundColors.stellarAqua,
    ).animate(_controller);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final isFocused = _focusNode.hasFocus;
    if (isFocused != _isFocused) {
      setState(() => _isFocused = isFocused);
      
      if (isFocused) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: StarboundTypography.caption.copyWith(
              color: hasError 
                ? StarboundColors.error 
                : StarboundColors.textSecondary,
            ),
          ),
          StarboundSpacing.spaceXS,
        ],
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: widget.enabled 
                  ? StarboundColors.surface 
                  : StarboundColors.withOpacity(StarboundColors.surface, 0.5),
                borderRadius: StarboundSpacing.radiusMD,
                border: Border.all(
                  color: hasError 
                    ? StarboundColors.error
                    : _borderColorAnimation.value ?? StarboundColors.borderDefault,
                  width: _isFocused ? 2.0 : 1.0,
                ),
                boxShadow: _isFocused && !hasError
                  ? StarboundColors.cosmicGlow(
                      StarboundColors.stellarAqua,
                      intensity: 0.1,
                    )
                  : [],
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                onChanged: widget.onChanged,
                onTap: widget.onTap,
                inputFormatters: widget.inputFormatters,
                textInputAction: widget.textInputAction,
                onEditingComplete: widget.onEditingComplete,
                onSubmitted: widget.onSubmitted,
                style: StarboundTypography.body.copyWith(
                  color: widget.enabled 
                    ? StarboundColors.textPrimary 
                    : StarboundColors.textDisabled,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: StarboundTypography.body.copyWith(
                    color: StarboundColors.textTertiary,
                  ),
                  prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused 
                          ? StarboundColors.stellarAqua 
                          : StarboundColors.textTertiary,
                        size: 20,
                      )
                    : null,
                  suffixIcon: widget.suffixIcon != null
                    ? IconButton(
                        icon: Icon(
                          widget.suffixIcon,
                          color: _isFocused 
                            ? StarboundColors.stellarAqua 
                            : StarboundColors.textTertiary,
                          size: 20,
                        ),
                        onPressed: widget.onSuffixIconPressed,
                      )
                    : null,
                  border: InputBorder.none,
                  contentPadding: _getContentPadding(),
                ),
              ),
            );
          },
        ),
        if (hasError) ...[
          StarboundSpacing.spaceXS,
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: StarboundColors.error,
              ),
              StarboundSpacing.hSpaceXS,
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: StarboundTypography.caption.copyWith(
                    color: StarboundColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  EdgeInsetsGeometry _getContentPadding() {
    switch (widget.variant) {
      case CosmicInputVariant.standard:
      case CosmicInputVariant.search:
        return StarboundSpacing.paddingMD;
      case CosmicInputVariant.multiline:
        return StarboundSpacing.paddingMD;
    }
  }
}

/// Input field variants
enum CosmicInputVariant {
  standard,
  search,
  multiline,
}