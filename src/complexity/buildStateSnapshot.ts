import { ComplexityDomain, COMPLEXITY_DOMAIN_META } from "./domains";
import { DomainClassificationResult, EventIntent } from "./types";
import { Event } from "./events";
import { Factor, FactorCode } from "./factors";
import { ComplexityProfile } from "./profile";
import {
  FrictionBand,
  NextActionKind,
  RiskBand,
  StateSnapshot,
  UncertaintyBand,
} from "./state";

type ExtractedPayload = {
  factors: Factor[];
  missing_info?: Array<{
    key: string;
    question: string;
    domain: ComplexityDomain;
    priority: "low" | "medium" | "high";
  }>;
};

type UsedFactor = {
  code: FactorCode;
  domain: ComplexityDomain;
  confidence: number;
};

const SAFETY_CODES = new Set<FactorCode>([
  FactorCode.SAFETY_RED_FLAG,
  FactorCode.SAFETY_SELF_HARM,
]);

const HIGH_FRICTION_CODES = new Set<FactorCode>([
  FactorCode.ACCESS_COST_BARRIER,
  FactorCode.ACCESS_APPOINTMENT_BARRIER,
  FactorCode.RESOURCE_TIME_PRESSURE,
  FactorCode.RESOURCE_CAREGIVING_LOAD,
  FactorCode.CAPACITY_FATIGUE,
  FactorCode.CAPACITY_POOR_SLEEP,
]);

const MEDIUM_FRICTION_CODES = new Set<FactorCode>([
  FactorCode.RESOURCE_FINANCIAL_STRAIN,
  FactorCode.CAPACITY_LOW_FOCUS,
  FactorCode.SOCIAL_SUPPORT_LIMITED,
]);

const HIGH_RISK_CODES = new Set<FactorCode>([
  FactorCode.SYMPTOM_BREATHLESSNESS,
  FactorCode.SYMPTOM_DIZZINESS,
]);

const MEDIUM_RISK_CODES = new Set<FactorCode>([
  FactorCode.SYMPTOM_PAIN,
  FactorCode.SYMPTOM_HEADACHE,
  FactorCode.SYMPTOM_NAUSEA,
  FactorCode.EMOTION_PANIC,
  FactorCode.EMOTION_ANXIETY_STRESS,
]);

const DOMAIN_PRIORITY: ComplexityDomain[] = [
  ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
  ComplexityDomain.RESOURCES_CONSTRAINTS,
  ComplexityDomain.ACCESS_TO_CARE,
  ComplexityDomain.CAPACITY_ENERGY,
  ComplexityDomain.MENTAL_EMOTIONAL_STATE,
  ComplexityDomain.DURATION_PATTERN,
  ComplexityDomain.MEDICAL_CONTEXT,
  ComplexityDomain.ENVIRONMENT_EXPOSURES,
  ComplexityDomain.SOCIAL_SUPPORT_CONTEXT,
  ComplexityDomain.KNOWLEDGE_BELIEFS_PREFERENCES,
  ComplexityDomain.GOALS_INTENT,
  ComplexityDomain.UNKNOWN_OTHER,
];

const BULLET_COPY: Record<FactorCode, string> = {
  [FactorCode.SYMPTOM_PAIN]: "Pain is showing up.",
  [FactorCode.SYMPTOM_DIZZINESS]: "Dizziness is present.",
  [FactorCode.SYMPTOM_NAUSEA]: "Feeling nauseous is part of this.",
  [FactorCode.SYMPTOM_BREATHLESSNESS]: "Breathlessness is affecting you.",
  [FactorCode.SYMPTOM_HEADACHE]: "Headache is bothering you.",
  [FactorCode.DURATION_ONSET_RECENT]: "This started recently.",
  [FactorCode.DURATION_DAYS_WEEKS]: "This has been going on for days or weeks.",
  [FactorCode.DURATION_MONTHS_PLUS]:
    "This has been going on for months or longer.",
  [FactorCode.PATTERN_RECURRING]: "It keeps coming back.",
  [FactorCode.MEDICAL_CHRONIC_CONDITION_MENTIONED]:
    "A long-term condition is part of the picture.",
  [FactorCode.MEDICAL_MEDS_MENTIONED]: "Medication is involved.",
  [FactorCode.MEDICAL_TESTS_MENTIONED]: "Tests or scans are in play.",
  [FactorCode.MEDICAL_CARE_VISIT]: "You've been in touch with care recently.",
  [FactorCode.EMOTION_ANXIETY_STRESS]: "Anxiety or stress is present.",
  [FactorCode.EMOTION_LOW_MOOD]: "Low mood is weighing on you.",
  [FactorCode.EMOTION_PANIC]: "Panic symptoms are showing up.",
  [FactorCode.CAPACITY_FATIGUE]: "Energy is low right now.",
  [FactorCode.CAPACITY_POOR_SLEEP]: "Sleep has been disrupted.",
  [FactorCode.CAPACITY_LOW_FOCUS]: "Focus is hard at the moment.",
  [FactorCode.ACCESS_COST_BARRIER]: "Cost is getting in the way of care.",
  [FactorCode.ACCESS_APPOINTMENT_BARRIER]:
    "Appointments are hard to access.",
  [FactorCode.RESOURCE_FINANCIAL_STRAIN]:
    "Money pressure is affecting options.",
  [FactorCode.RESOURCE_TIME_PRESSURE]:
    "Time pressure is limiting what you can do.",
  [FactorCode.RESOURCE_CAREGIVING_LOAD]:
    "Caring responsibilities are heavy.",
  [FactorCode.SAFETY_RED_FLAG]: "A safety concern was mentioned.",
  [FactorCode.SAFETY_SELF_HARM]:
    "Safety is a priority based on what you shared.",
  [FactorCode.ENV_AIR_QUALITY_EXPOSURE]:
    "Environment or air quality is a concern.",
  [FactorCode.SOCIAL_SUPPORT_LIMITED]: "Support feels limited.",
  [FactorCode.KNOWLEDGE_NEEDS_INFORMATION]: "More information would help.",
  [FactorCode.GOAL_SYMPTOM_RELIEF]: "You want relief from symptoms.",
  [FactorCode.GOAL_BEHAVIOUR_CHANGE]: "You want to make a behaviour change.",
};

const uniqueByCode = (factors: Factor[]): Factor[] => {
  const seen = new Set<FactorCode>();
  const result: Factor[] = [];
  for (const factor of factors) {
    if (seen.has(factor.code)) continue;
    seen.add(factor.code);
    result.push(factor);
  }
  return result;
};

const priorityForDomain = (domain: ComplexityDomain): number => {
  const index = DOMAIN_PRIORITY.indexOf(domain);
  return index === -1 ? DOMAIN_PRIORITY.length : index;
};

const sortForWhatMatters = (factors: Factor[]): Factor[] =>
  [...factors].sort((left, right) => {
    const domainDelta =
      priorityForDomain(left.domain) - priorityForDomain(right.domain);
    if (domainDelta !== 0) return domainDelta;
    if (right.confidence !== left.confidence) {
      return right.confidence - left.confidence;
    }
    return right.created_at.localeCompare(left.created_at);
  });

const summariseUsedFactors = (factors: Factor[]): UsedFactor[] =>
  uniqueByCode(factors).map((factor) => ({
    code: factor.code,
    domain: factor.domain,
    confidence: factor.confidence,
  }));

const selectHighestPriorityMissingInfo = (
  missing?: ExtractedPayload["missing_info"],
): ExtractedPayload["missing_info"][number] | undefined => {
  if (!missing || missing.length === 0) return undefined;
  const priorityRank = { high: 0, medium: 1, low: 2 };
  return [...missing].sort(
    (a, b) => priorityRank[a.priority] - priorityRank[b.priority],
  )[0];
};

const computeRiskBand = (
  factors: Factor[],
  domainResult: DomainClassificationResult,
  used: Factor[],
): RiskBand => {
  const hasSafetyDomain =
    domainResult.primary.domain === ComplexityDomain.SAFETY_RISK ||
    domainResult.secondary.some(
      (item) => item.domain === ComplexityDomain.SAFETY_RISK,
    );
  const safetyFactor = factors.find((factor) => SAFETY_CODES.has(factor.code));

  if (hasSafetyDomain || safetyFactor) {
    if (safetyFactor) used.push(safetyFactor);
    return "urgent";
  }

  const highRisk = factors.find(
    (factor) => HIGH_RISK_CODES.has(factor.code) && factor.confidence >= 0.8,
  );
  if (highRisk) {
    used.push(highRisk);
    return "high";
  }

  const mediumRisk = factors.find((factor) =>
    MEDIUM_RISK_CODES.has(factor.code),
  );
  if (mediumRisk) {
    used.push(mediumRisk);
    return "medium";
  }

  return "low";
};

const computeUncertaintyBand = (
  factors: Factor[],
  missing?: ExtractedPayload["missing_info"],
): UncertaintyBand => {
  if (missing && missing.length > 0) {
    return "high";
  }
  if (factors.length === 0) {
    return "medium";
  }
  const average =
    factors.reduce((sum, factor) => sum + factor.confidence, 0) /
    factors.length;
  if (average < 0.7) {
    return "medium";
  }
  return "low";
};

const computeFrictionBand = (
  factors: Factor[],
  used: Factor[],
): FrictionBand => {
  const highFriction = factors.find(
    (factor) =>
      HIGH_FRICTION_CODES.has(factor.code) && factor.confidence >= 0.75,
  );
  if (highFriction) {
    used.push(highFriction);
    return "high";
  }

  const mediumFriction = factors.find(
    (factor) =>
      MEDIUM_FRICTION_CODES.has(factor.code) && factor.confidence >= 0.6,
  );
  if (mediumFriction) {
    used.push(mediumFriction);
    return "medium";
  }

  return "low";
};

const buildWhatMatters = (factors: Factor[], used: Factor[]): string[] => {
  if (factors.length === 0) {
    return ["It is not clear yet what is most important."];
  }

  const ordered = sortForWhatMatters(factors);
  const bullets: string[] = [];

  for (const factor of ordered) {
    const copy = BULLET_COPY[factor.code];
    if (!copy) continue;
    bullets.push(copy);
    used.push(factor);
    if (bullets.length >= 3) break;
  }

  if (bullets.length === 0) {
    const primaryDomainLabel =
      COMPLEXITY_DOMAIN_META[factors[0].domain]?.label ?? "Focus area";
    bullets.push(`${primaryDomainLabel} is the main focus right now.`);
    used.push(factors[0]);
  }

  return bullets.slice(0, 3);
};

export const buildStateSnapshot = (
  event: Event,
  domainResult: DomainClassificationResult,
  extracted: ExtractedPayload,
  profile: ComplexityProfile,
): StateSnapshot => {
  const factors = extracted.factors;
  const usedFactorBuffer: Factor[] = [];

  const risk_band = computeRiskBand(factors, domainResult, usedFactorBuffer);
  const uncertainty_band = computeUncertaintyBand(
    factors,
    extracted.missing_info,
  );
  const friction_band = computeFrictionBand(factors, usedFactorBuffer);

  const what_matters = buildWhatMatters(factors, usedFactorBuffer);
  const used_factors = summariseUsedFactors(usedFactorBuffer);

  const missingInfo = selectHighestPriorityMissingInfo(
    extracted.missing_info,
  );

  let next_action_kind: NextActionKind = "answer";
  if (risk_band === "urgent") {
    next_action_kind = "safety_escalation";
  } else if (event.intent === "LOG_ONLY") {
    next_action_kind = "log_only";
  } else if (uncertainty_band === "high" && missingInfo) {
    next_action_kind = "ask_followup";
  }

  const followup_question =
    next_action_kind === "ask_followup" ? missingInfo?.question : undefined;

  const safety_copy =
    risk_band === "urgent"
      ? "If you are in immediate danger, call 000 or seek urgent care."
      : undefined;

  void profile;

  return {
    event_id: event.id,
    created_at: new Date().toISOString(),
    intent: event.intent as EventIntent,
    risk_band,
    friction_band,
    uncertainty_band,
    next_action_kind,
    what_matters,
    followup_question,
    safety_copy,
    used_factors,
  };
};
