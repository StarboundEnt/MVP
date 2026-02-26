import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starbound/services/action_conversion_service.dart';
import 'package:starbound/models/habit_model.dart';
import 'package:starbound/models/nudge_model.dart';

void main() {
  group('ActionConversionService', () {
    late ActionConversionService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = ActionConversionService();
    });

    test('should convert journal entry to action nudge', () {
      final entry = FreeFormEntry(
        id: 'test_entry',
        originalText: 'Had trouble sleeping last night, need to improve my sleep routine',
        timestamp: DateTime.now(),
        classifications: [
          ClassificationResult(
            habitKey: 'sleep',
            habitValue: 'poor sleep',
            categoryTitle: 'Sleep',
            categoryType: 'choice',
            confidence: 0.8,
            reasoning: 'Sleep mentioned',
            extractedText: 'trouble sleeping',
            sentiment: 'negative',
            themes: ['sleep', 'wellness'],
            keywords: ['sleep', 'trouble'],
            sentimentConfidence: 0.9,
          ),
        ],
        averageConfidence: 0.8,
      );

      final action = service.convertEntryToAction(entry);

      expect(action.id, startsWith('action_from_entry_'));
      expect(action.message, isNotEmpty);
      expect(action.theme, isNotEmpty);
      expect(action.content, isNotEmpty);
      expect(action.metadata?['source'], equals('journal_entry'));
      expect(action.metadata?['entry_id'], equals('test_entry'));
      expect(action.source, equals(NudgeSource.dynamic));
    });

    test('should generate sleep-related action for sleep theme', () {
      final entry = FreeFormEntry(
        id: 'sleep_entry',
        originalText: 'Great sleep last night!',
        timestamp: DateTime.now(),
        classifications: [
          ClassificationResult(
            habitKey: 'sleep',
            habitValue: 'good sleep',
            categoryTitle: 'Sleep',
            categoryType: 'choice',
            confidence: 0.9,
            reasoning: 'Sleep mentioned',
            extractedText: 'great sleep',
            sentiment: 'positive',
            themes: ['sleep'],
            keywords: ['sleep', 'great'],
            sentimentConfidence: 0.9,
          ),
        ],
        averageConfidence: 0.9,
      );

      final action = service.convertEntryToAction(entry);

      expect(action.message.toLowerCase(), contains('sleep'));
      expect(action.theme, equals('wellness'));
      expect(action.metadata?['emoji'], equals('😴'));
    });

    test('should generate exercise-related action for movement theme', () {
      final entry = FreeFormEntry(
        id: 'exercise_entry',
        originalText: 'Went for a run today, felt amazing!',
        timestamp: DateTime.now(),
        classifications: [
          ClassificationResult(
            habitKey: 'exercise',
            habitValue: 'cardio',
            categoryTitle: 'Exercise',
            categoryType: 'choice',
            confidence: 0.9,
            reasoning: 'Exercise mentioned',
            extractedText: 'went for a run',
            sentiment: 'positive',
            themes: ['exercise', 'movement'],
            keywords: ['run', 'amazing'],
            sentimentConfidence: 0.9,
          ),
        ],
        averageConfidence: 0.9,
      );

      final action = service.convertEntryToAction(entry);

      expect(action.message.toLowerCase(), anyOf(contains('movement'), contains('exercise')));
      expect(action.theme, equals('fitness'));
    });

    test('should detect repeated tags for habit tracking', () async {
      final entries = [
        // Sleep mentioned 3 times in the last week
        FreeFormEntry(
          id: '1',
          originalText: 'Sleep was good',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          classifications: [
            ClassificationResult(
              habitKey: 'sleep',
              habitValue: 'good',
              categoryTitle: 'Sleep',
              categoryType: 'choice',
              confidence: 0.8,
              reasoning: 'Sleep mentioned',
              extractedText: 'sleep was good',
              sentiment: 'positive',
              themes: ['sleep'],
              keywords: ['sleep'],
              sentimentConfidence: 0.8,
            ),
          ],
          averageConfidence: 0.8,
        ),
        FreeFormEntry(
          id: '2',
          originalText: 'Had trouble with sleep',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          classifications: [
            ClassificationResult(
              habitKey: 'sleep',
              habitValue: 'poor',
              categoryTitle: 'Sleep',
              categoryType: 'choice',
              confidence: 0.8,
              reasoning: 'Sleep mentioned',
              extractedText: 'trouble with sleep',
              sentiment: 'negative',
              themes: ['sleep'],
              keywords: ['sleep', 'trouble'],
              sentimentConfidence: 0.8,
            ),
          ],
          averageConfidence: 0.8,
        ),
        FreeFormEntry(
          id: '3',
          originalText: 'Sleep schedule is improving',
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          classifications: [
            ClassificationResult(
              habitKey: 'sleep',
              habitValue: 'improving',
              categoryTitle: 'Sleep',
              categoryType: 'choice',
              confidence: 0.8,
              reasoning: 'Sleep mentioned',
              extractedText: 'sleep schedule improving',
              sentiment: 'positive',
              themes: ['sleep'],
              keywords: ['sleep', 'improving'],
              sentimentConfidence: 0.8,
            ),
          ],
          averageConfidence: 0.8,
        ),
      ];

      final repeatedTags = await service.detectRepeatedTags(entries, threshold: 3);

      expect(repeatedTags, contains('sleep'));
    });

    test('should not detect tags that are too old', () async {
      final entries = [
        FreeFormEntry(
          id: '1',
          originalText: 'Sleep was mentioned',
          timestamp: DateTime.now().subtract(const Duration(days: 40)), // Too old
          classifications: [
            ClassificationResult(
              habitKey: 'sleep',
              habitValue: 'mentioned',
              categoryTitle: 'Sleep',
              categoryType: 'choice',
              confidence: 0.8,
              reasoning: 'Sleep mentioned',
              extractedText: 'sleep was mentioned',
              sentiment: 'neutral',
              themes: ['sleep'],
              keywords: ['sleep'],
              sentimentConfidence: 0.8,
            ),
          ],
          averageConfidence: 0.8,
        ),
      ];

      final repeatedTags = await service.detectRepeatedTags(entries, threshold: 1);

      expect(repeatedTags, isEmpty);
    });

    test('should generate habit tracking suggestion', () {
      const tag = 'sleep';
      const count = 5;

      final suggestion = service.generateHabitSuggestion(tag, count);

      expect(suggestion['title'], contains('Sleep'));
      expect(suggestion['description'], contains('5 times'));
      expect(suggestion['tag'], equals(tag));
      expect(suggestion['formatted_name'], equals('Sleep'));
      expect(suggestion['occurrence_count'], equals(count));
      expect(suggestion['suggested_frequency'], isNotEmpty);
    });

    test('should suggest appropriate frequency for different tag types', () {
      // Sleep should be daily
      final sleepSuggestion = service.generateHabitSuggestion('sleep', 3);
      expect(sleepSuggestion['suggested_frequency'], equals('daily'));

      // Exercise should be 3-4 times per week
      final exerciseSuggestion = service.generateHabitSuggestion('exercise', 3);
      expect(exerciseSuggestion['suggested_frequency'], equals('3-4 times per week'));

      // Social should be weekly
      final socialSuggestion = service.generateHabitSuggestion('social', 3);
      expect(socialSuggestion['suggested_frequency'], equals('weekly'));
    });

    test('should get contextual actions from entry', () {
      final entry = FreeFormEntry(
        id: 'context_entry',
        originalText: 'Feeling stressed about work',
        timestamp: DateTime.now(),
        classifications: [
          ClassificationResult(
            habitKey: 'stress',
            habitValue: 'work stress',
            categoryTitle: 'Mental Health',
            categoryType: 'outcome',
            confidence: 0.8,
            reasoning: 'Stress mentioned',
            extractedText: 'feeling stressed',
            sentiment: 'negative',
            themes: ['stress', 'work'],
            keywords: ['stressed', 'work'],
            sentimentConfidence: 0.8,
          ),
        ],
        averageConfidence: 0.8,
      );

      final actions = service.getContextualActions(entry);

      expect(actions, isNotEmpty);
      expect(actions.length, lessThanOrEqualTo(3));
      
      final stressAction = actions.firstWhere(
        (action) => action['category'] == 'mental_health',
        orElse: () => <String, String>{},
      );
      
      if (stressAction.isNotEmpty) {
        expect(stressAction['title'], isNotEmpty);
        expect(stressAction['description'], isNotEmpty);
        expect(stressAction['emoji'], isNotEmpty);
      }
    });

    test('should handle entry with no classifications', () {
      final entry = FreeFormEntry(
        id: 'no_class_entry',
        originalText: 'Just a random thought',
        timestamp: DateTime.now(),
        classifications: [],
        averageConfidence: 0.0,
      );

      final action = service.convertEntryToAction(entry);

      expect(action.message, isNotEmpty);
      expect(action.theme, equals('reflection'));
      expect(action.metadata?['emoji'], equals('🤔'));
    });

    test('should save and retrieve actions', () async {
      final action = StarboundNudge(
        id: 'test_action',
        theme: 'wellness',
        message: 'Test action message',
        title: 'Test Action',
        content: 'Test action content',
      );

      await service.saveActionToVault(action);
      final savedActions = await service.getSavedActions();

      expect(savedActions, isNotEmpty);
    });

    test('should mark tag as suggested for habits', () async {
      const tag = 'test_tag';

      // Mark as suggested should complete without error
      await service.markTagAsSuggestedForHabits(tag);

      // If we try to detect the same tag again, it should not be returned
      // since it was already suggested
      final entries = List.generate(5, (index) => FreeFormEntry(
        id: 'test_$index',
        originalText: 'test_tag mentioned',
        timestamp: DateTime.now().subtract(Duration(days: index)),
        classifications: [
          ClassificationResult(
            habitKey: 'test_tag',
            habitValue: 'test',
            categoryTitle: 'Test',
            categoryType: 'choice',
            confidence: 0.8,
            reasoning: 'Test',
            extractedText: 'test_tag mentioned',
            sentiment: 'neutral',
            themes: ['test_tag'],
            keywords: ['test_tag'],
            sentimentConfidence: 0.8,
          ),
        ],
        averageConfidence: 0.8,
      ));

      final repeatedTags = await service.detectRepeatedTags(entries, threshold: 3);
      expect(repeatedTags, isNot(contains(tag)));
    });
  });
}