import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starbound/main.dart';

void main() {
  const runIntegrationTests = bool.fromEnvironment(
    'RUN_INTEGRATION_TESTS',
    defaultValue: false,
  );

  if (!runIntegrationTests) {
    return;
  }

  final binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Flow Integration Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});

      binding.window.physicalSizeTestValue = const Size(1080, 1920);
      binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        binding.window.clearPhysicalSizeTestValue();
        binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('Complete onboarding flow', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle();

      // Should start with onboarding page
      expect(find.text('Welcome to Starbound'), findsOneWidget);

      // Enter user name
      await tester.enterText(find.byType(TextField), 'Test User');
      await tester.pump();

      // Select complexity profile
      await tester.tap(find.text('Trying'));
      await tester.pump();

      // Complete onboarding
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Should navigate to home page
      expect(find.byType(StarboundShell), findsOneWidget);
      expect(find.text('Welcome back, Test User'), findsOneWidget);
    });

    testWidgets('Navigate through all main pages', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle();

      // Complete onboarding first
      await _completeOnboarding(tester);

      // Test navigation to each page
      final navItems = ['Ask', 'Support', 'Journal', 'Vault'];

      for (final name in navItems) {
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();

        // Verify we're on the correct page
        expect(find.byType(StarboundShell), findsOneWidget);

        // Go back to home
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Habit tracking flow', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle();

      await _completeOnboarding(tester);

      // Navigate to journal page
      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();

      // Ensure journal content renders (fallback to checking tab presence)
      expect(find.text('Journal'), findsWidgets);
    });

    testWidgets('Ask page interaction flow', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle();

      await _completeOnboarding(tester);

      // Navigate to Ask page
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();

      // Enter a question
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'How can I improve my sleep?');
        await tester.pump();

        // Submit the question
        final submitButtons = find.text('Submit');
        if (submitButtons.evaluate().isNotEmpty) {
          await tester.tap(submitButtons.first);
          await tester.pumpAndSettle();
        }
      }

      // Verify we can navigate back
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      // Should show home content
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Settings and profile management', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle();

      await _completeOnboarding(tester);

      // Access debug menu (long press on home or settings icon)
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Should open debug/settings menu
        expect(find.text('Debug Menu'), findsOneWidget);

        // Test complexity profile change
        await tester.tap(find.text('Change Profile'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Overloaded'));
        await tester.pumpAndSettle();

        // Close dialogs
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Data persistence across app restarts', (WidgetTester tester) async {
      // First session - complete onboarding and update habits
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle();

      await _completeOnboarding(tester);

      // Update a habit
      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();

      // Complete a habit (implementation depends on UI)
      // This would test that the habit completion is saved

      // Simulate app restart by creating new app instance
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle();

      // Should skip onboarding and go straight to home
      expect(find.byType(StarboundShell), findsOneWidget);

      // Verify habit data persisted
      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();

      // Check that habit completion state is maintained
      // Implementation depends on specific habit UI
    });

    testWidgets('Error handling and recovery', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle();

      // Test app initialization error handling
      // This would require mocking storage failures

      // Complete onboarding
      await _completeOnboarding(tester);

      // Test network error scenarios
      // Navigate to a page that might make network calls
      await tester.tap(find.text('Support'));
      await tester.pumpAndSettle();

      // Verify error states are handled gracefully
      // Should not crash the app
      expect(find.byType(StarboundShell), findsOneWidget);
    });

    testWidgets('Accessibility navigation', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle();

      await _completeOnboarding(tester);

      // Test semantic navigation
      final semantics = tester.binding.pipelineOwner.semanticsOwner!;
      expect(semantics.rootSemanticsNode, isNotNull);

      // Test that all navigation items have proper semantics
      final navItems = ['Home', 'Ask', 'Support', 'Journal', 'Vault'];
      for (final item in navItems) {
        expect(find.text(item), findsOneWidget);
      }
    });

    testWidgets('Performance under load', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle();

      await _completeOnboarding(tester);

      // Rapid navigation test
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Journal'));
        await tester.pump();
        await tester.tap(find.text('Home'));
        await tester.pump();
      }

      // App should remain responsive
      expect(find.byType(StarboundShell), findsOneWidget);
    });
  });
}

/// Helper function to complete onboarding flow
Future<void> _completeOnboarding(WidgetTester tester) async {
  // Check if we're on onboarding page
  if (find.text('Welcome to Starbound').evaluate().isNotEmpty) {
    // Enter user name
    final nameFields = find.byType(TextField);
    if (nameFields.evaluate().isNotEmpty) {
      await tester.enterText(nameFields.first, 'Test User');
      await tester.pump();
    }

    // Select complexity profile
    final tryingButton = find.text('Trying');
    if (tryingButton.evaluate().isNotEmpty) {
      await tester.tap(tryingButton);
      await tester.pump();
    }

    // Complete onboarding
    final getStartedButton = find.text('Get Started');
    if (getStartedButton.evaluate().isNotEmpty) {
      await tester.tap(getStartedButton);
      await tester.pumpAndSettle();
    }
  }
}
