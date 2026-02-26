/// Health barrier assessment model
/// Adapts complexity profiling for health navigation barriers
/// Part of the health navigation transformation

import 'complexity_profile.dart'; // Reuse ComplexityLevel enum

/// Types of barriers people face when trying to access healthcare
enum HealthBarrierCategory {
  cost,            // Can't afford care/medications
  insurance,       // Uninsured or underinsured
  transportation,  // Can't get to appointments
  language,        // Limited English proficiency
  digital,         // No internet/smartphone access
  time,            // Work or caregiving conflicts
  trust,           // Healthcare system distrust
  literacy,        // Health literacy barriers
  documentation,   // Immigration/ID documentation issues
  disability,      // Disability access needs
}

/// Assessment of user's health access barriers
class HealthBarrierAssessment {
  final List<HealthBarrierCategory> primaryBarriers;
  final Map<HealthBarrierCategory, int> barrierSeverity; // 1-5 scale
  final ComplexityLevel navigationComplexity; // Reuse: stable/trying/overloaded/survival
  final String? preferredLanguage;
  final String? location; // Zip code or city
  final DateTime assessmentDate;
  final Map<String, String> responses; // Store original questionnaire responses

  const HealthBarrierAssessment({
    required this.primaryBarriers,
    required this.barrierSeverity,
    required this.navigationComplexity,
    this.preferredLanguage,
    this.location,
    required this.assessmentDate,
    this.responses = const {},
  });

  factory HealthBarrierAssessment.fromJson(Map<String, dynamic> json) {
    final primaryBarriers = (json['primaryBarriers'] as List<dynamic>?)
        ?.map((e) {
          final index = int.tryParse(e.toString()) ?? 0;
          return HealthBarrierCategory.values[index];
        })
        .toList() ?? [];

    final barrierSeverity = <HealthBarrierCategory, int>{};
    if (json['barrierSeverity'] != null) {
      (json['barrierSeverity'] as Map<String, dynamic>).forEach((key, value) {
        final index = int.tryParse(key) ?? 0;
        if (index < HealthBarrierCategory.values.length) {
          barrierSeverity[HealthBarrierCategory.values[index]] =
              int.tryParse(value.toString()) ?? 0;
        }
      });
    }

    return HealthBarrierAssessment(
      primaryBarriers: primaryBarriers,
      barrierSeverity: barrierSeverity,
      navigationComplexity: ComplexityLevel.values[json['navigationComplexity'] as int? ?? 1],
      preferredLanguage: json['preferredLanguage'] as String?,
      location: json['location'] as String?,
      assessmentDate: DateTime.parse(json['assessmentDate'] as String),
      responses: Map<String, String>.from(json['responses'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryBarriers': primaryBarriers.map((b) => b.index).toList(),
      'barrierSeverity': barrierSeverity.map(
        (key, value) => MapEntry(key.index.toString(), value),
      ),
      'navigationComplexity': navigationComplexity.index,
      'preferredLanguage': preferredLanguage,
      'location': location,
      'assessmentDate': assessmentDate.toIso8601String(),
      'responses': responses,
    };
  }

  HealthBarrierAssessment copyWith({
    List<HealthBarrierCategory>? primaryBarriers,
    Map<HealthBarrierCategory, int>? barrierSeverity,
    ComplexityLevel? navigationComplexity,
    String? preferredLanguage,
    String? location,
    DateTime? assessmentDate,
    Map<String, String>? responses,
  }) {
    return HealthBarrierAssessment(
      primaryBarriers: primaryBarriers ?? this.primaryBarriers,
      barrierSeverity: barrierSeverity ?? this.barrierSeverity,
      navigationComplexity: navigationComplexity ?? this.navigationComplexity,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      location: location ?? this.location,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      responses: responses ?? this.responses,
    );
  }

  // Check if user has a specific barrier
  bool hasBarrier(HealthBarrierCategory barrier) {
    return primaryBarriers.contains(barrier);
  }

  // Get severity of a specific barrier (0 if not present)
  int getSeverity(HealthBarrierCategory barrier) {
    return barrierSeverity[barrier] ?? 0;
  }

  // Get barrier display name
  static String getBarrierName(HealthBarrierCategory barrier) {
    switch (barrier) {
      case HealthBarrierCategory.cost:
        return 'Cost/Affordability';
      case HealthBarrierCategory.insurance:
        return 'Insurance Coverage';
      case HealthBarrierCategory.transportation:
        return 'Transportation';
      case HealthBarrierCategory.language:
        return 'Language';
      case HealthBarrierCategory.digital:
        return 'Digital Access';
      case HealthBarrierCategory.time:
        return 'Time/Scheduling';
      case HealthBarrierCategory.trust:
        return 'Trust/Past Experience';
      case HealthBarrierCategory.literacy:
        return 'Health Literacy';
      case HealthBarrierCategory.documentation:
        return 'Documentation';
      case HealthBarrierCategory.disability:
        return 'Disability Access';
    }
  }

  // Get personalized navigation approach based on barriers and complexity
  String getNavigationApproach() {
    // Adapt approach based on navigation complexity (same as wellness complexity)
    switch (navigationComplexity) {
      case ComplexityLevel.stable:
        return "You have good capacity to navigate health systems. We'll connect you to resources and help you make informed decisions.";
      case ComplexityLevel.trying:
        return "You're managing some barriers. We'll find accessible options and support you step-by-step.";
      case ComplexityLevel.overloaded:
        return "You're facing significant challenges. We'll focus on the most accessible, low-barrier resources.";
      case ComplexityLevel.survival:
        return "You're in crisis mode. We'll prioritize emergency resources and immediate support.";
    }
  }

  // Get resource filter criteria based on barriers
  Map<String, dynamic> getResourceFilters() {
    final filters = <String, dynamic>{};

    if (hasBarrier(HealthBarrierCategory.cost) ||
        hasBarrier(HealthBarrierCategory.insurance)) {
      filters['requiresFreeCare'] = true;
      filters['acceptsUninsured'] = true;
    }

    if (hasBarrier(HealthBarrierCategory.transportation)) {
      filters['maxDistance'] = 2.0; // Within 2 miles
      filters['publicTransitAccessible'] = true;
      filters['hasTelehealth'] = true;
    }

    if (hasBarrier(HealthBarrierCategory.language) && preferredLanguage != null) {
      filters['languages'] = [preferredLanguage];
    }

    if (hasBarrier(HealthBarrierCategory.digital)) {
      filters['hasPhoneSupport'] = true; // Prefer phone-based over app-only
      filters['excludeTelehealthOnly'] = true;
    }

    if (hasBarrier(HealthBarrierCategory.time)) {
      filters['hasExtendedHours'] = true;
      filters['hasWeekendHours'] = true;
      filters['hasTelehealth'] = true; // More flexible scheduling
    }

    if (hasBarrier(HealthBarrierCategory.disability)) {
      filters['wheelchairAccessible'] = true;
    }

    return filters;
  }

  // Get priority sorting for resources based on barriers
  List<String> getResourceSortPriority() {
    final priority = <String>[];

    // Most severe barriers get highest priority
    final sortedBarriers = barrierSeverity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedBarriers) {
      switch (entry.key) {
        case HealthBarrierCategory.cost:
        case HealthBarrierCategory.insurance:
          priority.add('cost_friendly');
          break;
        case HealthBarrierCategory.transportation:
          priority.add('proximity');
          priority.add('telehealth');
          break;
        case HealthBarrierCategory.time:
          priority.add('flexible_hours');
          break;
        case HealthBarrierCategory.language:
          priority.add('language_support');
          break;
        default:
          break;
      }
    }

    // Always consider distance/proximity
    if (!priority.contains('proximity')) {
      priority.add('proximity');
    }

    return priority;
  }

  @override
  String toString() {
    return 'HealthBarrierAssessment(barriers: ${primaryBarriers.length}, complexity: ${navigationComplexity.name})';
  }
}

/// Onboarding questions for health barrier assessment
/// Adapts the wellness onboarding to focus on health access barriers

class HealthBarrierQuestion {
  final String id;
  final String label;
  final List<HealthBarrierOption> options;
  final HealthBarrierCategory? category;
  final bool allowMultiple; // For barrier checkboxes

  const HealthBarrierQuestion({
    required this.id,
    required this.label,
    required this.options,
    this.category,
    this.allowMultiple = false,
  });
}

class HealthBarrierOption {
  final String id;
  final String label;
  final int severityScore; // 1-5, how severe this barrier is

  const HealthBarrierOption({
    required this.id,
    required this.label,
    required this.severityScore,
  });
}

/// Health barrier onboarding questions
const List<HealthBarrierQuestion> healthBarrierQuestions = [
  HealthBarrierQuestion(
    id: 'HB1',
    label: 'What makes it hard to get healthcare? (Select all that apply)',
    allowMultiple: true,
    options: [
      HealthBarrierOption(
        id: 'cost',
        label: 'Cost/Can\'t afford',
        severityScore: 5,
      ),
      HealthBarrierOption(
        id: 'no_insurance',
        label: 'No insurance',
        severityScore: 5,
      ),
      HealthBarrierOption(
        id: 'transportation',
        label: 'Getting there',
        severityScore: 4,
      ),
      HealthBarrierOption(
        id: 'language',
        label: 'Language barriers',
        severityScore: 4,
      ),
      HealthBarrierOption(
        id: 'time',
        label: 'Work/time conflicts',
        severityScore: 3,
      ),
      HealthBarrierOption(
        id: 'trust',
        label: 'Don\'t trust the system',
        severityScore: 4,
      ),
      HealthBarrierOption(
        id: 'documentation',
        label: 'Documentation concerns',
        severityScore: 5,
      ),
      HealthBarrierOption(
        id: 'none',
        label: 'No major barriers',
        severityScore: 1,
      ),
    ],
  ),
  HealthBarrierQuestion(
    id: 'HB2',
    label: 'When was your last healthcare visit?',
    options: [
      HealthBarrierOption(
        id: 'recent',
        label: 'Within the last 6 months',
        severityScore: 1,
      ),
      HealthBarrierOption(
        id: 'last_year',
        label: 'Within the last year',
        severityScore: 2,
      ),
      HealthBarrierOption(
        id: 'few_years',
        label: '1-3 years ago',
        severityScore: 3,
      ),
      HealthBarrierOption(
        id: 'long_time',
        label: 'More than 3 years',
        severityScore: 4,
      ),
      HealthBarrierOption(
        id: 'never',
        label: 'Never or can\'t remember',
        severityScore: 5,
      ),
    ],
  ),
  HealthBarrierQuestion(
    id: 'HB3',
    label: 'Do you have a regular doctor or healthcare provider?',
    options: [
      HealthBarrierOption(
        id: 'yes_regular',
        label: 'Yes, I see them regularly',
        severityScore: 1,
      ),
      HealthBarrierOption(
        id: 'yes_not_regular',
        label: 'Yes, but I don\'t see them often',
        severityScore: 2,
      ),
      HealthBarrierOption(
        id: 'no_looking',
        label: 'No, but I\'m looking for one',
        severityScore: 3,
      ),
      HealthBarrierOption(
        id: 'no_need_one',
        label: 'No, and I need help finding one',
        severityScore: 4,
      ),
    ],
  ),
  HealthBarrierQuestion(
    id: 'HB4',
    label: 'How comfortable are you navigating the healthcare system?',
    options: [
      HealthBarrierOption(
        id: 'very_comfortable',
        label: 'Very comfortable',
        severityScore: 1,
      ),
      HealthBarrierOption(
        id: 'somewhat_comfortable',
        label: 'Somewhat comfortable',
        severityScore: 2,
      ),
      HealthBarrierOption(
        id: 'not_comfortable',
        label: 'Not very comfortable',
        severityScore: 3,
      ),
      HealthBarrierOption(
        id: 'confused',
        label: 'It\'s confusing and overwhelming',
        severityScore: 4,
      ),
    ],
  ),
  HealthBarrierQuestion(
    id: 'HB5',
    label: 'What\'s your preferred language?',
    category: HealthBarrierCategory.language,
    options: [
      HealthBarrierOption(
        id: 'english',
        label: 'English',
        severityScore: 1,
      ),
      HealthBarrierOption(
        id: 'spanish',
        label: 'Spanish',
        severityScore: 1,
      ),
      HealthBarrierOption(
        id: 'other',
        label: 'Other language',
        severityScore: 3,
      ),
    ],
  ),
];

/// Service for calculating health barrier assessment from questionnaire
class HealthBarrierAssessmentService {
  static HealthBarrierAssessment calculateBarriers(
    Map<String, dynamic> responses,
  ) {
    final barriers = <HealthBarrierCategory>[];
    final severity = <HealthBarrierCategory, int>{};

    // Parse HB1 (multiple barriers)
    if (responses.containsKey('HB1')) {
      final selected = responses['HB1'] as List<String>? ?? [];

      for (final option in selected) {
        HealthBarrierCategory? category;
        int score = 3;

        switch (option) {
          case 'cost':
            category = HealthBarrierCategory.cost;
            score = 5;
            break;
          case 'no_insurance':
            category = HealthBarrierCategory.insurance;
            score = 5;
            break;
          case 'transportation':
            category = HealthBarrierCategory.transportation;
            score = 4;
            break;
          case 'language':
            category = HealthBarrierCategory.language;
            score = 4;
            break;
          case 'time':
            category = HealthBarrierCategory.time;
            score = 3;
            break;
          case 'trust':
            category = HealthBarrierCategory.trust;
            score = 4;
            break;
          case 'documentation':
            category = HealthBarrierCategory.documentation;
            score = 5;
            break;
        }

        if (category != null) {
          barriers.add(category);
          severity[category] = score;
        }
      }
    }

    // Calculate navigation complexity based on severity
    final avgSeverity = severity.values.isEmpty
        ? 1.0
        : severity.values.reduce((a, b) => a + b) / severity.values.length;

    ComplexityLevel complexity;
    if (avgSeverity <= 2.0) {
      complexity = ComplexityLevel.stable;
    } else if (avgSeverity <= 3.5) {
      complexity = ComplexityLevel.trying;
    } else if (avgSeverity <= 4.5) {
      complexity = ComplexityLevel.overloaded;
    } else {
      complexity = ComplexityLevel.survival;
    }

    String? preferredLanguage;
    if (responses.containsKey('HB5')) {
      final lang = responses['HB5'] as String?;
      if (lang != null && lang != 'english') {
        preferredLanguage = lang;
        if (!barriers.contains(HealthBarrierCategory.language)) {
          barriers.add(HealthBarrierCategory.language);
          severity[HealthBarrierCategory.language] = lang == 'other' ? 3 : 2;
        }
      }
    }

    return HealthBarrierAssessment(
      primaryBarriers: barriers,
      barrierSeverity: severity,
      navigationComplexity: complexity,
      preferredLanguage: preferredLanguage,
      location: responses['location'] as String?,
      assessmentDate: DateTime.now(),
      responses: Map<String, String>.from(responses),
    );
  }
}
