import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/design_system.dart';

/// Enhanced button with smooth animations and haptic feedback
class SmoothButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? elevation;
  final Duration animationDuration;
  final bool hapticFeedback;
  final double scaleOnPress;
  
  const SmoothButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.elevation,
    this.animationDuration = const Duration(milliseconds: 150),
    this.hapticFeedback = true,
    this.scaleOnPress = 0.95,
  }) : super(key: key);
  
  @override
  State<SmoothButton> createState() => _SmoothButtonState();
}

class _SmoothButtonState extends State<SmoothButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _hoverAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnPress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 4.0,
      end: (widget.elevation ?? 4.0) * 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    );
    
    // Start subtle hover animation
    _hoverController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _hoverController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
      if (widget.hapticFeedback) {
        HapticFeedback.lightImpact();
      }
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }
  
  void _handleTapCancel() {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: StarboundAnimations.breathingScale(
        animation: _hoverAnimation,
        minScale: 1.0,
        maxScale: 1.02,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                color: Colors.transparent,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                elevation: _elevationAnimation.value,
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.backgroundColor ?? StarboundColors.cosmicPink,
                        (widget.backgroundColor ?? StarboundColors.cosmicPink).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.backgroundColor ?? StarboundColors.cosmicPink).withValues(alpha: 0.3),
                        blurRadius: 8 + (_hoverAnimation.value * 4),
                        spreadRadius: 1 + (_hoverAnimation.value * 1),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: widget.foregroundColor ?? Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Smooth card with hover and press animations
class SmoothCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double? elevation;
  final Duration animationDuration;
  final bool hapticFeedback;
  
  const SmoothCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
    this.animationDuration = const Duration(milliseconds: 200),
    this.hapticFeedback = true,
  }) : super(key: key);
  
  @override
  State<SmoothCard> createState() => _SmoothCardState();
}

class _SmoothCardState extends State<SmoothCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) + 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          _controller.forward();
          if (widget.hapticFeedback) {
            HapticFeedback.selectionClick();
          }
        }
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              child: Material(
                color: widget.backgroundColor ?? Colors.white.withValues(alpha: 0.1),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                elevation: _elevationAnimation.value,
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated progress bar with smooth transitions
class SmoothProgressBar extends StatefulWidget {
  final double progress;
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration animationDuration;
  
  const SmoothProgressBar({
    Key? key,
    required this.progress,
    this.backgroundColor,
    this.progressColor,
    this.height = 8.0,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 500),
  }) : super(key: key);
  
  @override
  State<SmoothProgressBar> createState() => _SmoothProgressBarState();
}

class _SmoothProgressBarState extends State<SmoothProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _controller.forward();
  }
  
  @override
  void didUpdateWidget(SmoothProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _previousProgress = widget.progress;
      _controller.reset();
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey.withValues(alpha: 0.3),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
      ),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: widget.progressColor ?? Theme.of(context).primaryColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Floating action button with enhanced animations
class SmoothFAB extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool extended;
  final Duration animationDuration;
  
  const SmoothFAB({
    Key? key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56.0,
    this.extended = false,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);
  
  @override
  State<SmoothFAB> createState() => _SmoothFABState();
}

class _SmoothFABState extends State<SmoothFAB>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _orbitalController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _orbitalController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Start continuous orbital motion
    _orbitalController.repeat();
    
    // Start shimmer effect periodically
    _startPeriodicShimmer();
  }
  
  void _startPeriodicShimmer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _shimmerController.forward().then((_) {
          _shimmerController.reset();
          _startPeriodicShimmer();
        });
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _orbitalController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          _controller.forward();
          HapticFeedback.mediumImpact();
        }
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: StarboundAnimations.orbitalFloat(
        animation: _orbitalController,
        radius: 1.5,
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, _shimmerController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: StarboundAnimations.shimmerEffect(
                  animation: _shimmerController,
                  baseColor: widget.backgroundColor ?? StarboundColors.cosmicPink,
                  highlightColor: StarboundColors.stellarAqua,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.backgroundColor ?? StarboundColors.cosmicPink,
                          (widget.backgroundColor ?? StarboundColors.cosmicPink).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(widget.size / 2),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.backgroundColor ?? StarboundColors.cosmicPink).withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(
                          color: widget.foregroundColor ?? Colors.white,
                          size: 24,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Smooth tab bar with animated indicator
class SmoothTabBar extends StatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? indicatorColor;
  final Duration animationDuration;
  
  const SmoothTabBar({
    Key? key,
    required this.tabs,
    required this.selectedIndex,
    this.onTabSelected,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);
  
  @override
  State<SmoothTabBar> createState() => _SmoothTabBarState();
}

class _SmoothTabBarState extends State<SmoothTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _indicatorAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _indicatorAnimation = Tween<double>(
      begin: 0.0,
      end: widget.selectedIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _controller.forward();
  }
  
  @override
  void didUpdateWidget(SmoothTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _indicatorAnimation = Tween<double>(
        begin: oldWidget.selectedIndex.toDouble(),
        end: widget.selectedIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.reset();
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          // Animated indicator
          AnimatedBuilder(
            animation: _indicatorAnimation,
            builder: (context, child) {
              return Positioned(
                left: _indicatorAnimation.value * (MediaQuery.of(context).size.width - 32) / widget.tabs.length,
                child: Container(
                  width: (MediaQuery.of(context).size.width - 32) / widget.tabs.length,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.indicatorColor ?? Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
          // Tab buttons
          Row(
            children: widget.tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = index == widget.selectedIndex;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onTabSelected?.call(index);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: widget.animationDuration,
                      style: TextStyle(
                        color: isSelected 
                          ? (widget.selectedColor ?? Colors.white)
                          : (widget.unselectedColor ?? Colors.white60),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      child: Text(tab),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Smooth switch with custom animations
class SmoothSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final Duration animationDuration;
  
  const SmoothSwitch({
    Key? key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);
  
  @override
  State<SmoothSwitch> createState() => _SmoothSwitchState();
}

class _SmoothSwitchState extends State<SmoothSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbAnimation;
  late Animation<Color?> _trackAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _thumbAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _trackAnimation = ColorTween(
      begin: widget.inactiveColor ?? Colors.grey,
      end: widget.activeColor ?? Theme.of(context).primaryColor,
    ).animate(_controller);
    
    if (widget.value) {
      _controller.value = 1.0;
    }
  }
  
  @override
  void didUpdateWidget(SmoothSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
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
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged?.call(!widget.value);
        HapticFeedback.lightImpact();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 50,
            height: 28,
            decoration: BoxDecoration(
              color: _trackAnimation.value,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: _thumbAnimation.value * 22 + 2,
                  top: 2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.thumbColor ?? Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}