import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/smart_tag_model.dart';
import 'env_service.dart';
import 'logging_service.dart';

/// Lightweight client for sending journal episodes to the Complexity Profile ingest API while retaining backward compatibility with legacy Graphiti configuration.
class GraphitiService {
  GraphitiService._internal();

  static final GraphitiService _instance = GraphitiService._internal();
  factory GraphitiService() => _instance;

  final http.Client _client = http.Client();

  bool _isInitialized = false;
  String? _baseUrl;
  String _ingestPath = '/ingest';
  String _sourceDescription = 'starbound_smart_journal_v1';
  String _roleLabel = 'journaler';
  String _groupPrefix = 'user';
  String? _apiKey;

  /// Ensure configuration is loaded from the .env file.
  Future<void> initialize({String? overrideBaseUrl}) async {
    if (_isInitialized) {
      if (overrideBaseUrl != null) {
        _baseUrl = overrideBaseUrl;
      }
      return;
    }

    final env = EnvService.instance;
    await env.load();

    _baseUrl = overrideBaseUrl ?? env.maybe('COMPLEXITY_API_BASE_URL') ?? env.maybe('GRAPHITI_BASE_URL');
    _ingestPath = env.maybe('COMPLEXITY_API_INGEST_PATH') ?? env.maybe('GRAPHITI_MESSAGES_PATH') ?? _ingestPath;
    _sourceDescription = env.maybe('COMPLEXITY_API_SOURCE_DESCRIPTION') ??
        env.maybe('GRAPHITI_SOURCE_DESCRIPTION') ?? _sourceDescription;
    _roleLabel = env.maybe('COMPLEXITY_API_ROLE_LABEL') ?? env.maybe('GRAPHITI_ROLE_LABEL') ?? _roleLabel;
    _groupPrefix = env.maybe('COMPLEXITY_API_GROUP_PREFIX') ?? env.maybe('GRAPHITI_GROUP_PREFIX') ?? _groupPrefix;
    _apiKey = env.maybe('COMPLEXITY_API_KEY') ?? env.maybe('GRAPHITI_API_KEY');

    _isInitialized = true;
  }

  bool get isConfigured => _baseUrl != null && _baseUrl!.trim().isNotEmpty;

  /// Ingest a [SmartJournalEntry] into the backend for the supplied [userId].
  Future<bool> ingestJournalEntry({
    required SmartJournalEntry entry,
    required int userId,
  }) async {
    await initialize();

    if (!isConfigured) {
      LoggingService.debug(
        'Ingestion skipped – service not configured.',
        tag: 'IngestionService',
      );
      return false;
    }

    final payload = buildPayload(entry: entry, userId: userId);
    if (payload == null) {
      LoggingService.warning(
        'Ingestion skipped – behaviour/context tags missing.',
        tag: 'IngestionService',
      );
      return false;
    }

    try {
      final uri = Uri.parse('${_baseUrl!}$_ingestPath');
      final response = await _client.post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode(payload),
      );

      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      if (!isSuccess) {
        LoggingService.warning(
          'Graphiti ingestion failed with ${response.statusCode}',
          tag: 'IngestionService',
          error: response.body,
        );
      } else if (kDebugMode) {
        LoggingService.debug(
          'Journal entry ${entry.id} ingested into Graphiti.',
          tag: 'IngestionService',
        );
      }
      return isSuccess;
    } catch (error, stackTrace) {
      LoggingService.error(
        'Ingestion threw an exception.',
        tag: 'IngestionService',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_apiKey!}';
    }
    return headers;
  }

  /// Convert a journal entry into the backend ingest payload (compatible with legacy Graphiti format).
  @visibleForTesting
  Map<String, dynamic>? buildPayload({
    required SmartJournalEntry entry,
    required int userId,
  }) {
    final behaviours = entry.choiceTags;
    final contexts = entry.chanceTags;

    if (behaviours.isEmpty || contexts.isEmpty) {
      return null;
    }

    final outcomes = entry.outcomeTags;
    final timestamp = entry.timestamp.toUtc().toIso8601String();

    final canonicalPayload = {
      'original_text': entry.originalText,
      'behaviours': behaviours.map(_serialiseTag).toList(),
      'contexts': contexts.map(_serialiseTag).toList(),
      'outcomes': outcomes.map(_serialiseTag).toList(),
      'metadata': entry.metadata,
      'follow_up_responses': entry.followUpResponses,
      'nudge_recommendations': entry.recommendedNudgeIds,
      'has_nudges': entry.hasNudgeRecommendations,
      'daily_follow_up_count': entry.dailyFollowUpCount,
      'average_confidence': entry.averageConfidence,
    };

    final groupId = '${_groupPrefix}_$userId';

    return {
      'group_id': groupId,
      'messages': [
        {
          'content': jsonEncode(canonicalPayload),
          'uuid': entry.id,
          'name': _buildEpisodeName(entry, behaviours.first),
          'role_type': 'user',
          'role': _roleLabel,
          'timestamp': timestamp,
          'source_description': _sourceDescription,
        },
      ],
    };
  }

  String _buildEpisodeName(SmartJournalEntry entry, SmartTag primaryBehaviour) {
    final dateLabel = entry.timestamp.toLocal().toIso8601String();
    return '${primaryBehaviour.displayName} | $dateLabel';
  }

  Map<String, dynamic> _serialiseTag(SmartTag tag) {
    return {
      'canonical_key': tag.canonicalKey,
      'display_name': tag.displayName,
      'category': tag.category.name,
      'subdomain': tag.subdomain,
      'confidence': tag.confidence,
      'sentiment': tag.sentiment,
      'sentiment_confidence': tag.sentimentConfidence,
      'keywords': tag.keywords,
      'has_negation': tag.hasNegation,
      'has_uncertainty': tag.hasUncertainty,
      'evidence_span': tag.evidenceSpan,
      'metadata': tag.metadata,
    };
  }
}
