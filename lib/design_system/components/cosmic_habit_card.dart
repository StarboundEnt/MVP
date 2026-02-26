import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system.dart';

/// Cosmic Habit Card - Clean, floating habit tracking card with stellar styling
/// 
/// Features:
/// - Clean layout with emoji + title + status
/// - Floating elevation with cosmic shadows
/// - Orbital progress indicators
/// - Stellar micro-interactions
/// - Accessibility support
class CosmicHabitCard extends StatefulWidget {
  final String title;
  final String emoji;
  final List<HabitOption> options;
  final String? currentValue;
  final ValueChanged<String?> onSelectionChanged;
  final bool enabled;
  final double? progress;
  final bool showProgress;

  const CosmicHabitCard({
    Key? key,
    required this.title,
    required this.emoji,
    required this.options,
    this.currentValue,
    required this.onSelectionChanged,
    this.enabled = true,
    this.progress,
    this.showProgress = false,
  }) : super(key: key);

  @override
  State<CosmicHabitCard> createState() => _CosmicHabitCardState();
}

class _CosmicHabitCardState extends State<CosmicHabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _hoverAnimation;
  late Animation<double> _progressAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _controller = StarboundAnimations.createCosmicController(
      vsync: this,
      duration: StarboundAnimations.medium,
    );
    
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(StarboundAnimations.createStellarCurve(parent: _controller));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress ?? 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: StarboundAnimations.cosmicEase,
    ));

    // Animate progress if showing
    if (widget.showProgress && widget.progress != null) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CosmicHabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate progress changes
    if (oldWidget.progress != widget.progress && widget.showProgress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress ?? 0.0,
        end: widget.progress ?? 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: StarboundAnimations.cosmicEase,
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

  void _handleHover(bool isHovering) {
    if (widget.enabled) {
      setState(() => _isHovered = isHovering);
      
      if (isHovering) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: StarboundColors.cardGradient,
              borderRadius: StarboundSpacing.radiusLG,
              border: Border.all(
                color: _isHovered 
                  ? StarboundColors.withOpacity(StarboundColors.stellarAqua, 0.3)
                  : StarboundColors.borderSubtle,
                width: 1,
              ),
              boxShadow: [
                ...StarboundColors.elevatedShadow,
                if (_isHovered)
                  ...StarboundColors.cosmicGlow(
                    StarboundColors.stellarAqua,
                    intensity: 0.1 * _hoverAnimation.value,
                  ),
              ],
            ),
            child: Padding(
              padding: StarboundSpacing.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  StarboundSpacing.spaceMD,
                  if (widget.showProgress && widget.progress != null) ...[
                    _buildProgressIndicator(),
                    StarboundSpacing.spaceMD,
                  ],
                  _buildOptions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Emoji with subtle animation
        AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (0.1 * _hoverAnimation.value),
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            );
          },
        ),
        StarboundSpacing.hSpaceMD,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: StarboundTypography.heading3.copyWith(
                  color: widget.enabled 
                    ? StarboundColors.textPrimary 
                    : StarboundColors.textDisabled,
                ),
              ),
              if (widget.currentValue != null) ...[
                StarboundSpacing.spaceXS,
                Text(
                  _getDisplayValue(widget.currentValue!),
                  style: StarboundTypography.caption.copyWith(
                    color: StarboundColors.getHabitColor(widget.currentValue),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: StarboundTypography.caption.copyWith(
                color: StarboundColors.textTertiary,
              ),
            ),
            Text(
              '${((widget.progress ?? 0.0) * 100).round()}%',
              style: StarboundTypography.caption.copyWith(
                color: StarboundColors.stellarAqua,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        StarboundSpacing.spaceXS,
        _buildOrbitalProgress(),
      ],
    );
  }

  Widget _buildOrbitalProgress() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: StarboundColors.withOpacity(StarboundColors.stellarAqua, 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: StarboundColors.accentGradient,
                borderRadius: BorderRadius.circular(3),
                boxShadow: StarboundColors.cosmicGlow(
                  StarboundColors.stellarAqua,
                  intensity: 0.3,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptions() {
    return Wrap(
      spacing: StarboundSpacing.sm,
      runSpacing: StarboundSpacing.sm,
      children: widget.options.map((option) {
        final isSelected = option.value == widget.currentValue;
        
        return CosmicChip.choice(
          label: option.label,
          isSelected: isSelected,
          enabled: widget.enabled,
          color: StarboundColors.getHabitColor(option.value),
          onTap: widget.enabled 
            ? () {
                HapticFeedback.selectionClick();
                widget.onSelectionChanged(option.value);
              }
            : null,
        );
      }).toList(),
    );
  }

  String _getDisplayValue(String value) {
    final option = widget.options.firstWhere(
      (opt) => opt.value == value,
      orElse: () => HabitOption(label: 'Unknown', value: value),
    );
    return option.label;
  }
}

/// Habit option for selection
class HabitOption {
  final String label;
  final String value;
  final IconData? icon;

  const HabitOption({
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitOption &&
        other.label == label &&
        other.value == value &&
        other.icon == icon;
  }

  @override
  int get hashCode => label.hashCode ^ value.hashCode ^ icon.hashCode;
}

/// Cosmic Status Indicator - Constellation-style status display
class CosmicStatusIndicator extends StatefulWidget {
  final String? status;
  final double size;
  final bool animated;

  const CosmicStatusIndicator({
    Key? key,
    this.status,
    this.size = 24,
    this.animated = true,
  }) : super(key: key);

  @override
  State<CosmicStatusIndicator> createState() => _CosmicStatusIndicatorState();
}

class _CosmicStatusIndicatorState extends State<CosmicStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = StarboundAnimations.createCosmicController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.animated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = StarboundColors.getHabitColor(widget.status);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animated ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: StarboundColors.cosmicGlow(color, intensity: 0.4),
            ),
          ),
        );
      },
    );
  }
}