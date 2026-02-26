import { initLocalDb } from "./persistence";

export interface PendingFollowUp {
  id: string;
  parent_event_id: string;
  question_text: string;
  missing_info_key?: string;
  created_at: string;
}

const ensureFollowUpTable = (dbPath?: string): void => {
  const db = initLocalDb(dbPath);
  db.exec(`
    CREATE TABLE IF NOT EXISTS pending_followups (
      id TEXT PRIMARY KEY,
      parent_event_id TEXT NOT NULL,
      question_text TEXT NOT NULL,
      missing_info_key TEXT,
      created_at TEXT NOT NULL
    );
  `);
};

export const setPendingFollowUp = async (
  pfu: PendingFollowUp,
  dbPath?: string,
): Promise<void> => {
  ensureFollowUpTable(dbPath);
  const db = initLocalDb(dbPath);
  db.exec(`DELETE FROM pending_followups;`);
  const statement = db.prepare(`
    INSERT OR REPLACE INTO pending_followups (
      id, parent_event_id, question_text, missing_info_key, created_at
    )
    VALUES (
      @id, @parent_event_id, @question_text, @missing_info_key, @created_at
    );
  `);
  statement.run({
    id: pfu.id,
    parent_event_id: pfu.parent_event_id,
    question_text: pfu.question_text,
    missing_info_key: pfu.missing_info_key ?? null,
    created_at: pfu.created_at,
  });
};

export const getPendingFollowUp = async (
  dbPath?: string,
): Promise<PendingFollowUp | null> => {
  ensureFollowUpTable(dbPath);
  const db = initLocalDb(dbPath);
  const statement = db.prepare(`
    SELECT id, parent_event_id, question_text, missing_info_key, created_at
    FROM pending_followups
    ORDER BY created_at DESC
    LIMIT 1;
  `);
  const rows = statement.all ? statement.all() : [];
  const row = rows[0] as PendingFollowUp | undefined;
  return row ?? null;
};

export const clearPendingFollowUp = async (dbPath?: string): Promise<void> => {
  ensureFollowUpTable(dbPath);
  const db = initLocalDb(dbPath);
  db.exec(`DELETE FROM pending_followups;`);
};
