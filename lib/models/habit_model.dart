
/// High-level habit type classification used by legacy features and tests.
enum HabitType { choice, chance }

HabitType _habitTypeFromString(String value) {
  switch (value) {
    case 'chance':
      return HabitType.chance;
    case 'choice':
    default:
      return HabitType.choice;
  }
}

String _habitTypeToString(HabitType type) {
  return type == HabitType.chance ? 'chance' : 'choice';
}

/// Legacy habit model preserved for backwards compatibility with tests
/// and services that expect a flat habit representation.
class StarboundHabit {
  final String id;
  final String title;
  final String category;
  final HabitType habitType;
  final bool isCompleted;
  final List<String> completionDates;
  final int streak;
  final DateTime? lastCompleted;
  final String? description;
  final String? targetFrequency;
  final int completionCount;
  final int? totalGoal;
  final int priority;
  final List<String> tags;
  final Map<String, dynamic> customData;

  const StarboundHabit({
    required this.id,
    required this.title,
    required this.category,
    required this.habitType,
    this.isCompleted = false,
    this.completionDates = const [],
    this.streak = 0,
    this.lastCompleted,
    this.description,
    this.targetFrequency,
    this.completionCount = 0,
    this.totalGoal,
    this.priority = 1,
    this.tags = const [],
    this.customData = const {},
  });

  StarboundHabit copyWith({
    String? id,
    String? title,
    String? category,
    HabitType? habitType,
    bool? isCompleted,
    List<String>? completionDates,
    int? streak,
    DateTime? lastCompleted,
    String? description,
    String? targetFrequency,
    int? completionCount,
    int? totalGoal,
    int? priority,
    List<String>? tags,
    Map<String, dynamic>? customData,
  }) {
    return StarboundHabit(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      habitType: habitType ?? this.habitType,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDates: completionDates ?? this.completionDates,
      streak: streak ?? this.streak,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      description: description ?? this.description,
      targetFrequency: targetFrequency ?? this.targetFrequency,
      completionCount: completionCount ?? this.completionCount,
      totalGoal: totalGoal ?? this.totalGoal,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      customData: customData ?? this.customData,
    );
  }

  int getCurrentStreak() {
    if (completionDates.isEmpty) return 0;
    final parsedDates = completionDates
        .map((date) => DateTime.tryParse(date))
        .whereType<DateTime>()
        .toList()
      ..sort();

    int streakCount = 0;
    DateTime? previousDay;

    for (final date in parsedDates.reversed) {
      final normalized = DateTime(date.year, date.month, date.day);
      if (previousDay == null) {
        streakCount = 1;
        previousDay = normalized;
        continue;
      }

      if (previousDay!.difference(normalized).inDays == 1) {
        streakCount += 1;
        previousDay = normalized;
      } else if (previousDay == normalized) {
        // Same day entry, ignore.
        continue;
      } else {
        break;
      }
    }

    return streakCount;
  }

  bool isChoice() => habitType == HabitType.choice;
  bool isChance() => habitType == HabitType.chance;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'habitType': _habitTypeToString(habitType),
      'isCompleted': isCompleted,
      'completionDates': completionDates,
      'streak': streak,
      'lastCompleted': lastCompleted?.toIso8601String(),
      'description': description,
      'targetFrequency': targetFrequency,
      'completionCount': completionCount,
      'totalGoal': totalGoal,
      'priority': priority,
      'tags': tags,
      'customData': customData,
    };
  }

  factory StarboundHabit.fromJson(Map<String, dynamic> json) {
    final dates = (json['completionDates'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .toList();

    return StarboundHabit(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      habitType: _habitTypeFromString(json['habitType'] ?? 'choice'),
      isCompleted: json['isCompleted'] ?? false,
      completionDates: dates,
      streak: json['streak'] ?? 0,
      lastCompleted: json['lastCompleted'] != null
          ? DateTime.tryParse(json['lastCompleted'])
          : null,
      description: json['description'],
      targetFrequency: json['targetFrequency'],
      completionCount: json['completionCount'] ?? 0,
      totalGoal: json['totalGoal'],
      priority: json['priority'] ?? 1,
      tags: List<String>.from(json['tags'] ?? []),
      customData: Map<String, dynamic>.from(json['customData'] ?? {}),
    );
  }
}

// 🔹 Base Habit Option
class HabitOption {
  final String label;
  final String? value;

  const HabitOption({required this.label, required this.value});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitOption &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$runtimeType($label)';
}

// 🧭 Habit Category
class HabitCategory {
  final String? id; // Optional ID for custom habits
  final String title;
  final String emoji;
  final List<HabitOption> options;
  final String type; // 'choice' or 'chance'
  final String description;

  const HabitCategory({
    this.id,
    required this.title,
    required this.emoji,
    required this.options,
    required this.type,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitCategory && runtimeType == other.runtimeType && title == other.title;

  @override
  int get hashCode => title.hashCode;

  @override
  String toString() => '$runtimeType(title: "$title")';
}

// 💬 Free-form Entry for Smart Input
class FreeFormEntry {
  final String id;
  final String originalText;
  final DateTime timestamp;
  final List<ClassificationResult> classifications;
  final double averageConfidence;
  final Map<String, dynamic> metadata;
  final bool isProcessed;

  const FreeFormEntry({
    required this.id,
    required this.originalText,
    required this.timestamp,
    required this.classifications,
    required this.averageConfidence,
    this.metadata = const {},
    this.isProcessed = false,
  });

  // Computed properties
  int get classificationCount => classifications.length;
  bool get hasHighConfidence => averageConfidence >= 0.7;
  int get choiceCount => classifications.where((c) => c.category?.type == 'choice').length;
  int get chanceCount => classifications.where((c) => c.category?.type == 'chance').length;
  bool get hasClassifications => classifications.isNotEmpty;

  // Get unique habit keys that were detected
  List<String> get detectedHabitKeys => 
      classifications.map((c) => c.habitKey).toSet().toList();

  // Get summary of what was detected
  String get summary {
    if (classifications.isEmpty) return 'No habits detected';
    
    final habits = classifications
        .map((c) => c.category?.title ?? c.categoryTitle)
        .where((title) => title.isNotEmpty)
        .toSet()
        .toList();
    if (habits.isEmpty) return 'No habits detected';
    if (habits.length == 1) return habits.first;
    if (habits.length == 2) return '${habits[0]} and ${habits[1]}';
    return '${habits.take(habits.length - 1).join(', ')} and ${habits.last}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'timestamp': timestamp.toIso8601String(),
      'classifications': classifications.map((c) => c.toJson()).toList(),
      'averageConfidence': averageConfidence,
      'metadata': metadata,
      'isProcessed': isProcessed,
    };
  }

  factory FreeFormEntry.fromJson(Map<String, dynamic> json) {
    return FreeFormEntry(
      id: json['id'] ?? '',
      originalText: json['originalText'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      classifications: (json['classifications'] as List<dynamic>? ?? [])
          .map((item) => ClassificationResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      averageConfidence: (json['averageConfidence'] ?? 0.0).toDouble(),
      metadata: json['metadata'] ?? {},
      isProcessed: json['isProcessed'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreeFormEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FreeFormEntry($id: "$originalText")';
}

// Classification result for free-form entries with multi-layer analysis
class ClassificationResult {
  final String habitKey;
  final String habitValue; 
  final String categoryTitle;
  final String categoryType; // 'choice' or 'chance'
  final double confidence;
  final String reasoning;
  final String extractedText;
  final Map<String, dynamic> metadata;
  
  // New multi-layer classification fields
  final String sentiment; // 'positive', 'negative', 'neutral'
  final List<String> themes; // Life domain tags (sleep, housing, etc.)
  final List<String> keywords; // Detected keywords
  final double sentimentConfidence;

  const ClassificationResult({
    required this.habitKey,
    required this.habitValue,
    required this.categoryTitle,
    required this.categoryType,
    required this.confidence,
    required this.reasoning,
    required this.extractedText,
    this.metadata = const {},
    // New fields with defaults for backward compatibility
    this.sentiment = 'neutral',
    this.themes = const [],
    this.keywords = const [],
    this.sentimentConfidence = 0.0,
  });

  bool get isChoice => categoryType == 'choice';
  bool get isChance => categoryType == 'chance';
  bool get isHighConfidence => confidence >= 0.7;
  
  // New sentiment analysis getters
  bool get isPositive => sentiment == 'positive';
  bool get isNegative => sentiment == 'negative';
  bool get isNeutral => sentiment == 'neutral';
  bool get hasHighSentimentConfidence => sentimentConfidence >= 0.7;
  bool get hasThemes => themes.isNotEmpty;
  bool get hasKeywords => keywords.isNotEmpty;
  
  // Get primary theme (first one if multiple)
  String get primaryTheme => themes.isNotEmpty ? themes.first : 'general';
  
  // Get formatted theme display
  String get themeDisplay {
    if (themes.isEmpty) return 'General';
    if (themes.length == 1) return _capitalizeFirst(themes.first);
    if (themes.length == 2) return '${_capitalizeFirst(themes.first)} & ${_capitalizeFirst(themes.last)}';
    return '${_capitalizeFirst(themes.first)} +${themes.length - 1}';
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Get the habit category from the system
  HabitCategory? get category => StarboundHabits.all[habitKey];

  // Get human-readable value description
  String get valueDescription {
    final cat = category;
    if (cat == null) return habitValue;
    
    final option = cat.options.firstWhere(
      (opt) => opt.value == habitValue,
      orElse: () => HabitOption(label: habitValue, value: habitValue),
    );
    return option.label;
  }

  Map<String, dynamic> toJson() {
    return {
      'habitKey': habitKey,
      'habitValue': habitValue,
      'categoryTitle': categoryTitle,
      'categoryType': categoryType,
      'confidence': confidence,
      'reasoning': reasoning,
      'extractedText': extractedText,
      'metadata': metadata,
      // New multi-layer fields
      'sentiment': sentiment,
      'themes': themes,
      'keywords': keywords,
      'sentimentConfidence': sentimentConfidence,
    };
  }

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      habitKey: json['habitKey'] ?? '',
      habitValue: json['habitValue'] ?? '',
      categoryTitle: json['categoryTitle'] ?? '',
      categoryType: json['categoryType'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      reasoning: json['reasoning'] ?? '',
      extractedText: json['extractedText'] ?? '',
      metadata: json['metadata'] ?? {},
      // New multi-layer fields with defaults
      sentiment: json['sentiment'] ?? 'neutral',
      themes: List<String>.from(json['themes'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      sentimentConfidence: (json['sentimentConfidence'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() => 'ClassificationResult($habitKey: $habitValue [$confidence])';
}

// 📅 All Supported Habits
class StarboundHabits {
  static final List<StarboundHabit> _legacyHabits = [
    const StarboundHabit(
      id: 'sleep_hygiene',
      title: 'Sleep Hygiene',
      category: 'Physical Health',
      habitType: HabitType.choice,
    ),
    const StarboundHabit(
      id: 'daily_hydration',
      title: 'Daily Hydration',
      category: 'Physical Health',
      habitType: HabitType.choice,
    ),
    const StarboundHabit(
      id: 'mindfulness_break',
      title: 'Mindfulness Break',
      category: 'Mental Health',
      habitType: HabitType.choice,
    ),
    const StarboundHabit(
      id: 'gratitude_note',
      title: 'Gratitude Note',
      category: 'Mental Health',
      habitType: HabitType.choice,
    ),
    const StarboundHabit(
      id: 'check_in_friend',
      title: 'Check in with a friend',
      category: 'Relationships',
      habitType: HabitType.chance,
    ),
    const StarboundHabit(
      id: 'seek_support',
      title: 'Asked for support',
      category: 'Relationships',
      habitType: HabitType.chance,
    ),
  ];

  static final Map<String, StarboundHabit> _customLegacyHabits = {};

  // Static base categories (immutable defaults)
  static const Map<String, HabitCategory> _baseCategories = {
    // 🌀 CHOICES - "I did this today"
    'hydration': HabitCategory(
      title: "Drank water",
      emoji: "💧",
      type: "choice",
      description: "How did this feel?",
      options: [
        HabitOption(label: "Refreshing", value: "high"),
        HabitOption(label: "Good", value: "medium"),
        HabitOption(label: "Neutral", value: "low"),
        HabitOption(label: "Forced myself", value: "poor"),
      ],
    ),
    'nutrition': HabitCategory(
      title: "Ate something",
      emoji: "🥗",
      type: "choice",
      description: "How did this feel?",
      options: [
        HabitOption(label: "Nourishing", value: "good"),
        HabitOption(label: "Satisfying", value: "regular"),
        HabitOption(label: "Rushed", value: "some"),
        HabitOption(label: "Didn't enjoy", value: "skipped"),
      ],
    ),
    'focus': HabitCategory(
      title: "Took a breath",
      emoji: "🧘",
      type: "choice",
      description: "How did this feel?",
      options: [
        HabitOption(label: "Calming", value: "high"),
        HabitOption(label: "Helpful", value: "medium"),
        HabitOption(label: "Brief moment", value: "low"),
        HabitOption(label: "Hard to focus", value: "poor"),
      ],
    ),
    'sleep': HabitCategory(
      title: "Went to bed on time",
      emoji: "😴",
      type: "choice",
      description: "How did this feel?",
      options: [
        HabitOption(label: "Restful", value: "good"),
        HabitOption(label: "Sleepy", value: "medium"),
        HabitOption(label: "Restless", value: "low"),
        HabitOption(label: "Stayed up late", value: "poor"),
      ],
    ),
    'movement': HabitCategory(
      title: "Moved my body",
      emoji: "🚶‍♀️",
      type: "choice", 
      description: "How did this feel?",
      options: [
        HabitOption(label: "Energizing", value: "active"),
        HabitOption(label: "Good", value: "moderate"),
        HabitOption(label: "Tiring", value: "light"),
        HabitOption(label: "Couldn't manage", value: "none"),
      ],
    ),
    'energy': HabitCategory(
      title: "Energy Level",
      emoji: "⚡",
      type: "choice",
      description: "How are you feeling?",
      options: [
        HabitOption(label: "High energy", value: "high"),
        HabitOption(label: "Good energy", value: "medium"),
        HabitOption(label: "Low energy", value: "low"),
        HabitOption(label: "Exhausted", value: "poor"),
      ],
    ),
    'mood': HabitCategory(
      title: "Mood Check",
      emoji: "😊",
      type: "choice",
      description: "How are you feeling?",
      options: [
        HabitOption(label: "Great", value: "high"),
        HabitOption(label: "Good", value: "medium"),
        HabitOption(label: "Okay", value: "regular"),
        HabitOption(label: "Not great", value: "low"),
      ],
    ),
    
    // ⚠️ CHANCES - "This happened today"
    'safety': HabitCategory(
      title: "Felt unsafe",
      emoji: "😖",
      type: "chance",
      description: "Would you like support?",
      options: [
        HabitOption(label: "Yes, please", value: "yes_support"),
        HabitOption(label: "Maybe later", value: "maybe"),
        HabitOption(label: "I'm managing", value: "managing"),
        HabitOption(label: "Learn more", value: "learn_more"),
      ],
    ),
    'meals': HabitCategory(
      title: "Skipped a meal",
      emoji: "🚫",
      type: "chance",
      description: "Would you like support?",
      options: [
        HabitOption(label: "Yes, please", value: "yes_support"),
        HabitOption(label: "Maybe later", value: "maybe"),
        HabitOption(label: "I'm okay", value: "okay"),
        HabitOption(label: "Learn more", value: "learn_more"),
      ],
    ),
    'sleepIssues': HabitCategory(
      title: "Couldn't sleep",
      emoji: "💤",
      type: "chance",
      description: "Would you like support?",
      options: [
        HabitOption(label: "Yes, please", value: "yes_support"),
        HabitOption(label: "Maybe later", value: "maybe"),
        HabitOption(label: "I'm okay", value: "okay"),
        HabitOption(label: "Learn more", value: "learn_more"),
      ],
    ),
    'financial': HabitCategory(
      title: "Unexpected expense",
      emoji: "💸",
      type: "chance",
      description: "Would you like support?",
      options: [
        HabitOption(label: "Yes, please", value: "yes_support"),
        HabitOption(label: "Maybe later", value: "maybe"),
        HabitOption(label: "I'm managing", value: "managing"),
        HabitOption(label: "Learn more", value: "learn_more"),
      ],
    ),
    'outdoor': HabitCategory(
      title: "No time outside",
      emoji: "🌧",
      type: "chance",
      description: "Would you like support?",
      options: [
        HabitOption(label: "Yes, please", value: "yes_support"),
        HabitOption(label: "Maybe later", value: "maybe"),
        HabitOption(label: "I'm okay", value: "okay"),
        HabitOption(label: "Learn more", value: "learn_more"),
      ],
    ),
  };

  // Helper: get category by key
  static HabitCategory getCategory(String key) {
    return all[key] ?? all['hydration']!;
  }

  // Helper: get habit name from value
  static String getLabelFromValue(String key, String? value) {
    final options = getCategory(key).options;
    final option = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options[0],
    );
    return option.label;
  }
  
  // Runtime categories (mutable for custom habits)
  static Map<String, HabitCategory> _customCategories = <String, HabitCategory>{};
  
  // Combined categories getter
  static Map<String, HabitCategory> get all {
    return {..._baseCategories, ..._customCategories};
  }
  
  // Choice and Chance category getters
  static Map<String, HabitCategory> choiceCategories = <String, HabitCategory>{};
  static Map<String, HabitCategory> chanceCategories = <String, HabitCategory>{};
  
  // Initialize the categories (call this at app start)
  static void initialize() {
    resetLegacyHabits();

    // Initialize choice and chance categories with base categories
    choiceCategories.clear();
    chanceCategories.clear();
    
    for (final entry in _baseCategories.entries) {
      if (entry.value.type == 'choice') {
        choiceCategories[entry.key] = entry.value;
      } else {
        chanceCategories[entry.key] = entry.value;
      }
    }
    
    // Add any existing custom categories
    for (final entry in _customCategories.entries) {
      if (entry.value.type == 'choice') {
        choiceCategories[entry.key] = entry.value;
      } else {
        chanceCategories[entry.key] = entry.value;
      }
    }
  }
  
  // Add custom habit
  static void addCustomHabit(String key, HabitCategory category) {
    _customCategories[key] = category;
    
    // Update the type-specific maps
    if (category.type == 'choice') {
      choiceCategories[key] = category;
    } else {
      chanceCategories[key] = category;
    }
  }
  
  // Remove custom habit
  static void removeCustomHabit(String key) {
    final category = _customCategories.remove(key);
    if (category != null) {
      choiceCategories.remove(key);
      chanceCategories.remove(key);
    }
  }
  
  // Check if habit is custom
  static bool isCustomHabit(String key) {
    return _customCategories.containsKey(key);
  }
  
  // Helper: get categories by type (backward compatibility)
  static Map<String, HabitCategory> getChoices() {
    return Map.fromEntries(
      all.entries.where((entry) => entry.value.type == 'choice')
    );
  }
  
  static Map<String, HabitCategory> getChances() {
    return Map.fromEntries(
      all.entries.where((entry) => entry.value.type == 'chance')
    );
  }

  // --- Legacy helpers retained for existing tests/services ---------------
  static List<StarboundHabit> getAllHabits() {
    return [
      ..._legacyHabits,
      ..._customLegacyHabits.values,
    ];
  }

  static List<StarboundHabit> getHabitsForCategory(String category) {
    return getAllHabits()
        .where((habit) => habit.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  static List<StarboundHabit> getChoiceHabits() {
    return getAllHabits().where((habit) => habit.isChoice()).toList();
  }

  static List<StarboundHabit> getChanceHabits() {
    return getAllHabits().where((habit) => habit.isChance()).toList();
  }

  static List<String> getAllCategories() {
    final categories = <String>{
      for (final habit in _legacyHabits) habit.category,
      for (final habit in _customLegacyHabits.values) habit.category,
    };
    return categories.toList()..sort();
  }

  static StarboundHabit? getHabitById(String id) {
    for (final habit in getAllHabits()) {
      if (habit.id == id) {
        return habit;
      }
    }
    return null;
  }

  static void addLegacyHabit(StarboundHabit habit) {
    _customLegacyHabits[habit.id] = habit;
  }

  static void removeLegacyHabit(String id) {
    _customLegacyHabits.remove(id);
  }

  static void resetLegacyHabits() {
    _customLegacyHabits.clear();
  }
}
