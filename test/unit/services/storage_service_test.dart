import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starbound/models/complexity_profile.dart';
import 'package:starbound/services/storage_service.dart';

void main() {
  group('StorageService (SharedPreferences wrapper)', () {
    late StorageService storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
    });

    test('persists complexity profile level', () async {
      await storage.saveComplexityProfile(ComplexityLevel.trying);
      final level = await storage.loadComplexityProfile();
      expect(level, ComplexityLevel.trying);
    });

    test('stores habits map with null-friendly values', () async {
      final habits = {
        'sleep_hygiene': 'good',
        'daily_hydration': null,
      };

      await storage.saveHabits(habits);
      final loaded = await storage.loadHabits();
      expect(loaded['sleep_hygiene'], 'good');
      expect(loaded['daily_hydration'], isNull);
    });

    test('onboarding helpers toggle flag correctly', () async {
      expect(await storage.isOnboardingComplete(), isFalse);
      await storage.setOnboardingComplete(true);
      expect(await storage.isOnboardingComplete(), isTrue);
    });

    test('generic getters support default values', () async {
      expect(await storage.getString('missing', defaultValue: 'fallback'), 'fallback');
      expect(await storage.getInt('missing', defaultValue: 7), 7);
      expect(await storage.getBool('missing', defaultValue: true), isTrue);
      expect(await storage.getDouble('missing', defaultValue: 1.5), 1.5);
    });

    test('containsKey reflects stored items', () async {
      const key = 'test_key';
      expect(await storage.containsKey(key), isFalse);
      await storage.setString(key, 'value');
      expect(await storage.containsKey(key), isTrue);
      await storage.remove(key);
      expect(await storage.containsKey(key), isFalse);
    });

    test('clearAllData removes all stored entries', () async {
      await storage.setString('key1', 'value1');
      await storage.saveUserName('Explorer');

      await storage.clearAllData();

      expect(await storage.getString('key1'), isNull);
      expect(await storage.loadUserName(), 'Explorer'); // defaults to "Explorer"
    });
  });
}
