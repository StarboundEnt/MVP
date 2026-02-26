import 'complexity_engine_models.dart';

enum JournalPromptDomain { event, behaviour, relief, constraint, strength }

enum JournalPromptInputType { chips, shortText, mixed }

class JournalFactorRule {
  final String? option;
  final List<String> keywords;
  final List<FactorWrite> writesFactors;

  const JournalFactorRule({
    this.option,
    this.keywords = const [],
    this.writesFactors = const [],
  });
}

class JournalPrompt {
  final String id;
  final JournalPromptDomain domain;
  final String promptText;
  final String? prefaceText;
  final JournalPromptInputType inputType;
  final List<String> options;
  final Map<String, String> optionLabels;
  final List<JournalFactorRule> writesFactors;
  final bool skippable;

  const JournalPrompt({
    required this.id,
    required this.domain,
    required this.promptText,
    this.prefaceText,
    required this.inputType,
    this.options = const [],
    this.optionLabels = const {},
    this.writesFactors = const [],
    this.skippable = true,
  });

  JournalPrompt copyWith({
    String? promptText,
    String? prefaceText,
    List<String>? options,
    Map<String, String>? optionLabels,
  }) {
    return JournalPrompt(
      id: id,
      domain: domain,
      promptText: promptText ?? this.promptText,
      prefaceText: prefaceText ?? this.prefaceText,
      inputType: inputType,
      options: options ?? this.options,
      optionLabels: optionLabels ?? this.optionLabels,
      writesFactors: writesFactors,
      skippable: skippable,
    );
  }

  String labelForOption(String option) {
    return optionLabels[option] ?? option;
  }
}

class JournalPromptResponse {
  final String promptId;
  final List<String> selectedOptions;
  final String? text;
  final bool skipped;

  const JournalPromptResponse({
    required this.promptId,
    this.selectedOptions = const [],
    this.text,
    this.skipped = false,
  });

  bool get hasResponse =>
      selectedOptions.isNotEmpty || (text != null && text!.trim().isNotEmpty);

  JournalPromptResponse copyWith({
    List<String>? selectedOptions,
    String? text,
    bool? skipped,
  }) {
    return JournalPromptResponse(
      promptId: promptId,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      text: text ?? this.text,
      skipped: skipped ?? this.skipped,
    );
  }
}

class GuidedJournalResult {
  final String rawText;
  final List<FactorWrite> factorWrites;
  final Map<String, JournalPromptResponse> responses;
  final bool hasHealthSymptoms; // NEW: Detected health-related content
  final String? healthQuestion; // NEW: Extracted health question for AI

  const GuidedJournalResult({
    required this.rawText,
    required this.factorWrites,
    required this.responses,
    this.hasHealthSymptoms = false,
    this.healthQuestion,
  });

  bool get isEmpty => rawText.trim().isEmpty && factorWrites.isEmpty;
}
