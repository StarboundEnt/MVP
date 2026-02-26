import { formatUsedFactorsForUI } from "./explainability";
import { StateSnapshot } from "./state";
import { getSessionUseProfile, getUseSavedContext } from "./userControls";

export type WhatImUsingModel = {
  title: string;
  description: string;
  chips: ReturnType<typeof formatUsedFactorsForUI>;
  controls: {
    use_saved_context: boolean;
    session_use_profile: boolean;
  };
};

export const buildWhatImUsingModel = (
  snapshot: StateSnapshot,
): WhatImUsingModel => {
  const use_saved_context = getUseSavedContext();
  const session_use_profile = getSessionUseProfile();

  return {
    title: "What Starbound is using",
    description:
      "These are the signals being used right now. You can pause saved context or turn off profile use for this session.",
    chips: formatUsedFactorsForUI(snapshot.used_factors),
    controls: {
      use_saved_context,
      session_use_profile,
    },
  };
};
