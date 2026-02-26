import 'package:flutter/foundation.dart';
import '../models/health_journal_model.dart';
import '../models/pattern_insight_model.dart';

/// Service for detecting health patterns across journal entries
class PatternDetectionService {
  static final PatternDetectionService _instance = PatternDetectionService._internal();
  factory PatternDetectionService() => _instance;
  PatternDetectionService._internal();

  /// Minimum occurrences needed to consider a pattern
  static const int minOccurrences = 3;

  /// Maximum day window to analyze for patterns
  static const int defaultDayWindow = 14;

  /// Minimum correlation to consider significant
  static const double minCorrelation = 0.5;

  /// Detect patterns in journal entries
  Future<List<PatternInsight>> detectPatterns({
    required List<HealthJournalEntry> entries,
    int dayWindow = defaultDayWindow,
  }) async {
    if (entries.length < minOccurrences) {
      debugPrint('PatternDetectionService: Not enough entries for pattern detection (${entries.length} < $minOccurrences)');
      return [];
    }

    // Filter to recent entries within the day window
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(days: dayWindow));
    final recentEntries = entries.where((e) =>
      e.timestamp.isAfter(windowStart) && !e.isDraft
    ).toList();

    if (recentEntries.length < minOccurrences) {
      debugPrint('PatternDetectionService: Not enough recent entries (${recentEntries.length} < $minOccurrences)');
      return [];
    }

    debugPrint('PatternDetectionService: Analyzing ${recentEntries.length} entries over $dayWindow days');

    // Find symptoms/tags that appear frequently
    final symptomCounts = _countSymptomOccurrences(recentEntries);

    // Generate insights for significant patterns
    final insights = <PatternInsight>[];

    for (final entry in symptomCounts.entries) {
      final symptomKey = entry.key;
      final count = entry.value;

      // Only analyze if meets minimum threshold
      if (count >= minOccurrences) {
        final insight = await _analyzeSymptomPattern(
          symptomKey: symptomKey,
          entries: recentEntries,
          totalOccurrences: count,
        );

        if (insight != null) {
          insights.add(insight);
        }
      }
    }

    // Sort by occurrence count (most frequent first)
    insights.sort((a, b) => b.occurrenceCount.compareTo(a.occurrenceCount));

    debugPrint('PatternDetectionService: Found ${insights.length} significant patterns');

    return insights;
  }

  /// Count occurrences of each symptom/health tag
  Map<String, int> _countSymptomOccurrences(List<HealthJournalEntry> entries) {
    final counts = <String, int>{};

    for (final entry in entries) {
      // Count from symptom tracking
      for (final symptom in entry.symptoms) {
        counts[symptom.symptomType] = (counts[symptom.symptomType] ?? 0) + 1;
      }

      // Count from health tags (physical symptoms and mental/emotional)
      for (final tag in entry.healthTags) {
        if (tag.category == HealthTagCategory.physicalSymptom ||
            tag.category == HealthTagCategory.mentalEmotional) {
          counts[tag.canonicalKey] = (counts[tag.canonicalKey] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  /// Analyze a specific symptom pattern
  Future<PatternInsight?> _analyzeSymptomPattern({
    required String symptomKey,
    required List<HealthJournalEntry> entries,
    required int totalOccurrences,
  }) async {
    // Find entries where this symptom occurs
    final symptomEntries = entries.where((e) => e.mentionsSymptom(symptomKey)).toList();

    if (symptomEntries.isEmpty) return null;

    // Sort by timestamp
    symptomEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final startDate = symptomEntries.first.timestamp;
    final endDate = symptomEntries.last.timestamp;
    final daySpan = endDate.difference(startDate).inDays + 1;

    // Find co-occurring factors
    final coOccurrences = _findCoOccurrences(
      symptomEntries: symptomEntries,
      allEntries: entries,
    );

    // Generate insight text
    final symptomDisplay = HealthTagTaxonomy.getDisplayName(symptomKey);
    final insight = _generateInsightText(symptomDisplay, totalOccurrences, daySpan);
    final possibleConnection = PatternSuggestions.getPossibleConnection(
      symptomKey: symptomKey,
      coOccurrences: coOccurrences,
    );
    final suggestions = PatternSuggestions.getSuggestionsFor(
      symptomKey: symptomKey,
      coOccurrences: coOccurrences,
    );

    return PatternInsight(
      id: 'pattern_${symptomKey}_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      symptomKey: symptomKey,
      symptomDisplay: symptomDisplay,
      occurrenceCount: totalOccurrences,
      daySpan: daySpan,
      coOccurrences: coOccurrences,
      insight: insight,
      possibleConnection: possibleConnection,
      suggestions: suggestions,
      sourceEntryIds: symptomEntries.map((e) => e.id).toList(),
    );
  }

  /// Find factors that co-occur with the symptom
  List<CoOccurrence> _findCoOccurrences({
    required List<HealthJournalEntry> symptomEntries,
    required List<HealthJournalEntry> allEntries,
  }) {
    final coOccurrences = <CoOccurrence>[];
    final symptomCount = symptomEntries.length;

    // Define factors to check
    final factorChecks = <String, bool Function(HealthJournalEntry)>{
      'high_stress': (e) => (e.checkIn.stressLevel ?? 0) >= 4,
      'poor_sleep': (e) => (e.checkIn.sleepQuality ?? 5) <= 2,
      'low_energy': (e) => (e.checkIn.energy ?? 5) <= 2,
      'high_pain': (e) => (e.checkIn.painLevel ?? 0) >= 3,
      'skipped_meals': (e) => e.checkIn.ateRegularMeals == MealStatus.no,
      'low_mood': (e) => (e.checkIn.mood ?? 5) <= 2,
      'high_anxiety': (e) => (e.checkIn.anxietyLevel ?? 0) >= 4,
    };

    final factorDisplayNames = <String, String>{
      'high_stress': 'High stress',
      'poor_sleep': 'Poor sleep',
      'low_energy': 'Low energy',
      'high_pain': 'High pain levels',
      'skipped_meals': 'Skipped meals',
      'low_mood': 'Low mood',
      'high_anxiety': 'High anxiety',
    };

    // Check each factor
    for (final entry in factorChecks.entries) {
      final factorKey = entry.key;
      final checkFn = entry.value;

      // Count how many symptom entries have this factor
      int coOccurrenceCount = 0;
      for (final symptomEntry in symptomEntries) {
        if (checkFn(symptomEntry)) {
          coOccurrenceCount++;
        }
      }

      if (coOccurrenceCount > 0) {
        final correlation = coOccurrenceCount / symptomCount;

        // Only include if correlation is significant
        if (correlation >= minCorrelation) {
          coOccurrences.add(CoOccurrence(
            factorKey: factorKey,
            factorDisplay: factorDisplayNames[factorKey] ?? factorKey,
            coOccurrenceCount: coOccurrenceCount,
            correlation: correlation,
          ));
        }
      }
    }

    // Also check for co-occurring tags (life context, barriers)
    final tagCoOccurrences = _findTagCoOccurrences(symptomEntries);
    coOccurrences.addAll(tagCoOccurrences);

    // Sort by correlation (strongest first)
    coOccurrences.sort((a, b) => b.correlation.compareTo(a.correlation));

    // Limit to top 5 factors
    return coOccurrences.take(5).toList();
  }

  /// Find tag-based co-occurrences
  List<CoOccurrence> _findTagCoOccurrences(List<HealthJournalEntry> symptomEntries) {
    final coOccurrences = <CoOccurrence>[];
    final symptomCount = symptomEntries.length;

    // Count tag occurrences across symptom entries
    final tagCounts = <String, int>{};

    for (final entry in symptomEntries) {
      for (final tag in entry.healthTags) {
        // Only count life context and barrier tags as co-occurring factors
        if (tag.category == HealthTagCategory.lifeContext ||
            tag.category == HealthTagCategory.barrier) {
          tagCounts[tag.canonicalKey] = (tagCounts[tag.canonicalKey] ?? 0) + 1;
        }
      }
    }

    // Convert counts to co-occurrences
    for (final entry in tagCounts.entries) {
      final tagKey = entry.key;
      final count = entry.value;
      final correlation = count / symptomCount;

      if (correlation >= minCorrelation) {
        coOccurrences.add(CoOccurrence(
          factorKey: tagKey,
          factorDisplay: HealthTagTaxonomy.getDisplayName(tagKey),
          coOccurrenceCount: count,
          correlation: correlation,
        ));
      }
    }

    return coOccurrences;
  }

  /// Generate insight text based on pattern
  String _generateInsightText(String symptomDisplay, int count, int daySpan) {
    if (daySpan <= 7) {
      return 'You\'ve mentioned $symptomDisplay $count times this week.';
    } else if (daySpan <= 14) {
      return 'You\'ve mentioned $symptomDisplay $count times in the last 2 weeks.';
    } else {
      return 'You\'ve mentioned $symptomDisplay $count times over $daySpan days.';
    }
  }

  /// Analyze patterns for a single symptom (public API for on-demand analysis)
  Future<PatternInsight?> analyzeSymptomPattern({
    required String symptomKey,
    required List<HealthJournalEntry> entries,
  }) async {
    // Filter to entries that mention this symptom
    final symptomEntries = entries.where((e) => e.mentionsSymptom(symptomKey)).toList();

    if (symptomEntries.length < minOccurrences) {
      return null;
    }

    return _analyzeSymptomPattern(
      symptomKey: symptomKey,
      entries: entries,
      totalOccurrences: symptomEntries.length,
    );
  }

  /// Get a quick summary of patterns without full analysis
  Map<String, int> getSymptomSummary(List<HealthJournalEntry> entries) {
    return _countSymptomOccurrences(entries);
  }

  /// Check if any significant patterns exist
  bool hasSignificantPatterns(List<HealthJournalEntry> entries) {
    final counts = _countSymptomOccurrences(entries);
    return counts.values.any((count) => count >= minOccurrences);
  }
}
