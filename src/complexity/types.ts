import { ComplexityDomain } from "./domains";

export type EventIntent = "ASK" | "JOURNAL" | "FOLLOW_UP" | "MIXED" | "LOG_ONLY";

export interface DomainTag {
  domain: ComplexityDomain;
  confidence: number;
}

export interface DomainClassificationResult {
  primary: DomainTag;
  secondary: DomainTag[];
  rationale?: string;
}

export const ComplexityDomainSchema = {
  type: "string",
  enum: Object.values(ComplexityDomain),
} as const;

export const EventIntentSchema = {
  type: "string",
  enum: ["ASK", "JOURNAL", "FOLLOW_UP", "MIXED", "LOG_ONLY"],
} as const;

export const DomainTagSchema = {
  type: "object",
  additionalProperties: false,
  required: ["domain", "confidence"],
  properties: {
    domain: ComplexityDomainSchema,
    confidence: {
      type: "number",
      minimum: 0,
      maximum: 1,
    },
  },
} as const;

export const DomainClassificationResultSchema = {
  type: "object",
  additionalProperties: false,
  required: ["primary", "secondary"],
  properties: {
    primary: DomainTagSchema,
    secondary: {
      type: "array",
      items: DomainTagSchema,
      maxItems: 2,
    },
    rationale: {
      type: "string",
    },
  },
} as const;
