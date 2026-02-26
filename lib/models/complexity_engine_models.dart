import 'dart:convert';

enum ComplexityDomain {
  symptomsBodySignals,
  durationPattern,
  medicalContext,
  mentalEmotionalState,
  capacityEnergy,
  accessToCare,
  safetyRisk,
  environmentExposures,
  socialSupportContext,
  resourcesConstraints,
  knowledgeBeliefsPreferences,
  goalsIntent,
  unknownOther,
}

extension ComplexityDomainX on ComplexityDomain {
  String get code {
    switch (this) {
      case ComplexityDomain.symptomsBodySignals:
        return 'SYMPTOMS_BODY_SIGNALS';
      case ComplexityDomain.durationPattern:
        return 'DURATION_PATTERN';
      case ComplexityDomain.medicalContext:
        return 'MEDICAL_CONTEXT';
      case ComplexityDomain.mentalEmotionalState:
        return 'MENTAL_EMOTIONAL_STATE';
      case ComplexityDomain.capacityEnergy:
        return 'CAPACITY_ENERGY';
      case ComplexityDomain.accessToCare:
        return 'ACCESS_TO_CARE';
      case ComplexityDomain.safetyRisk:
        return 'SAFETY_RISK';
      case ComplexityDomain.environmentExposures:
        return 'ENVIRONMENT_EXPOSURES';
      case ComplexityDomain.socialSupportContext:
        return 'SOCIAL_SUPPORT_CONTEXT';
      case ComplexityDomain.resourcesConstraints:
        return 'RESOURCES_CONSTRAINTS';
      case ComplexityDomain.knowledgeBeliefsPreferences:
        return 'KNOWLEDGE_BELIEFS_PREFERENCES';
      case ComplexityDomain.goalsIntent:
        return 'GOALS_INTENT';
      case ComplexityDomain.unknownOther:
        return 'UNKNOWN_OTHER';
    }
  }

  static ComplexityDomain fromCode(String code) {
    switch (code) {
      case 'SYMPTOMS_BODY_SIGNALS':
        return ComplexityDomain.symptomsBodySignals;
      case 'DURATION_PATTERN':
        return ComplexityDomain.durationPattern;
      case 'MEDICAL_CONTEXT':
        return ComplexityDomain.medicalContext;
      case 'MENTAL_EMOTIONAL_STATE':
        return ComplexityDomain.mentalEmotionalState;
      case 'CAPACITY_ENERGY':
        return ComplexityDomain.capacityEnergy;
      case 'ACCESS_TO_CARE':
        return ComplexityDomain.accessToCare;
      case 'SAFETY_RISK':
        return ComplexityDomain.safetyRisk;
      case 'ENVIRONMENT_EXPOSURES':
        return ComplexityDomain.environmentExposures;
      case 'SOCIAL_SUPPORT_CONTEXT':
        return ComplexityDomain.socialSupportContext;
      case 'RESOURCES_CONSTRAINTS':
        return ComplexityDomain.resourcesConstraints;
      case 'KNOWLEDGE_BELIEFS_PREFERENCES':
        return ComplexityDomain.knowledgeBeliefsPreferences;
      case 'GOALS_INTENT':
        return ComplexityDomain.goalsIntent;
      default:
        return ComplexityDomain.unknownOther;
    }
  }
}

class DomainMeta {
  final String label;
  final String description;
  final List<String> examples;
  final List<String> typicalFactorTypes;
  final int priority;
  final String? overrideBehavior;

  const DomainMeta({
    required this.label,
    required this.description,
    required this.examples,
    required this.typicalFactorTypes,
    required this.priority,
    this.overrideBehavior,
  });
}

const Map<ComplexityDomain, DomainMeta> complexityDomainMeta = {
  ComplexityDomain.safetyRisk: DomainMeta(
    label: 'Safety risk',
    description:
        'Potential acute risk or urgent warning signs that should override other domains.',
    examples: [
      'severe chest pain',
      'trouble breathing',
      'fainting or blacking out',
      'suicidal thoughts',
      'heavy bleeding',
    ],
    typicalFactorTypes: ['chance'],
    priority: 1,
    overrideBehavior: 'OVERRIDES_ALL',
  ),
  ComplexityDomain.symptomsBodySignals: DomainMeta(
    label: 'Symptoms and body signals',
    description:
        'Physical sensations or changes the person notices in their body.',
    examples: [
      'sore throat and cough',
      'stomach cramps after meals',
      'headache and dizziness',
      'skin rash on my arms',
      'fever and chills',
    ],
    typicalFactorTypes: ['chance'],
    priority: 2,
  ),
  ComplexityDomain.medicalContext: DomainMeta(
    label: 'Medical context',
    description:
        'Clinical details like diagnoses, medications, tests, or health service interactions.',
    examples: [
      'GP diagnosed asthma',
      'started a new medication',
      'waiting for blood test results',
      'recent surgery recovery',
      'counselling session today',
    ],
    typicalFactorTypes: ['chance', 'constrained_choice'],
    priority: 3,
  ),
  ComplexityDomain.mentalEmotionalState: DomainMeta(
    label: 'Mental and emotional state',
    description: 'Feelings, mood, stress, or emotional wellbeing signals.',
    examples: [
      'feeling anxious',
      'low mood lately',
      'overwhelmed and stressed',
      'panic episodes',
      'grief is hitting hard',
    ],
    typicalFactorTypes: ['chance'],
    priority: 4,
  ),
  ComplexityDomain.durationPattern: DomainMeta(
    label: 'Duration and pattern',
    description: 'Timing, frequency, or persistence of symptoms or experiences.',
    examples: [
      'for three weeks now',
      'every afternoon',
      'on and off',
      'keeps coming back',
      'since last month',
    ],
    typicalFactorTypes: ['chance'],
    priority: 5,
  ),
  ComplexityDomain.capacityEnergy: DomainMeta(
    label: 'Capacity and energy',
    description: 'Energy, fatigue, bandwidth, or ability to carry out tasks.',
    examples: [
      'no energy to cook',
      'brain fog today',
      'exhausted after work',
      'struggling to focus',
      'can only manage basics',
    ],
    typicalFactorTypes: ['chance', 'constrained_choice'],
    priority: 6,
  ),
  ComplexityDomain.accessToCare: DomainMeta(
    label: 'Access to care',
    description:
        'Ability to reach healthcare, appointments, referrals, and care affordability.',
    examples: [
      'can\'t get a GP appointment',
      'waitlist for a specialist',
      'telehealth is the only option',
      'no bulk billing nearby',
      'referral needed',
    ],
    typicalFactorTypes: ['chance', 'constrained_choice'],
    priority: 7,
  ),
  ComplexityDomain.environmentExposures: DomainMeta(
    label: 'Environment exposures',
    description:
        'Physical environment factors like smoke, mould, heat, noise, or chemicals.',
    examples: [
      'mould in the flat',
      'smoke outside',
      'chemical fumes at work',
      'heatwave makes it worse',
      'dusty air',
    ],
    typicalFactorTypes: ['chance'],
    priority: 8,
  ),
  ComplexityDomain.socialSupportContext: DomainMeta(
    label: 'Social support context',
    description:
        'Support network, relationships, or social isolation affecting wellbeing.',
    examples: [
      'no one to help me',
      'partner is supportive',
      'living alone',
      'friends check in',
      'feel isolated',
    ],
    typicalFactorTypes: ['chance', 'constrained_choice'],
    priority: 9,
  ),
  ComplexityDomain.resourcesConstraints: DomainMeta(
    label: 'Resources and constraints',
    description:
        'Financial, housing, time, transport, or caregiving limits that constrain choices.',
    examples: [
      'can\'t afford groceries',
      'rent is overdue',
      'no transport to get around',
      'childcare is expensive',
      'shift work schedule',
    ],
    typicalFactorTypes: ['chance', 'constrained_choice'],
    priority: 10,
  ),
  ComplexityDomain.knowledgeBeliefsPreferences: DomainMeta(
    label: 'Knowledge, beliefs, and preferences',
    description: 'Understanding, beliefs, or preferences that guide decisions and behaviour.',
    examples: [
      'I prefer natural options',
      'not sure what this means',
      'need more information',
      'worried about side effects',
      'I believe this is normal',
    ],
    typicalFactorTypes: ['choice', 'chance', 'constrained_choice'],
    priority: 11,
  ),
  ComplexityDomain.goalsIntent: DomainMeta(
    label: 'Goals and intent',
    description: 'Goals, intentions, and what someone wants to achieve or change.',
    examples: [
      'I want to feel better',
      'trying to improve sleep',
      'goal is to reduce anxiety',
      'looking for ways to cope',
      'aiming to build a routine',
    ],
    typicalFactorTypes: ['choice'],
    priority: 12,
  ),
  ComplexityDomain.unknownOther: DomainMeta(
    label: 'Unknown / other',
    description: 'Not enough detail yet to assign a domain.',
    examples: ['not sure yet', 'hard to explain'],
    typicalFactorTypes: ['chance'],
    priority: 13,
  ),
};

enum FactorType { choice, chance, constrainedChoice }

enum FactorTimeHorizon { acute, chronic, lifeCourse, unknown }

enum FactorModifiability { high, medium, low, unknown }

enum FactorCode {
  symptomPain,
  symptomDizziness,
  symptomNausea,
  symptomBreathlessness,
  symptomHeadache,
  durationOnsetRecent,
  durationDaysWeeks,
  durationMonthsPlus,
  patternRecurring,
  durationToday,
  durationFewDays,
  durationWeekPlus,
  severityMild,
  severityModerate,
  severitySevere,
  trendBetter,
  trendWorse,
  trendSame,
  contextTriggerInjury,
  contextTriggerMedication,
  contextTriggerIllness,
  medicalChronicConditionMentioned,
  medicalMedsMentioned,
  medicalTestsMentioned,
  medicalCareVisit,
  emotionAnxietyStress,
  emotionLowMood,
  emotionPanic,
  capacityFatigue,
  capacityPoorSleep,
  capacityLowFocus,
  accessCostBarrier,
  accessAppointmentBarrier,
  resourceFinancialStrain,
  resourceTimePressure,
  resourceCaregivingLoad,
  safetyRedFlag,
  safetySelfHarm,
  envAirQualityExposure,
  socialSupportLimited,
  knowledgeNeedsInformation,
  goalSymptomRelief,
  goalBehaviourChange,
  symptomGeneral,
  behaviourRested,
  behaviourPushedThrough,
  behaviourChangedPlans,
  behaviourNoActionYet,
  reliefRest,
  reliefDistraction,
  reliefMovement,
  reliefRoutine,
  reliefConnection,
  reliefQuiet,
  reliefNone,
  strengthShowedUp,
  strengthTookBreak,
  strengthAskedForHelp,
  strengthResilience,
}

extension FactorCodeX on FactorCode {
  String get code {
    switch (this) {
      case FactorCode.symptomPain:
        return 'SYMPTOM_PAIN';
      case FactorCode.symptomDizziness:
        return 'SYMPTOM_DIZZINESS';
      case FactorCode.symptomNausea:
        return 'SYMPTOM_NAUSEA';
      case FactorCode.symptomBreathlessness:
        return 'SYMPTOM_BREATHLESSNESS';
      case FactorCode.symptomHeadache:
        return 'SYMPTOM_HEADACHE';
      case FactorCode.durationOnsetRecent:
        return 'DURATION_ONSET_RECENT';
      case FactorCode.durationDaysWeeks:
        return 'DURATION_DAYS_WEEKS';
      case FactorCode.durationMonthsPlus:
        return 'DURATION_MONTHS_PLUS';
      case FactorCode.patternRecurring:
        return 'PATTERN_RECURRING';
      case FactorCode.durationToday:
        return 'DURATION_TODAY';
      case FactorCode.durationFewDays:
        return 'DURATION_FEW_DAYS';
      case FactorCode.durationWeekPlus:
        return 'DURATION_WEEK_PLUS';
      case FactorCode.severityMild:
        return 'SEVERITY_MILD';
      case FactorCode.severityModerate:
        return 'SEVERITY_MODERATE';
      case FactorCode.severitySevere:
        return 'SEVERITY_SEVERE';
      case FactorCode.trendBetter:
        return 'TREND_BETTER';
      case FactorCode.trendWorse:
        return 'TREND_WORSE';
      case FactorCode.trendSame:
        return 'TREND_SAME';
      case FactorCode.contextTriggerInjury:
        return 'CONTEXT_TRIGGER_INJURY';
      case FactorCode.contextTriggerMedication:
        return 'CONTEXT_TRIGGER_MEDICATION';
      case FactorCode.contextTriggerIllness:
        return 'CONTEXT_TRIGGER_ILLNESS';
      case FactorCode.medicalChronicConditionMentioned:
        return 'MEDICAL_CHRONIC_CONDITION_MENTIONED';
      case FactorCode.medicalMedsMentioned:
        return 'MEDICAL_MEDS_MENTIONED';
      case FactorCode.medicalTestsMentioned:
        return 'MEDICAL_TESTS_MENTIONED';
      case FactorCode.medicalCareVisit:
        return 'MEDICAL_CARE_VISIT';
      case FactorCode.emotionAnxietyStress:
        return 'EMOTION_ANXIETY_STRESS';
      case FactorCode.emotionLowMood:
        return 'EMOTION_LOW_MOOD';
      case FactorCode.emotionPanic:
        return 'EMOTION_PANIC';
      case FactorCode.capacityFatigue:
        return 'CAPACITY_FATIGUE';
      case FactorCode.capacityPoorSleep:
        return 'CAPACITY_POOR_SLEEP';
      case FactorCode.capacityLowFocus:
        return 'CAPACITY_LOW_FOCUS';
      case FactorCode.accessCostBarrier:
        return 'ACCESS_COST_BARRIER';
      case FactorCode.accessAppointmentBarrier:
        return 'ACCESS_APPOINTMENT_BARRIER';
      case FactorCode.resourceFinancialStrain:
        return 'RESOURCE_FINANCIAL_STRAIN';
      case FactorCode.resourceTimePressure:
        return 'RESOURCE_TIME_PRESSURE';
      case FactorCode.resourceCaregivingLoad:
        return 'RESOURCE_CAREGIVING_LOAD';
      case FactorCode.safetyRedFlag:
        return 'SAFETY_RED_FLAG';
      case FactorCode.safetySelfHarm:
        return 'SAFETY_SELF_HARM';
      case FactorCode.envAirQualityExposure:
        return 'ENV_AIR_QUALITY_EXPOSURE';
      case FactorCode.socialSupportLimited:
        return 'SOCIAL_SUPPORT_LIMITED';
      case FactorCode.knowledgeNeedsInformation:
        return 'KNOWLEDGE_NEEDS_INFORMATION';
      case FactorCode.goalSymptomRelief:
        return 'GOAL_SYMPTOM_RELIEF';
      case FactorCode.goalBehaviourChange:
        return 'GOAL_BEHAVIOUR_CHANGE';
      case FactorCode.symptomGeneral:
        return 'SYMPTOM_GENERAL';
      case FactorCode.behaviourRested:
        return 'BEHAVIOUR_RESTED';
      case FactorCode.behaviourPushedThrough:
        return 'BEHAVIOUR_PUSHED_THROUGH';
      case FactorCode.behaviourChangedPlans:
        return 'BEHAVIOUR_CHANGED_PLANS';
      case FactorCode.behaviourNoActionYet:
        return 'BEHAVIOUR_NO_ACTION_YET';
      case FactorCode.reliefRest:
        return 'RELIEF_REST';
      case FactorCode.reliefDistraction:
        return 'RELIEF_DISTRACTION';
      case FactorCode.reliefMovement:
        return 'RELIEF_MOVEMENT';
      case FactorCode.reliefRoutine:
        return 'RELIEF_ROUTINE';
      case FactorCode.reliefConnection:
        return 'RELIEF_CONNECTION';
      case FactorCode.reliefQuiet:
        return 'RELIEF_QUIET';
      case FactorCode.reliefNone:
        return 'RELIEF_NONE';
      case FactorCode.strengthShowedUp:
        return 'STRENGTH_SHOWED_UP';
      case FactorCode.strengthTookBreak:
        return 'STRENGTH_TOOK_BREAK';
      case FactorCode.strengthAskedForHelp:
        return 'STRENGTH_ASKED_FOR_HELP';
      case FactorCode.strengthResilience:
        return 'STRENGTH_RESILIENCE';
    }
  }

  static FactorCode? fromCode(String code) {
    for (final value in FactorCode.values) {
      if (value.code == code) {
        return value;
      }
    }
    return null;
  }
}

class Factor {
  final String id;
  final ComplexityDomain domain;
  final FactorType type;
  final FactorCode code;
  final dynamic value;
  final double confidence;
  final FactorTimeHorizon timeHorizon;
  final FactorModifiability modifiability;
  final String sourceEventId;
  final String createdAt;

  const Factor({
    required this.id,
    required this.domain,
    required this.type,
    required this.code,
    required this.value,
    required this.confidence,
    required this.timeHorizon,
    required this.modifiability,
    required this.sourceEventId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'domain': domain.code,
        'type': type.name,
        'code': code.code,
        'value': value,
        'confidence': confidence,
        'time_horizon': timeHorizon.name,
        'modifiability': modifiability.name,
        'source_event_id': sourceEventId,
        'created_at': createdAt,
      };

  static Factor fromJson(Map<String, dynamic> json) {
    return Factor(
      id: json['id'] as String,
      domain: ComplexityDomainX.fromCode(json['domain'] as String),
      type: FactorType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => FactorType.chance,
      ),
      code: FactorCodeX.fromCode(json['code'] as String) ??
          FactorCode.knowledgeNeedsInformation,
      value: json['value'],
      confidence: (json['confidence'] as num).toDouble(),
      timeHorizon: FactorTimeHorizon.values.firstWhere(
        (value) => value.name == json['time_horizon'],
        orElse: () => FactorTimeHorizon.unknown,
      ),
      modifiability: FactorModifiability.values.firstWhere(
        (value) => value.name == json['modifiability'],
        orElse: () => FactorModifiability.unknown,
      ),
      sourceEventId: json['source_event_id'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class MissingInfo {
  final String key;
  final String question;
  final ComplexityDomain domain;
  final String priority;

  const MissingInfo({
    required this.key,
    required this.question,
    required this.domain,
    required this.priority,
  });
}

class FactorWrite {
  final FactorCode code;
  final dynamic value;
  final double confidence;
  final FactorTimeHorizon timeHorizon;

  const FactorWrite({
    required this.code,
    this.value = true,
    this.confidence = 0.9,
    this.timeHorizon = FactorTimeHorizon.unknown,
  });
}

class FollowUpChoice {
  final String label;
  final List<FactorWrite> writesFactors;

  const FollowUpChoice({
    required this.label,
    this.writesFactors = const [],
  });
}

class FollowUpPlan {
  final String questionText;
  final List<FollowUpChoice> choices;

  const FollowUpPlan({
    required this.questionText,
    required this.choices,
  });
}

enum EventIntent { ask, journal, followUp, mixed, logOnly }

extension EventIntentX on EventIntent {
  String get code {
    switch (this) {
      case EventIntent.ask:
        return 'ASK';
      case EventIntent.journal:
        return 'JOURNAL';
      case EventIntent.followUp:
        return 'FOLLOW_UP';
      case EventIntent.mixed:
        return 'MIXED';
      case EventIntent.logOnly:
        return 'LOG_ONLY';
    }
  }

  static EventIntent fromCode(String code) {
    switch (code) {
      case 'ASK':
        return EventIntent.ask;
      case 'JOURNAL':
        return EventIntent.journal;
      case 'FOLLOW_UP':
        return EventIntent.followUp;
      case 'MIXED':
        return EventIntent.mixed;
      case 'LOG_ONLY':
        return EventIntent.logOnly;
      default:
        return EventIntent.ask;
    }
  }
}

enum EventSaveMode { transient, saveJournal, saveFactorsOnly }

extension EventSaveModeX on EventSaveMode {
  String get code {
    switch (this) {
      case EventSaveMode.transient:
        return 'transient';
      case EventSaveMode.saveJournal:
        return 'save_journal';
      case EventSaveMode.saveFactorsOnly:
        return 'save_factors_only';
    }
  }

  static EventSaveMode fromCode(String code) {
    switch (code) {
      case 'save_journal':
        return EventSaveMode.saveJournal;
      case 'save_factors_only':
        return EventSaveMode.saveFactorsOnly;
      case 'transient':
      default:
        return EventSaveMode.transient;
    }
  }
}

class Event {
  final String id;
  final String createdAt;
  final String? parentEventId;
  final EventIntent intent;
  final EventSaveMode saveMode;
  final String? rawText;

  const Event({
    required this.id,
    required this.createdAt,
    this.parentEventId,
    required this.intent,
    required this.saveMode,
    this.rawText,
  });
}

class DomainTag {
  final ComplexityDomain domain;
  final double confidence;

  const DomainTag({
    required this.domain,
    required this.confidence,
  });
}

class DomainClassificationResult {
  final DomainTag primary;
  final List<DomainTag> secondary;
  final String? rationale;

  const DomainClassificationResult({
    required this.primary,
    required this.secondary,
    this.rationale,
  });
}

enum RiskBand { low, medium, high, urgent }

enum FrictionBand { low, medium, high }

enum UncertaintyBand { low, medium, high }

enum NextActionKind { answer, askFollowup, logOnly, safetyEscalation }

class UsedFactor {
  final FactorCode code;
  final ComplexityDomain domain;
  final double confidence;

  const UsedFactor({
    required this.code,
    required this.domain,
    required this.confidence,
  });
}

class StateSnapshot {
  final String eventId;
  final String createdAt;
  final EventIntent intent;
  final RiskBand riskBand;
  final FrictionBand frictionBand;
  final UncertaintyBand uncertaintyBand;
  final NextActionKind nextActionKind;
  final List<String> whatMatters;
  final String? followupQuestion;
  final String? safetyCopy;
  final List<UsedFactor> usedFactors;
  final String? symptomKey;
  final int followUpCount;

  const StateSnapshot({
    required this.eventId,
    required this.createdAt,
    required this.intent,
    required this.riskBand,
    required this.frictionBand,
    required this.uncertaintyBand,
    required this.nextActionKind,
    required this.whatMatters,
    required this.usedFactors,
    this.symptomKey,
    this.followUpCount = 0,
    this.followupQuestion,
    this.safetyCopy,
  });

  StateSnapshot copyWith({
    NextActionKind? nextActionKind,
    String? followupQuestion,
    String? symptomKey,
    int? followUpCount,
  }) {
    return StateSnapshot(
      eventId: eventId,
      createdAt: createdAt,
      intent: intent,
      riskBand: riskBand,
      frictionBand: frictionBand,
      uncertaintyBand: uncertaintyBand,
      nextActionKind: nextActionKind ?? this.nextActionKind,
      whatMatters: whatMatters,
      usedFactors: usedFactors,
      symptomKey: symptomKey ?? this.symptomKey,
      followUpCount: followUpCount ?? this.followUpCount,
      followupQuestion: followupQuestion ?? this.followupQuestion,
      safetyCopy: safetyCopy,
    );
  }
}

enum ResponseMode { logOnly, askFollowup, answer, safetyEscalation }

enum NextStepCategory {
  selfCare,
  pharmacist,
  gpTelehealth,
  urgentCareEd,
  crisisSupport,
}

extension NextStepCategoryX on NextStepCategory {
  String get code {
    switch (this) {
      case NextStepCategory.selfCare:
        return 'self_care';
      case NextStepCategory.pharmacist:
        return 'pharmacist';
      case NextStepCategory.gpTelehealth:
        return 'gp_telehealth';
      case NextStepCategory.urgentCareEd:
        return 'urgent_care_ed';
      case NextStepCategory.crisisSupport:
        return 'crisis_support';
    }
  }
}

class NextStep {
  final NextStepCategory category;
  final String heading;
  final String text;
  final List<String> options;

  const NextStep({
    required this.category,
    required this.heading,
    required this.text,
    required this.options,
  });
}

class UsedFactorChip {
  final String group;
  final String label;
  final FactorCode code;
  final double confidence;

  const UsedFactorChip({
    required this.group,
    required this.label,
    required this.code,
    required this.confidence,
  });
}

class WhatImUsingControls {
  final bool useSavedContext;
  final bool sessionUseProfile;

  const WhatImUsingControls({
    required this.useSavedContext,
    required this.sessionUseProfile,
  });
}

class WhatImUsingModel {
  final String title;
  final String description;
  final List<UsedFactorChip> chips;
  final WhatImUsingControls controls;

  const WhatImUsingModel({
    required this.title,
    required this.description,
    required this.chips,
    required this.controls,
  });
}

class VaultActionSuggestion {
  final String title;
  final List<String> steps;
  final String? defaultSchedule;
  final String? energyRequired;
  final String? timeRequired;
  final List<String> contextTags;
  final List<String> priorityFactors;
  final Map<String, dynamic> vaultPayload;

  const VaultActionSuggestion({
    required this.title,
    required this.steps,
    required this.vaultPayload,
    this.defaultSchedule,
    this.energyRequired,
    this.timeRequired,
    this.contextTags = const [],
    this.priorityFactors = const [],
  });
}

class ComplexityResponseModel {
  final ResponseMode mode;
  final String confirmation;
  final String? answer;
  final String? symptomKey;
  final List<String> keyFactors;
  final NextStepCategory? routerCategory;
  final FollowUpPlan? followUpPlan;
  final List<VaultActionSuggestion> whatToDoNow;
  final List<String> whatIfWorse;
  final String? safetyNet;
  final WhatImUsingModel whatImUsing;

  const ComplexityResponseModel({
    required this.mode,
    required this.confirmation,
    required this.whatImUsing,
    this.answer,
    this.symptomKey,
    this.keyFactors = const [],
    this.routerCategory,
    this.followUpPlan,
    this.whatToDoNow = const [],
    this.whatIfWorse = const [],
    this.safetyNet,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'confirmation': confirmation,
        'answer': answer,
        'symptom_key': symptomKey,
        'key_factors': keyFactors,
        'router_category': routerCategory?.code,
        'followup_plan': followUpPlan == null
            ? null
            : {
                'question_text': followUpPlan!.questionText,
                'choices': followUpPlan!.choices
                    .map(
                      (choice) => {
                        'label': choice.label,
                        'writes_factors': choice.writesFactors
                            .map(
                              (write) => {
                                'code': write.code.code,
                                'value': write.value,
                                'confidence': write.confidence,
                                'time_horizon': write.timeHorizon.name,
                              },
                            )
                            .toList(),
                      },
                    )
                    .toList(),
              },
        'what_to_do_now': whatToDoNow
            .map(
              (item) => {
                'title': item.title,
                'steps': item.steps,
                'default_schedule': item.defaultSchedule,
                'energy_required': item.energyRequired,
                'time_required': item.timeRequired,
                'context_tags': item.contextTags,
                'priority_factors': item.priorityFactors,
                'vault_payload': item.vaultPayload,
              },
            )
            .toList(),
        'what_if_worse': whatIfWorse,
        'safety_net': safetyNet,
        'what_im_using': {
          'title': whatImUsing.title,
          'description': whatImUsing.description,
          'controls': {
            'use_saved_context': whatImUsing.controls.useSavedContext,
            'session_use_profile': whatImUsing.controls.sessionUseProfile,
          },
          'chips': whatImUsing.chips
              .map(
                (chip) => {
                  'group': chip.group,
                  'label': chip.label,
                  'code': chip.code.code,
                  'confidence': chip.confidence,
                },
              )
              .toList(),
        },
      };

  @override
  String toString() => jsonEncode(toJson());

  ComplexityResponseModel copyWith({
    ResponseMode? mode,
    String? confirmation,
    String? answer,
    String? symptomKey,
    List<String>? keyFactors,
    NextStepCategory? routerCategory,
    FollowUpPlan? followUpPlan,
    List<VaultActionSuggestion>? whatToDoNow,
    List<String>? whatIfWorse,
    String? safetyNet,
    WhatImUsingModel? whatImUsing,
  }) {
    return ComplexityResponseModel(
      mode: mode ?? this.mode,
      confirmation: confirmation ?? this.confirmation,
      answer: answer ?? this.answer,
      symptomKey: symptomKey ?? this.symptomKey,
      keyFactors: keyFactors ?? this.keyFactors,
      routerCategory: routerCategory ?? this.routerCategory,
      followUpPlan: followUpPlan ?? this.followUpPlan,
      whatToDoNow: whatToDoNow ?? this.whatToDoNow,
      whatIfWorse: whatIfWorse ?? this.whatIfWorse,
      safetyNet: safetyNet ?? this.safetyNet,
      whatImUsing: whatImUsing ?? this.whatImUsing,
    );
  }
}

class PendingFollowUp {
  final String id;
  final String parentEventId;
  final String questionText;
  final String? missingInfoKey;
  final String createdAt;
  final int followUpCount;
  final String? symptomKey;

  const PendingFollowUp({
    required this.id,
    required this.parentEventId,
    required this.questionText,
    required this.createdAt,
    required this.followUpCount,
    this.missingInfoKey,
    this.symptomKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'parent_event_id': parentEventId,
        'question_text': questionText,
        'missing_info_key': missingInfoKey,
        'created_at': createdAt,
        'follow_up_count': followUpCount,
        'symptom_key': symptomKey,
      };

  static PendingFollowUp? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return PendingFollowUp(
      id: json['id'] as String,
      parentEventId: json['parent_event_id'] as String,
      questionText: json['question_text'] as String,
      missingInfoKey: json['missing_info_key'] as String?,
      createdAt: json['created_at'] as String,
      followUpCount: (json['follow_up_count'] as num?)?.toInt() ?? 0,
      symptomKey: json['symptom_key'] as String?,
    );
  }
}

class ExtractedPayload {
  final List<Factor> factors;
  final List<MissingInfo>? missingInfo;

  const ExtractedPayload({
    required this.factors,
    this.missingInfo,
  });
}

class DomainCoverage {
  final int acute;
  final int chronic;

  const DomainCoverage({
    required this.acute,
    required this.chronic,
  });

  DomainCoverage copyWith({int? acute, int? chronic}) => DomainCoverage(
        acute: acute ?? this.acute,
        chronic: chronic ?? this.chronic,
      );
}

class ComplexityProfile {
  final String updatedAt;
  final Map<FactorCode, Factor> factorsByCode;
  final List<Factor> topConstraints;
  final Map<ComplexityDomain, DomainCoverage> domainsCoverage;

  const ComplexityProfile({
    required this.updatedAt,
    required this.factorsByCode,
    required this.topConstraints,
    required this.domainsCoverage,
  });
}

class ProcessSmartInputResult {
  final Event event;
  final DomainClassificationResult domainResult;
  final ExtractedPayload extracted;
  final ComplexityProfile profile;
  final StateSnapshot snapshot;
  final ComplexityResponseModel responseModel;

  const ProcessSmartInputResult({
    required this.event,
    required this.domainResult,
    required this.extracted,
    required this.profile,
    required this.snapshot,
    required this.responseModel,
  });
}
