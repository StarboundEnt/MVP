import { buildResponseModel } from "./responseBuilder";
import { NextStepCategory } from "./nextStepRouter";
import { StateSnapshot } from "./state";
import { FactorCode } from "./factors";
import { ComplexityDomain } from "./domains";

const makeSnapshot = (overrides: Partial<StateSnapshot>): StateSnapshot => ({
  event_id: "evt-1",
  created_at: "2025-02-01T00:00:00.000Z",
  intent: "ASK",
  risk_band: "low",
  friction_band: "low",
  uncertainty_band: "low",
  next_action_kind: "answer",
  what_matters: ["Pain is showing up."],
  used_factors: [
    {
      code: FactorCode.SYMPTOM_PAIN,
      domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
      confidence: 0.9,
    },
  ],
  ...overrides,
});

const makeRouted = (category: NextStepCategory) => ({
  category,
  rationale: "Testing rationale",
  safety_net: "Safety net copy",
});

describe("buildResponseModel", () => {
  it("returns log_only mode for log-only snapshots", () => {
    const model = buildResponseModel(
      makeSnapshot({ next_action_kind: "log_only" }),
      makeRouted("self_care"),
    );
    expect(model.mode).toBe("log_only");
    expect(model.next_step).toBeUndefined();
  });

  it("returns ask_followup mode with a question", () => {
    const model = buildResponseModel(
      makeSnapshot({
        next_action_kind: "ask_followup",
        followup_question: "How long has this been going on?",
      }),
      makeRouted("self_care"),
    );
    expect(model.mode).toBe("ask_followup");
    expect(model.followup_question).toBe(
      "How long has this been going on?",
    );
  });

  it("returns safety escalation with safety net", () => {
    const model = buildResponseModel(
      makeSnapshot({ next_action_kind: "answer", risk_band: "urgent" }),
      makeRouted("urgent_care_ed"),
    );
    expect(model.mode).toBe("safety_escalation");
    expect(model.safety_net).toBeDefined();
  });

  it("builds next steps for each category", () => {
    const categories: NextStepCategory[] = [
      "self_care",
      "pharmacist",
      "gp_telehealth",
      "urgent_care_ed",
      "crisis_support",
    ];

    for (const category of categories) {
      const model = buildResponseModel(
        makeSnapshot({ next_action_kind: "answer" }),
        makeRouted(category),
      );
      if (model.next_step) {
        expect(model.next_step.options?.length).toBeGreaterThanOrEqual(2);
      }
    }
  });

  it("includes what_im_using with a max of 6 chips", () => {
    const used_factors = Array.from({ length: 8 }).map((_, index) => ({
      code: FactorCode.SYMPTOM_PAIN,
      domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
      confidence: 0.9 - index * 0.05,
    }));
    const model = buildResponseModel(
      makeSnapshot({ used_factors }),
      makeRouted("self_care"),
    );
    expect(model.what_im_using.chips.length).toBeLessThanOrEqual(6);
  });
});
