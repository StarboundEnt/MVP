import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/nudge_model.dart';
import '../design_system/design_system.dart';

/// Performance-optimized nudge card that caches results and prevents unnecessary rebuilds
class OptimizedNudgeCard extends StatefulWidget {
  const OptimizedNudgeCard({Key? key}) : super(key: key);

  @override
  State<OptimizedNudgeCard> createState() => _OptimizedNudgeCardState();
}

class _OptimizedNudgeCardState extends State<OptimizedNudgeCard> 
    with TickerProviderStateMixin {
  StarboundNudge? _cachedNudge;
  DateTime? _lastUpdate;
  bool _isLoading = false;
  
  late AnimationController _breathingController;
  late AnimationController _pulseController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize breathing animation for the card
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Initialize pulse animation for the icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _breathingAnimation = CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    );
    
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    // Start continuous animations
    _breathingController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    
    _loadNudge();
  }

  Future<void> _loadNudge() async {
    if (_isLoading) return;
    
    // Only reload if cache is stale (more than 1 hour old)
    if (_cachedNudge != null && _lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!).inHours < 1) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final appState = context.read<AppState>();
      final nudge = await appState.getCurrentNudge();
      
      if (mounted) {
        setState(() {
          _cachedNudge = nudge;
          _lastUpdate = DateTime.now();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Listen only to habits changes that might affect nudge relevance
    return Selector<AppState, String>(
      selector: (context, appState) => 
        '${appState.habits.length}_${appState.complexityProfile.name}',
      builder: (context, habitsSignature, child) {
        // Trigger reload only when habits or complexity profile change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_lastUpdate != null && 
              DateTime.now().difference(_lastUpdate!).inMinutes > 30) {
            _loadNudge();
          }
        });
        
        if (_isLoading && _cachedNudge == null) {
          return _buildLoadingCard();
        }
        
        if (_cachedNudge == null) {
          return _buildEmptyCard();
        }
        
        return _buildNudgeCard(_cachedNudge!);
      },
    );
  }
  
  Widget _buildLoadingCard() {
    return StarboundAnimations.breathingScale(
      animation: _breathingAnimation,
      minScale: 1.0,
      maxScale: 1.01,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: StarboundColors.cosmicWhite.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: StarboundColors.cosmicWhite.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: StarboundColors.stellarAqua.withValues(alpha: 0.1 * _breathingAnimation.value),
              blurRadius: 8 + (4 * _breathingAnimation.value),
              spreadRadius: 1 * _breathingAnimation.value,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(StarboundColors.stellarAqua),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              "Loading personalized nudge...", 
              style: StarboundTypography.body.copyWith(
                color: StarboundColors.cosmicWhite.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.white70),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "No personalized nudges right now. Check back later!",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNudgeCard(StarboundNudge nudge) {
    return StarboundAnimations.breathingScale(
      animation: _breathingAnimation,
      minScale: 1.0,
      maxScale: 1.02,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getNudgeColor(nudge.type).withValues(alpha: 0.15),
              _getNudgeColor(nudge.type).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getNudgeColor(nudge.type).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: _getNudgeColor(nudge.type).withValues(alpha: 0.2 + (0.1 * _breathingAnimation.value)),
              blurRadius: 12 + (4 * _breathingAnimation.value),
              spreadRadius: 2 + (1 * _breathingAnimation.value),
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarboundAnimations.pulseGlow(
                animation: _pulseAnimation,
                glowColor: _getNudgeColor(nudge.type),
                maxGlow: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNudgeColor(nudge.type).withValues(alpha: 0.2 + (0.1 * _pulseAnimation.value)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getNudgeColor(nudge.type).withValues(alpha: 0.4 * _pulseAnimation.value),
                        blurRadius: 6 * _pulseAnimation.value,
                        spreadRadius: 1 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getNudgeIcon(nudge.type),
                    color: _getNudgeColor(nudge.type),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nudge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatNudgeType(nudge.type),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nudge.content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (nudge.actionableSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...nudge.actionableSteps.take(2).map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: BoxDecoration(
                      color: _getNudgeColor(nudge.type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Updated ${_formatLastUpdate()}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              GestureDetector(
                onTap: _loadNudge,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
  
  Color _getNudgeColor(NudgeType type) {
    switch (type) {
      case NudgeType.encouragement:
        return StarboundColors.success;
      case NudgeType.insight:
        return StarboundColors.starlightBlue;
      case NudgeType.suggestion:
        return StarboundColors.solarOrange;
      case NudgeType.warning:
        return StarboundColors.warning;
      case NudgeType.celebration:
        return StarboundColors.cosmicPink;
      case NudgeType.reminder:
        return StarboundColors.solarOrange;
      case NudgeType.urgentReminder:
        return StarboundColors.warning;
    }
  }
  
  IconData _getNudgeIcon(NudgeType type) {
    switch (type) {
      case NudgeType.encouragement:
        return Icons.thumb_up;
      case NudgeType.insight:
        return Icons.lightbulb;
      case NudgeType.suggestion:
        return Icons.tips_and_updates;
      case NudgeType.warning:
        return Icons.warning;
      case NudgeType.celebration:
        return Icons.celebration;
      case NudgeType.reminder:
        return Icons.alarm;
      case NudgeType.urgentReminder:
        return Icons.priority_high;
    }
  }
  
  String _formatNudgeType(NudgeType type) {
    switch (type) {
      case NudgeType.encouragement:
        return 'Encouragement';
      case NudgeType.insight:
        return 'Insight';
      case NudgeType.suggestion:
        return 'Suggestion';
      case NudgeType.warning:
        return 'Warning';
      case NudgeType.celebration:
        return 'Celebration';
      case NudgeType.reminder:
        return 'Reminder';
      case NudgeType.urgentReminder:
        return 'Urgent Reminder';
    }
  }
  
  String _formatLastUpdate() {
    if (_lastUpdate == null) return 'just now';
    
    final difference = DateTime.now().difference(_lastUpdate!);
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
