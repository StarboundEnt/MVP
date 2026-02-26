import { extractFactors } from "./extractFactors";
import { ComplexityDomain } from "./domains";
import { FactorCode } from "./factors";
import { DomainClassificationResult } from "./types";

const makeDomainResult = (
  primary: ComplexityDomain,
  secondary: ComplexityDomain[] = [],
): DomainClassificationResult => ({
  primary: { domain: primary, confidence: 0.9 },
  secondary: secondary.map((domain) => ({ domain, confidence: 0.7 })),
});

describe("extractFactors", () => {
  it("extracts basic symptom factors", () => {
    const result = extractFactors(
      "I've got a headache and feel nauseous.",
      makeDomainResult(ComplexityDomain.SYMPTOMS_BODY_SIGNALS),
      "ASK",
      "evt-1",
    );
    const codes = result.factors.map((factor) => factor.code);
    expect(codes).toEqual(
      expect.arrayContaining([
        FactorCode.SYMPTOM_HEADACHE,
        FactorCode.SYMPTOM_NAUSEA,
      ]),
    );
  });

  it("extracts duration buckets", () => {
    const result = extractFactors(
      "It has been going on for weeks.",
      makeDomainResult(ComplexityDomain.DURATION_PATTERN),
      "ASK",
      "evt-2",
    );
    expect(result.factors.map((factor) => factor.code)).toContain(
      FactorCode.DURATION_DAYS_WEEKS,
    );
  });

  it("extracts access barriers and costs", () => {
    const result = extractFactors(
      "I can't afford the GP and no appointments are available.",
      makeDomainResult(ComplexityDomain.ACCESS_TO_CARE, [
        ComplexityDomain.RESOURCES_CONSTRAINTS,
      ]),
      "ASK",
      "evt-3",
    );
    const codes = result.factors.map((factor) => factor.code);
    expect(codes).toContain(FactorCode.ACCESS_COST_BARRIER);
    expect(codes).toContain(FactorCode.ACCESS_APPOINTMENT_BARRIER);
  });

  it("extracts mental state factors", () => {
    const result = extractFactors(
      "Feeling anxious and overwhelmed.",
      makeDomainResult(ComplexityDomain.MENTAL_EMOTIONAL_STATE),
      "JOURNAL",
      "evt-4",
    );
    expect(result.factors.map((factor) => factor.code)).toContain(
      FactorCode.EMOTION_ANXIETY_STRESS,
    );
  });

  it("extracts safety signals", () => {
    const result = extractFactors(
      "Severe chest pain and trouble breathing.",
      makeDomainResult(ComplexityDomain.SAFETY_RISK),
      "ASK",
      "evt-5",
    );
    expect(result.factors.map((factor) => factor.code)).toContain(
      FactorCode.SAFETY_RED_FLAG,
    );
  });

  it("uses MissingInfo for ambiguous inputs", () => {
    const result = extractFactors(
      "Not sure, hard to explain.",
      makeDomainResult(ComplexityDomain.UNKNOWN_OTHER),
      "ASK",
      "evt-6",
    );
    expect(result.factors.length).toBe(0);
    expect(result.missing_info?.length).toBe(1);
  });

  it("asks for duration when symptoms lack timing", () => {
    const result = extractFactors(
      "I've got a headache.",
      makeDomainResult(ComplexityDomain.SYMPTOMS_BODY_SIGNALS),
      "ASK",
      "evt-7",
    );
    expect(result.missing_info?.[0].key).toBe("duration");
  });

  it("extracts caregiving and time pressure constraints", () => {
    const result = extractFactors(
      "No time because I'm caring for my parent.",
      makeDomainResult(ComplexityDomain.RESOURCES_CONSTRAINTS),
      "JOURNAL",
      "evt-8",
    );
    const codes = result.factors.map((factor) => factor.code);
    expect(codes).toContain(FactorCode.RESOURCE_TIME_PRESSURE);
    expect(codes).toContain(FactorCode.RESOURCE_CAREGIVING_LOAD);
  });
});
