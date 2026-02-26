import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum for reminder time windows
enum ReminderWindow {
  morning('morning', 'Morning', '9:00 AM', 9, 0),
  lunch('lunch', 'Lunch', '12:30 PM', 12, 30),
  evening('evening', 'Evening', '7:00 PM', 19, 0);

  const ReminderWindow(this.key, this.displayName, this.defaultTime, this.defaultHour, this.defaultMinute);

  final String key;
  final String displayName;
  final String defaultTime;
  final int defaultHour;
  final int defaultMinute;

  static ReminderWindow fromKey(String key) {
    return ReminderWindow.values.firstWhere(
      (window) => window.key == key,
      orElse: () => ReminderWindow.evening,
    );
  }
}

/// Represents a user's reminder preferences
class ReminderPreferences {
  final bool isEnabled;
  final Set<ReminderWindow> enabledWindows;
  final Map<ReminderWindow, TimeOfDay> customTimes;
  final bool skipWeekendsEnabled;
  final bool onlyAfterInactivityEnabled;
  final int inactivityDays;

  const ReminderPreferences({
    this.isEnabled = false,
    this.enabledWindows = const {},
    this.customTimes = const {},
    this.skipWeekendsEnabled = false,
    this.onlyAfterInactivityEnabled = true,
    this.inactivityDays = 2,
  });

  ReminderPreferences copyWith({
    bool? isEnabled,
    Set<ReminderWindow>? enabledWindows,
    Map<ReminderWindow, TimeOfDay>? customTimes,
    bool? skipWeekendsEnabled,
    bool? onlyAfterInactivityEnabled,
    int? inactivityDays,
  }) {
    return ReminderPreferences(
      isEnabled: isEnabled ?? this.isEnabled,
      enabledWindows: enabledWindows ?? this.enabledWindows,
      customTimes: customTimes ?? this.customTimes,
      skipWeekendsEnabled: skipWeekendsEnabled ?? this.skipWeekendsEnabled,
      onlyAfterInactivityEnabled: onlyAfterInactivityEnabled ?? this.onlyAfterInactivityEnabled,
      inactivityDays: inactivityDays ?? this.inactivityDays,
    );
  }

  Map<String, dynamic> toJson() => {
    'is_enabled': isEnabled,
    'enabled_windows': enabledWindows.map((w) => w.key).toList(),
    'custom_times': customTimes.map(
      (window, time) => MapEntry(window.key, {'hour': time.hour, 'minute': time.minute}),
    ),
    'skip_weekends_enabled': skipWeekendsEnabled,
    'only_after_inactivity_enabled': onlyAfterInactivityEnabled,
    'inactivity_days': inactivityDays,
  };

  factory ReminderPreferences.fromJson(Map<String, dynamic> json) {
    final enabledWindowKeys = List<String>.from(json['enabled_windows'] ?? []);
    final enabledWindows = enabledWindowKeys.map(ReminderWindow.fromKey).toSet();
    
    final customTimesJson = Map<String, dynamic>.from(json['custom_times'] ?? {});
    final customTimes = <ReminderWindow, TimeOfDay>{};
    
    for (final entry in customTimesJson.entries) {
      final window = ReminderWindow.fromKey(entry.key);
      final timeData = Map<String, dynamic>.from(entry.value);
      customTimes[window] = TimeOfDay(
        hour: timeData['hour'] ?? window.defaultHour,
        minute: timeData['minute'] ?? window.defaultMinute,
      );
    }

    return ReminderPreferences(
      isEnabled: json['is_enabled'] ?? false,
      enabledWindows: enabledWindows,
      customTimes: customTimes,
      skipWeekendsEnabled: json['skip_weekends_enabled'] ?? false,
      onlyAfterInactivityEnabled: json['only_after_inactivity_enabled'] ?? true,
      inactivityDays: json['inactivity_days'] ?? 2,
    );
  }
}

/// Simple time representation for cross-platform compatibility
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  String format24Hour() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String format12Hour() {
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${hour12}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is TimeOfDay && runtimeType == other.runtimeType &&
    hour == other.hour && minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

/// Service for managing gentle journaling reminders
class JournalingReminderService {
  static const String _prefsKey = 'journaling_reminder_preferences';
  static const String _lastJournalDateKey = 'last_journal_date';
  
  SharedPreferences? _prefs;
  
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Collection of gentle health check-in messages
  static const List<String> _gentleReminders = [
    "Time for a quick health check-in?",
    "How's your health today? Track any changes.",
    "A moment to log how you're feeling?",
    "Track your symptoms or medications today.",
    "Your health journal is ready when you are.",
    "Quick check-in: any symptoms to note?",
    "How's your body feeling today?",
    "A moment to track your health progress?",
    "Gentle reminder: logging helps spot patterns.",
    "Time to check in on your health.",
    "How are you feeling physically today?",
    "Your health log is here when you're ready.",
    "Quick health check—no pressure though!",
    "Track how you're doing today.",
    "A moment to note any health changes?",
  ];

  /// Morning-specific health messages
  static const List<String> _morningReminders = [
    "Good morning! How did you sleep?",
    "Morning check-in: how's your body feeling?",
    "A gentle start—any symptoms to note?",
    "New day—how's your energy level?",
    "Morning health check: how are you today?",
    "Start your day with a quick health log?",
    "Good morning! Any medications to take?",
    "How's your health this morning?",
    "A soft morning health check-in?",
    "Rise and track—if you have a moment.",
  ];

  /// Lunch-time health messages
  static const List<String> _lunchReminders = [
    "Midday check-in: how's your health?",
    "Lunchtime—any symptoms to note?",
    "A quick midday health log?",
    "Half the day done—how's your energy?",
    "Quick check-in: how's your body feeling?",
    "Lunch break—time for medications?",
    "Midday health update?",
    "A brief pause to track how you're doing.",
    "Any changes to note since this morning?",
    "How's your health holding up today?",
  ];

  /// Evening-specific health messages
  static const List<String> _eveningReminders = [
    "Evening health check before bed?",
    "How did your body feel today?",
    "Day's end—any symptoms to log?",
    "Quick review: how was your health today?",
    "Evening health log, if you have a moment.",
    "Your health today—worth noting anything?",
    "Gentle evening health check-in?",
    "Did you take all your medications today?",
    "End your day with a quick health note?",
    "Evening check: how are your symptoms?",
  ];

  /// Get reminder preferences
  Future<ReminderPreferences> getReminderPreferences() async {
    try {
      final p = await prefs;
      final jsonString = p.getString(_prefsKey);
      
      if (jsonString == null) {
        return const ReminderPreferences();
      }
      
      final jsonData = Map<String, dynamic>.from(json.decode(jsonString));
      return ReminderPreferences.fromJson(jsonData);
    } catch (e) {
      debugPrint('Failed to load reminder preferences: $e');
      return const ReminderPreferences();
    }
  }

  /// Save reminder preferences
  Future<void> saveReminderPreferences(ReminderPreferences preferences) async {
    try {
      final p = await prefs;
      final jsonString = json.encode(preferences.toJson());
      await p.setString(_prefsKey, jsonString);
    } catch (e) {
      debugPrint('Failed to save reminder preferences: $e');
    }
  }

  /// Get a gentle reminder message for a specific window
  String getGentleReminder(ReminderWindow window) {
    final random = Random();
    
    switch (window) {
      case ReminderWindow.morning:
        return _morningReminders[random.nextInt(_morningReminders.length)];
      case ReminderWindow.lunch:
        return _lunchReminders[random.nextInt(_lunchReminders.length)];
      case ReminderWindow.evening:
        return _eveningReminders[random.nextInt(_eveningReminders.length)];
    }
  }

  /// Get a random gentle reminder
  String getRandomGentleReminder() {
    final random = Random();
    return _gentleReminders[random.nextInt(_gentleReminders.length)];
  }

  /// Check if user should receive a reminder based on activity
  Future<bool> shouldShowReminder(ReminderWindow window) async {
    try {
      final preferences = await getReminderPreferences();
      
      if (!preferences.isEnabled || !preferences.enabledWindows.contains(window)) {
        return false;
      }

      // Check if it's weekend and user wants to skip weekends
      final now = DateTime.now();
      if (preferences.skipWeekendsEnabled && (now.weekday == 6 || now.weekday == 7)) {
        return false;
      }

      // Check inactivity-based reminders
      if (preferences.onlyAfterInactivityEnabled) {
        final daysSinceLastJournal = await getDaysSinceLastJournal();
        if (daysSinceLastJournal < preferences.inactivityDays) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error checking reminder eligibility: $e');
      return false;
    }
  }

  /// Get days since last journal entry
  Future<int> getDaysSinceLastJournal() async {
    try {
      final p = await prefs;
      final lastJournalDateString = p.getString(_lastJournalDateKey);
      
      if (lastJournalDateString == null) {
        return 999; // No journal entries yet
      }
      
      final lastJournalDate = DateTime.tryParse(lastJournalDateString);
      if (lastJournalDate == null) {
        return 999;
      }
      
      final now = DateTime.now();
      final difference = now.difference(lastJournalDate);
      return difference.inDays;
    } catch (e) {
      debugPrint('Error getting days since last journal: $e');
      return 0;
    }
  }

  /// Record that user journaled today
  Future<void> recordJournalActivity() async {
    try {
      final p = await prefs;
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      await p.setString(_lastJournalDateKey, today);
    } catch (e) {
      debugPrint('Error recording journal activity: $e');
    }
  }

  /// Enable reminders with default settings
  Future<void> enableRemindersWithDefaults() async {
    final defaultPreferences = const ReminderPreferences(
      isEnabled: true,
      enabledWindows: {ReminderWindow.evening},
      onlyAfterInactivityEnabled: true,
      inactivityDays: 2,
      skipWeekendsEnabled: false,
    );
    
    await saveReminderPreferences(defaultPreferences);
  }

  /// Disable all reminders
  Future<void> disableReminders() async {
    final currentPreferences = await getReminderPreferences();
    final disabledPreferences = currentPreferences.copyWith(isEnabled: false);
    await saveReminderPreferences(disabledPreferences);
  }

  /// Get next scheduled reminder time for a window
  DateTime? getNextReminderTime(ReminderWindow window, ReminderPreferences preferences) {
    if (!preferences.enabledWindows.contains(window)) {
      return null;
    }

    final now = DateTime.now();
    final customTime = preferences.customTimes[window];
    final reminderTime = customTime ?? TimeOfDay(
      hour: window.defaultHour,
      minute: window.defaultMinute,
    );

    // Calculate next occurrence
    var nextReminder = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (nextReminder.isBefore(now)) {
      nextReminder = nextReminder.add(const Duration(days: 1));
    }

    // Skip weekends if enabled
    if (preferences.skipWeekendsEnabled) {
      while (nextReminder.weekday == 6 || nextReminder.weekday == 7) {
        nextReminder = nextReminder.add(const Duration(days: 1));
      }
    }

    return nextReminder;
  }

  /// Get all upcoming reminders
  Future<List<Map<String, dynamic>>> getUpcomingReminders() async {
    final preferences = await getReminderPreferences();
    final reminders = <Map<String, dynamic>>[];

    for (final window in preferences.enabledWindows) {
      final nextTime = getNextReminderTime(window, preferences);
      if (nextTime != null) {
        reminders.add({
          'window': window,
          'time': nextTime,
          'message': getGentleReminder(window),
        });
      }
    }

    // Sort by time
    reminders.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));
    return reminders;
  }

  /// Get encouragement message for enabling reminders
  String getEncouragementMessage() {
    final messages = [
      "Regular tracking helps you spot health patterns",
      "A gentle nudge to log your symptoms",
      "Tracking your health helps prepare for GP visits",
      "Building healthy habits, one day at a time",
      "Support for your health journey",
      "Your health log can be your daily companion",
      "Soft reminders to track what matters",
      "Building the habit of health tracking, gently",
    ];

    final random = Random();
    return messages[random.nextInt(messages.length)];
  }

  /// Get reminder frequency suggestions
  Map<String, String> getFrequencySuggestions() {
    return {
      'daily': 'A daily health check-in',
      'weekdays': 'Reminders on busy weekdays',
      'custom': 'Choose what works for you',
      'inactivity': 'Only when you haven\'t logged for a while',
    };
  }

  /// Check if it's currently in a reminder window (within 30 minutes)
  bool isInReminderWindow(ReminderWindow window, ReminderPreferences preferences) {
    final now = DateTime.now();
    final customTime = preferences.customTimes[window];
    final reminderTime = customTime ?? TimeOfDay(
      hour: window.defaultHour,
      minute: window.defaultMinute,
    );

    final reminderDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    final difference = now.difference(reminderDateTime).abs();
    return difference.inMinutes <= 30; // Within 30 minutes of reminder time
  }
}