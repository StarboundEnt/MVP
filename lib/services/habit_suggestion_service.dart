import 'package:flutter/foundation.dart';
import '../models/complexity_profile.dart';
import '../models/habit_model.dart';
import 'storage_service.dart';
import 'pattern_recognition_service.dart';
import 'correlation_service.dart';

enum SuggestionType {
  foundational,    // Basic habits for building routine
  complementary,   // Habits that pair well with existing ones
  recovery,        // Habits to help during difficult periods
  growth,          // Advanced habits for stable users
  seasonal,        // Time-sensitive recommendations
}

class HabitSuggestion {
  final String id;
  final String habitKey;
  final String title;
  final String description;
  final String rationale;
  final SuggestionType type;
  final double confidence;
  final double successProbability;
  final int priority;
  final List<String> relatedHabits;
  final Map<String, dynamic> metadata;
  final DateTime suggestedAt;
  
  HabitSuggestion({
    required this.id,
    required this.habitKey,
    required this.title,
    required this.description,
    required this.rationale,
    required this.type,
    required this.confidence,
    required this.successProbability,
    required this.priority,
    this.relatedHabits = const [],
    this.metadata = const {},
    DateTime? suggestedAt,
  }) : suggestedAt = suggestedAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'habitKey': habitKey,
    'title': title,
    'description': description,
    'rationale': rationale,
    'type': type.index,
    'confidence': confidence,
    'successProbability': successProbability,
    'priority': priority,
    'relatedHabits': relatedHabits,
    'metadata': metadata,
    'suggestedAt': suggestedAt.toIso8601String(),
  };
  
  factory HabitSuggestion.fromJson(Map<String, dynamic> json) => HabitSuggestion(
    id: json['id'],
    habitKey: json['habitKey'],
    title: json['title'],
    description: json['description'],
    rationale: json['rationale'],
    type: SuggestionType.values[json['type']],
    confidence: json['confidence']?.toDouble() ?? 0.0,
    successProbability: json['successProbability']?.toDouble() ?? 0.0,
    priority: json['priority'] ?? 0,
    relatedHabits: List<String>.from(json['relatedHabits'] ?? []),
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    suggestedAt: DateTime.parse(json['suggestedAt']),
  );
}

class HabitSuggestionService {
  static final HabitSuggestionService _instance = HabitSuggestionService._internal();
  factory HabitSuggestionService() => _instance;
  HabitSuggestionService._internal();
  
  final StorageService _storageService = StorageService();
  final PatternRecognitionService _patternService = PatternRecognitionService();
  final CorrelationService _correlationService = CorrelationService();
  
  // Generate personalized habit suggestions
  Future<List<HabitSuggestion>> generateSuggestions({
    required Map<String, String?> currentHabits,
    required ComplexityAssessment complexityAssessment,
    required List<SuccessPattern> patterns,
    required List<HabitCorrelation> correlations,
    int maxSuggestions = 5,
  }) async {
    try {
      final suggestions = <HabitSuggestion>[];
      final availableHabits = _getAvailableHabits(currentHabits);
      
      // Generate different types of suggestions based on complexity level
      switch (complexityAssessment.primaryLevel) {
        case ComplexityLevel.stable:
          suggestions.addAll(await _generateGrowthSuggestions(availableHabits, patterns, correlations));
          suggestions.addAll(await _generateComplementarySuggestions(currentHabits, correlations));
          break;
          
        case ComplexityLevel.trying:
          suggestions.addAll(await _generateFoundationalSuggestions(availableHabits, complexityAssessment));
          suggestions.addAll(await _generateComplementarySuggestions(currentHabits, correlations));
          break;
          
        case ComplexityLevel.overloaded:
          suggestions.addAll(await _generateFoundationalSuggestions(availableHabits, complexityAssessment));
          suggestions.addAll(await _generateRecoverySuggestions(availableHabits, complexityAssessment));
          break;
          
        case ComplexityLevel.survival:
          suggestions.addAll(await _generateRecoverySuggestions(availableHabits, complexityAssessment));
          break;
      }
      
      // Add seasonal suggestions for all users
      suggestions.addAll(await _generateSeasonalSuggestions(availableHabits, complexityAssessment));
      
      // Score and filter suggestions
      final scoredSuggestions = await _scoreSuggestions(suggestions, currentHabits, complexityAssessment, patterns);
      
      // Sort by priority and confidence, limit results
      scoredSuggestions.sort((a, b) {
        final priorityComparison = b.priority.compareTo(a.priority);
        if (priorityComparison != 0) return priorityComparison;
        return b.confidence.compareTo(a.confidence);
      });
      
      return scoredSuggestions.take(maxSuggestions).toList();
    } catch (e) {
      debugPrint('Error generating habit suggestions: $e');
      return [];
    }
  }
  
  // Get habits that user doesn't currently track
  List<String> _getAvailableHabits(Map<String, String?> currentHabits) {
    final allHabits = StarboundHabits.all.keys.toList();
    final currentHabitKeys = currentHabits.keys.toList();
    return allHabits.where((habit) => !currentHabitKeys.contains(habit)).toList();
  }
  
  // Generate foundational habit suggestions for building basic routines
  Future<List<HabitSuggestion>> _generateFoundationalSuggestions(
    List<String> availableHabits,
    ComplexityAssessment assessment,
  ) async {
    final suggestions = <HabitSuggestion>[];
    
    // Prioritize simple, high-impact habits based on complexity categories
    final foundationalHabits = <String, double>{
      'hydration': 0.9,
      'sleep': 0.8,
      'deep_breathing': 0.7,
      'gratitude': 0.6,
      'stretching': 0.5,
    };
    
    for (final entry in foundationalHabits.entries) {
      if (availableHabits.contains(entry.key)) {
        final category = StarboundHabits.all[entry.key];
        if (category != null) {
          suggestions.add(HabitSuggestion(
            id: 'foundational_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            habitKey: entry.key,
            title: category.title,
            description: category.description,
            rationale: _getFoundationalRationale(entry.key, assessment),
            type: SuggestionType.foundational,
            confidence: entry.value,
            successProbability: _calculateFoundationalSuccessProbability(entry.key, assessment),
            priority: _getFoundationalPriority(entry.key, assessment),
            metadata: {
              'complexity_match': _assessComplexityMatch(entry.key, assessment),
              'time_requirement': 'low',
            },
          ));
        }
      }
    }
    
    return suggestions;
  }
  
  // Generate complementary habit suggestions based on correlations
  Future<List<HabitSuggestion>> _generateComplementarySuggestions(
    Map<String, String?> currentHabits,
    List<HabitCorrelation> correlations,
  ) async {
    final suggestions = <HabitSuggestion>[];
    
    // Find habits that correlate positively with user's successful habits
    final successfulHabits = currentHabits.entries
        .where((entry) => entry.value == 'good' || entry.value == 'excellent')
        .map((entry) => entry.key)
        .toList();
    
    for (final habit in successfulHabits) {
      final relatedCorrelations = correlations
          .where((c) => 
              (c.habit1 == habit || c.habit2 == habit) && 
              c.type == CorrelationType.positive &&
              c.strength > 0.6)
          .toList();
      
      for (final correlation in relatedCorrelations) {
        final suggestedHabit = correlation.habit1 == habit ? correlation.habit2 : correlation.habit1;
        final category = StarboundHabits.all[suggestedHabit];
        
        if (category != null && !currentHabits.containsKey(suggestedHabit)) {
          suggestions.add(HabitSuggestion(
            id: 'complementary_${suggestedHabit}_${DateTime.now().millisecondsSinceEpoch}',
            habitKey: suggestedHabit,
            title: category.title,
            description: category.description,
            rationale: 'This habit pairs well with your successful ${StarboundHabits.all[habit]?.title ?? habit} habit. ${correlation.insight}',
            type: SuggestionType.complementary,
            confidence: correlation.strength,
            successProbability: _calculateComplementarySuccessProbability(correlation),
            priority: 3,
            relatedHabits: [habit],
            metadata: {
              'correlation_strength': correlation.strength,
              'base_habit': habit,
            },
          ));
        }
      }
    }
    
    return suggestions;
  }
  
  // Generate recovery-focused suggestions for stressed users
  Future<List<HabitSuggestion>> _generateRecoverySuggestions(
    List<String> availableHabits,
    ComplexityAssessment assessment,
  ) async {
    final suggestions = <HabitSuggestion>[];
    
    // Focus on stress relief and basic self-care
    final recoveryHabits = <String, double>{
      'deep_breathing': 0.9,
      'meditation': 0.8,
      'gentle_movement': 0.7,
      'journaling': 0.6,
      'hydration': 0.8,
    };
    
    for (final entry in recoveryHabits.entries) {
      if (availableHabits.contains(entry.key)) {
        final category = StarboundHabits.all[entry.key];
        if (category != null) {
          suggestions.add(HabitSuggestion(
            id: 'recovery_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            habitKey: entry.key,
            title: category.title,
            description: category.description,
            rationale: _getRecoveryRationale(entry.key, assessment),
            type: SuggestionType.recovery,
            confidence: entry.value,
            successProbability: _calculateRecoverySuccessProbability(entry.key, assessment),
            priority: 4,
            metadata: {
              'stress_relief': true,
              'low_energy_suitable': true,
            },
          ));
        }
      }
    }
    
    return suggestions;
  }
  
  // Generate growth-oriented suggestions for stable users
  Future<List<HabitSuggestion>> _generateGrowthSuggestions(
    List<String> availableHabits,
    List<SuccessPattern> patterns,
    List<HabitCorrelation> correlations,
  ) async {
    final suggestions = <HabitSuggestion>[];
    
    // Suggest more challenging or advanced habits
    final growthHabits = <String, double>{
      'exercise': 0.8,
      'reading': 0.7,
      'meal_prep': 0.6,
      'learning': 0.7,
      'creativity': 0.6,
    };
    
    for (final entry in growthHabits.entries) {
      if (availableHabits.contains(entry.key)) {
        final category = StarboundHabits.all[entry.key];
        if (category != null) {
          suggestions.add(HabitSuggestion(
            id: 'growth_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            habitKey: entry.key,
            title: category.title,
            description: category.description,
            rationale: _getGrowthRationale(entry.key, patterns),
            type: SuggestionType.growth,
            confidence: entry.value,
            successProbability: _calculateGrowthSuccessProbability(entry.key, patterns),
            priority: 2,
            metadata: {
              'challenging': true,
              'growth_oriented': true,
            },
          ));
        }
      }
    }
    
    return suggestions;
  }
  
  // Generate seasonal and contextual suggestions
  Future<List<HabitSuggestion>> _generateSeasonalSuggestions(
    List<String> availableHabits,
    ComplexityAssessment assessment,
  ) async {
    final suggestions = <HabitSuggestion>[];
    final now = DateTime.now();
    final month = now.month;
    
    // Seasonal habit recommendations
    Map<String, double> seasonalHabits = {};
    
    if (month >= 12 || month <= 2) { // Winter
      seasonalHabits = {
        'vitamin_d': 0.8,
        'indoor_exercise': 0.7,
        'warm_drinks': 0.6,
      };
    } else if (month >= 3 && month <= 5) { // Spring
      seasonalHabits = {
        'outdoor_time': 0.8,
        'spring_cleaning': 0.6,
        'gardening': 0.5,
      };
    } else if (month >= 6 && month <= 8) { // Summer
      seasonalHabits = {
        'hydration': 0.9,
        'sun_protection': 0.8,
        'outdoor_exercise': 0.7,
      };
    } else { // Fall
      seasonalHabits = {
        'immune_support': 0.7,
        'cozy_routines': 0.6,
        'reflection': 0.5,
      };
    }
    
    for (final entry in seasonalHabits.entries) {
      if (availableHabits.contains(entry.key)) {
        final category = StarboundHabits.all[entry.key];
        if (category != null) {
          suggestions.add(HabitSuggestion(
            id: 'seasonal_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
            habitKey: entry.key,
            title: category.title,
            description: category.description,
            rationale: _getSeasonalRationale(entry.key, month),
            type: SuggestionType.seasonal,
            confidence: entry.value,
            successProbability: _calculateSeasonalSuccessProbability(entry.key, assessment),
            priority: 1,
            metadata: {
              'seasonal': true,
              'month': month,
            },
          ));
        }
      }
    }
    
    return suggestions;
  }
  
  // Score and enhance suggestions with success probabilities
  Future<List<HabitSuggestion>> _scoreSuggestions(
    List<HabitSuggestion> suggestions,
    Map<String, String?> currentHabits,
    ComplexityAssessment assessment,
    List<SuccessPattern> patterns,
  ) async {
    final enhancedSuggestions = <HabitSuggestion>[];
    final correlations = await _correlationService.analyzeHabitCorrelations(
      currentHabits: currentHabits,
      daysToAnalyze: 30,
    );
    
    for (final suggestion in suggestions) {
      // Calculate precise success probability using the pattern recognition service
      final environmentalFactors = _getEnvironmentalFactors(assessment);
      final successProbability = await _patternService.calculateHabitSuccessProbability(
        habitKey: suggestion.habitKey,
        currentHabits: currentHabits,
        complexityProfile: assessment,
        patterns: patterns,
        correlations: correlations,
        environmentalFactors: environmentalFactors,
      );
      
      // Generate detailed explanation
      final explanation = _patternService.explainSuccessProbability(
        successProbability, 
        suggestion.habitKey, 
        assessment,
      );
      
      // Enhanced rationale with contextual factors
      final enhancedRationale = _enhanceRationaleWithContext(
        suggestion.rationale,
        suggestion.habitKey,
        assessment,
        successProbability,
      );
      
      // Create enhanced suggestion with precise scoring
      enhancedSuggestions.add(HabitSuggestion(
        id: suggestion.id,
        habitKey: suggestion.habitKey,
        title: suggestion.title,
        description: suggestion.description,
        rationale: enhancedRationale,
        type: suggestion.type,
        confidence: suggestion.confidence,
        successProbability: successProbability,
        priority: _calculateDynamicPriority(suggestion, successProbability, assessment),
        relatedHabits: suggestion.relatedHabits,
        metadata: {
          ...suggestion.metadata,
          'success_explanation': explanation,
          'environmental_factors': environmentalFactors,
          'confidence_interval': _patternService.generateProbabilityConfidenceInterval(successProbability),
        },
        suggestedAt: suggestion.suggestedAt,
      ));
    }
    
    return enhancedSuggestions;
  }
  
  // Extract environmental factors from complexity assessment
  Map<String, dynamic> _getEnvironmentalFactors(ComplexityAssessment assessment) {
    return {
      'social_support': _mapSocialSupport(assessment.highStressCategories, assessment.supportiveCategories),
      'time_capacity': _mapTimeCapacity(assessment.highStressCategories, assessment.supportiveCategories),
      'financial_stress': assessment.highStressCategories.contains(ComplexityCategory.financialStability),
      'care_responsibilities': assessment.highStressCategories.contains(ComplexityCategory.careResponsibilities),
      'mental_health_support': assessment.supportiveCategories.contains(ComplexityCategory.mentalHealth),
      'living_stability': assessment.supportiveCategories.contains(ComplexityCategory.livingCircumstances),
    };
  }
  
  String _mapSocialSupport(List<ComplexityCategory> stressed, List<ComplexityCategory> supportive) {
    if (supportive.contains(ComplexityCategory.socialSupport)) return 'strong';
    if (stressed.contains(ComplexityCategory.socialSupport)) return 'limited';
    return 'moderate';
  }
  
  String _mapTimeCapacity(List<ComplexityCategory> stressed, List<ComplexityCategory> supportive) {
    if (supportive.contains(ComplexityCategory.timeCapacity)) return 'plenty';
    if (stressed.contains(ComplexityCategory.timeCapacity)) return 'very_little';
    return 'some';
  }
  
  // Enhance rationale with contextual information
  String _enhanceRationaleWithContext(
    String baseRationale,
    String habitKey,
    ComplexityAssessment assessment,
    double successProbability,
  ) {
    final contextualTips = <String>[];
    
    // Add complexity-specific guidance
    switch (assessment.primaryLevel) {
      case ComplexityLevel.stable:
        if (successProbability > 75) {
          contextualTips.add("You're in a great position to take on this challenge.");
        }
        break;
      case ComplexityLevel.trying:
        contextualTips.add("Start small and be patient with yourself as you build this habit.");
        break;
      case ComplexityLevel.overloaded:
        contextualTips.add("Consider this when you have a lighter day or week.");
        break;
      case ComplexityLevel.survival:
        contextualTips.add("Any progress with this habit is a victory - be gentle with yourself.");
        break;
    }
    
    // Add environmental considerations
    if (assessment.highStressCategories.contains(ComplexityCategory.timeCapacity)) {
      contextualTips.add("Look for micro-moments throughout your day to practice this.");
    }
    
    if (assessment.highStressCategories.contains(ComplexityCategory.financialStability) && 
        !['hydration', 'deep_breathing', 'gratitude', 'stretching'].contains(habitKey)) {
      contextualTips.add("Consider low-cost or free ways to implement this habit.");
    }
    
    if (assessment.supportiveCategories.contains(ComplexityCategory.socialSupport)) {
      contextualTips.add("Your support network could help you stay accountable with this habit.");
    }
    
    // Add seasonal context
    final month = DateTime.now().month;
    if (habitKey.contains('outdoor') && (month <= 2 || month >= 11)) {
      contextualTips.add("Consider indoor alternatives during colder months.");
    }
    
    if (habitKey.contains('hydration') && month >= 6 && month <= 8) {
      contextualTips.add("Perfect timing - staying hydrated is especially important in summer.");
    }
    
    // Combine base rationale with contextual tips
    String enhanced = baseRationale;
    if (contextualTips.isNotEmpty) {
      enhanced += '\n\n💡 ' + contextualTips.join(' ');
    }
    
    return enhanced;
  }
  
  // Calculate dynamic priority based on success probability and user needs
  int _calculateDynamicPriority(HabitSuggestion suggestion, double successProbability, ComplexityAssessment assessment) {
    int priority = suggestion.priority;
    
    // Boost priority for high-success habits
    if (successProbability > 80) {
      priority += 2;
    } else if (successProbability > 65) {
      priority += 1;
    }
    
    // Adjust for urgent needs based on complexity categories
    if (assessment.highStressCategories.contains(ComplexityCategory.mentalHealth) &&
        ['deep_breathing', 'meditation', 'gratitude'].contains(suggestion.habitKey)) {
      priority += 3; // Mental health support is urgent
    }
    
    if (assessment.highStressCategories.contains(ComplexityCategory.physicalHealth) &&
        ['hydration', 'sleep', 'movement'].contains(suggestion.habitKey)) {
      priority += 2; // Physical health basics are important
    }
    
    // Lower priority for challenging habits when user is stressed
    if ((assessment.primaryLevel == ComplexityLevel.overloaded || 
         assessment.primaryLevel == ComplexityLevel.survival) &&
        successProbability < 50) {
      priority -= 2;
    }
    
    return priority.clamp(1, 10);
  }
  
  // Helper methods for generating rationales
  String _getFoundationalRationale(String habitKey, ComplexityAssessment assessment) {
    switch (habitKey) {
      case 'hydration':
        return 'Staying hydrated is one of the simplest ways to boost energy and mood. Perfect for building a sustainable routine.';
      case 'sleep':
        return 'Quality sleep is the foundation of all other health habits. When you sleep well, everything else becomes easier.';
      case 'deep_breathing':
        return 'A few minutes of deep breathing can reduce stress and increase focus. It\'s simple and works anywhere.';
      case 'gratitude':
        return 'Taking a moment for gratitude can shift your mindset and build resilience during challenging times.';
      case 'stretching':
        return 'Gentle stretching relieves tension and improves mobility. It\'s a kind way to care for your body.';
      default:
        return 'This habit provides a solid foundation for building healthier routines.';
    }
  }
  
  String _getRecoveryRationale(String habitKey, ComplexityAssessment assessment) {
    final stressAreas = assessment.highStressCategories.map((c) => ComplexityProfileService.getCategoryName(c)).join(', ');
    return 'Given the stress you\'re experiencing with $stressAreas, this gentle habit can provide relief without adding pressure.';
  }
  
  String _getGrowthRationale(String habitKey, List<SuccessPattern> patterns) {
    return 'Based on your success patterns, you\'re ready to take on this more challenging habit that can accelerate your progress.';
  }
  
  String _getSeasonalRationale(String habitKey, int month) {
    final season = month >= 12 || month <= 2 ? 'winter' : 
                  month >= 3 && month <= 5 ? 'spring' : 
                  month >= 6 && month <= 8 ? 'summer' : 'fall';
    return 'This habit is particularly beneficial during $season and aligns with natural seasonal rhythms.';
  }
  
  // Helper methods for calculating success probabilities
  double _calculateFoundationalSuccessProbability(String habitKey, ComplexityAssessment assessment) {
    double baseProbability = 0.7; // Foundational habits generally have good success rates
    
    // Adjust based on complexity level
    switch (assessment.primaryLevel) {
      case ComplexityLevel.stable:
        baseProbability += 0.2;
        break;
      case ComplexityLevel.trying:
        baseProbability += 0.1;
        break;
      case ComplexityLevel.overloaded:
        baseProbability -= 0.1;
        break;
      case ComplexityLevel.survival:
        baseProbability -= 0.2;
        break;
    }
    
    return (baseProbability * 100).clamp(0, 100);
  }
  
  double _calculateComplementarySuccessProbability(HabitCorrelation correlation) {
    return (correlation.strength * 100).clamp(0, 100);
  }
  
  double _calculateRecoverySuccessProbability(String habitKey, ComplexityAssessment assessment) {
    return 60.0; // Recovery habits are designed to be accessible
  }
  
  double _calculateGrowthSuccessProbability(String habitKey, List<SuccessPattern> patterns) {
    return 75.0; // Growth habits for stable users
  }
  
  double _calculateSeasonalSuccessProbability(String habitKey, ComplexityAssessment assessment) {
    double baseProbability = 65.0;
    
    // Seasonal habits benefit from natural timing
    switch (assessment.primaryLevel) {
      case ComplexityLevel.stable:
        baseProbability += 15.0;
        break;
      case ComplexityLevel.trying:
        baseProbability += 10.0;
        break;
      default:
        break;
    }
    
    return baseProbability.clamp(0, 100);
  }
  
  // Helper methods for priority and complexity matching
  int _getFoundationalPriority(String habitKey, ComplexityAssessment assessment) {
    if (assessment.highStressCategories.contains(ComplexityCategory.mentalHealth) && 
        ['deep_breathing', 'meditation', 'gratitude'].contains(habitKey)) {
      return 5; // High priority for mental health support
    }
    return 4;
  }
  
  double _assessComplexityMatch(String habitKey, ComplexityAssessment assessment) {
    // Return a score of how well this habit matches the user's complexity profile
    return 0.8; // Simplified for now
  }
}