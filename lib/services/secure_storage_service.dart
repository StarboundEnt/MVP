import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'crypto/device_key_manager.dart';

/// Secure storage service for sensitive health data
/// 
/// This service provides encrypted storage for sensitive information like:
/// - Personal health data
/// - User authentication tokens
/// - Biometric preferences
/// - Medical information
/// - Privacy settings
class SecureStorageService {
  static const String _keyPrefix = 'starbound_secure_';
  static const String _encryptionKeyName = '${_keyPrefix}encryption_key';
  static const String _healthDataKey = '${_keyPrefix}health_data';
  static const String _authTokenKey = '${_keyPrefix}auth_token';
  static const String _biometricPrefKey = '${_keyPrefix}biometric_pref';
  static const String _privacySettingsKey = '${_keyPrefix}privacy_settings';
  static const String _medicalDataKey = '${_keyPrefix}medical_data';
  
  late final FlutterSecureStorage _secureStorage;
  late final Encrypter _encrypter;
  late final DeviceKeyManager _deviceKeyManager;
  bool _isInitialized = false;

  SecureStorageService() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        sharedPreferencesName: 'starbound_secure_prefs',
        preferencesKeyPrefix: 'starbound_',
      ),
      iOptions: IOSOptions(
        groupId: 'group.starbound.app',
        accountName: 'starbound_secure_account',
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      lOptions: LinuxOptions(),
      wOptions: WindowsOptions(
        useBackwardCompatibility: true,
      ),
      mOptions: MacOsOptions(
        groupId: 'group.starbound.app',
        accountName: 'starbound_secure_account',
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    _deviceKeyManager = DeviceKeyManager(secureStorage: _secureStorage);
  }

  DeviceKeyManager get deviceKeyManager => _deviceKeyManager;
  FlutterSecureStorage get secureStorage => _secureStorage;

  /// Initialize the secure storage service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get or create encryption key
      final encryptionKey = await _getOrCreateEncryptionKey();
      final key = Key.fromBase64(encryptionKey);
      _encrypter = Encrypter(AES(key));
      await _deviceKeyManager.ensureKeyMaterial();
      
      _isInitialized = true;
    } catch (e) {
      throw SecureStorageException('Failed to initialize secure storage: $e');
    }
  }

  /// Get or create encryption key for additional data encryption
  Future<String> _getOrCreateEncryptionKey() async {
    try {
      String? existingKey = await _secureStorage.read(key: _encryptionKeyName);
      
      if (existingKey == null) {
        // Generate new 256-bit key
        final key = Key.fromSecureRandom(32);
        existingKey = key.base64;
        await _secureStorage.write(key: _encryptionKeyName, value: existingKey);
      }
      
      return existingKey;
    } catch (e) {
      throw SecureStorageException('Failed to manage encryption key: $e');
    }
  }

  IV _generateIv() => IV.fromSecureRandom(16);

  /// Store sensitive health data
  Future<void> storeHealthData(Map<String, dynamic> healthData) async {
    await _ensureInitialized();
    
    try {
      final keyMaterial = await _deviceKeyManager.ensureKeyMaterial();

      // Add metadata
      final dataWithMetadata = {
        ...healthData,
        'encrypted_at': DateTime.now().toIso8601String(),
        'data_version': '1.0',
        'integrity_hash': _calculateIntegrityHash(healthData),
        'encryption_key_id': keyMaterial.keyId,
      };

      // Encrypt the data
      final jsonString = jsonEncode(dataWithMetadata);
      final iv = _generateIv();
      final encrypted = _encrypter.encrypt(jsonString, iv: iv);
      
      // Store with additional security layers
      final securePayload = {
        'encrypted_data': encrypted.base64,
        'iv': iv.base64,
        'key_id': keyMaterial.keyId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'checksum': sha256.convert(utf8.encode(jsonString)).toString(),
      };

      await _secureStorage.write(
        key: _healthDataKey,
        value: jsonEncode(securePayload),
      );
    } catch (e) {
      throw SecureStorageException('Failed to store health data: $e');
    }
  }

  /// Retrieve sensitive health data
  Future<Map<String, dynamic>?> getHealthData() async {
    await _ensureInitialized();
    
    try {
      final encryptedPayload = await _secureStorage.read(key: _healthDataKey);
      if (encryptedPayload == null) return null;

      final payload = jsonDecode(encryptedPayload) as Map<String, dynamic>;
      final encryptedData = payload['encrypted_data'] as String;
      final ivString = payload['iv'] as String;
      final expectedChecksum = payload['checksum'] as String;

      // Decrypt the data
      final iv = IV.fromBase64(ivString);
      final encrypted = Encrypted.fromBase64(encryptedData);
      final decryptedJson = _encrypter.decrypt(encrypted, iv: iv);
      
      // Verify integrity
      final actualChecksum = sha256.convert(utf8.encode(decryptedJson)).toString();
      if (actualChecksum != expectedChecksum) {
        throw SecureStorageException('Data integrity check failed');
      }

      final decryptedData = jsonDecode(decryptedJson) as Map<String, dynamic>;
      
      // Verify data integrity hash
      final storedHash = decryptedData.remove('integrity_hash') as String?;
      final calculatedHash = _calculateIntegrityHash(decryptedData);
      
      if (storedHash != calculatedHash) {
        throw SecureStorageException('Health data integrity verification failed');
      }

      return decryptedData;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve health data: $e');
    }
  }

  /// Store authentication token securely
  Future<void> storeAuthToken(String token, {Duration? expiresIn}) async {
    await _ensureInitialized();
    
    try {
      final keyMaterial = await _deviceKeyManager.ensureKeyMaterial();
      final tokenData = {
        'token': token,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': expiresIn != null 
            ? DateTime.now().add(expiresIn).toIso8601String() 
            : null,
        'device_fingerprint': keyMaterial.fingerprint,
        'encryption_key_id': keyMaterial.keyId,
      };

      final iv = _generateIv();
      final encrypted = _encrypter.encrypt(jsonEncode(tokenData), iv: iv);
      final payload = jsonEncode({
        'ciphertext': encrypted.base64,
        'iv': iv.base64,
        'key_id': keyMaterial.keyId,
      });

      await _secureStorage.write(
        key: _authTokenKey,
        value: payload,
      );
    } catch (e) {
      throw SecureStorageException('Failed to store auth token: $e');
    }
  }

  /// Retrieve authentication token
  Future<String?> getAuthToken() async {
    await _ensureInitialized();
    
    try {
      final encryptedToken = await _secureStorage.read(key: _authTokenKey);
      if (encryptedToken == null) return null;

      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(encryptedToken) as Map<String, dynamic>;
      } catch (_) {
        await clearAuthToken();
        return null;
      }

      final ciphertext = payload['ciphertext'] as String?;
      final ivString = payload['iv'] as String?;
      if (ciphertext == null || ivString == null) {
        await clearAuthToken();
        return null;
      }

      final encrypted = Encrypted.fromBase64(ciphertext);
      final iv = IV.fromBase64(ivString);
      final decryptedJson = _encrypter.decrypt(encrypted, iv: iv);
      final tokenData = jsonDecode(decryptedJson) as Map<String, dynamic>;

      // Check if token has expired
      final expiresAtString = tokenData['expires_at'] as String?;
      if (expiresAtString != null) {
        final expiresAt = DateTime.parse(expiresAtString);
        if (DateTime.now().isAfter(expiresAt)) {
          await clearAuthToken();
          return null;
        }
      }

      // Verify device fingerprint
      final storedFingerprint = tokenData['device_fingerprint'] as String;
      final currentFingerprint = await _getDeviceFingerprint();
      if (storedFingerprint != currentFingerprint) {
        await clearAuthToken();
        throw SecureStorageException('Device fingerprint mismatch');
      }

      return tokenData['token'] as String;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve auth token: $e');
    }
  }

  /// Clear authentication token
  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: _authTokenKey);
  }

  /// Store biometric preferences
  Future<void> storeBiometricPreference(bool enabled) async {
    await _ensureInitialized();
    
    try {
      final prefData = {
        'biometric_enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _secureStorage.write(
        key: _biometricPrefKey,
        value: jsonEncode(prefData),
      );
    } catch (e) {
      throw SecureStorageException('Failed to store biometric preference: $e');
    }
  }

  /// Get biometric preferences
  Future<bool> getBiometricPreference() async {
    try {
      final prefJson = await _secureStorage.read(key: _biometricPrefKey);
      if (prefJson == null) return false;

      final prefData = jsonDecode(prefJson) as Map<String, dynamic>;
      return prefData['biometric_enabled'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Store privacy settings
  Future<void> storePrivacySettings(Map<String, dynamic> settings) async {
    await _ensureInitialized();
    
    try {
      final keyMaterial = await _deviceKeyManager.ensureKeyMaterial();
      final settingsWithMetadata = {
        ...settings,
        'updated_at': DateTime.now().toIso8601String(),
        'version': '1.0',
        'encryption_key_id': keyMaterial.keyId,
      };

      final iv = _generateIv();
      final encrypted = _encrypter.encrypt(
        jsonEncode(settingsWithMetadata), 
        iv: iv,
      );

      final payload = jsonEncode({
        'ciphertext': encrypted.base64,
        'iv': iv.base64,
        'key_id': keyMaterial.keyId,
      });

      await _secureStorage.write(
        key: _privacySettingsKey,
        value: payload,
      );
    } catch (e) {
      throw SecureStorageException('Failed to store privacy settings: $e');
    }
  }

  /// Get privacy settings
  Future<Map<String, dynamic>?> getPrivacySettings() async {
    await _ensureInitialized();
    
    try {
      final encryptedSettings = await _secureStorage.read(key: _privacySettingsKey);
      if (encryptedSettings == null) return null;

      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(encryptedSettings) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }

      final ciphertext = payload['ciphertext'] as String?;
      final ivString = payload['iv'] as String?;
      if (ciphertext == null || ivString == null) {
        return null;
      }

      final encrypted = Encrypted.fromBase64(ciphertext);
      final iv = IV.fromBase64(ivString);
      final decryptedJson = _encrypter.decrypt(encrypted, iv: iv);
      return jsonDecode(decryptedJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Store medical data
  Future<void> storeMedicalData(Map<String, dynamic> medicalData) async {
    await _ensureInitialized();
    
    try {
      final keyMaterial = await _deviceKeyManager.ensureKeyMaterial();
      // Add extra security for medical data
      final dataWithSecurity = {
        ...medicalData,
        'encrypted_at': DateTime.now().toIso8601String(),
        'classification': 'MEDICAL_SENSITIVE',
        'integrity_hash': _calculateIntegrityHash(medicalData),
        'access_logged_at': DateTime.now().toIso8601String(),
        'encryption_key_id': keyMaterial.keyId,
      };

      final iv = _generateIv();
      final encrypted = _encrypter.encrypt(
        jsonEncode(dataWithSecurity), 
        iv: iv,
      );
      
      final payload = jsonEncode({
        'ciphertext': encrypted.base64,
        'iv': iv.base64,
        'key_id': keyMaterial.keyId,
      });

      await _secureStorage.write(
        key: _medicalDataKey,
        value: payload,
      );

      // Log access for audit purposes
      await _logMedicalDataAccess('STORE');
    } catch (e) {
      throw SecureStorageException('Failed to store medical data: $e');
    }
  }

  /// Get medical data
  Future<Map<String, dynamic>?> getMedicalData() async {
    await _ensureInitialized();
    
    try {
      final encryptedData = await _secureStorage.read(key: _medicalDataKey);
      if (encryptedData == null) return null;

      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(encryptedData) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }

      final ciphertext = payload['ciphertext'] as String?;
      final ivString = payload['iv'] as String?;
      if (ciphertext == null || ivString == null) {
        return null;
      }

      final encrypted = Encrypted.fromBase64(ciphertext);
      final iv = IV.fromBase64(ivString);
      final decryptedJson = _encrypter.decrypt(encrypted, iv: iv);
      final medicalData = jsonDecode(decryptedJson) as Map<String, dynamic>;

      // Verify integrity
      final storedHash = medicalData.remove('integrity_hash') as String?;
      final calculatedHash = _calculateIntegrityHash(medicalData);
      
      if (storedHash != calculatedHash) {
        throw SecureStorageException('Medical data integrity verification failed');
      }

      // Log access for audit purposes
      await _logMedicalDataAccess('READ');

      return medicalData;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve medical data: $e');
    }
  }

  /// Check if secure storage contains key
  Future<bool> containsKey(String key) async {
    try {
      final value = await _secureStorage.read(key: '$_keyPrefix$key');
      return value != null;
    } catch (e) {
      return false;
    }
  }

  /// Get all secure storage keys
  Future<Set<String>> getAllKeys() async {
    try {
      final allKeys = await _secureStorage.readAll();
      return allKeys.keys.where((key) => key.startsWith(_keyPrefix)).toSet();
    } catch (e) {
      return <String>{};
    }
  }

  /// Clear all secure data (use with caution)
  Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to clear secure data: $e');
    }
  }

  /// Backup secure data (encrypted)
  Future<String> createSecureBackup() async {
    await _ensureInitialized();
    
    try {
      final allData = await _secureStorage.readAll();
      final starboundData = Map.fromEntries(
        allData.entries.where((entry) => entry.key.startsWith(_keyPrefix)),
      );

      final backupData = {
        'data': starboundData,
        'created_at': DateTime.now().toIso8601String(),
        'version': '1.0',
        'device_fingerprint': await _getDeviceFingerprint(),
      };

      final keyMaterial = await _deviceKeyManager.ensureKeyMaterial();
      final iv = _generateIv();
      final encrypted = _encrypter.encrypt(jsonEncode(backupData), iv: iv);
      final payload = {
        'ciphertext': encrypted.base64,
        'iv': iv.base64,
        'key_id': keyMaterial.keyId,
      };
      return jsonEncode(payload);
    } catch (e) {
      throw SecureStorageException('Failed to create secure backup: $e');
    }
  }

  /// Restore from secure backup
  Future<void> restoreFromSecureBackup(String encryptedBackup) async {
    await _ensureInitialized();
    
    try {
      final payload = jsonDecode(encryptedBackup) as Map<String, dynamic>;
      final ciphertext = payload['ciphertext'] as String;
      final ivString = payload['iv'] as String;

      final encrypted = Encrypted.fromBase64(ciphertext);
      final iv = IV.fromBase64(ivString);
      final decryptedJson = _encrypter.decrypt(encrypted, iv: iv);
      final backupData = jsonDecode(decryptedJson) as Map<String, dynamic>;

      final data = backupData['data'] as Map<String, dynamic>;
      
      // Restore each key-value pair
      for (final entry in data.entries) {
        await _secureStorage.write(key: entry.key, value: entry.value);
      }
    } catch (e) {
      throw SecureStorageException('Failed to restore from backup: $e');
    }
  }

  /// Calculate integrity hash for data verification
  String _calculateIntegrityHash(Map<String, dynamic> data) {
    final sortedData = Map.fromEntries(
      data.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final jsonString = jsonEncode(sortedData);
    return sha256.convert(utf8.encode(jsonString)).toString();
  }

  /// Get device fingerprint for additional security
  Future<String> _getDeviceFingerprint() async {
    final material = await _deviceKeyManager.ensureKeyMaterial();
    return material.fingerprint;
  }

  /// Log medical data access for audit purposes
  Future<void> _logMedicalDataAccess(String action) async {
    try {
      const auditKey = '${_keyPrefix}medical_audit_log';
      final existingLogJson = await _secureStorage.read(key: auditKey);
      
      List<Map<String, dynamic>> auditLog = [];
      if (existingLogJson != null) {
        auditLog = List<Map<String, dynamic>>.from(jsonDecode(existingLogJson));
      }

      auditLog.add({
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        'device_fingerprint': await _getDeviceFingerprint(),
      });

      // Keep only last 100 entries
      if (auditLog.length > 100) {
        auditLog = auditLog.skip(auditLog.length - 100).toList();
      }

      await _secureStorage.write(key: auditKey, value: jsonEncode(auditLog));
    } catch (e) {
      // Audit logging should not fail the main operation
      print('Failed to log medical data access: $e');
    }
  }

  /// Ensure the service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose of resources
  void dispose() {
    // Clean up any resources if needed
  }
}

/// Exception class for secure storage errors
class SecureStorageException implements Exception {
  final String message;
  
  const SecureStorageException(this.message);
  
  @override
  String toString() => 'SecureStorageException: $message';
}
