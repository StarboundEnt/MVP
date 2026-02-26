import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/smart_tag_model.dart';
import '../services/smart_tagging_service.dart';
import '../services/nudge_recommendation_service.dart';
import '../models/nudge_model.dart';
import '../widgets/suggestion_display_widget.dart';
import '../providers/app_state.dart';
import '../design_system/design_system.dart';
import '../design_system/design_system.dart';

/// Semi-interactive journaling widget with smart tagging and follow-up questions
class SmartJournalWidget extends StatefulWidget {
  final Function(SmartJournalEntry) onEntrySubmitted;
  final bool isProcessing;
  final String? placeholder;
  final bool showConfidenceScores;
  final bool enableFollowUps;
  final Color accentColor;
  final Color? surfaceColor;

  const SmartJournalWidget({
    Key? key,
    required this.onEntrySubmitted,
    this.isProcessing = false,
    this.placeholder,
    this.showConfidenceScores = false,
    this.enableFollowUps = true,
    this.accentColor = StarboundColors.stellarAqua,
    this.surfaceColor,
  }) : super(key: key);

  @override
  State<SmartJournalWidget> createState() => _SmartJournalWidgetState();
}

class _SmartJournalWidgetState extends State<SmartJournalWidget> 
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _followUpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SmartTaggingService _taggingService = SmartTaggingService();
  final NudgeRecommendationService _nudgeService = NudgeRecommendationService();
  
  bool _isAnalyzing = false;
  SmartTaggingResult? _currentAnalysis;
  List<FollowUpQuestion> _pendingQuestions = [];
  Map<String, String> _followUpResponses = {};
  int _currentQuestionIndex = 0;
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _textController.dispose();
    _followUpController.dispose();
    _focusNode.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Handle journal entry submission with smart analysis
  Future<void> _handleSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isAnalyzing || widget.isProcessing) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Perform smart tagging analysis
      final analysis = await _taggingService.analyzeText(text);
      
      setState(() {
        _currentAnalysis = analysis;
        _pendingQuestions = widget.enableFollowUps ? analysis.suggestedFollowUps : [];
        _currentQuestionIndex = 0;
        _followUpResponses.clear();
      });

      if (_pendingQuestions.isNotEmpty) {
        // Start follow-up flow
        _slideController.forward();
        _fadeController.forward();
      } else {
        // No follow-ups, submit immediately
        await _submitJournalEntry();
      }
    } catch (e) {
      debugPrint('Smart tagging failed: $e');
      // Fallback to basic submission
      await _submitBasicEntry(text);
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  /// Submit journal entry with smart tags and recommendations
  Future<void> _submitJournalEntry() async {
    if (_currentAnalysis == null) return;

    // Generate nudge recommendations
    final nudgeResult = _nudgeService.generateRecommendations(_currentAnalysis!.smartTags);

    // Create smart journal entry
    final entry = SmartJournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: _currentAnalysis!.originalText,
      timestamp: DateTime.now(),
      smartTags: _currentAnalysis!.smartTags,
      averageConfidence: _currentAnalysis!.averageConfidence,
      followUpQuestions: _pendingQuestions,
      followUpResponses: _followUpResponses,
      hasFollowUpPending: false,
      dailyFollowUpCount: _pendingQuestions.length,
      recommendedNudgeIds: nudgeResult.recommendedNudgeIds,
      hasNudgeRecommendations: nudgeResult.hasRecommendations,
      isProcessed: true,
      metadata: {
        'analysis_timestamp': _currentAnalysis!.timestamp.toIso8601String(),
        'nudge_reasoning': nudgeResult.reasoning,
        'follow_up_count': _followUpResponses.length,
      },
    );

    // Submit to parent
    widget.onEntrySubmitted(entry);

    // Clear state
    _textController.clear();
    _followUpController.clear();
    _currentAnalysis = null;
    _pendingQuestions.clear();
    _followUpResponses.clear();
    _slideController.reset();
    _fadeController.reset();
  }

  /// Fallback submission for basic entries
  Future<void> _submitBasicEntry(String text) async {
    final entry = SmartJournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: text,
      timestamp: DateTime.now(),
      smartTags: [],
      averageConfidence: 0.0,
      isProcessed: false,
      metadata: {'fallback_entry': true},
    );

    widget.onEntrySubmitted(entry);
    _textController.clear();
  }

  /// Handle follow-up question response
  void _handleFollowUpResponse(String response) {
    if (_currentQuestionIndex >= _pendingQuestions.length) return;

    final question = _pendingQuestions[_currentQuestionIndex];
    _followUpResponses[question.id] = response;

    HapticFeedback.lightImpact();

    if (_currentQuestionIndex < _pendingQuestions.length - 1) {
      // Move to next question
      setState(() {
        _currentQuestionIndex++;
      });
      // Clear the follow-up controller for the next question
      _followUpController.clear();
    } else {
      // All questions answered, submit entry
      _submitJournalEntry();
    }
  }

  /// Handle follow-up submission from main button
  void _handleFollowUpSubmit() {
    final response = _followUpController.text.trim();
    if (response.isNotEmpty) {
      _handleFollowUpResponse(response);
      _followUpController.clear();
    }
  }

  /// Skip current follow-up question
  void _skipFollowUp() {
    // Clear any text in the follow-up controller
    _followUpController.clear();
    
    if (_currentQuestionIndex < _pendingQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitJournalEntry();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accentColor.withValues(alpha: 0.1),
            widget.surfaceColor ?? StarboundColors.surface.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main input section
          _buildMainInput(),
          
          // Smart tags display (if available)
          if (_currentAnalysis?.hasSmartTags == true) ...[
            const SizedBox(height: 16),
            _buildSmartTagsDisplay(),
          ],
          
          // Contextual suggestions display (if available)
          if (_currentAnalysis?.hasContextualSuggestions == true) ...[
            const SizedBox(height: 16),
            _buildSuggestionsDisplay(),
          ],
          
          // Follow-up questions (if any)
          if (_pendingQuestions.isNotEmpty && _currentQuestionIndex < _pendingQuestions.length) ...[
            const SizedBox(height: 16),
            _buildFollowUpSection(),
          ],
          
          // Submit button
          const SizedBox(height: 20),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  /// Build main text input section
  Widget _buildMainInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input label
        Row(
          children: [
            const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'How was your day?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_isAnalyzing) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Analysing...',
                style: TextStyle(
                  color: widget.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Text input
        Container(
          decoration: BoxDecoration(
            color: widget.surfaceColor ?? StarboundColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focusNode.hasFocus 
                ? widget.accentColor.withValues(alpha: 0.5)
                : widget.accentColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            maxLines: 4,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder ??
                'Track symptoms, medications, or how you\'re feeling today...',
              hintStyle: TextStyle(
                color: widget.accentColor.withValues(alpha: 0.5),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) => setState(() {}), // Trigger rebuild for button state
          ),
        ),
      ],
    );
  }

  /// Build smart tags display section
  Widget _buildSmartTagsDisplay() {
    if (_currentAnalysis?.smartTags.isEmpty == true) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.surfaceColor ?? StarboundColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: widget.accentColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Smart Tags Detected',
                    style: TextStyle(
                      color: widget.accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.showConfidenceScores) ...[
                    const Spacer(),
                    Text(
                      '${(_currentAnalysis!.averageConfidence * 100).round()}% confidence',
                      style: TextStyle(
                        color: widget.accentColor.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentAnalysis!.smartTags.map((tag) => _buildSmartTagChip(tag)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual smart tag chip
  Widget _buildSmartTagChip(SmartTag tag) {
    final categoryColor = _getCategoryColor(tag.category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag.categoryEmoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            tag.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.showConfidenceScores) ...[
            const SizedBox(width: 4),
            Text(
              '${(tag.confidence * 100).round()}%',
              style: TextStyle(
                color: widget.accentColor.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build follow-up question section
  Widget _buildFollowUpSection() {
    final question = _pendingQuestions[_currentQuestionIndex];
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.surfaceColor ?? StarboundColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header
              Row(
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${_currentQuestionIndex + 1}/${_pendingQuestions.length}',
                    style: TextStyle(
                      color: widget.accentColor.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Response options
              if (question.isMultipleChoice) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: question.suggestedResponses
                      .map((response) => _buildResponseOption(response))
                      .toList(),
                ),
              ] else ...[
                // Open text input for non-multiple choice
                TextField(
                  controller: _followUpController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your response...',
                    hintStyle: TextStyle(color: widget.accentColor.withValues(alpha: 0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.accentColor.withValues(alpha: 0.25)),
                    ),
                  ),
                  onSubmitted: _handleFollowUpResponse,
                  onChanged: (_) => setState(() {}), // Trigger rebuild for button state
                ),
              ],
              
              // Skip option
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _skipFollowUp,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: widget.accentColor.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build response option button
  Widget _buildResponseOption(String response) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleFollowUpResponse(response),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            response,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Build submit button
  Widget _buildSubmitButton() {
    final hasFollowUps = _pendingQuestions.isNotEmpty && _currentQuestionIndex < _pendingQuestions.length;
    final hasText = hasFollowUps 
        ? _followUpController.text.trim().isNotEmpty 
        : _textController.text.trim().isNotEmpty;
    final isEnabled = hasText && !_isAnalyzing && !widget.isProcessing;
    
    return CosmicButton.primary(
      onPressed: isEnabled
          ? (hasFollowUps ? _handleFollowUpSubmit : _handleSubmit)
          : null,
      accentColor: widget.accentColor,
      icon: hasFollowUps ? Icons.question_answer : Icons.send,
      width: double.infinity,
      size: CosmicButtonSize.large,
      isLoading: _isAnalyzing || widget.isProcessing,
      loadingLabel: 'Analysing...',
      child: Text(
        hasFollowUps ? 'Continue' : 'Share Entry',
      ),
    );
  }

  /// Build suggestions display section
  Widget _buildSuggestionsDisplay() {
    if (_currentAnalysis?.contextualSuggestions.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: widget.accentColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Suggestions for you',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentAnalysis!.contextualSuggestions.length}',
                  style: TextStyle(
                    color: widget.accentColor.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SuggestionDisplayWidget(
              suggestions: _currentAnalysis!.contextualSuggestions,
              isCompact: true,
              showActions: true,
              onSuggestionTapped: _handleSuggestionTapped,
              onSuggestionDismissed: _handleSuggestionDismissed,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle suggestion tap
  void _handleSuggestionTapped(ContextualSuggestion suggestion) {
    HapticFeedback.mediumImpact();
    
    // Show detailed view of suggestion
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: SuggestionDisplayWidget(
                suggestions: [suggestion],
                isCompact: false,
                showActions: true,
                onSuggestionTapped: (s) {
                  Navigator.pop(context);
                  _applySuggestion(s);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle suggestion dismissed
  void _handleSuggestionDismissed(ContextualSuggestion suggestion) {
    HapticFeedback.lightImpact();
    // Could implement dismissal logic here
    debugPrint('Suggestion dismissed: ${suggestion.title}');
  }

  /// Apply suggestion (when user taps "Try This Now")
  void _applySuggestion(ContextualSuggestion suggestion) async {
    HapticFeedback.mediumImpact();
    
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
                    '"${suggestion.title}" saved to your Action Vault!',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'View Vault',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to Action Vault (this would need proper navigation setup)
                Navigator.of(context).pushNamed('/action-vault');
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save suggestion as nudge: $e');
      
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

  /// Convert ContextualSuggestion to StarboundNudge for saving to vault
  StarboundNudge _convertSuggestionToNudge(ContextualSuggestion suggestion) {
    // Map category to theme
    String theme = _mapCategoryToTheme(suggestion.category);
    
    // Determine nudge type based on relevance and category
    NudgeType nudgeType = suggestion.relevanceScore >= 0.8 
        ? NudgeType.encouragement 
        : NudgeType.suggestion;
    
    // Create unique ID for the nudge
    final uniqueId = 'suggestion_${suggestion.id}_${DateTime.now().millisecondsSinceEpoch}';
    
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
        'source': 'contextual_suggestion',
        'original_suggestion_id': suggestion.id,
        'relevance_score': suggestion.relevanceScore,
        'trigger_tags': suggestion.triggerTagKeys,
        'generated_from_journal': true,
        'creation_method': 'smart_journaling',
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

  /// Get color for tag category
  Color _getCategoryColor(TagCategory category) {
    switch (category) {
      case TagCategory.choice:
        return const Color(0xFF4CAF50); // Green
      case TagCategory.chance:
        return const Color(0xFFFF9800); // Orange  
      case TagCategory.outcome:
        return const Color(0xFF2196F3); // Blue
    }
  }
}
