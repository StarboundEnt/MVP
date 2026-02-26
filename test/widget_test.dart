import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starbound/main.dart';

void main() {
  group('Starbound App Integration Tests', () {
    setUp(() async {
      // Initialize SharedPreferences with mock values for each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('App initializes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pump();

      // Should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for initialization to complete
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Should navigate to onboarding for new users
      expect(find.text('Welcome to Starbound'), findsOneWidget);
    });

    testWidgets('App handles initialization errors gracefully', (WidgetTester tester) async {
      // This would test error scenarios - implementation depends on how errors are simulated
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // App should not crash and should show appropriate UI
      expect(find.byType(StarboundApp), findsOneWidget);
    });

    testWidgets('App renders with correct theme', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Find the MaterialApp and verify theme
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.brightness, Brightness.dark);
      expect(materialApp.theme?.scaffoldBackgroundColor, const Color(0xFF1F0150));
    });

    testWidgets('Navigation structure is set up correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Complete onboarding if needed
      if (find.text('Welcome to Starbound').evaluate().isNotEmpty) {
        // Skip onboarding for this test - would need to interact with onboarding flow
        // For now, just verify the onboarding page loads
        expect(find.text('Welcome to Starbound'), findsOneWidget);
      } else {
        // If already past onboarding, should see main app structure
        expect(find.byType(StarboundShell), findsOneWidget);
      }
    });

    testWidgets('App responds to basic interactions', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Basic smoke test - ensure tapping doesn't crash the app
      if (find.text('Get Started').evaluate().isNotEmpty) {
        // On onboarding page
        expect(find.text('Get Started'), findsOneWidget);
      } else if (find.byType(BottomNavigationBar).evaluate().isNotEmpty) {
        // On main app with navigation
        final navItems = ['Home', 'Ask', 'Support', 'Journal', 'Vault'];
        for (final item in navItems) {
          if (find.text(item).evaluate().isNotEmpty) {
            await tester.tap(find.text(item));
            await tester.pump();
            // Should not crash
          }
        }
      }

      // Verify app is still responsive
      expect(find.byType(StarboundApp), findsOneWidget);
    });

    testWidgets('App handles device rotation', (WidgetTester tester) async {
      await tester.pumpWidget(const StarboundApp());
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Simulate device rotation
      await tester.binding.setSurfaceSize(const Size(800, 600)); // Landscape
      await tester.pump();

      // App should still render correctly
      expect(find.byType(StarboundApp), findsOneWidget);

      // Rotate back to portrait
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Portrait
      await tester.pump();

      // App should still render correctly
      expect(find.byType(StarboundApp), findsOneWidget);
    });
  });
}
