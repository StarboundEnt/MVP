import 'package:flutter_test/flutter_test.dart';
import 'package:starbound/models/nudge_model.dart';

void main() {
  group('StarboundNudge', () {
    test('should create nudge with correct properties', () {
      final nudge = StarboundNudge(
        id: 'test-nudge-id',
        message: 'Test nudge message',
        type: NudgeType.encouragement,
        targetHabitId: 'habit-id',
        priority: 1,
        createdAt: DateTime.now(),
      );

      expect(nudge.id, 'test-nudge-id');
      expect(nudge.message, 'Test nudge message');
      expect(nudge.type, NudgeType.encouragement);
      expect(nudge.targetHabitId, 'habit-id');
      expect(nudge.priority, 1);
      expect(nudge.isActive, true);
      expect(nudge.views, 0);
    });

    test('should convert to JSON correctly', () {
      final nudge = StarboundNudge(
        id: 'test-nudge-id',
        message: 'Test nudge message',
        type: NudgeType.reminder,
        targetHabitId: 'habit-id',
        priority: 2,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        isActive: false,
        views: 5,
      );

      final json = nudge.toJson();

      expect(json['id'], 'test-nudge-id');
      expect(json['message'], 'Test nudge message');
      expect(json['type'], 'reminder');
      expect(json['targetHabitId'], 'habit-id');
      expect(json['priority'], 2);
      expect(json['isActive'], false);
      expect(json['views'], 5);
      expect(json['createdAt'], '2024-01-01T00:00:00.000Z');
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test-nudge-id',
        'message': 'Test nudge message',
        'type': 'suggestion',
        'targetHabitId': 'habit-id',
        'priority': 3,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'isActive': true,
        'views': 10,
        'dismissed': false,
        'banked': false,
        'effectiveness': 0.8,
        'personalizedContext': {'mood': 'positive'},
        'scheduledFor': null,
        'expiresAt': null,
      };

      final nudge = StarboundNudge.fromJson(json);

      expect(nudge.id, 'test-nudge-id');
      expect(nudge.message, 'Test nudge message');
      expect(nudge.type, NudgeType.suggestion);
      expect(nudge.targetHabitId, 'habit-id');
      expect(nudge.priority, 3);
      expect(nudge.isActive, true);
      expect(nudge.views, 10);
      expect(nudge.effectiveness, 0.8);
    });

    test('should calculate age correctly', () {
      final pastTime = DateTime.now().subtract(const Duration(hours: 2));
      final nudge = StarboundNudge(
        id: 'test-id',
        message: 'Test message',
        type: NudgeType.encouragement,
        targetHabitId: 'habit-id',
        priority: 1,
        createdAt: pastTime,
      );

      final age = nudge.getAgeInHours();
      expect(age, closeTo(2.0, 0.1));
    });

    test('should track views correctly', () {
      var nudge = StarboundNudge(
        id: 'test-id',
        message: 'Test message',
        type: NudgeType.encouragement,
        targetHabitId: 'habit-id',
        priority: 1,
        createdAt: DateTime.now(),
      );

      expect(nudge.views, 0);

      nudge = nudge.copyWith(views: nudge.views + 1);
      expect(nudge.views, 1);

      nudge = nudge.copyWith(views: nudge.views + 1);
      expect(nudge.views, 2);
    });

    test('should handle dismissal correctly', () {
      var nudge = StarboundNudge(
        id: 'test-id',
        message: 'Test message',
        type: NudgeType.encouragement,
        targetHabitId: 'habit-id',
        priority: 1,
        createdAt: DateTime.now(),
      );

      expect(nudge.dismissed, false);

      nudge = nudge.copyWith(dismissed: true);
      expect(nudge.dismissed, true);
    });

    test('should handle banking correctly', () {
      var nudge = StarboundNudge(
        id: 'test-id',
        message: 'Test message',
        type: NudgeType.encouragement,
        targetHabitId: 'habit-id',
        priority: 1,
        createdAt: DateTime.now(),
      );

      expect(nudge.banked, false);

      nudge = nudge.copyWith(banked: true);
      expect(nudge.banked, true);
    });

    test('should prioritize nudges correctly', () {
      final highPriorityNudge = StarboundNudge(
        id: 'high-priority',
        message: 'High priority message',
        type: NudgeType.urgentReminder,
        targetHabitId: 'habit-id',
        priority: 5,
        createdAt: DateTime.now(),
      );

      final lowPriorityNudge = StarboundNudge(
        id: 'low-priority',
        message: 'Low priority message',
        type: NudgeType.encouragement,
        targetHabitId: 'habit-id',
        priority: 1,
        createdAt: DateTime.now(),
      );

      expect(highPriorityNudge.priority > lowPriorityNudge.priority, true);
    });
  });

  group('NudgeType', () {
    test('should have correct string values', () {
      expect(NudgeType.encouragement.toString(), 'NudgeType.encouragement');
      expect(NudgeType.reminder.toString(), 'NudgeType.reminder');
      expect(NudgeType.suggestion.toString(), 'NudgeType.suggestion');
      expect(NudgeType.urgentReminder.toString(), 'NudgeType.urgentReminder');
      expect(NudgeType.celebration.toString(), 'NudgeType.celebration');
    });

    test('should parse from string correctly', () {
      expect(NudgeTypeExtension.fromString('encouragement'), NudgeType.encouragement);
      expect(NudgeTypeExtension.fromString('reminder'), NudgeType.reminder);
      expect(NudgeTypeExtension.fromString('suggestion'), NudgeType.suggestion);
      expect(NudgeTypeExtension.fromString('urgentReminder'), NudgeType.urgentReminder);
      expect(NudgeTypeExtension.fromString('celebration'), NudgeType.celebration);
    });

    test('should handle invalid string gracefully', () {
      expect(NudgeTypeExtension.fromString('invalid'), NudgeType.encouragement);
      expect(NudgeTypeExtension.fromString(''), NudgeType.encouragement);
    });
  });
}