
enum NudgeSource {
  predefined, // Static nudges from the vault
  dynamic, // Generated from patterns and recommendations
  emergency, // Urgent interventions
}

enum NudgeType {
  encouragement,
  insight,
  suggestion,
  warning,
  celebration,
  reminder,
  urgentReminder,
}

extension NudgeTypeExtension on NudgeType {
  String get value => name;

  static NudgeType fromString(String raw) {
    final normalised = raw.trim();
    if (normalised.isEmpty) {
      return NudgeType.encouragement;
    }
    for (final type in NudgeType.values) {
      if (type.name.toLowerCase() == normalised.toLowerCase()) {
        return type;
      }
    }
    return NudgeType.encouragement;
  }
}

// 🔹 Single Nudge Model
class StarboundNudge {
  final String id;
  final String theme;
  final String targetHabitId;
  final String message;
  final String tone;
  final String estimatedTime;
  final String energyRequired;
  final List<String> complexityProfileFit;
  final List<String> triggersFrom;
  final NudgeSource source;
  final DateTime? generatedAt;
  final Map<String, dynamic>? metadata;
  final List<String> contextTags;

  // Additional properties for UI compatibility
  final NudgeType type;
  final String title;
  final String content;
  final List<String> actionableSteps;
  final int priority;
  final DateTime? createdAt;
  final bool isActive;
  final int views;
  final bool dismissed;
  final bool banked;
  final double? effectiveness;
  final DateTime? scheduledFor;
  final DateTime? expiresAt;

  const StarboundNudge({
    required this.id,
    this.theme = '',
    this.targetHabitId = '',
    required this.message,
    this.tone = "gentle",
    this.estimatedTime = "<1 min",
    this.energyRequired = "low",
    this.complexityProfileFit = const ["stable"],
    this.triggersFrom = const [],
    this.source = NudgeSource.predefined,
    this.generatedAt,
    this.metadata,
    this.contextTags = const [],
    this.type = NudgeType.encouragement,
    this.title = "",
    this.content = "",
    this.actionableSteps = const [],
    this.priority = 0,
    this.createdAt,
    this.isActive = true,
    this.views = 0,
    this.dismissed = false,
    this.banked = false,
    this.effectiveness,
    this.scheduledFor,
    this.expiresAt,
  });

  StarboundNudge copyWith({
    String? id,
    String? theme,
    String? targetHabitId,
    String? message,
    String? tone,
    String? estimatedTime,
    String? energyRequired,
    List<String>? complexityProfileFit,
    List<String>? triggersFrom,
    NudgeSource? source,
    DateTime? generatedAt,
    Map<String, dynamic>? metadata,
    List<String>? contextTags,
    NudgeType? type,
    String? title,
    String? content,
    List<String>? actionableSteps,
    int? priority,
    DateTime? createdAt,
    bool? isActive,
    int? views,
    bool? dismissed,
    bool? banked,
    double? effectiveness,
    DateTime? scheduledFor,
    DateTime? expiresAt,
  }) {
    return StarboundNudge(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      targetHabitId: targetHabitId ?? this.targetHabitId,
      message: message ?? this.message,
      tone: tone ?? this.tone,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      energyRequired: energyRequired ?? this.energyRequired,
      complexityProfileFit:
          complexityProfileFit ?? List<String>.from(this.complexityProfileFit),
      triggersFrom: triggersFrom ?? List<String>.from(this.triggersFrom),
      source: source ?? this.source,
      generatedAt: generatedAt ?? this.generatedAt,
      metadata: metadata ??
          (this.metadata != null
              ? Map<String, dynamic>.from(this.metadata!)
              : null),
      contextTags:
          contextTags ?? List<String>.from(this.contextTags, growable: false),
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      actionableSteps:
          actionableSteps ?? List<String>.from(this.actionableSteps),
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      views: views ?? this.views,
      dismissed: dismissed ?? this.dismissed,
      banked: banked ?? this.banked,
      effectiveness: effectiveness ?? this.effectiveness,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  factory StarboundNudge.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    return StarboundNudge(
      id: json['id'].toString(),
      theme: json['theme'] ?? '',
      targetHabitId: json['targetHabitId']?.toString() ?? '',
      message: json['message'] ?? '',
      tone: json['tone'] ?? 'gentle',
      estimatedTime: json['estimated_time'] ?? '<1 min',
      energyRequired: json['energy_required'] ?? 'low',
      complexityProfileFit: json['complexity_profile_fit'] != null
          ? List<String>.from(json['complexity_profile_fit'])
          : ['stable'],
      triggersFrom: json['triggers_from'] != null
          ? List<String>.from(json['triggers_from'])
          : [],
      source: NudgeSource.values[json['source'] ?? 0],
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'])
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      contextTags: _parseContextTags(json),
      type: rawType is String
          ? NudgeTypeExtension.fromString(rawType)
          : NudgeType.values[(rawType as int?)?.clamp(0, NudgeType.values.length - 1) ?? 0],
      title: json['title'] ?? json['theme'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      actionableSteps: json['actionable_steps'] != null
          ? List<String>.from(json['actionable_steps'])
          : [],
      priority: json['priority'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      isActive: json['isActive'] ?? true,
      views: json['views'] ?? 0,
      dismissed: json['dismissed'] ?? false,
      banked: json['banked'] ?? false,
      effectiveness: (json['effectiveness'] as num?)?.toDouble(),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.tryParse(json['scheduledFor'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'theme': theme,
      'message': message,
      'tone': tone,
      'estimated_time': estimatedTime,
      'energy_required': energyRequired,
      'complexity_profile_fit': complexityProfileFit,
      'triggers_from': triggersFrom,
      'source': source.index,
      'generated_at': generatedAt?.toIso8601String(),
      'metadata': metadata,
      'context_tags': contextTags,
      'type': type.name,
      'title': title,
      'content': content,
      'actionable_steps': actionableSteps,
      'targetHabitId': targetHabitId,
      'priority': priority,
      'createdAt': createdAt?.toIso8601String(),
      'isActive': isActive,
      'views': views,
      'dismissed': dismissed,
      'banked': banked,
      'effectiveness': effectiveness,
      'scheduledFor': scheduledFor?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  double getAgeInHours() {
    final origin = createdAt ?? generatedAt;
    if (origin == null) {
      return 0;
    }
    final diff = DateTime.now().difference(origin);
    return diff.inMinutes / 60.0;
  }

  static List<String> _parseContextTags(Map<String, dynamic> json) {
    final rawFromRoot = json['context_tags'];
    if (rawFromRoot is List) {
      return rawFromRoot
          .whereType<dynamic>()
          .map((tag) => tag.toString().trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false);
    }

    final rawFromMetadata = json['metadata'];
    if (rawFromMetadata is Map<String, dynamic>) {
      final metadataTags = rawFromMetadata['context_tags'];
      if (metadataTags is List) {
        return metadataTags
            .whereType<dynamic>()
            .map((tag) => tag.toString().trim())
            .where((tag) => tag.isNotEmpty)
            .toList(growable: false);
      }
    }

    return const [];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StarboundNudge &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$runtimeType(id: $id, theme: $theme)';
}

// 🧭 Nudge Library / Action Vault
class NudgeVault {
  static const List<StarboundNudge> nudges = [
    StarboundNudge(
      id: "nudge_001",
      theme: "hydration",
      message: "Drink 1 cup of water right now — bonus if it’s cold!",
      tone: "gentle",
      estimatedTime: "<1 min",
      energyRequired: "low",
      complexityProfileFit: ["trying", "overloaded"],
      triggersFrom: ["hydration_low", "meals_skipped"],
      contextTags: const ["anywhere", "at home", "at work/school"],
    ),
    StarboundNudge(
      id: "nudge_002",
      theme: "sleep",
      message:
          "Try winding down 30 minutes earlier tonight with calming music or journaling.",
      tone: "encouraging",
      estimatedTime: "5-10 mins",
      energyRequired: "low",
      complexityProfileFit: ["overloaded", "survival"],
      triggersFrom: ["sleep_poor", "screen_breaks_none"],
      contextTags: const ["in bed", "at home", "needs quiet"],
    ),
    StarboundNudge(
      id: "nudge_003",
      theme: "movement",
      message:
          "Stretch for 2 minutes — just reach up and touch your toes a few times.",
      tone: "playful",
      estimatedTime: "1-2 mins",
      energyRequired: "very low",
      complexityProfileFit: ["stable", "trying"],
      triggersFrom: ["movement_none", "meals_good"],
      contextTags: const ["at home", "at work/school"],
    ),
    StarboundNudge(
      id: "nudge_004",
      theme: "focus",
      message: "Take a 2-minute breathing break — in for 4, out for 6.",
      tone: "calming",
      estimatedTime: "1-2 mins",
      energyRequired: "low",
      complexityProfileFit: ["trying", "overloaded"],
      triggersFrom: ["stress_high", "screen_breaks_few"],
      contextTags: const ["anywhere", "needs quiet"],
    ),
    StarboundNudge(
      id: "nudge_005",
      theme: "nutrition",
      message: "Grab a banana or handful of nuts — easy snacks for busy days.",
      tone: "practical",
      estimatedTime: "<1 min",
      energyRequired: "low",
      complexityProfileFit: ["overloaded", "survival"],
      triggersFrom: ["meals_skipped", "energy_low"],
      contextTags: const ["at home", "at work/school", "on the go"],
    ),
    // Additional hydration nudges
    StarboundNudge(
      id: "nudge_006",
      theme: "hydration",
      message: "Keep a water bottle within arm's reach — small sips add up.",
      tone: "practical",
      estimatedTime: "<1 min",
      energyRequired: "low",
      complexityProfileFit: ["survival", "overloaded"],
      triggersFrom: ["hydration_low"],
      contextTags: const ["anywhere", "on the go"],
    ),
    StarboundNudge(
      id: "nudge_007",
      theme: "hydration",
      message:
          "Challenge yourself to drink a glass of water before your next meal.",
      tone: "motivating",
      estimatedTime: "<1 min",
      energyRequired: "low",
      complexityProfileFit: ["stable", "trying"],
      triggersFrom: ["hydration_low"],
      contextTags: const ["at home", "at work/school"],
    ),
    // Additional sleep nudges
    StarboundNudge(
      id: "nudge_008",
      theme: "sleep",
      message:
          "Just for tonight, try putting your phone in another room before bed.",
      tone: "gentle",
      estimatedTime: "1-2 mins",
      energyRequired: "low",
      complexityProfileFit: ["trying", "overloaded"],
      triggersFrom: ["sleep_poor", "screen_breaks_none"],
      contextTags: const ["in bed", "at home", "needs quiet"],
    ),
    StarboundNudge(
      id: "nudge_009",
      theme: "sleep",
      message:
          "Set a consistent bedtime routine — even 10 minutes of the same activities can help.",
      tone: "supportive",
      estimatedTime: "5-10 mins",
      energyRequired: "low",
      complexityProfileFit: ["stable", "trying"],
      triggersFrom: ["sleep_poor"],
      contextTags: const ["in bed", "at home", "needs quiet"],
    ),
    // Additional movement nudges
    StarboundNudge(
      id: "nudge_010",
      theme: "movement",
      message: "Take the stairs instead of the elevator — small moves count.",
      tone: "encouraging",
      estimatedTime: "1-2 mins",
      energyRequired: "low",
      complexityProfileFit: ["trying", "stable"],
      triggersFrom: ["movement_none"],
      contextTags: const ["on the go", "at work/school"],
    ),
    StarboundNudge(
      id: "nudge_011",
      theme: "movement",
      message:
          "Stand up and walk around for 30 seconds — your body will thank you.",
      tone: "gentle",
      estimatedTime: "<1 min",
      energyRequired: "very low",
      complexityProfileFit: ["overloaded", "survival"],
      triggersFrom: ["movement_none"],
      contextTags: const ["at work/school", "at home"],
    ),
    // Additional focus nudges
    StarboundNudge(
      id: "nudge_012",
      theme: "focus",
      message:
          "Look away from your screen and focus on something 20 feet away for 20 seconds.",
      tone: "practical",
      estimatedTime: "<1 min",
      energyRequired: "very low",
      complexityProfileFit: ["survival", "overloaded"],
      triggersFrom: ["screen_breaks_none"],
      contextTags: const ["at work/school", "anywhere"],
    ),
    StarboundNudge(
      id: "nudge_013",
      theme: "focus",
      message:
          "Try the 5-4-3-2-1 technique: 5 things you see, 4 you hear, 3 you feel, 2 you smell, 1 you taste.",
      tone: "grounding",
      estimatedTime: "1-2 mins",
      energyRequired: "low",
      complexityProfileFit: ["trying", "overloaded"],
      triggersFrom: ["stress_high"],
      contextTags: const ["anywhere", "needs quiet"],
    ),
    // Additional nutrition nudges
    StarboundNudge(
      id: "nudge_014",
      theme: "nutrition",
      message:
          "Keep some crackers or a protein bar in your bag — backup fuel for tough days.",
      tone: "caring",
      estimatedTime: "<1 min",
      energyRequired: "low",
      complexityProfileFit: ["survival", "overloaded"],
      triggersFrom: ["meals_skipped"],
      contextTags: const [
        "on the go",
        "at home",
        "at work/school",
        "needs supplies"
      ],
    ),
    StarboundNudge(
      id: "nudge_015",
      theme: "nutrition",
      message:
          "Try adding one extra vegetable to whatever you're already eating.",
      tone: "gentle",
      estimatedTime: "1-2 mins",
      energyRequired: "low",
      complexityProfileFit: ["stable", "trying"],
      triggersFrom: ["meals_regular"],
      contextTags: const ["at home", "needs supplies"],
    ),
    // General/supportive nudges
    StarboundNudge(
      id: "nudge_016",
      theme: "general",
      message:
          "You're doing your best with what you have right now, and that's enough.",
      tone: "supportive",
      estimatedTime: "<1 min",
      energyRequired: "very low",
      complexityProfileFit: ["survival", "overloaded"],
      triggersFrom: ["stress_high", "low_energy"],
      contextTags: const ["anywhere", "in bed"],
    ),
    StarboundNudge(
      id: "nudge_017",
      theme: "general",
      message:
          "Take a moment to notice one thing that went well today, however small.",
      tone: "appreciative",
      estimatedTime: "1-2 mins",
      energyRequired: "low",
      complexityProfileFit: ["trying", "overloaded"],
      triggersFrom: ["general"],
      contextTags: const ["anywhere", "in bed"],
    ),
    StarboundNudge(
      id: "nudge_018",
      theme: "general",
      message:
          "You're building positive habits — keep going with whatever feels manageable today.",
      tone: "encouraging",
      estimatedTime: "<1 min",
      energyRequired: "very low",
      complexityProfileFit: ["stable", "trying"],
      triggersFrom: ["general"],
      contextTags: const ["anywhere"],
    ),
    // Celebration nudges for improvements
    StarboundNudge(
      id: "nudge_019",
      theme: "celebration",
      message:
          "Nice work staying consistent! Small wins build into bigger changes.",
      tone: "celebratory",
      estimatedTime: "<1 min",
      energyRequired: "very low",
      complexityProfileFit: ["stable", "trying"],
      triggersFrom: ["habit_improving"],
      contextTags: const ["anywhere"],
    ),
    StarboundNudge(
      id: "nudge_020",
      theme: "celebration",
      message: "You're making progress — that's something to feel proud of.",
      tone: "affirming",
      estimatedTime: "<1 min",
      energyRequired: "very low",
      complexityProfileFit: ["trying", "overloaded"],
      triggersFrom: ["habit_improving"],
      contextTags: const ["anywhere"],
    ),
  ];

  // Filter nudges by trigger or theme
  static List<StarboundNudge> filterNudges({
    String? searchQuery,
    List<String>? tags,
    String? profileFit,
  }) {
    return nudges.where((nudge) {
      final matchesSearch = searchQuery == null ||
          nudge.message.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesTag = tags == null ||
          tags.isEmpty ||
          nudge.triggersFrom.any((t) => tags.contains(t));
      final matchesProfile =
          profileFit == null || nudge.complexityProfileFit.contains(profileFit);

      return matchesSearch && matchesTag && matchesProfile;
    }).toList();
  }

  // Enhanced nudge matching with complexity profile and pattern recognition
  static StarboundNudge? getNudgeForHabits(Map<String, String?> habits,
      [String? complexityProfile]) {
    final validNudges = complexityProfile != null
        ? nudges
            .where((n) => n.complexityProfileFit.contains(complexityProfile))
            .toList()
        : nudges;

    if (validNudges.isEmpty) return nudges.first;

    // Priority-based matching (higher priority = more immediate need)
    final priorityHabits = [
      {
        'key': 'hydration',
        'trigger': 'hydration_low',
        'values': ['low', null]
      },
      {
        'key': 'meals',
        'trigger': 'meals_skipped',
        'values': ['skipped', null]
      },
      {
        'key': 'sleep',
        'trigger': 'sleep_poor',
        'values': ['poor', null]
      },
      {
        'key': 'movement',
        'trigger': 'movement_none',
        'values': ['none', null]
      },
      {
        'key': 'screenBreaks',
        'trigger': 'screen_breaks_none',
        'values': ['none', null]
      },
    ];

    // Find the most urgent need based on habit patterns
    for (final habit in priorityHabits) {
      final habitKey = habit['key'] as String;
      final trigger = habit['trigger'] as String;
      final concerningValues = habit['values'] as List<String?>;

      if (concerningValues.contains(habits[habitKey])) {
        final matchingNudge = validNudges.firstWhere(
          (n) => n.triggersFrom.contains(trigger),
          orElse: () => validNudges.first,
        );
        return matchingNudge;
      }
    }

    // If no specific triggers match, return a general nudge appropriate for complexity level
    return validNudges.firstWhere(
      (n) => n.theme == "general",
      orElse: () => validNudges.first,
    );
  }

  // Pattern recognition for habit trends
  static List<String> identifyHabitPatterns(
      Map<String, List<String?>> habitHistory) {
    final patterns = <String>[];

    // Check for declining patterns (getting worse over time)
    habitHistory.forEach((habitKey, history) {
      if (history.length >= 3) {
        final recent =
            history.length >= 3 ? history.sublist(history.length - 3) : history;
        if (_isDecreasingPattern(recent)) {
          patterns.add('${habitKey}_declining');
        }
        if (_isImprovingPattern(recent)) {
          patterns.add('${habitKey}_improving');
        }
      }
    });

    // Check for consistency patterns
    final consistentHabits = habitHistory.entries
        .where((entry) => _isConsistentPattern(entry.value))
        .map((entry) => '${entry.key}_consistent')
        .toList();

    patterns.addAll(consistentHabits);

    return patterns;
  }

  static bool _isDecreasingPattern(List<String?> values) {
    final scores = values.map((v) => _getHabitScore(v)).toList();
    return scores.length >= 3 && scores[0] > scores[1] && scores[1] > scores[2];
  }

  static bool _isImprovingPattern(List<String?> values) {
    final scores = values.map((v) => _getHabitScore(v)).toList();
    return scores.length >= 3 && scores[0] < scores[1] && scores[1] < scores[2];
  }

  static bool _isConsistentPattern(List<String?> values) {
    if (values.length < 5) return false;
    final recentValues =
        values.length >= 5 ? values.sublist(values.length - 5) : values;
    final uniqueValues = recentValues.toSet();
    return uniqueValues.length <= 2; // Consistent if only 1-2 different values
  }

  static int _getHabitScore(String? value) {
    // Convert habit values to numeric scores for pattern analysis
    switch (value) {
      case 'high':
      case 'good':
      case 'many':
      case 'active':
        return 4;
      case 'medium':
      case 'regular':
      case 'some':
      case 'moderate':
        return 3;
      case 'low':
      case 'once':
      case 'few':
      case 'light':
        return 2;
      case 'poor':
      case 'skipped':
      case 'none':
        return 1;
      default:
        return 0;
    }
  }

  // Get contextual nudges based on time, day, and patterns
  static List<StarboundNudge> getContextualNudges({
    required Map<String, String?> currentHabits,
    required String complexityProfile,
    List<String> patterns = const [],
    DateTime? currentTime,
  }) {
    final baseNudges = filterNudges(profileFit: complexityProfile);
    final contextualNudges = <StarboundNudge>[];

    final now = currentTime ?? DateTime.now();
    final hour = now.hour;

    // Morning nudges (6-10 AM)
    if (hour >= 6 && hour < 10) {
      contextualNudges.addAll(baseNudges
          .where((n) => n.theme == 'hydration' || n.theme == 'movement'));
    }

    // Afternoon nudges (12-4 PM)
    else if (hour >= 12 && hour < 16) {
      contextualNudges.addAll(baseNudges
          .where((n) => n.theme == 'nutrition' || n.theme == 'focus'));
    }

    // Evening nudges (6-10 PM)
    else if (hour >= 18 && hour < 22) {
      contextualNudges.addAll(
          baseNudges.where((n) => n.theme == 'sleep' || n.theme == 'calm'));
    }

    // Add pattern-based nudges
    for (final pattern in patterns) {
      if (pattern.contains('declining')) {
        contextualNudges.addAll(baseNudges
            .where((n) => n.tone == 'encouraging' || n.tone == 'gentle'));
      }
      if (pattern.contains('improving')) {
        contextualNudges.addAll(baseNudges
            .where((n) => n.tone == 'celebratory' || n.tone == 'motivating'));
      }
    }

    return contextualNudges.isEmpty ? [baseNudges.first] : contextualNudges;
  }
}

// 🤖 Dynamic Nudge Generation Service
class DynamicNudgeGenerator {
  // AI-powered nudge generation using Gemma AI service
  static Future<StarboundNudge> generateAINudge({
    required String userName,
    required String complexityProfile,
    required Map<String, dynamic> currentHabits,
    required Map<String, dynamic> contextData,
  }) async {
    try {
      // Import GemmaAIService dynamically to avoid circular dependencies
      final gemmaService = _getGemmaAIService();

      final aiNudgeData = await gemmaService.generatePersonalizedNudge(
        userName: userName,
        complexityProfile: complexityProfile,
        currentHabits: currentHabits,
        contextData: contextData,
      );

      final now = DateTime.now();

      return StarboundNudge(
        id: "ai_nudge_${now.millisecondsSinceEpoch}",
        theme: DynamicNudgeGenerator._extractThemeFromMessage(
            aiNudgeData['message'] ?? ''),
        message: aiNudgeData['message'] ?? '',
        tone: DynamicNudgeGenerator._mapTechniqueToTone(
            aiNudgeData['technique'] ?? ''),
        estimatedTime: aiNudgeData['estimatedTime'] ?? '<1 min',
        energyRequired: aiNudgeData['energyRequired'] ?? 'low',
        complexityProfileFit: [complexityProfile],
        triggersFrom: ['ai_behavioral_analysis'],
        source: NudgeSource.dynamic,
        generatedAt: now,
        metadata: {
          'technique': aiNudgeData['technique'],
          'behavioral_principle': aiNudgeData['behavioralPrinciple'],
          'sources': aiNudgeData['sources'],
          'generation_type': 'ai_behavioral_science',
          'ai_generated': true,
        },
      );
    } catch (e) {
      // Fallback to traditional generation if AI fails
      return DynamicNudgeGenerator._generateFallbackNudge(
          userName, complexityProfile, currentHabits);
    }
  }

  // Helper method to dynamically get GemmaAI service (to avoid import issues)
  static dynamic _getGemmaAIService() {
    // Import GemmaAI service dynamically to avoid circular dependencies
    // This is a workaround - in production this would use proper dependency injection
    try {
      // We'll create a simple factory pattern to access the service
      final gemmaAI = _GemmaAIServiceFactory.getInstance();
      return gemmaAI;
    } catch (e) {
      throw Exception('GemmaAI service not available: $e');
    }
  }

  // Missing static methods that are called from app_state.dart
  static StarboundNudge generateFromSuggestion({
    required String habitKey,
    required String habitTitle,
    required String rationale,
    required double successProbability,
    required String complexityLevel,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final tone = _selectTone(successProbability, complexityLevel);
    final prefix = _getPrefix(tone);
    final action = _getActionForHabit(habitKey);
    final encouragement =
        _getEncouragement(successProbability, complexityLevel);

    final message = "$prefix$action $encouragement";

    return StarboundNudge(
      id: "dynamic_${habitKey}_${now.millisecondsSinceEpoch}",
      theme: _getThemeForHabit(habitKey),
      message: message,
      tone: tone,
      estimatedTime: _getEstimatedTime(habitKey),
      energyRequired: _getEnergyRequired(habitKey, complexityLevel),
      complexityProfileFit: [complexityLevel],
      triggersFrom: ["recommendation_engine"],
      source: NudgeSource.dynamic,
      generatedAt: now,
      metadata: {
        "habit_key": habitKey,
        "success_probability": successProbability,
        "rationale": rationale,
        "generation_type": "habit_suggestion",
        ...?metadata,
      },
    );
  }

  static StarboundNudge generateInterventionNudge({
    required String habitKey,
    required String pattern,
    required String complexityLevel,
    int streakLength = 0,
  }) {
    final now = DateTime.now();
    final tone = "encouraging";
    final habitName = _formatHabitName(habitKey);

    String message;
    if (streakLength > 0) {
      message =
          "Your $streakLength-day $habitName streak is worth protecting. Even 30 seconds counts to keep it alive.";
    } else {
      message =
          "It's okay to have off days with $habitName. What's the smallest step you could take right now?";
    }

    return StarboundNudge(
      id: "intervention_${habitKey}_${now.millisecondsSinceEpoch}",
      theme: _getThemeForHabit(habitKey),
      message: message,
      tone: tone,
      estimatedTime: "<1 min",
      energyRequired: "very low",
      complexityProfileFit: [complexityLevel],
      triggersFrom: ["pattern_recognition", "streak_protection"],
      source: NudgeSource.emergency,
      generatedAt: now,
      metadata: {
        "habit_key": habitKey,
        "pattern": pattern,
        "streak_length": streakLength,
        "generation_type": "intervention",
      },
    );
  }

  static StarboundNudge generateCorrelationNudge({
    required String habit1,
    required String habit2,
    required double correlationStrength,
    required String complexityLevel,
    required String correlationType,
  }) {
    final now = DateTime.now();
    final habit1Name = _formatHabitName(habit1);
    final habit2Name = _formatHabitName(habit2);

    String message;
    if (correlationType == "positive") {
      message =
          "Since you're doing well with $habit1Name, this might be a great time to try $habit2Name too!";
    } else if (correlationType == "temporal") {
      message =
          "You often follow $habit1Name with $habit2Name. Ready to continue the pattern?";
    } else {
      message =
          "Based on your patterns, $habit2Name could complement your $habit1Name routine.";
    }

    return StarboundNudge(
      id: "correlation_${habit1}_${habit2}_${now.millisecondsSinceEpoch}",
      theme: _getThemeForHabit(habit2),
      message: message,
      tone: "encouraging",
      estimatedTime: _getEstimatedTime(habit2),
      energyRequired: _getEnergyRequired(habit2, complexityLevel),
      complexityProfileFit: [complexityLevel],
      triggersFrom: ["correlation_analysis"],
      source: NudgeSource.dynamic,
      generatedAt: now,
      metadata: {
        "primary_habit": habit1,
        "suggested_habit": habit2,
        "correlation_strength": correlationStrength,
        "correlation_type": correlationType,
        "generation_type": "correlation",
      },
    );
  }

  static StarboundNudge generateSeasonalNudge({
    required String habitKey,
    required String season,
    required String complexityLevel,
  }) {
    final now = DateTime.now();
    final habitName = _formatHabitName(habitKey);

    String message;
    switch (season.toLowerCase()) {
      case "winter":
        if (habitKey.contains("vitamin")) {
          message =
              "Winter is here! Perfect time to prioritize $habitName for immune support.";
        } else if (habitKey.contains("indoor")) {
          message =
              "Cold weather makes $habitName even more appealing. Cozy up and give it a try!";
        } else {
          message =
              "As the days get shorter, $habitName can help maintain your energy and mood.";
        }
        break;
      case "summer":
        if (habitKey.contains("hydration")) {
          message =
              "Summer heat makes $habitName extra important. Your body will thank you!";
        } else if (habitKey.contains("outdoor")) {
          message =
              "Beautiful weather ahead! Perfect time to embrace $habitName.";
        } else {
          message =
              "Summer energy is on your side - great time to focus on $habitName.";
        }
        break;
      case "spring":
        message =
            "Spring renewal energy! Nature is waking up, and so can your $habitName routine.";
        break;
      case "fall":
        message =
            "Fall preparation mode! Time to strengthen your $habitName habit before winter.";
        break;
      default:
        message =
            "This season brings new opportunities for $habitName. Ready to embrace it?";
    }

    return StarboundNudge(
      id: "seasonal_${habitKey}_${now.millisecondsSinceEpoch}",
      theme: _getThemeForHabit(habitKey),
      message: message,
      tone: "motivating",
      estimatedTime: _getEstimatedTime(habitKey),
      energyRequired: _getEnergyRequired(habitKey, complexityLevel),
      complexityProfileFit: [complexityLevel],
      triggersFrom: ["seasonal_adaptation"],
      source: NudgeSource.dynamic,
      generatedAt: now,
      metadata: {
        "habit_key": habitKey,
        "season": season,
        "generation_type": "seasonal",
      },
    );
  }

  // Helper methods for the new static methods
  static String _selectTone(double successProbability, String complexityLevel) {
    if (complexityLevel == "survival") return "gentle";
    if (successProbability > 0.7) return "encouraging";
    if (successProbability > 0.4) return "motivating";
    return "gentle";
  }

  static String _getPrefix(String tone) {
    switch (tone) {
      case "gentle":
        return "Maybe ";
      case "encouraging":
        return "You've got this! ";
      case "motivating":
        return "Ready to ";
      default:
        return "";
    }
  }

  static String _getActionForHabit(String habitKey) {
    final habitActions = {
      'hydration': 'drink a glass of water',
      'sleep': 'prepare for better rest',
      'movement': 'take a short walk',
      'nutrition': 'choose a healthy snack',
      'focus': 'take a mindful moment',
      'calm': 'practice deep breathing',
    };

    for (var entry in habitActions.entries) {
      if (habitKey.contains(entry.key)) {
        return entry.value;
      }
    }
    return "try ${_formatHabitName(habitKey)}";
  }

  static String _getEncouragement(
      double successProbability, String complexityLevel) {
    if (complexityLevel == "survival") return "when you're ready.";
    if (successProbability > 0.7)
      return "Your success pattern shows this fits perfectly!";
    if (successProbability > 0.4) return "This could be a great next step.";
    return "Small steps count!";
  }

  static String _getThemeForHabit(String habitKey) {
    if (habitKey.contains('water') || habitKey.contains('hydrat'))
      return 'hydration';
    if (habitKey.contains('sleep') || habitKey.contains('rest')) return 'sleep';
    if (habitKey.contains('move') ||
        habitKey.contains('exercise') ||
        habitKey.contains('walk')) return 'movement';
    if (habitKey.contains('eat') ||
        habitKey.contains('nutrition') ||
        habitKey.contains('food')) return 'nutrition';
    if (habitKey.contains('focus') || habitKey.contains('concentrate'))
      return 'focus';
    if (habitKey.contains('calm') ||
        habitKey.contains('relax') ||
        habitKey.contains('mindful')) return 'calm';
    return 'focus';
  }

  static String _getEstimatedTime(String habitKey) {
    final quickHabits = ['hydration', 'deep_breathing', 'gratitude'];
    final mediumHabits = ['stretching', 'meditation', 'journaling'];

    if (quickHabits.any((h) => habitKey.contains(h))) return '<1 min';
    if (mediumHabits.any((h) => habitKey.contains(h))) return '2-5 mins';
    return '1-2 mins';
  }

  static String _getEnergyRequired(String habitKey, String complexityLevel) {
    if (complexityLevel == "survival") return "very low";

    final lowEnergyHabits = ["hydration", "deep_breathing", "gratitude"];
    final mediumEnergyHabits = ["stretching", "meditation", "journaling"];

    if (lowEnergyHabits.any((h) => habitKey.contains(h))) return "low";
    if (mediumEnergyHabits.any((h) => habitKey.contains(h))) return "medium";
    return "medium";
  }

  static String _formatHabitName(String habitKey) {
    return habitKey.replaceAll('_', ' ').toLowerCase();
  }

  static String _extractThemeFromMessage(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('water') || lowerMessage.contains('hydrat'))
      return 'hydration';
    if (lowerMessage.contains('sleep') || lowerMessage.contains('rest'))
      return 'sleep';
    if (lowerMessage.contains('move') ||
        lowerMessage.contains('exercise') ||
        lowerMessage.contains('walk')) return 'movement';
    if (lowerMessage.contains('eat') ||
        lowerMessage.contains('nutrition') ||
        lowerMessage.contains('food')) return 'nutrition';
    if (lowerMessage.contains('focus') || lowerMessage.contains('concentrate'))
      return 'focus';
    if (lowerMessage.contains('calm') ||
        lowerMessage.contains('relax') ||
        lowerMessage.contains('mindful')) return 'calm';
    return 'focus';
  }

  static String _mapTechniqueToTone(String technique) {
    switch (technique.toLowerCase()) {
      case 'positive_framing':
      case 'celebration':
        return 'encouraging';
      case 'simplification':
      case 'default_options':
        return 'gentle';
      case 'commitment_device':
      case 'anchoring':
        return 'motivating';
      case 'salience':
      case 'priming':
        return 'inspiring';
      default:
        return 'gentle';
    }
  }

  static StarboundNudge _generateFallbackNudge(String userName,
      String complexityProfile, Map<String, dynamic> currentHabits) {
    final fallbackMessages = [
      "Small steps lead to big changes, $userName. What's one tiny action you could take right now?",
      "You're doing great, $userName! Every moment is a fresh start.",
      "Remember $userName, progress isn't always linear. You've got this!",
      "What would make you feel 1% better right now, $userName?",
    ];

    final message =
        fallbackMessages[DateTime.now().millisecond % fallbackMessages.length];

    return StarboundNudge(
      id: "fallback_${DateTime.now().millisecondsSinceEpoch}",
      theme: "encouragement",
      message: message,
      tone: "gentle",
      estimatedTime: "<1 min",
      energyRequired: "low",
      complexityProfileFit: [complexityProfile],
      triggersFrom: ["ai_fallback"],
      source: NudgeSource.dynamic,
      generatedAt: DateTime.now(),
      metadata: {
        "generation_type": "fallback",
        "user_name": userName,
        "complexity_profile": complexityProfile,
      },
    );
  }
}

// Simple factory to access GemmaAI service without circular imports
class _GemmaAIServiceFactory {
  static dynamic _instance;

  static dynamic getInstance() {
    if (_instance == null) {
      // Import the service dynamically
      try {
        // This will be replaced with proper dependency injection in production
        final serviceType = 'GemmaAIService'; // Dynamic type lookup
        _instance = _createServiceInstance(serviceType);
      } catch (e) {
        throw Exception('Failed to create GemmaAI service instance: $e');
      }
    }
    return _instance;
  }

  static dynamic _createServiceInstance(String serviceType) {
    // This would use reflection or dependency injection in a real app
    // For now, we'll simulate the service behavior
    return _GemmaAIServiceStub();
  }
}

// Stub implementation for GemmaAI service to avoid import cycles
class _GemmaAIServiceStub {
  Future<Map<String, dynamic>> generatePersonalizedNudge({
    required String userName,
    required String complexityProfile,
    required Map<String, dynamic> currentHabits,
    required Map<String, dynamic> contextData,
  }) async {
    // This stub simulates the AI service behavior
    // In production, this would be replaced with actual GemmaAI service integration

    await Future.delayed(
        Duration(milliseconds: 500)); // Simulate AI processing time

    final concerns = _identifyPrimaryConcerns(currentHabits);
    final technique = _selectTechniqueForProfile(complexityProfile, concerns);
    final message = _generateBehavioralMessage(
        userName, complexityProfile, technique, concerns);

    return {
      'message': message,
      'technique': technique,
      'behavioralPrinciple': _getBehavioralPrincipleExplanation(technique),
      'estimatedTime':
          _getEstimatedTimeForTechnique(technique, complexityProfile),
      'energyRequired':
          _getEnergyRequiredForTechnique(technique, complexityProfile),
      'sources': _generateBehavioralSources(technique),
    };
  }

  List<String> _identifyPrimaryConcerns(Map<String, dynamic> currentHabits) {
    final concerns = <String>[];

    currentHabits.forEach((key, value) {
      if (value == null ||
          value == 'poor' ||
          value == 'low' ||
          value == 'none' ||
          value == 'skipped') {
        switch (key) {
          case 'sleep':
            concerns.add('sleep_quality');
            break;
          case 'hydration':
            concerns.add('hydration_low');
            break;
          case 'meals':
            concerns.add('nutrition_poor');
            break;
          case 'movement':
            concerns.add('physical_activity');
            break;
          case 'screenBreaks':
            concerns.add('digital_wellness');
            break;
          case 'stress':
            concerns.add('stress_management');
            break;
        }
      }
    });

    return concerns;
  }

  String _selectTechniqueForProfile(
      String complexityProfile, List<String> concerns) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return 'default_option';
      case 'overloaded':
        return 'positive_framing';
      case 'trying':
        return 'commitment_device';
      default:
        return 'individualization';
    }
  }

  String _generateBehavioralMessage(String userName, String complexityProfile,
      String technique, List<String> concerns) {
    final name = userName.isNotEmpty ? userName : 'friend';

    switch (technique) {
      case 'default_option':
        if (concerns.contains('hydration_low')) {
          return "Hi $name, I've set a gentle reminder: drink water now. No decisions needed - just one sip when you see this message. 💧";
        }
        return "Hi $name, take three deep breaths right now. No thinking required - just breathe in, breathe out. You've got this. 🌱";

      case 'positive_framing':
        return "Hi $name, you're doing better than you think. Now let's add just 30 seconds of calm breathing to build on that success. 🌟";

      case 'commitment_device':
        return "Hi $name, commit to just 2 minutes of movement today. Set a timer, make it official. Your future self will thank you for this promise. ⏰💪";

      case 'individualization':
        return "Hi $name, this moment is designed specifically for you. What does YOUR body and mind need most right now? Honor that. ✨❤️";

      default:
        return "Hi $name, your wellbeing matters. Take a moment right now to do something kind for yourself - even if it's tiny. You deserve this care. 💝";
    }
  }

  String _getBehavioralPrincipleExplanation(String technique) {
    switch (technique) {
      case 'default_option':
        return 'Using defaults to reduce decision fatigue and make healthy choices easier';
      case 'positive_framing':
        return 'Focusing on gains and strengths to boost motivation and confidence';
      case 'commitment_device':
        return 'Using personal promises to increase follow-through on healthy behaviors';
      case 'individualization':
        return 'Tailoring interventions to personal preferences and circumstances';
      default:
        return 'Applying evidence-based behavioral science for sustainable change';
    }
  }

  String _getEstimatedTimeForTechnique(
      String technique, String complexityProfile) {
    if (complexityProfile == 'survival') return '<1 min';
    return technique == 'commitment_device' ? '2-5 mins' : '1-2 mins';
  }

  String _getEnergyRequiredForTechnique(
      String technique, String complexityProfile) {
    if (complexityProfile == 'survival' || complexityProfile == 'overloaded')
      return 'very low';
    return technique == 'commitment_device' ? 'medium' : 'low';
  }

  List<Map<String, String>> _generateBehavioralSources(String technique) {
    return [
      {
        'title': 'Behavioral Science in Health',
        'source': 'Penn Medicine Nudge Unit',
        'type': 'Medical',
        'icon': '🧠',
        'url': 'https://nudgeunit.upenn.edu/'
      },
      {
        'title': 'AI-Personalized for your profile',
        'source': 'Starbound Behavioral AI',
        'type': 'AI-generated',
        'icon': '🤖'
      }
    ];
  }

  // Extract theme from AI-generated message
  static String _extractThemeFromMessage(String message) {
    final messageLower = message.toLowerCase();

    if (messageLower.contains('water') || messageLower.contains('hydrat'))
      return 'hydration';
    if (messageLower.contains('sleep') || messageLower.contains('rest'))
      return 'sleep';
    if (messageLower.contains('move') || messageLower.contains('exercise'))
      return 'movement';
    if (messageLower.contains('eat') || messageLower.contains('nutrition'))
      return 'nutrition';
    if (messageLower.contains('breath') || messageLower.contains('stress'))
      return 'calm';
    if (messageLower.contains('focus') || messageLower.contains('attention'))
      return 'focus';

    return 'general';
  }

  // Map behavioral science technique to nudge tone
  static String _mapTechniqueToTone(String technique) {
    switch (technique) {
      case 'default_option':
      case 'simplification':
        return 'gentle';
      case 'positive_framing':
      case 'anchoring':
        return 'encouraging';
      case 'commitment_device':
      case 'salience':
        return 'motivating';
      case 'priming':
      case 'individualization':
        return 'supportive';
      default:
        return 'gentle';
    }
  }

  // Fallback nudge generation for when AI is unavailable
  static StarboundNudge _generateFallbackNudge(String userName,
      String complexityProfile, Map<String, dynamic> currentHabits) {
    final now = DateTime.now();
    final name = userName.isNotEmpty ? userName : 'friend';

    String message;
    String theme;

    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        message =
            "Hi $name, you're doing so much just by being here. Take one breath for yourself right now. 🌱";
        theme = 'calm';
        break;
      case 'overloaded':
        message =
            "Hi $name, you're managing a lot. Try one tiny act of self-care - even drinking water counts. ⚖️";
        theme = 'hydration';
        break;
      case 'trying':
        message =
            "Hi $name, your growth mindset is inspiring. What's one small step you could take for yourself today? 💡";
        theme = 'general';
        break;
      default:
        message =
            "Hi $name, you have the power to make positive changes. What feels most supportive right now? ✨";
        theme = 'general';
    }

    return StarboundNudge(
      id: "fallback_nudge_${now.millisecondsSinceEpoch}",
      theme: theme,
      message: message,
      tone: 'gentle',
      estimatedTime: '<1 min',
      energyRequired: 'very low',
      complexityProfileFit: [complexityProfile],
      triggersFrom: ['fallback_generation'],
      source: NudgeSource.dynamic,
      generatedAt: now,
      metadata: {
        'generation_type': 'fallback',
        'ai_generated': false,
      },
    );
  }

  // Generate nudge from habit suggestion
  static StarboundNudge generateFromSuggestion({
    required String habitKey,
    required String habitTitle,
    required String rationale,
    required double successProbability,
    required String complexityLevel,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final tone = _selectTone(successProbability, complexityLevel);
    final prefix = _getPrefix(tone);
    final action = _getActionForHabit(habitKey);
    final encouragement =
        _getEncouragement(successProbability, complexityLevel);

    final message = "$prefix$action $encouragement";

    return StarboundNudge(
      id: "dynamic_${habitKey}_${now.millisecondsSinceEpoch}",
      theme: _getThemeForHabit(habitKey),
      message: message,
      tone: tone,
      estimatedTime: _getEstimatedTime(habitKey),
      energyRequired: _getEnergyRequired(habitKey, complexityLevel),
      complexityProfileFit: [complexityLevel],
      triggersFrom: ["recommendation_engine"],
      source: NudgeSource.dynamic,
      generatedAt: now,
      metadata: {
        "habit_key": habitKey,
        "success_probability": successProbability,
        "rationale": rationale,
        "generation_type": "habit_suggestion",
        ...?metadata,
      },
    );
  }

  // Generate intervention nudge for declining patterns
  static StarboundNudge generateInterventionNudge({
    required String habitKey,
    required String pattern,
    required String complexityLevel,
    int streakLength = 0,
  }) {
    final now = DateTime.now();
    final tone = "encouraging";
    final habitName = _formatHabitName(habitKey);

    String message;
    if (streakLength > 0) {
      message =
          "Your $streakLength-day $habitName streak is worth protecting. Even 30 seconds counts to keep it alive.";
    } else {
      message =
          "It's okay to have off days with $habitName. What's the smallest step you could take right now?";
    }

    return StarboundNudge(
      id: "intervention_${habitKey}_${now.millisecondsSinceEpoch}",
      theme: _getThemeForHabit(habitKey),
      message: message,
      tone: tone,
      estimatedTime: "<1 min",
      energyRequired: "very low",
      complexityProfileFit: [complexityLevel],
      triggersFrom: ["pattern_recognition", "streak_protection"],
      source: NudgeSource.emergency,
      generatedAt: now,
      metadata: {
        "habit_key": habitKey,
        "pattern": pattern,
        "streak_length": streakLength,
        "generation_type": "intervention",
      },
    );
  }

  // Generate correlation-based nudge
  static StarboundNudge generateCorrelationNudge({
    required String habit1,
    required String habit2,
    required double correlationStrength,
    required String complexityLevel,
    required String correlationType,
  }) {
    final now = DateTime.now();
    final habit1Name = _formatHabitName(habit1);
    final habit2Name = _formatHabitName(habit2);

    String message;
    if (correlationType == "positive") {
      message =
          "Since you're doing well with $habit1Name, this might be a great time to try $habit2Name too!";
    } else if (correlationType == "temporal") {
      message =
          "You often follow $habit1Name with $habit2Name. Ready to continue the pattern?";
    } else {
      message =
          "Based on your patterns, $habit2Name could complement your $habit1Name routine.";
    }

    return StarboundNudge(
      id: "correlation_${habit1}_${habit2}_${now.millisecondsSinceEpoch}",
      theme: _getThemeForHabit(habit2),
      message: message,
      tone: "encouraging",
      estimatedTime: _getEstimatedTime(habit2),
      energyRequired: _getEnergyRequired(habit2, complexityLevel),
      complexityProfileFit: [complexityLevel],
      triggersFrom: ["correlation_analysis"],
      source: NudgeSource.dynamic,
      generatedAt: now,
      metadata: {
        "primary_habit": habit1,
        "suggested_habit": habit2,
        "correlation_strength": correlationStrength,
        "correlation_type": correlationType,
        "generation_type": "correlation",
      },
    );
  }

  // Generate seasonal nudge
  static StarboundNudge generateSeasonalNudge({
    required String habitKey,
    required String season,
    required String complexityLevel,
  }) {
    final now = DateTime.now();
    final habitName = _formatHabitName(habitKey);

    String message;
    switch (season.toLowerCase()) {
      case "winter":
        if (habitKey.contains("vitamin")) {
          message =
              "Winter is here! Perfect time to prioritize $habitName for immune support.";
        } else if (habitKey.contains("indoor")) {
          message =
              "Cold weather makes $habitName even more appealing. Cozy up and give it a try!";
        } else {
          message =
              "As the days get shorter, $habitName can help maintain your energy and mood.";
        }
        break;
      case "summer":
        if (habitKey.contains("hydration")) {
          message =
              "Summer heat makes $habitName extra important. Your body will thank you!";
        } else if (habitKey.contains("outdoor")) {
          message =
              "Beautiful weather ahead! Perfect time to embrace $habitName.";
        } else {
          message =
              "Summer energy is on your side - great time to focus on $habitName.";
        }
        break;
      case "spring":
        message =
            "Spring renewal energy! Nature is waking up, and so can your $habitName routine.";
        break;
      case "fall":
        message =
            "Fall preparation mode! Time to strengthen your $habitName habit before winter.";
        break;
      default:
        message =
            "This season brings new opportunities for $habitName. Ready to embrace it?";
    }

    return StarboundNudge(
      id: "seasonal_${habitKey}_${now.millisecondsSinceEpoch}",
      theme: _getThemeForHabit(habitKey),
      message: message,
      tone: "motivating",
      estimatedTime: _getEstimatedTime(habitKey),
      energyRequired: _getEnergyRequired(habitKey, complexityLevel),
      complexityProfileFit: [complexityLevel],
      triggersFrom: ["seasonal_adaptation"],
      source: NudgeSource.dynamic,
      generatedAt: now,
      metadata: {
        "habit_key": habitKey,
        "season": season,
        "generation_type": "seasonal",
      },
    );
  }

  static const List<String> _encouragingPrefixes = [
    "You've got this! ",
    "Small steps lead to big changes. ",
    "Every bit of progress counts. ",
    "One moment at a time. ",
    "Building momentum: ",
  ];

  static const List<String> _celebratoryPrefixes = [
    "Amazing progress! ",
    "You're on a roll! ",
    "Look at you go! ",
    "Fantastic job! ",
    "Keep it up! ",
  ];

  static const List<String> _gentlePrefixes = [
    "When you're ready, ",
    "Take your time with this: ",
    "If it feels right, ",
    "Consider trying: ",
    "A gentle suggestion: ",
  ];

  // Helper methods for nudge generation
  static String _selectTone(double successProbability, String complexityLevel) {
    if (complexityLevel == "survival" || complexityLevel == "overloaded") {
      return "gentle";
    } else if (successProbability > 75) {
      return "motivating";
    } else if (successProbability > 50) {
      return "encouraging";
    } else {
      return "gentle";
    }
  }

  static String _getPrefix(String tone) {
    switch (tone) {
      case "encouraging":
        return _encouragingPrefixes[
            DateTime.now().millisecond % _encouragingPrefixes.length];
      case "motivating":
        return _celebratoryPrefixes[
            DateTime.now().millisecond % _celebratoryPrefixes.length];
      case "gentle":
      default:
        return _gentlePrefixes[
            DateTime.now().millisecond % _gentlePrefixes.length];
    }
  }

  static String _getActionForHabit(String habitKey) {
    switch (habitKey) {
      case "hydration":
        return "drink a glass of water.";
      case "deep_breathing":
        return "take 3 deep breaths.";
      case "gratitude":
        return "think of one thing you're grateful for.";
      case "stretching":
        return "do a gentle stretch.";
      case "movement":
        return "move your body for a minute.";
      case "sleep":
        return "prepare for restful sleep.";
      case "meditation":
        return "take a moment to be present.";
      case "journaling":
        return "write down one thought.";
      default:
        return "try ${_formatHabitName(habitKey)}.";
    }
  }

  static String _getEncouragement(
      double successProbability, String complexityLevel) {
    if (complexityLevel == "survival") {
      return "Every small step is a victory.";
    } else if (complexityLevel == "overloaded") {
      return "You've got this, one moment at a time.";
    } else if (successProbability > 80) {
      return "You're ready for this!";
    } else if (successProbability > 60) {
      return "This feels achievable for you.";
    } else {
      return "Start small and see how it feels.";
    }
  }

  static String _getThemeForHabit(String habitKey) {
    if (habitKey.contains("water") || habitKey.contains("hydration"))
      return "hydration";
    if (habitKey.contains("sleep") || habitKey.contains("rest")) return "sleep";
    if (habitKey.contains("move") || habitKey.contains("exercise"))
      return "movement";
    if (habitKey.contains("breath") || habitKey.contains("meditat"))
      return "calm";
    if (habitKey.contains("food") || habitKey.contains("nutrition"))
      return "nutrition";
    if (habitKey.contains("focus") || habitKey.contains("work")) return "focus";
    return "wellbeing";
  }

  static String _getEstimatedTime(String habitKey) {
    final quickHabits = ["hydration", "deep_breathing", "gratitude"];
    final mediumHabits = ["stretching", "journaling", "meditation"];

    if (quickHabits.any((h) => habitKey.contains(h))) return "<1 min";
    if (mediumHabits.any((h) => habitKey.contains(h))) return "2-5 min";
    return "5-10 min";
  }

  static String _getEnergyRequired(String habitKey, String complexityLevel) {
    if (complexityLevel == "survival" || complexityLevel == "overloaded") {
      return "very low";
    }

    final lowEnergyHabits = ["hydration", "deep_breathing", "gratitude"];
    final mediumEnergyHabits = ["stretching", "meditation", "journaling"];

    if (lowEnergyHabits.any((h) => habitKey.contains(h))) return "low";
    if (mediumEnergyHabits.any((h) => habitKey.contains(h))) return "medium";
    return "medium";
  }

  static String _formatHabitName(String habitKey) {
    return habitKey.replaceAll('_', ' ').toLowerCase();
  }
}
