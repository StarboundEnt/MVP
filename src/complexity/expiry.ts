import { Factor, FactorCode } from "./factors";

const FOURTEEN_DAYS_MS = 14 * 24 * 60 * 60 * 1000;
const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;
const SEVENTY_TWO_HOURS_MS = 72 * 60 * 60 * 1000;

const CONSTRAINT_CODES = new Set<FactorCode>([
  FactorCode.ACCESS_COST_BARRIER,
  FactorCode.ACCESS_APPOINTMENT_BARRIER,
  FactorCode.RESOURCE_TIME_PRESSURE,
]);

export const getFactorTTL = (
  code: FactorCode,
  time_horizon: Factor["time_horizon"],
): number | null => {
  if (time_horizon === "chronic" || time_horizon === "life_course") {
    return null;
  }

  if (CONSTRAINT_CODES.has(code)) {
    return FOURTEEN_DAYS_MS;
  }

  if (time_horizon === "acute") {
    return SEVENTY_TWO_HOURS_MS;
  }

  if (time_horizon === "unknown") {
    return SEVEN_DAYS_MS;
  }

  return null;
};
