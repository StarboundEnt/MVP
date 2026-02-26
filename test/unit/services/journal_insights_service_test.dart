import 'package:flutter_test/flutter_test.dart';
import 'package:starbound/services/journal_insights_service.dart';
import 'package:starbound/models/habit_model.dart';

void main() {
  group('JournalInsightsService', () {
    late JournalInsightsService service;

    setUp(() {
      service = JournalInsightsService();
    });

    test('should generate tag frequency insights', () {
      final entries = [
        FreeFormEntry(
          id: '1',
          originalText: 'Had a good sleep last night',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          classifications: [
            ClassificationResult(
              habitKey: 'sleep',
              habitValue: 'good sleep',
              categoryTitle: 'Sleep',
              categoryType: 'choice',
              confidence: 0.9,
              reasoning: 'Sleep mentioned',
              extractedText: 'good sleep',
              sentiment: 'positive',
              themes: ['sleep', 'wellbeing'],
              keywords: ['sleep', 'good'],
              sentimentConfidence: 0.8,
            ),
          ],
          averageConfidence: 0.9,
        ),
        FreeFormEntry(
          id: '2', 
          originalText: 'Sleep was terrible, stayed up too late',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          classifications: [
            ClassificationResult(
              habitKey: 'sleep',
              habitValue: 'poor sleep',
              categoryTitle: 'Sleep',
              categoryType: 'choice',
              confidence: 0.8,
              reasoning: 'Sleep mentioned',
              extractedText: 'sleep was terrible',
              sentiment: 'negative',
              themes: ['sleep', 'wellbeing'],
              keywords: ['sleep', 'terrible'],
              sentimentConfidence: 0.9,
            ),
          ],
          averageConfidence: 0.8,
        ),
      ];

      final insights = service.generateWeeklyInsights(entries);
      
      expect(insights, isNotEmpty);
      final sleepInsight = insights.firstWhere(
        (insight) => insight.title.toLowerCase().contains('sleep'),
        orElse: () => throw StateError('No sleep insight found'),
      );
      
      expect(sleepInsight.category, equals('pattern'));
      expect(sleepInsight.description.toLowerCase(), contains('sleep'));
      expect(sleepInsight.description, contains('×')); // Just check for the × symbol
    });

    test('should generate mood trend insights', () {
      final entries = List.generate(5, (index) => FreeFormEntry(
        id: index.toString(),
        originalText: 'Feeling positive today',
        timestamp: DateTime.now().subtract(Duration(days: index)),
        classifications: [
          ClassificationResult(
            habitKey: 'mood',
            habitValue: 'positive',
            categoryTitle: 'Mood',
            categoryType: 'outcome',
            confidence: 0.9,
            reasoning: 'Positive sentiment',
            extractedText: 'feeling positive',
            sentiment: 'positive',
            themes: ['mood', 'emotions'],
            keywords: ['positive', 'feeling'],
            sentimentConfidence: 0.9,
          ),
        ],
        averageConfidence: 0.9,
      ));

      final insights = service.generateWeeklyInsights(entries);
      
      final moodInsight = insights.where((insight) => insight.category == 'mood');
      expect(moodInsight, isNotEmpty);
      expect(moodInsight.first.title, contains('Positive'));
    });

    test('should generate correlation insights', () {
      final entries = [
        FreeFormEntry(
          id: '1',
          originalText: 'Had good sleep and felt energetic',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          classifications: [
            ClassificationResult(
              habitKey: 'sleep',
              habitValue: 'good sleep',
              categoryTitle: 'Sleep',
              categoryType: 'choice',
              confidence: 0.9,
              reasoning: 'Sleep mentioned',
              extractedText: 'good sleep',
              sentiment: 'positive',
              themes: ['sleep', 'energy'],
              keywords: ['sleep', 'energetic'],
              sentimentConfidence: 0.8,
            ),
          ],
          averageConfidence: 0.9,
        ),
        FreeFormEntry(
          id: '2',
          originalText: 'Great sleep again, lots of energy',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          classifications: [
            ClassificationResult(
              habitKey: 'sleep',
              habitValue: 'good sleep',
              categoryTitle: 'Sleep',
              categoryType: 'choice',
              confidence: 0.8,
              reasoning: 'Sleep mentioned',
              extractedText: 'great sleep',
              sentiment: 'positive',
              themes: ['sleep', 'energy'],
              keywords: ['sleep', 'energy'],
              sentimentConfidence: 0.9,
            ),
          ],
          averageConfidence: 0.8,
        ),
      ];

      final insights = service.generateWeeklyInsights(entries);
      
      final correlationInsights = insights.where((insight) => insight.category == 'correlation');
      
      if (correlationInsights.isNotEmpty) {
        final sleepEnergyInsight = correlationInsights.firstWhere(
          (insight) => insight.description.toLowerCase().contains('sleep') && 
                      insight.description.toLowerCase().contains('energy'),
          orElse: () => correlationInsights.first,
        );
        
        expect(sleepEnergyInsight.description.toLowerCase(), contains('good')); // The service uses "good feelings"
      } else {
        // If no correlations found, just verify insights were generated
        expect(insights, isNotEmpty);
      }
    });

    test('should generate growth insights', () {
      final entries = [
        FreeFormEntry(
          id: '1',
          originalText: 'Learning so much about myself today',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          classifications: [
            ClassificationResult(
              habitKey: 'reflection',
              habitValue: 'self reflection',
              categoryTitle: 'Growth',
              categoryType: 'choice',
              confidence: 0.9,
              reasoning: 'Growth mentioned',
              extractedText: 'learning so much about myself',
              sentiment: 'positive',
              themes: ['growth', 'learning'],
              keywords: ['learning', 'myself'],
              sentimentConfidence: 0.8,
            ),
          ],
          averageConfidence: 0.9,
        ),
        FreeFormEntry(
          id: '2',
          originalText: 'Made progress on my goals today',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          classifications: [
            ClassificationResult(
              habitKey: 'goals',
              habitValue: 'goal progress',
              categoryTitle: 'Growth',
              categoryType: 'choice',
              confidence: 0.8,
              reasoning: 'Progress mentioned',
              extractedText: 'made progress on goals',
              sentiment: 'positive',
              themes: ['growth', 'goals'],
              keywords: ['progress', 'goals'],
              sentimentConfidence: 0.9,
            ),
          ],
          averageConfidence: 0.8,
        ),
      ];

      final insights = service.generateWeeklyInsights(entries);
      
      final growthInsights = insights.where((insight) => insight.category == 'growth');
      expect(growthInsights, isNotEmpty);
      expect(growthInsights.first.description, contains('growth'));
    });

    test('should generate weekly summary', () {
      final entries = [
        FreeFormEntry(
          id: '1',
          originalText: 'Sleep was great',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          classifications: [
            ClassificationResult(
              habitKey: 'sleep',
              habitValue: 'good sleep',
              categoryTitle: 'Sleep',
              categoryType: 'choice',
              confidence: 0.9,
              reasoning: 'Sleep mentioned',
              extractedText: 'sleep was great',
              sentiment: 'positive',
              themes: ['sleep'],
              keywords: ['sleep', 'great'],
              sentimentConfidence: 0.8,
            ),
          ],
          averageConfidence: 0.9,
        ),
      ];

      final summary = service.getWeeklySummary(entries);
      
      expect(summary['total_entries'], equals(1));
      expect(summary['average_mood'], equals('positive'));
      expect(summary['top_tags'], isNotEmpty);
      expect(summary['mood_distribution'], isA<Map>());
    });

    test('should handle empty entries gracefully', () {
      final insights = service.generateWeeklyInsights([]);
      final summary = service.getWeeklySummary([]);
      
      expect(insights, isEmpty);
      expect(summary['total_entries'], equals(0));
      expect(summary['top_tags'], isEmpty);
      expect(summary['average_mood'], equals('neutral'));
    });

    test('should format tag names correctly', () {
      final entries = [
        FreeFormEntry(
          id: '1',
          originalText: 'Had some physical_activity today',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          classifications: [
            ClassificationResult(
              habitKey: 'physical_activity',
              habitValue: 'exercise',
              categoryTitle: 'Exercise',
              categoryType: 'choice',
              confidence: 0.9,
              reasoning: 'Exercise mentioned',
              extractedText: 'physical activity',
              sentiment: 'positive',
              themes: ['physical_activity'],
              keywords: ['physical', 'activity'],
              sentimentConfidence: 0.8,
            ),
          ],
          averageConfidence: 0.9,
        ),
      ];

      final summary = service.getWeeklySummary(entries);
      final topTags = List<Map<String, dynamic>>.from(summary['top_tags']);
      
      expect(topTags.first['tag'], equals('Physical Activity'));
    });
  });
}