import { ComplexityDomain, COMPLEXITY_DOMAIN_META } from "./domains";
import { DomainClassificationResult, DomainTag, EventIntent } from "./types";

const MIN_PRIMARY_CONFIDENCE = 0.6;
const FOLLOW_UP_BIAS_SCORE = 1.5;
const SAFETY_RISK_CONFIDENCE = 0.9;
const MAX_SECONDARIES = 2;

const SAFETY_RISK_PHRASES = [
  "chest pain",
  "trouble breathing",
  "cant breathe",
  "shortness of breath",
  "severe bleeding",
  "bleeding heavily",
  "passed out",
  "black out",
  "face droop",
  "slurred speech",
  "weakness on one side",
  "sudden severe headache",
  "suicidal thoughts",
  "self harm",
  "severe allergic reaction",
  "anaphylaxis",
];

const SAFETY_RISK_KEYWORDS = [
  "suicidal",
  "suicide",
  "overdose",
  "unconscious",
  "fainting",
  "seizure",
  "stroke",
];

const DOMAIN_KEYWORDS: Record<ComplexityDomain, string[]> = {
  [ComplexityDomain.SYMPTOMS_BODY_SIGNALS]: [
    "pain",
    "ache",
    "sore",
    "fever",
    "cough",
    "nausea",
    "vomit",
    "vomiting",
    "dizzy",
    "dizziness",
    "headache",
    "migraine",
    "rash",
    "swelling",
    "cramps",
    "diarrhoea",
    "constipation",
    "chills",
    "palpitations",
    "breathless",
  ],
  [ComplexityDomain.DURATION_PATTERN]: [
    "daily",
    "weekly",
    "monthly",
    "recurring",
    "chronic",
    "persistent",
    "regularly",
    "often",
    "frequently",
    "lately",
  ],
  [ComplexityDomain.MEDICAL_CONTEXT]: [
    "diagnosed",
    "diagnosis",
    "medication",
    "meds",
    "dose",
    "prescription",
    "gp",
    "doctor",
    "specialist",
    "nurse",
    "hospital",
    "clinic",
    "physio",
    "surgery",
    "operation",
    "treatment",
    "immunisation",
    "vaccine",
    "vaccination",
    "xray",
    "mri",
    "ct",
    "ultrasound",
    "counselling",
    "therapy",
  ],
  [ComplexityDomain.MENTAL_EMOTIONAL_STATE]: [
    "anxious",
    "anxiety",
    "stressed",
    "stress",
    "depressed",
    "low",
    "sad",
    "panic",
    "overwhelmed",
    "irritable",
    "grief",
    "hopeless",
    "burnout",
  ],
  [ComplexityDomain.CAPACITY_ENERGY]: [
    "tired",
    "fatigue",
    "fatigued",
    "exhausted",
    "drained",
    "energy",
    "stamina",
    "overloaded",
    "bandwidth",
    "capacity",
    "motivation",
    "focus",
  ],
  [ComplexityDomain.ACCESS_TO_CARE]: [
    "appointment",
    "waitlist",
    "wait",
    "referral",
    "telehealth",
    "bulk",
    "billing",
    "gap",
    "medicare",
  ],
  [ComplexityDomain.ENVIRONMENT_EXPOSURES]: [
    "mould",
    "mold",
    "smoke",
    "pollution",
    "fumes",
    "chemical",
    "chemicals",
    "dust",
    "pollen",
    "heatwave",
    "heat",
    "cold",
    "noise",
    "damp",
    "allergens",
  ],
  [ComplexityDomain.SOCIAL_SUPPORT_CONTEXT]: [
    "partner",
    "family",
    "friends",
    "support",
    "supportive",
    "carer",
    "caregiver",
    "community",
    "alone",
    "isolated",
    "lonely",
  ],
  [ComplexityDomain.RESOURCES_CONSTRAINTS]: [
    "money",
    "rent",
    "bills",
    "debt",
    "housing",
    "food",
    "groceries",
    "transport",
    "job",
    "unemployed",
    "work",
    "shift",
    "childcare",
    "cost",
    "afford",
    "budget",
    "centrelink",
    "income",
  ],
  [ComplexityDomain.KNOWLEDGE_BELIEFS_PREFERENCES]: [
    "prefer",
    "preference",
    "believe",
    "think",
    "unsure",
    "confused",
    "information",
    "research",
    "avoid",
    "comfortable",
    "worried",
    "concerned",
    "values",
    "effects",
  ],
  [ComplexityDomain.GOALS_INTENT]: [
    "goal",
    "aim",
    "plan",
    "intend",
    "trying",
    "want",
    "hope",
    "looking",
  ],
  [ComplexityDomain.SAFETY_RISK]: [],
  [ComplexityDomain.UNKNOWN_OTHER]: [],
};

const DOMAIN_PHRASES: Record<ComplexityDomain, string[]> = {
  [ComplexityDomain.SYMPTOMS_BODY_SIGNALS]: [
    "sore throat",
    "body aches",
    "stomach pain",
    "skin rash",
  ],
  [ComplexityDomain.DURATION_PATTERN]: [
    "for weeks",
    "for months",
    "for days",
    "for years",
    "on and off",
    "every day",
    "every week",
    "every afternoon",
    "since last",
    "keeps coming back",
    "all the time",
  ],
  [ComplexityDomain.MEDICAL_CONTEXT]: [
    "blood test",
    "test results",
    "x ray",
    "gp appointment",
  ],
  [ComplexityDomain.MENTAL_EMOTIONAL_STATE]: [
    "low mood",
    "panic attack",
    "panic attacks",
    "on edge",
    "feeling down",
    "burnt out",
  ],
  [ComplexityDomain.CAPACITY_ENERGY]: [
    "no energy",
    "brain fog",
    "cant focus",
    "can only manage",
    "struggling to focus",
  ],
  [ComplexityDomain.ACCESS_TO_CARE]: [
    "cant get an appointment",
    "cant get a gp appointment",
    "cant see a doctor",
    "no bulk billing",
    "need a referral",
    "long wait",
    "wait time",
  ],
  [ComplexityDomain.ENVIRONMENT_EXPOSURES]: [
    "poor air",
    "workplace exposure",
    "second hand smoke",
    "air quality",
  ],
  [ComplexityDomain.SOCIAL_SUPPORT_CONTEXT]: [
    "no one",
    "living alone",
    "no support",
    "support network",
    "feel isolated",
  ],
  [ComplexityDomain.RESOURCES_CONSTRAINTS]: [
    "cant afford",
    "rent overdue",
    "no transport",
    "shift work",
    "cost of living",
    "working two jobs",
  ],
  [ComplexityDomain.KNOWLEDGE_BELIEFS_PREFERENCES]: [
    "not sure",
    "dont understand",
    "need more information",
    "want to avoid",
    "natural options",
    "side effects",
  ],
  [ComplexityDomain.GOALS_INTENT]: [
    "want to",
    "trying to",
    "hoping to",
    "looking to",
    "plan to",
    "aim to",
    "goal is",
  ],
  [ComplexityDomain.SAFETY_RISK]: [],
  [ComplexityDomain.UNKNOWN_OTHER]: [],
};

const SCORING_DOMAINS = [
  ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
  ComplexityDomain.DURATION_PATTERN,
  ComplexityDomain.MEDICAL_CONTEXT,
  ComplexityDomain.MENTAL_EMOTIONAL_STATE,
  ComplexityDomain.CAPACITY_ENERGY,
  ComplexityDomain.ACCESS_TO_CARE,
  ComplexityDomain.ENVIRONMENT_EXPOSURES,
  ComplexityDomain.SOCIAL_SUPPORT_CONTEXT,
  ComplexityDomain.RESOURCES_CONSTRAINTS,
  ComplexityDomain.KNOWLEDGE_BELIEFS_PREFERENCES,
  ComplexityDomain.GOALS_INTENT,
];

const normaliseText = (input: string): string =>
  input
    .toLowerCase()
    .replace(/'/g, "")
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const countKeywordMatches = (text: string, keywords: string[]): number => {
  let score = 0;
  for (const keyword of keywords) {
    if (!keyword) continue;
    const pattern = new RegExp(`\\b${escapeRegExp(keyword)}\\b`, "g");
    const matches = text.match(pattern);
    if (matches) score += matches.length;
  }
  return score;
};

const countPhraseMatches = (text: string, phrases: string[]): number => {
  let score = 0;
  for (const phrase of phrases) {
    if (!phrase) continue;
    if (text.includes(phrase)) {
      score += 2;
    }
  }
  return score;
};

const detectSafetyRisk = (text: string): boolean => {
  for (const phrase of SAFETY_RISK_PHRASES) {
    if (text.includes(phrase)) {
      return true;
    }
  }
  for (const keyword of SAFETY_RISK_KEYWORDS) {
    const pattern = new RegExp(`\\b${escapeRegExp(keyword)}\\b`, "g");
    if (pattern.test(text)) {
      return true;
    }
  }
  return false;
};

const scoreText = (text: string): Record<ComplexityDomain, number> => {
  const scores: Record<ComplexityDomain, number> = {
    [ComplexityDomain.SYMPTOMS_BODY_SIGNALS]: 0,
    [ComplexityDomain.DURATION_PATTERN]: 0,
    [ComplexityDomain.MEDICAL_CONTEXT]: 0,
    [ComplexityDomain.MENTAL_EMOTIONAL_STATE]: 0,
    [ComplexityDomain.CAPACITY_ENERGY]: 0,
    [ComplexityDomain.ACCESS_TO_CARE]: 0,
    [ComplexityDomain.ENVIRONMENT_EXPOSURES]: 0,
    [ComplexityDomain.SOCIAL_SUPPORT_CONTEXT]: 0,
    [ComplexityDomain.RESOURCES_CONSTRAINTS]: 0,
    [ComplexityDomain.KNOWLEDGE_BELIEFS_PREFERENCES]: 0,
    [ComplexityDomain.GOALS_INTENT]: 0,
    [ComplexityDomain.SAFETY_RISK]: 0,
    [ComplexityDomain.UNKNOWN_OTHER]: 0,
  };

  for (const domain of SCORING_DOMAINS) {
    const keywordScore = countKeywordMatches(text, DOMAIN_KEYWORDS[domain]);
    const phraseScore = countPhraseMatches(text, DOMAIN_PHRASES[domain]);
    scores[domain] = keywordScore + phraseScore;
  }

  return scores;
};

const clamp = (value: number, min = 0, max = 1): number =>
  Math.max(min, Math.min(max, value));

const toDomainTags = (
  scores: Record<ComplexityDomain, number>,
): DomainTag[] => {
  const total = SCORING_DOMAINS.reduce(
    (sum, domain) => sum + (scores[domain] || 0),
    0,
  );

  if (total <= 0) {
    return [];
  }

  const tags = SCORING_DOMAINS.filter((domain) => scores[domain] > 0).map(
    (domain) => ({
      domain,
      confidence: clamp((scores[domain] || 0) / total),
    }),
  );

  tags.sort((a, b) => {
    if (b.confidence !== a.confidence) {
      return b.confidence - a.confidence;
    }
    const priorityA = COMPLEXITY_DOMAIN_META[a.domain].priority;
    const priorityB = COMPLEXITY_DOMAIN_META[b.domain].priority;
    return priorityA - priorityB;
  });

  return tags;
};

const inferDomainFromQuestion = (question: string): ComplexityDomain | null => {
  const questionText = normaliseText(question);
  if (!questionText) return null;
  const tags = toDomainTags(scoreText(questionText));
  if (tags.length === 0) return null;
  if (tags[0].confidence < 0.4) return null;
  return tags[0].domain;
};

export const classifyDomains = (
  inputText: string,
  intent: EventIntent,
  previousQuestion?: string,
): DomainClassificationResult => {
  // TODO: Replace keyword heuristics with an LLM classifier when available.
  const text = normaliseText(inputText);

  // SAFETY_RISK overrides all other domains for response routing.
  if (detectSafetyRisk(text)) {
    const secondary = toDomainTags(scoreText(text))
      .filter((tag) => tag.domain !== ComplexityDomain.SAFETY_RISK)
      .slice(0, MAX_SECONDARIES);
    return {
      primary: {
        domain: ComplexityDomain.SAFETY_RISK,
        confidence: SAFETY_RISK_CONFIDENCE,
      },
      secondary,
      rationale: "Safety risk keywords detected.",
    };
  }

  const scores = scoreText(text);

  if (intent === "FOLLOW_UP" && previousQuestion) {
    const biasDomain = inferDomainFromQuestion(previousQuestion);
    if (biasDomain) {
      scores[biasDomain] = (scores[biasDomain] || 0) + FOLLOW_UP_BIAS_SCORE;
    }
  }

  const tags = toDomainTags(scores);
  if (tags.length === 0) {
    return {
      primary: { domain: ComplexityDomain.UNKNOWN_OTHER, confidence: 0 },
      secondary: [],
      rationale: "No domain signals detected.",
    };
  }

  const primaryCandidate = tags[0];
  if (primaryCandidate.confidence < MIN_PRIMARY_CONFIDENCE) {
    const secondary = tags.slice(0, MAX_SECONDARIES);
    return {
      primary: {
        domain: ComplexityDomain.UNKNOWN_OTHER,
        confidence: clamp(1 - primaryCandidate.confidence),
      },
      secondary,
      rationale: "Low confidence match.",
    };
  }

  const secondary = tags
    .filter((tag) => tag.domain !== primaryCandidate.domain)
    .slice(0, MAX_SECONDARIES);

  return {
    primary: primaryCandidate,
    secondary,
  };
};
