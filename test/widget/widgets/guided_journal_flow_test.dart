import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starbound/models/journal_prompt_model.dart';
import 'package:starbound/services/guided_journal_service.dart';
import 'package:starbound/widgets/guided_journal_flow.dart';

void main() {
  testWidgets(
    'Get Health Guidance requests guidance before completion callback',
    (WidgetTester tester) async {
      final service = GuidedJournalService();
      final prompts = const [
        JournalPrompt(
          id: 'event',
          domain: JournalPromptDomain.event,
          promptText: 'What happened today?',
          inputType: JournalPromptInputType.shortText,
          skippable: false,
        ),
      ];

      final callbackOrder = <String>[];
      String? draft = 'I have head pain after work.';
      String? draftAtGuidanceTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuidedJournalFlow(
              prompts: prompts,
              service: service,
              initialEventText: draft,
              useSafeArea: false,
              margin: EdgeInsets.zero,
              onCompleted: (_) {
                callbackOrder.add('completed');
                draft = null;
              },
              onHealthGuidanceRequested: (_) {
                callbackOrder.add('guidance');
                draftAtGuidanceTime = draft;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.text('Get Health Guidance'), findsOneWidget);

      await tester.tap(find.text('Get Health Guidance'));
      await tester.pump();

      expect(callbackOrder, equals(['guidance', 'completed']));
      expect(draftAtGuidanceTime, equals('I have head pain after work.'));
    },
  );
}
