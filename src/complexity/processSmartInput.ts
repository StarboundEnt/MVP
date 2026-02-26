import { classifyDomains } from "./classifyDomains";
import { extractFactors } from "./extractFactors";
import { buildStateSnapshot } from "./buildStateSnapshot";
import { ComplexityDomain } from "./domains";
import { Event, EventSaveMode } from "./events";
import { Factor, FactorCode, MissingInfo } from "./factors";
import { saveEventAndFactors, initLocalDb } from "./persistence";
import { buildComplexityProfile } from "./profile";
import { getSuppressedFactorCodes } from "./suppression";
import { getSessionUseProfile, getUseSavedContext } from "./userControls";
import { routeNextStep } from "./nextStepRouter";
import { buildResponseModel } from "./responseBuilder";
import {
  clearPendingFollowUp,
  getPendingFollowUp,
  setPendingFollowUp,
} from "./followup";
import { DomainClassificationResult, EventIntent } from "./types";
import { buildDebugModel } from "./debugModel";

type ProcessSmartInputArgs = {
  inputText: string;
  intent: EventIntent;
  save_mode: EventSaveMode;
  event_id?: string;
  created_at?: string;
  dbPath?: string;
  includeDebug?: boolean;
};

export type ExtractedPayload = {
  factors: Factor[];
  missing_info?: MissingInfo[];
};

const generateId = (prefix: string): string =>
  `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

const symptomCodes = new Set<FactorCode>([
  FactorCode.SYMPTOM_PAIN,
  FactorCode.SYMPTOM_DIZZINESS,
  FactorCode.SYMPTOM_NAUSEA,
  FactorCode.SYMPTOM_BREATHLESSNESS,
  FactorCode.SYMPTOM_HEADACHE,
]);

const loadPersistedFactors = (dbPath?: string): Factor[] => {
  const db = initLocalDb(dbPath);
  const statement = db.prepare(`
    SELECT id, event_id, domain, type, code, value_json,
           confidence, time_horizon, modifiability, created_at
    FROM factors;
  `);
  const rows = statement.all ? statement.all() : [];
  return (rows as Array<Record<string, unknown>>).map((row) => ({
    id: String(row.id),
    domain: row.domain as ComplexityDomain,
    type: row.type as Factor["type"],
    code: row.code as FactorCode,
    value: row.value_json ? JSON.parse(String(row.value_json)) : true,
    confidence: Number(row.confidence),
    time_horizon: row.time_horizon as Factor["time_horizon"],
    modifiability: row.modifiability as Factor["modifiability"],
    source_event_id: String(row.event_id),
    created_at: String(row.created_at),
  }));
};

const filterMissingInfo = (
  missingInfo: MissingInfo[] | undefined,
  factors: Factor[],
): MissingInfo[] | undefined => {
  if (!missingInfo || missingInfo.length === 0) return undefined;
  const hasSymptom = factors.some((factor) => symptomCodes.has(factor.code));
  const filtered = missingInfo.filter((info) => {
    if (info.key === "duration") {
      return hasSymptom;
    }
    return true;
  });
  return filtered.length > 0 ? filtered : undefined;
};

export const processSmartInput = async (
  args: ProcessSmartInputArgs,
): Promise<{
  event: Event;
  domainResult: DomainClassificationResult;
  extracted: ExtractedPayload;
  profile: ReturnType<typeof buildComplexityProfile>;
  snapshot: ReturnType<typeof buildStateSnapshot>;
  responseModel: ReturnType<typeof buildResponseModel>;
  debugModel?: ReturnType<typeof buildDebugModel>;
}> => {
  const pending = await getPendingFollowUp(args.dbPath);
  const useSavedContext = getUseSavedContext(args.dbPath);
  const sessionUseProfile = getSessionUseProfile();
  const allowProfile = useSavedContext && sessionUseProfile;
  const forcedIntent: EventIntent = pending ? "FOLLOW_UP" : args.intent;
  const previousQuestion = pending?.question_text;

  const event: Event = {
    id: args.event_id ?? generateId("evt"),
    created_at: args.created_at ?? new Date().toISOString(),
    parent_event_id: pending?.parent_event_id,
    intent: forcedIntent,
    save_mode: args.save_mode,
    raw_text: args.save_mode === "save_journal" ? args.inputText : undefined,
  };

  const domainResult = classifyDomains(
    args.inputText,
    forcedIntent,
    previousQuestion,
  );

  const extracted = extractFactors(
    args.inputText,
    domainResult,
    forcedIntent,
    event.id,
  );

  const suppressedCodes = await getSuppressedFactorCodes(args.dbPath);
  const filteredFactors = extracted.factors.filter(
    (factor) => !suppressedCodes.has(factor.code),
  );
  const filteredMissingInfo = filterMissingInfo(
    extracted.missing_info,
    filteredFactors,
  );
  const filteredExtracted: ExtractedPayload = {
    factors: filteredFactors,
    missing_info: filteredMissingInfo,
  };

  const shouldPersist =
    args.save_mode !== "transient" &&
    (allowProfile || args.save_mode === "save_journal");
  if (shouldPersist) {
    saveEventAndFactors(event, filteredFactors, { dbPath: args.dbPath });
  }

  const profile = allowProfile
    ? buildComplexityProfile(
        [...loadPersistedFactors(args.dbPath), ...filteredFactors],
        { suppressedCodes },
      )
    : buildComplexityProfile(filteredFactors, { suppressedCodes });

  const snapshot = buildStateSnapshot(
    event,
    domainResult,
    filteredExtracted,
    profile,
  );
  const routed = routeNextStep(snapshot);
  const responseModel = buildResponseModel(snapshot, routed);

  if (pending) {
    await clearPendingFollowUp(args.dbPath);
  }

  if (
    snapshot.next_action_kind === "ask_followup" &&
    snapshot.followup_question &&
    snapshot.risk_band !== "urgent" &&
    event.intent !== "LOG_ONLY"
  ) {
    await setPendingFollowUp(
      {
        id: generateId("pfu"),
        parent_event_id: event.id,
        question_text: snapshot.followup_question,
        missing_info_key: filteredMissingInfo?.[0]?.key,
        created_at: new Date().toISOString(),
      },
      args.dbPath,
    );
  }

  const debugModel = args.includeDebug
    ? buildDebugModel({
        domainResult,
        extracted: filteredExtracted,
        snapshot,
        routerCategory: routed.category,
        toggles: {
          use_saved_context: useSavedContext,
          session_use_profile: sessionUseProfile,
        },
        pendingFollowUp: await getPendingFollowUp(args.dbPath),
      })
    : undefined;

  return {
    event,
    domainResult,
    extracted: filteredExtracted,
    profile,
    snapshot,
    responseModel,
    debugModel,
  };
};
