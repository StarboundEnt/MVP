import 'package:meta/meta.dart';

/// Context describing metadata available when encrypting or decrypting payloads.
@immutable
class PayloadContext {
  final String requestId;
  final Uri uri;

  const PayloadContext({
    required this.requestId,
    required this.uri,
  });
}
