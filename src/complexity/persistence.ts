import { Event } from "./events";
import { Factor } from "./factors";

type SqliteStatement = {
  run: (params?: Record<string, unknown>) => void;
  all?: (params?: Record<string, unknown>) => unknown[];
};

type SqliteDatabase = {
  prepare: (sql: string) => SqliteStatement;
  exec: (sql: string) => void;
  transaction?: (fn: () => void) => () => void;
};

const getDatabase = (path: string): SqliteDatabase => {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const DatabaseCtor = require("better-sqlite3");
  return new DatabaseCtor(path);
};

const schemaSql = `
  CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY,
    created_at TEXT NOT NULL,
    parent_event_id TEXT,
    intent TEXT NOT NULL,
    save_mode TEXT NOT NULL,
    raw_text TEXT
  );

  CREATE TABLE IF NOT EXISTS factors (
    id TEXT PRIMARY KEY,
    event_id TEXT NOT NULL,
    domain TEXT NOT NULL,
    type TEXT NOT NULL,
    code TEXT NOT NULL,
    value_json TEXT NOT NULL,
    confidence REAL NOT NULL,
    time_horizon TEXT NOT NULL,
    modifiability TEXT NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY(event_id) REFERENCES events(id)
  );

  CREATE INDEX IF NOT EXISTS idx_factors_event_id ON factors(event_id);
  CREATE INDEX IF NOT EXISTS idx_factors_code ON factors(code);
`;

const dbInstances = new Map<string, SqliteDatabase>();

const ensureEventColumn = (
  db: SqliteDatabase,
  column: string,
  columnType: string,
): void => {
  const statement = db.prepare(`PRAGMA table_info(events)`);
  const rows = statement.all ? statement.all() : [];
  const hasColumn = rows.some(
    (row) => (row as { name?: string }).name === column,
  );
  if (!hasColumn) {
    db.exec(`ALTER TABLE events ADD COLUMN ${column} ${columnType}`);
  }
};

export const initLocalDb = (
  path = "complexity_profile.sqlite",
): SqliteDatabase => {
  const resolvedPath = path || "complexity_profile.sqlite";
  const existing = dbInstances.get(resolvedPath);
  if (existing) {
    return existing;
  }

  const database = getDatabase(resolvedPath);
  database.exec(schemaSql);
  ensureEventColumn(database, "parent_event_id", "TEXT");
  dbInstances.set(resolvedPath, database);
  return database;
};

const serialiseValue = (value: Factor["value"]): string =>
  JSON.stringify(value);

export const saveEventAndFactors = (
  event: Event,
  factors: Factor[],
  options?: { dbPath?: string },
): void => {
  if (event.save_mode === "transient") {
    return;
  }

  const db = initLocalDb(options?.dbPath);
  const insertEvent = db.prepare(`
    INSERT OR REPLACE INTO events (
      id, created_at, parent_event_id, intent, save_mode, raw_text
    )
    VALUES (
      @id, @created_at, @parent_event_id, @intent, @save_mode, @raw_text
    );
  `);
  const insertFactor = db.prepare(`
    INSERT OR REPLACE INTO factors (
      id, event_id, domain, type, code, value_json,
      confidence, time_horizon, modifiability, created_at
    )
    VALUES (
      @id, @event_id, @domain, @type, @code, @value_json,
      @confidence, @time_horizon, @modifiability, @created_at
    );
  `);

  const rawText = event.save_mode === "save_journal" ? event.raw_text ?? null : null;
  const runSave = () => {
    insertEvent.run({
      id: event.id,
      created_at: event.created_at,
      parent_event_id: event.parent_event_id ?? null,
      intent: event.intent,
      save_mode: event.save_mode,
      raw_text: rawText,
    });

    for (const factor of factors) {
      insertFactor.run({
        id: factor.id,
        event_id: event.id,
        domain: factor.domain,
        type: factor.type,
        code: factor.code,
        value_json: serialiseValue(factor.value),
        confidence: factor.confidence,
        time_horizon: factor.time_horizon,
        modifiability: factor.modifiability,
        created_at: factor.created_at,
      });
    }
  };

  if (db.transaction) {
    db.transaction(runSave)();
  } else {
    runSave();
  }
};
