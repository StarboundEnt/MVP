import 'package:equatable/equatable.dart';

/// User profile domain entity
class UserProfile extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String email;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final UserSettings settings;
  final UserPreferences preferences;
  final UserHealthProfile healthProfile;
  final List<String> roles;
  final UserStatus status;
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic>? metadata;

  const UserProfile({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.email,
    required this.displayName,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.phoneNumber,
    this.dateOfBirth,
    required this.settings,
    required this.preferences,
    required this.healthProfile,
    required this.roles,
    required this.status,
    this.lastLoginAt,
    this.lastActiveAt,
    this.metadata,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      avatarUrl: json['avatarUrl'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.parse(json['dateOfBirth']) : null,
      settings: UserSettings.fromJson(json['settings'] ?? {}),
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      healthProfile: UserHealthProfile.fromJson(json['healthProfile'] ?? {}),
      roles: List<String>.from(json['roles'] ?? []),
      status: UserStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => UserStatus.active,
      ),
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt']) : null,
      lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt']) : null,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'settings': settings.toJson(),
      'preferences': preferences.toJson(),
      'healthProfile': healthProfile.toJson(),
      'roles': roles,
      'status': status.name,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory UserProfile.create({
    required String email,
    required String displayName,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? phoneNumber,
    DateTime? dateOfBirth,
    UserSettings? settings,
    UserPreferences? preferences,
    UserHealthProfile? healthProfile,
    List<String>? roles,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return UserProfile(
      id: _generateId(),
      createdAt: now,
      updatedAt: now,
      email: email,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      avatarUrl: avatarUrl,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      settings: settings ?? UserSettings.defaultSettings(),
      preferences: preferences ?? UserPreferences.defaultPreferences(),
      healthProfile: healthProfile ?? UserHealthProfile.defaultProfile(),
      roles: roles ?? ['user'],
      status: UserStatus.active,
      lastLoginAt: null,
      lastActiveAt: null,
      metadata: metadata,
    );
  }

  UserProfile copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? phoneNumber,
    DateTime? dateOfBirth,
    UserSettings? settings,
    UserPreferences? preferences,
    UserHealthProfile? healthProfile,
    List<String>? roles,
    UserStatus? status,
    DateTime? lastLoginAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      settings: settings ?? this.settings,
      preferences: preferences ?? this.preferences,
      healthProfile: healthProfile ?? this.healthProfile,
      roles: roles ?? this.roles,
      status: status ?? this.status,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        email,
        displayName,
        firstName,
        lastName,
        avatarUrl,
        phoneNumber,
        dateOfBirth,
        settings,
        preferences,
        healthProfile,
        roles,
        status,
        lastLoginAt,
        lastActiveAt,
        metadata,
      ];

  static String _generateId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}

/// User settings model
class UserSettings extends Equatable {
  final NotificationSettings notifications;
  final PrivacySettings privacy;
  final AccessibilitySettings accessibility;
  final AppearanceSettings appearance;
  final SecuritySettings security;
  final DataSyncSettings dataSync;

  const UserSettings({
    required this.notifications,
    required this.privacy,
    required this.accessibility,
    required this.appearance,
    required this.security,
    required this.dataSync,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      notifications: NotificationSettings.fromJson(json['notifications'] ?? {}),
      privacy: PrivacySettings.fromJson(json['privacy'] ?? {}),
      accessibility: AccessibilitySettings.fromJson(json['accessibility'] ?? {}),
      appearance: AppearanceSettings.fromJson(json['appearance'] ?? {}),
      security: SecuritySettings.fromJson(json['security'] ?? {}),
      dataSync: DataSyncSettings.fromJson(json['dataSync'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.toJson(),
      'privacy': privacy.toJson(),
      'accessibility': accessibility.toJson(),
      'appearance': appearance.toJson(),
      'security': security.toJson(),
      'dataSync': dataSync.toJson(),
    };
  }

  factory UserSettings.defaultSettings() {
    return UserSettings(
      notifications: NotificationSettings.defaultSettings(),
      privacy: PrivacySettings.defaultSettings(),
      accessibility: AccessibilitySettings.defaultSettings(),
      appearance: AppearanceSettings.defaultSettings(),
      security: SecuritySettings.defaultSettings(),
      dataSync: DataSyncSettings.defaultSettings(),
    );
  }

  UserSettings copyWith({
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    AccessibilitySettings? accessibility,
    AppearanceSettings? appearance,
    SecuritySettings? security,
    DataSyncSettings? dataSync,
  }) {
    return UserSettings(
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      accessibility: accessibility ?? this.accessibility,
      appearance: appearance ?? this.appearance,
      security: security ?? this.security,
      dataSync: dataSync ?? this.dataSync,
    );
  }

  @override
  List<Object?> get props => [notifications, privacy, accessibility, appearance, security, dataSync];
}

/// Notification settings model
class NotificationSettings extends Equatable {
  final bool enabled;
  final bool habits;
  final bool achievements;
  final bool insights;
  final bool social;
  final List<String> quietHours;
  final Map<String, bool> channels;

  const NotificationSettings({
    required this.enabled,
    required this.habits,
    required this.achievements,
    required this.insights,
    required this.social,
    required this.quietHours,
    required this.channels,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      habits: json['habits'] ?? true,
      achievements: json['achievements'] ?? true,
      insights: json['insights'] ?? true,
      social: json['social'] ?? false,
      quietHours: List<String>.from(json['quietHours'] ?? ['22:00', '08:00']),
      channels: Map<String, bool>.from(json['channels'] ?? {'push': true, 'email': false}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'habits': habits,
      'achievements': achievements,
      'insights': insights,
      'social': social,
      'quietHours': quietHours,
      'channels': channels,
    };
  }

  factory NotificationSettings.defaultSettings() {
    return const NotificationSettings(
      enabled: true,
      habits: true,
      achievements: true,
      insights: true,
      social: false,
      quietHours: ['22:00', '08:00'],
      channels: {'push': true, 'email': false},
    );
  }

  @override
  List<Object?> get props => [enabled, habits, achievements, insights, social, quietHours, channels];
}

/// Privacy settings model
class PrivacySettings extends Equatable {
  final bool shareProgress;
  final bool allowFriends;
  final bool publicProfile;
  final DataRetentionLevel dataRetention;

  const PrivacySettings({
    required this.shareProgress,
    required this.allowFriends,
    required this.publicProfile,
    required this.dataRetention,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      shareProgress: json['shareProgress'] ?? false,
      allowFriends: json['allowFriends'] ?? true,
      publicProfile: json['publicProfile'] ?? false,
      dataRetention: DataRetentionLevel.values.firstWhere(
        (d) => d.name == json['dataRetention'],
        orElse: () => DataRetentionLevel.standard,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shareProgress': shareProgress,
      'allowFriends': allowFriends,
      'publicProfile': publicProfile,
      'dataRetention': dataRetention.name,
    };
  }

  factory PrivacySettings.defaultSettings() {
    return const PrivacySettings(
      shareProgress: false,
      allowFriends: true,
      publicProfile: false,
      dataRetention: DataRetentionLevel.standard,
    );
  }

  @override
  List<Object?> get props => [shareProgress, allowFriends, publicProfile, dataRetention];
}

/// Accessibility settings model
class AccessibilitySettings extends Equatable {
  final bool highContrast;
  final bool largeText;
  final bool screenReader;
  final bool reducedMotion;
  final bool hapticFeedback;
  final double textScale;

  const AccessibilitySettings({
    required this.highContrast,
    required this.largeText,
    required this.screenReader,
    required this.reducedMotion,
    required this.hapticFeedback,
    required this.textScale,
  });

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      highContrast: json['highContrast'] ?? false,
      largeText: json['largeText'] ?? false,
      screenReader: json['screenReader'] ?? false,
      reducedMotion: json['reducedMotion'] ?? false,
      hapticFeedback: json['hapticFeedback'] ?? true,
      textScale: (json['textScale'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highContrast': highContrast,
      'largeText': largeText,
      'screenReader': screenReader,
      'reducedMotion': reducedMotion,
      'hapticFeedback': hapticFeedback,
      'textScale': textScale,
    };
  }

  factory AccessibilitySettings.defaultSettings() {
    return const AccessibilitySettings(
      highContrast: false,
      largeText: false,
      screenReader: false,
      reducedMotion: false,
      hapticFeedback: true,
      textScale: 1.0,
    );
  }

  @override
  List<Object?> get props => [highContrast, largeText, screenReader, reducedMotion, hapticFeedback, textScale];
}

/// Appearance settings model
class AppearanceSettings extends Equatable {
  final ThemeMode theme;
  final String primaryColor;
  final String language;
  final String region;

  const AppearanceSettings({
    required this.theme,
    required this.primaryColor,
    required this.language,
    required this.region,
  });

  factory AppearanceSettings.fromJson(Map<String, dynamic> json) {
    return AppearanceSettings(
      theme: ThemeMode.values.firstWhere(
        (t) => t.name == json['theme'],
        orElse: () => ThemeMode.system,
      ),
      primaryColor: json['primaryColor'] ?? '#6B73FF',
      language: json['language'] ?? 'en',
      region: json['region'] ?? 'AU',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.name,
      'primaryColor': primaryColor,
      'language': language,
      'region': region,
    };
  }

  factory AppearanceSettings.defaultSettings() {
    return const AppearanceSettings(
      theme: ThemeMode.system,
      primaryColor: '#6B73FF',
      language: 'en',
      region: 'AU',
    );
  }

  @override
  List<Object?> get props => [theme, primaryColor, language, region];
}

/// Security settings model
class SecuritySettings extends Equatable {
  final bool biometricAuth;
  final bool requirePin;
  final int sessionTimeout;
  final bool autoLock;

  const SecuritySettings({
    required this.biometricAuth,
    required this.requirePin,
    required this.sessionTimeout,
    required this.autoLock,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      biometricAuth: json['biometricAuth'] ?? false,
      requirePin: json['requirePin'] ?? false,
      sessionTimeout: json['sessionTimeout'] ?? 30,
      autoLock: json['autoLock'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'biometricAuth': biometricAuth,
      'requirePin': requirePin,
      'sessionTimeout': sessionTimeout,
      'autoLock': autoLock,
    };
  }

  factory SecuritySettings.defaultSettings() {
    return const SecuritySettings(
      biometricAuth: false,
      requirePin: false,
      sessionTimeout: 30,
      autoLock: true,
    );
  }

  @override
  List<Object?> get props => [biometricAuth, requirePin, sessionTimeout, autoLock];
}

/// Data sync settings model
class DataSyncSettings extends Equatable {
  final bool autoSync;
  final bool wifiOnly;
  final int syncInterval;
  final bool backupEnabled;

  const DataSyncSettings({
    required this.autoSync,
    required this.wifiOnly,
    required this.syncInterval,
    required this.backupEnabled,
  });

  factory DataSyncSettings.fromJson(Map<String, dynamic> json) {
    return DataSyncSettings(
      autoSync: json['autoSync'] ?? true,
      wifiOnly: json['wifiOnly'] ?? true,
      syncInterval: json['syncInterval'] ?? 60,
      backupEnabled: json['backupEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSync': autoSync,
      'wifiOnly': wifiOnly,
      'syncInterval': syncInterval,
      'backupEnabled': backupEnabled,
    };
  }

  factory DataSyncSettings.defaultSettings() {
    return const DataSyncSettings(
      autoSync: true,
      wifiOnly: true,
      syncInterval: 60,
      backupEnabled: true,
    );
  }

  @override
  List<Object?> get props => [autoSync, wifiOnly, syncInterval, backupEnabled];
}

/// User preferences model
class UserPreferences extends Equatable {
  final MotivationStyle motivationStyle;
  final DifficultyLevel preferredDifficulty;
  final List<String> favoriteHabitCategories;
  final List<String> preferredReminderTimes;
  final GoalOrientation goalOrientation;
  final bool enableAI;
  final bool shareInsights;

  const UserPreferences({
    required this.motivationStyle,
    required this.preferredDifficulty,
    required this.favoriteHabitCategories,
    required this.preferredReminderTimes,
    required this.goalOrientation,
    required this.enableAI,
    required this.shareInsights,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      motivationStyle: MotivationStyle.values.firstWhere(
        (m) => m.name == json['motivationStyle'],
        orElse: () => MotivationStyle.encouraging,
      ),
      preferredDifficulty: DifficultyLevel.values.firstWhere(
        (d) => d.name == json['preferredDifficulty'],
        orElse: () => DifficultyLevel.medium,
      ),
      favoriteHabitCategories: List<String>.from(json['favoriteHabitCategories'] ?? []),
      preferredReminderTimes: List<String>.from(json['preferredReminderTimes'] ?? ['09:00', '21:00']),
      goalOrientation: GoalOrientation.values.firstWhere(
        (g) => g.name == json['goalOrientation'],
        orElse: () => GoalOrientation.wellness,
      ),
      enableAI: json['enableAI'] ?? true,
      shareInsights: json['shareInsights'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'motivationStyle': motivationStyle.name,
      'preferredDifficulty': preferredDifficulty.name,
      'favoriteHabitCategories': favoriteHabitCategories,
      'preferredReminderTimes': preferredReminderTimes,
      'goalOrientation': goalOrientation.name,
      'enableAI': enableAI,
      'shareInsights': shareInsights,
    };
  }

  factory UserPreferences.defaultPreferences() {
    return const UserPreferences(
      motivationStyle: MotivationStyle.encouraging,
      preferredDifficulty: DifficultyLevel.medium,
      favoriteHabitCategories: [],
      preferredReminderTimes: ['09:00', '21:00'],
      goalOrientation: GoalOrientation.wellness,
      enableAI: true,
      shareInsights: false,
    );
  }

  UserPreferences copyWith({
    MotivationStyle? motivationStyle,
    DifficultyLevel? preferredDifficulty,
    List<String>? favoriteHabitCategories,
    List<String>? preferredReminderTimes,
    GoalOrientation? goalOrientation,
    bool? enableAI,
    bool? shareInsights,
  }) {
    return UserPreferences(
      motivationStyle: motivationStyle ?? this.motivationStyle,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      favoriteHabitCategories: favoriteHabitCategories ?? this.favoriteHabitCategories,
      preferredReminderTimes: preferredReminderTimes ?? this.preferredReminderTimes,
      goalOrientation: goalOrientation ?? this.goalOrientation,
      enableAI: enableAI ?? this.enableAI,
      shareInsights: shareInsights ?? this.shareInsights,
    );
  }

  @override
  List<Object?> get props => [
        motivationStyle,
        preferredDifficulty,
        favoriteHabitCategories,
        preferredReminderTimes,
        goalOrientation,
        enableAI,
        shareInsights,
      ];
}

/// User health profile model
class UserHealthProfile extends Equatable {
  final int? age;
  final double? height;
  final double? weight;
  final String? fitnessLevel;
  final List<String> fitnessGoals;
  final List<String> wellnessGoals;
  final List<String> healthConditions;
  final List<String> dietaryRestrictions;
  final String? activityLevel;
  final Map<String, dynamic>? healthMetrics;

  const UserHealthProfile({
    this.age,
    this.height,
    this.weight,
    this.fitnessLevel,
    required this.fitnessGoals,
    required this.wellnessGoals,
    required this.healthConditions,
    required this.dietaryRestrictions,
    this.activityLevel,
    this.healthMetrics,
  });

  factory UserHealthProfile.fromJson(Map<String, dynamic> json) {
    return UserHealthProfile(
      age: json['age'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      fitnessLevel: json['fitnessLevel'],
      fitnessGoals: List<String>.from(json['fitnessGoals'] ?? []),
      wellnessGoals: List<String>.from(json['wellnessGoals'] ?? []),
      healthConditions: List<String>.from(json['healthConditions'] ?? []),
      dietaryRestrictions: List<String>.from(json['dietaryRestrictions'] ?? []),
      activityLevel: json['activityLevel'],
      healthMetrics: json['healthMetrics'] != null ? Map<String, dynamic>.from(json['healthMetrics']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'height': height,
      'weight': weight,
      'fitnessLevel': fitnessLevel,
      'fitnessGoals': fitnessGoals,
      'wellnessGoals': wellnessGoals,
      'healthConditions': healthConditions,
      'dietaryRestrictions': dietaryRestrictions,
      'activityLevel': activityLevel,
      'healthMetrics': healthMetrics,
    };
  }

  factory UserHealthProfile.defaultProfile() {
    return const UserHealthProfile(
      fitnessGoals: [],
      wellnessGoals: [],
      healthConditions: [],
      dietaryRestrictions: [],
    );
  }

  UserHealthProfile copyWith({
    int? age,
    double? height,
    double? weight,
    String? fitnessLevel,
    List<String>? fitnessGoals,
    List<String>? wellnessGoals,
    List<String>? healthConditions,
    List<String>? dietaryRestrictions,
    String? activityLevel,
    Map<String, dynamic>? healthMetrics,
  }) {
    return UserHealthProfile(
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      wellnessGoals: wellnessGoals ?? this.wellnessGoals,
      healthConditions: healthConditions ?? this.healthConditions,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      activityLevel: activityLevel ?? this.activityLevel,
      healthMetrics: healthMetrics ?? this.healthMetrics,
    );
  }

  @override
  List<Object?> get props => [
        age,
        height,
        weight,
        fitnessLevel,
        fitnessGoals,
        wellnessGoals,
        healthConditions,
        dietaryRestrictions,
        activityLevel,
        healthMetrics,
      ];
}

// Extension methods for UserProfile
extension UserProfileExtensions on UserProfile {
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else {
      return displayName;
    }
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    final age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      return age - 1;
    }
    return age;
  }

  bool get isActive => status == UserStatus.active;
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasHealthData => healthProfile.age != null || healthProfile.height != null;
}

// Enums
enum UserStatus {
  active,
  inactive,
  suspended,
  pending,
}

enum MotivationStyle {
  encouraging,
  challenging,
  analytical,
  supportive,
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
}

enum GoalOrientation {
  performance,
  wellness,
  lifestyle,
  clinical,
}

enum ThemeMode {
  light,
  dark,
  system,
}

enum DataRetentionLevel {
  minimal,
  standard,
  extended,
}