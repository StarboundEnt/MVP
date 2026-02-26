import { FactorCode } from "./factors";
import { StateSnapshot } from "./state";

export type UsedFactorChip = {
  group: "Body signals" | "Constraints" | "Context";
  label: string;
  code: FactorCode;
  confidence: number;
};

const BODY_SIGNAL_CODES = new Set<FactorCode>([
  FactorCode.SYMPTOM_PAIN,
  FactorCode.SYMPTOM_DIZZINESS,
  FactorCode.SYMPTOM_NAUSEA,
  FactorCode.SYMPTOM_BREATHLESSNESS,
  FactorCode.SYMPTOM_HEADACHE,
  FactorCode.DURATION_ONSET_RECENT,
  FactorCode.DURATION_DAYS_WEEKS,
  FactorCode.DURATION_MONTHS_PLUS,
  FactorCode.PATTERN_RECURRING,
  FactorCode.SAFETY_RED_FLAG,
  FactorCode.SAFETY_SELF_HARM,
]);

const CONSTRAINT_CODES = new Set<FactorCode>([
  FactorCode.ACCESS_COST_BARRIER,
  FactorCode.ACCESS_APPOINTMENT_BARRIER,
  FactorCode.RESOURCE_FINANCIAL_STRAIN,
  FactorCode.RESOURCE_TIME_PRESSURE,
  FactorCode.RESOURCE_CAREGIVING_LOAD,
  FactorCode.CAPACITY_FATIGUE,
  FactorCode.CAPACITY_POOR_SLEEP,
  FactorCode.CAPACITY_LOW_FOCUS,
]);

const CONTEXT_CODES = new Set<FactorCode>([
  FactorCode.MEDICAL_CHRONIC_CONDITION_MENTIONED,
  FactorCode.MEDICAL_MEDS_MENTIONED,
  FactorCode.MEDICAL_TESTS_MENTIONED,
  FactorCode.MEDICAL_CARE_VISIT,
  FactorCode.EMOTION_ANXIETY_STRESS,
  FactorCode.EMOTION_LOW_MOOD,
  FactorCode.EMOTION_PANIC,
  FactorCode.ENV_AIR_QUALITY_EXPOSURE,
  FactorCode.SOCIAL_SUPPORT_LIMITED,
  FactorCode.KNOWLEDGE_NEEDS_INFORMATION,
  FactorCode.GOAL_SYMPTOM_RELIEF,
  FactorCode.GOAL_BEHAVIOUR_CHANGE,
]);

const CODE_LABELS: Record<FactorCode, string> = {
  [FactorCode.SYMPTOM_PAIN]: "Pain",
  [FactorCode.SYMPTOM_DIZZINESS]: "Dizziness",
  [FactorCode.SYMPTOM_NAUSEA]: "Nausea",
  [FactorCode.SYMPTOM_BREATHLESSNESS]: "Breathlessness",
  [FactorCode.SYMPTOM_HEADACHE]: "Headache",
  [FactorCode.DURATION_ONSET_RECENT]: "Recently started",
  [FactorCode.DURATION_DAYS_WEEKS]: "Days or weeks",
  [FactorCode.DURATION_MONTHS_PLUS]: "Months or longer",
  [FactorCode.PATTERN_RECURRING]: "Keeps recurring",
  [FactorCode.MEDICAL_CHRONIC_CONDITION_MENTIONED]: "Long-term condition",
  [FactorCode.MEDICAL_MEDS_MENTIONED]: "Medication mentioned",
  [FactorCode.MEDICAL_TESTS_MENTIONED]: "Tests or scans mentioned",
  [FactorCode.MEDICAL_CARE_VISIT]: "Recent care visit",
  [FactorCode.EMOTION_ANXIETY_STRESS]: "Anxiety or stress",
  [FactorCode.EMOTION_LOW_MOOD]: "Low mood",
  [FactorCode.EMOTION_PANIC]: "Panic symptoms",
  [FactorCode.CAPACITY_FATIGUE]: "Low energy",
  [FactorCode.CAPACITY_POOR_SLEEP]: "Poor sleep",
  [FactorCode.CAPACITY_LOW_FOCUS]: "Low focus",
  [FactorCode.ACCESS_COST_BARRIER]: "Care costs",
  [FactorCode.ACCESS_APPOINTMENT_BARRIER]: "Appointments hard to access",
  [FactorCode.RESOURCE_FINANCIAL_STRAIN]: "Money pressure",
  [FactorCode.RESOURCE_TIME_PRESSURE]: "Time pressure",
  [FactorCode.RESOURCE_CAREGIVING_LOAD]: "Caring responsibilities",
  [FactorCode.SAFETY_RED_FLAG]: "Safety concern",
  [FactorCode.SAFETY_SELF_HARM]: "Safety support needed",
  [FactorCode.ENV_AIR_QUALITY_EXPOSURE]: "Environmental exposure",
  [FactorCode.SOCIAL_SUPPORT_LIMITED]: "Limited support",
  [FactorCode.KNOWLEDGE_NEEDS_INFORMATION]: "Needs more information",
  [FactorCode.GOAL_SYMPTOM_RELIEF]: "Wants symptom relief",
  [FactorCode.GOAL_BEHAVIOUR_CHANGE]: "Wants a change in habits",
};

const resolveGroup = (code: FactorCode): UsedFactorChip["group"] => {
  if (BODY_SIGNAL_CODES.has(code)) return "Body signals";
  if (CONSTRAINT_CODES.has(code)) return "Constraints";
  if (CONTEXT_CODES.has(code)) return "Context";
  return "Context";
};

const groupBoost = (group: UsedFactorChip["group"]): number => {
  switch (group) {
    case "Body signals":
      return 0.2;
    case "Constraints":
      return 0.15;
    case "Context":
      return 0;
  }
};

const uniqueByCode = (
  used: StateSnapshot["used_factors"],
): StateSnapshot["used_factors"] => {
  const seen = new Set<FactorCode>();
  const result: StateSnapshot["used_factors"] = [];
  for (const item of used) {
    if (seen.has(item.code)) continue;
    seen.add(item.code);
    result.push(item);
  }
  return result;
};

export const formatUsedFactorsForUI = (
  used: StateSnapshot["used_factors"],
): UsedFactorChip[] => {
  const unique = uniqueByCode(used);
  const chips = unique.map((item) => {
    const label = CODE_LABELS[item.code] ?? item.code.toLowerCase();
    const group = resolveGroup(item.code);
    return {
      group,
      label,
      code: item.code,
      confidence: item.confidence,
    };
  });

  chips.sort((left, right) => {
    const scoreLeft = left.confidence + groupBoost(left.group);
    const scoreRight = right.confidence + groupBoost(right.group);
    if (scoreRight !== scoreLeft) {
      return scoreRight - scoreLeft;
    }
    if (left.group !== right.group) {
      return left.group.localeCompare(right.group);
    }
    return left.label.localeCompare(right.label);
  });

  return chips.slice(0, 6);
};
