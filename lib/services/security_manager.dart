import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'secure_storage_service.dart';
import 'secure_http_service.dart';

/// Comprehensive security manager for Starbound app
/// 
/// This service coordinates all security-related operations including:
/// - Device security validation
/// - Biometric authentication
/// - Security policy enforcement
/// - Threat detection and response
/// - Security audit logging
/// - Privacy compliance
class SecurityManager {
  static SecurityManager? _instance;
  static SecurityManager get instance => _instance ??= SecurityManager._();
  
  SecurityManager._();

  late final SecureStorageService _secureStorage;
  late final SecureHttpService _secureHttp;
  late final LocalAuthentication _localAuth;
  late final DeviceInfoPlugin _deviceInfo;
  
  bool _isInitialized = false;
  SecurityLevel _currentSecurityLevel = SecurityLevel.unknown;
  final List<SecurityThreat> _detectedThreats = [];
  final List<SecurityEvent> _securityLog = [];
  
  Timer? _securityMonitoringTimer;
  StreamController<SecurityEvent>? _securityEventController;
  
  /// Initialize the security manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _secureStorage = SecureStorageService();
      _localAuth = LocalAuthentication();
      _deviceInfo = DeviceInfoPlugin();
      
      await _secureStorage.initialize();
      _secureHttp = await SecureHttpService.create(
        secureStorage: _secureStorage,
      );
      
      // Assess initial security level
      await _assessSecurityLevel();
      
      // Start security monitoring
      _startSecurityMonitoring();
      
      // Initialize event stream
      _securityEventController = StreamController<SecurityEvent>.broadcast();
      
      _isInitialized = true;
      
      await _logSecurityEvent(SecurityEvent(
        type: SecurityEventType.systemInitialized,
        severity: SecuritySeverity.info,
        message: 'Security manager initialized successfully',
        timestamp: DateTime.now(),
      ));
      
    } catch (e) {
      throw SecurityException('Failed to initialize security manager: $e');
    }
  }

  /// Stream of security events
  Stream<SecurityEvent> get securityEvents => 
      _securityEventController?.stream ?? const Stream.empty();

  /// Current security level
  SecurityLevel get securityLevel => _currentSecurityLevel;

  /// Check if device meets minimum security requirements
  Future<SecurityAssessment> assessDeviceSecurityy() async {
    await _ensureInitialized();

    final assessment = SecurityAssessment();
    
    try {
      // Check device encryption
      assessment.isDeviceEncrypted = await _checkDeviceEncryption();
      
      // Check screen lock
      assessment.hasScreenLock = await _checkScreenLock();
      
      // Check biometric availability
      assessment.biometricAvailable = await _checkBiometricAvailability();
      
      // Check for rooting/jailbreaking
      assessment.isDeviceCompromised = await _checkDeviceCompromise();
      
      // Check app integrity
      assessment.appIntegrityValid = await _checkAppIntegrity();
      
      // Check network security
      assessment.networkSecure = await _checkNetworkSecurity();
      
      // Check for debugging/development tools
      assessment.developmentToolsDetected = await _checkDevelopmentTools();
      
      // Calculate overall security score
      assessment.securityScore = _calculateSecurityScore(assessment);
      
      // Determine security level
      assessment.securityLevel = _determineSecurityLevel(assessment.securityScore);
      
      _currentSecurityLevel = assessment.securityLevel;
      
      await _logSecurityEvent(SecurityEvent(
        type: SecurityEventType.securityAssessment,
        severity: assessment.securityLevel == SecurityLevel.high 
            ? SecuritySeverity.info 
            : SecuritySeverity.warning,
        message: 'Device security assessment completed',
        data: assessment.toJson(),
        timestamp: DateTime.now(),
      ));
      
      return assessment;
      
    } catch (e) {
      await _logSecurityEvent(SecurityEvent(
        type: SecurityEventType.securityError,
        severity: SecuritySeverity.error,
        message: 'Security assessment failed: $e',
        timestamp: DateTime.now(),
      ));
      
      throw SecurityException('Security assessment failed: $e');
    }
  }

  /// Authenticate user with biometrics or device credentials
  Future<AuthenticationResult> authenticateUser({
    String? reason,
    bool allowDeviceCredentials = true,
    bool requireBiometric = false,
  }) async {
    await _ensureInitialized();

    try {
      // Check if biometric authentication is preferred
      final biometricPreferred = await _secureStorage.getBiometricPreference();
      
      if (requireBiometric || biometricPreferred) {
        // Check biometric availability
        final isAvailable = await _localAuth.canCheckBiometrics;
        final isDeviceSupported = await _localAuth.isDeviceSupported();
        
        if (!isAvailable || !isDeviceSupported) {
          if (requireBiometric) {
            return AuthenticationResult(
              success: false,
              errorMessage: 'Biometric authentication not available',
              authMethod: AuthenticationMethod.none,
            );
          }
          // Fall back to device credentials if allowed
        } else {
          // Attempt biometric authentication
          final availableBiometrics = await _localAuth.getAvailableBiometrics();
          
          final authenticated = await _localAuth.authenticate(
            localizedReason: reason ?? 'Please authenticate to access your health data',
            authMessages: <AuthMessages>[
              const AndroidAuthMessages(
                signInTitle: 'Starbound Authentication',
                biometricHint: 'Touch the fingerprint sensor',
                biometricNotRecognized: 'Biometric not recognized, please try again',
                biometricSuccess: 'Biometric authentication successful',
                cancelButton: 'Cancel',
                deviceCredentialsRequiredTitle: 'Device credentials required',
                deviceCredentialsSetupDescription: 'Please set up device credentials',
                goToSettingsButton: 'Go to Settings',
                goToSettingsDescription: 'Set up biometric authentication',
              ),
            ],
            options: AuthenticationOptions(
              biometricOnly: requireBiometric,
              stickyAuth: true,
              sensitiveTransaction: true,
              useErrorDialogs: true,
            ),
          );

          if (authenticated) {
            await _logSecurityEvent(SecurityEvent(
              type: SecurityEventType.userAuthenticated,
              severity: SecuritySeverity.info,
              message: 'User authenticated successfully with biometrics',
              data: {'method': 'biometric', 'types': availableBiometrics.toString()},
              timestamp: DateTime.now(),
            ));
            
            return AuthenticationResult(
              success: true,
              authMethod: AuthenticationMethod.biometric,
              biometricTypes: availableBiometrics,
            );
          }
        }
      }

      // Fall back to device credentials if allowed
      if (allowDeviceCredentials && !requireBiometric) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: reason ?? 'Please authenticate to access your health data',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            sensitiveTransaction: true,
            useErrorDialogs: true,
          ),
        );

        if (authenticated) {
          await _logSecurityEvent(SecurityEvent(
            type: SecurityEventType.userAuthenticated,
            severity: SecuritySeverity.info,
            message: 'User authenticated successfully with device credentials',
            data: {'method': 'device_credentials'},
            timestamp: DateTime.now(),
          ));
          
          return AuthenticationResult(
            success: true,
            authMethod: AuthenticationMethod.deviceCredentials,
          );
        }
      }

      // Authentication failed
      await _logSecurityEvent(SecurityEvent(
        type: SecurityEventType.authenticationFailed,
        severity: SecuritySeverity.warning,
        message: 'User authentication failed',
        timestamp: DateTime.now(),
      ));

      return AuthenticationResult(
        success: false,
        errorMessage: 'Authentication failed',
        authMethod: AuthenticationMethod.none,
      );

    } catch (e) {
      await _logSecurityEvent(SecurityEvent(
        type: SecurityEventType.securityError,
        severity: SecuritySeverity.error,
        message: 'Authentication error: $e',
        timestamp: DateTime.now(),
      ));

      return AuthenticationResult(
        success: false,
        errorMessage: 'Authentication error: $e',
        authMethod: AuthenticationMethod.none,
      );
    }
  }

  /// Validate security policy compliance
  Future<PolicyComplianceResult> validatePolicyCompliance() async {
    await _ensureInitialized();

    final result = PolicyComplianceResult();
    final violations = <String>[];

    try {
      // Check minimum security level
      if (_currentSecurityLevel == SecurityLevel.low || 
          _currentSecurityLevel == SecurityLevel.unknown) {
        violations.add('Device security level below minimum requirements');
      }

      // Check for detected threats
      if (_detectedThreats.isNotEmpty) {
        violations.add('Active security threats detected');
      }

      // Check encryption requirements
      final deviceEncrypted = await _checkDeviceEncryption();
      if (!deviceEncrypted) {
        violations.add('Device encryption not enabled');
      }

      // Check screen lock
      final hasScreenLock = await _checkScreenLock();
      if (!hasScreenLock) {
        violations.add('Screen lock not configured');
      }

      // Check for development/debugging tools in production
      if (!kDebugMode) {
        final devToolsDetected = await _checkDevelopmentTools();
        if (devToolsDetected) {
          violations.add('Development tools detected in production');
        }
      }

      result.isCompliant = violations.isEmpty;
      result.violations = violations;
      result.assessmentTime = DateTime.now();

      await _logSecurityEvent(SecurityEvent(
        type: SecurityEventType.policyValidation,
        severity: result.isCompliant ? SecuritySeverity.info : SecuritySeverity.warning,
        message: result.isCompliant 
            ? 'Policy compliance validation passed'
            : 'Policy compliance violations detected',
        data: {'violations': violations},
        timestamp: DateTime.now(),
      ));

      return result;

    } catch (e) {
      throw SecurityException('Policy compliance validation failed: $e');
    }
  }

  /// Generate security report
  Future<SecurityReport> generateSecurityReport() async {
    await _ensureInitialized();

    final deviceAssessment = await assessDeviceSecurityy();
    final policyCompliance = await validatePolicyCompliance();
    
    final report = SecurityReport(
      reportId: _generateReportId(),
      generatedAt: DateTime.now(),
      deviceAssessment: deviceAssessment,
      policyCompliance: policyCompliance,
      detectedThreats: List.from(_detectedThreats),
      recentSecurityEvents: _getRecentSecurityEvents(),
      recommendations: _generateSecurityRecommendations(deviceAssessment),
    );

    await _logSecurityEvent(SecurityEvent(
      type: SecurityEventType.reportGenerated,
      severity: SecuritySeverity.info,
      message: 'Security report generated',
      data: {'report_id': report.reportId},
      timestamp: DateTime.now(),
    ));

    return report;
  }

  /// Check device encryption status
  Future<bool> _checkDeviceEncryption() async {
    try {
      if (Platform.isAndroid) {
        // Android-specific encryption check
        final androidInfo = await _deviceInfo.androidInfo;
        // This would require platform-specific implementation
        return true; // Assume encrypted for now
      } else if (Platform.isIOS) {
        // iOS devices are encrypted by default
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check screen lock status
  Future<bool> _checkScreenLock() async {
    try {
      // This uses local_auth to check if device credentials are set up
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Check biometric availability
  Future<bool> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Check for device compromise (root/jailbreak)
  Future<bool> _checkDeviceCompromise() async {
    try {
      // Check for common rooting/jailbreaking indicators
      final suspiciousFiles = [
        '/system/app/Superuser.apk',
        '/system/xbin/su',
        '/system/bin/su',
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
      ];

      for (final file in suspiciousFiles) {
        if (await File(file).exists()) {
          return true;
        }
      }

      // Check for debugging flags
      if (kDebugMode) {
        // Allow in debug mode
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check app integrity
  Future<bool> _checkAppIntegrity() async {
    try {
      // This would verify app signature and checksums
      // For now, assume valid
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check network security
  Future<bool> _checkNetworkSecurity() async {
    try {
      // Check if connected to secure network
      // This would require network_info_plus plugin
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check for development tools
  Future<bool> _checkDevelopmentTools() async {
    try {
      return kDebugMode;
    } catch (e) {
      return false;
    }
  }

  /// Calculate overall security score
  double _calculateSecurityScore(SecurityAssessment assessment) {
    double score = 0.0;
    
    if (assessment.isDeviceEncrypted) score += 20;
    if (assessment.hasScreenLock) score += 20;
    if (assessment.biometricAvailable) score += 15;
    if (!assessment.isDeviceCompromised) score += 25;
    if (assessment.appIntegrityValid) score += 10;
    if (assessment.networkSecure) score += 5;
    if (!assessment.developmentToolsDetected) score += 5;
    
    return score;
  }

  /// Determine security level from score
  SecurityLevel _determineSecurityLevel(double score) {
    if (score >= 80) return SecurityLevel.high;
    if (score >= 60) return SecurityLevel.medium;
    if (score >= 40) return SecurityLevel.low;
    return SecurityLevel.critical;
  }

  /// Assess current security level
  Future<void> _assessSecurityLevel() async {
    try {
      final assessment = await assessDeviceSecurityy();
      _currentSecurityLevel = assessment.securityLevel;
    } catch (e) {
      _currentSecurityLevel = SecurityLevel.unknown;
    }
  }

  /// Start security monitoring
  void _startSecurityMonitoring() {
    _securityMonitoringTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _performSecurityScan(),
    );
  }

  /// Perform periodic security scan
  Future<void> _performSecurityScan() async {
    try {
      // Check for new threats
      await _scanForThreats();
      
      // Validate policy compliance
      await validatePolicyCompliance();
      
      // Clean old log entries
      _cleanOldLogEntries();
      
    } catch (e) {
      await _logSecurityEvent(SecurityEvent(
        type: SecurityEventType.securityError,
        severity: SecuritySeverity.error,
        message: 'Security scan failed: $e',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Scan for security threats
  Future<void> _scanForThreats() async {
    // This would implement threat detection logic
    // For now, just check basic security indicators
  }

  /// Generate security recommendations
  List<String> _generateSecurityRecommendations(SecurityAssessment assessment) {
    final recommendations = <String>[];

    if (!assessment.isDeviceEncrypted) {
      recommendations.add('Enable device encryption for enhanced data protection');
    }

    if (!assessment.hasScreenLock) {
      recommendations.add('Set up a screen lock (PIN, password, or pattern)');
    }

    if (!assessment.biometricAvailable) {
      recommendations.add('Enable biometric authentication for convenient access');
    }

    if (assessment.isDeviceCompromised) {
      recommendations.add('Device appears compromised - consider security reset');
    }

    if (assessment.securityScore < 70) {
      recommendations.add('Review and improve overall device security settings');
    }

    return recommendations;
  }

  /// Get recent security events
  List<SecurityEvent> _getRecentSecurityEvents() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    
    return _securityLog
        .where((event) => event.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Generate report ID
  String _generateReportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'security_report_$timestamp';
  }

  /// Log security event
  Future<void> _logSecurityEvent(SecurityEvent event) async {
    _securityLog.add(event);
    _securityEventController?.add(event);
    
    // Store in secure storage for persistence
    try {
      await _secureStorage.storePrivacySettings({
        'last_security_event': event.toJson(),
        'event_timestamp': event.timestamp.toIso8601String(),
      });
    } catch (e) {
      // Continue even if logging fails
    }
  }

  /// Clean old log entries
  void _cleanOldLogEntries() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _securityLog.removeWhere((event) => event.timestamp.isBefore(cutoff));
  }

  /// Ensure initialization
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    _securityMonitoringTimer?.cancel();
    await _securityEventController?.close();
    _secureHttp.dispose();
  }
}

/// Security assessment result
class SecurityAssessment {
  bool isDeviceEncrypted = false;
  bool hasScreenLock = false;
  bool biometricAvailable = false;
  bool isDeviceCompromised = false;
  bool appIntegrityValid = false;
  bool networkSecure = false;
  bool developmentToolsDetected = false;
  double securityScore = 0.0;
  SecurityLevel securityLevel = SecurityLevel.unknown;

  Map<String, dynamic> toJson() => {
    'device_encrypted': isDeviceEncrypted,
    'screen_lock': hasScreenLock,
    'biometric_available': biometricAvailable,
    'device_compromised': isDeviceCompromised,
    'app_integrity': appIntegrityValid,
    'network_secure': networkSecure,
    'dev_tools_detected': developmentToolsDetected,
    'security_score': securityScore,
    'security_level': securityLevel.toString(),
  };
}

/// Authentication result
class AuthenticationResult {
  final bool success;
  final String? errorMessage;
  final AuthenticationMethod authMethod;
  final List<BiometricType>? biometricTypes;

  const AuthenticationResult({
    required this.success,
    this.errorMessage,
    required this.authMethod,
    this.biometricTypes,
  });
}

/// Policy compliance result
class PolicyComplianceResult {
  bool isCompliant = false;
  List<String> violations = [];
  DateTime? assessmentTime;
}

/// Security report
class SecurityReport {
  final String reportId;
  final DateTime generatedAt;
  final SecurityAssessment deviceAssessment;
  final PolicyComplianceResult policyCompliance;
  final List<SecurityThreat> detectedThreats;
  final List<SecurityEvent> recentSecurityEvents;
  final List<String> recommendations;

  const SecurityReport({
    required this.reportId,
    required this.generatedAt,
    required this.deviceAssessment,
    required this.policyCompliance,
    required this.detectedThreats,
    required this.recentSecurityEvents,
    required this.recommendations,
  });
}

/// Security event
class SecurityEvent {
  final SecurityEventType type;
  final SecuritySeverity severity;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const SecurityEvent({
    required this.type,
    required this.severity,
    required this.message,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'severity': severity.toString(),
    'message': message,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Security threat
class SecurityThreat {
  final String id;
  final ThreatType type;
  final ThreatSeverity severity;
  final String description;
  final DateTime detectedAt;
  final bool isActive;

  const SecurityThreat({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.detectedAt,
    this.isActive = true,
  });
}

/// Enums
enum SecurityLevel { unknown, critical, low, medium, high }
enum AuthenticationMethod { none, deviceCredentials, biometric }
enum SecurityEventType {
  systemInitialized,
  userAuthenticated,
  authenticationFailed,
  securityAssessment,
  policyValidation,
  threatDetected,
  reportGenerated,
  securityError,
}
enum SecuritySeverity { info, warning, error, critical }
enum ThreatType { malware, dataExposure, networkAttack, deviceCompromise }
enum ThreatSeverity { low, medium, high, critical }
