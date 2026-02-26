import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/complexity_profile.dart';
import 'storage_service.dart';

enum CorrelationType {
  positive,  // Habits that tend to happen together
  negative,  // Habits that tend to be exclusive
  temporal,  // Habits that follow each other in time
  causal,    // One habit seems to lead to another
}

class HabitCorrelation {
  final String habit1;
  final String habit2;
  final CorrelationType type;
  final double strength; // 0.0 to 1.0
  final int sampleSize;
  final String description;
  final String insight;
  final DateTime discoveredAt;
  
  HabitCorrelation({
    required this.habit1,
    required this.habit2,
    required this.type,
    required this.strength,
    required this.sampleSize,
    required this.description,
    required this.insight,
    required this.discoveredAt,
  });
  
  Map<String, dynamic> toJson() => {
    'habit1': habit1,
    'habit2': habit2,
    'type': type.index,
    'strength': strength,
    'sampleSize': sampleSize,
    'description': description,
    'insight': insight,
    'discoveredAt': discoveredAt.toIso8601String(),
  };
  
  factory HabitCorrelation.fromJson(Map<String, dynamic> json) => HabitCorrelation(
    habit1: json['habit1'],
    habit2: json['habit2'],
    type: CorrelationType.values[json['type']],
    strength: json['strength']?.toDouble() ?? 0.0,
    sampleSize: json['sampleSize'] ?? 0,
    description: json['description'] ?? '',
    insight: json['insight'] ?? '',
    discoveredAt: DateTime.parse(json['discoveredAt']),
  );
}

class HabitPair {
  final String habit1;
  final String habit2;
  final List<bool> habit1Values;
  final List<bool> habit2Values;
  final List<DateTime> dates;
  
  HabitPair({
    required this.habit1,
    required this.habit2,
    required this.habit1Values,
    required this.habit2Values,
    required this.dates,
  });
  
  int get sampleSize => habit1Values.length;
  
  // Calculate correlation coefficient (-1 to 1)
  double get correlationCoefficient {
    if (sampleSize < 2) return 0.0;
    
    final mean1 = habit1Values.where((v) => v).length / sampleSize;
    final mean2 = habit2Values.where((v) => v).length / sampleSize;
    
    double numerator = 0.0;
    double sumSq1 = 0.0;
    double sumSq2 = 0.0;
    
    for (int i = 0; i < sampleSize; i++) {
      final val1 = habit1Values[i] ? 1.0 : 0.0;
      final val2 = habit2Values[i] ? 1.0 : 0.0;
      
      final diff1 = val1 - mean1;
      final diff2 = val2 - mean2;
      
      numerator += diff1 * diff2;
      sumSq1 += diff1 * diff1;
      sumSq2 += diff2 * diff2;
    }
    
    final denominator = sqrt(sumSq1 * sumSq2);
    return denominator > 0 ? numerator / denominator : 0.0;
  }
  
  // Calculate temporal correlation (how often habit2 follows habit1)
  double get temporalCorrelation {
    if (sampleSize < 2) return 0.0;
    
    int followCount = 0;
    int habit1Count = 0;
    
    for (int i = 0; i < sampleSize - 1; i++) {
      if (habit1Values[i]) {
        habit1Count++;
        if (habit2Values[i + 1]) {
          followCount++;
        }
      }
    }
    
    return habit1Count > 0 ? followCount / habit1Count : 0.0;
  }
  
  // Calculate same-day correlation
  double get sameDayCorrelation {
    if (sampleSize < 1) return 0.0;
    
    int bothCount = 0;
    int eitherCount = 0;
    
    for (int i = 0; i < sampleSize; i++) {
      if (habit1Values[i] || habit2Values[i]) {
        eitherCount++;
        if (habit1Values[i] && habit2Values[i]) {
          bothCount++;
        }
      }
    }
    
    return eitherCount > 0 ? bothCount / eitherCount : 0.0;
  }
}

class CorrelationService {
  static final CorrelationService _instance = CorrelationService._internal();
  factory CorrelationService() => _instance;
  CorrelationService._internal();
  
  final StorageService _storageService = StorageService();
  List<HabitCorrelation> _discoveredCorrelations = [];
  
  // Analyze habit correlations for a given time period
  Future<List<HabitCorrelation>> analyzeHabitCorrelations({
    required Map<String, String?> currentHabits,
    required int daysToAnalyze,
    double minimumStrength = 0.3,
    int minimumSamples = 7,
  }) async {
    try {
      final habitKeys = currentHabits.keys.where((key) => key.isNotEmpty).toList();
      if (habitKeys.length < 2) return [];
      
      final habitPairs = await _buildHabitPairs(habitKeys, daysToAnalyze);
      final correlations = <HabitCorrelation>[];
      
      for (final pair in habitPairs) {
        if (pair.sampleSize >= minimumSamples) {
          final correlation = _analyzeHabitPair(pair);
          if (correlation != null && correlation.strength >= minimumStrength) {
            correlations.add(correlation);
          }
        }
      }
      
      // Sort by strength (strongest first)
      correlations.sort((a, b) => b.strength.compareTo(a.strength));
      
      // Update discovered correlations
      _updateDiscoveredCorrelations(correlations);
      
      return correlations;
      
    } catch (e) {
      debugPrint('Error analyzing habit correlations: $e');
      return [];
    }
  }
  
  // Build habit pairs with historical data
  Future<List<HabitPair>> _buildHabitPairs(List<String> habitKeys, int daysToAnalyze) async {
    final pairs = <HabitPair>[];
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysToAnalyze));
    
    // Get historical data for each habit
    final habitData = <String, List<MapEntry<DateTime, bool>>>{};
    
    for (final habitKey in habitKeys) {
      final entries = <MapEntry<DateTime, bool>>[];
      
      for (int i = 0; i < daysToAnalyze; i++) {
        final date = startDate.add(Duration(days: i));
        final dayEntries = await _storageService.getHabitEntriesForDate(date);
        final value = dayEntries[habitKey];
        
        // Consider habit completed if value exists and is not 'skipped' or empty
        final isCompleted = value != null && 
                           value.isNotEmpty && 
                           value != 'skipped' && 
                           value != 'poor';
        
        entries.add(MapEntry(date, isCompleted));
      }
      
      habitData[habitKey] = entries;
    }
    
    // Create pairs for analysis
    for (int i = 0; i < habitKeys.length; i++) {
      for (int j = i + 1; j < habitKeys.length; j++) {
        final habit1 = habitKeys[i];
        final habit2 = habitKeys[j];
        
        final data1 = habitData[habit1] ?? [];
        final data2 = habitData[habit2] ?? [];
        
        if (data1.length == data2.length && data1.isNotEmpty) {
          pairs.add(HabitPair(
            habit1: habit1,
            habit2: habit2,
            habit1Values: data1.map((e) => e.value).toList(),
            habit2Values: data2.map((e) => e.value).toList(),
            dates: data1.map((e) => e.key).toList(),
          ));
        }
      }
    }
    
    return pairs;
  }
  
  // Analyze a specific habit pair for correlations
  HabitCorrelation? _analyzeHabitPair(HabitPair pair) {
    final sameDayCorr = pair.sameDayCorrelation;
    final temporalCorr = pair.temporalCorrelation;
    final reversTemporalCorr = _calculateReverseTemporalCorrelation(pair);
    final coefficient = pair.correlationCoefficient;
    
    // Determine the strongest correlation type
    CorrelationType? type;
    double strength = 0.0;
    String description = '';
    String insight = '';
    
    // Check for positive same-day correlation
    if (sameDayCorr >= 0.3) {
      type = CorrelationType.positive;
      strength = sameDayCorr;
      description = _formatHabitName(pair.habit1) + ' and ' + _formatHabitName(pair.habit2) + ' often happen together';
      insight = 'When you do one, you\'re ${(sameDayCorr * 100).round()}% likely to do the other on the same day.';
    }
    
    // Check for temporal correlation (stronger than same-day)
    if (temporalCorr > strength && temporalCorr >= 0.4) {
      type = CorrelationType.temporal;
      strength = temporalCorr;
      description = _formatHabitName(pair.habit2) + ' often follows ' + _formatHabitName(pair.habit1);
      insight = 'Doing ${_formatHabitName(pair.habit1)} makes you ${(temporalCorr * 100).round()}% more likely to do ${_formatHabitName(pair.habit2)} the next day.';
    }
    
    // Check for reverse temporal correlation
    if (reversTemporalCorr > strength && reversTemporalCorr >= 0.4) {
      type = CorrelationType.temporal;
      strength = reversTemporalCorr;
      description = _formatHabitName(pair.habit1) + ' often follows ' + _formatHabitName(pair.habit2);
      insight = 'Doing ${_formatHabitName(pair.habit2)} makes you ${(reversTemporalCorr * 100).round()}% more likely to do ${_formatHabitName(pair.habit1)} the next day.';
    }
    
    // Check for causal correlation (very strong temporal + positive correlation)
    if (temporalCorr >= 0.6 && sameDayCorr >= 0.3) {
      type = CorrelationType.causal;
      strength = (temporalCorr + sameDayCorr) / 2;
      description = _formatHabitName(pair.habit1) + ' appears to drive ' + _formatHabitName(pair.habit2);
      insight = 'Strong pattern detected: ${_formatHabitName(pair.habit1)} seems to create momentum for ${_formatHabitName(pair.habit2)}.';
    }
    
    // Check for negative correlation
    if (coefficient < -0.3) {
      type = CorrelationType.negative;
      strength = coefficient.abs();
      description = _formatHabitName(pair.habit1) + ' and ' + _formatHabitName(pair.habit2) + ' rarely happen together';
      insight = 'These habits seem to compete for your time or energy.';
    }
    
    if (type != null && strength > 0) {
      return HabitCorrelation(
        habit1: pair.habit1,
        habit2: pair.habit2,
        type: type,
        strength: strength,
        sampleSize: pair.sampleSize,
        description: description,
        insight: insight,
        discoveredAt: DateTime.now(),
      );
    }
    
    return null;
  }
  
  // Calculate reverse temporal correlation
  double _calculateReverseTemporalCorrelation(HabitPair pair) {
    if (pair.sampleSize < 2) return 0.0;
    
    int followCount = 0;
    int habit2Count = 0;
    
    for (int i = 0; i < pair.sampleSize - 1; i++) {
      if (pair.habit2Values[i]) {
        habit2Count++;
        if (pair.habit1Values[i + 1]) {
          followCount++;
        }
      }
    }
    
    return habit2Count > 0 ? followCount / habit2Count : 0.0;
  }
  
  // Generate insights based on correlations and user complexity
  List<Map<String, dynamic>> generateCorrelationInsights({
    required List<HabitCorrelation> correlations,
    required ComplexityLevel complexityProfile,
    required Map<String, String?> currentHabits,
  }) {
    final insights = <Map<String, dynamic>>[];
    
    if (correlations.isEmpty) {
      insights.add({
        'type': 'MORE DATA NEEDED',
        'message': 'Keep tracking for a few more days to discover your habit patterns.',
        'actionable': false,
        'complexity_appropriate': true,
      });
      return insights;
    }
    
    // Find strongest positive correlations
    final positiveCorrelations = correlations
        .where((c) => c.type == CorrelationType.positive)
        .take(3)
        .toList();
    
    for (final correlation in positiveCorrelations) {
      insights.add({
        'type': 'HABIT SYNERGY',
        'message': correlation.description,
        'detail': correlation.insight,
        'actionable': true,
        'action': 'Try pairing these habits in your routine',
        'complexity_appropriate': _isComplexityAppropriate(correlation, complexityProfile),
      });
    }
    
    // Find temporal patterns
    final temporalCorrelations = correlations
        .where((c) => c.type == CorrelationType.temporal)
        .take(2)
        .toList();
    
    for (final correlation in temporalCorrelations) {
      insights.add({
        'type': 'MOMENTUM PATTERN',
        'message': correlation.description,
        'detail': correlation.insight,
        'actionable': true,
        'action': 'Use this natural flow to build habit chains',
        'complexity_appropriate': _isComplexityAppropriate(correlation, complexityProfile),
      });
    }
    
    // Find causal relationships
    final causalCorrelations = correlations
        .where((c) => c.type == CorrelationType.causal)
        .take(1)
        .toList();
    
    for (final correlation in causalCorrelations) {
      insights.add({
        'type': 'KEYSTONE HABIT',
        'message': correlation.description,
        'detail': correlation.insight,
        'actionable': true,
        'action': 'Focus on the driving habit to improve both',
        'complexity_appropriate': _isComplexityAppropriate(correlation, complexityProfile),
      });
    }
    
    // Find negative correlations (conflicts)
    final negativeCorrelations = correlations
        .where((c) => c.type == CorrelationType.negative && c.strength > 0.5)
        .take(1)
        .toList();
    
    for (final correlation in negativeCorrelations) {
      final suggestion = _getConflictSuggestion(correlation, complexityProfile);
      insights.add({
        'type': 'HABIT CONFLICT',
        'message': correlation.description,
        'detail': correlation.insight,
        'actionable': true,
        'action': suggestion,
        'complexity_appropriate': true,
      });
    }
    
    return insights;
  }
  
  // Check if insight is appropriate for user's complexity level
  bool _isComplexityAppropriate(HabitCorrelation correlation, ComplexityLevel complexityProfile) {
    switch (complexityProfile) {
      case ComplexityLevel.stable:
        return true; // Can handle all insights
      case ComplexityLevel.trying:
        return correlation.strength >= 0.4; // Only stronger patterns
      case ComplexityLevel.overloaded:
        return correlation.type == CorrelationType.positive && correlation.strength >= 0.5; // Only clear synergies
      case ComplexityLevel.survival:
        return false; // No complex insights for survival mode
    }
  }
  
  // Get suggestion for resolving habit conflicts
  String _getConflictSuggestion(HabitCorrelation correlation, ComplexityLevel complexityProfile) {
    switch (complexityProfile) {
      case ComplexityLevel.stable:
        return 'Try scheduling these habits at different times or days';
      case ComplexityLevel.trying:
        return 'Focus on one of these habits first, then add the other';
      case ComplexityLevel.overloaded:
        return 'Consider dropping one habit to reduce decision fatigue';
      case ComplexityLevel.survival:
        return 'Choose the habit that feels most supportive right now';
    }
  }
  
  // Format habit name for display
  String _formatHabitName(String habitKey) {
    return habitKey.replaceAll('_', ' ').toLowerCase();
  }
  
  // Update the list of discovered correlations
  void _updateDiscoveredCorrelations(List<HabitCorrelation> newCorrelations) {
    for (final correlation in newCorrelations) {
      final existingIndex = _discoveredCorrelations.indexWhere((c) =>
          (c.habit1 == correlation.habit1 && c.habit2 == correlation.habit2) ||
          (c.habit1 == correlation.habit2 && c.habit2 == correlation.habit1));
      
      if (existingIndex >= 0) {
        // Update existing correlation if strength improved
        if (correlation.strength > _discoveredCorrelations[existingIndex].strength) {
          _discoveredCorrelations[existingIndex] = correlation;
        }
      } else {
        // Add new correlation
        _discoveredCorrelations.add(correlation);
      }
    }
    
    // Keep only the most recent/relevant correlations
    _discoveredCorrelations.sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));
    if (_discoveredCorrelations.length > 20) {
      _discoveredCorrelations = _discoveredCorrelations.take(20).toList();
    }
  }
  
  // Get discovered correlations
  List<HabitCorrelation> get discoveredCorrelations => List.from(_discoveredCorrelations);
  
  // Get correlations for a specific habit
  List<HabitCorrelation> getCorrelationsForHabit(String habitKey) {
    return _discoveredCorrelations
        .where((c) => c.habit1 == habitKey || c.habit2 == habitKey)
        .toList();
  }
  
  // Get strongest correlation for habit pairing suggestions
  HabitCorrelation? getBestPairingForHabit(String habitKey) {
    final correlations = getCorrelationsForHabit(habitKey)
        .where((c) => c.type == CorrelationType.positive || c.type == CorrelationType.temporal)
        .toList();
    
    if (correlations.isEmpty) return null;
    
    correlations.sort((a, b) => b.strength.compareTo(a.strength));
    return correlations.first;
  }
}