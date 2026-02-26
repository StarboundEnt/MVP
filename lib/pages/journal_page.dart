import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import 'dart:ui';
import '../models/habit_model.dart';
import '../models/smart_tag_model.dart';
import '../models/nudge_model.dart';
import '../providers/app_state.dart';
import '../components/complexity_badge.dart';
import '../components/interactive_tag_chip.dart';
import '../services/habit_classifier_service.dart';
import '../services/smart_tagging_service.dart';
import '../services/daily_prompts_service.dart';
import '../services/action_conversion_service.dart';
import '../services/journaling_reminder_service.dart';
import '../services/graphiti_service.dart';
import '../widgets/smart_journal_widget.dart';
import '../design_system/design_system.dart';
import '../pages/complexity_profile_page.dart';
import '../utils/tag_utils.dart';

class JournalPage extends StatefulWidget {
  final VoidCallback onGoBack;
  final Map<String, dynamic> habits;
  final Function(String, String) updateHabit;
  final String? nudge;
  final VoidCallback bankNudge;
  final VoidCallback? onNavigateToAnalytics;
  final bool embedded;

  const JournalPage({
    Key? key,
    required this.onGoBack,
    required this.habits,
    required this.updateHabit,
    this.nudge,
    required this.bankNudge,
    this.onNavigateToAnalytics,
    this.embedded = false,
  }) : super(key: key);

  @override
  State<JournalPage> createState() => JournalPageState();
}

class JournalPageState extends State<JournalPage>
    with TickerProviderStateMixin {
  late Map<String, dynamic> habits;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _textController = TextEditingController();
  final HabitClassifierService _classifierService = HabitClassifierService();
  final SmartTaggingService _smartTaggingService = SmartTaggingService();
  final DailyPromptsService _promptsService = DailyPromptsService();
  final JournalingReminderService _reminderService =
      JournalingReminderService();
  final ActionConversionService _actionService = ActionConversionService();
  List<FreeFormEntry> _recentReflections = [];
  List<SmartJournalEntry> _smartReflections = [];
  bool _isClassifierReady = false;
  bool _isSmartTaggingReady = false;
  bool _isProcessing = false;
  String _dailyPrompt = "How's your health today?";
  Set<String> _pinnedTags = <String>{};
  Map<String, String> _renamedTags = <String, String>{};
  Map<String, dynamic>? _pendingHabitSuggestion;
  String? _pendingHabitTag;
  Timer? _statusTimer;
  String? _statusMessage;
  Color? _statusAccent;
  String? _statusActionLabel;
  VoidCallback? _statusAction;

  @override
  void initState() {
    super.initState();
    habits = widget.habits;

    // Animation controller for fade transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _initializeClassifier();
    _initializeSmartTagging();
    _loadDailyPrompt();
    _loadRecentReflections();
    _fadeController.forward();

    // Listen to AppState changes to refresh entries when new ones are added from other pages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().addListener(_onAppStateChanged);
      _checkForPendingDraft();
    });
  }

  @override
  void dispose() {
    // Remove listener to prevent memory leaks
    try {
      context.read<AppState>().removeListener(_onAppStateChanged);
    } catch (e) {
      // Context might be disposed already, ignore
    }
    _fadeController.dispose();
    _textController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  void _onAppStateChanged() {
    // Reload recent reflections when AppState changes (e.g., new entry from Home page)
    if (mounted) {
      _loadRecentReflections();
    }
  }

  /// Called by parent when this page becomes visible again inside the tab stack.
  void handlePendingJournalDraft() {
    if (!mounted) return;
    _checkForPendingDraft();
  }

  void _checkForPendingDraft() {
    final appState = context.read<AppState>();
    final pendingDraft = appState.getPendingJournalDraft();
    if (pendingDraft == null) {
      return;
    }

    final text = (pendingDraft['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      appState.clearPendingJournalDraft();
      return;
    }

    appState.clearPendingJournalDraft();
    _onSmartInputSubmitted(text);
  }

  /// Initialize the habit classifier service
  Future<void> _initializeClassifier() async {
    try {
      final success = await _classifierService.initialize();
      setState(() {
        _isClassifierReady = success;
      });
    } catch (e) {
      debugPrint('Failed to initialize classifier: $e');
    }
  }

  /// Initialize the smart tagging service
  Future<void> _initializeSmartTagging() async {
    try {
      final success = await _smartTaggingService.initialize();
      setState(() {
        _isSmartTaggingReady = success;
      });
      debugPrint('SmartTaggingService initialized: $success');
    } catch (e) {
      debugPrint('Failed to initialize smart tagging: $e');
    }
  }

  /// Load today's daily prompt
  Future<void> _loadDailyPrompt() async {
    try {
      final prompt = await _promptsService.getTodaysPrompt();
      setState(() {
        _dailyPrompt = prompt;
      });
      debugPrint('Daily prompt loaded: $prompt');
    } catch (e) {
      debugPrint('Failed to load daily prompt: $e');
      // Keep default prompt on error
    }
  }

  /// Load recent reflections from app state
  Future<void> _loadRecentReflections() async {
    try {
      final appState = context.read<AppState>();
      final existingEntries = appState.getRecentFreeFormEntries(limit: 20);

      setState(() {
        _recentReflections = _dedupeRecentReflections(existingEntries);
      });

      debugPrint('Loaded ${existingEntries.length} existing journal entries');
      for (final entry in _recentReflections.take(5)) {
        debugPrint('Entry ${entry.id} -> '
            '${entry.classifications.map((c) => c.categoryTitle)}');
      }

      // Check for repeated tags and suggest habit tracking
      _checkForHabitTrackingSuggestions(existingEntries);
    } catch (e) {
      debugPrint('Failed to load recent reflections: $e');
      // Initialize with empty list on error
      setState(() {
        _recentReflections = [];
      });
    }
  }

  List<FreeFormEntry> _dedupeRecentReflections(List<FreeFormEntry> entries) {
    if (entries.isEmpty) {
      return entries;
    }

    final List<FreeFormEntry> deduped = [];

    for (final entry in entries) {
      final existingIndex = deduped.indexWhere((candidate) {
        final sameText = candidate.originalText.trim().toLowerCase() ==
            entry.originalText.trim().toLowerCase();
        final closeInTime =
            (candidate.timestamp.difference(entry.timestamp).abs()) <
                const Duration(minutes: 2);
        return sameText && closeInTime;
      });

      if (existingIndex == -1) {
        deduped.add(entry);
      } else {
        final current = deduped[existingIndex];
        final currentScore = _reflectionRichnessScore(current);
        final newScore = _reflectionRichnessScore(entry);

        if (newScore >= currentScore) {
          deduped[existingIndex] = entry;
        }
      }
    }

    return deduped.take(20).toList();
  }

  int _reflectionRichnessScore(FreeFormEntry entry) {
    if (entry.classifications.isEmpty) {
      return entry.metadata?['smart_tags_count'] is int
          ? entry.metadata['smart_tags_count'] as int
          : 0;
    }

    int score = 0;
    for (final classification in entry.classifications) {
      if (classification.categoryTitle.toLowerCase() != 'general') {
        score += 4;
      }
      score += classification.themes.length * 2;
      score += classification.keywords.length;
      if (classification.sentiment == 'positive' ||
          classification.sentiment == 'negative') {
        score += 1;
      }
    }

    if (entry.metadata?['smart_tags_count'] is int) {
      score += (entry.metadata['smart_tags_count'] as int);
    }

    return score;
  }

  ClassificationResult _buildClassificationFromSmartEntry(
      SmartJournalEntry entry) {
    if (entry.smartTags.isEmpty) {
      return ClassificationResult(
        habitKey: 'reflection',
        habitValue: '1',
        categoryTitle: 'Personal Reflection',
        categoryType: 'choice',
        confidence: entry.averageConfidence,
        reasoning: 'Fallback classification with basic sentiment analysis',
        extractedText: entry.originalText,
        sentiment: _detectSentiment(entry.originalText),
        themes: ['personal_reflection'],
        keywords: _extractKeywords(entry.originalText),
        metadata: const {
          'source': 'smart_journal_entry',
          'fallback': true,
        },
      );
    }

    SmartTag primaryTag = entry.smartTags.reduce((a, b) {
      if (a.confidence == b.confidence) {
        return a.createdAt.isBefore(b.createdAt) ? b : a;
      }
      return a.confidence >= b.confidence ? a : b;
    });

    final allThemes = entry.smartTags
        .map((tag) => tag.canonicalKey.replaceAll('_', ' '))
        .map((theme) => theme.trim())
        .where((theme) => theme.isNotEmpty)
        .toSet()
        .toList();

    final allKeywords = entry.smartTags
        .expand((tag) => tag.keywords)
        .map((keyword) => keyword.trim().toLowerCase())
        .where((keyword) => keyword.isNotEmpty)
        .toSet()
        .toList();

    String overallSentiment = 'neutral';
    if (entry.smartTags.any((tag) => tag.isPositive)) {
      overallSentiment = 'positive';
    } else if (entry.smartTags.any((tag) => tag.isNegative)) {
      overallSentiment = 'negative';
    }

    String categoryType;
    switch (primaryTag.category) {
      case TagCategory.choice:
        categoryType = 'choice';
        break;
      case TagCategory.chance:
        categoryType = 'chance';
        break;
      case TagCategory.outcome:
        categoryType = 'outcome';
        break;
    }

    final keywords = allKeywords.isEmpty
        ? _extractKeywords(entry.originalText)
        : allKeywords;

    return ClassificationResult(
      habitKey: primaryTag.canonicalKey,
      habitValue: primaryTag.metadata['habitValue']?.toString() ?? '1',
      categoryTitle: primaryTag.displayName,
      categoryType: categoryType,
      confidence: entry.averageConfidence,
      reasoning:
          'Derived from smart tagging (${primaryTag.displayName}) with ${entry.smartTags.length} detected patterns',
      extractedText: entry.originalText,
      sentiment: overallSentiment,
      themes: allThemes.isNotEmpty ? allThemes : ['personal_reflection'],
      keywords: keywords,
      metadata: {
        'source': 'smart_journal_entry',
        'smart_tag_ids': entry.smartTags.map((tag) => tag.id).toList(),
        'smart_tag_names':
            entry.smartTags.map((tag) => tag.displayName).toList(),
        'primary_tag_confidence': primaryTag.confidence,
      },
    );
  }

  /// Check for repeated tags and suggest habit tracking
  Future<void> _checkForHabitTrackingSuggestions(
      List<FreeFormEntry> entries) async {
    try {
      final repeatedTags = await _actionService.detectRepeatedTags(entries);

      if (repeatedTags.isNotEmpty && mounted) {
        // Show habit tracking suggestion for the first repeated tag
        final tag = repeatedTags.first;
        final suggestion = _actionService.generateHabitSuggestion(tag, 3);

        if (_pendingHabitTag == tag) {
          return;
        }

        setState(() {
          _pendingHabitSuggestion = suggestion;
          _pendingHabitTag = tag;
        });

        final formattedName = suggestion['formatted_name'] ?? tag;
        _showStatusMessage(
          'Noticing "$formattedName" a lot—want to turn it into a habit?',
          StarboundColors.stellarAqua,
        );
      }
    } catch (e) {
      debugPrint('Failed to check for habit tracking suggestions: $e');
    }
  }

  /// Show habit tracking suggestion modal
  Future<void> _showHabitTrackingSuggestionModal(
      Map<String, dynamic> suggestion, String tag) async {
    await showModalBottomSheet(
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
                color: StarboundColors.background.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
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
                          color: StarboundColors.nebulaPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.target,
                          size: 20,
                          color: StarboundColors.nebulaPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion['title']!,
                              style: StarboundTypography.heading2.copyWith(
                                color: StarboundColors.textPrimary,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Turn patterns into progress',
                              style: StarboundTypography.body.copyWith(
                                color: StarboundColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          LucideIcons.x,
                          color: StarboundColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.trendingUp,
                              size: 16,
                              color: StarboundColors.nebulaPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pattern Detected',
                              style: StarboundTypography.bodyLarge.copyWith(
                                color: StarboundColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          suggestion['description']!,
                          style: StarboundTypography.body.copyWith(
                            color: StarboundColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                StarboundColors.nebulaPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.repeat,
                                size: 14,
                                color: StarboundColors.nebulaPurple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Suggested frequency: ${suggestion['suggested_frequency']}',
                                style: StarboundTypography.bodySmall.copyWith(
                                  color: StarboundColors.nebulaPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            // Mark as suggested so we don't ask again
                            await _actionService
                                .markTagAsSuggestedForHabits(tag);
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Not Now',
                            style: StarboundTypography.button.copyWith(
                              color: StarboundColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CosmicButton.primary(
                          onPressed: () async {
                            await _actionService
                                .markTagAsSuggestedForHabits(tag);
                            Navigator.of(context).pop();
                            _showStatusMessage(
                              '${suggestion['formatted_name']} added to habit tracking!',
                              StarboundColors.success,
                            );
                          },
                          accentColor: StarboundColors.nebulaPurple,
                          child: const Text('Start Tracking'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handle tag pinning/unpinning
  void _handleTagPin(String tag) {
    bool willPin = !_pinnedTags.contains(tag);

    setState(() {
      if (willPin) {
        _pinnedTags.add(tag);
      } else {
        _pinnedTags.remove(tag);
      }
    });

    _showStatusMessage(
      willPin ? 'Pattern pinned for tracking' : 'Pattern unpinned',
      willPin ? StarboundColors.stellarYellow : StarboundColors.textSecondary,
    );
  }

  /// Handle tag renaming
  void _handleTagRename(String originalTag, String newTag) {
    setState(() {
      _renamedTags[originalTag] = newTag;
    });

    // Show feedback
    _showStatusMessage(
        'Tag renamed to "$newTag"', StarboundColors.nebulaPurple);
  }

  /// Handle nudge request for specific tag
  void _handleNudgeRequest(String tag) {
    // Generate a contextual nudge based on the tag
    String nudgeMessage = _generateTagBasedNudge(tag);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNudgeModal(tag, nudgeMessage),
    );
  }

  String _generateTagBasedNudge(String tag) {
    final tagLower = tag.toLowerCase();

    if (tagLower.contains('anxiety') || tagLower.contains('stress')) {
      return "Try the 3-3-3 technique: Name 3 things you see, 3 sounds you hear, and move 3 parts of your body.";
    } else if (tagLower.contains('tired') || tagLower.contains('energy')) {
      return "A 5-minute walk outside or some gentle stretches might help restore your energy.";
    } else if (tagLower.contains('lonely') || tagLower.contains('sad')) {
      return "Consider reaching out to a friend or doing one small thing that usually brings you joy.";
    } else if (tagLower.contains('overwhelmed')) {
      return "Write down 3 things you need to do today, then pick just one to focus on right now.";
    } else {
      return "Take a moment to breathe deeply and acknowledge how you're feeling right now.";
    }
  }

  Widget _buildNudgeModal(String tag, String nudgeMessage) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: StarboundColors.background.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: StarboundColors.stellarAqua.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.lightbulb,
                        size: 20,
                        color: StarboundColors.stellarAqua,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Suggestion for ${tag.replaceAll('_', ' ')}',
                        style: StarboundTypography.heading2.copyWith(
                          color: StarboundColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        LucideIcons.x,
                        color: StarboundColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  nudgeMessage,
                  style: StarboundTypography.bodyLarge.copyWith(
                    color: StarboundColors.textPrimary,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: StarboundColors.textSecondary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'Maybe later',
                          style:
                              TextStyle(color: StarboundColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // TODO: Track that user tried the suggestion
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StarboundColors.stellarAqua,
                          foregroundColor: StarboundColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('I\'ll try this'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dismiss the current habit suggestion inline card
  Future<void> _dismissHabitSuggestion({bool markSuggested = false}) async {
    final tag = _pendingHabitTag;
    if (tag == null) return;

    if (markSuggested) {
      try {
        await _actionService.markTagAsSuggestedForHabits(tag);
      } catch (e) {
        debugPrint('Failed to mark tag as suggested: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _pendingHabitSuggestion = null;
      _pendingHabitTag = null;
    });
  }

  /// Handle smart input processing with enhanced AI tagging
  Future<void> _onSmartInputSubmitted(String input) async {
    final trimmedInput = input.trim();
    if (trimmedInput.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isProcessing = true;
    });

    try {
      if (_isClassifierReady) {
        // Use the app state's processFreeFormEntry method when services are ready
        final appState = context.read<AppState>();
        final entry = await appState.processFreeFormEntry(trimmedInput);

        await _reminderService.recordJournalActivity();

        final totalTags = entry.classifications
            .map((c) => c.themes.length + c.keywords.length)
            .fold<int>(0, (sum, count) => sum + count);

        final summaryText = totalTags > 0
            ? "Journal entry saved! I found $totalTags insights to explore."
            : "Journal entry saved! AI analysis complete.";

        _showStatusMessage(summaryText, StarboundColors.success);

        await _loadRecentReflections();
      } else {
        // Services aren't ready yet – capture a simple entry
        await _createFallbackEntry(trimmedInput);
        _showStatusMessage(
          'Journal entry saved. I\'ll add insights once analysis is ready.',
          StarboundColors.stellarAqua,
        );
      }
    } catch (e) {
      debugPrint('Smart input processing failed: $e');
      await _createFallbackEntry(trimmedInput);
      _showStatusMessage(
        'Saved with basic analysis while smart tools recover.',
        StarboundColors.warning,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Enhanced AI tagging to ensure all entries get meaningful tags
  Future<List<ClassificationResult>> _enhanceClassificationsWithAI(
      String input, List<ClassificationResult> existingClassifications) async {
    // If we already have good classifications with themes, return as-is
    if (existingClassifications.isNotEmpty &&
        existingClassifications.any((c) => c.themes.isNotEmpty)) {
      return existingClassifications;
    }

    // Generate AI-powered tags for entries that lack sufficient classification
    try {
      final aiTags = await _generateAITags(input);

      if (existingClassifications.isEmpty) {
        // Create new classification with AI-generated tags
        return [
          ClassificationResult(
            habitKey: 'reflection',
            habitValue: '1',
            categoryTitle: 'Personal Reflection',
            categoryType: 'choice',
            confidence: 0.8,
            reasoning: 'Generated comprehensive tags using AI analysis',
            extractedText: input,
            sentiment: _detectSentiment(input),
            themes: aiTags,
            keywords: _extractKeywords(input),
          )
        ];
      } else {
        // Enhance existing classifications with AI tags
        return existingClassifications.map((classification) {
          return ClassificationResult(
            habitKey: classification.habitKey,
            habitValue: classification.habitValue,
            categoryTitle: classification.categoryTitle,
            categoryType: classification.categoryType,
            confidence: classification.confidence,
            reasoning: classification.reasoning + ' (Enhanced with AI tagging)',
            extractedText: classification.extractedText,
            sentiment: classification.sentiment,
            themes: [...classification.themes, ...aiTags].toSet().toList(),
            keywords: [...classification.keywords, ..._extractKeywords(input)]
                .toSet()
                .toList(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('AI tag generation failed: $e');
      // Return existing classifications with basic fallback tags
      if (existingClassifications.isEmpty) {
        return [_createBasicClassification(input)];
      }
      return existingClassifications;
    }
  }

  /// Generate AI-powered tags for better categorization
  Future<List<String>> _generateAITags(String input) async {
    // Use simple keyword detection and sentiment analysis for now
    // In a full implementation, this would call an AI service
    final tags = <String>[];
    final lowerInput = input.toLowerCase();

    // Emotion-based tags
    if (lowerInput.contains(
        RegExp(r'\b(happy|joy|excited|great|amazing|wonderful|good)\b'))) {
      tags.add('positive_emotion');
    }
    if (lowerInput
        .contains(RegExp(r'\b(sad|upset|down|depressed|unhappy|bad)\b'))) {
      tags.add('negative_emotion');
    }
    if (lowerInput
        .contains(RegExp(r'\b(anxious|worried|stress|nervous|panic)\b'))) {
      tags.add('anxiety');
    }
    if (lowerInput.contains(RegExp(r'\b(tired|exhausted|fatigue|sleepy)\b'))) {
      tags.add('fatigue');
    }

    // Activity-based tags
    if (lowerInput.contains(RegExp(r'\b(work|job|office|meeting|project)\b'))) {
      tags.add('work');
    }
    if (lowerInput
        .contains(RegExp(r'\b(family|friend|social|people|relationship)\b'))) {
      tags.add('social');
    }
    if (lowerInput
        .contains(RegExp(r'\b(exercise|workout|run|walk|gym|sport)\b'))) {
      tags.add('physical_activity');
    }
    if (lowerInput.contains(RegExp(r'\b(eat|food|meal|hungry|cook)\b'))) {
      tags.add('nutrition');
    }
    if (lowerInput.contains(RegExp(r'\b(sleep|bed|rest|nap|dream)\b'))) {
      tags.add('sleep');
    }

    // Context-based tags
    if (lowerInput.contains(RegExp(r'\b(home|house|room)\b'))) {
      tags.add('home');
    }
    if (lowerInput.contains(RegExp(r'\b(outside|outdoor|nature|weather)\b'))) {
      tags.add('outdoor');
    }

    // Default tags if nothing specific found
    if (tags.isEmpty) {
      tags.addAll(['daily_life', 'personal_reflection', 'mood_check']);
    }

    return tags.take(5).toList(); // Limit to 5 most relevant tags
  }

  /// Create basic classification for fallback scenarios
  ClassificationResult _createBasicClassification(String input) {
    return ClassificationResult(
      habitKey: 'reflection',
      habitValue: '1',
      categoryTitle: 'Personal Reflection',
      categoryType: 'choice',
      confidence: 0.6,
      reasoning: 'Fallback classification with basic sentiment analysis',
      extractedText: input,
      sentiment: _detectSentiment(input),
      themes: [
        'personal_reflection',
        'daily_check_in',
        _detectSentiment(input)
      ],
      keywords: _extractKeywords(input),
    );
  }

  /// Detect sentiment from text
  String _detectSentiment(String input) {
    final lowerInput = input.toLowerCase();

    final positiveWords = [
      'good',
      'great',
      'happy',
      'amazing',
      'wonderful',
      'excited',
      'joy',
      'love',
      'perfect',
      'awesome'
    ];
    final negativeWords = [
      'bad',
      'terrible',
      'sad',
      'angry',
      'hate',
      'awful',
      'horrible',
      'upset',
      'frustrated',
      'stressed'
    ];

    int positiveCount =
        positiveWords.where((word) => lowerInput.contains(word)).length;
    int negativeCount =
        negativeWords.where((word) => lowerInput.contains(word)).length;

    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }

  /// Extract key words from input
  List<String> _extractKeywords(String input) {
    // Simple keyword extraction - remove common words and extract meaningful terms
    final commonWords = [
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'i',
      'me',
      'my',
      'was',
      'is',
      'am',
      'are'
    ];
    final words = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((word) => word.length > 2 && !commonWords.contains(word))
        .toList();

    return words.take(3).toList(); // Return top 3 keywords
  }

  /// Create fallback entry when main processing fails
  Future<void> _createFallbackEntry(String input) async {
    try {
      final fallbackClassification = _createBasicClassification(input);

      final entry = FreeFormEntry(
        id: 'reflection_${DateTime.now().millisecondsSinceEpoch}',
        originalText: input,
        timestamp: DateTime.now(),
        classifications: [fallbackClassification],
        averageConfidence: 0.6,
        isProcessed: true,
      );

      // Save to app state storage for persistence
      final appState = context.read<AppState>();
      await appState.addSimpleFreeFormEntry(entry);

      // Refresh local cache so UI stays in sync
      await _loadRecentReflections();
    } catch (e) {
      debugPrint('Fallback entry creation failed: $e');
      _showStatusMessage(
        'Unable to save your reflection. Please try again.',
        StarboundColors.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildEmbeddedBody();
    }

    return CosmicPageScaffold(
      title: "Your Journal",
      titleIcon: Icons.edit_note_rounded,
      onBack: widget.onGoBack,
      accentColor: StarboundColors.stellarAqua,
      actions: [
        Consumer<AppState>(
          builder: (context, appState, child) {
            return ComplexityBadge(
              level: appState.complexityProfile,
              showLabel: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ComplexityProfilePage(),
                  ),
                );
              },
            );
          },
        ),
      ],
      contentPadding: EdgeInsets.zero,
      backgroundColor: StarboundColors.deepSpace,
      body: Stack(
        children: [
          // Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: StarboundColors.deepSpace,
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_statusMessage != null) _buildStatusBanner(),
                          if (_pendingHabitSuggestion != null &&
                              _pendingHabitTag != null)
                            _buildHabitSuggestionBanner(),
                          // Smart Input Section
                          _buildSmartInputSection(),
                          const SizedBox(height: 32),

                          // Journal History Section
                          _buildJournalHistorySection(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_statusMessage != null) _buildStatusBanner(),
            if (_pendingHabitSuggestion != null && _pendingHabitTag != null)
              _buildHabitSuggestionBanner(),
            _buildSmartInputSection(),
            const SizedBox(height: 32),
            _buildJournalHistorySection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitSuggestionBanner() {
    final suggestion = _pendingHabitSuggestion;
    final tag = _pendingHabitTag;

    if (suggestion == null || tag == null) {
      return const SizedBox.shrink();
    }

    final capturedSuggestion = Map<String, dynamic>.from(suggestion);
    final capturedTag = tag;
    final formattedName = capturedSuggestion['formatted_name'] ??
        capturedSuggestion['title'] ??
        capturedTag;
    final description = capturedSuggestion['description'] ?? '';
    final frequency = capturedSuggestion['suggested_frequency'];

    return CosmicGlassPanel.success(
      margin: const EdgeInsets.only(bottom: StarboundSpacing.lg),
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CosmicIconBadge.success(icon: LucideIcons.target),
              StarboundSpacing.hSpaceMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Habit idea spotted',
                      style: StarboundTypography.bodySmall.copyWith(
                        color: StarboundColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedName,
                      style: StarboundTypography.heading3.copyWith(
                        color: StarboundColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _dismissHabitSuggestion(markSuggested: true),
                icon: Icon(
                  LucideIcons.x,
                  color: StarboundColors.textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: StarboundTypography.body.copyWith(
                color: StarboundColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
          if (frequency != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.repeat,
                    size: 14,
                    color: StarboundColors.stellarAqua,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Suggested frequency: $frequency',
                    style: StarboundTypography.bodySmall.copyWith(
                      color: StarboundColors.stellarAqua,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: () async {
                  await _dismissHabitSuggestion(markSuggested: true);
                  _showStatusMessage(
                      'Okay, I\'ll keep an eye out for other patterns.',
                      StarboundColors.textSecondary);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: StarboundColors.textPrimary,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Dismiss'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _pendingHabitSuggestion = null;
                    _pendingHabitTag = null;
                  });
                  await _showHabitTrackingSuggestionModal(
                      capturedSuggestion, capturedTag);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: StarboundColors.stellarAqua,
                  foregroundColor: StarboundColors.background,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('See suggestion'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStatusMessage(
    String message,
    Color accent, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;

    _statusTimer?.cancel();
    setState(() {
      _statusMessage = message;
      _statusAccent = accent;
      _statusActionLabel = actionLabel;
      _statusAction = onAction;
    });

    _statusTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        _statusMessage = null;
        _statusAccent = null;
        _statusActionLabel = null;
        _statusAction = null;
      });
    });
  }

  Widget _buildStatusBanner() {
    if (_statusMessage == null) {
      return const SizedBox.shrink();
    }

    final accent = _statusAccent ?? StarboundColors.stellarAqua;

    return CosmicGlassPanel(
      margin: const EdgeInsets.only(bottom: StarboundSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      tintColor: accent.withValues(alpha: 0.16),
      borderColor: accent.withValues(alpha: 0.45),
      shadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.2),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CosmicIconBadge(
            icon: LucideIcons.sparkles,
            color: accent,
            padding: const EdgeInsets.all(8),
            glowIntensity: 0.25,
          ),
          StarboundSpacing.hSpaceSM,
          Expanded(
            child: Text(
              _statusMessage!,
              style: StarboundTypography.body.copyWith(
                color: StarboundColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          if (_statusActionLabel != null && _statusAction != null)
            TextButton(
              onPressed: () {
                final callback = _statusAction;
                _statusTimer?.cancel();
                setState(() {
                  _statusMessage = null;
                  _statusAccent = null;
                  _statusActionLabel = null;
                  _statusAction = null;
                });
                callback?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: StarboundTypography.button.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(_statusActionLabel!),
            ),
          IconButton(
            onPressed: () {
              _statusTimer?.cancel();
              setState(() {
                _statusMessage = null;
                _statusAccent = null;
                _statusActionLabel = null;
                _statusAction = null;
              });
            },
            icon: Icon(
              LucideIcons.x,
              size: 18,
              color: accent,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page subtitle
        Text(
          "Share what's on your mind",
          style: StarboundTypography.body.copyWith(
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          "How are you feeling today?",
          style: StarboundTypography.heading2.copyWith(
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Share anything - I'll help identify patterns and insights",
          style: StarboundTypography.body.copyWith(
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Smart Input Widget - need to create this locally since we removed the component
        _buildJournalInput(),
      ],
    );
  }

  Widget _buildJournalInput() {
    if (_isSmartTaggingReady) {
      // Use SmartJournalWidget when available
      return SmartJournalWidget(
        onEntrySubmitted: _handleSmartJournalEntry,
        isProcessing: _isProcessing,
        placeholder: _dailyPrompt,
        showConfidenceScores: false,
        enableFollowUps: true,
        accentColor: StarboundColors.stellarAqua,
        surfaceColor: StarboundColors.surface.withValues(alpha: 0.7),
      );
    }

    // Fallback to traditional input when smart tagging unavailable
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: StarboundColors.stellarAqua.withValues(alpha: 0.15),
                      boxShadow: StarboundColors.cosmicGlow(
                        StarboundColors.stellarAqua,
                        intensity: 0.2,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 18,
                      color: StarboundColors.stellarAqua,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "How was your day?",
                      style: StarboundTypography.heading3,
                    ),
                  ),
                  if (!_isClassifierReady)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          StarboundColors.stellarAqua,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Text input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  minLines: 4,
                  maxLines: 8,
                  style: StarboundTypography.bodyLarge.copyWith(
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: _dailyPrompt,
                    hintStyle: StarboundTypography.body,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _onSmartInputSubmitted(text);
                      _textController.clear();
                    }
                  },
                ),
              ),

              // Submit button
              const SizedBox(height: 16),
              Row(
                children: [
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (_textController.text.trim().isNotEmpty) {
                              _onSmartInputSubmitted(_textController.text);
                              _textController.clear();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color:
                                  StarboundColors.stellarAqua.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: StarboundColors.stellarAqua
                                    .withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.send,
                                  size: 14,
                                  color: StarboundColors.stellarAqua,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Log it",
                                  style: StarboundTypography.button.copyWith(
                                    color: StarboundColors.stellarAqua,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isClassifierReady)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            StarboundColors.stellarAqua,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Capturing now — insights load in a moment.',
                        style: StarboundTypography.bodySmall.copyWith(
                          color: StarboundColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the main journal history section
  Widget _buildJournalHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Journal",
                    style: StarboundTypography.heading2.copyWith(
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _recentReflections.isEmpty
                        ? "Your thoughts and reflections will appear here"
                        : "${_recentReflections.length} entries • Automatically analyzed",
                    style: StarboundTypography.body.copyWith(
                      color: StarboundColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Journal Entries or Empty State
        if (_recentReflections.isEmpty)
          _buildEmptyJournalState()
        else
          _buildJournalEntries(),
      ],
    );
  }

  /// Build empty state when no journal entries exist
  Widget _buildEmptyJournalState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.bookOpen,
            size: 48,
            color: StarboundColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Start your first entry',
            style: StarboundTypography.heading3.copyWith(
              color: StarboundColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share how you\'re feeling, what happened today, or anything on your mind. I\'ll help identify patterns and insights.',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build the list of journal entries
  Widget _buildJournalEntries() {
    return Column(
      children: [
        ..._recentReflections.take(5).map(_buildReflectionCard),
        if (_recentReflections.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildViewAllButton(),
          ),
      ],
    );
  }

  /// Build view all button
  Widget _buildViewAllButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showAllJournalEntries,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: StarboundColors.stellarAqua.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: StarboundColors.stellarAqua.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _recentReflections.length > 5
                    ? 'View all ${_recentReflections.length} entries'
                    : 'View all entries',
                style: StarboundTypography.button.copyWith(
                  color: StarboundColors.stellarAqua,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.arrowRight,
                size: 14,
                color: StarboundColors.stellarAqua,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show all journal entries in a modal
  void _showAllJournalEntries() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: StarboundColors.background.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.bookOpen,
                          size: 24,
                          color: StarboundColors.stellarAqua,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Journal Entries',
                                style: StarboundTypography.heading2.copyWith(
                                  color: StarboundColors.textPrimary,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '${_recentReflections.length} entries',
                                style: StarboundTypography.body.copyWith(
                                  color: StarboundColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            LucideIcons.x,
                            color: StarboundColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Entries List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _recentReflections.length,
                      itemBuilder: (context, index) {
                        return _buildReflectionCard(_recentReflections[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReflectionCard(FreeFormEntry reflection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original text
                Text(
                  reflection.originalText,
                  style: StarboundTypography.bodyLarge.copyWith(
                    color: StarboundColors.textPrimary,
                    fontSize: 16,
                    height: 1.4,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),

                if (reflection.hasClassifications) ...[
                  const SizedBox(height: 16),
                  // Classifications
                  ...reflection.classifications.map((classification) =>
                      _buildClassificationInsight(classification)),
                ] else ...[
                  const SizedBox(height: 16),
                  // No classifications found - show encouraging message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: StarboundColors.stellarAqua.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: StarboundColors.stellarAqua.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.heart,
                          size: 16,
                          color: StarboundColors.stellarAqua,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Thank you for sharing. Every reflection helps me understand you better.",
                            style: StarboundTypography.bodyLarge.copyWith(
                              color: StarboundColors.textPrimary,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Timestamp and actions
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 12,
                      color: StarboundColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(reflection.timestamp),
                      style: StarboundTypography.bodySmall.copyWith(
                        color: StarboundColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    // Save as action button
                    _buildSaveActionButton(reflection),
                    const SizedBox(width: 8),
                    // Nudge/suggestion button
                    if (reflection.hasClassifications)
                      _buildNudgeButton(reflection),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build nudge/suggestion button for journal entry
  Widget _buildNudgeButton(FreeFormEntry reflection) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showNudgesForEntry(reflection),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF00F5D4).withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.lightbulb,
                size: 16,
                color: const Color(0xFF00F5D4),
              ),
              const SizedBox(width: 6),
              Text(
                'Get suggestion',
                style: StarboundTypography.bodySmall.copyWith(
                  color: const Color(0xFF00F5D4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build save as action button for journal entry
  Widget _buildSaveActionButton(FreeFormEntry reflection) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _saveAsActionIdea(reflection),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: StarboundColors.stellarYellow.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: StarboundColors.stellarYellow.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.plus,
                size: 16,
                color: StarboundColors.stellarYellow,
              ),
              const SizedBox(width: 6),
              Text(
                'Save as action',
                style: StarboundTypography.bodySmall.copyWith(
                  color: StarboundColors.stellarYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show nudges/suggestions for a specific journal entry
  void _showNudgesForEntry(FreeFormEntry reflection) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: StarboundColors.background.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
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
                          size: 20,
                          color: const Color(0xFF00F5D4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Suggestions for you',
                              style: StarboundTypography.heading2.copyWith(
                                color: StarboundColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Based on: "${reflection.originalText}"',
                              style: StarboundTypography.bodySmall.copyWith(
                                color: StarboundColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          LucideIcons.x,
                          color: StarboundColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: _buildSuggestionsForEntry(reflection),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build suggestions content for a specific entry
  Widget _buildSuggestionsForEntry(FreeFormEntry reflection) {
    // Generate contextual suggestions based on the entry content and classifications
    final suggestions = _generateSuggestionsForReflection(reflection);

    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 48,
              color: StarboundColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No specific suggestions available',
              style: StarboundTypography.bodyLarge.copyWith(
                color: StarboundColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep journaling to get personalized suggestions!',
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.textTertiary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: suggestions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return _buildSuggestionCard(suggestion);
      },
    );
  }

  /// Generate suggestions using both reflection text and its classifications
  List<Map<String, String>> _generateSuggestionsForReflection(
      FreeFormEntry reflection) {
    final suggestions = <Map<String, String>>[];
    final lowerText = reflection.originalText.toLowerCase();

    final tokens = <String>{};
    for (final classification in reflection.classifications) {
      tokens.add(classification.habitKey.toLowerCase());
      if (classification.habitValue.isNotEmpty) {
        tokens.add(classification.habitValue.toLowerCase());
      }
      if (classification.sentiment.isNotEmpty) {
        tokens.add(classification.sentiment.toLowerCase());
      }
      tokens.addAll(classification.themes.map((t) => t.toLowerCase()));
      tokens.addAll(classification.keywords.map((k) => k.toLowerCase()));
    }

    bool _containsToken(List<String> keywords) {
      return keywords.any((keyword) =>
          lowerText.contains(keyword) ||
          tokens.any((token) => token.contains(keyword)));
    }

    bool mentionsLowActivity = _containsToken(const [
          'exercise',
          'workout',
          'movement',
          'move',
          'run',
          'walk',
          'gym',
          'training',
          'steps',
        ]) &&
        _containsToken(const [
          'barely',
          'didn',
          "haven't",
          'hardly',
          'little',
          'less',
          'skip'
        ]);

    bool mentionsMovement = _containsToken(const [
      'exercise',
      'workout',
      'movement',
      'move',
      'run',
      'walk',
      'gym',
      'training',
      'steps',
      'stretch',
    ]);

    bool mentionsStress = _containsToken(const [
      'stress',
      'anxiety',
      'overwhelm',
      'panic',
      'tense',
    ]);

    bool mentionsRest = _containsToken(const [
      'sleep',
      'tired',
      'fatigue',
      'exhausted',
      'rest',
    ]);

    bool mentionsNutrition = _containsToken(const [
      'food',
      'meal',
      'eat',
      'snack',
      'hungry',
      'junk',
      'sugar',
      'craving',
    ]);

    // Tailored movement suggestions
    if (mentionsLowActivity) {
      suggestions.add({
        'canonical_tag': 'movement_boost',
        'title': 'Momentum Reboot',
        'description':
            'You mentioned low movement today. A small win now can build momentum.',
        'action':
            'Take a 3-minute stretch or walk to your kitchen and back twice. Set a gentle timer so it feels doable.',
        'category': 'immediate',
      });
    } else if (mentionsMovement) {
      suggestions.add({
        'canonical_tag': 'movement_boost',
        'title': 'Movement Momentum',
        'description': 'Build on your activity with gentle movement.',
        'action':
            'Add 5 minutes of stretching or a short walk around the block.',
        'category': 'daily',
      });
    }

    // Nutrition support
    if (mentionsNutrition) {
      final expressedConcern = _containsToken(const [
        'guilt',
        'bad',
        'worried',
        'concern',
        'regret',
      ]);
      suggestions.add({
        'canonical_tag': 'need_fuel',
        'title': expressedConcern ? 'Gentle Reset' : 'Nutrition Balance',
        'description': expressedConcern
            ? 'It’s okay—every meal is a new chance to nourish yourself.'
            : 'Balance your nutrition with your next meal or snack.',
        'action':
            'Drink a glass of water and plan one colorful addition (fruit, veggies, protein) for your next bite.',
        'category': 'immediate',
      });
    }

    // Stress relief
    if (mentionsStress) {
      suggestions.add({
        'canonical_tag': 'breathing_reset',
        'title': 'Quick Calm',
        'description': 'Take a moment to center yourself and find some peace.',
        'action':
            'Try 4-7-8 breathing: inhale for 4, hold for 7, exhale for 8.',
        'category': 'immediate',
      });
    }

    // Rest support
    if (mentionsRest) {
      suggestions.add({
        'canonical_tag': 'sleep_hygiene',
        'title': 'Sleep Support',
        'description': 'Support better rest with a calming routine.',
        'action':
            'Dim the lights 30 minutes before bed or do a gentle neck and shoulder release.',
        'category': 'evening',
      });
    }

    // Add general wellness suggestion only if nothing specific surfaced
    if (suggestions.isEmpty) {
      suggestions.add({
        'canonical_tag': 'mindful_break',
        'title': 'Mindful Check-in',
        'description': 'Take a moment to notice how you\'re feeling right now.',
        'action':
            'Notice 3 things you can see, 2 you can hear, and 1 you can feel.',
        'category': 'immediate',
      });
    }

    return suggestions.take(3).toList();
  }

  /// Build individual suggestion card
  Widget _buildSuggestionCard(Map<String, String> suggestion) {
    final category = suggestion['category'] ?? 'immediate';
    final categoryColor = _getCategorySuggestionColor(category);

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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategorySuggestionIcon(category),
                  size: 16,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion['title'] ?? 'Suggestion',
                  style: StarboundTypography.heading3.copyWith(
                    color: StarboundColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: StarboundTypography.bodySmall.copyWith(
                    color: categoryColor,
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
            suggestion['description'] ?? '',
            style: StarboundTypography.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Action
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
              suggestion['action'] ?? '',
              style: StarboundTypography.bodyLarge.copyWith(
                color: const Color(0xFF00F5D4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applySuggestionFromEntry(suggestion);
              },
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
        ],
      ),
    );
  }

  /// Apply suggestion from entry
  void _applySuggestionFromEntry(Map<String, String> suggestion) async {
    HapticFeedback.mediumImpact();

    try {
      // Convert suggestion Map to StarboundNudge
      final nudge = _convertMapToNudge(suggestion);

      // Save nudge to vault using app state
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.bankNudge(nudge);

      // Show success confirmation
      final title = suggestion['title'] ?? 'Suggestion';
      _showStatusMessage(
        '"$title" saved to your Action Vault!',
        StarboundColors.success,
        duration: const Duration(seconds: 4),
        actionLabel: 'View vault',
        onAction: () => Navigator.of(context).pushNamed('/action-vault'),
      );
    } catch (e) {
      debugPrint('Failed to save journal suggestion as nudge: $e');

      // Show error message
      _showStatusMessage(
        'Failed to save suggestion. Please try again.',
        StarboundColors.error,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Convert Map suggestion to StarboundNudge for saving to vault
  StarboundNudge _convertMapToNudge(Map<String, String> suggestion) {
    final category = suggestion['category'] ?? 'immediate';
    final title = suggestion['title'] ?? 'Journal Suggestion';
    final description = suggestion['description'] ?? '';
    final action = suggestion['action'] ?? '';

    final canonicalTheme = TagUtils.resolveCanonicalTag(
          suggestion['canonical_tag'] ??
              suggestion['tag'] ??
              suggestion['title'],
        ) ??
        'balanced';

    // Create unique ID for the nudge
    final uniqueId =
        'journal_suggestion_${DateTime.now().millisecondsSinceEpoch}';

    // Map category to theme and properties
    final timeMapping = {
      'immediate': '<2 mins',
      'daily': '5-10 mins',
      'evening': '10-15 mins',
      'nutrition': '2-5 mins',
      'movement': '5-10 mins',
      'sleep': '10-15 mins',
      'hydration': '<1 min',
    };

    final energyMapping = {
      'immediate': 'low',
      'daily': 'medium',
      'evening': 'low',
      'nutrition': 'low',
      'movement': 'medium',
      'sleep': 'low',
      'hydration': 'very low',
    };

    final estimatedTime = timeMapping[category] ?? '2-5 mins';
    final energyRequired = energyMapping[category] ?? 'low';

    return StarboundNudge(
      id: uniqueId,
      theme: canonicalTheme,
      message: action,
      title: title,
      content: description,
      tone: 'supportive',
      estimatedTime: estimatedTime,
      energyRequired: energyRequired,
      complexityProfileFit: [
        'stable',
        'trying',
        'overloaded'
      ], // Allow for most profiles
      triggersFrom: ['journal_analysis', category],
      source: NudgeSource.dynamic,
      type: NudgeType.suggestion,
      actionableSteps: [action],
      generatedAt: DateTime.now(),
      metadata: {
        'source': 'journal_entry_suggestion',
        'category': category,
        'generated_from_classification': true,
        'creation_method': 'journal_analysis',
        'canonical_theme': canonicalTheme,
        'canonical_tags': [canonicalTheme],
      },
    );
  }

  /// Get color for suggestion category
  Color _getCategorySuggestionColor(String category) {
    switch (category) {
      case 'immediate':
        return const Color(0xFF00F5D4);
      case 'daily':
        return StarboundColors.stellarYellow;
      case 'evening':
        return StarboundColors.nebulaPurple;
      default:
        return StarboundColors.stellarAqua;
    }
  }

  /// Get icon for suggestion category
  IconData _getCategorySuggestionIcon(String category) {
    switch (category) {
      case 'immediate':
        return LucideIcons.zap;
      case 'daily':
        return LucideIcons.calendar;
      case 'evening':
        return LucideIcons.moon;
      default:
        return LucideIcons.lightbulb;
    }
  }

  Widget _buildClassificationInsight(ClassificationResult classification) {
    final Set<String> canonicalTags = {};

    String? _resolveCanonical(String raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      final attempts = <String>{
        trimmed,
        trimmed.toLowerCase(),
        trimmed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
      };
      for (final attempt in attempts) {
        final resolved = CanonicalOntology.resolveCanonicalKey(attempt);
        if (resolved != null) {
          return resolved;
        }
      }
      return null;
    }

    void addCanonicalTag(String? value) {
      if (value == null) return;
      final resolved = _resolveCanonical(value);
      if (resolved != null) {
        canonicalTags.add(resolved);
      }
    }

    for (final theme in classification.themes) {
      addCanonicalTag(theme);
    }

    for (final keyword in classification.keywords) {
      addCanonicalTag(keyword);
    }

    addCanonicalTag(classification.habitKey);
    addCanonicalTag(classification.categoryTitle);

    if (classification.sentiment != 'neutral') {
      addCanonicalTag(classification.sentiment);
    }

    if (canonicalTags.isEmpty) {
      addCanonicalTag(classification.habitKey);
    }

    if (canonicalTags.isEmpty) {
      canonicalTags.add('balanced');
    }

    final tags = canonicalTags.take(6).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            "What I noticed:",
            style: StarboundTypography.bodyLarge.copyWith(
              color: StarboundColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Interactive tag chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((canonicalTag) {
              final displayTag = _renamedTags[canonicalTag] ??
                  CanonicalOntology.getDisplayName(canonicalTag);
              final subdomain = CanonicalOntology.getSubdomain(canonicalTag);

              return InteractiveTagChip(
                tag: displayTag,
                originalTag: canonicalTag,
                confidence: classification.confidence,
                subdomain: subdomain,
                aiReasoning: _generateAIReasoning(canonicalTag, classification),
                isPinned: _pinnedTags.contains(canonicalTag),
                onPin: () => _handleTagPin(canonicalTag),
                onRename: (newName) => _handleTagRename(canonicalTag, newName),
                onRequestNudge: _handleNudgeRequest,
                isEditable: true,
              );
            }).toList(),
          ),

          // Classification metadata (smaller, less prominent)
          const SizedBox(height: 12),
          Row(
            children: [
              // Type indicator (smaller)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(classification).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getTypeColor(classification).withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  classification.isChoice ? 'Choice' : 'Chance',
                  style: StarboundTypography.bodySmall.copyWith(
                    color: _getTypeColor(classification),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Sentiment indicator (smaller)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSentimentColor(classification).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getSentimentColor(classification).withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  classification.sentiment.toLowerCase(),
                  style: StarboundTypography.bodySmall.copyWith(
                    color: _getSentimentColor(classification),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _generateAIReasoning(
      String theme, ClassificationResult classification) {
    return "I connected your words to '${theme.replaceAll('_', ' ')}' based on the emotional language and context patterns I recognized in your text.";
  }

  Color _getTypeColor(ClassificationResult classification) {
    return classification.isChoice
        ? StarboundColors.stellarAqua
        : classification.isNegative
            ? StarboundColors.warning
            : StarboundColors.stellarYellow;
  }

  Color _getSentimentColor(ClassificationResult classification) {
    return classification.isPositive
        ? StarboundColors.success
        : classification.isNegative
            ? StarboundColors.error
            : StarboundColors.textSecondary;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Handle saving journal entry as action idea
  void _saveAsActionIdea(FreeFormEntry reflection) async {
    HapticFeedback.lightImpact();

    try {
      // Convert entry to action using the service
      final action = _actionService.convertEntryToAction(reflection);

      // Show action preview modal for user to edit before saving
      final confirmed = await _showActionPreviewModal(action, reflection);

      if (confirmed && mounted) {
        // Save to Action Vault
        await _actionService.saveActionToVault(action);

        // Show success feedback
        _showStatusMessage(
          'Action idea saved to your vault!',
          StarboundColors.success,
          actionLabel: 'Open vault',
          onAction: () => Navigator.of(context).pushNamed('/action-vault'),
        );
      }
    } catch (e) {
      debugPrint('Failed to save action idea: $e');
      _showStatusMessage(
        'Failed to save action idea. Please try again.',
        StarboundColors.error,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Show action preview modal for user to edit before saving
  Future<bool> _showActionPreviewModal(
      StarboundNudge action, FreeFormEntry originalEntry) async {
    final titleController = TextEditingController(text: action.message);
    final descriptionController =
        TextEditingController(text: action.metadata?['description'] ?? '');

    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            margin: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: StarboundColors.background.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
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
                              color: StarboundColors.stellarYellow
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.plus,
                              size: 20,
                              color: StarboundColors.stellarYellow,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Save as Action Idea',
                                  style: StarboundTypography.heading2.copyWith(
                                    color: StarboundColors.textPrimary,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Edit this action before saving to your vault',
                                  style: StarboundTypography.body.copyWith(
                                    color: StarboundColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: Icon(
                              LucideIcons.x,
                              color: StarboundColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Original reflection preview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Original reflection:',
                              style: StarboundTypography.bodySmall.copyWith(
                                color: StarboundColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              originalEntry.originalText,
                              style: StarboundTypography.body.copyWith(
                                color: StarboundColors.textPrimary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action title field
                      Text(
                        'Action Title',
                        style: StarboundTypography.bodyLarge.copyWith(
                          color: StarboundColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        style: StarboundTypography.body.copyWith(
                          color: StarboundColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter action title...',
                          hintStyle: StarboundTypography.body.copyWith(
                            color: StarboundColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: StarboundColors.stellarYellow,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action description field
                      Text(
                        'Description',
                        style: StarboundTypography.bodyLarge.copyWith(
                          color: StarboundColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: StarboundTypography.body.copyWith(
                          color: StarboundColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Describe this action...',
                          hintStyle: StarboundTypography.body.copyWith(
                            color: StarboundColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: StarboundColors.stellarYellow,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: StarboundTypography.button.copyWith(
                                  color: StarboundColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Update action with edited content
                                final updatedMetadata =
                                    Map<String, dynamic>.from(
                                        action.metadata ?? {});
                                updatedMetadata['title'] = titleController.text;
                                updatedMetadata['description'] =
                                    descriptionController.text;
                                // Note: We should create a new action with updated metadata using copyWith
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: StarboundColors.stellarYellow,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Save to Vault',
                                style: StarboundTypography.button.copyWith(
                                  color: StarboundColors.deepSpace,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ) ??
        false;
  }

  /// Build nudge info chip
  Widget _buildNudgeInfo(String icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            text,
            style: StarboundTypography.bodySmall.copyWith(
              color: StarboundColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle smart journal entry submission
  void _handleSmartJournalEntry(SmartJournalEntry entry) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Store the smart journal entry locally for quick access
      _smartReflections.insert(0, entry);

      // Build a rich classification from smart tags when available
      final classification = _buildClassificationFromSmartEntry(entry);

      final legacyEntry = FreeFormEntry(
        id: entry.id,
        originalText: entry.originalText,
        timestamp: entry.timestamp,
        classifications: [classification],
        averageConfidence: entry.averageConfidence,
        metadata: {
          'smart_tags_count': entry.smartTags.length,
          'has_follow_ups': entry.followUpQuestions.isNotEmpty,
        },
      );

      final appState = context.read<AppState>();
      debugPrint('Smart entry tags: '
          '${entry.smartTags.map((t) => t.displayName).toList()}');
      debugPrint('Legacy classification: '
          '${legacyEntry.classifications.first.categoryTitle}');
      await appState.addSimpleFreeFormEntry(legacyEntry);

      final graphitiService = GraphitiService();
      unawaited(graphitiService.ingestJournalEntry(
        entry: entry,
        userId: appState.userId,
      ));

      if (mounted) {
        await _loadRecentReflections();
      }

      if (_smartReflections.length > 50) {
        _smartReflections.removeLast();
      }

      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Record journaling activity for reminder scheduling
      await _reminderService.recordJournalActivity();

      debugPrint(
          'Smart journal entry stored with ${entry.smartTags.length} tags');
    } catch (e) {
      debugPrint('Error handling smart journal entry: $e');

      // Show error to user
      _showStatusMessage(
        'Entry saved, but some smart features need another try.',
        StarboundColors.warning,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Get theme emoji
  String _getThemeEmoji(String theme) {
    switch (theme) {
      case "hydration":
        return "💧";
      case "sleep":
        return "😴";
      case "movement":
        return "🏃‍♀️";
      case "nutrition":
        return "🥗";
      case "focus":
        return "🎯";
      case "calm":
        return "🧘‍♀️";
      default:
        return "✨";
    }
  }
}
