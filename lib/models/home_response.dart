enum ResponseShape {
  clarifyingQuestion,
  gentleReflection,
  concreteNextStep,
  optionComparison,
  escalationSupport,
  patternRecall,
}

enum EscalationTier {
  none,
  gentle,
  strong,
  crisis,
}

enum HomeActionChip {
  clarify,
  save,
  getSupport,
  justSave,
  nextStep,
}

class HomeResponseData {
  final String whatMatters;
  final String nextStep;
  final ResponseShape shape;
  final EscalationTier escalationTier;
  final List<HomeActionChip> actionChips;
  final List<String> statusLines;
  final List<String> signals;
  final String? rememberedSummary;
  final bool memoryUsed;

  const HomeResponseData({
    required this.whatMatters,
    required this.nextStep,
    required this.shape,
    required this.escalationTier,
    this.actionChips = const [],
    this.statusLines = const [],
    this.signals = const [],
    this.rememberedSummary,
    this.memoryUsed = false,
  });
}

class HomeResponseDecision {
  final HomeResponseData? response;
  final bool shouldSave;
  final bool logOnly;

  const HomeResponseDecision({
    required this.response,
    required this.shouldSave,
    required this.logOnly,
  });
}

class HomeMemoryContext {
  final bool used;
  final bool hasRecurrence;
  final List<String> themes;
  final String? summary;

  const HomeMemoryContext({
    required this.used,
    required this.hasRecurrence,
    this.themes = const [],
    this.summary,
  });
}
