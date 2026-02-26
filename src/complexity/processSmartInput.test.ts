import { processSmartInput } from "./processSmartInput";
import { getPendingFollowUp } from "./followup";
import { suppressFactorCode, unsuppressFactorCode } from "./suppression";
import { Factor, FactorCode, FactorType } from "./factors";
import { buildComplexityProfile } from "./profile";
import { routeNextStep } from "./nextStepRouter";
import { StateSnapshot } from "./state";
import { ComplexityDomain } from "./domains";

const makeDbPath = (label: string): string =>
  `/tmp/complexity_${label}_${Date.now()}_${Math.random()
    .toString(36)
    .slice(2, 8)}.sqlite`;

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
  created_at: overrides.created_at ?? "2025-02-01T00:00:00.000Z",
});

const makeSnapshot = (overrides: Partial<StateSnapshot>): StateSnapshot => ({
  event_id: "evt-1",
  created_at: "2025-02-01T00:00:00.000Z",
  intent: "ASK",
  risk_band: "low",
  friction_band: "low",
  uncertainty_band: "low",
  next_action_kind: "answer",
  what_matters: [],
  used_factors: [],
  ...overrides,
});

describe("processSmartInput follow-up orchestration", () => {
  it("sets a pending follow-up when a question is needed", async () => {
    const dbPath = makeDbPath("pending");
    const result = await processSmartInput({
      inputText: "I've got a headache.",
      intent: "ASK",
      save_mode: "save_factors_only",
      dbPath,
    });

    expect(result.snapshot.next_action_kind).toBe("ask_followup");
    const pending = await getPendingFollowUp(dbPath);
    expect(pending?.parent_event_id).toBe(result.event.id);
    expect(pending?.question_text).toBe(result.snapshot.followup_question);
  });

  it("processes follow-up answers automatically and clears pending follow-ups", async () => {
    const dbPath = makeDbPath("followup");
    const first = await processSmartInput({
      inputText: "I've got a headache.",
      intent: "ASK",
      save_mode: "save_factors_only",
      dbPath,
    });

    const second = await processSmartInput({
      inputText: "For weeks.",
      intent: "ASK",
      save_mode: "save_factors_only",
      dbPath,
    });

    expect(first.snapshot.uncertainty_band).toBe("high");
    expect(second.event.intent).toBe("FOLLOW_UP");
    expect(second.snapshot.uncertainty_band).not.toBe("high");
    const pending = await getPendingFollowUp(dbPath);
    expect(pending).toBeNull();
  });

  it("does not set pending follow-up for safety escalation", async () => {
    const dbPath = makeDbPath("safety");
    const result = await processSmartInput({
      inputText: "Severe chest pain and trouble breathing.",
      intent: "ASK",
      save_mode: "save_factors_only",
      dbPath,
    });

    expect(result.snapshot.next_action_kind).toBe("safety_escalation");
    const pending = await getPendingFollowUp(dbPath);
    expect(pending).toBeNull();
  });

  it("does not set pending follow-up for LOG_ONLY", async () => {
    const dbPath = makeDbPath("logonly");
    const result = await processSmartInput({
      inputText: "I've got a headache.",
      intent: "LOG_ONLY",
      save_mode: "save_factors_only",
      dbPath,
    });

    expect(result.snapshot.next_action_kind).toBe("log_only");
    const pending = await getPendingFollowUp(dbPath);
    expect(pending).toBeNull();
  });
});

describe("suppression and expiry behaviour", () => {
  it("suppresses a factor code from the profile and snapshot", async () => {
    const dbPath = makeDbPath("suppress");
    await suppressFactorCode(FactorCode.SYMPTOM_PAIN, dbPath);

    const result = await processSmartInput({
      inputText: "I have sharp back pain.",
      intent: "LOG_ONLY",
      save_mode: "save_factors_only",
      dbPath,
    });

    const usedCodes = result.snapshot.used_factors.map((factor) => factor.code);
    expect(usedCodes).not.toContain(FactorCode.SYMPTOM_PAIN);
    expect(result.profile.factors_by_code[FactorCode.SYMPTOM_PAIN]).toBeUndefined();

    await unsuppressFactorCode(FactorCode.SYMPTOM_PAIN, dbPath);
    const restored = await processSmartInput({
      inputText: "I have sharp back pain.",
      intent: "LOG_ONLY",
      save_mode: "save_factors_only",
      dbPath,
    });
    const restoredCodes = restored.snapshot.used_factors.map((factor) => factor.code);
    expect(restoredCodes).toContain(FactorCode.SYMPTOM_PAIN);
  });

  it("excludes expired factors during aggregation", () => {
    const now = new Date("2025-02-01T00:00:00.000Z");
    const factors: Factor[] = [
      makeFactor({
        id: "f1",
        code: FactorCode.SYMPTOM_PAIN,
        created_at: "2025-01-26T00:00:00.000Z",
        time_horizon: "acute",
      }),
      makeFactor({
        id: "f2",
        code: FactorCode.MEDICAL_CHRONIC_CONDITION_MENTIONED,
        created_at: "2024-12-01T00:00:00.000Z",
        time_horizon: "chronic",
      }),
      makeFactor({
        id: "f3",
        code: FactorCode.ACCESS_COST_BARRIER,
        created_at: "2025-01-15T00:00:00.000Z",
        time_horizon: "unknown",
      }),
    ];

    const profile = buildComplexityProfile(factors, { now });
    expect(profile.factors_by_code[FactorCode.SYMPTOM_PAIN]).toBeUndefined();
    expect(
      profile.factors_by_code[FactorCode.MEDICAL_CHRONIC_CONDITION_MENTIONED],
    ).toBeDefined();
    expect(profile.factors_by_code[FactorCode.ACCESS_COST_BARRIER]).toBeUndefined();
  });
});

describe("next step routing", () => {
  it("routes urgent risk to urgent care with safety net", () => {
    const result = routeNextStep(
      makeSnapshot({
        risk_band: "urgent",
        next_action_kind: "safety_escalation",
      }),
    );
    expect(result.category).toBe("urgent_care_ed");
    expect(result.safety_net).toBeDefined();
  });

  it("routes medium risk with low friction to pharmacist", () => {
    const result = routeNextStep(
      makeSnapshot({ risk_band: "medium", friction_band: "low" }),
    );
    expect(result.category).toBe("pharmacist");
  });

  it("routes medium risk with high friction to GP or telehealth", () => {
    const result = routeNextStep(
      makeSnapshot({ risk_band: "medium", friction_band: "high" }),
    );
    expect(result.category).toBe("gp_telehealth");
  });

  it("routes low risk to self-care", () => {
    const result = routeNextStep(makeSnapshot({ risk_band: "low" }));
    expect(result.category).toBe("self_care");
  });
});
