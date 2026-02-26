import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../design_system/design_system.dart';

/// Unified search widget for the dashboard that intelligently detects and routes queries
/// across journal entries, Ask Starbound conversations, and health forecasts
class UnifiedSearchWidget extends StatefulWidget {
  final Function(String query, SearchIntent intent) onSearch;
  final bool isSearching;

  const UnifiedSearchWidget({
    Key? key,
    required this.onSearch,
    this.isSearching = false,
  }) : super(key: key);

  @override
  State<UnifiedSearchWidget> createState() => _UnifiedSearchWidgetState();
}

class _UnifiedSearchWidgetState extends State<UnifiedSearchWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isFocused = false;
  SearchIntent _detectedIntent = SearchIntent.unknown;
  String _intentHint = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    
    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.01,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Focus listener
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    // Text change listener for intent detection
    _controller.addListener(_detectIntent);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _detectIntent() {
    final query = _controller.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() {
        _detectedIntent = SearchIntent.unknown;
        _intentHint = '';
      });
      return;
    }

    // Simple intent detection based on keywords and patterns
    SearchIntent intent = SearchIntent.unknown;
    String hint = '';

    // Journal patterns
    if (_containsJournalKeywords(query)) {
      intent = SearchIntent.journal;
      hint = 'Searching journal entries';
    }
    // Ask Starbound patterns
    else if (_containsQuestionKeywords(query)) {
      intent = SearchIntent.askStarbound;
      hint = 'Ask Starbound AI';
    }
    // Health forecast patterns
    else if (_containsForecastKeywords(query)) {
      intent = SearchIntent.healthForecast;
      hint = 'Health predictions';
    }
    // Default to journal for personal statements
    else if (_containsPersonalKeywords(query)) {
      intent = SearchIntent.journal;
      hint = 'Searching journal entries';
    }

    setState(() {
      _detectedIntent = intent;
      _intentHint = hint;
    });
  }

  bool _containsJournalKeywords(String query) {
    final journalKeywords = [
      'felt', 'feeling', 'mood', 'today', 'yesterday', 'last week', 'emotions',
      'happy', 'sad', 'anxious', 'stressed', 'tired', 'energetic', 'diary',
      'entry', 'journal', 'logged', 'recorded', 'wrote'
    ];
    return journalKeywords.any((keyword) => query.contains(keyword));
  }

  bool _containsQuestionKeywords(String query) {
    final questionKeywords = [
      'what', 'how', 'why', 'when', 'where', 'should i', 'can i', 'help me',
      'advice', 'recommend', 'suggest', 'tell me', 'explain', '?'
    ];
    return questionKeywords.any((keyword) => query.contains(keyword));
  }

  bool _containsForecastKeywords(String query) {
    final forecastKeywords = [
      'predict', 'forecast', 'future', 'next week', 'next month', 'will i',
      'trend', 'pattern', 'projection', 'likely', 'expect', 'upcoming'
    ];
    return forecastKeywords.any((keyword) => query.contains(keyword));
  }

  bool _containsPersonalKeywords(String query) {
    final personalKeywords = [
      'i was', 'i am', 'i felt', 'i feel', 'my', 'me', 'i had', 'i did'
    ];
    return personalKeywords.any((keyword) => query.contains(keyword));
  }

  void _handleSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    HapticFeedback.lightImpact();
    widget.onSearch(query, _detectedIntent);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isFocused
                          ? StarboundColors.stellarAqua.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.15),
                      width: _isFocused ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                      if (_isFocused)
                        ...StarboundColors.cosmicGlow(
                          StarboundColors.stellarAqua.withValues(alpha: 0.2 * _glowAnimation.value),
                          intensity: 0.08 * _glowAnimation.value,
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search input with intent indicator
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: StarboundTypography.body.copyWith(
                            color: StarboundColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search journals, ask questions, or explore forecasts...",
                            hintStyle: StarboundTypography.body.copyWith(
                              color: StarboundColors.textTertiary,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              _getIntentIcon(),
                              color: _isFocused && _detectedIntent != SearchIntent.unknown
                                  ? _getIntentColor()
                                  : StarboundColors.textTertiary,
                              size: 18,
                            ),
                            suffixIcon: widget.isSearching
                                ? Container(
                                    width: 16,
                                    height: 16,
                                    padding: const EdgeInsets.all(14),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        StarboundColors.stellarAqua,
                                      ),
                                    ),
                                  )
                                : _controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          LucideIcons.search,
                                          color: StarboundColors.stellarAqua,
                                          size: 18,
                                        ),
                                        onPressed: _handleSearch,
                                      )
                                    : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _handleSearch(),
                          enabled: !widget.isSearching,
                        ),
                      ),
                      
                      // Intent hint
                      if (_intentHint.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _getIntentIcon(),
                              size: 12,
                              color: _getIntentColor().withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _intentHint,
                              style: StarboundTypography.caption.copyWith(
                                color: _getIntentColor().withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIntentIcon() {
    switch (_detectedIntent) {
      case SearchIntent.journal:
        return LucideIcons.bookOpen;
      case SearchIntent.askStarbound:
        return LucideIcons.messageCircle;
      case SearchIntent.healthForecast:
        return LucideIcons.trendingUp;
      case SearchIntent.unknown:
        return LucideIcons.search;
    }
  }

  Color _getIntentColor() {
    switch (_detectedIntent) {
      case SearchIntent.journal:
        return StarboundColors.stellarAqua;
      case SearchIntent.askStarbound:
        return StarboundColors.nebulaPurple;
      case SearchIntent.healthForecast:
        return StarboundColors.success;
      case SearchIntent.unknown:
        return StarboundColors.textTertiary;
    }
  }
}

/// Search intent detection results
enum SearchIntent {
  journal,
  askStarbound,
  healthForecast,
  unknown,
}