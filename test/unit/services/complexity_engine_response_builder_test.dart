import 'package:flutter_test/flutter_test.dart';
import 'package:starbound/models/complexity_engine_models.dart';
import 'package:starbound/services/complexity_engine_rules.dart';

void main() {
  test('ask_followup invariants enforced', () {
    const snapshot = StateSnapshot(
      eventId: 'evt-1',
      createdAt: '2025-02-01T00:00:00.000Z',
      intent: EventIntent.ask,
      riskBand: RiskBand.low,
      frictionBand: FrictionBand.low,
      uncertaintyBand: UncertaintyBand.high,
      nextActionKind: NextActionKind.askFollowup,
      whatMatters: ['One quick detail can help narrow this down.'],
      followupQuestion: null,
      safetyCopy: null,
      usedFactors: [],
    );

    final routed = routeNextStep(snapshot);
    final whatImUsing = buildWhatImUsingModel(
      snapshot,
      useSavedContext: true,
      sessionUseProfile: true,
    );
    const followUpPlan = FollowUpPlan(
      questionText: 'How long has this been happening?',
      choices: [
        FollowUpChoice(label: 'Today'),
        FollowUpChoice(label: 'A few days'),
        FollowUpChoice(label: 'Skip'),
      ],
    );
    final model = buildResponseModel(
      'I feel dizzy.',
      snapshot,
      routed,
      whatImUsing,
      const [],
      followUpPlan: followUpPlan,
    );

    expect(model.mode, ResponseMode.askFollowup);
    expect(model.followUpPlan, isNotNull);
    expect(model.followUpPlan!.questionText, isNotEmpty);
    expect(model.whatToDoNow, isEmpty);
    expect(model.safetyNet, isNull);
  });
}
