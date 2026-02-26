import 'package:flutter/material.dart';

// ============================================================================
// CO-OCCURRENCE MODEL
// ============================================================================

/// Co-occurring factor with a symptom
class CoOccurrence {
  final String factorKey;         // "high_stress", "skipped_meals", "poor_sleep"
  final String factorDisplay;     // "High stress", "Skipped meals"
  final int coOccurrenceCount;    // How many times they happened together
  final double correlation;       // 0.0 - 1.0 (percentage of times together)

  const CoOccurrence({
    required this.factorKey,
    required this.factorDisplay,
    required this.coOccurrenceCount,
    required this.correlation,
  });

  bool get isStrongCorrelation => correlation >= 0.6;
  bool get isModerateCorrelation => correlation >= 0.4 && correlation < 0.6;
  bool get isWeakCorrelation => correlation < 0.4;

  /// Get percentage display (e.g., "80%")
  String get correlationPercentage => '${(correlation * 100).round()}%';

  /// Get fraction display (e.g., "4/5 times")
  String get fractionDisplay {
    // Estimate total occurrences from count and correlation
    final total = (coOccurrenceCount / correlation).round();
    return '$coOccurrenceCount/$total times';
  }

  CoOccurrence copyWith({
    String? factorKey,
    String? factorDisplay,
    int? coOccurrenceCount,
    double? correlation,
  }) {
    return CoOccurrence(
      factorKey: factorKey ?? this.factorKey,
      factorDisplay: factorDisplay ?? this.factorDisplay,
      coOccurrenceCount: coOccurrenceCount ?? this.coOccurrenceCount,
      correlation: correlation ?? this.correlation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factorKey': factorKey,
      'factorDisplay': factorDisplay,
      'coOccurrenceCount': coOccurrenceCount,
      'correlation': correlation,
    };
  }

  factory CoOccurrence.fromJson(Map<String, dynamic> json) {
    return CoOccurrence(
      factorKey: json['factorKey'] ?? '',
      factorDisplay: json['factorDisplay'] ?? '',
      coOccurrenceCount: json['coOccurrenceCount'] ?? 0,
      correlation: (json['correlation'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() => 'CoOccurrence($factorDisplay: $correlationPercentage)';
}

// ============================================================================
// PATTERN INSIGHT MODEL
// ============================================================================

/// Detected health pattern across multiple journal entries
class PatternInsight {
  final String id;
  final DateTime createdAt;
  final DateTime startDate; // First entry in pattern
  final DateTime endDate;   // Most recent entry

  // Pattern details
  final String symptomKey;        // "headache", "fatigue", etc.
  final String symptomDisplay;    // "Headache", "Fatigue"
  final int occurrenceCount;      // How many times mentioned
  final int daySpan;              // Days between first and last

  // Co-occurring factors (what else happens when symptom occurs)
  final List<CoOccurrence> coOccurrences;

  // Generated insight
  final String insight;           // "You've mentioned headaches 5 times this week"
  final String possibleConnection; // "They seem to happen after stressful workdays"
  final List<String> suggestions; // Actionable steps

  // User interaction
  final bool isDismissed;
  final bool isBookmarked;
  final DateTime? dismissedAt;
  final DateTime? viewedAt;

  // Source entries
  final List<String> sourceEntryIds;

  const PatternInsight({
    required this.id,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.symptomKey,
    required this.symptomDisplay,
    required this.occurrenceCount,
    required this.daySpan,
    required this.coOccurrences,
    required this.insight,
    required this.possibleConnection,
    required this.suggestions,
    this.isDismissed = false,
    this.isBookmarked = false,
    this.dismissedAt,
    this.viewedAt,
    this.sourceEntryIds = const [],
  });

  /// Is this pattern significant enough to show?
  bool get isSignificant => occurrenceCount >= 3 && daySpan <= 14;

  /// Is this pattern recent (within last 7 days)?
  bool get isRecent => DateTime.now().difference(endDate).inDays <= 7;

  /// Should this pattern be shown to the user?
  bool get shouldShow => isSignificant && isRecent && !isDismissed;

  /// Get the strongest co-occurrence
  CoOccurrence? get strongestCorrelation {
    if (coOccurrences.isEmpty) return null;
    return coOccurrences.reduce((a, b) => a.correlation > b.correlation ? a : b);
  }

  /// Get all strong co-occurrences (>= 60% correlation)
  List<CoOccurrence> get strongCoOccurrences {
    return coOccurrences.where((c) => c.isStrongCorrelation).toList();
  }

  /// Get icon for this pattern
  IconData get icon {
    // Map symptom to appropriate icon
    switch (symptomKey) {
      case 'headache':
      case 'migraine':
        return Icons.psychology;
      case 'fatigue':
      case 'exhausted':
        return Icons.battery_1_bar;
      case 'pain':
      case 'back-pain':
      case 'joint-pain':
        return Icons.healing;
      case 'insomnia':
        return Icons.bedtime;
      case 'stress':
      case 'anxiety':
        return Icons.sentiment_dissatisfied;
      case 'nausea':
      case 'stomach-pain':
        return Icons.sick;
      default:
        return Icons.insights;
    }
  }

  /// Get color for this pattern
  Color get color {
    if (strongCoOccurrences.isNotEmpty) {
      return const Color(0xFFFF9800); // Orange - actionable insight
    }
    return const Color(0xFF2196F3); // Blue - informational
  }

  /// Generate the pattern summary text
  String get summaryText {
    if (daySpan <= 7) {
      return 'You\'ve mentioned $symptomDisplay $occurrenceCount times this week.';
    } else if (daySpan <= 14) {
      return 'You\'ve mentioned $symptomDisplay $occurrenceCount times in the last 2 weeks.';
    } else {
      return 'You\'ve mentioned $symptomDisplay $occurrenceCount times over $daySpan days.';
    }
  }

  /// Generate the correlation summary text
  String get correlationSummaryText {
    if (coOccurrences.isEmpty) {
      return 'No clear patterns detected yet.';
    }

    final strong = strongCoOccurrences;
    if (strong.isEmpty) {
      return 'Some possible connections, but no strong patterns yet.';
    }

    if (strong.length == 1) {
      return 'They seem to happen ${strong.first.factorDisplay.toLowerCase()} (${strong.first.fractionDisplay}).';
    }

    final factors = strong.take(2).map((c) => c.factorDisplay.toLowerCase()).toList();
    return 'They seem to happen with ${factors.join(' and ')}.';
  }

  PatternInsight copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    String? symptomKey,
    String? symptomDisplay,
    int? occurrenceCount,
    int? daySpan,
    List<CoOccurrence>? coOccurrences,
    String? insight,
    String? possibleConnection,
    List<String>? suggestions,
    bool? isDismissed,
    bool? isBookmarked,
    DateTime? dismissedAt,
    DateTime? viewedAt,
    List<String>? sourceEntryIds,
  }) {
    return PatternInsight(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      symptomKey: symptomKey ?? this.symptomKey,
      symptomDisplay: symptomDisplay ?? this.symptomDisplay,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      daySpan: daySpan ?? this.daySpan,
      coOccurrences: coOccurrences ?? this.coOccurrences,
      insight: insight ?? this.insight,
      possibleConnection: possibleConnection ?? this.possibleConnection,
      suggestions: suggestions ?? this.suggestions,
      isDismissed: isDismissed ?? this.isDismissed,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      viewedAt: viewedAt ?? this.viewedAt,
      sourceEntryIds: sourceEntryIds ?? this.sourceEntryIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'symptomKey': symptomKey,
      'symptomDisplay': symptomDisplay,
      'occurrenceCount': occurrenceCount,
      'daySpan': daySpan,
      'coOccurrences': coOccurrences.map((c) => c.toJson()).toList(),
      'insight': insight,
      'possibleConnection': possibleConnection,
      'suggestions': suggestions,
      'isDismissed': isDismissed,
      'isBookmarked': isBookmarked,
      'dismissedAt': dismissedAt?.toIso8601String(),
      'viewedAt': viewedAt?.toIso8601String(),
      'sourceEntryIds': sourceEntryIds,
    };
  }

  factory PatternInsight.fromJson(Map<String, dynamic> json) {
    return PatternInsight(
      id: json['id'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      symptomKey: json['symptomKey'] ?? '',
      symptomDisplay: json['symptomDisplay'] ?? '',
      occurrenceCount: json['occurrenceCount'] ?? 0,
      daySpan: json['daySpan'] ?? 0,
      coOccurrences: (json['coOccurrences'] as List<dynamic>? ?? [])
          .map((c) => CoOccurrence.fromJson(c))
          .toList(),
      insight: json['insight'] ?? '',
      possibleConnection: json['possibleConnection'] ?? '',
      suggestions: List<String>.from(json['suggestions'] ?? []),
      isDismissed: json['isDismissed'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
      dismissedAt: json['dismissedAt'] != null
          ? DateTime.tryParse(json['dismissedAt'])
          : null,
      viewedAt: json['viewedAt'] != null
          ? DateTime.tryParse(json['viewedAt'])
          : null,
      sourceEntryIds: List<String>.from(json['sourceEntryIds'] ?? []),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternInsight && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PatternInsight($symptomKey: $occurrenceCount occurrences)';
}

// ============================================================================
// PATTERN SUGGESTION TEMPLATES
// ============================================================================

/// Templates for generating pattern suggestions
class PatternSuggestions {
  PatternSuggestions._();

  /// Get suggestions for a symptom with its co-occurrences
  static List<String> getSuggestionsFor({
    required String symptomKey,
    required List<CoOccurrence> coOccurrences,
  }) {
    final suggestions = <String>[];

    // Add symptom-specific suggestions
    suggestions.addAll(_getSymptomSuggestions(symptomKey));

    // Add co-occurrence-specific suggestions
    for (final coOccurrence in coOccurrences.where((c) => c.isStrongCorrelation)) {
      suggestions.addAll(_getCoOccurrenceSuggestions(coOccurrence.factorKey));
    }

    // Always suggest GP if pattern persists
    suggestions.add('Talk to a GP if this pattern continues for another week');

    // Remove duplicates and limit
    return suggestions.toSet().take(4).toList();
  }

  static List<String> _getSymptomSuggestions(String symptomKey) {
    switch (symptomKey) {
      case 'headache':
      case 'migraine':
        return [
          'Keep water nearby and stay hydrated',
          'Take regular screen breaks (20-20-20 rule)',
          'Track when headaches start to identify triggers',
        ];
      case 'fatigue':
      case 'exhausted':
        return [
          'Aim for consistent sleep and wake times',
          'Check if you\'re eating regular meals',
          'Consider a short walk for an energy boost',
        ];
      case 'insomnia':
        return [
          'Try reducing screen time 1 hour before bed',
          'Keep your bedroom cool and dark',
          'Consider a wind-down routine',
        ];
      case 'stress':
      case 'anxiety':
        return [
          'Try 5 minutes of deep breathing',
          'Write down your main worry to process it',
          'Reach out to someone you trust',
        ];
      case 'pain':
      case 'back-pain':
      case 'joint-pain':
        return [
          'Gentle stretching may help relieve tension',
          'Check your posture at work/home',
          'Consider heat or ice therapy',
        ];
      default:
        return [
          'Track when symptoms occur to identify patterns',
          'Note what makes it better or worse',
        ];
    }
  }

  static List<String> _getCoOccurrenceSuggestions(String factorKey) {
    switch (factorKey) {
      case 'high_stress':
        return [
          'Try stress-reducing activities during the day',
          'Schedule short breaks between tasks',
        ];
      case 'skipped_meals':
        return [
          'Keep snacks at work or in your bag',
          'Set meal reminders if you tend to forget',
        ];
      case 'poor_sleep':
        return [
          'Prioritize getting to bed at a consistent time',
          'Reduce caffeine after midday',
        ];
      case 'low_energy':
        return [
          'Check if you\'re getting enough protein',
          'A short walk can boost energy naturally',
        ];
      case 'high_pain':
        return [
          'Consider keeping a pain diary for your GP',
          'Explore gentle movement options',
        ];
      default:
        return [];
    }
  }

  /// Get a possible connection phrase for co-occurrences
  static String getPossibleConnection({
    required String symptomKey,
    required List<CoOccurrence> coOccurrences,
  }) {
    if (coOccurrences.isEmpty) {
      return 'No clear patterns detected yet.';
    }

    final strong = coOccurrences.where((c) => c.isStrongCorrelation).toList();
    if (strong.isEmpty) {
      return 'Some possible connections, but more data needed.';
    }

    // Build connection phrase based on factors
    final factors = strong.take(2).map((c) {
      switch (c.factorKey) {
        case 'high_stress':
          return 'stressful days';
        case 'skipped_meals':
          return 'skipped meals';
        case 'poor_sleep':
          return 'poor sleep';
        case 'low_energy':
          return 'low energy days';
        case 'high_pain':
          return 'high pain days';
        default:
          return c.factorDisplay.toLowerCase();
      }
    }).toList();

    if (factors.length == 1) {
      return 'Possible connection: ${factors.first}?';
    }

    return 'Possible connection: ${factors.join(' + ')}?';
  }
}
