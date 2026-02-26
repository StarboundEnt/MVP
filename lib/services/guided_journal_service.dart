import 'dart:convert';

import '../models/complexity_engine_models.dart';
import '../models/complexity_profile.dart';
import '../models/journal_prompt_model.dart';
import 'gemma_ai_service.dart';
import 'openrouter_service.dart';

class GuidedJournalService {
  const GuidedJournalService();

  static const Duration _aiTimeout = Duration(seconds: 2);
  static const List<JournalPromptDomain> _orderedDomains = [
    JournalPromptDomain.event,
    JournalPromptDomain.behaviour,
    JournalPromptDomain.relief,
    JournalPromptDomain.constraint,
    JournalPromptDomain.strength,
  ];

  Future<List<JournalPrompt>> buildV1PromptsForInput(
    String? input,
    ComplexityLevel complexityLevel, {
    bool useAi = true,
  }) async {
    final basePrompts = buildV1Prompts();
    final cleaned = input?.trim() ?? '';
    if (cleaned.isEmpty) {
      return _applyHeuristicPersonalisation(
        basePrompts,
        cleaned,
        complexityLevel,
      );
    }

    final selected = _selectDomainsHeuristic(cleaned);

    final promptByDomain = {
      for (final prompt in basePrompts) prompt.domain: prompt,
    };

    final ordered = <JournalPrompt>[];
    for (final domain in _orderedDomains) {
      if (selected.contains(domain)) {
        final prompt = promptByDomain[domain];
        if (prompt != null) {
          ordered.add(prompt);
        }
      }
    }

    if (ordered.isEmpty) {
      return basePrompts;
    }

    var personalised = _applyHeuristicPersonalisation(
      ordered,
      cleaned,
      complexityLevel,
    );

    if (useAi) {
      personalised = await _applyAiPersonalisation(
        personalised,
        cleaned,
        complexityLevel,
      );
    }

    return personalised;
  }

  List<JournalPrompt> buildV1Prompts() {
    return const [
      JournalPrompt(
        id: 'event',
        domain: JournalPromptDomain.event,
        promptText: "What's been most noticeable today?",
        inputType: JournalPromptInputType.mixed,
        options: [
          'pain',
          'headache',
          'fatigue',
          'nausea',
          'dizziness',
          'stress',
          'low mood',
        ],
        writesFactors: [
          JournalFactorRule(
            option: 'pain',
            writesFactors: [
              FactorWrite(code: FactorCode.symptomPain, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            keywords: ['pain', 'ache', 'sore', 'hurts'],
            writesFactors: [
              FactorWrite(code: FactorCode.symptomPain, confidence: 0.65),
            ],
          ),
          JournalFactorRule(
            option: 'headache',
            writesFactors: [
              FactorWrite(code: FactorCode.symptomHeadache, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            keywords: ['headache', 'migraine'],
            writesFactors: [
              FactorWrite(code: FactorCode.symptomHeadache, confidence: 0.65),
            ],
          ),
          JournalFactorRule(
            option: 'fatigue',
            writesFactors: [
              FactorWrite(code: FactorCode.capacityFatigue, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            keywords: ['tired', 'fatigue', 'exhausted', 'drained'],
            writesFactors: [
              FactorWrite(code: FactorCode.capacityFatigue, confidence: 0.65),
            ],
          ),
          JournalFactorRule(
            option: 'nausea',
            writesFactors: [
              FactorWrite(code: FactorCode.symptomNausea, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            keywords: ['nausea', 'nauseous', 'vomit'],
            writesFactors: [
              FactorWrite(code: FactorCode.symptomNausea, confidence: 0.65),
            ],
          ),
          JournalFactorRule(
            option: 'dizziness',
            writesFactors: [
              FactorWrite(code: FactorCode.symptomDizziness, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            keywords: ['dizzy', 'dizziness', 'lightheaded'],
            writesFactors: [
              FactorWrite(code: FactorCode.symptomDizziness, confidence: 0.65),
            ],
          ),
          JournalFactorRule(
            option: 'stress',
            writesFactors: [
              FactorWrite(code: FactorCode.emotionAnxietyStress, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            keywords: ['stress', 'stressed', 'anxious', 'anxiety', 'overwhelmed'],
            writesFactors: [
              FactorWrite(code: FactorCode.emotionAnxietyStress, confidence: 0.65),
            ],
          ),
          JournalFactorRule(
            option: 'low mood',
            writesFactors: [
              FactorWrite(code: FactorCode.emotionLowMood, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            keywords: ['low mood', 'sad', 'down', 'depressed'],
            writesFactors: [
              FactorWrite(code: FactorCode.emotionLowMood, confidence: 0.65),
            ],
          ),
        ],
      ),
      JournalPrompt(
        id: 'behaviour',
        domain: JournalPromptDomain.behaviour,
        promptText: 'Did you try anything to help yourself today?',
        inputType: JournalPromptInputType.chips,
        options: [
          'rested',
          'pushed through',
          'asked for help',
          'used medication',
          'changed plans',
          'nothing yet',
        ],
        writesFactors: [
          JournalFactorRule(
            option: 'rested',
            writesFactors: [
              FactorWrite(code: FactorCode.behaviourRested, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'pushed through',
            writesFactors: [
              FactorWrite(code: FactorCode.behaviourPushedThrough, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'asked for help',
            writesFactors: [
              FactorWrite(code: FactorCode.strengthAskedForHelp, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'used medication',
            writesFactors: [
              FactorWrite(code: FactorCode.medicalMedsMentioned, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'changed plans',
            writesFactors: [
              FactorWrite(code: FactorCode.behaviourChangedPlans, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'nothing yet',
            writesFactors: [
              FactorWrite(code: FactorCode.behaviourNoActionYet, confidence: 0.85),
            ],
          ),
        ],
      ),
      JournalPrompt(
        id: 'relief',
        domain: JournalPromptDomain.relief,
        promptText: 'Did anything help, even a little?',
        inputType: JournalPromptInputType.chips,
        options: [
          'rest',
          'distraction',
          'movement',
          'routine',
          'connection',
          'quiet',
          'nothing helped',
        ],
        writesFactors: [
          JournalFactorRule(
            option: 'rest',
            writesFactors: [
              FactorWrite(code: FactorCode.reliefRest, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'distraction',
            writesFactors: [
              FactorWrite(code: FactorCode.reliefDistraction, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'movement',
            writesFactors: [
              FactorWrite(code: FactorCode.reliefMovement, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'routine',
            writesFactors: [
              FactorWrite(code: FactorCode.reliefRoutine, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'connection',
            writesFactors: [
              FactorWrite(code: FactorCode.reliefConnection, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'quiet',
            writesFactors: [
              FactorWrite(code: FactorCode.reliefQuiet, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'nothing helped',
            writesFactors: [
              FactorWrite(code: FactorCode.reliefNone, confidence: 0.8),
            ],
          ),
        ],
      ),
      JournalPrompt(
        id: 'constraint',
        domain: JournalPromptDomain.constraint,
        promptText: 'What made today harder?',
        inputType: JournalPromptInputType.chips,
        options: [
          'time',
          'energy',
          'money',
          'access',
          'responsibilities',
          'symptoms',
          'uncertainty',
        ],
        writesFactors: [
          JournalFactorRule(
            option: 'time',
            writesFactors: [
              FactorWrite(code: FactorCode.resourceTimePressure, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'energy',
            writesFactors: [
              FactorWrite(code: FactorCode.capacityFatigue, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'money',
            writesFactors: [
              FactorWrite(code: FactorCode.resourceFinancialStrain, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'access',
            writesFactors: [
              FactorWrite(code: FactorCode.accessAppointmentBarrier, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'responsibilities',
            writesFactors: [
              FactorWrite(code: FactorCode.resourceCaregivingLoad, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'symptoms',
            writesFactors: [
              FactorWrite(code: FactorCode.symptomGeneral, confidence: 0.9),
            ],
          ),
          JournalFactorRule(
            option: 'uncertainty',
            writesFactors: [
              FactorWrite(code: FactorCode.knowledgeNeedsInformation, confidence: 0.9),
            ],
          ),
        ],
      ),
      JournalPrompt(
        id: 'strength',
        domain: JournalPromptDomain.strength,
        promptText: 'One small thing you handled okay today?',
        inputType: JournalPromptInputType.mixed,
        options: [
          'showed up',
          'took a break',
          'asked for help',
        ],
        writesFactors: [
          JournalFactorRule(
            option: 'showed up',
            writesFactors: [
              FactorWrite(
                code: FactorCode.strengthShowedUp,
                confidence: 0.9,
                timeHorizon: FactorTimeHorizon.lifeCourse,
              ),
            ],
          ),
          JournalFactorRule(
            option: 'took a break',
            writesFactors: [
              FactorWrite(
                code: FactorCode.strengthTookBreak,
                confidence: 0.9,
                timeHorizon: FactorTimeHorizon.lifeCourse,
              ),
            ],
          ),
          JournalFactorRule(
            option: 'asked for help',
            writesFactors: [
              FactorWrite(
                code: FactorCode.strengthAskedForHelp,
                confidence: 0.9,
                timeHorizon: FactorTimeHorizon.lifeCourse,
              ),
            ],
          ),
          JournalFactorRule(
            keywords: ['showed up', 'showing up', 'kept going'],
            writesFactors: [
              FactorWrite(
                code: FactorCode.strengthShowedUp,
                confidence: 0.7,
                timeHorizon: FactorTimeHorizon.lifeCourse,
              ),
            ],
          ),
          JournalFactorRule(
            keywords: ['break', 'rested', 'paused'],
            writesFactors: [
              FactorWrite(
                code: FactorCode.strengthTookBreak,
                confidence: 0.7,
                timeHorizon: FactorTimeHorizon.lifeCourse,
              ),
            ],
          ),
          JournalFactorRule(
            keywords: ['asked for help', 'reached out', 'support'],
            writesFactors: [
              FactorWrite(
                code: FactorCode.strengthAskedForHelp,
                confidence: 0.7,
                timeHorizon: FactorTimeHorizon.lifeCourse,
              ),
            ],
          ),
        ],
      ),
    ];
  }

  GuidedJournalResult buildResult({
    required List<JournalPrompt> prompts,
    required Map<String, JournalPromptResponse> responses,
  }) {
    final entries = <String>[];
    final writes = <FactorWrite>[];
    String? healthQuestion;
    bool hasHealthSymptoms = false;

    for (final prompt in prompts) {
      final response = responses[prompt.id];
      if (response == null || response.skipped) continue;

      final line = _formatEntryLine(prompt, response);
      if (line != null) {
        entries.add(line);
      }

      final responseWrites = _extractWrites(prompt, response);
      _mergeFactorWrites(writes, responseWrites);

      // NEW: Detect health symptoms in responses
      if (!hasHealthSymptoms && response.text != null) {
        final detected = _detectHealthSymptoms(response.text!);
        if (detected.isHealthRelated) {
          hasHealthSymptoms = true;
          healthQuestion = response.text!.trim();
        }
      }

      // Also check selected options for health symptoms
      if (!hasHealthSymptoms && response.selectedOptions.isNotEmpty) {
        final optionsText = response.selectedOptions.join(' ');
        final detected = _detectHealthSymptoms(optionsText);
        if (detected.isHealthRelated) {
          hasHealthSymptoms = true;
          healthQuestion = optionsText;
        }
      }
    }

    return GuidedJournalResult(
      rawText: entries.join('\n'),
      factorWrites: writes,
      responses: responses,
      hasHealthSymptoms: hasHealthSymptoms,
      healthQuestion: healthQuestion,
    );
  }

  /// Detect health symptoms in text
  ({bool isHealthRelated, double confidence}) _detectHealthSymptoms(String text) {
    final lower = text.toLowerCase();

    // Health symptom keywords
    final symptoms = [
      'pain', 'ache', 'headache', 'tired', 'fatigue', 'dizzy', 'nausea',
      'fever', 'cough', 'cold', 'flu', 'sick', 'hurt', 'sore', 'bleeding',
      'rash', 'itch', 'swollen', 'numb', 'weak', 'breath', 'chest',
      'stomach', 'vomit', 'diarrhea', 'constipation', 'migraine', 'cramp',
      'anxiety', 'depressed', 'panic', 'insomnia', 'sleep problem',
      'weight loss', 'weight gain', 'appetite', 'blood', 'pressure',
      'diabetes', 'sugar', 'infection', 'virus', 'bacteria', 'disease',
    ];

    // Health questions
    final questions = [
      'where can i get', 'how do i find', 'need a doctor', 'see a gp',
      'clinic near', 'health service', 'medical help', 'prescription',
      'medication', 'treatment', 'diagnosis', 'specialist',
    ];

    int symptomMatches = 0;
    int questionMatches = 0;

    for (final symptom in symptoms) {
      if (lower.contains(symptom)) {
        symptomMatches++;
      }
    }

    for (final question in questions) {
      if (lower.contains(question)) {
        questionMatches++;
      }
    }

    final isHealthRelated = symptomMatches > 0 || questionMatches > 0;
    final confidence = (symptomMatches + questionMatches * 2) / 10.0;

    return (isHealthRelated: isHealthRelated, confidence: confidence.clamp(0.0, 1.0));
  }

  List<JournalPrompt> _applyHeuristicPersonalisation(
    List<JournalPrompt> prompts,
    String input,
    ComplexityLevel complexityLevel,
  ) {
    final snippet = _buildInputSnippet(input);
    return prompts.map((prompt) {
      final promptText = _buildTonePrompt(prompt.domain, complexityLevel);
      final preface =
          _buildPrefaceText(prompt.domain, snippet, complexityLevel);
      final labels =
          _buildOptionLabels(prompt, input, complexityLevel);
      final options = _prioritiseOptions(prompt, input);
      return prompt.copyWith(
        promptText: promptText,
        prefaceText: preface,
        optionLabels: labels,
        options: options,
      );
    }).toList();
  }

  Future<List<JournalPrompt>> _applyAiPersonalisation(
    List<JournalPrompt> prompts,
    String input,
    ComplexityLevel complexityLevel,
  ) async {
    try {
      final isHighLoad = complexityLevel == ComplexityLevel.overloaded ||
          complexityLevel == ComplexityLevel.survival;

      // Build context about current prompts
      final promptsContext = prompts.map((prompt) {
        final options = prompt.options
            .map((option) => '$option: ${prompt.labelForOption(option)}')
            .join(', ');
        return '${prompt.domain.name.toUpperCase()}: "${prompt.promptText}" | options: [$options]';
      }).join('\n');

      // Try OpenRouter first for better contextual generation
      final openRouter = OpenRouterService();
      String? response;

      if (openRouter.isConfigured) {
        await openRouter.initialize();
        response = await openRouter.generateContextualJournalPrompts(
          userInput: input,
          promptsContext: promptsContext,
          isHighLoad: isHighLoad,
        );
      }

      // Fall back to Gemma if OpenRouter fails
      if (response == null || response.isEmpty) {
        final fallbackPrompt = _buildContextualAiPrompt(input, complexityLevel, prompts);
        response = await GemmaAIService()
            .generateResponse(fallbackPrompt)
            .timeout(_aiTimeout);
      }

      final overrides = _parseAiPromptOverrides(response);
      if (overrides.isEmpty) {
        return prompts;
      }

      final updated = <JournalPrompt>[];
      for (final item in prompts) {
        final override = overrides[item.domain];
        if (override == null) {
          updated.add(item);
          continue;
        }
        updated.add(
          item.copyWith(
            promptText: override.promptText ?? item.promptText,
            prefaceText: override.prefaceText ?? item.prefaceText,
            optionLabels: override.optionLabels.isEmpty
                ? item.optionLabels
                : override.optionLabels,
          ),
        );
      }
      return updated;
    } catch (_) {
      return prompts;
    }
  }

  String _buildTonePrompt(
    JournalPromptDomain domain,
    ComplexityLevel complexityLevel,
  ) {
    final isHighLoad = complexityLevel == ComplexityLevel.overloaded ||
        complexityLevel == ComplexityLevel.survival;

    switch (domain) {
      case JournalPromptDomain.event:
        return isHighLoad
            ? 'Most noticeable today?'
            : "What stood out most today?";
      case JournalPromptDomain.behaviour:
        return isHighLoad
            ? 'Did you try anything to help?'
            : 'Did you try anything to help yourself today?';
      case JournalPromptDomain.relief:
        return isHighLoad
            ? 'Anything help even a little?'
            : 'Did anything help, even a little?';
      case JournalPromptDomain.constraint:
        return 'What made today harder?';
      case JournalPromptDomain.strength:
        return isHighLoad
            ? 'One small thing you handled okay?'
            : 'One small thing you handled okay today?';
    }
  }

  String _buildPrefaceText(
    JournalPromptDomain domain,
    String snippet,
    ComplexityLevel complexityLevel,
  ) {
    final isHighLoad = complexityLevel == ComplexityLevel.overloaded ||
        complexityLevel == ComplexityLevel.survival;
    final softPrefix = isHighLoad ? 'Thanks for sharing.' : 'Thanks for sharing.';

    switch (domain) {
      case JournalPromptDomain.event:
        return snippet.isEmpty ? softPrefix : '$softPrefix You mentioned $snippet.';
      case JournalPromptDomain.behaviour:
        return isHighLoad
            ? 'Any steps you tried matter.'
            : 'Knowing what you tried helps me tailor support.';
      case JournalPromptDomain.relief:
        return isHighLoad
            ? 'Even small reliefs count.'
            : 'Noting what helped builds a clearer picture.';
      case JournalPromptDomain.constraint:
        return isHighLoad
            ? 'It is okay if today felt hard.'
            : 'Naming friction helps me reduce it.';
      case JournalPromptDomain.strength:
        return isHighLoad
            ? 'Small wins still count.'
            : 'Small wins build resilience.';
    }
  }

  Map<String, String> _buildOptionLabels(
    JournalPrompt prompt,
    String input,
    ComplexityLevel complexityLevel,
  ) {
    final isHighLoad = complexityLevel == ComplexityLevel.overloaded ||
        complexityLevel == ComplexityLevel.survival;

    final labels = <String, String>{};
    switch (prompt.domain) {
      case JournalPromptDomain.event:
        labels.addAll({
          'pain': 'pain/aches',
          'headache': 'headache/migraine',
          'fatigue': isHighLoad ? 'worn out' : 'fatigue',
          'nausea': 'nausea/queasy',
          'dizziness': 'dizzy/lightheaded',
          'stress': 'stress/anxiety',
          'low mood': 'low mood/down',
        });
        _applyInputLabelOverrides(labels, input);
        break;
      case JournalPromptDomain.behaviour:
        labels.addAll({
          'rested': isHighLoad ? 'rested a bit' : 'rested',
          'pushed through': 'pushed through',
          'asked for help': isHighLoad ? 'reached out' : 'asked for help',
          'used medication': isHighLoad ? 'took meds' : 'used medication',
          'changed plans': 'changed plans',
          'nothing yet': isHighLoad ? 'not yet' : 'nothing yet',
        });
        break;
      case JournalPromptDomain.relief:
        labels.addAll({
          'rest': isHighLoad ? 'rested' : 'rest',
          'distraction': 'distraction',
          'movement': isHighLoad ? 'gentle movement' : 'movement',
          'routine': 'routine',
          'connection': isHighLoad ? 'checked in' : 'connection',
          'quiet': 'quiet',
          'nothing helped': isHighLoad ? 'nothing helped' : 'nothing helped',
        });
        break;
      case JournalPromptDomain.constraint:
        labels.addAll({
          'time': 'time',
          'energy': 'energy',
          'money': 'money',
          'access': 'access',
          'responsibilities': isHighLoad ? 'responsibilities' : 'responsibilities',
          'symptoms': 'symptoms',
          'uncertainty': 'uncertainty',
        });
        _applyInputConstraintOverrides(labels, input);
        break;
      case JournalPromptDomain.strength:
        labels.addAll({
          'showed up': 'showed up',
          'took a break': isHighLoad ? 'took a break' : 'took a break',
          'asked for help': isHighLoad ? 'reached out' : 'asked for help',
        });
        break;
    }

    final filtered = <String, String>{};
    for (final option in prompt.options) {
      filtered[option] = labels[option] ?? option;
    }
    return filtered;
  }

  void _applyInputLabelOverrides(Map<String, String> labels, String input) {
    final normalized = input.toLowerCase();
    if (normalized.contains('dizzy') || normalized.contains('lightheaded')) {
      labels['dizziness'] = 'dizzy/lightheaded';
    }
    if (normalized.contains('headache') || normalized.contains('migraine')) {
      labels['headache'] = 'headache/migraine';
    }
    if (normalized.contains('nausea') || normalized.contains('queasy')) {
      labels['nausea'] = 'nausea/queasy';
    }
    if (normalized.contains('stress') || normalized.contains('anxious')) {
      labels['stress'] = 'stress/anxiety';
    }
    if (normalized.contains('sad') || normalized.contains('down')) {
      labels['low mood'] = 'low mood/down';
    }
  }

  void _applyInputConstraintOverrides(
      Map<String, String> labels, String input) {
    final normalized = input.toLowerCase();
    if (normalized.contains('work') || normalized.contains('busy')) {
      labels['time'] = 'time/work';
    }
    if (normalized.contains('money') || normalized.contains('bills')) {
      labels['money'] = 'money/budget';
    }
    if (normalized.contains('kids') ||
        normalized.contains('family') ||
        normalized.contains('care')) {
      labels['responsibilities'] = 'responsibilities/care';
    }
  }

  List<String> _prioritiseOptions(JournalPrompt prompt, String input) {
    if (prompt.domain != JournalPromptDomain.event) {
      return prompt.options;
    }

    final normalized = input.toLowerCase();
    final scoreByOption = <String, int>{};
    const optionKeywords = {
      'pain': ['pain', 'ache', 'sore'],
      'headache': ['headache', 'migraine'],
      'fatigue': ['tired', 'fatigue', 'exhausted', 'drained'],
      'nausea': ['nausea', 'nauseous', 'queasy'],
      'dizziness': ['dizzy', 'dizziness', 'lightheaded'],
      'stress': ['stress', 'anxious', 'overwhelmed'],
      'low mood': ['low mood', 'sad', 'down', 'depressed'],
    };

    for (final option in prompt.options) {
      final keywords = optionKeywords[option] ?? const [];
      final matches = keywords.where((word) => normalized.contains(word)).length;
      scoreByOption[option] = matches;
    }

    final sorted = List<String>.from(prompt.options);
    sorted.sort((a, b) {
      final scoreA = scoreByOption[a] ?? 0;
      final scoreB = scoreByOption[b] ?? 0;
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }
      return prompt.options.indexOf(a).compareTo(prompt.options.indexOf(b));
    });
    return sorted;
  }

  String _buildInputSnippet(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    if (cleaned.isEmpty) return '';
    final truncated = cleaned.length > 60 ? cleaned.substring(0, 60) : cleaned;
    final trimmed = truncated.trim().replaceAll(RegExp(r'[.!?]+$'), '');
    if (trimmed.toLowerCase().startsWith('i ')) {
      return trimmed.substring(2).trim();
    }
    return trimmed;
  }

  String _buildContextualAiPrompt(
    String input,
    ComplexityLevel complexityLevel,
    List<JournalPrompt> prompts,
  ) {
    final promptLines = prompts.map((prompt) {
      final options = prompt.options
          .map((option) => '${option}: ${prompt.labelForOption(option)}')
          .join(', ');
      return '${prompt.domain.name.toUpperCase()}: "${prompt.promptText}" | options: [$options]';
    }).join('\n');

    final isHighLoad = complexityLevel == ComplexityLevel.overloaded ||
        complexityLevel == ComplexityLevel.survival;

    return '''
They said: "$input"

Rewrite these journal check-in questions to feel like natural follow-ups to what they just shared.

RULES:
- Reference something specific from their input
- Questions should feel like a caring friend checking in, not a form
- Keep questions short (under 12 words)
- Preface should acknowledge what they shared (1 sentence)
- Option labels can be tweaked to feel more relevant
- ${isHighLoad ? 'Keep it extra gentle — they seem to be having a hard time' : 'Warm but practical tone'}

CURRENT PROMPTS:
$promptLines

EXAMPLE OF GOOD CONTEXTUAL REWRITING:

If they said "had a rough day, headache won't go away":
- EVENT prompt: "How's that headache feeling now?" (preface: "Rough days are hard, especially with a headache on top.")
- BEHAVIOUR prompt: "Did you try anything for the headache?" (preface: "Sometimes small things help.")
- BEHAVIOUR labels: {"rested": "Took a break", "used medication": "Took something for it", "pushed through": "Powered through"}

If they said "feeling anxious about work tomorrow":
- EVENT prompt: "What's weighing on you most?" (preface: "Work stress can sit heavy.")
- BEHAVIOUR prompt: "Did you do anything to settle the nerves?" (preface: "Even small things count.")

YOUR TASK:
Rewrite each prompt to connect to "$input"
Keep the same option KEYS but update labels to feel relevant.

Return JSON only:
{
  "prompts": {
    "EVENT": {"prompt": "...", "preface": "...", "labels": {"pain": "..."}},
    "BEHAVIOUR": {"prompt": "...", "preface": "...", "labels": {"rested": "...", "pushed through": "..."}}
  }
}
''';
  }

  Map<JournalPromptDomain, _PromptOverride> _parseAiPromptOverrides(
      String response) {
    final cleaned = _extractJsonObject(response.trim());
    if (cleaned == null) return {};
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is! Map) return {};
      final prompts = decoded['prompts'];
      if (prompts is! Map) return {};

      final overrides = <JournalPromptDomain, _PromptOverride>{};
      for (final entry in prompts.entries) {
        final domain = _domainFromString(entry.key.toString());
        if (domain == null) continue;
        final value = entry.value;
        if (value is! Map) continue;
        final promptText = value['prompt']?.toString();
        final prefaceText = value['preface']?.toString();
        final labels = <String, String>{};
        final rawLabels = value['labels'];
        if (rawLabels is Map) {
          for (final labelEntry in rawLabels.entries) {
            labels[labelEntry.key.toString()] =
                labelEntry.value.toString();
          }
        }
        overrides[domain] = _PromptOverride(
          promptText: promptText,
          prefaceText: prefaceText,
          optionLabels: labels,
        );
      }

      return overrides;
    } catch (_) {
      return {};
    }
  }

  Future<Set<JournalPromptDomain>> _selectDomainsWithAi(
      String input) async {
    final fallback = _selectDomainsHeuristic(input);
    try {
      final prompt = _buildGuidedSelectionPrompt(input);
      final response = await GemmaAIService()
          .generateResponse(prompt)
          .timeout(_aiTimeout);
      final selected = _parseDomainsFromResponse(response);
      if (selected.isEmpty) {
        return fallback;
      }
      return _ensureRequiredDomains(selected);
    } catch (_) {
      return fallback;
    }
  }

  Set<JournalPromptDomain> _selectDomainsHeuristic(String input) {
    final normalized = input.toLowerCase();
    final selected = <JournalPromptDomain>{
      JournalPromptDomain.event,
      JournalPromptDomain.strength,
    };

    const behaviourKeywords = [
      'rested',
      'rest',
      'pushed through',
      'asked for help',
      'help',
      'medication',
      'meds',
      'changed plans',
      'nothing yet',
    ];
    const reliefKeywords = [
      'helped',
      'relief',
      'rest',
      'distraction',
      'movement',
      'routine',
      'connection',
      'quiet',
      'nothing helped',
    ];
    const constraintKeywords = [
      'time',
      'energy',
      'money',
      'access',
      'responsibilities',
      'symptoms',
      'uncertainty',
      'busy',
      'overwhelmed',
    ];

    if (_containsAny(normalized, behaviourKeywords)) {
      selected.add(JournalPromptDomain.behaviour);
    }
    if (_containsAny(normalized, reliefKeywords)) {
      selected.add(JournalPromptDomain.relief);
    }
    if (_containsAny(normalized, constraintKeywords)) {
      selected.add(JournalPromptDomain.constraint);
    }

    if (selected.length == 2) {
      selected.add(JournalPromptDomain.behaviour);
    }

    return selected;
  }

  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((keyword) => input.contains(keyword));
  }

  String _buildGuidedSelectionPrompt(String input) {
    return '''
You are selecting which guided journaling prompts are relevant to the user's input.

Return JSON only, no commentary.
Allowed domains: EVENT, BEHAVIOUR, RELIEF, CONSTRAINT, STRENGTH.
Always include EVENT and STRENGTH. Include the others only if relevant.

User input:
"$input"

Return format:
{"domains":["EVENT","BEHAVIOUR"]}
''';
  }

  Set<JournalPromptDomain> _parseDomainsFromResponse(String response) {
    final cleaned = _extractJsonObject(response.trim());
    if (cleaned == null) return {};

    try {
      final decoded = jsonDecode(cleaned);
      final rawDomains = decoded is Map<String, dynamic>
          ? decoded['domains']
          : decoded;
      if (rawDomains is! List) {
        return {};
      }
      final parsed = rawDomains
          .map((item) => _domainFromString(item.toString()))
          .whereType<JournalPromptDomain>()
          .toSet();
      return _ensureRequiredDomains(parsed);
    } catch (_) {
      return {};
    }
  }

  String? _extractJsonObject(String response) {
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return null;
    }
    return response.substring(start, end + 1);
  }

  Set<JournalPromptDomain> _ensureRequiredDomains(
      Set<JournalPromptDomain> selected) {
    return {
      ...selected,
      JournalPromptDomain.event,
      JournalPromptDomain.strength,
    };
  }

  JournalPromptDomain? _domainFromString(String value) {
    switch (value.toUpperCase()) {
      case 'EVENT':
        return JournalPromptDomain.event;
      case 'BEHAVIOUR':
        return JournalPromptDomain.behaviour;
      case 'RELIEF':
        return JournalPromptDomain.relief;
      case 'CONSTRAINT':
        return JournalPromptDomain.constraint;
      case 'STRENGTH':
        return JournalPromptDomain.strength;
      default:
        return null;
    }
  }

  String? _formatEntryLine(
    JournalPrompt prompt,
    JournalPromptResponse response,
  ) {
    final parts = <String>[];
    if (response.selectedOptions.isNotEmpty) {
      final labels = response.selectedOptions
          .map((option) => prompt.labelForOption(option))
          .toList();
      parts.add(labels.join(', '));
    }
    final text = response.text?.trim();
    if (text != null && text.isNotEmpty) {
      parts.add(text);
    }
    if (parts.isEmpty) return null;
    return '${_promptLabel(prompt.domain)}: ${parts.join(' | ')}';
  }

  List<FactorWrite> _extractWrites(
    JournalPrompt prompt,
    JournalPromptResponse response,
  ) {
    final writes = <FactorWrite>[];
    final text = response.text?.toLowerCase().trim();

    for (final rule in prompt.writesFactors) {
      if (rule.option != null &&
          response.selectedOptions.contains(rule.option)) {
        writes.addAll(rule.writesFactors);
      }
      if (text != null &&
          text.isNotEmpty &&
          rule.keywords.isNotEmpty &&
          _matchesKeywords(text, rule.keywords)) {
        writes.addAll(rule.writesFactors);
      }
    }

    if (prompt.domain == JournalPromptDomain.strength &&
        text != null &&
        text.isNotEmpty &&
        !_hasStrengthWrite(writes)) {
      writes.add(
        const FactorWrite(
          code: FactorCode.strengthResilience,
          confidence: 0.7,
          timeHorizon: FactorTimeHorizon.lifeCourse,
        ),
      );
    }

    return writes;
  }

  bool _matchesKeywords(String text, List<String> keywords) {
    for (final keyword in keywords) {
      final pattern = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  bool _hasStrengthWrite(List<FactorWrite> writes) {
    return writes.any(
      (write) => {
        FactorCode.strengthShowedUp,
        FactorCode.strengthTookBreak,
        FactorCode.strengthAskedForHelp,
        FactorCode.strengthResilience,
      }.contains(write.code),
    );
  }

  void _mergeFactorWrites(List<FactorWrite> target, List<FactorWrite> incoming) {
    for (final write in incoming) {
      final existingIndex =
          target.indexWhere((item) => item.code == write.code);
      if (existingIndex == -1) {
        target.add(write);
      } else if (target[existingIndex].confidence < write.confidence) {
        target[existingIndex] = write;
      }
    }
  }

  String _promptLabel(JournalPromptDomain domain) {
    switch (domain) {
      case JournalPromptDomain.event:
        return 'Event';
      case JournalPromptDomain.behaviour:
        return 'Behaviour';
      case JournalPromptDomain.relief:
        return 'Relief';
      case JournalPromptDomain.constraint:
        return 'Constraint';
      case JournalPromptDomain.strength:
        return 'Strength';
    }
  }
}

class _PromptOverride {
  final String? promptText;
  final String? prefaceText;
  final Map<String, String> optionLabels;

  const _PromptOverride({
    this.promptText,
    this.prefaceText,
    this.optionLabels = const {},
  });
}
