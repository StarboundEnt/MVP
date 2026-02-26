import { FactorCode } from "./factors";
import { StateSnapshot } from "./state";

export type NextStepCategory =
  | "self_care"
  | "pharmacist"
  | "gp_telehealth"
  | "urgent_care_ed"
  | "crisis_support";

const SAFETY_NET_COPY =
  "If you feel unsafe or symptoms get worse, call 000 or seek urgent care.";

const hasSelfHarmSignal = (snapshot: StateSnapshot): boolean =>
  snapshot.used_factors.some((factor) => factor.code === FactorCode.SAFETY_SELF_HARM);

export const routeNextStep = (
  snapshot: StateSnapshot,
): { category: NextStepCategory; rationale: string; safety_net?: string } => {
  if (hasSelfHarmSignal(snapshot)) {
    return {
      category: "crisis_support",
      rationale: "You deserve immediate support right now.",
      safety_net: SAFETY_NET_COPY,
    };
  }

  if (
    snapshot.next_action_kind === "safety_escalation" ||
    snapshot.risk_band === "urgent"
  ) {
    return {
      category: "urgent_care_ed",
      rationale: "Urgent safety signals mean rapid care is the safest option.",
      safety_net: SAFETY_NET_COPY,
    };
  }

  if (
    snapshot.uncertainty_band === "high" &&
    snapshot.next_action_kind === "ask_followup"
  ) {
    return {
      category: "self_care",
      rationale: "Need one more detail to guide the next step.",
    };
  }

  if (snapshot.risk_band === "high") {
    if (snapshot.friction_band === "high") {
      return {
        category: "urgent_care_ed",
        rationale: "Higher risk with high friction suggests urgent care.",
        safety_net: SAFETY_NET_COPY,
      };
    }
    return {
      category: "gp_telehealth",
      rationale: "Higher risk points to GP or telehealth support.",
    };
  }

  if (snapshot.risk_band === "medium") {
    if (snapshot.friction_band === "high") {
      return {
        category: "gp_telehealth",
        rationale: "Medium risk with high friction needs GP support.",
      };
    }
    return {
      category: "pharmacist",
      rationale: "A pharmacist can help with the next step.",
    };
  }

  return {
    category: "self_care",
    rationale: "Low risk points to self-care for now.",
  };
};
