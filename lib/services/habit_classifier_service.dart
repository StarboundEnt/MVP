import 'package:flutter/foundation.dart';
import 'text_parser_service.dart';
import '../models/habit_model.dart';
import '../providers/app_state.dart';

/// Complete classification of a user's input
class InputClassification {
  final String originalText;
  final List<ClassificationResult> classifications;
  final DateTime timestamp;
  final Map<String, dynamic> summary;

  const InputClassification({
    required this.originalText,
    required this.classifications,
    required this.timestamp,
    this.summary = const {},
  });

  bool get hasClassifications => classifications.isNotEmpty;
  int get choiceCount => classifications.where((c) => c.categoryType == 'choice').length;
  int get chanceCount => classifications.where((c) => c.categoryType == 'chance').length;
  double get averageConfidence => 
      classifications.isEmpty ? 0.0 : 
      classifications.map((c) => c.confidence).reduce((a, b) => a + b) / classifications.length;

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'classifications': classifications.map((c) => c.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'summary': summary,
    };
  }
}

/// Service for classifying parsed text segments into habit categories
class HabitClassifierService {
  static final HabitClassifierService _instance = HabitClassifierService._internal();
  factory HabitClassifierService() => _instance;
  HabitClassifierService._internal();

  final TextParserService _textParser = TextParserService();
  
  // Mapping from parsed categories to habit system categories
  static const Map<String, String> _categoryMapping = {
    // Parser categories -> Habit system keys
    'hydration': 'hydration',
    'nutrition': 'nutrition', 
    'focus': 'focus',
    'sleep': 'sleep',
    'movement': 'movement',
    'energy': 'energy',
    'mood': 'mood',
    'safety': 'safety',
    'meals': 'meals',
    'sleepIssues': 'sleepIssues',
    'financial': 'financial',
    'outdoor': 'outdoor',
  };

  /// Initialize the classifier
  Future<bool> initialize() async {
    return await _textParser.initialize();
  }

  bool get isReady => _textParser.isReady;

  /// Classify user input into habit categories
  Future<InputClassification> classifyInput(String input) async {
    try {
      // Parse the input first
      final parseResult = await _textParser.parseInput(input);
      
      if (!parseResult.isValid || parseResult.segments.isEmpty) {
        return InputClassification(
          originalText: input,
          classifications: [],
          timestamp: DateTime.now(),
          summary: {
            'error': parseResult.error ?? 'No meaningful segments found',
            'segmentCount': 0,
          },
        );
      }

      // Classify each segment
      final classifications = <ClassificationResult>[];
      
      for (final segment in parseResult.segments) {
        final classification = await _classifySegment(segment);
        if (classification != null) {
          classifications.add(classification);
        }
      }

      return InputClassification(
        originalText: input,
        classifications: classifications,
        timestamp: DateTime.now(),
        summary: {
          'segmentCount': parseResult.segments.length,
          'classificationCount': classifications.length,
          'averageConfidence': classifications.isEmpty ? 0.0 : 
            classifications.map((c) => c.confidence).reduce((a, b) => a + b) / classifications.length,
          'choiceCount': classifications.where((c) => c.categoryType == 'choice').length,
          'chanceCount': classifications.where((c) => c.categoryType == 'chance').length,
        },
      );

    } catch (e) {
      debugPrint('HabitClassifierService: Classification failed: $e');
      return InputClassification(
        originalText: input,
        classifications: [],
        timestamp: DateTime.now(),
        summary: {
          'error': e.toString(),
        },
      );
    }
  }

  /// Classify a single parsed segment
  Future<ClassificationResult?> _classifySegment(ParsedSegment segment) async {
    // Map the parser category to habit system category
    final habitKey = _categoryMapping[segment.category];
    if (habitKey == null) {
      debugPrint('HabitClassifierService: Unknown category ${segment.category}');
      return null;
    }

    // Get the habit category definition
    final categories = StarboundHabits.all;
    final habitCategory = categories[habitKey];
    if (habitCategory == null) {
      debugPrint('HabitClassifierService: Habit category not found: $habitKey');
      return null;
    }

    // Determine the habit value based on the segment
    final habitValue = _determineHabitValue(segment, habitCategory);
    
    // Calculate final confidence
    final confidence = _calculateConfidence(segment, habitCategory, habitValue);

    // Generate reasoning
    final reasoning = _generateReasoning(segment, habitCategory, habitValue);

    return ClassificationResult(
      habitKey: habitKey,
      habitValue: habitValue,
      categoryTitle: habitCategory.title,
      categoryType: habitCategory.type,
      confidence: confidence,
      reasoning: reasoning,
      extractedText: segment.text,
      metadata: {
        'originalCategory': segment.category,
        'segmentConfidence': segment.confidence,
        'classificationMethod': segment.metadata['method'] ?? 'ai',
      },
      // Pass through multi-layer analysis data with enhancement
      sentiment: segment.sentiment,
      themes: _enhanceThemes(segment, habitKey, habitCategory),
      keywords: segment.keywords,
      sentimentConfidence: segment.sentimentConfidence,
    );
  }

  /// Enhance themes with additional context-aware tags
  List<String> _enhanceThemes(ParsedSegment segment, String habitKey, HabitCategory habitCategory) {
    List<String> themes = List.from(segment.themes);
    
    // Add the habit category as a theme if not already present
    final categoryTheme = habitKey.toLowerCase();
    if (!themes.contains(categoryTheme)) {
      themes.add(categoryTheme);
    }
    
    // Add themes based on sentiment
    if (segment.sentiment != 'neutral' && !themes.contains(segment.sentiment)) {
      themes.add(segment.sentiment);
    }
    
    // Add contextual themes based on habit type and content
    final textLower = segment.text.toLowerCase();
    
    // Emotional themes
    if (textLower.contains('stress') || textLower.contains('anxious') || textLower.contains('worried')) {
      if (!themes.contains('anxiety')) themes.add('anxiety');
    }
    if (textLower.contains('tired') || textLower.contains('exhausted') || textLower.contains('energy')) {
      if (!themes.contains('energy')) themes.add('energy');
    }
    if (textLower.contains('lonely') || textLower.contains('isolated')) {
      if (!themes.contains('loneliness')) themes.add('loneliness');
    }
    if (textLower.contains('overwhelmed') || textLower.contains('too much')) {
      if (!themes.contains('overwhelmed')) themes.add('overwhelmed');
    }
    
    // Life domain themes
    if (textLower.contains('work') || textLower.contains('job') || textLower.contains('office')) {
      if (!themes.contains('work')) themes.add('work');
    }
    if (textLower.contains('family') || textLower.contains('parent') || textLower.contains('child')) {
      if (!themes.contains('family')) themes.add('family');
    }
    if (textLower.contains('friend') || textLower.contains('social')) {
      if (!themes.contains('social')) themes.add('social');
    }
    if (textLower.contains('money') || textLower.contains('rent') || textLower.contains('bill')) {
      if (!themes.contains('finance')) themes.add('finance');
    }
    if (textLower.contains('health') || textLower.contains('doctor') || textLower.contains('sick')) {
      if (!themes.contains('health')) themes.add('health');
    }
    
    // Ensure we have at least one theme
    if (themes.isEmpty) {
      themes.add('reflection');
    }
    
    return themes;
  }

  /// Determine the appropriate habit value for a segment
  String _determineHabitValue(ParsedSegment segment, HabitCategory category) {
    final lowerText = segment.text.toLowerCase();
    final intensity = segment.metadata['intensity'] as String? ?? 'medium';

    // For CHOICES - determine quality/success level
    if (category.type == 'choice') {
      // Look for positive/negative indicators
      if (lowerText.contains('great') || lowerText.contains('amazing') || 
          lowerText.contains('wonderful') || lowerText.contains('love')) {
        return 'high';
      } else if (lowerText.contains('struggled') || lowerText.contains('hard') || 
                 lowerText.contains('difficult') || lowerText.contains('force')) {
        return 'poor';
      } else if (lowerText.contains('okay') || lowerText.contains('fine') || 
                 lowerText.contains('alright')) {
        return 'medium';
      } else {
        // Default based on intensity
        switch (intensity) {
          case 'high': return 'high';
          case 'low': return 'low';
          default: return 'medium';
        }
      }
    } 
    
    // For CHANCES - determine support level needed
    else {
      if (lowerText.contains('panic') || lowerText.contains('terrible') || 
          lowerText.contains('crisis') || lowerText.contains('emergency')) {
        return 'yes_support';
      } else if (lowerText.contains('managing') || lowerText.contains('okay') || 
                 lowerText.contains('handling')) {
        return 'managing';
      } else if (lowerText.contains('maybe') || lowerText.contains('not sure')) {
        return 'maybe';
      } else {
        // Default based on intensity
        switch (intensity) {
          case 'high': return 'yes_support';
          case 'low': return 'okay';
          default: return 'maybe';
        }
      }
    }
  }

  /// Calculate confidence score for the classification
  double _calculateConfidence(ParsedSegment segment, HabitCategory category, String habitValue) {
    double confidence = segment.confidence;
    
    // Adjust based on text clarity
    final lowerText = segment.text.toLowerCase();
    
    // Boost confidence for clear indicators
    if (category.type == 'choice') {
      if (lowerText.contains('i ') || lowerText.contains('did ') || 
          lowerText.contains('had ') || lowerText.contains('went ')) {
        confidence += 0.1;
      }
    } else {
      if (lowerText.contains('happened') || lowerText.contains('couldn\'t') || 
          lowerText.contains('couldn\'t') || lowerText.contains('unexpected')) {
        confidence += 0.1;
      }
    }

    // Reduce confidence for ambiguous text
    if (segment.text.length < 10) {
      confidence -= 0.1;
    }

    // Ensure confidence is within bounds
    return confidence.clamp(0.0, 1.0);
  }

  /// Generate human-readable reasoning for the classification
  String _generateReasoning(ParsedSegment segment, HabitCategory category, String habitValue) {
    final type = category.type == 'choice' ? 'action you took' : 'event that happened';
    final valueDescription = _getValueDescription(category, habitValue);
    
    return 'Identified "${segment.text}" as ${category.title.toLowerCase()} - an $type. '
           'Classified as: $valueDescription';
  }

  /// Get human-readable description of habit value
  String _getValueDescription(HabitCategory category, String habitValue) {
    final option = category.options.firstWhere(
      (opt) => opt.value == habitValue,
      orElse: () => HabitOption(label: habitValue, value: habitValue),
    );
    return option.label;
  }

  /// Apply classifications to the app state
  Future<bool> applyClassifications(InputClassification classification, AppState appState) async {
    try {
      bool anyChanges = false;

      for (final result in classification.classifications) {
        // Only apply high-confidence classifications automatically
        if (result.confidence >= 0.7) {
          await appState.updateHabit(result.habitKey, result.habitValue);
          anyChanges = true;
          
          debugPrint('Applied: ${result.habitKey} = ${result.habitValue} (confidence: ${result.confidence.toStringAsFixed(2)})');
        }
      }

      return anyChanges;
    } catch (e) {
      debugPrint('HabitClassifierService: Failed to apply classifications: $e');
      return false;
    }
  }

  /// Get classification summary for user feedback
  String getClassificationSummary(InputClassification classification) {
    if (classification.classifications.isEmpty) {
      return 'No habit patterns detected in your message.';
    }

    final highConfidence = classification.classifications.where((c) => c.confidence >= 0.7).length;
    final choices = classification.choiceCount;
    final chances = classification.chanceCount;

    String summary = 'Found ${classification.classifications.length} habit';
    if (classification.classifications.length > 1) summary += 's';
    
    if (choices > 0 && chances > 0) {
      summary += ' ($choices choice${choices > 1 ? 's' : ''}, $chances event${chances > 1 ? 's' : ''})';
    } else if (choices > 0) {
      summary += ' - action${choices > 1 ? 's' : ''} you took';
    } else if (chances > 0) {
      summary += ' - event${chances > 1 ? 's' : ''} that happened';
    }

    if (highConfidence < classification.classifications.length) {
      summary += '. ${highConfidence} applied automatically';
    }

    return summary + '.';
  }
}