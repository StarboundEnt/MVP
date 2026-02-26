import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:starbound/models/complexity_engine_models.dart';
import 'package:starbound/services/complexity_engine_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('headache triggers duration follow-up first', () async {
    final engine = ComplexityEngineService();

    final result = await engine.processSmartInput(
      inputText: 'Why do I have a headache?',
      intent: EventIntent.ask,
      saveMode: EventSaveMode.saveFactorsOnly,
    );

    expect(result.responseModel.mode, ResponseMode.askFollowup);
    expect(
      result.responseModel.followUpPlan?.questionText.toLowerCase(),
      contains('how long'),
    );
  });

  test('duration follow-up writes factors and returns answer', () async {
    final engine = ComplexityEngineService();

    final first = await engine.processSmartInput(
      inputText: 'Why do I have a headache?',
      intent: EventIntent.ask,
      saveMode: EventSaveMode.saveFactorsOnly,
    );

    final plan = first.responseModel.followUpPlan;
    expect(plan, isNotNull);

    final choice = plan!.choices.firstWhere(
      (item) => item.label.toLowerCase().contains('today'),
      orElse: () => plan.choices.first,
    );

    final second = await engine.processSmartInput(
      inputText: choice.label,
      intent: EventIntent.ask,
      saveMode: EventSaveMode.saveFactorsOnly,
      factorWrites: choice.writesFactors,
    );

    expect(second.responseModel.mode, ResponseMode.answer);
    expect(
      second.responseModel.keyFactors.join(' ').toLowerCase(),
      contains('today'),
    );
    expect(
      second.responseModel.whatToDoNow.any(
        (item) => item.title.toLowerCase().contains('reduce') ||
            item.title.toLowerCase().contains('hydrate'),
      ),
      isTrue,
    );
    expect(
      second.responseModel.whatToDoNow.every((item) => item.vaultPayload.isNotEmpty),
      isTrue,
    );
  });

  test('follow-up count stops at two and then answers', () async {
    final engine = ComplexityEngineService();

    final first = await engine.processSmartInput(
      inputText: 'I feel dizzy.',
      intent: EventIntent.ask,
      saveMode: EventSaveMode.saveFactorsOnly,
    );

    final plan = first.responseModel.followUpPlan;
    expect(plan, isNotNull);

    final skipChoice = plan!.choices.firstWhere(
      (item) => item.label.toLowerCase() == 'skip',
      orElse: () => plan.choices.last,
    );

    final second = await engine.processSmartInput(
      inputText: skipChoice.label,
      intent: EventIntent.ask,
      saveMode: EventSaveMode.saveFactorsOnly,
      factorWrites: skipChoice.writesFactors,
    );

    expect(second.responseModel.mode, ResponseMode.askFollowup);

    final secondPlan = second.responseModel.followUpPlan;
    expect(secondPlan, isNotNull);

    final secondSkip = secondPlan!.choices.firstWhere(
      (item) => item.label.toLowerCase() == 'skip',
      orElse: () => secondPlan.choices.last,
    );

    final third = await engine.processSmartInput(
      inputText: secondSkip.label,
      intent: EventIntent.ask,
      saveMode: EventSaveMode.saveFactorsOnly,
      factorWrites: secondSkip.writesFactors,
    );

    expect(third.responseModel.mode, ResponseMode.answer);
    expect(
      third.responseModel.keyFactors.join(' ').toLowerCase(),
      contains('unclear'),
    );
  });

  test('vomiting triggers fluids follow-up and safety bullets', () async {
    final engine = ComplexityEngineService();

    final first = await engine.processSmartInput(
      inputText: 'I just threw up.',
      intent: EventIntent.ask,
      saveMode: EventSaveMode.saveFactorsOnly,
    );

    expect(first.responseModel.mode, ResponseMode.askFollowup);
    expect(
      first.responseModel.followUpPlan?.questionText.toLowerCase(),
      contains('fluids'),
    );

    final plan = first.responseModel.followUpPlan!;
    final choice = plan.choices.firstWhere(
      (item) => item.label.toLowerCase().contains('no'),
      orElse: () => plan.choices.first,
    );

    final second = await engine.processSmartInput(
      inputText: choice.label,
      intent: EventIntent.ask,
      saveMode: EventSaveMode.saveFactorsOnly,
      factorWrites: choice.writesFactors,
    );

    expect(second.responseModel.mode, ResponseMode.answer);
    expect(
      second.responseModel.whatIfWorse.join(' ').toLowerCase(),
      contains('fluids'),
    );
  });

  test('journal save mode controls profile impact', () async {
    final engine = ComplexityEngineService();

    await engine.processSmartInput(
      inputText: 'Guided journal check-in',
      intent: EventIntent.journal,
      saveMode: EventSaveMode.transient,
      factorWrites: const [
        FactorWrite(code: FactorCode.resourceTimePressure),
      ],
    );

    final afterTransient = await engine.processSmartInput(
      inputText: 'What should I do?',
      intent: EventIntent.ask,
      saveMode: EventSaveMode.saveFactorsOnly,
    );

    expect(
      afterTransient.profile.factorsByCode
          .containsKey(FactorCode.resourceTimePressure),
      isFalse,
    );

    await engine.processSmartInput(
      inputText: 'Guided journal check-in',
      intent: EventIntent.journal,
      saveMode: EventSaveMode.saveFactorsOnly,
      factorWrites: const [
        FactorWrite(code: FactorCode.resourceTimePressure),
      ],
    );

    final afterPersisted = await engine.processSmartInput(
      inputText: 'What should I do?',
      intent: EventIntent.ask,
      saveMode: EventSaveMode.saveFactorsOnly,
    );

    expect(
      afterPersisted.profile.factorsByCode
          .containsKey(FactorCode.resourceTimePressure),
      isTrue,
    );
  });
}
