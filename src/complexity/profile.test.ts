import { buildComplexityProfile } from "./profile";
import { ComplexityDomain } from "./domains";
import { Factor, FactorCode, FactorType } from "./factors";

const makeFactor = (overrides: Partial<Factor>): Factor => ({
  id: overrides.id ?? "factor-1",
  domain: overrides.domain ?? ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
  type: overrides.type ?? FactorType.CHANCE,
  code: overrides.code ?? FactorCode.SYMPTOM_PAIN,
  value: overrides.value ?? true,
  confidence: overrides.confidence ?? 0.9,
  time_horizon: overrides.time_horizon ?? "acute",
  modifiability: overrides.modifiability ?? "low",
  source_event_id: overrides.source_event_id ?? "evt-1",
  created_at: overrides.created_at ?? "2025-01-01T00:00:00.000Z",
});

describe("buildComplexityProfile", () => {
  it("keeps the latest factor per code above the confidence threshold", () => {
    const factors: Factor[] = [
      makeFactor({
        id: "f1",
        code: FactorCode.SYMPTOM_PAIN,
        created_at: "2025-01-01T00:00:00.000Z",
        confidence: 0.8,
      }),
      makeFactor({
        id: "f2",
        code: FactorCode.SYMPTOM_PAIN,
        created_at: "2025-01-02T00:00:00.000Z",
        confidence: 0.9,
      }),
      makeFactor({
        id: "f3",
        code: FactorCode.CAPACITY_FATIGUE,
        confidence: 0.6,
      }),
    ];

    const profile = buildComplexityProfile(factors);
    const painFactor = profile.factors_by_code[FactorCode.SYMPTOM_PAIN];
    expect(painFactor.id).toBe("f2");
    expect(profile.factors_by_code[FactorCode.CAPACITY_FATIGUE]).toBeUndefined();
  });

  it("separates acute and chronic coverage by domain", () => {
    const factors: Factor[] = [
      makeFactor({
        id: "f1",
        code: FactorCode.SYMPTOM_HEADACHE,
        domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
        time_horizon: "acute",
      }),
      makeFactor({
        id: "f2",
        code: FactorCode.RESOURCE_FINANCIAL_STRAIN,
        domain: ComplexityDomain.RESOURCES_CONSTRAINTS,
        time_horizon: "chronic",
      }),
      makeFactor({
        id: "f3",
        code: FactorCode.RESOURCE_TIME_PRESSURE,
        domain: ComplexityDomain.RESOURCES_CONSTRAINTS,
        time_horizon: "acute",
      }),
    ];

    const profile = buildComplexityProfile(factors);
    expect(profile.domains_coverage[ComplexityDomain.SYMPTOMS_BODY_SIGNALS].acute).toBe(1);
    expect(profile.domains_coverage[ComplexityDomain.RESOURCES_CONSTRAINTS].chronic).toBe(1);
    expect(profile.domains_coverage[ComplexityDomain.RESOURCES_CONSTRAINTS].acute).toBe(1);
  });

  it("returns top constraints ordered by confidence and recency", () => {
    const factors: Factor[] = [
      makeFactor({
        id: "f1",
        code: FactorCode.ACCESS_APPOINTMENT_BARRIER,
        domain: ComplexityDomain.ACCESS_TO_CARE,
        type: FactorType.CONSTRAINED_CHOICE,
        confidence: 0.7,
        created_at: "2025-01-02T00:00:00.000Z",
      }),
      makeFactor({
        id: "f2",
        code: FactorCode.RESOURCE_TIME_PRESSURE,
        domain: ComplexityDomain.RESOURCES_CONSTRAINTS,
        confidence: 0.85,
        created_at: "2025-01-01T00:00:00.000Z",
      }),
      makeFactor({
        id: "f3",
        code: FactorCode.ACCESS_COST_BARRIER,
        domain: ComplexityDomain.ACCESS_TO_CARE,
        type: FactorType.CONSTRAINED_CHOICE,
        confidence: 0.9,
        created_at: "2025-01-03T00:00:00.000Z",
      }),
    ];

    const profile = buildComplexityProfile(factors);
    expect(profile.top_constraints[0].code).toBe(
      FactorCode.ACCESS_COST_BARRIER,
    );
    expect(profile.top_constraints.length).toBeLessThanOrEqual(3);
  });
});
