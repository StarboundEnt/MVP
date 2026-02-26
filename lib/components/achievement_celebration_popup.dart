import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/design_system.dart';
import '../services/achievement_service.dart';

/// Magical Achievement Celebration Popup
/// Shows when achievements are unlocked with cosmic celebration effects
class AchievementCelebrationPopup extends StatefulWidget {
  final List<Achievement> achievements;
  final VoidCallback? onDismiss;

  const AchievementCelebrationPopup({
    Key? key,
    required this.achievements,
    this.onDismiss,
  }) : super(key: key);

  static void show(
    BuildContext context,
    List<Achievement> achievements, {
    VoidCallback? onDismiss,
  }) {
    if (achievements.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => AchievementCelebrationPopup(
        achievements: achievements,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<AchievementCelebrationPopup> createState() => _AchievementCelebrationPopupState();
}

class _AchievementCelebrationPopupState extends State<AchievementCelebrationPopup>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _starsController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  int _currentIndex = 0;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: StarboundAnimations.slow,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _starsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: StarboundAnimations.nebulaEase,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: StarboundAnimations.cosmicEase,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.3,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: StarboundAnimations.stellarEase,
    ));
    
    _startAnimation();
  }

  void _startAnimation() {
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    setState(() {
      _showCelebration = true;
    });
    
    _mainController.forward();
    _pulseController.repeat(reverse: true);
    _starsController.forward();
    
    // Auto advance after showing current achievement
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _nextAchievement();
      }
    });
  }

  void _nextAchievement() {
    if (_currentIndex < widget.achievements.length - 1) {
      setState(() {
        _currentIndex++;
      });
      
      _mainController.reset();
      _starsController.reset();
      _startAnimation();
    } else {
      _dismiss();
    }
  }

  void _dismiss() {
    _mainController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievements[_currentIndex];
    
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Celebration particles
          if (_showCelebration)
            Positioned.fill(
              child: CosmicCelebration(
                isActive: true,
                style: _getCelebrationStyle(achievement.tier),
                child: Container(),
              ),
            ),
          
          // Stellar constellation background for higher tier achievements
          if (_showCelebration && _shouldShowConstellation(achievement.tier))
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _starsController,
                builder: (context, child) {
                  return StarboundAnimations.stellarConstellation(
                    animation: _starsController,
                    starColor: _getTierColor(achievement.tier),
                    starCount: _getConstellationStarCount(achievement.tier),
                    child: Container(),
                  );
                },
              ),
            ),
          
          // Main popup
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * _scaleAnimation.value),
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value * 100),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: _buildPopupContent(achievement),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value * 0.7,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Progress indicator (if multiple achievements)
          if (widget.achievements.length > 1)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildProgressIndicator(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopupContent(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: StarboundSpacing.paddingXL,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StarboundColors.deepSpace,
            StarboundColors.deepSpace.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _getTierColor(achievement.tier).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getTierColor(achievement.tier).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Achievement icon with pulsing glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getTierColor(achievement.tier).withValues(alpha: 0.3 * _pulseController.value),
                      _getTierColor(achievement.tier).withValues(alpha: 0.1 * _pulseController.value),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getTierColor(achievement.tier).withValues(alpha: 0.4 * _pulseController.value),
                      blurRadius: 30 * _pulseController.value,
                      spreadRadius: 10 * _pulseController.value,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getTierColor(achievement.tier).withValues(alpha: 0.2),
                    border: Border.all(
                      color: _getTierColor(achievement.tier),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      achievement.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: StarboundSpacing.xl),
          
          // Achievement unlocked text
          Text(
            'Achievement Unlocked!',
            style: StarboundTypography.heading3.copyWith(
              color: _getTierColor(achievement.tier),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: StarboundSpacing.md),
          
          // Achievement title
          Text(
            achievement.title,
            style: StarboundTypography.heading2.copyWith(
              color: StarboundColors.cosmicWhite,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: StarboundSpacing.sm),
          
          // Achievement description
          Text(
            achievement.description,
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.cosmicWhite.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: StarboundSpacing.lg),
          
          // Tier and points
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTierBadge(achievement.tier),
              SizedBox(width: StarboundSpacing.md),
              _buildPointsBadge(achievement.points),
            ],
          ),
          
          SizedBox(height: StarboundSpacing.xl),
          
          // Continue button
          CosmicButton.primary(
            onPressed: _nextAchievement,
            child: Text(
              widget.achievements.length > 1 && _currentIndex < widget.achievements.length - 1
                  ? 'Next Achievement'
                  : 'Continue',
              style: StarboundTypography.button,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(AchievementTier tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTierColor(tier).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTierColor(tier).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTierIcon(tier),
            color: _getTierColor(tier),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _getTierName(tier),
            style: StarboundTypography.caption.copyWith(
              color: _getTierColor(tier),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBadge(int points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: StarboundColors.stellarYellow.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StarboundColors.stellarYellow.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: StarboundColors.stellarYellow,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '+$points pts',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.stellarYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.achievements.length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= _currentIndex
                ? StarboundColors.stellarAqua
                : StarboundColors.stellarAqua.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  CelebrationStyle _getCelebrationStyle(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return CelebrationStyle.sparkles;
      case AchievementTier.silver:
        return CelebrationStyle.stars;
      case AchievementTier.gold:
      case AchievementTier.platinum:
      case AchievementTier.diamond:
        return CelebrationStyle.confetti;
    }
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return StarboundColors.stellarYellow;
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.diamond:
        return StarboundColors.stellarAqua;
    }
  }

  IconData _getTierIcon(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Icons.military_tech;
      case AchievementTier.silver:
        return Icons.workspace_premium;
      case AchievementTier.gold:
        return Icons.emoji_events;
      case AchievementTier.platinum:
        return Icons.diamond;
      case AchievementTier.diamond:
        return Icons.auto_awesome;
    }
  }

  String _getTierName(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
      case AchievementTier.diamond:
        return 'Diamond';
    }
  }

  bool _shouldShowConstellation(AchievementTier tier) {
    return tier == AchievementTier.gold || 
           tier == AchievementTier.platinum || 
           tier == AchievementTier.diamond;
  }

  int _getConstellationStarCount(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
      case AchievementTier.silver:
        return 0;
      case AchievementTier.gold:
        return 6;
      case AchievementTier.platinum:
        return 8;
      case AchievementTier.diamond:
        return 12;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _starsController.dispose();
    super.dispose();
  }
}
