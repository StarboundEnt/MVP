import 'dart:math';

/// Lightweight analytics entities used by the dashboard and services.
/// These plain data classes replaced the previous Freezed models so
/// no build_runner step is required to compile the app.
class AnalyticsData {
  final String id;
  final DateTime timestamp;
  final AnalyticsEventType eventType;
  final Map<String, dynamic> properties;
  final String userId;
  final String? sessionId;
  final AnalyticsCategory? category;
  final Map<String, dynamic> metadata;

  const AnalyticsData({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.properties,
    required this.userId,
    this.sessionId,
    this.category,
    this.metadata = const {},
  });

  factory AnalyticsData.create({
    required AnalyticsEventType eventType,
    required Map<String, dynamic> properties,
    required String userId,
    String? sessionId,
    AnalyticsCategory? category,
    Map<String, dynamic>? metadata,
  }) {
    return AnalyticsData(
      id: _generateId(),
      timestamp: DateTime.now(),
      eventType: eventType,
      properties: Map<String, dynamic>.from(properties),
      userId: userId,
      sessionId: sessionId,
      category: category,
      metadata: metadata != null
          ? Map<String, dynamic>.from(metadata)
          : <String, dynamic>{},
    );
  }

  AnalyticsData copyWith({
    String? id,
    DateTime? timestamp,
    AnalyticsEventType? eventType,
    Map<String, dynamic>? properties,
    String? userId,
    String? sessionId,
    AnalyticsCategory? category,
    Map<String, dynamic>? metadata,
  }) {
    return AnalyticsData(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      properties: properties ?? Map<String, dynamic>.from(this.properties),
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      category: category ?? this.category,
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
    );
  }

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      id: json['id']?.toString() ?? _generateId(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      eventType:
          AnalyticsEventTypeExtension.parse(json['eventType']?.toString()),
      properties: Map<String, dynamic>.from(json['properties'] ?? const {}),
      userId: json['userId']?.toString() ?? '',
      sessionId: json['sessionId']?.toString(),
      category: json['category'] != null
          ? AnalyticsCategoryExtension.parse(json['category'].toString())
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.name,
      'properties': properties,
      'userId': userId,
      'sessionId': sessionId,
      'category': category?.name,
      'metadata': metadata,
    };
  }
}

enum AnalyticsEventType {
  habitCompleted,
  habitSkipped,
  habitCreated,
  habitDeleted,
  screenViewed,
  buttonPressed,
  featureUsed,
  sessionStarted,
  sessionEnded,
  errorOccurred,
  notificationReceived,
  notificationOpened,
  feedbackSubmitted,
}

enum AnalyticsCategory {
  habits,
  actions,
  wellbeing,
  engagement,
  performance,
  notifications,
  feedback,
}

enum PerformanceMetricType {
  streakLength,
  completionRate,
  consistency,
  recoveryTime,
  intentStrength,
}

enum NotificationType {
  reminder,
  followUp,
  celebration,
  urgent,
}

enum FeedbackType {
  praise,
  issue,
  suggestion,
  neutral,
}

enum AnalyticsTimeRange { week, month, quarter }

enum HabitCategory {
  sleep,
  hydration,
  movement,
  nutrition,
  mindfulness,
  social,
  productivity,
  creativity,
  spirituality,
  finance,
  environment,
  other,
}

enum HabitType { choice, chance }

/// Helper for generating lightweight IDs without external deps.
String _generateId() {
  final random = Random();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final suffix = random.nextInt(1 << 32).toRadixString(16);
  return 'analytics_${timestamp}_$suffix';
}

extension AnalyticsEventTypeExtension on AnalyticsEventType {
  static AnalyticsEventType parse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return AnalyticsEventType.habitCompleted;
    }
    return AnalyticsEventType.values.firstWhere(
      (value) => value.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => AnalyticsEventType.habitCompleted,
    );
  }

  String get displayName {
    switch (this) {
      case AnalyticsEventType.habitCompleted:
        return 'Habit Completed';
      case AnalyticsEventType.habitSkipped:
        return 'Habit Skipped';
      case AnalyticsEventType.habitCreated:
        return 'Habit Created';
      case AnalyticsEventType.habitDeleted:
        return 'Habit Deleted';
      case AnalyticsEventType.screenViewed:
        return 'Screen Viewed';
      case AnalyticsEventType.buttonPressed:
        return 'Button Pressed';
      case AnalyticsEventType.featureUsed:
        return 'Feature Used';
      case AnalyticsEventType.sessionStarted:
        return 'Session Started';
      case AnalyticsEventType.sessionEnded:
        return 'Session Ended';
      case AnalyticsEventType.errorOccurred:
        return 'Error Occurred';
      case AnalyticsEventType.notificationReceived:
        return 'Notification Received';
      case AnalyticsEventType.notificationOpened:
        return 'Notification Opened';
      case AnalyticsEventType.feedbackSubmitted:
        return 'Feedback Submitted';
    }
  }
}

extension AnalyticsCategoryExtension on AnalyticsCategory {
  static AnalyticsCategory parse(String raw) {
    return AnalyticsCategory.values.firstWhere(
      (value) => value.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => AnalyticsCategory.wellbeing,
    );
  }

  String get displayName {
    switch (this) {
      case AnalyticsCategory.habits:
        return 'Habits';
      case AnalyticsCategory.actions:
        return 'Actions';
      case AnalyticsCategory.wellbeing:
        return 'Wellbeing';
      case AnalyticsCategory.engagement:
        return 'Engagement';
      case AnalyticsCategory.performance:
        return 'Performance';
      case AnalyticsCategory.notifications:
        return 'Notifications';
      case AnalyticsCategory.feedback:
        return 'Feedback';
    }
  }
}
