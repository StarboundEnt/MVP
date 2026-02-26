import 'dart:convert';
import 'dart:collection';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/api.dart';

import 'device_key_manager.dart';
import 'payload_context.dart';
import 'payload_exceptions.dart';
import 'payload_transformer.dart';

/// Envelope-based payload transformer that performs hybrid encryption.
class EnvelopePayloadTransformer implements SecurePayloadTransformer {
  EnvelopePayloadTransformer({
    required String serverPublicKeyPem,
    required this.serverKeyId,
    DeviceKeyManager? deviceKeyManager,
    FlutterSecureStorage? secureStorage,
    int maxOutstandingSessions = 32,
  })  : _serverPublicKey = RSAKeyParser().parse(serverPublicKeyPem) as RSAPublicKey,
        _maxOutstandingSessions = maxOutstandingSessions,
        _deviceKeyManager = deviceKeyManager ??
            DeviceKeyManager(
              secureStorage: secureStorage ??
                  const FlutterSecureStorage(),
            );

  final RSAPublicKey _serverPublicKey;
  final String serverKeyId;
  final DeviceKeyManager _deviceKeyManager;
  final int _maxOutstandingSessions;

  final Map<String, Key> _sessionKeys = LinkedHashMap();

  @override
  String get contentType => 'application/x-starbound-envelope+json';

  @override
  Future<String> encrypt(
    Map<String, dynamic> payload, {
    required PayloadContext context,
  }) async {
    final keyMaterial = await _deviceKeyManager.ensureKeyMaterial();
    final sessionKey = Key.fromSecureRandom(32);
    final iv = IV.fromSecureRandom(16);
    final aes = Encrypter(AES(sessionKey, mode: AESMode.cbc, padding: 'PKCS7'));
    final plaintext = jsonEncode(payload);
    final encrypted = aes.encrypt(plaintext, iv: iv);

    final mac = Hmac(sha256, sessionKey.bytes).convert(
      utf8.encode('${context.requestId}|${encrypted.base64}'),
    );

    final rsa = Encrypter(
      RSA(
        publicKey: _serverPublicKey,
        encoding: RSAEncoding.OAEP,
      ),
    );
    final encryptedKey = rsa.encryptBytes(sessionKey.bytes);

    _sessionKeys[context.requestId] = sessionKey;
    _trimSessionsIfNeeded();

    final envelope = {
      'version': '1.0',
      'request_id': context.requestId,
      'server_key_id': serverKeyId,
      'device_fingerprint': keyMaterial.fingerprint,
      'encrypted_key': encryptedKey.base64,
      'ciphertext': encrypted.base64,
      'iv': iv.base64,
      'mac': base64Encode(mac.bytes),
    };

    return jsonEncode(envelope);
  }

  @override
  Future<String> decrypt(
    String payload, {
    required PayloadContext context,
  }) async {
    Map<String, dynamic>? envelope;
    try {
      envelope = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      _sessionKeys.remove(context.requestId);
      return payload;
    }

    final ciphertext = envelope['ciphertext'] as String?;
    final ivBase64 = envelope['iv'] as String?;
    final macBase64 = envelope['mac'] as String?;
    final envelopeRequestId =
        envelope['request_id'] as String? ?? context.requestId;

    if (ciphertext == null || ivBase64 == null || macBase64 == null) {
      _sessionKeys.remove(context.requestId);
      return payload;
    }

    final sessionKey = _sessionKeys.remove(envelopeRequestId);
    if (sessionKey == null) {
      throw const SecurePayloadDecryptionException(
        'Missing session key for encrypted response',
      );
    }

    final expectedMac = Hmac(sha256, sessionKey.bytes).convert(
      utf8.encode('$envelopeRequestId|$ciphertext'),
    );
    final providedMac = base64Decode(macBase64);
    if (!_constantTimeEquals(expectedMac.bytes, providedMac)) {
      throw const SecurePayloadDecryptionException('Envelope MAC mismatch');
    }

    final aes = Encrypter(AES(sessionKey, mode: AESMode.cbc, padding: 'PKCS7'));
    final iv = IV.fromBase64(ivBase64);
    final decrypted = aes.decrypt64(ciphertext, iv: iv);
    return decrypted;
  }

  void _trimSessionsIfNeeded() {
    if (_sessionKeys.length <= _maxOutstandingSessions) {
      return;
    }

    final overflow = _sessionKeys.length - _maxOutstandingSessions;
    final keysToRemove = <String>[];
    final iterator = _sessionKeys.keys.iterator;
    while (keysToRemove.length < overflow && iterator.moveNext()) {
      keysToRemove.add(iterator.current);
    }
    for (final key in keysToRemove) {
      _sessionKeys.remove(key);
    }
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
