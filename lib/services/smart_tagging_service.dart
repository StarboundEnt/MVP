import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'gemma_ai_service.dart';
import '../models/smart_tag_model.dart';

/// Result of smart tagging analysis
class SmartTaggingResult {
  final String originalText;
  final List<SmartTag> smartTags;
  final DateTime timestamp;
  final bool isValid;
  final String? error;
  final double averageConfidence;
  final List<FollowUpQuestion> suggestedFollowUps;
  final List<ContextualSuggestion> contextualSuggestions;

  const SmartTaggingResult({
    required this.originalText,
    required this.smartTags,
    required this.timestamp,
    this.isValid = true,
    this.error,
    required this.averageConfidence,
    this.suggestedFollowUps = const [],
    this.contextualSuggestions = const [],
  });

  bool get hasHighConfidenceTags =>
      smartTags.any((tag) => tag.isHighConfidence);
  bool get hasSmartTags => smartTags.isNotEmpty;
  bool get hasContextualSuggestions => contextualSuggestions.isNotEmpty;
  bool get hasHighRelevanceSuggestions =>
      contextualSuggestions.any((s) => s.isHighRelevance);
  int get choiceCount => smartTags.where((t) => t.isChoice).length;
  int get chanceCount => smartTags.where((t) => t.isChance).length;
  int get outcomeCount => smartTags.where((t) => t.isOutcome).length;
  int get suggestionCount => contextualSuggestions.length;

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'smartTags': smartTags.map((t) => t.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'isValid': isValid,
      'error': error,
      'averageConfidence': averageConfidence,
      'suggestedFollowUps': suggestedFollowUps.map((q) => q.toJson()).toList(),
      'contextualSuggestions':
          contextualSuggestions.map((s) => s.toJson()).toList(),
    };
  }
}

/// Service for smart tagging using canonical ontology
class SmartTaggingService {
  static final SmartTaggingService _instance = SmartTaggingService._internal();
  factory SmartTaggingService() => _instance;
  SmartTaggingService._internal();

  final GemmaAIService _aiService = GemmaAIService();

  // Cache for frequently used patterns
  final Map<String, SmartTaggingResult> _tagCache = {};
  static const int _maxCacheSize = 100;

  // Daily follow-up tracking
  final Map<String, int> _dailyFollowUpCounts = {}; // date -> count
  static const int _maxDailyFollowUps = 3;

  /// Initialize the service
  Future<bool> initialize() async {
    try {
      await _aiService.initialize();
      return _aiService.isInitialized;
    } catch (e) {
      debugPrint('SmartTaggingService: Failed to initialize AI service: $e');
      return false;
    }
  }

  bool get isReady => _aiService.isInitialized;

  /// Analyze text and return smart tags with follow-up questions
  Future<SmartTaggingResult> analyzeText(String input) async {
    if (input.trim().isEmpty) {
      return SmartTaggingResult(
        originalText: input,
        smartTags: [],
        timestamp: DateTime.now(),
        isValid: false,
        error: 'Input is empty',
        averageConfidence: 0.0,
      );
    }

    // Check cache first
    final cacheKey = input.toLowerCase().trim();
    if (_tagCache.containsKey(cacheKey)) {
      return _tagCache[cacheKey]!;
    }

    try {
      final result = await _analyzeWithAI(input);

      // Cache the result
      if (_tagCache.length >= _maxCacheSize) {
        _tagCache.remove(_tagCache.keys.first);
      }
      _tagCache[cacheKey] = result;

      return result;
    } catch (e) {
      debugPrint('SmartTaggingService: Analysis failed: $e');

      // Fallback to rule-based tagging
      return _fallbackTagging(input);
    }
  }

  /// Analyze input using AI service with canonical ontology
  Future<SmartTaggingResult> _analyzeWithAI(String input) async {
    if (!_aiService.isInitialized) {
      throw Exception('AI service not initialized');
    }

    final prompt = _buildSmartTaggingPrompt(input);
    final response = await _aiService.generateResponse(prompt);

    if (response.isEmpty) {
      throw Exception('AI service returned empty response');
    }

    return await _parseAITaggingResponse(input, response);
  }

  /// Build comprehensive prompting for smart tagging with canonical ontology
  String _buildSmartTaggingPrompt(String input) {
    final buffer = StringBuffer()
      ..writeln('Analyze this journal entry and extract smart tags using our ')
      ..writeln(
          'curated canonical ontology. Provide multi-layer classification ')
      ..writeln('with confidence scores, evidence spans, sentiment, and ')
      ..writeln('supporting keywords.')
      ..writeln()
      ..writeln('Input: "$input"')
      ..writeln()
      ..writeln('CANONICAL ONTOLOGY (use ONLY these canonicalKey values):');

    const categoryHeaders = {
      'choice': '🔷 CHOICE (User Actions & Decisions)',
      'chance': '🔶 CHANCE (Context & Conditions)',
      'outcome': '📊 OUTCOME (States & Signals)',
    };

    CanonicalOntology.structure.forEach((category, subdomains) {
      buffer
        ..writeln()
        ..writeln(categoryHeaders[category] ?? category.toUpperCase());
      subdomains.forEach((subdomain, keys) {
        buffer
          ..writeln('$subdomain:')
          ..writeln('- ${keys.join(', ')}');
      });
    });

    buffer
      ..writeln()
      ..writeln('ANALYSIS REQUIREMENTS:')
      ..writeln('1. Extract 1-5 relevant canonical tags with evidence spans')
      ..writeln('2. Provide confidence (0.0-1.0) for each tag')
      ..writeln(
          '3. Include sentiment (positive/negative/neutral) with confidence')
      ..writeln(
          "4. Flag negation (didn't, wasn't, couldn't) and uncertainty (maybe, might)")
      ..writeln('5. Extract supporting keywords (max 5)')
      ..writeln('6. Suggest optional follow-up questions tied to specific tags')
      ..writeln(
          '7. Use Australian spelling and a neutral, non-anthropomorphic tone')
      ..writeln()
      ..writeln('Respond with ONLY valid JSON in this format:')
      ..writeln('{')
      ..writeln('  "smartTags": [')
      ..writeln('    {')
      ..writeln('      "canonicalKey": "movement_boost",')
      ..writeln(
          '      "displayName": "${CanonicalOntology.getDisplayName('movement_boost')}",')
      ..writeln('      "category": "choice",')
      ..writeln('      "subdomain": "Movement & Energy",')
      ..writeln('      "confidence": 0.85,')
      ..writeln('      "evidenceSpan": "took a 20-minute walk after lunch",')
      ..writeln('      "sentiment": "positive",')
      ..writeln('      "sentimentConfidence": 0.9,')
      ..writeln('      "keywords": ["walk", "20-minute", "movement"],')
      ..writeln('      "hasNegation": false,')
      ..writeln('      "hasUncertainty": false,')
      ..writeln('      "metadata": {')
      ..writeln('        "intensity": "light",')
      ..writeln('        "duration": "20 minutes"')
      ..writeln('      }')
      ..writeln('    }')
      ..writeln('  ],')
      ..writeln('  "followUpQuestions": [')
      ..writeln('    {')
      ..writeln(
          '      "question": "What helped you make time for movement today?",')
      ..writeln('      "triggerTagKey": "movement_boost",')
      ..writeln('      "type": "multipleChoice",')
      ..writeln(
          '      "suggestedResponses": ["Scheduled it", "Motivation", "Accountability", "Other"],')
      ..writeln('      "priority": 2')
      ..writeln('    }')
      ..writeln('  ]')
      ..writeln('}')
      ..writeln()
      ..writeln(
          'Extract only tags from the ontology. If nothing fits, return an empty array.');

    return buffer.toString();
  }

  /// Parse AI response into smart tagging result
  Future<SmartTaggingResult> _parseAITaggingResponse(
      String originalText, String aiResponse) async {
    try {
      // Clean up the response - sometimes AI adds extra text
      String jsonStr = aiResponse.trim();

      // Find JSON object in the response
      final startIndex = jsonStr.indexOf('{');
      final endIndex = jsonStr.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1) {
        throw Exception('No valid JSON found in AI response');
      }

      jsonStr = jsonStr.substring(startIndex, endIndex + 1);

      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;

      // Parse smart tags
      final smartTagsJson = jsonMap['smartTags'] as List<dynamic>? ?? [];
      final smartTags = smartTagsJson
          .cast<Map<String, dynamic>>()
          .map((item) => _parseSmartTagFromJson(item))
          .where((tag) => tag != null)
          .cast<SmartTag>()
          .toList();

      // Parse follow-up questions
      final followUpsJson =
          jsonMap['followUpQuestions'] as List<dynamic>? ?? [];
      final followUps = followUpsJson
          .cast<Map<String, dynamic>>()
          .map((item) => _parseFollowUpFromJson(item))
          .where((q) => q != null)
          .cast<FollowUpQuestion>()
          .toList();

      // Filter follow-ups based on daily limit
      final filteredFollowUps = _filterFollowUpsByDailyLimit(followUps);

      // Generate contextual suggestions based on smart tags
      final contextualSuggestions =
          await _generateContextualSuggestions(originalText, smartTags);

      final averageConfidence = smartTags.isEmpty
          ? 0.0
          : smartTags.map((t) => t.confidence).reduce((a, b) => a + b) /
              smartTags.length;

      return SmartTaggingResult(
        originalText: originalText,
        smartTags: smartTags,
        timestamp: DateTime.now(),
        isValid: true,
        averageConfidence: averageConfidence,
        suggestedFollowUps: filteredFollowUps,
        contextualSuggestions: contextualSuggestions,
      );
    } catch (e) {
      debugPrint('SmartTaggingService: Failed to parse AI response: $e');
      debugPrint('AI Response: $aiResponse');

      // Fallback to rule-based tagging
      return _fallbackTagging(originalText);
    }
  }

  /// Parse smart tag from JSON with validation
  SmartTag? _parseSmartTagFromJson(Map<String, dynamic> json) {
    try {
      final resolvedKey = CanonicalOntology.resolveCanonicalKey(
          json['canonicalKey'] as String?);
      if (resolvedKey == null) {
        return null;
      }

      final resolvedCategory = CanonicalOntology.getCategory(resolvedKey) ??
          TagCategory.values.firstWhere(
            (e) => e.name == json['category'],
            orElse: () => TagCategory.choice,
          );

      return SmartTag.fromAIClassification(
        canonicalKey: resolvedKey,
        displayName: json['displayName'] ??
            CanonicalOntology.getDisplayName(resolvedKey),
        category: resolvedCategory,
        subdomain: CanonicalOntology.getSubdomain(resolvedKey) ??
            json['subdomain'] ??
            '',
        confidence: (json['confidence'] ?? 0.0).toDouble(),
        evidenceSpan: json['evidenceSpan'],
        metadata: json['metadata'] ?? {},
        sentiment: json['sentiment'] ?? 'neutral',
        sentimentConfidence: (json['sentimentConfidence'] ?? 0.0).toDouble(),
        keywords: List<String>.from(json['keywords'] ?? []),
        hasNegation: json['hasNegation'] ?? false,
        hasUncertainty: json['hasUncertainty'] ?? false,
      );
    } catch (e) {
      debugPrint('SmartTaggingService: Failed to parse smart tag: $e');
      return null;
    }
  }

  /// Parse follow-up question from JSON
  FollowUpQuestion? _parseFollowUpFromJson(Map<String, dynamic> json) {
    try {
      final question = json['question'] as String?;
      final triggerTagKey = json['triggerTagKey'] as String?;

      if (question == null || question.isEmpty || triggerTagKey == null)
        return null;

      return FollowUpQuestion(
        id: '${DateTime.now().millisecondsSinceEpoch}_${triggerTagKey}',
        question: question,
        triggerTagKey: triggerTagKey,
        type: QuestionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => QuestionType.openText,
        ),
        suggestedResponses: List<String>.from(json['suggestedResponses'] ?? []),
        priority: json['priority'] ?? 1,
        createdAt: DateTime.now(),
        expiresAt:
            DateTime.now().add(const Duration(hours: 24)), // 24-hour expiry
      );
    } catch (e) {
      debugPrint('SmartTaggingService: Failed to parse follow-up question: $e');
      return null;
    }
  }

  /// Filter follow-up questions by daily limit
  List<FollowUpQuestion> _filterFollowUpsByDailyLimit(
      List<FollowUpQuestion> questions) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final currentCount = _dailyFollowUpCounts[today] ?? 0;

    if (currentCount >= _maxDailyFollowUps) {
      return []; // No more follow-ups today
    }

    // Sort by priority and take only what we can fit
    final remaining = _maxDailyFollowUps - currentCount;
    final sortedQuestions = questions
      ..sort((a, b) => b.priority.compareTo(a.priority));
    final filtered = sortedQuestions.take(remaining).toList();

    // Update count
    _dailyFollowUpCounts[today] = currentCount + filtered.length;

    return filtered;
  }

  /// Fallback rule-based tagging when AI fails
  SmartTaggingResult _fallbackTagging(String input) {
    final smartTags = <SmartTag>[];
    final lowerInput = input.toLowerCase();

    // Simple keyword mapping to canonical tags
    final keywordMappings = {
      // Choice tags
      'movement_boost': ['walk', 'run', 'exercise', 'gym', 'workout', 'moved'],
      'energy_plan': [
        'energy plan',
        'pace myself',
        'planned breaks',
        'manage energy'
      ],
      'rest_day': ['rest day', 'took a break', 'day off', 'recovery day'],
      'mindful_break': [
        'mindful',
        'present',
        'meditate',
        'journaling',
        'reflect'
      ],
      'breathing_reset': [
        'breathe',
        'breathing exercise',
        'deep breath',
        'box breathing'
      ],
      'digital_detox': [
        'digital detox',
        'offline',
        'logged off',
        'away from screens'
      ],
      'reset_routine': ['reset routine', 'back on track', 'fresh start'],
      'balanced_meal': [
        'ate well',
        'healthy meal',
        'balanced meal',
        'nutritious'
      ],
      'hydration_reset': ['water', 'hydrated', 'drink', 'drank', 'sipped'],
      'sleep_hygiene': [
        'sleep routine',
        'lights out',
        'early night',
        'bedtime'
      ],
      'self_compassion': [
        'self-compassion',
        'gentle with myself',
        'kind to myself'
      ],
      'social_checkin': [
        'checked in',
        'caught up',
        'called',
        'message',
        'talked'
      ],
      'gratitude_moment': ['grateful', 'gratitude', 'thankful'],
      'creative_play': ['creative', 'sketched', 'music', 'play'],
      'focus_sprint': ['focus sprint', 'deep work', 'concentrated'],

      // Chance tags
      'busy_day': ['busy day', 'back-to-back', 'nonstop'],
      'time_pressure': ['time pressure', 'deadline', 'ran out of time'],
      'deadline_mode': ['deadline mode', 'crunch', 'due soon'],
      'unexpected_event': ['unexpected', 'surprise', 'sudden'],
      'travel_disruption': ['travel', 'commute', 'transport', 'bus', 'traffic'],
      'workspace_shift': [
        'new desk',
        'workspace',
        'office change',
        'work from home'
      ],
      'weather_slump': ['rainy', 'weather', 'cold day', 'heatwave'],
      'nature_time': ['nature', 'park', 'outside'],
      'supportive_chat': [
        'support',
        'therapist',
        'counsellor',
        'talked through'
      ],
      'family_duty': ['family duty', 'caring for', 'looked after'],
      'morning_check': ['this morning', 'morning check', 'start of the day'],
      'midday_reset': ['midday', 'lunch break', 'afternoon reset'],
      'evening_reflection': ['evening', 'tonight', 'end of the day'],

      // Outcome tags
      'calm_grounded': ['calm', 'grounded', 'steady'],
      'hopeful': ['hopeful', 'optimistic'],
      'relief': ['relieved', 'relief'],
      'balanced': ['balanced', 'even keel'],
      'overwhelmed': ['overwhelmed', 'too much'],
      'lonely': ['lonely', 'isolated'],
      'anxious_underlying': ['anxious', 'worried', 'uneasy'],
      'energized': ['energised', 'energetic', 'buzzing'],
      'drained': ['tired', 'exhausted', 'drained'],
      'restless': ['restless', 'antsy'],
      'foggy': ['foggy', 'blurry', 'couldn\'t think'],
      'proud_progress': ['proud', 'progress'],
      'micro_win': ['small win', 'tiny win', 'micro win'],
      'setback': ['setback', 'slipped', 'off track'],
      'learning': ['learned', 'lesson'],
      'habit_chain': ['streak', 'chain', 'kept going'],
      'first_step': ['first step', 'got started'],
      'need_rest': ['need rest', 'need break', 'body needs rest'],
      'need_connection': ['need connection', 'need people'],
      'need_fuel': ['need food', 'need fuel', 'need to eat'],
      'need_clarity': ['need clarity', 'unsure', 'confused'],
    };

    for (final entry in keywordMappings.entries) {
      final canonicalKey = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        final regex = RegExp('\\b${RegExp.escape(keyword)}\\b');
        if (regex.hasMatch(lowerInput)) {
          final category =
              CanonicalOntology.getCategory(canonicalKey) ?? TagCategory.choice;
          final subdomain =
              CanonicalOntology.getSubdomain(canonicalKey) ?? 'General';

          // Simple sentiment detection
          String sentiment = 'neutral';
          if (lowerInput
              .contains(RegExp(r'\b(good|great|happy|love|enjoy)\b'))) {
            sentiment = 'positive';
          } else if (lowerInput
              .contains(RegExp(r'\b(bad|terrible|hate|difficult|hard)\b'))) {
            sentiment = 'negative';
          }

          smartTags.add(SmartTag.fromAIClassification(
            canonicalKey: canonicalKey,
            displayName: CanonicalOntology.getDisplayName(canonicalKey),
            category: category,
            subdomain: subdomain,
            confidence: 0.6, // Lower confidence for rule-based
            evidenceSpan: _extractEvidenceSpan(input, keyword),
            sentiment: sentiment,
            sentimentConfidence: 0.5,
            keywords: [keyword],
            hasNegation: lowerInput
                .contains(RegExp(r'\b(not|didnt|wasnt|couldnt|no)\b')),
            hasUncertainty: lowerInput
                .contains(RegExp(r'\b(maybe|might|perhaps|possibly)\b')),
            metadata: {'method': 'rule-based'},
          ));
          break; // Only one match per canonical key
        }
      }
    }

    final averageConfidence = smartTags.isEmpty
        ? 0.0
        : smartTags.map((t) => t.confidence).reduce((a, b) => a + b) /
            smartTags.length;

    return SmartTaggingResult(
      originalText: input,
      smartTags: smartTags,
      timestamp: DateTime.now(),
      isValid: true,
      averageConfidence: averageConfidence,
    );
  }

  /// Extract evidence span around a keyword
  String _extractEvidenceSpan(String text, String keyword) {
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    final index = lowerText.indexOf(lowerKeyword);

    if (index == -1) return text.substring(0, min(50, text.length));

    final start = max(0, index - 20);
    final end = min(text.length, index + keyword.length + 20);

    return text.substring(start, end).trim();
  }

  /// Generate follow-up question for a tag
  FollowUpQuestion? generateFollowUpQuestion(SmartTag tag) {
    // Basic follow-up question templates based on canonical keys
    final questionTemplates = {
      'movement_boost': {
        'question': 'How did that movement shift your energy?',
        'responses': [
          'Energised',
          'Grounded',
          'A little tired',
          'Still unsure'
        ],
        'type': QuestionType.multipleChoice,
      },
      'sleep_hygiene': {
        'question': 'What helped your wind-down routine tonight?',
        'responses': ['Lighting', 'No screens', 'Breathing', 'Something else'],
        'type': QuestionType.multipleChoice,
      },
      'anxious_underlying': {
        'question': 'What usually helps soften that anxious feeling?',
        'responses': [
          'Breathing',
          'Movement',
          'Talking to someone',
          'Planning one step'
        ],
        'type': QuestionType.multipleChoice,
      },
      'time_pressure': {
        'question': 'What would take the edge off the time pressure right now?',
        'responses': [
          'Clarify priorities',
          'Delegate',
          'Micro-break',
          'Note it down'
        ],
        'type': QuestionType.multipleChoice,
      },
      'need_connection': {
        'question': 'Who could you check in with after this entry?',
        'responses': ['Friend', 'Family', 'Support person', 'No-one right now'],
        'type': QuestionType.multipleChoice,
      },
    };

    final template = questionTemplates[tag.canonicalKey];
    if (template == null) return null;

    return FollowUpQuestion(
      id: '${DateTime.now().millisecondsSinceEpoch}_${tag.canonicalKey}',
      question: template['question'] as String,
      triggerTagKey: tag.canonicalKey,
      type: template['type'] as QuestionType,
      suggestedResponses: template['responses'] as List<String>,
      priority: tag.isHighConfidence ? 3 : 1,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  /// Generate contextual suggestions based on smart tags and original text
  Future<List<ContextualSuggestion>> _generateContextualSuggestions(
      String originalText, List<SmartTag> smartTags) async {
    if (smartTags.isEmpty) return [];

    try {
      final suggestions = <ContextualSuggestion>[];
      final now = DateTime.now();
      final timeOfDay = now.hour;

      // Process tags by priority (high confidence first)
      final sortedTags = smartTags
          .where((tag) => tag.confidence >= 0.4)
          .toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));

      for (final tag in sortedTags.take(3)) {
        // Limit to top 3 tags
        final tagSuggestions =
            await _generateSuggestionsForTag(tag, originalText, timeOfDay);
        suggestions.addAll(tagSuggestions);
      }

      // Add contextual time-based suggestions
      if (timeOfDay >= 6 && timeOfDay < 12) {
        suggestions
            .addAll(_generateMorningSuggestions(smartTags, originalText));
      } else if (timeOfDay >= 18 && timeOfDay <= 23) {
        suggestions
            .addAll(_generateEveningSuggestions(smartTags, originalText));
      }

      // Sort by relevance score and limit to 5
      suggestions.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      return suggestions.take(5).toList();
    } catch (e) {
      debugPrint('Failed to generate contextual suggestions: $e');
      return [];
    }
  }

  /// Generate specific suggestions for a smart tag
  Future<List<ContextualSuggestion>> _generateSuggestionsForTag(
      SmartTag tag, String originalText, int timeOfDay) async {
    final suggestions = <ContextualSuggestion>[];
    final timestamp = DateTime.now();

    // Tag-specific suggestion templates
    final tagSuggestionMap = _getTagSuggestionTemplates();
    final template = tagSuggestionMap[tag.canonicalKey];

    if (template != null) {
      // Create immediate suggestion based on sentiment
      String title = template['title'] as String;
      String description = template['description'] as String;
      String actionText = template['action'] as String;

      // Adjust based on sentiment and negation
      if (tag.hasNegation || tag.sentiment == 'negative') {
        title = template['supportive_title'] as String? ?? title;
        description =
            template['supportive_description'] as String? ?? description;
        actionText = template['supportive_action'] as String? ?? actionText;
      }

      // Add contextual reference to user's specific situation
      final contextualDescription =
          _personalizeDescription(description, originalText, tag);

      suggestions.add(ContextualSuggestion(
        id: '${tag.id}_immediate',
        title: title,
        description: contextualDescription,
        actionText: actionText,
        category: 'immediate',
        relevanceScore: _calculateRelevanceScore(tag, timeOfDay),
        triggerTagKeys: [tag.canonicalKey],
        metadata: {
          'tag_confidence': tag.confidence,
          'sentiment': tag.sentiment,
          'time_sensitive': timeOfDay >= 6 && timeOfDay <= 23,
        },
        createdAt: timestamp,
      ));
    }

    return suggestions;
  }

  /// Generate time-appropriate morning suggestions
  List<ContextualSuggestion> _generateMorningSuggestions(
      List<SmartTag> tags, String originalText) {
    final suggestions = <ContextualSuggestion>[];
    final hasEnergyTags = tags.any((t) => {
          'energized',
          'drained',
          'energy_plan',
          'movement_boost',
          'rest_day'
        }.contains(t.canonicalKey));
    final hasSleepTags = tags.any((t) => t.canonicalKey == 'sleep_hygiene');

    if (hasEnergyTags || hasSleepTags) {
      suggestions.add(ContextualSuggestion(
        id: 'morning_energy_boost',
        title: 'Morning Energy Boost',
        description: 'Start your day with a gentle energy lift',
        actionText: 'Try 2 minutes of stretching or step outside for fresh air',
        category: 'immediate',
        relevanceScore: 0.7,
        triggerTagKeys: tags.map((t) => t.canonicalKey).toList(),
        metadata: {'time_context': 'morning', 'energy_focused': true},
        createdAt: DateTime.now(),
      ));
    }

    return suggestions;
  }

  /// Generate time-appropriate evening suggestions
  List<ContextualSuggestion> _generateEveningSuggestions(
      List<SmartTag> tags, String originalText) {
    final suggestions = <ContextualSuggestion>[];
    final hasStressTags = tags.any((t) => {
          'anxious_underlying',
          'overwhelmed',
          'time_pressure'
        }.contains(t.canonicalKey));

    if (hasStressTags) {
      suggestions.add(ContextualSuggestion(
        id: 'evening_wind_down',
        title: 'Evening Wind Down',
        description: 'Let go of today\'s stress before rest',
        actionText:
            'Try 3 deep breaths or write down one thing that went well today',
        category: 'immediate',
        relevanceScore: 0.8,
        triggerTagKeys: tags.map((t) => t.canonicalKey).toList(),
        metadata: {'time_context': 'evening', 'stress_focused': true},
        createdAt: DateTime.now(),
      ));
    }

    return suggestions;
  }

  /// Personalize suggestion description with user context
  String _personalizeDescription(
      String template, String originalText, SmartTag tag) {
    // Extract key phrases from original text for personalization
    final words = originalText.toLowerCase().split(' ');
    final contextWords = words
        .where((w) =>
            w.length > 4 &&
            !['that', 'this', 'with', 'have', 'been', 'were'].contains(w))
        .take(2)
        .join(' ');

    if (contextWords.isNotEmpty && tag.evidenceSpan != null) {
      return template.replaceFirst(
          '${tag.displayName.toLowerCase()}', 'your "${tag.evidenceSpan}"');
    }

    return template;
  }

  /// Calculate relevance score for a suggestion
  double _calculateRelevanceScore(SmartTag tag, int timeOfDay) {
    double score = tag.confidence;

    // Boost score for high confidence tags
    if (tag.confidence >= 0.8) score += 0.1;

    // Boost score for immediate action tags during active hours
    if (timeOfDay >= 8 && timeOfDay <= 20) {
      if (tag.isChoice && !tag.hasNegation) score += 0.1;
    }

    // Boost score for negative sentiment (more urgent)
    if (tag.sentiment == 'negative' || tag.hasNegation) {
      score += 0.15;
    }

    return (score * 10).round() / 10.0; // Round to 1 decimal place
  }

  /// Get suggestion templates for different tags
  Map<String, Map<String, String>> _getTagSuggestionTemplates() {
    return {
      'anxious_underlying': {
        'title': 'Quick Calm',
        'description': 'Take a moment to centre yourself',
        'action': 'Try 4-7-8 breathing: inhale 4, hold 7, exhale 8',
        'supportive_title': 'Gentle Grounding',
        'supportive_description':
            'It\'s okay to feel on edge—let\'s soften it a little',
        'supportive_action':
            'Place a hand on your chest and name three things you can see',
      },
      'drained': {
        'title': 'Energy Reset',
        'description': 'Give yourself a gentle energy boost',
        'action':
            'Stand up and do 5 gentle arm circles or drink a glass of water',
        'supportive_title': 'Rest is Valid',
        'supportive_description':
            'Your body is telling you something important',
        'supportive_action':
            'Find a comfortable position and rest for 5 minutes',
      },
      'movement_boost': {
        'title': 'Movement Momentum',
        'description': 'Build on your activity with gentle movement',
        'action': 'Add 2 minutes of stretching or a short walk',
        'supportive_title': 'Every Step Counts',
        'supportive_description': 'Moving your body in any way is valuable',
        'supportive_action':
            'Try gentle neck rolls or shoulder shrugs where you are',
      },
      'sleep_hygiene': {
        'title': 'Sleep Success',
        'description': 'Support your wind-down routine tonight',
        'action':
            'Dim the lights and step away from screens 30 minutes before bed',
        'supportive_title': 'Sleep Support',
        'supportive_description':
            'Let\'s work toward better rest, one cue at a time',
        'supportive_action': 'Note one thing that helps you ease into sleep',
      },
      'time_pressure': {
        'title': 'Ease The Pace',
        'description': 'A tiny plan can relieve the pressure',
        'action': 'List the next micro-step that keeps today moving',
        'supportive_title': 'Breathe First',
        'supportive_description':
            'Slow is smooth—give yourself a calm starting point',
        'supportive_action':
            'Take three slow breaths before choosing the next task',
      },
      'balanced_meal': {
        'title': 'Nourish Yourself',
        'description': 'Fuel your body with something supportive',
        'action': 'Plan your next meal with colour, protein, and hydration',
        'supportive_title': 'Gentle Nourishment',
        'supportive_description':
            'Even a small snack counts towards caring for yourself',
        'supportive_action': 'Start with a glass of water and a quick snack',
      },
      'social_checkin': {
        'title': 'Stay Connected',
        'description': 'Lean into the support that\'s available',
        'action': 'Send a quick message to say thanks or share an update',
        'supportive_title': 'Reach Out',
        'supportive_description': 'It\'s okay to ask for help when you need it',
        'supportive_action': 'Name one person who feels safe to contact',
      },
      'need_rest': {
        'title': 'Rest Signal',
        'description': 'Your body is asking for downtime',
        'action': 'Block out 10 minutes to lie down or stretch gently',
        'supportive_title': 'Permission To Pause',
        'supportive_description':
            'You deserve rest even if the to-do list is long',
        'supportive_action': 'Write one thing you can defer or delegate today',
      },
      'hopeful': {
        'title': 'Anchor The Hope',
        'description': 'Capture the spark so you can return to it later',
        'action': 'Write one sentence about what you\'re hopeful for',
        'supportive_title': 'Share The Light',
        'supportive_description': 'Let that hopeful feeling ripple outward',
        'supportive_action':
            'Send a kind note to someone while you have this energy',
      },
    };
  }

  /// Clear the cache
  void clearCache() {
    _tagCache.clear();
  }

  /// Reset daily follow-up counts (call at midnight)
  void resetDailyFollowUpCounts() {
    _dailyFollowUpCounts.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _tagCache.length,
      'maxSize': _maxCacheSize,
      'dailyFollowUpCounts': _dailyFollowUpCounts,
      'maxDailyFollowUps': _maxDailyFollowUps,
    };
  }
}
