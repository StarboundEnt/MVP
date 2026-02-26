import { buildStateSnapshot } from "./buildStateSnapshot";
import { ComplexityDomain } from "./domains";
import { Event } from "./events";
import { Factor, FactorCode, FactorType } from "./factors";
import { ComplexityProfile } from "./profile";
import { DomainClassificationResult } from "./types";

const makeEvent = (overrides: Partial<Event>): Event => ({
  id: overrides.id ?? "evt-1",
  created_at: overrides.created_at ?? "2025-02-01T00:00:00.000Z",
  intent: overrides.intent ?? "ASK",
  save_mode: overrides.save_mode ?? "save_journal",
  raw_text: overrides.raw_text,
});

const makeDomainResult = (
  primary: ComplexityDomain,
  secondary: ComplexityDomain[] = [],
): DomainClassificationResult => ({
  primary: { domain: primary, confidence: 0.9 },
  secondary: secondary.map((domain) => ({ domain, confidence: 0.7 })),
});

const makeFactor = (overrides: Partial<Factor>): Factor => ({
  id: overrides.id ?? "factor-1",
  domain: overrides.domain ?? ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
  type: overrides.type ?? FactorType.CHANCE,
  code: overrides.code ?? FactorCode.SYMPTOM_PAIN,
  value: overrides.value ?? true,
  confidence: overrides.confidence ?? 0.85,
  time_horizon: overrides.time_horizon ?? "acute",
  modifiability: overrides.modifiability ?? "low",
  source_event_id: overrides.source_event_id ?? "evt-1",
  created_at: overrides.created_at ?? "2025-02-01T00:00:00.000Z",
});

const makeProfile = (): ComplexityProfile => ({
  updated_at: "2025-02-01T00:00:00.000Z",
  factors_by_code: {},
  top_constraints: [],
  domains_coverage: Object.values(ComplexityDomain).reduce((acc, domain) => {
    acc[domain] = { acute: 0, chronic: 0 };
    return acc;
  }, {} as ComplexityProfile["domains_coverage"]),
});

describe("buildStateSnapshot", () => {
  it("uses urgent safety override when safety factors are present", () => {
    const snapshot = buildStateSnapshot(
      makeEvent({ id: "evt-safe" }),
      makeDomainResult(ComplexityDomain.SAFETY_RISK),
      {
        factors: [
          makeFactor({
            code: FactorCode.SAFETY_RED_FLAG,
            domain: ComplexityDomain.SAFETY_RISK,
            confidence: 0.95,
          }),
        ],
      },
      makeProfile(),
    );

    expect(snapshot.risk_band).toBe("urgent");
    expect(snapshot.next_action_kind).toBe("safety_escalation");
    expect(snapshot.safety_copy).toBeDefined();
  });

  it("asks a follow-up when ambiguity is present", () => {
    const snapshot = buildStateSnapshot(
      makeEvent({ id: "evt-ambiguous" }),
      makeDomainResult(ComplexityDomain.SYMPTOMS_BODY_SIGNALS),
      {
        factors: [
          makeFactor({
            code: FactorCode.SYMPTOM_PAIN,
            confidence: 0.65,
          }),
        ],
        missing_info: [
          {
            key: "duration",
            question: "How long has this been going on?",
            domain: ComplexityDomain.DURATION_PATTERN,
            priority: "high",
          },
        ],
      },
      makeProfile(),
    );

    expect(snapshot.uncertainty_band).toBe("high");
    expect(snapshot.next_action_kind).toBe("ask_followup");
    expect(snapshot.followup_question).toBe(
      "How long has this been going on?",
    );
  });

  it("sets friction high for constraint signals", () => {
    const snapshot = buildStateSnapshot(
      makeEvent({ id: "evt-friction" }),
      makeDomainResult(ComplexityDomain.ACCESS_TO_CARE),
      {
        factors: [
          makeFactor({
            code: FactorCode.ACCESS_COST_BARRIER,
            domain: ComplexityDomain.ACCESS_TO_CARE,
            confidence: 0.9,
          }),
        ],
      },
      makeProfile(),
    );

    expect(snapshot.friction_band).toBe("high");
    expect(snapshot.used_factors.map((factor) => factor.code)).toContain(
      FactorCode.ACCESS_COST_BARRIER,
    );
  });

  it("uses log_only for LOG_ONLY intent", () => {
    const snapshot = buildStateSnapshot(
      makeEvent({ id: "evt-log", intent: "LOG_ONLY" }),
      makeDomainResult(ComplexityDomain.UNKNOWN_OTHER),
      { factors: [] },
      makeProfile(),
    );

    expect(snapshot.next_action_kind).toBe("log_only");
  });

  it("builds what_matters across multiple domains", () => {
    const snapshot = buildStateSnapshot(
      makeEvent({ id: "evt-multi" }),
      makeDomainResult(ComplexityDomain.SYMPTOMS_BODY_SIGNALS, [
        ComplexityDomain.RESOURCES_CONSTRAINTS,
      ]),
      {
        factors: [
          makeFactor({
            code: FactorCode.SYMPTOM_PAIN,
            domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
            confidence: 0.9,
          }),
          makeFactor({
            code: FactorCode.RESOURCE_TIME_PRESSURE,
            domain: ComplexityDomain.RESOURCES_CONSTRAINTS,
            confidence: 0.85,
          }),
        ],
      },
      makeProfile(),
    );

    expect(snapshot.what_matters.join(" ")).toContain("Pain is showing up.");
    expect(snapshot.what_matters.join(" ")).toContain(
      "Time pressure is limiting what you can do.",
    );
  });
});
