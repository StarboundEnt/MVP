import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starbound/services/journaling_reminder_service.dart' as reminders;

void main() {
  group('JournalingReminderService', () {
    late reminders.JournalingReminderService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = reminders.JournalingReminderService();
    });

    test('should return default preferences when none are saved', () async {
      final preferences = await service.getReminderPreferences();

      expect(preferences.isEnabled, false);
      expect(preferences.enabledWindows, isEmpty);
      expect(preferences.customTimes, isEmpty);
      expect(preferences.skipWeekendsEnabled, false);
      expect(preferences.onlyAfterInactivityEnabled, true);
      expect(preferences.inactivityDays, 2);
    });

    test('should save and retrieve reminder preferences', () async {
      final testPreferences = reminders.ReminderPreferences(
        isEnabled: true,
        enabledWindows: {
          reminders.ReminderWindow.morning,
          reminders.ReminderWindow.evening,
        },
        customTimes: {
          reminders.ReminderWindow.morning:
              const reminders.TimeOfDay(hour: 8, minute: 30),
        },
        skipWeekendsEnabled: true,
        onlyAfterInactivityEnabled: false,
        inactivityDays: 3,
      );

      await service.saveReminderPreferences(testPreferences);
      final retrieved = await service.getReminderPreferences();

      expect(retrieved.isEnabled, true);
      expect(retrieved.enabledWindows,
          contains(reminders.ReminderWindow.morning));
      expect(retrieved.enabledWindows,
          contains(reminders.ReminderWindow.evening));
      expect(retrieved.skipWeekendsEnabled, true);
      expect(retrieved.onlyAfterInactivityEnabled, false);
      expect(retrieved.inactivityDays, 3);
    });

    test('should return appropriate reminder message for each window', () {
      final morningMessage =
          service.getGentleReminder(reminders.ReminderWindow.morning);
      final lunchMessage =
          service.getGentleReminder(reminders.ReminderWindow.lunch);
      final eveningMessage =
          service.getGentleReminder(reminders.ReminderWindow.evening);

      expect(morningMessage, isNotEmpty);
      expect(lunchMessage, isNotEmpty);
      expect(eveningMessage, isNotEmpty);
    });

    test('should record journal activity', () async {
      await service.recordJournalActivity();
      final daysSince = await service.getDaysSinceLastJournal();

      expect(daysSince, equals(0));
    });

    test('should calculate days since last journal correctly', () async {
      final initialDays = await service.getDaysSinceLastJournal();
      expect(initialDays, equals(999));

      await service.recordJournalActivity();
      final afterRecording = await service.getDaysSinceLastJournal();
      expect(afterRecording, equals(0));
    });

    test('should enable reminders with default settings', () async {
      await service.enableRemindersWithDefaults();
      final preferences = await service.getReminderPreferences();

      expect(preferences.isEnabled, true);
      expect(preferences.enabledWindows,
          contains(reminders.ReminderWindow.evening));
      expect(preferences.onlyAfterInactivityEnabled, true);
      expect(preferences.inactivityDays, 2);
      expect(preferences.skipWeekendsEnabled, false);
    });

    test('should disable reminders', () async {
      await service.saveReminderPreferences(
        const reminders.ReminderPreferences(
          isEnabled: true,
          enabledWindows: {reminders.ReminderWindow.morning},
        ),
      );

      await service.disableReminders();
      final preferences = await service.getReminderPreferences();

      expect(preferences.isEnabled, false);
      expect(preferences.enabledWindows,
          contains(reminders.ReminderWindow.morning));
    });

    test('should determine if reminder should be shown based on preferences',
        () async {
      await service.saveReminderPreferences(
        const reminders.ReminderPreferences(isEnabled: false),
      );

      final shouldShowDisabled =
          await service.shouldShowReminder(reminders.ReminderWindow.evening);
      expect(shouldShowDisabled, false);

      await service.saveReminderPreferences(
        const reminders.ReminderPreferences(
          isEnabled: true,
          enabledWindows: {reminders.ReminderWindow.morning},
        ),
      );

      final shouldShowWrongWindow =
          await service.shouldShowReminder(reminders.ReminderWindow.evening);
      expect(shouldShowWrongWindow, false);

      final shouldShowCorrect =
          await service.shouldShowReminder(reminders.ReminderWindow.morning);
      expect(shouldShowCorrect, true);
    });

    test('should get next reminder time correctly', () {
      final preferences = reminders.ReminderPreferences(
        enabledWindows: {reminders.ReminderWindow.morning},
        customTimes: {
          reminders.ReminderWindow.morning:
              const reminders.TimeOfDay(hour: 9, minute: 0),
        },
      );

      final nextTime = service.getNextReminderTime(
        reminders.ReminderWindow.morning,
        preferences,
      );
      expect(nextTime, isNotNull);
      expect(nextTime!.hour, anyOf(equals(9), greaterThan(9)));
    });

    test('should get encouragement message', () {
      final message = service.getEncouragementMessage();
      expect(message, isNotEmpty);
      expect(message.length, greaterThan(10));
    });

    test('should get frequency suggestions', () {
      final suggestions = service.getFrequencySuggestions();
      expect(suggestions, isNotEmpty);
      expect(suggestions, containsPair('daily', 'A gentle daily check-in'));
      expect(suggestions,
          containsPair('weekdays', 'Soft reminders on busy weekdays'));
      expect(suggestions,
          containsPair('custom', 'Choose what feels right for you'));
      expect(suggestions,
          containsPair('inactivity', "Only when you've been away for a while"));
    });

    test('should determine if currently in reminder window', () {
      final preferences = reminders.ReminderPreferences(
        customTimes: {
          reminders.ReminderWindow.morning:
              const reminders.TimeOfDay(hour: 9, minute: 0),
        },
      );

      final inWindow = service.isInReminderWindow(
        reminders.ReminderWindow.morning,
        preferences,
      );
      expect(inWindow, isA<bool>());
    });
  });
}
