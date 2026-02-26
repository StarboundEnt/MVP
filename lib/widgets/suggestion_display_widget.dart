import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../models/smart_tag_model.dart';
import '../models/nudge_model.dart';
import '../providers/app_state.dart';
import '../design_system/design_system.dart';

/// Widget to display contextual suggestions with interactive UI
class SuggestionDisplayWidget extends StatefulWidget {
  final List<ContextualSuggestion> suggestions;
  final Function(ContextualSuggestion)? onSuggestionTapped;
  final Function(ContextualSuggestion)? onSuggestionDismissed;
  final bool isCompact;
  final bool showActions;

  const SuggestionDisplayWidget({
    Key? key,
    required this.suggestions,
    this.onSuggestionTapped,
    this.onSuggestionDismissed,
    this.isCompact = false,
    this.showActions = true,
  }) : super(key: key);

  @override
  State<SuggestionDisplayWidget> createState() => _SuggestionDisplayWidgetState();
}

class _SuggestionDisplayWidgetState extends State<SuggestionDisplayWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.isCompact ? _buildCompactView() : _buildFullView(),
      ),
    );
  }

  /// Build compact view for inline display
  Widget _buildCompactView() {
    final topSuggestion = widget.suggestions.first;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00F5D4).withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getSuggestionIcon(topSuggestion.category),
              size: 16,
              color: const Color(0xFF00F5D4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topSuggestion.title,
                  style: StarboundTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topSuggestion.description,
                  style: StarboundTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.showActions) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleSuggestionTap(topSuggestion),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5D4).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Try',
                    style: StarboundTypography.bodySmall.copyWith(
                      color: const Color(0xFF00F5D4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build full view with suggestion carousel
  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00F5D4).withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.lightbulb,
                  size: 18,
                  color: const Color(0xFF00F5D4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.suggestions.length} suggestion${widget.suggestions.length == 1 ? '' : 's'} for you',
                  style: StarboundTypography.heading3.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.suggestions.length > 1)
                Text(
                  '${_currentIndex + 1}/${widget.suggestions.length}',
                  style: StarboundTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Current suggestion
          _buildSuggestionCard(widget.suggestions[_currentIndex]),
          
          // Navigation if multiple suggestions
          if (widget.suggestions.length > 1) ...[
            const SizedBox(height: 16),
            _buildNavigationControls(),
          ],
        ],
      ),
    );
  }

  /// Build individual suggestion card
  Widget _buildSuggestionCard(ContextualSuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suggestion header
          Row(
            children: [
              Icon(
                _getSuggestionIcon(suggestion.category),
                size: 20,
                color: _getSuggestionColor(suggestion.relevanceScore),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestion.title,
                  style: StarboundTypography.heading3.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSuggestionColor(suggestion.relevanceScore).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  suggestion.category.toUpperCase(),
                  style: StarboundTypography.bodySmall.copyWith(
                    color: _getSuggestionColor(suggestion.relevanceScore),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Text(
            suggestion.description,
            style: StarboundTypography.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00F5D4).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              suggestion.actionText,
              style: StarboundTypography.bodyLarge.copyWith(
                color: const Color(0xFF00F5D4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          
          // Action buttons
          if (widget.showActions) ...[
            const SizedBox(height: 16),
            _buildActionButtons(suggestion),
          ],
        ],
      ),
    );
  }

  /// Build action buttons for suggestion
  Widget _buildActionButtons(ContextualSuggestion suggestion) {
    return Column(
      children: [
        // Primary action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleSuggestionTap(suggestion),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F5D4),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.play, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Try This Now',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary actions row
        Row(
          children: [
            // Save to vault button
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleSaveToVault(suggestion),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00F5D4),
                  side: BorderSide(
                    color: const Color(0xFF00F5D4).withValues(alpha: 0.5),
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.bookmark, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'Save to Vault',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Dismiss button
            IconButton(
              onPressed: () => _handleSuggestionDismiss(suggestion),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white.withValues(alpha: 0.7),
              ),
              icon: const Icon(LucideIcons.x, size: 16),
            ),
          ],
        ),
      ],
    );
  }

  /// Build navigation controls for multiple suggestions
  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentIndex > 0 ? _previousSuggestion : null,
          icon: Icon(
            LucideIcons.chevronLeft,
            size: 20,
            color: _currentIndex > 0 
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 16),
        ...List.generate(widget.suggestions.length, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: index == _currentIndex ? 8 : 6,
            height: index == _currentIndex ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentIndex
                ? const Color(0xFF00F5D4)
                : Colors.white.withValues(alpha: 0.3),
            ),
          );
        }),
        const SizedBox(width: 16),
        IconButton(
          onPressed: _currentIndex < widget.suggestions.length - 1 ? _nextSuggestion : null,
          icon: Icon(
            LucideIcons.chevronRight,
            size: 20,
            color: _currentIndex < widget.suggestions.length - 1
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  /// Get appropriate icon for suggestion category
  IconData _getSuggestionIcon(String category) {
    switch (category) {
      case 'immediate':
        return LucideIcons.zap;
      case 'daily':
        return LucideIcons.calendar;
      case 'weekly':
        return LucideIcons.clock;
      default:
        return LucideIcons.lightbulb;
    }
  }

  /// Get color based on relevance score
  Color _getSuggestionColor(double relevanceScore) {
    if (relevanceScore >= 0.8) {
      return StarboundColors.success;
    } else if (relevanceScore >= 0.6) {
      return const Color(0xFF00F5D4);
    } else {
      return StarboundColors.stellarYellow;
    }
  }

  /// Handle suggestion tap
  void _handleSuggestionTap(ContextualSuggestion suggestion) {
    HapticFeedback.lightImpact();
    if (widget.onSuggestionTapped != null) {
      widget.onSuggestionTapped!(suggestion);
    }
  }

  /// Handle saving suggestion to vault
  void _handleSaveToVault(ContextualSuggestion suggestion) async {
    HapticFeedback.lightImpact();
    
    try {
      // Convert contextual suggestion to StarboundNudge
      final nudge = _convertSuggestionToNudge(suggestion);
      
      // Save nudge to vault using app state
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.bankNudge(nudge);
      
      // Show success confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bookmark_added, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${suggestion.title}" saved to Action Vault!',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: StarboundColors.success,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'View Vault',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pushNamed('/action-vault');
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save suggestion to vault: $e');
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to save suggestion. Please try again.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  /// Handle suggestion dismiss
  void _handleSuggestionDismiss(ContextualSuggestion suggestion) {
    HapticFeedback.lightImpact();
    if (widget.onSuggestionDismissed != null) {
      widget.onSuggestionDismissed!(suggestion);
    }
  }

  /// Navigate to previous suggestion
  void _previousSuggestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      HapticFeedback.selectionClick();
    }
  }

  /// Navigate to next suggestion
  void _nextSuggestion() {
    if (_currentIndex < widget.suggestions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      HapticFeedback.selectionClick();
    }
  }

  /// Convert ContextualSuggestion to StarboundNudge for saving to vault
  StarboundNudge _convertSuggestionToNudge(ContextualSuggestion suggestion) {
    // Map category to theme
    String theme = _mapCategoryToTheme(suggestion.category);
    
    // Determine nudge type based on relevance and category
    NudgeType nudgeType = suggestion.relevanceScore >= 0.8 
        ? NudgeType.encouragement 
        : NudgeType.suggestion;
    
    // Create unique ID for the nudge
    final uniqueId = 'contextual_${suggestion.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    return StarboundNudge(
      id: uniqueId,
      theme: theme,
      message: suggestion.actionText,
      title: suggestion.title,
      content: suggestion.description,
      tone: suggestion.relevanceScore >= 0.8 ? 'encouraging' : 'supportive',
      estimatedTime: _mapCategoryToEstimatedTime(suggestion.category),
      energyRequired: suggestion.relevanceScore >= 0.7 ? 'low' : 'very low',
      complexityProfileFit: ['stable', 'trying'], // Allow for most profiles
      triggersFrom: suggestion.triggerTagKeys,
      source: NudgeSource.dynamic,
      type: nudgeType,
      actionableSteps: [suggestion.actionText],
      generatedAt: DateTime.now(),
      metadata: {
        'source': 'contextual_suggestion_widget',
        'original_suggestion_id': suggestion.id,
        'relevance_score': suggestion.relevanceScore,
        'trigger_tags': suggestion.triggerTagKeys,
        'generated_from_journal': true,
        'creation_method': 'smart_journaling_widget',
        'category': suggestion.category,
      },
    );
  }
  
  /// Map suggestion category to nudge theme
  String _mapCategoryToTheme(String category) {
    switch (category) {
      case 'immediate':
        return 'focus';
      case 'daily':
        return 'wellness';
      case 'weekly':
        return 'planning';
      default:
        return 'general';
    }
  }
  
  /// Map category to estimated time
  String _mapCategoryToEstimatedTime(String category) {
    switch (category) {
      case 'immediate':
        return '<2 mins';
      case 'daily':
        return '5-10 mins';
      case 'weekly':
        return '10-15 mins';
      default:
        return '2-5 mins';
    }
  }
}