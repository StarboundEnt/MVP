import '../models/complexity_profile.dart';
import '../models/habit_model.dart';

/// Complexity indicator with weight and level mapping
class ComplexityIndicator {
  final String tag;
  final Map<ComplexityLevel, double> levelWeights;
  final double baseWeight;
  final String domain; // chance, choice, outcome
  
  const ComplexityIndicator({
    required this.tag,
    required this.levelWeights,
    this.baseWeight = 1.0,
    required this.domain,
  });
}

/// Analysis result for a specific time period
class ComplexityAnalysis {
  final Map<ComplexityLevel, double> scores;
  final ComplexityLevel suggestedLevel;
  final double confidence;
  final Map<String, int> tagFrequency;
  final Map<String, double> sentimentBreakdown;
  final List<String> criticalIndicators;
  final List<String> positiveIndicators;
  final DateTime analyzedPeriod;
  final int totalReflections;
  
  ComplexityAnalysis({
    required this.scores,
    required this.suggestedLevel,
    required this.confidence,
    required this.tagFrequency,
    required this.sentimentBreakdown,
    required this.criticalIndicators,
    required this.positiveIndicators,
    required this.analyzedPeriod,
    required this.totalReflections,
  });
  
  /// Check if analysis suggests profile needs updating
  bool shouldSuggestReassessment(ComplexityLevel currentLevel) {
    final suggestedScore = scores[suggestedLevel] ?? 0.0;
    final currentScore = scores[currentLevel] ?? 0.0;
    
    // Suggest reassessment if there's a significant difference and high confidence
    return (suggestedScore - currentScore).abs() > 2.0 && confidence > 0.7;
  }
  
  /// Get summary of complexity trends
  String getTrendSummary(ComplexityLevel currentLevel) {
    if (suggestedLevel == currentLevel) {
      return "Your reflections align with your current profile";
    }
    
    final direction = _getComplexityLevelIndex(suggestedLevel) > _getComplexityLevelIndex(currentLevel) 
        ? "higher" : "lower";
    
    return "Your reflections suggest ${direction} complexity than your current profile";
  }
  
  int _getComplexityLevelIndex(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable: return 0;
      case ComplexityLevel.trying: return 1;
      case ComplexityLevel.overloaded: return 2;
      case ComplexityLevel.survival: return 3;
    }
  }
}

/// Service for analyzing complexity patterns from social determinants tags
class ComplexityAnalysisService {
  static final ComplexityAnalysisService _instance = ComplexityAnalysisService._internal();
  factory ComplexityAnalysisService() => _instance;
  ComplexityAnalysisService._internal();
  
  /// Social determinants tags mapped to complexity indicators
  static const Map<String, ComplexityIndicator> _complexityIndicators = {
    // 🚨 SURVIVAL LEVEL INDICATORS
    
    // Economic Stability - Crisis Level
    'financial_crisis': ComplexityIndicator(
      tag: 'financial_crisis',
      domain: 'chance',
      levelWeights: {
        ComplexityLevel.survival: 3.0,
        ComplexityLevel.overloaded: 1.0,
        ComplexityLevel.trying: 0.0,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'housing_instability': ComplexityIndicator(
      tag: 'housing_instability',
      domain: 'chance',
      levelWeights: {
        ComplexityLevel.survival: 3.0,
        ComplexityLevel.overloaded: 1.5,
        ComplexityLevel.trying: 0.0,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'food_insecurity': ComplexityIndicator(
      tag: 'food_insecurity',
      domain: 'chance',
      levelWeights: {
        ComplexityLevel.survival: 2.5,
        ComplexityLevel.overloaded: 1.0,
        ComplexityLevel.trying: 0.0,
        ComplexityLevel.stable: 0.0,
      },
    ),
    
    // Mental Health - Crisis Outcomes
    'emotional_exhaustion': ComplexityIndicator(
      tag: 'emotional_exhaustion',
      domain: 'outcome',
      levelWeights: {
        ComplexityLevel.survival: 2.0,
        ComplexityLevel.overloaded: 2.5,
        ComplexityLevel.trying: 0.5,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'depression': ComplexityIndicator(
      tag: 'depression',
      domain: 'outcome',
      levelWeights: {
        ComplexityLevel.survival: 2.0,
        ComplexityLevel.overloaded: 1.5,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'panic_attacks': ComplexityIndicator(
      tag: 'panic_attacks',
      domain: 'choice', // Often triggered by circumstances but manifests as experience
      levelWeights: {
        ComplexityLevel.survival: 2.0,
        ComplexityLevel.overloaded: 1.5,
        ComplexityLevel.trying: 0.5,
        ComplexityLevel.stable: 0.0,
      },
    ),
    
    // ⚡ OVERLOADED LEVEL INDICATORS
    
    // Economic & Social Stress
    'job_loss': ComplexityIndicator(
      tag: 'job_loss',
      domain: 'chance',
      levelWeights: {
        ComplexityLevel.survival: 1.0,
        ComplexityLevel.overloaded: 2.5,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'financial_stress': ComplexityIndicator(
      tag: 'financial_stress',
      domain: 'chance',
      levelWeights: {
        ComplexityLevel.survival: 0.5,
        ComplexityLevel.overloaded: 2.0,
        ComplexityLevel.trying: 1.5,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'isolation_loneliness': ComplexityIndicator(
      tag: 'isolation_loneliness',
      domain: 'chance',
      levelWeights: {
        ComplexityLevel.survival: 1.0,
        ComplexityLevel.overloaded: 2.0,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'discrimination': ComplexityIndicator(
      tag: 'discrimination',
      domain: 'chance',
      levelWeights: {
        ComplexityLevel.survival: 1.5,
        ComplexityLevel.overloaded: 2.0,
        ComplexityLevel.trying: 0.5,
        ComplexityLevel.stable: 0.0,
      },
    ),
    
    // Health & Wellbeing Strain
    'anxiety': ComplexityIndicator(
      tag: 'anxiety',
      domain: 'outcome',
      levelWeights: {
        ComplexityLevel.survival: 1.0,
        ComplexityLevel.overloaded: 2.0,
        ComplexityLevel.trying: 1.5,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'fatigue': ComplexityIndicator(
      tag: 'fatigue',
      domain: 'outcome',
      levelWeights: {
        ComplexityLevel.survival: 0.5,
        ComplexityLevel.overloaded: 1.5,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'poor_sleep': ComplexityIndicator(
      tag: 'poor_sleep',
      domain: 'choice',
      levelWeights: {
        ComplexityLevel.survival: 1.0,
        ComplexityLevel.overloaded: 1.5,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'skipping_meals': ComplexityIndicator(
      tag: 'skipping_meals',
      domain: 'choice',
      levelWeights: {
        ComplexityLevel.survival: 1.5,
        ComplexityLevel.overloaded: 1.5,
        ComplexityLevel.trying: 0.5,
        ComplexityLevel.stable: 0.0,
      },
    ),
    
    // 🌊 TRYING LEVEL INDICATORS
    
    // Mixed Patterns & Effort
    'mood_swings': ComplexityIndicator(
      tag: 'mood_swings',
      domain: 'outcome',
      levelWeights: {
        ComplexityLevel.survival: 0.5,
        ComplexityLevel.overloaded: 1.0,
        ComplexityLevel.trying: 2.0,
        ComplexityLevel.stable: 0.0,
      },
    ),
    'stress_level': ComplexityIndicator(
      tag: 'stress_level',
      domain: 'outcome',
      levelWeights: {
        ComplexityLevel.survival: 0.5,
        ComplexityLevel.overloaded: 1.0,
        ComplexityLevel.trying: 1.5,
        ComplexityLevel.stable: 0.5,
      },
    ),
    'therapy': ComplexityIndicator(
      tag: 'therapy',
      domain: 'choice',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.5,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 0.5,
      },
    ),
    
    // ✨ STABLE LEVEL INDICATORS
    
    // Positive Choices & Outcomes
    'daily_movement': ComplexityIndicator(
      tag: 'daily_movement',
      domain: 'choice',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.0,
        ComplexityLevel.trying: 0.5,
        ComplexityLevel.stable: 2.0,
      },
    ),
    'balanced_meal': ComplexityIndicator(
      tag: 'balanced_meal',
      domain: 'choice',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.0,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 1.5,
      },
    ),
    'quality_sleep': ComplexityIndicator(
      tag: 'quality_sleep',
      domain: 'choice',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.0,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 2.0,
      },
    ),
    'social_support': ComplexityIndicator(
      tag: 'social_support',
      domain: 'chance',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.5,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 2.0,
      },
    ),
    'time_with_others': ComplexityIndicator(
      tag: 'time_with_others',
      domain: 'choice',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.0,
        ComplexityLevel.trying: 0.5,
        ComplexityLevel.stable: 1.5,
      },
    ),
    'calm_mood': ComplexityIndicator(
      tag: 'calm_mood',
      domain: 'outcome',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.0,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 2.0,
      },
    ),
    'happy_mood': ComplexityIndicator(
      tag: 'happy_mood',
      domain: 'outcome',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.0,
        ComplexityLevel.trying: 0.5,
        ComplexityLevel.stable: 2.0,
      },
    ),
    'feeling_well': ComplexityIndicator(
      tag: 'feeling_well',
      domain: 'outcome',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.0,
        ComplexityLevel.trying: 0.5,
        ComplexityLevel.stable: 1.5,
      },
    ),
    'housing_stability': ComplexityIndicator(
      tag: 'housing_stability',
      domain: 'chance',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.0,
        ComplexityLevel.trying: 0.5,
        ComplexityLevel.stable: 2.0,
      },
    ),
    'stable_income': ComplexityIndicator(
      tag: 'stable_income',
      domain: 'chance',
      levelWeights: {
        ComplexityLevel.survival: 0.0,
        ComplexityLevel.overloaded: 0.0,
        ComplexityLevel.trying: 1.0,
        ComplexityLevel.stable: 2.0,
      },
    ),
  };
  
  /// Analyze complexity from recent reflection entries
  Future<ComplexityAnalysis> analyzeComplexity(List<FreeFormEntry> entries, {
    Duration? period,
  }) async {
    period ??= const Duration(days: 7); // Default to last week
    
    final cutoffDate = DateTime.now().subtract(period);
    final relevantEntries = entries
        .where((entry) => entry.timestamp.isAfter(cutoffDate))
        .toList();
    
    if (relevantEntries.isEmpty) {
      return _createEmptyAnalysis(cutoffDate);
    }
    
    // Initialize complexity scores
    final complexityScores = <ComplexityLevel, double>{
      ComplexityLevel.stable: 0.0,
      ComplexityLevel.trying: 0.0,
      ComplexityLevel.overloaded: 0.0,
      ComplexityLevel.survival: 0.0,
    };
    
    // Track tag frequency and sentiment
    final tagFrequency = <String, int>{};
    final sentimentBreakdown = <String, double>{
      'positive': 0.0,
      'negative': 0.0,
      'neutral': 0.0,
    };
    final criticalIndicators = <String>[];
    final positiveIndicators = <String>[];
    
    int totalClassifications = 0;
    
    // Analyze each reflection entry
    for (final entry in relevantEntries) {
      for (final classification in entry.classifications) {
        totalClassifications++;
        
        // Track sentiment breakdown
        sentimentBreakdown[classification.sentiment] = 
            (sentimentBreakdown[classification.sentiment] ?? 0.0) + 1.0;
        
        // Analyze each theme/tag
        for (final theme in classification.themes) {
          tagFrequency[theme] = (tagFrequency[theme] ?? 0) + 1;
          
          final indicator = _complexityIndicators[theme];
          if (indicator != null) {
            // Apply sentiment weight modifier
            final sentimentWeight = _getSentimentWeight(classification.sentiment);
            final confidenceWeight = classification.confidence;
            
            // Calculate weighted contribution to each complexity level
            indicator.levelWeights.forEach((level, weight) {
              complexityScores[level] = (complexityScores[level] ?? 0.0) + 
                  (weight * indicator.baseWeight * sentimentWeight * confidenceWeight);
            });
            
            // Track critical and positive indicators
            if (indicator.levelWeights[ComplexityLevel.survival]! > 1.5 ||
                indicator.levelWeights[ComplexityLevel.overloaded]! > 1.5) {
              if (!criticalIndicators.contains(theme)) {
                criticalIndicators.add(theme);
              }
            }
            
            if (indicator.levelWeights[ComplexityLevel.stable]! > 1.0) {
              if (!positiveIndicators.contains(theme)) {
                positiveIndicators.add(theme);
              }
            }
          }
        }
      }
    }
    
    // Normalize sentiment breakdown
    if (totalClassifications > 0) {
      sentimentBreakdown.updateAll((key, value) => value / totalClassifications);
    }
    
    // Determine suggested complexity level
    final sortedScores = complexityScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final suggestedLevel = sortedScores.first.key;
    final maxScore = sortedScores.first.value;
    final secondScore = sortedScores.length > 1 ? sortedScores[1].value : 0.0;
    
    // Calculate confidence based on score difference and data volume
    final scoreDifference = maxScore - secondScore;
    final dataVolume = relevantEntries.length / 7.0; // Normalize to daily entries
    final confidence = (scoreDifference / (maxScore + 1.0) * dataVolume).clamp(0.0, 1.0);
    
    return ComplexityAnalysis(
      scores: complexityScores,
      suggestedLevel: suggestedLevel,
      confidence: confidence,
      tagFrequency: tagFrequency,
      sentimentBreakdown: sentimentBreakdown,
      criticalIndicators: criticalIndicators,
      positiveIndicators: positiveIndicators,
      analyzedPeriod: cutoffDate,
      totalReflections: relevantEntries.length,
    );
  }
  
  /// Get sentiment weight modifier for complexity scoring
  double _getSentimentWeight(String sentiment) {
    switch (sentiment) {
      case 'positive': return 0.7; // Positive sentiment reduces complexity weight
      case 'negative': return 1.3; // Negative sentiment increases complexity weight
      case 'neutral': return 1.0;
      default: return 1.0;
    }
  }
  
  /// Create empty analysis for when no data is available
  ComplexityAnalysis _createEmptyAnalysis(DateTime cutoffDate) {
    return ComplexityAnalysis(
      scores: {
        ComplexityLevel.stable: 0.0,
        ComplexityLevel.trying: 0.0,
        ComplexityLevel.overloaded: 0.0,
        ComplexityLevel.survival: 0.0,
      },
      suggestedLevel: ComplexityLevel.trying, // Default neutral suggestion
      confidence: 0.0,
      tagFrequency: {},
      sentimentBreakdown: {},
      criticalIndicators: [],
      positiveIndicators: [],
      analyzedPeriod: cutoffDate,
      totalReflections: 0,
    );
  }
  
  /// Get critical indicators that suggest immediate intervention
  List<String> getCriticalIndicators(List<FreeFormEntry> recentEntries) {
    final criticalTags = <String>[];
    
    for (final entry in recentEntries) {
      for (final classification in entry.classifications) {
        for (final theme in classification.themes) {
          final indicator = _complexityIndicators[theme];
          if (indicator != null && 
              indicator.levelWeights[ComplexityLevel.survival]! >= 2.0 &&
              classification.sentiment == 'negative') {
            criticalTags.add(theme);
          }
        }
      }
    }
    
    return criticalTags.toSet().toList();
  }
  
  /// Generate insights about complexity patterns
  List<String> generateInsights(ComplexityAnalysis analysis, ComplexityLevel currentLevel) {
    final insights = <String>[];
    
    // Profile alignment insight
    if (analysis.suggestedLevel == currentLevel) {
      insights.add("Your reflections align well with your current profile");
    } else {
      final direction = _getComplexityLevelIndex(analysis.suggestedLevel) > 
                      _getComplexityLevelIndex(currentLevel) ? "higher" : "lower";
      insights.add("Your reflections suggest ${direction} complexity than your current profile");
    }
    
    // Sentiment insight
    final negativeRatio = analysis.sentimentBreakdown['negative'] ?? 0.0;
    if (negativeRatio > 0.6) {
      insights.add("Most of your recent reflections have been challenging");
    } else if (negativeRatio < 0.3) {
      insights.add("Your recent reflections show mostly positive experiences");
    }
    
    // Critical indicators
    if (analysis.criticalIndicators.isNotEmpty) {
      final topCritical = analysis.criticalIndicators.take(2).join(" and ");
      insights.add("Key stress areas: ${topCritical.replaceAll('_', ' ')}");
    }
    
    // Positive patterns
    if (analysis.positiveIndicators.isNotEmpty) {
      final topPositive = analysis.positiveIndicators.take(2).join(" and ");
      insights.add("Strength areas: ${topPositive.replaceAll('_', ' ')}");
    }
    
    // Data sufficiency
    if (analysis.totalReflections < 3) {
      insights.add("Consider more frequent reflections for better analysis");
    }
    
    return insights;
  }
  
  int _getComplexityLevelIndex(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable: return 0;
      case ComplexityLevel.trying: return 1;
      case ComplexityLevel.overloaded: return 2;
      case ComplexityLevel.survival: return 3;
    }
  }
}