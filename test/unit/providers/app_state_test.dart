import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starbound/providers/app_state.dart';
import 'package:starbound/models/complexity_profile.dart';

void main() {
  group('AppState', () {
    late AppState appState;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Initialize SharedPreferences with mock values
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
      appState.disableBackendForTesting();
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(appState.isLoading, false);
        expect(appState.error, isNull);
        expect(appState.habits, isEmpty);
        expect(appState.userName, 'Explorer');
        expect(appState.isOnboardingComplete, false);
        expect(appState.complexityProfile, ComplexityLevel.trying);
      });

      test('should initialize successfully', () async {
        await appState.initialize();
        
        expect(appState.isLoading, false);
        expect(appState.error, isNull);
      });
    });

    group('Loading State Management', () {
      test('should manage loading state correctly', () {
        expect(appState.isLoading, false);
        
        // Simulate loading
        appState.setLoading(true);
        expect(appState.isLoading, true);
        
        appState.setLoading(false);
        expect(appState.isLoading, false);
      });
    });

    group('Error Handling', () {
      test('should set and clear errors', () {
        expect(appState.error, isNull);
        
        appState.setError('Test error message');
        expect(appState.error, 'Test error message');
        
        appState.clearError();
        expect(appState.error, isNull);
      });
    });

    group('User Management', () {
      test('should update user name', () async {
        const newName = 'New User Name';
        
        await appState.updateUserName(newName);
        expect(appState.userName, newName);
      });

      test('should update onboarding status', () async {
        expect(appState.isOnboardingComplete, false);
        
        await appState.setOnboardingComplete(true);
        expect(appState.isOnboardingComplete, true);
        
        await appState.setOnboardingComplete(false);
        expect(appState.isOnboardingComplete, false);
      });

      test('should update complexity profile', () async {
        expect(appState.complexityProfile, ComplexityLevel.trying);
        
        await appState.updateComplexityProfile(ComplexityLevel.overloaded);
        expect(appState.complexityProfile, ComplexityLevel.overloaded);
        
        await appState.updateComplexityProfile(ComplexityLevel.stable);
        expect(appState.complexityProfile, ComplexityLevel.stable);
      });
    });

    group('Habit Management', () {
      test('should update habit status', () async {
        const habitId = 'test-habit-id';
        const status = 'completed';
        
        await appState.updateHabit(habitId, status);
        expect(appState.habits[habitId], status);
      });

      test('should handle multiple habit updates', () async {
        final habitsToUpdate = {
          'habit1': 'completed',
          'habit2': 'pending',
          'habit3': 'skipped',
        };
        
        for (final entry in habitsToUpdate.entries) {
          await appState.updateHabit(entry.key, entry.value);
        }
        
        expect(appState.habits, habitsToUpdate);
      });

      test('should get habit status', () async {
        const habitId = 'test-habit-id';
        const status = 'completed';
        
        await appState.updateHabit(habitId, status);
        final retrievedStatus = appState.getHabitStatus(habitId);
        
        expect(retrievedStatus, status);
      });

      test('should return null for non-existent habit', () {
        final status = appState.getHabitStatus('non-existent-habit');
        expect(status, isNull);
      });
    });

    group('Analytics', () {
      test('should calculate total habits correctly', () async {
        await appState.updateHabit('habit1', 'completed');
        await appState.updateHabit('habit2', 'pending');
        await appState.updateHabit('habit3', 'skipped');
        
        final analytics = await appState.getAnalytics();
        expect(analytics['totalHabits'], 3);
      });

      test('should calculate completed habits correctly', () async {
        await appState.updateHabit('habit1', 'completed');
        await appState.updateHabit('habit2', 'completed');
        await appState.updateHabit('habit3', 'pending');
        
        final analytics = await appState.getAnalytics();
        expect(analytics['completedHabits'], 2);
      });

      test('should handle empty habits in analytics', () async {
        final analytics = await appState.getAnalytics();
        expect(analytics['totalHabits'], 0);
        expect(analytics['completedHabits'], 0);
      });
    });

    group('Cache Management', () {
      test('should detect cache expiry correctly', () {
        final now = DateTime.now();
        
        // Fresh cache (within 15 minutes)
        final freshTime = now.subtract(const Duration(minutes: 10));
        expect(appState.isCacheExpired(freshTime, 15), false);
        
        // Expired cache (older than 15 minutes)
        final expiredTime = now.subtract(const Duration(minutes: 20));
        expect(appState.isCacheExpired(expiredTime, 15), true);
      });

      test('should handle null cache time', () {
        expect(appState.isCacheExpired(null, 15), true);
      });
    });

    group('Data Reset', () {
      test('should reset all data', () async {
        // Set up some state
        await appState.updateUserName('Test User');
        await appState.setOnboardingComplete(true);
        await appState.updateComplexityProfile(ComplexityLevel.overloaded);
        await appState.updateHabit('habit1', 'completed');
        
        // Verify state is set
        expect(appState.userName, 'Test User');
        expect(appState.isOnboardingComplete, true);
        expect(appState.complexityProfile, ComplexityLevel.overloaded);
        expect(appState.habits, isNotEmpty);
        
        // Reset all data
        await appState.resetAllData();
        
        // Verify state is reset to defaults
        expect(appState.userName, 'Explorer');
        expect(appState.isOnboardingComplete, false);
        expect(appState.complexityProfile, ComplexityLevel.trying);
        expect(appState.habits, isEmpty);
      });
    });

    group('Validation', () {
      test('should validate habit IDs', () {
        expect(appState.isValidHabitId('valid-habit-id'), true);
        expect(appState.isValidHabitId(''), false);
        expect(appState.isValidHabitId(' '), false);
      });

      test('should validate habit status', () {
        expect(appState.isValidHabitStatus('completed'), true);
        expect(appState.isValidHabitStatus('pending'), true);
        expect(appState.isValidHabitStatus('skipped'), true);
        expect(appState.isValidHabitStatus('invalid'), false);
        expect(appState.isValidHabitStatus(''), false);
      });

      test('should validate user names', () {
        expect(appState.isValidUserName('Valid Name'), true);
        expect(appState.isValidUserName('A'), true);
        expect(appState.isValidUserName(''), false);
        expect(appState.isValidUserName(' '), false);
        expect(appState.isValidUserName('   '), false);
      });
    });

    group('Performance Tracking', () {
      test('should track performance metrics', () {
        final startTime = DateTime.now();
        
        // Simulate some operation
        appState.trackPerformance('test_operation', startTime);
        
        // Should not throw any errors
        expect(true, true);
      });
    });

    group('Memory Management', () {
      test('should cleanup resources on dispose', () {
        // This test ensures dispose doesn't throw errors
        expect(() => appState.dispose(), returnsNormally);
      });
    });
  });
}
