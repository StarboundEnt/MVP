/// Secure secrets management for API keys and sensitive configuration
/// Handles loading secrets from environment variables and secure storage
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'app_config.dart';

class SecretsManager {
  static const _storage = FlutterSecureStorage();

  // Secret keys
  static const String _geminiApiKeyKey = 'GEMINI_API_KEY';
  static const String _apiSigningKeyKey = 'API_SIGNING_KEY';
  static const String _encryptionKeyKey = 'ENCRYPTION_KEY';

  // Cached secrets (in-memory only, not persisted)
  static String? _cachedGeminiApiKey;
  static String? _cachedApiSigningKey;
  static String? _cachedEncryptionKey;

  /// Initialize secrets from environment and secure storage
  static Future<void> initialize() async {
    // Load Gemini API key
    _cachedGeminiApiKey = await _loadSecret(
      _geminiApiKeyKey,
      envKey: 'GEMINI_API_KEY',
      fallback: const String.fromEnvironment('GEMINI_API_KEY'),
    );

    // Load API signing key (for request authentication)
    _cachedApiSigningKey = await _loadSecret(
      _apiSigningKeyKey,
      envKey: 'API_SIGNING_KEY',
      fallback: const String.fromEnvironment('API_SIGNING_KEY'),
    );

    // Load encryption key (for local data encryption)
    _cachedEncryptionKey = await _loadSecret(
      _encryptionKeyKey,
      envKey: 'ENCRYPTION_KEY',
      fallback: null, // Will generate if not found
    );

    // Generate encryption key if not exists
    if (_cachedEncryptionKey == null || _cachedEncryptionKey!.isEmpty) {
      _cachedEncryptionKey = await _generateAndStoreEncryptionKey();
    }

    if (kDebugMode && AppConfig.current.enableLogging) {
      print('SecretsManager: Initialized');
      print('- Gemini API Key: ${_cachedGeminiApiKey != null && _cachedGeminiApiKey!.isNotEmpty ? "✓" : "✗"}');
      print('- API Signing Key: ${_cachedApiSigningKey != null && _cachedApiSigningKey!.isNotEmpty ? "✓" : "✗"}');
      print('- Encryption Key: ${_cachedEncryptionKey != null && _cachedEncryptionKey!.isNotEmpty ? "✓" : "✗"}');
    }
  }

  /// Get Gemini API key
  static String get geminiApiKey {
    if (_cachedGeminiApiKey == null || _cachedGeminiApiKey!.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Gemini API key not configured. AI features will use simulation mode.');
      }
      return '';
    }
    return _cachedGeminiApiKey!;
  }

  /// Get API signing key for request authentication
  static String get apiSigningKey {
    if (_cachedApiSigningKey == null || _cachedApiSigningKey!.isEmpty) {
      if (kDebugMode) {
        print('⚠️ API signing key not configured. Request signing disabled.');
      }
      return '';
    }
    return _cachedApiSigningKey!;
  }

  /// Get encryption key for local data
  static String get encryptionKey {
    if (_cachedEncryptionKey == null || _cachedEncryptionKey!.isEmpty) {
      throw Exception('Encryption key not initialized. Call SecretsManager.initialize() first.');
    }
    return _cachedEncryptionKey!;
  }

  /// Update a secret (for key rotation)
  static Future<void> updateSecret(String key, String value) async {
    await _storage.write(key: key, value: value);

    // Update cache
    switch (key) {
      case _geminiApiKeyKey:
        _cachedGeminiApiKey = value;
        break;
      case _apiSigningKeyKey:
        _cachedApiSigningKey = value;
        break;
      case _encryptionKeyKey:
        _cachedEncryptionKey = value;
        break;
    }

    if (kDebugMode && AppConfig.current.enableLogging) {
      print('SecretsManager: Updated secret: $key');
    }
  }

  /// Rotate API signing key
  static Future<String> rotateApiSigningKey() async {
    final newKey = _generateSecureKey(32);
    await updateSecret(_apiSigningKeyKey, newKey);
    return newKey;
  }

  /// Rotate encryption key (WARNING: This will invalidate all encrypted data)
  static Future<String> rotateEncryptionKey() async {
    final newKey = _generateSecureKey(32);
    await updateSecret(_encryptionKeyKey, newKey);
    return newKey;
  }

  /// Clear all secrets (for logout or security purposes)
  static Future<void> clearSecrets() async {
    await _storage.delete(key: _geminiApiKeyKey);
    await _storage.delete(key: _apiSigningKeyKey);
    await _storage.delete(key: _encryptionKeyKey);

    _cachedGeminiApiKey = null;
    _cachedApiSigningKey = null;
    _cachedEncryptionKey = null;

    if (kDebugMode && AppConfig.current.enableLogging) {
      print('SecretsManager: Cleared all secrets');
    }
  }

  /// Load a secret from secure storage or environment
  static Future<String?> _loadSecret(
    String storageKey, {
    String? envKey,
    String? fallback,
  }) async {
    try {
      // First, try secure storage
      final stored = await _storage.read(key: storageKey);
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }

      // Then, try environment variable
      if (envKey != null) {
        const envValue = String.fromEnvironment('ENV');
        if (envValue.isNotEmpty) {
          await _storage.write(key: storageKey, value: envValue);
          return envValue;
        }
      }

      // Finally, use fallback
      if (fallback != null && fallback.isNotEmpty) {
        await _storage.write(key: storageKey, value: fallback);
        return fallback;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading secret $storageKey: $e');
      }
      return fallback;
    }
  }

  /// Generate and store a new encryption key
  static Future<String> _generateAndStoreEncryptionKey() async {
    final key = _generateSecureKey(32);
    await _storage.write(key: _encryptionKeyKey, value: key);
    return key;
  }

  /// Generate a cryptographically secure random key
  static String _generateSecureKey(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      length,
      (i) => chars[(random + i * 37) % chars.length],
    ).join();
  }

  /// Check if secrets are properly configured
  static bool get isConfigured {
    return geminiApiKey.isNotEmpty &&
        (_cachedEncryptionKey != null && _cachedEncryptionKey!.isNotEmpty);
  }

  /// Get configuration status for debugging
  static Map<String, bool> get status {
    return {
      'geminiApiKey': _cachedGeminiApiKey != null && _cachedGeminiApiKey!.isNotEmpty,
      'apiSigningKey': _cachedApiSigningKey != null && _cachedApiSigningKey!.isNotEmpty,
      'encryptionKey': _cachedEncryptionKey != null && _cachedEncryptionKey!.isNotEmpty,
    };
  }
}
