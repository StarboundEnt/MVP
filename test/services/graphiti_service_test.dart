import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:starbound/services/graphiti_service.dart';
import 'package:starbound/models/smart_tag_model.dart';

void main() {
  group('GraphitiService.buildPayload', () {
    final service = GraphitiService();

    SmartTag _tag({
      required String id,
      required String canonicalKey,
      required TagCategory category,
    }) {
      return SmartTag(
        id: id,
        canonicalKey: canonicalKey,
        displayName: canonicalKey,
        category: category,
        subdomain: 'test',
        confidence: 0.9,
        createdAt: DateTime.utc(2024, 1, 1),
      );
    }

    test('returns payload when behaviour and context present', () {
      final entry = SmartJournalEntry(
        id: 'entry-1',
        originalText: 'Went for an evening walk with friends.',
        timestamp: DateTime.utc(2024, 1, 2, 18, 0),
        smartTags: [
          _tag(
              id: 'beh',
              canonicalKey: 'daily_movement',
              category: TagCategory.choice),
          _tag(
              id: 'ctx',
              canonicalKey: 'community_support',
              category: TagCategory.chance),
          _tag(
              id: 'out',
              canonicalKey: 'calm_mood',
              category: TagCategory.outcome),
        ],
        averageConfidence: 0.82,
        metadata: {'note': 'test'},
        followUpResponses: {'context_details': 'neighbourhood walk'},
        recommendedNudgeIds: const ['nudge-1'],
        hasNudgeRecommendations: true,
      );

      final payload = service.buildPayload(entry: entry, userId: 42);

      expect(payload, isNotNull);
      expect(payload!['group_id'], equals('user_42'));
      expect(payload['messages'], hasLength(1));

      final message = payload['messages'][0] as Map<String, dynamic>;
      final content =
          jsonDecode(message['content'] as String) as Map<String, dynamic>;

      expect(content['original_text'], contains('evening walk'));
      expect(content['behaviours'], hasLength(1));
      expect(content['contexts'], hasLength(1));
      expect(content['outcomes'], hasLength(1));
      expect(content['metadata']['note'], equals('test'));
      expect(content['follow_up_responses']['context_details'],
          equals('neighbourhood walk'));
    });

    test('returns null when behaviour missing', () {
      final entry = SmartJournalEntry(
        id: 'entry-2',
        originalText: 'Felt tired today.',
        timestamp: DateTime.utc(2024, 1, 3, 8, 30),
        smartTags: [
          _tag(
              id: 'ctx',
              canonicalKey: 'poor_sleep',
              category: TagCategory.chance),
        ],
        averageConfidence: 0.5,
      );

      final payload = service.buildPayload(entry: entry, userId: 12);
      expect(payload, isNull);
    });
  });
}
