import 'package:flutter_test/flutter_test.dart';
import 'package:starbound/models/complexity_profile.dart';
import 'package:starbound/utils/implementation_intention.dart';

void main() {
  group('buildImplementationIntention', () {
    test('returns null when text is empty after cleanup', () {
      final result = buildImplementationIntention(
        rawStepText: '   ',
        profile: ComplexityLevel.trying,
      );
      expect(result, isNull);
    });

    test('personalises with first name when available', () {
      final result = buildImplementationIntention(
        rawStepText: '1. Drink water slowly',
        profile: ComplexityLevel.trying,
        userName: 'Taylor Smith',
      );

      expect(
        result,
        equals('Taylor, if things wobble later, come back to Drink water slowly.'),
      );
    });

    test('avoids default Explorer name and adds punctuation when missing', () {
      final result = buildImplementationIntention(
        rawStepText: '**Step 2:** Stretch your back',
        profile: ComplexityLevel.stable,
        userName: 'Explorer',
      );

      expect(
        result,
        equals('when this pops up again, lean on Stretch your back.'),
      );
    });

    test('uses supportive tone for survival profile and preserves punctuation', () {
      final result = buildImplementationIntention(
        rawStepText: 'Breathe slowly for 30 seconds!',
        profile: ComplexityLevel.survival,
        userName: 'Avery',
      );

      expect(
        result,
        equals(
          'Avery, if everything is overwhelming later, the smallest next step is Breathe slowly for 30 seconds!',
        ),
      );
    });
  });
}
