import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/nudge_model.dart';
import '../models/complexity_profile.dart';
import '../models/health_navigation_profile.dart';
import '../models/habit_model.dart';
import '../models/service_model.dart';
import '../models/health_journal_model.dart';
import '../models/pattern_insight_model.dart';
import '../models/saved_items_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../services/correlation_service.dart';
import '../services/achievement_service.dart';
import '../services/pattern_recognition_service.dart';
import '../services/habit_suggestion_service.dart';
import '../services/text_parser_service.dart';
import '../services/habit_classifier_service.dart';
import '../services/complexity_analysis_service.dart';
import '../services/logging_service.dart';
import '../services/health_journal_service.dart';
import '../utils/tag_utils.dart';
import '../components/achievement_celebration_popup.dart';

class CompletionReflectionPrompt {
  final String id;
  final String actionId;
  final String actionTitle;
  final String emoji;
  final DateTime createdAt;

  const CompletionReflectionPrompt({
    required this.id,
    required this.actionId,
    required this.actionTitle,
    required this.emoji,
    required this.createdAt,
  });
}

class CompletionReflectionEntry {
  final String promptId;
  final String actionId;
  final String feeling;
  final DateTime respondedAt;

  const CompletionReflectionEntry({
    required this.promptId,
    required this.actionId,
    required this.feeling,
    required this.respondedAt,
  });
}

class ServiceCheckInPrompt {
  final String id;
  final String serviceName;
  final String serviceIcon;
  final DateTime favoritedAt;
  final DateTime scheduledCheckIn;
  final String checkInType; // 'initial', 'follow_up', 'routine'
  final bool isCompleted;

  const ServiceCheckInPrompt({
    required this.id,
    required this.serviceName,
    required this.serviceIcon,
    required this.favoritedAt,
    required this.scheduledCheckIn,
    required this.checkInType,
    this.isCompleted = false,
  });

  ServiceCheckInPrompt copyWith({
    String? id,
    String? serviceName,
    String? serviceIcon,
    DateTime? favoritedAt,
    DateTime? scheduledCheckIn,
    String? checkInType,
    bool? isCompleted,
  }) {
    return ServiceCheckInPrompt(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      serviceIcon: serviceIcon ?? this.serviceIcon,
      favoritedAt: favoritedAt ?? this.favoritedAt,
      scheduledCheckIn: scheduledCheckIn ?? this.scheduledCheckIn,
      checkInType: checkInType ?? this.checkInType,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ServiceCheckInEntry {
  final String promptId;
  final String serviceName;
  final String experience; // 'positive', 'neutral', 'negative'
  final String? details;
  final bool wantReminder;
  final DateTime respondedAt;

  const ServiceCheckInEntry({
    required this.promptId,
    required this.serviceName,
    required this.experience,
    this.details,
    this.wantReminder = false,
    required this.respondedAt,
  });
}

class AppState extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  final UserService _userService = UserService();
  final SyncService _syncService = SyncService();
  final NotificationService _notificationService = NotificationService();
  final CorrelationService _correlationService = CorrelationService();
  final AchievementService _achievementService = AchievementService();
  final PatternRecognitionService _patternService = PatternRecognitionService();
  final HabitSuggestionService _suggestionService = HabitSuggestionService();
  final TextParserService _textParser = TextParserService();
  final HabitClassifierService _habitClassifier = HabitClassifierService();
  final ComplexityAnalysisService _complexityAnalyzer =
      ComplexityAnalysisService();

  // Performance optimization: Selective notification using ValueNotifiers
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _errorNotifier = ValueNotifier(null);
  final ValueNotifier<Map<String, String?>> _habitsNotifier = ValueNotifier({});
  final ValueNotifier<String> _userNameNotifier = ValueNotifier('Explorer');
  final ValueNotifier<bool> _syncStatusNotifier = ValueNotifier(false);

  // Core state
  ComplexityLevel _complexityProfile = ComplexityLevel.trying;
  ComplexityAssessment? _currentComplexityAssessment;
  List<ComplexityAssessment> _assessmentHistory = [];
  Map<ComplexityLevel, double> _complexityTrendScores = {
    for (final level in ComplexityLevel.values) level: 0.0,
  };
  List<ComplexityProfileTransition> _complexityHistory = [];
  DateTime? _lastComplexityShift;

  // NEW: Health Navigation Profile
  HealthNavigationProfile? _healthNavigationProfile;

  // NEW: Health Journal
  final HealthJournalService _healthJournalService = HealthJournalService();
  bool _healthJournalInitialized = false;

  Map<String, String?> _habits = {};
  List<StarboundNudge> _bankedNudges = [];
  List<String> _favoriteActions = [];
  List<String> _completedActions = [];
  List<String> _favoriteServices = [];
  List<String> _favoriteResources = []; // Health resource IDs
  List<SavedResource> _savedResources = []; // Saved resources with notes
  List<SavedConversation> _savedConversations = []; // Saved health Q&A
  List<FreeFormEntry> _freeFormEntries = [];
  List<CompletionReflectionPrompt> _completionPrompts = [];
  List<CompletionReflectionEntry> _completionResponses = [];
  List<ServiceCheckInPrompt> _serviceCheckInPrompts = [];
  List<ServiceCheckInEntry> _serviceCheckInResponses = [];
  DateTime? _lastComplexityAnalysis;
  bool _isLoading = false;
  String? _error;
  bool _useBackend = true; // Flag to switch between backend and local storage

  // Performance optimization: Track which parts of state have changed
  bool _habitsChanged = false;
  bool _userDataChanged = false;
  bool _achievementsChanged = false;
  bool _syncStatusChanged = false;

  // Performance optimization: Enhanced caching system
  Map<String, int>? _cachedHabitStreaks;
  Map<String, List<String>>? _cachedHabitTrends;
  List<dynamic>? _cachedSuccessPatterns;
  List<dynamic>? _cachedCorrelations;
  List<HabitSuggestion>? _cachedSuggestions;
  StarboundNudge? _cachedCurrentNudge;
  DateTime? _lastStreakCalculation;
  DateTime? _lastTrendCalculation;
  DateTime? _lastPatternAnalysis;
  DateTime? _lastCorrelationAnalysis;
  DateTime? _lastSuggestionGeneration;
  DateTime? _lastHabitUpdate;
  DateTime? _lastNudgeGeneration;
  final List<String> _recentNudgeHistory = [];
  static const int _recentNudgeHistoryLimit = 8;

  // Intelligent cache expiry based on data type
  static const _shortCacheMinutes = 15; // For frequently changing data
  static const _mediumCacheMinutes = 60; // For analytics data
  static const _longCacheMinutes = 240; // For pattern recognition data
  // Auto-adjust heuristics (tuned for smoother shifts)
  static const double _complexityTrendAlpha =
      0.25; // less reactive EMA blending
  static const double _complexityTrendMinimumGap =
      0.10; // require clearer trend lift
  static const double _complexityScoreMinimumGap =
      1.5; // demand stronger score delta
  static const double _complexityConfidenceThreshold =
      0.78; // only trust higher-confidence analyses
  static const Duration _complexityShiftCooldown = Duration(days: 5);
  static const int _complexityHistoryLimit = 20;

  // User preferences
  bool _notificationsEnabled = true;
  String _notificationTime = '19:00';
  String _userName = 'Explorer';
  bool _isOnboardingComplete = false;
  bool _homeMemoryEnabled = true;

  // Chat-to-forecast integration

  // Smart input data for seamless page transitions
  String? _pendingSmartInputText;
  String? _pendingSmartInputIntent;
  Map<String, dynamic>? _pendingSmartInputMetadata;
  String? _pendingJournalDraftText;
  Map<String, dynamic>? _pendingJournalDraftMetadata;
  String? _pendingRouterDraftText;
  Map<String, dynamic>? _pendingRouterDraftMetadata;

  // Getters
  ComplexityLevel get complexityProfile =>
      _userService.currentComplexityProfile ?? _complexityProfile;
  HealthNavigationProfile? get healthNavigationProfile => _healthNavigationProfile;

  // Health Journal getters
  List<HealthJournalEntry> get healthJournalEntries => _healthJournalService.entries;
  List<PatternInsight> get activePatternInsights => _healthJournalService.activeInsights;
  HealthJournalEntry? get healthJournalDraft => _healthJournalService.currentDraft;
  bool get hasPatternInsights => _healthJournalService.hasPatternInsights();

  Map<String, String?> get habits => Map.unmodifiable(_habits);
  List<StarboundNudge> get bankedNudges => List.unmodifiable(_bankedNudges);
  List<String> get favoriteActions => List.unmodifiable(_favoriteActions);
  List<String> get completedActions => List.unmodifiable(_completedActions);
  List<String> get favoriteServices => List.unmodifiable(_favoriteServices);
  List<String> get favoriteResources => List.unmodifiable(_favoriteResources);
  List<SavedResource> get savedResources => List.unmodifiable(_savedResources);
  List<SavedConversation> get savedConversations => List.unmodifiable(_savedConversations);
  List<FreeFormEntry> get freeFormEntries =>
      List.unmodifiable(_freeFormEntries);
  List<CompletionReflectionPrompt> get completionPrompts =>
      List.unmodifiable(_completionPrompts);
  List<ServiceCheckInPrompt> get serviceCheckInPrompts =>
      List.unmodifiable(_serviceCheckInPrompts);
  List<ServiceCheckInEntry> get serviceCheckInResponses =>
      List.unmodifiable(_serviceCheckInResponses);
  List<CompletionReflectionEntry> get completionResponses =>
      List.unmodifiable(_completionResponses);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get notificationsEnabled => _notificationsEnabled;
  String get notificationTime => _notificationTime;
  String get userName => _userService.currentDisplayName ?? _userName;
  bool get homeMemoryEnabled => _homeMemoryEnabled;
  bool get isOnboardingComplete {
    if (!_useBackend || !_userService.isLoggedIn) {
      return _isOnboardingComplete;
    }
    return _userService.isOnboardingComplete;
  }
  bool get useBackend => _useBackend;
  bool get isLoggedIn => _userService.isLoggedIn;
  int get userId =>
      _userService.currentUserId ?? 1; // Default to 1 for development
  Map<ComplexityLevel, double> get complexityTrendScores =>
      Map.unmodifiable(_complexityTrendScores);
  List<ComplexityProfileTransition> get complexityHistory =>
      List.unmodifiable(_complexityHistory);
  DateTime? get lastComplexityShift => _lastComplexityShift;

  // Performance optimization: Selective listening with ValueNotifiers
  ValueListenable<bool> get isLoadingNotifier => _isLoadingNotifier;
  ValueListenable<String?> get errorNotifier => _errorNotifier;
  ValueListenable<Map<String, String?>> get habitsNotifier => _habitsNotifier;
  ValueListenable<String> get userNameNotifier => _userNameNotifier;
  ValueListenable<bool> get syncStatusNotifier => _syncStatusNotifier;

  // State change tracking getters
  bool get habitsChanged => _habitsChanged;
  bool get userDataChanged => _userDataChanged;
  bool get achievementsChanged => _achievementsChanged;
  bool get syncStatusChanged => _syncStatusChanged;

  // Sync-related getters
  bool get hasPendingSync => _syncService.hasPendingActions;
  int get pendingSyncCount => _syncService.pendingActionsCount;
  Map<String, dynamic> get syncStatus => _syncService.getSyncStatus();

  // Notification-related getters
  List<int> get notificationDays => _notificationService.enabledDays;

  
  @visibleForTesting
  void disableBackendForTesting() {
    _useBackend = false;
  }

// Initialize app state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Initialize user service first
      await _userService.initialize();

      // Initialize sync service and set up callbacks
      await _syncService.initialize();
      _setupSyncCallbacks();

      // Initialize notification service
      await _notificationService.initialize();

      // Initialize achievement service
      await _achievementService.initialize();

      // Initialize health journal service
      await _healthJournalService.initialize();
      _healthJournalInitialized = true;

      // Initialize smart input services
      await _textParser.initialize();
      await _habitClassifier.initialize();
      // ComplexityAnalysisService is stateless and doesn't need initialization

      // Check if backend is available
      if (_useBackend) {
        _useBackend = await _userService.isServerAvailable();
        if (!_useBackend) {
          LoggingService.warning(
              'Backend not available, falling back to local storage',
              tag: 'AppState');
        }
      }

      if (_useBackend && _userService.isLoggedIn) {
        await _loadDataFromBackend();
      } else {
        await _loadDataFromLocal();
      }

      _clearError();
    } catch (e, stackTrace) {
      LoggingService.critical('Failed to initialize app',
          tag: 'AppState', error: e, stackTrace: stackTrace);
      _setError('Failed to initialize app: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Complexity Profile Management
  Future<void> updateComplexityProfile(ComplexityLevel profile) async {
    // Always update locally first for immediate UI feedback
    _complexityProfile = profile;
    await _storageService.saveComplexityProfile(profile);

    if (_useBackend && _userService.isLoggedIn) {
      try {
        await _userService.updateProfile(complexityProfile: profile);
      } catch (e) {
        LoggingService.warning(
            'Failed to sync complexity profile update, queuing for later',
            tag: 'AppState',
            error: e);
        // Queue for offline sync
        await _syncService.queueAction(SyncActionType.updateComplexityProfile, {
          'profile': profile.name,
        });
      }
    } else {
      // Queue for sync when backend becomes available
      if (_useBackend) {
        await _syncService.queueAction(SyncActionType.updateComplexityProfile, {
          'profile': profile.name,
        });
      }
    }
    notifyListeners();
  }

  Future<void> applyComplexityAssessment(ComplexityAssessment assessment) async {
    _currentComplexityAssessment = assessment;
    await _storageService.saveComplexityAssessment(assessment);
    _assessmentHistory.add(assessment);
    if (_assessmentHistory.length > 20) {
      _assessmentHistory = _assessmentHistory.sublist(_assessmentHistory.length - 20);
    }
    await _storageService.saveAssessmentHistory(_assessmentHistory);
    await updateComplexityProfile(assessment.primaryLevel);
  }

  // Habit Management
  Future<void> updateHabit(String habitKey, String? value) async {
    final oldValue = _habits[habitKey];
    var habitChanged = false;
    if (oldValue != value) {
      _habits[habitKey] = value;
      habitChanged = true;

      // Performance optimization: Only notify if value actually changed
      _updateHabitsState(_habits);

      // Smart cache invalidation when habits change
      _markHabitsUpdated();

      // Store habit entry for local analytics
      await _storeHabitEntry(habitKey, value);
    }

    if (_useBackend && _userService.isLoggedIn) {
      try {
        await _apiService.updateDailyHabits(
          userId: _userService.currentUserId!,
          habits: _habits,
        );
      } catch (e) {
        LoggingService.warning('Failed to sync habit update, queuing for later',
            tag: 'AppState', error: e);
        // Queue for offline sync
        await _syncService.queueAction(SyncActionType.updateHabit, {
          'habits': Map<String, String?>.from(_habits),
        });
      }
    } else {
      await _storageService.saveHabits(_habits);

      // Queue for sync when backend becomes available
      if (_useBackend) {
        await _syncService.queueAction(SyncActionType.updateHabit, {
          'habits': Map<String, String?>.from(_habits),
        });
      }
    }

    if (habitChanged) {
      await _ingestHabitComplexitySignal();
    }

    // Schedule smart notifications based on habit updates
    await _scheduleSmartNotifications();

    // Check for new achievements
    await _checkForNewAchievements();

    notifyListeners();
  }

  Future<void> updateMultipleHabits(Map<String, String?> newHabits) async {
    if (newHabits.isEmpty) {
      return;
    }

    _habits.addAll(newHabits);

    // Invalidate analytics cache when habits change
    _invalidateAnalyticsCache();
    _markHabitsUpdated();
    _updateHabitsState(_habits);

    // Store habit entries for local analytics (optimized batch operation)
    final today = DateTime.now();
    final futures = newHabits.entries.map((entry) =>
        _storageService.saveHabitEntry(entry.key, entry.value ?? '', today));
    await Future.wait(futures);

    if (_useBackend && _userService.isLoggedIn) {
      try {
        await _apiService.updateDailyHabits(
          userId: _userService.currentUserId!,
          habits: _habits,
        );
      } catch (e) {
        LoggingService.warning(
            'Failed to sync multiple habits update, queuing for later',
            tag: 'AppState',
            error: e);
        // Queue for offline sync
        await _syncService.queueAction(SyncActionType.updateMultipleHabits, {
          'habits': Map<String, String?>.from(_habits),
        });
      }
    } else {
      await _storageService.saveHabits(_habits);

      // Queue for sync when backend becomes available
      if (_useBackend) {
        await _syncService.queueAction(SyncActionType.updateMultipleHabits, {
          'habits': Map<String, String?>.from(_habits),
        });
      }
    }

    await _ingestHabitComplexitySignal();

    await _scheduleSmartNotifications();
    await _checkForNewAchievements();

    notifyListeners();
  }

  // Smart Input Processing
  Future<FreeFormEntry> processFreeFormEntry(String input) async {
    if (!_textParser.isReady || !_habitClassifier.isReady) {
      throw Exception('Smart input services not initialized');
    }

    try {
      // Generate unique ID for this entry
      final entryId = 'entry_${DateTime.now().millisecondsSinceEpoch}';

      // Classify the input
      final classification = await _habitClassifier.classifyInput(input);

      // Convert to ClassificationResult list for the FreeFormEntry
      final results = classification.classifications;

      // Calculate average confidence
      final avgConfidence = results.isEmpty
          ? 0.0
          : results.map((r) => r.confidence).reduce((a, b) => a + b) /
              results.length;

      // Create the entry
      final entry = FreeFormEntry(
        id: entryId,
        originalText: input,
        timestamp: DateTime.now(),
        classifications: results,
        averageConfidence: avgConfidence,
        metadata: {
          'inputLength': input.length,
          'processingTime': DateTime.now().toIso8601String(),
          'servicesReady': {
            'textParser': _textParser.isReady,
            'classifier': _habitClassifier.isReady,
          },
        },
        isProcessed: false,
      );

      // Store the entry
      _freeFormEntries.add(entry);

      // Apply high-confidence classifications automatically
      bool anyChanges = false;
      final appliedClassifications = <ClassificationResult>[];

      for (final result in results) {
        if (result.confidence >= 0.7) {
          await updateHabit(result.habitKey, result.habitValue);
          appliedClassifications.add(result);
          anyChanges = true;
          debugPrint(
              'Auto-applied: ${result.habitKey} = ${result.habitValue} (${result.confidence.toStringAsFixed(2)})');
        }
      }

      // Analyze complexity patterns if we have enough data
      await _analyzeComplexityFromReflections();

      // Mark as processed if we applied any classifications
      final finalEntry = FreeFormEntry(
        id: entry.id,
        originalText: entry.originalText,
        timestamp: entry.timestamp,
        classifications: entry.classifications,
        averageConfidence: entry.averageConfidence,
        metadata: {
          ...entry.metadata,
          'appliedCount': appliedClassifications.length,
          'appliedClassifications':
              appliedClassifications.map((r) => r.habitKey).toList(),
        },
        isProcessed: appliedClassifications.isNotEmpty,
      );

      // Update the entry in storage
      final index = _freeFormEntries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        _freeFormEntries[index] = finalEntry;
      }

      // Save to storage
      await _storageService.saveFreeFormEntries(_freeFormEntries);

      notifyListeners();
      return finalEntry;
    } catch (e) {
      LoggingService.error('Failed to process free-form entry',
          tag: 'AppState', error: e);
      rethrow;
    }
  }

  /// Get summary of what was classified
  String getClassificationSummary(FreeFormEntry entry) {
    return _habitClassifier.getClassificationSummary(InputClassification(
      originalText: entry.originalText,
      classifications: entry.classifications,
      timestamp: entry.timestamp,
    ));
  }

  /// Get recent free-form entries
  List<FreeFormEntry> getRecentFreeFormEntries({int limit = 10}) {
    final sorted = List<FreeFormEntry>.from(_freeFormEntries);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  Map<String, int> getTagFrequency({Duration? timeframe}) {
    final cutoff =
        timeframe != null ? DateTime.now().subtract(timeframe) : null;

    final counts = <String, int>{};
    for (final entry in _freeFormEntries) {
      if (cutoff != null && entry.timestamp.isBefore(cutoff)) {
        continue;
      }
      final tags = TagUtils.extractFromEntry(entry);
      for (final tag in tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<MapEntry<String, int>> getTopTags({
    int limit = 5,
    Duration? timeframe,
  }) {
    final frequency = getTagFrequency(timeframe: timeframe);
    final entries = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList(growable: false);
  }

  /// Delete a free-form entry
  Future<void> deleteFreeFormEntry(String entryId) async {
    _freeFormEntries.removeWhere((entry) => entry.id == entryId);
    await _storageService.saveFreeFormEntries(_freeFormEntries);
    notifyListeners();
  }

  /// Add a simple free-form entry (fallback when services aren't initialized)
  Future<void> addSimpleFreeFormEntry(FreeFormEntry entry) async {
    _freeFormEntries.insert(0, entry); // Add to beginning of list
    await _storageService.saveFreeFormEntries(_freeFormEntries);
    notifyListeners();
  }

  // ============================================================================
  // HEALTH JOURNAL METHODS
  // ============================================================================

  /// Get today's health journal entry (or create new one)
  HealthJournalEntry? getTodayHealthJournalEntry() {
    if (!_healthJournalInitialized) return null;
    return _healthJournalService.getTodayEntry();
  }

  /// Get health journal entries for a date range
  List<HealthJournalEntry> getHealthJournalEntriesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _healthJournalService.getEntriesInRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get health journal entries by tag
  List<HealthJournalEntry> getHealthJournalEntriesByTag(String tagKey) {
    return _healthJournalService.getEntriesByTag(tagKey);
  }

  /// Save a health journal entry
  Future<HealthJournalEntry> saveHealthJournalEntry({
    String? id,
    required HealthCheckIn checkIn,
    List<SymptomTracking> symptoms = const [],
    String? journalText,
    bool isDraft = false,
  }) async {
    final entry = await _healthJournalService.saveEntry(
      id: id,
      checkIn: checkIn,
      symptoms: symptoms,
      journalText: journalText,
      isDraft: isDraft,
    );
    notifyListeners();
    return entry;
  }

  /// Save health journal draft
  Future<void> saveHealthJournalDraft(HealthJournalEntry draft) async {
    await _healthJournalService.saveDraft(draft);
    notifyListeners();
  }

  /// Delete a health journal entry
  Future<bool> deleteHealthJournalEntry(String id) async {
    final deleted = await _healthJournalService.deleteEntry(id);
    if (deleted) {
      notifyListeners();
    }
    return deleted;
  }

  /// Dismiss a pattern insight
  Future<void> dismissPatternInsight(String insightId) async {
    await _healthJournalService.dismissInsight(insightId);
    notifyListeners();
  }

  /// Bookmark a pattern insight
  Future<void> bookmarkPatternInsight(String insightId) async {
    await _healthJournalService.bookmarkInsight(insightId);
    notifyListeners();
  }

  /// Force pattern detection
  Future<List<PatternInsight>> detectHealthPatterns() async {
    final insights = await _healthJournalService.detectPatterns();
    notifyListeners();
    return insights;
  }

  /// Get symptom summary for stats
  Map<String, int> getHealthSymptomSummary() {
    return _healthJournalService.getSymptomSummary();
  }

  Future<void> clearHabits() async {
    _habits.clear();
    await _storageService.clearHabits();
    notifyListeners();
  }

  // Complexity Profile Management

  /// Get the current complexity assessment with detailed information
  ComplexityAssessment? getCurrentComplexityAssessment() {
    // Return the stored assessment if available, or create a basic one from current level
    return _currentComplexityAssessment ??
        ComplexityAssessment(
          scores: {complexityProfile: 10},
          primaryLevel: complexityProfile,
          secondaryLevel: complexityProfile,
          highStressCategories: [],
          supportiveCategories: [],
          responses: {},
        );
  }

  /// Get assessment history for the user (most recent first)
  List<ComplexityAssessment> getComplexityAssessmentHistory() {
    if (_assessmentHistory.isNotEmpty) {
      return List.unmodifiable(_assessmentHistory.reversed.toList());
    }
    final current = getCurrentComplexityAssessment();
    return current != null ? [current] : [];
  }

  /// Check if the user should be prompted to update their complexity profile
  bool shouldPromptProfileUpdate() {
    final lastAssessment = _assessmentHistory.isNotEmpty
        ? _assessmentHistory.last
        : getCurrentComplexityAssessment();
    if (lastAssessment == null) return true;
    final daysSinceAssessment =
        DateTime.now().difference(lastAssessment.assessmentDate).inDays;
    return daysSinceAssessment > 90;
  }

  /// Get category-specific insights for the profile page
  Map<ComplexityCategory, Map<String, dynamic>> getCategoryInsights() {
    final assessment = getCurrentComplexityAssessment();
    final responses = assessment?.responses ?? {};
    final hasResponses = responses.isNotEmpty;

    final categoryScores = <ComplexityCategory, List<double>>{};

    if (hasResponses) {
      for (final question in ComplexityProfileService.scoringQuestions) {
        final responseId = responses[question.id];
        if (responseId == null) continue;

        final option = question.options.firstWhere(
          (option) => option.id == responseId,
          orElse: () => question.options.first,
        );

        final category = question.category;
        final score = option.score;
        if (category == null || score == null) continue;

        categoryScores.putIfAbsent(category, () => []).add(score);
      }
    }

    final Map<ComplexityCategory, Map<String, dynamic>> insights = {};

    for (final category in ComplexityCategory.values) {
      final scoresForCategory = categoryScores[category] ?? const <double>[];
      final average = scoresForCategory.isNotEmpty
          ? scoresForCategory.reduce((a, b) => a + b) / scoresForCategory.length
          : null;
      final stressRatio = average != null
          ? ((average - 1.0) / 3.0).clamp(0.0, 1.0)
          : null;
      final supportRatio = average != null
          ? ((4.0 - average) / 3.0).clamp(0.0, 1.0)
          : null;
      final answered = scoresForCategory.length;

      final isStressful = assessment?.highStressCategories.contains(category) ??
          (average != null && average >= ComplexityProfileService.highStressThreshold);
      final isSupportive =
          assessment?.supportiveCategories.contains(category) ??
              (average != null && average <= ComplexityProfileService.supportiveThreshold);

      final statusLabel = isStressful
          ? 'Needs support'
          : (isSupportive ? 'Supportive' : 'Watchful');

      insights[category] = {
        'name': ComplexityProfileService.getCategoryName(category),
        'isStressful': isStressful,
        'statusLabel': statusLabel,
        'description': _summarizeCategoryStatus(
          category: category,
          isStressful: isStressful,
          isSupportive: isSupportive,
          stressRatio: stressRatio,
          answers: answered,
        ),
        'icon': _getCategoryIcon(category),
        'stressRatio': stressRatio,
        'supportRatio': supportRatio,
        'answers': answered,
        'hasResponses': scoresForCategory.isNotEmpty,
      };
    }

    return insights;
  }

  // Helper methods for category analysis
  bool _isStressfulCategory(
      ComplexityCategory category, ComplexityLevel level) {
    // Mock logic based on complexity level and category
    switch (level) {
      case ComplexityLevel.stable:
        return false;
      case ComplexityLevel.trying:
        return category == ComplexityCategory.mentalHealth;
      case ComplexityLevel.overloaded:
        return [
          ComplexityCategory.timeCapacity,
          ComplexityCategory.mentalHealth,
          ComplexityCategory.careResponsibilities
        ].contains(category);
      case ComplexityLevel.survival:
        return [
          ComplexityCategory.livingCircumstances,
          ComplexityCategory.financialStability,
          ComplexityCategory.mentalHealth
        ].contains(category);
    }
  }

  String _getCategoryDescription(ComplexityCategory category) {
    switch (category) {
      case ComplexityCategory.livingCircumstances:
        return 'Housing and living environment';
      case ComplexityCategory.mentalHealth:
        return 'Emotional wellbeing and mental state';
      case ComplexityCategory.physicalHealth:
        return 'Physical health and medical needs';
      case ComplexityCategory.socialSupport:
        return 'Support from family and friends';
      case ComplexityCategory.timeCapacity:
        return 'Available time for self-care';
      case ComplexityCategory.financialStability:
        return 'Financial security and money stress';
      case ComplexityCategory.careResponsibilities:
        return 'Caring for children, parents, or others';
    }
  }

  String _summarizeCategoryStatus({
    required ComplexityCategory category,
    required bool isStressful,
    required bool isSupportive,
    double? stressRatio,
    required int answers,
  }) {
    final base = _getCategoryDescription(category);

    if (isStressful) {
      return answers > 0
          ? '$base is feeling strained right now. Protect your energy here and lean on supports.'
          : '$base tends to add pressure. Keep an eye on small warning signs.';
    }

    if (isSupportive) {
      return '$base is a current strength—keep nurturing what\'s working.';
    }

    if (stressRatio != null) {
      if (stressRatio >= 0.6) {
        return '$base is mixed with a few pinch points—check in when things feel busy.';
      }
      if (stressRatio >= 0.3) {
        return '$base looks mostly steady with occasional bumps. Light touch check-ins help.';
      }
    }

    return '$base is in a steady phase. Keep noting changes so you can respond early.';
  }

  String _getCategoryIcon(ComplexityCategory category) {
    // Return icon name as string for flexibility
    switch (category) {
      case ComplexityCategory.livingCircumstances:
        return 'home';
      case ComplexityCategory.mentalHealth:
        return 'brain';
      case ComplexityCategory.physicalHealth:
        return 'heart';
      case ComplexityCategory.socialSupport:
        return 'users';
      case ComplexityCategory.timeCapacity:
        return 'clock';
      case ComplexityCategory.financialStability:
        return 'dollar-sign';
      case ComplexityCategory.careResponsibilities:
        return 'baby';
    }
  }

  /// Get habits filtered and prioritized based on complexity profile
  Map<String, HabitCategory> getProfileAdaptedChoices() {
    final allChoices = StarboundHabits.getChoices();
    return _filterHabitsForProfile(allChoices, true);
  }

  Map<String, HabitCategory> getProfileAdaptedChances() {
    final allChances = StarboundHabits.getChances();
    return _filterHabitsForProfile(allChances, false);
  }

  /// Filter and prioritize habits based on user's complexity level
  Map<String, HabitCategory> _filterHabitsForProfile(
      Map<String, HabitCategory> habits, bool isChoices) {
    final level = complexityProfile;
    final filteredHabits = <String, HabitCategory>{};

    // Priority habits based on complexity level
    final priorityKeys = _getPriorityHabitsForLevel(level, isChoices);
    final maxItems = _getMaxItemsForLevel(level);

    // Add priority habits first
    for (final key in priorityKeys) {
      if (habits.containsKey(key) && filteredHabits.length < maxItems) {
        filteredHabits[key] = habits[key]!;
      }
    }

    // Fill remaining slots with other habits
    for (final entry in habits.entries) {
      if (!filteredHabits.containsKey(entry.key) &&
          filteredHabits.length < maxItems) {
        filteredHabits[entry.key] = entry.value;
      }
    }

    return filteredHabits;
  }

  /// Get priority habits based on complexity level
  List<String> _getPriorityHabitsForLevel(
      ComplexityLevel level, bool isChoices) {
    if (isChoices) {
      switch (level) {
        case ComplexityLevel.stable:
          return [
            'hydration',
            'movement',
            'nutrition',
            'focus',
            'sleep',
            'energy',
            'mood'
          ];
        case ComplexityLevel.trying:
          return ['hydration', 'sleep', 'mood', 'movement', 'nutrition'];
        case ComplexityLevel.overloaded:
          return ['hydration', 'sleep', 'mood'];
        case ComplexityLevel.survival:
          return ['hydration', 'sleep'];
      }
    } else {
      // Chances - what to watch for based on complexity
      switch (level) {
        case ComplexityLevel.stable:
          return ['outdoor', 'meals'];
        case ComplexityLevel.trying:
          return ['sleepIssues', 'meals', 'outdoor'];
        case ComplexityLevel.overloaded:
          return ['safety', 'sleepIssues', 'meals', 'financial'];
        case ComplexityLevel.survival:
          return ['safety', 'sleepIssues', 'meals', 'financial'];
      }
    }
  }

  /// Get maximum number of items to show based on complexity level
  int _getMaxItemsForLevel(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return 12; // Show most items for growth
      case ComplexityLevel.trying:
        return 8; // Moderate amount
      case ComplexityLevel.overloaded:
        return 5; // Focus on essentials
      case ComplexityLevel.survival:
        return 3; // Absolute minimum
    }
  }

  /// Get personalized messaging for the check-in page
  Map<String, String> getCheckInMessaging() {
    final level = complexityProfile;

    switch (level) {
      case ComplexityLevel.stable:
        return {
          'choiceTitle': 'Growth Actions',
          'chanceTitle': 'Life Events',
          'encouragement': 'Ready to push boundaries and build new habits?',
          'completion': 'Great progress on your growth journey!',
        };
      case ComplexityLevel.trying:
        return {
          'choiceTitle': 'Things You Did',
          'chanceTitle': 'What Happened',
          'encouragement':
              'Every small step counts. Be flexible with yourself.',
          'completion': 'You\'re doing well navigating the ups and downs!',
        };
      case ComplexityLevel.overloaded:
        return {
          'choiceTitle': 'Self-Care Wins',
          'chanceTitle': 'Challenges Today',
          'encouragement': 'Focus on maintaining what you can. No pressure.',
          'completion': 'Maintaining through tough times is an achievement!',
        };
      case ComplexityLevel.survival:
        return {
          'choiceTitle': 'Getting Through',
          'chanceTitle': 'What\'s Happening',
          'encouragement':
              'Just getting through today is enough. You\'re stronger than you know.',
          'completion': 'Every moment you\'re taking care of yourself matters.',
        };
    }
  }

  /// Get the appropriate save button text based on complexity
  String getSaveButtonText() {
    switch (complexityProfile) {
      case ComplexityLevel.stable:
        return 'Save Progress';
      case ComplexityLevel.trying:
        return 'Save & Reflect';
      case ComplexityLevel.overloaded:
        return 'All Set';
      case ComplexityLevel.survival:
        return 'You Did It';
    }
  }

  // Nudge Management
  Future<void> bankNudge(StarboundNudge nudge) async {
    final normalizedNudge = _normalizeNudgeTheme(nudge);
    if (!_bankedNudges.any((n) => n.id == normalizedNudge.id)) {
      // Always add locally first for immediate UI feedback
      _bankedNudges.add(normalizedNudge);
      await _storageService.saveBankedNudges(_bankedNudges);

      if (_useBackend && _userService.isLoggedIn) {
        try {
          await _apiService.bankNudge(
            userId: _userService.currentUserId!,
            nudgeId: int.parse(normalizedNudge.id),
          );
        } catch (e) {
          LoggingService.warning('Failed to sync bank nudge, queuing for later',
              tag: 'AppState', error: e);
          // Queue for offline sync
          await _syncService.queueAction(SyncActionType.bankNudge, {
            'nudgeId': int.parse(normalizedNudge.id),
          });
        }
      } else {
        // Queue for sync when backend becomes available
        if (_useBackend) {
          await _syncService.queueAction(SyncActionType.bankNudge, {
            'nudgeId': int.parse(normalizedNudge.id),
          });
        }
      }
      notifyListeners();
    }
  }

  StarboundNudge _normalizeNudgeTheme(StarboundNudge nudge) {
    final metadata = Map<String, dynamic>.from(nudge.metadata ?? {});

    String? canonicalFromMetadata;
    if (metadata['canonical_theme'] != null) {
      canonicalFromMetadata =
          TagUtils.resolveCanonicalTag(metadata['canonical_theme'].toString());
    }

    if (canonicalFromMetadata == null && metadata['canonical_tags'] is List) {
      for (final dynamic value in (metadata['canonical_tags'] as List)) {
        canonicalFromMetadata = TagUtils.resolveCanonicalTag(value?.toString());
        if (canonicalFromMetadata != null) break;
      }
    }

    final canonicalTheme = canonicalFromMetadata ??
        TagUtils.resolveCanonicalTag(nudge.theme) ??
        'balanced';

    final canonicalTags = <String>{canonicalTheme};
    if (metadata['canonical_tags'] is List) {
      for (final dynamic value in (metadata['canonical_tags'] as List)) {
        final resolved = TagUtils.resolveCanonicalTag(value?.toString());
        if (resolved != null) canonicalTags.add(resolved);
      }
    }

    metadata['canonical_theme'] = canonicalTheme;
    metadata['canonical_tags'] = canonicalTags.toList();

    if (nudge.theme == canonicalTheme && identical(metadata, nudge.metadata)) {
      return nudge;
    }

    return nudge.copyWith(
      theme: canonicalTheme,
      metadata: metadata,
    );
  }

  Future<void> removeBankedNudge(String nudgeId) async {
    _bankedNudges.removeWhere((n) => n.id == nudgeId);
    if (_useBackend && _userService.isLoggedIn) {
      // Note: Backend doesn't have remove nudge endpoint yet
      // For now, just remove locally
    } else {
      await _storageService.saveBankedNudges(_bankedNudges);
    }
    notifyListeners();
  }

  // Favorites Management
  Future<void> toggleFavoriteAction(String actionId) async {
    if (_favoriteActions.contains(actionId)) {
      _favoriteActions.remove(actionId);
    } else {
      _favoriteActions.add(actionId);
    }
    await _storageService.saveFavoriteActions(_favoriteActions);
    notifyListeners();
  }

  Future<void> toggleActionCompleted(String actionId,
      {StarboundNudge? nudge}) async {
    final bool alreadyCompleted = _completedActions.contains(actionId);

    if (alreadyCompleted) {
      _completedActions.remove(actionId);
      _removeCompletionPromptsForAction(actionId);
    } else {
      _completedActions.add(actionId);
      final StarboundNudge resolvedNudge =
          _fallbackNudgeForAction(actionId, nudge);
      _enqueueCompletionPrompt(resolvedNudge);
    }
    await _storageService.saveCompletedActions(_completedActions);
    notifyListeners();
  }

  bool isActionCompleted(String actionId) {
    return _completedActions.contains(actionId);
  }

  Future<void> respondToCompletionPrompt(String promptId,
      {required String feeling}) async {
    final promptIndex =
        _completionPrompts.indexWhere((prompt) => prompt.id == promptId);
    if (promptIndex == -1) {
      return;
    }

    final prompt = _completionPrompts.removeAt(promptIndex);
    _completionResponses.add(CompletionReflectionEntry(
      promptId: prompt.id,
      actionId: prompt.actionId,
      feeling: feeling,
      respondedAt: DateTime.now(),
    ));

    if (_completionResponses.length > 20) {
      _completionResponses.removeRange(0, _completionResponses.length - 20);
    }

    final journalText =
        _buildCompletionJournalEntry(prompt: prompt, feeling: feeling);

    if (journalText != null) {
      final entry = FreeFormEntry(
        id: 'completion_reflection_${prompt.actionId}_${DateTime.now().millisecondsSinceEpoch}',
        originalText: journalText,
        timestamp: DateTime.now(),
        classifications: const [],
        averageConfidence: 1.0,
        metadata: {
          'source': 'action_completion_reflection',
          'action_id': prompt.actionId,
          'prompt_id': prompt.id,
          'feeling': feeling,
        },
        isProcessed: false,
      );

      await addSimpleFreeFormEntry(entry);
    } else {
      notifyListeners();
    }
  }

  void dismissCompletionPrompt(String promptId) {
    final before = _completionPrompts.length;
    _completionPrompts.removeWhere((prompt) => prompt.id == promptId);
    if (_completionPrompts.length != before) {
      notifyListeners();
    }
  }

  Future<void> toggleFavoriteService(String serviceName) async {
    if (_favoriteServices.contains(serviceName)) {
      _favoriteServices.remove(serviceName);
      // Remove any pending check-in prompts for this service
      _serviceCheckInPrompts.removeWhere(
          (prompt) => prompt.serviceName == serviceName && !prompt.isCompleted);
    } else {
      _favoriteServices.add(serviceName);
      // Create a check-in prompt for 2 days from now
      await _createServiceCheckInPrompt(serviceName);
    }
    await _storageService.saveFavoriteServices(_favoriteServices);
    notifyListeners();
  }

  /// Toggle a health resource as favorite (by resource ID)
  Future<void> toggleFavoriteResource(String resourceId) async {
    if (_favoriteResources.contains(resourceId)) {
      _favoriteResources.remove(resourceId);
    } else {
      _favoriteResources.add(resourceId);
    }
    await _storageService.saveFavoriteResources(_favoriteResources);
    notifyListeners();
  }

  /// Check if a resource is favorited
  bool isResourceFavorited(String resourceId) {
    return _favoriteResources.contains(resourceId);
  }

  // Saved Resources Management
  /// Save a health resource with optional notes
  Future<void> saveResource(String resourceId, {String? notes}) async {
    // Check if already saved
    if (_savedResources.any((r) => r.resourceId == resourceId)) {
      return;
    }
    final savedResource = SavedResource.create(resourceId, notes: notes);
    _savedResources.insert(0, savedResource);
    await _storageService.saveSavedResources(_savedResources);
    notifyListeners();
  }

  /// Remove a saved resource
  Future<void> unsaveResource(String resourceId) async {
    _savedResources.removeWhere((r) => r.resourceId == resourceId);
    await _storageService.saveSavedResources(_savedResources);
    notifyListeners();
  }

  /// Update notes on a saved resource
  Future<void> updateSavedResourceNotes(String resourceId, String? notes) async {
    final index = _savedResources.indexWhere((r) => r.resourceId == resourceId);
    if (index != -1) {
      _savedResources[index] = _savedResources[index].copyWith(
        userNotes: notes,
        lastAccessedAt: DateTime.now(),
      );
      await _storageService.saveSavedResources(_savedResources);
      notifyListeners();
    }
  }

  /// Check if a resource is saved
  bool isResourceSaved(String resourceId) {
    return _savedResources.any((r) => r.resourceId == resourceId);
  }

  /// Mark a saved resource as accessed
  Future<void> markResourceAccessed(String resourceId) async {
    final index = _savedResources.indexWhere((r) => r.resourceId == resourceId);
    if (index != -1) {
      _savedResources[index] = _savedResources[index].copyWith(
        lastAccessedAt: DateTime.now(),
      );
      await _storageService.saveSavedResources(_savedResources);
    }
  }

  // Saved Conversations Management
  /// Save a health Q&A conversation
  Future<void> saveConversation(SavedConversation conversation) async {
    // Check if already saved
    if (_savedConversations.any((c) => c.id == conversation.id)) {
      return;
    }
    _savedConversations.insert(0, conversation);
    await _storageService.saveSavedConversations(_savedConversations);
    notifyListeners();
  }

  /// Remove a saved conversation
  Future<void> unsaveConversation(String conversationId) async {
    _savedConversations.removeWhere((c) => c.id == conversationId);
    await _storageService.saveSavedConversations(_savedConversations);
    notifyListeners();
  }

  /// Update tags on a saved conversation
  Future<void> updateConversationTags(String conversationId, List<String> tags) async {
    final index = _savedConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _savedConversations[index] = _savedConversations[index].copyWith(
        tags: tags,
        lastAccessedAt: DateTime.now(),
      );
      await _storageService.saveSavedConversations(_savedConversations);
      notifyListeners();
    }
  }

  /// Mark a conversation as accessed
  Future<void> markConversationAccessed(String conversationId) async {
    final index = _savedConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _savedConversations[index] = _savedConversations[index].copyWith(
        lastAccessedAt: DateTime.now(),
      );
      await _storageService.saveSavedConversations(_savedConversations);
    }
  }

  /// Get a saved conversation by ID
  SavedConversation? getSavedConversation(String conversationId) {
    try {
      return _savedConversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  // Service Check-In Management
  Future<void> _createServiceCheckInPrompt(String serviceName) async {
    // Find the service to get its icon and determine timing
    final service = _getServiceByName(serviceName);
    if (service == null) return;

    // Determine check-in timing based on service type
    final scheduledCheckIn = _calculateCheckInTime(service);

    final prompt = ServiceCheckInPrompt(
      id: 'service_checkin_${DateTime.now().millisecondsSinceEpoch}',
      serviceName: serviceName,
      serviceIcon: service.icon,
      favoritedAt: DateTime.now(),
      scheduledCheckIn: scheduledCheckIn,
      checkInType: 'initial',
    );

    _serviceCheckInPrompts.add(prompt);
    debugPrint(
        '📅 Created check-in prompt for $serviceName, scheduled for $scheduledCheckIn');
  }

  DateTime _calculateCheckInTime(SupportService service) {
    final now = DateTime.now();

    // Check service tags to determine appropriate timing
    final tags = service.tags;

    if (tags.contains('crisis') || tags.contains('emergency')) {
      // Check within 24 hours for crisis services
      return now.add(const Duration(hours: 24));
    } else if (tags.contains('counselling') || tags.contains('therapy')) {
      // Check after 3 days for counseling services
      return now.add(const Duration(days: 3));
    } else {
      // Default: check after 2 days
      return now.add(const Duration(days: 2));
    }
  }

  SupportService? _getServiceByName(String serviceName) {
    try {
      return StarboundServices.all.firstWhere(
        (service) => service.name == serviceName,
      );
    } catch (e) {
      debugPrint('Service not found: $serviceName');
      return null;
    }
  }

  // Get current service check-in prompt (similar to completion prompts)
  ServiceCheckInPrompt? getCurrentServiceCheckInPrompt() {
    final now = DateTime.now();

    // For demo purposes: if we have any completed prompts, don't show new ones
    // This prevents infinite demo prompts
    if (_serviceCheckInResponses.isNotEmpty) {
      return null;
    }

    // For demo: if no prompts exist but we have favorited services, create a demo prompt
    if (_serviceCheckInPrompts.isEmpty && _favoriteServices.isNotEmpty) {
      final service = _getServiceByName(_favoriteServices.first);
      if (service != null) {
        final demoPrompt = ServiceCheckInPrompt(
          id: 'demo_prompt_${DateTime.now().millisecondsSinceEpoch}',
          serviceName: service.name,
          serviceIcon: service.icon,
          favoritedAt: DateTime.now().subtract(const Duration(days: 2)),
          scheduledCheckIn: DateTime.now().subtract(const Duration(minutes: 1)),
          checkInType: 'initial',
        );
        debugPrint(
            '🎪 Created demo service check-in prompt for: ${service.name}');
        return demoPrompt;
      }
    }

    // Find prompts that are due and not completed
    final duePrompts = _serviceCheckInPrompts
        .where((prompt) =>
            !prompt.isCompleted && now.isAfter(prompt.scheduledCheckIn))
        .toList();

    return duePrompts.isNotEmpty ? duePrompts.first : null;
  }

  // Respond to a service check-in prompt
  Future<void> respondToServiceCheckIn(
    String promptId, {
    required String experience,
    String? details,
    bool wantReminder = false,
  }) async {
    // Mark prompt as completed
    final promptIndex =
        _serviceCheckInPrompts.indexWhere((p) => p.id == promptId);
    if (promptIndex != -1) {
      _serviceCheckInPrompts[promptIndex] =
          _serviceCheckInPrompts[promptIndex].copyWith(isCompleted: true);
    }

    // Create response entry
    final response = ServiceCheckInEntry(
      promptId: promptId,
      serviceName: _serviceCheckInPrompts[promptIndex].serviceName,
      experience: experience,
      details: details,
      wantReminder: wantReminder,
      respondedAt: DateTime.now(),
    );

    _serviceCheckInResponses.add(response);

    debugPrint('📝 Service check-in response recorded: $experience');
    notifyListeners();
  }

  // Gemini Actions Management
  /// Save a Gemini-generated action to the vault
  Future<void> saveGeminiActionToVault(StarboundNudge geminiAction) async {
    await bankNudge(geminiAction);
  }

  /// Check if a Gemini action is already saved in the vault
  bool isGeminiActionSaved(String actionId) {
    return _bankedNudges.any((nudge) => nudge.id == actionId);
  }

  /// Get all saved Gemini actions from the vault
  List<StarboundNudge> getSavedGeminiActions() {
    return _bankedNudges
        .where((nudge) =>
            nudge.source == NudgeSource.dynamic &&
            nudge.metadata?['ai_generated'] == true)
        .toList();
  }

  /// Toggle save state for a Gemini action
  Future<void> toggleSaveGeminiAction(StarboundNudge geminiAction) async {
    if (isGeminiActionSaved(geminiAction.id)) {
      await removeBankedNudge(geminiAction.id);
    } else {
      await saveGeminiActionToVault(geminiAction);
    }
  }

  // User Management
  Future<void> createOrLoginUser({
    required String username,
    required String displayName,
    required ComplexityLevel complexityProfile,
  }) async {
    if (_useBackend) {
      try {
        await _userService.createOrLoginUser(
          username: username,
          displayName: displayName,
          complexityProfile: complexityProfile,
        );
        await _loadDataFromBackend();
        notifyListeners();
      } catch (e) {
        throw Exception('Failed to create or login user: $e');
      }
    } else {
      _userName = displayName;
      _complexityProfile = complexityProfile;
      _isOnboardingComplete = true;
      await _storageService.saveUserName(displayName);
      await _storageService.saveComplexityProfile(complexityProfile);
      await _storageService.setOnboardingComplete(true);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_useBackend) {
      await _userService.logout();
    }
    await resetAllData();
  }

  // User Preferences
  Future<void> updateUserName(String name) async {
    // Always update locally first for immediate UI feedback
    _userName = name;
    await _storageService.saveUserName(name);

    if (_useBackend && _userService.isLoggedIn) {
      try {
        await _userService.updateProfile(displayName: name);
      } catch (e) {
        LoggingService.warning(
            'Failed to sync user name update, queuing for later',
            tag: 'AppState',
            error: e);
        // Queue for offline sync
        await _syncService.queueAction(SyncActionType.updateUserProfile, {
          'displayName': name,
        });
      }
    } else {
      // Queue for sync when backend becomes available
      if (_useBackend) {
        await _syncService.queueAction(SyncActionType.updateUserProfile, {
          'displayName': name,
        });
      }
    }
    notifyListeners();
  }

  Future<void> setHomeMemoryEnabled(bool enabled) async {
    if (_homeMemoryEnabled == enabled) {
      return;
    }
    _homeMemoryEnabled = enabled;
    await _storageService.saveHomeMemoryEnabled(enabled);
    _userDataChanged = true;
    notifyListeners();
  }

  Future<bool> submitUserFeedback({
    required String category,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    final feedbackMetadata = {
      'source': 'in_app_feedback',
      'category': category,
      'submitted_at': DateTime.now().toIso8601String(),
      'platform': defaultTargetPlatform.toString().split('.').last,
      if (metadata != null) ...metadata,
    };

    final data = {
      'category': category,
      'message': message,
      'metadata': feedbackMetadata,
      'userId': _userService.currentUserId,
    };

    if (_useBackend && _userService.isLoggedIn) {
      try {
        await _apiService.submitFeedback(
          userId: _userService.currentUserId,
          category: category,
          message: message,
          metadata: feedbackMetadata,
        );
        LoggingService.info('Feedback submitted to backend',
            tag: 'Feedback');
        return true;
      } catch (e) {
        LoggingService.warning(
          'Feedback submission failed, queuing for sync',
          tag: 'Feedback',
          error: e,
        );
      }
    }

    await _syncService.queueAction(SyncActionType.submitFeedback, data);
    return false;
  }

  Future<void> updateNotificationSettings(bool enabled, String time) async {
    _notificationsEnabled = enabled;
    _notificationTime = time;
    await _storageService.saveNotificationSettings(enabled, time);
    notifyListeners();
  }

  // Onboarding
  Future<void> setOnboardingComplete(bool complete) async {
    _isOnboardingComplete = complete;
    await _storageService.setOnboardingComplete(complete);

    // Try to update backend if available
    if (complete && _useBackend && _userService.isLoggedIn) {
      try {
        await _userService.completeOnboarding();
      } catch (e) {
        LoggingService.warning('Failed to complete onboarding in backend',
            tag: 'AppState', error: e);
        // Continue with local storage - no need to fail
      }
    }

    notifyListeners();
  }

  // NEW: Set Health Navigation Profile
  Future<void> setHealthNavigationProfile({
    required String userName,
    String? neighborhood,
    List<String>? languages,
    List<String>? barriers,
    List<String>? healthInterests,
    String? workSchedule,
    required String checkInFrequency,
    String? additionalNotes,
  }) async {
    _healthNavigationProfile = HealthNavigationProfile(
      userName: userName,
      neighborhood: neighborhood,
      languages: languages ?? [],
      barriers: barriers ?? [],
      healthInterests: healthInterests ?? [],
      workSchedule: workSchedule,
      checkInFrequency: checkInFrequency,
      additionalNotes: additionalNotes,
      isOnboardingComplete: true,
      onboardingCompletedAt: DateTime.now(),
      habits: _habits.map((k, v) => MapEntry(k, v ?? '')),
      journalEntries: _freeFormEntries.map((e) => e.toJson()).toList(),
    );

    // Update userName in AppState
    _userName = userName;
    _userNameNotifier.value = userName;

    // Save to storage
    await _storageService.saveHealthNavigationProfile(_healthNavigationProfile!);

    // Create or retrieve user in backend using device-based identity
    if (_useBackend && !_userService.isLoggedIn) {
      try {
        final deviceId = await _userService.getOrCreateDeviceId();
        await _userService.createOrLoginUser(
          username: deviceId,
          displayName: userName,
          complexityProfile: _complexityProfile,
        );
        LoggingService.info('Device user registered with backend', tag: 'AppState');
      } catch (e) {
        LoggingService.warning('Could not register device user with backend: $e', tag: 'AppState');
      }
    }

    LoggingService.info(
        'Health navigation profile saved: userName=$userName, barriers=${barriers?.length ?? 0}, '
        'healthInterests=${healthInterests?.length ?? 0}, neighborhood=$neighborhood',
        tag: 'AppState');

    notifyListeners();
  }

  // Smart Nudge Matching with Dynamic Generation
  Future<StarboundNudge?> getCurrentNudge({
    String? excludeId,
    bool forceRefresh = false,
  }) async {
    try {
      final bool canUseCache = _cachedCurrentNudge != null &&
          !forceRefresh &&
          (_lastNudgeGeneration != null &&
              DateTime.now().difference(_lastNudgeGeneration!).inMinutes < 30) &&
          (excludeId == null || _cachedCurrentNudge!.id != excludeId);

      if (canUseCache) {
        return _cachedCurrentNudge;
      }

      final blockedIds = <String>{};
      if (excludeId != null && excludeId.isNotEmpty) {
        blockedIds.add(excludeId);
      }

      // First try to get dynamic nudges
      final dynamicNudges = await generateDynamicNudges();
      final dynamicCandidate = _selectNextNudge(dynamicNudges, blockedIds);
      if (dynamicCandidate != null) {
        return _cacheAndReturnNudge(dynamicCandidate);
      }

      // Try backend if available
      if (_useBackend && _userService.isLoggedIn) {
        try {
          final nudgeData =
              await _apiService.getCurrentNudge(_userService.currentUserId!);
          if (nudgeData != null) {
            final backendNudge = StarboundNudge.fromJson(nudgeData);
            if (!_isBlockedNudge(backendNudge.id, blockedIds)) {
              return _cacheAndReturnNudge(backendNudge);
            }
          }
        } catch (e) {
          LoggingService.warning('Failed to get current nudge from backend',
              tag: 'AppState', error: e);
        }
      }

      // Fall back to predefined nudges
      final complexityLevelString =
          ComplexityProfileService.getComplexityLevelName(complexityProfile)
              .toLowerCase();
      final filteredNudges =
          NudgeVault.filterNudges(profileFit: complexityLevelString);

      final fallbackCandidate = _selectNextNudge(filteredNudges, blockedIds);
      if (fallbackCandidate != null) {
        return _cacheAndReturnNudge(fallbackCandidate);
      }

      return null;
    } catch (e) {
      LoggingService.error('Error getting current nudge',
          tag: 'AppState', error: e);
      return null;
    }
  }

  Future<StarboundNudge?> refreshCurrentNudge({String? excludeId}) async {
    _cachedCurrentNudge = null;
    _lastNudgeGeneration = null;
    return getCurrentNudge(excludeId: excludeId, forceRefresh: true);
  }

  Future<void> markNudgeCompleted(StarboundNudge nudge) async {
    try {
      final alreadyCompleted = _completedActions.contains(nudge.id);
      if (!alreadyCompleted) {
        await toggleActionCompleted(nudge.id, nudge: nudge);
      }
      _recordNudgeInteraction('completed', nudge);
    } catch (e, stackTrace) {
      LoggingService.error('Failed to mark nudge completed',
          tag: 'AppState', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> skipNudge(StarboundNudge nudge) async {
    _recordNudgeInteraction('skipped', nudge);
  }

  StarboundNudge _cacheAndReturnNudge(StarboundNudge nudge) {
    _cachedCurrentNudge = nudge;
    _lastNudgeGeneration = DateTime.now();
    _rememberNudge(nudge.id);
    return nudge;
  }

  StarboundNudge? _selectNextNudge(
    List<StarboundNudge> candidates,
    Set<String> blockedIds,
  ) {
    if (candidates.isEmpty) {
      return null;
    }

    final filtered = candidates
        .where((nudge) => !_isBlockedNudge(nudge.id, blockedIds))
        .toList();

    if (filtered.isNotEmpty) {
      return filtered.first;
    }

    final secondary = candidates
        .where((nudge) => !blockedIds.contains(nudge.id))
        .toList();

    if (secondary.isNotEmpty) {
      final index =
          DateTime.now().millisecondsSinceEpoch % secondary.length;
      return secondary[index];
    }

    final index = DateTime.now().millisecondsSinceEpoch % candidates.length;
    return candidates[index];
  }

  bool _isBlockedNudge(String id, Set<String> blockedIds) {
    if (id.isEmpty) return false;
    if (blockedIds.contains(id)) return true;

    const window = 3;
    for (var i = _recentNudgeHistory.length - 1;
        i >= 0 && i >= _recentNudgeHistory.length - window;
        i--) {
      if (_recentNudgeHistory[i] == id) {
        return true;
      }
    }
    return false;
  }

  void _rememberNudge(String? id) {
    if (id == null || id.isEmpty) return;
    _recentNudgeHistory.removeWhere((value) => value == id);
    _recentNudgeHistory.add(id);
    if (_recentNudgeHistory.length > _recentNudgeHistoryLimit) {
      _recentNudgeHistory.removeRange(
          0, _recentNudgeHistory.length - _recentNudgeHistoryLimit);
    }
  }

  void _recordNudgeInteraction(String action, StarboundNudge nudge) {
    LoggingService.info(
      'Nudge $action: ${nudge.id} (${nudge.theme})',
      tag: 'Nudge',
    );
  }

  List<StarboundNudge> getPersonalizedNudges() {
    return NudgeVault.filterNudges(
      profileFit: _complexityProfile.name,
    );
  }

  // Enhanced contextual nudges
  List<StarboundNudge> getContextualNudges({List<String> patterns = const []}) {
    return NudgeVault.getContextualNudges(
      currentHabits: _habits,
      complexityProfile: _complexityProfile.name,
      patterns: patterns,
    );
  }

  // Habit Analytics with enhanced caching
  Future<Map<String, int>> getHabitStreak() async {
    // Check cache first with intelligent expiry
    final now = DateTime.now();
    if (_cachedHabitStreaks != null &&
        _lastStreakCalculation != null &&
        _shouldUseCachedData(_lastStreakCalculation!, _shortCacheMinutes) &&
        !_hasHabitsChangedSinceCache()) {
      return _cachedHabitStreaks!;
    }

    Map<String, int> streaks;

    if (_useBackend && _userService.isLoggedIn) {
      try {
        final streaksData =
            await _apiService.getHabitStreaks(_userService.currentUserId!);
        streaks = Map<String, int>.from(streaksData);
      } catch (e) {
        LoggingService.warning(
            'Failed to get habit streaks from backend, falling back to local tracking',
            tag: 'AppState',
            error: e);
        // Fall through to local implementation
        streaks = await _calculateLocalHabitStreaks();
      }
    } else {
      // Local habit streak tracking implementation
      streaks = await _calculateLocalHabitStreaks();
    }

    // Cache the result
    _cachedHabitStreaks = streaks;
    _lastStreakCalculation = now;

    return streaks;
  }

  Future<Map<String, List<String>>> getHabitTrends() async {
    // Check cache first
    final now = DateTime.now();
    if (_cachedHabitTrends != null &&
        _lastTrendCalculation != null &&
        now.difference(_lastTrendCalculation!).inMinutes < _shortCacheMinutes) {
      return _cachedHabitTrends!;
    }

    Map<String, List<String>> trends;

    if (_useBackend && _userService.isLoggedIn) {
      try {
        final trendsData =
            await _apiService.getHabitTrends(_userService.currentUserId!);
        trends = Map<String, List<String>>.from(trendsData);
      } catch (e) {
        LoggingService.warning(
            'Failed to get habit trends from backend, falling back to local tracking',
            tag: 'AppState',
            error: e);
        // Fall through to local implementation
        trends = await _calculateLocalHabitTrends();
      }
    } else {
      // Local habit trend analysis implementation
      trends = await _calculateLocalHabitTrends();
    }

    // Cache the result
    _cachedHabitTrends = trends;
    _lastTrendCalculation = now;

    return trends;
  }

  // Local Analytics Implementation
  Future<Map<String, int>> _calculateLocalHabitStreaks() async {
    final streaks = <String, int>{};
    final today = DateTime.now();

    // Calculate streaks for all habits that have been tracked
    for (final habitKey in _habits.keys) {
      if (habitKey.isNotEmpty) {
        final streak =
            await _storageService.calculateHabitStreak(habitKey, today);
        if (streak > 0) {
          streaks[habitKey] = streak;
        }
      }
    }

    return streaks;
  }

  Future<Map<String, List<String>>> _calculateLocalHabitTrends() async {
    final trends = <String, List<String>>{};
    const daysToAnalyze = 7; // Last 7 days

    // Calculate trends for all habits that have been tracked
    for (final habitKey in _habits.keys) {
      if (habitKey.isNotEmpty) {
        final trendData =
            await _storageService.getHabitTrendData(habitKey, daysToAnalyze);
        if (trendData.isNotEmpty) {
          trends[habitKey] = trendData;
        }
      }
    }

    return trends;
  }

  // Store habit entry when habits are updated
  Future<void> _storeHabitEntry(String habitKey, String? value) async {
    if (value != null && value.isNotEmpty) {
      final today = DateTime.now();
      await _storageService.saveHabitEntry(habitKey, value, today);
    }
  }

  // Setup sync service callbacks
  void _setupSyncCallbacks() {
    _syncService.onSyncStarted = () {
      debugPrint('Sync started');
      notifyListeners(); // Notify UI about sync status change
    };

    _syncService.onSyncCompleted = () {
      debugPrint('Sync completed');
      notifyListeners(); // Notify UI about sync status change
    };

    _syncService.onSyncError = (error) {
      LoggingService.error('Sync error', tag: 'AppState', error: error);
      _setError('Sync failed: $error');
    };

    _syncService.onSyncProgress = (processed) {
      debugPrint('Sync progress: $processed actions processed');
      notifyListeners(); // Notify UI about progress
    };
  }

  // Manual sync trigger
  Future<bool> syncNow() async {
    return await _syncService.syncNow();
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    return await _syncService.getLastSyncTime();
  }

  // Public methods for testing
  void setLoading(bool loading) {
    _setLoading(loading);
  }

  void setError(String error) {
    _setError(error);
  }

  String? getHabitStatus(String habitId) {
    return _habits[habitId];
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final streaks = await getHabitStreak();
    final trends = await getHabitTrends();

    return {
      'streaks': streaks,
      'trends': trends,
      'totalHabits': _habits.length,
      'completedHabits':
          _habits.values.where((v) => v == 'completed').length,
      'activeHabits':
          _habits.values.where((v) => v != null && v.isNotEmpty).length,
    };
  }

  // Test helper methods
  bool isCacheExpired(DateTime? cacheTime, int maxAgeMinutes) {
    return !_shouldUseCachedData(
        cacheTime ?? DateTime.now().subtract(Duration(hours: 1)),
        maxAgeMinutes);
  }

  bool isValidHabitId(String habitId) {
    return habitId.isNotEmpty && habitId.trim().isNotEmpty;
  }

  bool isValidHabitStatus(String status) {
    const validStatuses = [
      'completed',
      'pending',
      'skipped',
      'good',
      'poor',
      'excellent',
      'none'
    ];
    return validStatuses.contains(status);
  }

  bool isValidUserName(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty;
  }

  void trackPerformance(String operation, DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    if (kDebugMode) {
      print('Performance: $operation took ${duration.inMilliseconds}ms');
    }
  }

  // Private helper methods with selective notification
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _isLoadingNotifier.value = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    if (_error != error) {
      _error = error;
      _errorNotifier.value = error;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      _errorNotifier.value = null;
      notifyListeners();
    }
  }

  // Public method to clear error
  void clearError() {
    _clearError();
  }

  // Performance optimization: Update specific state sections
  void _updateHabitsState(Map<String, String?> newHabits) {
    if (_habits != newHabits) {
      _habits = newHabits;
      _habitsNotifier.value = Map.unmodifiable(newHabits);
      _habitsChanged = true;
      notifyListeners();
    }
  }

  void _updateUserName(String newName) {
    if (_userName != newName) {
      _userName = newName;
      _userNameNotifier.value = newName;
      _userDataChanged = true;
      notifyListeners();
    }
  }

  void _updateSyncStatus(bool hasChanges) {
    final newStatus = _syncService.hasPendingActions;
    if (_syncStatusNotifier.value != newStatus) {
      _syncStatusNotifier.value = newStatus;
      _syncStatusChanged = true;
      notifyListeners();
    }
  }

  // Reset change tracking flags
  void resetChangeTracking() {
    _habitsChanged = false;
    _userDataChanged = false;
    _achievementsChanged = false;
    _syncStatusChanged = false;
  }

  Future<void> _loadUserData() async {
    _complexityProfile = await _storageService.loadComplexityProfile();
    _currentComplexityAssessment =
        await _storageService.loadComplexityAssessment();
    _assessmentHistory = await _storageService.loadAssessmentHistory();
    _complexityTrendScores = await _storageService.loadComplexityTrend();
    _complexityHistory = await _storageService.loadComplexityHistory();
    _complexityHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _lastComplexityShift = _complexityHistory.isNotEmpty
        ? _complexityHistory.last.timestamp
        : null;
    _userName = await _storageService.loadUserName();
    _isOnboardingComplete = await _storageService.isOnboardingComplete();
    final notificationSettings =
        await _storageService.loadNotificationSettings();
    _notificationsEnabled = notificationSettings['enabled'] ?? true;
    _notificationTime = notificationSettings['time'] ?? '19:00';
    _homeMemoryEnabled = await _storageService.loadHomeMemoryEnabled();

    // NEW: Load or migrate to HealthNavigationProfile
    await _loadOrMigrateHealthNavigationProfile();
  }

  // NEW: Load health navigation profile or migrate from legacy complexity
  Future<void> _loadOrMigrateHealthNavigationProfile() async {
    _healthNavigationProfile = await _storageService.loadHealthNavigationProfile();

    // Migration: If no health navigation profile exists but user has completed onboarding
    if (_healthNavigationProfile == null && _isOnboardingComplete) {
      LoggingService.info('Migrating legacy profile to health navigation profile',
          tag: 'AppState');

      // Create profile from legacy complexity level
      _healthNavigationProfile = HealthNavigationProfile.fromLegacyComplexity(
        complexityLevel: _complexityProfile,
        habits: _habits.map((k, v) => MapEntry(k, v ?? '')),
        journalEntries: _freeFormEntries.map((e) => e.toJson()).toList(),
      );

      // Update userName if we have one
      if (_userName != 'Explorer') {
        _healthNavigationProfile = _healthNavigationProfile!.copyWith(
          userName: _userName,
        );
      }

      // Save the migrated profile
      await _storageService.saveHealthNavigationProfile(_healthNavigationProfile!);

      LoggingService.info(
          'Migration complete: legacyComplexity=${_complexityProfile.name}, '
          'barriers=${_healthNavigationProfile!.barriers}, '
          'healthInterests=${_healthNavigationProfile!.healthInterests}',
          tag: 'AppState');
    }
  }

  Future<void> _loadHabits() async {
    _habits = await _storageService.loadHabits();
  }

  Future<void> _loadBankedNudges() async {
    _bankedNudges = (await _storageService.loadBankedNudges())
        .map(_normalizeNudgeTheme)
        .toList();
  }

  Future<void> _loadFreeFormEntries() async {
    _freeFormEntries = await _storageService.loadFreeFormEntries();
  }

  Future<void> _loadFavorites() async {
    _favoriteActions = await _storageService.loadFavoriteActions();
    _favoriteServices = await _storageService.loadFavoriteServices();
    _favoriteResources = await _storageService.loadFavoriteResources();
    _savedResources = await _storageService.loadSavedResources();
    _savedConversations = await _storageService.loadSavedConversations();
  }

  Future<void> _loadCompletedActions() async {
    _completedActions = await _storageService.loadCompletedActions();
  }

  void _enqueueCompletionPrompt(StarboundNudge nudge) {
    final promptId = 'prompt_${DateTime.now().millisecondsSinceEpoch}';
    _completionPrompts.add(CompletionReflectionPrompt(
      id: promptId,
      actionId: nudge.id,
      actionTitle: _deriveActionTitle(nudge),
      emoji: _emojiForTheme(nudge.theme),
      createdAt: DateTime.now(),
    ));

    if (_completionPrompts.length > 5) {
      _completionPrompts.removeRange(0, _completionPrompts.length - 5);
    }
  }

  void _removeCompletionPromptsForAction(String actionId) {
    _completionPrompts.removeWhere((prompt) => prompt.actionId == actionId);
  }

  StarboundNudge _fallbackNudgeForAction(
      String actionId, StarboundNudge? original) {
    if (original != null) {
      return original;
    }

    final resolved = _resolveNudgeById(actionId);
    if (resolved != null) {
      return resolved;
    }

    try {
      return NudgeVault.nudges
          .firstWhere((candidate) => candidate.id == actionId);
    } catch (_) {
      return StarboundNudge(
        id: actionId,
        theme: 'focus',
        message: 'Completed action',
        tone: 'gentle',
      );
    }
  }

  StarboundNudge? _resolveNudgeById(String actionId) {
    for (final nudge in _bankedNudges) {
      if (nudge.id == actionId) {
        return nudge;
      }
    }
    return null;
  }

  String _deriveActionTitle(StarboundNudge nudge) {
    String rawTitle = nudge.title.trim();
    if (rawTitle.isEmpty) {
      rawTitle = nudge.message.trim();
    }

    if (rawTitle.isEmpty) {
      return 'Simple task';
    }

    final firstSentence = _extractLeadingPhrase(rawTitle);
    if (firstSentence.isEmpty) {
      return 'Simple task';
    }

    return _sentenceCase(firstSentence);
  }

  String _emojiForTheme(String theme) {
    switch (theme.toLowerCase()) {
      case 'hydration':
        return '💧';
      case 'sleep':
        return '😴';
      case 'movement':
        return '🏃‍♀️';
      case 'nutrition':
        return '🥗';
      case 'focus':
        return '🎯';
      case 'calm':
        return '🧘‍♀️';
      default:
        return '✨';
    }
  }

  String _extractLeadingPhrase(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final colonIndex = trimmed.indexOf(':');
    if (colonIndex != -1) {
      return trimmed.substring(0, colonIndex).trim();
    }

    final match = RegExp(r'[^.!?]+').firstMatch(trimmed);
    return match?.group(0)?.trim() ?? trimmed;
  }

  String _sentenceCase(String input) {
    final words = input.split(RegExp(r'\s+'));
    if (words.isEmpty) {
      return input;
    }

    final transformed = <String>[];
    for (final word in words) {
      if (word.isEmpty) continue;
      final hasInnerUpper =
          word.length > 1 && word.substring(1).contains(RegExp(r'[A-Z]'));
      final isAllCaps = word.length > 1 && word == word.toUpperCase();
      if (hasInnerUpper || isAllCaps) {
        transformed.add(word);
      } else {
        transformed.add(word.toLowerCase());
      }
    }

    if (transformed.isEmpty) {
      return input;
    }

    final sentence = transformed.join(' ');
    return sentence[0].toUpperCase() + sentence.substring(1);
  }

  String? _buildCompletionJournalEntry({
    required CompletionReflectionPrompt prompt,
    required String feeling,
  }) {
    final actionTitle = prompt.actionTitle;

    switch (feeling) {
      case 'better':
        return '${prompt.emoji} I felt better right after "$actionTitle".';
      case 'same':
        return '${prompt.emoji} No big change after "$actionTitle".';
      case 'worse':
        return '${prompt.emoji} I actually feel worse after "$actionTitle".';
      case 'journal':
        return '${prompt.emoji} I want to capture more about "$actionTitle".';
      default:
        return null;
    }
  }

  // Load data from backend
  Future<void> _loadDataFromBackend() async {
    if (!_userService.isLoggedIn) return;

    try {
      // Load banked nudges
      final bankedNudgesData =
          await _apiService.getBankedNudges(_userService.currentUserId!);
      _bankedNudges = bankedNudgesData
          .map((data) => StarboundNudge.fromJson(data))
          .toList();

      // Load habit entries and reconstruct current habits
      final habitEntries =
          await _apiService.getUserHabitEntries(_userService.currentUserId!);
      _habits = {}; // Reset habits

      // Get today's entries and build current habits map
      final today = DateTime.now();
      final todayEntries = habitEntries.where((entry) {
        final entryDate = DateTime.parse(entry['entry_date']);
        return entryDate.year == today.year &&
            entryDate.month == today.month &&
            entryDate.day == today.day;
      }).toList();

      for (final entry in todayEntries) {
        final categoryId = entry['category_id'];
        final value = entry['selected_value'];
        // Map category ID to habit key - this would need habit categories from backend
        // For now, use a simple mapping
        if (categoryId == 1) _habits['hydration'] = value;
        if (categoryId == 2) _habits['sleep'] = value;
        if (categoryId == 3) _habits['movement'] = value;
        if (categoryId == 4) _habits['nutrition'] = value;
        if (categoryId == 5) _habits['mood'] = value;
        if (categoryId == 6) _habits['stress'] = value;
        if (categoryId == 7) _habits['connection'] = value;
        if (categoryId == 8) _habits['focus'] = value;
      }

      // Load favorites and completion state from local storage for now
      await _loadFavorites();
      await _loadCompletedActions();
    } catch (e) {
      LoggingService.error('Failed to load data from backend',
          tag: 'AppState', error: e);
      // Fall back to local storage
      await _loadDataFromLocal();
    }
  }

  // Load data from local storage
  Future<void> _loadDataFromLocal() async {
    await _loadUserData();
    await _loadHabits();
    await _loadBankedNudges();
    await _loadFreeFormEntries();
    await _loadFavorites();
    await _loadCompletedActions();

  }

  // Reset all data (for testing or user request)
  Future<void> resetAllData() async {
    _complexityProfile = ComplexityLevel.trying;
    _complexityTrendScores = {
      for (final level in ComplexityLevel.values) level: 0.0,
    };
    _complexityHistory = [];
    _lastComplexityShift = null;
    _habits.clear();
    _bankedNudges.clear();
    _favoriteActions.clear();
    _completedActions.clear();
    _favoriteServices.clear();
    _favoriteResources.clear();
    _savedResources.clear();
    _savedConversations.clear();
    _completionPrompts.clear();
    _completionResponses.clear();
    _serviceCheckInPrompts.clear();
    _serviceCheckInResponses.clear();
    _userName = 'Explorer';
    _notificationsEnabled = true;
    _notificationTime = '19:00';
    _isOnboardingComplete = false;

    await _userService.logout();
    await _storageService.clearAll();
    _invalidateAnalyticsCache();
    notifyListeners();
  }

  // Performance optimization: Enhanced cache management
  void _invalidateAnalyticsCache() {
    _cachedHabitStreaks = null;
    _cachedHabitTrends = null;
    _cachedSuccessPatterns = null;
    _cachedCorrelations = null;
    _cachedSuggestions = null;
    _lastStreakCalculation = null;
    _lastTrendCalculation = null;
    _lastPatternAnalysis = null;
    _lastCorrelationAnalysis = null;
    _lastSuggestionGeneration = null;
  }

  // Intelligent cache validity check
  bool _shouldUseCachedData(DateTime cacheTime, int maxAgeMinutes) {
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < maxAgeMinutes;
  }

  // Check if habits have changed since last cache
  bool _hasHabitsChangedSinceCache() {
    if (_lastHabitUpdate == null) return false;
    if (_lastStreakCalculation == null) return true;
    return _lastHabitUpdate!.isAfter(_lastStreakCalculation!);
  }

  // Mark habit data as updated (for smart cache invalidation)
  void _markHabitsUpdated() {
    _lastHabitUpdate = DateTime.now();
    // Only invalidate streak cache since habits changed
    _cachedHabitStreaks = null;
    _lastStreakCalculation = null;
  }

  // Smart notification scheduling based on current state
  Future<void> _scheduleSmartNotifications() async {
    try {
      // Get current habit streaks for background scheduling
      final streaks = await getHabitStreak();

      // Trigger comprehensive background scheduling with current context
      await _notificationService.triggerBackgroundScheduling(
        currentHabits: _habits,
        complexityProfile: complexityProfile,
        habitStreaks: streaks,
      );

      // Schedule contextual nudges based on current habits and complexity profile
      final currentNudge = await getCurrentNudge();
      if (currentNudge != null) {
        await _notificationService.scheduleContextualReminder(
          nudge: currentNudge,
          complexityProfile: complexityProfile,
          currentHabits: _habits,
        );
      }
    } catch (e) {
      LoggingService.error('Error scheduling smart notifications',
          tag: 'AppState', error: e);
    }
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences({
    bool? enabled,
    String? preferredTime,
    List<int>? enabledDays,
  }) async {
    await _notificationService.updatePreferences(
      enabled: enabled,
      preferredTime: preferredTime,
      enabledDays: enabledDays,
    );
    notifyListeners();
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  // Habit correlation analysis
  Future<List<dynamic>> getHabitCorrelations({int daysToAnalyze = 30}) async {
    try {
      return await _correlationService.analyzeHabitCorrelations(
        currentHabits: _habits,
        daysToAnalyze: daysToAnalyze,
        minimumStrength: 0.3,
        minimumSamples: 7,
      );
    } catch (e) {
      LoggingService.error('Error getting habit correlations',
          tag: 'AppState', error: e);
      return [];
    }
  }

  // Get correlation insights based on complexity profile
  Future<List<Map<String, dynamic>>> getCorrelationInsights(
      {int daysToAnalyze = 30}) async {
    try {
      final correlations =
          await getHabitCorrelations(daysToAnalyze: daysToAnalyze);
      return _correlationService.generateCorrelationInsights(
        correlations: correlations.cast(),
        complexityProfile: complexityProfile,
        currentHabits: _habits,
      );
    } catch (e) {
      LoggingService.error('Error getting correlation insights',
          tag: 'AppState', error: e);
      return [];
    }
  }

  // Get habit pairing suggestions
  Future<dynamic> getBestHabitPairing(String habitKey) async {
    try {
      return _correlationService.getBestPairingForHabit(habitKey);
    } catch (e) {
      LoggingService.error('Error getting habit pairing',
          tag: 'AppState', error: e);
      return null;
    }
  }

  // Achievement system integration
  Future<void> _checkForNewAchievements([BuildContext? context]) async {
    try {
      final streaks = await getHabitStreak();
      final correlations = await getHabitCorrelations();

      final newAchievements = await _achievementService.checkForNewAchievements(
        currentHabits: _habits,
        habitStreaks: streaks,
        complexityProfile: complexityProfile,
        correlations: correlations,
      );

      if (newAchievements.isNotEmpty) {
        // Show magical celebration popup if context is available
        if (context != null && context.mounted) {
          AchievementCelebrationPopup.show(
            context,
            newAchievements,
            onDismiss: () {
              // Mark achievements as celebrated
              _achievementsChanged = true;
              notifyListeners();
            },
          );
        }

        // Also show achievement notifications for background unlocks
        for (final achievement in newAchievements) {
          await _showAchievementNotification(achievement);
        }
      }
    } catch (e) {
      LoggingService.error('Error checking for achievements',
          tag: 'AppState', error: e);
    }
  }

  // Show achievement unlock notification
  Future<void> _showAchievementNotification(dynamic achievement) async {
    if (achievement is Map<String, dynamic>) {
      final title = achievement['title'] as String? ?? 'Achievement Unlocked!';
      final emoji = achievement['emoji'] as String? ?? '🏆';
      final points = achievement['points'] as int? ?? 0;

      // Schedule immediate achievement notification
      await _notificationService.scheduleContextualReminder(
        nudge: StarboundNudge(
          id: 'achievement_${achievement['id']}',
          theme: 'celebration',
          message: 'You earned $points points! Keep up the great work.',
          tone: 'celebratory',
          complexityProfileFit: [complexityProfile.name],
        ),
        complexityProfile: complexityProfile,
        currentHabits: _habits,
        customTime: DateTime.now().add(const Duration(seconds: 5)),
      );
    }
  }

  // Achievement-related getters and methods
  List<dynamic> get unlockedAchievements =>
      _achievementService.unlockedAchievements;

  List<dynamic> get availableAchievements =>
      _achievementService.getAvailableAchievements(complexityProfile);

  List<dynamic> getUnlockableAchievements() {
    try {
      return _achievementService.getUnlockableAchievements(
        currentHabits: _habits,
        complexityProfile: complexityProfile,
      );
    } catch (e) {
      LoggingService.error('Error getting unlockable achievements',
          tag: 'AppState', error: e);
      return [];
    }
  }

  int get achievementPoints => _achievementService.totalPoints;

  int get achievementCount => _achievementService.unlockedCount;

  Map<String, dynamic> get achievementStats =>
      _achievementService.getAchievementStats(complexityProfile);

  // Increment analytics views for achievement tracking
  Future<void> incrementAnalyticsViews([BuildContext? context]) async {
    await _achievementService.incrementAnalyticsViews();
    await _checkForNewAchievements(
        context); // Check if analytics achievements unlocked
  }

  // Public method to trigger achievement checks with celebration popups
  Future<void> checkForNewAchievements(BuildContext context) async {
    await _checkForNewAchievements(context);
  }

  // Pattern recognition and insights with caching
  Future<List<dynamic>> getSuccessPatterns({int analysisDepthDays = 30}) async {
    try {
      // Check cache first for expensive pattern analysis
      if (_cachedSuccessPatterns != null &&
          _lastPatternAnalysis != null &&
          _shouldUseCachedData(_lastPatternAnalysis!, _longCacheMinutes) &&
          !_hasHabitsChangedSinceCache()) {
        return _cachedSuccessPatterns!;
      }

      final streaks = await getHabitStreak();
      final correlations =
          await getHabitCorrelations(daysToAnalyze: analysisDepthDays);

      final patterns = await _patternService.analyzeSuccessPatterns(
        currentHabits: _habits,
        habitStreaks: streaks,
        complexityProfile: complexityProfile,
        correlations: correlations,
        analysisDepthDays: analysisDepthDays,
      );

      // Cache the results for performance
      _cachedSuccessPatterns = patterns;
      _lastPatternAnalysis = DateTime.now();

      return patterns;
    } catch (e) {
      LoggingService.error('Error getting success patterns',
          tag: 'AppState', error: e);
      return _cachedSuccessPatterns ??
          []; // Return cached data on error if available
    }
  }

  // Get actionable insights based on discovered patterns
  Future<List<Map<String, dynamic>>> getActionableInsights(
      {int analysisDepthDays = 30}) async {
    try {
      final patterns =
          await getSuccessPatterns(analysisDepthDays: analysisDepthDays);
      return _patternService.generateActionableInsights(
        patterns.cast(),
        complexityProfile,
      );
    } catch (e) {
      LoggingService.error('Error getting actionable insights',
          tag: 'AppState', error: e);
      return [];
    }
  }

  // Get personalized habit suggestions with performance caching
  Future<List<HabitSuggestion>> getHabitSuggestions(
      {int maxSuggestions = 5}) async {
    try {
      // Check cache first for expensive suggestion generation
      if (_cachedSuggestions != null &&
          _lastSuggestionGeneration != null &&
          _shouldUseCachedData(
              _lastSuggestionGeneration!, _mediumCacheMinutes) &&
          !_hasHabitsChangedSinceCache()) {
        return _cachedSuggestions!.take(maxSuggestions).toList();
      }

      final patterns = await getSuccessPatterns();
      final correlations = await getHabitCorrelations();
      final assessment = ComplexityProfileService.calculateComplexityLevel({});

      final suggestions = await _suggestionService.generateSuggestions(
        currentHabits: _habits,
        complexityAssessment: assessment,
        patterns: patterns.cast(),
        correlations: correlations.cast(),
        maxSuggestions: maxSuggestions,
      );

      // Cache the results for performance
      _cachedSuggestions = suggestions;
      _lastSuggestionGeneration = DateTime.now();

      return suggestions;
    } catch (e) {
      LoggingService.error('Error getting habit suggestions',
          tag: 'AppState', error: e);
      return _cachedSuggestions?.take(maxSuggestions).toList() ??
          []; // Return cached data on error
    }
  }

  // Generate dynamic nudges from suggestions
  Future<List<StarboundNudge>> generateDynamicNudges({
    List<HabitSuggestion>? suggestions,
    bool includeInterventions = true,
    bool includeCorrelations = true,
    bool includeSeasonal = true,
    bool useAI = true, // New parameter to enable AI-powered nudges
  }) async {
    try {
      final dynamicNudges = <StarboundNudge>[];
      final complexityLevelString =
          ComplexityProfileService.getComplexityLevelName(complexityProfile)
              .toLowerCase();

      // NEW: Generate AI-powered personalized nudge first (if enabled)
      if (useAI) {
        try {
          final aiNudge = await DynamicNudgeGenerator.generateAINudge(
            userName: userName.isNotEmpty ? userName : 'friend',
            complexityProfile: complexityLevelString,
            currentHabits: _habits,
            contextData: {
              'timeOfDay': DateTime.now().hour,
              'lastActiveHour':
                  DateTime.now().subtract(Duration(hours: 1)).hour,
              'currentSession': true,
              'recentActivities': _getRecentActivities(),
            },
          );

          dynamicNudges.add(aiNudge);

          if (kDebugMode) {
            print('🤖 Generated AI-powered nudge: ${aiNudge.message}');
            print('🧠 Using technique: ${aiNudge.metadata?['technique']}');
            print(
                '📚 Behavioral principle: ${aiNudge.metadata?['behavioral_principle']}');
          }
        } catch (e) {
          if (kDebugMode) {
            print(
                '⚠️ AI nudge generation failed, falling back to traditional methods: $e');
          }
          // Continue with traditional nudge generation if AI fails
        }
      }

      // Generate nudges from habit suggestions
      if (suggestions != null) {
        for (final suggestion in suggestions.take(3)) {
          // Limit to top 3
          if (suggestion.successProbability > 50) {
            // Only suggest if reasonable chance
            dynamicNudges.add(DynamicNudgeGenerator.generateFromSuggestion(
              habitKey: suggestion.habitKey,
              habitTitle: suggestion.title,
              rationale: suggestion.rationale,
              successProbability: suggestion.successProbability,
              complexityLevel: complexityLevelString,
              metadata: suggestion.metadata,
            ));
          }
        }
      }

      // Generate intervention nudges for declining patterns
      if (includeInterventions) {
        final streaks = await getHabitStreak();
        for (final entry in streaks.entries) {
          if (entry.value > 3 && _habits[entry.key] == 'poor') {
            // Declining streak
            dynamicNudges.add(DynamicNudgeGenerator.generateInterventionNudge(
              habitKey: entry.key,
              pattern: 'declining_streak',
              complexityLevel: complexityLevelString,
              streakLength: entry.value,
            ));
          }
        }
      }

      // Generate correlation-based nudges
      if (includeCorrelations) {
        final correlations = await getHabitCorrelations();
        final successfulHabits = _habits.entries
            .where((e) => e.value == 'good' || e.value == 'excellent')
            .map((e) => e.key)
            .toList();

        for (final correlation in correlations.take(2)) {
          // Top 2 correlations
          if (correlation is Map<String, dynamic>) {
            final habit1 = correlation['habit1'] as String?;
            final habit2 = correlation['habit2'] as String?;
            final strength =
                (correlation['strength'] as num?)?.toDouble() ?? 0.0;
            final type = correlation['type'] as String?;

            if (habit1 != null && habit2 != null && strength > 0.7) {
              if (successfulHabits.contains(habit1) &&
                  !_habits.containsKey(habit2)) {
                dynamicNudges
                    .add(DynamicNudgeGenerator.generateCorrelationNudge(
                  habit1: habit1,
                  habit2: habit2,
                  correlationStrength: strength,
                  complexityLevel: complexityLevelString,
                  correlationType: type ?? 'positive',
                ));
              }
            }
          }
        }
      }

      // Generate seasonal nudges
      if (includeSeasonal) {
        final month = DateTime.now().month;
        final season = month >= 12 || month <= 2
            ? 'winter'
            : month >= 3 && month <= 5
                ? 'spring'
                : month >= 6 && month <= 8
                    ? 'summer'
                    : 'fall';

        final seasonalHabits = _getSeasonalHabitRecommendations(season);
        for (final habitKey in seasonalHabits.take(2)) {
          if (!_habits.containsKey(habitKey)) {
            dynamicNudges.add(DynamicNudgeGenerator.generateSeasonalNudge(
              habitKey: habitKey,
              season: season,
              complexityLevel: complexityLevelString,
            ));
          }
        }
      }

      return dynamicNudges;
    } catch (e) {
      LoggingService.error('Error generating dynamic nudges',
          tag: 'AppState', error: e);
      return [];
    }
  }

  // Helper method to get recent activities for AI context
  Map<String, dynamic> _getRecentActivities() {
    final now = DateTime.now();
    final recentHours = 6; // Look at last 6 hours of activity

    return {
      'last_habit_update': _lastHabitUpdate?.toIso8601String(),
      'recent_habit_changes': _habits.entries
          .where((entry) => entry.value != null && entry.value != 'none')
          .map((entry) => '${entry.key}:${entry.value}')
          .toList(),
      'active_session_duration': _lastHabitUpdate != null
          ? now.difference(_lastHabitUpdate!).inMinutes
          : 0,
      'current_habits_summary': _summarizeCurrentHabits(),
      'time_since_last_update': _lastHabitUpdate != null
          ? now.difference(_lastHabitUpdate!).inMinutes
          : null,
    };
  }

  // Helper to summarize current habits for AI context
  Map<String, int> _summarizeCurrentHabits() {
    final summary = <String, int>{};

    // Count habits by status
    var goodCount = 0;
    var poorCount = 0;
    var nullCount = 0;

    _habits.forEach((key, value) {
      if (value == 'good' || value == 'high' || value == 'regular') {
        goodCount++;
      } else if (value == 'poor' ||
          value == 'low' ||
          value == 'none' ||
          value == 'skipped') {
        poorCount++;
      } else if (value == null) {
        nullCount++;
      }
    });

    summary['good_habits'] = goodCount;
    summary['poor_habits'] = poorCount;
    summary['unknown_habits'] = nullCount;
    summary['total_habits'] = _habits.length;

    return summary;
  }

  // Helper method for seasonal habit recommendations
  List<String> _getSeasonalHabitRecommendations(String season) {
    switch (season.toLowerCase()) {
      case 'winter':
        return ['vitamin_d', 'indoor_exercise', 'warm_drinks', 'light_therapy'];
      case 'spring':
        return ['outdoor_time', 'spring_cleaning', 'gardening', 'fresh_air'];
      case 'summer':
        return [
          'hydration',
          'sun_protection',
          'outdoor_exercise',
          'fresh_fruits'
        ];
      case 'fall':
        return ['immune_support', 'cozy_routines', 'reflection', 'preparation'];
      default:
        return ['mindfulness', 'gratitude', 'self_care'];
    }
  }

  // Calculate success probability for a specific habit
  Future<double> calculateHabitSuccessProbability(String habitKey) async {
    try {
      final patterns = await getSuccessPatterns();
      final correlations = await getHabitCorrelations();
      final assessment = ComplexityProfileService.calculateComplexityLevel({});

      return await _patternService.calculateHabitSuccessProbability(
        habitKey: habitKey,
        currentHabits: _habits,
        complexityProfile: assessment,
        patterns: patterns.cast(),
        correlations: correlations,
      );
    } catch (e) {
      LoggingService.error('Error calculating success probability',
          tag: 'AppState', error: e);
      return 50.0; // Default neutral probability
    }
  }

  // Complexity Analysis Integration

  /// Analyze complexity patterns from recent reflections
  void _blendTrendScores(
    Map<ComplexityLevel, double> signal, {
    double alpha = _complexityTrendAlpha,
  }) {
    if (signal.isEmpty) return;

    final total = signal.values.fold<double>(0.0, (sum, value) => sum + value);
    if (total <= 0) return;

    for (final level in ComplexityLevel.values) {
      final target = (signal[level] ?? 0.0) / total;
      final previous = _complexityTrendScores[level] ?? 0.0;
      var updated = (target * alpha) + (previous * (1.0 - alpha));
      if (updated < 0) updated = 0;
      if (updated > 1) updated = 1;
      _complexityTrendScores[level] = updated;
    }
  }

  void _updateComplexityTrendFromAnalysis(ComplexityAnalysis analysis) {
    _blendTrendScores(analysis.scores);
  }

  Future<void> _evaluateComplexityShift(ComplexityAnalysis analysis) async {
    final currentLevel = complexityProfile;
    final suggestedLevel = analysis.suggestedLevel;

    if (suggestedLevel == currentLevel) {
      return;
    }

    final now = DateTime.now();
    if (_lastComplexityShift != null &&
        now.difference(_lastComplexityShift!).abs() <
            _complexityShiftCooldown) {
      return;
    }

    final trendAdvantage = (_complexityTrendScores[suggestedLevel] ?? 0.0) -
        (_complexityTrendScores[currentLevel] ?? 0.0);
    final scoreAdvantage = (analysis.scores[suggestedLevel] ?? 0.0) -
        (analysis.scores[currentLevel] ?? 0.0);

    if (analysis.confidence < _complexityConfidenceThreshold) {
      return;
    }

    if (trendAdvantage < _complexityTrendMinimumGap &&
        scoreAdvantage < _complexityScoreMinimumGap) {
      return;
    }

    final reason = analysis.getTrendSummary(currentLevel);

    await _commitComplexityProfileShift(
      fromLevel: currentLevel,
      toLevel: suggestedLevel,
      reason: reason,
      confidence: analysis.confidence,
    );
  }

  Future<void> _ingestHabitComplexitySignal() async {
    if (_habits.isEmpty) return;

    final summary = _summarizeCurrentHabits();
    final totalHabits = summary['total_habits'] ?? 0;
    if (totalHabits <= 0) return;

    final goodHabits = summary['good_habits'] ?? 0;
    final poorHabits = summary['poor_habits'] ?? 0;
    final unknownHabits = summary['unknown_habits'] ?? 0;

    final positiveRatio = goodHabits / totalHabits;
    final negativeRatio = poorHabits / totalHabits;
    final neutralRatio = (unknownHabits / totalHabits).clamp(0.0, 1.0);

    final habitSignal = <ComplexityLevel, double>{
      ComplexityLevel.stable: positiveRatio,
      ComplexityLevel.trying:
          (neutralRatio * 0.6) + (positiveRatio * 0.2) + (negativeRatio * 0.2),
      ComplexityLevel.overloaded: (negativeRatio * 0.8) + (neutralRatio * 0.2),
      ComplexityLevel.survival: negativeRatio * negativeRatio,
    };

    _blendTrendScores(habitSignal, alpha: 0.2);
    await _storageService.saveComplexityTrend(_complexityTrendScores);

    await _evaluateHabitSignalShift(
      positiveRatio: positiveRatio,
      negativeRatio: negativeRatio,
      sampleSize: totalHabits,
    );
  }

  Future<void> _evaluateHabitSignalShift({
    required double positiveRatio,
    required double negativeRatio,
    required int sampleSize,
  }) async {
    if (sampleSize < 5) return; // need enough data to be confident

    final now = DateTime.now();
    if (_lastComplexityShift != null &&
        now.difference(_lastComplexityShift!).abs() <
            _complexityShiftCooldown) {
      return;
    }

    final currentLevel = complexityProfile;
    ComplexityLevel? target;
    double confidence = 0.0;
    String reason;

    final negativeAdvantage = negativeRatio - positiveRatio;
    final positiveAdvantage = positiveRatio - negativeRatio;

    if (negativeRatio >= 0.80 && negativeAdvantage >= 0.35) {
      target = ComplexityLevel.survival;
      confidence = negativeRatio;
      reason = 'Habit patterns show sustained survival-mode effort';
    } else if (negativeRatio >= 0.60 && negativeAdvantage >= 0.25) {
      target = ComplexityLevel.overloaded;
      confidence = negativeRatio;
      reason = 'Habit patterns show high strain and skipped routines';
    } else if (positiveRatio >= 0.80 && positiveAdvantage >= 0.35) {
      target = ComplexityLevel.stable;
      confidence = positiveRatio;
      reason = 'Habit momentum suggests greater capacity';
    } else if (positiveRatio >= 0.60 &&
        positiveAdvantage >= 0.20 &&
        currentLevel.index > ComplexityLevel.trying.index) {
      target = ComplexityLevel.trying;
      confidence = positiveRatio;
      reason = 'Habits showing recovery and consistent follow-through';
    } else {
      return;
    }

    if (target == currentLevel) {
      return;
    }

    await _commitComplexityProfileShift(
      fromLevel: currentLevel,
      toLevel: target,
      reason: reason,
      confidence: confidence.clamp(0.0, 1.0),
    );
  }

  Future<void> _commitComplexityProfileShift({
    required ComplexityLevel fromLevel,
    required ComplexityLevel toLevel,
    required String reason,
    double? confidence,
  }) async {
    final transition = ComplexityProfileTransition(
      fromLevel: fromLevel,
      toLevel: toLevel,
      timestamp: DateTime.now(),
      reason: reason,
      confidence: confidence,
    );

    _complexityHistory.add(transition);
    if (_complexityHistory.length > _complexityHistoryLimit) {
      _complexityHistory = _complexityHistory
          .sublist(_complexityHistory.length - _complexityHistoryLimit);
    }
    _lastComplexityShift = transition.timestamp;

    if (kDebugMode) {
      final confidenceLabel = confidence != null
          ? '${(confidence * 100).toStringAsFixed(0)}%'
          : 'n/a';
      debugPrint(
        '🔄 Complexity profile auto-adjusted: ${fromLevel.name} → ${toLevel.name} '
        '(confidence $confidenceLabel)',
      );
    }

    await _storageService.saveComplexityHistory(_complexityHistory);
    await _storageService.saveComplexityTrend(_complexityTrendScores);

    if (_currentComplexityAssessment != null) {
      final currentAssessment = _currentComplexityAssessment!;
      final updatedScores = {...currentAssessment.scores};
      updatedScores[toLevel] = (updatedScores[toLevel] ?? 0) + 1;

      _currentComplexityAssessment = ComplexityAssessment(
        scores: updatedScores,
        primaryLevel: toLevel,
        secondaryLevel: fromLevel,
        highStressCategories: currentAssessment.highStressCategories,
        supportiveCategories: currentAssessment.supportiveCategories,
        responses: currentAssessment.responses,
        livedExperienceLevel: toLevel,
        livedExperienceConfidence: confidence,
        recentTagFrequency: currentAssessment.recentTagFrequency,
        criticalIndicators: currentAssessment.criticalIndicators,
        positiveIndicators: currentAssessment.positiveIndicators,
        lastAnalysisDate: currentAssessment.lastAnalysisDate,
        needsReassessment: false,
      );

      await _storageService
          .saveComplexityAssessment(_currentComplexityAssessment!);
    }

    await updateComplexityProfile(toLevel);
  }

  Future<void> _analyzeComplexityFromReflections() async {
    try {
      // Only analyze if we have enough recent data and it's been a while since last analysis
      final now = DateTime.now();
      if (_lastComplexityAnalysis != null &&
          now.difference(_lastComplexityAnalysis!).inHours < 12) {
        return; // Don't analyze too frequently
      }

      if (_freeFormEntries.length < 3) {
        return; // Need at least 3 entries for meaningful analysis
      }

      // Get recent entries (last 7 days)
      final recentEntries = _freeFormEntries
          .where((entry) => now.difference(entry.timestamp).inDays <= 7)
          .toList();

      if (recentEntries.isEmpty) return;

      // Perform complexity analysis
      final analysis =
          await _complexityAnalyzer.analyzeComplexity(recentEntries);

      // Get current assessment or create a basic one
      final currentAssessment = getCurrentComplexityAssessment();
      if (currentAssessment == null) return;

      // Update the assessment with dynamic analysis data
      _currentComplexityAssessment = currentAssessment.copyWithDynamicAnalysis(
        livedExperienceLevel: analysis.suggestedLevel,
        livedExperienceConfidence: analysis.confidence,
        recentTagFrequency: analysis.tagFrequency,
        criticalIndicators: analysis.criticalIndicators,
        positiveIndicators: analysis.positiveIndicators,
        lastAnalysisDate: now,
        needsReassessment:
            analysis.shouldSuggestReassessment(currentAssessment.primaryLevel),
      );

      _updateComplexityTrendFromAnalysis(analysis);
      await _storageService.saveComplexityTrend(_complexityTrendScores);

      _lastComplexityAnalysis = now;

      // Save the updated assessment
      await _storageService
          .saveComplexityAssessment(_currentComplexityAssessment!);

      await _evaluateComplexityShift(analysis);

      // Log insights for debugging
      if (kDebugMode) {
        final insights = _complexityAnalyzer.generateInsights(
            analysis, currentAssessment.primaryLevel);
        debugPrint('🧠 Complexity Analysis Complete:');
        debugPrint('  Suggested Level: ${analysis.suggestedLevel}');
        debugPrint('  Confidence: ${(analysis.confidence * 100).round()}%');
        debugPrint(
            '  Critical Indicators: ${analysis.criticalIndicators.take(3).join(", ")}');
        debugPrint(
            '  Positive Indicators: ${analysis.positiveIndicators.take(3).join(", ")}');
        for (final insight in insights.take(3)) {
          debugPrint('  💡 $insight');
        }
      }

      notifyListeners();
    } catch (e) {
      LoggingService.error('Error analyzing complexity from reflections',
          tag: 'AppState', error: e);
      // Don't rethrow - this is a background process
    }
  }

  /// Get complexity insights based on lived experience data
  List<String> getComplexityInsights() {
    final assessment = getCurrentComplexityAssessment();
    if (assessment == null) return [];

    final insights = <String>[];

    // Add lived experience insights
    insights.add(assessment.getLivedExperienceInsight());

    // Add critical and positive indicator summaries
    insights.add(assessment.getCriticalIndicatorsSummary());
    insights.add(assessment.getPositiveIndicatorsSummary());

    // Add reassessment suggestion if needed
    if (assessment.needsReassessment == true) {
      insights.add(
          "Consider updating your complexity profile based on recent reflections");
    }

    if (_complexityHistory.isNotEmpty) {
      final latestShift = _complexityHistory.last;
      final elapsed = DateTime.now().difference(latestShift.timestamp);
      String whenLabel;
      if (elapsed.inDays >= 1) {
        whenLabel =
            '${elapsed.inDays} day${elapsed.inDays == 1 ? '' : 's'} ago';
      } else if (elapsed.inHours >= 1) {
        whenLabel =
            '${elapsed.inHours} hour${elapsed.inHours == 1 ? '' : 's'} ago';
      } else {
        whenLabel = 'just now';
      }

      final targetLabel =
          ComplexityProfileService.getComplexityLevelTagline(latestShift.toLevel);
      insights.add(
          'Profile shifted to $targetLabel $whenLabel because ${latestShift.reason.toLowerCase()}');
    }

    return insights.where((insight) => insight.isNotEmpty).toList();
  }

  /// Get the effective complexity level (lived experience or static)
  ComplexityLevel getEffectiveComplexityLevel() {
    final assessment = getCurrentComplexityAssessment();
    return assessment?.getEffectiveComplexityLevel() ?? complexityProfile;
  }

  /// Check if the user's lived experience suggests a different complexity level
  bool hasComplexityProfileDiscrepancy() {
    final assessment = getCurrentComplexityAssessment();
    return assessment?.hasProfileDiscrepancy() ?? false;
  }

  /// Get recent tag frequency for complexity analysis
  Map<String, int> getRecentTagFrequency() {
    final assessment = getCurrentComplexityAssessment();
    return assessment?.recentTagFrequency ?? {};
  }

  /// Force a complexity analysis update
  Future<void> refreshComplexityAnalysis() async {
    _lastComplexityAnalysis = null; // Force refresh
    await _analyzeComplexityFromReflections();
  }

  /// Set smart input data for seamless page transitions
  void setPendingSmartInput(String text, String intent,
      {Map<String, dynamic>? metadata}) {
    _pendingSmartInputText = text;
    _pendingSmartInputIntent = intent;
    _pendingSmartInputMetadata = metadata ?? {};
    if (kDebugMode) {
      print('📝 Smart input set: "$text" → $intent');
    }
    // Don't notify listeners as this is just a data transfer mechanism
  }

  /// Get pending smart input data
  Map<String, dynamic>? getPendingSmartInput() {
    if (_pendingSmartInputText == null) return null;

    return {
      'text': _pendingSmartInputText!,
      'intent': _pendingSmartInputIntent!,
      'metadata': _pendingSmartInputMetadata ?? {},
    };
  }

  /// Clear smart input data (called after destination page uses it)
  void clearPendingSmartInput() {
    _pendingSmartInputText = null;
    _pendingSmartInputIntent = null;
    _pendingSmartInputMetadata = null;
    if (kDebugMode) {
      print('🧹 Smart input cleared');
    }
  }

  /// Persist a journal draft before navigation.
  void setPendingJournalDraft(String text, {Map<String, dynamic>? metadata}) {
    _pendingJournalDraftText = text;
    _pendingJournalDraftMetadata = metadata ?? {};
    if (kDebugMode) {
      print('📝 Journal draft set');
    }
  }

  /// Get pending journal draft data
  Map<String, dynamic>? getPendingJournalDraft() {
    if (_pendingJournalDraftText == null) return null;
    return {
      'text': _pendingJournalDraftText!,
      'metadata': _pendingJournalDraftMetadata ?? {},
    };
  }

  /// Clear pending journal draft
  void clearPendingJournalDraft() {
    _pendingJournalDraftText = null;
    _pendingJournalDraftMetadata = null;
    if (kDebugMode) {
      print('🧹 Journal draft cleared');
    }
  }

  /// Persist a routing draft while awaiting clarification.
  void setPendingRouterDraft(String text, {Map<String, dynamic>? metadata}) {
    _pendingRouterDraftText = text;
    _pendingRouterDraftMetadata = metadata ?? {};
    if (kDebugMode) {
      print('📝 Router draft set');
    }
  }

  /// Get pending routing draft data
  Map<String, dynamic>? getPendingRouterDraft() {
    if (_pendingRouterDraftText == null) return null;
    return {
      'text': _pendingRouterDraftText!,
      'metadata': _pendingRouterDraftMetadata ?? {},
    };
  }

  /// Clear pending routing draft
  void clearPendingRouterDraft() {
    _pendingRouterDraftText = null;
    _pendingRouterDraftMetadata = null;
    if (kDebugMode) {
      print('🧹 Router draft cleared');
    }
  }
}
