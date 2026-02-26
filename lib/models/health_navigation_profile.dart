import 'package:equatable/equatable.dart';
import './complexity_profile.dart'; // For legacy compatibility

/// Health Navigation Profile - stores user's health access context
/// Replaces mental wellness/complexity approach with health navigation focus
class HealthNavigationProfile extends Equatable {
  final String userName;
  final String? neighborhood;
  final List<String> languages;
  final List<String> barriers; // KEY field - what makes healthcare hard
  final List<String> healthInterests;
  final String? workSchedule;
  final String checkInFrequency;
  final String? additionalNotes;
  final bool isOnboardingComplete;
  final DateTime? onboardingCompletedAt;

  // Keep for journal/habits features that still use it
  final Map<String, dynamic> habits;
  final List<dynamic> journalEntries;

  // Backwards compatibility - deprecated but kept for migration
  @Deprecated('Use barriers and healthInterests instead')
  final ComplexityLevel? legacyComplexityLevel;

  const HealthNavigationProfile({
    this.userName = 'Explorer',
    this.neighborhood,
    this.languages = const [],
    this.barriers = const [],
    this.healthInterests = const [],
    this.workSchedule,
    this.checkInFrequency = 'weekly',
    this.additionalNotes,
    this.isOnboardingComplete = false,
    this.onboardingCompletedAt,
    this.habits = const {},
    this.journalEntries = const [],
    this.legacyComplexityLevel,
  });

  /// Helper: Check if user has a specific barrier
  bool hasBarrier(String barrierId) {
    return barriers.contains(barrierId);
  }

  /// Helper: Check if user is interested in a health topic
  bool isInterestedIn(String topicId) {
    return healthInterests.contains(topicId);
  }

  /// Helper: Get best time to contact based on work schedule
  String getBestContactTime() {
    switch (workSchedule) {
      case 'night_shift':
        return 'afternoon (before work)';
      case 'irregular':
      case 'multiple_jobs':
        return 'flexible times';
      case 'regular_day':
        return 'evening or weekend';
      case 'not_working':
        return 'any time';
      default:
        return 'flexible';
    }
  }

  /// Helper: Get barrier-sensitive recommendations
  List<String> getRecommendationFilters() {
    final filters = <String>[];

    if (hasBarrier('cost')) filters.add('free_or_low_cost');
    if (hasBarrier('transportation')) filters.add('telehealth_friendly');
    if (hasBarrier('time')) filters.add('quick_access');
    if (hasBarrier('childcare')) filters.add('family_friendly');
    if (hasBarrier('language')) filters.add('multilingual');
    if (hasBarrier('immigration')) filters.add('safe_for_undocumented');

    return filters;
  }

  /// Helper: Get summary of barriers for display
  String getBarriersSummary() {
    if (barriers.isEmpty) return 'No major barriers reported';
    if (barriers.length == 1) return '1 barrier: ${_getFriendlyBarrierName(barriers.first)}';
    return '${barriers.length} barriers reported';
  }

  /// Helper: Check if user needs urgent support (multiple severe barriers)
  bool needsUrgentSupport() {
    final severeBarriers = ['cost', 'transportation', 'immigration', 'bad_experiences'];
    final severeCount = barriers.where((b) => severeBarriers.contains(b)).length;
    return severeCount >= 3;
  }

  /// Convert friendly barrier label to internal ID
  static String barrierLabelToId(String label) {
    const mapping = {
      'Cost / Can\'t afford it': 'cost',
      'No insurance or bad coverage': 'insurance',
      'Transportation / Getting there is difficult': 'transportation',
      'Time / Work schedule makes it hard': 'time',
      'Childcare / Can\'t bring kids or leave them': 'childcare',
      'Language barriers': 'language',
      'Don\'t know where to go': 'navigation',
      'Bad experiences / Don\'t trust system': 'bad_experiences',
      'Immigration concerns': 'immigration',
      'Physical accessibility': 'accessibility',
      'Other': 'other',
    };
    return mapping[label] ?? label.toLowerCase().replaceAll(' ', '_');
  }

  /// Convert internal barrier ID to friendly label
  static String barrierIdToLabel(String id) {
    const mapping = {
      'cost': 'Cost / Can\'t afford it',
      'insurance': 'No insurance or bad coverage',
      'transportation': 'Transportation / Getting there is difficult',
      'time': 'Time / Work schedule makes it hard',
      'childcare': 'Childcare / Can\'t bring kids or leave them',
      'language': 'Language barriers',
      'navigation': 'Don\'t know where to go',
      'bad_experiences': 'Bad experiences / Don\'t trust system',
      'immigration': 'Immigration concerns',
      'accessibility': 'Physical accessibility',
      'other': 'Other',
    };
    return mapping[id] ?? id;
  }

  String _getFriendlyBarrierName(String barrierId) {
    return barrierIdToLabel(barrierId).split('/').first.trim();
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'neighborhood': neighborhood,
      'languages': languages,
      'barriers': barriers,
      'healthInterests': healthInterests,
      'workSchedule': workSchedule,
      'checkInFrequency': checkInFrequency,
      'additionalNotes': additionalNotes,
      'isOnboardingComplete': isOnboardingComplete,
      'onboardingCompletedAt': onboardingCompletedAt?.toIso8601String(),
      'habits': habits,
      'journalEntries': journalEntries,
      'legacyComplexityLevel': legacyComplexityLevel?.index,
    };
  }

  /// Deserialize from JSON
  factory HealthNavigationProfile.fromJson(Map<String, dynamic> json) {
    return HealthNavigationProfile(
      userName: json['userName'] as String? ?? 'Explorer',
      neighborhood: json['neighborhood'] as String?,
      languages: List<String>.from(json['languages'] ?? []),
      barriers: List<String>.from(json['barriers'] ?? []),
      healthInterests: List<String>.from(json['healthInterests'] ?? []),
      workSchedule: json['workSchedule'] as String?,
      checkInFrequency: json['checkInFrequency'] as String? ?? 'weekly',
      additionalNotes: json['additionalNotes'] as String?,
      isOnboardingComplete: json['isOnboardingComplete'] as bool? ?? false,
      onboardingCompletedAt: json['onboardingCompletedAt'] != null
          ? DateTime.parse(json['onboardingCompletedAt'])
          : null,
      habits: json['habits'] as Map<String, dynamic>? ?? {},
      journalEntries: json['journalEntries'] as List? ?? [],
      legacyComplexityLevel: json['legacyComplexityLevel'] != null
          ? ComplexityLevel.values[json['legacyComplexityLevel'] as int]
          : null,
    );
  }

  /// Create empty profile
  factory HealthNavigationProfile.empty() {
    return const HealthNavigationProfile();
  }

  /// Create from legacy complexity assessment (migration helper)
  factory HealthNavigationProfile.fromLegacyComplexity({
    required ComplexityLevel complexityLevel,
    Map<String, dynamic>? habits,
    List<dynamic>? journalEntries,
  }) {
    // Map legacy complexity to sensible default barriers/interests
    List<String> defaultBarriers;
    List<String> defaultInterests;

    switch (complexityLevel) {
      case ComplexityLevel.survival:
        defaultBarriers = ['cost', 'transportation', 'time'];
        defaultInterests = ['general_health'];
        break;
      case ComplexityLevel.overloaded:
        defaultBarriers = ['time', 'cost'];
        defaultInterests = ['mental_health', 'chronic_illness'];
        break;
      case ComplexityLevel.trying:
        defaultBarriers = ['time'];
        defaultInterests = ['general_health', 'mental_health'];
        break;
      case ComplexityLevel.stable:
        defaultBarriers = [];
        defaultInterests = ['nutrition', 'general_health'];
        break;
    }

    return HealthNavigationProfile(
      barriers: defaultBarriers,
      healthInterests: defaultInterests,
      habits: habits ?? {},
      journalEntries: journalEntries ?? [],
      legacyComplexityLevel: complexityLevel,
      isOnboardingComplete: true, // Already completed old onboarding
      onboardingCompletedAt: DateTime.now(),
    );
  }

  /// Copy with updated fields
  HealthNavigationProfile copyWith({
    String? userName,
    String? neighborhood,
    List<String>? languages,
    List<String>? barriers,
    List<String>? healthInterests,
    String? workSchedule,
    String? checkInFrequency,
    String? additionalNotes,
    bool? isOnboardingComplete,
    DateTime? onboardingCompletedAt,
    Map<String, dynamic>? habits,
    List<dynamic>? journalEntries,
    ComplexityLevel? legacyComplexityLevel,
  }) {
    return HealthNavigationProfile(
      userName: userName ?? this.userName,
      neighborhood: neighborhood ?? this.neighborhood,
      languages: languages ?? this.languages,
      barriers: barriers ?? this.barriers,
      healthInterests: healthInterests ?? this.healthInterests,
      workSchedule: workSchedule ?? this.workSchedule,
      checkInFrequency: checkInFrequency ?? this.checkInFrequency,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
      habits: habits ?? this.habits,
      journalEntries: journalEntries ?? this.journalEntries,
      legacyComplexityLevel: legacyComplexityLevel ?? this.legacyComplexityLevel,
    );
  }

  @override
  List<Object?> get props => [
        userName,
        neighborhood,
        languages,
        barriers,
        healthInterests,
        workSchedule,
        checkInFrequency,
        additionalNotes,
        isOnboardingComplete,
        onboardingCompletedAt,
        habits,
        journalEntries,
        legacyComplexityLevel,
      ];
}
