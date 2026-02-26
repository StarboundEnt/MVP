import { clearPendingFollowUp } from "./followup";
import { initLocalDb } from "./persistence";

type UserControlKey = "use_saved_context";

const DEFAULT_USE_SAVED_CONTEXT = true;
let sessionUseProfile = true;
let activeDbPath: string | undefined;

const ensureUserControlsTable = (dbPath?: string): void => {
  const db = initLocalDb(dbPath);
  db.exec(`
    CREATE TABLE IF NOT EXISTS user_controls (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  `);
};

const resolveDbPath = (dbPath?: string): string | undefined => {
  if (dbPath) {
    activeDbPath = dbPath;
    return dbPath;
  }
  return activeDbPath;
};

const readBooleanSetting = (
  key: UserControlKey,
  defaultValue: boolean,
  dbPath?: string,
): boolean => {
  const resolvedPath = resolveDbPath(dbPath);
  ensureUserControlsTable(resolvedPath);
  const db = initLocalDb(resolvedPath);
  const statement = db.prepare(`
    SELECT value FROM user_controls WHERE key = @key;
  `);
  const rows = statement.all ? statement.all({ key }) : [];
  const row = rows[0] as { value?: string } | undefined;
  if (!row || row.value == null) {
    return defaultValue;
  }
  return row.value === "true";
};

const writeBooleanSetting = (
  key: UserControlKey,
  value: boolean,
  dbPath?: string,
): void => {
  const resolvedPath = resolveDbPath(dbPath);
  ensureUserControlsTable(resolvedPath);
  const db = initLocalDb(resolvedPath);
  const statement = db.prepare(`
    INSERT OR REPLACE INTO user_controls (key, value)
    VALUES (@key, @value);
  `);
  statement.run({ key, value: value ? "true" : "false" });
};

export const setUseSavedContext = (enabled: boolean, dbPath?: string): void => {
  writeBooleanSetting("use_saved_context", enabled, dbPath);
};

export const getUseSavedContext = (dbPath?: string): boolean =>
  readBooleanSetting("use_saved_context", DEFAULT_USE_SAVED_CONTEXT, dbPath);

export const setSessionUseProfile = (enabled: boolean): void => {
  sessionUseProfile = enabled;
};

export const getSessionUseProfile = (): boolean => sessionUseProfile;

export const clearSessionContext = (dbPath?: string): void => {
  sessionUseProfile = true;
  void clearPendingFollowUp(resolveDbPath(dbPath));
};
