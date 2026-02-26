import '../models/complexity_engine_models.dart';

const int maxFollowupsPerThread = 2;

enum QuestionType {
  symptomClarify,
  duration,
  severityImpact,
  progression,
  redFlags,
  contextTrigger,
}

FollowUpPlan? chooseNextFollowUp(
  String inputText,
  List<Factor> factors,
  String? symptomKey,
  int followUpCount,
  RiskBand riskBand,
) {
  if (riskBand == RiskBand.urgent) return null;
  if (followUpCount >= maxFollowupsPerThread) return null;

  if (followUpCount >= 1 &&
      (riskBand == RiskBand.low || riskBand == RiskBand.medium)) {
    return null;
  }

  final hasSymptoms = factors.any(
    (factor) => factor.domain == ComplexityDomain.symptomsBodySignals,
  );
  if (!hasSymptoms && (symptomKey == null || symptomKey.isEmpty)) {
    return null;
  }

  final hasDuration = _hasAnyFactor(factors, const {
    FactorCode.durationOnsetRecent,
    FactorCode.durationDaysWeeks,
    FactorCode.durationMonthsPlus,
    FactorCode.durationToday,
    FactorCode.durationFewDays,
    FactorCode.durationWeekPlus,
    FactorCode.patternRecurring,
  });
  final hasSeverity = _hasAnyFactor(factors, const {
    FactorCode.severityMild,
    FactorCode.severityModerate,
    FactorCode.severitySevere,
  });
  final hasProgression = _hasAnyFactor(factors, const {
    FactorCode.trendBetter,
    FactorCode.trendWorse,
    FactorCode.trendSame,
  });
  final hasContext = _hasAnyFactor(factors, const {
    FactorCode.contextTriggerInjury,
    FactorCode.contextTriggerMedication,
    FactorCode.contextTriggerIllness,
  });

  if (!hasDuration) {
    return _durationPlan();
  }
  if (!hasSeverity) {
    return _severityPlan(symptomKey);
  }
  if (!hasProgression) {
    return _progressionPlan();
  }
  if (symptomKey == null || symptomKey.isEmpty) {
    return _symptomClarifyPlan();
  }
  if (!hasContext) {
    return _contextTriggerPlan();
  }

  return null;
}

bool _hasAnyFactor(List<Factor> factors, Set<FactorCode> codes) {
  return factors.any((factor) => codes.contains(factor.code));
}

FollowUpPlan _durationPlan() {
  return FollowUpPlan(
    questionText: 'How long has this been happening?',
    choices: const [
      FollowUpChoice(
        label: 'Today',
        writesFactors: [
          FactorWrite(
            code: FactorCode.durationToday,
            confidence: 0.95,
            timeHorizon: FactorTimeHorizon.acute,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'A few days',
        writesFactors: [
          FactorWrite(
            code: FactorCode.durationFewDays,
            confidence: 0.95,
            timeHorizon: FactorTimeHorizon.acute,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'A week or more',
        writesFactors: [
          FactorWrite(
            code: FactorCode.durationWeekPlus,
            confidence: 0.95,
            timeHorizon: FactorTimeHorizon.chronic,
          ),
        ],
      ),
      FollowUpChoice(label: 'Not sure'),
      FollowUpChoice(label: 'Skip'),
    ],
  );
}

FollowUpPlan _severityPlan(String? symptomKey) {
  final isVomiting = symptomKey == 'vomiting' || symptomKey == 'nausea';
  if (isVomiting) {
    return FollowUpPlan(
      questionText: 'Have you been able to keep fluids down?',
      choices: const [
        FollowUpChoice(
          label: 'Yes, mostly',
          writesFactors: [
            FactorWrite(
              code: FactorCode.severityMild,
              confidence: 0.95,
            ),
          ],
        ),
        FollowUpChoice(
          label: 'A bit, not much',
          writesFactors: [
            FactorWrite(
              code: FactorCode.severityModerate,
              confidence: 0.95,
            ),
          ],
        ),
        FollowUpChoice(
          label: 'No, not really',
          writesFactors: [
            FactorWrite(
              code: FactorCode.severitySevere,
              confidence: 0.95,
            ),
          ],
        ),
        FollowUpChoice(label: 'Skip'),
      ],
    );
  }

  return FollowUpPlan(
    questionText: 'How much is it affecting you right now?',
    choices: const [
      FollowUpChoice(
        label: 'Mild / manageable',
        writesFactors: [
          FactorWrite(
            code: FactorCode.severityMild,
            confidence: 0.95,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'Moderate / getting in the way',
        writesFactors: [
          FactorWrite(
            code: FactorCode.severityModerate,
            confidence: 0.95,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'Severe / hard to function',
        writesFactors: [
          FactorWrite(
            code: FactorCode.severitySevere,
            confidence: 0.95,
          ),
        ],
      ),
      FollowUpChoice(label: 'Skip'),
    ],
  );
}

FollowUpPlan _progressionPlan() {
  return FollowUpPlan(
    questionText: 'Is it getting better, worse, or staying about the same?',
    choices: const [
      FollowUpChoice(
        label: 'Better',
        writesFactors: [
          FactorWrite(
            code: FactorCode.trendBetter,
            confidence: 0.95,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'Worse',
        writesFactors: [
          FactorWrite(
            code: FactorCode.trendWorse,
            confidence: 0.95,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'About the same',
        writesFactors: [
          FactorWrite(
            code: FactorCode.trendSame,
            confidence: 0.95,
          ),
        ],
      ),
      FollowUpChoice(label: 'Skip'),
    ],
  );
}

FollowUpPlan _symptomClarifyPlan() {
  return FollowUpPlan(
    questionText: 'Where in your body is it most noticeable?',
    choices: const [
      FollowUpChoice(
        label: 'Head',
        writesFactors: [
          FactorWrite(
            code: FactorCode.symptomHeadache,
            confidence: 0.9,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'Stomach',
        writesFactors: [
          FactorWrite(
            code: FactorCode.symptomNausea,
            confidence: 0.9,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'Breathing or chest',
        writesFactors: [
          FactorWrite(
            code: FactorCode.symptomBreathlessness,
            confidence: 0.9,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'General pain or soreness',
        writesFactors: [
          FactorWrite(
            code: FactorCode.symptomPain,
            confidence: 0.9,
          ),
        ],
      ),
      FollowUpChoice(label: 'Skip'),
    ],
  );
}

FollowUpPlan _contextTriggerPlan() {
  return FollowUpPlan(
    questionText: 'Did this start after an injury, new medication, or illness?',
    choices: const [
      FollowUpChoice(
        label: 'Injury or irritation',
        writesFactors: [
          FactorWrite(
            code: FactorCode.contextTriggerInjury,
            confidence: 0.95,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'New medication',
        writesFactors: [
          FactorWrite(
            code: FactorCode.contextTriggerMedication,
            confidence: 0.95,
          ),
        ],
      ),
      FollowUpChoice(
        label: 'Illness or infection',
        writesFactors: [
          FactorWrite(
            code: FactorCode.contextTriggerIllness,
            confidence: 0.95,
          ),
        ],
      ),
      FollowUpChoice(label: 'No clear trigger'),
      FollowUpChoice(label: 'Skip'),
    ],
  );
}
