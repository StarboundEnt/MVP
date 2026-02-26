enum ComplexityLevel { stable, trying, overloaded, survival }

/// Mapped average score thresholds for each complexity profile.
class ComplexityProfileThreshold {
  const ComplexityProfileThreshold({
    required this.level,
    required this.minAverage,
    required this.maxAverage,
    required this.interpretation,
  });

  final ComplexityLevel level;
  final double minAverage;
  final double maxAverage;
  final String interpretation;

  bool contains(double score) =>
      score >= minAverage && score <= maxAverage;
}

const List<ComplexityProfileThreshold> complexityProfileThresholds = [
  ComplexityProfileThreshold(
    level: ComplexityLevel.stable,
    minAverage: 1.0,
    maxAverage: 1.9,
    interpretation:
        'Plenty of capacity for new habits and longer-term planning.',
  ),
  ComplexityProfileThreshold(
    level: ComplexityLevel.trying,
    minAverage: 2.0,
    maxAverage: 2.9,
    interpretation: 'Handling some bumps — focus on small, flexible wins.',
  ),
  ComplexityProfileThreshold(
    level: ComplexityLevel.overloaded,
    minAverage: 3.0,
    maxAverage: 3.9,
    interpretation:
        'Significant stress; just maintaining basics counts as success.',
  ),
  ComplexityProfileThreshold(
    level: ComplexityLevel.survival,
    minAverage: 4.0,
    maxAverage: 5.0,
    interpretation:
        'Bandwidth near zero; any act of self-care matters.',
  ),
];

class OnboardingSectionDefinition {
  const OnboardingSectionDefinition({
    required this.id,
    required this.title,
    required this.questions,
  });

  final String id;
  final String title;
  final List<OnboardingQuestionDefinition> questions;
}

class OnboardingQuestionDefinition {
  const OnboardingQuestionDefinition({
    required this.id,
    required this.label,
    required this.profileSignal,
    required this.options,
    this.icon,
    this.category,
    this.appliesToScoring = true,
    this.isMultiSelect = false,
    this.isTextArea = false,
  });

  final String id;
  final String label;
  final String profileSignal;
  final List<OnboardingOptionDefinition> options;
  final String? icon;
  final ComplexityCategory? category;
  final bool appliesToScoring;
  final bool isMultiSelect; // NEW: Allows multiple selections
  final bool isTextArea; // NEW: Renders as text area instead of options
}

class OnboardingOptionDefinition {
  const OnboardingOptionDefinition({
    required this.id,
    required this.label,
    this.score,
    this.icon,
  });

  final String id;
  final String label;
  final double? score;
  final String? icon;
}

const OnboardingSectionDefinition onboardingSectionA =
    OnboardingSectionDefinition(
  id: 'section_a',
  title: 'Section A — About You',
  questions: [
    OnboardingQuestionDefinition(
      id: 'A1',
      label: 'What should we call you?',
      profileSignal: 'Pseudonym (optional, default "Explorer")',
      icon: 'user',
      appliesToScoring: false,
      options: [
        OnboardingOptionDefinition(id: 'a1_explorer', label: 'Explorer (default)'),
        OnboardingOptionDefinition(id: 'a1_custom', label: 'Enter custom name'),
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'A2',
      label: 'Which area are you in?',
      profileSignal: 'Neighborhood/region',
      icon: 'home',
      appliesToScoring: false,
      options: [
        OnboardingOptionDefinition(id: 'a2_inner_sydney', label: 'Inner Sydney'),
        OnboardingOptionDefinition(id: 'a2_eastern_suburbs', label: 'Eastern Suburbs'),
        OnboardingOptionDefinition(id: 'a2_inner_west', label: 'Inner West'),
        OnboardingOptionDefinition(id: 'a2_canterbury_bankstown', label: 'Canterbury-Bankstown'),
        OnboardingOptionDefinition(id: 'a2_south_western', label: 'South Western Sydney'),
        OnboardingOptionDefinition(id: 'a2_western', label: 'Western Sydney'),
        OnboardingOptionDefinition(id: 'a2_northern', label: 'Northern Suburbs'),
        OnboardingOptionDefinition(id: 'a2_north_shore', label: 'North Shore'),
        OnboardingOptionDefinition(id: 'a2_sutherland', label: 'Sutherland Shire'),
        OnboardingOptionDefinition(id: 'a2_hills', label: 'Hills District'),
        OnboardingOptionDefinition(id: 'a2_outer_western', label: 'Outer Western Sydney'),
        OnboardingOptionDefinition(id: 'a2_regional', label: 'Outside Sydney metro (regional NSW)'),
        OnboardingOptionDefinition(id: 'a2_prefer_not', label: 'Prefer not to say'),
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'A3',
      label: 'What languages do you speak?',
      profileSignal: 'Languages (multi-select)',
      icon: 'users',
      appliesToScoring: false,
      isMultiSelect: true,
      options: [
        OnboardingOptionDefinition(id: 'a3_english', label: 'English'),
        OnboardingOptionDefinition(id: 'a3_spanish', label: 'Spanish'),
        OnboardingOptionDefinition(id: 'a3_arabic', label: 'Arabic'),
        OnboardingOptionDefinition(id: 'a3_mandarin', label: 'Mandarin'),
        OnboardingOptionDefinition(id: 'a3_somali', label: 'Somali'),
        OnboardingOptionDefinition(id: 'a3_other', label: 'Other'),
      ],
    ),
  ],
);

const OnboardingSectionDefinition onboardingSectionB =
    OnboardingSectionDefinition(
  id: 'section_b',
  title: 'Section B — Understanding Your Situation',
  questions: [
    OnboardingQuestionDefinition(
      id: 'B1',
      label: 'What makes healthcare hard for you? (Select all that apply)',
      profileSignal: 'Health access barriers (multi-select)',
      icon: 'stethoscope',
      appliesToScoring: false,
      isMultiSelect: true,
      options: [
        OnboardingOptionDefinition(
          id: 'b1_cost',
          label: 'Cost / Can\'t afford it',
          icon: 'wallet',
        ),
        OnboardingOptionDefinition(
          id: 'b1_insurance',
          label: 'No insurance or bad coverage',
          icon: 'heart-handshake',
        ),
        OnboardingOptionDefinition(
          id: 'b1_transportation',
          label: 'Transportation / Getting there is difficult',
          icon: 'shuffle',
        ),
        OnboardingOptionDefinition(
          id: 'b1_time',
          label: 'Time / Work schedule makes it hard',
          icon: 'clock',
        ),
        OnboardingOptionDefinition(
          id: 'b1_childcare',
          label: 'Childcare / Can\'t bring kids or leave them',
          icon: 'users',
        ),
        OnboardingOptionDefinition(
          id: 'b1_language',
          label: 'Language barriers',
          icon: 'users',
        ),
        OnboardingOptionDefinition(
          id: 'b1_navigation',
          label: 'Don\'t know where to go',
          icon: 'compass',
        ),
        OnboardingOptionDefinition(
          id: 'b1_bad_experiences',
          label: 'Bad experiences / Don\'t trust system',
          icon: 'warning',
        ),
        OnboardingOptionDefinition(
          id: 'b1_immigration',
          label: 'Immigration concerns',
          icon: 'lock',
        ),
        OnboardingOptionDefinition(
          id: 'b1_accessibility',
          label: 'Physical accessibility',
          icon: 'adjust',
        ),
        OnboardingOptionDefinition(
          id: 'b1_other',
          label: 'Other',
          icon: 'sliders',
        ),
      ],
    ),
  ],
);

const OnboardingSectionDefinition onboardingSectionC =
    OnboardingSectionDefinition(
  id: 'section_c',
  title: 'Section C — Health Focus (Optional)',
  questions: [
    OnboardingQuestionDefinition(
      id: 'C1',
      label: 'What health topics are you focused on? (Select all that apply)',
      profileSignal: 'Health interests (multi-select, optional)',
      icon: 'heart',
      appliesToScoring: false,
      isMultiSelect: true,
      options: [
        OnboardingOptionDefinition(
          id: 'c1_diabetes',
          label: 'Diabetes & blood sugar',
          icon: 'droplet',
        ),
        OnboardingOptionDefinition(
          id: 'c1_blood_pressure',
          label: 'Blood pressure & heart health',
          icon: 'heart',
        ),
        OnboardingOptionDefinition(
          id: 'c1_mental_health',
          label: 'Mental health & stress',
          icon: 'brain',
        ),
        OnboardingOptionDefinition(
          id: 'c1_pregnancy',
          label: 'Pregnancy & maternal health',
          icon: 'heart-handshake',
        ),
        OnboardingOptionDefinition(
          id: 'c1_children',
          label: 'Children\'s health',
          icon: 'users',
        ),
        OnboardingOptionDefinition(
          id: 'c1_pain',
          label: 'Pain management',
          icon: 'lifebuoy',
        ),
        OnboardingOptionDefinition(
          id: 'c1_sexual_health',
          label: 'Sexual & reproductive health',
          icon: 'heart',
        ),
        OnboardingOptionDefinition(
          id: 'c1_nutrition',
          label: 'Nutrition & food access',
          icon: 'utensils',
        ),
        OnboardingOptionDefinition(
          id: 'c1_substance_use',
          label: 'Substance use support',
          icon: 'lifebuoy',
        ),
        OnboardingOptionDefinition(
          id: 'c1_chronic_illness',
          label: 'Chronic illness management',
          icon: 'stethoscope',
        ),
        OnboardingOptionDefinition(
          id: 'c1_general',
          label: 'General health / Not sure yet',
          icon: 'compass',
        ),
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'C2',
      label: 'What is your work schedule like?',
      profileSignal: 'Work schedule (helps us suggest best times)',
      icon: 'calendar-check',
      appliesToScoring: false,
      options: [
        OnboardingOptionDefinition(
          id: 'c2_regular_day',
          label: 'Regular day job (9-5)',
          icon: 'sunrise',
        ),
        OnboardingOptionDefinition(
          id: 'c2_night_shift',
          label: 'Night shift',
          icon: 'calendar',
        ),
        OnboardingOptionDefinition(
          id: 'c2_irregular',
          label: 'Irregular / Rotating shifts',
          icon: 'shuffle',
        ),
        OnboardingOptionDefinition(
          id: 'c2_multiple_jobs',
          label: 'Multiple jobs',
          icon: 'calendar-range',
        ),
        OnboardingOptionDefinition(
          id: 'c2_flexible',
          label: 'Flexible schedule',
          icon: 'sliders',
        ),
        OnboardingOptionDefinition(
          id: 'c2_not_working',
          label: 'Not working right now',
          icon: 'home',
        ),
        OnboardingOptionDefinition(
          id: 'c2_prefer_not',
          label: 'Prefer not to say',
          icon: 'bell-off',
        ),
      ],
    ),
  ],
);

const OnboardingSectionDefinition onboardingSectionD =
    OnboardingSectionDefinition(
  id: 'section_d',
  title: 'Section D — Your Preferences',
  questions: [
    OnboardingQuestionDefinition(
      id: 'D1',
      label: 'How often should we check in?',
      profileSignal: 'Check-in frequency',
      icon: 'calendar-check',
      appliesToScoring: false,
      options: [
        OnboardingOptionDefinition(
          id: 'd1_daily',
          label: 'Daily',
          icon: 'sunrise',
        ),
        OnboardingOptionDefinition(
          id: 'd1_few_week',
          label: 'A few times a week',
          icon: 'calendar-range',
        ),
        OnboardingOptionDefinition(
          id: 'd1_weekly',
          label: 'Weekly',
          icon: 'calendar',
        ),
        OnboardingOptionDefinition(
          id: 'd1_changes',
          label: 'Only when something changes',
          icon: 'bell-off',
        ),
      ],
    ),
    OnboardingQuestionDefinition(
      id: 'D2',
      label: 'Anything else you want us to know?',
      profileSignal: 'Additional notes (optional)',
      icon: 'book-open',
      appliesToScoring: false,
      isTextArea: true,
      options: [], // Text area - handled specially in UI
    ),
  ],
);

const List<OnboardingSectionDefinition> onboardingSections = [
  onboardingSectionA,
  onboardingSectionB,
  onboardingSectionC,
  onboardingSectionD,
];

/// Structured metadata for onboarding questions grouped by section.

enum ComplexityCategory {
  livingCircumstances,
  mentalHealth,
  physicalHealth,
  socialSupport,
  timeCapacity,
  financialStability,
  careResponsibilities,
}

class ComplexityAssessment {
  final Map<ComplexityLevel, int> scores;
  final ComplexityLevel primaryLevel;
  final ComplexityLevel secondaryLevel;
  final List<ComplexityCategory> highStressCategories;
  final List<ComplexityCategory> supportiveCategories;
  final DateTime assessmentDate;
  final Map<String, String> responses;
  
  // Dynamic analysis fields
  final ComplexityLevel? livedExperienceLevel;
  final double? livedExperienceConfidence;
  final Map<String, int>? recentTagFrequency;
  final List<String>? criticalIndicators;
  final List<String>? positiveIndicators;
  final DateTime? lastAnalysisDate;
  final bool? needsReassessment;

  ComplexityAssessment({
    required this.scores,
    required this.primaryLevel,
    required this.secondaryLevel,
    required this.highStressCategories,
    required this.supportiveCategories,
    required this.responses,
    // Dynamic analysis parameters
    this.livedExperienceLevel,
    this.livedExperienceConfidence,
    this.recentTagFrequency,
    this.criticalIndicators,
    this.positiveIndicators,
    this.lastAnalysisDate,
    this.needsReassessment,
  }) : assessmentDate = DateTime.now();

  // Get personalized description based on profile
  String getDescription() {
    switch (primaryLevel) {
      case ComplexityLevel.stable:
        return "You're in a stable phase with good capacity for building new habits. You have the mental and physical space to focus on growth and can handle moderate challenges.";
      case ComplexityLevel.trying:
        return "You're navigating some challenges but have moments of stability. You can work on small, manageable changes when you have the energy and focus.";
      case ComplexityLevel.overloaded:
        return "You're dealing with significant stress and have limited capacity. Focus on maintaining what you can and being gentle with yourself during this demanding time.";
      case ComplexityLevel.survival:
        return "You're in survival mode, dealing with intense challenges. Right now, just getting through each day is an achievement. Any small act of self-care is valuable.";
    }
  }

  // Get recommended approach based on profile
  String getApproach() {
    switch (primaryLevel) {
      case ComplexityLevel.stable:
        return "Build sustainable habits, set meaningful goals, and explore new areas of growth. You can handle complexity and long-term planning.";
      case ComplexityLevel.trying:
        return "Focus on one small thing at a time, celebrate micro-wins, and be flexible with your goals. Some days will be better than others.";
      case ComplexityLevel.overloaded:
        return "Prioritize bare essentials, use shortcuts and convenience options, and don't add pressure to change. Maintenance is success.";
      case ComplexityLevel.survival:
        return "Any small step counts as a victory. Focus on immediate needs, use all available support, and remember that this phase will pass.";
    }
  }

  // Get recommended nudge frequency
  Duration getRecommendedNudgeFrequency() {
    switch (primaryLevel) {
      case ComplexityLevel.stable:
        return const Duration(hours: 8);
      case ComplexityLevel.trying:
        return const Duration(hours: 12);
      case ComplexityLevel.overloaded:
        return const Duration(days: 1);
      case ComplexityLevel.survival:
        return const Duration(days: 2);
    }
  }
  
  // Dynamic analysis helper methods
  
  /// Check if lived experience suggests different complexity level
  bool hasProfileDiscrepancy() {
    return livedExperienceLevel != null && 
           livedExperienceLevel != primaryLevel &&
           (livedExperienceConfidence ?? 0.0) > 0.6;
  }
  
  /// Get the suggested complexity level (lived experience or static)
  ComplexityLevel getEffectiveComplexityLevel() {
    if (hasProfileDiscrepancy()) {
      return livedExperienceLevel!;
    }
    return primaryLevel;
  }
  
  /// Get lived experience insights
  String getLivedExperienceInsight() {
    if (livedExperienceLevel == null) {
      return "Share more reflections for personalized insights";
    }
    
    if (!hasProfileDiscrepancy()) {
      return "Your reflections align with your assessed profile";
    }
    
    final direction = _getComplexityLevelIndex(livedExperienceLevel!) > 
                     _getComplexityLevelIndex(primaryLevel) ? "higher" : "lower";
    
    return "Your recent reflections suggest ${direction} complexity than your assessment";
  }
  
  /// Get critical indicators summary
  String getCriticalIndicatorsSummary() {
    if (criticalIndicators == null || criticalIndicators!.isEmpty) {
      return "No critical stress patterns detected";
    }
    
    final indicators = criticalIndicators!.take(3).map((tag) => 
        tag.replaceAll('_', ' ')).join(", ");
    
    return "Key stress areas: $indicators";
  }
  
  /// Get positive indicators summary
  String getPositiveIndicatorsSummary() {
    if (positiveIndicators == null || positiveIndicators!.isEmpty) {
      return "Consider reflecting on positive experiences too";
    }
    
    final indicators = positiveIndicators!.take(3).map((tag) => 
        tag.replaceAll('_', ' ')).join(", ");
    
    return "Strength areas: $indicators";
  }
  
  /// Check if analysis data is fresh (within last 24 hours)
  bool isAnalysisFresh() {
    if (lastAnalysisDate == null) return false;
    return DateTime.now().difference(lastAnalysisDate!).inHours < 24;
  }
  
  int _getComplexityLevelIndex(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable: return 0;
      case ComplexityLevel.trying: return 1;
      case ComplexityLevel.overloaded: return 2;
      case ComplexityLevel.survival: return 3;
    }
  }
  
  /// Create a copy with updated dynamic analysis data
  ComplexityAssessment copyWithDynamicAnalysis({
    ComplexityLevel? livedExperienceLevel,
    double? livedExperienceConfidence,
    Map<String, int>? recentTagFrequency,
    List<String>? criticalIndicators,
    List<String>? positiveIndicators,
    DateTime? lastAnalysisDate,
    bool? needsReassessment,
  }) {
    return ComplexityAssessment(
      scores: scores,
      primaryLevel: primaryLevel,
      secondaryLevel: secondaryLevel,
      highStressCategories: highStressCategories,
      supportiveCategories: supportiveCategories,
      responses: responses,
      livedExperienceLevel: livedExperienceLevel ?? this.livedExperienceLevel,
      livedExperienceConfidence: livedExperienceConfidence ?? this.livedExperienceConfidence,
      recentTagFrequency: recentTagFrequency ?? this.recentTagFrequency,
      criticalIndicators: criticalIndicators ?? this.criticalIndicators,
      positiveIndicators: positiveIndicators ?? this.positiveIndicators,
      lastAnalysisDate: lastAnalysisDate ?? this.lastAnalysisDate,
      needsReassessment: needsReassessment ?? this.needsReassessment,
    );
  }
  
  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'scores': scores.map((level, score) => MapEntry(level.index.toString(), score)),
      'primaryLevel': primaryLevel.index,
      'secondaryLevel': secondaryLevel.index,
      'highStressCategories': highStressCategories.map((c) => c.index).toList(),
      'supportiveCategories': supportiveCategories.map((c) => c.index).toList(),
      'assessmentDate': assessmentDate.toIso8601String(),
      'responses': responses,
      'livedExperienceLevel': livedExperienceLevel?.index,
      'livedExperienceConfidence': livedExperienceConfidence,
      'recentTagFrequency': recentTagFrequency,
      'criticalIndicators': criticalIndicators,
      'positiveIndicators': positiveIndicators,
      'lastAnalysisDate': lastAnalysisDate?.toIso8601String(),
      'needsReassessment': needsReassessment,
    };
  }
  
  /// Deserialize from JSON
  factory ComplexityAssessment.fromJson(Map<String, dynamic> json) {
    final scoresMap = <ComplexityLevel, int>{};
    final scoresJson = json['scores'] as Map<String, dynamic>? ?? {};
    for (final entry in scoresJson.entries) {
      final levelIndex = int.parse(entry.key);
      if (levelIndex < ComplexityLevel.values.length) {
        scoresMap[ComplexityLevel.values[levelIndex]] = entry.value as int;
      }
    }
    
    return ComplexityAssessment(
      scores: scoresMap,
      primaryLevel: ComplexityLevel.values[json['primaryLevel'] as int? ?? 0],
      secondaryLevel: ComplexityLevel.values[json['secondaryLevel'] as int? ?? 0],
      highStressCategories: (json['highStressCategories'] as List<dynamic>? ?? [])
          .map((index) => ComplexityCategory.values[index as int])
          .toList(),
      supportiveCategories: (json['supportiveCategories'] as List<dynamic>? ?? [])
          .map((index) => ComplexityCategory.values[index as int])
          .toList(),
      responses: Map<String, String>.from(json['responses'] as Map? ?? {}),
      livedExperienceLevel: json['livedExperienceLevel'] != null 
          ? ComplexityLevel.values[json['livedExperienceLevel'] as int]
          : null,
      livedExperienceConfidence: json['livedExperienceConfidence']?.toDouble(),
      recentTagFrequency: json['recentTagFrequency'] != null
          ? Map<String, int>.from(json['recentTagFrequency'] as Map)
          : null,
      criticalIndicators: json['criticalIndicators'] != null
          ? List<String>.from(json['criticalIndicators'] as List)
          : null,
      positiveIndicators: json['positiveIndicators'] != null
          ? List<String>.from(json['positiveIndicators'] as List)
          : null,
      lastAnalysisDate: json['lastAnalysisDate'] != null
          ? DateTime.parse(json['lastAnalysisDate'])
          : null,
      needsReassessment: json['needsReassessment'] as bool?,
    );
  }
}

/// Records when the user's complexity profile shifts and why.
class ComplexityProfileTransition {
  final ComplexityLevel fromLevel;
  final ComplexityLevel toLevel;
  final DateTime timestamp;
  final String reason;
  final double? confidence;

  const ComplexityProfileTransition({
    required this.fromLevel,
    required this.toLevel,
    required this.timestamp,
    required this.reason,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'fromLevel': fromLevel.index,
        'toLevel': toLevel.index,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
        'confidence': confidence,
      };

  factory ComplexityProfileTransition.fromJson(Map<String, dynamic> json) {
    final fromIndex = json['fromLevel'] as int? ?? 0;
    final toIndex = json['toLevel'] as int? ?? 0;
    int _safeIndex(int index) {
      if (index < 0 || index >= ComplexityLevel.values.length) {
        return 0;
      }
      return index;
    }
    return ComplexityProfileTransition(
      fromLevel: ComplexityLevel.values[_safeIndex(fromIndex)],
      toLevel: ComplexityLevel.values[_safeIndex(toIndex)],
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      reason: json['reason'] as String? ?? 'Profile update',
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}



class ComplexityProfileService {
  static const List<OnboardingSectionDefinition> sections = onboardingSections;

  static Iterable<OnboardingQuestionDefinition> get scoringQuestions =>
      sections.expand((section) => section.questions).where(
            (question) =>
                question.appliesToScoring &&
                question.options.any((option) => option.score != null),
          );

  static const double supportiveThreshold = 2.0;
  static const double highStressThreshold = 3.0;

  static ComplexityAssessment calculateComplexityLevel(
      Map<String, String> responses) {
    final scoreValues = <double>[];
    final categoryBuckets = <ComplexityCategory, List<double>>{};

    for (final question in scoringQuestions) {
      final responseId = responses[question.id];
      if (responseId == null) continue;

      final option = question.options.firstWhere(
        (option) => option.id == responseId,
        orElse: () => question.options.first,
      );

      final score = option.score;
      if (score == null) continue;

      scoreValues.add(score);

      final category = question.category;
      if (category != null) {
        categoryBuckets.putIfAbsent(category, () => []).add(score);
      }
    }

    final double averageScore = scoreValues.isNotEmpty
        ? scoreValues.reduce((a, b) => a + b) / scoreValues.length
        : 2.5;

    final scores = <ComplexityLevel, int>{};
    for (final threshold in complexityProfileThresholds) {
      final midpoint = (threshold.minAverage + threshold.maxAverage) / 2;
      final distance = (averageScore - midpoint).abs();
      final closeness = (5.0 - distance).clamp(0.0, 5.0);
      scores[threshold.level] = (closeness / 5.0 * 100).round();
    }

    final sortedLevels = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final primaryLevel = sortedLevels.isNotEmpty
        ? sortedLevels.first.key
        : ComplexityLevel.trying;
    final secondaryLevel = sortedLevels.length > 1
        ? sortedLevels[1].key
        : primaryLevel;

    final highStressCategories = <ComplexityCategory>[];
    final supportiveCategories = <ComplexityCategory>[];

    categoryBuckets.forEach((category, values) {
      if (values.isEmpty) return;
      final average = values.reduce((a, b) => a + b) / values.length;
      if (average >= highStressThreshold) {
        highStressCategories.add(category);
      } else if (average <= supportiveThreshold) {
        supportiveCategories.add(category);
      }
    });

    return ComplexityAssessment(
      scores: scores,
      primaryLevel: primaryLevel,
      secondaryLevel: secondaryLevel,
      highStressCategories: highStressCategories,
      supportiveCategories: supportiveCategories,
      responses: responses,
    );
  }

  static String getCategoryName(ComplexityCategory category) {
    switch (category) {
      case ComplexityCategory.livingCircumstances:
        return 'Living Circumstances';
      case ComplexityCategory.mentalHealth:
        return 'Mental Health';
      case ComplexityCategory.physicalHealth:
        return 'Physical Health';
      case ComplexityCategory.socialSupport:
        return 'Social Support';
      case ComplexityCategory.timeCapacity:
        return 'Time Capacity';
      case ComplexityCategory.financialStability:
        return 'Financial Stability';
      case ComplexityCategory.careResponsibilities:
        return 'Care Responsibilities';
    }
  }

  static String getComplexityLevelMessage(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return 'Looks like you have solid energy to build new habits — let’s turn that momentum into routines that stick.';
      case ComplexityLevel.trying:
        return 'You’re navigating a few bumps but still making progress — we’ll focus on tiny wins that fit the day you’re having.';
      case ComplexityLevel.overloaded:
        return 'You’ve got a lot on your plate — we’ll keep things light and flexible so self-care feels doable.';
      case ComplexityLevel.survival:
        return 'Right now just getting through the day is a feat — we’ll celebrate small moments of care and keep everything gentle.';
    }
  }

  


  static String getComplexityLevelTagline(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return 'Momentum building';
      case ComplexityLevel.trying:
        return 'Finding your rhythm';
      case ComplexityLevel.overloaded:
        return 'Keeping it gentle';
      case ComplexityLevel.survival:
        return 'Care first today';
    }
  }

  static String getComplexityLevelName(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return 'Stable';
      case ComplexityLevel.trying:
        return 'Trying';
      case ComplexityLevel.overloaded:
        return 'Overloaded';
      case ComplexityLevel.survival:
        return 'Survival';
    }
  }
}
