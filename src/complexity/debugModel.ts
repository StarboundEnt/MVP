import { DomainClassificationResult } from "./types";
import { StateSnapshot } from "./state";
import { NextStepCategory } from "./nextStepRouter";
import { PendingFollowUp } from "./followup";
import { Factor, MissingInfo } from "./factors";

export type DebugModel = {
  domains: DomainClassificationResult;
  factors: Factor[];
  missing_info?: MissingInfo[];
  snapshotBands: {
    risk_band: StateSnapshot["risk_band"];
    friction_band: StateSnapshot["friction_band"];
    uncertainty_band: StateSnapshot["uncertainty_band"];
    next_action_kind: StateSnapshot["next_action_kind"];
  };
  routerCategory: NextStepCategory;
  toggles: {
    use_saved_context: boolean;
    session_use_profile: boolean;
  };
  pendingFollowUp: PendingFollowUp | null;
};

export const buildDebugModel = (args: {
  domainResult: DomainClassificationResult;
  extracted: { factors: Factor[]; missing_info?: MissingInfo[] };
  snapshot: StateSnapshot;
  routerCategory: NextStepCategory;
  toggles: { use_saved_context: boolean; session_use_profile: boolean };
  pendingFollowUp: PendingFollowUp | null;
}): DebugModel => ({
  domains: args.domainResult,
  factors: args.extracted.factors,
  missing_info: args.extracted.missing_info,
  snapshotBands: {
    risk_band: args.snapshot.risk_band,
    friction_band: args.snapshot.friction_band,
    uncertainty_band: args.snapshot.uncertainty_band,
    next_action_kind: args.snapshot.next_action_kind,
  },
  routerCategory: args.routerCategory,
  toggles: args.toggles,
  pendingFollowUp: args.pendingFollowUp,
});
