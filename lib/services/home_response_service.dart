import '../models/complexity_profile.dart';
import '../models/home_response.dart';
import 'smart_input_service.dart';

class HomeResponseService {
  HomeResponseDecision buildDecision(
    SmartInputResult result, {
    HomeMemoryContext? memoryContext,
    bool ignoreLogOnly = false,
    bool suppressAutoSave = false,
    ComplexityLevel? complexityLevel,
  }) {
    final text = result.processedText.trim();
    if (text.isEmpty) {
      return const HomeResponseDecision(
        response: null,
        shouldSave: false,
        logOnly: false,
      );
    }

    final lowerText = text.toLowerCase();
    final bool logOnly = _containsAny(lowerText, _logOnlyPhrases);
    if (logOnly && !ignoreLogOnly) {
      final response = HomeResponseData(
        whatMatters: 'Logged.',
        nextStep: 'Want a next step, or just saving today?',
        shape: ResponseShape.clarifyingQuestion,
        escalationTier: EscalationTier.none,
        actionChips: const [HomeActionChip.justSave, HomeActionChip.nextStep],
        statusLines: const [],
        signals: const [],
        rememberedSummary: null,
        memoryUsed: false,
      );
      return HomeResponseDecision(
        response: response,
        shouldSave: false,
        logOnly: true,
      );
    }

    final bool isQuestion = result.tags.isQuestion ||
        lowerText.contains('?') ||
        _containsAny(lowerText, _questionPhrases);
    final bool uncertainty = _containsAny(lowerText, _uncertaintyPhrases);
    final bool hasHighEmotion = _containsAny(lowerText, _highEmotionWords);
    final bool hasMediumEmotion =
        hasHighEmotion || result.tags.emotions.isNotEmpty || _containsAny(lowerText, _mediumEmotionWords);
    final EmotionalLoad emotionalLoad = hasHighEmotion
        ? EmotionalLoad.high
        : (hasMediumEmotion ? EmotionalLoad.medium : EmotionalLoad.low);
    final TimePressure timePressure = _detectTimePressure(lowerText);
    final Agency agency = _detectAgency(lowerText);
    final Complexity complexity = _detectComplexity(result.tags, lowerText);
    final List<String> socialSignals = _detectSocialSignals(lowerText);
    final RiskFlag riskFlag = _detectRisk(lowerText);
    final bool isolation = _containsAny(lowerText, _isolationWords);
    final bool cantCope = _containsAny(lowerText, _cantCopeWords);

    final EscalationTier tier = _detectEscalationTier(
      riskFlag: riskFlag,
      emotionalLoad: emotionalLoad,
      agency: agency,
      timePressure: timePressure,
      isolation: isolation,
      cantCope: cantCope,
    );

    final bool hasRecurrence = memoryContext?.hasRecurrence ?? false;
    final ResponseShape shape = _selectShape(
      tier: tier,
      isQuestion: isQuestion,
      uncertainty: uncertainty,
      complexity: complexity,
      agency: agency,
      intent: result.intent,
      emotionalLoad: emotionalLoad,
      lowerText: lowerText,
      hasRecurrence: hasRecurrence,
    );

    final bool shouldSave = _shouldAutoSave(
      intent: result.intent,
      emotionalLoad: emotionalLoad,
      isQuestion: isQuestion,
      hasEmotions: result.tags.emotions.isNotEmpty,
    );
    final bool noSave = _containsAny(lowerText, _noSavePhrases);
    final bool effectiveSave = !noSave && !suppressAutoSave && shouldSave;

    final List<String> signals = _buildSignals(
      emotionalLoad: emotionalLoad,
      timePressure: timePressure,
      complexity: complexity,
      agency: agency,
      socialSignals: socialSignals,
      memoryContext: memoryContext,
    );

    final bool memoryUsed = memoryContext?.used ?? false;

    final String whatMatters = _buildWhatMatters(
      shape: shape,
      emotionalLoad: emotionalLoad,
      timePressure: timePressure,
      complexity: complexity,
      agency: agency,
      isQuestion: isQuestion,
      hasRecurrence: hasRecurrence,
    );
    final String nextStep = _buildNextStep(
      shape: shape,
      tier: tier,
      timePressure: timePressure,
      agency: agency,
      complexityLevel: complexityLevel,
    );

    final List<HomeActionChip> chips = _buildChips(
      shape: shape,
      tier: tier,
      shouldSave: effectiveSave,
    );

    final List<String> statusLines = _buildStatusLines(
      shouldSave: effectiveSave,
      hasHealthTopics: result.tags.healthTopics.isNotEmpty,
      memoryUsed: memoryUsed,
    );

    final response = HomeResponseData(
      whatMatters: whatMatters,
      nextStep: nextStep,
      shape: shape,
      escalationTier: tier,
      actionChips: chips,
      statusLines: statusLines,
      signals: signals,
      rememberedSummary: memoryContext?.summary,
      memoryUsed: memoryUsed,
    );

    return HomeResponseDecision(
      response: response,
      shouldSave: effectiveSave,
      logOnly: false,
    );
  }

  EscalationTier _detectEscalationTier({
    required RiskFlag riskFlag,
    required EmotionalLoad emotionalLoad,
    required Agency agency,
    required TimePressure timePressure,
    required bool isolation,
    required bool cantCope,
  }) {
    if (riskFlag != RiskFlag.none) {
      return EscalationTier.crisis;
    }

    if (emotionalLoad == EmotionalLoad.high && agency == Agency.blocked) {
      return EscalationTier.strong;
    }

    if (emotionalLoad == EmotionalLoad.high &&
        timePressure == TimePressure.high &&
        (agency != Agency.canActNow || isolation || cantCope)) {
      return EscalationTier.strong;
    }

    if (emotionalLoad == EmotionalLoad.high && agency != Agency.canActNow) {
      return EscalationTier.gentle;
    }

    return EscalationTier.none;
  }

  ResponseShape _selectShape({
    required EscalationTier tier,
    required bool isQuestion,
    required bool uncertainty,
    required Complexity complexity,
    required Agency agency,
    required SmartRouteIntent intent,
    required EmotionalLoad emotionalLoad,
    required String lowerText,
    required bool hasRecurrence,
  }) {
    if (tier == EscalationTier.strong || tier == EscalationTier.crisis) {
      return ResponseShape.escalationSupport;
    }

    if (hasRecurrence && !isQuestion) {
      return ResponseShape.patternRecall;
    }

    if (complexity == Complexity.systemic || agency == Agency.blocked) {
      return ResponseShape.optionComparison;
    }

    if (isQuestion) {
      if (_containsAny(lowerText, _optionPhrases)) {
        return ResponseShape.optionComparison;
      }
      return ResponseShape.clarifyingQuestion;
    }

    if (uncertainty) {
      return emotionalLoad == EmotionalLoad.high || emotionalLoad == EmotionalLoad.medium
          ? ResponseShape.gentleReflection
          : ResponseShape.clarifyingQuestion;
    }

    if (intent == SmartRouteIntent.journal ||
        intent == SmartRouteIntent.guidedJournal) {
      return emotionalLoad == EmotionalLoad.low
          ? ResponseShape.concreteNextStep
          : ResponseShape.gentleReflection;
    }

    return ResponseShape.concreteNextStep;
  }

  bool _shouldAutoSave({
    required SmartRouteIntent intent,
    required EmotionalLoad emotionalLoad,
    required bool isQuestion,
    required bool hasEmotions,
  }) {
    if (isQuestion && intent == SmartRouteIntent.ask) {
      return false;
    }
    if (intent == SmartRouteIntent.journal ||
        intent == SmartRouteIntent.guidedJournal ||
        intent == SmartRouteIntent.both) {
      return true;
    }
    if (hasEmotions) {
      return true;
    }
    return emotionalLoad != EmotionalLoad.low;
  }

  List<HomeActionChip> _buildChips({
    required ResponseShape shape,
    required EscalationTier tier,
    required bool shouldSave,
  }) {
    final chips = <HomeActionChip>[];
    if (shape == ResponseShape.clarifyingQuestion) {
      chips.add(HomeActionChip.clarify);
    }
    if (!shouldSave &&
        (shape == ResponseShape.gentleReflection ||
            shape == ResponseShape.concreteNextStep ||
            shape == ResponseShape.patternRecall)) {
      chips.add(HomeActionChip.save);
    }
    if (tier == EscalationTier.gentle ||
        tier == EscalationTier.strong ||
        tier == EscalationTier.crisis) {
      chips.add(HomeActionChip.getSupport);
    }
    return chips;
  }

  List<String> _buildStatusLines({
    required bool shouldSave,
    required bool hasHealthTopics,
    required bool memoryUsed,
  }) {
    final lines = <String>[];
    if (shouldSave) {
      lines.add('Saved to Journal');
    }
    if (memoryUsed) {
      lines.add('Using past entries to personalize this');
    }
    if (hasHealthTopics) {
      lines.add('Not medical advice');
    }
    return lines;
  }

  String _buildWhatMatters({
    required ResponseShape shape,
    required EmotionalLoad emotionalLoad,
    required TimePressure timePressure,
    required Complexity complexity,
    required Agency agency,
    required bool isQuestion,
    required bool hasRecurrence,
  }) {
    if (shape == ResponseShape.escalationSupport) {
      return 'Safety and real-time support come first right now.';
    }

    if (hasRecurrence) {
      return 'This theme has come up a few times recently. Focus on the smallest step that reduces friction.';
    }

    final parts = <String>[];
    if (emotionalLoad == EmotionalLoad.high) {
      parts.add('This is heavy and high-stakes.');
    } else if (emotionalLoad == EmotionalLoad.medium) {
      parts.add('There is a lot of weight here.');
    }

    if (timePressure == TimePressure.high) {
      parts.add('Time pressure is high.');
    }

    if (complexity == Complexity.systemic) {
      parts.add('Multiple constraints are pulling at once.');
    } else if (complexity == Complexity.tangled) {
      parts.add('A few threads are tangled together.');
    }

    if (agency == Agency.blocked) {
      parts.add('Your options feel constrained right now.');
    } else if (agency == Agency.constrained) {
      parts.add('It is harder to act than usual.');
    }

    if (parts.isEmpty) {
      if (isQuestion) {
        return 'You want a clear answer before acting.';
      }
      return 'You are trying to make progress with limited bandwidth.';
    }

    return parts.take(2).join(' ');
  }

  String _buildNextStep({
    required ResponseShape shape,
    required EscalationTier tier,
    required TimePressure timePressure,
    required Agency agency,
    ComplexityLevel? complexityLevel,
  }) {
    if (shape == ResponseShape.escalationSupport) {
      if (tier == EscalationTier.crisis) {
        return 'Call emergency services or a crisis line now. Reach out to a trusted person right away.';
      }
      if (tier == EscalationTier.strong) {
        return 'This is worth real-time support. Choose one: trusted person, professional help, or local resources.';
      }
      return 'Would it help to loop someone in? Choose one person or support option.';
    }

    final isSurvival = complexityLevel == ComplexityLevel.survival;
    final isOverloaded = complexityLevel == ComplexityLevel.overloaded;
    final isStable = complexityLevel == ComplexityLevel.stable;

    switch (shape) {
      case ResponseShape.clarifyingQuestion:
        if (agency == Agency.blocked) {
          if (isSurvival) return 'What is the one thing you need most right now?';
          return 'What is one small part you can control today?';
        }
        if (timePressure == TimePressure.high) {
          if (isSurvival || isOverloaded) return 'What needs to happen first to keep you stable?';
          return 'Do you want a quick next step or a fuller plan?';
        }
        if (isSurvival) return 'What do you need most in this moment?';
        if (isOverloaded) return 'What would feel like the smallest bit of relief right now?';
        return 'What feels most urgent: relief now, or a plan for later?';
      case ResponseShape.gentleReflection:
        if (isSurvival) return 'You don\'t have to fix everything. What do you need right now?';
        if (isOverloaded) return 'What would feel like even a tiny bit of relief right now?';
        return 'Name one thing that would make this 10% lighter today.';
      case ResponseShape.concreteNextStep:
        if (isSurvival) return 'What is the one thing you can do right now to feel safer or more stable?';
        if (isOverloaded) return 'Choose one small thing. Just one. Start there.';
        if (isStable) return 'Pick the next action and start it now.';
        return 'Pick the smallest useful action and do it within 10 minutes.';
      case ResponseShape.optionComparison:
        if (isSurvival) return 'Which option needs the least from you and keeps you safe?';
        if (isOverloaded) return 'Which option takes less from you right now? Start there.';
        return 'Compare two options on speed vs stability. Pick the one that fits your bandwidth.';
      case ResponseShape.patternRecall:
        if (isSurvival) return 'This keeps coming up. Is there someone who could help you with this?';
        if (isOverloaded) return 'This keeps coming up. What is the smallest thing that could ease it?';
        return 'Notice the pattern, then choose one small shift to try this week.';
      case ResponseShape.escalationSupport:
        return 'This is worth real-time support.';
    }
  }

  TimePressure _detectTimePressure(String lowerText) {
    if (_containsAny(lowerText, _highTimeWords)) {
      return TimePressure.high;
    }
    if (_containsAny(lowerText, _mediumTimeWords)) {
      return TimePressure.medium;
    }
    return TimePressure.low;
  }

  Agency _detectAgency(String lowerText) {
    if (_containsAny(lowerText, _blockedWords)) {
      return Agency.blocked;
    }
    if (_containsAny(lowerText, _constrainedWords)) {
      return Agency.constrained;
    }
    return Agency.canActNow;
  }

  Complexity _detectComplexity(InputTags tags, String lowerText) {
    if (tags.hasChance && tags.hasOutcome) {
      return Complexity.systemic;
    }
    if (tags.hasChance ||
        tags.hasOutcome ||
        _containsAny(lowerText, _tangledWords)) {
      return Complexity.tangled;
    }
    return Complexity.simple;
  }

  List<String> _detectSocialSignals(String lowerText) {
    final signals = <String>[];
    if (_containsAny(lowerText, _moneyWords)) {
      signals.add('money constraint');
    }
    if (_containsAny(lowerText, _housingWords)) {
      signals.add('housing pressure');
    }
    if (_containsAny(lowerText, _workWords)) {
      signals.add('work pressure');
    }
    if (_containsAny(lowerText, _careWords)) {
      signals.add('caregiving load');
    }
    if (_containsAny(lowerText, _accessWords)) {
      signals.add('access constraint');
    }
    return signals;
  }

  RiskFlag _detectRisk(String lowerText) {
    if (_containsAny(lowerText, _selfHarmPhrases)) {
      return RiskFlag.selfHarm;
    }
    if (_containsAny(lowerText, _harmOthersPhrases)) {
      return RiskFlag.harmToOthers;
    }
    if (_containsAny(lowerText, _imminentPhrases)) {
      return RiskFlag.imminentDanger;
    }
    return RiskFlag.none;
  }

  List<String> _buildSignals({
    required EmotionalLoad emotionalLoad,
    required TimePressure timePressure,
    required Complexity complexity,
    required Agency agency,
    required List<String> socialSignals,
    HomeMemoryContext? memoryContext,
  }) {
    final signals = <String>[];
    signals.add('emotional load: ${emotionalLoad.label}');
    if (timePressure != TimePressure.low) {
      signals.add('time pressure: ${timePressure.label}');
    }
    if (complexity != Complexity.simple) {
      signals.add('complexity: ${complexity.label}');
    }
    if (agency != Agency.canActNow) {
      signals.add('agency: ${agency.label}');
    }
    signals.addAll(socialSignals);
    if (memoryContext != null && memoryContext.used && memoryContext.themes.isNotEmpty) {
      signals.add('pattern recall: ${memoryContext.themes.join(', ')}');
    }
    return signals;
  }

  bool _containsAny(String text, List<String> phrases) {
    for (final phrase in phrases) {
      if (text.contains(phrase)) {
        return true;
      }
    }
    return false;
  }
}

enum EmotionalLoad { low, medium, high }

enum TimePressure { low, medium, high }

enum Complexity { simple, tangled, systemic }

enum Agency { canActNow, constrained, blocked }

enum RiskFlag { none, selfHarm, harmToOthers, imminentDanger }

extension _EmotionalLoadLabel on EmotionalLoad {
  String get label {
    switch (this) {
      case EmotionalLoad.low:
        return 'low';
      case EmotionalLoad.medium:
        return 'medium';
      case EmotionalLoad.high:
        return 'high';
    }
  }
}

extension _TimePressureLabel on TimePressure {
  String get label {
    switch (this) {
      case TimePressure.low:
        return 'low';
      case TimePressure.medium:
        return 'medium';
      case TimePressure.high:
        return 'high';
    }
  }
}

extension _ComplexityLabel on Complexity {
  String get label {
    switch (this) {
      case Complexity.simple:
        return 'simple';
      case Complexity.tangled:
        return 'tangled';
      case Complexity.systemic:
        return 'systemic';
    }
  }
}

extension _AgencyLabel on Agency {
  String get label {
    switch (this) {
      case Agency.canActNow:
        return 'can act now';
      case Agency.constrained:
        return 'constrained';
      case Agency.blocked:
        return 'blocked';
    }
  }
}

const List<String> _logOnlyPhrases = [
  'just logging',
  'log only',
  'note to self',
  'just a note',
  'logging this',
];
const List<String> _noSavePhrases = [
  'do not save',
  'don\'t save',
  'dont save',
  'not for journal',
  'private',
  'off the record',
];

const List<String> _questionPhrases = [
  'how do i',
  'what should',
  'should i',
  'can i',
  'what is the best',
];

const List<String> _uncertaintyPhrases = [
  'not sure',
  'unsure',
  'maybe',
  'confused',
  'uncertain',
];

const List<String> _highEmotionWords = [
  'overwhelmed',
  'panicked',
  'hopeless',
  'desperate',
  'shattered',
  'devastated',
  'burned out',
  'burnt out',
  'helpless',
];

const List<String> _mediumEmotionWords = [
  'anxious',
  'stressed',
  'sad',
  'down',
  'tired',
  'exhausted',
  'frustrated',
];

const List<String> _highTimeWords = [
  'urgent',
  'asap',
  'right now',
  'deadline',
  'today',
  'tonight',
];

const List<String> _mediumTimeWords = [
  'soon',
  'tomorrow',
  'this week',
  'next week',
];

const List<String> _blockedWords = [
  'cannot',
  'can\'t',
  'stuck',
  'no control',
  'blocked',
  'impossible',
];

const List<String> _constrainedWords = [
  'hard to',
  'struggling',
  'not sure',
  'unsure',
  'no time',
  'no energy',
];

const List<String> _tangledWords = [
  'complicated',
  'tangled',
  'mess',
  'too many',
  'multiple',
];

const List<String> _optionPhrases = [
  'either ',
  ' or ',
  'option',
  'choices',
  'compare',
];

const List<String> _moneyWords = [
  'money',
  'rent',
  'bills',
  'debt',
  'income',
];

const List<String> _housingWords = [
  'housing',
  'rent',
  'landlord',
  'apartment',
  'home',
];

const List<String> _workWords = [
  'work',
  'job',
  'boss',
  'shift',
  'deadline',
];

const List<String> _careWords = [
  'kids',
  'child',
  'caregiving',
  'family',
  'parent',
];

const List<String> _accessWords = [
  'access',
  'transport',
  'bus',
  'car',
  'clinic',
  'insurance',
];

const List<String> _selfHarmPhrases = [
  'kill myself',
  'suicide',
  'self-harm',
  'hurt myself',
  'end it',
];

const List<String> _harmOthersPhrases = [
  'hurt someone',
  'harm someone',
];

const List<String> _imminentPhrases = [
  'immediate danger',
];

const List<String> _isolationWords = [
  'alone',
  'no one',
  'nobody',
  'isolated',
];

const List<String> _cantCopeWords = [
  'cannot cope',
  'can\'t cope',
  'cant cope',
  'can\'t handle',
  'cannot handle',
  'can\'t do this',
  'cant do this',
];
