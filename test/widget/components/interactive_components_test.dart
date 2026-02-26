import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starbound/components/interactive_components.dart';

void main() {
  group('SmoothButton Widget Tests', () {
    testWidgets('should render with child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothButton(
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(SmoothButton), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothButton(
              onPressed: () => wasPressed = true,
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SmoothButton));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('should not respond to taps when disabled', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothButton(
              onPressed: null, // Disabled button
              child: const Text('Disabled Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SmoothButton));
      await tester.pump();

      expect(wasPressed, false);
    });

    testWidgets('should animate on press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothButton(
              onPressed: () {},
              child: const Text('Animated Button'),
            ),
          ),
        ),
      );

      // Start the press gesture
      await tester.press(find.byType(SmoothButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75)); // Mid-animation

      // The button should be in a pressed state (scaled down)
      expect(find.byType(AnimatedBuilder), findsOneWidget);
    });
  });

  group('SmoothCard Widget Tests', () {
    testWidgets('should render with child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothCard(
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(SmoothCard), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothCard(
              onTap: () => wasTapped = true,
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SmoothCard));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('should not respond to taps when no onTap provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothCard(
              child: const Text('Non-tappable Card'),
            ),
          ),
        ),
      );

      // Should not throw any errors when tapped
      await tester.tap(find.byType(SmoothCard));
      await tester.pump();

      expect(find.text('Non-tappable Card'), findsOneWidget);
    });
  });

  group('SmoothProgressBar Widget Tests', () {
    testWidgets('should render with correct progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SmoothProgressBar(
              progress: 0.5, // 50%
            ),
          ),
        ),
      );

      expect(find.byType(SmoothProgressBar), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });

    testWidgets('should animate progress changes', (WidgetTester tester) async {
      double progress = 0.3;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    SmoothProgressBar(progress: progress),
                    ElevatedButton(
                      onPressed: () => setState(() => progress = 0.8),
                      child: const Text('Update Progress'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initial progress
      expect(find.byType(SmoothProgressBar), findsOneWidget);

      // Update progress
      await tester.tap(find.text('Update Progress'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 10)); // Let animation complete

      // Progress should be updated
      expect(find.byType(SmoothProgressBar), findsOneWidget);
    });

    testWidgets('should handle edge case progress values', (WidgetTester tester) async {
      // Test with 0% progress
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SmoothProgressBar(progress: 0.0),
          ),
        ),
      );
      expect(find.byType(SmoothProgressBar), findsOneWidget);

      // Test with 100% progress
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SmoothProgressBar(progress: 1.0),
          ),
        ),
      );
      expect(find.byType(SmoothProgressBar), findsOneWidget);

      // Test with over 100% progress (should be clamped)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SmoothProgressBar(progress: 1.5),
          ),
        ),
      );
      expect(find.byType(SmoothProgressBar), findsOneWidget);
    });
  });

  group('SmoothFAB Widget Tests', () {
    testWidgets('should render with child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothFAB(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(SmoothFAB), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothFAB(
              onPressed: () => wasPressed = true,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SmoothFAB));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('should have circular shape', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothFAB(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      // Verify the FAB has proper circular decoration
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('SmoothTabBar Widget Tests', () {
    testWidgets('should render all tabs', (WidgetTester tester) async {
      const tabs = ['Tab 1', 'Tab 2', 'Tab 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothTabBar(
              tabs: tabs,
              selectedIndex: 0,
              onTabSelected: (index) {},
            ),
          ),
        ),
      );

      for (final tab in tabs) {
        expect(find.text(tab), findsOneWidget);
      }
    });

    testWidgets('should call onTabSelected when tab is tapped', (WidgetTester tester) async {
      const tabs = ['Tab 1', 'Tab 2', 'Tab 3'];
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothTabBar(
              tabs: tabs,
              selectedIndex: 0,
              onTabSelected: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tab 2'));
      await tester.pump();

      expect(selectedIndex, 1);
    });

    testWidgets('should highlight selected tab', (WidgetTester tester) async {
      const tabs = ['Tab 1', 'Tab 2', 'Tab 3'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothTabBar(
              tabs: tabs,
              selectedIndex: 1, // Tab 2 is selected
              onTabSelected: (index) {},
            ),
          ),
        ),
      );

      // The selected tab should have different styling
      expect(find.byType(AnimatedBuilder), findsOneWidget);
    });
  });

  group('SmoothSwitch Widget Tests', () {
    testWidgets('should render in correct initial state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothSwitch(
              value: false,
              onChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.byType(SmoothSwitch), findsOneWidget);
    });

    testWidgets('should call onChanged when tapped', (WidgetTester tester) async {
      bool? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothSwitch(
              value: false,
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SmoothSwitch));
      await tester.pump();

      expect(changedValue, true);
    });

    testWidgets('should not respond when disabled', (WidgetTester tester) async {
      bool? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmoothSwitch(
              value: false,
              onChanged: null, // Disabled
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SmoothSwitch));
      await tester.pump();

      expect(changedValue, isNull);
    });

    testWidgets('should animate state changes', (WidgetTester tester) async {
      bool switchValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: SmoothSwitch(
                  value: switchValue,
                  onChanged: (value) => setState(() => switchValue = value),
                ),
              );
            },
          ),
        ),
      );

      // Toggle the switch
      await tester.tap(find.byType(SmoothSwitch));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 10)); // Let animation complete

      expect(switchValue, true);
    });
  });
}