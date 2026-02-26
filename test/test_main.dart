import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'unit/models/habit_model_test.dart' as habit_model_tests;
import 'unit/models/nudge_model_test.dart' as nudge_model_tests;
import 'unit/services/storage_service_test.dart' as storage_service_tests;
import 'unit/providers/app_state_test.dart' as app_state_tests;
import 'widget/components/bottom_nav_test.dart' as bottom_nav_tests;
import 'widget/components/interactive_components_test.dart' as interactive_components_tests;

/// Main test runner that executes all tests in the project
/// 
/// This file provides a centralized way to run all tests and ensures
/// proper test organization and execution order.
void main() {
  group('Starbound App Test Suite', () {
    group('Unit Tests', () {
      group('Models', () {
        habit_model_tests.main();
        nudge_model_tests.main();
      });

      group('Services', () {
        storage_service_tests.main();
      });

      group('Providers', () {
        app_state_tests.main();
      });
    });

    group('Widget Tests', () {
      group('Components', () {
        bottom_nav_tests.main();
        interactive_components_tests.main();
      });
    });

    // Integration tests are run separately using the integration_test package
    // They can be executed using: flutter test integration_test/
  });
}

/// Test configuration and utilities
class TestConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(minutes: 2);
  
  /// Runs setup before all tests
  static void setUpAll() {
    // Global test setup can go here
    // e.g., timezone initialization, global mocks, etc.
  }
  
  /// Runs cleanup after all tests
  static void tearDownAll() {
    // Global test cleanup can go here
    // e.g., clearing caches, disposing resources, etc.
  }
}