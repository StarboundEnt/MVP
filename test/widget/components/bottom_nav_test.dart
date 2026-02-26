import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starbound/components/bottom_nav.dart';

Widget _buildNavApp({
  required int currentIndex,
  required ValueChanged<int> onTap,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      bottomNavigationBar: SizedBox(
        height: 120,
        child: StarboundBottomNav(
          currentIndex: currentIndex,
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StarboundBottomNav', () {
    testWidgets('renders all navigation items with icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildNavApp(currentIndex: 0, onTap: (_) {}),
      );

      for (final label in ['Home', 'Ask', 'Support', 'Journal', 'Vault']) {
        expect(find.text(label), findsOneWidget);
      }

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.psychology_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.people_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });

    testWidgets('invokes onTap callback for selected tab', (WidgetTester tester) async {
      final tapped = <int>[];

      await tester.pumpWidget(
        _buildNavApp(
          currentIndex: 0,
          onTap: tapped.add,
        ),
      );

      await tester.tap(find.text('Support'));
      await tester.pump();

      expect(tapped, [2]);
    });

    testWidgets('highlights the active tab and remains accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildNavApp(currentIndex: 3, onTap: (_) {}),
      );

      // Journal tab should be marked as selected via semantics
      final journalSemantics = tester.getSemantics(find.text('Journal'));
      expect(journalSemantics.hasFlag(SemanticsFlag.isSelected), isTrue);

      // Dark theme rendering sanity check
      await tester.pumpWidget(
        _buildNavApp(currentIndex: 1, onTap: (_) {}, theme: ThemeData.dark()),
      );

      expect(find.text('Ask'), findsOneWidget);
    });
  });
}
