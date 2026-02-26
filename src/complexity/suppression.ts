import { FactorCode } from "./factors";
import { initLocalDb } from "./persistence";

const ensureSuppressionTable = (dbPath?: string): void => {
  const db = initLocalDb(dbPath);
  db.exec(`
    CREATE TABLE IF NOT EXISTS suppressed_factor_codes (
      code TEXT PRIMARY KEY,
      suppressed_at TEXT NOT NULL
    );
  `);
};

export const suppressFactorCode = async (
  code: FactorCode,
  dbPath?: string,
): Promise<void> => {
  ensureSuppressionTable(dbPath);
  const db = initLocalDb(dbPath);
  const statement = db.prepare(`
    INSERT OR REPLACE INTO suppressed_factor_codes (code, suppressed_at)
    VALUES (@code, @suppressed_at);
  `);
  statement.run({
    code,
    suppressed_at: new Date().toISOString(),
  });
};

export const unsuppressFactorCode = async (
  code: FactorCode,
  dbPath?: string,
): Promise<void> => {
  ensureSuppressionTable(dbPath);
  const db = initLocalDb(dbPath);
  const statement = db.prepare(`
    DELETE FROM suppressed_factor_codes WHERE code = @code;
  `);
  statement.run({ code });
};

export const getSuppressedFactorCodes = async (
  dbPath?: string,
): Promise<Set<FactorCode>> => {
  ensureSuppressionTable(dbPath);
  const db = initLocalDb(dbPath);
  const statement = db.prepare(`
    SELECT code FROM suppressed_factor_codes;
  `);
  const rows = statement.all ? statement.all() : [];
  const result = new Set<FactorCode>();
  for (const row of rows as Array<{ code?: string }>) {
    if (row.code) {
      result.add(row.code as FactorCode);
    }
  }
  return result;
};
