import 'package:flutter/foundation.dart';
import '../models/habit_model.dart';
import '../models/conversation_thread.dart';
import '../models/forecast_model.dart';
import '../components/unified_search_widget.dart';
import 'search_intent_classifier_service.dart';
import 'storage_service.dart';

/// Search result from different data sources
class SearchResult {
  final String id;
  final String title;
  final String content;
  final String snippet;
  final SearchResultType type;
  final DateTime timestamp;
  final double relevanceScore;
  final Map<String, dynamic> metadata;

  const SearchResult({
    required this.id,
    required this.title,
    required this.content,
    required this.snippet,
    required this.type,
    required this.timestamp,
    required this.relevanceScore,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'snippet': snippet,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'relevanceScore': relevanceScore,
      'metadata': metadata,
    };
  }
}

/// Types of search results
enum SearchResultType {
  journalEntry,
  conversation,
  habitEntry,
  forecast,
  recommendation,
}

/// Categorized search results
class SearchResults {
  final String query;
  final SearchIntent detectedIntent;
  final List<SearchResult> journalResults;
  final List<SearchResult> conversationResults;
  final List<SearchResult> forecastResults;
  final List<SearchResult> allResults;
  final int totalResults;
  final Duration searchTime;

  const SearchResults({
    required this.query,
    required this.detectedIntent,
    required this.journalResults,
    required this.conversationResults,
    required this.forecastResults,
    required this.allResults,
    required this.totalResults,
    required this.searchTime,
  });

  bool get hasResults => totalResults > 0;
  bool get hasJournalResults => journalResults.isNotEmpty;
  bool get hasConversationResults => conversationResults.isNotEmpty;
  bool get hasForecastResults => forecastResults.isNotEmpty;
}

/// Service for searching across all Starbound features
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final SearchIntentClassifierService _intentClassifier = SearchIntentClassifierService();
  final StorageService _storageService = StorageService();

  /// Main search method that queries across all features
  Future<SearchResults> search(String query, {SearchIntent? forceIntent}) async {
    if (query.trim().isEmpty) {
      return SearchResults(
        query: query,
        detectedIntent: SearchIntent.unknown,
        journalResults: [],
        conversationResults: [],
        forecastResults: [],
        allResults: [],
        totalResults: 0,
        searchTime: Duration.zero,
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Detect intent if not forced
      final intentResult = forceIntent != null
          ? SearchIntentResult(
              intent: forceIntent,
              confidence: 1.0,
              reasoning: 'Intent forced by user',
            )
          : await _intentClassifier.classifyIntent(query);

      // Search based on intent priority, but also search other sources
      List<SearchResult> journalResults = [];
      List<SearchResult> conversationResults = [];
      List<SearchResult> forecastResults = [];

      // Perform searches in parallel for better performance
      final futures = <Future>[];

      // Always search journals as they contain the most historical data
      futures.add(_searchJournalEntries(query).then((results) => journalResults = results));

      // Always search conversations for context
      futures.add(_searchConversations(query).then((results) => conversationResults = results));

      // Search forecasts if relevant or if intent suggests it
      if (intentResult.intent == SearchIntent.healthForecast ||
          intentResult.intent == SearchIntent.unknown ||
          _containsForecastKeywords(query.toLowerCase())) {
        futures.add(_searchForecasts(query).then((results) => forecastResults = results));
      }

      await Future.wait(futures);

      // Combine and rank results
      final allResults = <SearchResult>[];
      allResults.addAll(journalResults);
      allResults.addAll(conversationResults);
      allResults.addAll(forecastResults);

      // Sort by relevance and recency
      allResults.sort((a, b) {
        // First by relevance score
        final scoreComparison = b.relevanceScore.compareTo(a.relevanceScore);
        if (scoreComparison != 0) return scoreComparison;
        
        // Then by recency
        return b.timestamp.compareTo(a.timestamp);
      });

      stopwatch.stop();

      return SearchResults(
        query: query,
        detectedIntent: intentResult.intent,
        journalResults: journalResults,
        conversationResults: conversationResults,
        forecastResults: forecastResults,
        allResults: allResults,
        totalResults: allResults.length,
        searchTime: stopwatch.elapsed,
      );
    } catch (e) {
      debugPrint('Search error: $e');
      stopwatch.stop();
      
      return SearchResults(
        query: query,
        detectedIntent: SearchIntent.unknown,
        journalResults: [],
        conversationResults: [],
        forecastResults: [],
        allResults: [],
        totalResults: 0,
        searchTime: stopwatch.elapsed,
      );
    }
  }

  /// Search through journal entries and habit logs
  Future<List<SearchResult>> _searchJournalEntries(String query) async {
    try {
      final results = <SearchResult>[];
      final queryLower = query.toLowerCase();

      // Search free-form entries
      final freeFormEntries = await _getFreeFormEntries();
      for (final entry in freeFormEntries) {
        final content = entry.originalText.toLowerCase();
        final summary = entry.summary.toLowerCase();
        
        if (content.contains(queryLower) || summary.contains(queryLower)) {
          final relevance = _calculateRelevance(queryLower, content + ' ' + summary);
          final snippet = _generateSnippet(entry.originalText, query);
          
          results.add(SearchResult(
            id: entry.id,
            title: 'Journal Entry - ${_formatDate(entry.timestamp)}',
            content: entry.originalText,
            snippet: snippet,
            type: SearchResultType.journalEntry,
            timestamp: entry.timestamp,
            relevanceScore: relevance,
            metadata: {
              'classifications': entry.classifications.map((c) => c.toJson()).toList(),
              'averageConfidence': entry.averageConfidence,
              'classificationCount': entry.classificationCount,
            },
          ));
        }
      }

      // Search habit entries
      final habitEntries = await _getHabitEntries();
      for (final entry in habitEntries) {
        final searchableText = '${entry.category} ${entry.value} ${entry.notes ?? ''}'.toLowerCase();
        
        if (searchableText.contains(queryLower)) {
          final relevance = _calculateRelevance(queryLower, searchableText);
          final snippet = _generateHabitSnippet(entry, query);
          
          results.add(SearchResult(
            id: entry.id,
            title: 'Habit Log - ${entry.category}',
            content: entry.notes ?? 'Logged ${entry.category}: ${entry.value}',
            snippet: snippet,
            type: SearchResultType.habitEntry,
            timestamp: entry.timestamp,
            relevanceScore: relevance,
            metadata: {
              'category': entry.category,
              'value': entry.value,
              'habitType': entry.categoryType,
            },
          ));
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error searching journal entries: $e');
      return [];
    }
  }

  /// Search through Ask Starbound conversation history
  Future<List<SearchResult>> _searchConversations(String query) async {
    try {
      final results = <SearchResult>[];
      final queryLower = query.toLowerCase();

      final conversations = await _getConversationThreads();
      for (final thread in conversations) {
        // Search thread title and main topic
        final threadSearchText = '${thread.title} ${thread.mainTopic ?? ''}'.toLowerCase();
        if (threadSearchText.contains(queryLower)) {
          final relevance = _calculateRelevance(queryLower, threadSearchText);
          final snippet = thread.title;
          
          results.add(SearchResult(
            id: thread.id,
            title: 'Conversation: ${thread.title}',
            content: thread.title,
            snippet: snippet,
            type: SearchResultType.conversation,
            timestamp: thread.lastActivity,
            relevanceScore: relevance + 0.1, // Boost thread matches
            metadata: {
              'exchangeCount': thread.exchanges.length,
              'mainTopic': thread.mainTopic,
              'type': 'thread',
            },
          ));
        }

        // Search individual exchanges
        for (final exchange in thread.exchanges) {
          final exchangeSearchText = '${exchange.question} ${exchange.response.overview}'.toLowerCase();
          if (exchangeSearchText.contains(queryLower)) {
            final relevance = _calculateRelevance(queryLower, exchangeSearchText);
            final snippet = _generateSnippet(exchange.question + ' ' + exchange.response.overview, query);
            
            results.add(SearchResult(
              id: '${thread.id}_${exchange.id}',
              title: 'Q: ${_truncateText(exchange.question, 50)}',
              content: exchange.response.overview,
              snippet: snippet,
              type: SearchResultType.conversation,
              timestamp: exchange.timestamp,
              relevanceScore: relevance,
              metadata: {
                'threadId': thread.id,
                'threadTitle': thread.title,
                'question': exchange.question,
                'immediateSteps': exchange.response.immediateSteps.length,
                'type': 'exchange',
              },
            ));
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error searching conversations: $e');
      return [];
    }
  }

  /// Search through health forecasts and predictions
  Future<List<SearchResult>> _searchForecasts(String query) async {
    try {
      final results = <SearchResult>[];
      final queryLower = query.toLowerCase();

      final forecasts = await _storageService.loadForecastEntries();
      for (final entry in forecasts) {
        final searchable = _buildForecastSearchCorpus(entry).toLowerCase();

        if (queryLower.isNotEmpty && !searchable.contains(queryLower)) {
          continue;
        }

        final relevance = _calculateRelevance(queryLower, searchable);
        final snippet = _generateSnippet(
          entry.summary.isNotEmpty
              ? entry.summary
              : entry.horizons.isNotEmpty
                  ? entry.horizons.first.outlook
                  : entry.immediateAction,
          query,
        );

        results.add(
          SearchResult(
            id: entry.id,
            title: 'Forecast - ${entry.habit}',
            content: entry.summary.isNotEmpty
                ? entry.summary
                : entry.immediateAction,
            snippet: snippet,
            type: SearchResultType.forecast,
            timestamp: entry.createdAt,
            relevanceScore: relevance,
            metadata: {
              'habit': entry.habit,
              'summary': entry.summary,
              'immediate_action': entry.immediateAction,
              'key_signals': entry.keySignals,
              'why_it_matters': entry.whyItMatters,
              'impact_areas': entry.impactAreas,
              'horizons': entry.horizons
                  .map((h) => {
                        'id': h.id,
                        'label': h.label,
                        'timeframe': h.timeframe,
                        'outlook': h.outlook,
                        'recommended_move': h.recommendedMove,
                        'driving_signals': h.drivingSignals,
                        'confidence': h.confidence,
                        'risk_level': h.riskLevel,
                        if (h.trend != null) 'trend': h.trend,
                      })
                  .toList(),
            },
          ),
        );
      }

      results.sort((a, b) {
        final relevanceDiff = b.relevanceScore.compareTo(a.relevanceScore);
        if (relevanceDiff != 0) return relevanceDiff;
        return b.timestamp.compareTo(a.timestamp);
      });

      return results;
    } catch (e) {
      debugPrint('Error searching forecasts: $e');
      return [];
    }
  }

  String _buildForecastSearchCorpus(ForecastEntry entry) {
    final buffer = StringBuffer()
      ..write(entry.habit)
      ..write(' ')
      ..write(entry.summary)
      ..write(' ')
      ..write(entry.immediateAction)
      ..write(' ')
      ..write(entry.whyItMatters)
      ..write(' ')
      ..write(entry.encouragement);

    for (final signal in entry.keySignals) {
      buffer
        ..write(' ')
        ..write(signal);
    }

    entry.impactAreas.forEach((domain, description) {
      buffer
        ..write(' ')
        ..write(domain)
        ..write(' ')
        ..write(description);
    });

    for (final horizon in entry.horizons) {
      buffer
        ..write(' ')
        ..write(horizon.label)
        ..write(' ')
        ..write(horizon.timeframe)
        ..write(' ')
        ..write(horizon.outlook)
        ..write(' ')
        ..write(horizon.recommendedMove);

      for (final driver in horizon.drivingSignals) {
        buffer
          ..write(' ')
          ..write(driver);
      }
    }

    return buffer.toString();
  }

  // Helper methods for data retrieval
  Future<List<FreeFormEntry>> _getFreeFormEntries() async {
    try {
      return await _storageService.getAllFreeFormEntries();
    } catch (e) {
      debugPrint('Error getting free form entries: $e');
      return [];
    }
  }

  Future<List<HabitLogEntry>> _getHabitEntries() async {
    try {
      return await _storageService.getAllHabitEntries();
    } catch (e) {
      debugPrint('Error getting habit entries: $e');
      return [];
    }
  }

  Future<List<ConversationThread>> _getConversationThreads() async {
    try {
      return await _storageService.getAllConversationThreads();
    } catch (e) {
      debugPrint('Error getting conversation threads: $e');
      return [];
    }
  }

  // Utility methods
  double _calculateRelevance(String query, String content) {
    final queryWords = query.split(' ').where((w) => w.isNotEmpty).toList();
    if (queryWords.isEmpty) return 0.0;

    double score = 0.0;
    int totalMatches = 0;

    for (final word in queryWords) {
      final matches = word.allMatches(content).length;
      if (matches > 0) {
        totalMatches += matches;
        // Boost exact matches
        if (content.contains(word)) {
          score += matches * 0.8;
        }
        // Partial matches get lower score
        score += matches * 0.4;
      }
    }

    // Normalize by query length and content length
    final normalizedScore = score / (queryWords.length * (content.length / 100 + 1));
    return normalizedScore.clamp(0.0, 1.0);
  }

  String _generateSnippet(String content, String query, {int maxLength = 100}) {
    final queryLower = query.toLowerCase();
    final contentLower = content.toLowerCase();
    
    // Find the first occurrence of any query word
    int startIndex = contentLower.indexOf(queryLower);
    if (startIndex == -1) {
      // If exact query not found, find first word
      final queryWords = queryLower.split(' ');
      for (final word in queryWords) {
        startIndex = contentLower.indexOf(word);
        if (startIndex != -1) break;
      }
    }
    
    if (startIndex == -1) {
      return _truncateText(content, maxLength);
    }
    
    // Create snippet around the match
    final start = (startIndex - 20).clamp(0, content.length);
    final end = (startIndex + maxLength - 20).clamp(0, content.length);
    
    String snippet = content.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';
    
    return snippet;
  }

  String _generateHabitSnippet(HabitLogEntry entry, String query) {
    return 'Logged ${entry.category}: ${entry.value}${entry.notes != null && entry.notes!.isNotEmpty ? ' - ${entry.notes}' : ''}';
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _containsForecastKeywords(String query) {
    final forecastKeywords = [
      'predict', 'forecast', 'future', 'next', 'will', 'trend', 'pattern'
    ];
    return forecastKeywords.any((keyword) => query.contains(keyword));
  }
}

// Data model for habit log entries (placeholder until proper implementation)
class HabitLogEntry {
  final String id;
  final String category;
  final String value;
  final String? notes;
  final DateTime timestamp;
  final String categoryType;

  const HabitLogEntry({
    required this.id,
    required this.category,
    required this.value,
    this.notes,
    required this.timestamp,
    required this.categoryType,
  });
}
