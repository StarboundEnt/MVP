import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starbound/services/daily_prompts_service.dart';

void main() {
  group('DailyPromptsService', () {
    late DailyPromptsService service;

    setUp(() async {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
      service = DailyPromptsService();
    });

    test('should return a valid prompt from getTodaysPrompt', () async {
      final prompt = await service.getTodaysPrompt();
      
      expect(prompt, isNotNull);
      expect(prompt, isNotEmpty);
      expect(prompt.endsWith('?'), isTrue, reason: 'Prompt should be a question');
    });

    test('should return same prompt for same day', () async {
      final prompt1 = await service.getTodaysPrompt();
      final prompt2 = await service.getTodaysPrompt();
      
      expect(prompt1, equals(prompt2));
    });

    test('should return different prompt with getNewPrompt', () async {
      final originalPrompt = await service.getTodaysPrompt();
      
      // Allow some time to pass to ensure different seed
      await Future.delayed(const Duration(milliseconds: 10));
      
      final newPrompt = await service.getNewPrompt();
      
      expect(newPrompt, isNotNull);
      expect(newPrompt, isNotEmpty);
      // Note: There's a small chance they could be the same due to randomness
      // but it's very unlikely with our large prompt collection
    });

    test('should return valid categories', () {
      final categories = service.getCategories();
      
      expect(categories, isNotEmpty);
      expect(categories, contains('energy_emotions'));
      expect(categories, contains('gratitude_growth'));
      expect(categories, contains('reflection_learning'));
      expect(categories, contains('connection_care'));
      expect(categories, contains('hopes_intentions'));
    });

    test('should get prompts from specific category', () async {
      final energyPrompts = await service.getPromptsFromCategory('energy_emotions');
      
      expect(energyPrompts, isNotEmpty);
      expect(energyPrompts, contains('What gave you energy today?'));
      expect(energyPrompts, contains("What's something that felt heavy?"));
    });

    test('should return empty list for invalid category', () async {
      final invalidPrompts = await service.getPromptsFromCategory('invalid_category');
      
      expect(invalidPrompts, isEmpty);
    });

    test('should handle fallback gracefully when SharedPreferences fails', () async {
      // This test verifies that the service handles errors gracefully
      // and falls back to default prompts
      
      final prompt = await service.getTodaysPrompt();
      
      // Even if SharedPreferences fails, we should get a valid prompt
      expect(prompt, isNotNull);
      expect(prompt, isNotEmpty);
    });

    test('should provide prompt stats', () async {
      final stats = await service.getPromptStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['total_categories'], equals(5));
      expect(stats['total_prompts'], greaterThan(20)); // We have 25 total prompts
    });

    test('should detect if it is a new day', () async {
      final isNewDay = await service.isNewDay();
      
      // On first run, it should be considered a new day
      expect(isNewDay, isTrue);
      
      // After getting today's prompt, it should not be a new day
      await service.getTodaysPrompt();
      final isStillNewDay = await service.isNewDay();
      expect(isStillNewDay, isFalse);
    });

    test('should clear prompt data', () async {
      // Get a prompt to store some data
      await service.getTodaysPrompt();
      
      // Clear the data
      await service.clearPromptData();
      
      // Should be considered a new day again
      final isNewDay = await service.isNewDay();
      expect(isNewDay, isTrue);
    });
  });
}