class ValidationResult {
  final bool isValid;
  final String? error;
  final List<String> errors;
  
  ValidationResult.success() : isValid = true, error = null, errors = [];
  ValidationResult.failure(String error) : isValid = false, error = error, errors = [error];
  ValidationResult.multipleErrors(List<String> errors) : isValid = false, error = errors.first, errors = errors;
  
  bool get hasError => !isValid;
  
  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $error';
}

class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();
  
  // Common validation patterns
  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp _phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  static final RegExp _nameRegex = RegExp(r'^[a-zA-Z\s]+$');
  
  // Text validation
  ValidationResult validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('$fieldName is required');
    }
    return ValidationResult.success();
  }
  
  ValidationResult validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return ValidationResult.failure('$fieldName must be at least $minLength characters');
    }
    return ValidationResult.success();
  }
  
  ValidationResult validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return ValidationResult.failure('$fieldName must be less than $maxLength characters');
    }
    return ValidationResult.success();
  }
  
  ValidationResult validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Email is required');
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return ValidationResult.failure('Please enter a valid email address');
    }
    return ValidationResult.success();
  }
  
  ValidationResult validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Phone number is required');
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (!_phoneRegex.hasMatch(cleaned)) {
      return ValidationResult.failure('Please enter a valid phone number');
    }
    return ValidationResult.success();
  }
  
  ValidationResult validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Name is required');
    }
    if (value.trim().length < 2) {
      return ValidationResult.failure('Name must be at least 2 characters');
    }
    if (!_nameRegex.hasMatch(value.trim())) {
      return ValidationResult.failure('Name can only contain letters and spaces');
    }
    return ValidationResult.success();
  }
  
  // Habit-specific validation
  ValidationResult validateHabitInput(String? value, String habitType) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Please select a $habitType option');
    }
    return ValidationResult.success();
  }
  
  ValidationResult validateSearchQuery(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Search query cannot be empty');
    }
    if (value.trim().length < 2) {
      return ValidationResult.failure('Search query must be at least 2 characters');
    }
    if (value.trim().length > 100) {
      return ValidationResult.failure('Search query is too long');
    }
    return ValidationResult.success();
  }
  
  ValidationResult validateAskStarboundQuery(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Please enter your question');
    }
    if (value.trim().length < 5) {
      return ValidationResult.failure('Please provide more details in your question');
    }
    if (value.trim().length > 500) {
      return ValidationResult.failure('Question is too long. Please keep it under 500 characters');
    }
    
    // Validate health/medical domain
    final healthValidation = validateHealthDomain(value);
    if (!healthValidation.isValid) {
      return healthValidation;
    }
    
    return ValidationResult.success();
  }

  // Health domain validation keywords and scoring
  static final List<String> _healthKeywords = [
    // Medical conditions
    'health', 'medical', 'doctor', 'symptom', 'diagnosis', 'treatment', 'medicine', 'medication',
    'disease', 'illness', 'pain', 'ache', 'fever', 'infection', 'condition', 'disorder',
    'therapy', 'prescription', 'clinic', 'hospital', 'patient', 'healthcare',
    
    // Wellness and lifestyle
    'wellness', 'fitness', 'exercise', 'diet', 'nutrition', 'weight', 'sleep', 'stress',
    'mental health', 'anxiety', 'depression', 'mood', 'meditation', 'mindfulness',
    'habit', 'lifestyle', 'recovery', 'healing', 'prevention', 'immune',
    
    // Social health and relationships
    'relationship', 'relationships', 'social', 'friendship', 'friends', 'family', 'loneliness',
    'isolation', 'communication', 'boundaries', 'support system', 'social anxiety', 'connect',
    'belonging', 'community', 'intimacy', 'conflict', 'trust', 'emotional support',
    'social skills', 'networking', 'peer pressure', 'bullying', 'workplace relationships',
    'dating', 'marriage', 'parenting', 'caregiving', 'grief', 'loss', 'social media',
    
    // Body parts and systems
    'heart', 'lung', 'brain', 'stomach', 'liver', 'kidney', 'muscle', 'bone',
    'blood', 'skin', 'eye', 'ear', 'throat', 'chest', 'back', 'head',
    
    // Health actions
    'feel', 'hurt', 'tired', 'sick', 'healthy', 'improve', 'manage', 'cope',
    'prevent', 'treat', 'heal', 'recover', 'support', 'care'
  ];

  static final List<String> _inappropriateKeywords = [
    // Financial advice
    'invest', 'stock', 'crypto', 'bitcoin', 'trading', 'finance', 'money', 'loan', 'mortgage',
    'insurance', 'tax', 'accounting', 'budget', 'savings', 'retirement',
    
    // Legal advice
    'legal', 'lawyer', 'attorney', 'court', 'lawsuit', 'contract', 'divorce', 'custody',
    'crime', 'arrest', 'police', 'rights', 'law', 'regulation',
    
    // Technical/non-health topics
    'programming', 'code', 'software', 'computer', 'technology', 'app', 'website',
    'car', 'vehicle', 'repair', 'mechanic', 'engine',
    
    // Academic subjects (non-health)
    'math', 'physics', 'chemistry', 'history', 'literature', 'geography',
    'homework', 'assignment', 'essay', 'research paper'
  ];

  ValidationResult validateHealthDomain(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Please enter your question');
    }

    final query = value.trim().toLowerCase();
    
    // Debug logging for validation process
    if (true) { // Always log for debugging
      print('🔍 VALIDATION: Checking query: "$query"');
    }
    
    // Check for inappropriate content first
    int inappropriateScore = 0;
    for (String keyword in _inappropriateKeywords) {
      if (query.contains(keyword.toLowerCase())) {
        inappropriateScore += 2;
      }
    }

    // Check for health-related content
    int healthScore = 0;
    for (String keyword in _healthKeywords) {
      if (query.contains(keyword.toLowerCase())) {
        healthScore += 1;
      }
    }

    // Additional health patterns including social health - EXPANDED FOR MORE PERMISSIVENESS
    final healthPatterns = [
      RegExp(r'\bhow\s+to\s+(improve|manage|treat|prevent|cope|deal\s+with)', caseSensitive: false),
      RegExp(r'\bwhat\s+(causes|helps|prevents|treats)', caseSensitive: false),
      RegExp(r'\bis\s+it\s+(normal|safe|healthy)', caseSensitive: false),
      RegExp(r'\bshould\s+i\s+(see\s+a\s+doctor|be\s+worried|take)', caseSensitive: false),
      RegExp(r'\bhow\s+to\s+(communicate|connect|build\s+relationships|make\s+friends)', caseSensitive: false),
      RegExp(r'\bfeeling\s+(lonely|isolated|disconnected|rejected)', caseSensitive: false),
      RegExp(r'\bstruggling\s+with\s+(relationships|social|communication|boundaries)', caseSensitive: false),
      RegExp(r'\bhow\s+do\s+i\s+(handle|deal\s+with|manage)\s+(conflict|peer\s+pressure|social\s+anxiety)', caseSensitive: false),
      
      // Common question patterns that are likely health-related
      RegExp(r'\bwhy\s+(do|am)\s+i\s+(feel|always)', caseSensitive: false), // "Why do I feel tired?"
      RegExp(r'\bhow\s+(can|do)\s+i\s+(get|be|feel|sleep|eat)', caseSensitive: false), // "How can I sleep better?"  
      RegExp(r'\bwhat\s+(should|can)\s+i\s+(do|eat|take)', caseSensitive: false), // "What should I eat?"
      RegExp(r'\bi\s+(feel|am|have|need|want)\s+', caseSensitive: false), // "I feel...", "I am...", "I have..."
      RegExp(r'\bhelp\s+(me|with)', caseSensitive: false), // "Help me with..."
      RegExp(r'\btired|exhausted|energy|fatigue', caseSensitive: false), // Energy-related
      RegExp(r'\bsleep|sleeping|insomnia|rest', caseSensitive: false), // Sleep-related
      RegExp(r'\beat|eating|food|hungry|appetite', caseSensitive: false), // Food-related
      RegExp(r'\bstressed?|stressed|worry|worried|anxious', caseSensitive: false), // Stress-related
      RegExp(r'\bbetter|improve|fix|solve|help', caseSensitive: false), // Improvement-seeking
    ];

    for (RegExp pattern in healthPatterns) {
      if (pattern.hasMatch(query)) {
        healthScore += 2;
      }
    }

    // Debug logging for scores
    print('🔍 VALIDATION: inappropriateScore=$inappropriateScore, healthScore=$healthScore');
    
    // Decision logic - MUCH MORE PERMISSIVE
    if (inappropriateScore > 4) { // Increased threshold - only block clearly inappropriate content
      print('❌ VALIDATION: BLOCKED - Too inappropriate (score: $inappropriateScore)');
      return ValidationResult.failure(
        'I can only help with health and wellness questions. Please ask about medical conditions, symptoms, lifestyle, social health, or general wellbeing.'
      );
    }

    // REMOVED: The overly restrictive healthScore == 0 check
    // Instead, we'll be much more permissive and let the AI determine if it can help
    // This allows natural language questions that might not match our keyword patterns
    
    // Only block if it's very obviously inappropriate AND has no health context
    if (inappropriateScore > 2 && healthScore == 0) {
      print('❌ VALIDATION: BLOCKED - Inappropriate with no health context');
      return ValidationResult.failure(
        'I\'m designed to help with health and wellness questions. Please ask about your wellbeing, lifestyle, or any health-related concerns.'
      );
    }

    print('✅ VALIDATION: PASSED - Question allowed');
    return ValidationResult.success();
  }
  
  ValidationResult validateForecastInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Please describe a habit');
    }
    if (value.trim().length < 3) {
      return ValidationResult.failure('Please provide more details about the habit');
    }
    if (value.trim().length > 200) {
      return ValidationResult.failure('Description is too long. Please keep it under 200 characters');
    }
    return ValidationResult.success();
  }
  
  // Time validation
  ValidationResult validateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Time is required');
    }
    
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value.trim())) {
      return ValidationResult.failure('Please enter a valid time (HH:MM)');
    }
    
    return ValidationResult.success();
  }
  
  // Combined validation
  ValidationResult validateMultiple(List<ValidationResult> results) {
    final errors = results.where((r) => !r.isValid).map((r) => r.error!).toList();
    
    if (errors.isEmpty) {
      return ValidationResult.success();
    }
    
    return ValidationResult.multipleErrors(errors);
  }
  
  // Context-specific validators
  ValidationResult validateUserProfile(Map<String, dynamic> profileData) {
    final errors = <String>[];
    
    // Validate name
    final nameResult = validateName(profileData['name']);
    if (!nameResult.isValid) {
      errors.add(nameResult.error!);
    }
    
    // Validate notification time if provided
    if (profileData.containsKey('notificationTime')) {
      final timeResult = validateTime(profileData['notificationTime']);
      if (!timeResult.isValid) {
        errors.add(timeResult.error!);
      }
    }
    
    if (errors.isEmpty) {
      return ValidationResult.success();
    }
    
    return ValidationResult.multipleErrors(errors);
  }
  
  // Sanitization methods
  String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  String sanitizeSearchQuery(String query) {
    return query.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
  }
  
  String sanitizeName(String name) {
    return name.trim().split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
    ).join(' ');
  }
  
  // Helper methods
  bool isValidEmail(String email) => _emailRegex.hasMatch(email.trim());
  bool isValidPhone(String phone) => _phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[^\d+]'), ''));
  bool isValidName(String name) => _nameRegex.hasMatch(name.trim()) && name.trim().length >= 2;
  
  // Custom validation builder
  ValidationResult validateCustom(String? value, List<bool Function(String)> validators, List<String> errorMessages) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.failure('Field is required');
    }
    
    for (int i = 0; i < validators.length; i++) {
      if (!validators[i](value)) {
        return ValidationResult.failure(errorMessages[i]);
      }
    }
    
    return ValidationResult.success();
  }
}