import { ComplexityDomain } from "./domains";

export enum FactorType {
  CHOICE = "choice",
  CHANCE = "chance",
  CONSTRAINED_CHOICE = "constrained_choice",
}

export type FactorTimeHorizon = "acute" | "chronic" | "life_course" | "unknown";
export type FactorModifiability = "high" | "medium" | "low" | "unknown";
export type FactorValue = boolean | number | string;

// Factors are small, reusable signals that support stable reasoning.
export enum FactorCode {
  SYMPTOM_PAIN = "SYMPTOM_PAIN",
  SYMPTOM_DIZZINESS = "SYMPTOM_DIZZINESS",
  SYMPTOM_NAUSEA = "SYMPTOM_NAUSEA",
  SYMPTOM_BREATHLESSNESS = "SYMPTOM_BREATHLESSNESS",
  SYMPTOM_HEADACHE = "SYMPTOM_HEADACHE",
  DURATION_ONSET_RECENT = "DURATION_ONSET_RECENT",
  DURATION_DAYS_WEEKS = "DURATION_DAYS_WEEKS",
  DURATION_MONTHS_PLUS = "DURATION_MONTHS_PLUS",
  PATTERN_RECURRING = "PATTERN_RECURRING",
  MEDICAL_CHRONIC_CONDITION_MENTIONED = "MEDICAL_CHRONIC_CONDITION_MENTIONED",
  MEDICAL_MEDS_MENTIONED = "MEDICAL_MEDS_MENTIONED",
  MEDICAL_TESTS_MENTIONED = "MEDICAL_TESTS_MENTIONED",
  MEDICAL_CARE_VISIT = "MEDICAL_CARE_VISIT",
  EMOTION_ANXIETY_STRESS = "EMOTION_ANXIETY_STRESS",
  EMOTION_LOW_MOOD = "EMOTION_LOW_MOOD",
  EMOTION_PANIC = "EMOTION_PANIC",
  CAPACITY_FATIGUE = "CAPACITY_FATIGUE",
  CAPACITY_POOR_SLEEP = "CAPACITY_POOR_SLEEP",
  CAPACITY_LOW_FOCUS = "CAPACITY_LOW_FOCUS",
  ACCESS_COST_BARRIER = "ACCESS_COST_BARRIER",
  ACCESS_APPOINTMENT_BARRIER = "ACCESS_APPOINTMENT_BARRIER",
  RESOURCE_FINANCIAL_STRAIN = "RESOURCE_FINANCIAL_STRAIN",
  RESOURCE_TIME_PRESSURE = "RESOURCE_TIME_PRESSURE",
  RESOURCE_CAREGIVING_LOAD = "RESOURCE_CAREGIVING_LOAD",
  SAFETY_RED_FLAG = "SAFETY_RED_FLAG",
  SAFETY_SELF_HARM = "SAFETY_SELF_HARM",
  ENV_AIR_QUALITY_EXPOSURE = "ENV_AIR_QUALITY_EXPOSURE",
  SOCIAL_SUPPORT_LIMITED = "SOCIAL_SUPPORT_LIMITED",
  KNOWLEDGE_NEEDS_INFORMATION = "KNOWLEDGE_NEEDS_INFORMATION",
  GOAL_SYMPTOM_RELIEF = "GOAL_SYMPTOM_RELIEF",
  GOAL_BEHAVIOUR_CHANGE = "GOAL_BEHAVIOUR_CHANGE",
}

export interface Factor {
  id: string;
  domain: ComplexityDomain;
  type: FactorType;
  code: FactorCode;
  value: FactorValue;
  confidence: number;
  time_horizon: FactorTimeHorizon;
  modifiability: FactorModifiability;
  source_event_id: string;
  created_at: string;
}

export interface MissingInfo {
  key: string;
  question: string;
  domain: ComplexityDomain;
  priority: "low" | "medium" | "high";
}
