import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/complexity_engine_models.dart';
import '../models/starbound_response.dart';
import 'env_service.dart';

/// Direct OpenRouter API service for smart input - streamlined and reliable
class OpenRouterService {
  static final OpenRouterService _instance = OpenRouterService._internal();
  factory OpenRouterService() => _instance;
  OpenRouterService._internal();

  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  bool _isInitialized = false;
  String? _activeModel;
  static const String _systemInstruction = '''
You are Starbound — a warm, genuine health companion for people in Sydney who face real barriers accessing healthcare.

PERSONALITY:
- Talk like a knowledgeable friend, not a chatbot or medical pamphlet
- Use the person's name naturally (not every sentence, just occasionally)
- Reference what they've actually said — their words, their situation
- Vary your tone: sometimes reassuring, sometimes gently direct, sometimes curious
- It's okay to say "I'm not sure, but here's what might help"
- Acknowledge frustration or worry without being patronizing

WHAT YOU DO:
- Help find accessible care that fits their situation (bulk billing, telehealth, after-hours)
- Suggest tracking symptoms in their journal before GP visits
- Give practical next steps, not generic advice
- Use Australian context (Medicare, PBS, 000 for emergencies)

WHAT YOU DON'T DO:
- Never diagnose — "only a doctor can say for certain"
- Never lecture or use corporate health-speak
- Never ignore their specific barriers (cost, transport, time)

RESPONSE STYLE:
- Responses are JSON objects (start with {, end with })
- No markdown code blocks or extra text
- Vary your language — don't start every section the same way
''';
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

    final legacyRuntimeModel =
        EnvService.instance.maybe('GEMINI_MODEL')?.trim();
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

  /// Get API key - same logic as GemmaAIService but cleaner
  static String get _apiKey {
    // First try environment variable
    const String? envApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
    if (envApiKey != null &&
        envApiKey.isNotEmpty &&
        envApiKey != 'YOUR_API_KEY_HERE') {
      return envApiKey;
    }

    // Then try runtime environment variables (desktop/debug)
    try {
      if (!kIsWeb) {
        final String? platformKey = Platform.environment['OPENROUTER_API_KEY'];
        if (platformKey != null &&
            platformKey.isNotEmpty &&
            platformKey != 'YOUR_API_KEY_HERE') {
          return platformKey;
        }
      }
    } catch (_) {
      // Platform.environment is unsupported on web; fall through to .env
    }

    final runtimeApiKey = EnvService.instance.maybe('OPENROUTER_API_KEY');
    if (runtimeApiKey != null &&
        runtimeApiKey.isNotEmpty &&
        runtimeApiKey != 'YOUR_API_KEY_HERE') {
      return runtimeApiKey;
    }

    const String? legacyEnvApiKey = String.fromEnvironment('GEMINI_API_KEY');
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

    return 'YOUR_API_KEY_HERE'; // Placeholder
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

  /// Initialize OpenRouter API
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    final apiKey = _apiKey;
    if (apiKey == 'YOUR_API_KEY_HERE') {
      debugPrint('❌ OpenRouter: No OpenRouter API key configured');
      return false;
    }

    for (final modelName in _candidateModels) {
      try {
        final testResponse = await _sendChat(
          model: modelName,
          messages: const [
            {
              'role': 'system',
              'content': _systemInstruction,
            },
            {
              'role': 'user',
              'content':
                  'Respond with "Ready" if you can help with health navigation questions.',
            }
          ],
          temperature: 0.2,
          maxTokens: 60,
        );

        if (testResponse != null && testResponse.trim().isNotEmpty) {
          _activeModel = modelName;
          _isInitialized = true;
          debugPrint(
              '✅ OpenRouter: Successfully initialized with OpenRouter (model=$modelName)');
          return true;
        }
      } catch (e) {
        debugPrint('❌ OpenRouter: Initialization failed with $modelName: $e');
      }
    }

    return false;
  }

  /// Generate response for a health question
  Future<String?> answerQuestion(
    String question,
    String userName,
    String complexityProfile, {
    String? memorySummary,
    List<Map<String, String>> followUpAnswers = const [],
    String? intentCategory,
    String? neighborhood,
    List<String>? barriers,
    List<String>? languages,
    String? workSchedule,
    List<String>? healthInterests,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ OpenRouter: Cannot answer - initialization failed');
        return null;
      }
    }

    if (_activeModel == null && _candidateModels.isEmpty) {
      debugPrint('❌ OpenRouter: No model available');
      return null;
    }

    try {
      final name = userName.isNotEmpty ? userName : 'friend';
      final memoryContext =
          (memorySummary != null && memorySummary.trim().isNotEmpty)
              ? memorySummary.trim()
              : 'none';
      final followUpContext = _formatFollowUpAnswers(followUpAnswers);

      // Health navigation context
      final locationText = neighborhood ?? 'Sydney';
      final barriersText = (barriers != null && barriers.isNotEmpty)
          ? barriers.join(', ')
          : 'unknown';
      final languagesText = (languages != null && languages.isNotEmpty)
          ? languages.join(', ')
          : 'English';
      final scheduleText = workSchedule ?? 'unknown';
      final interestsText =
          (healthInterests != null && healthInterests.isNotEmpty)
              ? healthInterests.join(', ')
              : 'general health';

      final prompt = '''
$name asked: "$question"

THEIR SITUATION:
- Location: $locationText
- Barriers they face: $barriersText
- Languages: $languagesText
- Work: $scheduleText
- What they care about: $interestsText
- Complexity profile: $complexityProfile

WHAT YOU KNOW ABOUT THEM:
$memoryContext
${followUpContext != 'none' ? 'They also mentioned: $followUpContext' : ''}

---

Write a response that feels like it came from someone who actually read what $name wrote and understands their situation.

VARY YOUR APPROACH based on what they asked:
- Worried about something → Start with reassurance, then practical options
- Asking about access/cost → Lead with the most relevant option for their barriers
- Describing symptoms → Acknowledge first, then explore what might help
- Feeling stuck/frustrated → Validate before jumping to solutions

ADAPT TO THEIR COMPLEXITY PROFILE:
- stable: can handle fuller plans and forward-looking habit suggestions
- trying: keep steps clear, practical, and not too many moving parts
- overloaded: keep actions low-effort and reduce cognitive load
- survival: prioritize one tiny immediate step; avoid long or demanding plans

MAKE IT PERSONAL:
- Reference their actual words or situation (not generic "I understand")
- If their journal mentions something relevant, bring it in naturally
- Match urgency to what they're asking — don't treat everything the same

RESPONSE FORMAT (JSON):
{
  "understanding": "[2-3 sentences that show you actually read their question. Use their name once. Reference their specific situation or words. DON'T start with 'I understand' or 'I hear you' — vary it.]",

  "possible_causes": [
    "[Plain language, connected to what they described]",
    "[Another possibility — mention journal patterns if relevant]",
    "[Include 'Only a doctor can say for certain' naturally, not as a disclaimer]"
  ],

  "immediate_steps": [
    {"step_number": 1, "title": "[Action title]", "description": "[Specific to THEIR barriers: ${barriersText == 'unknown' ? 'offer a few options since we don\'t know their situation yet' : 'tailor to ' + barriersText}]", "theme": "self_care"},
    {"step_number": 2, "title": "[Action title]", "description": "[Mix: one healthcare access step + one tracking/journaling step]", "theme": "healthcare_access"},
    {"step_number": 3, "title": "[Action title]", "description": "[Something they can do right now]", "theme": "monitoring"}
  ],

  "when_to_seek_care": {
    "routine": "[When to see GP — be specific to their symptoms]",
    "urgent": "[Warning signs for today/tomorrow — specific, not generic]",
    "emergency": "[Call 000 if... — only include if relevant to what they asked]"
  },

  "resource_needs": ["[2-4 relevant resources: bulk-billing-gp, telehealth, journaling, habit-tracking, mood-tracking, mental-health-service, etc.]"],

  "follow_up_suggestions": [
    "[What specific thing to track in their journal]",
    "[When to check back — tied to their situation]"
  ]
}

AUSTRALIAN CONTEXT: Medicare, bulk billing, PBS (\$7.70/\$42.50), 000 for emergencies, Lifeline 13 11 14.

CRITICAL: If crisis signs (suicidal thoughts, severe hopelessness) → include Lifeline prominently, add "mental-health-crisis" to resources.
      ''';

      debugPrint('🤖 OpenRouter: Sending request to OpenRouter...');
      final response = await _sendChatWithFailover(
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
        temperature: 0.7,
        maxTokens: 900,
        topP: 0.8,
      );

      final parsed = response?.trim();
      if (parsed != null && parsed.isNotEmpty) {
        debugPrint(
            '✅ OpenRouter: Received response: ${parsed.substring(0, parsed.length.clamp(0, 100))}...');
        return parsed;
      }

      return null;
    } catch (e) {
      debugPrint('❌ OpenRouter: Error generating response: $e');
      return null;
    }
  }

  Future<String?> generateAskAnswer({
    required String question,
    required String userName,
    required String complexityProfile,
    String? symptomKey,
    List<String> keyFactors = const [],
    String routerCategory = 'unspecified',
    List<VaultActionSuggestion> whatToDoNow = const [],
    List<String> whatIfWorse = const [],
    String? neighborhood,
    List<String>? barriers,
    List<String>? languages,
    String? workSchedule,
    List<String>? healthInterests,
    List<Map<String, String>> followUpAnswers = const [],
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ OpenRouter: Cannot answer - initialization failed');
        return null;
      }
    }

    if (_activeModel == null && _candidateModels.isEmpty) {
      debugPrint('❌ OpenRouter: No model available');
      return null;
    }

    final actionsText = whatToDoNow.isEmpty
        ? 'none'
        : whatToDoNow
            .map((item) => '- ${item.title}: ${item.steps.join('; ')}')
            .join('\n');
    final safetyText = whatIfWorse.isEmpty
        ? 'none'
        : whatIfWorse.map((item) => '- $item').join('\n');
    final factorsText = keyFactors.isEmpty ? 'none' : keyFactors.join('; ');
    final name = userName.isNotEmpty ? userName : 'friend';
    final symptom = symptomKey ?? 'unspecified';

    // Health navigation context
    final locationText = neighborhood ?? 'Sydney';
    final barriersText = (barriers != null && barriers.isNotEmpty)
        ? barriers.join(', ')
        : 'unknown';
    final languagesText = (languages != null && languages.isNotEmpty)
        ? languages.join(', ')
        : 'English';
    final scheduleText = workSchedule ?? 'unknown';
    final interestsText =
        (healthInterests != null && healthInterests.isNotEmpty)
            ? healthInterests.join(', ')
            : 'general health';

    // Format follow-up answers if present
    final followUpContext = followUpAnswers.isEmpty
        ? ''
        : '''
They then clarified with these follow-up answers:
${followUpAnswers.map((item) => '- "${item['answer']}"').join('\n')}
''';

    final prompt = '''
⭐ ORIGINAL STATEMENT (this is the main context — reference this directly):
"$question"
$followUpContext
ABOUT THEM:
- In $locationText
- Barriers: $barriersText
- Languages: $languagesText
- Work: $scheduleText
- Interests: $interestsText
- Complexity profile: $complexityProfile

CRITICAL INSTRUCTION:
Your response MUST reference their ORIGINAL STATEMENT ("$question") — not just the follow-up answers.
The follow-ups add detail, but the original statement is what they actually said and wanted help with.
In your "understanding" section, quote or paraphrase something from their original words.

ANALYSIS HINTS:
- This seems related to: $symptom ($routerCategory)
- Key factors: $factorsText
- Suggested focus: $actionsText
- Watch for: $safetyText

---

Write like you're talking to $name directly — not like you're filling out a form.

HOW TO VARY YOUR RESPONSE:

Opening ("understanding"):
- DON'T always start with "I hear you" or "That sounds difficult"
- TRY THESE VARIATIONS:
  * Curious: "That's been going on for a while — let's figure out what might help."
  * Reassuring: "$name, this is something a lot of people deal with, and there are good options."
  * Direct: "Okay, here's what I'm thinking based on what you've described..."
  * Acknowledging: "That sounds frustrating, especially with [their specific barrier]."

Middle (causes + steps):
- Connect causes to THEIR situation, not generic lists
- If barriers unknown: "I'll give you a few options — pick what fits your situation"
- If barriers known: Lead with the most relevant one (cost→bulk billing, transport→telehealth)
- Mix practical access steps with tracking suggestions

Complexity adaptation (required):
- stable: include practical next steps plus one forward-looking habit/system idea
- trying: keep the plan concise and flexible, with manageable effort
- overloaded: simplify hard; low-effort, low-friction actions only
- survival: prioritize one tiny immediate action and emotional safety; no heavy plans

Closing (when to seek care):
- Be specific to THEIR symptoms, not generic warnings
- Only include emergency info if actually relevant

RESPONSE (JSON only, no markdown):
{
  "understanding": "[2-3 sentences. START by referencing their ORIGINAL STATEMENT ('$question') — quote or paraphrase their actual words. Then acknowledge how the follow-up details add to the picture. Use their name once.]",

  "possible_causes": [
    "[Connected to their ORIGINAL STATEMENT, not just the follow-up answers]",
    "[Another angle — connect to what they actually said]",
    "[Work in 'a doctor can confirm' naturally, not as a bolted-on disclaimer]"
  ],

  "immediate_steps": [
    {"step_number": 1, "title": "[Short action]", "theme": "self_care"},
    {"step_number": 2, "title": "[Short action — tailored to their barriers]", "theme": "healthcare_access"},
    {"step_number": 3, "title": "[Something trackable for their journal]", "theme": "monitoring"}
  ],

  "when_to_seek_care": {
    "routine": "[Specific to their symptoms]",
    "urgent": "[Based on $safetyText if relevant]",
    "emergency": "[Only if genuinely applicable — Call 000 if...]"
  },

  "resource_needs": ["[Pick 2-4 that actually fit: bulk-billing-gp, telehealth, journaling, habit-tracking, mood-tracking, mental-health-service]"],

  "follow_up_suggestions": [
    "[Specific thing to track]",
    "[When to check back]"
  ]
}

CONTEXT: Australia — Medicare, bulk billing, PBS, 000. Lifeline 13 11 14 for crisis.
OUTPUT: JSON only. Start with {, end with }. No markdown blocks.
''';

    try {
      debugPrint('🚀 OpenRouter: Sending generateAskAnswer request...');
      debugPrint('📋 OpenRouter: Question: "$question"');

      final response = await _sendChatWithFailover(
        messages: [
          {
            'role': 'system',
            'content':
                _systemInstruction, // Use the full health navigation system prompt
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        temperature: 0.7,
        maxTokens: 800, // Increased for JSON response
        topP: 0.9,
      );

      if (response == null) {
        debugPrint('❌ OpenRouter: generateAskAnswer returned NULL');
        return null;
      }

      debugPrint(
          '📥 OpenRouter: generateAskAnswer received ${response.length} chars');
      debugPrint(
          '📄 OpenRouter: Response preview: ${response.substring(0, response.length < 150 ? response.length : 150)}...');

      return response.trim();
    } catch (e) {
      debugPrint('❌ OpenRouter: Error generating answer: $e');
      return null;
    }
  }

  /// Generate a single clarifying follow-up question.
  Future<String?> generateFollowupQuestion({
    required String inputText,
    String? hint,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint(
            '❌ OpenRouter: Cannot generate follow-up - initialization failed');
        return null;
      }
    }

    final hintText = (hint != null && hint.trim().isNotEmpty)
        ? '\nWhat we need to know: $hint'
        : '';

    final prompt = '''
They said: "$inputText"
$hintText

Ask ONE follow-up question that:
- References something specific from what they wrote
- Fills in a gap (timing, severity, triggers, what helps, barriers)
- Sounds like a natural conversation, not a form
- Under 16 words

Don't ask generic questions. Make it about THEIR situation.
''';

    final response = await _sendChat(
      model: _activeModel ?? _candidateModels.first,
      messages: [
        const {
          'role': 'system',
          'content':
              'You are Starbound. Ask one short, specific follow-up question based on what the person actually said. Sound human, not clinical.',
        },
        {
          'role': 'user',
          'content': prompt.toString(),
        },
      ],
      temperature: 0.4,
      maxTokens: 60,
    );

    if (response == null) {
      return null;
    }
    return response.trim();
  }

  Future<List<String>> generateFollowUpQuestions({
    required String question,
    required String userName,
    required String complexityProfile,
    String? memorySummary,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ OpenRouter: Cannot generate follow-ups - init failed');
        return [];
      }
    }

    if (_activeModel == null && _candidateModels.isEmpty) {
      debugPrint('❌ OpenRouter: No model available for follow-ups');
      return [];
    }

    final name = userName.isNotEmpty ? userName : 'friend';
    final memoryContext =
        (memorySummary != null && memorySummary.trim().isNotEmpty)
            ? memorySummary.trim()
            : 'none';
    final prompt = '''
$name said: "$question"

Journal context: $memoryContext

---

STEP 1: Analyze what they told you
Look at their exact words. What did they mention? What's missing?

STEP 2: Ask questions about THEIR specific situation
Don't ask generic health questions. Ask about gaps in what THEY wrote.

EXAMPLES OF GOOD CONTEXT-SPECIFIC QUESTIONS:

If they said "I've been getting headaches lately":
- "Are these headaches different from ones you've had before?"
- "Do they hit at a particular time — morning, after screens, end of day?"
- "Has anything changed recently — sleep, stress, work?"

If they said "feeling really tired":
- "Is this a new kind of tired, or has it been building up?"
- "How's your sleep been — getting enough hours, or waking up tired anyway?"
- "Any other things feeling off alongside the tiredness?"

If they said "my anxiety has been bad":
- "Is there something specific triggering it, or is it more constant?"
- "How's it showing up for you — racing thoughts, physical tension, both?"
- "Have you tried anything that's helped before?"

YOUR QUESTIONS FOR $name:
- Reference something specific they mentioned
- Ask about what's UNCLEAR in their message
- Don't repeat info they already gave
- Keep each question short and focused

{
  "questions": [
    {"question": "[About something specific they mentioned or a gap in what they said]"},
    {"question": "[Another angle — timing, triggers, what helps, what makes it worse]"},
    {"question": "[If relevant: barriers to getting help — cost, time, transport]"}
  ]
}

Output JSON only.
''';

    try {
      final response = await _sendChatWithFailover(
        messages: [
          const {
            'role': 'system',
            'content':
                'You are Starbound, a health navigation assistant. Ask clarifying questions to understand health concerns safely and identify barriers to care. Output JSON only.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        temperature: 0.4,
        maxTokens: 420,
        topP: 0.85,
      );

      if (response == null || response.trim().isEmpty) {
        return [];
      }

      return _extractFollowUpQuestions(response);
    } catch (e) {
      debugPrint('❌ OpenRouter: Follow-up generation failed: $e');
      return [];
    }
  }

  /// Generate a short Home response card (what matters + next step)
  Future<Map<String, String>?> generateHomeCard({
    required String input,
    required List<String> signals,
    required String? memorySummary,
    required String responseShape,
    required String escalationTier,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('❌ OpenRouter: Cannot generate Home card - init failed');
        return null;
      }
    }

    if (_activeModel == null && _candidateModels.isEmpty) {
      debugPrint('❌ OpenRouter: No model available for Home card');
      return null;
    }

    final signalText = signals.isEmpty ? 'none' : signals.join(', ');
    final memoryText = memorySummary ?? 'none';
    final prompt = '''
They said: "$input"
Signals: $signalText
Recent patterns: $memoryText
Tone needed: $responseShape
Urgency: $escalationTier

Write two short, human sentences (not bullet points, not clinical):

VARY YOUR APPROACH:
- If worried → reassure first, then suggest action
- If asking practical question → give direct answer
- If frustrated → acknowledge it, then offer a path forward
- If describing symptoms → gentle + practical next step

{
  "what_matters": "[One warm sentence that shows you get what they're dealing with — under 16 words]",
  "next_step": "[One clear, specific action — under 16 words, no 'you should']"
}

Examples of good variation:
- "That headache sounds draining — try tracking when it hits worst."
- "Makes sense to check this out. A bulk-billing GP can take a look without the cost stress."
- "You've been pushing through a lot. Even 5 minutes of rest counts."

Output JSON only. Start with {.
''';

    try {
      final response = await _sendChatWithFailover(
        messages: [
          const {
            'role': 'system',
            'content':
                'You are Starbound, a health navigation assistant helping people access healthcare despite barriers. Output JSON only.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        temperature: 0.6,
        maxTokens: 200,
        topP: 0.8,
      );

      if (response == null || response.trim().isEmpty) {
        return null;
      }

      final decoded = _safeDecodeJsonMap(response);
      if (decoded == null) {
        return null;
      }

      final whatMatters = decoded['what_matters']?.toString().trim();
      final nextStep = decoded['next_step']?.toString().trim();
      if (whatMatters == null || nextStep == null) {
        return null;
      }
      return {
        'what_matters': whatMatters,
        'next_step': nextStep,
      };
    } catch (e) {
      debugPrint('❌ OpenRouter: Home card failed: $e');
      return null;
    }
  }

  /// Generate contextual journal check-in prompts based on user input
  Future<String?> generateContextualJournalPrompts({
    required String userInput,
    required String promptsContext,
    required bool isHighLoad,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return null;
      }
    }

    final prompt = '''
They shared: "$userInput"

Rewrite these journal check-in questions to feel like natural follow-ups to what they just said.

HOW TO MAKE IT CONTEXTUAL:
- Reference something specific from their input
- Questions should feel like a caring friend checking in
- Keep questions SHORT (under 12 words)
- Preface acknowledges what they shared (1 sentence max)
- ${isHighLoad ? 'Extra gentle — they seem to be struggling' : 'Warm but practical'}

CURRENT PROMPTS TO REWRITE:
$promptsContext

EXAMPLES OF GOOD CONTEXTUAL QUESTIONS:

If they said "had a rough day, headache won't go away":
→ EVENT: "How's that headache now?" (preface: "Rough days are harder with a headache.")
→ BEHAVIOUR: "Did you try anything for it?" (preface: "Even small things help.")
→ Labels: {"rested": "Took a break", "used medication": "Took something", "pushed through": "Pushed through anyway"}

If they said "feeling anxious about work tomorrow":
→ EVENT: "What part is weighing on you?" (preface: "Work stress can really sit with you.")
→ BEHAVIOUR: "Anything help settle the nerves?" (preface: "Sometimes small things make a difference.")

NOW REWRITE FOR: "$userInput"
- Connect each question to what they actually said
- Make it feel like you read their message
- Keep option KEYS the same, just update labels to fit

{
  "prompts": {
    "EVENT": {"prompt": "[short contextual question]", "preface": "[1 sentence acknowledging their input]", "labels": {}},
    "BEHAVIOUR": {"prompt": "[short contextual question]", "preface": "[1 sentence]", "labels": {"rested": "...", "pushed through": "..."}},
    "RELIEF": {"prompt": "[short contextual question]", "preface": "[1 sentence]", "labels": {}},
    "CONSTRAINT": {"prompt": "[short contextual question]", "preface": "[1 sentence]", "labels": {}},
    "STRENGTH": {"prompt": "[short contextual question]", "preface": "[1 sentence]", "labels": {}}
  }
}

JSON only. No markdown.
''';

    try {
      final response = await _sendChatWithFailover(
        messages: [
          const {
            'role': 'system',
            'content':
                'You are Starbound, rewriting journal check-in questions to feel personal and connected to what someone just shared. Output JSON only.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        temperature: 0.7,
        maxTokens: 600,
        topP: 0.9,
      );

      return response?.trim();
    } catch (e) {
      debugPrint('❌ OpenRouter: Journal prompts failed: $e');
      return null;
    }
  }

  /// Check if service is properly configured and ready
  bool get isConfigured => _apiKey != 'YOUR_API_KEY_HERE';
  bool get isInitialized => _isInitialized;

  Map<String, String> _buildHeaders(String apiKey) {
    final headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
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
    double temperature = 0.7,
    int maxTokens = 800,
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
    double temperature = 0.7,
    int maxTokens = 800,
    double topP = 0.8,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == 'YOUR_API_KEY_HERE') {
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
        headers: _buildHeaders(apiKey),
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
            '❌ OpenRouter: OpenRouter error ${response.statusCode} ${response.body}');
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
      debugPrint('❌ OpenRouter: OpenRouter request failed: $e');
    }

    return null;
  }

  Map<String, dynamic>? _safeDecodeJsonMap(String responseText) {
    if (responseText.trim().isEmpty) {
      return null;
    }

    String candidate = responseText.trim();
    if (candidate.startsWith('```')) {
      final fenceMatch =
          RegExp(r'```[a-zA-Z]*\s*([\s\S]*?)```').firstMatch(candidate);
      if (fenceMatch != null) {
        candidate = fenceMatch.group(1)?.trim() ?? candidate;
      }
    }

    Map<String, dynamic>? tryDecode(String text) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        // ignored
      }
      return null;
    }

    var decoded = tryDecode(candidate);
    if (decoded != null && decoded.isNotEmpty) {
      return decoded;
    }

    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      final sliced = candidate.substring(start, end + 1);
      decoded = tryDecode(sliced);
      if (decoded != null && decoded.isNotEmpty) {
        return decoded;
      }
    }

    return null;
  }

  List<dynamic>? _safeDecodeJsonList(String responseText) {
    if (responseText.trim().isEmpty) {
      return null;
    }

    String candidate = responseText.trim();
    if (candidate.startsWith('```')) {
      final fenceMatch =
          RegExp(r'```[a-zA-Z]*\s*([\s\S]*?)```').firstMatch(candidate);
      if (fenceMatch != null) {
        candidate = fenceMatch.group(1)?.trim() ?? candidate;
      }
    }

    try {
      final decoded = jsonDecode(candidate);
      if (decoded is List) {
        return decoded;
      }
    } catch (_) {
      // ignored
    }

    final start = candidate.indexOf('[');
    final end = candidate.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      try {
        final sliced = candidate.substring(start, end + 1);
        final decoded = jsonDecode(sliced);
        if (decoded is List) {
          return decoded;
        }
      } catch (_) {
        // ignored
      }
    }

    return null;
  }

  List<String> _extractFollowUpQuestions(String responseText) {
    final results = <String>[];
    final decodedMap = _safeDecodeJsonMap(responseText);
    if (decodedMap != null && decodedMap['questions'] is List) {
      final questions = decodedMap['questions'] as List;
      for (final entry in questions) {
        if (entry is String) {
          final trimmed = entry.trim();
          if (trimmed.isNotEmpty) {
            results.add(trimmed);
          }
        } else if (entry is Map && entry['question'] != null) {
          final trimmed = entry['question'].toString().trim();
          if (trimmed.isNotEmpty) {
            results.add(trimmed);
          }
        }
      }
    }

    if (results.isNotEmpty) {
      return results;
    }

    final decodedList = _safeDecodeJsonList(responseText);
    if (decodedList != null) {
      for (final entry in decodedList) {
        if (entry is String) {
          final trimmed = entry.trim();
          if (trimmed.isNotEmpty) {
            results.add(trimmed);
          }
        } else if (entry is Map && entry['question'] != null) {
          final trimmed = entry['question'].toString().trim();
          if (trimmed.isNotEmpty) {
            results.add(trimmed);
          }
        }
      }
    }

    if (results.isNotEmpty) {
      return results;
    }

    final fallbackLines = responseText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.endsWith('?'))
        .toList();
    return fallbackLines;
  }

  String _formatFollowUpAnswers(List<Map<String, String>> answers) {
    if (answers.isEmpty) {
      return 'none';
    }
    final lines = answers
        .map((entry) {
          final question = entry['question']?.trim() ?? '';
          final answer = entry['answer']?.trim() ?? '';
          if (question.isEmpty || answer.isEmpty) {
            return '';
          }
          return 'Q: $question A: $answer';
        })
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return 'none';
    }
    return lines.join(' | ');
  }

  /// Parse health navigation response from OpenRouter into StarboundResponse
  /// Returns null if parsing fails
  StarboundResponse? parseHealthNavigationResponse({
    required String responseText,
    required String userQuery,
  }) {
    try {
      debugPrint(
          '🔍 OpenRouter: Attempting to parse response (length: ${responseText.length})');
      debugPrint(
          '📝 OpenRouter: Response preview: ${responseText.substring(0, responseText.length < 200 ? responseText.length : 200)}...');

      // Try to parse the JSON response
      final jsonData = _safeDecodeJsonMap(responseText);
      if (jsonData == null) {
        debugPrint(
            '❌ OpenRouter: Failed to parse health navigation response as JSON');
        debugPrint('📄 OpenRouter: Full response text:\n$responseText');
        return null;
      }

      debugPrint('✅ OpenRouter: Successfully parsed JSON response');

      // Extract fields from the JSON response
      final understanding = jsonData['understanding']?.toString().trim() ?? '';
      final possibleCauses = jsonData['possible_causes'] as List?;
      final immediateStepsRaw = jsonData['immediate_steps'] as List?;
      final whenToSeekCareRaw = jsonData['when_to_seek_care'] as Map?;
      final resourceNeedsRaw = jsonData['resource_needs'] as List?;
      final followUpSuggestionsRaw = jsonData['follow_up_suggestions'] as List?;

      // Parse possible causes into InsightSections
      final insightSections = <InsightSection>[];
      if (possibleCauses != null) {
        for (final cause in possibleCauses) {
          if (cause is String && cause.trim().isNotEmpty) {
            insightSections.add(InsightSection(
              title: cause.trim(),
              summary: cause.trim(),
            ));
          } else if (cause is Map) {
            insightSections.add(InsightSection(
              title: cause['title']?.toString().trim() ?? cause.toString(),
              summary: cause['summary']?.toString().trim() ?? cause.toString(),
            ));
          }
        }
      }

      // Parse immediate steps into ActionableSteps
      final immediateSteps = <ActionableStep>[];
      if (immediateStepsRaw != null) {
        for (var i = 0; i < immediateStepsRaw.length; i++) {
          final step = immediateStepsRaw[i];
          if (step is String && step.trim().isNotEmpty) {
            immediateSteps.add(ActionableStep(
              id: 'step_$i',
              text: step.trim(),
            ));
          } else if (step is Map) {
            String? cleanValue(dynamic raw) {
              final value = raw?.toString().trim();
              if (value == null || value.isEmpty) return null;
              return value;
            }

            final title = cleanValue(step['title']) ?? '';
            final description =
                cleanValue(step['description']) ?? cleanValue(step['details']);
            final estimatedTime = cleanValue(step['estimated_time']) ??
                cleanValue(step['estimatedTime']);
            final theme = cleanValue(step['theme']);
            final text =
                title.isNotEmpty ? title : (description ?? step.toString());
            immediateSteps.add(ActionableStep(
              id: 'step_$i',
              text: text,
              details: description,
              estimatedTime: estimatedTime,
              theme: theme,
            ));
          }
        }
      }

      // Parse when to seek care
      WhenToSeekCare? whenToSeekCare;
      if (whenToSeekCareRaw != null) {
        whenToSeekCare = WhenToSeekCare(
          routine: whenToSeekCareRaw['routine']?.toString().trim(),
          urgent: whenToSeekCareRaw['urgent']?.toString().trim(),
          emergency: whenToSeekCareRaw['emergency']?.toString().trim(),
        );
      }

      // Parse resource needs
      final resourceNeeds = <String>[];
      if (resourceNeedsRaw != null) {
        for (final resource in resourceNeedsRaw) {
          if (resource is String && resource.trim().isNotEmpty) {
            resourceNeeds.add(resource.trim());
          }
        }
      }

      // Parse follow-up suggestions
      final followUpSuggestions = <String>[];
      if (followUpSuggestionsRaw != null) {
        for (final suggestion in followUpSuggestionsRaw) {
          if (suggestion is String && suggestion.trim().isNotEmpty) {
            followUpSuggestions.add(suggestion.trim());
          }
        }
      }

      // Create the StarboundResponse
      return StarboundResponse(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userQuery: userQuery,
        overview: understanding,
        immediateSteps: immediateSteps,
        nextSteps: [], // Health navigation doesn't use next steps
        actions: [], // Actions will be populated by the UI
        timestamp: DateTime.now(),
        insightSections: insightSections,
        aiSource: 'openrouter',
        whenToSeekCare: whenToSeekCare,
        resourceNeeds: resourceNeeds,
        followUpSuggestions: followUpSuggestions,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ OpenRouter: Error parsing health navigation response: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
