import { ComplexityDomain } from "./domains";
import { FactorCode } from "./factors";
import { EventIntent } from "./types";

export type RiskBand = "low" | "medium" | "high" | "urgent";
export type FrictionBand = "low" | "medium" | "high";
export type UncertaintyBand = "low" | "medium" | "high";
export type NextActionKind =
  | "answer"
  | "ask_followup"
  | "log_only"
  | "safety_escalation";

export interface StateSnapshot {
  event_id: string;
  created_at: string;
  intent: EventIntent;
  risk_band: RiskBand;
  friction_band: FrictionBand;
  uncertainty_band: UncertaintyBand;
  next_action_kind: NextActionKind;
  what_matters: string[];
  followup_question?: string;
  safety_copy?: string;
  used_factors: Array<{
    code: FactorCode;
    domain: ComplexityDomain;
    confidence: number;
  }>;
}
