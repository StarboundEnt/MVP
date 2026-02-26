import 'dart:convert';

import 'payload_context.dart';

/// Defines how request/response bodies are encrypted and decrypted.
abstract class SecurePayloadTransformer {
  /// Content-type emitted for encrypted payloads.
  String get contentType;

  /// Encrypts the supplied JSON-serialisable payload.
  Future<String> encrypt(
    Map<String, dynamic> payload, {
    required PayloadContext context,
  });

  /// Decrypts the supplied encrypted payload back into a JSON string.
  Future<String> decrypt(
    String payload, {
    required PayloadContext context,
  });
}

/// Default payload transformer that keeps legacy base64 behaviour.
class Base64PayloadTransformer implements SecurePayloadTransformer {
  const Base64PayloadTransformer();

  @override
  String get contentType => 'application/x-starbound-encrypted';

  @override
  Future<String> encrypt(
    Map<String, dynamic> payload, {
    required PayloadContext context,
  }) async {
    final jsonString = jsonEncode(payload);
    final bytes = utf8.encode(jsonString);
    return base64Encode(bytes);
  }

  @override
  Future<String> decrypt(
    String payload, {
    required PayloadContext context,
  }) async {
    final encryptedBytes = base64Decode(payload);
    return utf8.decode(encryptedBytes);
  }
}
