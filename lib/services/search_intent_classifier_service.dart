import 'package:flutter/foundation.dart';
import 'gemma_ai_service.dart';
import '../components/unified_search_widget.dart';

/// Search intent classification result
class SearchIntentResult {
  final SearchIntent intent;
  final double confidence;
  final String reasoning;
  final Map<String, dynamic> metadata;

  const SearchIntentResult({
    required this.intent,
    required this.confidence,
    required this.reasoning,
    this.metadata = const {},
  });

  bool get isConfident => confidence >= 0.6;
  
  Map<String, dynamic> toJson() {
    return {
      'intent': intent.toString(),
      'confidence': confidence,
      'reasoning': reasoning,
      'metadata': metadata,
    };
  }
}

/// Service for intelligently classifying search queries into different intent categories
class SearchIntentClassifierService {
  static final SearchIntentClassifierService _instance = SearchIntentClassifierService._internal();
  factory SearchIntentClassifierService() => _instance;
  SearchIntentClassifierService._internal();

  final GemmaAIService _gemmaAI = GemmaAIService();

  /// Classifies a search query into the most appropriate intent
  Future<SearchIntentResult> classifyIntent(String query) async {
    try {
      // First try with rule-based classification for speed
      final ruleBasedResult = _classifyWithRules(query);
      
      // If rule-based classification is confident, use it (offline capable)
      if (ruleBasedResult.isConfident) {
        debugPrint('✅ Using rule-based classification (offline capable)');
        return ruleBasedResult;
      }
      
      // Try AI classification if available and rule-based is not confident
      try {
        final aiResult = await _classifyWithAI(query);
        // Blend rule-based and AI results for better accuracy
        return _blendResults(ruleBasedResult, aiResult);
      } catch (aiError) {
        debugPrint('AI classification failed, using enhanced rule-based: $aiError');
        // Enhance rule-based result when AI is not available
        return _enhanceRuleBasedResult(ruleBasedResult);
      }
    } catch (e) {
      debugPrint('Search intent classification error: $e');
      // Final fallback to rule-based classification
      return _classifyWithRules(query);
    }
  }

  /// Fast rule-based classification for common patterns
  SearchIntentResult _classifyWithRules(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    
    if (normalizedQuery.isEmpty) {
      return SearchIntentResult(
        intent: SearchIntent.unknown,
        confidence: 1.0,
        reasoning: 'Empty query',
      );
    }

    // Calculate confidence scores for each intent
    final questionScore = _calculateQuestionConfidence(normalizedQuery);
    final forecastScore = _calculateForecastConfidence(normalizedQuery);
    final journalScore = _calculateJournalConfidence(normalizedQuery);
    
    debugPrint('🎯 CLASSIFIER: "${normalizedQuery}"');
    debugPrint('🎯 Question score: $questionScore');
    debugPrint('🎯 Forecast score: $forecastScore'); 
    debugPrint('🎯 Journal score: $journalScore');
    
    // Find the highest scoring intent
    final scores = {
      SearchIntent.askStarbound: questionScore,
      SearchIntent.healthForecast: forecastScore,
      SearchIntent.journal: journalScore,
    };
    
    final bestIntent = scores.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    // Special handling: If query has strong question indicators, prioritize askStarbound
    // even if journal score is higher due to personal pronouns
    final hasStrongQuestionIndicators = _hasStrongQuestionIndicators(normalizedQuery);
    if (hasStrongQuestionIndicators && questionScore > 0.4) {
      debugPrint('🎯 OVERRIDE: Strong question indicators found, using askStarbound');
      return SearchIntentResult(
        intent: SearchIntent.askStarbound,
        confidence: (questionScore * 1.2).clamp(0.0, 1.0), // Boost confidence
        reasoning: 'Strong question indicators override other classifications',
        metadata: _getMetadataForIntent(SearchIntent.askStarbound, normalizedQuery),
      );
    }
    
    // Only return confident results (>0.6), otherwise return unknown
    if (bestIntent.value >= 0.6) {
      return SearchIntentResult(
        intent: bestIntent.key,
        confidence: bestIntent.value,
        reasoning: _getReasoningForIntent(bestIntent.key, bestIntent.value),
        metadata: _getMetadataForIntent(bestIntent.key, normalizedQuery),
      );
    }
    
    // Return the best guess with lower confidence
    return SearchIntentResult(
      intent: bestIntent.key,
      confidence: bestIntent.value,
      reasoning: 'Best match with moderate confidence: ${_getReasoningForIntent(bestIntent.key, bestIntent.value)}',
      metadata: _getMetadataForIntent(bestIntent.key, normalizedQuery),
    );
  }

  /// AI-powered classification for complex queries
  Future<SearchIntentResult> _classifyWithAI(String query) async {
    try {
      final prompt = '''
Classify this search query into one of these categories:
1. journal - Personal reflections, emotions, daily experiences, mood tracking
2. askStarbound - Questions, advice requests, information seeking
3. healthForecast - Future predictions, trend analysis, forecasting
4. unknown - Cannot determine or unclear intent

Query: "$query"

Respond with just the category name and confidence (0.0-1.0) in format: "category:confidence"
''';

      final response = await _gemmaAI.generateResponse(prompt);
      return _parseAIResponse(query, response);
    } catch (e) {
      debugPrint('AI classification failed: $e');
      // Fallback to unknown
      return _getAIFallbackResult(query);
    }
  }

  /// Fallback when AI classification fails
  SearchIntentResult _getAIFallbackResult(String query) {
    // Use enhanced rule-based classification as fallback instead of unknown
    final ruleBasedFallback = _classifyWithRules(query);
    return SearchIntentResult(
      intent: ruleBasedFallback.intent,
      confidence: ruleBasedFallback.confidence * 0.8, // Slight penalty for AI failure
      reasoning: 'AI unavailable, using enhanced rule-based: ${ruleBasedFallback.reasoning}',
      metadata: {...ruleBasedFallback.metadata, 'ai_fallback': true},
    );
  }

  SearchIntentResult _parseAIResponse(String query, String response) {
    try {
      final parts = response.toLowerCase().split(':');
      if (parts.length != 2) throw 'Invalid response format';
      
      final categoryStr = parts[0].trim();
      final confidenceStr = parts[1].trim();
      
      SearchIntent intent;
      switch (categoryStr) {
        case 'journal':
          intent = SearchIntent.journal;
          break;
        case 'askstarbound':
          intent = SearchIntent.askStarbound;
          break;
        case 'healthforecast':
          intent = SearchIntent.healthForecast;
          break;
        default:
          intent = SearchIntent.unknown;
      }
      
      final confidence = double.tryParse(confidenceStr) ?? 0.5;
      
      return SearchIntentResult(
        intent: intent,
        confidence: confidence.clamp(0.0, 1.0),
        reasoning: 'AI classified as $categoryStr with ${(confidence * 100).toInt()}% confidence',
        metadata: {'ai_response': response},
      );
    } catch (e) {
      return SearchIntentResult(
        intent: SearchIntent.unknown,
        confidence: 0.2,
        reasoning: 'Failed to parse AI response: $response',
      );
    }
  }

  // Rule-based classification helpers - now integrated into confidence calculation methods

  List<String> _getMatchingJournalKeywords(String query) {
    final journalKeywords = [
      'felt', 'feeling', 'mood', 'emotions', 'happy', 'sad', 'anxious',
      'stressed', 'tired', 'energetic', 'diary', 'entry', 'journal'
    ];
    return journalKeywords.where((keyword) => query.contains(keyword)).toList();
  }

  String _getQuestionType(String query) {
    if (query.contains('what')) return 'information';
    if (query.contains('how')) return 'instruction';
    if (query.contains('why')) return 'explanation';
    if (query.contains('should')) return 'advice';
    if (query.contains('recommend') || query.contains('suggest')) return 'recommendation';
    return 'general';
  }

  String _getForecastType(String query) {
    if (query.contains('mood') || query.contains('feeling')) return 'mood';
    if (query.contains('health') || query.contains('wellness')) return 'health';
    if (query.contains('habit') || query.contains('routine')) return 'habits';
    if (query.contains('energy') || query.contains('sleep')) return 'energy';
    return 'general';
  }
  
  // Enhanced confidence calculation methods
  double _calculateQuestionConfidence(String query) {
    double score = 0.0;
    
    // Strong question indicators
    final questionStarters = ['what ', 'how ', 'why ', 'when ', 'where ', 'who ', 'which '];
    if (questionStarters.any((starter) => query.startsWith(starter))) {
      score += 0.8;
    }
    
    // Question mark
    if (query.contains('?')) {
      score += 0.6;
    }
    
    // Strong question phrases
    final strongQuestionPhrases = [
      'should i ', 'can i ', 'could i ', 'would i ', 'help me ',
      'tell me ', 'advice', 'recommend', 'suggest', 'explain',
      'show me ', 'teach me', 'guide me'
    ];
    final matchingPhrases = strongQuestionPhrases.where((phrase) => query.contains(phrase)).length;
    score += matchingPhrases * 0.3;
    
    // Moderate question words anywhere in query
    final questionWords = ['advice', 'help', 'how', 'what', 'why'];
    final matchingWords = questionWords.where((word) => query.contains(word)).length;
    score += matchingWords * 0.2;
    
    return (score).clamp(0.0, 1.0);
  }
  
  double _calculateForecastConfidence(String query) {
    double score = 0.0;
    
    // Strong forecast keywords
    final strongForecastKeywords = [
      'predict', 'forecast', 'future', 'will i ', 'going to ',
      'what will happen', 'how will', 'likely to', 'expect to'
    ];
    final strongMatches = strongForecastKeywords.where((keyword) => query.contains(keyword)).length;
    score += strongMatches * 0.7;
    
    // Moderate forecast keywords
    final moderateForecastKeywords = [
      'next week', 'next month', 'tomorrow', 'trend', 'pattern',
      'projection', 'in the future', 'upcoming', 'eventually'
    ];
    final moderateMatches = moderateForecastKeywords.where((keyword) => query.contains(keyword)).length;
    score += moderateMatches * 0.4;
    
    // Time-related words indicating future
    final futureWords = ['will', 'tomorrow', 'next', 'future', 'later'];
    final futureMatches = futureWords.where((word) => query.contains(word)).length;
    score += futureMatches * 0.2;
    
    return (score).clamp(0.0, 1.0);
  }
  
  double _calculateJournalConfidence(String query) {
    double score = 0.0;
    
    // Strong journal indicators
    final strongJournalKeywords = [
      'felt ', 'feeling ', 'today i', 'yesterday i', 'last week i',
      'i am ', 'i was ', 'diary', 'journal', 'logged', 'recorded',
      'my day', 'my mood', 'my emotions', 'had a good', 'had a bad',
      'went well', 'struggled with', 'accomplished', 'achieved'
    ];
    final strongMatches = strongJournalKeywords.where((keyword) => query.contains(keyword)).length;
    score += strongMatches * 0.6;
    
    // Emotion words
    final emotionWords = ['happy', 'sad', 'anxious', 'stressed', 'tired', 'excited', 'angry', 'calm'];
    final emotionMatches = emotionWords.where((word) => query.contains(word)).length;
    score += emotionMatches * 0.3;
    
    // Personal pronouns (weaker indicator)
    final personalPronouns = ['i ', ' i ', 'my ', 'me ', 'myself'];
    final pronounMatches = personalPronouns.where((pronoun) => query.contains(pronoun)).length;
    score += pronounMatches * 0.1;
    
    // Past tense indicators
    final pastTenseIndicators = ['was', 'were', 'did', 'had', 'went', 'felt', 'thought'];
    final pastMatches = pastTenseIndicators.where((word) => query.contains(word)).length;
    score += pastMatches * 0.15;
    
    return (score).clamp(0.0, 1.0);
  }
  
  /// Check if query has strong question indicators that should override other classifications
  bool _hasStrongQuestionIndicators(String query) {
    // Question starters that are very clear
    final strongQuestionStarters = ['what ', 'how ', 'why ', 'when ', 'where ', 'who ', 'which '];
    if (strongQuestionStarters.any((starter) => query.startsWith(starter))) {
      return true;
    }
    
    // Question mark is a strong indicator
    if (query.contains('?')) {
      return true;
    }
    
    // Strong question phrases
    final strongQuestionPhrases = [
      'should i ', 'can i ', 'could i ', 'would i ',
      'help me ', 'tell me ', 'explain ', 'show me '
    ];
    return strongQuestionPhrases.any((phrase) => query.contains(phrase));
  }
  
  String _getReasoningForIntent(SearchIntent intent, double confidence) {
    final confidencePercent = (confidence * 100).toInt();
    switch (intent) {
      case SearchIntent.askStarbound:
        return 'Question pattern detected ($confidencePercent% confidence)';
      case SearchIntent.healthForecast:
        return 'Future prediction pattern detected ($confidencePercent% confidence)';
      case SearchIntent.journal:
        return 'Personal reflection pattern detected ($confidencePercent% confidence)';
      default:
        return 'Intent unclear ($confidencePercent% confidence)';
    }
  }
  
  Map<String, dynamic> _getMetadataForIntent(SearchIntent intent, String query) {
    switch (intent) {
      case SearchIntent.askStarbound:
        return {'question_type': _getQuestionType(query)};
      case SearchIntent.healthForecast:
        return {'forecast_type': _getForecastType(query)};
      case SearchIntent.journal:
        return {'keywords': _getMatchingJournalKeywords(query)};
      default:
        return {};
    }
  }
  
  /// Blend rule-based and AI results for better accuracy
  SearchIntentResult _blendResults(SearchIntentResult ruleBasedResult, SearchIntentResult aiResult) {
    // If AI is very confident and disagrees significantly with rule-based, trust AI
    if (aiResult.confidence > 0.8 && 
        aiResult.intent != ruleBasedResult.intent && 
        ruleBasedResult.confidence < 0.7) {
      return SearchIntentResult(
        intent: aiResult.intent,
        confidence: aiResult.confidence * 0.9, // Slight penalty for blending
        reasoning: 'AI override: ${aiResult.reasoning}',
        metadata: aiResult.metadata,
      );
    }
    
    // If both agree, boost confidence
    if (aiResult.intent == ruleBasedResult.intent) {
      final blendedConfidence = ((aiResult.confidence + ruleBasedResult.confidence) / 2 * 1.1).clamp(0.0, 1.0);
      return SearchIntentResult(
        intent: aiResult.intent,
        confidence: blendedConfidence,
        reasoning: 'Rule-based + AI agreement: ${ruleBasedResult.reasoning}',
        metadata: {...ruleBasedResult.metadata, ...aiResult.metadata},
      );
    }
    
    // If rule-based is more confident, use it
    if (ruleBasedResult.confidence >= aiResult.confidence) {
      return ruleBasedResult;
    }
    
    // Otherwise use AI result
    return aiResult;
  }
  
  /// Enhance rule-based result when AI is not available
  SearchIntentResult _enhanceRuleBasedResult(SearchIntentResult ruleBasedResult) {
    // Boost confidence slightly for offline capability
    final enhancedConfidence = (ruleBasedResult.confidence * 1.05).clamp(0.0, 1.0);
    
    return SearchIntentResult(
      intent: ruleBasedResult.intent,
      confidence: enhancedConfidence,
      reasoning: '${ruleBasedResult.reasoning} (offline mode)',
      metadata: {...ruleBasedResult.metadata, 'offline_mode': true},
    );
  }
}