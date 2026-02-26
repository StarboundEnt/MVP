import 'package:flutter/material.dart';

/// Health status assessment levels
enum HealthStatus { unknown, good, moderate, concerning }

/// Meal status for daily check-in
enum MealStatus { yes, no, some }

/// Duration options for symptom tracking
enum SymptomDuration { fewHours, allDay, multipleDays }

/// Health-focused tag categories (replaces Choice/Chance/Outcome)
enum HealthTagCategory {
  physicalSymptom,  // fatigue, headache, pain, nausea, etc.
  mentalEmotional,  // anxiety, depression, stress, overwhelmed
  healthConcern,    // diabetes-concern, blood-pressure, chronic-pain
  barrier,          // cost-barrier, transportation-issue, time-pressure
  lifeContext,      // work-stress, food-insecurity, housing-stress
  positive,         // feeling-better, good-day, progress, supported
}

// ============================================================================
// HEALTH CHECK-IN MODEL
// ============================================================================

/// Structured daily health check-in (takes ~1-2 minutes)
class HealthCheckIn {
  // Physical Health (3 metrics) - all 1-5 scale except pain which is 0-5
  final int? energy;        // 1-5: Low → High
  final int? painLevel;     // 0-5: None → Severe (0 = no pain)
  final int? sleepQuality;  // 1-5: Poor → Great

  // Mental/Emotional Health (3 metrics) - all 1-5 scale
  final int? mood;          // 1-5: Low → Good
  final int? stressLevel;   // 1-5: None → Very high
  final int? anxietyLevel;  // 1-5: None → Very high

  // Context (quick yes/no/some)
  final MealStatus? ateRegularMeals;
  final String? majorStressors; // Optional free text

  const HealthCheckIn({
    this.energy,
    this.painLevel,
    this.sleepQuality,
    this.mood,
    this.stressLevel,
    this.anxietyLevel,
    this.ateRegularMeals,
    this.majorStressors,
  });

  // Computed properties
  bool get hasPhysicalData => energy != null || painLevel != null || sleepQuality != null;
  bool get hasMentalData => mood != null || stressLevel != null || anxietyLevel != null;
  bool get isComplete => hasPhysicalData && hasMentalData;
  bool get isEmpty => !hasPhysicalData && !hasMentalData && ateRegularMeals == null && majorStressors == null;

  /// Overall physical health assessment based on check-in data
  HealthStatus get overallPhysicalHealth {
    if (!hasPhysicalData) return HealthStatus.unknown;

    // Calculate average: energy (higher=better), pain (lower=better), sleep (higher=better)
    int count = 0;
    double total = 0;

    if (energy != null) {
      total += energy!;
      count++;
    }
    if (painLevel != null) {
      // Invert pain: 0=5(good), 5=0(bad)
      total += (5 - painLevel!);
      count++;
    }
    if (sleepQuality != null) {
      total += sleepQuality!;
      count++;
    }

    if (count == 0) return HealthStatus.unknown;

    final avg = total / count;
    if (avg >= 4) return HealthStatus.good;
    if (avg >= 2.5) return HealthStatus.moderate;
    return HealthStatus.concerning;
  }

  /// Overall mental health assessment based on check-in data
  HealthStatus get overallMentalHealth {
    if (!hasMentalData) return HealthStatus.unknown;

    // Calculate average: mood (higher=better), stress (lower=better), anxiety (lower=better)
    int count = 0;
    double total = 0;

    if (mood != null) {
      total += mood!;
      count++;
    }
    if (stressLevel != null) {
      // Invert stress: 1=5(good), 5=1(bad)
      total += (6 - stressLevel!);
      count++;
    }
    if (anxietyLevel != null) {
      // Invert anxiety: 1=5(good), 5=1(bad)
      total += (6 - anxietyLevel!);
      count++;
    }

    if (count == 0) return HealthStatus.unknown;

    final avg = total / count;
    if (avg >= 4) return HealthStatus.good;
    if (avg >= 2.5) return HealthStatus.moderate;
    return HealthStatus.concerning;
  }

  /// Get a summary text for the check-in
  String get summaryText {
    final parts = <String>[];

    if (energy != null) {
      parts.add('Energy: ${_getLevelText(energy!)}');
    }
    if (mood != null) {
      parts.add('Mood: ${_getLevelText(mood!)}');
    }
    if (stressLevel != null && stressLevel! >= 4) {
      parts.add('High stress');
    }
    if (painLevel != null && painLevel! >= 3) {
      parts.add('Pain: ${_getPainText(painLevel!)}');
    }

    if (parts.isEmpty) return 'No check-in data';
    return parts.join(' | ');
  }

  String _getLevelText(int level) {
    switch (level) {
      case 1: return 'Very low';
      case 2: return 'Low';
      case 3: return 'Moderate';
      case 4: return 'Good';
      case 5: return 'Great';
      default: return 'Unknown';
    }
  }

  String _getPainText(int level) {
    switch (level) {
      case 0: return 'None';
      case 1: return 'Mild';
      case 2: return 'Light';
      case 3: return 'Moderate';
      case 4: return 'Severe';
      case 5: return 'Very severe';
      default: return 'Unknown';
    }
  }

  HealthCheckIn copyWith({
    int? energy,
    int? painLevel,
    int? sleepQuality,
    int? mood,
    int? stressLevel,
    int? anxietyLevel,
    MealStatus? ateRegularMeals,
    String? majorStressors,
  }) {
    return HealthCheckIn(
      energy: energy ?? this.energy,
      painLevel: painLevel ?? this.painLevel,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      mood: mood ?? this.mood,
      stressLevel: stressLevel ?? this.stressLevel,
      anxietyLevel: anxietyLevel ?? this.anxietyLevel,
      ateRegularMeals: ateRegularMeals ?? this.ateRegularMeals,
      majorStressors: majorStressors ?? this.majorStressors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'energy': energy,
      'painLevel': painLevel,
      'sleepQuality': sleepQuality,
      'mood': mood,
      'stressLevel': stressLevel,
      'anxietyLevel': anxietyLevel,
      'ateRegularMeals': ateRegularMeals?.name,
      'majorStressors': majorStressors,
    };
  }

  factory HealthCheckIn.fromJson(Map<String, dynamic> json) {
    return HealthCheckIn(
      energy: json['energy'] as int?,
      painLevel: json['painLevel'] as int?,
      sleepQuality: json['sleepQuality'] as int?,
      mood: json['mood'] as int?,
      stressLevel: json['stressLevel'] as int?,
      anxietyLevel: json['anxietyLevel'] as int?,
      ateRegularMeals: json['ateRegularMeals'] != null
          ? MealStatus.values.firstWhere(
              (e) => e.name == json['ateRegularMeals'],
              orElse: () => MealStatus.some,
            )
          : null,
      majorStressors: json['majorStressors'] as String?,
    );
  }

  @override
  String toString() => 'HealthCheckIn(energy: $energy, mood: $mood, stress: $stressLevel)';
}

// ============================================================================
// SYMPTOM TRACKING MODEL
// ============================================================================

/// Optional symptom tracking for specific health concerns
class SymptomTracking {
  final String id;
  final String symptomType; // "headache", "nausea", "fatigue", etc.
  final int severity;       // 1-5: Mild → Severe
  final SymptomDuration duration;
  final List<String> whatHelps; // ["rest", "medication", "nothing"]
  final String? notes;
  final DateTime createdAt;

  const SymptomTracking({
    required this.id,
    required this.symptomType,
    required this.severity,
    required this.duration,
    this.whatHelps = const [],
    this.notes,
    required this.createdAt,
  });

  bool get isSevere => severity >= 4;
  bool get isPersistent => duration == SymptomDuration.multipleDays;
  bool get needsAttention => isSevere || isPersistent;

  /// Get human-readable duration text
  String get durationText {
    switch (duration) {
      case SymptomDuration.fewHours:
        return 'A few hours';
      case SymptomDuration.allDay:
        return 'All day';
      case SymptomDuration.multipleDays:
        return 'Multiple days';
    }
  }

  /// Get severity text
  String get severityText {
    switch (severity) {
      case 1: return 'Mild';
      case 2: return 'Light';
      case 3: return 'Moderate';
      case 4: return 'Severe';
      case 5: return 'Very severe';
      default: return 'Unknown';
    }
  }

  /// Get what helps text
  String get whatHelpsText {
    if (whatHelps.isEmpty) return 'Nothing noted';
    return whatHelps.map((h) => _capitalizeFirst(h)).join(', ');
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  SymptomTracking copyWith({
    String? id,
    String? symptomType,
    int? severity,
    SymptomDuration? duration,
    List<String>? whatHelps,
    String? notes,
    DateTime? createdAt,
  }) {
    return SymptomTracking(
      id: id ?? this.id,
      symptomType: symptomType ?? this.symptomType,
      severity: severity ?? this.severity,
      duration: duration ?? this.duration,
      whatHelps: whatHelps ?? this.whatHelps,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symptomType': symptomType,
      'severity': severity,
      'duration': duration.name,
      'whatHelps': whatHelps,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SymptomTracking.fromJson(Map<String, dynamic> json) {
    return SymptomTracking(
      id: json['id'] ?? '',
      symptomType: json['symptomType'] ?? '',
      severity: json['severity'] ?? 3,
      duration: SymptomDuration.values.firstWhere(
        (e) => e.name == json['duration'],
        orElse: () => SymptomDuration.fewHours,
      ),
      whatHelps: List<String>.from(json['whatHelps'] ?? []),
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomTracking && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SymptomTracking($symptomType: $severityText)';
}

// ============================================================================
// HEALTH TAG MODEL
// ============================================================================

/// AI-extracted health theme tags (replaces Choice/Chance/Outcome)
class HealthTag {
  final String id;
  final String canonicalKey;  // "fatigue", "work-stress", "cost-barrier"
  final String displayName;   // "Fatigue", "Work Stress", "Cost Barrier"
  final HealthTagCategory category;
  final double confidence;    // 0.0 - 1.0
  final String? evidenceSpan; // Text that triggered this tag
  final DateTime createdAt;

  const HealthTag({
    required this.id,
    required this.canonicalKey,
    required this.displayName,
    required this.category,
    required this.confidence,
    this.evidenceSpan,
    required this.createdAt,
  });

  bool get isHighConfidence => confidence >= 0.7;
  bool get isMediumConfidence => confidence >= 0.4 && confidence < 0.7;
  bool get isLowConfidence => confidence < 0.4;

  /// Get color for this tag category
  Color get categoryColor {
    switch (category) {
      case HealthTagCategory.physicalSymptom:
        return const Color(0xFFE57373); // Red
      case HealthTagCategory.mentalEmotional:
        return const Color(0xFF7986CB); // Indigo
      case HealthTagCategory.healthConcern:
        return const Color(0xFFFFB74D); // Orange
      case HealthTagCategory.barrier:
        return const Color(0xFF90A4AE); // Blue Grey
      case HealthTagCategory.lifeContext:
        return const Color(0xFFBA68C8); // Purple
      case HealthTagCategory.positive:
        return const Color(0xFF81C784); // Green
    }
  }

  /// Get icon for this tag category
  IconData get categoryIcon {
    switch (category) {
      case HealthTagCategory.physicalSymptom:
        return Icons.healing;
      case HealthTagCategory.mentalEmotional:
        return Icons.psychology;
      case HealthTagCategory.healthConcern:
        return Icons.medical_services;
      case HealthTagCategory.barrier:
        return Icons.block;
      case HealthTagCategory.lifeContext:
        return Icons.home_work;
      case HealthTagCategory.positive:
        return Icons.thumb_up;
    }
  }

  /// Factory for creating from detected keyword
  factory HealthTag.fromKeyword({
    required String canonicalKey,
    required HealthTagCategory category,
    String? evidenceSpan,
    double confidence = 0.8,
  }) {
    return HealthTag(
      id: '${canonicalKey}_${DateTime.now().millisecondsSinceEpoch}',
      canonicalKey: canonicalKey,
      displayName: HealthTagTaxonomy.getDisplayName(canonicalKey),
      category: category,
      confidence: confidence,
      evidenceSpan: evidenceSpan,
      createdAt: DateTime.now(),
    );
  }

  HealthTag copyWith({
    String? id,
    String? canonicalKey,
    String? displayName,
    HealthTagCategory? category,
    double? confidence,
    String? evidenceSpan,
    DateTime? createdAt,
  }) {
    return HealthTag(
      id: id ?? this.id,
      canonicalKey: canonicalKey ?? this.canonicalKey,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      evidenceSpan: evidenceSpan ?? this.evidenceSpan,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canonicalKey': canonicalKey,
      'displayName': displayName,
      'category': category.name,
      'confidence': confidence,
      'evidenceSpan': evidenceSpan,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HealthTag.fromJson(Map<String, dynamic> json) {
    return HealthTag(
      id: json['id'] ?? '',
      canonicalKey: json['canonicalKey'] ?? '',
      displayName: json['displayName'] ?? '',
      category: HealthTagCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => HealthTagCategory.physicalSymptom,
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      evidenceSpan: json['evidenceSpan'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthTag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HealthTag($canonicalKey: $displayName [$confidence])';
}

// ============================================================================
// HEALTH TAG TAXONOMY
// ============================================================================

/// Complete taxonomy of health tags
class HealthTagTaxonomy {
  HealthTagTaxonomy._();

  /// Physical symptom tags
  static const Map<String, String> physicalSymptomTags = {
    'fatigue': 'Fatigue',
    'headache': 'Headache',
    'pain': 'Pain',
    'nausea': 'Nausea',
    'dizziness': 'Dizziness',
    'fever': 'Fever',
    'cough': 'Cough',
    'shortness-of-breath': 'Shortness of Breath',
    'chest-pain': 'Chest Pain',
    'stomach-pain': 'Stomach Pain',
    'back-pain': 'Back Pain',
    'joint-pain': 'Joint Pain',
    'muscle-ache': 'Muscle Ache',
    'insomnia': 'Insomnia',
    'appetite-loss': 'Appetite Loss',
    'cold': 'Cold',
    'flu': 'Flu',
    'migraine': 'Migraine',
    'weakness': 'Weakness',
  };

  /// Mental/emotional tags
  static const Map<String, String> mentalEmotionalTags = {
    'anxiety': 'Anxiety',
    'depression': 'Depression',
    'stress': 'Stress',
    'overwhelmed': 'Overwhelmed',
    'hopeless': 'Hopeless',
    'panic': 'Panic',
    'irritable': 'Irritable',
    'lonely': 'Lonely',
    'worried': 'Worried',
    'sad': 'Sad',
    'angry': 'Angry',
    'frustrated': 'Frustrated',
    'exhausted': 'Exhausted',
  };

  /// Health concern tags
  static const Map<String, String> healthConcernTags = {
    'diabetes-concern': 'Diabetes Concern',
    'blood-pressure': 'Blood Pressure',
    'heart-health': 'Heart Health',
    'pregnancy': 'Pregnancy',
    'chronic-pain': 'Chronic Pain',
    'medication-concern': 'Medication Concern',
    'weight-concern': 'Weight Concern',
    'breathing-issues': 'Breathing Issues',
    'digestive-issues': 'Digestive Issues',
  };

  /// Barrier tags
  static const Map<String, String> barrierTags = {
    'cost-barrier': 'Cost Barrier',
    'transportation-issue': 'Transportation Issue',
    'time-pressure': 'Time Pressure',
    'childcare-problem': 'Childcare Problem',
    'language-barrier': 'Language Barrier',
    'no-insurance': 'No Insurance',
    'cant-take-time-off': 'Can\'t Take Time Off',
    'waiting-list': 'Waiting List',
    'no-gp': 'No Regular GP',
  };

  /// Life context tags
  static const Map<String, String> lifeContextTags = {
    'work-stress': 'Work Stress',
    'food-insecurity': 'Food Insecurity',
    'housing-stress': 'Housing Stress',
    'social-isolation': 'Social Isolation',
    'family-stress': 'Family Stress',
    'financial-stress': 'Financial Stress',
    'relationship-issues': 'Relationship Issues',
    'job-loss': 'Job Loss',
    'caregiving': 'Caregiving',
  };

  /// Positive tags
  static const Map<String, String> positiveTags = {
    'feeling-better': 'Feeling Better',
    'good-day': 'Good Day',
    'progress': 'Progress',
    'supported': 'Supported',
    'accomplished': 'Accomplished',
    'hopeful': 'Hopeful',
    'rested': 'Rested',
    'energized': 'Energized',
    'calm': 'Calm',
  };

  /// Get all tags by category
  static Map<String, String> getTagsByCategory(HealthTagCategory category) {
    switch (category) {
      case HealthTagCategory.physicalSymptom:
        return physicalSymptomTags;
      case HealthTagCategory.mentalEmotional:
        return mentalEmotionalTags;
      case HealthTagCategory.healthConcern:
        return healthConcernTags;
      case HealthTagCategory.barrier:
        return barrierTags;
      case HealthTagCategory.lifeContext:
        return lifeContextTags;
      case HealthTagCategory.positive:
        return positiveTags;
    }
  }

  /// Get all tags combined
  static Map<String, String> get allTags => {
    ...physicalSymptomTags,
    ...mentalEmotionalTags,
    ...healthConcernTags,
    ...barrierTags,
    ...lifeContextTags,
    ...positiveTags,
  };

  /// Get display name for a canonical key
  static String getDisplayName(String canonicalKey) {
    return allTags[canonicalKey] ?? _formatKey(canonicalKey);
  }

  /// Get category for a canonical key
  static HealthTagCategory? getCategoryForKey(String canonicalKey) {
    if (physicalSymptomTags.containsKey(canonicalKey)) {
      return HealthTagCategory.physicalSymptom;
    }
    if (mentalEmotionalTags.containsKey(canonicalKey)) {
      return HealthTagCategory.mentalEmotional;
    }
    if (healthConcernTags.containsKey(canonicalKey)) {
      return HealthTagCategory.healthConcern;
    }
    if (barrierTags.containsKey(canonicalKey)) {
      return HealthTagCategory.barrier;
    }
    if (lifeContextTags.containsKey(canonicalKey)) {
      return HealthTagCategory.lifeContext;
    }
    if (positiveTags.containsKey(canonicalKey)) {
      return HealthTagCategory.positive;
    }
    return null;
  }

  /// Format a key into display format
  static String _formatKey(String key) {
    return key
        .split('-')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Common symptoms for dropdown (most frequently used)
  static const List<String> commonSymptoms = [
    'headache',
    'fatigue',
    'nausea',
    'pain',
    'dizziness',
    'stomach-pain',
    'back-pain',
    'insomnia',
    'cough',
    'cold',
  ];

  /// What helps options for symptom tracking
  static const List<String> whatHelpsOptions = [
    'rest',
    'medication',
    'water',
    'food',
    'sleep',
    'fresh-air',
    'nothing',
  ];
}

// ============================================================================
// HEALTH JOURNAL ENTRY MODEL
// ============================================================================

/// Health-focused journal entry with structured check-ins and free-form text
class HealthJournalEntry {
  final String id;
  final DateTime timestamp; // When the entry was for (date of the day)
  final DateTime createdAt;
  final DateTime updatedAt;

  // === STRUCTURED CHECK-IN DATA ===
  final HealthCheckIn checkIn;

  // === OPTIONAL SYMPTOM TRACKING ===
  final List<SymptomTracking> symptoms;

  // === FREE-FORM JOURNAL ===
  final String? journalText;

  // === AI-GENERATED HEALTH TAGS ===
  final List<HealthTag> healthTags;

  // === PATTERN DETECTION ===
  final bool hasPatternDetected;
  final String? patternInsightId; // Reference to pattern insight if generated

  // === METADATA ===
  final Map<String, dynamic> metadata;
  final bool isProcessed; // Has AI tagging completed?
  final bool isDraft;

  const HealthJournalEntry({
    required this.id,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
    required this.checkIn,
    this.symptoms = const [],
    this.journalText,
    this.healthTags = const [],
    this.hasPatternDetected = false,
    this.patternInsightId,
    this.metadata = const {},
    this.isProcessed = false,
    this.isDraft = false,
  });

  // Computed properties
  bool get hasCheckIn => !checkIn.isEmpty;
  bool get hasSymptoms => symptoms.isNotEmpty;
  bool get hasJournalText => journalText != null && journalText!.trim().isNotEmpty;
  bool get hasTags => healthTags.isNotEmpty;
  bool get isEmpty => !hasCheckIn && !hasSymptoms && !hasJournalText;

  /// Get all symptom types tracked in this entry
  List<String> get symptomTypes => symptoms.map((s) => s.symptomType).toList();

  /// Get all tag keys
  List<String> get tagKeys => healthTags.map((t) => t.canonicalKey).toList();

  /// Get tags by category
  List<HealthTag> getTagsByCategory(HealthTagCategory category) {
    return healthTags.where((t) => t.category == category).toList();
  }

  /// Check if entry mentions a specific symptom (in tracking or text)
  bool mentionsSymptom(String symptomKey) {
    // Check symptom tracking
    if (symptoms.any((s) => s.symptomType == symptomKey)) {
      return true;
    }
    // Check tags
    if (healthTags.any((t) => t.canonicalKey == symptomKey)) {
      return true;
    }
    // Check journal text
    if (journalText != null) {
      final displayName = HealthTagTaxonomy.getDisplayName(symptomKey).toLowerCase();
      return journalText!.toLowerCase().contains(symptomKey) ||
             journalText!.toLowerCase().contains(displayName);
    }
    return false;
  }

  /// Get a preview of the journal text (truncated)
  String get journalPreview {
    if (journalText == null || journalText!.isEmpty) return '';
    final text = journalText!.trim();
    if (text.length <= 100) return text;
    return '${text.substring(0, 97)}...';
  }

  /// Get formatted date string
  String get dateString {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (entryDate == today) return 'Today';
    if (entryDate == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final difference = today.difference(entryDate).inDays;
    if (difference < 7) return '${difference} days ago';

    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  HealthJournalEntry copyWith({
    String? id,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
    HealthCheckIn? checkIn,
    List<SymptomTracking>? symptoms,
    String? journalText,
    List<HealthTag>? healthTags,
    bool? hasPatternDetected,
    String? patternInsightId,
    Map<String, dynamic>? metadata,
    bool? isProcessed,
    bool? isDraft,
  }) {
    return HealthJournalEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      checkIn: checkIn ?? this.checkIn,
      symptoms: symptoms ?? this.symptoms,
      journalText: journalText ?? this.journalText,
      healthTags: healthTags ?? this.healthTags,
      hasPatternDetected: hasPatternDetected ?? this.hasPatternDetected,
      patternInsightId: patternInsightId ?? this.patternInsightId,
      metadata: metadata ?? this.metadata,
      isProcessed: isProcessed ?? this.isProcessed,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'checkIn': checkIn.toJson(),
      'symptoms': symptoms.map((s) => s.toJson()).toList(),
      'journalText': journalText,
      'healthTags': healthTags.map((t) => t.toJson()).toList(),
      'hasPatternDetected': hasPatternDetected,
      'patternInsightId': patternInsightId,
      'metadata': metadata,
      'isProcessed': isProcessed,
      'isDraft': isDraft,
    };
  }

  factory HealthJournalEntry.fromJson(Map<String, dynamic> json) {
    return HealthJournalEntry(
      id: json['id'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      checkIn: json['checkIn'] != null
          ? HealthCheckIn.fromJson(json['checkIn'])
          : const HealthCheckIn(),
      symptoms: (json['symptoms'] as List<dynamic>? ?? [])
          .map((s) => SymptomTracking.fromJson(s))
          .toList(),
      journalText: json['journalText'] as String?,
      healthTags: (json['healthTags'] as List<dynamic>? ?? [])
          .map((t) => HealthTag.fromJson(t))
          .toList(),
      hasPatternDetected: json['hasPatternDetected'] ?? false,
      patternInsightId: json['patternInsightId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isProcessed: json['isProcessed'] ?? false,
      isDraft: json['isDraft'] ?? false,
    );
  }

  /// Create a new empty entry for today
  factory HealthJournalEntry.today() {
    final now = DateTime.now();
    return HealthJournalEntry(
      id: 'entry_${now.millisecondsSinceEpoch}',
      timestamp: now,
      createdAt: now,
      updatedAt: now,
      checkIn: const HealthCheckIn(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthJournalEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HealthJournalEntry($id: ${dateString})';
}
