import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'gemma_ai_service.dart';
import '../models/smart_tag_model.dart';

/// Represents a parsed segment from user input with multi-layer analysis
class ParsedSegment {
  final String text;
  final String category;
  final double confidence;
  final String type; // 'choice' or 'chance'
  final Map<String, dynamic> metadata;

  // New multi-layer analysis fields
  final String sentiment; // 'positive', 'negative', 'neutral'
  final List<String> themes; // Life domain tags
  final List<String> keywords; // Detected keywords
  final double sentimentConfidence;

  const ParsedSegment({
    required this.text,
    required this.category,
    required this.confidence,
    required this.type,
    this.metadata = const {},
    // New fields with defaults
    this.sentiment = 'neutral',
    this.themes = const [],
    this.keywords = const [],
    this.sentimentConfidence = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'category': category,
      'confidence': confidence,
      'type': type,
      'metadata': metadata,
      // New multi-layer fields
      'sentiment': sentiment,
      'themes': themes,
      'keywords': keywords,
      'sentimentConfidence': sentimentConfidence,
    };
  }

  factory ParsedSegment.fromJson(Map<String, dynamic> json) {
    return ParsedSegment(
      text: json['text'] ?? '',
      category: json['category'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      type: json['type'] ?? '',
      metadata: json['metadata'] ?? {},
      // New multi-layer fields with defaults
      sentiment: json['sentiment'] ?? 'neutral',
      themes: List<String>.from(json['themes'] ?? []),
      keywords: List<String>.from(json['keywords'] ?? []),
      sentimentConfidence: (json['sentimentConfidence'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() => 'ParsedSegment($text -> $category [$type])';
}

/// Result of parsing user input
class ParseResult {
  final String originalText;
  final List<ParsedSegment> segments;
  final DateTime timestamp;
  final bool isValid;
  final String? error;

  const ParseResult({
    required this.originalText,
    required this.segments,
    required this.timestamp,
    this.isValid = true,
    this.error,
  });

  bool get hasChoices => segments.any((s) => s.type == 'choice');
  bool get hasChances => segments.any((s) => s.type == 'chance');
  int get segmentCount => segments.length;

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'segments': segments.map((s) => s.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'isValid': isValid,
      'error': error,
    };
  }
}

/// Service for parsing natural language input into structured habit data
class TextParserService {
  static final TextParserService _instance = TextParserService._internal();
  factory TextParserService() => _instance;
  TextParserService._internal();

  final GemmaAIService _aiService = GemmaAIService();

  // Cache for frequently used patterns
  final Map<String, ParseResult> _parseCache = {};
  static const int _maxCacheSize = 50;

  // Social determinants framework structure
  static const Map<String, Map<String, List<String>>>
      socialDeterminantsFramework = {
    'chance': {
      'Economic Stability': [
        'employment_status',
        'job_loss',
        'job_insecurity',
        'stable_income',
        'financial_stress',
        'food_security',
        'food_insecurity',
        'housing_stability',
        'housing_instability'
      ],
      'Education Access & Quality': [
        'school_attendance',
        'school_disengagement',
        'literacy_level',
        'language_barriers',
        'higher_education_access'
      ],
      'Health Care Access & Quality': [
        'health_services_access',
        'health_insurance',
        'regular_gp',
        'health_literacy',
        'missed_appointments',
        'transport_to_health'
      ],
      'Neighbourhood & Built Environment': [
        'safe_housing',
        'unsafe_housing',
        'community_violence',
        'environmental_pollution',
        'clean_air_water',
        'public_transport',
        'transport_access',
        'healthy_food_outlets',
        'recreation_spaces'
      ],
      'Social & Community Context': [
        'social_support',
        'isolation_loneliness',
        'community_engagement',
        'discrimination',
        'incarceration_history',
        'peer_conflict',
        'civic_participation'
      ]
    },
    'choice': {
      'Nutrition & Hydration': [
        'balanced_meal',
        'skipping_meals',
        'junk_food',
        'whole_food_diet',
        'drinking_water',
        'dehydration'
      ],
      'Physical Activity': [
        'daily_movement',
        'exercise',
        'sedentary_lifestyle',
        'walking',
        'sports',
        'stretching',
        'yoga'
      ],
      'Restorative Sleep': [
        'quality_sleep',
        'poor_sleep',
        'insomnia',
        'napping',
        'oversleeping'
      ],
      'Stress Management & Mental Wellness': [
        'mindfulness',
        'meditation',
        'journaling',
        'therapy',
        'stress_coping',
        'burnout',
        'panic_attacks',
        'emotional_regulation'
      ],
      'Avoidance of Risky Substances': [
        'smoking',
        'vaping',
        'alcohol_use',
        'drug_use',
        'sobriety',
        'reducing_substances'
      ],
      'Social Connection': [
        'time_with_others',
        'reaching_for_help',
        'conflict_resolution',
        'feeling_connected',
        'avoiding_interaction',
        'voluntary_isolation'
      ]
    },
    'outcome': {
      'Mental Health': [
        'calm_mood',
        'happy_mood',
        'depression',
        'anxiety',
        'mood_swings',
        'stress_level',
        'emotional_exhaustion'
      ],
      'Physical Health': [
        'feeling_well',
        'fatigue',
        'low_energy',
        'pain',
        'injury',
        'illness_symptoms',
        'doctor_visit',
        'recovery'
      ]
    }
  };

  /// Get subdomain for a given tag
  static String? getSubdomainForTag(String tag) {
    for (final domain in socialDeterminantsFramework.values) {
      for (final subdomain in domain.keys) {
        if (domain[subdomain]!.contains(tag)) {
          return subdomain;
        }
      }
    }
    return null;
  }

  /// Get domain for a given tag
  static String? getDomainForTag(String tag) {
    for (final domainName in socialDeterminantsFramework.keys) {
      final domain = socialDeterminantsFramework[domainName]!;
      for (final subdomain in domain.values) {
        if (subdomain.contains(tag)) {
          return domainName;
        }
      }
    }
    return null;
  }

  /// Initialize the service
  Future<bool> initialize() async {
    try {
      await _aiService.initialize();
      return _aiService.isInitialized;
    } catch (e) {
      debugPrint('TextParserService: Failed to initialize AI service: $e');
      return false;
    }
  }

  bool get isReady => _aiService.isInitialized;

  /// Parse user input into structured segments
  Future<ParseResult> parseInput(String input) async {
    if (input.trim().isEmpty) {
      return ParseResult(
        originalText: input,
        segments: [],
        timestamp: DateTime.now(),
        isValid: false,
        error: 'Input is empty',
      );
    }

    // Check cache first
    final cacheKey = input.toLowerCase().trim();
    if (_parseCache.containsKey(cacheKey)) {
      return _parseCache[cacheKey]!;
    }

    try {
      final result = await _parseWithAI(input);

      // Cache the result
      if (_parseCache.length >= _maxCacheSize) {
        _parseCache.remove(_parseCache.keys.first);
      }
      _parseCache[cacheKey] = result;

      return result;
    } catch (e) {
      debugPrint('TextParserService: Parsing failed: $e');

      // Fallback to rule-based parsing
      return _fallbackParsing(input);
    }
  }

  /// Parse input using AI service
  Future<ParseResult> _parseWithAI(String input) async {
    if (!_aiService.isInitialized) {
      throw Exception('AI service not initialized');
    }

    final prompt = _buildParsingPrompt(input);
    final response = await _aiService.generateResponse(prompt);

    if (response.isEmpty) {
      throw Exception('AI service returned empty response');
    }

    return _parseAIResponse(input, response);
  }

  /// Build the parsing prompt for the AI with multi-layer analysis
  String _buildParsingPrompt(String input) {
    return '''
Analyze this daily update and extract habit-related segments. For each segment, provide multi-layer classification:

Input: "$input"

CLASSIFICATION LAYERS:
1. DOMAIN/TYPE: "chance" (external circumstances), "choice" (user actions), or "outcome" (resulting states)
2. SENTIMENT: "positive", "negative", or "neutral"
3. SUBDOMAIN & TAGS: Structured social determinants framework:

🎯 CHANCE (External Circumstances):
Economic Stability:
- employment_status, job_loss, job_insecurity, stable_income, financial_stress
- food_security, food_insecurity, housing_stability, housing_instability

Education Access & Quality:
- school_attendance, school_disengagement, literacy_level, language_barriers, higher_education_access

Health Care Access & Quality:
- health_services_access, health_insurance, regular_gp, health_literacy, missed_appointments, transport_to_health

Neighbourhood & Built Environment:
- safe_housing, unsafe_housing, community_violence, environmental_pollution
- clean_air_water, public_transport, transport_access, healthy_food_outlets, recreation_spaces

Social & Community Context:
- social_support, isolation_loneliness, community_engagement, discrimination
- incarceration_history, peer_conflict, civic_participation

💪 CHOICE (User Actions):
Nutrition & Hydration:
- balanced_meal, skipping_meals, junk_food, whole_food_diet, drinking_water, dehydration

Physical Activity:
- daily_movement, exercise, sedentary_lifestyle, walking, sports, stretching, yoga

Restorative Sleep:
- quality_sleep, poor_sleep, insomnia, napping, oversleeping

Stress Management & Mental Wellness:
- mindfulness, meditation, journaling, therapy, stress_coping, burnout, panic_attacks, emotional_regulation

Avoidance of Risky Substances:
- smoking, vaping, alcohol_use, drug_use, sobriety, reducing_substances

Social Connection:
- time_with_others, reaching_for_help, conflict_resolution, feeling_connected, avoiding_interaction, voluntary_isolation

📊 OUTCOME (Resulting States):
Mental Health:
- calm_mood, happy_mood, depression, anxiety, mood_swings, stress_level, emotional_exhaustion

Physical Health:
- feeling_well, fatigue, low_energy, pain, injury, illness_symptoms, doctor_visit, recovery

Available habit categories:
CHOICES (user actions):
- hydration: drinking water, fluids
- nutrition: eating, meals, food
- focus: breathing, meditation, mindfulness
- sleep: going to bed, sleep timing
- movement: exercise, walking, physical activity
- energy: energy levels, fatigue
- mood: emotional state

CHANCES (external events):
- safety: feeling unsafe, anxiety, panic
- meals: skipping meals, missed eating
- sleepIssues: sleep problems, insomnia
- financial: unexpected expenses, money stress
- outdoor: weather, no time outside

Respond with ONLY a valid JSON array of objects with this exact format:
[
  {
    "text": "extracted segment text",
    "category": "category_key",
    "confidence": 0.0-1.0,
    "type": "choice" or "chance",
    "sentiment": "positive/negative/neutral",
    "themes": ["theme1", "theme2"],
    "keywords": ["keyword1", "keyword2"],
    "sentimentConfidence": 0.0-1.0,
    "metadata": {"intensity": "low/medium/high"}
  }
]

Extract all relevant segments. If none found, return [].
''';
  }

  /// Parse the AI response into segments
  ParseResult _parseAIResponse(String originalText, String aiResponse) {
    try {
      // Clean up the response - sometimes AI adds extra text
      String jsonStr = aiResponse.trim();

      // Find JSON array in the response
      final startIndex = jsonStr.indexOf('[');
      final endIndex = jsonStr.lastIndexOf(']');

      if (startIndex == -1 || endIndex == -1) {
        throw Exception('No valid JSON found in AI response');
      }

      jsonStr = jsonStr.substring(startIndex, endIndex + 1);

      final jsonList = json.decode(jsonStr) as List<dynamic>;
      final segments = jsonList
          .cast<Map<String, dynamic>>()
          .map((item) => ParsedSegment.fromJson(item))
          .where((segment) =>
              segment.text.isNotEmpty && segment.category.isNotEmpty)
          .toList();

      return ParseResult(
        originalText: originalText,
        segments: segments,
        timestamp: DateTime.now(),
        isValid: true,
      );
    } catch (e) {
      debugPrint('TextParserService: Failed to parse AI response: $e');
      debugPrint('AI Response: $aiResponse');

      // Fallback to rule-based parsing
      return _fallbackParsing(originalText);
    }
  }

  /// Fallback rule-based parsing with multi-layer analysis when AI fails
  ParseResult _fallbackParsing(String input) {
    final segments = <ParsedSegment>[];
    final lowerInput = input.toLowerCase();

    // Keyword mappings limited to the curated canonical tag set
    final themeKeywords = <String, List<String>>{
      // Choice tags
      'movement_boost': ['walk', 'run', 'exercise', 'workout', 'gym', 'moved'],
      'mindful_break': ['mindful', 'present', 'pause', 'mini break'],
      'balanced_meal': [
        'healthy meal',
        'balanced meal',
        'nutritious',
        'good food',
        'snack'
      ],
      'hydration_reset': ['water', 'hydrated', 'drink', 'drank', 'sipped'],
      'sleep_hygiene': [
        'sleep routine',
        'bedtime',
        'lights out',
        'rested',
        'early night'
      ],
      'self_compassion': [
        'self compassion',
        'kind to myself',
        'gentle with myself'
      ],
      'focus_sprint': ['focus sprint', 'deep work', 'concentrated'],
      'reset_routine': ['reset', 'fresh start', 'back on track'],
      'digital_detox': ['offline', 'logged off', 'screen break'],
      'energy_plan': ['energy plan', 'pace myself', 'planned breaks'],
      'rest_day': ['rest day', 'recovery day', 'took a break'],
      'social_checkin': [
        'caught up',
        'checked in',
        'called',
        'messaged',
        'talked'
      ],
      'gratitude_moment': ['grateful', 'gratitude', 'thankful'],
      'creative_play': ['creative', 'drew', 'painted', 'music', 'play'],
      'breathing_reset': ['deep breath', 'breathing exercise', 'box breathing'],

      // Chance tags
      'busy_day': ['busy day', 'back-to-back', 'nonstop'],
      'time_pressure': ['time pressure', 'deadline', 'rushed', 'running late'],
      'deadline_mode': ['deadline mode', 'crunch', 'due soon'],
      'unexpected_event': ['unexpected', 'surprise', 'sudden'],
      'travel_disruption': ['traffic', 'train', 'bus', 'commute', 'transport'],
      'workspace_shift': [
        'new desk',
        'workspace',
        'office change',
        'work from home'
      ],
      'weather_slump': ['rainy', 'grey day', 'storm', 'heatwave'],
      'nature_time': ['outside', 'nature', 'park', 'fresh air'],
      'supportive_chat': [
        'therapy',
        'counsellor',
        'support worker',
        'talked through'
      ],
      'family_duty': ['family duty', 'care for', 'school run', 'kids'],
      'morning_check': ['this morning', 'start of the day'],
      'midday_reset': ['midday', 'lunch break', 'afternoon reset'],
      'evening_reflection': ['evening', 'tonight', 'end of the day'],

      // Outcome tags
      'calm_grounded': ['calm', 'grounded', 'steady'],
      'hopeful': ['hopeful', 'optimistic'],
      'relief': ['relieved', 'relief'],
      'balanced': ['balanced', 'even keel'],
      'overwhelmed': ['overwhelmed', 'too much'],
      'lonely': ['lonely', 'isolated', 'alone'],
      'anxious_underlying': ['anxious', 'worried', 'uneasy'],
      'energized': ['energised', 'energetic', 'buzzing'],
      'drained': ['tired', 'exhausted', 'drained'],
      'restless': ['restless', 'antsy'],
      'foggy': ['foggy', 'cloudy mind', 'couldn\'t think'],
      'proud_progress': ['proud', 'made progress'],
      'micro_win': ['micro win', 'small win', 'tiny win'],
      'setback': ['setback', 'slipped', 'off track'],
      'learning': ['learned', 'lesson'],
      'habit_chain': ['streak', 'chain'],
      'first_step': ['first step', 'got started'],
      'need_rest': ['need rest', 'need break'],
      'need_connection': ['need connection', 'miss people'],
      'need_fuel': ['need food', 'hungry', 'need fuel'],
      'need_clarity': ['need clarity', 'confused', 'unclear'],
    };

    // Enhanced sentiment keyword mappings
    final sentimentKeywords = {
      'positive': [
        'good',
        'great',
        'amazing',
        'wonderful',
        'love',
        'happy',
        'successful',
        'achieved',
        'accomplished',
        'proud',
        'excited',
        'grateful',
        'hopeful',
        'calm',
        'peaceful',
        'energetic',
        'motivated',
        'productive',
        'satisfied',
        'content',
        'joy',
        'relief',
        'stable',
        'secure',
        'confident',
        'optimistic',
        'better',
        'improved',
        'progress'
      ],
      'negative': [
        'bad',
        'terrible',
        'awful',
        'hate',
        'failed',
        'missed',
        'couldn\'t',
        'struggling',
        'stressed',
        'anxious',
        'worried',
        'sad',
        'depressed',
        'overwhelmed',
        'frustrated',
        'angry',
        'tired',
        'exhausted',
        'burnt out',
        'lonely',
        'isolated',
        'panic',
        'crisis',
        'difficult',
        'hard',
        'challenging',
        'broke',
        'homeless',
        'eviction',
        'forgot',
        'skipped',
        'gave up',
        'stuck',
        'lost',
        'confused',
        'helpless'
      ],
    };

    // Simple keyword-based detection with enhanced analysis
    final patterns = {
      // Choice tags
      'hydration_reset': {
        'keywords': ['drank', 'water', 'hydrat', 'drink', 'fluid'],
        'type': 'choice',
      },
      'balanced_meal': {
        'keywords': ['ate', 'meal', 'breakfast', 'lunch', 'dinner', 'snack'],
        'type': 'choice',
      },
      'movement_boost': {
        'keywords': ['walked', 'exercise', 'run', 'gym', 'move', 'active'],
        'type': 'choice',
      },
      'mindful_break': {
        'keywords': ['mindful', 'pause', 'breath', 'calm', 'journal'],
        'type': 'choice',
      },
      'sleep_hygiene': {
        'keywords': ['sleep', 'bed', 'rest', 'nap'],
        'type': 'choice',
      },

      // Chance tags
      'time_pressure': {
        'keywords': ['deadline', 'time pressure', 'rushed', 'back-to-back'],
        'type': 'chance',
      },
      'unexpected_event': {
        'keywords': ['unexpected', 'surprise', 'sudden'],
        'type': 'chance',
      },
      'travel_disruption': {
        'keywords': ['traffic', 'train', 'bus', 'transport', 'commute'],
        'type': 'chance',
      },
      'weather_slump': {
        'keywords': ['rainy', 'grey day', 'storm', 'heatwave'],
        'type': 'chance',
      },
      'supportive_chat': {
        'keywords': ['therapy', 'counsellor', 'support worker'],
        'type': 'chance',
      },

      // Outcome tags
      'anxious_underlying': {
        'keywords': ['anxious', 'worried', 'panic', 'uneasy'],
        'type': 'outcome',
      },
      'drained': {
        'keywords': ['tired', 'exhausted', 'drained'],
        'type': 'outcome',
      },
      'energized': {
        'keywords': ['energised', 'energized', 'buzzing'],
        'type': 'outcome',
      },
      'overwhelmed': {
        'keywords': ['overwhelmed', 'too much', 'flooded'],
        'type': 'outcome',
      },
      'calm_grounded': {
        'keywords': ['calm', 'grounded', 'steady'],
        'type': 'outcome',
      },
    };

    for (final category in patterns.keys) {
      final pattern = patterns[category]!;
      final keywords = pattern['keywords'] as List<String>;

      for (final keyword in keywords) {
        final regex = RegExp('\\b${RegExp.escape(keyword)}\\b');
        if (regex.hasMatch(lowerInput)) {
          // Extract the relevant portion of text
          final startIndex = lowerInput.indexOf(keyword);
          final endIndex = (startIndex + 30).clamp(0, input.length);
          final extractedText = input.substring(startIndex, endIndex);

          // Detect sentiment
          String sentiment = 'neutral';
          double sentimentConfidence = 0.5;
          for (final sentType in sentimentKeywords.keys) {
            for (final sentWord in sentimentKeywords[sentType]!) {
              if (lowerInput.contains(sentWord)) {
                sentiment = sentType;
                sentimentConfidence = 0.7;
                break;
              }
            }
            if (sentiment != 'neutral') break;
          }

          // Detect themes
          final detectedThemes = <String>[];
          final detectedKeywords = <String>[];
          for (final theme in themeKeywords.keys) {
            for (final themeWord in themeKeywords[theme]!) {
              if (lowerInput.contains(themeWord)) {
                if (!detectedThemes.contains(theme)) {
                  detectedThemes.add(theme);
                }
                detectedKeywords.add(themeWord);
              }
            }
          }

          if (detectedThemes.isEmpty) {
            detectedThemes.add(category);
          }

          final canonicalThemes = detectedThemes
              .map(CanonicalOntology.resolveCanonicalKey)
              .whereType<String>()
              .toList();

          if (canonicalThemes.isEmpty) {
            canonicalThemes.add('balanced');
          }

          segments.add(ParsedSegment(
            text: extractedText,
            category: canonicalThemes.first,
            confidence: 0.7, // Lower confidence for rule-based
            type: pattern['type'] as String,
            sentiment: sentiment,
            themes: canonicalThemes,
            keywords: detectedKeywords,
            sentimentConfidence: sentimentConfidence,
            metadata: {'method': 'rule-based'},
          ));
          break; // Only one match per category
        }
      }
    }

    return ParseResult(
      originalText: input,
      segments: segments,
      timestamp: DateTime.now(),
      isValid: true,
    );
  }

  /// Clear the parsing cache
  void clearCache() {
    _parseCache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _parseCache.length,
      'maxSize': _maxCacheSize,
      'entries': _parseCache.keys.toList(),
    };
  }
}
