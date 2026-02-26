import 'dart:math';

import '../models/complexity_engine_models.dart';

class RouteNextStepResult {
  final NextStepCategory category;
  final String rationale;
  final String? safetyNet;

  const RouteNextStepResult({
    required this.category,
    required this.rationale,
    this.safetyNet,
  });
}

const List<ComplexityDomain> _domainPriority = [
  ComplexityDomain.symptomsBodySignals,
  ComplexityDomain.resourcesConstraints,
  ComplexityDomain.accessToCare,
  ComplexityDomain.capacityEnergy,
  ComplexityDomain.mentalEmotionalState,
  ComplexityDomain.durationPattern,
  ComplexityDomain.medicalContext,
  ComplexityDomain.environmentExposures,
  ComplexityDomain.socialSupportContext,
  ComplexityDomain.knowledgeBeliefsPreferences,
  ComplexityDomain.goalsIntent,
  ComplexityDomain.unknownOther,
];

const Set<FactorCode> _safetyCodes = {
  FactorCode.safetyRedFlag,
  FactorCode.safetySelfHarm,
};

const Set<FactorCode> _highRiskCodes = {
  FactorCode.symptomBreathlessness,
  FactorCode.symptomDizziness,
};

const Set<FactorCode> _mediumRiskCodes = {
  FactorCode.symptomPain,
  FactorCode.symptomHeadache,
  FactorCode.symptomNausea,
  FactorCode.emotionPanic,
  FactorCode.emotionAnxietyStress,
};

const Set<FactorCode> _highFrictionCodes = {
  FactorCode.accessCostBarrier,
  FactorCode.accessAppointmentBarrier,
  FactorCode.resourceTimePressure,
  FactorCode.resourceCaregivingLoad,
  FactorCode.capacityFatigue,
  FactorCode.capacityPoorSleep,
};

const Set<FactorCode> _mediumFrictionCodes = {
  FactorCode.resourceFinancialStrain,
  FactorCode.capacityLowFocus,
  FactorCode.socialSupportLimited,
};

const Map<FactorCode, String> _bulletCopy = {
  FactorCode.symptomPain: 'Pain is showing up.',
  FactorCode.symptomDizziness: 'Dizziness is present.',
  FactorCode.symptomNausea: 'Feeling nauseous is part of this.',
  FactorCode.symptomBreathlessness: 'Breathlessness is affecting you.',
  FactorCode.symptomHeadache: 'Headache is bothering you.',
  FactorCode.durationOnsetRecent: 'This started recently.',
  FactorCode.durationDaysWeeks: 'This has been going on for days or weeks.',
  FactorCode.durationMonthsPlus: 'This has been going on for months or longer.',
  FactorCode.patternRecurring: 'It keeps coming back.',
  FactorCode.durationToday: 'This started today.',
  FactorCode.durationFewDays: 'This has been going on for a few days.',
  FactorCode.durationWeekPlus: 'This has been going on for a week or more.',
  FactorCode.severityMild: 'It feels mild and manageable.',
  FactorCode.severityModerate: 'It is getting in the way.',
  FactorCode.severitySevere: 'It feels severe and hard to manage.',
  FactorCode.trendBetter: 'It is starting to ease.',
  FactorCode.trendWorse: 'It is getting worse.',
  FactorCode.trendSame: 'It feels about the same.',
  FactorCode.contextTriggerInjury: 'An injury or irritation might be involved.',
  FactorCode.contextTriggerMedication: 'A new medication might be involved.',
  FactorCode.contextTriggerIllness: 'An illness might be involved.',
  FactorCode.medicalChronicConditionMentioned:
      'A long-term condition is part of the picture.',
  FactorCode.medicalMedsMentioned: 'Medication is involved.',
  FactorCode.medicalTestsMentioned: 'Tests or scans are in play.',
  FactorCode.medicalCareVisit: 'You have been in touch with care recently.',
  FactorCode.emotionAnxietyStress: 'Anxiety or stress is present.',
  FactorCode.emotionLowMood: 'Low mood is weighing on you.',
  FactorCode.emotionPanic: 'Panic symptoms are showing up.',
  FactorCode.capacityFatigue: 'Energy is low right now.',
  FactorCode.capacityPoorSleep: 'Sleep has been disrupted.',
  FactorCode.capacityLowFocus: 'Focus is hard at the moment.',
  FactorCode.accessCostBarrier: 'Cost is getting in the way of care.',
  FactorCode.accessAppointmentBarrier: 'Appointments are hard to access.',
  FactorCode.resourceFinancialStrain: 'Money pressure is affecting options.',
  FactorCode.resourceTimePressure: 'Time pressure is limiting what you can do.',
  FactorCode.resourceCaregivingLoad: 'Caring responsibilities are heavy.',
  FactorCode.safetyRedFlag: 'A safety concern was mentioned.',
  FactorCode.safetySelfHarm: 'Safety is a priority based on what you shared.',
  FactorCode.envAirQualityExposure: 'Environment or air quality is a concern.',
  FactorCode.socialSupportLimited: 'Support feels limited.',
  FactorCode.knowledgeNeedsInformation: 'More information would help.',
  FactorCode.goalSymptomRelief: 'You want relief from symptoms.',
  FactorCode.goalBehaviourChange: 'You want to make a behaviour change.',
  FactorCode.symptomGeneral: 'Symptoms are making things harder.',
  FactorCode.behaviourRested: 'Rest was part of today.',
  FactorCode.behaviourPushedThrough: 'You pushed through.',
  FactorCode.behaviourChangedPlans: 'You adjusted plans.',
  FactorCode.behaviourNoActionYet: 'No actions yet today.',
  FactorCode.reliefRest: 'Rest helped a little.',
  FactorCode.reliefDistraction: 'Distraction helped a little.',
  FactorCode.reliefMovement: 'Movement helped a little.',
  FactorCode.reliefRoutine: 'Routine helped a little.',
  FactorCode.reliefConnection: 'Connection helped a little.',
  FactorCode.reliefQuiet: 'Quiet helped a little.',
  FactorCode.reliefNone: 'Relief was hard to find today.',
  FactorCode.strengthShowedUp: 'You showed up for yourself.',
  FactorCode.strengthTookBreak: 'You took a break when needed.',
  FactorCode.strengthAskedForHelp: 'You reached for help.',
  FactorCode.strengthResilience: 'You showed resilience.',
};

const Map<FactorCode, _FactorDefinition> _factorDefinitions = {
  FactorCode.symptomPain: _FactorDefinition(
    domain: ComplexityDomain.symptomsBodySignals,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.symptomDizziness: _FactorDefinition(
    domain: ComplexityDomain.symptomsBodySignals,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.symptomNausea: _FactorDefinition(
    domain: ComplexityDomain.symptomsBodySignals,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.symptomBreathlessness: _FactorDefinition(
    domain: ComplexityDomain.symptomsBodySignals,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.symptomHeadache: _FactorDefinition(
    domain: ComplexityDomain.symptomsBodySignals,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.durationOnsetRecent: _FactorDefinition(
    domain: ComplexityDomain.durationPattern,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.durationDaysWeeks: _FactorDefinition(
    domain: ComplexityDomain.durationPattern,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.durationMonthsPlus: _FactorDefinition(
    domain: ComplexityDomain.durationPattern,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.chronic,
  ),
  FactorCode.patternRecurring: _FactorDefinition(
    domain: ComplexityDomain.durationPattern,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.chronic,
  ),
  FactorCode.durationToday: _FactorDefinition(
    domain: ComplexityDomain.durationPattern,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.durationFewDays: _FactorDefinition(
    domain: ComplexityDomain.durationPattern,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.durationWeekPlus: _FactorDefinition(
    domain: ComplexityDomain.durationPattern,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.chronic,
  ),
  FactorCode.severityMild: _FactorDefinition(
    domain: ComplexityDomain.symptomsBodySignals,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.severityModerate: _FactorDefinition(
    domain: ComplexityDomain.symptomsBodySignals,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.severitySevere: _FactorDefinition(
    domain: ComplexityDomain.symptomsBodySignals,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.trendBetter: _FactorDefinition(
    domain: ComplexityDomain.durationPattern,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.trendWorse: _FactorDefinition(
    domain: ComplexityDomain.durationPattern,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.trendSame: _FactorDefinition(
    domain: ComplexityDomain.durationPattern,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.contextTriggerInjury: _FactorDefinition(
    domain: ComplexityDomain.medicalContext,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.contextTriggerMedication: _FactorDefinition(
    domain: ComplexityDomain.medicalContext,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.contextTriggerIllness: _FactorDefinition(
    domain: ComplexityDomain.medicalContext,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.medicalChronicConditionMentioned: _FactorDefinition(
    domain: ComplexityDomain.medicalContext,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.chronic,
  ),
  FactorCode.medicalMedsMentioned: _FactorDefinition(
    domain: ComplexityDomain.medicalContext,
    type: FactorType.constrainedChoice,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.medicalTestsMentioned: _FactorDefinition(
    domain: ComplexityDomain.medicalContext,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.medicalCareVisit: _FactorDefinition(
    domain: ComplexityDomain.medicalContext,
    type: FactorType.constrainedChoice,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.emotionAnxietyStress: _FactorDefinition(
    domain: ComplexityDomain.mentalEmotionalState,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.emotionLowMood: _FactorDefinition(
    domain: ComplexityDomain.mentalEmotionalState,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.emotionPanic: _FactorDefinition(
    domain: ComplexityDomain.mentalEmotionalState,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.capacityFatigue: _FactorDefinition(
    domain: ComplexityDomain.capacityEnergy,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.capacityPoorSleep: _FactorDefinition(
    domain: ComplexityDomain.capacityEnergy,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.capacityLowFocus: _FactorDefinition(
    domain: ComplexityDomain.capacityEnergy,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.accessCostBarrier: _FactorDefinition(
    domain: ComplexityDomain.accessToCare,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.accessAppointmentBarrier: _FactorDefinition(
    domain: ComplexityDomain.accessToCare,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.resourceFinancialStrain: _FactorDefinition(
    domain: ComplexityDomain.resourcesConstraints,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.chronic,
  ),
  FactorCode.resourceTimePressure: _FactorDefinition(
    domain: ComplexityDomain.resourcesConstraints,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.resourceCaregivingLoad: _FactorDefinition(
    domain: ComplexityDomain.resourcesConstraints,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.lifeCourse,
  ),
  FactorCode.safetyRedFlag: _FactorDefinition(
    domain: ComplexityDomain.safetyRisk,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.safetySelfHarm: _FactorDefinition(
    domain: ComplexityDomain.safetyRisk,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.envAirQualityExposure: _FactorDefinition(
    domain: ComplexityDomain.environmentExposures,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.socialSupportLimited: _FactorDefinition(
    domain: ComplexityDomain.socialSupportContext,
    type: FactorType.chance,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.chronic,
  ),
  FactorCode.knowledgeNeedsInformation: _FactorDefinition(
    domain: ComplexityDomain.knowledgeBeliefsPreferences,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.goalSymptomRelief: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.goalBehaviourChange: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.unknown,
  ),
  FactorCode.symptomGeneral: _FactorDefinition(
    domain: ComplexityDomain.symptomsBodySignals,
    type: FactorType.chance,
    modifiability: FactorModifiability.low,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.behaviourRested: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.behaviourPushedThrough: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.behaviourChangedPlans: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.behaviourNoActionYet: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.reliefRest: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.reliefDistraction: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.reliefMovement: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.reliefRoutine: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.reliefConnection: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.reliefQuiet: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.reliefNone: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.medium,
    defaultTimeHorizon: FactorTimeHorizon.acute,
  ),
  FactorCode.strengthShowedUp: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.lifeCourse,
  ),
  FactorCode.strengthTookBreak: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.lifeCourse,
  ),
  FactorCode.strengthAskedForHelp: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.lifeCourse,
  ),
  FactorCode.strengthResilience: _FactorDefinition(
    domain: ComplexityDomain.goalsIntent,
    type: FactorType.choice,
    modifiability: FactorModifiability.high,
    defaultTimeHorizon: FactorTimeHorizon.lifeCourse,
  ),
};

const double _minFactorConfidence = 0.6;

const List<String> _safetyRiskPhrases = [
  'chest pain',
  'trouble breathing',
  'cant breathe',
  'shortness of breath',
  'severe bleeding',
  'bleeding heavily',
  'passed out',
  'black out',
  'face droop',
  'slurred speech',
  'weakness on one side',
  'sudden severe headache',
  'suicidal thoughts',
  'self harm',
  'severe allergic reaction',
  'anaphylaxis',
];

const List<String> _safetyRiskKeywords = [
  'suicidal',
  'suicide',
  'overdose',
  'unconscious',
  'fainting',
  'seizure',
  'stroke',
];

const Map<ComplexityDomain, List<String>> _domainKeywords = {
  ComplexityDomain.symptomsBodySignals: [
    'pain',
    'ache',
    'sore',
    'soreness',
    'swelling',
    'swollen',
    'tender',
    'hurt',
    'hurts',
    'fever',
    'cough',
    'nausea',
    'vomit',
    'vomiting',
    'dizzy',
    'dizziness',
    'headache',
    'migraine',
    'rash',
    'swelling',
    'cramps',
    'diarrhoea',
    'constipation',
    'chills',
    'palpitations',
    'breathless',
  ],
  ComplexityDomain.durationPattern: [
    'daily',
    'weekly',
    'monthly',
    'recurring',
    'chronic',
    'persistent',
    'regularly',
    'often',
    'frequently',
    'lately',
  ],
  ComplexityDomain.medicalContext: [
    'diagnosed',
    'diagnosis',
    'medication',
    'meds',
    'dose',
    'prescription',
    'gp',
    'doctor',
    'specialist',
    'nurse',
    'hospital',
    'clinic',
    'physio',
    'surgery',
    'operation',
    'treatment',
    'immunisation',
    'vaccine',
    'vaccination',
    'xray',
    'mri',
    'ct',
    'ultrasound',
    'counselling',
    'therapy',
  ],
  ComplexityDomain.mentalEmotionalState: [
    'anxious',
    'anxiety',
    'stressed',
    'stress',
    'depressed',
    'low',
    'sad',
    'panic',
    'overwhelmed',
    'irritable',
    'grief',
    'hopeless',
    'burnout',
  ],
  ComplexityDomain.capacityEnergy: [
    'tired',
    'fatigue',
    'fatigued',
    'exhausted',
    'drained',
    'energy',
    'stamina',
    'overloaded',
    'bandwidth',
    'capacity',
    'motivation',
    'focus',
  ],
  ComplexityDomain.accessToCare: [
    'appointment',
    'waitlist',
    'wait',
    'referral',
    'telehealth',
    'bulk',
    'billing',
    'gap',
    'medicare',
  ],
  ComplexityDomain.environmentExposures: [
    'mould',
    'mold',
    'smoke',
    'pollution',
    'fumes',
    'chemical',
    'chemicals',
    'dust',
    'pollen',
    'heatwave',
    'heat',
    'cold',
    'noise',
    'damp',
    'allergens',
  ],
  ComplexityDomain.socialSupportContext: [
    'partner',
    'family',
    'friends',
    'support',
    'supportive',
    'carer',
    'caregiver',
    'community',
    'alone',
    'isolated',
    'lonely',
  ],
  ComplexityDomain.resourcesConstraints: [
    'money',
    'rent',
    'bills',
    'debt',
    'housing',
    'food',
    'groceries',
    'transport',
    'job',
    'unemployed',
    'work',
    'shift',
    'childcare',
    'cost',
    'afford',
    'budget',
    'centrelink',
    'income',
  ],
  ComplexityDomain.knowledgeBeliefsPreferences: [
    'prefer',
    'preference',
    'believe',
    'think',
    'unsure',
    'confused',
    'information',
    'research',
    'avoid',
    'comfortable',
    'worried',
    'concerned',
    'values',
    'effects',
  ],
  ComplexityDomain.goalsIntent: [
    'goal',
    'aim',
    'plan',
    'intend',
    'trying',
    'want',
    'hope',
    'looking',
  ],
  ComplexityDomain.safetyRisk: [],
  ComplexityDomain.unknownOther: [],
};

const Map<ComplexityDomain, List<String>> _domainPhrases = {
  ComplexityDomain.symptomsBodySignals: [
    'sore throat',
    'body aches',
    'stomach pain',
    'skin rash',
  ],
  ComplexityDomain.durationPattern: [
    'for weeks',
    'for months',
    'for days',
    'for years',
    'on and off',
    'every day',
    'every week',
    'every afternoon',
    'since last',
    'keeps coming back',
    'all the time',
  ],
  ComplexityDomain.medicalContext: [
    'blood test',
    'test results',
    'x ray',
    'gp appointment',
  ],
  ComplexityDomain.mentalEmotionalState: [
    'low mood',
    'panic attack',
    'panic attacks',
    'on edge',
    'feeling down',
    'burnt out',
  ],
  ComplexityDomain.capacityEnergy: [
    'no energy',
    'brain fog',
    'cant focus',
    'can only manage',
    'struggling to focus',
  ],
  ComplexityDomain.accessToCare: [
    'cant get an appointment',
    'cant get a gp appointment',
    'cant see a doctor',
    'no bulk billing',
    'need a referral',
    'long wait',
    'wait time',
  ],
  ComplexityDomain.environmentExposures: [
    'poor air',
    'workplace exposure',
    'second hand smoke',
    'air quality',
  ],
  ComplexityDomain.socialSupportContext: [
    'no one',
    'living alone',
    'no support',
    'support network',
    'feel isolated',
  ],
  ComplexityDomain.resourcesConstraints: [
    'cant afford',
    'rent overdue',
    'no transport',
    'shift work',
    'cost of living',
    'working two jobs',
  ],
  ComplexityDomain.knowledgeBeliefsPreferences: [
    'not sure',
    'dont understand',
    'need more information',
    'want to avoid',
    'natural options',
    'side effects',
  ],
  ComplexityDomain.goalsIntent: [
    'want to',
    'trying to',
    'hoping to',
    'looking to',
    'plan to',
    'aim to',
    'goal is',
  ],
  ComplexityDomain.safetyRisk: [],
  ComplexityDomain.unknownOther: [],
};

class _FactorDefinition {
  final ComplexityDomain domain;
  final FactorType type;
  final FactorModifiability modifiability;
  final FactorTimeHorizon defaultTimeHorizon;

  const _FactorDefinition({
    required this.domain,
    required this.type,
    required this.modifiability,
    required this.defaultTimeHorizon,
  });
}

class _MatchResult {
  final bool matched;
  final double confidence;

  const _MatchResult({
    required this.matched,
    required this.confidence,
  });
}

String _normaliseText(String input) {
  final normalized = input
      .toLowerCase()
      .replaceAll("'", '')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return normalized;
}

String _escapeRegExp(String value) {
  return value.replaceAllMapped(
    RegExp(r'[.*+?^${}()|[\]\\]'),
    (match) => '\\${match[0]}',
  );
}

int _countKeywordMatches(String text, List<String> keywords) {
  var score = 0;
  for (final keyword in keywords) {
    if (keyword.isEmpty) continue;
    final pattern = RegExp('\\b${_escapeRegExp(keyword)}\\b');
    final matches = pattern.allMatches(text);
    score += matches.length;
  }
  return score;
}

int _countPhraseMatches(String text, List<String> phrases) {
  var score = 0;
  for (final phrase in phrases) {
    if (phrase.isEmpty) continue;
    if (text.contains(phrase)) {
      score += 2;
    }
  }
  return score;
}

bool _detectSafetyRisk(String text) {
  for (final phrase in _safetyRiskPhrases) {
    if (text.contains(phrase)) return true;
  }
  for (final keyword in _safetyRiskKeywords) {
    final pattern = RegExp('\\b${_escapeRegExp(keyword)}\\b');
    if (pattern.hasMatch(text)) return true;
  }
  return false;
}

Map<ComplexityDomain, double> _scoreText(String text) {
  final scores = <ComplexityDomain, double>{
    for (final domain in ComplexityDomain.values) domain: 0,
  };

  for (final domain in _domainKeywords.keys) {
    final keywordScore = _countKeywordMatches(text, _domainKeywords[domain]!);
    final phraseScore = _countPhraseMatches(text, _domainPhrases[domain]!);
    scores[domain] = (keywordScore + phraseScore).toDouble();
  }

  return scores;
}

List<DomainTag> _toDomainTags(Map<ComplexityDomain, double> scores) {
  final total = scores.entries
      .where((entry) => entry.key != ComplexityDomain.safetyRisk)
      .fold<double>(0, (sum, entry) => sum + entry.value);

  if (total <= 0) return [];

  final tags = scores.entries
      .where((entry) => entry.value > 0)
      .map(
        (entry) => DomainTag(
          domain: entry.key,
          confidence: (entry.value / total).clamp(0, 1),
        ),
      )
      .toList();

  tags.sort((a, b) {
    if (b.confidence != a.confidence) {
      return b.confidence.compareTo(a.confidence);
    }
    final priorityA = complexityDomainMeta[a.domain]?.priority ?? 999;
    final priorityB = complexityDomainMeta[b.domain]?.priority ?? 999;
    return priorityA.compareTo(priorityB);
  });

  return tags;
}

ComplexityDomain? _inferDomainFromQuestion(String question) {
  final questionText = _normaliseText(question);
  if (questionText.isEmpty) return null;
  final tags = _toDomainTags(_scoreText(questionText));
  if (tags.isEmpty) return null;
  if (tags.first.confidence < 0.4) return null;
  return tags.first.domain;
}

DomainClassificationResult classifyDomains(
  String inputText,
  EventIntent intent, {
  String? previousQuestion,
}) {
  const minPrimaryConfidence = 0.6;
  const followUpBiasScore = 1.5;
  const safetyRiskConfidence = 0.9;
  const maxSecondaries = 2;

  final text = _normaliseText(inputText);

  if (_detectSafetyRisk(text)) {
    final secondary = _toDomainTags(_scoreText(text))
        .where((tag) => tag.domain != ComplexityDomain.safetyRisk)
        .take(maxSecondaries)
        .toList();
    return DomainClassificationResult(
      primary: const DomainTag(
        domain: ComplexityDomain.safetyRisk,
        confidence: safetyRiskConfidence,
      ),
      secondary: secondary,
      rationale: 'Safety risk keywords detected.',
    );
  }

  final scores = _scoreText(text);

  if (intent == EventIntent.followUp && previousQuestion != null) {
    final biasDomain = _inferDomainFromQuestion(previousQuestion);
    if (biasDomain != null) {
      scores[biasDomain] = (scores[biasDomain] ?? 0) + followUpBiasScore;
    }
  }

  final tags = _toDomainTags(scores);
  if (tags.isEmpty) {
    return DomainClassificationResult(
      primary: const DomainTag(
        domain: ComplexityDomain.unknownOther,
        confidence: 0,
      ),
      secondary: const [],
      rationale: 'No domain signals detected.',
    );
  }

  final primaryCandidate = tags.first;
  if (primaryCandidate.confidence < minPrimaryConfidence) {
    final secondary = tags.take(maxSecondaries).toList();
    return DomainClassificationResult(
      primary: DomainTag(
        domain: ComplexityDomain.unknownOther,
        confidence: (1 - primaryCandidate.confidence).clamp(0, 1),
      ),
      secondary: secondary,
      rationale: 'Low confidence match.',
    );
  }

  final secondary = tags
      .where((tag) => tag.domain != primaryCandidate.domain)
      .take(maxSecondaries)
      .toList();

  return DomainClassificationResult(
    primary: primaryCandidate,
    secondary: secondary,
  );
}

ExtractedPayload extractFactors(
  String inputText,
  DomainClassificationResult domainResult,
  EventIntent intent,
  String eventId,
) {
  final text = _normaliseText(inputText);
  final allowedDomains = _buildAllowedDomains(domainResult);
  final factors = <FactorCode, Factor>{};
  var factorIndex = 0;
  var weakSignalDetected = false;

  void addFactor(
    FactorCode code,
    double confidence, {
    dynamic value = true,
    FactorTimeHorizon? timeHorizon,
  }) {
    if (confidence < _minFactorConfidence) {
      if (confidence > 0) {
        weakSignalDetected = true;
      }
      return;
    }
    final definition = _factorDefinitions[code];
    if (definition == null) return;
    if (!allowedDomains.contains(definition.domain)) return;

    final existing = factors[code];
    if (existing != null && existing.confidence >= confidence) {
      return;
    }

    factors[code] = Factor(
      id: 'factor_${eventId}_$factorIndex',
      domain: definition.domain,
      type: definition.type,
      code: code,
      value: value,
      confidence: confidence,
      timeHorizon: timeHorizon ?? definition.defaultTimeHorizon,
      modifiability: definition.modifiability,
      sourceEventId: eventId,
      createdAt: DateTime.now().toIso8601String(),
    );
    factorIndex += 1;
  }

  final safetyCode = _detectSafety(text);
  if (safetyCode != null) {
    addFactor(safetyCode, 0.95);
    if (safetyCode == FactorCode.safetySelfHarm) {
      addFactor(FactorCode.safetyRedFlag, 0.85);
    }
  }

  addFactor(
    FactorCode.symptomPain,
    _matchEither(
      text,
      ['sharp pain', 'severe pain', 'aching pain'],
      [
        'pain',
        'ache',
        'sore',
        'soreness',
        'tender',
        'swelling',
        'swollen',
        'hurt',
        'hurts',
        'cramp',
        'cramps'
      ],
      0.85,
    ).confidence,
  );
  addFactor(
    FactorCode.symptomDizziness,
    _matchEither(
      text,
      ['light headed', 'lightheaded'],
      ['dizzy', 'dizziness', 'spinning'],
      0.8,
    ).confidence,
  );
  addFactor(
    FactorCode.symptomNausea,
    _matchEither(
      text,
      ['feel sick', 'feel nauseous', 'threw up', 'throwing up'],
      ['nausea', 'nauseous', 'queasy', 'vomit', 'vomiting', 'threw up'],
      0.8,
    ).confidence,
  );
  addFactor(
    FactorCode.symptomBreathlessness,
    _matchEither(
      text,
      ['shortness of breath', 'trouble breathing', 'cant breathe'],
      ['breathless'],
      0.85,
    ).confidence,
  );
  addFactor(
    FactorCode.symptomHeadache,
    _matchEither(
      text,
      ['headache', 'migraine'],
      ['headache', 'migraine'],
      0.8,
    ).confidence,
  );

  for (final duration in _detectDuration(text)) {
    addFactor(
      duration.code,
      duration.confidence,
      value: duration.value,
      timeHorizon: duration.timeHorizon,
    );
  }

  addFactor(
    FactorCode.medicalChronicConditionMentioned,
    _matchPhrases(
      text,
      [
        'chronic condition',
        'long term condition',
        'long-term condition',
        'ongoing condition'
      ],
      0.75,
    ).confidence,
  );
  addFactor(
    FactorCode.medicalMedsMentioned,
    _matchEither(
      text,
      ['taking medication', 'on medication'],
      ['medication', 'meds', 'prescription', 'dose', 'tablet', 'pill'],
      0.8,
    ).confidence,
  );
  addFactor(
    FactorCode.medicalTestsMentioned,
    _matchEither(
      text,
      ['blood test', 'test results', 'scan results'],
      ['test', 'tests', 'xray', 'x ray', 'mri', 'ct', 'ultrasound', 'scan'],
      0.75,
    ).confidence,
  );
  addFactor(
    FactorCode.medicalCareVisit,
    _matchEither(
      text,
      ['saw my gp', 'visited the clinic', 'hospital visit'],
      ['gp', 'doctor', 'clinic', 'hospital', 'physio', 'counselling', 'therapy', 'appointment'],
      0.75,
    ).confidence,
  );

  addFactor(
    FactorCode.emotionAnxietyStress,
    _matchEither(
      text,
      ['feeling anxious', 'feeling stressed', 'overwhelmed'],
      ['anxious', 'anxiety', 'stress', 'stressed', 'overwhelmed', 'on edge'],
      0.8,
    ).confidence,
  );
  addFactor(
    FactorCode.emotionLowMood,
    _matchEither(
      text,
      ['low mood', 'feeling down'],
      ['sad', 'down', 'depressed', 'hopeless'],
      0.75,
    ).confidence,
  );
  addFactor(
    FactorCode.emotionPanic,
    _matchEither(
      text,
      ['panic attack', 'panic attacks'],
      ['panic'],
      0.85,
    ).confidence,
  );

  addFactor(
    FactorCode.capacityFatigue,
    _matchEither(
      text,
      ['no energy', 'completely drained'],
      ['tired', 'fatigue', 'fatigued', 'exhausted', 'drained'],
      0.8,
    ).confidence,
  );
  addFactor(
    FactorCode.capacityPoorSleep,
    _matchEither(
      text,
      ['poor sleep', 'cant sleep', "can't sleep", 'sleeping badly'],
      ['insomnia', 'waking up', 'sleep problems'],
      0.8,
    ).confidence,
  );
  addFactor(
    FactorCode.capacityLowFocus,
    _matchEither(
      text,
      ['cant focus', "can't focus", 'brain fog'],
      ['foggy', 'distracted', 'low focus'],
      0.75,
    ).confidence,
  );

  const careTerms = [
    'gp',
    'doctor',
    'clinic',
    'hospital',
    'appointment',
    'specialist',
    'telehealth'
  ];
  final hasCareTerm = _matchKeywords(text, careTerms).matched;

  final costBarrierMatch = _matchEither(
    text,
    ['cant afford', "can't afford", 'too expensive', 'no bulk billing', 'gap fee'],
    ['expensive', 'cost'],
    0.85,
  );
  if (costBarrierMatch.matched && hasCareTerm) {
    addFactor(FactorCode.accessCostBarrier, costBarrierMatch.confidence);
  }

  final appointmentBarrierMatch = _matchEither(
    text,
    [
      'cant get appointment',
      "can't get appointment",
      'no appointments',
      'booked out',
      'long wait',
      'waitlist'
    ],
    ['wait', 'waiting'],
    0.8,
  );
  if (appointmentBarrierMatch.matched) {
    addFactor(
      FactorCode.accessAppointmentBarrier,
      appointmentBarrierMatch.confidence,
    );
  }

  addFactor(
    FactorCode.resourceFinancialStrain,
    _matchEither(
      text,
      ['cant afford', "can't afford", 'rent overdue', 'bills piling up', 'cost of living'],
      ['money', 'rent', 'bills', 'debt', 'budget', 'afford'],
      0.75,
    ).confidence,
  );
  addFactor(
    FactorCode.resourceTimePressure,
    _matchEither(
      text,
      ['no time', 'time pressure', 'too busy', 'time poor', 'time-poor'],
      ['deadline', 'overbooked', 'shift work', 'busy'],
      0.7,
    ).confidence,
  );
  addFactor(
    FactorCode.resourceCaregivingLoad,
    _matchEither(
      text,
      ['caring for', 'looking after', 'caring responsibilities'],
      ['carer', 'caregiver', 'kids', 'children', 'childcare', 'elderly', 'parent'],
      0.75,
    ).confidence,
  );

  addFactor(
    FactorCode.envAirQualityExposure,
    _matchEither(
      text,
      ['air quality', 'second hand smoke'],
      ['smoke', 'mould', 'mold', 'pollution', 'fumes', 'dust', 'pollen'],
      0.75,
    ).confidence,
  );

  addFactor(
    FactorCode.socialSupportLimited,
    _matchEither(
      text,
      ['no support', 'no one', 'living alone'],
      ['alone', 'isolated', 'lonely'],
      0.7,
    ).confidence,
  );

  addFactor(
    FactorCode.knowledgeNeedsInformation,
    _matchEither(
      text,
      ['need more information', 'dont understand', "don't understand"],
      ['not sure', 'unsure', 'confused'],
      0.7,
    ).confidence,
  );

  addFactor(
    FactorCode.goalSymptomRelief,
    _matchEither(
      text,
      ['feel better', 'relief', 'ease symptoms', 'reduce pain'],
      ['improve symptoms', 'help with pain'],
      0.7,
    ).confidence,
  );
  addFactor(
    FactorCode.goalBehaviourChange,
    _matchEither(
      text,
      ['want to', 'trying to', 'plan to', 'aim to', 'goal is'],
      ['build a routine', 'start exercising', 'improve sleep'],
      0.65,
    ).confidence,
  );

  final factorList = factors.values.toList();
  final onlyKnowledgeFactor =
      factorList.length == 1 && factorList.first.code == FactorCode.knowledgeNeedsInformation;

  MissingInfo? missingInfo;
  const symptomCodes = {
    FactorCode.symptomPain,
    FactorCode.symptomDizziness,
    FactorCode.symptomNausea,
    FactorCode.symptomBreathlessness,
    FactorCode.symptomHeadache,
  };
  const durationCodes = {
    FactorCode.durationOnsetRecent,
    FactorCode.durationDaysWeeks,
    FactorCode.durationMonthsPlus,
    FactorCode.patternRecurring,
  };

  final hasSymptom = factorList.any((factor) => symptomCodes.contains(factor.code));
  final hasDuration = factorList.any((factor) => durationCodes.contains(factor.code));
  final hasInjuryCause = _hasInjuryCause(text);
  final hasSeveritySignal = _hasSeveritySignal(text);
  final hasVisibleSigns = _hasVisibleSigns(text);
  final hasOralContext = _hasOralContext(text);

  if (hasSymptom && !hasDuration && intent != EventIntent.followUp) {
    missingInfo = const MissingInfo(
      key: 'duration',
      question: 'How long has this been happening?',
      domain: ComplexityDomain.durationPattern,
      priority: 'high',
    );
  } else if (hasSymptom && hasOralContext && !hasInjuryCause) {
    missingInfo = const MissingInfo(
      key: 'onset_injury',
      question: 'Did this start after biting, burning, or irritation?',
      domain: ComplexityDomain.symptomsBodySignals,
      priority: 'high',
    );
  } else if (hasSymptom && !hasSeveritySignal && !hasInjuryCause) {
    missingInfo = const MissingInfo(
      key: 'severity',
      question: 'How intense is the discomfort right now?',
      domain: ComplexityDomain.symptomsBodySignals,
      priority: 'high',
    );
  } else if (hasSymptom && !hasVisibleSigns && !hasInjuryCause) {
    missingInfo = const MissingInfo(
      key: 'visible_signs',
      question: 'Can you see a sore, ulcer, or colour change?',
      domain: ComplexityDomain.symptomsBodySignals,
      priority: 'medium',
    );
  } else if ((factorList.isEmpty || onlyKnowledgeFactor) &&
      (weakSignalDetected || _isAmbiguousText(text))) {
    missingInfo = MissingInfo(
      key: 'clarify',
      question: 'What feels most important to focus on right now?',
      domain: domainResult.primary.domain,
      priority: 'medium',
    );
  }

  if (missingInfo != null) {
    return ExtractedPayload(
      factors: onlyKnowledgeFactor ? const [] : factorList,
      missingInfo: [missingInfo],
    );
  }

  return ExtractedPayload(factors: factorList);
}

List<Factor> applyFactorWrites(
  List<Factor> factors,
  List<FactorWrite> writes,
  String eventId,
) {
  if (writes.isEmpty) return factors;
  final now = DateTime.now().toIso8601String();
  final updated = List<Factor>.from(factors);

  var index = 0;
  for (final write in writes) {
    final definition = _factorDefinitions[write.code];
    if (definition == null) {
      index += 1;
      continue;
    }
    final existingIndex =
        updated.indexWhere((factor) => factor.code == write.code);
    final created = Factor(
      id: 'factor_${eventId}_followup_$index',
      domain: definition.domain,
      type: definition.type,
      code: write.code,
      value: write.value,
      confidence: write.confidence,
      timeHorizon: write.timeHorizon == FactorTimeHorizon.unknown
          ? definition.defaultTimeHorizon
          : write.timeHorizon,
      modifiability: definition.modifiability,
      sourceEventId: eventId,
      createdAt: now,
    );

    if (existingIndex == -1) {
      updated.add(created);
    } else if (updated[existingIndex].confidence <= created.confidence) {
      updated[existingIndex] = created;
    }
    index += 1;
  }

  return updated;
}

String? detectSymptomKey(String inputText, List<Factor> factors) {
  final text = _normaliseText(inputText);
  if (text.contains('vomit') || text.contains('threw up')) {
    return 'vomiting';
  }
  if (text.contains('nausea') || text.contains('nauseous')) {
    return 'nausea';
  }
  if (text.contains('headache') || text.contains('migraine')) {
    return 'headache';
  }
  if (text.contains('dizzy') || text.contains('dizziness')) {
    return 'dizziness';
  }
  if (text.contains('breathless') || text.contains('breathing')) {
    return 'breathlessness';
  }
  if (text.contains('pain') || text.contains('ache') || text.contains('sore')) {
    return 'pain';
  }

  if (factors.any((factor) => factor.code == FactorCode.symptomHeadache)) {
    return 'headache';
  }
  if (factors.any((factor) => factor.code == FactorCode.symptomNausea)) {
    return 'nausea';
  }
  if (factors.any((factor) => factor.code == FactorCode.symptomDizziness)) {
    return 'dizziness';
  }
  if (factors.any((factor) => factor.code == FactorCode.symptomBreathlessness)) {
    return 'breathlessness';
  }
  if (factors.any((factor) => factor.code == FactorCode.symptomPain)) {
    return 'pain';
  }

  return null;
}

Set<ComplexityDomain> _buildAllowedDomains(DomainClassificationResult domainResult) {
  final allowed = <ComplexityDomain>{};
  final primary = domainResult.primary.domain;
  if (primary == ComplexityDomain.unknownOther) {
    allowed.addAll(ComplexityDomain.values);
    return allowed;
  }
  allowed.add(primary);
  for (final secondary in domainResult.secondary) {
    allowed.add(secondary.domain);
  }
  allowed.add(ComplexityDomain.safetyRisk);
  if (allowed.contains(ComplexityDomain.symptomsBodySignals)) {
    allowed.add(ComplexityDomain.durationPattern);
  }
  return allowed;
}

bool _isAmbiguousText(String text) {
  const markers = [
    'not sure',
    'hard to explain',
    'dont know',
    'no idea',
    'unsure',
    'confused',
  ];
  return markers.any(text.contains);
}

bool _hasSeveritySignal(String text) {
  const cues = [
    'mild',
    'moderate',
    'severe',
    'sharp',
    'intense',
    'throbbing',
    'burning',
    'stinging',
    'aching',
    'constant',
    'comes and goes',
  ];
  return cues.any(text.contains);
}

bool _hasVisibleSigns(String text) {
  const cues = [
    'sore',
    'ulcer',
    'blister',
    'swollen',
    'swelling',
    'rash',
    'redness',
    'white patch',
    'colour change',
    'color change',
    'bruise',
    'bleeding',
    'lump',
    'lesion',
  ];
  return cues.any(text.contains);
}

bool _hasInjuryCause(String text) {
  const cues = [
    'bit',
    'bite',
    'biting',
    'burn',
    'burnt',
    'burning',
    'irritation',
    'irritated',
    'scratched',
    'cut',
    'injured',
    'trauma',
  ];
  return cues.any(text.contains);
}

bool _hasOralContext(String text) {
  const cues = [
    'tongue',
    'mouth',
    'gum',
    'cheek',
    'lip',
    'throat',
  ];
  return cues.any(text.contains);
}

List<_DurationMatch> _detectDuration(String text) {
  final results = <_DurationMatch>[];

  final onsetMatch = _matchPhrases(
    text,
    [
      'just started',
      'started today',
      'since yesterday',
      'yesterday',
      'since last night',
      'this morning',
      'sudden',
      'suddenly'
    ],
    0.75,
  );
  if (onsetMatch.matched) {
    results.add(
      _DurationMatch(
        code: FactorCode.durationOnsetRecent,
        confidence: onsetMatch.confidence,
        timeHorizon: FactorTimeHorizon.acute,
        value: 'recent_onset',
      ),
    );
  }

  final numericMatch = RegExp(r'\b(\d+|few|couple)\s+(day|days|week|weeks|month|months|year|years)\b')
      .firstMatch(text);
  if (numericMatch != null) {
    final unit = numericMatch.group(2) ?? '';
    if (unit.startsWith('month') || unit.startsWith('year')) {
      results.add(
        _DurationMatch(
          code: FactorCode.durationMonthsPlus,
          confidence: 0.8,
          timeHorizon:
              unit.startsWith('year') ? FactorTimeHorizon.lifeCourse : FactorTimeHorizon.chronic,
          value: unit.startsWith('year') ? 'years_plus' : 'months_plus',
        ),
      );
    } else {
      results.add(
        _DurationMatch(
          code: FactorCode.durationDaysWeeks,
          confidence: 0.75,
          timeHorizon: FactorTimeHorizon.acute,
          value: 'days_weeks',
        ),
      );
    }
  }

  final phraseDaysWeeks = _matchPhrases(
    text,
    ['for days', 'for weeks', 'last week', 'past few days', 'this week'],
    0.7,
  );
  if (phraseDaysWeeks.matched) {
    results.add(
      _DurationMatch(
        code: FactorCode.durationDaysWeeks,
        confidence: phraseDaysWeeks.confidence,
        timeHorizon: FactorTimeHorizon.acute,
        value: 'days_weeks',
      ),
    );
  }

  final phraseMonthsPlus = _matchPhrases(
    text,
    ['for months', 'for years', 'long term', 'long-term', 'ongoing'],
    0.75,
  );
  if (phraseMonthsPlus.matched) {
    results.add(
      _DurationMatch(
        code: FactorCode.durationMonthsPlus,
        confidence: phraseMonthsPlus.confidence,
        timeHorizon: text.contains('year') ? FactorTimeHorizon.lifeCourse : FactorTimeHorizon.chronic,
        value: text.contains('year') ? 'years_plus' : 'months_plus',
      ),
    );
  }

  final recurringMatch = _matchPhrases(
    text,
    ['on and off', 'keeps coming back', 'recurring', 'every day', 'every week', 'most days', 'regularly'],
    0.7,
  );
  if (recurringMatch.matched) {
    results.add(
      _DurationMatch(
        code: FactorCode.patternRecurring,
        confidence: recurringMatch.confidence,
        timeHorizon: FactorTimeHorizon.chronic,
        value: 'recurring',
      ),
    );
  }

  return results;
}

FactorCode? _detectSafety(String text) {
  const selfHarmPhrases = [
    'suicidal',
    'suicide',
    'self harm',
    'kill myself',
    'end my life',
  ];
  if (selfHarmPhrases.any(text.contains)) {
    return FactorCode.safetySelfHarm;
  }

  const redFlags = [
    'chest pain',
    'trouble breathing',
    'shortness of breath',
    'cant breathe',
    'severe bleeding',
    'bleeding heavily',
    'passed out',
    'fainting',
    'face droop',
    'slurred speech',
    'weakness on one side',
    'sudden severe headache',
  ];
  if (redFlags.any(text.contains)) {
    return FactorCode.safetyRedFlag;
  }
  return null;
}

_MatchResult _matchKeywords(String text, List<String> keywords) {
  for (final keyword in keywords) {
    final pattern = RegExp('\\b${_escapeRegExp(keyword)}\\b');
    if (pattern.hasMatch(text)) {
      return const _MatchResult(matched: true, confidence: 0.7);
    }
  }
  return const _MatchResult(matched: false, confidence: 0);
}

_MatchResult _matchPhrases(String text, List<String> phrases, double confidence) {
  for (final phrase in phrases) {
    if (text.contains(phrase)) {
      return _MatchResult(matched: true, confidence: confidence);
    }
  }
  return const _MatchResult(matched: false, confidence: 0);
}

_MatchResult _matchEither(
  String text,
  List<String> phrases,
  List<String> keywords,
  double phraseConfidence,
) {
  final phraseMatch = _matchPhrases(text, phrases, phraseConfidence);
  if (phraseMatch.matched) {
    return phraseMatch;
  }
  return _matchKeywords(text, keywords);
}

class _DurationMatch {
  final FactorCode code;
  final double confidence;
  final FactorTimeHorizon timeHorizon;
  final String value;

  const _DurationMatch({
    required this.code,
    required this.confidence,
    required this.timeHorizon,
    required this.value,
  });
}

ExtractedPayload filterMissingInfo(ExtractedPayload extracted) {
  final missingInfo = extracted.missingInfo;
  if (missingInfo == null || missingInfo.isEmpty) {
    return extracted;
  }
  final hasSymptom = extracted.factors.any(
    (factor) => {
      FactorCode.symptomPain,
      FactorCode.symptomDizziness,
      FactorCode.symptomNausea,
      FactorCode.symptomBreathlessness,
      FactorCode.symptomHeadache,
    }.contains(factor.code),
  );

  final filtered = missingInfo.where((info) {
    if (info.key == 'duration' ||
        info.key == 'severity' ||
        info.key == 'visible_signs' ||
        info.key == 'onset_injury') {
      return hasSymptom;
    }
    return true;
  }).toList();

  if (filtered.isEmpty) {
    return ExtractedPayload(factors: extracted.factors);
  }
  return ExtractedPayload(factors: extracted.factors, missingInfo: filtered);
}

ComplexityProfile buildComplexityProfile(
  List<Factor> factors, {
  double minConfidence = 0.7,
  Set<FactorCode>? suppressedCodes,
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final latestByCode = <FactorCode, Factor>{};

  for (final factor in factors) {
    if (factor.confidence < minConfidence) continue;
    if (suppressedCodes != null && suppressedCodes.contains(factor.code)) continue;
    final ttl = getFactorTtl(factor.code, factor.timeHorizon);
    if (ttl != null) {
      final factorTime = DateTime.tryParse(factor.createdAt);
      if (factorTime != null) {
        if (currentTime.difference(factorTime) > ttl) {
          continue;
        }
      }
    }
    final existing = latestByCode[factor.code];
    if (existing == null) {
      latestByCode[factor.code] = factor;
      continue;
    }
    final existingTime = DateTime.tryParse(existing.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final candidateTime = DateTime.tryParse(factor.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (candidateTime.isAfter(existingTime) ||
        (candidateTime.isAtSameMomentAs(existingTime) &&
            factor.confidence >= existing.confidence)) {
      latestByCode[factor.code] = factor;
    }
  }

  final coverage = {
    for (final domain in ComplexityDomain.values) domain: const DomainCoverage(acute: 0, chronic: 0),
  };

  for (final factor in latestByCode.values) {
    final current = coverage[factor.domain] ?? const DomainCoverage(acute: 0, chronic: 0);
    if (factor.timeHorizon == FactorTimeHorizon.chronic ||
        factor.timeHorizon == FactorTimeHorizon.lifeCourse) {
      coverage[factor.domain] = current.copyWith(chronic: current.chronic + 1);
    } else if (factor.timeHorizon == FactorTimeHorizon.acute) {
      coverage[factor.domain] = current.copyWith(acute: current.acute + 1);
    }
  }

  final constraintCandidates = latestByCode.values
      .where(
        (factor) => factor.type == FactorType.constrainedChoice ||
            factor.domain == ComplexityDomain.resourcesConstraints ||
            factor.domain == ComplexityDomain.accessToCare,
      )
      .toList();

  constraintCandidates.sort((a, b) {
    final aTime = DateTime.tryParse(a.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = DateTime.tryParse(b.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (aTime != bTime) {
      return bTime.compareTo(aTime);
    }
    return b.confidence.compareTo(a.confidence);
  });

  return ComplexityProfile(
    updatedAt: currentTime.toIso8601String(),
    factorsByCode: Map<FactorCode, Factor>.from(latestByCode),
    topConstraints: constraintCandidates.take(3).toList(),
    domainsCoverage: coverage,
  );
}

Duration? getFactorTtl(FactorCode code, FactorTimeHorizon timeHorizon) {
  const fourteenDays = Duration(days: 14);
  const sevenDays = Duration(days: 7);
  const seventyTwoHours = Duration(hours: 72);
  const constraintCodes = {
    FactorCode.accessCostBarrier,
    FactorCode.accessAppointmentBarrier,
    FactorCode.resourceTimePressure,
  };

  if (timeHorizon == FactorTimeHorizon.chronic || timeHorizon == FactorTimeHorizon.lifeCourse) {
    return null;
  }

  if (constraintCodes.contains(code)) {
    return fourteenDays;
  }

  if (timeHorizon == FactorTimeHorizon.acute) {
    return seventyTwoHours;
  }

  if (timeHorizon == FactorTimeHorizon.unknown) {
    return sevenDays;
  }

  return null;
}

StateSnapshot buildStateSnapshot(
  Event event,
  DomainClassificationResult domainResult,
  ExtractedPayload extracted,
  ComplexityProfile profile,
) {
  final factors = extracted.factors;
  final usedBuffer = <Factor>[];

  final riskBand = _computeRiskBand(factors, domainResult, usedBuffer);
  final uncertaintyBand = _computeUncertaintyBand(factors, extracted.missingInfo);
  final frictionBand = _computeFrictionBand(factors, usedBuffer);

  final whatMatters = _buildWhatMatters(factors, usedBuffer);
  for (final factor in factors) {
    final alreadyUsed = usedBuffer.any((item) => item.code == factor.code);
    if (!alreadyUsed) {
      usedBuffer.add(factor);
    }
  }
  final usedFactors = _summariseUsedFactors(usedBuffer);

  NextActionKind nextActionKind = NextActionKind.answer;
  if (riskBand == RiskBand.urgent) {
    nextActionKind = NextActionKind.safetyEscalation;
  } else if (event.intent == EventIntent.logOnly) {
    nextActionKind = NextActionKind.logOnly;
  }

  final safetyCopy = riskBand == RiskBand.urgent
      ? 'If you are in immediate danger, call 000 or seek urgent care.'
      : null;

  return StateSnapshot(
    eventId: event.id,
    createdAt: DateTime.now().toIso8601String(),
    intent: event.intent,
    riskBand: riskBand,
    frictionBand: frictionBand,
    uncertaintyBand: uncertaintyBand,
    nextActionKind: nextActionKind,
    whatMatters: whatMatters,
    followupQuestion: null,
    safetyCopy: safetyCopy,
    usedFactors: usedFactors,
  );
}

RiskBand _computeRiskBand(
  List<Factor> factors,
  DomainClassificationResult domainResult,
  List<Factor> used,
) {
  final hasSafetyDomain = domainResult.primary.domain == ComplexityDomain.safetyRisk ||
      domainResult.secondary.any((item) => item.domain == ComplexityDomain.safetyRisk);
  final safetyFactor = factors.firstWhere(
    (factor) => _safetyCodes.contains(factor.code),
    orElse: () => const Factor(
      id: 'none',
      domain: ComplexityDomain.unknownOther,
      type: FactorType.chance,
      code: FactorCode.knowledgeNeedsInformation,
      value: true,
      confidence: 0,
      timeHorizon: FactorTimeHorizon.unknown,
      modifiability: FactorModifiability.unknown,
      sourceEventId: 'none',
      createdAt: '',
    ),
  );

  if (hasSafetyDomain || safetyFactor.confidence > 0) {
    if (safetyFactor.confidence > 0) {
      used.add(safetyFactor);
    }
    return RiskBand.urgent;
  }

  final highRisk = factors.firstWhere(
    (factor) => _highRiskCodes.contains(factor.code) && factor.confidence >= 0.8,
    orElse: () => const Factor(
      id: 'none',
      domain: ComplexityDomain.unknownOther,
      type: FactorType.chance,
      code: FactorCode.knowledgeNeedsInformation,
      value: true,
      confidence: 0,
      timeHorizon: FactorTimeHorizon.unknown,
      modifiability: FactorModifiability.unknown,
      sourceEventId: 'none',
      createdAt: '',
    ),
  );
  if (highRisk.confidence > 0) {
    used.add(highRisk);
    return RiskBand.high;
  }

  final mediumRisk = factors.firstWhere(
    (factor) => _mediumRiskCodes.contains(factor.code),
    orElse: () => const Factor(
      id: 'none',
      domain: ComplexityDomain.unknownOther,
      type: FactorType.chance,
      code: FactorCode.knowledgeNeedsInformation,
      value: true,
      confidence: 0,
      timeHorizon: FactorTimeHorizon.unknown,
      modifiability: FactorModifiability.unknown,
      sourceEventId: 'none',
      createdAt: '',
    ),
  );
  if (mediumRisk.confidence > 0) {
    used.add(mediumRisk);
    return RiskBand.medium;
  }

  return RiskBand.low;
}

UncertaintyBand _computeUncertaintyBand(
  List<Factor> factors,
  List<MissingInfo>? missing,
) {
  if (missing != null && missing.isNotEmpty) {
    return UncertaintyBand.high;
  }
  if (factors.isEmpty) {
    return UncertaintyBand.medium;
  }
  final average =
      factors.fold<double>(0, (sum, factor) => sum + factor.confidence) / factors.length;
  if (average < 0.7) {
    return UncertaintyBand.medium;
  }
  return UncertaintyBand.low;
}

FrictionBand _computeFrictionBand(List<Factor> factors, List<Factor> used) {
  final highFriction = factors.firstWhere(
    (factor) => _highFrictionCodes.contains(factor.code) && factor.confidence >= 0.75,
    orElse: () => const Factor(
      id: 'none',
      domain: ComplexityDomain.unknownOther,
      type: FactorType.chance,
      code: FactorCode.knowledgeNeedsInformation,
      value: true,
      confidence: 0,
      timeHorizon: FactorTimeHorizon.unknown,
      modifiability: FactorModifiability.unknown,
      sourceEventId: 'none',
      createdAt: '',
    ),
  );
  if (highFriction.confidence > 0) {
    used.add(highFriction);
    return FrictionBand.high;
  }

  final mediumFriction = factors.firstWhere(
    (factor) => _mediumFrictionCodes.contains(factor.code) && factor.confidence >= 0.6,
    orElse: () => const Factor(
      id: 'none',
      domain: ComplexityDomain.unknownOther,
      type: FactorType.chance,
      code: FactorCode.knowledgeNeedsInformation,
      value: true,
      confidence: 0,
      timeHorizon: FactorTimeHorizon.unknown,
      modifiability: FactorModifiability.unknown,
      sourceEventId: 'none',
      createdAt: '',
    ),
  );
  if (mediumFriction.confidence > 0) {
    used.add(mediumFriction);
    return FrictionBand.medium;
  }

  return FrictionBand.low;
}

List<String> _buildWhatMatters(List<Factor> factors, List<Factor> used) {
  if (factors.isEmpty) {
    return ['One quick detail can help narrow this down.'];
  }

  final ordered = _sortForWhatMatters(factors);
  final bullets = <String>[];

  for (final factor in ordered) {
    final copy = _bulletCopy[factor.code];
    if (copy == null) continue;
    bullets.add(copy);
    used.add(factor);
    if (bullets.length >= 3) break;
  }

  if (bullets.isEmpty) {
    final primaryDomainLabel =
        complexityDomainMeta[factors.first.domain]?.label ?? 'Focus area';
    bullets.add('$primaryDomainLabel is the main focus right now.');
    used.add(factors.first);
  }

  return bullets.take(3).toList();
}

List<Factor> _sortForWhatMatters(List<Factor> factors) {
  final sorted = List<Factor>.from(factors);
  sorted.sort((left, right) {
    final domainDelta = _priorityForDomain(left.domain) - _priorityForDomain(right.domain);
    if (domainDelta != 0) return domainDelta;
    if (right.confidence != left.confidence) {
      return right.confidence.compareTo(left.confidence);
    }
    return right.createdAt.compareTo(left.createdAt);
  });
  return sorted;
}

int _priorityForDomain(ComplexityDomain domain) {
  final index = _domainPriority.indexOf(domain);
  return index == -1 ? _domainPriority.length : index;
}

List<UsedFactor> _summariseUsedFactors(List<Factor> factors) {
  final seen = <FactorCode>{};
  final result = <UsedFactor>[];
  for (final factor in factors) {
    if (seen.contains(factor.code)) continue;
    seen.add(factor.code);
    result.add(
      UsedFactor(
        code: factor.code,
        domain: factor.domain,
        confidence: factor.confidence,
      ),
    );
  }
  return result;
}

MissingInfo? _selectHighestPriorityMissingInfo(List<MissingInfo>? missing) {
  if (missing == null || missing.isEmpty) return null;
  final priorityRank = {'high': 0, 'medium': 1, 'low': 2};
  final sorted = List<MissingInfo>.from(missing);
  sorted.sort((a, b) {
    final aRank = priorityRank[a.priority] ?? 99;
    final bRank = priorityRank[b.priority] ?? 99;
    return aRank.compareTo(bRank);
  });
  return sorted.first;
}

RouteNextStepResult routeNextStep(StateSnapshot snapshot) {
  const safetyNetCopy =
      'If you feel unsafe or symptoms get worse, call 000 or seek urgent care.';

  final hasSelfHarmSignal = snapshot.usedFactors
      .any((factor) => factor.code == FactorCode.safetySelfHarm);
  if (hasSelfHarmSignal) {
    return const RouteNextStepResult(
      category: NextStepCategory.crisisSupport,
      rationale: 'You deserve immediate support right now.',
      safetyNet: safetyNetCopy,
    );
  }

  if (snapshot.nextActionKind == NextActionKind.safetyEscalation ||
      snapshot.riskBand == RiskBand.urgent) {
    return const RouteNextStepResult(
      category: NextStepCategory.urgentCareEd,
      rationale: 'Urgent safety signals mean rapid care is the safest option.',
      safetyNet: safetyNetCopy,
    );
  }

  if (snapshot.uncertaintyBand == UncertaintyBand.high &&
      snapshot.nextActionKind == NextActionKind.askFollowup) {
    return const RouteNextStepResult(
      category: NextStepCategory.selfCare,
      rationale: 'Need one more detail to guide the next step.',
    );
  }

  if (snapshot.riskBand == RiskBand.high) {
    if (snapshot.frictionBand == FrictionBand.high) {
      return const RouteNextStepResult(
        category: NextStepCategory.urgentCareEd,
        rationale: 'Higher risk with high friction suggests urgent care.',
        safetyNet: safetyNetCopy,
      );
    }
    return const RouteNextStepResult(
      category: NextStepCategory.gpTelehealth,
      rationale: 'Higher risk points to GP or telehealth support.',
    );
  }

  if (snapshot.riskBand == RiskBand.medium) {
    if (snapshot.frictionBand == FrictionBand.high) {
      return const RouteNextStepResult(
        category: NextStepCategory.gpTelehealth,
        rationale: 'Medium risk with high friction needs GP support.',
      );
    }
    return const RouteNextStepResult(
      category: NextStepCategory.pharmacist,
      rationale: 'A pharmacist can help with the next step.',
    );
  }

  return const RouteNextStepResult(
    category: NextStepCategory.selfCare,
    rationale: 'Low risk points to self-care for now.',
  );
}

ComplexityResponseModel buildResponseModel(
  String inputText,
  StateSnapshot snapshot,
  RouteNextStepResult routed,
  WhatImUsingModel whatImUsing,
  List<Factor> factors, {
  FollowUpPlan? followUpPlan,
}) {
  final symptomKey = snapshot.symptomKey;
  final confirmation = buildConfirmation(inputText, symptomKey);
  final keyFactors = [...buildKeyFactors(factors)];
  if (snapshot.followUpCount >= 2 && keyFactors.length < 2) {
    keyFactors.add('Some details are still unclear, so keep things gentle.');
  }
  final whatToDoNow = buildWhatToDoNow(symptomKey, factors);
  final whatIfWorse = buildWhatIfWorse(symptomKey, factors);

  if (snapshot.nextActionKind == NextActionKind.logOnly) {
    return ComplexityResponseModel(
      mode: ResponseMode.logOnly,
      confirmation: 'Saved for you.',
      whatImUsing: whatImUsing,
    );
  }

  if (snapshot.nextActionKind == NextActionKind.askFollowup) {
    final resolvedPlan = followUpPlan ?? _fallbackFollowUpPlan();
    return ComplexityResponseModel(
      mode: ResponseMode.askFollowup,
      confirmation: confirmation,
      followUpPlan: resolvedPlan,
      symptomKey: symptomKey,
      keyFactors: keyFactors,
      routerCategory: routed.category,
      whatImUsing: whatImUsing,
    );
  }

  if (snapshot.nextActionKind == NextActionKind.safetyEscalation ||
      routed.category == NextStepCategory.urgentCareEd ||
      routed.category == NextStepCategory.crisisSupport) {
    return ComplexityResponseModel(
      mode: ResponseMode.safetyEscalation,
      confirmation: confirmation,
      symptomKey: symptomKey,
      keyFactors: keyFactors,
      routerCategory: routed.category,
      safetyNet: routed.safetyNet ?? snapshot.safetyCopy,
      whatImUsing: whatImUsing,
    );
  }

  final answerText = buildAnswerText(symptomKey, factors);

  return ComplexityResponseModel(
    mode: ResponseMode.answer,
    confirmation: confirmation,
    answer: answerText,
    symptomKey: symptomKey,
    keyFactors: keyFactors,
    routerCategory: routed.category,
    whatToDoNow: whatToDoNow,
    whatIfWorse: whatIfWorse,
    safetyNet: routed.safetyNet,
    whatImUsing: whatImUsing,
  );
}

FollowUpPlan _fallbackFollowUpPlan() {
  return const FollowUpPlan(
    questionText: 'How long has this been happening?',
    choices: [
      FollowUpChoice(
        label: 'Today',
        writesFactors: [
          FactorWrite(
            code: FactorCode.durationToday,
            confidence: 0.95,
            timeHorizon: FactorTimeHorizon.acute,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'A few days',
        writesFactors: [
          FactorWrite(
            code: FactorCode.durationFewDays,
            confidence: 0.95,
            timeHorizon: FactorTimeHorizon.acute,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'A week or more',
        writesFactors: [
          FactorWrite(
            code: FactorCode.durationWeekPlus,
            confidence: 0.95,
            timeHorizon: FactorTimeHorizon.chronic,
          ),
        ],
      ),
      FollowUpChoice(label: 'Skip'),
    ],
  );
}

String buildConfirmation(String inputText, String? symptomKey) {
  final trimmed = inputText.trim();
  if (symptomKey == 'headache') {
    return 'Headaches can throw off your day — that is very common.';
  }
  if (symptomKey == 'vomiting') {
    return 'Throwing up can feel rough and draining. That is a lot to deal with.';
  }
  if (symptomKey == 'nausea') {
    return 'Feeling nauseous can be really unsettling. Thanks for sharing.';
  }
  if (symptomKey == 'dizziness') {
    return 'Feeling dizzy can be unsettling. Many people feel off like this at times.';
  }
  if (symptomKey == 'breathlessness') {
    return 'Breathlessness can feel scary in the moment. Thanks for letting me know.';
  }
  if (symptomKey == 'pain') {
    return 'Pain can be draining. Thanks for sharing what is going on.';
  }
  if (trimmed.isNotEmpty) {
    return 'Thanks for sharing. That sounds uncomfortable.';
  }
  return 'Thanks for sharing. That sounds uncomfortable.';
}

List<String> buildKeyFactors(List<Factor> factors) {
  final scored = factors
      .where((factor) =>
          factor.confidence >= 0.7 && _bulletCopy.containsKey(factor.code))
      .toList();
  scored.sort((a, b) {
    final aPriority = complexityDomainMeta[a.domain]?.priority ?? 99;
    final bPriority = complexityDomainMeta[b.domain]?.priority ?? 99;
    if (aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }
    return b.confidence.compareTo(a.confidence);
  });
  final items = <String>[];
  for (final factor in scored) {
    final copy = _bulletCopy[factor.code];
    if (copy == null) continue;
    if (!items.contains(copy)) {
      items.add(copy);
    }
    if (items.length >= 4) break;
  }
  return items;
}

List<VaultActionSuggestion> buildWhatToDoNow(
  String? symptomKey,
  List<Factor> factors,
) {
  final items = <VaultActionSuggestion>[];

  void addAction(
    String title,
    List<String> steps, {
    String? schedule,
    String? energy,
    String? time,
    List<String> contexts = const [],
    List<String> priority = const [],
  }) {
    items.add(
      VaultActionSuggestion(
        title: title,
        steps: steps,
        defaultSchedule: schedule,
        energyRequired: energy,
        timeRequired: time,
        contextTags: contexts,
        priorityFactors: priority,
        vaultPayload: {
          'title': title,
          'steps': steps,
          'symptom_key': symptomKey,
          'schedule': schedule,
          'energy_required': energy,
          'time_required': time,
          'context_tags': contexts,
          'priority_factors': priority,
        },
      ),
    );
  }

  switch (symptomKey) {
    case 'headache':
      addAction(
        'Use a small reset',
        [
          'Dim lights and lower screen brightness',
          'Take a quiet 2-minute break to reset',
        ],
        schedule: 'today',
        energy: 'low',
        time: '2-5 mins',
        contexts: ['needs quiet', 'at home', 'at work/school'],
        priority: ['low effort', 'reduces strain'],
      );
      addAction(
        'Hydrate with an easy cue',
        [
          'Keep a glass nearby and take a few sips now',
          'Set a reminder to sip again in 20 minutes',
        ],
        energy: 'low',
        time: '1-2 mins',
        contexts: ['anywhere', 'on the go'],
        priority: ['supports recovery'],
      );
      addAction(
        'Release tension gently',
        [
          'Try two slow neck rolls each side',
          'Use a warm compress if that usually helps',
        ],
        energy: 'low',
        time: '5-10 mins',
        contexts: ['at home', 'needs supplies'],
        priority: ['targets tension'],
      );
      break;
    case 'vomiting':
      addAction(
        'Keep fluids manageable',
        [
          'Try a few sips every 5–10 minutes',
          'Pause if nausea rises and restart slowly',
        ],
        schedule: 'today',
        energy: 'very low',
        time: '2-5 mins',
        contexts: ['in bed', 'at home'],
        priority: ['prevents dehydration'],
      );
      addAction(
        'Create a calmer space',
        ['Lie on your side if you can', 'Keep the room cool and quiet'],
        energy: 'very low',
        time: '5-10 mins',
        contexts: ['in bed', 'needs quiet'],
        priority: ['conserves energy'],
      );
      addAction(
        'Return to food slowly',
        ['When ready, try bland food', 'Keep portions small'],
        energy: 'low',
        time: '10+ mins',
        contexts: ['at home', 'needs supplies'],
        priority: ['supports recovery'],
      );
      break;
    case 'nausea':
      addAction(
        'Settle your stomach',
        ['Try small sips of water or tea', 'Avoid heavy foods for now'],
        schedule: 'today',
        energy: 'very low',
        time: '2-5 mins',
        contexts: ['anywhere', 'on the go'],
        priority: ['gentle start'],
      );
      addAction(
        'Try a light reset',
        ['Sit near a window', 'Take a slow walk if it feels okay'],
        energy: 'low',
        time: '5-10 mins',
        contexts: ['at home', 'on the go'],
        priority: ['light movement'],
      );
      addAction(
        'Ease discomfort',
        ['Loosen tight clothing', 'Try slow breathing for a few minutes'],
        energy: 'very low',
        time: '2-5 mins',
        contexts: ['anywhere'],
        priority: ['quick relief'],
      );
      break;
    case 'dizziness':
      addAction(
        'Pause and steady',
        ['Sit or lie down for a few minutes', 'Fix your gaze on one spot'],
        schedule: 'today',
        energy: 'very low',
        time: '2-5 mins',
        contexts: ['anywhere', 'needs quiet'],
        priority: ['reduces risk'],
      );
      addAction(
        'Hydrate gently',
        ['Sip water or an oral rehydration drink', 'Avoid sudden standing'],
        energy: 'low',
        time: '2-5 mins',
        contexts: ['anywhere', 'on the go'],
        priority: ['supports balance'],
      );
      addAction(
        'Light fuel',
        ['If you can, have a small snack', 'Choose something easy to digest'],
        energy: 'low',
        time: '5-10 mins',
        contexts: ['at home', 'on the go'],
        priority: ['steady energy'],
      );
      break;
    default:
      addAction(
        'Pause and check in',
        ['Take a slow breath', 'Notice what feels most uncomfortable'],
        schedule: 'today',
        energy: 'very low',
        time: '1-2 mins',
        contexts: ['anywhere'],
        priority: ['builds awareness'],
      );
      addAction(
        'Hydrate gently',
        ['Sip water over a few minutes', 'Keep it light and steady'],
        energy: 'low',
        time: '2-5 mins',
        contexts: ['anywhere', 'on the go'],
        priority: ['easy win'],
      );
      addAction(
        'Keep it simple',
        ['Give yourself permission to go easy', 'Reassess in a little while'],
        energy: 'very low',
        time: '1-2 mins',
        contexts: ['anywhere', 'needs quiet'],
        priority: ['gentle pacing'],
      );
  }

  return items;
}

String buildAnswerText(String? symptomKey, List<Factor> factors) {
  final contextLine = _buildContextLine(factors);
  final triggerLine = _buildTriggerLine(factors);
  final decisionLine = _buildDecisionLine(symptomKey, factors);

  switch (symptomKey) {
    case 'headache':
      return _joinSentences([
        'Headaches can be linked to sleep changes, stress, dehydration, or muscle tension.',
        contextLine,
        triggerLine,
        decisionLine,
        'For now, the steps below focus on easing strain and supporting recovery.',
      ]);
    case 'dizziness':
      return _joinSentences([
        'Dizziness can show up with dehydration, low fuel, or moving too quickly.',
        contextLine,
        triggerLine,
        decisionLine,
        'For now, try steadying your body and keeping fluids gentle.',
      ]);
    case 'vomiting':
      return _joinSentences([
        'Vomiting can happen with a stomach bug, food irritation, or stress on the body.',
        contextLine,
        triggerLine,
        decisionLine,
        'For now, focus on small sips and giving your stomach time to settle.',
      ]);
    case 'nausea':
      return _joinSentences([
        'Nausea can be triggered by food, stress, or changes in routine.',
        contextLine,
        triggerLine,
        decisionLine,
        'For now, keep intake light and choose small, steady sips.',
      ]);
    case 'breathlessness':
      return _joinSentences([
        'Breathlessness can have a few causes, including exertion, anxiety, or illness.',
        contextLine,
        triggerLine,
        decisionLine,
        'For now, try slowing your breathing and minimising exertion.',
      ]);
    case 'pain':
      return _joinSentences([
        'Pain can follow strain, irritation, or overuse.',
        contextLine,
        triggerLine,
        decisionLine,
        'For now, keep things gentle and see how it shifts with light care.',
      ]);
    default:
      return _joinSentences([
        'Based on what you shared, it makes sense to start with gentle, practical steps.',
        contextLine,
        triggerLine,
        decisionLine,
        'The suggestions below focus on easing discomfort and monitoring changes.',
      ]);
  }
}

List<String> buildWhatIfWorse(String? symptomKey, List<Factor> factors) {
  switch (symptomKey) {
    case 'headache':
      return const [
        'Seek help if the headache becomes sudden and severe.',
        'Get support if you notice vision changes, weakness, or confusion.',
        'Reach out if it keeps worsening despite rest and hydration.',
      ];
    case 'vomiting':
      return const [
        'Get help if you cannot keep fluids down for several hours.',
        'Seek support if you feel very weak, dizzy, or faint.',
        'Reach out if there is severe abdominal pain or ongoing vomiting.',
      ];
    case 'nausea':
      return const [
        'Get help if you cannot keep fluids down or feel faint.',
        'Seek support if symptoms worsen or become severe.',
      ];
    case 'dizziness':
      return const [
        'Get help if dizziness comes with chest pain or severe headache.',
        'Seek support if you faint or cannot keep fluids down.',
      ];
    default:
      return const [
        'Seek support if symptoms get worse or feel severe.',
        'Reach out if you feel unsafe or unable to manage at home.',
      ];
  }
}

String _buildContextLine(List<Factor> factors) {
  final duration = _durationPhrase(factors);
  final severity = _severityPhrase(factors);
  final trend = _trendPhrase(factors);

  final parts = <String>[];
  if (duration != null) parts.add(duration);
  if (severity != null) parts.add(severity);
  if (trend != null) parts.add(trend);
  if (parts.isEmpty) return '';
  final sentence = parts.join(', ');
  return 'From what you shared, it $sentence.';
}

String _buildTriggerLine(List<Factor> factors) {
  final triggers = <String>[];
  if (_hasFactor(factors, FactorCode.contextTriggerInjury)) {
    triggers.add('an injury or irritation');
  }
  if (_hasFactor(factors, FactorCode.contextTriggerMedication)) {
    triggers.add('a new medication');
  }
  if (_hasFactor(factors, FactorCode.contextTriggerIllness)) {
    triggers.add('an illness');
  }
  if (triggers.isEmpty) return '';
  final joined = triggers.join(' or ');
  return 'You mentioned $joined, which can be relevant here.';
}

String _buildDecisionLine(String? symptomKey, List<Factor> factors) {
  final severe = _hasFactor(factors, FactorCode.severitySevere);
  final worse = _hasFactor(factors, FactorCode.trendWorse);
  final longDuration = _hasAnyFactor(
    factors,
    const {
      FactorCode.durationWeekPlus,
      FactorCode.durationMonthsPlus,
      FactorCode.durationDaysWeeks,
    },
  );

  if (severe || worse) {
    return 'If this feels severe or keeps worsening, it is sensible to seek medical advice sooner.';
  }
  if (longDuration) {
    return 'If this continues beyond a week or two, consider speaking with a GP or pharmacist.';
  }
  return 'If this does not settle in a few days or starts to worsen, consider a GP or pharmacist.';
}

String? _durationPhrase(List<Factor> factors) {
  if (_hasFactor(factors, FactorCode.durationToday)) {
    return 'started today';
  }
  if (_hasFactor(factors, FactorCode.durationFewDays)) {
    return 'has been going for a few days';
  }
  if (_hasFactor(factors, FactorCode.durationWeekPlus)) {
    return 'has been going for a week or more';
  }
  if (_hasFactor(factors, FactorCode.durationOnsetRecent)) {
    return 'started recently';
  }
  if (_hasFactor(factors, FactorCode.durationDaysWeeks)) {
    return 'has been going for days or weeks';
  }
  if (_hasFactor(factors, FactorCode.durationMonthsPlus)) {
    return 'has been going for months or longer';
  }
  if (_hasFactor(factors, FactorCode.patternRecurring)) {
    return 'has been coming and going';
  }
  return null;
}

String? _severityPhrase(List<Factor> factors) {
  if (_hasFactor(factors, FactorCode.severitySevere)) {
    return 'feels severe';
  }
  if (_hasFactor(factors, FactorCode.severityModerate)) {
    return 'feels moderate';
  }
  if (_hasFactor(factors, FactorCode.severityMild)) {
    return 'feels mild';
  }
  return null;
}

String? _trendPhrase(List<Factor> factors) {
  if (_hasFactor(factors, FactorCode.trendWorse)) {
    return 'seems to be getting worse';
  }
  if (_hasFactor(factors, FactorCode.trendBetter)) {
    return 'seems to be easing';
  }
  if (_hasFactor(factors, FactorCode.trendSame)) {
    return 'feels about the same';
  }
  return null;
}

bool _hasFactor(List<Factor> factors, FactorCode code) {
  return factors.any((factor) => factor.code == code);
}

bool _hasAnyFactor(List<Factor> factors, Set<FactorCode> codes) {
  return factors.any((factor) => codes.contains(factor.code));
}

String _joinSentences(List<String> sentences) {
  final filtered = sentences.where((item) => item.trim().isNotEmpty).toList();
  return filtered.join(' ');
}

WhatImUsingModel buildWhatImUsingModel(
  StateSnapshot snapshot, {
  required bool useSavedContext,
  required bool sessionUseProfile,
}) {
  return WhatImUsingModel(
    title: 'What Starbound is using',
    description:
        'These are the signals being used right now. You can pause saved context or turn off profile use for this session.',
    chips: formatUsedFactorsForUI(snapshot.usedFactors),
    controls: WhatImUsingControls(
      useSavedContext: useSavedContext,
      sessionUseProfile: sessionUseProfile,
    ),
  );
}

List<UsedFactorChip> formatUsedFactorsForUI(List<UsedFactor> used) {
  const bodySignalCodes = {
    FactorCode.symptomPain,
    FactorCode.symptomDizziness,
    FactorCode.symptomNausea,
    FactorCode.symptomBreathlessness,
    FactorCode.symptomHeadache,
    FactorCode.symptomGeneral,
    FactorCode.durationOnsetRecent,
    FactorCode.durationDaysWeeks,
    FactorCode.durationMonthsPlus,
    FactorCode.patternRecurring,
    FactorCode.durationToday,
    FactorCode.durationFewDays,
    FactorCode.durationWeekPlus,
    FactorCode.severityMild,
    FactorCode.severityModerate,
    FactorCode.severitySevere,
    FactorCode.trendBetter,
    FactorCode.trendWorse,
    FactorCode.trendSame,
    FactorCode.safetyRedFlag,
    FactorCode.safetySelfHarm,
  };

  const constraintCodes = {
    FactorCode.accessCostBarrier,
    FactorCode.accessAppointmentBarrier,
    FactorCode.resourceFinancialStrain,
    FactorCode.resourceTimePressure,
    FactorCode.resourceCaregivingLoad,
    FactorCode.capacityFatigue,
    FactorCode.capacityPoorSleep,
    FactorCode.capacityLowFocus,
  };

  const contextCodes = {
    FactorCode.medicalChronicConditionMentioned,
    FactorCode.medicalMedsMentioned,
    FactorCode.medicalTestsMentioned,
    FactorCode.medicalCareVisit,
    FactorCode.emotionAnxietyStress,
    FactorCode.emotionLowMood,
    FactorCode.emotionPanic,
    FactorCode.envAirQualityExposure,
    FactorCode.socialSupportLimited,
    FactorCode.knowledgeNeedsInformation,
    FactorCode.goalSymptomRelief,
    FactorCode.goalBehaviourChange,
  };

  const actionCodes = {
    FactorCode.behaviourRested,
    FactorCode.behaviourPushedThrough,
    FactorCode.behaviourChangedPlans,
    FactorCode.behaviourNoActionYet,
    FactorCode.reliefRest,
    FactorCode.reliefDistraction,
    FactorCode.reliefMovement,
    FactorCode.reliefRoutine,
    FactorCode.reliefConnection,
    FactorCode.reliefQuiet,
    FactorCode.reliefNone,
  };

  const strengthCodes = {
    FactorCode.strengthShowedUp,
    FactorCode.strengthTookBreak,
    FactorCode.strengthAskedForHelp,
    FactorCode.strengthResilience,
  };

  const labels = {
    FactorCode.symptomPain: 'Pain',
    FactorCode.symptomDizziness: 'Dizziness',
    FactorCode.symptomNausea: 'Nausea',
    FactorCode.symptomBreathlessness: 'Breathlessness',
    FactorCode.symptomHeadache: 'Headache',
    FactorCode.symptomGeneral: 'Symptoms',
    FactorCode.durationOnsetRecent: 'Recently started',
    FactorCode.durationDaysWeeks: 'Days or weeks',
    FactorCode.durationMonthsPlus: 'Months or longer',
    FactorCode.patternRecurring: 'Keeps recurring',
    FactorCode.durationToday: 'Started today',
    FactorCode.durationFewDays: 'A few days',
    FactorCode.durationWeekPlus: 'Week or more',
    FactorCode.severityMild: 'Mild impact',
    FactorCode.severityModerate: 'Moderate impact',
    FactorCode.severitySevere: 'Severe impact',
    FactorCode.trendBetter: 'Getting better',
    FactorCode.trendWorse: 'Getting worse',
    FactorCode.trendSame: 'About the same',
    FactorCode.medicalChronicConditionMentioned: 'Long-term condition',
    FactorCode.medicalMedsMentioned: 'Medication mentioned',
    FactorCode.medicalTestsMentioned: 'Tests or scans mentioned',
    FactorCode.medicalCareVisit: 'Recent care visit',
    FactorCode.emotionAnxietyStress: 'Anxiety or stress',
    FactorCode.emotionLowMood: 'Low mood',
    FactorCode.emotionPanic: 'Panic symptoms',
    FactorCode.capacityFatigue: 'Low energy',
    FactorCode.capacityPoorSleep: 'Poor sleep',
    FactorCode.capacityLowFocus: 'Low focus',
    FactorCode.accessCostBarrier: 'Care costs',
    FactorCode.accessAppointmentBarrier: 'Appointments hard to access',
    FactorCode.resourceFinancialStrain: 'Money pressure',
    FactorCode.resourceTimePressure: 'Time pressure',
    FactorCode.resourceCaregivingLoad: 'Caring responsibilities',
    FactorCode.safetyRedFlag: 'Safety concern',
    FactorCode.safetySelfHarm: 'Safety support needed',
    FactorCode.envAirQualityExposure: 'Environmental exposure',
    FactorCode.socialSupportLimited: 'Limited support',
    FactorCode.knowledgeNeedsInformation: 'Needs more information',
    FactorCode.goalSymptomRelief: 'Wants symptom relief',
    FactorCode.goalBehaviourChange: 'Wants a change in habits',
    FactorCode.behaviourRested: 'Rested',
    FactorCode.behaviourPushedThrough: 'Pushed through',
    FactorCode.behaviourChangedPlans: 'Changed plans',
    FactorCode.behaviourNoActionYet: 'Nothing yet',
    FactorCode.reliefRest: 'Rest helped',
    FactorCode.reliefDistraction: 'Distraction helped',
    FactorCode.reliefMovement: 'Movement helped',
    FactorCode.reliefRoutine: 'Routine helped',
    FactorCode.reliefConnection: 'Connection helped',
    FactorCode.reliefQuiet: 'Quiet helped',
    FactorCode.reliefNone: 'Nothing helped',
    FactorCode.strengthShowedUp: 'Showed up',
    FactorCode.strengthTookBreak: 'Took a break',
    FactorCode.strengthAskedForHelp: 'Asked for help',
    FactorCode.strengthResilience: 'Resilience',
  };

  final seen = <FactorCode>{};
  final unique = <UsedFactor>[];
  for (final item in used) {
    if (seen.contains(item.code)) continue;
    seen.add(item.code);
    unique.add(item);
  }

  final chips = unique.map((item) {
    final label = labels[item.code] ?? item.code.code.toLowerCase();
    final group = strengthCodes.contains(item.code)
        ? 'Strengths'
        : actionCodes.contains(item.code)
            ? 'Actions'
            : bodySignalCodes.contains(item.code)
                ? 'Body signals'
                : constraintCodes.contains(item.code)
                    ? 'Constraints'
                    : contextCodes.contains(item.code)
                        ? 'Context'
                        : 'Context';
    return UsedFactorChip(
      group: group,
      label: label,
      code: item.code,
      confidence: item.confidence,
    );
  }).toList();

  double groupBoost(String group) {
    switch (group) {
      case 'Strengths':
        return 0.12;
      case 'Actions':
        return 0.08;
      case 'Body signals':
        return 0.2;
      case 'Constraints':
        return 0.15;
      case 'Context':
      default:
        return 0;
    }
  }

  chips.sort((left, right) {
    final scoreLeft = left.confidence + groupBoost(left.group);
    final scoreRight = right.confidence + groupBoost(right.group);
    if (scoreRight != scoreLeft) {
      return scoreRight.compareTo(scoreLeft);
    }
    if (left.group != right.group) {
      return left.group.compareTo(right.group);
    }
    return left.label.compareTo(right.label);
  });

  return chips.toList();
}

String buildDebugSummary(StateSnapshot snapshot) {
  final buffer = StringBuffer();
  buffer.writeln('risk=${snapshot.riskBand.name}');
  buffer.writeln('friction=${snapshot.frictionBand.name}');
  buffer.writeln('uncertainty=${snapshot.uncertaintyBand.name}');
  return buffer.toString();
}

String buildOrientationSummary(StateSnapshot snapshot) {
  if (snapshot.whatMatters.isEmpty) return 'Not enough detail yet.';
  return snapshot.whatMatters.first;
}

int clampInt(int value, {int min = 0, int? max}) {
  if (value < min) return min;
  if (max != null && value > max) return max;
  return value;
}

int clampListLength(int value, int limit) => min(value, limit);
