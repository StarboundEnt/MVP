import 'package:flutter/foundation.dart';
import '../models/smart_tag_model.dart';
import '../models/nudge_model.dart';

/// Result of nudge recommendation analysis
class NudgeRecommendationResult {
  final List<String> recommendedNudgeIds;
  final Map<String, double> nudgeScores; // nudgeId -> relevance score
  final List<String> triggerTags; // Which tags triggered these recommendations
  final String reasoning;
  final DateTime timestamp;

  const NudgeRecommendationResult({
    required this.recommendedNudgeIds,
    required this.nudgeScores,
    required this.triggerTags,
    required this.reasoning,
    required this.timestamp,
  });

  bool get hasRecommendations => recommendedNudgeIds.isNotEmpty;
  int get recommendationCount => recommendedNudgeIds.length;
  
  // Get top recommendation
  String? get topRecommendation => recommendedNudgeIds.isNotEmpty ? recommendedNudgeIds.first : null;
  
  Map<String, dynamic> toJson() {
    return {
      'recommendedNudgeIds': recommendedNudgeIds,
      'nudgeScores': nudgeScores,
      'triggerTags': triggerTags,
      'reasoning': reasoning,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Service for generating nudge recommendations based on smart tags
class NudgeRecommendationService {
  static final NudgeRecommendationService _instance = NudgeRecommendationService._internal();
  factory NudgeRecommendationService() => _instance;
  NudgeRecommendationService._internal();

  // Recommendation cache
  final Map<String, NudgeRecommendationResult> _recommendationCache = {};
  static const int _maxCacheSize = 50;

  /// Generate nudge recommendations based on smart tags
  NudgeRecommendationResult generateRecommendations(List<SmartTag> smartTags) {
    if (smartTags.isEmpty) {
      return NudgeRecommendationResult(
        recommendedNudgeIds: [],
        nudgeScores: {},
        triggerTags: [],
        reasoning: 'No smart tags provided for analysis',
        timestamp: DateTime.now(),
      );
    }

    // Create cache key from sorted tag keys
    final cacheKey = smartTags
        .map((t) => '${t.canonicalKey}:${t.confidence.toStringAsFixed(2)}')
        .toList()
        ..sort();
    final cacheKeyStr = cacheKey.join('|');

    // Check cache
    if (_recommendationCache.containsKey(cacheKeyStr)) {
      return _recommendationCache[cacheKeyStr]!;
    }

    try {
      final result = _analyzeTagsAndRecommend(smartTags);
      
      // Cache result
      if (_recommendationCache.length >= _maxCacheSize) {
        _recommendationCache.remove(_recommendationCache.keys.first);
      }
      _recommendationCache[cacheKeyStr] = result;
      
      return result;
    } catch (e) {
      debugPrint('NudgeRecommendationService: Failed to generate recommendations: $e');
      return NudgeRecommendationResult(
        recommendedNudgeIds: [],
        nudgeScores: {},
        triggerTags: [],
        reasoning: 'Failed to generate recommendations: ${e.toString()}',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Analyze smart tags and generate recommendations
  NudgeRecommendationResult _analyzeTagsAndRecommend(List<SmartTag> smartTags) {
    final Map<String, double> nudgeScores = {};
    final List<String> triggerTags = [];
    final List<String> reasoningParts = [];

    // Get all available nudges
    final availableNudges = NudgeVault.nudges;

    // Analyze each smart tag and score relevant nudges
    for (final tag in smartTags) {
      if (tag.confidence < 0.4) continue; // Skip low confidence tags
      
      final tagRecommendations = _getRecommendationsForTag(tag, availableNudges);
      if (tagRecommendations.isNotEmpty) {
        triggerTags.add(tag.canonicalKey);
        reasoningParts.add('${tag.displayName} (${tag.confidence.toStringAsFixed(2)})');
      }

      // Add scores for this tag's recommendations
      for (final entry in tagRecommendations.entries) {
        final nudgeId = entry.key;
        final baseScore = entry.value;
        
        // Apply confidence weighting
        final confidenceWeight = tag.confidence;
        final finalScore = baseScore * confidenceWeight;
        
        // Combine with existing score if present
        nudgeScores[nudgeId] = (nudgeScores[nudgeId] ?? 0.0) + finalScore;
      }
    }

    // Apply sentiment and context boosting
    _applySentimentBoosting(smartTags, nudgeScores);
    _applyContextualBoosting(smartTags, nudgeScores, availableNudges);

    // Sort by score and take top recommendations
    final sortedNudges = nudgeScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final recommendedIds = sortedNudges
        .take(5) // Top 5 recommendations
        .where((entry) => entry.value >= 0.3) // Minimum score threshold
        .map((entry) => entry.key)
        .toList();

    final reasoning = reasoningParts.isNotEmpty 
        ? 'Based on: ${reasoningParts.join(', ')}'
        : 'No significant triggers found';

    return NudgeRecommendationResult(
      recommendedNudgeIds: recommendedIds,
      nudgeScores: Map.fromEntries(sortedNudges.take(10)), // Top 10 scores
      triggerTags: triggerTags,
      reasoning: reasoning,
      timestamp: DateTime.now(),
    );
  }

  /// Get nudge recommendations for a specific smart tag
  Map<String, double> _getRecommendationsForTag(SmartTag tag, List<StarboundNudge> availableNudges) {
    final Map<String, double> scores = {};

    // Tag-specific recommendation mapping
    final tagRecommendations = _getTagRecommendationMappings();
    final mappings = tagRecommendations[tag.canonicalKey] ?? {};

    // Score nudges based on theme matching and specific mappings
    for (final nudge in availableNudges) {
      double score = 0.0;

      // Direct mapping score (highest priority)
      if (mappings.containsKey(nudge.id)) {
        score = mappings[nudge.id]!;
      }
      // Theme-based matching
      else if (_isThemeRelevant(tag, nudge)) {
        score = 0.6;
      }
      // Category-based matching (choice/chance alignment)
      else if (_isCategoryRelevant(tag, nudge)) {
        score = 0.4;
      }
      // General wellness matching
      else if (_isGeneralWellnessRelevant(tag, nudge)) {
        score = 0.2;
      }

      if (score > 0.0) {
        scores[nudge.id] = score;
      }
    }

    return scores;
  }

  /// Get tag-specific nudge recommendation mappings
  Map<String, Map<String, double>> _getTagRecommendationMappings() {
    return {
      // Choice tags - encourage positive reinforcement
      'daily_movement': {
        'movement_1': 0.9, // Direct movement nudges
        'movement_2': 0.8,
        'energy_1': 0.7,   // Energy-related nudges
        'hydration_1': 0.6, // Supporting hydration
      },
      'drinking_water': {
        'hydration_1': 0.9,
        'hydration_2': 0.8,
        'movement_1': 0.6, // Movement can support hydration
      },
      'quality_sleep': {
        'sleep_1': 0.9,
        'sleep_2': 0.8,
        'calm_1': 0.7,    // Calm/relaxation support
        'focus_1': 0.6,   // Mindfulness for sleep
      },
      'mindfulness': {
        'focus_1': 0.9,
        'focus_2': 0.8,
        'calm_1': 0.9,
        'sleep_1': 0.6,   // Mindfulness supports sleep
      },

      // Chance tags - offer supportive interventions  
      'financial_stress': {
        'calm_1': 0.8,    // Stress management
        'focus_1': 0.7,   // Mindfulness for stress
        'movement_1': 0.6, // Physical activity for stress relief
      },
      'anxiety': {
        'calm_1': 0.9,
        'focus_1': 0.8,   // Breathing/mindfulness
        'movement_1': 0.7, // Exercise for anxiety
        'hydration_1': 0.5, // Basic self-care
      },
      'social_support': {
        'calm_1': 0.7,    // Feeling centered before connecting
        'focus_1': 0.6,   // Mindfulness for social anxiety
      },

      // Outcome tags - provide appropriate responses
      'happy_mood': {
        'movement_1': 0.7, // Maintain with activity
        'hydration_1': 0.6, // Support with basics
      },
      'fatigue': {
        'sleep_1': 0.8,   // Address with rest
        'hydration_1': 0.7, // Basic hydration  
        'movement_1': 0.5, // Gentle movement
      },
      'depression': {
        'calm_1': 0.8,    // Emotional support
        'movement_1': 0.7, // Activity for mood
        'focus_1': 0.6,   // Mindfulness practices
      },
    };
  }

  /// Check if nudge theme is relevant to smart tag
  bool _isThemeRelevant(SmartTag tag, StarboundNudge nudge) {
    // Map canonical keys to nudge themes
    final themeMapping = {
      'daily_movement': ['movement'],
      'drinking_water': ['hydration'],
      'quality_sleep': ['sleep'],
      'mindfulness': ['focus', 'calm'],
      'balanced_meal': ['nutrition'],
      'anxiety': ['calm', 'focus'],
      'fatigue': ['sleep', 'hydration'],
      'happy_mood': ['movement', 'nutrition'],
    };

    final relevantThemes = themeMapping[tag.canonicalKey] ?? [];
    return relevantThemes.contains(nudge.theme);
  }

  /// Check if nudge category aligns with smart tag category
  bool _isCategoryRelevant(SmartTag tag, StarboundNudge nudge) {
    // Choices align with positive, proactive nudges
    if (tag.isChoice && nudge.tone == 'encouraging') return true;
    
    // Chances might need supportive, gentle nudges
    if (tag.isChance && nudge.tone == 'supportive') return true;
    
    // Outcomes need contextual responses
    if (tag.isOutcome) return true;
    
    return false;
  }

  /// Check if nudge provides general wellness support
  bool _isGeneralWellnessRelevant(SmartTag tag, StarboundNudge nudge) {
    // Basic wellness themes that support most situations
    final generalThemes = ['hydration', 'calm', 'focus'];
    return generalThemes.contains(nudge.theme);
  }

  /// Apply sentiment-based boosting to nudge scores
  void _applySentimentBoosting(List<SmartTag> smartTags, Map<String, double> nudgeScores) {
    // Get overall sentiment from tags
    final sentiments = smartTags.where((t) => t.sentimentConfidence > 0.5).map((t) => t.sentiment);
    
    if (sentiments.isEmpty) return;
    
    final positiveCount = sentiments.where((s) => s == 'positive').length;
    final negativeCount = sentiments.where((s) => s == 'negative').length;
    
    // Boost certain nudge types based on sentiment
    for (final entry in nudgeScores.entries.toList()) {
      final nudgeId = entry.key;
      final currentScore = entry.value;
      
      // Find the nudge
      final nudge = NudgeVault.nudges.firstWhere((n) => n.id == nudgeId);
      
      double multiplier = 1.0;
      
      if (negativeCount > positiveCount) {
        // More negative sentiment - boost supportive, gentle nudges
        if (nudge.tone == 'supportive' || nudge.energyRequired == 'very low') {
          multiplier = 1.2;
        }
      } else if (positiveCount > negativeCount) {
        // More positive sentiment - boost encouraging, active nudges
        if (nudge.tone == 'encouraging' || nudge.energyRequired == 'high') {
          multiplier = 1.15;
        }
      }
      
      nudgeScores[nudgeId] = currentScore * multiplier;
    }
  }

  /// Apply contextual boosting based on tag combinations
  void _applyContextualBoosting(List<SmartTag> smartTags, Map<String, double> nudgeScores, List<StarboundNudge> availableNudges) {
    // Look for tag patterns that suggest specific needs
    final tagKeys = smartTags.map((t) => t.canonicalKey).toSet();
    
    // Stress pattern (anxiety + other stressors)
    if (tagKeys.contains('anxiety') && (tagKeys.contains('financial_stress') || tagKeys.contains('fatigue'))) {
      _boostNudgesByTheme(nudgeScores, ['calm', 'focus'], 1.3);
    }
    
    // Wellness pattern (multiple positive choices)
    final positiveChoices = smartTags.where((t) => t.isChoice && t.isPositive).length;
    if (positiveChoices >= 2) {
      _boostNudgesByTheme(nudgeScores, ['movement', 'nutrition'], 1.2);
    }
    
    // Recovery pattern (fatigue + poor sleep)
    if (tagKeys.contains('fatigue') && tagKeys.contains('poor_sleep')) {
      _boostNudgesByTheme(nudgeScores, ['sleep', 'hydration'], 1.4);
    }
    
    // Energy pattern (low energy indicators)
    if (tagKeys.contains('fatigue') || tagKeys.contains('low_energy')) {
      _boostNudgesByEnergyRequired(nudgeScores, 'very low', 1.3);
    }
  }

  /// Boost nudges by theme
  void _boostNudgesByTheme(Map<String, double> nudgeScores, List<String> themes, double multiplier) {
    final relevantNudges = NudgeVault.nudges.where((n) => themes.contains(n.theme));
    
    for (final nudge in relevantNudges) {
      if (nudgeScores.containsKey(nudge.id)) {
        nudgeScores[nudge.id] = nudgeScores[nudge.id]! * multiplier;
      }
    }
  }

  /// Boost nudges by energy requirement
  void _boostNudgesByEnergyRequired(Map<String, double> nudgeScores, String energyLevel, double multiplier) {
    final relevantNudges = NudgeVault.nudges.where((n) => n.energyRequired == energyLevel);
    
    for (final nudge in relevantNudges) {
      if (nudgeScores.containsKey(nudge.id)) {
        nudgeScores[nudge.id] = nudgeScores[nudge.id]! * multiplier;
      }
    }
  }

  /// Generate nudges dynamically based on smart tags (for AI-generated nudges)
  Future<List<StarboundNudge>> generateDynamicNudges(List<SmartTag> smartTags) async {
    final dynamicNudges = <StarboundNudge>[];
    
    // Generate nudges for high-confidence, specific tags
    for (final tag in smartTags.where((t) => t.confidence >= 0.8)) {
      final nudge = await _generateNudgeForTag(tag);
      if (nudge != null) {
        dynamicNudges.add(nudge);
      }
    }
    
    return dynamicNudges;
  }

  /// Generate nudges from contextual suggestions
  List<StarboundNudge> generateNudgesFromSuggestions(List<ContextualSuggestion> suggestions) {
    final nudges = <StarboundNudge>[];
    
    for (final suggestion in suggestions.take(3)) { // Limit to top 3 suggestions
      final nudge = StarboundNudge(
        id: 'contextual_${suggestion.id}',
        theme: _getThemeFromCategory(suggestion.category),
        message: suggestion.actionText,
        title: suggestion.title,
        content: suggestion.description,
        tone: suggestion.relevanceScore >= 0.8 ? 'encouraging' : 'gentle',
        estimatedTime: suggestion.category == 'immediate' ? '<1 min' : '2-5 mins',
        energyRequired: suggestion.relevanceScore >= 0.7 ? 'low' : 'very low',
        source: NudgeSource.dynamic,
        type: NudgeType.suggestion,
        actionableSteps: [suggestion.actionText],
        metadata: {
          'contextual_suggestion': true,
          'relevance_score': suggestion.relevanceScore,
          'trigger_tags': suggestion.triggerTagKeys,
          'category': suggestion.category,
          'generated_at': DateTime.now().toIso8601String(),
        },
      );
      nudges.add(nudge);
    }
    
    return nudges;
  }

  /// Get appropriate theme from suggestion category
  String _getThemeFromCategory(String category) {
    switch (category) {
      case 'immediate':
        return 'focus';
      case 'daily':
        return 'wellness';
      case 'weekly':
        return 'planning';
      default:
        return 'support';
    }
  }

  /// Generate a specific nudge for a smart tag
  Future<StarboundNudge?> _generateNudgeForTag(SmartTag tag) async {
    // Template-based nudge generation
    final templates = _getNudgeTemplates();
    final template = templates[tag.canonicalKey];
    
    if (template == null) return null;
    
    // Customize based on sentiment and context
    String message = template['message'] as String;
    String theme = template['theme'] as String;
    
    // Apply sentiment customisation
    if (tag.isNegative) {
      message = template['supportive_message'] as String? ?? message;
    } else if (tag.isPositive) {
      message = template['encouraging_message'] as String? ?? message;
    }
    
    return StarboundNudge(
      id: 'dynamic_${tag.canonicalKey}_${DateTime.now().millisecondsSinceEpoch}',
      message: message,
      theme: theme,
      estimatedTime: template['estimatedTime'] as String? ?? '1-2 mins',
      energyRequired: template['energyRequired'] as String? ?? 'low',
      tone: tag.isNegative ? 'supportive' : 'encouraging',
      source: NudgeSource.dynamic,
      metadata: {
        'ai_generated': true,
        'trigger_tag': tag.canonicalKey,
        'confidence': tag.confidence,
        'generated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get nudge templates for dynamic generation
  Map<String, Map<String, String>> _getNudgeTemplates() {
    return {
      'daily_movement': {
        'message': 'Your body is ready for some gentle movement. How about a short walk?',
        'supportive_message': 'Even a few minutes of gentle movement can help. Try stretching where you are.',
        'encouraging_message': 'You\'re doing great with movement! Ready to keep the momentum going?',
        'theme': 'movement',
        'estimatedTime': '5-10 mins',
        'energyRequired': 'medium',
      },
      'drinking_water': {
        'message': 'Time for a refreshing glass of water to keep you hydrated.',
        'supportive_message': 'Small sips count too. Your body will appreciate any hydration.',
        'encouraging_message': 'Brilliant hydration habits! Keep nourishing your body.',
        'theme': 'hydration',
        'estimatedTime': '<1 min',
        'energyRequired': 'very low',
      },
      'anxiety': {
        'message': 'Take three deep breaths. Let each exhale release some tension.',
        'supportive_message': 'This feeling will pass. Focus on one breath at a time.',
        'encouraging_message': 'You\'re handling this well. Trust in your strength.',
        'theme': 'calm',
        'estimatedTime': '1-2 mins',
        'energyRequired': 'very low',
      },
    };
  }

  /// Clear recommendation cache
  void clearCache() {
    _recommendationCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _recommendationCache.length,
      'maxCacheSize': _maxCacheSize,
    };
  }
}