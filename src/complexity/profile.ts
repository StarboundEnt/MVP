import { ComplexityDomain } from "./domains";
import { Factor, FactorCode, FactorType } from "./factors";
import { getFactorTTL } from "./expiry";

export interface ComplexityProfile {
  updated_at: string;
  factors_by_code: Record<FactorCode, Factor>;
  top_constraints: Factor[];
  domains_coverage: Record<ComplexityDomain, { acute: number; chronic: number }>;
}

const parseTimestamp = (value: string): number => {
  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? 0 : parsed;
};

const compareByRecency = (left: Factor, right: Factor): number => {
  const leftTime = parseTimestamp(left.created_at);
  const rightTime = parseTimestamp(right.created_at);
  if (leftTime !== rightTime) {
    return rightTime - leftTime;
  }
  return right.confidence - left.confidence;
};

const isChronicHorizon = (horizon: Factor["time_horizon"]): boolean =>
  horizon === "chronic" || horizon === "life_course";

type BuildProfileOptions = {
  minConfidence?: number;
  suppressedCodes?: Set<FactorCode>;
  now?: Date;
};

export const buildComplexityProfile = (
  factors: Factor[],
  minConfidenceOrOptions: number | BuildProfileOptions = 0.7,
): ComplexityProfile => {
  const options: BuildProfileOptions =
    typeof minConfidenceOrOptions === "number"
      ? { minConfidence: minConfidenceOrOptions }
      : minConfidenceOrOptions;
  const minConfidence = options.minConfidence ?? 0.7;
  const suppressedCodes = options.suppressedCodes;
  const now = options.now ?? new Date();
  const latestByCode = new Map<FactorCode, Factor>();

  for (const factor of factors) {
    if (factor.confidence < minConfidence) continue;
    if (suppressedCodes?.has(factor.code)) continue;
    const ttl = getFactorTTL(factor.code, factor.time_horizon);
    if (ttl !== null) {
      const factorTime = parseTimestamp(factor.created_at);
      if (factorTime > 0 && now.getTime() - factorTime > ttl) {
        continue;
      }
    }
    const existing = latestByCode.get(factor.code);
    if (!existing) {
      latestByCode.set(factor.code, factor);
      continue;
    }
    const existingTime = parseTimestamp(existing.created_at);
    const candidateTime = parseTimestamp(factor.created_at);
    if (
      candidateTime > existingTime ||
      (candidateTime === existingTime &&
        factor.confidence >= existing.confidence)
    ) {
      latestByCode.set(factor.code, factor);
    }
  }

  const coverage: Record<ComplexityDomain, { acute: number; chronic: number }> =
    Object.values(ComplexityDomain).reduce((acc, domain) => {
      acc[domain] = { acute: 0, chronic: 0 };
      return acc;
    }, {} as Record<ComplexityDomain, { acute: number; chronic: number }>);

  for (const factor of latestByCode.values()) {
    if (isChronicHorizon(factor.time_horizon)) {
      coverage[factor.domain].chronic += 1;
    } else if (factor.time_horizon === "acute") {
      coverage[factor.domain].acute += 1;
    }
  }

  const constraintCandidates = Array.from(latestByCode.values())
    .filter(
      (factor) =>
        factor.type === FactorType.CONSTRAINED_CHOICE ||
        factor.domain === ComplexityDomain.RESOURCES_CONSTRAINTS ||
        factor.domain === ComplexityDomain.ACCESS_TO_CARE,
    )
    .sort(compareByRecency)
    .slice(0, 3);

  return {
    updated_at: now.toISOString(),
    factors_by_code: Object.fromEntries(
      latestByCode.entries(),
    ) as Record<FactorCode, Factor>,
    top_constraints: constraintCandidates,
    domains_coverage: coverage,
  };
};
