import { buildDebugModel } from "./debugModel";
import { ComplexityDomain } from "./domains";
import { FactorCode } from "./factors";
import { StateSnapshot } from "./state";
import { FactorType } from "./factors";

describe("buildDebugModel", () => {
  it("returns a minimal debug payload", () => {
    const snapshot: StateSnapshot = {
      event_id: "evt-1",
      created_at: "2025-02-01T00:00:00.000Z",
      intent: "ASK",
      risk_band: "low",
      friction_band: "low",
      uncertainty_band: "low",
      next_action_kind: "answer",
      what_matters: [],
      used_factors: [],
    };

    const debug = buildDebugModel({
      domainResult: {
        primary: { domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS, confidence: 0.9 },
        secondary: [],
      },
      extracted: {
        factors: [
          {
            id: "f1",
            domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
            type: FactorType.CHANCE,
            code: FactorCode.SYMPTOM_PAIN,
            value: true,
            confidence: 0.8,
            time_horizon: "acute",
            modifiability: "low",
            source_event_id: "evt-1",
            created_at: "2025-02-01T00:00:00.000Z",
          },
        ],
      },
      snapshot,
      routerCategory: "self_care",
      toggles: { use_saved_context: true, session_use_profile: true },
      pendingFollowUp: null,
    });

    expect(debug.snapshotBands.risk_band).toBe("low");
    expect(debug.routerCategory).toBe("self_care");
  });
});
