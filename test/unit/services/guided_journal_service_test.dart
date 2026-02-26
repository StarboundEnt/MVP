import 'package:flutter_test/flutter_test.dart';

import 'package:starbound/models/complexity_engine_models.dart';
import 'package:starbound/models/complexity_profile.dart';
import 'package:starbound/models/journal_prompt_model.dart';
import 'package:starbound/services/guided_journal_flow_controller.dart';
import 'package:starbound/services/guided_journal_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('guided journaling flow completes with skips', () {
    final service = GuidedJournalService();
    final prompts = service.buildV1Prompts();
    final controller = GuidedJournalFlowController(prompts: prompts);

    while (!controller.isComplete) {
      controller.skipCurrent();
    }

    expect(controller.isComplete, isTrue);
    expect(controller.responses.length, prompts.length);
    expect(
      controller.responses.values.every((response) => response.skipped),
      isTrue,
    );
  });

  test('chip selections produce expected factors', () {
    final service = GuidedJournalService();
    final prompts = service.buildV1Prompts();

    final responses = {
      'event': const JournalPromptResponse(
        promptId: 'event',
        selectedOptions: ['headache'],
      ),
      'behaviour': const JournalPromptResponse(
        promptId: 'behaviour',
        selectedOptions: ['rested', 'used medication'],
      ),
      'relief': const JournalPromptResponse(
        promptId: 'relief',
        selectedOptions: ['movement'],
      ),
      'constraint': const JournalPromptResponse(
        promptId: 'constraint',
        selectedOptions: ['time'],
      ),
      'strength': const JournalPromptResponse(
        promptId: 'strength',
        selectedOptions: ['showed up'],
      ),
    };

    final result = service.buildResult(
      prompts: prompts,
      responses: responses,
    );
    final codes = result.factorWrites.map((write) => write.code).toSet();

    expect(codes, contains(FactorCode.symptomHeadache));
    expect(codes, contains(FactorCode.behaviourRested));
    expect(codes, contains(FactorCode.medicalMedsMentioned));
    expect(codes, contains(FactorCode.reliefMovement));
    expect(codes, contains(FactorCode.resourceTimePressure));
    expect(codes, contains(FactorCode.strengthShowedUp));
  });

  test('strength prompt writes only strength factors', () {
    final service = GuidedJournalService();
    final prompts = service.buildV1Prompts();

    final responses = {
      'strength': const JournalPromptResponse(
        promptId: 'strength',
        text: 'took a break and asked for help',
      ),
    };

    final result = service.buildResult(
      prompts: prompts,
      responses: responses,
    );

    final allowed = {
      FactorCode.strengthShowedUp,
      FactorCode.strengthTookBreak,
      FactorCode.strengthAskedForHelp,
      FactorCode.strengthResilience,
    };

    expect(result.factorWrites, isNotEmpty);
    expect(
      result.factorWrites.every((write) => allowed.contains(write.code)),
      isTrue,
    );
  });

  test('buildV1PromptsForInput keeps event and strength', () async {
    final service = GuidedJournalService();

    final prompts = await service.buildV1PromptsForInput(
      'No time and low energy today',
      ComplexityLevel.overloaded,
      useAi: false,
    );

    final domains = prompts.map((prompt) => prompt.domain).toList();
    expect(domains, contains(JournalPromptDomain.event));
    expect(domains, contains(JournalPromptDomain.strength));
    expect(domains, contains(JournalPromptDomain.constraint));
  });
}
