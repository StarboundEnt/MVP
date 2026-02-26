import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/nudge_model.dart';
import '../utils/tag_utils.dart';
import '../models/complexity_profile.dart';
import 'storage_service.dart';

enum NotificationType {
  habitReminder,
  streakProtection,
  contextualNudge,
  motivationalBoost,
  checkIn,
}

class ScheduledNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final Map<String, dynamic> payload;
  final String? habitKey;

  ScheduledNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.payload = const {},
    this.habitKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.toIso8601String(),
        'payload': payload,
        'habitKey': habitKey,
      };

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) =>
      ScheduledNotification(
        id: json['id'],
        type: NotificationType.values[json['type']],
        title: json['title'],
        body: json['body'],
        scheduledTime: DateTime.parse(json['scheduledTime']),
        payload: Map<String, dynamic>.from(json['payload'] ?? {}),
        habitKey: json['habitKey'],
      );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final StorageService _storageService = StorageService();

  bool _isInitialized = false;
  List<ScheduledNotification> _scheduledNotifications = [];
  Timer? _scheduleTimer;

  // User preferences
  bool _notificationsEnabled = true;
  String _preferredTime = '19:00';
  List<int> _enabledDays = [1, 2, 3, 4, 5, 6, 7]; // Monday to Sunday
  int _frequencyHours = 24; // Default daily

  static const String _notificationPrefsKey = 'notification_preferences';
  static const String _scheduledNotificationsKey = 'scheduled_notifications';

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Initialize notifications plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
    } on MissingPluginException catch (e) {
      debugPrint(
        'NotificationService: flutter_local_notifications plugin unavailable '
        '(likely in tests). Skipping initialization. Details: $e',
      );
      _isInitialized = true;
      return;
    }

    // Load preferences and scheduled notifications
    await _loadPreferences();
    await _loadScheduledNotifications();

    // Request permissions
    await _requestPermissions();

    // Start the scheduling system
    _startNotificationScheduler();

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      // For iOS, also request specific permissions
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
      return true;
    }

    debugPrint('Notification permissions denied');
    return false;
  }

  // Load user preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_notificationPrefsKey);

      if (prefsJson != null) {
        final prefsData = jsonDecode(prefsJson);
        _notificationsEnabled = prefsData['enabled'] ?? true;
        _preferredTime = prefsData['preferredTime'] ?? '19:00';
        _enabledDays =
            List<int>.from(prefsData['enabledDays'] ?? [1, 2, 3, 4, 5, 6, 7]);
        _frequencyHours = prefsData['frequencyHours'] ?? 24;
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    }
  }

  // Save user preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsData = {
        'enabled': _notificationsEnabled,
        'preferredTime': _preferredTime,
        'enabledDays': _enabledDays,
        'frequencyHours': _frequencyHours,
      };
      await prefs.setString(_notificationPrefsKey, jsonEncode(prefsData));
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }

  // Load scheduled notifications
  Future<void> _loadScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_scheduledNotificationsKey);

      if (notificationsJson != null) {
        final notificationsData = jsonDecode(notificationsJson) as List;
        _scheduledNotifications = notificationsData
            .map((data) => ScheduledNotification.fromJson(data))
            .where((notification) =>
                notification.scheduledTime.isAfter(DateTime.now()))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading scheduled notifications: $e');
    }
  }

  // Save scheduled notifications
  Future<void> _saveScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsData =
          _scheduledNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(
          _scheduledNotificationsKey, jsonEncode(notificationsData));
    } catch (e) {
      debugPrint('Error saving scheduled notifications: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = jsonDecode(response.payload ?? '{}');
      final type = NotificationType.values[payload['type'] ?? 0];

      switch (type) {
        case NotificationType.habitReminder:
          // Navigate to habit tracker
          debugPrint('Opening habit tracker for: ${payload['habitKey']}');
          break;
        case NotificationType.streakProtection:
          // Navigate to specific habit
          debugPrint('Opening streak protection for: ${payload['habitKey']}');
          break;
        case NotificationType.contextualNudge:
          // Navigate to relevant page
          debugPrint('Opening contextual nudge: ${payload['nudgeId']}');
          break;
        default:
          debugPrint('Opening main app');
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  // Start the notification scheduler
  void _startNotificationScheduler() {
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _scheduleUpcomingNotifications();
    });

    // Schedule initial batch
    _scheduleUpcomingNotifications();
  }

  // Schedule contextual habit reminders based on nudge system
  Future<void> scheduleContextualReminder({
    required StarboundNudge nudge,
    required ComplexityLevel complexityProfile,
    required Map<String, String?> currentHabits,
    DateTime? customTime,
  }) async {
    if (!_notificationsEnabled) return;

    final scheduledTime =
        customTime ?? _getOptimalReminderTime(complexityProfile);

    final notification = ScheduledNotification(
      id: 'contextual_${nudge.id}_${scheduledTime.millisecondsSinceEpoch}',
      type: NotificationType.contextualNudge,
      title: _getContextualTitle(nudge, complexityProfile),
      body: _getContextualBody(nudge, complexityProfile),
      scheduledTime: scheduledTime,
      payload: {
        'nudgeId': nudge.id,
        'type': NotificationType.contextualNudge.index,
        'complexityProfile': complexityProfile.name,
      },
    );

    await _scheduleNotification(notification);
  }

  // Schedule streak protection alerts with intelligent timing
  Future<void> scheduleStreakProtection({
    required String habitKey,
    required int currentStreak,
    required ComplexityLevel complexityProfile,
    DateTime? lastCompletedTime,
  }) async {
    if (!_notificationsEnabled || currentStreak < 3) return;

    // Cancel any existing streak protection for this habit
    await _cancelStreakProtection(habitKey);

    // Schedule multiple alerts with increasing urgency
    final alertTimes =
        _getStreakProtectionTimes(complexityProfile, lastCompletedTime);

    for (int i = 0; i < alertTimes.length; i++) {
      final alertTime = alertTimes[i];
      final urgency = i + 1; // 1 = gentle, 2 = moderate, 3 = urgent

      final notification = ScheduledNotification(
        id: 'streak_${habitKey}_${urgency}_${alertTime.millisecondsSinceEpoch}',
        type: NotificationType.streakProtection,
        title: _getStreakProtectionTitle(
            currentStreak, complexityProfile, urgency),
        body: _getStreakProtectionBody(
            habitKey, currentStreak, complexityProfile, urgency),
        scheduledTime: alertTime,
        habitKey: habitKey,
        payload: {
          'habitKey': habitKey,
          'streak': currentStreak,
          'urgency': urgency,
          'type': NotificationType.streakProtection.index,
        },
      );

      await _scheduleNotification(notification);
    }
  }

  // Cancel streak protection for a specific habit
  Future<void> _cancelStreakProtection(String habitKey) async {
    final toRemove = _scheduledNotifications
        .where((n) =>
            n.type == NotificationType.streakProtection &&
            n.habitKey == habitKey)
        .toList();

    for (final notification in toRemove) {
      await _notifications.cancel(notification.id.hashCode);
      _scheduledNotifications.remove(notification);
    }

    await _saveScheduledNotifications();
  }

  // Schedule daily check-in based on complexity profile
  Future<void> scheduleAdaptiveCheckIn(
      ComplexityLevel complexityProfile) async {
    if (!_notificationsEnabled) return;

    final checkInTime = _getAdaptiveCheckInTime(complexityProfile);

    final notification = ScheduledNotification(
      id: 'checkin_${checkInTime.millisecondsSinceEpoch}',
      type: NotificationType.checkIn,
      title: _getCheckInTitle(complexityProfile),
      body: _getCheckInBody(complexityProfile),
      scheduledTime: checkInTime,
      payload: {
        'type': NotificationType.checkIn.index,
        'complexityProfile': complexityProfile.name,
      },
    );

    await _scheduleNotification(notification);
  }

  // Get optimal reminder time based on complexity profile
  DateTime _getOptimalReminderTime(ComplexityLevel complexityProfile) {
    final now = DateTime.now();
    final baseTime = _parseTime(_preferredTime);

    switch (complexityProfile) {
      case ComplexityLevel.stable:
        // Stable users get consistent timing
        return DateTime(
                now.year, now.month, now.day, baseTime.hour, baseTime.minute)
            .add(const Duration(days: 1));

      case ComplexityLevel.trying:
        // Trying users get slight variation to find what works
        final variance = Random().nextInt(60) - 30; // ±30 minutes
        return DateTime(
                now.year, now.month, now.day, baseTime.hour, baseTime.minute)
            .add(Duration(days: 1, minutes: variance));

      case ComplexityLevel.overloaded:
        // Overloaded users get gentler, less frequent reminders
        return DateTime(
                now.year, now.month, now.day, baseTime.hour, baseTime.minute)
            .add(Duration(days: 2)); // Every other day

      case ComplexityLevel.survival:
        // Survival users get minimal, very gentle nudges
        return DateTime(
                now.year, now.month, now.day, baseTime.hour, baseTime.minute)
            .add(Duration(days: 3)); // Every third day
    }
  }

  // Get multiple streak protection alert times with progressive urgency
  List<DateTime> _getStreakProtectionTimes(
      ComplexityLevel complexityProfile, DateTime? lastCompletedTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alertTimes = <DateTime>[];

    switch (complexityProfile) {
      case ComplexityLevel.stable:
        // Stable users: gentle afternoon reminder, evening check-in, night reminder
        alertTimes.addAll([
          today.add(const Duration(hours: 15)), // 3 PM
          today.add(const Duration(hours: 19)), // 7 PM
          today.add(const Duration(hours: 21)), // 9 PM
        ]);
        break;

      case ComplexityLevel.trying:
        // Trying users: mid-day nudge, evening reminder
        alertTimes.addAll([
          today.add(const Duration(hours: 14)), // 2 PM
          today.add(const Duration(hours: 20)), // 8 PM
        ]);
        break;

      case ComplexityLevel.overloaded:
        // Overloaded users: single gentle evening reminder
        alertTimes
            .add(today.add(const Duration(hours: 19, minutes: 30))); // 7:30 PM
        break;

      case ComplexityLevel.survival:
        // Survival users: very gentle late afternoon check-in
        alertTimes.add(today.add(const Duration(hours: 17))); // 5 PM
        break;
    }

    // Filter out times that have already passed
    final cutoffTime =
        now.add(const Duration(minutes: 30)); // Give 30min buffer
    return alertTimes.where((time) => time.isAfter(cutoffTime)).toList();
  }

  // Get adaptive check-in time based on complexity
  DateTime _getAdaptiveCheckInTime(ComplexityLevel complexityProfile) {
    final now = DateTime.now();

    switch (complexityProfile) {
      case ComplexityLevel.stable:
        // Stable users: consistent morning check-in
        return DateTime(now.year, now.month, now.day, 9, 0)
            .add(const Duration(days: 1));

      case ComplexityLevel.trying:
        // Trying users: flexible timing
        return DateTime(now.year, now.month, now.day, 10, 0)
            .add(const Duration(days: 1));

      case ComplexityLevel.overloaded:
        // Overloaded users: gentle evening reflection
        return DateTime(now.year, now.month, now.day, 21, 0)
            .add(const Duration(days: 1));

      case ComplexityLevel.survival:
        // Survival users: very gentle, less frequent
        return DateTime(now.year, now.month, now.day, 12, 0)
            .add(const Duration(days: 2));
    }
  }

  // Helper method to parse time string
  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(2024, 1, 1, hour, minute);
  }

  // Generate contextual titles based on complexity profile
  String _getContextualTitle(
      StarboundNudge nudge, ComplexityLevel complexityProfile) {
    switch (complexityProfile) {
      case ComplexityLevel.stable:
        final label = TagUtils.displayName(nudge.theme);
        return "Time for your $label 🌟";
      case ComplexityLevel.trying:
        final label = TagUtils.displayName(nudge.theme).toLowerCase();
        return "Ready to $label? 💪";
      case ComplexityLevel.overloaded:
        final label = TagUtils.displayName(nudge.theme);
        return "Gentle reminder: $label 🌸";
      case ComplexityLevel.survival:
        final label = TagUtils.displayName(nudge.theme);
        return "When you're ready: $label 🤗";
    }
  }

  // Generate contextual bodies based on complexity profile
  String _getContextualBody(
      StarboundNudge nudge, ComplexityLevel complexityProfile) {
    switch (complexityProfile) {
      case ComplexityLevel.stable:
        return nudge.message;
      case ComplexityLevel.trying:
        return "Small steps count! ${nudge.message}";
      case ComplexityLevel.overloaded:
        return "No pressure, just a gentle nudge: ${nudge.message}";
      case ComplexityLevel.survival:
        return "Only if it feels right: ${nudge.message}";
    }
  }

  // Generate streak protection titles with urgency awareness
  String _getStreakProtectionTitle(
      int streak, ComplexityLevel complexityProfile,
      [int urgency = 1]) {
    switch (complexityProfile) {
      case ComplexityLevel.stable:
        switch (urgency) {
          case 1:
            return "Time for your habit! 🌟";
          case 2:
            return "Protect your $streak-day streak! 🔥";
          case 3:
            return "Don't break the chain! $streak days 💪";
          default:
            return "Keep your streak alive! 🔥";
        }
      case ComplexityLevel.trying:
        switch (urgency) {
          case 1:
            return "Habit check-in 💭";
          case 2:
            return "$streak days strong! 💪";
          default:
            return "You've got this! $streak days 🌟";
        }
      case ComplexityLevel.overloaded:
        return urgency == 1
            ? "Gentle habit reminder 🌸"
            : "Your $streak-day journey 🌱";
      case ComplexityLevel.survival:
        return "$streak days of self-care 🤗";
    }
  }

  // Generate streak protection bodies with urgency awareness
  String _getStreakProtectionBody(
      String habitKey, int streak, ComplexityLevel complexityProfile,
      [int urgency = 1]) {
    final habitName = habitKey.replaceAll('_', ' ').toLowerCase();

    switch (complexityProfile) {
      case ComplexityLevel.stable:
        switch (urgency) {
          case 1:
            return "A gentle reminder to check in with your $habitName habit.";
          case 2:
            return "You've been consistent with $habitName for $streak days. Keep the momentum!";
          case 3:
            return "Your $streak-day $habitName streak is precious. Just a quick check-in?";
          default:
            return "Keep that beautiful $habitName streak going!";
        }
      case ComplexityLevel.trying:
        switch (urgency) {
          case 1:
            return "How's your $habitName going today? Every moment counts.";
          case 2:
            return "Your $habitName streak is at $streak days. Even a small action counts!";
          default:
            return "You're building something beautiful with $habitName. $streak days and counting!";
        }
      case ComplexityLevel.overloaded:
        return urgency == 1
            ? "No pressure - just checking if you'd like to continue your $habitName practice. $streak days so far."
            : "Gentle reminder about your $habitName journey. $streak days of showing up for yourself.";
      case ComplexityLevel.survival:
        return "You've shown up for $habitName $streak times. That's something worth celebrating, whenever you're ready.";
    }
  }

  // Generate check-in titles based on complexity
  String _getCheckInTitle(ComplexityLevel complexityProfile) {
    switch (complexityProfile) {
      case ComplexityLevel.stable:
        return "Daily Check-in 📊";
      case ComplexityLevel.trying:
        return "How are you doing? 💭";
      case ComplexityLevel.overloaded:
        return "Gentle check-in 🌸";
      case ComplexityLevel.survival:
        return "You matter 💙";
    }
  }

  // Generate check-in bodies based on complexity
  String _getCheckInBody(ComplexityLevel complexityProfile) {
    switch (complexityProfile) {
      case ComplexityLevel.stable:
        return "Time to log your habits and see your progress!";
      case ComplexityLevel.trying:
        return "Small wins add up. Check in with yourself.";
      case ComplexityLevel.overloaded:
        return "No pressure, just checking if you need any support.";
      case ComplexityLevel.survival:
        return "Taking time for yourself is an act of self-care.";
    }
  }

  // Schedule a notification
  Future<void> _scheduleNotification(ScheduledNotification notification) async {
    if (!_notificationsEnabled) return;

    try {
      _scheduledNotifications.add(notification);
      await _saveScheduledNotifications();

      final androidDetails = AndroidNotificationDetails(
        'starbound_habits',
        'Habit Reminders',
        channelDescription: 'Smart habit reminders and nudges',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: const BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        notification.id.hashCode,
        notification.title,
        notification.body,
        tz.TZDateTime.from(notification.scheduledTime, tz.local),
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode(notification.payload),
      );

      debugPrint(
          'Scheduled notification: ${notification.title} for ${notification.scheduledTime}');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Schedule upcoming notifications (called periodically)
  Future<void> _scheduleUpcomingNotifications() async {
    try {
      // Clean up expired notifications
      final now = DateTime.now();
      final expiredCount = _scheduledNotifications.length;
      _scheduledNotifications.removeWhere((n) => n.scheduledTime.isBefore(now));

      if (_scheduledNotifications.length != expiredCount) {
        await _saveScheduledNotifications();
        debugPrint(
            'Cleaned up ${expiredCount - _scheduledNotifications.length} expired notifications');
      }

      // Check if we need to schedule more notifications (always keep 24-48 hours ahead)
      final hoursAhead = _getHoursAheadScheduled();
      if (hoursAhead < 24) {
        debugPrint(
            'Only $hoursAhead hours scheduled ahead, generating more notifications');
        await _generatePeriodicNotifications();
      }
    } catch (e) {
      debugPrint('Error in background notification scheduling: $e');
    }
  }

  // Calculate how many hours ahead we have notifications scheduled
  int _getHoursAheadScheduled() {
    if (_scheduledNotifications.isEmpty) return 0;

    final now = DateTime.now();
    final futureNotifications = _scheduledNotifications
        .where((n) => n.scheduledTime.isAfter(now))
        .toList();

    if (futureNotifications.isEmpty) return 0;

    // Find the latest scheduled notification
    final latestTime = futureNotifications
        .map((n) => n.scheduledTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return latestTime.difference(now).inHours;
  }

  // Generate periodic notifications for the next 48 hours
  Future<void> _generatePeriodicNotifications() async {
    if (!_notificationsEnabled) return;

    try {
      final now = DateTime.now();
      final endTime = now.add(const Duration(hours: 48));

      // Generate daily check-ins for the next 2 days
      for (int day = 0; day < 2; day++) {
        final targetDate = now.add(Duration(days: day + 1));

        // Skip if we already have a check-in for this day
        final hasCheckIn = _scheduledNotifications.any((n) =>
            n.type == NotificationType.checkIn &&
            _isSameDay(n.scheduledTime, targetDate));

        if (!hasCheckIn) {
          final checkInTime = _getAdaptiveCheckInTime(ComplexityLevel.stable);

          final notification = ScheduledNotification(
            id: 'daily_checkin_${targetDate.day}_${targetDate.month}',
            type: NotificationType.checkIn,
            title: 'Daily Check-in 📊',
            body: 'How are your habits going today?',
            scheduledTime: checkInTime,
            payload: {
              'type': NotificationType.checkIn.index,
              'generated': true,
            },
          );

          await _scheduleNotification(notification);
        }
      }

      // Generate motivational boosts (every 2-3 days based on complexity)
      await _generateMotivationalNotifications(endTime);
    } catch (e) {
      debugPrint('Error generating periodic notifications: $e');
    }
  }

  // Generate motivational boost notifications
  Future<void> _generateMotivationalNotifications(DateTime endTime) async {
    final now = DateTime.now();
    final targetDate = now.add(const Duration(days: 2));

    // Check if we need a motivational boost
    final hasMotivation = _scheduledNotifications.any((n) =>
        n.type == NotificationType.motivationalBoost &&
        _isSameDay(n.scheduledTime, targetDate));

    if (!hasMotivation) {
      final motivationTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        Random().nextInt(3) + 10, // 10 AM - 12 PM
        Random().nextInt(60),
      );

      final motivationalMessages = [
        "You're building amazing habits! 🌟",
        "Every small step counts 💪",
        "Your consistency is inspiring! 🔥",
        "Progress, not perfection 🌱",
        "You're stronger than you think 💙",
      ];

      final notification = ScheduledNotification(
        id: 'motivation_${motivationTime.millisecondsSinceEpoch}',
        type: NotificationType.motivationalBoost,
        title:
            motivationalMessages[Random().nextInt(motivationalMessages.length)],
        body: "Take a moment to appreciate how far you've come.",
        scheduledTime: motivationTime,
        payload: {
          'type': NotificationType.motivationalBoost.index,
          'generated': true,
        },
      );

      await _scheduleNotification(notification);
    }
  }

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Public method to trigger background scheduling (called by app state)
  Future<void> triggerBackgroundScheduling({
    Map<String, String?>? currentHabits,
    ComplexityLevel? complexityProfile,
    Map<String, int>? habitStreaks,
  }) async {
    try {
      // Schedule context-aware notifications if we have current state
      if (currentHabits != null && complexityProfile != null) {
        await _scheduleContextAwareNotifications(
            currentHabits, complexityProfile, habitStreaks ?? {});
      }

      // Always run the general scheduling
      await _scheduleUpcomingNotifications();
    } catch (e) {
      debugPrint('Error in triggered background scheduling: $e');
    }
  }

  // Schedule context-aware notifications based on current app state
  Future<void> _scheduleContextAwareNotifications(
    Map<String, String?> currentHabits,
    ComplexityLevel complexityProfile,
    Map<String, int> habitStreaks,
  ) async {
    // Schedule streak protection for habits with active streaks
    for (final entry in habitStreaks.entries) {
      if (entry.value >= 3) {
        await scheduleStreakProtection(
          habitKey: entry.key,
          currentStreak: entry.value,
          complexityProfile: complexityProfile,
        );
      }
    }

    // Schedule check-in based on complexity profile
    await scheduleAdaptiveCheckIn(complexityProfile);
  }

  // Public API methods
  Future<void> updatePreferences({
    bool? enabled,
    String? preferredTime,
    List<int>? enabledDays,
    int? frequencyHours,
  }) async {
    if (enabled != null) _notificationsEnabled = enabled;
    if (preferredTime != null) _preferredTime = preferredTime;
    if (enabledDays != null) _enabledDays = enabledDays;
    if (frequencyHours != null) _frequencyHours = frequencyHours;

    await _savePreferences();

    if (!_notificationsEnabled) {
      await cancelAllNotifications();
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    _scheduledNotifications.clear();
    await _saveScheduledNotifications();
  }

  Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode);
    _scheduledNotifications.removeWhere((n) => n.id == id);
    await _saveScheduledNotifications();
  }

  // Getters
  bool get isEnabled => _notificationsEnabled;
  String get preferredTime => _preferredTime;
  List<int> get enabledDays => List.from(_enabledDays);
  int get frequencyHours => _frequencyHours;
  List<ScheduledNotification> get scheduledNotifications =>
      List.from(_scheduledNotifications);

  // Dispose
  void dispose() {
    _scheduleTimer?.cancel();
  }
}
