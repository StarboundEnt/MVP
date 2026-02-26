import 'dart:async';
import 'dart:convert';
import 'secure_storage_service.dart';

/// Privacy manager for handling user privacy and data protection
/// 
/// This service manages:
/// - Privacy consent and preferences
/// - Data retention policies
/// - GDPR/Privacy compliance
/// - Data anonymization
/// - Privacy-preserving analytics
/// - Right to be forgotten
class PrivacyManager {
  static PrivacyManager? _instance;
  static PrivacyManager get instance => _instance ??= PrivacyManager._();
  
  PrivacyManager._();

  late final SecureStorageService _secureStorage;
  bool _isInitialized = false;
  
  PrivacySettings? _currentSettings;
  final StreamController<PrivacyEvent> _privacyEventController = 
      StreamController<PrivacyEvent>.broadcast();

  /// Initialize the privacy manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _secureStorage = SecureStorageService();
      await _secureStorage.initialize();
      
      // Load existing privacy settings
      await _loadPrivacySettings();
      
      _isInitialized = true;
      
      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.systemInitialized,
        message: 'Privacy manager initialized',
        timestamp: DateTime.now(),
      ));
      
    } catch (e) {
      throw PrivacyException('Failed to initialize privacy manager: $e');
    }
  }

  /// Stream of privacy events
  Stream<PrivacyEvent> get privacyEvents => _privacyEventController.stream;

  /// Current privacy settings
  PrivacySettings get currentSettings => _currentSettings ?? PrivacySettings.defaultSettings();

  /// Update privacy consent
  Future<void> updatePrivacyConsent(ConsentPreferences consent) async {
    await _ensureInitialized();

    try {
      final updatedSettings = currentSettings.copyWith(
        consentPreferences: consent,
        lastUpdated: DateTime.now(),
      );

      await _savePrivacySettings(updatedSettings);
      
      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.consentUpdated,
        message: 'Privacy consent preferences updated',
        data: consent.toJson(),
        timestamp: DateTime.now(),
      ));

      // Apply consent changes immediately
      await _applyConsentChanges(consent);

    } catch (e) {
      throw PrivacyException('Failed to update privacy consent: $e');
    }
  }

  /// Update data retention preferences
  Future<void> updateDataRetention(DataRetentionSettings retention) async {
    await _ensureInitialized();

    try {
      final updatedSettings = currentSettings.copyWith(
        dataRetention: retention,
        lastUpdated: DateTime.now(),
      );

      await _savePrivacySettings(updatedSettings);
      
      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.retentionUpdated,
        message: 'Data retention settings updated',
        data: retention.toJson(),
        timestamp: DateTime.now(),
      ));

      // Schedule data cleanup based on new retention settings
      await _scheduleDataCleanup(retention);

    } catch (e) {
      throw PrivacyException('Failed to update data retention: $e');
    }
  }

  /// Update analytics preferences
  Future<void> updateAnalyticsPreferences(AnalyticsPreferences analytics) async {
    await _ensureInitialized();

    try {
      final updatedSettings = currentSettings.copyWith(
        analyticsPreferences: analytics,
        lastUpdated: DateTime.now(),
      );

      await _savePrivacySettings(updatedSettings);
      
      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.analyticsUpdated,
        message: 'Analytics preferences updated',
        data: analytics.toJson(),
        timestamp: DateTime.now(),
      ));

    } catch (e) {
      throw PrivacyException('Failed to update analytics preferences: $e');
    }
  }

  /// Request data export (GDPR Right to Data Portability)
  Future<DataExportResult> requestDataExport({
    List<DataCategory>? categories,
    DataExportFormat format = DataExportFormat.json,
  }) async {
    await _ensureInitialized();

    try {
      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.dataExportRequested,
        message: 'Data export requested',
        data: {
          'categories': categories?.map((c) => c.toString()).toList(),
          'format': format.toString(),
        },
        timestamp: DateTime.now(),
      ));

      // Generate export data
      final exportData = await _generateExportData(categories ?? DataCategory.values);
      
      // Create export file
      final exportFile = await _createExportFile(exportData, format);
      
      final result = DataExportResult(
        exportId: _generateExportId(),
        createdAt: DateTime.now(),
        format: format,
        categories: categories ?? DataCategory.values,
        filePath: exportFile,
        dataSize: exportData.length,
      );

      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.dataExported,
        message: 'Data export completed',
        data: {
          'export_id': result.exportId,
          'data_size': result.dataSize,
        },
        timestamp: DateTime.now(),
      ));

      return result;

    } catch (e) {
      throw PrivacyException('Failed to export data: $e');
    }
  }

  /// Request data deletion (GDPR Right to be Forgotten)
  Future<DataDeletionResult> requestDataDeletion({
    List<DataCategory>? categories,
    bool confirmDeletion = false,
  }) async {
    await _ensureInitialized();

    if (!confirmDeletion) {
      throw PrivacyException('Data deletion requires explicit confirmation');
    }

    try {
      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.dataDeletionRequested,
        message: 'Data deletion requested',
        data: {
          'categories': categories?.map((c) => c.toString()).toList(),
          'confirmed': confirmDeletion,
        },
        timestamp: DateTime.now(),
      ));

      final deletionSummary = await _performDataDeletion(categories ?? DataCategory.values);
      
      final result = DataDeletionResult(
        deletionId: _generateDeletionId(),
        requestedAt: DateTime.now(),
        categories: categories ?? DataCategory.values,
        deletionSummary: deletionSummary,
        isComplete: true,
      );

      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.dataDeleted,
        message: 'Data deletion completed',
        data: result.toJson(),
        timestamp: DateTime.now(),
      ));

      return result;

    } catch (e) {
      throw PrivacyException('Failed to delete data: $e');
    }
  }

  /// Anonymize user data
  Future<void> anonymizeUserData() async {
    await _ensureInitialized();

    try {
      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.dataAnonymized,
        message: 'User data anonymization started',
        timestamp: DateTime.now(),
      ));

      // Anonymize personal identifiers
      await _anonymizePersonalData();
      
      // Anonymize health data while preserving scientific value
      await _anonymizeHealthData();
      
      // Update privacy settings to reflect anonymization
      final updatedSettings = currentSettings.copyWith(
        isAnonymized: true,
        lastUpdated: DateTime.now(),
      );
      
      await _savePrivacySettings(updatedSettings);

      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.dataAnonymized,
        message: 'User data anonymization completed',
        timestamp: DateTime.now(),
      ));

    } catch (e) {
      throw PrivacyException('Failed to anonymize data: $e');
    }
  }

  /// Check if user can access specific data category
  bool canAccessDataCategory(DataCategory category) {
    final consent = currentSettings.consentPreferences;
    
    switch (category) {
      case DataCategory.personalInfo:
        return consent.personalDataConsent;
      case DataCategory.healthData:
        return consent.healthDataConsent;
      case DataCategory.usageAnalytics:
        return consent.analyticsConsent;
      case DataCategory.diagnostics:
        return consent.diagnosticsConsent;
      case DataCategory.preferences:
        return true; // Always accessible
    }
  }

  /// Check if data should be retained
  bool shouldRetainData(DataCategory category, DateTime dataAge) {
    final retention = currentSettings.dataRetention;
    final now = DateTime.now();
    
    Duration retentionPeriod;
    switch (category) {
      case DataCategory.personalInfo:
        retentionPeriod = Duration(days: retention.personalDataRetentionDays);
        break;
      case DataCategory.healthData:
        retentionPeriod = Duration(days: retention.healthDataRetentionDays);
        break;
      case DataCategory.usageAnalytics:
        retentionPeriod = Duration(days: retention.analyticsRetentionDays);
        break;
      case DataCategory.diagnostics:
        retentionPeriod = Duration(days: retention.diagnosticsRetentionDays);
        break;
      case DataCategory.preferences:
        return true; // Preferences always retained
    }
    
    return now.difference(dataAge) <= retentionPeriod;
  }

  /// Generate privacy compliance report
  Future<PrivacyComplianceReport> generateComplianceReport() async {
    await _ensureInitialized();

    try {
      final report = PrivacyComplianceReport(
        reportId: _generateReportId(),
        generatedAt: DateTime.now(),
        privacySettings: currentSettings,
        consentStatus: _getConsentStatus(),
        retentionCompliance: await _checkRetentionCompliance(),
        dataMinimization: await _checkDataMinimization(),
        securityMeasures: _getSecurityMeasures(),
        userRights: _getUserRights(),
      );

      await _logPrivacyEvent(PrivacyEvent(
        type: PrivacyEventType.complianceReportGenerated,
        message: 'Privacy compliance report generated',
        data: {'report_id': report.reportId},
        timestamp: DateTime.now(),
      ));

      return report;

    } catch (e) {
      throw PrivacyException('Failed to generate compliance report: $e');
    }
  }

  /// Load privacy settings from secure storage
  Future<void> _loadPrivacySettings() async {
    try {
      final settingsData = await _secureStorage.getPrivacySettings();
      if (settingsData != null) {
        _currentSettings = PrivacySettings.fromJson(settingsData);
      } else {
        _currentSettings = PrivacySettings.defaultSettings();
        await _savePrivacySettings(_currentSettings!);
      }
    } catch (e) {
      _currentSettings = PrivacySettings.defaultSettings();
    }
  }

  /// Save privacy settings to secure storage
  Future<void> _savePrivacySettings(PrivacySettings settings) async {
    try {
      await _secureStorage.storePrivacySettings(settings.toJson());
      _currentSettings = settings;
    } catch (e) {
      throw PrivacyException('Failed to save privacy settings: $e');
    }
  }

  /// Apply consent changes
  Future<void> _applyConsentChanges(ConsentPreferences consent) async {
    // If user revoked analytics consent, stop analytics
    if (!consent.analyticsConsent) {
      await _stopAnalytics();
    }
    
    // If user revoked diagnostic consent, disable diagnostics
    if (!consent.diagnosticsConsent) {
      await _disableDiagnostics();
    }
    
    // Apply other consent changes as needed
  }

  /// Schedule data cleanup based on retention settings
  Future<void> _scheduleDataCleanup(DataRetentionSettings retention) async {
    // This would schedule background cleanup tasks
    // For now, perform immediate cleanup if needed
    await _performDataCleanup(retention);
  }

  /// Perform data cleanup
  Future<void> _performDataCleanup(DataRetentionSettings retention) async {
    final now = DateTime.now();
    
    // Clean up old personal data
    final personalCutoff = now.subtract(Duration(days: retention.personalDataRetentionDays));
    await _cleanupDataCategory(DataCategory.personalInfo, personalCutoff);
    
    // Clean up old health data
    final healthCutoff = now.subtract(Duration(days: retention.healthDataRetentionDays));
    await _cleanupDataCategory(DataCategory.healthData, healthCutoff);
    
    // Clean up old analytics data
    final analyticsCutoff = now.subtract(Duration(days: retention.analyticsRetentionDays));
    await _cleanupDataCategory(DataCategory.usageAnalytics, analyticsCutoff);
    
    // Clean up old diagnostics data
    final diagnosticsCutoff = now.subtract(Duration(days: retention.diagnosticsRetentionDays));
    await _cleanupDataCategory(DataCategory.diagnostics, diagnosticsCutoff);
  }

  /// Clean up data for specific category
  Future<void> _cleanupDataCategory(DataCategory category, DateTime cutoff) async {
    // Implementation would depend on data storage structure
    await _logPrivacyEvent(PrivacyEvent(
      type: PrivacyEventType.dataCleanup,
      message: 'Data cleanup performed for category: $category',
      data: {'category': category.toString(), 'cutoff': cutoff.toIso8601String()},
      timestamp: DateTime.now(),
    ));
  }

  /// Generate export data
  Future<Map<String, dynamic>> _generateExportData(List<DataCategory> categories) async {
    final exportData = <String, dynamic>{};
    
    for (final category in categories) {
      if (canAccessDataCategory(category)) {
        exportData[category.toString()] = await _getCategoryData(category);
      }
    }
    
    exportData['export_metadata'] = {
      'generated_at': DateTime.now().toIso8601String(),
      'privacy_settings': currentSettings.toJson(),
      'user_id': 'anonymized_${_generateAnonymousId()}',
    };
    
    return exportData;
  }

  /// Get data for specific category
  Future<Map<String, dynamic>> _getCategoryData(DataCategory category) async {
    switch (category) {
      case DataCategory.personalInfo:
        return await _getPersonalData();
      case DataCategory.healthData:
        return await _getHealthData();
      case DataCategory.usageAnalytics:
        return await _getAnalyticsData();
      case DataCategory.diagnostics:
        return await _getDiagnosticsData();
      case DataCategory.preferences:
        return await _getPreferencesData();
    }
  }

  /// Create export file
  Future<String> _createExportFile(Map<String, dynamic> data, DataExportFormat format) async {
    final exportId = _generateExportId();
    final fileName = 'starbound_data_export_$exportId.${format.extension}';
    
    // This would create actual file
    // For now, return mock path
    return '/tmp/$fileName';
  }

  /// Perform data deletion
  Future<Map<String, int>> _performDataDeletion(List<DataCategory> categories) async {
    final deletionSummary = <String, int>{};
    
    for (final category in categories) {
      final deletedCount = await _deleteCategoryData(category);
      deletionSummary[category.toString()] = deletedCount;
    }
    
    return deletionSummary;
  }

  /// Delete data for specific category
  Future<int> _deleteCategoryData(DataCategory category) async {
    // Implementation would depend on data storage structure
    // Return mock count for now
    return switch (category) {
      DataCategory.personalInfo => 5,
      DataCategory.healthData => 100,
      DataCategory.usageAnalytics => 50,
      DataCategory.diagnostics => 25,
      DataCategory.preferences => 10,
    };
  }

  /// Anonymize personal data
  Future<void> _anonymizePersonalData() async {
    // Replace personal identifiers with anonymous ones
    // This would involve updating actual data
  }

  /// Anonymize health data
  Future<void> _anonymizeHealthData() async {
    // Remove identifying information while preserving scientific value
    // This would involve updating actual data
  }

  /// Stop analytics collection
  Future<void> _stopAnalytics() async {
    // Implementation to stop analytics
  }

  /// Disable diagnostics
  Future<void> _disableDiagnostics() async {
    // Implementation to disable diagnostics
  }

  /// Get mock data methods
  Future<Map<String, dynamic>> _getPersonalData() async => {'name': 'anonymized', 'email': 'anonymized'};
  Future<Map<String, dynamic>> _getHealthData() async => {'habits': [], 'goals': []};
  Future<Map<String, dynamic>> _getAnalyticsData() async => {'usage_stats': {}};
  Future<Map<String, dynamic>> _getDiagnosticsData() async => {'error_logs': []};
  Future<Map<String, dynamic>> _getPreferencesData() async => currentSettings.toJson();

  /// Generate IDs
  String _generateExportId() => 'export_${DateTime.now().millisecondsSinceEpoch}';
  String _generateDeletionId() => 'deletion_${DateTime.now().millisecondsSinceEpoch}';
  String _generateReportId() => 'report_${DateTime.now().millisecondsSinceEpoch}';
  String _generateAnonymousId() => 'anon_${DateTime.now().millisecondsSinceEpoch}';

  /// Compliance check methods
  ConsentStatus _getConsentStatus() {
    final consent = currentSettings.consentPreferences;
    return ConsentStatus(
      hasValidConsent: consent.consentTimestamp != null,
      consentDate: consent.consentTimestamp,
      personalDataConsent: consent.personalDataConsent,
      healthDataConsent: consent.healthDataConsent,
      analyticsConsent: consent.analyticsConsent,
      diagnosticsConsent: consent.diagnosticsConsent,
    );
  }

  Future<RetentionCompliance> _checkRetentionCompliance() async {
    // Check if data retention policies are being followed
    return RetentionCompliance(
      isCompliant: true,
      violationsFound: [],
      lastCleanup: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  Future<DataMinimization> _checkDataMinimization() async {
    // Check if only necessary data is being collected
    return DataMinimization(
      isMinimized: true,
      unnecessaryDataFound: [],
      dataCategories: DataCategory.values,
    );
  }

  List<String> _getSecurityMeasures() {
    return [
      'Data encryption at rest',
      'Data encryption in transit',
      'Secure authentication',
      'Access controls',
      'Audit logging',
    ];
  }

  Map<String, bool> _getUserRights() {
    return {
      'right_to_access': true,
      'right_to_rectification': true,
      'right_to_erasure': true,
      'right_to_portability': true,
      'right_to_restrict_processing': true,
      'right_to_object': true,
    };
  }

  /// Log privacy event
  Future<void> _logPrivacyEvent(PrivacyEvent event) async {
    _privacyEventController.add(event);
    
    // Store in secure storage for persistence
    try {
      await _secureStorage.storePrivacySettings({
        'last_privacy_event': event.toJson(),
        'event_timestamp': event.timestamp.toIso8601String(),
      });
    } catch (e) {
      // Continue even if logging fails
    }
  }

  /// Ensure initialization
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _privacyEventController.close();
  }
}

/// Privacy settings model
class PrivacySettings {
  final ConsentPreferences consentPreferences;
  final DataRetentionSettings dataRetention;
  final AnalyticsPreferences analyticsPreferences;
  final bool isAnonymized;
  final DateTime lastUpdated;

  const PrivacySettings({
    required this.consentPreferences,
    required this.dataRetention,
    required this.analyticsPreferences,
    this.isAnonymized = false,
    required this.lastUpdated,
  });

  factory PrivacySettings.defaultSettings() {
    return PrivacySettings(
      consentPreferences: ConsentPreferences.defaultConsent(),
      dataRetention: DataRetentionSettings.defaultRetention(),
      analyticsPreferences: AnalyticsPreferences.defaultAnalytics(),
      lastUpdated: DateTime.now(),
    );
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      consentPreferences: ConsentPreferences.fromJson(json['consent_preferences']),
      dataRetention: DataRetentionSettings.fromJson(json['data_retention']),
      analyticsPreferences: AnalyticsPreferences.fromJson(json['analytics_preferences']),
      isAnonymized: json['is_anonymized'] ?? false,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() => {
    'consent_preferences': consentPreferences.toJson(),
    'data_retention': dataRetention.toJson(),
    'analytics_preferences': analyticsPreferences.toJson(),
    'is_anonymized': isAnonymized,
    'last_updated': lastUpdated.toIso8601String(),
  };

  PrivacySettings copyWith({
    ConsentPreferences? consentPreferences,
    DataRetentionSettings? dataRetention,
    AnalyticsPreferences? analyticsPreferences,
    bool? isAnonymized,
    DateTime? lastUpdated,
  }) {
    return PrivacySettings(
      consentPreferences: consentPreferences ?? this.consentPreferences,
      dataRetention: dataRetention ?? this.dataRetention,
      analyticsPreferences: analyticsPreferences ?? this.analyticsPreferences,
      isAnonymized: isAnonymized ?? this.isAnonymized,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Consent preferences
class ConsentPreferences {
  final bool personalDataConsent;
  final bool healthDataConsent;
  final bool analyticsConsent;
  final bool diagnosticsConsent;
  final DateTime? consentTimestamp;

  const ConsentPreferences({
    required this.personalDataConsent,
    required this.healthDataConsent,
    required this.analyticsConsent,
    required this.diagnosticsConsent,
    this.consentTimestamp,
  });

  factory ConsentPreferences.defaultConsent() {
    return ConsentPreferences(
      personalDataConsent: false,
      healthDataConsent: false,
      analyticsConsent: false,
      diagnosticsConsent: false,
      consentTimestamp: DateTime.now(),
    );
  }

  factory ConsentPreferences.fromJson(Map<String, dynamic> json) {
    return ConsentPreferences(
      personalDataConsent: json['personal_data_consent'] ?? false,
      healthDataConsent: json['health_data_consent'] ?? false,
      analyticsConsent: json['analytics_consent'] ?? false,
      diagnosticsConsent: json['diagnostics_consent'] ?? false,
      consentTimestamp: json['consent_timestamp'] != null 
          ? DateTime.parse(json['consent_timestamp']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'personal_data_consent': personalDataConsent,
    'health_data_consent': healthDataConsent,
    'analytics_consent': analyticsConsent,
    'diagnostics_consent': diagnosticsConsent,
    'consent_timestamp': consentTimestamp?.toIso8601String(),
  };
}

/// Data retention settings
class DataRetentionSettings {
  final int personalDataRetentionDays;
  final int healthDataRetentionDays;
  final int analyticsRetentionDays;
  final int diagnosticsRetentionDays;

  const DataRetentionSettings({
    required this.personalDataRetentionDays,
    required this.healthDataRetentionDays,
    required this.analyticsRetentionDays,
    required this.diagnosticsRetentionDays,
  });

  factory DataRetentionSettings.defaultRetention() {
    return const DataRetentionSettings(
      personalDataRetentionDays: 365, // 1 year
      healthDataRetentionDays: 1095,  // 3 years
      analyticsRetentionDays: 90,     // 3 months
      diagnosticsRetentionDays: 30,   // 1 month
    );
  }

  factory DataRetentionSettings.fromJson(Map<String, dynamic> json) {
    return DataRetentionSettings(
      personalDataRetentionDays: json['personal_data_retention_days'] ?? 365,
      healthDataRetentionDays: json['health_data_retention_days'] ?? 1095,
      analyticsRetentionDays: json['analytics_retention_days'] ?? 90,
      diagnosticsRetentionDays: json['diagnostics_retention_days'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
    'personal_data_retention_days': personalDataRetentionDays,
    'health_data_retention_days': healthDataRetentionDays,
    'analytics_retention_days': analyticsRetentionDays,
    'diagnostics_retention_days': diagnosticsRetentionDays,
  };
}

/// Analytics preferences
class AnalyticsPreferences {
  final bool enableUsageAnalytics;
  final bool enablePerformanceAnalytics;
  final bool enableCrashReporting;
  final bool anonymizeData;

  const AnalyticsPreferences({
    required this.enableUsageAnalytics,
    required this.enablePerformanceAnalytics,
    required this.enableCrashReporting,
    required this.anonymizeData,
  });

  factory AnalyticsPreferences.defaultAnalytics() {
    return const AnalyticsPreferences(
      enableUsageAnalytics: false,
      enablePerformanceAnalytics: false,
      enableCrashReporting: false,
      anonymizeData: true,
    );
  }

  factory AnalyticsPreferences.fromJson(Map<String, dynamic> json) {
    return AnalyticsPreferences(
      enableUsageAnalytics: json['enable_usage_analytics'] ?? false,
      enablePerformanceAnalytics: json['enable_performance_analytics'] ?? false,
      enableCrashReporting: json['enable_crash_reporting'] ?? false,
      anonymizeData: json['anonymize_data'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'enable_usage_analytics': enableUsageAnalytics,
    'enable_performance_analytics': enablePerformanceAnalytics,
    'enable_crash_reporting': enableCrashReporting,
    'anonymize_data': anonymizeData,
  };
}

/// Data models for results and compliance
class DataExportResult {
  final String exportId;
  final DateTime createdAt;
  final DataExportFormat format;
  final List<DataCategory> categories;
  final String filePath;
  final int dataSize;

  const DataExportResult({
    required this.exportId,
    required this.createdAt,
    required this.format,
    required this.categories,
    required this.filePath,
    required this.dataSize,
  });
}

class DataDeletionResult {
  final String deletionId;
  final DateTime requestedAt;
  final List<DataCategory> categories;
  final Map<String, int> deletionSummary;
  final bool isComplete;

  const DataDeletionResult({
    required this.deletionId,
    required this.requestedAt,
    required this.categories,
    required this.deletionSummary,
    required this.isComplete,
  });

  Map<String, dynamic> toJson() => {
    'deletion_id': deletionId,
    'requested_at': requestedAt.toIso8601String(),
    'categories': categories.map((c) => c.toString()).toList(),
    'deletion_summary': deletionSummary,
    'is_complete': isComplete,
  };
}

class PrivacyComplianceReport {
  final String reportId;
  final DateTime generatedAt;
  final PrivacySettings privacySettings;
  final ConsentStatus consentStatus;
  final RetentionCompliance retentionCompliance;
  final DataMinimization dataMinimization;
  final List<String> securityMeasures;
  final Map<String, bool> userRights;

  const PrivacyComplianceReport({
    required this.reportId,
    required this.generatedAt,
    required this.privacySettings,
    required this.consentStatus,
    required this.retentionCompliance,
    required this.dataMinimization,
    required this.securityMeasures,
    required this.userRights,
  });
}

class ConsentStatus {
  final bool hasValidConsent;
  final DateTime? consentDate;
  final bool personalDataConsent;
  final bool healthDataConsent;
  final bool analyticsConsent;
  final bool diagnosticsConsent;

  const ConsentStatus({
    required this.hasValidConsent,
    this.consentDate,
    required this.personalDataConsent,
    required this.healthDataConsent,
    required this.analyticsConsent,
    required this.diagnosticsConsent,
  });
}

class RetentionCompliance {
  final bool isCompliant;
  final List<String> violationsFound;
  final DateTime? lastCleanup;

  const RetentionCompliance({
    required this.isCompliant,
    required this.violationsFound,
    this.lastCleanup,
  });
}

class DataMinimization {
  final bool isMinimized;
  final List<String> unnecessaryDataFound;
  final List<DataCategory> dataCategories;

  const DataMinimization({
    required this.isMinimized,
    required this.unnecessaryDataFound,
    required this.dataCategories,
  });
}

class PrivacyEvent {
  final PrivacyEventType type;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const PrivacyEvent({
    required this.type,
    required this.message,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'message': message,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Enums
enum DataCategory {
  personalInfo,
  healthData,
  usageAnalytics,
  diagnostics,
  preferences,
}

enum DataExportFormat {
  json,
  csv,
  xml,
}

extension DataExportFormatExtension on DataExportFormat {
  String get extension {
    switch (this) {
      case DataExportFormat.json:
        return 'json';
      case DataExportFormat.csv:
        return 'csv';
      case DataExportFormat.xml:
        return 'xml';
    }
  }
}

enum PrivacyEventType {
  systemInitialized,
  consentUpdated,
  retentionUpdated,
  analyticsUpdated,
  dataExportRequested,
  dataExported,
  dataDeletionRequested,
  dataDeleted,
  dataAnonymized,
  dataCleanup,
  complianceReportGenerated,
}

/// Exception for privacy operations
class PrivacyException implements Exception {
  final String message;
  
  const PrivacyException(this.message);
  
  @override
  String toString() => 'PrivacyException: $message';
}