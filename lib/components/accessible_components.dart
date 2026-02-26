import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';

/// Collection of accessible UI components for Starbound app
/// 
/// These components are optimized for:
/// - Screen readers
/// - Keyboard navigation
/// - Voice control
/// - High contrast themes
/// - Touch accessibility
/// - Semantic markup

/// Accessible button with enhanced semantics
class AccessibleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticHint;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool autofocus;
  final String? tooltip;

  const AccessibleButton({
    Key? key,
    required this.child,
    this.onPressed,
    required this.semanticLabel,
    this.semanticHint,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.autofocus = false,
    this.tooltip,
  }) : super(key: key);

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;
    final settings = accessibilityService.currentSettings;

    Widget button = Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && widget.onPressed != null) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onPressed!();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: settings.reduceMotionEnabled 
                ? Duration.zero 
                : const Duration(milliseconds: 150),
            padding: widget.padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBackgroundColor(context, settings),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              border: _isFocused ? Border.all(
                color: Theme.of(context).focusColor,
                width: 2,
              ) : null,
              boxShadow: _isHovered && !settings.reduceMotionEnabled ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: widget.foregroundColor ?? 
                       Theme.of(context).colorScheme.onPrimary,
                fontSize: 16 * settings.textScaleFactor,
                fontWeight: FontWeight.w600,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    // Wrap with semantics
    button = Semantics(
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      button: true,
      enabled: widget.onPressed != null,
      focusable: true,
      focused: _isFocused,
      onTap: widget.onPressed,
      child: button,
    );

    // Add tooltip if provided
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }

  Color _getBackgroundColor(BuildContext context, AccessibilitySettings settings) {
    final theme = Theme.of(context);
    Color baseColor = widget.backgroundColor ?? theme.primaryColor;
    
    if (settings.highContrastEnabled) {
      return _isFocused || _isHovered ? Colors.yellow : Colors.white;
    }
    
    if (widget.onPressed == null) {
      return baseColor.withValues(alpha: 0.3);
    }
    
    if (_isHovered || _isFocused) {
      return Color.lerp(baseColor, Colors.white, 0.1) ?? baseColor;
    }
    
    return baseColor;
  }
}

/// Accessible form field with enhanced labels
class AccessibleFormField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final bool required;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;
  final String? initialValue;

  const AccessibleFormField({
    Key? key,
    required this.label,
    this.hint,
    this.errorText,
    this.required = false,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.suffixIcon,
    this.initialValue,
  }) : super(key: key);

  @override
  State<AccessibleFormField> createState() => _AccessibleFormFieldState();
}

class _AccessibleFormFieldState extends State<AccessibleFormField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;
    final settings = accessibilityService.currentSettings;
    final theme = Theme.of(context);

    String semanticLabel = widget.label;
    if (widget.required) {
      semanticLabel += ', required field';
    }
    
    String? semanticHint = widget.hint;
    if (widget.errorText != null) {
      semanticHint = 'Error: ${widget.errorText}';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Semantics(
          label: semanticLabel,
          child: RichText(
            text: TextSpan(
              text: widget.label,
              style: TextStyle(
                color: settings.highContrastEnabled 
                    ? Colors.white 
                    : theme.textTheme.bodyMedium?.color,
                fontSize: 14 * settings.textScaleFactor,
                fontWeight: FontWeight.w500,
              ),
              children: widget.required ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: settings.highContrastEnabled 
                        ? Colors.yellow 
                        : theme.colorScheme.error,
                  ),
                ),
              ] : null,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Text field
        Semantics(
          label: semanticLabel,
          hint: semanticHint,
          textField: true,
          focused: _isFocused,
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            initialValue: widget.initialValue,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            style: TextStyle(
              fontSize: 16 * settings.textScaleFactor,
              color: settings.highContrastEnabled 
                  ? Colors.white 
                  : null,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor: settings.highContrastEnabled 
                  ? Colors.grey[900] 
                  : theme.inputDecorationTheme.fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: settings.highContrastEnabled 
                      ? Colors.white 
                      : theme.dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: settings.highContrastEnabled 
                      ? Colors.yellow 
                      : theme.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: settings.highContrastEnabled 
                      ? Colors.red[300]! 
                      : theme.colorScheme.error,
                ),
              ),
              hintStyle: TextStyle(
                fontSize: 16 * settings.textScaleFactor,
                color: settings.highContrastEnabled 
                    ? Colors.grey[400] 
                    : null,
              ),
            ),
          ),
        ),
        
        // Helper text or error
        if (widget.hint != null && widget.errorText == null) ...[
          const SizedBox(height: 4),
          Text(
            widget.hint!,
            style: TextStyle(
              fontSize: 12 * settings.textScaleFactor,
              color: settings.highContrastEnabled 
                  ? Colors.grey[400] 
                  : theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ],
    );
  }
}

/// Accessible card with proper semantics
class AccessibleCard extends StatefulWidget {
  final Widget child;
  final String semanticLabel;
  final String? semanticHint;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final bool selectable;
  final bool selected;

  const AccessibleCard({
    Key? key,
    required this.child,
    required this.semanticLabel,
    this.semanticHint,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation,
    this.selectable = false,
    this.selected = false,
  }) : super(key: key);

  @override
  State<AccessibleCard> createState() => _AccessibleCardState();
}

class _AccessibleCardState extends State<AccessibleCard> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;
    final settings = accessibilityService.currentSettings;
    Widget card = Focus(
      focusNode: _focusNode,
      onKeyEvent: widget.onTap != null ? (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onTap!();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      } : null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: settings.reduceMotionEnabled 
                ? Duration.zero 
                : const Duration(milliseconds: 200),
            margin: widget.margin ?? const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCardColor(context, settings),
              borderRadius: BorderRadius.circular(12),
              border: _getBorder(context, settings),
              boxShadow: _getShadow(settings),
            ),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(16),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      button: widget.onTap != null,
      selected: widget.selected,
      focusable: widget.onTap != null,
      focused: _isFocused,
      onTap: widget.onTap,
      child: card,
    );
  }

  Color _getCardColor(BuildContext context, AccessibilitySettings settings) {
    final theme = Theme.of(context);
    
    if (settings.highContrastEnabled) {
      if (widget.selected) {
        return Colors.yellow.withValues(alpha: 0.3);
      }
      return Colors.grey[900]!;
    }
    
    Color baseColor = theme.cardColor;
    
    if (widget.selected) {
      return theme.primaryColor.withValues(alpha: 0.1);
    }
    
    if (_isHovered || _isFocused) {
      return Color.lerp(baseColor, theme.primaryColor, 0.05) ?? baseColor;
    }
    
    return baseColor;
  }

  Border? _getBorder(BuildContext context, AccessibilitySettings settings) {
    final theme = Theme.of(context);
    
    if (_isFocused) {
      return Border.all(
        color: settings.highContrastEnabled 
            ? Colors.yellow 
            : theme.focusColor,
        width: 2,
      );
    }
    
    if (widget.selected) {
      return Border.all(
        color: settings.highContrastEnabled 
            ? Colors.yellow 
            : theme.primaryColor,
        width: 1,
      );
    }
    
    if (settings.highContrastEnabled) {
      return Border.all(
        color: Colors.white.withValues(alpha: 0.3),
        width: 1,
      );
    }
    
    return null;
  }

  List<BoxShadow>? _getShadow(AccessibilitySettings settings) {
    if (settings.reduceMotionEnabled || settings.highContrastEnabled) {
      return null;
    }
    
    double elevation = widget.elevation ?? 2.0;
    if (_isHovered) {
      elevation += 2.0;
    }
    
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation),
      ),
    ];
  }
}

/// Accessible navigation bar
class AccessibleNavigationBar extends StatelessWidget {
  final List<AccessibleNavigationItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final String semanticLabel;

  const AccessibleNavigationBar({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
    this.semanticLabel = 'Navigation',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;
    final settings = accessibilityService.currentSettings;
    final theme = Theme.of(context);
    
    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: settings.highContrastEnabled 
              ? Colors.black 
              : theme.bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: settings.highContrastEnabled 
                  ? Colors.white.withValues(alpha: 0.3) 
                  : theme.dividerColor,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == currentIndex;
            
            return Expanded(
              child: AccessibleNavigationItemWidget(
                item: item,
                isSelected: isSelected,
                index: index,
                totalItems: items.length,
                onTap: () => onItemSelected(index),
                settings: settings,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Individual navigation item widget
class AccessibleNavigationItemWidget extends StatefulWidget {
  final AccessibleNavigationItem item;
  final bool isSelected;
  final int index;
  final int totalItems;
  final VoidCallback onTap;
  final AccessibilitySettings settings;

  const AccessibleNavigationItemWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.index,
    required this.totalItems,
    required this.onTap,
    required this.settings,
  }) : super(key: key);

  @override
  State<AccessibleNavigationItemWidget> createState() => 
      _AccessibleNavigationItemWidgetState();
}

class _AccessibleNavigationItemWidgetState 
    extends State<AccessibleNavigationItemWidget> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String semanticLabel = widget.item.label;
    if (widget.isSelected) {
      semanticLabel += ', selected';
    }
    semanticLabel += ', tab ${widget.index + 1} of ${widget.totalItems}';
    
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        label: semanticLabel,
        hint: widget.item.hint,
        button: true,
        selected: widget.isSelected,
        focused: _isFocused,
        onTap: widget.onTap,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: widget.settings.reduceMotionEnabled 
                ? Duration.zero 
                : const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getBackgroundColor(theme),
              borderRadius: BorderRadius.circular(12),
              border: _isFocused ? Border.all(
                color: widget.settings.highContrastEnabled 
                    ? Colors.yellow 
                    : theme.focusColor,
                width: 2,
              ) : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.isSelected && !widget.settings.reduceMotionEnabled)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getActiveColor(theme).withValues(alpha: 0.1),
                        ),
                      ),
                    Icon(
                      widget.item.icon,
                      size: 24,
                      color: _getIconColor(theme),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 12 * widget.settings.textScaleFactor,
                    color: _getTextColor(theme),
                    fontWeight: widget.isSelected 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.isSelected && widget.settings.highContrastEnabled) {
      return Colors.yellow.withValues(alpha: 0.2);
    }
    
    if (widget.isSelected) {
      return widget.item.activeColor.withValues(alpha: 0.15);
    }
    
    return Colors.transparent;
  }

  Color _getActiveColor(ThemeData theme) {
    if (widget.settings.highContrastEnabled) {
      return Colors.yellow;
    }
    return widget.item.activeColor;
  }

  Color _getIconColor(ThemeData theme) {
    if (widget.settings.highContrastEnabled) {
      return widget.isSelected ? Colors.yellow : Colors.white;
    }
    
    return widget.isSelected 
        ? widget.item.activeColor 
        : Colors.white.withValues(alpha: 0.7);
  }

  Color _getTextColor(ThemeData theme) {
    if (widget.settings.highContrastEnabled) {
      return widget.isSelected ? Colors.yellow : Colors.white;
    }
    
    return widget.isSelected 
        ? widget.item.activeColor 
        : Colors.white.withValues(alpha: 0.7);
  }
}

/// Navigation item data model
class AccessibleNavigationItem {
  final String label;
  final String? hint;
  final IconData icon;
  final Color activeColor;
  final String route;

  const AccessibleNavigationItem({
    required this.label,
    this.hint,
    required this.icon,
    required this.activeColor,
    required this.route,
  });
}

/// Accessible progress indicator
class AccessibleProgressIndicator extends StatelessWidget {
  final double progress;
  final String semanticLabel;
  final String? semanticHint;
  final Color? color;
  final Color? backgroundColor;
  final double height;

  const AccessibleProgressIndicator({
    Key? key,
    required this.progress,
    required this.semanticLabel,
    this.semanticHint,
    this.color,
    this.backgroundColor,
    this.height = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;
    final settings = accessibilityService.currentSettings;
    final theme = Theme.of(context);
    
    final progressPercentage = (progress * 100).round();
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint ?? '$progressPercentage percent complete',
      value: '$progressPercentage%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? 
                 (settings.highContrastEnabled 
                     ? Colors.grey[800] 
                     : Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: color ?? 
                     (settings.highContrastEnabled 
                         ? Colors.yellow 
                         : theme.primaryColor),
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessible loading indicator
class AccessibleLoadingIndicator extends StatelessWidget {
  final String semanticLabel;
  final double size;
  final Color? color;

  const AccessibleLoadingIndicator({
    Key? key,
    this.semanticLabel = 'Loading',
    this.size = 24.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService.instance;
    final settings = accessibilityService.currentSettings;
    final theme = Theme.of(context);
    
    if (settings.reduceMotionEnabled) {
      // Static loading indicator for reduced motion
      return Semantics(
        label: semanticLabel,
        liveRegion: true,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color ?? 
                     (settings.highContrastEnabled 
                         ? Colors.white 
                         : theme.primaryColor),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ?? 
                       (settings.highContrastEnabled 
                           ? Colors.white 
                           : theme.primaryColor),
              ),
            ),
          ),
        ),
      );
    }
    
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? 
            (settings.highContrastEnabled 
                ? Colors.white 
                : theme.primaryColor),
          ),
        ),
      ),
    );
  }
}
