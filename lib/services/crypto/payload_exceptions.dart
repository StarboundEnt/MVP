/// Base class for payload encryption/decryption errors.
class SecurePayloadException implements Exception {
  final String message;

  const SecurePayloadException(this.message);

  @override
  String toString() => 'SecurePayloadException: $message';
}

/// Raised when decrypting an envelope fails.
class SecurePayloadDecryptionException extends SecurePayloadException {
  const SecurePayloadDecryptionException(String message) : super(message);
}
