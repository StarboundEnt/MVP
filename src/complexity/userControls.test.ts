import { processSmartInput } from "./processSmartInput";
import {
  clearSessionContext,
  getSessionUseProfile,
  getUseSavedContext,
  setSessionUseProfile,
  setUseSavedContext,
} from "./userControls";
import { getPendingFollowUp } from "./followup";

const makeDbPath = (label: string): string =>
  `/tmp/controls_${label}_${Date.now()}_${Math.random()
    .toString(36)
    .slice(2, 8)}.sqlite`;

describe("user controls", () => {
  it("disables stored profile influence when use_saved_context is off", async () => {
    const dbPath = makeDbPath("nosave");
    setUseSavedContext(true, dbPath);

    await processSmartInput({
      inputText: "I've got a headache.",
      intent: "ASK",
      save_mode: "save_factors_only",
      dbPath,
    });

    setUseSavedContext(false, dbPath);
    const result = await processSmartInput({
      inputText: "Just checking in.",
      intent: "ASK",
      save_mode: "save_factors_only",
      dbPath,
    });

    expect(Object.keys(result.profile.factors_by_code)).toHaveLength(0);
  });

  it("clears pending follow-up and resets session use profile", async () => {
    const dbPath = makeDbPath("clear");
    await processSmartInput({
      inputText: "I've got a headache.",
      intent: "ASK",
      save_mode: "save_factors_only",
      dbPath,
    });

    expect(await getPendingFollowUp(dbPath)).not.toBeNull();
    setSessionUseProfile(false);
    clearSessionContext(dbPath);

    expect(await getPendingFollowUp(dbPath)).toBeNull();
    expect(getSessionUseProfile()).toBe(true);
  });

  it("returns persisted setting defaults", () => {
    const dbPath = makeDbPath("defaults");
    const defaultValue = getUseSavedContext(dbPath);
    expect(typeof defaultValue).toBe("boolean");
  });
});
