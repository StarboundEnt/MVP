/// Health question model for user inquiries about health concerns
/// Part of the health navigation transformation

enum HealthQuestionCategory {
  symptoms,           // Physical symptoms
  mentalHealth,       // Mental health concerns
  access,             // Accessing healthcare
  insurance,          // Insurance/coverage questions
  medication,         // Medication/prescription
  prevention,         // Preventive care
  nutrition,          // Diet/nutrition
  chronicCondition,   // Managing chronic conditions
  emergency,          // Emergency situations
  general,            // General health questions
}

enum UrgencyLevel {
  routine,            // Can wait for regular appointment (weeks)
  monitor,            // Keep an eye on it (days)
  seekCareSoon,       // See provider within 24-48 hours
  seekCareNow,        // See provider today/urgent care
  emergency,          // Call 911 or go to ER immediately
}

class HealthQuestion {
  final String id;
  final String questionText;
  final DateTime timestamp;
  final HealthQuestionCategory category;
  final UrgencyLevel urgency;
  final List<String> extractedSymptoms;
  final List<String> healthBarriers;
  final String? location; // Zip code or general location for resource matching

  const HealthQuestion({
    required this.id,
    required this.questionText,
    required this.timestamp,
    required this.category,
    required this.urgency,
    this.extractedSymptoms = const [],
    this.healthBarriers = const [],
    this.location,
  });

  // Create from JSON
  factory HealthQuestion.fromJson(Map<String, dynamic> json) {
    return HealthQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: HealthQuestionCategory.values.firstWhere(
        (e) => e.toString() == 'HealthQuestionCategory.${json['category']}',
        orElse: () => HealthQuestionCategory.general,
      ),
      urgency: UrgencyLevel.values.firstWhere(
        (e) => e.toString() == 'UrgencyLevel.${json['urgency']}',
        orElse: () => UrgencyLevel.routine,
      ),
      extractedSymptoms: (json['extractedSymptoms'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? const [],
      healthBarriers: (json['healthBarriers'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? const [],
      location: json['location'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
      'urgency': urgency.name,
      'extractedSymptoms': extractedSymptoms,
      'healthBarriers': healthBarriers,
      'location': location,
    };
  }

  // Copy with modifications
  HealthQuestion copyWith({
    String? id,
    String? questionText,
    DateTime? timestamp,
    HealthQuestionCategory? category,
    UrgencyLevel? urgency,
    List<String>? extractedSymptoms,
    List<String>? healthBarriers,
    String? location,
  }) {
    return HealthQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      urgency: urgency ?? this.urgency,
      extractedSymptoms: extractedSymptoms ?? this.extractedSymptoms,
      healthBarriers: healthBarriers ?? this.healthBarriers,
      location: location ?? this.location,
    );
  }

  // Get urgency level display text
  String get urgencyDisplayText {
    switch (urgency) {
      case UrgencyLevel.routine:
        return 'Routine care';
      case UrgencyLevel.monitor:
        return 'Monitor closely';
      case UrgencyLevel.seekCareSoon:
        return 'See provider soon (24-48 hours)';
      case UrgencyLevel.seekCareNow:
        return 'Seek care today';
      case UrgencyLevel.emergency:
        return '🚨 EMERGENCY - Call 911';
    }
  }

  // Get category display text
  String get categoryDisplayText {
    switch (category) {
      case HealthQuestionCategory.symptoms:
        return 'Symptoms';
      case HealthQuestionCategory.mentalHealth:
        return 'Mental Health';
      case HealthQuestionCategory.access:
        return 'Healthcare Access';
      case HealthQuestionCategory.insurance:
        return 'Insurance';
      case HealthQuestionCategory.medication:
        return 'Medication';
      case HealthQuestionCategory.prevention:
        return 'Prevention';
      case HealthQuestionCategory.nutrition:
        return 'Nutrition';
      case HealthQuestionCategory.chronicCondition:
        return 'Chronic Condition';
      case HealthQuestionCategory.emergency:
        return 'Emergency';
      case HealthQuestionCategory.general:
        return 'General Health';
    }
  }

  // Check if question is high urgency
  bool get isHighUrgency =>
      urgency == UrgencyLevel.seekCareNow ||
      urgency == UrgencyLevel.emergency;

  // Check if requires immediate emergency response
  bool get isEmergency => urgency == UrgencyLevel.emergency;

  @override
  String toString() {
    return 'HealthQuestion(id: $id, category: ${category.name}, urgency: ${urgency.name})';
  }
}

/// Helper class for categorizing health questions
class HealthQuestionCategorizer {
  static HealthQuestionCategory categorizeQuestion(String questionText) {
    final text = questionText.toLowerCase();

    // Emergency keywords
    if (_containsAny(text, [
      'chest pain',
      'can\'t breathe',
      'difficulty breathing',
      'severe bleeding',
      'head injury',
      'unconscious',
      'seizure',
      'stroke',
      'heart attack',
      'overdose',
      'poisoning',
    ])) {
      return HealthQuestionCategory.emergency;
    }

    // Mental health keywords
    if (_containsAny(text, [
      'depressed',
      'anxiety',
      'panic',
      'suicidal',
      'self harm',
      'mental health',
      'therapist',
      'counseling',
      'stressed',
      'overwhelmed',
    ])) {
      return HealthQuestionCategory.mentalHealth;
    }

    // Access/insurance keywords
    if (_containsAny(text, [
      'find a doctor',
      'find clinic',
      'free care',
      'uninsured',
      'no insurance',
      'sliding scale',
      'medicaid',
      'medicare',
      'can\'t afford',
    ])) {
      return HealthQuestionCategory.access;
    }

    // Medication keywords
    if (_containsAny(text, [
      'prescription',
      'medication',
      'medicine',
      'pills',
      'pharmacy',
      'drug',
    ])) {
      return HealthQuestionCategory.medication;
    }

    // Chronic condition keywords
    if (_containsAny(text, [
      'diabetes',
      'asthma',
      'hypertension',
      'chronic',
      'manage',
      'condition',
    ])) {
      return HealthQuestionCategory.chronicCondition;
    }

    // Nutrition keywords
    if (_containsAny(text, [
      'diet',
      'nutrition',
      'eating',
      'weight',
      'food',
    ])) {
      return HealthQuestionCategory.nutrition;
    }

    // Prevention keywords
    if (_containsAny(text, [
      'vaccine',
      'screening',
      'checkup',
      'prevention',
      'wellness visit',
    ])) {
      return HealthQuestionCategory.prevention;
    }

    // Default to symptoms if contains body parts or symptom words
    if (_containsAny(text, [
      'pain',
      'ache',
      'hurt',
      'fever',
      'cough',
      'nausea',
      'dizzy',
      'tired',
      'symptom',
    ])) {
      return HealthQuestionCategory.symptoms;
    }

    return HealthQuestionCategory.general;
  }

  static UrgencyLevel assessUrgency(String questionText) {
    final text = questionText.toLowerCase();

    // Emergency keywords - life-threatening
    if (_containsAny(text, [
      'chest pain',
      'can\'t breathe',
      'difficulty breathing',
      'severe bleeding',
      'head injury',
      'unconscious',
      'seizure',
      'stroke symptoms',
      'heart attack',
      'overdose',
      'poisoned',
      'suicidal',
      'want to die',
    ])) {
      return UrgencyLevel.emergency;
    }

    // Seek care now - serious but not immediately life-threatening
    if (_containsAny(text, [
      'severe pain',
      'high fever',
      'can\'t keep anything down',
      'dehydrated',
      'bleeding',
      'injury',
      'broken',
      'dislocated',
    ])) {
      return UrgencyLevel.seekCareNow;
    }

    // Seek care soon - needs attention within 1-2 days
    if (_containsAny(text, [
      'pain',
      'fever',
      'infection',
      'rash',
      'swelling',
      'worsening',
      'getting worse',
    ])) {
      return UrgencyLevel.seekCareSoon;
    }

    // Monitor - watch symptoms
    if (_containsAny(text, [
      'mild',
      'occasional',
      'sometimes',
      'started',
      'new',
    ])) {
      return UrgencyLevel.monitor;
    }

    // Default to routine for general questions
    return UrgencyLevel.routine;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}
