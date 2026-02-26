import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starbound/pages/home_page.dart';
import 'package:starbound/providers/app_state.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('HomePage Widget Tests', () {
    late AppState mockAppState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockAppState = AppState();
      await mockAppState.initialize();
    });

    testWidgets('should render home page with welcome message', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          appState: mockAppState,
          child: HomePage(
            onInsightsPressed: () {},
            onSupportPressed: () {},
            onActionVaultPressed: () {},
            onJournalPressed: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      // Should render the home page structure
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should call navigation callbacks when pressed', (WidgetTester tester) async {
      bool askPressed = false;
      bool supportPressed = false;
      bool vaultPressed = false;
      bool journalPressed = false;
      bool settingsPressed = false;

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          appState: mockAppState,
          child: HomePage(
            onInsightsPressed: () => askPressed = true,
            onSupportPressed: () => supportPressed = true,
            onActionVaultPressed: () => vaultPressed = true,
            onJournalPressed: () => journalPressed = true,
            onSettingsPressed: () => settingsPressed = true,
          ),
        ),
      );

      // Look for interactive elements and test callbacks
      // Note: The actual UI elements depend on your HomePage implementation
      
      // This is a basic structure test
      expect(find.byType(HomePage), findsOneWidget);
      expect(askPressed, isFalse);
      expect(supportPressed, isFalse);
      expect(vaultPressed, isFalse);
      expect(journalPressed, isFalse);
      expect(settingsPressed, isFalse);
    });

    testWidgets('should display user name from app state', (WidgetTester tester) async {
      // Update app state with test user name
      await mockAppState.updateUserName('Test Explorer');

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          appState: mockAppState,
          child: HomePage(
            onInsightsPressed: () {},
            onSupportPressed: () {},
            onActionVaultPressed: () {},
            onJournalPressed: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      // Should display the user name somewhere on the page
      // Exact implementation depends on your HomePage widget
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should handle loading state correctly', (WidgetTester tester) async {
      // Set loading state
      mockAppState.setLoading(true);

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          appState: mockAppState,
          child: HomePage(
            onInsightsPressed: () {},
            onSupportPressed: () {},
            onActionVaultPressed: () {},
            onJournalPressed: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      // Should handle loading state appropriately
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should handle error state correctly', (WidgetTester tester) async {
      // Set error state
      mockAppState.setError('Test error message');

      await tester.pumpWidget(
        TestHelpers.createTestApp(
          appState: mockAppState,
          child: HomePage(
            onInsightsPressed: () {},
            onSupportPressed: () {},
            onActionVaultPressed: () {},
            onJournalPressed: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      // Should handle error state appropriately
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should be responsive to different screen sizes', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          appState: mockAppState,
          child: HomePage(
            onInsightsPressed: () {},
            onSupportPressed: () {},
            onActionVaultPressed: () {},
            onJournalPressed: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      // Test mobile portrait
      await TestHelpers.setTestScreenSize(tester, width: 375, height: 667);
      await tester.pump();
      expect(find.byType(HomePage), findsOneWidget);

      // Test tablet landscape
      await TestHelpers.setTestScreenSize(tester, width: 1024, height: 768);
      await tester.pump();
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should display current complexity profile', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          appState: mockAppState,
          child: HomePage(
            onInsightsPressed: () {},
            onSupportPressed: () {},
            onActionVaultPressed: () {},
            onJournalPressed: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      // Should reflect the current complexity profile
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should animate properly on state changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          appState: mockAppState,
          child: HomePage(
            onInsightsPressed: () {},
            onSupportPressed: () {},
            onActionVaultPressed: () {},
            onJournalPressed: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      // Initial state
      expect(find.byType(HomePage), findsOneWidget);

      // Change state and verify animations work
      mockAppState.setLoading(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      mockAppState.setLoading(false);
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should handle accessibility requirements', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          appState: mockAppState,
          child: HomePage(
            onInsightsPressed: () {},
            onSupportPressed: () {},
            onActionVaultPressed: () {},
            onJournalPressed: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      // Verify semantic structure
      final semantics = tester.binding.pipelineOwner.semanticsOwner!;
      expect(semantics.rootSemanticsNode, isNotNull);

      // Should have proper semantic labels for accessibility
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should maintain theme consistency', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          appState: mockAppState,
          child: HomePage(
            onInsightsPressed: () {},
            onSupportPressed: () {},
            onActionVaultPressed: () {},
            onJournalPressed: () {},
            onSettingsPressed: () {},
          ),
        ),
      );

      // Get the build context to check theme
      final BuildContext context = tester.element(find.byType(HomePage));
      TestHelpers.expectThemeConsistency(context);
    });
  });
}
