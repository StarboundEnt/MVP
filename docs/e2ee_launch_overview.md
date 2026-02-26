# End-to-End Encryption Launch Overview

## Purpose
Summarises the hybrid (envelope) encryption path shipped in the Starbound MVP so that security, backend, and mobile teams can coordinate rollout and operations.

## Encryption Flow
- **Device key seeding**: `SecureStorageService` initialises a device-scoped key seed and fingerprint via `DeviceKeyManager`. The fingerprint is transmitted with encrypted requests so backend services can trace device provenance without seeing plaintext.
- **Session key creation**: For each encrypted request, `EnvelopePayloadTransformer` creates a 256-bit session key and IV. The request payload is AES-CBC encrypted (PKCS7 padding) and integrity-protected with an HMAC-SHA256 combining the request ID and ciphertext.
- **Server key hand-off**: The session key is wrapped with the production Complexity Profile RSA public key (`E2EE_SERVER_PUBLIC_KEY`) and shipped alongside the ciphertext envelope. Backend decrypts the session key using the matching private key and key ID.
- **Response handling**: The transformer caches session keys per `X-Request-ID` so responses tagged with `application/x-starbound-envelope+json` can be decrypted without exposing symmetric material outside the app process. Plain JSON responses automatically release the session key when the map exceeds the configured capacity.

## Configuration
Set the following keys in bundled `.env` files or secret managers before production deploy:

| Key | Description |
| --- | --- |
| `E2EE_MODE` | `base64` (default) or `envelope` to enable hybrid encryption. |
| `E2EE_SERVER_KEY_ID` | Stable identifier for the active backend RSA key (e.g., `prod-key-2024-01`). |
| `E2EE_SERVER_PUBLIC_KEY` | PEM-encoded RSA public key used to unwrap session keys. |

If the mode is `envelope` but key values are absent, the app falls back to Base64 bodies and logs a warning so builds stay functional.

## Operational Considerations
- Rotate the backend RSA key by updating both the PEM and key ID, then forcing clients to refresh configuration via OTA or app update.
- Session cache defaults to 32 outstanding requests. Increase after load testing if high-concurrency scenarios drop responses, or ensure backend echoes `X-Request-ID` so the cache hit rate stays high.
- Envelope responses inherit the request’s `X-Request-ID`. Backend services must persist and echo this header to allow mobile clients to decrypt return payloads.
- Upload APIs are still streamed in plaintext. Plan follow-up stories to stream-encrypt multipart bodies or limit uploads to non-sensitive assets until server and client agree on a format.
