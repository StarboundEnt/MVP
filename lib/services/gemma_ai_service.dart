import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/forecast_model.dart';
import '../models/smart_tag_model.dart';
import '../utils/response_filter.dart';
import 'env_service.dart';
import 'storage_service.dart';

// Minimal type definitions to avoid import conflicts
class UserProfile {
  final int? age;
  final HealthProfile healthProfile;
  final UserPreferences preferences;

  UserProfile({
    this.age,
    required this.healthProfile,
    required this.preferences,
  });
}

class HealthProfile {
  final List<String> fitnessGoals;
  HealthProfile({required this.fitnessGoals});
}

class UserPreferences {
  final String motivationStyle;
  UserPreferences({required this.motivationStyle});
}

class Habit {
  final String title;
  final String description;
  Habit({required this.title, required this.description});
}

enum HabitCategory {
  nutrition,
  exercise,
  sleep,
  mindfulness,
  productivity,
  social,
  other;

  String get displayName => name;
}

/// Structured response schema for Starbound AI responses
class StarboundResponseSchema {
  static const Map<String, Object> schema = {
    "type": "object",
    "properties": {
      "overview": {
        "type": "string",
        "description": "Main insight or response text without any step listings"
      },
      "immediate_steps": {
        "type": "array",
        "description": "Actionable steps the user can take now",
        "items": {
          "type": "object",
          "properties": {
            "step_number": {"type": "integer"},
            "title": {
              "type": "string",
              "description": "Brief title for the step"
            },
            "description": {
              "type": "string",
              "description": "Detailed description of what to do"
            },
            "estimated_time": {
              "type": "string",
              "description": "Time estimate like '2-5 min'"
            },
            "theme": {
              "type": "string",
              "description": "Theme category like 'hydration', 'movement', etc."
            }
          },
          "required": ["step_number", "title", "description"]
        }
      },
      "suggested_actions": {
        "type": "array",
        "description": "Additional suggestions that can be saved to vault",
        "items": {
          "type": "object",
          "properties": {
            "message": {
              "type": "string",
              "description": "The actionable suggestion"
            },
            "theme": {"type": "string", "description": "Theme category"},
            "estimated_time": {
              "type": "string",
              "description": "Time estimate"
            },
            "energy_required": {
              "type": "string",
              "description": "Energy level needed"
            }
          },
          "required": ["message", "theme"]
        }
      }
    },
    "required": ["overview"]
  };
}

/// Gemma AI Service for on-device personalized AI question answering
class GemmaAIService {
  static final GemmaAIService _instance = GemmaAIService._internal();
  factory GemmaAIService() => _instance;
  GemmaAIService._internal();

  static const Map<String, List<String>> _smartTagKeywordMap = {
    'movement_boost': ['walk', 'run', 'exercise', 'workout', 'gym', 'moved'],
    'mindful_break': ['mindful', 'present', 'pause', 'mini break', 'noticing'],
    'balanced_meal': [
      'healthy meal',
      'balanced meal',
      'ate well',
      'nutritious',
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
      'gentle with myself',
      'self compassion',
      'kind to myself'
    ],
    'focus_sprint': ['deep work', 'focus sprint', 'focus block'],
    'reset_routine': ['reset', 'fresh start', 'back on track'],
    'digital_detox': ['offline', 'logged off', 'screen break'],
    'energy_plan': ['manage energy', 'energy plan', 'pacers'],
    'rest_day': ['rest day', 'recovery day', 'day off'],
    'social_checkin': [
      'caught up',
      'checked in',
      'called',
      'messaged',
      'talked'
    ],
    'gratitude_moment': ['grateful', 'gratitude', 'thankful'],
    'creative_play': ['creative', 'painted', 'drew', 'music'],
    'breathing_reset': ['deep breath', 'breathing exercise', 'box breathing'],
    'busy_day': ['busy day', 'back-to-back', 'nonstop'],
    'time_pressure': ['time pressure', 'deadline', 'rushed', 'running late'],
    'deadline_mode': ['deadline mode', 'crunch time'],
    'unexpected_event': ['unexpected', 'surprise', 'sudden'],
    'travel_disruption': [
      'traffic',
      'train delay',
      'bus',
      'commute',
      'transport'
    ],
    'workspace_shift': [
      'workspace',
      'desk change',
      'office move',
      'work from home'
    ],
    'weather_slump': ['rainy', 'grey day', 'stormy', 'heatwave'],
    'nature_time': ['outside', 'nature', 'park', 'fresh air'],
    'supportive_chat': ['therapy', 'counsellor', 'support worker'],
    'family_duty': ['family duty', 'caregiving', 'school run', 'kids'],
    'morning_check': ['this morning', 'morning check'],
    'midday_reset': ['midday', 'lunch break', 'afternoon reset'],
    'evening_reflection': ['evening', 'tonight', 'end of day'],
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
    'foggy': ['foggy', 'cloudy', 'couldn\'t think'],
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

  static final Map<String, Map<String, dynamic>> _smartTagFollowUpMap = {
    'balanced_meal': {
      'question': 'What could nourish you next?',
      'triggerTagKey': 'balanced_meal',
      'type': 'multipleChoice',
      'suggestedResponses': [
        'Something colourful',
        'Protein first',
        'Snack and water',
        'Not sure yet'
      ],
      'priority': 2,
    },
    'movement_boost': {
      'question': 'How did that movement shift your energy?',
      'triggerTagKey': 'movement_boost',
      'type': 'multipleChoice',
      'suggestedResponses': [
        'Energised',
        'Grounded',
        'Still flat',
        'Not sure yet'
      ],
      'priority': 2,
    },
    'sleep_hygiene': {
      'question': 'What helps you wind down most?',
      'triggerTagKey': 'sleep_hygiene',
      'type': 'multipleChoice',
      'suggestedResponses': [
        'Lights low',
        'Screens away',
        'Breathing',
        'Something else'
      ],
      'priority': 1,
    },
    'anxious_underlying': {
      'question': 'What usually softens that anxious feeling?',
      'triggerTagKey': 'anxious_underlying',
      'type': 'multipleChoice',
      'suggestedResponses': [
        'Movement',
        'Talking to someone',
        'Breathing',
        'Not sure yet'
      ],
      'priority': 3,
    },
    'need_connection': {
      'question': 'Who could you check in with next?',
      'triggerTagKey': 'need_connection',
      'type': 'multipleChoice',
      'suggestedResponses': [
        'Friend',
        'Family',
        'Support person',
        'No-one right now'
      ],
      'priority': 1,
    },
  };

  
  // Model state
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _activeModel;
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _systemInstruction = '''
You are Starbound, a wellness coach specializing in personalized health guidance.

Core Principles:
- Always be supportive, factual, and non-judgmental
- Provide practical, actionable advice tailored to the user's complexity profile
- Use behavioral science principles to create effective interventions
- Keep responses concise but comprehensive (under 300 words)
- Always encourage small, sustainable changes over dramatic lifestyle overhauls

Complexity Profiles:
- Survival: Struggling with basic needs, overwhelmed. Use simple, immediate actions with lots of support.
- Overloaded: Too much on their plate, stressed. Focus on simplification and stress reduction.
- Trying: Motivated but inconsistent. Provide structure and accountability systems.
- Stable: Ready for growth and optimization. Offer advanced strategies and challenges.

Behavioral Science Techniques:
1. Default Options: Suggest pre-selected beneficial choices
2. Simplification: Break complex tasks into tiny steps
3. Positive Framing: Focus on gains rather than losses
4. Anchoring: Use reference points to guide decisions
5. Commitment Devices: Create accountability mechanisms
6. Salience: Make important factors more noticeable
7. Priming: Set environmental cues for success
8. Individualization: Tailor advice to personal context

Always end responses with supportive encouragement and 1-2 specific next steps.
''';
  final StorageService _storageService = StorageService();

  static const List<String> _defaultHorizonOrder = [
    'month1',
    'month6',
    'year1',
    'year5'
  ];

  static const Map<String, String> _defaultHorizonLabels = {
    'month1': '1 Month',
    'month6': '6 Months',
    'year1': '1 Year',
    'year5': '5 Years',
  };

  static const Map<String, String> _defaultHorizonTimeframes = {
    'month1': '1 month',
    'month6': '6 months',
    'year1': '1 year',
    'year5': '5 years',
  };

  // Model configuration - Get API key from environment or fallback
  static String get _apiKey {
    // First try environment variable
    const String? envApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
    if (envApiKey != null &&
        envApiKey.isNotEmpty &&
        envApiKey != 'YOUR_API_KEY_HERE') {
      return envApiKey;
    }

    final runtimeApiKey = EnvService.instance.maybe('OPENROUTER_API_KEY');
    if (runtimeApiKey != null &&
        runtimeApiKey.isNotEmpty &&
        runtimeApiKey != 'YOUR_API_KEY_HERE') {
      return runtimeApiKey;
    }

    const String? legacyEnvApiKey =
        String.fromEnvironment('GEMINI_API_KEY');
    if (legacyEnvApiKey != null &&
        legacyEnvApiKey.isNotEmpty &&
        legacyEnvApiKey != 'YOUR_API_KEY_HERE') {
      return legacyEnvApiKey;
    }

    final legacyRuntimeApiKey = EnvService.instance.maybe('GEMINI_API_KEY');
    if (legacyRuntimeApiKey != null &&
        legacyRuntimeApiKey.isNotEmpty &&
        legacyRuntimeApiKey != 'YOUR_API_KEY_HERE') {
      return legacyRuntimeApiKey;
    }

    // TODO: Replace with your actual OpenRouter API key for testing
    const String testApiKey = 'YOUR_OPENROUTER_API_KEY_HERE';

    if (testApiKey != 'YOUR_OPENROUTER_API_KEY_HERE') {
      return testApiKey;
    }

    // Return placeholder to force simulation mode
    return 'YOUR_API_KEY_HERE';
  }

  static String _normalizeModelName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.contains('/')) {
      return trimmed;
    }
    if (trimmed.startsWith('gemini')) {
      return 'google/$trimmed';
    }
    return trimmed;
  }

  static Iterable<String> _splitModelList(String raw) {
    return raw
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty);
  }

  static List<String> get _candidateModels {
    final candidates = <String>[];
    final runtimeList =
        EnvService.instance.maybe('OPENROUTER_MODEL_CANDIDATES');
    if (runtimeList != null && runtimeList.isNotEmpty) {
      candidates.addAll(_splitModelList(runtimeList));
    }

    const compileTimeList =
        String.fromEnvironment('OPENROUTER_MODEL_CANDIDATES');
    if (compileTimeList.isNotEmpty) {
      candidates.addAll(_splitModelList(compileTimeList));
    }

    candidates.addAll(_modelCandidates);

    final seen = <String>{};
    final uniqueCandidates = <String>[];
    for (final model in candidates) {
      final normalized = _normalizeModelName(model);
      if (normalized.isEmpty) {
        continue;
      }
      if (seen.add(normalized)) {
        uniqueCandidates.add(normalized);
      }
    }

    return uniqueCandidates;
  }

  // Use the free tier-compatible model; 2.5 requires upgraded quota
  static List<String> get _modelCandidates {
    final candidates = <String>[];
    final runtimeModel = EnvService.instance.maybe('OPENROUTER_MODEL')?.trim();
    if (runtimeModel != null && runtimeModel.isNotEmpty) {
      candidates.add(runtimeModel);
    }

    const compileTimeModel = String.fromEnvironment('OPENROUTER_MODEL');
    if (compileTimeModel.isNotEmpty) {
      candidates.add(compileTimeModel);
    }

    final legacyRuntimeModel = EnvService.instance.maybe('GEMINI_MODEL')?.trim();
    if (legacyRuntimeModel != null && legacyRuntimeModel.isNotEmpty) {
      candidates.add(legacyRuntimeModel);
    }

    const legacyCompileTimeModel = String.fromEnvironment('GEMINI_MODEL');
    if (legacyCompileTimeModel.isNotEmpty) {
      candidates.add(legacyCompileTimeModel);
    }

    candidates.addAll([
      'google/gemini-1.5-flash-latest',
      'google/gemini-1.5-flash',
      'google/gemini-1.0-pro',
      'google/gemini-pro',
    ]);

    final seen = <String>{};
    final uniqueCandidates = <String>[];
    for (final model in candidates) {
      final normalized = _normalizeModelName(model);
      if (normalized.isEmpty) {
        continue;
      }
      if (seen.add(normalized)) {
        uniqueCandidates.add(normalized);
      }
    }

    return uniqueCandidates;
  }
  static const int _maxTokens = 500;
  static const double _temperature = 0.7;

  // Initialization status
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

  /// Initialize the Gemma model
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_isInitializing) return false;

    _isInitializing = true;

    try {
      // Check if we have a valid API key
      if (_apiKey == 'YOUR_API_KEY_HERE') {
        if (kDebugMode) {
          print('⚠️ No API key provided, using enhanced simulation mode');
          print('💡 Set OPENROUTER_API_KEY environment variable for real AI');
        }
        await _initializeDemoMode();
      } else {
        // Initialize real OpenRouter model
        for (final modelName in _candidateModels) {
          try {
            if (kDebugMode) {
              print('🤖 Testing OpenRouter connection...');
              print(
                  '🔍 Testing OpenRouter API with key: ${_apiKey.substring(0, 10)}...');
            }

            final testResponse = await _sendChat(
              model: modelName,
              messages: const [
                {
                  'role': 'system',
                  'content':
                      'You are Starbound, a wellness coach specializing in personalized health guidance.',
                },
                {
                  'role': 'user',
                  'content':
                      'Respond with "Ready" if you can help with health and wellness questions.',
                },
              ],
              temperature: 0.2,
              maxTokens: 60,
            );

            if (testResponse != null && testResponse.trim().isNotEmpty) {
              if (kDebugMode) {
                print('✅ Real OpenRouter AI initialized successfully');
                print(
                    '🧠 Advanced AI responses with complexity profiles enabled');
                print(
                    '🔑 API Key is working: ${_apiKey.substring(0, 10)}...');
                print('🧩 Using model: $modelName');
              }
              _activeModel = modelName;
              break;
            } else {
              throw Exception('API test failed - empty response');
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Model init failed ($modelName): $e');
            }
            _activeModel = null;
          }
        }

        if (_activeModel == null) {
          throw Exception('No OpenRouter models available for this API key.');
        }
      }

      _isInitialized = true;
      _isInitializing = false;

      return true;
    } catch (e) {
      _isInitializing = false;
      if (kDebugMode) {
        print('❌ Failed to initialize real AI, falling back to simulation: $e');
        print('📍 Error type: ${e.runtimeType}');
        if (e.toString().contains('401') || e.toString().contains('403')) {
          print(
              '🔑 API Key issue: The key may be invalid or lacks permissions');
        } else if (e.toString().contains('429')) {
          print('⏰ Quota exceeded: API has hit rate limits');
        } else if (e.toString().contains('503')) {
          print('🚫 Service unavailable: OpenRouter is temporarily down');
        }
        print('💡 Check your OPENROUTER_API_KEY or internet connection');
      }

      // Always fallback to enhanced simulation mode - this should never fail
      try {
        await _initializeDemoMode();
        _isInitialized = true;
        return true;
      } catch (fallbackError) {
        if (kDebugMode) {
          print('❌ Critical error: Enhanced simulation failed: $fallbackError');
        }
        // This is a critical error - enhanced simulation should never fail
        return false;
      }
    }
  }

  /// Answer general questions using Gemma AI
  Future<Map<String, dynamic>> answerQuestion({
    required String question,
    required String userName,
    required String complexityProfile,
    required Map<String, dynamic> context,
  }) async {
    if (kDebugMode) {
      print(
          '🤖 ASK AI: Received question: "$question" from user: "$userName" with profile: "$complexityProfile"');
    }

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        if (kDebugMode) {
          print('🤖 GemmaAI: Initialization failed, forcing simulation mode');
        }
        // Force simulation mode - never throw exception
        await _initializeDemoMode();
        _isInitialized = true;
      }
    }

    final prompt =
        _buildQuestionPrompt(question, userName, complexityProfile, context);
    if (kDebugMode) {
      print('🤖 GemmaAI: Built prompt: $prompt');
    }

    try {
      // Check if we have the real model available
      if (_activeModel != null || _candidateModels.isNotEmpty) {
        if (kDebugMode) {
          print('🤖 GemmaAI: Using OpenRouter with structured response');
        }

        // Check if this is a forecast request - use text response for forecasts
        final isForecastRequest = context['requestType'] == 'health_forecast';

        final responseText = await _sendChatWithFailover(
          messages: [
            const {
              'role': 'system',
              'content': _systemInstruction,
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          temperature: _temperature,
          maxTokens: isForecastRequest ? 2000 : _maxTokens,
          topP: 0.8,
        );

        if (responseText != null && responseText.trim().isNotEmpty) {
          if (isForecastRequest) {
            // For forecasts, return text response directly
            final responseData = {
              'response': ResponseFilter.processResponse(responseText),
              'sources': [
                {
                  'title': 'OpenRouter AI Forecast',
                  'source': 'OpenRouter',
                  'type': 'AI-generated',
                  'icon': '🔮',
                  'url': 'https://openrouter.ai/'
                }
              ],
              'aiType': 'real_openrouter'
            };

            if (kDebugMode) {
              print(
                  '🔮 GemmaAI: Forecast response received (${responseText.length} chars)');
            }
            return responseData;
          } else {
            // Parse the structured JSON response for non-forecast requests
            final jsonResponse = _safeDecodeJsonObject(responseText);
            final structured = jsonResponse.isNotEmpty ? jsonResponse : null;
            final overview = structured?['overview']?.toString();

            final responseData = {
              'response': ResponseFilter.processResponse(
                  overview ?? responseText),
              'structured_data': structured,
              'sources': [
                {
                  'title': 'OpenRouter AI Response',
                  'source': 'OpenRouter',
                  'type': 'AI-generated',
                  'icon': '🤖',
                  'url': 'https://openrouter.ai/'
                }
              ],
              'aiType': 'real_openrouter'
            };

            if (kDebugMode) {
              print(
                  '🤖 GemmaAI: Structured AI response received: ${overview ?? 'unstructured'}');
              if (structured != null) {
                print('🔧 JSON structure: ${structured.keys.toList()}');
              }
            }
            return responseData;
          }
        } else {
          throw Exception('Empty response from OpenRouter API');
        }
      } else {
        if (kDebugMode) {
          print('🤖 GemmaAI: Model not available, using enhanced simulation');
        }
        // Fallback to enhanced AI simulation
        final responseData = await _simulateGemmaInferenceWithSources(
            prompt, question, complexityProfile);

        if (kDebugMode) {
          print(
              '🤖 GemmaAI: Generated simulation response: ${responseData['response']}');
        }
        return responseData;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🤖 GemmaAI: Real AI failed, falling back to simulation: $e');
      }

      // Fallback to enhanced simulation if real AI fails
      try {
        final responseData = await _simulateGemmaInferenceWithSources(
            prompt, question, complexityProfile);
        return responseData;
      } catch (fallbackError) {
        if (kDebugMode) {
          print('❌ CRITICAL: Enhanced simulation failed: $fallbackError');
          print('🚨 This should never happen - returning emergency response');
        }
        // Never throw exception - return emergency response instead
        return {
          'response':
              "I'm experiencing technical difficulties but I'm here to help. Could you please try rephrasing your question?",
          'sources': [],
          'aiType': 'emergency_fallback'
        };
      }
    }
  }

  Future<ForecastEntry> generateHealthForecast({
    required String habit,
    required String userName,
    required String complexityProfile,
    required Map<String, dynamic> userHabits,
    required Map<String, dynamic> enhancedContext,
  }) async {
    final normalizedHabit = habit.trim().isEmpty ? 'this habit' : habit.trim();
    final generatedAt = DateTime.now();

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        await _initializeDemoMode();
        _isInitialized = true;
      }
    }

    final prompt = _buildForecastPrompt(
      habit: normalizedHabit,
      userName: userName,
      complexityProfile: complexityProfile,
      userHabits: userHabits,
      enhancedContext: enhancedContext,
    );

    if (kDebugMode) {
      print('🔮 Forecast Prompt Built (${prompt.length} chars)');
    }

    try {
      if (_activeModel != null || _candidateModels.isNotEmpty) {
        final responseText = await _sendChatWithFailover(
          messages: [
            const {
              'role': 'system',
              'content': _systemInstruction,
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          temperature: 0.6,
          maxTokens: 1400,
          topP: 0.85,
        );

        if (responseText == null || responseText.trim().isEmpty) {
          throw Exception('Empty response from OpenRouter API');
        }

        if (kDebugMode) {
          final preview = responseText.length > 160
              ? '${responseText.substring(0, 160)}...'
              : responseText;
          print('🔮 Forecast raw response preview: $preview');
        }

        final decoded = _safeDecodeForecastJson(responseText);
        if (decoded.isNotEmpty) {
          final entry = _buildForecastEntryFromJson(
            decoded,
            normalizedHabit,
            complexityProfile,
            generatedAt,
            userHabits,
            enhancedContext,
            source: 'openrouter',
          );
          await _storageService.addForecastEntry(entry);
          return entry;
        }
      } else {
        throw StateError(
            'OpenRouter model unavailable. Set OPENROUTER_API_KEY to enable forecasts.');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Forecast generation failed: $e');
        print(stack);
      }
      rethrow;
    }

    throw Exception('Forecast generation returned no data.');
  }

  String _buildForecastPrompt({
    required String habit,
    required String userName,
    required String complexityProfile,
    required Map<String, dynamic> userHabits,
    required Map<String, dynamic> enhancedContext,
  }) {
    final contextSummary = _formatForecastContext(userHabits, enhancedContext);
    final structuredContext = const JsonEncoder.withIndent('  ').convert({
      'profile': enhancedContext['profile'],
      'habit_trends': enhancedContext['habit_trends'],
      'protective_factors': enhancedContext['protective_factors'],
      'risk_factors': enhancedContext['risk_factors'],
      'personalization_notes': enhancedContext['personalization_notes'],
    });

    return '''
You are Starbound's health forecasting specialist.

Goal: Predict how "$habit" will influence $userName's wellbeing over time and deliver a JSON payload that matches the provided schema.

User capacity: $complexityProfile

Context summary:
$contextSummary

Structured context JSON:
$structuredContext

Instructions:
1. Model four horizons (1 month, 6 months, 1 year, 5 years) and tailor language to the user's capacity.
2. For each horizon provide: outlook, recommended_move, driving_signals (1-3), confidence (0-1), risk_level word, optional trend.
3. Include a short summary, one immediate_action for the next 24 hours, encouraging support, and why_it_matters referencing key mechanisms.
4. Populate impact_areas with one concise sentence each explaining the mental, physical, and social effects of continuing this habit for this user.
5. Keep tone compassionate, realistic, and agency-building. Reference protective factors and risks where relevant.
6. Use the JSON schema provided by the system—do not return markdown, only JSON.
''';
  }

  String _formatForecastContext(Map<String, dynamic> userHabits,
      Map<String, dynamic> enhancedContext) {
    final buffer = StringBuffer();
    buffer.writeln('- Habit snapshot: ${_summarizeHabits(userHabits)}');

    final trends = enhancedContext['habit_trends'];
    if (trends is Map) {
      final strengths = (trends['strengths'] as List?)
              ?.whereType<dynamic>()
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[];
      final concerns = (trends['concerns'] as List?)
              ?.whereType<dynamic>()
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[];

      if (strengths.isNotEmpty) {
        buffer.writeln('- Protective habits already working: ${strengths.join(', ')}');
      }
      if (concerns.isNotEmpty) {
        buffer.writeln('- Habits needing support: ${concerns.join(', ')}');
      }
    }

    final protective = enhancedContext['protective_factors'];
    if (protective is List && protective.isNotEmpty) {
      final formatted = protective
          .whereType<dynamic>()
          .map((factor) => factor.toString())
          .where((factor) => factor.isNotEmpty)
          .toList();
      if (formatted.isNotEmpty) {
        buffer.writeln('- Protective factors: ${formatted.join(', ')}');
      }
    }

    final risks = enhancedContext['risk_factors'];
    if (risks is List && risks.isNotEmpty) {
      final formatted = risks
          .whereType<dynamic>()
          .map((risk) => risk.toString())
          .where((risk) => risk.isNotEmpty)
          .toList();
      if (formatted.isNotEmpty) {
        buffer.writeln('- Risk factors: ${formatted.join(', ')}');
      }
    }

    final notes = enhancedContext['personalization_notes'];
    if (notes is List && notes.isNotEmpty) {
      final formatted = notes
          .whereType<dynamic>()
          .map((note) => note.toString())
          .where((note) => note.isNotEmpty)
          .toList();
      if (formatted.isNotEmpty) {
        buffer.writeln('- Personalization notes: ${formatted.join(' | ')}');
      }
    }

    return buffer.toString().trim();
  }

  Map<String, dynamic> _safeDecodeForecastJson(String responseText) {
    if (responseText.isEmpty) return const {};

    String candidate = responseText.trim();
    if (candidate.startsWith('```')) {
      final fenceMatch =
          RegExp(r'```[a-zA-Z]*\s*([\s\S]*?)```').firstMatch(candidate);
      if (fenceMatch != null) {
        candidate = fenceMatch.group(1)?.trim() ?? candidate;
      }
    }

    Map<String, dynamic> _tryDecode(String text) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        // ignored
      }
      return const {};
    }

    var decoded = _tryDecode(candidate);
    if (decoded.isNotEmpty) return decoded;

    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      final sliced = candidate.substring(start, end + 1);
      decoded = _tryDecode(sliced);
      if (decoded.isNotEmpty) return decoded;
    }

    return const {};
  }

  Map<String, dynamic> _safeDecodeJsonObject(String responseText) {
    return _safeDecodeForecastJson(responseText);
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    final runtimeReferer = EnvService.instance.maybe('OPENROUTER_SITE_URL');
    const compileTimeReferer = String.fromEnvironment('OPENROUTER_SITE_URL');
    String? referer;
    if (runtimeReferer != null && runtimeReferer.isNotEmpty) {
      referer = runtimeReferer;
    } else if (compileTimeReferer.isNotEmpty) {
      referer = compileTimeReferer;
    }
    if (referer != null) {
      headers['HTTP-Referer'] = referer;
    }

    final runtimeTitle = EnvService.instance.maybe('OPENROUTER_APP_NAME');
    const compileTimeTitle = String.fromEnvironment('OPENROUTER_APP_NAME');
    String? title;
    if (runtimeTitle != null && runtimeTitle.isNotEmpty) {
      title = runtimeTitle;
    } else if (compileTimeTitle.isNotEmpty) {
      title = compileTimeTitle;
    }
    if (title != null) {
      headers['X-Title'] = title;
    }

    return headers;
  }

  Future<String?> _sendChatWithFailover({
    required List<Map<String, String>> messages,
    double temperature = _temperature,
    int maxTokens = _maxTokens,
    double topP = 0.8,
  }) async {
    final preferred = _activeModel;
    if (preferred != null && preferred.trim().isNotEmpty) {
      final response = await _sendChat(
        model: preferred,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
        topP: topP,
      );
      if (response != null && response.trim().isNotEmpty) {
        return response;
      }
    }

    for (final model in _candidateModels) {
      if (model == preferred) {
        continue;
      }
      final response = await _sendChat(
        model: model,
        messages: messages,
        temperature: temperature,
        maxTokens: maxTokens,
        topP: topP,
      );
      if (response != null && response.trim().isNotEmpty) {
        _activeModel = model;
        return response;
      }
    }

    return null;
  }

  Future<String?> _sendChat({
    required String model,
    required List<Map<String, String>> messages,
    double temperature = _temperature,
    int maxTokens = _maxTokens,
    double topP = 0.8,
  }) async {
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      return null;
    }

    final payload = {
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'top_p': topP,
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _buildHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          print(
              '❌ OpenRouter request failed: ${response.statusCode} ${response.body}');
        }
        return null;
      }

      final decoded = jsonDecode(response.body);
      final choices = decoded['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map && first['message'] is Map) {
          final message = first['message'] as Map;
          final content = message['content']?.toString();
          return content;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OpenRouter request failed: $e');
      }
    }

    return null;
  }

  ForecastEntry _buildForecastEntryFromJson(
    Map<String, dynamic> forecastJson,
    String habit,
    String complexityProfile,
    DateTime generatedAt,
    Map<String, dynamic> userHabits,
    Map<String, dynamic> enhancedContext, {
    required String source,
  }) {
    final normalized = Map<String, dynamic>.from(forecastJson);

    normalized['id'] ??=
        'forecast-${generatedAt.millisecondsSinceEpoch.toString()}';
    normalized['habit'] = habit;
    normalized['created_at'] = generatedAt.toIso8601String();
    normalized['complexity_profile'] = complexityProfile;

    normalized['summary'] ??=
        'Here is how "$habit" could shape your energy and wellbeing.';
    normalized['why_it_matters'] ??=
        'Daily habits compound—adjusting "$habit" now protects future energy, mood, and health.';
    normalized['immediate_action'] ??=
        'Choose one tiny adjustment for the next 24 hours and notice how your body responds.';
    normalized['encouragement'] ??=
        'You do not need perfect streaks—keep experimenting and capture what helps.';

    final impactAreasRaw = normalized['impact_areas'];
    Map<String, String> impactAreas;
    if (impactAreasRaw is Map) {
      impactAreas = impactAreasRaw.map((key, value) =>
          MapEntry(key.toString().toLowerCase(), value.toString().trim()));
    } else {
      impactAreas = {};
    }
    if (impactAreas.isEmpty) {
      impactAreas = ForecastEntry.defaultImpactAreasFor(habit);
    }
    normalized['impact_areas'] = impactAreas;

    final horizonsInput = normalized['horizons'];
    final normalizedHorizons = <Map<String, dynamic>>[];
    if (horizonsInput is List && horizonsInput.isNotEmpty) {
      for (int index = 0; index < horizonsInput.length; index++) {
        final raw = horizonsInput[index];
        if (raw is! Map) continue;
        final horizon = raw.map((key, value) => MapEntry(key.toString(), value));
        final id = horizon['id']?.toString().trim().isNotEmpty == true
            ? horizon['id'].toString()
            : (index < _defaultHorizonOrder.length
                ? _defaultHorizonOrder[index]
                : 'custom_${index + 1}');
        horizon['id'] = id;
        horizon['label'] = horizon['label']?.toString().trim().isNotEmpty == true
            ? horizon['label']
            : _defaultHorizonLabels[id] ?? id;
        horizon['timeframe'] =
            horizon['timeframe']?.toString().trim().isNotEmpty == true
                ? horizon['timeframe']
                : _defaultHorizonTimeframes[id] ?? id;
        horizon['outlook'] = horizon['outlook']?.toString().trim().isNotEmpty == true
            ? horizon['outlook']
            : 'Your experience with "$habit" will become clearer at this point.';
        horizon['recommended_move'] =
                horizon['recommended_move']?.toString().trim().isNotEmpty == true
            ? horizon['recommended_move']
            : 'Log how "$habit" felt this week and choose one supportive tweak.';
        horizon['risk_level'] =
            horizon['risk_level']?.toString().trim().isNotEmpty == true
                ? horizon['risk_level']
                : 'medium';

        final confidence = horizon['confidence'];
        if (confidence is num) {
          horizon['confidence'] = confidence.toDouble().clamp(0.0, 1.0);
        } else {
          final parsed = double.tryParse(confidence?.toString() ?? '');
          horizon['confidence'] =
              (parsed ?? 0.6).clamp(0.0, 1.0);
        }

        final signals = horizon['driving_signals'];
        if (signals is! List || signals.isEmpty) {
          horizon['driving_signals'] =
              _collectSignalsFromHorizons(horizonsInput).take(3).toList();
        }

        normalizedHorizons.add(horizon);
      }
    }

    if (normalizedHorizons.isEmpty) {
      throw StateError('Forecast response missing horizon data.');
    }
    normalized['horizons'] = normalizedHorizons;

    normalized['key_signals'] ??=
        _collectSignalsFromHorizons(normalized['horizons']).toList();

    final metadata = <String, dynamic>{};
    final rawMetadata = normalized['metadata'];
    if (rawMetadata is Map<String, dynamic>) {
      metadata.addAll(rawMetadata);
    } else if (rawMetadata is Map) {
      metadata.addAll(
          rawMetadata.map((key, value) => MapEntry(key.toString(), value)));
    }

    metadata['source'] = source;
    metadata['generated_at'] = generatedAt.toIso8601String();
    metadata['habit'] = habit;
    metadata['context'] = {
      'user_habits': userHabits,
      'enhanced_context': enhancedContext,
    };
    metadata['impact_areas'] = normalized['impact_areas'];

    normalized['metadata'] = metadata;

    return ForecastEntry.fromJson(normalized);
  }

  Iterable<String> _collectSignalsFromHorizons(dynamic horizonsInput) {
    final signals = <String>{};
    if (horizonsInput is List) {
      for (final horizon in horizonsInput) {
        if (horizon is Map) {
          final rawSignals = horizon['driving_signals'] ?? horizon['top_signals'];
          if (rawSignals is List) {
            for (final signal in rawSignals) {
              final asString = signal?.toString().trim();
              if (asString != null && asString.isNotEmpty) {
                signals.add(asString);
              }
            }
          }
        }
      }
    }
    return signals;
  }

  /// Generate a simple response using the AI model (for TextParserService)
  Future<String> generateResponse(String prompt) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        if (kDebugMode) {
          print(
              '🤖 GeminiAI: generateResponse initialization failed, forcing simulation mode');
        }
        // Force simulation mode - never throw exception
        await _initializeDemoMode();
        _isInitialized = true;
      }
    }

    try {
      // Check if we have the real model available
      if (_activeModel != null || _candidateModels.isNotEmpty) {
        // Call real OpenRouter API
        final responseText = await _sendChatWithFailover(
          messages: [
            const {
              'role': 'system',
              'content': _systemInstruction,
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          temperature: _temperature,
          maxTokens: _maxTokens,
          topP: 0.8,
        );

        if (responseText != null && responseText.trim().isNotEmpty) {
          return ResponseFilter.processResponse(responseText);
        } else {
          throw Exception('Empty response from OpenRouter API');
        }
      } else {
        // Fallback to simulation
        if (kDebugMode) {
          print('🤖 GemmaAI: No real model, using enhanced simulation');
        }
        return await _simulateGemmaInference(prompt);
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            '🤖 GeminiAI: API error ($e), using enhanced simulation fallback');
      }
      // Always fallback to enhanced simulation - this should never fail
      try {
        return await _simulateGemmaInference(prompt);
      } catch (simulationError) {
        if (kDebugMode) {
          print('❌ CRITICAL: Enhanced simulation failed: $simulationError');
        }
        // Last resort - return a basic error message to prevent total failure
        return "I'm experiencing technical difficulties. Please try again in a moment.";
      }
    }
  }

  // Prompt building methods

  String _buildQuestionPrompt(String question, String userName,
      String complexityProfile, Map<String, dynamic> context) {
    // Multi-layer prompt architecture: System + Context + Complexity + Domain
    final name = userName.isNotEmpty ? userName : 'friend';
    final domain = _identifyQuestionDomain(question);
    final complexityGuidance = _getComplexityGuidance(complexityProfile);
    final domainSpecialization = _getDomainSpecialization(domain);
    final contextualFactors = _buildContextualFactors(context);
    final conversationContext = _buildConversationContext(context);

    return '''$domainSpecialization

$name is asking about $domain: "$question"

WHAT YOU KNOW ABOUT THEM:
$contextualFactors
$conversationContext

HOW TO ADAPT YOUR RESPONSE:
$complexityGuidance

---

Talk to $name like a knowledgeable friend, not a wellness bot. Answer their actual question first.

VARY YOUR APPROACH:
- If they seem stuck → gentle encouragement, one small step
- If they're curious → explain the "why" behind things
- If they're frustrated → validate first, then offer options
- If they're doing well → celebrate and suggest what's next

DON'T:
- Give the same structure every time
- Start every section the same way
- Sound like a pamphlet

RESPONSE (JSON only):
{
  "overview": "[Answer their question directly in 2-3 sentences. Reference something specific about their situation. Under 55 words.]",

  "insight_sections": [
    {"title": "[Relevant title — NOT always 'What's happening']", "summary": "[2-3 sentences connecting to their signals]", "context_signals": ["[signals you referenced]"]},
    {"title": "[Another angle — could be 'Why this makes sense' or 'The pattern here' or 'What might help']", "summary": "[2-3 sentences]", "context_signals": ["..."]},
    {"title": "[Forward-looking — 'What to try' or 'Worth watching' or 'Next step']", "summary": "[2-3 sentences]", "context_signals": ["..."]}
  ],

  "immediate_steps": [
    {"step_number": 1, "title": "[Short action]", "description": "[Specific to their capacity]", "estimated_time": "...", "theme": "..."},
    {"step_number": 2, "title": "[Short action]", "description": "[Connected to their situation]", "estimated_time": "...", "theme": "..."},
    {"step_number": 3, "title": "[Short action]", "description": "[Something trackable]", "estimated_time": "...", "theme": "..."}
  ],

  "suggested_actions": [
    {"message": "[Natural suggestion, not robotic]", "theme": "...", "estimated_time": "...", "energy_required": "..."}
  ]
}

Never diagnose. If something needs medical attention, say so clearly in the insight sections.''';
  }

  String _buildConversationContext(Map<String, dynamic> context) {
    final isFollowUp = context['is_follow_up'] == true;
    if (!isFollowUp) return '';

    final conversationHistory = context['conversation_history'] as String?;
    final threadTopic = context['thread_topic'] as String?;

    if (conversationHistory == null || conversationHistory.isEmpty) return '';

    return '''
CONVERSATION CONTEXT:
- This is a follow-up question in an ongoing conversation
- Main topic: ${threadTopic ?? 'general wellness'}
- Build upon previous responses and maintain consistency
- Reference earlier exchanges when relevant

$conversationHistory

FOLLOW-UP GUIDANCE:
- Acknowledge the conversation flow
- Build on previous advice given
- Avoid repeating identical suggestions
- Provide progressive depth or new angles
- Maintain therapeutic rapport''';
  }

  String _identifyQuestionDomain(String question) {
    final questionLower = question.toLowerCase();
    if (_isSleepRelated(questionLower)) return 'sleep';
    if (_isFoodRelated(questionLower)) return 'nutrition';
    if (_isExerciseRelated(questionLower)) return 'fitness';
    if (_isMoodRelated(questionLower)) return 'mental_health';
    if (_isStressRelated(questionLower)) return 'stress_management';
    if (_isEnergyRelated(questionLower)) return 'energy';
    if (_isMotivationRelated(questionLower)) return 'motivation';
    if (_isWorkRelated(questionLower)) return 'work_life';
    if (_isRelationshipRelated(questionLower)) return 'relationships';
    return 'general_wellness';
  }

  String _getComplexityGuidance(String complexityProfile) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return '''
- Keep suggestions simple and immediately actionable
- Focus on one small step at a time
- Provide extra emotional support and validation
- Emphasize that any progress is meaningful
- Avoid overwhelming with multiple options
- Use gentle, encouraging language throughout''';
      case 'overloaded':
        return '''
- Prioritize simplification and stress reduction
- Focus on removing barriers rather than adding tasks
- Suggest ways to streamline existing routines
- Emphasize efficiency and time-saving approaches
- Acknowledge their circumstances and validate their efforts
- Offer quick wins that reduce overall burden''';
      case 'trying':
        return '''
- Provide structure and clear step-by-step guidance
- Include accountability mechanisms and tracking
- Offer multiple options to maintain engagement
- Focus on consistency over perfection
- Celebrate small wins and progress made
- Help troubleshoot common obstacles''';
      case 'stable':
        return '''
- Present advanced strategies and optimization techniques
- Offer challenges that promote growth
- Include research-backed methodologies
- Encourage experimentation with new approaches
- Focus on long-term benefits and compound effects
- Suggest ways to help others or become a role model''';
      default:
        return '''
- Provide balanced, practical advice
- Include both simple and advanced options
- Focus on sustainable, evidence-based approaches''';
    }
  }

  String _getDomainSpecialization(String domain) {
    switch (domain) {
      case 'sleep':
        return '''You're Starbound, and you know a lot about sleep — not in a clinical way, but in a "here's what actually works" way. You get that sleep problems are frustrating and you don't lecture.''';
      case 'nutrition':
        return '''You're Starbound, and you're good at talking about food without being preachy. You focus on what's practical and sustainable, not perfect eating.''';
      case 'fitness':
        return '''You're Starbound, and you understand that movement looks different for everyone. You're not about gym culture — you're about finding what works for each person.''';
      case 'mental_health':
        return '''You're Starbound, and you're comfortable talking about mental health. You're supportive without being patronizing, and you know when to suggest professional help.''';
      case 'stress_management':
        return '''You're Starbound, and you get that stress is real and sometimes unavoidable. You focus on practical coping, not toxic positivity.''';
      case 'energy':
        return '''You're Starbound, and you understand energy management — why some days feel harder than others, and what actually helps (versus what sounds good but doesn't work).''';
      case 'motivation':
        return '''You're Starbound, and you know that motivation is complicated. You don't do generic pep talks — you help people find what works for their brain.''';
      case 'work_life':
        return '''You're Starbound, and you understand that work-life balance isn't always achievable, but you can help people manage what they're dealing with.''';
      case 'relationships':
        return '''You're Starbound, and you can talk about social connection and relationships in a grounded way — not self-help platitudes.''';
      default:
        return '''You're Starbound — a wellness companion that talks like a knowledgeable friend, not a chatbot. You're warm, practical, and honest.''';
    }
  }

  String _buildContextualFactors(Map<String, dynamic> context) {
    final factors = <String>[];

    final timeOfDay = context['timeOfDay'];
    if (timeOfDay != null) {
      final hour = timeOfDay is int ? timeOfDay : DateTime.now().hour;
      final timeContext = hour < 12
          ? 'morning'
          : hour < 17
              ? 'afternoon'
              : 'evening';
      factors.add('- Time: $timeContext session');
    }

    final habits = context['habits'];
    if (habits is Map && habits.isNotEmpty) {
      factors.add('- Current Habits: ${_summarizeHabits(habits)}');
    }

    final focusAreas = context['habitFocus'];
    if (focusAreas is List && focusAreas.isNotEmpty) {
      factors.add('- Needs attention: ${focusAreas.join(', ')}');
    }

    final habitWins = context['habitWins'];
    if (habitWins is List && habitWins.isNotEmpty) {
      factors.add('- Recent wins: ${habitWins.join(', ')}');
    }

    final recentNotes = context['recentNotes'];
    if (recentNotes is List && recentNotes.isNotEmpty) {
      factors.add('- Recent reflections: ${recentNotes.join(' | ')}');
    }

    final followUpAnswers = context['followUpAnswers'];
    if (followUpAnswers is List && followUpAnswers.isNotEmpty) {
      final formatted = followUpAnswers
          .map((entry) {
            if (entry is Map) {
              final question = entry['question']?.toString().trim() ?? '';
              final answer = entry['answer']?.toString().trim() ?? '';
              if (question.isNotEmpty && answer.isNotEmpty) {
                return 'Q: $question A: $answer';
              }
            }
            return '';
          })
          .where((line) => line.isNotEmpty)
          .toList();
      if (formatted.isNotEmpty) {
        factors.add('- Follow-up answers: ${formatted.join(' | ')}');
      }
    }

    final favoriteActions = context['favoriteActions'];
    if (favoriteActions is List && favoriteActions.isNotEmpty) {
      factors.add('- Favorite actions: ${favoriteActions.join(', ')}');
    }

    final savedActionSummaries = context['savedActionSummaries'];
    if (savedActionSummaries is List && savedActionSummaries.isNotEmpty) {
      factors.add('- Saved routines: ${savedActionSummaries.join(' | ')}');
    }

    final completedSteps = context['completedSessionSteps'];
    if (completedSteps is List && completedSteps.isNotEmpty) {
      factors.add('- Completed steps today: ${completedSteps.join(', ')}');
    }

    final activeTopic = context['activeConversationTopic'];
    if (activeTopic is String && activeTopic.isNotEmpty) {
      factors.add('- Ongoing topic: $activeTopic');
    }

    final detectedHabit = context['detectedHabit'];
    if (detectedHabit is String && detectedHabit.isNotEmpty) {
      factors.add('- Habit flagged recently: $detectedHabit');
    }

    final recentSuggestions = context['recentlySuggestedActions'];
    if (recentSuggestions is List && recentSuggestions.isNotEmpty) {
      factors
          .add('- Recent suggestions given: ${recentSuggestions.join('; ')}');
    }

    return factors.isNotEmpty
        ? factors.join('\n')
        : '- Context: Standard wellness consultation';
  }

  String _summarizeHabits(Map habits) {
    final summary = <String>[];
    habits.forEach((key, value) {
      if (value != null && value != 'good' && value != 'normal') {
        summary.add('$key: $value');
      }
    });
    return summary.isNotEmpty ? summary.join(', ') : 'baseline habits';
  }

  // Initialization methods

  Future<void> _initializeDemoMode() async {
    try {
      // Simulate loading time for enhanced AI
      await Future.delayed(const Duration(milliseconds: 500));
      if (kDebugMode) {
        print(
            '🤖 Enhanced AI simulation initialized - intelligent responses ready');
      }
    } catch (e) {
      // This should never happen, but ensure we never fail
      if (kDebugMode) {
        print('⚠️  Demo mode initialization error (ignoring): $e');
      }
    }
  }

  // AI inference simulation

  Future<String> _simulateGemmaInference(String prompt) async {
    if (kDebugMode) {
      print(
          '🎯 DEBUG: _simulateGemmaInference called - this is the ENHANCED AI');
    }

    // Simulate AI inference with realistic delay
    await Future.delayed(
        Duration(milliseconds: 800 + (DateTime.now().millisecond % 1200)));

    // Enhanced AI simulation - analyze the prompt more intelligently
    final response = _generateIntelligentResponse(prompt);

    if (kDebugMode) {
      print(
          '🎯 DEBUG: Enhanced simulation generated response: "${response.substring(0, 100)}..."');
    }

    return response;
  }

  Future<Map<String, dynamic>> _simulateGemmaInferenceWithSources(
      String prompt, String question, String complexityProfile) async {
    // Simulate AI inference with realistic delay
    await Future.delayed(
        Duration(milliseconds: 800 + (DateTime.now().millisecond % 1200)));

    // Enhanced AI simulation - analyze the prompt more intelligently
    final response = _generateIntelligentResponse(prompt);
    final sources = _generateSources(question, complexityProfile);

    return {
      'response': response,
      'sources': sources,
      'aiType': 'enhanced_simulation', // Indicator for UI
    };
  }

  String _generateIntelligentResponse(String prompt) {
    if (prompt.contains('CANONICAL ONTOLOGY') && prompt.contains('Input:')) {
      final entryMatch = RegExp(r'Input:\s*"([\s\S]*?)"\s*', multiLine: true)
          .firstMatch(prompt);
      final entryText = entryMatch?.group(1)?.trim() ?? '';
      return _generateSmartTaggingJson(entryText);
    }

    // Extract key information from prompt
    final question = _extractQuestionFromPrompt(prompt);
    final userName = _extractUserNameFromPrompt(prompt);
    final complexityProfile = _extractComplexityProfileFromPrompt(prompt);

    if (kDebugMode) {
      print('🔍 DEBUG _generateIntelligentResponse:');
      print('  Question: "$question"');
      print('  User: "$userName"');
      print('  Profile: "$complexityProfile"');

      if (question.isEmpty) {
        print('❌ WARNING: Question extraction failed from prompt!');
        print('🔍 DEBUG: Full prompt: "${prompt.substring(0, 200)}..."');
      }
    }

    // If question extraction failed, try to use the raw prompt
    final finalQuestion = question.isEmpty ? prompt : question;

    // Analyze question intent and generate appropriate response
    return _analyzeAndRespond(
        finalQuestion, userName, complexityProfile, prompt);
  }

  String _generateSmartTaggingJson(String entryText) {
    final lowerInput = entryText.toLowerCase();
    final matchedTags = <String>{};
    final keywordHits = <String, List<String>>{};

    for (final entry in _smartTagKeywordMap.entries) {
      final key = entry.key;
      final keywords = entry.value;
      final hits = <String>[];
      for (final keyword in keywords) {
        final regex = RegExp('\\b${RegExp.escape(keyword)}\\b');
        if (regex.hasMatch(lowerInput)) {
          hits.add(keyword);
        }
      }
      if (hits.isNotEmpty) {
        matchedTags.add(key);
        keywordHits[key] = hits;
      }
    }

    if (matchedTags.isEmpty) {
      matchedTags.add('mindful_break');
    }

    final hasNegation = lowerInput
        .contains(RegExp(r"\b(didn't|didnt|wasn't|wasnt|can't|cant|no)\b"));
    final hasUncertainty = lowerInput
        .contains(RegExp(r'\b(maybe|might|perhaps|unsure|not sure)\b'));

    final positiveWords = [
      'good',
      'great',
      'proud',
      'happy',
      'energised',
      'joy'
    ];
    final negativeWords = [
      'tired',
      'drained',
      'sad',
      'worried',
      'anxious',
      'overwhelmed'
    ];

    int positiveHit = positiveWords.where(lowerInput.contains).length;
    int negativeHit = negativeWords.where(lowerInput.contains).length;
    String sentiment = 'neutral';
    if (positiveHit > negativeHit) {
      sentiment = 'positive';
    } else if (negativeHit > positiveHit) {
      sentiment = 'negative';
    }

    final tags = matchedTags.take(5).map((canonicalKey) {
      final displayName = CanonicalOntology.getDisplayName(canonicalKey);
      final category =
          CanonicalOntology.getCategory(canonicalKey)?.name ?? 'choice';
      final subdomain =
          CanonicalOntology.getSubdomain(canonicalKey) ?? 'General';
      final keywords = keywordHits[canonicalKey] ?? [];

      return {
        'canonicalKey': canonicalKey,
        'displayName': displayName,
        'category': category,
        'subdomain': subdomain,
        'confidence': keywords.isNotEmpty ? 0.82 : 0.7,
        'evidenceSpan':
            entryText.length > 80 ? entryText.substring(0, 80) : entryText,
        'sentiment': sentiment,
        'sentimentConfidence': sentiment == 'neutral' ? 0.4 : 0.7,
        'keywords':
            keywords.isNotEmpty ? keywords : [entryText.split(' ').first],
        'hasNegation': hasNegation,
        'hasUncertainty': hasUncertainty,
        'metadata': {
          'source': 'gemma_simulation',
        }
      };
    }).toList();

    final followUps = <Map<String, dynamic>>[];
    final primaryTag =
        tags.isNotEmpty ? tags.first['canonicalKey'] as String : null;
    if (primaryTag != null && _smartTagFollowUpMap.containsKey(primaryTag)) {
      followUps.add(_smartTagFollowUpMap[primaryTag]!);
    }

    final result = {
      'smartTags': tags,
      'followUpQuestions': followUps,
    };

    return jsonEncode(result);
  }

  String _extractQuestionFromPrompt(String prompt) {
    // Look for "USER QUESTION:" pattern (updated format)
    final questionMatch =
        RegExp(r'USER QUESTION:\s*"([^"]*)"').firstMatch(prompt);
    if (questionMatch != null) {
      return questionMatch.group(1) ?? '';
    }

    // Fallback to old format for compatibility
    final oldQuestionMatch =
        RegExp(r'User Question:\s*"([^"]*)"').firstMatch(prompt);
    if (oldQuestionMatch != null) {
      return oldQuestionMatch.group(1) ?? '';
    }

    return '';
  }

  String _extractUserNameFromPrompt(String prompt) {
    // Look for "- Name:" pattern (updated format)
    final nameMatch = RegExp(r'-\s*Name:\s*([^\n]+)').firstMatch(prompt);
    if (nameMatch != null) {
      return nameMatch.group(1)?.trim() ?? '';
    }

    // Fallback to old format
    final oldNameMatch = RegExp(r'Name:\s*([^\n]+)').firstMatch(prompt);
    if (oldNameMatch != null) {
      return oldNameMatch.group(1)?.trim() ?? '';
    }
    return '';
  }

  String _extractComplexityProfileFromPrompt(String prompt) {
    // Look for "- Complexity Profile:" pattern (updated format)
    final profileMatch =
        RegExp(r'-\s*Complexity Profile:\s*([^\n]+)').firstMatch(prompt);
    if (profileMatch != null) {
      return profileMatch.group(1)?.trim() ?? '';
    }

    // Fallback to old format
    final oldProfileMatch =
        RegExp(r'Complexity Profile:\s*([^\n]+)').firstMatch(prompt);
    if (oldProfileMatch != null) {
      return oldProfileMatch.group(1)?.trim() ?? '';
    }
    return 'stable';
  }

  String _analyzeAndRespond(String question, String userName,
      String complexityProfile, String fullPrompt) {
    final questionLower = question.toLowerCase();

    // Check if this is a forecast request
    if (questionLower.contains('health forecast') ||
        fullPrompt.contains('requestType') &&
            fullPrompt.contains('health_forecast')) {
      if (kDebugMode) print('🤖 GemmaAI: Detected health forecast request');
      return ResponseFilter.processResponse(_generateForecastResponse(
          userName, complexityProfile, questionLower, fullPrompt));
    }
    final name = userName.isNotEmpty ? userName : 'friend';

    if (kDebugMode) {
      print(
          '🤖 GemmaAI: Analyzing question: "$questionLower" for user: "$name" with profile: "$complexityProfile"');
      print(
          '🔍 DEBUG: Health-related check: ${_isHealthRelated(questionLower)}');
      print('🔍 DEBUG: Food-related check: ${_isFoodRelated(questionLower)}');
      print(
          '🔍 DEBUG: Injury-related check: ${_isInjuryRelated(questionLower)}');
      if (_isHealthRelated(questionLower)) {
        print('🏥 DEBUG: Calling _generateHealthResponse');
      }
      if (_isFoodRelated(questionLower)) {
        print('🍎 DEBUG: Calling _generateFoodResponse');
      }
    }

    // Comprehensive question analysis - prioritize health/medical issues first
    if (_isInjuryRelated(questionLower)) {
      if (kDebugMode) print('🤖 GemmaAI: Detected injury-related question');
      return ResponseFilter.processResponse(
          _generateInjuryResponse(name, complexityProfile, questionLower));
    }

    if (_isHealthRelated(questionLower)) {
      if (kDebugMode) print('🤖 GemmaAI: Detected health-related question');
      return ResponseFilter.processResponse(
          _generateHealthResponse(name, complexityProfile, questionLower));
    }

    if (_isStressRelated(questionLower)) {
      if (kDebugMode) print('🤖 GemmaAI: Detected stress-related question');
      return ResponseFilter.processResponse(
          _generateStressResponse(name, complexityProfile, questionLower));
    }

    if (_isFoodRelated(questionLower)) {
      if (kDebugMode) print('🤖 GemmaAI: Detected food-related question');
      return ResponseFilter.processResponse(
          _generateFoodResponse(name, complexityProfile, questionLower));
    }

    if (_isSleepRelated(questionLower)) {
      return ResponseFilter.processResponse(
          _generateSleepResponse(name, complexityProfile, questionLower));
    }

    if (_isEnergyRelated(questionLower)) {
      return ResponseFilter.processResponse(
          _generateEnergyResponse(name, complexityProfile, questionLower));
    }

    if (_isMoodRelated(questionLower)) {
      return ResponseFilter.processResponse(
          _generateMoodResponse(name, complexityProfile, questionLower));
    }

    if (_isExerciseRelated(questionLower)) {
      return ResponseFilter.processResponse(
          _generateExerciseResponse(name, complexityProfile, questionLower));
    }

    if (_isMotivationRelated(questionLower)) {
      return ResponseFilter.processResponse(
          _generateMotivationResponse(name, complexityProfile, questionLower));
    }

    if (_isRelationshipRelated(questionLower)) {
      return ResponseFilter.processResponse(_generateRelationshipResponse(
          name, complexityProfile, questionLower));
    }

    if (_isWorkRelated(questionLower)) {
      return ResponseFilter.processResponse(
          _generateWorkResponse(name, complexityProfile, questionLower));
    }

    if (_isGeneralKnowledgeQuestion(questionLower)) {
      return ResponseFilter.processResponse(_generateGeneralKnowledgeResponse(
          name, complexityProfile, questionLower));
    }

    if (_isGoalOrFocusQuestion(questionLower)) {
      return ResponseFilter.processResponse(
          _generateGoalFocusResponse(name, complexityProfile, questionLower));
    }

    if (_isLifestyleQuestion(questionLower)) {
      return ResponseFilter.processResponse(
          _generateLifestyleResponse(name, complexityProfile, questionLower));
    }

    // Default response - now much more specific and helpful
    if (kDebugMode) {
      print(
          '🤖 GemmaAI: No specific category matched - using intelligent general response');
      print('🧠 DEBUG: Question: "$questionLower"');
      print(
          '🧠 DEBUG: This should generate a contextual response for ANY question');
    }
    return ResponseFilter.processResponse(_generateIntelligentGeneralResponse(
        name, complexityProfile, questionLower));
  }

  String _generateForecastResponse(String userName, String complexityProfile,
      String questionLower, String fullPrompt) {
    final name = userName.isNotEmpty ? userName : 'friend';

    // Extract habit from the prompt
    String habit = 'this habit';
    if (fullPrompt.contains('Current Habit Pattern:')) {
      final habitMatch =
          RegExp(r'Current Habit Pattern:\s*([^\n]+)').firstMatch(fullPrompt);
      if (habitMatch != null) {
        habit = habitMatch.group(1)?.trim() ?? habit;
      }
    }

    if (kDebugMode) {
      print(
          '🔮 GemmaAI: Generating forecast for habit: "$habit" with profile: "$complexityProfile"');
    }

    // Generate comprehensive, intelligent forecast for ANY habit
    return _generateUniversalForecastResponse(name, habit, complexityProfile);
  }

  String _generateUniversalForecastResponse(
      String name, String habit, String complexityProfile) {
    // Analyze the habit to understand its impact categories
    final categories = _analyzeHabitCategories(habit);

    // Generate structured forecast using the new format
    String confirmation = "**Forecast for: ${habit.toLowerCase()}**\n\n";
    String timeline =
        _generateTimelineForecast(habit, complexityProfile, categories);
    String nudge =
        _generateComplexityNudge(habit, complexityProfile, categories);
    String actionPrompt =
        "\n\n💬 Want to explore this further? Ask Starbound for personalized advice about ${habit.toLowerCase()}.";

    return "$confirmation$timeline$nudge$actionPrompt";
  }

  Set<String> _analyzeHabitCategories(String habit) {
    final habitLower = habit.toLowerCase();
    final categories = <String>{};

    // Physical health indicators
    if (habitLower.contains(RegExp(r'sleep|tired|rest|insomnia|bed|wake')))
      categories.add('sleep');
    if (habitLower.contains(RegExp(r'eat|food|meal|hungry|diet|nutrition')))
      categories.add('nutrition');
    if (habitLower
        .contains(RegExp(r'exercise|workout|movement|gym|run|walk|active')))
      categories.add('movement');
    if (habitLower.contains(RegExp(r'water|drink|hydrat')))
      categories.add('hydration');

    // Mental health indicators
    if (habitLower
        .contains(RegExp(r'stress|anxiety|worry|panic|overwhelm|pressure')))
      categories.add('stress');
    if (habitLower.contains(RegExp(r'mood|sad|happy|depress|anger|emotion')))
      categories.add('mood');
    if (habitLower.contains(RegExp(r'focus|concentrat|attention|distract')))
      categories.add('focus');

    // Behavioral indicators
    if (habitLower.contains(RegExp(r'smoking|drink|alcohol|substance')))
      categories.add('substance');
    if (habitLower.contains(RegExp(r'screen|phone|social media|technology')))
      categories.add('technology');
    if (habitLower.contains(RegExp(r'procrastinat|delay|avoid|postpone')))
      categories.add('avoidance');
    if (habitLower.contains(RegExp(r'social|relationship|people|connect')))
      categories.add('social');

    // Work/productivity indicators
    if (habitLower.contains(RegExp(r'work|job|productivity|deadline|task')))
      categories.add('work');
    if (habitLower.contains(RegExp(r'time|schedule|routine|organize')))
      categories.add('time');

    return categories;
  }

  String _generateTimelineForecast(
      String habit, String complexityProfile, Set<String> categories) {
    return '''**📅 In 1 month:**
${_generateBehavioralSection('1 month', habit, complexityProfile, categories)}

**📅 In 6 months:**
${_generateBehavioralSection('6 months', habit, complexityProfile, categories)}

**📅 In 1 year:**
${_generateBehavioralSection('1 year', habit, complexityProfile, categories)}

**📅 In 5 years:**
${_generateBehavioralSection('5 years', habit, complexityProfile, categories)}
''';
  }

  String _generateBehavioralSection(String timeframe, String habit,
      String complexityProfile, Set<String> categories) {
    String hook = _generateHookForTimeframe(timeframe, habit, categories);
    String why = _generateWhyForTimeframe(timeframe, habit, categories);
    String evidence = _generateEvidenceForTimeframe(timeframe, categories);
    String action =
        _generateActionForTimeframe(timeframe, habit, complexityProfile);
    String nudge = _generateNudgeForTimeframe(timeframe, habit);

    return '''**Hook:** $hook
**Why:** $why
**Evidence:** $evidence
**Action:** $action
**Nudge:** $nudge''';
  }

  String _generateHookForTimeframe(
      String timeframe, String habit, Set<String> categories) {
    switch (timeframe) {
      case '1 month':
        if (categories.contains('sleep'))
          return "By 1 month, your energy will feel more consistent and you'll wake up feeling actually refreshed";
        if (categories.contains('nutrition'))
          return "By 1 month, your energy will stabilize and you'll notice fewer afternoon crashes";
        if (categories.contains('movement'))
          return "By 1 month, your body will feel stronger and more alive throughout the day";
        if (categories.contains('hydration'))
          return "By 1 month, your energy will feel more reliable and your focus will be sharper";
        if (categories.contains('stress'))
          return "By 1 month, you'll feel more in control and less overwhelmed by daily challenges";
        return "By 1 month, you'll notice positive changes in your energy and mood";

      case '6 months':
        if (categories.contains('sleep'))
          return "By 6 months, quality sleep will become your superpower for handling stress and staying focused";
        if (categories.contains('nutrition'))
          return "By 6 months, healthy eating will feel natural and you'll love how your body feels";
        if (categories.contains('movement'))
          return "By 6 months, being active will be something you crave rather than avoid";
        if (categories.contains('hydration'))
          return "By 6 months, staying hydrated will be automatic and you'll feel the difference when you forget";
        if (categories.contains('stress'))
          return "By 6 months, you'll have reliable tools for managing stress that actually work";
        return "By 6 months, this positive change will feel like a natural part of who you are";

      case '1 year':
        if (categories.contains('sleep'))
          return "By 1 year, excellent sleep will boost your career performance and give you energy for relationships";
        if (categories.contains('nutrition'))
          return "By 1 year, your relationship with food will support everything else you want to achieve";
        if (categories.contains('movement'))
          return "By 1 year, your physical confidence will enhance every area of your life";
        if (categories.contains('hydration'))
          return "By 1 year, optimal hydration will support your mental clarity and physical performance";
        if (categories.contains('stress'))
          return "By 1 year, your stress management skills will give you confidence to take on bigger challenges";
        return "By 1 year, this change will have enhanced your overall quality of life significantly";

      case '5 years':
        if (categories.contains('sleep'))
          return "By 5 years, excellent sleep habits will help maintain your vitality and mental sharpness as you age";
        if (categories.contains('nutrition'))
          return "By 5 years, your nutrition habits will dramatically reduce health risks and keep you energized";
        if (categories.contains('movement'))
          return "By 5 years, staying active will keep you strong, confident, and injury-free";
        if (categories.contains('hydration'))
          return "By 5 years, proper hydration will support your long-term health and cognitive function";
        if (categories.contains('stress'))
          return "By 5 years, your stress resilience will be a cornerstone of your success and happiness";
        return "By 5 years, this change will have transformed your entire life trajectory";

      default:
        return "This change will create positive momentum in your life";
    }
  }

  String _generateWhyForTimeframe(
      String timeframe, String habit, Set<String> categories) {
    switch (timeframe) {
      case '1 month':
        return "Early improvements give you motivation and prove to yourself that change is possible, building confidence for bigger goals.";
      case '6 months':
        return "Sustained changes reshape your daily experience, boosting mood stability and giving you energy for work and relationships.";
      case '1 year':
        return "Long-term patterns enhance career performance, relationship quality, and give you the energy to pursue what matters most.";
      case '5 years':
        return "Excellent habits dramatically reduce health risks, maintain your vitality, and give you the foundation for a fulfilling life.";
      default:
        return "Positive changes compound over time, creating benefits that extend far beyond the original habit.";
    }
  }

  String _generateEvidenceForTimeframe(
      String timeframe, Set<String> categories) {
    switch (timeframe) {
      case '1 month':
        return "This is based on neuroplasticity research showing the brain adapts to new patterns within 2-4 weeks.";
      case '6 months':
        return "This is based on behavioral studies showing sustained changes become automatic around the 6-month mark.";
      case '1 year':
        return "This is based on longitudinal research on habit formation and its impact on life satisfaction over time.";
      case '5 years':
        return "This is based on population studies linking consistent healthy behaviors to longevity and quality of life.";
      default:
        return "This is based on research showing how small consistent changes create significant long-term benefits.";
    }
  }

  String _generateActionForTimeframe(
      String timeframe, String habit, String complexityProfile) {
    switch (timeframe) {
      case '1 month':
        return complexityProfile == 'survival'
            ? "Just focus on one tiny step you can take today, even if it's imperfect."
            : "Choose one specific aspect to work on and commit to trying it for just one week.";
      case '6 months':
        return "Create a simple tracking system and review your progress weekly to stay on course.";
      case '1 year':
        return "Set quarterly check-ins to maintain momentum and adjust your approach as needed.";
      case '5 years':
        return "Build a support system and make this change part of your identity for life.";
      default:
        return "Take one small step today that moves you in the right direction.";
    }
  }

  String _generateNudgeForTimeframe(String timeframe, String habit) {
    switch (timeframe) {
      case '1 month':
        return "Try this for just 7 days and notice what changes first - your energy, mood, or confidence.";
      case '6 months':
        return "Set a phone reminder to check in with yourself monthly about this change.";
      case '1 year':
        return "Put a calendar reminder to celebrate your progress and plan your next level of growth.";
      case '5 years':
        return "Take a moment to imagine your future self thanking you for starting this change today.";
      default:
        return "Start with the smallest possible step and build from there.";
    }
  }

  String _generate1YearForecast(
      String habit, String complexityProfile, Set<String> categories) {
    if (categories.contains('sleep')) {
      return "Chronic sleep issues could contribute to increased risk of depression, anxiety, and metabolic problems.";
    } else if (categories.contains('stress')) {
      return "Ongoing stress might lead to significant burnout, damaged relationships, and serious health complications.";
    } else if (categories.contains('nutrition')) {
      return "Nutrient deficiencies might start to show up — like brittle nails, frequent illness, or trouble concentrating.";
    } else if (categories.contains('movement')) {
      return "You could experience significant muscle loss, joint problems, and increased risk of chronic diseases.";
    } else if (categories.contains('technology')) {
      return "You might develop attention disorders, chronic eye problems, and severely disrupted real-world social skills.";
    } else if (categories.contains('substance')) {
      return "You could face dependency issues, significant health problems, and major life disruptions.";
    } else if (categories.contains('social')) {
      return "You might experience clinical-level social anxiety, depression, and loss of important relationships.";
    } else if (categories.contains('work')) {
      return "You could face severe burnout, career damage, and significant physical and mental health problems.";
    } else {
      return "This pattern could significantly impact your quality of life, relationships, and overall health and happiness.";
    }
  }

  String _generate5YearForecast(
      String habit, String complexityProfile, Set<String> categories) {
    if (categories.contains('sleep')) {
      return "Long-term sleep deprivation could contribute to serious risks including diabetes, heart disease, and cognitive decline.";
    } else if (categories.contains('stress')) {
      return "Chronic stress could lead to serious cardiovascular problems, autoimmune issues, and long-term mental health challenges.";
    } else if (categories.contains('nutrition')) {
      return "Chronic effects may include digestive issues, long-term fatigue, blood sugar instability, and bone health problems.";
    } else if (categories.contains('movement')) {
      return "You could face serious cardiovascular disease, severe muscle loss, bone density loss, and increased mortality risk.";
    } else if (categories.contains('technology')) {
      return "Long-term effects might include chronic vision problems, severe postural deformities, and inability to form meaningful relationships.";
    } else if (categories.contains('substance')) {
      return "You could face life-threatening health complications, complete social isolation, and potential legal or financial ruin.";
    } else if (categories.contains('social')) {
      return "Long-term isolation could contribute to severe depression, cognitive decline, and significantly shortened lifespan.";
    } else if (categories.contains('work')) {
      return "Chronic overwork could lead to serious cardiovascular disease, complete career burnout, and irreversible health damage.";
    } else {
      return "Over time, this pattern could fundamentally alter your life trajectory, health, and relationships in ways that become very difficult to reverse.";
    }
  }

  String _generateComplexityNudge(
      String habit, String complexityProfile, Set<String> categories) {
    String icon = "";
    String advice = "";

    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        icon = "🌱";
        if (categories.contains('nutrition')) {
          advice =
              "Just eating a piece of fruit or a small snack is a win. You don't have to cook a full meal to nourish yourself today.";
        } else if (categories.contains('sleep')) {
          advice =
              "Even lying down for 10 minutes with your eyes closed counts as rest. Your body needs any recovery it can get.";
        } else if (categories.contains('stress')) {
          advice =
              "Taking three deep breaths when you remember is enough right now. You're doing more than you realize just by surviving.";
        } else {
          advice =
              "Focus on just one tiny improvement today — even 5 minutes of self-care counts as a victory.";
        }
        break;
      case 'overloaded':
        icon = "⚖️";
        if (categories.contains('nutrition')) {
          advice =
              "Just eating a piece of fruit or a small snack is a win. You don't have to cook a full meal to fuel yourself today.";
        } else if (categories.contains('work')) {
          advice =
              "Try saying no to one small thing this week, or ask for help with just one task. You can't pour from an empty cup.";
        } else if (categories.contains('stress')) {
          advice =
              "Set one tiny boundary today — maybe not checking emails after 8pm, or taking 5 minutes to yourself.";
        } else {
          advice =
              "Try the 'minimum viable' approach — what's the smallest version of improvement you could manage right now?";
        }
        break;
      case 'trying':
        icon = "💡";
        if (categories.contains('nutrition')) {
          advice =
              "Try scheduling lunch in your calendar like a meeting — protect that time to nourish yourself.";
        } else if (categories.contains('sleep')) {
          advice =
              "Since you're already working on growth, try putting your phone in another room 30 minutes before bed.";
        } else if (categories.contains('movement')) {
          advice =
              "Start with just 2 minutes of movement daily — dancing to one song or walking around the block counts.";
        } else {
          advice =
              "Since you're already in a growth mindset, consider how this habit connects to your other goals — sometimes one small change helps everything.";
        }
        break;
      default: // stable
        icon = "💡";
        if (categories.contains('nutrition')) {
          advice =
              "Try scheduling lunch in your calendar like a meeting — protect that time to nourish yourself.";
        } else if (categories.contains('work')) {
          advice =
              "Consider time-blocking your schedule to include breaks, or setting boundaries around after-hours work.";
        } else if (categories.contains('technology')) {
          advice =
              "Try creating phone-free zones or times — like during meals or the first hour after waking up.";
        } else {
          advice =
              "Consider what the smallest, most manageable first step might be — small, consistent changes often have the biggest impact.";
        }
    }

    return "\n$icon **$advice**";
  }

  String _generateShortTermForecast(
      String habit, String complexityProfile, Set<String> categories) {
    if (categories.contains('sleep')) {
      return complexityProfile == 'survival'
          ? "In the next week, sleep issues could make everything feel harder - basic tasks, emotions, and coping with daily stress."
          : "Over the next week, you might notice increased fatigue, difficulty concentrating, and more irritability throughout the day.";
    } else if (categories.contains('stress')) {
      return complexityProfile == 'survival'
          ? "In the coming week, this stress pattern could make even simple daily tasks feel overwhelming and exhausting."
          : "Within a week, you may experience physical tension, headaches, difficulty sleeping, or digestive issues.";
    } else if (categories.contains('nutrition')) {
      return "In the next week, this eating pattern could affect your energy levels, mood stability, and ability to focus.";
    } else if (categories.contains('movement')) {
      return "Over the next week, lack of movement could contribute to lower energy, mood dips, and increased stiffness or restlessness.";
    } else if (categories.contains('technology')) {
      return "In the coming week, this technology pattern could affect your sleep quality, attention span, and real-world social connections.";
    } else if (categories.contains('substance')) {
      return complexityProfile == 'survival'
          ? "This week, this pattern could worsen feelings of anxiety, disrupt sleep, and make stress feel more intense."
          : "In the next week, this habit could affect your sleep quality, energy levels, and emotional regulation.";
    } else {
      return "In the coming week, this pattern could start affecting your daily energy, mood, and overall sense of wellbeing.";
    }
  }

  String _generateMidTermForecast(
      String habit, String complexityProfile, Set<String> categories) {
    if (categories.contains('sleep')) {
      return "Over the next month, chronic sleep issues could weaken your immune system and make you more susceptible to illness.";
    } else if (categories.contains('stress')) {
      return "Within a month, ongoing stress could begin affecting your relationships, work performance, and physical health.";
    } else if (categories.contains('nutrition')) {
      return "Over the next month, poor nutrition patterns could affect your mental clarity, emotional stability, and physical energy.";
    } else if (categories.contains('movement')) {
      return "Within a month, sedentary patterns could contribute to decreased cardiovascular health, muscle weakness, and mood changes.";
    } else if (categories.contains('technology')) {
      return "Over the next month, excessive screen time could contribute to eye strain, posture problems, and social isolation.";
    } else if (categories.contains('substance')) {
      return "Within a month, this pattern could create tolerance, affect your liver function, and impact your relationships.";
    } else {
      return "Over the next month, this pattern could become more entrenched, making positive changes feel increasingly difficult.";
    }
  }

  String _generateLongTermForecast(
      String habit, String complexityProfile, Set<String> categories) {
    if (categories.contains('sleep')) {
      return "Long-term, chronic sleep deprivation could contribute to increased risk of depression, anxiety, diabetes, and heart disease.";
    } else if (categories.contains('stress')) {
      return "Over 6 months, unmanaged stress could lead to burnout, relationship damage, and serious health complications.";
    } else if (categories.contains('nutrition')) {
      return "Long-term, poor nutrition could affect your immune system, bone health, and increase risk of chronic diseases.";
    } else if (categories.contains('movement')) {
      return "Over 6 months, lack of movement could contribute to muscle loss, bone density reduction, and increased disease risk.";
    } else if (categories.contains('technology')) {
      return "Long-term, this pattern could contribute to attention disorders, social anxiety, and disrupted real-world relationships.";
    } else if (categories.contains('substance')) {
      return "Over 6 months, this could lead to dependency, serious health problems, and significant life disruption.";
    } else {
      return "Long-term, this pattern could significantly impact your quality of life, relationships, and overall health.";
    }
  }

  String _generatePersonalizedAdvice(String habit, String complexityProfile) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Right now, focus on the tiniest possible step - even just acknowledging that you deserve care and support.";
      case 'overloaded':
        return "Consider starting with one small boundary or asking for help with just one aspect of this challenge.";
      case 'trying':
        return "Since you're already working on growth, think about how this connects to your other goals - sometimes one small change helps everything.";
      default:
        return "Consider what the smallest, most manageable first step might be - small, consistent changes often have the biggest impact.";
    }
  }

  // Question classification methods

  bool _isStressRelated(String question) {
    return question.contains('stress') ||
        question.contains('anxious') ||
        question.contains('overwhelmed') ||
        question.contains('panic') ||
        question.contains('worried') ||
        question.contains('nervous');
  }

  bool _isFoodRelated(String question) {
    // Don't treat as food advice if expressing dislike/aversion
    if (question.contains('hate') ||
        question.contains('dislike') ||
        question.contains("don't like") ||
        question.contains('cant stand') ||
        question.contains("can't stand")) {
      return false;
    }

    return question.contains('eat') ||
        question.contains('food') ||
        question.contains('hungry') ||
        question.contains('diet') ||
        question.contains('nutrition') ||
        question.contains('meal') ||
        question.contains('fruit') ||
        question.contains('vegetable') ||
        question.contains('drink') ||
        question.contains('snack');
  }

  bool _isSleepRelated(String question) {
    return question.contains('sleep') ||
        question.contains('tired') ||
        question.contains('rest') ||
        question.contains('insomnia') ||
        question.contains('bed') ||
        question.contains('wake');
  }

  bool _isEnergyRelated(String question) {
    // Check for energy-specific terms but avoid false positives
    if (question.contains('burned') || question.contains('burning')) {
      // Check if it's actually about injury/physical burns, not energy burnout
      if (question.contains('tongue') ||
          question.contains('skin') ||
          question.contains('finger') ||
          question.contains('hand') ||
          question.contains('accident') ||
          question.contains('hurt')) {
        return false; // This is about physical burns, not energy
      }
    }

    return question.contains('energy') ||
        question.contains('exhausted') ||
        question.contains('fatigue') ||
        question.contains('drain') ||
        question.contains('burnout') ||
        question.contains('burn out') ||
        question.contains('tired');
  }

  bool _isMoodRelated(String question) {
    return question.contains('mood') ||
        question.contains('sad') ||
        question.contains('happy') ||
        question.contains('feeling') ||
        question.contains('emotion') ||
        question.contains('depression') ||
        question.contains('joy') ||
        question.contains('anger');
  }

  bool _isExerciseRelated(String question) {
    // Don't treat as exercise advice if expressing dislike/aversion
    if (question.contains('hate') ||
        question.contains('dislike') ||
        question.contains("don't like") ||
        question.contains('cant stand') ||
        question.contains("can't stand")) {
      return false;
    }

    return question.contains('exercise') ||
        question.contains('workout') ||
        question.contains('movement') ||
        question.contains('fitness') ||
        question.contains('gym') ||
        question.contains('run') ||
        question.contains('walk') ||
        question.contains('yoga');
  }

  bool _isMotivationRelated(String question) {
    return question.contains('motivat') ||
        question.contains('inspire') ||
        question.contains('encourage') ||
        question.contains('goal') ||
        question.contains('purpose') ||
        question.contains('drive') ||
        question.contains('habit') ||
        question.contains('build') ||
        question.contains('change') ||
        question.contains('improve') ||
        question.contains('better') ||
        question.contains('start') ||
        question.contains('stuck') ||
        question.contains('procrastinat') ||
        question.contains('consistent') ||
        question.contains('discipline');
  }

  bool _isInjuryRelated(String question) {
    return (question.contains('burned') ||
            question.contains('burning') ||
            question.contains('cut') ||
            question.contains('bruise') ||
            question.contains('sprain') ||
            question.contains('injured') ||
            question.contains('accident') ||
            question.contains('bleeding') ||
            question.contains('swollen')) &&
        (question.contains('tongue') ||
            question.contains('finger') ||
            question.contains('hand') ||
            question.contains('foot') ||
            question.contains('skin') ||
            question.contains('arm') ||
            question.contains('leg') ||
            question.contains('myself'));
  }

  bool _isHealthRelated(String question) {
    return question.contains('health') ||
        question.contains('wellness') ||
        question.contains('sick') ||
        question.contains('doctor') ||
        question.contains('medical') ||
        question.contains('symptom') ||
        question.contains('pain') ||
        question.contains('ache') ||
        question.contains('hurt') ||
        question.contains('sore') ||
        question.contains('injury') ||
        question.contains('toe') ||
        question.contains('finger') ||
        question.contains('back') ||
        question.contains('head') ||
        question.contains('stomach') ||
        question.contains('body') ||
        question.contains('runny nose') ||
        question.contains('nose') ||
        question.contains('cold') ||
        question.contains('flu') ||
        question.contains('cough') ||
        question.contains('fever') ||
        question.contains('headache') ||
        question.contains('throat') ||
        question.contains('congested') ||
        question.contains('sneezing') ||
        question.contains('allergies') ||
        question.contains('itchy') ||
        question.contains('itch') ||
        question.contains('allergic') ||
        question.contains('reaction') ||
        question.contains('swelling') ||
        question.contains('hives') ||
        question.contains('rash') ||
        question.contains('tongue') ||
        question.contains('mouth') ||
        question.contains('lips');
  }

  bool _isRelationshipRelated(String question) {
    return question.contains('relationship') ||
        question.contains('friend') ||
        question.contains('family') ||
        question.contains('partner') ||
        question.contains('social') ||
        question.contains('connect');
  }

  bool _isWorkRelated(String question) {
    return question.contains('work') ||
        question.contains('job') ||
        question.contains('career') ||
        question.contains('professional') ||
        question.contains('colleague') ||
        question.contains('boss');
  }

  bool _isGeneralKnowledgeQuestion(String question) {
    return question.contains('how') ||
        question.contains('what') ||
        question.contains('when') ||
        question.contains('where') ||
        question.contains('why') ||
        question.contains('can you');
  }

  // Response generation methods

  String _generateStressResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, stress is a natural response when managing multiple demands. When stress feels overwhelming, here's what can help right now:\n\n1. Take three deep breaths, focusing only on your breathing.\n2. Drink a glass of water if you can manage it.\n\n**Next Steps:**\n• Remember that feeling stressed doesn't mean you're failing\n• Consider reaching out to someone you trust when you're ready";
      case 'overloaded':
        return "Hey $name, stress when you're already managing so much can feel impossible. Let's focus on tiny, manageable steps:\n\n1. Step outside for just 30 seconds and breathe fresh air.\n2. Drink some water or any liquid you have available.\n3. Put your hand on your chest and feel your heartbeat for 10 seconds.\n\n**Next Steps:**\n• Notice what time of day stress hits you hardest\n• Keep water nearby as a simple stress-relief tool";
      case 'trying':
        return "Hi $name, I can sense you're dealing with stress while working on other challenges too. That takes real strength. Here's a simple technique that can help:\n\n1. Try the 5-4-3-2-1 grounding technique: name 5 things you can see.\n2. Name 4 things you can touch, 3 you can hear.\n3. Name 2 things you can smell and 1 you can taste.\n\n**Next Steps:**\n• Practice this technique when you notice stress building\n• Remember that managing stress while trying other things is incredibly difficult";
      default:
        return "Hi $name, stress is your body's way of telling you something needs attention. Here's how you can respond mindfully:\n\n1. Identify what might be causing the stress right now.\n2. Ask yourself: \"What's one small change I can make?\"\n3. Take care of one basic need (food, water, rest, or movement).\n\n**Next Steps:**\n• Consider setting small boundaries to protect your energy\n• Monitor how sleep and nutrition affect your stress levels";
    }
  }

  String _generateFoodResponse(
      String name, String complexityProfile, String question) {
    // Check for specific food requests
    if (question.contains(RegExp(r'fruit|fruits'))) {
      return _generateFruitResponse(name, complexityProfile, question);
    }

    if (question.contains(RegExp(r'vegetable|vegetables|veggies'))) {
      return _generateVegetableResponse(name, complexityProfile, question);
    }

    if (question.contains(RegExp(r'water|hydrat|drink'))) {
      return _generateHydrationResponse(name, complexityProfile, question);
    }

    // General food response
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, when you're in survival mode, eating anything is better than nothing. Don't worry about perfect nutrition right now - focus on foods that feel manageable and give you some energy. Even a piece of toast or a banana is nourishing when you're struggling.";
      case 'overloaded':
        return "Hey $name, I get it - when you're overwhelmed, even deciding what to eat feels hard. Try to keep some simple options nearby: crackers, fruit, nuts, or anything that doesn't require much preparation. Your body needs fuel to cope with everything you're managing.";
      case 'trying':
        return "Hi $name, nutrition can feel complicated when you're managing other challenges. Start simple: try to include a protein (like eggs, yogurt, or nuts) and something fresh (like fruit or vegetables) in your meals when possible. Small, consistent choices often work better than big changes.";
      default:
        return "Hi $name, when you're unsure what to eat, think about what your body needs right now. Are you looking for energy, comfort, or nourishment? Try to balance protein, healthy fats, and complex carbs. If you're stressed, foods rich in magnesium (like leafy greens or nuts) and omega-3s (like salmon or walnuts) can help support your mood.";
    }
  }

  String _generateFruitResponse(
      String name, String complexityProfile, String question) {
    // Check if they specifically mention hating fruits
    final bool hatesFruits =
        question.contains('hate') && question.contains('fruit');

    if (hatesFruits) {
      switch (complexityProfile.toLowerCase()) {
        case 'survival':
          return "Hi $name, forcing yourself to eat something you dislike isn't sustainable. Try these gentle approaches: 1) Start with dried fruits (often sweeter), 2) Mix tiny amounts into foods you like (berries in yogurt), 3) Try fruit smoothies where you can't taste individual fruits, 4) Remember that vegetables can provide many of the same nutrients. Progress over perfection!";
        case 'overloaded':
          return "Hey $name, totally get it! When you hate fruits but want the nutrition, try these shortcuts: 1) Smoothies where you can mask the taste with protein powder, 2) Dried fruits or fruit leathers (sweeter), 3) Frozen fruit in oatmeal, 4) V8 or other vegetable juices for similar nutrients. Don't stress yourself - there are many ways to be healthy!";
        case 'trying':
          return "Hi $name, I appreciate your honesty! Hating fruits but wanting to eat them shows great self-awareness. Let's work with this: 1) Try different preparations (baked apples, grilled pineapple), 2) Mix with foods you love (fruit in pancakes), 3) Start with naturally sweeter fruits (mango, grapes), 4) Consider that you might just need the vitamins - vegetables can help too. What fruits have you tried that were least offensive?";
        default:
          return "Hi $name, this is actually a common challenge! Since you want the nutrition but dislike the taste, let's be strategic: 1) **Disguise method**: Blend fruits into smoothies with flavors you love, 2) **Texture solution**: Try freeze-dried fruits or fruit powders, 3) **Pairing strategy**: Combine with strong flavors (berries with dark chocolate), 4) **Alternative approach**: Focus on fruit-like vegetables (bell peppers, tomatoes) that provide similar nutrients. The goal is nutrition, not forcing yourself to suffer!";
      }
    }

    // Regular fruit advice for those who want to eat more
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, wanting to eat more fruit is wonderful! When you're in survival mode, start super simple: grab whatever fruit feels appealing and easy - bananas, apples, or oranges require no prep. Even canned fruit or applesauce counts. One piece of fruit today is better than none.";
      case 'overloaded':
        return "Hey $name, eating more fruit is a great goal! When you're busy, try these easy wins: keep bananas or apples on your counter, buy pre-cut fruit from the store, or add berries to your cereal. Make it so easy that grabbing fruit becomes the obvious choice when you're rushing.";
      case 'trying':
        return "Hi $name, I love that you want to eat more fruit! Start with one fruit you actually enjoy - don't force yourself to eat kale if you love strawberries. Try adding fruit to meals you already eat: berries in yogurt, banana with breakfast, or an apple as an afternoon snack. What's your favorite fruit?";
      default:
        return "Hi $name, that's fantastic! Fruits are packed with vitamins, fiber, and natural energy. Try these strategies: 1) Keep fruit visible (countertop bowl), 2) Prep fruit when you get home from shopping, 3) Pair fruit with protein (apple + peanut butter), 4) Try frozen fruit in smoothies. What fruits do you enjoy most?";
    }
  }

  String _generateVegetableResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, any vegetables you can manage are amazing! Try easy options: baby carrots, cherry tomatoes, or frozen vegetables you can microwave. Even having some V8 juice or adding spinach to a smoothie counts. Progress, not perfection.";
      case 'overloaded':
        return "Hey $name, vegetables can be simple! Try: pre-washed salad bags, frozen vegetable steamers, or adding vegetables to foods you already make (spinach in pasta, peppers in eggs). The easier it is, the more likely you'll do it consistently.";
      case 'trying':
        return "Hi $name, great goal! Start with vegetables you actually like - don't torture yourself with brussels sprouts if you love carrots. Try roasting vegetables with olive oil and salt, adding them to soups, or having raw veggies with hummus. What vegetables do you enjoy?";
      default:
        return "Hi $name, excellent choice! Vegetables provide essential nutrients and fiber. Try: 1) Fill half your plate with vegetables, 2) Try different cooking methods (roasted, grilled, raw), 3) Add vegetables to dishes you already make, 4) Experiment with seasonings. What's your favorite way to prepare vegetables?";
    }
  }

  String _generateHydrationResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, staying hydrated is so important, especially when you're struggling. Start simple: keep a water bottle nearby and try to sip throughout the day. If plain water feels hard, try adding a slice of lemon or drinking herbal tea. Any fluid helps.";
      case 'overloaded':
        return "Hey $name, when you're busy it's easy to forget to drink water! Try: setting phone reminders, keeping a large water bottle at your desk, or drinking a glass of water before each meal. Make it automatic so you don't have to think about it.";
      case 'trying':
        return "Hi $name, staying hydrated supports everything else you're working on - energy, mood, and focus. Try the 'water first' rule: drink water before coffee, meals, or snacks. If you find water boring, try sparkling water, herbal teas, or fruit-infused water.";
      default:
        return "Hi $name, great focus on hydration! Aim for about 8 glasses a day, but listen to your body. Try: drinking water when you wake up, having a glass before each meal, and keeping water visible. If you exercise or it's hot, you'll need more. What helps you remember to drink water?";
    }
  }

  String _generateSleepResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, when you're in survival mode, any rest you can get matters. Don't worry about perfect sleep - just focus on resting your body and mind when you can. Even lying down with your eyes closed for 20 minutes can help restore some energy.";
      case 'overloaded':
        return "Hey $name, sleep can feel impossible when your mind is racing. Try creating a simple wind-down routine: dim the lights, put your phone in another room, and focus on slow, deep breathing. Even 10 minutes of this can help signal to your body that it's time to rest.";
      case 'trying':
        return "Hi $name, sleep challenges are so common when you're managing a lot. Try the 3-2-1 rule: no food 3 hours before bed, no liquids 2 hours before, and no screens 1 hour before. Pick just one of these to start with - small changes can make a big difference.";
      default:
        return "Hi $name, good sleep is foundational for managing stress and maintaining energy. Consider your sleep environment (cool, dark, quiet), your bedtime routine, and what might be disrupting your sleep. Sometimes stress affects sleep, and poor sleep increases stress - breaking this cycle with small changes can help significantly.";
    }
  }

  String _generateEnergyResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, when you're in survival mode, energy is precious. Let's focus on the absolute basics:\n\n1. Drink water if you can manage it.\n2. Rest for even 5-10 minutes if possible.\n\n**Keep in Mind:**\n• Any sleep you can get is helping\n• Conserving energy is actually a smart strategy right now\n• You don't need to push yourself beyond what's necessary";
      case 'overloaded':
        return "Hey $name, low energy when you're overwhelmed makes complete sense. Try these micro-energy boosters:\n\n1. Take 2 minutes of deep breathing right now.\n2. Do gentle neck and shoulder stretches at your desk.\n3. Step outside briefly if you can.\n\n**Keep in Mind:**\n• Even the smallest energy-boosting actions count\n• Your body is working overtime managing everything";
      case 'trying':
        return "Hi $name, energy dips are normal when you're working on change. Here's what can help:\n\n1. Pair a protein with a complex carb (like apple with almond butter).\n2. Set a timer to drink water every hour.\n3. Take a 5-minute break between challenging tasks.\n\n**Keep in Mind:**\n• Your body needs consistent fuel when managing challenges\n• Energy management is part of the change process";
      default:
        return "Hi $name, sustainable energy comes from multiple factors working together. Let's start with what feels most manageable:\n\n1. Choose one area to focus on: sleep, nutrition, or movement.\n2. Make one small improvement in that area today.\n3. Notice how this small change affects your energy.\n\n**Keep in Mind:**\n• Quality sleep, balanced nutrition, and regular movement all support energy\n• Small, consistent changes often work better than big overhauls";
    }
  }

  String _generateMoodResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, your feelings are completely valid. When you're in survival mode, it's normal for mood to be difficult. You're not broken - you're human dealing with real challenges. Any small act of self-compassion counts as a victory right now.";
      case 'overloaded':
        return "Hey $name, mood swings when you're overwhelmed are your body's way of processing stress. Try to be gentle with yourself. Sometimes just acknowledging 'this is hard and I'm doing my best' can provide a tiny bit of relief.";
      case 'trying':
        return "Hi $name, mood changes while navigating challenges are completely normal. Consider what supports your emotional wellbeing: connection with others, time in nature, creative expression, or gentle movement. Even 5 minutes of something that feels good can help.";
      default:
        return "Hi $name, mood is influenced by many factors including sleep, nutrition, exercise, stress levels, and social connection. Notice patterns - what tends to lift your mood and what tends to drain it? Small, consistent practices often have more impact than big changes.";
    }
  }

  String _generateExerciseResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, when you're in survival mode, any movement is an achievement. Even stretching in bed, walking to the kitchen, or doing a few arm circles counts. Your body is working hard just to cope - be proud of any movement you can manage.";
      case 'overloaded':
        return "Hey $name, formal exercise might feel impossible when you're overwhelmed, and that's okay. Try integrating tiny movements into your day: stretch while waiting for coffee, take the stairs, or do some gentle neck rolls. Movement doesn't have to be scheduled to be beneficial.";
      case 'trying':
        return "Hi $name, starting with movement when you're managing challenges is smart. Try the 2-minute rule: commit to just 2 minutes of movement daily. It could be dancing to one song, walking around the block, or doing some stretches. Success builds on itself.";
      default:
        return "Hi $name, movement is medicine for both body and mind. Find what feels good for you - walking, dancing, yoga, swimming, or playing sports. The best exercise is the one you'll actually do. Start small and build gradually, focusing on how movement makes you feel rather than perfect form.";
    }
  }

  String _generateMotivationResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, you're asking about motivation while in survival mode, which shows incredible strength. Right now, motivation isn't about big goals - it's about recognizing that you're still here, still trying, still caring. That's heroic.";
      case 'overloaded':
        return "Hey $name, motivation when you're overwhelmed isn't about doing more - it's about recognizing that you're already doing so much. Sometimes the most motivating thing is to acknowledge your effort and give yourself permission to rest.";
      case 'trying':
        return "Hi $name, motivation often comes from small wins building up. Celebrate tiny victories - drinking water, taking a shower, reaching out for support. Progress isn't always linear, and that's perfectly normal. You're doing better than you think.";
      default:
        return "Hi $name, sustainable motivation comes from connecting with your values and breaking big goals into small, manageable steps. Remember your 'why' - what matters most to you? Then ask: what's the smallest step I can take today toward that? Motivation often follows action, not the other way around.";
    }
  }

  String _generateInjuryResponse(
      String name, String complexityProfile, String question) {
    // Extract specific injury from question
    String injuryType = 'injury';
    if (question.contains('burned') || question.contains('burning')) {
      injuryType = 'burn';
    } else if (question.contains('cut')) {
      injuryType = 'cut';
    } else if (question.contains('bruise')) {
      injuryType = 'bruise';
    }

    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, managing a $injuryType while dealing with other demands can be challenging.\n\n1. Apply basic first aid if you haven't already (cool water for burns, clean cloth for cuts).\n2. Keep the area clean and dry.\n\n**Keep in Mind:**\n• If pain is severe or gets worse, consider seeking medical attention\n• Your body needs extra care right now while healing\n• Small injuries matter - don't ignore them because other things feel more urgent";
      case 'overloaded':
        return "Hey $name, dealing with a $injuryType when you're already juggling everything else is frustrating. Let's keep this simple:\n\n1. Take care of immediate first aid needs.\n2. Monitor it for the next day or two for any changes.\n3. Be gentle with that area while it heals.\n\n**Keep in Mind:**\n• Your body is trying to heal while you're managing everything else\n• If it's not improving in a few days, consider checking with a healthcare provider\n• This is a reminder to slow down just a bit if possible";
      case 'trying':
        return "Hi $name, injuries like your $injuryType can be setbacks when you're working on other challenges, but they're also reminders to be kind to yourself.\n\n1. Follow proper first aid care for your specific injury.\n2. Keep an eye on healing progress over the next few days.\n3. Adjust your activities if needed to avoid making it worse.\n\n**Keep in Mind:**\n• Healing takes energy - be patient with yourself during recovery\n• This might be your body's way of asking you to slow down\n• Small injuries can teach us about taking better care of ourselves";
      default:
        return "Hi $name, let's make sure you're taking proper care of your $injuryType:\n\n1. Apply appropriate first aid treatment based on the type of injury.\n2. Keep the area clean and protected from further damage.\n3. Monitor healing progress and watch for signs of infection.\n\n**Keep in Mind:**\n• Most minor injuries heal well with proper care and time\n• If symptoms worsen or don't improve, consult a healthcare provider\n• Use this as a reminder to be more mindful of your physical safety";
    }
  }

  String _generateHealthResponse(
      String name, String complexityProfile, String question) {
    // Determine specific health issue from question
    String specificGuidance = "";
    if (question.contains("itchy") ||
        question.contains("allergic") ||
        question.contains("reaction")) {
      specificGuidance = "for managing allergic reactions and symptoms";
    } else if (question.contains("runny nose") ||
        question.contains("nose") ||
        question.contains("cold")) {
      specificGuidance = "for managing cold symptoms like a runny nose";
    } else if (question.contains("headache") || question.contains("head")) {
      specificGuidance = "for addressing headache relief";
    } else if (question.contains("throat")) {
      specificGuidance = "for soothing throat discomfort";
    } else {
      specificGuidance = "for supporting your health";
    }

    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return '''Hi $name, dealing with health concerns while managing significant stress is challenging. When you're in survival mode, your body's healing capacity is already stretched thin, so let's work with your current reality $specificGuidance.

**Step 1:** Apply "minimum effective dose" - choose the single most impactful health action you can sustain (usually hydration or rest).
**Step 2:** Use "environmental design" - make healthy choices the easiest option by preparing what you need in advance when you have any energy.

**Keep in Mind:**
• Stress hormones actively interfere with healing - your gentleness with yourself is medicine
• Research shows that self-compassion boosts immune function more than self-criticism
• Your nervous system needs safety signals right now, not additional pressure''';
      case 'overloaded':
        return '''Hey $name, I recognize you're trying to maintain your health while juggling multiple demands. Your cognitive load is already maxed out, so let's use behavioral shortcuts to make health easier $specificGuidance.

**Step 1:** Use "habit stacking" - attach one health behavior to something you already do automatically (like drinking water after using the bathroom).
**Step 2:** Apply "implementation intentions" - create specific if-then plans: "If I feel overwhelmed, then I will take 3 deep breaths."
**Step 3:** Design your environment for success - put healthy options in visible, easy-to-reach places.

**Keep in Mind:**
• Decision fatigue makes healthy choices harder - create automatic systems instead
• Your overwhelmed brain responds better to simple, binary choices than complex decisions
• Small, consistent actions compound more effectively than sporadic intense efforts''';
      case 'trying':
        if (question.contains("itchy") &&
            (question.contains("kiwi") ||
                question.contains("fruit") ||
                question.contains("eating"))) {
          return '''Hi $name, itchy tongue after eating certain foods is often a sign of a food allergy or sensitivity. Here's how to approach this safely:

**Step 1:** Stop eating kiwis and any related fruits immediately to avoid worsening the reaction.
**Step 2:** Keep a food diary to track when symptoms occur and which foods might be triggers.
**Step 3:** Consider consulting with a healthcare provider about food allergy testing.

**Keep in Mind:**
• Food allergies can worsen over time, so it's important to identify triggers early
• Some fruits (like kiwi, banana, avocado) share similar proteins and may cause cross-reactions
• If you experience difficulty breathing or swelling, seek immediate medical attention''';
        }
        return '''Hi $name, health improvements work best when they're gradual and sustainable. Here's how to approach this $specificGuidance:

**Step 1:** Identify what aspect feels most important right now - rest, nutrition, or stress management.
**Step 2:** Choose one small change you can make consistently for the next week.
**Step 3:** Notice how this change affects your overall well-being without judging yourself.

**Keep in Mind:**
• Focus on one area at a time rather than trying to change everything
• Progress isn't always linear when you're building new habits
• Your body responds better to gentle, consistent care''';
      default:
        return '''Hi $name, good health is built on consistent small choices rather than dramatic changes. Here's a balanced approach $specificGuidance:

**Step 1:** Assess which health fundamental needs attention - sleep, nutrition, movement, or stress management.
**Step 2:** Choose one area to focus on and make a specific, small improvement.
**Step 3:** Build this into your routine for two weeks before adding anything new.

**Keep in Mind:**
• All health fundamentals work together to support your well-being
• Sustainable changes are more valuable than perfect short-term fixes
• Listen to your body and adjust your approach as needed''';
    }
  }

  String _generateRelationshipResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, maintaining relationships in survival mode is tough, but connection is healing. Even small gestures count - a text to say you're thinking of someone, asking for help when you need it, or just being honest about where you are. People who care about you want to support you.";
      case 'overloaded':
        return "Hey $name, relationships when you're overwhelmed require boundaries and honesty. It's okay to tell people you're going through a tough time and need space, or conversely, that you need extra support. Real connections can handle the truth about what you're experiencing.";
      case 'trying':
        return "Hi $name, nurturing relationships while managing challenges takes intention but it's worth it. Consider reaching out to one person this week - whether for support, to check in on them, or just to share something you're grateful for. Connection doesn't always have to be heavy or problem-focused.";
      default:
        return "Hi $name, healthy relationships require both giving and receiving, boundaries and vulnerability. Think about what you need from your relationships right now and what you're able to offer. Sometimes the most loving thing is honest communication about your capacity and needs.";
    }
  }

  String _generateWorkResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, work in survival mode means focusing on the essentials. Do what you absolutely must, communicate your limitations when possible, and don't take on extra responsibilities. Your job is to get through this period, not to excel at everything.";
      case 'overloaded':
        return "Hey $name, work when you're overwhelmed requires ruthless prioritization. Focus on your most important tasks, delegate when possible, and don't be afraid to communicate with your manager about your capacity. Taking care of yourself ultimately helps you be more effective at work.";
      case 'trying':
        return "Hi $name, balancing work while managing other challenges requires clear boundaries and realistic expectations. Consider what work practices support your wellbeing - regular breaks, organized workspace, clear priorities. Small changes in how you approach work can make a big difference.";
      default:
        return "Hi $name, sustainable work performance comes from managing energy, not just time. Think about when you do your best work, what drains you, and what gives you energy. Building work habits that align with your natural rhythms and values can improve both productivity and satisfaction.";
    }
  }

  String _generateGeneralKnowledgeResponse(
      String name, String complexityProfile, String question) {
    return "Hi $name, I'm here to help with wellness and personal growth questions. While I can provide general guidance, I'm most effective when helping you navigate health, stress, relationships, and personal development challenges. Is there something specific about your wellbeing I can help you with today?";
  }

  bool _isGoalOrFocusQuestion(String question) {
    return question.contains(RegExp(
        r'focus|goal|priority|prioriti|next|direction|path|should i|what to|where to|improve|progress|grow'));
  }

  bool _isLifestyleQuestion(String question) {
    return question.contains(RegExp(
        r'routine|schedule|daily|morning|evening|habit|lifestyle|balance|time'));
  }

  String _generateGoalFocusResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, when you're in survival mode, the most important focus is basic care: one meal, one hour of rest, one moment of safety. Don't worry about big goals right now - focus on the next small thing that will help you feel a bit more stable. That's enough. What would feel most essential today?";
      case 'overloaded':
        return "Hey $name, with everything on your plate, focus on what's truly urgent vs. what feels urgent. Pick ONE thing that would reduce the most stress if completed. Let everything else wait. Your energy is precious - invest it where it matters most. What would give you the biggest relief right now?";
      case 'trying':
        return "Hi $name, I love that you're thinking about what to focus on next - that shows real intention. Since you're working through challenges, I'd suggest focusing on building one small, consistent habit that supports your foundation. Maybe better sleep, regular meals, or 5 minutes of daily movement. What feels doable but meaningful to you?";
      default:
        return "Hi $name, great question! For someone in a stable place, I'd recommend focusing on something that combines growth with joy. Maybe: 1) A skill you've wanted to develop, 2) Deeper connection with someone important, or 3) A physical challenge that excites you. What area of your life feels ready for positive attention?";
    }
  }

  String _generateLifestyleResponse(
      String name, String complexityProfile, String question) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return "Hi $name, right now the best routine is whatever helps you get through each day safely. Focus on basics: eating something, sleeping when you can, and staying connected to supportive people. Rigid schedules can wait - survival comes first. What small routine has been helping you feel more grounded?";
      case 'overloaded':
        return "Hey $name, with your packed schedule, the key is ruthless simplification. Pick 3 non-negotiables (sleep time, one meal, one moment to breathe) and protect those fiercely. Everything else is flexible. Your routine should reduce decisions, not add pressure. What would make your days feel more manageable?";
      case 'trying':
        return "Hi $name, building sustainable routines while managing challenges takes patience. Start with anchoring one or two activities at consistent times - maybe morning water and evening wind-down. Let everything else be flexible until these feel natural. What routine element would support you most right now?";
      default:
        return "Hi $name, you're in a great position to design a routine that truly serves you! Think about your energy patterns, values, and what brings you joy. The best routines feel supportive, not restrictive. Consider morning intention-setting, regular movement, and evening reflection. What would make your days feel most fulfilling?";
    }
  }

  String _generateDislikeResponse(
      String name, String complexityProfile, String question) {
    // Identify what they dislike
    String dislikedThing = "that";
    if (question.contains('exercise') || question.contains('workout')) {
      dislikedThing = "exercising";
    } else if (question.contains('fruit')) {
      dislikedThing = "fruits";
    } else if (question.contains('vegetable')) {
      dislikedThing = "vegetables";
    } else if (question.contains('work')) {
      dislikedThing = "work";
    }

    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return '''Hi $name, acknowledging that you don't like $dislikedThing is completely valid. When you're in survival mode, it's completely okay to acknowledge what doesn't work for you right now.

**Step 1:** Accept that your current feelings are valid - you don't have to force yourself to like everything.
**Step 2:** Focus on what you can manage today, without adding pressure to change your preferences.

**Keep in Mind:**
• Your preferences matter and deserve respect
• You don't have to fix everything about yourself right now
• Sometimes our dislikes protect us from overwhelm''';
      case 'overloaded':
        return '''Hey $name, when you're overwhelmed, having preferences about $dislikedThing is natural. Let's work with your preferences, not against them.

**Step 1:** Acknowledge that it's okay to not like certain things - this is self-awareness, not a flaw.
**Step 2:** Consider if there are any gentle alternatives that feel more appealing to you.
**Step 3:** Remove any pressure to "fix" this dislike right now.

**Keep in Mind:**
• Your dislikes often tell you important information about your needs
• You can pursue wellness in ways that feel good to you
• There's no one-size-fits-all approach to healthy living''';
      case 'trying':
        return '''Hi $name, I appreciate your honesty about not liking $dislikedThing. This self-awareness is actually valuable data for building sustainable habits. Let's use behavioral science to work with your preferences, not against them.

**Step 1:** Apply "preference mapping" - identify specifically what you dislike (the activity, timing, context, or past associations) to find alternatives.
**Step 2:** Use "substitution strategies" - find activities that provide similar benefits but align better with your natural preferences and interests.
**Step 3:** Try "implementation intentions" - create if-then plans for alternatives: "If I need [benefit], then I will [preferred alternative] instead."

**Keep in Mind:**
• Research shows that intrinsic motivation (doing what you enjoy) is more sustainable than extrinsic pressure
• Your preferences contain valuable information about what will work for your unique psychology
• Behavioral change succeeds when you design around your authentic self, not against it''';
      default:
        return '''Hi $name, having preferences about $dislikedThing is completely valid. Understanding your preferences is an important part of building a sustainable wellness approach.

**Step 1:** Reflect on what specifically doesn't appeal to you - this insight can guide better choices.
**Step 2:** Explore alternatives that align more with your natural preferences and interests.
**Step 3:** Design your wellness approach around activities and foods you genuinely enjoy.

**Keep in Mind:**
• Sustainable wellness comes from working with your preferences, not against them
• Your dislikes often point toward what you actually need and want
• There are countless ways to be healthy - find the ones that feel good to you''';
    }
  }

  String _generateIntelligentGeneralResponse(
      String name, String complexityProfile, String question) {
    if (kDebugMode) {
      print('🧠 DEBUG: _generateIntelligentGeneralResponse called');
      print('🧠 DEBUG: Question: "$question"');
      print('🧠 DEBUG: User: "$name", Profile: "$complexityProfile"');
    }

    // Handle dislike/aversion questions with empathy and alternatives
    if (question.contains('hate') ||
        question.contains('dislike') ||
        question.contains("don't like") ||
        question.contains('cant stand') ||
        question.contains("can't stand")) {
      if (kDebugMode) {
        print(
            '🧠 DEBUG: Detected dislike/aversion - using specialized response');
      }
      return _generateDislikeResponse(name, complexityProfile, question);
    }

    // Extract key themes and generate contextual response
    final questionTheme = _identifyQuestionTheme(question);
    final keyWords = _extractKeyQuestionWords(question);
    final questionIntent = _analyzeQuestionIntent(question);

    if (kDebugMode) {
      print('🧠 DEBUG: Theme: "$questionTheme"');
      print('🧠 DEBUG: Keywords: $keyWords');
    }

    // Generate a response that directly addresses what they're asking about
    String contextualGuidance =
        _generateContextualGuidance(question, questionTheme, keyWords);

    // Analyze the question more deeply to provide specific guidance
    if (question.contains(RegExp(r'how|what|why|when|where'))) {
      return _generateHowToResponse(name, complexityProfile, question);
    }

    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return '''Hi $name, navigating ${questionTheme.isNotEmpty ? questionTheme : 'challenging situations'} requires effort and planning. When you're in survival mode, even thinking about this topic takes courage. $contextualGuidance

**Step 1:** Apply the "minimum viable action" principle - identify the smallest possible step related to your question that requires almost no energy.
**Step 2:** Use the "external scaffolding" approach - lean on any available support, resources, or people rather than trying to handle this alone.

**Keep in Mind:**
• Behavioral science shows that micro-actions build momentum when energy is low
• Your brain is conserving resources right now - work with this, not against it
• Progress in survival mode looks different but is equally valuable''';
      case 'overloaded':
        return '''Hey $name, I recognize you're managing ${questionTheme.isNotEmpty ? questionTheme : 'multiple competing demands right now'}. When you're overloaded, your cognitive load is already maxed out, so let's use behavioral science to make this easier. $contextualGuidance

**Step 1:** Apply "satisficing" (not optimizing) - choose a "good enough" approach rather than trying to find the perfect solution.
**Step 2:** Use the "implementation intention" technique - decide specifically when and where you'll address this: "When [trigger], I will [specific action]."
**Step 3:** Create a "stop-doing" boundary - identify one thing you can temporarily stop or delegate to make space for this.

**Keep in Mind:**
• Research shows that decision fatigue is real - simplify choices wherever possible
• Your brain needs cognitive rest between complex decisions
• "Good enough" solutions often work better than perfect ones when you're overwhelmed''';
      case 'trying':
        return '''Hi $name, I appreciate you taking action on ${questionTheme.isNotEmpty ? questionTheme : 'something that matters to you'}. You're in the "trying" phase, which means you have motivation but may need better systems and accountability. $contextualGuidance

**Step 1:** Use "temptation bundling" - pair addressing this question with something you already enjoy or do regularly.
**Step 2:** Apply the "2-minute rule" - identify a version of progress that takes less than 2 minutes, then do it consistently.
**Step 3:** Create an "implementation plan" - write down: If X happens, then I will Y (specific behavioral response).

**Keep in Mind:**
• Behavioral science shows that consistency beats intensity for building new patterns
• Your brain is actively trying to form new habits - support this process with clear cues
• Small wins create psychological momentum that builds over time''';
      default:
        final response =
            '''Hi $name, I can see you're thoughtfully considering ${questionTheme.isNotEmpty ? questionTheme : 'how to approach this situation'}. Since you're in a stable place, we can use more advanced behavioral strategies to create lasting change. $contextualGuidance

**Step 1:** Apply "mental contrasting" - visualize your desired outcome, then honestly assess current obstacles, and create specific if-then plans to overcome them.
**Step 2:** Use "commitment devices" - create accountability by telling someone your intention or setting up consequences that make following through easier than giving up.
**Step 3:** Implement "systematic experimentation" - try your approach for a defined period, measure results, then iterate based on what you learn.

**Keep in Mind:**
• Research shows that optimizing systems beats relying on motivation for sustained change
• Your stable foundation allows for strategic risk-taking and longer-term thinking
• Advanced behavior change involves testing, measuring, and refining your approach''';

        if (kDebugMode) {
          print(
              '🧠 DEBUG: Generated intelligent general response: "${response.substring(0, 100)}..."');
        }
        return response;
    }
  }

  /// Extract the main theme from a question to personalize responses
  String _identifyQuestionTheme(String question) {
    final cleanQuestion = question.toLowerCase().trim();

    // Look for specific topics in the question
    if (cleanQuestion
        .contains(RegExp(r'work|job|career|boss|meeting|deadline|office'))) {
      return 'work and career challenges';
    }
    if (cleanQuestion.contains(
        RegExp(r'relationship|partner|friend|family|social|lonely|connect'))) {
      return 'relationships and connections';
    }
    if (cleanQuestion
        .contains(RegExp(r'money|financial|budget|debt|expense|cost|afford'))) {
      return 'financial concerns';
    }
    if (cleanQuestion
        .contains(RegExp(r'time|busy|schedule|manage|overwhelm|priority'))) {
      return 'time management and priorities';
    }
    if (cleanQuestion
        .contains(RegExp(r'decision|choice|choose|confused|uncertain|doubt'))) {
      return 'decision-making and uncertainty';
    }
    if (cleanQuestion
        .contains(RegExp(r'goal|achieve|success|progress|improve|better'))) {
      return 'goals and personal growth';
    }
    if (cleanQuestion
        .contains(RegExp(r'change|different|new|start|begin|transition'))) {
      return 'change and transitions';
    }
    if (cleanQuestion
        .contains(RegExp(r'habit|routine|daily|regular|consistent'))) {
      return 'habits and routines';
    }
    if (cleanQuestion
        .contains(RegExp(r'confidence|self.*esteem|worth|doubt|insecure'))) {
      return 'self-confidence and self-worth';
    }
    if (cleanQuestion
        .contains(RegExp(r'balance|juggle|manage.*everything|too.*much'))) {
      return 'life balance';
    }

    // Extract key action words or topics
    final actionWords =
        RegExp(r'\b(do|handle|deal|manage|cope|fix|solve|help|support)\b')
            .allMatches(cleanQuestion);
    if (actionWords.isNotEmpty) {
      return 'finding solutions and coping strategies';
    }

    // Look for question words to understand intent
    if (cleanQuestion.contains(RegExp(r'why.*feel|why.*happen|why.*keep'))) {
      return 'understanding patterns and feelings';
    }
    if (cleanQuestion.contains(RegExp(r'what.*should|what.*can|what.*need'))) {
      return 'finding direction and next steps';
    }
    if (cleanQuestion.contains(RegExp(r'how.*stop|how.*prevent|how.*avoid'))) {
      return 'breaking unwanted patterns';
    }

    return ''; // Return empty if no clear theme is identified
  }

  /// Extract key action words and nouns from the question
  List<String> _extractKeyQuestionWords(String question) {
    final cleanQuestion = question.toLowerCase().trim();
    final words = cleanQuestion.split(RegExp(r'\s+'));

    // Important action words and question indicators
    final keyWords = <String>[];
    for (final word in words) {
      if (word.length > 3 &&
          ![
            'with',
            'that',
            'this',
            'have',
            'been',
            'will',
            'what',
            'when',
            'where',
            'how',
            'why'
          ].contains(word)) {
        keyWords.add(word);
      }
    }
    return keyWords.take(5).toList(); // Limit to most important words
  }

  /// Analyze the intent behind a question
  String _analyzeQuestionIntent(String question) {
    final cleanQuestion = question.toLowerCase().trim();

    if (cleanQuestion
        .contains(RegExp(r'help|support|advice|guidance|what.*do'))) {
      return 'seeking_help';
    }
    if (cleanQuestion.contains(RegExp(r'feel|feeling|emotion|mood'))) {
      return 'emotional_support';
    }
    if (cleanQuestion
        .contains(RegExp(r'how.*stop|how.*prevent|how.*avoid|get.*rid'))) {
      return 'problem_solving';
    }
    if (cleanQuestion.contains(RegExp(r'why.*happen|why.*feel|why.*keep'))) {
      return 'understanding';
    }
    if (cleanQuestion.contains(RegExp(r'should.*do|need.*do|what.*next'))) {
      return 'direction_seeking';
    }
    return 'general_inquiry';
  }

  /// Generate contextual guidance based on what the user is actually asking about
  String _generateContextualGuidance(
      String question, String theme, List<String> keyWords) {
    final cleanQuestion = question.toLowerCase().trim();

    // Generate behaviorally-informed contextual guidance
    if (keyWords
        .any((word) => ['pain', 'hurt', 'ache', 'sore'].contains(word))) {
      return "Pain signals activate your nervous system's threat response, which affects decision-making and emotional regulation.";
    }
    if (keyWords.any(
        (word) => ['anxious', 'anxiety', 'worry', 'nervous'].contains(word))) {
      return "Anxiety is your brain's early warning system - it can be managed through specific behavioral techniques that calm your nervous system.";
    }
    if (keyWords.any((word) =>
        ['busy', 'overwhelmed', 'too much', 'stressed'].contains(word))) {
      return "Cognitive overload happens when demands exceed your mental processing capacity - the solution involves strategic reduction and boundaries.";
    }
    if (keyWords.any(
        (word) => ['stuck', 'confused', 'lost', 'direction'].contains(word))) {
      return "Feeling stuck often means you need to change your environment, perspective, or approach - small experiments can reveal new paths.";
    }
    if (keyWords.any((word) =>
        ['motivation', 'motivated', 'energy', 'drive'].contains(word))) {
      return "Behavioral science shows that motivation is unreliable - sustainable change comes from designing better systems and environments.";
    }
    if (keyWords.any((word) =>
        ['relationship', 'family', 'friend', 'partner'].contains(word))) {
      return "Healthy relationships require clear communication patterns, consistent boundaries, and mutual emotional regulation skills.";
    }
    if (keyWords
        .any((word) => ['work', 'job', 'career', 'boss'].contains(word))) {
      return "Work stress affects both performance and wellbeing - effective solutions address both environmental factors and personal responses.";
    }

    // Fallback based on question theme
    if (theme.isNotEmpty) {
      return "Research shows that complex situations respond best to systematic approaches that address both immediate needs and underlying patterns.";
    }

    return "Every situation has behavioral and environmental factors that can be optimized - small changes in approach often create significant results.";
  }

  String _generateHowToResponse(
      String name, String complexityProfile, String question) {
    if (question.contains(RegExp(r'how.*feel|how.*better|how.*improve'))) {
      switch (complexityProfile.toLowerCase()) {
        case 'survival':
          return "Hi $name, feeling better in survival mode means focusing on basics: one good meal, some rest, a moment of safety, or connection with someone who cares. These aren't luxuries - they're necessities. What basic need feels most important right now?";
        case 'overloaded':
          return "Hey $name, when you're overwhelmed, feeling better often means doing less, not more. Try: 5 deep breaths, saying no to one thing, or asking for help with something. Relief comes from reducing pressure, not adding more tasks. What would lighten your load today?";
        case 'trying':
          return "Hi $name, improvement during challenges means honoring where you are while taking tiny steps forward. Maybe it's a 5-minute walk, one healthy meal, or calling someone supportive. Progress counts, no matter how small. What small step feels possible today?";
        default:
          return "Hi $name, feeling better is often about alignment - making sure your daily actions match your values and energy. Try: moving your body, connecting meaningfully with others, doing something creative, or spending time in nature. What usually energizes you?";
      }
    }

    return _generateIntelligentGeneralResponse(
        name, complexityProfile, question);
  }

  // Response processing methods

  String _processQuestionResponse(String response) {
    final cleaned = response.trim();

    // Ensure appropriate length for chat responses
    if (cleaned.length > 300) {
      return cleaned.substring(0, 297) + '...';
    }

    // Check for inappropriate content
    if (_containsInappropriateContent(cleaned)) {
      return 'I appreciate your question, but I need to keep our conversation focused on wellness and habits. How can I help you with your health journey today?';
    }

    // Ensure the response is helpful and supportive
    if (cleaned.length < 10) {
      return 'Could you tell me a bit more about what you\'re experiencing so I can provide better guidance?';
    }

    return cleaned;
  }

  bool _containsInappropriateContent(String content) {
    final inappropriate = ['hate', 'violent', 'harmful', 'illegal', 'explicit'];
    final lower = content.toLowerCase();
    return inappropriate.any((word) => lower.contains(word));
  }

  // Enhanced AI question categorization and response methods

  /// Generate personalized nudge using AI and behavioral science principles
  Future<Map<String, dynamic>> generatePersonalizedNudge({
    required String userName,
    required String complexityProfile,
    required Map<String, dynamic> currentHabits,
    required Map<String, dynamic> contextData,
  }) async {
    if (kDebugMode) {
      print(
          '🧠 GemmaAI: Generating personalized nudge for $userName with profile: $complexityProfile');
    }

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('AI service failed to initialize');
      }
    }

    try {
      // Analyze current user state and context
      final behavioralAnalysis = _analyzeBehavioralContext(
          currentHabits, contextData, complexityProfile);

      // Select appropriate behavioral science technique
      final technique =
          _selectBehavioralTechnique(complexityProfile, behavioralAnalysis);

      // Generate nudge using AI with behavioral science framework
      final nudgeData = await _generateAINudgeWithBehavioralScience(
        userName: userName,
        complexityProfile: complexityProfile,
        behavioralAnalysis: behavioralAnalysis,
        technique: technique,
        currentHabits: currentHabits,
        contextData: contextData,
      );

      if (kDebugMode) {
        print('🧠 GemmaAI: Generated nudge: ${nudgeData['message']}');
      }

      return nudgeData;
    } catch (e) {
      if (kDebugMode) {
        print('🧠 GemmaAI: Nudge generation failed: $e');
      }
      // This should never happen since we always fallback to enhanced simulation
      throw Exception('Nudge generation failed unexpectedly: $e');
    }
  }

  /// Analyze behavioral context to understand user state
  Map<String, dynamic> _analyzeBehavioralContext(
      Map<String, dynamic> currentHabits,
      Map<String, dynamic> contextData,
      String complexityProfile) {
    final analysis = <String, dynamic>{};

    // Analyze habit patterns
    analysis['primaryConcerns'] = _identifyPrimaryConcerns(currentHabits);
    analysis['energyLevel'] =
        _assessEnergyLevel(currentHabits, complexityProfile);
    analysis['cognitiveLoad'] =
        _assessCognitiveLoad(complexityProfile, contextData);
    analysis['motivationalState'] =
        _assessMotivationalState(currentHabits, complexityProfile);
    analysis['timeContext'] = _getTimeContext();
    analysis['habitStrengths'] = _identifyHabitStrengths(currentHabits);

    return analysis;
  }

  /// Select behavioral science technique based on profile and context
  String _selectBehavioralTechnique(
      String complexityProfile, Map<String, dynamic> behavioralAnalysis) {
    final cognitiveLoad = behavioralAnalysis['cognitiveLoad'] ?? 'medium';
    final energyLevel = behavioralAnalysis['energyLevel'] ?? 'medium';
    final timeContext = behavioralAnalysis['timeContext'] ?? 'general';

    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        // Use simplification and default options - reduce decision fatigue
        if (cognitiveLoad == 'high') return 'default_option';
        return 'simplification';

      case 'overloaded':
        // Use positive framing and social norms - gentle motivation
        if (timeContext == 'morning') return 'anchoring';
        return 'positive_framing';

      case 'trying':
        // Use commitment devices and salience - harness existing motivation
        if (energyLevel == 'high') return 'commitment_device';
        return 'salience';

      default: // stable
        // Use individualization and priming - optimize for sustained change
        if (timeContext == 'evening') return 'priming';
        return 'individualization';
    }
  }

  /// Generate AI nudge using behavioral science framework
  Future<Map<String, dynamic>> _generateAINudgeWithBehavioralScience({
    required String userName,
    required String complexityProfile,
    required Map<String, dynamic> behavioralAnalysis,
    required String technique,
    required Map<String, dynamic> currentHabits,
    required Map<String, dynamic> contextData,
  }) async {
    if ((_activeModel != null || _candidateModels.isNotEmpty) &&
        _apiKey != 'YOUR_API_KEY_HERE') {
      try {
        // Build comprehensive prompt for AI nudge generation
        final prompt = _buildNudgePrompt(
          userName: userName,
          complexityProfile: complexityProfile,
          behavioralAnalysis: behavioralAnalysis,
          technique: technique,
          currentHabits: currentHabits,
          contextData: contextData,
        );

        if (kDebugMode) {
          print('🤖 Generating AI-powered nudge with behavioral science...');
        }

        final text = await _sendChatWithFailover(
          messages: [
            const {
              'role': 'system',
              'content': _systemInstruction,
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          temperature: _temperature,
          maxTokens: _maxTokens,
          topP: 0.8,
        );

        if (text != null && text.trim().isNotEmpty) {
          // Parse AI response to extract nudge components
          final nudgeData =
              _parseAINudgeResponse(text, technique, complexityProfile);

          if (kDebugMode) {
            print('✅ AI-generated nudge: ${nudgeData['message']}');
          }

          return nudgeData;
        } else {
          throw Exception('Empty nudge response from AI');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ AI nudge generation failed, using simulation: $e');
        }
        // Fallback to simulation
        return _generateNudgeSimulation(
          userName: userName,
          complexityProfile: complexityProfile,
          behavioralAnalysis: behavioralAnalysis,
          technique: technique,
          currentHabits: currentHabits,
        );
      }
    } else {
      // Use simulation
      return _generateNudgeSimulation(
        userName: userName,
        complexityProfile: complexityProfile,
        behavioralAnalysis: behavioralAnalysis,
        technique: technique,
        currentHabits: currentHabits,
      );
    }
  }

  Future<Map<String, dynamic>> _generateNudgeSimulation({
    required String userName,
    required String complexityProfile,
    required Map<String, dynamic> behavioralAnalysis,
    required String technique,
    required Map<String, dynamic> currentHabits,
  }) async {
    // Simulate AI inference with realistic delay
    await Future.delayed(
        Duration(milliseconds: 600 + (DateTime.now().millisecond % 800)));

    final nudgeMessage = _constructBehavioralNudge(
      userName: userName,
      complexityProfile: complexityProfile,
      technique: technique,
      behavioralAnalysis: behavioralAnalysis,
      currentHabits: currentHabits,
    );

    final sources = _generateNudgeSources(technique, complexityProfile);

    return {
      'message': nudgeMessage,
      'technique': technique,
      'sources': sources,
      'behavioralPrinciple': _getBehavioralPrincipleExplanation(technique),
      'estimatedTime': _getEstimatedTimeForNudge(technique, complexityProfile),
      'energyRequired':
          _getEnergyRequiredForNudge(technique, complexityProfile),
    };
  }

  /// Construct nudge message using specific behavioral science technique
  String _constructBehavioralNudge({
    required String userName,
    required String complexityProfile,
    required String technique,
    required Map<String, dynamic> behavioralAnalysis,
    required Map<String, dynamic> currentHabits,
  }) {
    final name = userName.isNotEmpty ? userName : 'friend';
    final primaryConcerns =
        behavioralAnalysis['primaryConcerns'] as List<String>? ?? [];
    final habitStrengths =
        behavioralAnalysis['habitStrengths'] as List<String>? ?? [];
    final timeContext =
        behavioralAnalysis['timeContext'] as String? ?? 'general';

    switch (technique) {
      case 'default_option':
        return _createDefaultOptionNudge(
            name, complexityProfile, primaryConcerns);

      case 'simplification':
        return _createSimplificationNudge(
            name, complexityProfile, primaryConcerns);

      case 'positive_framing':
        return _createPositiveFramingNudge(
            name, complexityProfile, primaryConcerns, habitStrengths);

      case 'anchoring':
        return _createAnchoringNudge(
            name, complexityProfile, primaryConcerns, timeContext);

      case 'commitment_device':
        return _createCommitmentDeviceNudge(
            name, complexityProfile, primaryConcerns);

      case 'salience':
        return _createSalienceNudge(
            name, complexityProfile, primaryConcerns, timeContext);

      case 'priming':
        return _createPrimingNudge(
            name, complexityProfile, primaryConcerns, habitStrengths);

      case 'individualization':
        return _createIndividualizationNudge(
            name, complexityProfile, primaryConcerns, habitStrengths);

      default:
        return _createGeneralNudge(name, complexityProfile, primaryConcerns);
    }
  }

  // Behavioral analysis helper methods

  List<String> _identifyPrimaryConcerns(Map<String, dynamic> currentHabits) {
    final concerns = <String>[];

    currentHabits.forEach((key, value) {
      if (value == null ||
          value == 'poor' ||
          value == 'low' ||
          value == 'none' ||
          value == 'skipped') {
        switch (key) {
          case 'sleep':
            concerns.add('sleep_quality');
            break;
          case 'hydration':
            concerns.add('hydration_low');
            break;
          case 'meals':
            concerns.add('nutrition_poor');
            break;
          case 'movement':
            concerns.add('physical_activity');
            break;
          case 'screenBreaks':
            concerns.add('digital_wellness');
            break;
          case 'stress':
            concerns.add('stress_management');
            break;
        }
      }
    });

    return concerns;
  }

  String _assessEnergyLevel(
      Map<String, dynamic> currentHabits, String complexityProfile) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return 'very_low';
      case 'overloaded':
        return 'low';
      case 'trying':
        return 'medium';
      default:
        return 'high';
    }
  }

  String _assessCognitiveLoad(
      String complexityProfile, Map<String, dynamic> contextData) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
      case 'overloaded':
        return 'high';
      case 'trying':
        return 'medium';
      default:
        return 'low';
    }
  }

  String _assessMotivationalState(
      Map<String, dynamic> currentHabits, String complexityProfile) {
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        return 'depleted';
      case 'overloaded':
        return 'strained';
      case 'trying':
        return 'engaged';
      default:
        return 'ready';
    }
  }

  String _getTimeContext() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  List<String> _identifyHabitStrengths(Map<String, dynamic> currentHabits) {
    final strengths = <String>[];

    currentHabits.forEach((key, value) {
      if (value == 'good' ||
          value == 'high' ||
          value == 'regular' ||
          value == 'active') {
        strengths.add(key);
      }
    });

    return strengths;
  }

  // Behavioral nudge construction methods

  String _createDefaultOptionNudge(
      String name, String complexityProfile, List<String> concerns) {
    if (concerns.contains('hydration_low')) {
      return "Hi $name, I've set a gentle reminder: drink water now. No decisions needed - just one sip when you see this message. 💧";
    } else if (concerns.contains('sleep_quality')) {
      return "Hi $name, it's time to rest. Put your phone down and lie down - your body knows what to do. 😴";
    } else {
      return "Hi $name, take three deep breaths right now. No thinking required - just breathe in, breathe out. You've got this. 🌱";
    }
  }

  String _createSimplificationNudge(
      String name, String complexityProfile, List<String> concerns) {
    if (concerns.contains('nutrition_poor')) {
      return "Hi $name, eat something now. Anything. A banana, crackers, whatever's closest. Simple nutrition for a complex day. 🍌";
    } else if (concerns.contains('physical_activity')) {
      return "Hi $name, stand up. That's it. Standing is movement, and movement is medicine. One step at a time. 🌱";
    } else {
      return "Hi $name, one tiny thing: wash your hands mindfully. Focus only on the water and soap. Simple self-care starts here. 🙌";
    }
  }

  String _createPositiveFramingNudge(String name, String complexityProfile,
      List<String> concerns, List<String> strengths) {
    final strengthText = strengths.isNotEmpty
        ? "You're already succeeding with ${strengths.first}"
        : "You're doing better than you think";

    if (concerns.contains('stress_management')) {
      return "Hi $name, $strengthText. Now let's add just 30 seconds of calm breathing to build on that success. 🌟";
    } else if (concerns.contains('digital_wellness')) {
      return "Hi $name, $strengthText. Ready to give your eyes a 20-second break? Look at something far away and feel the relief. ✨";
    } else {
      return "Hi $name, $strengthText. You're building positive momentum - let's add one small win to your day. 💫";
    }
  }

  String _createAnchoringNudge(String name, String complexityProfile,
      List<String> concerns, String timeContext) {
    if (timeContext == 'morning' && concerns.contains('hydration_low')) {
      return "Hi $name, since you're already starting your day, anchor it with a glass of water. Morning hydration = morning success. ☀️💧";
    } else if (timeContext == 'evening' && concerns.contains('sleep_quality')) {
      return "Hi $name, since the day is winding down, let your mind wind down too. Put your phone away and start tonight's rest ritual. 🌙";
    } else {
      return "Hi $name, since you're already here reading this, you're already taking care of yourself. Build on this moment of self-awareness. 🎯";
    }
  }

  String _createCommitmentDeviceNudge(
      String name, String complexityProfile, List<String> concerns) {
    if (concerns.contains('physical_activity')) {
      return "Hi $name, commit to just 2 minutes of movement today. Set a timer, make it official. Your future self will thank you for this promise. ⏰💪";
    } else if (concerns.contains('digital_wellness')) {
      return "Hi $name, make a deal with yourself: no phone for the next 10 minutes. Put it in another room and honor this commitment to yourself. 📱➡️🚪";
    } else {
      return "Hi $name, promise yourself one act of self-care in the next hour. Write it down, make it real. You deserve this commitment. ✍️❤️";
    }
  }

  String _createSalienceNudge(String name, String complexityProfile,
      List<String> concerns, String timeContext) {
    if (concerns.contains('hydration_low')) {
      return "Hi $name, 🚨 HYDRATION ALERT 🚨 Your body needs water RIGHT NOW. Notice how you feel, then drink and notice the difference. 💧⚡";
    } else if (concerns.contains('stress_management')) {
      return "Hi $name, 🔴 STRESS CHECK 🔴 Notice your shoulders, jaw, breathing right now. Feel the tension? Time for 3 conscious deep breaths. 🧘‍♀️";
    } else {
      return "Hi $name, ⭐ WELLNESS MOMENT ⭐ This is your reminder that self-care is happening RIGHT NOW. Feel this moment of attention to yourself. ✨";
    }
  }

  String _createPrimingNudge(String name, String complexityProfile,
      List<String> concerns, List<String> strengths) {
    if (concerns.contains('sleep_quality')) {
      return "Hi $name, imagine waking up tomorrow feeling truly rested... Start creating that reality by dimming lights and slowing down now. 🌙✨";
    } else if (concerns.contains('nutrition_poor')) {
      return "Hi $name, picture yourself feeling energized and nourished... Begin that feeling by choosing one nutritious thing to eat right now. 🍎💫";
    } else {
      return "Hi $name, envision yourself feeling balanced and centered... You can start embodying that feeling with one mindful breath. 🌟🧘‍♀️";
    }
  }

  String _createIndividualizationNudge(String name, String complexityProfile,
      List<String> concerns, List<String> strengths) {
    final personalTouch = strengths.isNotEmpty
        ? "Building on your strength with ${strengths.first}"
        : "Tailored specifically for your current needs";

    if (concerns.contains('physical_activity')) {
      return "Hi $name, $personalTouch: your body is asking for movement in its own unique way. What type of movement would feel good to YOU right now? 🏃‍♀️💫";
    } else if (concerns.contains('stress_management')) {
      return "Hi $name, $personalTouch: you have your own stress signature. What's one thing that uniquely helps YOU feel calmer? Try that now. 🌸🧘‍♀️";
    } else {
      return "Hi $name, $personalTouch: this moment is designed specifically for you. What does YOUR body and mind need most right now? Honor that. ✨❤️";
    }
  }

  String _createGeneralNudge(
      String name, String complexityProfile, List<String> concerns) {
    return "Hi $name, your wellbeing matters. Take a moment right now to do something kind for yourself - even if it's tiny. You deserve this care. 💝";
  }

  // Helper methods for nudge metadata

  String _getBehavioralPrincipleExplanation(String technique) {
    switch (technique) {
      case 'default_option':
        return 'Using defaults to reduce decision fatigue and make healthy choices easier';
      case 'simplification':
        return 'Breaking down complex behaviors into simple, manageable actions';
      case 'positive_framing':
        return 'Focusing on gains and strengths to boost motivation and confidence';
      case 'anchoring':
        return 'Connecting new behaviors to existing routines or contexts';
      case 'commitment_device':
        return 'Using personal promises to increase follow-through on healthy behaviors';
      case 'salience':
        return 'Making important health information highly visible and attention-grabbing';
      case 'priming':
        return 'Using mental imagery to prepare the mind for positive behaviors';
      case 'individualization':
        return 'Tailoring interventions to personal preferences and circumstances';
      default:
        return 'Applying evidence-based behavioral science for sustainable change';
    }
  }

  String _getEstimatedTimeForNudge(String technique, String complexityProfile) {
    if (complexityProfile == 'survival') return '<30 sec';

    switch (technique) {
      case 'default_option':
      case 'simplification':
        return '<1 min';
      case 'commitment_device':
      case 'individualization':
        return '2-3 min';
      default:
        return '1-2 min';
    }
  }

  String _getEnergyRequiredForNudge(
      String technique, String complexityProfile) {
    if (complexityProfile == 'survival' || complexityProfile == 'overloaded')
      return 'minimal';

    switch (technique) {
      case 'default_option':
      case 'simplification':
        return 'very low';
      case 'commitment_device':
      case 'individualization':
        return 'medium';
      default:
        return 'low';
    }
  }

  List<Map<String, String>> _generateNudgeSources(
      String technique, String complexityProfile) {
    final sources = <Map<String, String>>[];

    // Add technique-specific sources
    switch (technique) {
      case 'default_option':
        sources.add({
          'title': 'The Power of Default Options',
          'source': 'Behavioral Economics Guide',
          'type': 'Research',
          'icon': '🎯',
          'url':
              'https://www.behavioraleconomics.com/resources/mini-encyclopedia-of-be/default-bias/'
        });
        break;
      case 'positive_framing':
        sources.add({
          'title': 'Framing Effects in Health Communication',
          'source': 'American Psychological Association',
          'type': 'Academic',
          'icon': '🌟',
          'url':
              'https://www.apa.org/science/about/psa/2011/05/framing-messages'
        });
        break;
      case 'commitment_device':
        sources.add({
          'title': 'Commitment Devices and Behavior Change',
          'source': 'Journal of Behavioral Economics',
          'type': 'Research',
          'icon': '🤝',
          'url':
              'https://www.behavioraleconomics.com/resources/mini-encyclopedia-of-be/commitment-device/'
        });
        break;
      default:
        sources.add({
          'title': 'Behavioral Science in Health',
          'source': 'Penn Medicine Nudge Unit',
          'type': 'Medical',
          'icon': '🧠',
          'url': 'https://nudgeunit.upenn.edu/'
        });
    }

    // Add general behavioral science source
    sources.add({
      'title': 'Nudge Theory Applications',
      'source': 'The Decision Lab',
      'type': 'Evidence-based',
      'icon': '🔬',
      'url':
          'https://thedecisionlab.com/reference-guide/psychology/nudge-theory'
    });

    // Add AI personalization source
    sources.add({
      'title': 'AI-Personalized for your profile',
      'source': 'Starbound Behavioral AI',
      'type': 'AI-generated',
      'icon': '🤖'
    });

    return sources;
  }

  List<Map<String, String>> _generateSources(
      String question, String complexityProfile) {
    final questionLower = question.toLowerCase();
    final sources = <Map<String, String>>[];

    // Add relevant sources based on question type
    if (_isStressRelated(questionLower)) {
      sources.addAll([
        {
          'title': 'Stress Management Techniques',
          'source': 'American Psychological Association',
          'type': 'Research',
          'icon': '🧠',
          'url': 'https://www.apa.org/topics/stress'
        },
        {
          'title': '5-4-3-2-1 Grounding Technique',
          'source': 'University of Rochester Medical Center',
          'type': 'Evidence-based',
          'icon': '🌱',
          'url':
              'https://www.urmc.rochester.edu/behavioral-health-partners/bhp-blog/april-2018/5-4-3-2-1-coping-technique-for-anxiety.aspx'
        },
      ]);
    }

    if (_isSleepRelated(questionLower)) {
      sources.addAll([
        {
          'title': 'Sleep Hygiene Guidelines',
          'source': 'National Sleep Foundation',
          'type': 'Medical',
          'icon': '😴',
          'url': 'https://www.sleepfoundation.org/sleep-hygiene'
        },
        {
          'title': 'Healthy Sleep Tips',
          'source': 'Centers for Disease Control and Prevention',
          'type': 'Medical',
          'icon': '📚',
          'url': 'https://www.cdc.gov/sleep/about_sleep/sleep_hygiene.html'
        },
      ]);
    }

    if (_isFoodRelated(questionLower)) {
      sources.addAll([
        {
          'title': 'Healthy Eating Guidelines',
          'source': 'Harvard School of Public Health',
          'type': 'Academic',
          'icon': '🍎',
          'url':
              'https://www.hsph.harvard.edu/nutritionsource/healthy-eating-plate/'
        },
        {
          'title': 'Mindful Eating Resources',
          'source': 'Harvard Health Publishing',
          'type': 'Medical',
          'icon': '🧘',
          'url':
              'https://www.health.harvard.edu/staying-healthy/8-steps-to-mindful-eating'
        },
      ]);
    }

    if (_isExerciseRelated(questionLower)) {
      sources.addAll([
        {
          'title': 'Physical Activity Guidelines',
          'source': 'World Health Organization',
          'type': 'Medical',
          'icon': '🏃',
          'url':
              'https://www.who.int/news-room/fact-sheets/detail/physical-activity'
        },
        {
          'title': 'Exercise and Mental Health',
          'source': 'Mayo Clinic',
          'type': 'Medical',
          'icon': '💪',
          'url':
              'https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/exercise/art-20048389'
        },
      ]);
    }

    if (_isMoodRelated(questionLower)) {
      sources.addAll([
        {
          'title': 'Mental Health Resources',
          'source': 'National Institute of Mental Health',
          'type': 'Medical',
          'icon': '🧠',
          'url':
              'https://www.nimh.nih.gov/health/topics/caring-for-your-mental-health'
        },
        {
          'title': 'Mood and Wellness',
          'source': 'Mental Health America',
          'type': 'Support',
          'icon': '🌈',
          'url': 'https://mhanational.org/conditions/mood-disorders'
        },
      ]);
    }

    // Add complexity-profile specific sources
    switch (complexityProfile.toLowerCase()) {
      case 'survival':
        sources.add({
          'title': 'Crisis Support Resources',
          'source': 'National Institute of Mental Health',
          'type': 'Support',
          'icon': '🆘',
          'url': 'https://www.nimh.nih.gov/health/find-help'
        });
        break;
      case 'overloaded':
        sources.add({
          'title': 'Managing Overwhelm',
          'source': 'Cleveland Clinic',
          'type': 'Medical',
          'icon': '⚖️',
          'url': 'https://my.clevelandclinic.org/health/diseases/9639-stress'
        });
        break;
      case 'trying':
        sources.add({
          'title': 'Building Healthy Habits',
          'source': 'Mayo Clinic',
          'type': 'Evidence-based',
          'icon': '🌟',
          'url':
              'https://www.mayoclinic.org/healthy-lifestyle/adult-health/in-depth/habits/art-20049040'
        });
        break;
      default:
        sources.add({
          'title': 'General Wellness Tips',
          'source': 'Harvard Health Publishing',
          'type': 'Medical',
          'icon': '✨',
          'url': 'https://www.health.harvard.edu/topics/staying-healthy'
        });
    }

    // Always include the AI personalization source (no URL for this one)
    sources.add({
      'title': 'Personalized for your complexity profile',
      'source': 'Starbound AI Analysis',
      'type': 'AI-generated',
      'icon': '🤖'
    });

    return sources.take(3).toList(); // Limit to 3 sources for clean UI
  }

  // Real AI integration helper methods

  String _buildNudgePrompt({
    required String userName,
    required String complexityProfile,
    required Map<String, dynamic> behavioralAnalysis,
    required String technique,
    required Map<String, dynamic> currentHabits,
    required Map<String, dynamic> contextData,
  }) {
    final name = userName.isNotEmpty ? userName : 'friend';
    final timeOfDay = contextData['timeOfDay'] ?? DateTime.now().hour;
    final timeContext = timeOfDay < 12
        ? 'morning'
        : timeOfDay < 17
            ? 'afternoon'
            : 'evening';

    return '''Generate a personalized behavioral nudge using the following framework:

USER CONTEXT:
- Name: $name
- Complexity Profile: $complexityProfile
- Time: $timeContext
- Current Habits: ${currentHabits.toString()}
- Behavioral Analysis: ${behavioralAnalysis.toString()}

BEHAVIORAL SCIENCE TECHNIQUE: $technique

COMPLEXITY PROFILE GUIDANCE:
- Survival: Simple, immediate actions with lots of support and encouragement
- Overloaded: Focus on simplification, stress reduction, and removing barriers
- Trying: Provide structure, accountability, and motivation with clear next steps
- Stable: Offer advanced strategies, challenges, and optimization opportunities

RESPONSE FORMAT:
NUDGE: [A personalized, encouraging nudge message that applies the $technique technique. Keep it warm, actionable, and under 100 words. Address them by name.]

EXPLANATION: [Brief explanation of the behavioral science principle behind this nudge, 1-2 sentences]

TIME_ESTIMATE: [How long this will take: <1 min, 2-5 min, 5-15 min, or 15+ min]

ENERGY_LEVEL: [Energy required: minimal, low, moderate, or high]

SOURCES: [List 2-3 real, credible health organization URLs that support this advice, like WHO, Mayo Clinic, Harvard Health, CDC, etc.]

Generate the nudge now:''';
  }

  Map<String, dynamic> _parseAINudgeResponse(
      String response, String technique, String complexityProfile) {
    try {
      // Parse the structured AI response
      final sections = <String, String>{};
      final lines = response.split('\n');
      String currentSection = '';
      String currentContent = '';

      for (final line in lines) {
        if (line.startsWith('NUDGE:')) {
          if (currentSection.isNotEmpty) {
            sections[currentSection] = currentContent.trim();
          }
          currentSection = 'nudge';
          currentContent = line.substring(6).trim();
        } else if (line.startsWith('EXPLANATION:')) {
          if (currentSection.isNotEmpty) {
            sections[currentSection] = currentContent.trim();
          }
          currentSection = 'explanation';
          currentContent = line.substring(12).trim();
        } else if (line.startsWith('TIME_ESTIMATE:')) {
          if (currentSection.isNotEmpty) {
            sections[currentSection] = currentContent.trim();
          }
          currentSection = 'time';
          currentContent = line.substring(14).trim();
        } else if (line.startsWith('ENERGY_LEVEL:')) {
          if (currentSection.isNotEmpty) {
            sections[currentSection] = currentContent.trim();
          }
          currentSection = 'energy';
          currentContent = line.substring(13).trim();
        } else if (line.startsWith('SOURCES:')) {
          if (currentSection.isNotEmpty) {
            sections[currentSection] = currentContent.trim();
          }
          currentSection = 'sources';
          currentContent = line.substring(8).trim();
        } else if (currentSection.isNotEmpty) {
          currentContent += '\n' + line;
        }
      }

      // Add the last section
      if (currentSection.isNotEmpty) {
        sections[currentSection] = currentContent.trim();
      }

      // Extract and parse sources
      final sourcesText = sections['sources'] ?? '';
      final sources = _parseSources(sourcesText, '', complexityProfile);

      return {
        'message': sections['nudge'] ??
            'Take a small step toward better health today.',
        'technique': technique,
        'sources': sources,
        'behavioralPrinciple': sections['explanation'] ??
            _getBehavioralPrincipleExplanation(technique),
        'estimatedTime': sections['time'] ?? '<1 min',
        'energyRequired': sections['energy'] ?? 'minimal',
      };
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to parse AI nudge response: $e');
      }

      // Fallback to using the raw response as the message
      return {
        'message': response.length > 200
            ? response.substring(0, 200) + '...'
            : response,
        'technique': technique,
        'sources': _generateNudgeSources(technique, complexityProfile),
        'behavioralPrinciple': _getBehavioralPrincipleExplanation(technique),
        'estimatedTime': '<1 min',
        'energyRequired': 'minimal',
      };
    }
  }

  List<Map<String, String>> _parseSources(
      String sourcesText, String question, String complexityProfile) {
    final sources = <Map<String, String>>[];

    if (sourcesText.isEmpty) {
      return _generateSources(question, complexityProfile);
    }

    try {
      // Split by lines and look for URLs
      final lines = sourcesText.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.contains('http') || trimmed.contains('www.')) {
          // Extract organization name and URL
          String title = 'Health Resource';
          String source = 'Health Organization';

          if (trimmed.contains('mayo')) {
            title = 'Evidence-Based Health Information';
            source = 'Mayo Clinic';
          } else if (trimmed.contains('harvard')) {
            title = 'Harvard Health Research';
            source = 'Harvard Health Publishing';
          } else if (trimmed.contains('who.int')) {
            title = 'Global Health Guidelines';
            source = 'World Health Organization';
          } else if (trimmed.contains('cdc.gov')) {
            title = 'Public Health Information';
            source = 'Centers for Disease Control';
          } else if (trimmed.contains('nih.gov')) {
            title = 'Medical Research';
            source = 'National Institutes of Health';
          }

          sources.add({
            'title': title,
            'source': source,
            'type': 'Research',
            'icon': '🔬',
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to parse sources: $e');
      }
    }

    // If no sources found, add fallback
    if (sources.isEmpty) {
      sources.add({
        'title': 'AI-Generated Health Guidance',
        'source': 'Starbound AI',
        'type': 'AI-generated',
        'icon': '🤖',
      });
    }

    return sources.take(3).toList();
  }
}
