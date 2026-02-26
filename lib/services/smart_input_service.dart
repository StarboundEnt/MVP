import 'package:flutter/foundation.dart';
import 'dart:async';
import 'search_intent_classifier_service.dart';
import '../components/unified_search_widget.dart';
import '../models/complexity_engine_models.dart';
import 'complexity_engine_service.dart';

/// Routing intents for Smart Input.
enum SmartRouteIntent {
  ask,
  journal,
  guidedJournal,
  both,
  clarify,
}

/// Enhanced smart input result with routing information
class SmartInputResult {
  final SmartRouteIntent intent;
  final String processedText;
  final double confidence;
  final String reasoning;
  final Map<String, dynamic> metadata;
  final InputTags tags;
  final ComplexityResponseModel? responseModel;
  final String? engineEventId;
  final String? engineCreatedAt;

  const SmartInputResult({
    required this.intent,
    required this.processedText,
    required this.confidence,
    required this.reasoning,
    this.metadata = const {},
    this.tags = const InputTags(),
    this.responseModel,
    this.engineEventId,
    this.engineCreatedAt,
  });

  bool get isConfident => confidence >= 0.6;
  
  /// Get the destination route for this input
  String get destination {
    switch (intent) {
      case SmartRouteIntent.journal:
        return '/journal';
      case SmartRouteIntent.guidedJournal:
        return '/journal';
      case SmartRouteIntent.ask:
        return '/ask';
      case SmartRouteIntent.both:
        return '/ask';
      case SmartRouteIntent.clarify:
        return '/clarify';
      default:
        return '/journal'; // Default fallback
    }
  }

  /// Get the icon for this input type
  String get iconName {
    switch (intent) {
      case SmartRouteIntent.journal:
        return 'bookOpen';
      case SmartRouteIntent.guidedJournal:
        return 'bookOpen';
      case SmartRouteIntent.ask:
        return 'messageCircle';
      case SmartRouteIntent.both:
        return 'layers';
      case SmartRouteIntent.clarify:
        return 'helpCircle';
      default:
        return 'edit3';
    }
  }

  /// Get the color theme for this input type
  String get colorTheme {
    switch (intent) {
      case SmartRouteIntent.journal:
        return 'stellarAqua';
      case SmartRouteIntent.guidedJournal:
        return 'stellarAqua';
      case SmartRouteIntent.ask:
        return 'nebulaPurple';
      case SmartRouteIntent.both:
        return 'stellarAqua';
      case SmartRouteIntent.clarify:
        return 'textPrimary';
      default:
        return 'textPrimary';
    }
  }
}

/// Tags that can be automatically detected and applied to input
class InputTags {
  final bool hasChoice;
  final bool hasChance;
  final bool hasOutcome;
  final List<String> emotions;
  final List<String> healthTopics;
  final bool isFutureOriented;
  final bool isQuestion;

  const InputTags({
    this.hasChoice = false,
    this.hasChance = false,
    this.hasOutcome = false,
    this.emotions = const [],
    this.healthTopics = const [],
    this.isFutureOriented = false,
    this.isQuestion = false,
  });

  /// Create tags from metadata
  factory InputTags.fromMetadata(Map<String, dynamic> metadata) {
    return InputTags(
      hasChoice: metadata['hasChoice'] ?? false,
      hasChance: metadata['hasChance'] ?? false,
      hasOutcome: metadata['hasOutcome'] ?? false,
      emotions: List<String>.from(metadata['emotions'] ?? []),
      healthTopics: List<String>.from(metadata['healthTopics'] ?? []),
      isFutureOriented: metadata['isFutureOriented'] ?? false,
      isQuestion: metadata['isQuestion'] ?? false,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'hasChoice': hasChoice,
      'hasChance': hasChance,
      'hasOutcome': hasOutcome,
      'emotions': emotions,
      'healthTopics': healthTopics,
      'isFutureOriented': isFutureOriented,
      'isQuestion': isQuestion,
    };
  }
}

/// Enhanced smart input processing service
class SmartInputService {
  static final SmartInputService _instance = SmartInputService._internal();
  factory SmartInputService() => _instance;
  SmartInputService._internal();

  final SearchIntentClassifierService _classifier =
      SearchIntentClassifierService();
  final ComplexityEngineService _complexityEngine = ComplexityEngineService();
  
  // Cache for intent classification results
  final Map<String, _CachedResult> _intentCache = {};
  static const int _cacheMaxSize = 100;
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Process user input and return smart routing information
  Future<SmartInputResult> processInput(String input) async {
    try {
      // Validate input
      if (input.trim().isEmpty) {
        return _createFallbackResult(input);
      }

      // Check cache first
      final cacheKey = _getCacheKey(input);
      final cachedResult = _getCachedResult(cacheKey);
      if (cachedResult != null) {
        debugPrint('🚀 Using cached intent result for: "${input.substring(0, input.length.clamp(0, 50))}..."');
        return cachedResult;
      }

      // Classify the intent using existing service with reduced timeout
      final intentResult =
          await _classifier.classifyIntent(input).timeout(const Duration(seconds: 3));
      
      debugPrint('🎯 Intent classification result: ${intentResult.intent}');
      debugPrint('🎯 Confidence: ${intentResult.confidence}');
      debugPrint('🎯 Reasoning: ${intentResult.reasoning}');
      
      // Enhance with additional smart tagging
      final tags = _extractTags(input, intentResult.intent);
      
      // Heuristic scores
      final heuristicScores = _scoreHeuristics(input);
      final double heuristicAsk = heuristicScores['ask'] ?? 0.0;
      final double heuristicJournal = heuristicScores['journal'] ?? 0.0;

      // Optional ML/LLM classification mapping
      final double mlAsk = _mapMLConfidenceToAsk(intentResult);
      final double mlJournal = _mapMLConfidenceToJournal(intentResult);

      final double askScore =
          _blendScores(heuristicAsk, mlAsk, heuristicWeight: 0.7);
      final double journalScore =
          _blendScores(heuristicJournal, mlJournal, heuristicWeight: 0.7);

      final guidedScore = _scoreGuidedJournal(input, tags, journalScore);
      final routing = _selectRouteWithOverrides(
        input: input,
        tags: tags,
        askScore: askScore,
        journalScore: journalScore,
        guidedScore: guidedScore,
      );

      // Process the text for the specific destination
      final processedText = _processTextForIntent(input, routing, tags);

      ComplexityResponseModel? responseModel;
      String? engineEventId;
      String? engineCreatedAt;
      if (routing == SmartRouteIntent.ask || routing == SmartRouteIntent.both) {
        try {
          final engineResult = await _complexityEngine.processSmartInput(
            inputText: processedText,
            intent: routing == SmartRouteIntent.ask
                ? EventIntent.ask
                : EventIntent.mixed,
            saveMode: EventSaveMode.saveFactorsOnly,
          );
          responseModel = engineResult.responseModel;
          engineEventId = engineResult.event.id;
          engineCreatedAt = engineResult.event.createdAt;
        } catch (e) {
          debugPrint('Complexity engine failed: $e');
        }
      }

      final result = SmartInputResult(
        intent: routing,
        processedText: processedText,
        confidence: _deriveConfidence(askScore, journalScore),
        reasoning: _buildRoutingReasoning(
          askScore: askScore,
          journalScore: journalScore,
          mlIntent: intentResult.intent,
          mlConfidence: intentResult.confidence,
          mlReasoning: intentResult.reasoning,
          routing: routing,
        ),
        metadata: {
          ...intentResult.metadata,
          'heuristic_ask': askScore,
          'heuristic_journal': journalScore,
          'ml_intent': intentResult.intent.toString(),
          'ml_confidence': intentResult.confidence,
        },
        tags: tags,
        responseModel: responseModel,
        engineEventId: engineEventId,
        engineCreatedAt: engineCreatedAt,
      );
      
      // Cache the result
      _cacheResult(cacheKey, result);
      
      return result;
    } on TimeoutException catch (e) {
      debugPrint('Smart input processing timeout: $e');
      return _createTimeoutFallbackResult(input);
    } catch (e) {
      debugPrint('Smart input processing error: $e');
      return _createFallbackResult(input);
    }
  }

  /// Extract smart tags from input text
  InputTags _extractTags(String input, SearchIntent intent) {
    final lowercaseInput = input.toLowerCase();
    
    // Choice detection
    final hasChoice = _detectChoice(lowercaseInput);
    
    // Chance/probability detection
    final hasChance = _detectChance(lowercaseInput);
    
    // Outcome detection
    final hasOutcome = _detectOutcome(lowercaseInput);
    
    // Emotion detection
    final emotions = _detectEmotions(lowercaseInput);
    
    // Health topics detection
    final healthTopics = _detectHealthTopics(lowercaseInput);
    
    // Future orientation
    final isFutureOriented = _detectFutureOrientation(lowercaseInput);
    
    // Question detection
    final isQuestion = _detectQuestion(input);

    return InputTags(
      hasChoice: hasChoice,
      hasChance: hasChance,
      hasOutcome: hasOutcome,
      emotions: emotions,
      healthTopics: healthTopics,
      isFutureOriented: isFutureOriented,
      isQuestion: isQuestion,
    );
  }

  /// Detect if input contains choice-related content
  bool _detectChoice(String input) {
    final choiceKeywords = [
      'choose', 'choice', 'decision', 'decide', 'option', 'alternative',
      'should i', 'which', 'either', 'or', 'pick', 'select'
    ];
    return choiceKeywords.any((keyword) => input.contains(keyword));
  }

  /// Detect if input contains chance/probability content
  bool _detectChance(String input) {
    final chanceKeywords = [
      'chance', 'probability', 'likely', 'unlikely', 'maybe', 'perhaps',
      'might', 'could', 'possibly', 'odds', 'risk', 'uncertain'
    ];
    return chanceKeywords.any((keyword) => input.contains(keyword));
  }

  /// Detect if input contains outcome-related content
  bool _detectOutcome(String input) {
    final outcomeKeywords = [
      'result', 'outcome', 'consequence', 'effect', 'impact', 'happened',
      'ended up', 'turned out', 'resulted in', 'led to', 'caused'
    ];
    return outcomeKeywords.any((keyword) => input.contains(keyword));
  }

  /// Detect emotions in the input
  List<String> _detectEmotions(String input) {
    final emotionMap = {
      'happy': ['happy', 'joy', 'excited', 'cheerful', 'glad', 'delighted'],
      'sad': ['sad', 'depressed', 'down', 'upset', 'disappointed', 'blue'],
      'anxious': ['anxious', 'worried', 'nervous', 'stress', 'panic', 'fear'],
      'angry': ['angry', 'mad', 'furious', 'irritated', 'annoyed', 'rage'],
      'tired': ['tired', 'exhausted', 'fatigue', 'worn out', 'drained'],
      'energetic': ['energetic', 'motivated', 'pumped', 'active', 'vibrant'],
      'calm': ['calm', 'peaceful', 'relaxed', 'serene', 'tranquil'],
      'confused': ['confused', 'lost', 'unclear', 'puzzled', 'bewildered'],
    };

    List<String> detectedEmotions = [];
    for (final emotion in emotionMap.keys) {
      if (emotionMap[emotion]!.any((word) => input.contains(word))) {
        detectedEmotions.add(emotion);
      }
    }
    return detectedEmotions;
  }

  /// Detect health topics in the input
  List<String> _detectHealthTopics(String input) {
    final healthTopics = {
      'sleep': ['sleep', 'insomnia', 'tired', 'rest', 'bed', 'dream'],
      'exercise': ['exercise', 'workout', 'gym', 'run', 'walk', 'fitness'],
      'diet': ['diet', 'eat', 'food', 'nutrition', 'meal', 'hungry'],
      'mental_health': ['stress', 'anxiety', 'depression', 'mood', 'mental'],
      'energy': ['energy', 'fatigue', 'tired', 'exhausted', 'motivation'],
      'social': ['friends', 'family', 'social', 'relationship', 'people'],
    };

    List<String> detectedTopics = [];
    for (final topic in healthTopics.keys) {
      if (healthTopics[topic]!.any((word) => input.contains(word))) {
        detectedTopics.add(topic);
      }
    }
    return detectedTopics;
  }

  /// Detect future-oriented language
  bool _detectFutureOrientation(String input) {
    final futureKeywords = [
      'will', 'going to', 'plan to', 'next', 'tomorrow', 'future',
      'predict', 'forecast', 'expect', 'hope', 'want to', 'goal'
    ];
    return futureKeywords.any((keyword) => input.contains(keyword));
  }

  /// Detect if input is a question
  bool _detectQuestion(String input) {
    final questionWords = ['what', 'how', 'why', 'when', 'where', 'who', 'which', 'can', 'should', 'would', 'could'];
    final hasQuestionWord = questionWords.any((word) => input.toLowerCase().startsWith(word));
    final hasQuestionMark = input.contains('?');
    return hasQuestionWord || hasQuestionMark;
  }

  /// Process text specifically for the detected intent
  String _processTextForIntent(
      String input, SmartRouteIntent intent, InputTags tags) {
    switch (intent) {
      case SmartRouteIntent.journal:
        return _processForJournal(input, tags);
      case SmartRouteIntent.guidedJournal:
        return _processForGuidedJournal(input);
      case SmartRouteIntent.ask:
        return _processForAsk(input, tags);
      case SmartRouteIntent.both:
        return _processForAsk(input, tags);
      case SmartRouteIntent.clarify:
        return input;
      default:
        return input;
    }
  }

  /// Process text for journal entry
  String _processForJournal(String input, InputTags tags) {
    String processed = input;
    
    // Add automatic tags if detected
    List<String> autoTags = [];
    if (tags.hasChoice) autoTags.add('#choice');
    if (tags.hasChance) autoTags.add('#chance');
    if (tags.hasOutcome) autoTags.add('#outcome');
    
    // Add emotion tags
    for (final emotion in tags.emotions) {
      autoTags.add('#$emotion');
    }
    
    // Add health topic tags
    for (final topic in tags.healthTopics) {
      autoTags.add('#$topic');
    }

    if (autoTags.isNotEmpty) {
      processed += '\n\n${autoTags.join(' ')}';
    }

    return processed;
  }

  String _processForGuidedJournal(String input) {
    return input.trim();
  }

  /// Process text for Ask Starbound
  String _processForAsk(String input, InputTags tags) {
    // Ensure it's formatted as a question if not already
    if (!tags.isQuestion && !input.trim().endsWith('?')) {
      return '$input?';
    }
    return input;
  }

  /// Create a fallback result when processing fails
  SmartInputResult _createFallbackResult(String input) {
    return SmartInputResult(
      intent: SmartRouteIntent.journal,
      processedText: input,
      confidence: 0.3,
      reasoning: 'Fallback to journal due to processing error',
      tags: const InputTags(),
    );
  }

  /// Create a fallback result when processing times out
  SmartInputResult _createTimeoutFallbackResult(String input) {
    return SmartInputResult(
      intent: SmartRouteIntent.journal,
      processedText: input,
      confidence: 0.2,
      reasoning: 'Fallback to journal due to processing timeout',
      tags: const InputTags(),
    );
  }

  Map<String, double> _scoreHeuristics(String input) {
    final normalized = input.toLowerCase().trim();
    double askScore = 0.0;
    double journalScore = 0.0;

    // Punctuation & question structure
    if (normalized.contains('?')) {
      askScore += 0.6;
    }

    final questionStarters = [
      'what ',
      'how ',
      'why ',
      'when ',
      'where ',
      'who ',
      'which ',
      'can ',
      'should ',
      'would ',
      'could ',
      'is ',
      'are ',
      'do ',
      'did ',
    ];
    if (questionStarters.any((starter) => normalized.startsWith(starter))) {
      askScore += 0.5;
    }

    final questionPhrases = [
      'help me',
      'tell me',
      'advice',
      'recommend',
      'suggest',
      'what should',
      'how do i',
      'is it normal',
      'can you',
      'could you',
      'should i',
      'what can i',
    ];
    final questionPhraseMatches =
        questionPhrases.where((phrase) => normalized.contains(phrase)).length;
    askScore += questionPhraseMatches * 0.25;

    // Reflection phrases
    final reflectionPhrases = [
      'i feel',
      'i felt',
      'i am',
      'i was',
      "i'm",
      "i’ve",
      "i've",
      'today i',
      'yesterday i',
      'lately',
      'recently',
      'this week',
      'last night',
      'this morning',
      'my mood',
      'my day',
      'my sleep',
    ];
    final reflectionMatches =
        reflectionPhrases.where((phrase) => normalized.contains(phrase)).length;
    journalScore += reflectionMatches * 0.35;

    // Time anchors
    final timeAnchors = [
      'today',
      'yesterday',
      'last night',
      'this morning',
      'this week',
      'last week',
      'recently',
      'lately',
    ];
    final timeMatches =
        timeAnchors.where((anchor) => normalized.contains(anchor)).length;
    journalScore += timeMatches * 0.2;

    // Emotional language boosts journal
    final emotions = _detectEmotions(normalized);
    if (emotions.isNotEmpty) {
      journalScore += 0.3;
    }

    final hasHealthConcern = _detectHealthConcern(normalized);
    if (hasHealthConcern) {
      askScore += 0.4;
    }

    if (hasHealthConcern && reflectionMatches > 0) {
      askScore += 0.2;
      journalScore += 0.3;
    }

    return {
      'ask': askScore.clamp(0.0, 1.0),
      'journal': journalScore.clamp(0.0, 1.0),
    };
  }

  bool _detectHealthConcern(String input) {
    final keywords = [
      'sick',
      'ill',
      'fever',
      'pain',
      'ache',
      'cough',
      'nausea',
      'dizzy',
      'infection',
      'headache',
      'migraine',
      'stomach',
      'throat',
      'cold',
      'flu',
    ];
    return keywords.any((keyword) => input.contains(keyword));
  }

  double _mapMLConfidenceToAsk(SearchIntentResult intentResult) {
    switch (intentResult.intent) {
      case SearchIntent.askStarbound:
      case SearchIntent.healthForecast:
        return intentResult.confidence;
      default:
        return 0.0;
    }
  }

  double _mapMLConfidenceToJournal(SearchIntentResult intentResult) {
    switch (intentResult.intent) {
      case SearchIntent.journal:
        return intentResult.confidence;
      default:
        return 0.0;
    }
  }

  double _blendScores(
    double heuristicScore,
    double mlScore, {
    double heuristicWeight = 0.7,
  }) {
    final mlWeight = 1.0 - heuristicWeight;
    if (mlScore <= 0.0) {
      return heuristicScore.clamp(0.0, 1.0);
    }
    return (heuristicScore * heuristicWeight + mlScore * mlWeight)
        .clamp(0.0, 1.0);
  }

  SmartRouteIntent _selectRoute({
    required double askScore,
    required double journalScore,
    required double guidedScore,
  }) {
    const double highConfidence = 0.7;
    const double mixedThreshold = 0.55;
    const double guidedThreshold = 0.6;

    final bool askHigh = askScore >= highConfidence;
    final bool journalHigh = journalScore >= highConfidence;
    final bool guidedHigh = guidedScore >= guidedThreshold;

    if (askHigh && journalHigh) {
      return SmartRouteIntent.both;
    }

    if (askHigh && journalScore >= mixedThreshold) {
      return SmartRouteIntent.both;
    }

    if (journalHigh && askScore >= mixedThreshold) {
      return SmartRouteIntent.both;
    }

    if (askHigh) {
      return SmartRouteIntent.ask;
    }

    if (guidedHigh && !askHigh) {
      return SmartRouteIntent.guidedJournal;
    }

    if (journalHigh) {
      return SmartRouteIntent.journal;
    }

    return SmartRouteIntent.clarify;
  }

  SmartRouteIntent _selectRouteWithOverrides({
    required String input,
    required InputTags tags,
    required double askScore,
    required double journalScore,
    required double guidedScore,
  }) {
    final normalized = input.toLowerCase().trim();
    final bool isQuestion = tags.isQuestion;
    final bool isReflective =
        _isReflectiveStatement(normalized, tags, journalScore);
    final bool isOverwhelmed = _detectOverwhelm(normalized, tags);
    final bool isVagueQuestion = _isVagueQuestion(normalized);

    if (isQuestion) {
      if (isOverwhelmed && isVagueQuestion) {
        return SmartRouteIntent.guidedJournal;
      }
      return SmartRouteIntent.ask;
    }

    if (isReflective) {
      return SmartRouteIntent.guidedJournal;
    }

    return _selectRoute(
      askScore: askScore,
      journalScore: journalScore,
      guidedScore: guidedScore,
    );
  }

  double _scoreGuidedJournal(
    String input,
    InputTags tags,
    double journalScore,
  ) {
    final normalized = input.toLowerCase().trim();
    double score = journalScore;

    final guidedKeywords = [
      'guided',
      'check in',
      'check-in',
      'checkin',
      'journal',
      'journaling',
      'log',
      'reflect',
      'reflection',
      'prompt',
      'check in with',
    ];
    if (guidedKeywords.any((keyword) => normalized.contains(keyword))) {
      score = score < 0.75 ? 0.75 : score + 0.1;
    }

    if (!tags.isQuestion) {
      score += 0.1;
    }

    if (normalized.length > 12 && normalized.length < 320) {
      score += 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  bool _isReflectiveStatement(
    String input,
    InputTags tags,
    double journalScore,
  ) {
    if (tags.isQuestion) return false;
    if (journalScore >= 0.3) return true;
    if (tags.emotions.isNotEmpty || tags.healthTopics.isNotEmpty) {
      return true;
    }
    if (_containsFirstPerson(input) && input.length >= 8) {
      return true;
    }
    if (_containsTimeAnchor(input)) {
      return true;
    }
    return false;
  }

  bool _containsFirstPerson(String input) {
    final phrases = ['i ', "i'm", "i’ve", "i've", 'my ', 'me '];
    return phrases.any((phrase) => input.contains(phrase));
  }

  bool _containsTimeAnchor(String input) {
    const anchors = [
      'today',
      'yesterday',
      'last night',
      'this morning',
      'this week',
      'recently',
      'lately',
    ];
    return anchors.any((anchor) => input.contains(anchor));
  }

  bool _detectOverwhelm(String input, InputTags tags) {
    const keywords = [
      'overwhelmed',
      'cant cope',
      "can't cope",
      'burned out',
      'burnt out',
      'no energy',
      'exhausted',
      'too much',
      'cant handle',
      "can't handle",
      'at capacity',
      'drowning',
      'no bandwidth',
      'no capacity',
      'brain fog',
      'drained',
    ];
    if (keywords.any((keyword) => input.contains(keyword))) {
      return true;
    }
    final hasTired = tags.emotions.contains('tired');
    final hasAnxious = tags.emotions.contains('anxious');
    return hasTired && hasAnxious;
  }

  bool _isVagueQuestion(String input) {
    if (input.isEmpty) return true;
    const phrases = [
      'help',
      'help me',
      'any advice',
      'any ideas',
      'what should i do',
      'what do i do',
      'what now',
      'not sure',
      'idk',
      "i don't know",
      'can you help',
      'should i',
      'thoughts',
      'advice',
    ];
    if (phrases.any((phrase) => input.contains(phrase))) {
      return true;
    }
    return input.length <= 40;
  }

  double _deriveConfidence(double askScore, double journalScore) {
    return (askScore >= journalScore ? askScore : journalScore)
        .clamp(0.0, 1.0);
  }

  String _buildRoutingReasoning({
    required double askScore,
    required double journalScore,
    required SearchIntent mlIntent,
    required double mlConfidence,
    required String mlReasoning,
    required SmartRouteIntent routing,
  }) {
    return 'Routing=$routing ask=$askScore journal=$journalScore | '
        'ML=$mlIntent (${mlConfidence.toStringAsFixed(2)}): $mlReasoning';
  }
  
  // Cache management methods
  String _getCacheKey(String input) {
    return input.trim().toLowerCase();
  }
  
  SmartInputResult? _getCachedResult(String cacheKey) {
    final cached = _intentCache[cacheKey];
    if (cached == null || cached.isExpired) {
      _intentCache.remove(cacheKey);
      return null;
    }
    return cached.result;
  }
  
  void _cacheResult(String cacheKey, SmartInputResult result) {
    // Clean up old cache entries if we're at max size
    if (_intentCache.length >= _cacheMaxSize) {
      final oldestKey = _intentCache.keys.first;
      _intentCache.remove(oldestKey);
    }
    
    _intentCache[cacheKey] = _CachedResult(result, DateTime.now());
  }
  
  /// Clear the intent cache
  void clearCache() {
    _intentCache.clear();
    debugPrint('🧹 Smart input cache cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final expired = _intentCache.values.where((cached) => cached.isExpired).length;
    final active = _intentCache.length - expired;
    
    return {
      'total_entries': _intentCache.length,
      'active_entries': active,
      'expired_entries': expired,
      'cache_hit_potential': active > 0 ? '${(active / _cacheMaxSize * 100).toStringAsFixed(1)}%' : '0%',
    };
  }
}

/// Internal class for caching results
class _CachedResult {
  final SmartInputResult result;
  final DateTime timestamp;
  
  _CachedResult(this.result, this.timestamp);
  
  bool get isExpired => DateTime.now().difference(timestamp) > SmartInputService._cacheDuration;
}
