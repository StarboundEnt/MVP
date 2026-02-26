import { classifyDomains } from "./classifyDomains";
import { ComplexityDomain } from "./domains";
import { EventIntent } from "./types";

const ASK: EventIntent = "ASK";

describe("classifyDomains", () => {
  it("classifies symptoms and body signals", () => {
    const result = classifyDomains("I've got a sore throat and cough.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.SYMPTOMS_BODY_SIGNALS);
  });

  it("classifies duration and pattern", () => {
    const result = classifyDomains("It has been going on for weeks.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.DURATION_PATTERN);
  });

  it("classifies medical context", () => {
    const result = classifyDomains(
      "My GP diagnosed asthma and prescribed medication.",
      ASK,
    );
    expect(result.primary.domain).toBe(ComplexityDomain.MEDICAL_CONTEXT);
  });

  it("classifies mental and emotional state", () => {
    const result = classifyDomains("Feeling anxious and stressed lately.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.MENTAL_EMOTIONAL_STATE);
  });

  it("classifies capacity and energy", () => {
    const result = classifyDomains("I have no energy and feel exhausted.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.CAPACITY_ENERGY);
  });

  it("classifies access to care", () => {
    const result = classifyDomains(
      "Waitlist for a specialist appointment is long.",
      ASK,
    );
    expect(result.primary.domain).toBe(ComplexityDomain.ACCESS_TO_CARE);
  });

  it("classifies environment exposures", () => {
    const result = classifyDomains("Smoke outside and mould in the flat.", ASK);
    expect(result.primary.domain).toBe(
      ComplexityDomain.ENVIRONMENT_EXPOSURES,
    );
  });

  it("classifies social support context", () => {
    const result = classifyDomains("I feel isolated and have no support.", ASK);
    expect(result.primary.domain).toBe(
      ComplexityDomain.SOCIAL_SUPPORT_CONTEXT,
    );
  });

  it("classifies resources and constraints", () => {
    const result = classifyDomains("Can't afford groceries or rent.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.RESOURCES_CONSTRAINTS);
  });

  it("classifies knowledge, beliefs, and preferences", () => {
    const result = classifyDomains(
      "I prefer natural options and need more information.",
      ASK,
    );
    expect(result.primary.domain).toBe(
      ComplexityDomain.KNOWLEDGE_BELIEFS_PREFERENCES,
    );
  });

  it("classifies goals and intent", () => {
    const result = classifyDomains("I want to build a walking routine.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.GOALS_INTENT);
  });

  it("falls back to unknown when no signals are present", () => {
    const result = classifyDomains("Just checking in.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.UNKNOWN_OTHER);
  });

  it("returns duration as secondary for symptom plus duration input", () => {
    const result = classifyDomains("I've had a headache for months.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.SYMPTOMS_BODY_SIGNALS);
    expect(
      result.secondary.some(
        (tag) => tag.domain === ComplexityDomain.DURATION_PATTERN,
      ),
    ).toBe(true);
  });

  it("returns mental as primary with capacity as secondary", () => {
    const result = classifyDomains(
      "I feel anxious and panic at night, and I'm tired.",
      ASK,
    );
    expect(result.primary.domain).toBe(ComplexityDomain.MENTAL_EMOTIONAL_STATE);
    expect(
      result.secondary.some(
        (tag) => tag.domain === ComplexityDomain.CAPACITY_ENERGY,
      ),
    ).toBe(true);
  });

  it("uses UNKNOWN_OTHER when confidence is low", () => {
    const result = classifyDomains("I'm anxious and tired.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.UNKNOWN_OTHER);
  });

  it("overrides with safety risk when chest pain is mentioned", () => {
    const result = classifyDomains(
      "Severe chest pain and trouble breathing.",
      ASK,
    );
    expect(result.primary.domain).toBe(ComplexityDomain.SAFETY_RISK);
    expect(result.primary.confidence).toBeGreaterThanOrEqual(0.8);
  });

  it("overrides with safety risk for suicidal thoughts", () => {
    const result = classifyDomains(
      "I've been feeling suicidal and overwhelmed.",
      ASK,
    );
    expect(result.primary.domain).toBe(ComplexityDomain.SAFETY_RISK);
    expect(result.primary.confidence).toBeGreaterThanOrEqual(0.8);
  });

  it("keeps safety risk primary even when other domains appear", () => {
    const result = classifyDomains("Chest pain and I'm stressed.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.SAFETY_RISK);
  });

  it("biases to the previous question domain for follow ups", () => {
    const result = classifyDomains(
      "Twice a day.",
      "FOLLOW_UP",
      "What medication are you on?",
    );
    expect(result.primary.domain).toBe(ComplexityDomain.MEDICAL_CONTEXT);
  });

  it("biases to goals for follow ups about intent", () => {
    const result = classifyDomains(
      "More movement.",
      "FOLLOW_UP",
      "What are you hoping to change?",
    );
    expect(result.primary.domain).toBe(ComplexityDomain.GOALS_INTENT);
  });

  it("classifies duration when a clear pattern is present", () => {
    const result = classifyDomains("Every afternoon I feel tired.", ASK);
    expect(result.primary.domain).toBe(ComplexityDomain.DURATION_PATTERN);
  });

  it("classifies environment exposures with symptom secondary", () => {
    const result = classifyDomains("Mould and smoke make me cough.", ASK);
    expect(result.primary.domain).toBe(
      ComplexityDomain.ENVIRONMENT_EXPOSURES,
    );
    expect(
      result.secondary.some(
        (tag) => tag.domain === ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
      ),
    ).toBe(true);
  });

  it("classifies social support context from relationship cues", () => {
    const result = classifyDomains(
      "My partner is supportive but I feel isolated.",
      ASK,
    );
    expect(result.primary.domain).toBe(
      ComplexityDomain.SOCIAL_SUPPORT_CONTEXT,
    );
  });

  it("classifies resource constraints from time and cost cues", () => {
    const result = classifyDomains(
      "Shift work and childcare costs make things hard.",
      ASK,
    );
    expect(result.primary.domain).toBe(ComplexityDomain.RESOURCES_CONSTRAINTS);
  });

  it("keeps secondary domains capped at two", () => {
    const result = classifyDomains(
      "I'm anxious, tired, and have a headache every week.",
      ASK,
    );
    expect(result.secondary.length).toBeLessThanOrEqual(2);
  });
});
