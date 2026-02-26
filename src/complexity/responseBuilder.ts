import { buildWhatImUsingModel } from "./whatImUsingModel";
import { NextStepCategory } from "./nextStepRouter";
import { StateSnapshot } from "./state";

export type ResponseMode =
  | "log_only"
  | "ask_followup"
  | "answer"
  | "safety_escalation";

export type ResponseModel = {
  mode: ResponseMode;
  title: string;
  what_matters: string[];
  followup_question?: string;
  next_step?: {
    category: NextStepCategory;
    heading: string;
    text: string;
    options?: string[];
  };
  safety_net?: string;
  what_im_using: ReturnType<typeof buildWhatImUsingModel>;
};

type RoutedNextStep = {
  category: NextStepCategory;
  rationale: string;
  safety_net?: string;
};

const NEXT_STEP_TEMPLATES: Record<
  NextStepCategory,
  { text: string; options: string[] }
> = {
  self_care: {
    text: "Gentle self-care is a good next step for now.",
    options: ["Rest and hydrate", "Keep things light today", "Check in later"],
  },
  pharmacist: {
    text: "A pharmacist can help with practical options and advice.",
    options: [
      "Speak with a local pharmacist",
      "Ask about over-the-counter options",
      "Check interactions or side effects",
    ],
  },
  gp_telehealth: {
    text: "A GP or telehealth consult can help plan next steps.",
    options: [
      "Book a GP appointment",
      "Use a telehealth service",
      "Bring notes on symptoms and timing",
    ],
  },
  urgent_care_ed: {
    text: "Getting urgent care now may be the safest option.",
    options: ["Go to urgent care or ED", "Call 000", "Ask someone to go with you"],
  },
  crisis_support: {
    text: "You deserve immediate support and care.",
    options: [
      "Reach out to a crisis line",
      "Contact someone you trust",
      "Seek urgent support now",
    ],
  },
};

const buildNextStep = (routed: RoutedNextStep) => {
  const template = NEXT_STEP_TEMPLATES[routed.category];
  return {
    category: routed.category,
    heading: "Next step",
    text: template.text,
    options: template.options,
  };
};

export const buildResponseModel = (
  snapshot: StateSnapshot,
  routed: RoutedNextStep,
): ResponseModel => {
  const what_im_using = buildWhatImUsingModel(snapshot);

  if (snapshot.next_action_kind === "log_only") {
    return {
      mode: "log_only",
      title: "Saved",
      what_matters: snapshot.what_matters,
      what_im_using,
    };
  }

  if (snapshot.next_action_kind === "ask_followup") {
    return {
      mode: "ask_followup",
      title: "One quick question",
      what_matters: snapshot.what_matters,
      followup_question: snapshot.followup_question,
      what_im_using,
    };
  }

  if (
    snapshot.next_action_kind === "safety_escalation" ||
    routed.category === "urgent_care_ed" ||
    routed.category === "crisis_support"
  ) {
    return {
      mode: "safety_escalation",
      title: "It may be safer to get help now",
      what_matters: snapshot.what_matters,
      next_step: buildNextStep(routed),
      safety_net: routed.safety_net ?? snapshot.safety_copy,
      what_im_using,
    };
  }

  return {
    mode: "answer",
    title: "Here’s what matters",
    what_matters: snapshot.what_matters,
    next_step: buildNextStep(routed),
    safety_net: routed.safety_net,
    what_im_using,
  };
};
