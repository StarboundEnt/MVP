import 'dart:math';
import '../models/habit_model.dart';

/// Represents a weekly insight or pattern discovered from journal entries
class WeeklyInsight {
  final String id;
  final String title;
  final String description;
  final String category; // 'pattern', 'mood', 'correlation', 'growth'
  final double confidence;
  final Map<String, dynamic> data;
  final DateTime generatedAt;
  final List<String> supportingEntryIds;

  const WeeklyInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.confidence,
    required this.data,
    required this.generatedAt,
    this.supportingEntryIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'confidence': confidence,
    'data': data,
    'generated_at': generatedAt.toIso8601String(),
    'supporting_entry_ids': supportingEntryIds,
  };

  factory WeeklyInsight.fromJson(Map<String, dynamic> json) => WeeklyInsight(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? 'pattern',
    confidence: (json['confidence'] ?? 0.0).toDouble(),
    data: Map<String, dynamic>.from(json['data'] ?? {}),
    generatedAt: DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
    supportingEntryIds: List<String>.from(json['supporting_entry_ids'] ?? []),
  );
}

/// Service for analyzing journal entries and generating insights
class JournalInsightsService {
  /// Generate weekly insights from journal entries
  List<WeeklyInsight> generateWeeklyInsights(List<FreeFormEntry> entries) {
    final insights = <WeeklyInsight>[];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Filter entries to current week
    final weekEntries = entries.where((entry) {
      return entry.timestamp.isAfter(weekStart) && entry.timestamp.isBefore(weekEnd);
    }).toList();

    if (weekEntries.isEmpty) return insights;

    // Generate different types of insights
    insights.addAll(_generateTagFrequencyInsights(weekEntries));
    insights.addAll(_generateMoodTrendInsights(weekEntries));
    insights.addAll(_generateCorrelationInsights(weekEntries));
    insights.addAll(_generateGrowthInsights(weekEntries));

    // Sort by confidence and return top insights
    insights.sort((a, b) => b.confidence.compareTo(a.confidence));
    return insights.take(3).toList(); // Return top 3 insights
  }

  /// Generate insights about tag/theme frequency patterns
  List<WeeklyInsight> _generateTagFrequencyInsights(List<FreeFormEntry> entries) {
    final insights = <WeeklyInsight>[];
    final tagCounts = <String, int>{};
    final tagSentiments = <String, List<String>>{};
    final tagEntries = <String, List<String>>{};

    // Count tag occurrences and track sentiments
    for (final entry in entries) {
      for (final classification in entry.classifications) {
        // Count themes
        for (final theme in classification.themes) {
          tagCounts[theme] = (tagCounts[theme] ?? 0) + 1;
          tagSentiments.putIfAbsent(theme, () => []).add(classification.sentiment);
          tagEntries.putIfAbsent(theme, () => []).add(entry.id);
        }
        
        // Count habit keys as tags too
        if (classification.habitKey.isNotEmpty) {
          tagCounts[classification.habitKey] = (tagCounts[classification.habitKey] ?? 0) + 1;
          tagSentiments.putIfAbsent(classification.habitKey, () => []).add(classification.sentiment);
          tagEntries.putIfAbsent(classification.habitKey, () => []).add(entry.id);
        }
      }
    }

    // Generate insights for frequently mentioned tags
    for (final entry in tagCounts.entries) {
      final tag = entry.key;
      final count = entry.value;
      
      if (count >= 2) { // Tag mentioned at least twice
        final sentiments = tagSentiments[tag] ?? [];
        final positiveCount = sentiments.where((s) => s == 'positive').length;
        final negativeCount = sentiments.where((s) => s == 'negative').length;
        final entryIds = tagEntries[tag] ?? [];

        String description;
        String category = 'pattern';
        double confidence = min(count / entries.length, 1.0);

        if (positiveCount > negativeCount) {
          description = "You mentioned ${_formatTagName(tag)} ${count}× this week — and it's been linked to positive feelings!";
          confidence += 0.2; // Boost confidence for positive correlations
        } else if (negativeCount > positiveCount) {
          description = "You mentioned ${_formatTagName(tag)} ${count}× this week — this might be something to explore further.";
          category = 'concern';
        } else {
          description = "You mentioned ${_formatTagName(tag)} ${count}× this week — it's been a recurring theme.";
        }

        insights.add(WeeklyInsight(
          id: 'tag_frequency_${tag}_${DateTime.now().millisecondsSinceEpoch}',
          title: '${_formatTagName(tag)} pattern spotted',
          description: description,
          category: category,
          confidence: min(confidence, 1.0),
          data: {
            'tag': tag,
            'count': count,
            'positive_mentions': positiveCount,
            'negative_mentions': negativeCount,
            'total_entries': entries.length,
          },
          generatedAt: DateTime.now(),
          supportingEntryIds: entryIds,
        ));
      }
    }

    return insights;
  }

  /// Generate insights about mood trends and sentiment patterns
  List<WeeklyInsight> _generateMoodTrendInsights(List<FreeFormEntry> entries) {
    final insights = <WeeklyInsight>[];
    final dailySentiments = <String, List<String>>{};

    // Group sentiments by day
    for (final entry in entries) {
      final dayKey = '${entry.timestamp.year}-${entry.timestamp.month}-${entry.timestamp.day}';
      for (final classification in entry.classifications) {
        dailySentiments.putIfAbsent(dayKey, () => []).add(classification.sentiment);
      }
    }

    if (dailySentiments.length >= 3) { // Need at least 3 days of data
      final positiveDays = dailySentiments.entries
          .where((e) => e.value.where((s) => s == 'positive').length > e.value.where((s) => s == 'negative').length)
          .length;
      
      final totalDays = dailySentiments.length;
      final positiveRatio = positiveDays / totalDays;

      if (positiveRatio >= 0.7) {
        insights.add(WeeklyInsight(
          id: 'mood_positive_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Positive week detected! 🌟',
          description: 'Your mood has been trending upward — ${positiveDays} out of ${totalDays} days showed positive emotions.',
          category: 'mood',
          confidence: positiveRatio,
          data: {
            'positive_days': positiveDays,
            'total_days': totalDays,
            'positive_ratio': positiveRatio,
          },
          generatedAt: DateTime.now(),
        ));
      } else if (positiveRatio <= 0.3) {
        insights.add(WeeklyInsight(
          id: 'mood_challenging_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Challenging week noticed',
          description: 'This week seems to have had more difficult moments. Remember, tough times don\'t last — you do.',
          category: 'concern',
          confidence: 1 - positiveRatio,
          data: {
            'positive_days': positiveDays,
            'total_days': totalDays,
            'positive_ratio': positiveRatio,
          },
          generatedAt: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  /// Generate insights about correlations between different themes
  List<WeeklyInsight> _generateCorrelationInsights(List<FreeFormEntry> entries) {
    final insights = <WeeklyInsight>[];
    final coOccurrences = <String, Map<String, int>>{};
    final tagSentiments = <String, List<String>>{};

    // Track co-occurrences of themes in the same entry
    for (final entry in entries) {
      final entryThemes = <String>{};
      final entryMood = <String, String>{};

      for (final classification in entry.classifications) {
        entryThemes.addAll(classification.themes);
        if (classification.habitKey.isNotEmpty) {
          entryThemes.add(classification.habitKey);
        }
        
        // Track mood for each theme
        for (final theme in classification.themes) {
          entryMood[theme] = classification.sentiment;
          tagSentiments.putIfAbsent(theme, () => []).add(classification.sentiment);
        }
      }

      // Record co-occurrences
      final themes = entryThemes.toList();
      for (int i = 0; i < themes.length; i++) {
        for (int j = i + 1; j < themes.length; j++) {
          final theme1 = themes[i];
          final theme2 = themes[j];
          
          coOccurrences.putIfAbsent(theme1, () => {});
          coOccurrences[theme1]![theme2] = (coOccurrences[theme1]![theme2] ?? 0) + 1;
          
          coOccurrences.putIfAbsent(theme2, () => {});
          coOccurrences[theme2]![theme1] = (coOccurrences[theme2]![theme1] ?? 0) + 1;
        }
      }
    }

    // Find meaningful correlations
    for (final theme1Entry in coOccurrences.entries) {
      final theme1 = theme1Entry.key;
      final correlatedThemes = theme1Entry.value;

      for (final correlationEntry in correlatedThemes.entries) {
        final theme2 = correlationEntry.key;
        final coOccurrenceCount = correlationEntry.value;

        if (coOccurrenceCount >= 2) { // Appeared together at least twice
          final theme1Sentiments = tagSentiments[theme1] ?? [];
          final theme2Sentiments = tagSentiments[theme2] ?? [];
          
          final theme1Positive = theme1Sentiments.where((s) => s == 'positive').length;
          final theme2Positive = theme2Sentiments.where((s) => s == 'positive').length;

          // Look for positive correlations
          if (theme1Positive > 0 && theme2Positive > 0) {
            final confidence = coOccurrenceCount / entries.length;
            
            insights.add(WeeklyInsight(
              id: 'correlation_${theme1}_${theme2}_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Positive pattern discovered',
              description: 'You mentioned ${_formatTagName(theme1)} and ${_formatTagName(theme2)} together ${coOccurrenceCount}× — and both were linked to good feelings!',
              category: 'correlation',
              confidence: confidence,
              data: {
                'theme1': theme1,
                'theme2': theme2,
                'co_occurrence_count': coOccurrenceCount,
                'theme1_positive_count': theme1Positive,
                'theme2_positive_count': theme2Positive,
              },
              generatedAt: DateTime.now(),
            ));
          }
        }
      }
    }

    return insights;
  }

  /// Generate insights about personal growth and progress
  List<WeeklyInsight> _generateGrowthInsights(List<FreeFormEntry> entries) {
    final insights = <WeeklyInsight>[];
    
    // Look for growth-related keywords and themes
    final growthKeywords = ['learn', 'grow', 'improve', 'better', 'progress', 'achieve', 'succeed', 'proud'];
    final growthMentions = <String, List<String>>{};

    for (final entry in entries) {
      for (final classification in entry.classifications) {
        final text = classification.extractedText.toLowerCase();
        for (final keyword in growthKeywords) {
          if (text.contains(keyword)) {
            growthMentions.putIfAbsent(keyword, () => []).add(entry.id);
          }
        }
      }
    }

    final totalGrowthMentions = growthMentions.values.expand((list) => list).toSet().length;
    
    if (totalGrowthMentions >= 2) {
      final confidence = min(totalGrowthMentions / entries.length, 1.0);
      
      insights.add(WeeklyInsight(
        id: 'growth_pattern_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Growth mindset shining through ✨',
        description: 'You\'ve mentioned growth and learning ${totalGrowthMentions}× this week — your commitment to personal development is inspiring!',
        category: 'growth',
        confidence: confidence + 0.3, // Boost confidence for growth insights
        data: {
          'growth_mentions': totalGrowthMentions,
          'keywords_mentioned': growthMentions.keys.toList(),
          'total_entries': entries.length,
        },
        generatedAt: DateTime.now(),
      ));
    }

    return insights;
  }

  /// Format tag name for display (convert underscores to spaces, capitalize)
  String _formatTagName(String tag) {
    return tag.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Get summary statistics for the current week
  Map<String, dynamic> getWeeklySummary(List<FreeFormEntry> entries) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final weekEntries = entries.where((entry) {
      return entry.timestamp.isAfter(weekStart) && entry.timestamp.isBefore(weekEnd);
    }).toList();

    if (weekEntries.isEmpty) {
      return {
        'total_entries': 0,
        'top_tags': <String>[],
        'average_mood': 'neutral',
        'mood_distribution': {'positive': 0, 'neutral': 0, 'negative': 0},
      };
    }

    // Count all tags/themes
    final tagCounts = <String, int>{};
    final sentiments = <String>[];

    for (final entry in weekEntries) {
      for (final classification in entry.classifications) {
        sentiments.add(classification.sentiment);
        
        for (final theme in classification.themes) {
          tagCounts[theme] = (tagCounts[theme] ?? 0) + 1;
        }
        
        if (classification.habitKey.isNotEmpty) {
          tagCounts[classification.habitKey] = (tagCounts[classification.habitKey] ?? 0) + 1;
        }
      }
    }

    // Get top 3 tags
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(3).map((e) => {
      'tag': _formatTagName(e.key),
      'count': e.value,
    }).toList();

    // Calculate mood distribution
    final positiveCount = sentiments.where((s) => s == 'positive').length;
    final negativeCount = sentiments.where((s) => s == 'negative').length;
    final neutralCount = sentiments.length - positiveCount - negativeCount;

    String averageMood;
    if (positiveCount > negativeCount && positiveCount > neutralCount) {
      averageMood = 'positive';
    } else if (negativeCount > positiveCount && negativeCount > neutralCount) {
      averageMood = 'negative';
    } else {
      averageMood = 'neutral';
    }

    return {
      'total_entries': weekEntries.length,
      'top_tags': topTags,
      'average_mood': averageMood,
      'mood_distribution': {
        'positive': positiveCount,
        'neutral': neutralCount,
        'negative': negativeCount,
      },
      'week_start': weekStart.toIso8601String(),
      'week_end': weekEnd.toIso8601String(),
    };
  }

  /// Get insights for a specific time period
  List<WeeklyInsight> getInsightsForPeriod(List<FreeFormEntry> entries, DateTime start, DateTime end) {
    final periodEntries = entries.where((entry) {
      return entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end);
    }).toList();

    if (periodEntries.isEmpty) return [];

    final insights = <WeeklyInsight>[];
    insights.addAll(_generateTagFrequencyInsights(periodEntries));
    insights.addAll(_generateMoodTrendInsights(periodEntries));
    insights.addAll(_generateCorrelationInsights(periodEntries));
    insights.addAll(_generateGrowthInsights(periodEntries));

    insights.sort((a, b) => b.confidence.compareTo(a.confidence));
    return insights;
  }
}