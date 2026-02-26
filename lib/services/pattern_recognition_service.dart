import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/complexity_profile.dart';
import '../models/habit_model.dart';
import 'storage_service.dart';

enum PatternType {
  successStreak,     // Consistent success patterns
  recoveryPattern,   // Bouncing back from setbacks
  weeklyRhythm,      // Weekly habit patterns
  timeOptimal,       // Best times for habits
  seasonalTrend,     // Seasonal variations
  correlationBoost,  // Habits that boost each other
}

class SuccessPattern {
  final String id;
  final PatternType type;
  final String title;
  final String description;
  final String insight;
  final double confidence; // 0.0 to 1.0
  final Map<String, dynamic> data;
  final DateTime discoveredAt;
  final List<String> relatedHabits;
  
  SuccessPattern({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.insight,
    required this.confidence,
    required this.data,
    required this.discoveredAt,
    this.relatedHabits = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'title': title,
    'description': description,
    'insight': insight,
    'confidence': confidence,
    'data': data,
    'discoveredAt': discoveredAt.toIso8601String(),
    'relatedHabits': relatedHabits,
  };
  
  factory SuccessPattern.fromJson(Map<String, dynamic> json) => SuccessPattern(
    id: json['id'],
    type: PatternType.values[json['type']],
    title: json['title'],
    description: json['description'],
    insight: json['insight'],
    confidence: json['confidence']?.toDouble() ?? 0.0,
    data: Map<String, dynamic>.from(json['data'] ?? {}),
    discoveredAt: DateTime.parse(json['discoveredAt']),
    relatedHabits: List<String>.from(json['relatedHabits'] ?? []),
  );
}

class PatternRecognitionService {
  static final PatternRecognitionService _instance = PatternRecognitionService._internal();
  factory PatternRecognitionService() => _instance;
  PatternRecognitionService._internal();
  
  final StorageService _storageService = StorageService();
  final List<SuccessPattern> _discoveredPatterns = [];
  
  // Analyze user patterns for success insights with performance optimization
  Future<List<SuccessPattern>> analyzeSuccessPatterns({
    required Map<String, String?> currentHabits,
    required Map<String, int> habitStreaks,
    required ComplexityLevel complexityProfile,
    required List<dynamic> correlations,
    int analysisDepthDays = 30,
  }) async {
    try {
      // For small datasets, process directly for faster results
      if (currentHabits.length <= 3 || habitStreaks.length <= 3) {
        return await _analyzePatternsDirect(
          currentHabits, habitStreaks, complexityProfile, correlations, analysisDepthDays);
      }
      
      // For larger datasets, use background processing to avoid blocking UI
      final analysisData = {
        'currentHabits': Map<String, String>.from(currentHabits.map((k, v) => MapEntry(k, v ?? ''))),
        'habitStreaks': habitStreaks,
        'complexityProfile': complexityProfile.index,
        'correlations': correlations,
        'analysisDepthDays': analysisDepthDays,
        'minConfidence': _getMinConfidence(complexityProfile),
      };
      
      // Use compute for CPU-intensive pattern analysis
      final results = await compute(_analyzeSuccessPatternsIsolate, analysisData);
      
      // Convert back to SuccessPattern objects
      final patterns = results.map((data) => SuccessPattern.fromJson(data)).toList();
      
      // Update discovered patterns
      _updateDiscoveredPatterns(patterns);
      
      return patterns;
    } catch (e) {
      debugPrint('Error analyzing success patterns: $e, falling back to direct processing');
      // Fallback to direct processing on error
      return await _analyzePatternsDirect(
        currentHabits, habitStreaks, complexityProfile, correlations, analysisDepthDays);
    }
  }
  
  // Direct processing for small datasets or fallback
  Future<List<SuccessPattern>> _analyzePatternsDirect(
    Map<String, String?> currentHabits,
    Map<String, int> habitStreaks,
    ComplexityLevel complexityProfile,
    List<dynamic> correlations,
    int analysisDepthDays,
  ) async {
    final patterns = <SuccessPattern>[];
    
    // Analyze streak patterns
    patterns.addAll(await _analyzeStreakPatterns(habitStreaks, analysisDepthDays));
    
    // Analyze recovery patterns
    patterns.addAll(await _analyzeRecoveryPatterns(currentHabits, analysisDepthDays));
    
    // Analyze weekly rhythms
    patterns.addAll(await _analyzeWeeklyRhythms(currentHabits, analysisDepthDays));
    
    // Analyze time-based patterns
    patterns.addAll(await _analyzeTimePatterns(currentHabits, analysisDepthDays));
    
    // Analyze correlation-based success patterns
    patterns.addAll(await _analyzeCorrelationPatterns(correlations));
    
    // Filter by confidence and complexity appropriateness
    final filteredPatterns = patterns
        .where((p) => p.confidence >= _getMinConfidence(complexityProfile))
        .toList();
    
    // Sort by confidence (highest first)
    filteredPatterns.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return filteredPatterns.take(10).toList(); // Return top 10 patterns
  }
  
  // Analyze streak-based success patterns
  Future<List<SuccessPattern>> _analyzeStreakPatterns(
    Map<String, int> habitStreaks,
    int analysisDepthDays,
  ) async {
    final patterns = <SuccessPattern>[];
    
    // Find longest streaks
    final sortedStreaks = habitStreaks.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedStreaks.isNotEmpty && sortedStreaks.first.value >= 7) {
      final topHabit = sortedStreaks.first;
      final habitName = _formatHabitName(topHabit.key);
      
      patterns.add(SuccessPattern(
        id: 'streak_champion_${topHabit.key}',
        type: PatternType.successStreak,
        title: 'Streak Champion',
        description: 'Your $habitName habit shows exceptional consistency',
        insight: 'You\'ve maintained a ${topHabit.value}-day streak with $habitName. This habit is clearly well-integrated into your routine.',
        confidence: min(1.0, topHabit.value / 30.0), // Higher confidence for longer streaks
        data: {
          'habit': topHabit.key,
          'streak_length': topHabit.value,
          'habit_name': habitName,
        },
        discoveredAt: DateTime.now(),
        relatedHabits: [topHabit.key],
      ));
    }
    
    // Find multiple concurrent streaks (consistency pattern)
    final activeStreaks = habitStreaks.values.where((streak) => streak >= 3).length;
    if (activeStreaks >= 3) {
      patterns.add(SuccessPattern(
        id: 'multi_streak_master',
        type: PatternType.successStreak,
        title: 'Multi-Streak Master',
        description: 'You\'re maintaining $activeStreaks habits simultaneously',
        insight: 'Your ability to keep multiple habits going shows strong routine-building skills. This balanced approach is sustainable.',
        confidence: min(1.0, activeStreaks / 5.0),
        data: {
          'active_streaks': activeStreaks,
          'habits': habitStreaks.keys.where((key) => habitStreaks[key]! >= 3).toList(),
        },
        discoveredAt: DateTime.now(),
        relatedHabits: habitStreaks.keys.where((key) => habitStreaks[key]! >= 3).toList(),
      ));
    }
    
    return patterns;
  }
  
  // Analyze recovery patterns
  Future<List<SuccessPattern>> _analyzeRecoveryPatterns(
    Map<String, String?> currentHabits,
    int analysisDepthDays,
  ) async {
    final patterns = <SuccessPattern>[];
    
    // Analyze habit consistency over time to detect recovery patterns
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: analysisDepthDays));
    
    for (final habitKey in currentHabits.keys) {
      if (habitKey.isEmpty) continue;
      
      final habitData = <bool>[];
      var hasRecovery = false;
      var recoveryCount = 0;
      
      for (int i = 0; i < analysisDepthDays; i++) {
        final date = startDate.add(Duration(days: i));
        final entries = await _storageService.getHabitEntriesForDate(date);
        final value = entries[habitKey];
        final isCompleted = value != null && value.isNotEmpty && 
                           value != 'skipped' && value != 'poor';
        habitData.add(isCompleted);
      }
      
      // Detect recovery patterns (gap followed by resumption)
      for (int i = 1; i < habitData.length - 2; i++) {
        if (!habitData[i] && !habitData[i-1] && habitData[i+1] && habitData[i+2]) {
          hasRecovery = true;
          recoveryCount++;
        }
      }
      
      if (hasRecovery && recoveryCount >= 2) {
        final habitName = _formatHabitName(habitKey);
        patterns.add(SuccessPattern(
          id: 'recovery_master_$habitKey',
          type: PatternType.recoveryPattern,
          title: 'Resilient Recoverer',
          description: 'You consistently bounce back with $habitName',
          insight: 'You\'ve shown $recoveryCount recovery instances with $habitName. This resilience is a key success factor.',
          confidence: min(1.0, recoveryCount / 5.0),
          data: {
            'habit': habitKey,
            'recovery_count': recoveryCount,
            'habit_name': habitName,
          },
          discoveredAt: DateTime.now(),
          relatedHabits: [habitKey],
        ));
      }
    }
    
    return patterns;
  }
  
  // Analyze weekly rhythm patterns
  Future<List<SuccessPattern>> _analyzeWeeklyRhythms(
    Map<String, String?> currentHabits,
    int analysisDepthDays,
  ) async {
    final patterns = <SuccessPattern>[];
    
    // Analyze completion rates by day of week
    final weeklyData = <int, List<bool>>{
      for (int i = 1; i <= 7; i++) i: [],
    };
    
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: analysisDepthDays));
    
    for (int i = 0; i < analysisDepthDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dayOfWeek = date.weekday;
      final entries = await _storageService.getHabitEntriesForDate(date);
      
      final completionRate = entries.isNotEmpty 
          ? entries.values.where((v) => v != null && v.isNotEmpty && v != 'skipped' && v != 'poor').length / entries.length
          : 0.0;
      
      weeklyData[dayOfWeek]!.add(completionRate > 0.5);
    }
    
    // Find strongest day patterns
    final dayStrengths = <int, double>{};
    for (final entry in weeklyData.entries) {
      if (entry.value.isNotEmpty) {
        dayStrengths[entry.key] = entry.value.where((completed) => completed).length / entry.value.length;
      }
    }
    
    // Find strongest and weakest days
    if (dayStrengths.isNotEmpty) {
      final sortedDays = dayStrengths.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final strongestDay = sortedDays.first;
      final weakestDay = sortedDays.last;
      
      if (strongestDay.value >= 0.7) {
        patterns.add(SuccessPattern(
          id: 'weekly_champion',
          type: PatternType.weeklyRhythm,
          title: 'Weekly Champion',
          description: '${_getDayName(strongestDay.key)}s are your strongest day',
          insight: 'You complete ${(strongestDay.value * 100).round()}% of habits on ${_getDayName(strongestDay.key)}s. Consider using this energy for challenging new habits.',
          confidence: strongestDay.value,
          data: {
            'strongest_day': strongestDay.key,
            'completion_rate': strongestDay.value,
            'day_name': _getDayName(strongestDay.key),
          },
          discoveredAt: DateTime.now(),
        ));
      }
      
      if (strongestDay.value - weakestDay.value >= 0.3) {
        patterns.add(SuccessPattern(
          id: 'weekly_rhythm',
          type: PatternType.weeklyRhythm,
          title: 'Weekly Rhythm',
          description: 'You have a clear weekly pattern',
          insight: '${_getDayName(strongestDay.key)}s (${(strongestDay.value * 100).round()}%) vs ${_getDayName(weakestDay.key)}s (${(weakestDay.value * 100).round()}%). Plan accordingly!',
          confidence: strongestDay.value - weakestDay.value,
          data: {
            'strong_day': strongestDay.key,
            'weak_day': weakestDay.key,
            'difference': strongestDay.value - weakestDay.value,
          },
          discoveredAt: DateTime.now(),
        ));
      }
    }
    
    return patterns;
  }
  
  // Analyze time-based patterns
  Future<List<SuccessPattern>> _analyzeTimePatterns(
    Map<String, String?> currentHabits,
    int analysisDepthDays,
  ) async {
    final patterns = <SuccessPattern>[];
    
    // This would ideally analyze time-of-day completion patterns
    // For now, we'll create a simulated pattern based on habits
    if (currentHabits.containsKey('sleep') || currentHabits.containsKey('mood')) {
      patterns.add(SuccessPattern(
        id: 'evening_routine',
        type: PatternType.timeOptimal,
        title: 'Evening Routine Builder',
        description: 'Your evening habits support each other',
        insight: 'Evening reflection habits like sleep and mood tracking create positive momentum for the next day.',
        confidence: 0.8,
        data: {
          'time_period': 'evening',
          'supporting_habits': ['sleep', 'mood'],
        },
        discoveredAt: DateTime.now(),
        relatedHabits: ['sleep', 'mood'],
      ));
    }
    
    return patterns;
  }
  
  // Analyze correlation-based success patterns
  Future<List<SuccessPattern>> _analyzeCorrelationPatterns(List<dynamic> correlations) async {
    final patterns = <SuccessPattern>[];
    
    for (final correlation in correlations) {
      if (correlation is Map<String, dynamic>) {
        final strength = correlation['strength'] as double? ?? 0.0;
        final type = correlation['type'] as String? ?? '';
        final habit1 = correlation['habit1'] as String? ?? '';
        final habit2 = correlation['habit2'] as String? ?? '';
        
        if (strength >= 0.6 && type == 'positive') {
          patterns.add(SuccessPattern(
            id: 'synergy_${habit1}_$habit2',
            type: PatternType.correlationBoost,
            title: 'Synergy Success',
            description: '${_formatHabitName(habit1)} and ${_formatHabitName(habit2)} boost each other',
            insight: 'These habits have a ${(strength * 100).round()}% positive correlation. When you do one, you\'re much more likely to do the other.',
            confidence: strength,
            data: {
              'habit1': habit1,
              'habit2': habit2,
              'correlation_strength': strength,
            },
            discoveredAt: DateTime.now(),
            relatedHabits: [habit1, habit2],
          ));
        }
      }
    }
    
    return patterns;
  }
  
  // Get minimum confidence threshold based on complexity profile
  double _getMinConfidence(ComplexityLevel complexityProfile) {
    switch (complexityProfile) {
      case ComplexityLevel.stable:
        return 0.3; // Show more patterns
      case ComplexityLevel.trying:
        return 0.5; // Moderate confidence
      case ComplexityLevel.overloaded:
        return 0.7; // Only high confidence patterns
      case ComplexityLevel.survival:
        return 0.8; // Only very clear patterns
    }
  }
  
  // Update discovered patterns list
  void _updateDiscoveredPatterns(List<SuccessPattern> newPatterns) {
    for (final pattern in newPatterns) {
      final existingIndex = _discoveredPatterns.indexWhere((p) => p.id == pattern.id);
      
      if (existingIndex >= 0) {
        // Update existing pattern if confidence improved
        if (pattern.confidence > _discoveredPatterns[existingIndex].confidence) {
          _discoveredPatterns[existingIndex] = pattern;
        }
      } else {
        // Add new pattern
        _discoveredPatterns.add(pattern);
      }
    }
    
    // Keep only recent patterns
    _discoveredPatterns.removeWhere((p) => 
        DateTime.now().difference(p.discoveredAt).inDays > 30);
    
    // Limit total patterns
    if (_discoveredPatterns.length > 50) {
      _discoveredPatterns.sort((a, b) => b.confidence.compareTo(a.confidence));
      _discoveredPatterns.removeRange(50, _discoveredPatterns.length);
    }
  }
  
  // Helper methods
  String _formatHabitName(String habitKey) {
    return habitKey.replaceAll('_', ' ').toLowerCase();
  }
  
  String _getDayName(int dayOfWeek) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek - 1];
  }
  
  // Public getters
  List<SuccessPattern> get discoveredPatterns => List.from(_discoveredPatterns);
  
  List<SuccessPattern> getPatternsByType(PatternType type) {
    return _discoveredPatterns.where((p) => p.type == type).toList();
  }
  
  List<SuccessPattern> getPatternsForHabit(String habitKey) {
    return _discoveredPatterns.where((p) => p.relatedHabits.contains(habitKey)).toList();
  }
  
  // Get actionable insights based on patterns
  List<Map<String, dynamic>> generateActionableInsights(
    List<SuccessPattern> patterns,
    ComplexityLevel complexityProfile,
  ) {
    final insights = <Map<String, dynamic>>[];
    
    for (final pattern in patterns.take(5)) { // Top 5 patterns
      String actionableAdvice = '';
      bool isHighPriority = false;
      
      switch (pattern.type) {
        case PatternType.successStreak:
          actionableAdvice = 'Continue this momentum and consider adding a related habit';
          isHighPriority = true;
          break;
        case PatternType.recoveryPattern:
          actionableAdvice = 'Your resilience is a strength - don\'t fear setbacks';
          isHighPriority = false;
          break;
        case PatternType.weeklyRhythm:
          actionableAdvice = 'Use your strong days to tackle challenging goals';
          isHighPriority = true;
          break;
        case PatternType.timeOptimal:
          actionableAdvice = 'Optimize your schedule around this natural rhythm';
          isHighPriority = true;
          break;
        case PatternType.correlationBoost:
          actionableAdvice = 'Pair these habits intentionally in your routine';
          isHighPriority = true;
          break;
        case PatternType.seasonalTrend:
          actionableAdvice = 'Prepare for seasonal changes in motivation';
          isHighPriority = false;
          break;
      }
      
      // Filter advice by complexity appropriateness
      if (_isAdviceAppropriate(pattern, complexityProfile)) {
        insights.add({
          'pattern_id': pattern.id,
          'type': pattern.type.name,
          'title': pattern.title,
          'insight': pattern.insight,
          'advice': actionableAdvice,
          'confidence': pattern.confidence,
          'high_priority': isHighPriority,
          'related_habits': pattern.relatedHabits,
        });
      }
    }
    
    return insights;
  }
  
  bool _isAdviceAppropriate(SuccessPattern pattern, ComplexityLevel complexityProfile) {
    switch (complexityProfile) {
      case ComplexityLevel.stable:
        return true; // All advice appropriate
      case ComplexityLevel.trying:
        return pattern.confidence >= 0.5; // Medium+ confidence patterns
      case ComplexityLevel.overloaded:
        return pattern.confidence >= 0.7 && 
               (pattern.type == PatternType.successStreak || pattern.type == PatternType.recoveryPattern);
      case ComplexityLevel.survival:
        return pattern.confidence >= 0.8 && pattern.type == PatternType.successStreak;
    }
  }
  
  // Calculate success probability for a new habit
  Future<double> calculateHabitSuccessProbability({
    required String habitKey,
    required Map<String, String?> currentHabits,
    required ComplexityAssessment complexityProfile,
    required List<SuccessPattern> patterns,
    required List<dynamic> correlations,
    Map<String, dynamic>? environmentalFactors,
  }) async {
    try {
      double probability = 50.0; // Base probability
      
      // Factor 1: User's overall success rate
      final overallSuccessRate = await _calculateOverallSuccessRate(currentHabits);
      probability += (overallSuccessRate - 0.5) * 30; // -15 to +15 adjustment
      
      // Factor 2: Complexity profile impact
      probability += _getComplexityAdjustment(complexityProfile);
      
      // Factor 3: Habit difficulty and user capacity match
      probability += _getHabitDifficultyAdjustment(habitKey, complexityProfile);
      
      // Factor 4: Correlation with successful habits
      probability += _getCorrelationBonus(habitKey, currentHabits, correlations);
      
      // Factor 5: Pattern-based success indicators
      probability += _getPatternBasedAdjustment(habitKey, patterns);
      
      // Factor 6: Seasonal and environmental factors
      if (environmentalFactors != null) {
        probability += _getEnvironmentalAdjustment(habitKey, environmentalFactors);
      }
      
      // Factor 7: Historical success with similar habits
      probability += await _getSimilarHabitSuccessBonus(habitKey, currentHabits);
      
      return probability.clamp(5.0, 95.0); // Keep within realistic bounds
    } catch (e) {
      debugPrint('Error calculating success probability: $e');
      return 50.0; // Default neutral probability
    }
  }
  
  // Calculate user's overall success rate with current habits
  Future<double> _calculateOverallSuccessRate(Map<String, String?> currentHabits) async {
    if (currentHabits.isEmpty) return 0.5;
    
    final successfulHabits = currentHabits.values
        .where((status) => status == 'good' || status == 'excellent')
        .length;
    
    return successfulHabits / currentHabits.length;
  }
  
  // Adjust probability based on complexity profile
  double _getComplexityAdjustment(ComplexityAssessment assessment) {
    switch (assessment.primaryLevel) {
      case ComplexityLevel.stable:
        return 15.0; // Higher capacity for new habits
      case ComplexityLevel.trying:
        return 5.0; // Some capacity
      case ComplexityLevel.overloaded:
        return -10.0; // Limited capacity
      case ComplexityLevel.survival:
        return -20.0; // Very limited capacity
    }
  }
  
  // Adjust based on habit difficulty vs user capacity
  double _getHabitDifficultyAdjustment(String habitKey, ComplexityAssessment assessment) {
    final category = StarboundHabits.all[habitKey];
    if (category == null) return 0.0;
    
    final difficulty = 'medium'; // Default difficulty since not available in HabitCategory
    final userCapacity = assessment.primaryLevel;
    
    // Simple habits are easier for stressed users
    if (difficulty == 'low') {
      switch (userCapacity) {
        case ComplexityLevel.survival:
        case ComplexityLevel.overloaded:
          return 10.0; // Simple habits work well for stressed users
        default:
          return 5.0;
      }
    }
    
    // Complex habits need stable users
    if (difficulty == 'high') {
      switch (userCapacity) {
        case ComplexityLevel.stable:
          return 5.0; // Stable users can handle complexity
        case ComplexityLevel.trying:
          return -5.0;
        default:
          return -15.0; // Too difficult for stressed users
      }
    }
    
    return 0.0; // Medium difficulty habits are neutral
  }
  
  // Bonus for habits that correlate with user's successful habits
  double _getCorrelationBonus(String habitKey, Map<String, String?> currentHabits, List<dynamic> correlations) {
    double bonus = 0.0;
    
    final successfulHabits = currentHabits.entries
        .where((entry) => entry.value == 'good' || entry.value == 'excellent')
        .map((entry) => entry.key)
        .toList();
    
    for (final correlation in correlations) {
      if (correlation is Map<String, dynamic>) {
        final habit1 = correlation['habit1'] as String?;
        final habit2 = correlation['habit2'] as String?;
        final strength = (correlation['strength'] as num?)?.toDouble() ?? 0.0;
        final type = correlation['type'] as String?;
        
        if (type == 'positive' && strength > 0.6) {
          if (habit1 == habitKey && successfulHabits.contains(habit2) ||
              habit2 == habitKey && successfulHabits.contains(habit1)) {
            bonus += strength * 10; // Up to 10 point bonus for strong correlations
          }
        }
      }
    }
    
    return bonus.clamp(0.0, 15.0);
  }
  
  // Adjustment based on success patterns
  double _getPatternBasedAdjustment(String habitKey, List<SuccessPattern> patterns) {
    double adjustment = 0.0;
    
    for (final pattern in patterns) {
      if (pattern.relatedHabits.contains(habitKey) || 
          pattern.description.toLowerCase().contains(habitKey.toLowerCase())) {
        
        switch (pattern.type) {
          case PatternType.successStreak:
            adjustment += pattern.confidence * 8; // Success streaks boost confidence
            break;
          case PatternType.recoveryPattern:
            adjustment += pattern.confidence * 5; // Recovery patterns show resilience
            break;
          case PatternType.timeOptimal:
            adjustment += pattern.confidence * 6; // Timing patterns help
            break;
          case PatternType.correlationBoost:
            adjustment += pattern.confidence * 7; // Correlation patterns are predictive
            break;
          default:
            adjustment += pattern.confidence * 3;
        }
      }
    }
    
    return adjustment.clamp(0.0, 12.0);
  }
  
  // Environmental and seasonal adjustments
  double _getEnvironmentalAdjustment(String habitKey, Map<String, dynamic> factors) {
    double adjustment = 0.0;
    
    final month = DateTime.now().month;
    
    // Seasonal adjustments
    if (habitKey.contains('outdoor') || habitKey.contains('exercise')) {
      if (month >= 3 && month <= 10) { // Spring to fall
        adjustment += 5.0;
      } else { // Winter
        adjustment -= 3.0;
      }
    }
    
    if (habitKey.contains('hydration') && month >= 6 && month <= 8) { // Summer
      adjustment += 8.0;
    }
    
    if (habitKey.contains('vitamin') && (month <= 2 || month >= 11)) { // Winter
      adjustment += 6.0;
    }
    
    // Social support factor
    final socialSupport = factors['social_support'] as String?;
    if (socialSupport == 'strong') {
      adjustment += 5.0;
    } else if (socialSupport == 'limited') {
      adjustment -= 3.0;
    }
    
    // Time availability factor
    final timeCapacity = factors['time_capacity'] as String?;
    if (timeCapacity == 'plenty') {
      adjustment += 7.0;
    } else if (timeCapacity == 'very_little' || timeCapacity == 'none') {
      adjustment -= 8.0;
    }
    
    return adjustment.clamp(-10.0, 10.0);
  }
  
  // Bonus based on success with similar habit categories
  Future<double> _getSimilarHabitSuccessBonus(String habitKey, Map<String, String?> currentHabits) async {
    final targetCategory = StarboundHabits.all[habitKey];
    if (targetCategory == null) return 0.0;
    
    double bonus = 0.0;
    int similarHabits = 0;
    int successfulSimilar = 0;
    
    for (final entry in currentHabits.entries) {
      final category = StarboundHabits.all[entry.key];
      if (category != null && category.type == targetCategory.type) {
        similarHabits++;
        if (entry.value == 'good' || entry.value == 'excellent') {
          successfulSimilar++;
        }
      }
    }
    
    if (similarHabits > 0) {
      final similarSuccessRate = successfulSimilar / similarHabits;
      bonus = (similarSuccessRate - 0.5) * 15; // -7.5 to +7.5 adjustment
    }
    
    return bonus.clamp(-8.0, 8.0);
  }
  
  // Generate confidence intervals for success probability
  Map<String, double> generateProbabilityConfidenceInterval(double probability) {
    final margin = 15.0; // ±15% margin of error
    return {
      'probability': probability,
      'lower_bound': (probability - margin).clamp(0.0, 100.0),
      'upper_bound': (probability + margin).clamp(0.0, 100.0),
      'confidence_level': 0.8, // 80% confidence interval
    };
  }
  
  // Provide success probability explanation
  String explainSuccessProbability(double probability, String habitKey, ComplexityAssessment assessment) {
    if (probability >= 80) {
      return "High likelihood of success! Your patterns and capacity align well with this habit.";
    } else if (probability >= 65) {
      return "Good chance of success. Consider starting with smaller steps to build momentum.";
    } else if (probability >= 50) {
      return "Moderate likelihood. This might be challenging but achievable with the right approach.";
    } else if (probability >= 35) {
      return "Lower probability of success. Consider building foundational habits first.";
    } else {
      return "This habit might be too challenging right now. Focus on simpler habits to build capacity.";
    }
  }
}

// Isolate function for background pattern analysis
List<Map<String, dynamic>> _analyzeSuccessPatternsIsolate(Map<String, dynamic> data) {
  try {
    final currentHabits = Map<String, String>.from(data['currentHabits'] as Map);
    final habitStreaks = Map<String, int>.from(data['habitStreaks'] as Map);
    final complexityProfileIndex = data['complexityProfile'] as int;
    final complexityProfile = ComplexityLevel.values[complexityProfileIndex];
    final correlations = data['correlations'] as List<dynamic>;
    final analysisDepthDays = data['analysisDepthDays'] as int;
    final minConfidence = data['minConfidence'] as double;
    
    final patterns = <SuccessPattern>[];
    
    // Simplified pattern analysis for isolate (no async operations)
    // Focus on computational patterns that don't require storage access
    
    // 1. Analyze streak patterns
    for (final entry in habitStreaks.entries) {
      if (entry.value >= 3) {
        patterns.add(SuccessPattern(
          id: 'streak_${entry.key}_${DateTime.now().millisecondsSinceEpoch}',
          type: PatternType.successStreak,
          title: 'Strong ${entry.key.replaceAll('_', ' ')} streak',
          description: 'You\'ve maintained ${entry.key.replaceAll('_', ' ')} for ${entry.value} days',
          insight: 'This consistency shows your capability to maintain habits',
          confidence: (entry.value / 30.0).clamp(0.3, 0.9),
          data: {'streak_length': entry.value, 'habit': entry.key},
          discoveredAt: DateTime.now(),
          relatedHabits: [entry.key],
        ));
      }
    }
    
    // 2. Analyze correlation patterns (simplified)
    for (final correlation in correlations.take(5)) {
      if (correlation is Map<String, dynamic>) {
        final strength = (correlation['strength'] as num?)?.toDouble() ?? 0.0;
        if (strength > 0.6) {
          final habit1 = correlation['habit1'] as String? ?? '';
          final habit2 = correlation['habit2'] as String? ?? '';
          
          patterns.add(SuccessPattern(
            id: 'correlation_${habit1}_${habit2}_${DateTime.now().millisecondsSinceEpoch}',
            type: PatternType.correlationBoost,
            title: 'Strong habit pairing',
            description: '${habit1.replaceAll('_', ' ')} and ${habit2.replaceAll('_', ' ')} work well together',
            insight: 'These habits complement each other in your routine',
            confidence: strength,
            data: {'correlation_strength': strength, 'habits': [habit1, habit2]},
            discoveredAt: DateTime.now(),
            relatedHabits: [habit1, habit2],
          ));
        }
      }
    }
    
    // 3. Weekly rhythm analysis (simplified)
    final weeklyHabits = currentHabits.entries.where((e) => e.value == 'good' || e.value == 'excellent').toList();
    if (weeklyHabits.length >= 2) {
      patterns.add(SuccessPattern(
        id: 'weekly_rhythm_${DateTime.now().millisecondsSinceEpoch}',
        type: PatternType.weeklyRhythm,
        title: 'Consistent weekly routine',
        description: 'You maintain ${weeklyHabits.length} habits well consistently',
        insight: 'Your routine is becoming automatic',
        confidence: (weeklyHabits.length / 5.0).clamp(0.4, 0.8),
        data: {'successful_habits_count': weeklyHabits.length},
        discoveredAt: DateTime.now(),
        relatedHabits: weeklyHabits.map((e) => e.key).toList(),
      ));
    }
    
    // Filter by confidence and sort
    final filteredPatterns = patterns
        .where((p) => p.confidence >= minConfidence)
        .toList();
    
    filteredPatterns.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // Convert to JSON for return
    return filteredPatterns.take(10).map((p) => p.toJson()).toList();
  } catch (e) {
    // Return empty list on error in isolate
    return [];
  }
}