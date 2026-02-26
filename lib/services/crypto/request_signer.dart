import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Produces request signatures to satisfy API integrity requirements.
abstract class RequestSigner {
  Future<String> sign(Map<String, String> headers);
}

/// SHA-256 signer that mirrors the legacy Starbound header signature behaviour.
class Sha256HeaderRequestSigner implements RequestSigner {
  @override
  Future<String> sign(Map<String, String> headers) async {
    final sortedHeaders = Map.fromEntries(
      headers.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    final headerString = sortedHeaders.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');

    final bytes = utf8.encode(headerString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
