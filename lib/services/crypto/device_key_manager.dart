import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds metadata about the device-scoped key material.
class DeviceKeyMaterial {
  final String keyId;
  final String publicKey;
  final String fingerprint;

  const DeviceKeyMaterial({
    required this.keyId,
    required this.publicKey,
    required this.fingerprint,
  });
}

/// Manages generation and persistence of device-scoped keys for E2EE.
class DeviceKeyManager {
  static const String _keySeedStorageKey = 'starbound_secure_device_key_seed';
  static const String _publicKeyStorageKey = 'starbound_secure_device_public_key';
  static const String _fingerprintStorageKey = 'starbound_secure_device_fingerprint';
  static const String _keyIdStorageKey = 'starbound_secure_device_key_id';

  final FlutterSecureStorage _secureStorage;
  DeviceKeyMaterial? _cachedMaterial;

  DeviceKeyManager({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  /// Ensures a stable device keypair exists and returns its metadata.
  Future<DeviceKeyMaterial> ensureKeyMaterial() async {
    if (_cachedMaterial != null) {
      return _cachedMaterial!;
    }

    final existingSeed = await _secureStorage.read(key: _keySeedStorageKey);
    final existingPublicKey = await _secureStorage.read(key: _publicKeyStorageKey);
    final existingFingerprint = await _secureStorage.read(key: _fingerprintStorageKey);
    final existingKeyId = await _secureStorage.read(key: _keyIdStorageKey);

    if (existingSeed != null &&
        existingPublicKey != null &&
        existingFingerprint != null &&
        existingKeyId != null) {
      _cachedMaterial = DeviceKeyMaterial(
        keyId: existingKeyId,
        publicKey: existingPublicKey,
        fingerprint: existingFingerprint,
      );
      return _cachedMaterial!;
    }

    final seed = IV.fromSecureRandom(32);
    final seedBase64 = base64Encode(seed.bytes);
    final digest = sha256.convert(seed.bytes);
    final fingerprint = digest.toString();
    final publicKey = base64Encode(digest.bytes);
    final keyId = 'device-${DateTime.now().millisecondsSinceEpoch}';

    await _secureStorage.write(key: _keySeedStorageKey, value: seedBase64);
    await _secureStorage.write(key: _publicKeyStorageKey, value: publicKey);
    await _secureStorage.write(key: _fingerprintStorageKey, value: fingerprint);
    await _secureStorage.write(key: _keyIdStorageKey, value: keyId);

    _cachedMaterial = DeviceKeyMaterial(
      keyId: keyId,
      publicKey: publicKey,
      fingerprint: fingerprint,
    );
    return _cachedMaterial!;
  }
}
