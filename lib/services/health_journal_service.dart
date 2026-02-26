import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_journal_model.dart';
import '../models/pattern_insight_model.dart';
import 'health_tagging_service.dart';
import 'pattern_detection_service.dart';

/// Service for managing health journal entries
/// Handles CRUD operations, persistence, and pattern detection integration
class HealthJournalService {
  static final HealthJournalService _instance = HealthJournalService._internal();
  factory HealthJournalService() => _instance;
  HealthJournalService._internal();

  static const String _entriesKey = 'health_journal_entries';
  static const String _draftKey = 'health_journal_draft';
  static const String _insightsKey = 'health_pattern_insights';

  final HealthTaggingService _taggingService = HealthTaggingService();
  final PatternDetectionService _patternService = PatternDetectionService();

  SharedPreferences? _prefs;
  List<HealthJournalEntry> _entries = [];
  List<PatternInsight> _insights = [];
  HealthJournalEntry? _currentDraft;

  bool _isInitialized = false;

  /// Initialize the service and load persisted data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadEntries();
      await _loadInsights();
      await _loadDraft();
      _isInitialized = true;
      debugPrint('HealthJournalService: Initialized with ${_entries.length} entries');
    } catch (e) {
      debugPrint('HealthJournalService: Error initializing: $e');
    }
  }

  /// Get all entries (sorted by timestamp, newest first)
  List<HealthJournalEntry> get entries {
    final sorted = List<HealthJournalEntry>.from(_entries);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  /// Get all pattern insights (not dismissed)
  List<PatternInsight> get activeInsights {
    return _insights.where((i) => !i.isDismissed && i.shouldShow).toList();
  }

  /// Get current draft entry
  HealthJournalEntry? get currentDraft => _currentDraft;

  /// Get today's entry (if exists)
  HealthJournalEntry? getTodayEntry() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    return _entries.firstWhere(
      (e) {
        final entryDate = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
        return entryDate == todayStart && !e.isDraft;
      },
      orElse: () => HealthJournalEntry.today(),
    );
  }

  /// Get entries for a date range
  List<HealthJournalEntry> getEntriesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _entries.where((e) {
      return e.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
             e.timestamp.isBefore(endDate.add(const Duration(days: 1))) &&
             !e.isDraft;
    }).toList();
  }

  /// Get entries by health tag
  List<HealthJournalEntry> getEntriesByTag(String tagKey) {
    return _entries.where((e) =>
      e.healthTags.any((t) => t.canonicalKey == tagKey) && !e.isDraft
    ).toList();
  }

  /// Get entries mentioning a symptom
  List<HealthJournalEntry> getEntriesBySymptom(String symptomKey) {
    return _entries.where((e) =>
      e.mentionsSymptom(symptomKey) && !e.isDraft
    ).toList();
  }

  /// Create or update a journal entry
  Future<HealthJournalEntry> saveEntry({
    String? id,
    required HealthCheckIn checkIn,
    List<SymptomTracking> symptoms = const [],
    String? journalText,
    bool isDraft = false,
  }) async {
    await initialize();

    final now = DateTime.now();
    final existingIndex = id != null
        ? _entries.indexWhere((e) => e.id == id)
        : -1;

    // Extract health tags from the entry
    final healthTags = await _taggingService.extractHealthTags(
      text: journalText,
      checkIn: checkIn,
      symptoms: symptoms,
    );

    HealthJournalEntry entry;

    if (existingIndex >= 0) {
      // Update existing entry
      final existing = _entries[existingIndex];
      entry = existing.copyWith(
        checkIn: checkIn,
        symptoms: symptoms,
        journalText: journalText,
        healthTags: healthTags,
        isProcessed: true,
        isDraft: isDraft,
        updatedAt: now,
      );
      _entries[existingIndex] = entry;
    } else {
      // Create new entry
      entry = HealthJournalEntry(
        id: id ?? 'entry_${now.millisecondsSinceEpoch}',
        timestamp: now,
        createdAt: now,
        updatedAt: now,
        checkIn: checkIn,
        symptoms: symptoms,
        journalText: journalText,
        healthTags: healthTags,
        isProcessed: true,
        isDraft: isDraft,
      );
      _entries.add(entry);
    }

    // Persist
    await _saveEntries();

    // Clear draft if saving a non-draft entry
    if (!isDraft) {
      _currentDraft = null;
      await _clearDraft();

      // Trigger pattern detection in background
      _detectPatternsAsync();
    }

    debugPrint('HealthJournalService: Saved entry ${entry.id} with ${healthTags.length} tags');

    return entry;
  }

  /// Save current entry as draft
  Future<void> saveDraft(HealthJournalEntry draft) async {
    await initialize();

    _currentDraft = draft.copyWith(isDraft: true);
    await _persistDraft();

    debugPrint('HealthJournalService: Saved draft');
  }

  /// Delete a journal entry
  Future<bool> deleteEntry(String id) async {
    await initialize();

    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0) return false;

    _entries.removeAt(index);
    await _saveEntries();

    debugPrint('HealthJournalService: Deleted entry $id');
    return true;
  }

  /// Dismiss a pattern insight
  Future<void> dismissInsight(String insightId) async {
    await initialize();

    final index = _insights.indexWhere((i) => i.id == insightId);
    if (index < 0) return;

    _insights[index] = _insights[index].copyWith(
      isDismissed: true,
      dismissedAt: DateTime.now(),
    );

    await _saveInsights();

    debugPrint('HealthJournalService: Dismissed insight $insightId');
  }

  /// Bookmark a pattern insight
  Future<void> bookmarkInsight(String insightId) async {
    await initialize();

    final index = _insights.indexWhere((i) => i.id == insightId);
    if (index < 0) return;

    _insights[index] = _insights[index].copyWith(
      isBookmarked: !_insights[index].isBookmarked,
    );

    await _saveInsights();
  }

  /// Force pattern detection (on-demand)
  Future<List<PatternInsight>> detectPatterns() async {
    await initialize();

    final newInsights = await _patternService.detectPatterns(entries: _entries);

    // Merge with existing insights (don't duplicate)
    for (final insight in newInsights) {
      final existingIndex = _insights.indexWhere((i) =>
        i.symptomKey == insight.symptomKey &&
        !i.isDismissed &&
        i.endDate.difference(insight.endDate).inDays.abs() <= 3
      );

      if (existingIndex >= 0) {
        // Update existing insight
        _insights[existingIndex] = insight.copyWith(
          id: _insights[existingIndex].id,
          viewedAt: _insights[existingIndex].viewedAt,
        );
      } else {
        // Add new insight
        _insights.add(insight);
      }
    }

    await _saveInsights();

    debugPrint('HealthJournalService: Detected ${newInsights.length} patterns');

    return newInsights;
  }

  /// Check if any patterns should be shown
  bool hasPatternInsights() {
    return activeInsights.isNotEmpty;
  }

  /// Get symptom summary for quick stats
  Map<String, int> getSymptomSummary() {
    return _patternService.getSymptomSummary(_entries);
  }

  // ============================================================================
  // PRIVATE METHODS - PERSISTENCE
  // ============================================================================

  Future<void> _loadEntries() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final jsonString = prefs.getString(_entriesKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _entries = jsonList
            .map((json) => HealthJournalEntry.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('HealthJournalService: Error loading entries: $e');
      _entries = [];
    }
  }

  Future<void> _saveEntries() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final jsonList = _entries.map((e) => e.toJson()).toList();
      await prefs.setString(_entriesKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('HealthJournalService: Error saving entries: $e');
    }
  }

  Future<void> _loadInsights() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final jsonString = prefs.getString(_insightsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _insights = jsonList
            .map((json) => PatternInsight.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('HealthJournalService: Error loading insights: $e');
      _insights = [];
    }
  }

  Future<void> _saveInsights() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final jsonList = _insights.map((i) => i.toJson()).toList();
      await prefs.setString(_insightsKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('HealthJournalService: Error saving insights: $e');
    }
  }

  Future<void> _loadDraft() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      final jsonString = prefs.getString(_draftKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _currentDraft = HealthJournalEntry.fromJson(json);
      }
    } catch (e) {
      debugPrint('HealthJournalService: Error loading draft: $e');
      _currentDraft = null;
    }
  }

  Future<void> _persistDraft() async {
    final prefs = _prefs;
    if (prefs == null || _currentDraft == null) return;

    try {
      await prefs.setString(_draftKey, jsonEncode(_currentDraft!.toJson()));
    } catch (e) {
      debugPrint('HealthJournalService: Error saving draft: $e');
    }
  }

  Future<void> _clearDraft() async {
    final prefs = _prefs;
    if (prefs == null) return;

    try {
      await prefs.remove(_draftKey);
    } catch (e) {
      debugPrint('HealthJournalService: Error clearing draft: $e');
    }
  }

  /// Detect patterns asynchronously (after saving an entry)
  void _detectPatternsAsync() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await detectPatterns();
      } catch (e) {
        debugPrint('HealthJournalService: Error in async pattern detection: $e');
      }
    });
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    await initialize();

    _entries.clear();
    _insights.clear();
    _currentDraft = null;

    final prefs = _prefs;
    if (prefs != null) {
      await prefs.remove(_entriesKey);
      await prefs.remove(_insightsKey);
      await prefs.remove(_draftKey);
    }

    debugPrint('HealthJournalService: Cleared all data');
  }
}
