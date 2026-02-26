
/// Contextual suggestion for user actions
class ContextualSuggestion {
  final String id;
  final String title;
  final String description;
  final String actionText;
  final String category; // 'immediate', 'daily', 'weekly'
  final double relevanceScore;
  final List<String> triggerTagKeys;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const ContextualSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.actionText,
    required this.category,
    required this.relevanceScore,
    required this.triggerTagKeys,
    this.metadata = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'actionText': actionText,
        'category': category,
        'relevanceScore': relevanceScore,
        'triggerTagKeys': triggerTagKeys,
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
      };

  bool get isHighRelevance => relevanceScore >= 0.8;
  bool get isImmediate => category == 'immediate';
}

/// Canonical ontology categories for smart tagging
enum TagCategory {
  choice, // User actions and decisions
  chance, // External circumstances
  outcome // Resulting states and feelings
}

/// Confidence level for tag classification
enum ConfidenceLevel {
  low, // 0.0 - 0.4
  medium, // 0.4 - 0.7
  high // 0.7 - 1.0
}

/// Smart tag with canonical ontology classification
class SmartTag {
  final String id;
  final String canonicalKey; // Canonical tag key (e.g., 'daily_movement')
  final String displayName; // Human-readable name (e.g., 'Daily Movement')
  final TagCategory category; // Choice/Chance/Outcome
  final String
      subdomain; // Subdomain within category (e.g., 'Physical Activity')
  final double confidence; // 0.0 - 1.0 confidence score
  final String? evidenceSpan; // Extracted text span that supports this tag
  final Map<String, dynamic> metadata; // Additional context
  final DateTime createdAt;

  // Sentiment and analysis
  final String sentiment; // 'positive', 'negative', 'neutral'
  final double sentimentConfidence;
  final List<String> keywords; // Supporting keywords
  final bool hasNegation; // Contains negation (e.g., "didn't exercise")
  final bool hasUncertainty; // Contains uncertainty (e.g., "maybe", "might")

  const SmartTag({
    required this.id,
    required this.canonicalKey,
    required this.displayName,
    required this.category,
    required this.subdomain,
    required this.confidence,
    this.evidenceSpan,
    this.metadata = const {},
    required this.createdAt,
    this.sentiment = 'neutral',
    this.sentimentConfidence = 0.0,
    this.keywords = const [],
    this.hasNegation = false,
    this.hasUncertainty = false,
  });

  // Computed properties
  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.7) return ConfidenceLevel.high;
    if (confidence >= 0.4) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  bool get isChoice => category == TagCategory.choice;
  bool get isChance => category == TagCategory.chance;
  bool get isOutcome => category == TagCategory.outcome;

  bool get isPositive => sentiment == 'positive';
  bool get isNegative => sentiment == 'negative';
  bool get isNeutral => sentiment == 'neutral';

  bool get isHighConfidence => confidence >= 0.7;
  bool get isMediumConfidence => confidence >= 0.4 && confidence < 0.7;
  bool get isLowConfidence => confidence < 0.4;

  /// Get emoji representation for category
  String get categoryEmoji {
    switch (category) {
      case TagCategory.choice:
        return '💪'; // User actions
      case TagCategory.chance:
        return '🎯'; // External circumstances
      case TagCategory.outcome:
        return '📊'; // Resulting states
    }
  }

  /// Get color representation for category
  String get categoryColor {
    switch (category) {
      case TagCategory.choice:
        return '#4CAF50'; // Green - positive actions
      case TagCategory.chance:
        return '#FF9800'; // Orange - external factors
      case TagCategory.outcome:
        return '#2196F3'; // Blue - outcomes/states
    }
  }

  /// Factory constructor for creating from AI classification
  factory SmartTag.fromAIClassification({
    required String canonicalKey,
    required String displayName,
    required TagCategory category,
    required String subdomain,
    required double confidence,
    String? evidenceSpan,
    Map<String, dynamic> metadata = const {},
    String sentiment = 'neutral',
    double sentimentConfidence = 0.0,
    List<String> keywords = const [],
    bool hasNegation = false,
    bool hasUncertainty = false,
  }) {
    return SmartTag(
      id: '${DateTime.now().millisecondsSinceEpoch}_${canonicalKey}',
      canonicalKey: canonicalKey,
      displayName: displayName,
      category: category,
      subdomain: subdomain,
      confidence: confidence,
      evidenceSpan: evidenceSpan,
      metadata: metadata,
      createdAt: DateTime.now(),
      sentiment: sentiment,
      sentimentConfidence: sentimentConfidence,
      keywords: keywords,
      hasNegation: hasNegation,
      hasUncertainty: hasUncertainty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canonicalKey': canonicalKey,
      'displayName': displayName,
      'category': category.name,
      'subdomain': subdomain,
      'confidence': confidence,
      'evidenceSpan': evidenceSpan,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'sentiment': sentiment,
      'sentimentConfidence': sentimentConfidence,
      'keywords': keywords,
      'hasNegation': hasNegation,
      'hasUncertainty': hasUncertainty,
    };
  }

  factory SmartTag.fromJson(Map<String, dynamic> json) {
    return SmartTag(
      id: json['id'] ?? '',
      canonicalKey: json['canonicalKey'] ?? '',
      displayName: json['displayName'] ?? '',
      category: TagCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TagCategory.choice,
      ),
      subdomain: json['subdomain'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      evidenceSpan: json['evidenceSpan'],
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      sentiment: json['sentiment'] ?? 'neutral',
      sentimentConfidence: (json['sentimentConfidence'] ?? 0.0).toDouble(),
      keywords: List<String>.from(json['keywords'] ?? []),
      hasNegation: json['hasNegation'] ?? false,
      hasUncertainty: json['hasUncertainty'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartTag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SmartTag($canonicalKey: $displayName [$confidence])';
}

/// Enhanced journal entry with smart tagging
class SmartJournalEntry {
  final String id;
  final String originalText;
  final DateTime timestamp;
  final List<SmartTag> smartTags;
  final double averageConfidence;
  final Map<String, dynamic> metadata;
  final bool isProcessed;

  // Follow-up system
  final List<FollowUpQuestion> followUpQuestions;
  final Map<String, String> followUpResponses; // questionId -> response
  final bool hasFollowUpPending;
  final int dailyFollowUpCount; // Track daily limit

  // Nudge integration
  final List<String> recommendedNudgeIds;
  final bool hasNudgeRecommendations;

  const SmartJournalEntry({
    required this.id,
    required this.originalText,
    required this.timestamp,
    required this.smartTags,
    required this.averageConfidence,
    this.metadata = const {},
    this.isProcessed = false,
    this.followUpQuestions = const [],
    this.followUpResponses = const {},
    this.hasFollowUpPending = false,
    this.dailyFollowUpCount = 0,
    this.recommendedNudgeIds = const [],
    this.hasNudgeRecommendations = false,
  });

  // Computed properties
  int get tagCount => smartTags.length;
  bool get hasHighConfidence => averageConfidence >= 0.7;
  int get choiceCount => smartTags.where((t) => t.isChoice).length;
  int get chanceCount => smartTags.where((t) => t.isChance).length;
  int get outcomeCount => smartTags.where((t) => t.isOutcome).length;
  bool get hasSmartTags => smartTags.isNotEmpty;

  // Get unique canonical keys that were detected
  List<String> get detectedCanonicalKeys =>
      smartTags.map((t) => t.canonicalKey).toSet().toList();

  // Get tags by category
  List<SmartTag> get choiceTags => smartTags.where((t) => t.isChoice).toList();
  List<SmartTag> get chanceTags => smartTags.where((t) => t.isChance).toList();
  List<SmartTag> get outcomeTags =>
      smartTags.where((t) => t.isOutcome).toList();

  // Get high confidence tags
  List<SmartTag> get highConfidenceTags =>
      smartTags.where((t) => t.isHighConfidence).toList();

  // Get summary of what was detected
  String get summary {
    if (smartTags.isEmpty) return 'No tags detected';

    final tags = smartTags.map((t) => t.displayName).toSet().toList();
    if (tags.isEmpty) return 'No tags detected';
    if (tags.length == 1) return tags.first;
    if (tags.length == 2) return '${tags[0]} and ${tags[1]}';
    return '${tags.take(tags.length - 1).join(', ')} and ${tags.last}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'timestamp': timestamp.toIso8601String(),
      'smartTags': smartTags.map((t) => t.toJson()).toList(),
      'averageConfidence': averageConfidence,
      'metadata': metadata,
      'isProcessed': isProcessed,
      'followUpQuestions': followUpQuestions.map((q) => q.toJson()).toList(),
      'followUpResponses': followUpResponses,
      'hasFollowUpPending': hasFollowUpPending,
      'dailyFollowUpCount': dailyFollowUpCount,
      'recommendedNudgeIds': recommendedNudgeIds,
      'hasNudgeRecommendations': hasNudgeRecommendations,
    };
  }

  factory SmartJournalEntry.fromJson(Map<String, dynamic> json) {
    return SmartJournalEntry(
      id: json['id'] ?? '',
      originalText: json['originalText'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      smartTags: (json['smartTags'] as List<dynamic>? ?? [])
          .map((item) => SmartTag.fromJson(item as Map<String, dynamic>))
          .toList(),
      averageConfidence: (json['averageConfidence'] ?? 0.0).toDouble(),
      metadata: json['metadata'] ?? {},
      isProcessed: json['isProcessed'] ?? false,
      followUpQuestions: (json['followUpQuestions'] as List<dynamic>? ?? [])
          .map(
              (item) => FollowUpQuestion.fromJson(item as Map<String, dynamic>))
          .toList(),
      followUpResponses:
          Map<String, String>.from(json['followUpResponses'] ?? {}),
      hasFollowUpPending: json['hasFollowUpPending'] ?? false,
      dailyFollowUpCount: json['dailyFollowUpCount'] ?? 0,
      recommendedNudgeIds: List<String>.from(json['recommendedNudgeIds'] ?? []),
      hasNudgeRecommendations: json['hasNudgeRecommendations'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartJournalEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SmartJournalEntry($id: "$originalText")';
}

/// Follow-up question model for semi-interactive journaling
class FollowUpQuestion {
  final String id;
  final String question;
  final String triggerTagKey; // The canonical tag that triggered this question
  final QuestionType type;
  final List<String> suggestedResponses; // For multiple choice
  final bool isOptional;
  final int priority; // Higher number = higher priority
  final DateTime createdAt;
  final DateTime? expiresAt; // Optional expiration

  const FollowUpQuestion({
    required this.id,
    required this.question,
    required this.triggerTagKey,
    required this.type,
    this.suggestedResponses = const [],
    this.isOptional = true,
    this.priority = 1,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isMultipleChoice => type == QuestionType.multipleChoice;
  bool get isOpenText => type == QuestionType.openText;
  bool get isScale => type == QuestionType.scale;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'triggerTagKey': triggerTagKey,
      'type': type.name,
      'suggestedResponses': suggestedResponses,
      'isOptional': isOptional,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory FollowUpQuestion.fromJson(Map<String, dynamic> json) {
    return FollowUpQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      triggerTagKey: json['triggerTagKey'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.openText,
      ),
      suggestedResponses: List<String>.from(json['suggestedResponses'] ?? []),
      isOptional: json['isOptional'] ?? true,
      priority: json['priority'] ?? 1,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
    );
  }

  @override
  String toString() => 'FollowUpQuestion($triggerTagKey: "$question")';
}

/// Types of follow-up questions
enum QuestionType {
  openText, // Free text response
  multipleChoice, // Select from options
  scale // 1-5 or 1-10 scale
}

/// Canonical ontology definition with subdomains
class CanonicalOntology {
  static const Map<String, Map<String, List<String>>> structure = {
    'choice': {
      'Movement & Energy': ['movement_boost', 'energy_plan', 'rest_day'],
      'Mindful Reset': [
        'mindful_break',
        'breathing_reset',
        'digital_detox',
        'reset_routine'
      ],
      'Nourish & Restore': [
        'balanced_meal',
        'hydration_reset',
        'sleep_hygiene',
        'self_compassion'
      ],
      'Connection & Joy': [
        'social_checkin',
        'gratitude_moment',
        'creative_play'
      ],
      'Focus & Progress': ['focus_sprint'],
    },
    'chance': {
      'Day Dynamics': [
        'busy_day',
        'time_pressure',
        'deadline_mode',
        'unexpected_event'
      ],
      'Environment & Travel': [
        'travel_disruption',
        'workspace_shift',
        'weather_slump',
        'nature_time'
      ],
      'Support Context': ['supportive_chat', 'family_duty'],
      'Temporal Lens': ['morning_check', 'midday_reset', 'evening_reflection'],
    },
    'outcome': {
      'Emotional State': [
        'calm_grounded',
        'hopeful',
        'relief',
        'balanced',
        'overwhelmed',
        'lonely',
        'anxious_underlying'
      ],
      'Energy & Body': ['energized', 'drained', 'restless', 'foggy'],
      'Momentum & Pride': [
        'proud_progress',
        'micro_win',
        'setback',
        'learning',
        'habit_chain',
        'first_step'
      ],
      'Needs & Signals': [
        'need_rest',
        'need_connection',
        'need_fuel',
        'need_clarity'
      ],
    },
  };

  static const Map<String, String> _displayNameOverrides = {
    'calm_grounded': 'Calm & Grounded',
    'hydration_reset': 'Hydration Reset',
    'sleep_hygiene': 'Sleep Hygiene',
    'focus_sprint': 'Focus Sprint',
    'social_checkin': 'Social Check-in',
    'gratitude_moment': 'Gratitude Moment',
    'self_compassion': 'Self-Compassion',
    'energy_plan': 'Energy Plan',
    'busy_day': 'Busy Day',
    'time_pressure': 'Time Pressure',
    'unexpected_event': 'Unexpected Event',
    'travel_disruption': 'Travel Disruption',
    'workspace_shift': 'Workspace Shift',
    'weather_slump': 'Weather Slump',
    'supportive_chat': 'Supportive Chat',
    'family_duty': 'Family Duty',
    'morning_check': 'Morning Check',
    'midday_reset': 'Midday Reset',
    'evening_reflection': 'Evening Reflection',
    'proud_progress': 'Proud of Progress',
    'micro_win': 'Micro Win',
    'habit_chain': 'Habit Chain',
    'first_step': 'First Step',
    'need_rest': 'Needs Rest',
    'need_connection': 'Needs Connection',
    'need_fuel': 'Needs Fuel',
    'need_clarity': 'Needs Clarity',
    'breathing_reset': 'Breathing Reset',
    'movement_boost': 'Movement Boost',
    'mindful_break': 'Mindful Break',
    'balanced_meal': 'Balanced Meal',
    'creative_play': 'Creative Play',
    'rest_day': 'Rest Day',
    'relief': 'Relief',
    'hopeful': 'Hopeful',
    'balanced': 'Balanced',
    'overwhelmed': 'Overwhelmed',
    'lonely': 'Lonely',
    'anxious_underlying': 'Underlying Anxiety',
    'energized': 'Energized',
    'drained': 'Drained',
    'restless': 'Restless',
    'foggy': 'Foggy',
    'learning': 'Learning',
    'setback': 'Setback',
  };

  static const Map<String, String> _aliases = {
    // Choice aliases
    'hydration': 'hydration_reset',
    'nutrition': 'balanced_meal',
    'sleep': 'sleep_hygiene',
    'movement': 'movement_boost',
    'focus': 'focus_sprint',
    'calm': 'calm_grounded',
    'daily_movement': 'movement_boost',
    'exercise': 'movement_boost',
    'walking': 'movement_boost',
    'sports': 'movement_boost',
    'stretching': 'movement_boost',
    'yoga': 'movement_boost',
    'strength_training': 'movement_boost',
    'sedentary_lifestyle': 'movement_boost',
    'quality_sleep': 'sleep_hygiene',
    'poor_sleep': 'sleep_hygiene',
    'insomnia': 'sleep_hygiene',
    'napping': 'rest_day',
    'oversleeping': 'sleep_hygiene',
    'sleep_schedule': 'sleep_hygiene',
    'bedtime_routine': 'sleep_hygiene',
    'mindfulness': 'mindful_break',
    'meditation': 'breathing_reset',
    'journaling': 'gratitude_moment',
    'therapy': 'supportive_chat',
    'stress_coping': 'breathing_reset',
    'burnout': 'need_rest',
    'panic_attacks': 'anxious_underlying',
    'emotional_regulation': 'balanced',
    'self_care': 'self_compassion',
    'drinking_water': 'hydration_reset',
    'dehydration': 'hydration_reset',
    'cooking_meal': 'balanced_meal',
    'meal_prep': 'balanced_meal',
    'alcohol_use': 'reset_routine',
    'smoking': 'reset_routine',
    'sobriety': 'reset_routine',
    'drug_use': 'reset_routine',
    'reducing_substances': 'reset_routine',
    'addiction_recovery': 'reset_routine',
    'time_with_others': 'social_checkin',
    'reaching_for_help': 'social_checkin',
    'conflict_resolution': 'supportive_chat',
    'feeling_connected': 'social_checkin',
    'avoiding_interaction': 'lonely',
    'voluntary_isolation': 'lonely',
    'social_activity': 'social_checkin',
    'community_engagement': 'social_checkin',

    // Chance aliases
    'employment_status': 'busy_day',
    'job_loss': 'unexpected_event',
    'job_insecurity': 'time_pressure',
    'stable_income': 'balanced',
    'financial_stress': 'time_pressure',
    'food_security': 'balanced_meal',
    'food_insecurity': 'need_fuel',
    'housing_stability': 'balanced',
    'housing_instability': 'time_pressure',
    'unexpected_expense': 'unexpected_event',
    'school_attendance': 'busy_day',
    'school_disengagement': 'overwhelmed',
    'literacy_level': 'need_clarity',
    'language_barriers': 'need_connection',
    'higher_education_access': 'focus_sprint',
    'learning_difficulties': 'need_clarity',
    'health_services_access': 'supportive_chat',
    'health_insurance': 'supportive_chat',
    'regular_gp': 'supportive_chat',
    'health_literacy': 'need_clarity',
    'missed_appointments': 'setback',
    'transport_to_health': 'travel_disruption',
    'medication_access': 'need_fuel',
    'specialist_care': 'supportive_chat',
    'safe_housing': 'calm_grounded',
    'unsafe_housing': 'anxious_underlying',
    'community_violence': 'anxious_underlying',
    'environmental_pollution': 'weather_slump',
    'clean_air_water': 'calm_grounded',
    'public_transport': 'travel_disruption',
    'transport_access': 'travel_disruption',
    'healthy_food_outlets': 'balanced_meal',
    'recreation_spaces': 'movement_boost',
    'social_support': 'supportive_chat',
    'isolation_loneliness': 'lonely',
    'discrimination': 'anxious_underlying',
    'incarceration_history': 'anxious_underlying',
    'peer_conflict': 'family_duty',
    'civic_participation': 'social_checkin',
    'family_dynamics': 'family_duty',

    // Outcome aliases
    'calm_mood': 'calm_grounded',
    'happy_mood': 'energized',
    'depression': 'need_connection',
    'anxiety': 'anxious_underlying',
    'mood_swings': 'foggy',
    'stress_level': 'overwhelmed',
    'emotional_exhaustion': 'drained',
    'mental_clarity': 'need_clarity',
    'emotional_stability': 'balanced',
    'self_confidence': 'hopeful',
    'feeling_well': 'balanced',
    'fatigue': 'drained',
    'low_energy': 'drained',
    'pain': 'need_rest',
    'injury': 'need_rest',
    'illness_symptoms': 'need_rest',
    'doctor_visit': 'family_duty',
    'recovery': 'rest_day',
    'physical_strength': 'energized',
    'immune_system': 'need_fuel',
    'chronic_condition': 'need_rest',
    'hungry': 'need_fuel',
    'needs_fuel': 'need_fuel',
    'need fuel': 'need_fuel',
  };

  /// Get all canonical keys for a category
  static List<String> getCanonicalKeys(TagCategory category) {
    final categoryName = category.name;
    final categoryMap = structure[categoryName];
    if (categoryMap == null) return [];

    return categoryMap.values.expand((keys) => keys).toList();
  }

  /// Get subdomain for a canonical key
  static String? getSubdomain(String canonicalKey) {
    for (final categoryMap in structure.values) {
      for (final entry in categoryMap.entries) {
        if (entry.value.contains(canonicalKey)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// Get category for a canonical key
  static TagCategory? getCategory(String canonicalKey) {
    for (final entry in structure.entries) {
      final categoryMap = entry.value;
      for (final subdomain in categoryMap.values) {
        if (subdomain.contains(canonicalKey)) {
          return TagCategory.values.firstWhere((e) => e.name == entry.key);
        }
      }
    }
    return null;
  }

  /// Get display name for canonical key
  static String getDisplayName(String canonicalKey) {
    if (_displayNameOverrides.containsKey(canonicalKey)) {
      return _displayNameOverrides[canonicalKey]!;
    }

    return canonicalKey
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ')
        .trim();
  }

  static bool isSupported(String canonicalKey) {
    return structure.values
        .expand((subdomains) => subdomains.values)
        .expand((keys) => keys)
        .contains(canonicalKey);
  }

  static String? resolveCanonicalKey(String? canonicalKey) {
    if (canonicalKey == null || canonicalKey.isEmpty) {
      return null;
    }

    if (isSupported(canonicalKey)) {
      return canonicalKey;
    }

    final alias = _aliases[canonicalKey];
    if (alias != null && isSupported(alias)) {
      return alias;
    }

    return null;
  }
}
