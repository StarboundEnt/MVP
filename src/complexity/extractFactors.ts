import { ComplexityDomain } from "./domains";
import { DomainClassificationResult, EventIntent } from "./types";
import {
  Factor,
  FactorCode,
  FactorModifiability,
  FactorTimeHorizon,
  FactorType,
  MissingInfo,
} from "./factors";

type FactorDefinition = {
  domain: ComplexityDomain;
  type: FactorType;
  modifiability: FactorModifiability;
  defaultTimeHorizon: FactorTimeHorizon;
};

type MatchResult = {
  matched: boolean;
  confidence: number;
};

const MIN_FACTOR_CONFIDENCE = 0.6;

const FACTOR_DEFINITIONS: Record<FactorCode, FactorDefinition> = {
  [FactorCode.SYMPTOM_PAIN]: {
    domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.SYMPTOM_DIZZINESS]: {
    domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.SYMPTOM_NAUSEA]: {
    domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.SYMPTOM_BREATHLESSNESS]: {
    domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.SYMPTOM_HEADACHE]: {
    domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.DURATION_ONSET_RECENT]: {
    domain: ComplexityDomain.DURATION_PATTERN,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "acute",
  },
  [FactorCode.DURATION_DAYS_WEEKS]: {
    domain: ComplexityDomain.DURATION_PATTERN,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "acute",
  },
  [FactorCode.DURATION_MONTHS_PLUS]: {
    domain: ComplexityDomain.DURATION_PATTERN,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "chronic",
  },
  [FactorCode.PATTERN_RECURRING]: {
    domain: ComplexityDomain.DURATION_PATTERN,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "chronic",
  },
  [FactorCode.MEDICAL_CHRONIC_CONDITION_MENTIONED]: {
    domain: ComplexityDomain.MEDICAL_CONTEXT,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "chronic",
  },
  [FactorCode.MEDICAL_MEDS_MENTIONED]: {
    domain: ComplexityDomain.MEDICAL_CONTEXT,
    type: FactorType.CONSTRAINED_CHOICE,
    modifiability: "medium",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.MEDICAL_TESTS_MENTIONED]: {
    domain: ComplexityDomain.MEDICAL_CONTEXT,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.MEDICAL_CARE_VISIT]: {
    domain: ComplexityDomain.MEDICAL_CONTEXT,
    type: FactorType.CONSTRAINED_CHOICE,
    modifiability: "medium",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.EMOTION_ANXIETY_STRESS]: {
    domain: ComplexityDomain.MENTAL_EMOTIONAL_STATE,
    type: FactorType.CHANCE,
    modifiability: "medium",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.EMOTION_LOW_MOOD]: {
    domain: ComplexityDomain.MENTAL_EMOTIONAL_STATE,
    type: FactorType.CHANCE,
    modifiability: "medium",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.EMOTION_PANIC]: {
    domain: ComplexityDomain.MENTAL_EMOTIONAL_STATE,
    type: FactorType.CHANCE,
    modifiability: "medium",
    defaultTimeHorizon: "acute",
  },
  [FactorCode.CAPACITY_FATIGUE]: {
    domain: ComplexityDomain.CAPACITY_ENERGY,
    type: FactorType.CHANCE,
    modifiability: "medium",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.CAPACITY_POOR_SLEEP]: {
    domain: ComplexityDomain.CAPACITY_ENERGY,
    type: FactorType.CHANCE,
    modifiability: "medium",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.CAPACITY_LOW_FOCUS]: {
    domain: ComplexityDomain.CAPACITY_ENERGY,
    type: FactorType.CHANCE,
    modifiability: "medium",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.ACCESS_COST_BARRIER]: {
    domain: ComplexityDomain.ACCESS_TO_CARE,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.ACCESS_APPOINTMENT_BARRIER]: {
    domain: ComplexityDomain.ACCESS_TO_CARE,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.RESOURCE_FINANCIAL_STRAIN]: {
    domain: ComplexityDomain.RESOURCES_CONSTRAINTS,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "chronic",
  },
  [FactorCode.RESOURCE_TIME_PRESSURE]: {
    domain: ComplexityDomain.RESOURCES_CONSTRAINTS,
    type: FactorType.CHANCE,
    modifiability: "medium",
    defaultTimeHorizon: "acute",
  },
  [FactorCode.RESOURCE_CAREGIVING_LOAD]: {
    domain: ComplexityDomain.RESOURCES_CONSTRAINTS,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "life_course",
  },
  [FactorCode.SAFETY_RED_FLAG]: {
    domain: ComplexityDomain.SAFETY_RISK,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "acute",
  },
  [FactorCode.SAFETY_SELF_HARM]: {
    domain: ComplexityDomain.SAFETY_RISK,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "acute",
  },
  [FactorCode.ENV_AIR_QUALITY_EXPOSURE]: {
    domain: ComplexityDomain.ENVIRONMENT_EXPOSURES,
    type: FactorType.CHANCE,
    modifiability: "low",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.SOCIAL_SUPPORT_LIMITED]: {
    domain: ComplexityDomain.SOCIAL_SUPPORT_CONTEXT,
    type: FactorType.CHANCE,
    modifiability: "medium",
    defaultTimeHorizon: "chronic",
  },
  [FactorCode.KNOWLEDGE_NEEDS_INFORMATION]: {
    domain: ComplexityDomain.KNOWLEDGE_BELIEFS_PREFERENCES,
    type: FactorType.CHOICE,
    modifiability: "high",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.GOAL_SYMPTOM_RELIEF]: {
    domain: ComplexityDomain.GOALS_INTENT,
    type: FactorType.CHOICE,
    modifiability: "high",
    defaultTimeHorizon: "unknown",
  },
  [FactorCode.GOAL_BEHAVIOUR_CHANGE]: {
    domain: ComplexityDomain.GOALS_INTENT,
    type: FactorType.CHOICE,
    modifiability: "high",
    defaultTimeHorizon: "unknown",
  },
};

const NORMALISE_REGEX = /[^a-z0-9\s]/g;

const normaliseText = (input: string): string =>
  input
    .toLowerCase()
    .replace(/'/g, "")
    .replace(NORMALISE_REGEX, " ")
    .replace(/\s+/g, " ")
    .trim();

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const matchKeywords = (text: string, keywords: string[]): MatchResult => {
  for (const keyword of keywords) {
    const pattern = new RegExp(`\\b${escapeRegExp(keyword)}\\b`);
    if (pattern.test(text)) {
      return { matched: true, confidence: 0.7 };
    }
  }
  return { matched: false, confidence: 0 };
};

const matchPhrases = (text: string, phrases: string[], confidence = 0.8): MatchResult => {
  for (const phrase of phrases) {
    if (text.includes(phrase)) {
      return { matched: true, confidence };
    }
  }
  return { matched: false, confidence: 0 };
};

const matchEither = (
  text: string,
  phrases: string[],
  keywords: string[],
  phraseConfidence = 0.8,
): MatchResult => {
  const phraseMatch = matchPhrases(text, phrases, phraseConfidence);
  if (phraseMatch.matched) {
    return phraseMatch;
  }
  return matchKeywords(text, keywords);
};

const buildAllowedDomains = (
  domainResult: DomainClassificationResult,
): Set<ComplexityDomain> => {
  const allowed = new Set<ComplexityDomain>();
  const primary = domainResult.primary.domain;
  if (primary === ComplexityDomain.UNKNOWN_OTHER) {
    Object.values(ComplexityDomain).forEach((domain) => allowed.add(domain));
    return allowed;
  }
  allowed.add(primary);
  for (const secondary of domainResult.secondary) {
    allowed.add(secondary.domain);
  }
  allowed.add(ComplexityDomain.SAFETY_RISK);
  if (allowed.has(ComplexityDomain.SYMPTOMS_BODY_SIGNALS)) {
    allowed.add(ComplexityDomain.DURATION_PATTERN);
  }
  return allowed;
};

const isAmbiguousText = (text: string): boolean => {
  const markers = [
    "not sure",
    "hard to explain",
    "dont know",
    "no idea",
    "unsure",
    "confused",
  ];
  return markers.some((marker) => text.includes(marker));
};

const detectDuration = (
  text: string,
): Array<{
  code: FactorCode;
  confidence: number;
  timeHorizon: FactorTimeHorizon;
  value: string;
}> => {
  const results: Array<{
    code: FactorCode;
    confidence: number;
    timeHorizon: FactorTimeHorizon;
    value: string;
  }> = [];

  const onsetMatch = matchPhrases(text, [
    "just started",
    "started today",
    "since yesterday",
    "since last night",
    "this morning",
    "sudden",
    "suddenly",
  ], 0.75);
  if (onsetMatch.matched) {
    results.push({
      code: FactorCode.DURATION_ONSET_RECENT,
      confidence: onsetMatch.confidence,
      timeHorizon: "acute",
      value: "recent_onset",
    });
  }

  const numericMatch = text.match(
    /\b(\d+|few|couple)\s+(day|days|week|weeks|month|months|year|years)\b/,
  );
  if (numericMatch) {
    const unit = numericMatch[2];
    if (unit.startsWith("month") || unit.startsWith("year")) {
      results.push({
        code: FactorCode.DURATION_MONTHS_PLUS,
        confidence: 0.8,
        timeHorizon: unit.startsWith("year") ? "life_course" : "chronic",
        value: unit.startsWith("year") ? "years_plus" : "months_plus",
      });
    } else {
      results.push({
        code: FactorCode.DURATION_DAYS_WEEKS,
        confidence: 0.75,
        timeHorizon: "acute",
        value: "days_weeks",
      });
    }
  }

  const phraseDaysWeeks = matchPhrases(text, [
    "for days",
    "for weeks",
    "last week",
    "past few days",
    "this week",
  ], 0.7);
  if (phraseDaysWeeks.matched) {
    results.push({
      code: FactorCode.DURATION_DAYS_WEEKS,
      confidence: phraseDaysWeeks.confidence,
      timeHorizon: "acute",
      value: "days_weeks",
    });
  }

  const phraseMonthsPlus = matchPhrases(text, [
    "for months",
    "for years",
    "long term",
    "long-term",
    "ongoing",
  ], 0.75);
  if (phraseMonthsPlus.matched) {
    results.push({
      code: FactorCode.DURATION_MONTHS_PLUS,
      confidence: phraseMonthsPlus.confidence,
      timeHorizon: text.includes("year") ? "life_course" : "chronic",
      value: text.includes("year") ? "years_plus" : "months_plus",
    });
  }

  const recurringMatch = matchPhrases(text, [
    "on and off",
    "keeps coming back",
    "recurring",
    "every day",
    "every week",
    "most days",
    "regularly",
  ], 0.7);
  if (recurringMatch.matched) {
    results.push({
      code: FactorCode.PATTERN_RECURRING,
      confidence: recurringMatch.confidence,
      timeHorizon: "chronic",
      value: "recurring",
    });
  }

  return results;
};

const detectSafety = (text: string): FactorCode | null => {
  const selfHarmPhrases = [
    "suicidal",
    "suicide",
    "self harm",
    "kill myself",
    "end my life",
  ];
  if (selfHarmPhrases.some((phrase) => text.includes(phrase))) {
    return FactorCode.SAFETY_SELF_HARM;
  }

  const redFlags = [
    "chest pain",
    "trouble breathing",
    "shortness of breath",
    "cant breathe",
    "severe bleeding",
    "bleeding heavily",
    "passed out",
    "fainting",
    "face droop",
    "slurred speech",
    "weakness on one side",
    "sudden severe headache",
  ];
  if (redFlags.some((phrase) => text.includes(phrase))) {
    return FactorCode.SAFETY_RED_FLAG;
  }
  return null;
};

export const extractFactors = (
  inputText: string,
  domainResult: DomainClassificationResult,
  intent: EventIntent,
  eventId: string,
): { factors: Factor[]; missing_info?: MissingInfo[] } => {
  const text = normaliseText(inputText);
  const allowedDomains = buildAllowedDomains(domainResult);
  const factors = new Map<FactorCode, Factor>();
  let factorIndex = 0;
  let weakSignalDetected = false;

  const addFactor = (
    code: FactorCode,
    confidence: number,
    value: boolean | number | string = true,
    timeHorizon?: FactorTimeHorizon,
  ) => {
    if (confidence < MIN_FACTOR_CONFIDENCE) {
      if (confidence > 0) {
        weakSignalDetected = true;
      }
      return;
    }
    const definition = FACTOR_DEFINITIONS[code];
    if (!definition) return;
    if (!allowedDomains.has(definition.domain)) {
      return;
    }

    const existing = factors.get(code);
    if (existing && existing.confidence >= confidence) {
      return;
    }

    factors.set(code, {
      id: `factor_${eventId}_${factorIndex++}`,
      domain: definition.domain,
      type: definition.type,
      code,
      value,
      confidence,
      time_horizon: timeHorizon ?? definition.defaultTimeHorizon,
      modifiability: definition.modifiability,
      source_event_id: eventId,
      created_at: new Date().toISOString(),
    });
  };

  const safetyCode = detectSafety(text);
  if (safetyCode) {
    addFactor(safetyCode, 0.95);
    if (safetyCode === FactorCode.SAFETY_SELF_HARM) {
      addFactor(FactorCode.SAFETY_RED_FLAG, 0.85);
    }
  }

  addFactor(
    FactorCode.SYMPTOM_PAIN,
    matchEither(
      text,
      ["sharp pain", "severe pain", "aching pain"],
      ["pain", "ache", "sore", "cramp", "cramps"],
      0.85,
    ).confidence,
  );
  addFactor(
    FactorCode.SYMPTOM_DIZZINESS,
    matchEither(text, ["light headed", "lightheaded"], ["dizzy", "dizziness", "spinning"], 0.8)
      .confidence,
  );
  addFactor(
    FactorCode.SYMPTOM_NAUSEA,
    matchEither(text, ["feel sick", "feel nauseous"], ["nausea", "nauseous", "queasy", "vomit", "vomiting"], 0.8)
      .confidence,
  );
  addFactor(
    FactorCode.SYMPTOM_BREATHLESSNESS,
    matchEither(text, ["shortness of breath", "trouble breathing", "cant breathe"], ["breathless"], 0.85)
      .confidence,
  );
  addFactor(
    FactorCode.SYMPTOM_HEADACHE,
    matchEither(text, ["headache", "migraine"], ["headache", "migraine"], 0.8).confidence,
  );

  for (const duration of detectDuration(text)) {
    addFactor(
      duration.code,
      duration.confidence,
      duration.value,
      duration.timeHorizon,
    );
  }

  addFactor(
    FactorCode.MEDICAL_CHRONIC_CONDITION_MENTIONED,
    matchPhrases(text, ["chronic condition", "long term condition", "long-term condition", "ongoing condition"], 0.75)
      .confidence,
  );
  addFactor(
    FactorCode.MEDICAL_MEDS_MENTIONED,
    matchEither(
      text,
      ["taking medication", "on medication"],
      ["medication", "meds", "prescription", "dose", "tablet", "pill"],
      0.8,
    ).confidence,
  );
  addFactor(
    FactorCode.MEDICAL_TESTS_MENTIONED,
    matchEither(
      text,
      ["blood test", "test results", "scan results"],
      ["test", "tests", "xray", "x ray", "mri", "ct", "ultrasound", "scan"],
      0.75,
    ).confidence,
  );
  addFactor(
    FactorCode.MEDICAL_CARE_VISIT,
    matchEither(
      text,
      ["saw my gp", "visited the clinic", "hospital visit"],
      ["gp", "doctor", "clinic", "hospital", "physio", "counselling", "therapy", "appointment"],
      0.75,
    ).confidence,
  );

  addFactor(
    FactorCode.EMOTION_ANXIETY_STRESS,
    matchEither(
      text,
      ["feeling anxious", "feeling stressed", "overwhelmed"],
      ["anxious", "anxiety", "stress", "stressed", "overwhelmed", "on edge"],
      0.8,
    ).confidence,
  );
  addFactor(
    FactorCode.EMOTION_LOW_MOOD,
    matchEither(
      text,
      ["low mood", "feeling down"],
      ["sad", "down", "depressed", "hopeless"],
      0.75,
    ).confidence,
  );
  addFactor(
    FactorCode.EMOTION_PANIC,
    matchEither(
      text,
      ["panic attack", "panic attacks"],
      ["panic"],
      0.85,
    ).confidence,
  );

  addFactor(
    FactorCode.CAPACITY_FATIGUE,
    matchEither(
      text,
      ["no energy", "completely drained"],
      ["tired", "fatigue", "fatigued", "exhausted", "drained"],
      0.8,
    ).confidence,
  );
  addFactor(
    FactorCode.CAPACITY_POOR_SLEEP,
    matchEither(
      text,
      ["poor sleep", "cant sleep", "can't sleep", "sleeping badly"],
      ["insomnia", "waking up", "sleep problems"],
      0.8,
    ).confidence,
  );
  addFactor(
    FactorCode.CAPACITY_LOW_FOCUS,
    matchEither(
      text,
      ["cant focus", "can't focus", "brain fog"],
      ["foggy", "distracted", "low focus"],
      0.75,
    ).confidence,
  );

  const careTerms = ["gp", "doctor", "clinic", "hospital", "appointment", "specialist", "telehealth"];
  const hasCareTerm = matchKeywords(text, careTerms).matched;

  const costBarrierMatch = matchEither(
    text,
    ["cant afford", "can't afford", "too expensive", "no bulk billing", "gap fee"],
    ["expensive", "cost"],
    0.85,
  );
  if (costBarrierMatch.matched && hasCareTerm) {
    addFactor(FactorCode.ACCESS_COST_BARRIER, costBarrierMatch.confidence);
  }

  const appointmentBarrierMatch = matchEither(
    text,
    ["cant get appointment", "can't get appointment", "no appointments", "booked out", "long wait", "waitlist"],
    ["wait", "waiting"],
    0.8,
  );
  if (appointmentBarrierMatch.matched) {
    addFactor(FactorCode.ACCESS_APPOINTMENT_BARRIER, appointmentBarrierMatch.confidence);
  }

  addFactor(
    FactorCode.RESOURCE_FINANCIAL_STRAIN,
    matchEither(
      text,
      ["cant afford", "can't afford", "rent overdue", "bills piling up", "cost of living"],
      ["money", "rent", "bills", "debt", "budget", "afford"],
      0.75,
    ).confidence,
  );
  addFactor(
    FactorCode.RESOURCE_TIME_PRESSURE,
    matchEither(
      text,
      ["no time", "time pressure", "too busy", "time poor", "time-poor"],
      ["deadline", "overbooked", "shift work", "busy"],
      0.7,
    ).confidence,
  );
  addFactor(
    FactorCode.RESOURCE_CAREGIVING_LOAD,
    matchEither(
      text,
      ["caring for", "looking after", "caring responsibilities"],
      ["carer", "caregiver", "kids", "children", "childcare", "elderly", "parent"],
      0.75,
    ).confidence,
  );

  addFactor(
    FactorCode.ENV_AIR_QUALITY_EXPOSURE,
    matchEither(
      text,
      ["air quality", "second hand smoke"],
      ["smoke", "mould", "mold", "pollution", "fumes", "dust", "pollen"],
      0.75,
    ).confidence,
  );

  addFactor(
    FactorCode.SOCIAL_SUPPORT_LIMITED,
    matchEither(
      text,
      ["no support", "no one", "living alone"],
      ["alone", "isolated", "lonely"],
      0.7,
    ).confidence,
  );

  addFactor(
    FactorCode.KNOWLEDGE_NEEDS_INFORMATION,
    matchEither(
      text,
      ["need more information", "dont understand", "don't understand"],
      ["not sure", "unsure", "confused"],
      0.7,
    ).confidence,
  );

  addFactor(
    FactorCode.GOAL_SYMPTOM_RELIEF,
    matchEither(
      text,
      ["feel better", "relief", "ease symptoms", "reduce pain"],
      ["improve symptoms", "help with pain"],
      0.7,
    ).confidence,
  );
  addFactor(
    FactorCode.GOAL_BEHAVIOUR_CHANGE,
    matchEither(
      text,
      ["want to", "trying to", "plan to", "aim to", "goal is"],
      ["build a routine", "start exercising", "improve sleep"],
      0.65,
    ).confidence,
  );

  const factorList = Array.from(factors.values());
  const onlyKnowledgeFactor =
    factorList.length === 1 &&
    factorList[0].code === FactorCode.KNOWLEDGE_NEEDS_INFORMATION;

  let missingInfo: MissingInfo | undefined;
  const symptomCodes = new Set<FactorCode>([
    FactorCode.SYMPTOM_PAIN,
    FactorCode.SYMPTOM_DIZZINESS,
    FactorCode.SYMPTOM_NAUSEA,
    FactorCode.SYMPTOM_BREATHLESSNESS,
    FactorCode.SYMPTOM_HEADACHE,
  ]);
  const durationCodes = new Set<FactorCode>([
    FactorCode.DURATION_ONSET_RECENT,
    FactorCode.DURATION_DAYS_WEEKS,
    FactorCode.DURATION_MONTHS_PLUS,
    FactorCode.PATTERN_RECURRING,
  ]);

  const hasSymptom = factorList.some((factor) => symptomCodes.has(factor.code));
  const hasDuration = factorList.some((factor) => durationCodes.has(factor.code));

  if (hasSymptom && !hasDuration && intent !== "FOLLOW_UP") {
    missingInfo = {
      key: "duration",
      question: "How long has this been going on?",
      domain: ComplexityDomain.DURATION_PATTERN,
      priority: "high",
    };
  } else if (
    (factorList.length === 0 || onlyKnowledgeFactor) &&
    (weakSignalDetected || isAmbiguousText(text))
  ) {
    missingInfo = {
      key: "clarify",
      question: "What feels most important to focus on right now?",
      domain: domainResult.primary.domain ?? ComplexityDomain.UNKNOWN_OTHER,
      priority: "medium",
    };
  }

  if (missingInfo) {
    return {
      factors: onlyKnowledgeFactor ? [] : factorList,
      missing_info: [missingInfo],
    };
  }

  return { factors: factorList };
};
