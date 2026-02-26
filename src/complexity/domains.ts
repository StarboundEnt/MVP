export enum ComplexityDomain {
  SYMPTOMS_BODY_SIGNALS = "SYMPTOMS_BODY_SIGNALS",
  DURATION_PATTERN = "DURATION_PATTERN",
  MEDICAL_CONTEXT = "MEDICAL_CONTEXT",
  MENTAL_EMOTIONAL_STATE = "MENTAL_EMOTIONAL_STATE",
  CAPACITY_ENERGY = "CAPACITY_ENERGY",
  ACCESS_TO_CARE = "ACCESS_TO_CARE",
  SAFETY_RISK = "SAFETY_RISK",
  ENVIRONMENT_EXPOSURES = "ENVIRONMENT_EXPOSURES",
  SOCIAL_SUPPORT_CONTEXT = "SOCIAL_SUPPORT_CONTEXT",
  RESOURCES_CONSTRAINTS = "RESOURCES_CONSTRAINTS",
  KNOWLEDGE_BELIEFS_PREFERENCES = "KNOWLEDGE_BELIEFS_PREFERENCES",
  GOALS_INTENT = "GOALS_INTENT",
  UNKNOWN_OTHER = "UNKNOWN_OTHER",
}

export type DomainFactorType = "choice" | "chance" | "constrained_choice";
export type DomainOverrideBehavior = "OVERRIDES_ALL" | "NONE";

export interface DomainMeta {
  label: string;
  description: string;
  examples: string[];
  typical_factor_types: DomainFactorType[];
  priority: number;
  override_behavior?: DomainOverrideBehavior;
}

export const COMPLEXITY_DOMAIN_META: Record<ComplexityDomain, DomainMeta> = {
  // Safety risk overrides all other domains for response routing.
  [ComplexityDomain.SAFETY_RISK]: {
    label: "Safety risk",
    description:
      "Potential acute risk or urgent warning signs that should override other domains.",
    examples: [
      "severe chest pain",
      "trouble breathing",
      "fainting or blacking out",
      "suicidal thoughts",
      "heavy bleeding",
    ],
    typical_factor_types: ["chance"],
    priority: 1,
    override_behavior: "OVERRIDES_ALL",
  },
  // Physical sensations or changes in the body.
  [ComplexityDomain.SYMPTOMS_BODY_SIGNALS]: {
    label: "Symptoms and body signals",
    description:
      "Physical sensations or changes the person notices in their body.",
    examples: [
      "sore throat and cough",
      "stomach cramps after meals",
      "headache and dizziness",
      "skin rash on my arms",
      "fever and chills",
    ],
    typical_factor_types: ["chance"],
    priority: 2,
    override_behavior: "NONE",
  },
  // Clinical history, diagnosis, treatment, or health service details.
  [ComplexityDomain.MEDICAL_CONTEXT]: {
    label: "Medical context",
    description:
      "Clinical details like diagnoses, medications, tests, or health service interactions.",
    examples: [
      "GP diagnosed asthma",
      "started a new medication",
      "waiting for blood test results",
      "recent surgery recovery",
      "counselling session today",
    ],
    typical_factor_types: ["chance", "constrained_choice"],
    priority: 3,
    override_behavior: "NONE",
  },
  // Emotional wellbeing and mental state signals.
  [ComplexityDomain.MENTAL_EMOTIONAL_STATE]: {
    label: "Mental and emotional state",
    description: "Feelings, mood, stress, or emotional wellbeing signals.",
    examples: [
      "feeling anxious",
      "low mood lately",
      "overwhelmed and stressed",
      "panic episodes",
      "grief is hitting hard",
    ],
    typical_factor_types: ["chance"],
    priority: 4,
    override_behavior: "NONE",
  },
  // Timing, frequency, or persistence.
  [ComplexityDomain.DURATION_PATTERN]: {
    label: "Duration and pattern",
    description:
      "Timing, frequency, or persistence of symptoms or experiences.",
    examples: [
      "for three weeks now",
      "every afternoon",
      "on and off",
      "keeps coming back",
      "since last month",
    ],
    typical_factor_types: ["chance"],
    priority: 5,
    override_behavior: "NONE",
  },
  // Energy, capacity, and bandwidth for action.
  [ComplexityDomain.CAPACITY_ENERGY]: {
    label: "Capacity and energy",
    description:
      "Energy, fatigue, bandwidth, or ability to carry out tasks.",
    examples: [
      "no energy to cook",
      "brain fog today",
      "exhausted after work",
      "struggling to focus",
      "can only manage basics",
    ],
    typical_factor_types: ["chance", "constrained_choice"],
    priority: 6,
    override_behavior: "NONE",
  },
  // Ability to access healthcare.
  [ComplexityDomain.ACCESS_TO_CARE]: {
    label: "Access to care",
    description:
      "Ability to reach healthcare, appointments, referrals, and care affordability.",
    examples: [
      "can't get a GP appointment",
      "waitlist for a specialist",
      "telehealth is the only option",
      "no bulk billing nearby",
      "referral needed",
    ],
    typical_factor_types: ["chance", "constrained_choice"],
    priority: 7,
    override_behavior: "NONE",
  },
  // Environmental factors that affect wellbeing.
  [ComplexityDomain.ENVIRONMENT_EXPOSURES]: {
    label: "Environment exposures",
    description:
      "Physical environment factors like smoke, mould, heat, noise, or chemicals.",
    examples: [
      "mould in the flat",
      "smoke outside",
      "chemical fumes at work",
      "heatwave makes it worse",
      "dusty air",
    ],
    typical_factor_types: ["chance"],
    priority: 8,
    override_behavior: "NONE",
  },
  // Social support and relationships.
  [ComplexityDomain.SOCIAL_SUPPORT_CONTEXT]: {
    label: "Social support context",
    description:
      "Support network, relationships, or social isolation affecting wellbeing.",
    examples: [
      "no one to help me",
      "partner is supportive",
      "living alone",
      "friends check in",
      "feel isolated",
    ],
    typical_factor_types: ["chance", "constrained_choice"],
    priority: 9,
    override_behavior: "NONE",
  },
  // Financial, housing, transport, or time constraints.
  [ComplexityDomain.RESOURCES_CONSTRAINTS]: {
    label: "Resources and constraints",
    description:
      "Financial, housing, time, transport, or caregiving limits that constrain choices.",
    examples: [
      "can't afford groceries",
      "rent is overdue",
      "no transport to get around",
      "childcare is expensive",
      "shift work schedule",
    ],
    typical_factor_types: ["chance", "constrained_choice"],
    priority: 10,
    override_behavior: "NONE",
  },
  // Understanding, beliefs, or preferences that guide behaviour.
  [ComplexityDomain.KNOWLEDGE_BELIEFS_PREFERENCES]: {
    label: "Knowledge, beliefs, and preferences",
    description:
      "Understanding, beliefs, or preferences that guide decisions and behaviour.",
    examples: [
      "I prefer natural options",
      "not sure what this means",
      "need more information",
      "worried about side effects",
      "I believe this is normal",
    ],
    typical_factor_types: ["choice"],
    priority: 11,
    override_behavior: "NONE",
  },
  // Goals and desired outcomes.
  [ComplexityDomain.GOALS_INTENT]: {
    label: "Goals and intent",
    description: "Stated goals, plans, or desired changes.",
    examples: [
      "I want to sleep better",
      "trying to walk daily",
      "goal is to reduce sugar",
      "plan to organise meals",
      "hoping to feel calmer",
    ],
    typical_factor_types: ["choice"],
    priority: 12,
    override_behavior: "NONE",
  },
  // Fallback for unclear or out-of-scope inputs.
  [ComplexityDomain.UNKNOWN_OTHER]: {
    label: "Unknown or other",
    description:
      "Fallback for unclear, mixed, or out-of-scope inputs. Keep the taxonomy stable.",
    examples: [
      "just checking in",
      "hard to explain",
      "not sure",
      "something feels off",
      "no idea",
    ],
    typical_factor_types: ["choice", "chance", "constrained_choice"],
    priority: 13,
    override_behavior: "NONE",
  },
};
