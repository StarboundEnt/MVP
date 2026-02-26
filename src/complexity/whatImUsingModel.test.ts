import { buildWhatImUsingModel } from "./whatImUsingModel";
import { FactorCode } from "./factors";
import { StateSnapshot } from "./state";
import { setSessionUseProfile, setUseSavedContext } from "./userControls";
import { ComplexityDomain } from "./domains";

const makeSnapshot = (usedCodes: FactorCode[]): StateSnapshot => ({
  event_id: "evt-1",
  created_at: "2025-02-01T00:00:00.000Z",
  intent: "ASK",
  risk_band: "low",
  friction_band: "low",
  uncertainty_band: "low",
  next_action_kind: "answer",
  what_matters: [],
  used_factors: usedCodes.map((code, index) => ({
    code,
    domain: ComplexityDomain.SYMPTOMS_BODY_SIGNALS,
    confidence: 0.9 - index * 0.05,
  })),
});

describe("buildWhatImUsingModel", () => {
  it("returns max 6 chips and exposes control flags", () => {
    const dbPath = `/tmp/what_im_using_${Date.now()}.sqlite`;
    setUseSavedContext(false, dbPath);
    setSessionUseProfile(false);

    const snapshot = makeSnapshot([
      FactorCode.SYMPTOM_PAIN,
      FactorCode.SYMPTOM_HEADACHE,
      FactorCode.SYMPTOM_NAUSEA,
      FactorCode.CAPACITY_FATIGUE,
      FactorCode.ACCESS_COST_BARRIER,
      FactorCode.RESOURCE_TIME_PRESSURE,
      FactorCode.EMOTION_ANXIETY_STRESS,
    ]);

    const model = buildWhatImUsingModel(snapshot);
    expect(model.chips.length).toBeLessThanOrEqual(6);
    expect(model.controls.use_saved_context).toBe(false);
    expect(model.controls.session_use_profile).toBe(false);

    setUseSavedContext(true, dbPath);
    setSessionUseProfile(true);
  });
});
