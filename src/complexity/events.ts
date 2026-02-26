import { EventIntent } from "./types";

export type EventSaveMode = "transient" | "save_journal" | "save_factors_only";

export interface Event {
  id: string;
  created_at: string;
  parent_event_id?: string;
  intent: EventIntent;
  save_mode: EventSaveMode;
  raw_text?: string;
}
