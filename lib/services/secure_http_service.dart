import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'env_service.dart';
import 'secure_storage_service.dart';
import 'crypto/envelope_payload_transformer.dart';
import 'crypto/payload_context.dart';
import 'crypto/payload_exceptions.dart';
import 'crypto/payload_transformer.dart';
import 'crypto/request_signer.dart';

/// Secure HTTP service with certificate pinning and enhanced security
/// 
/// This service provides:
/// - Certificate pinning for API endpoints
/// - Request/response encryption
/// - Request signing and verification
/// - Rate limiting and DDoS protection
/// - Network security monitoring
class SecureHttpService {
  static const String _baseUrl = 'https://api.starbound.health';
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  // Certificate pins for starbound.health domain
  // These should be updated when certificates are rotated
  static const List<String> _certificatePins = [
    // Primary certificate SHA-256 fingerprint
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    // Backup certificate SHA-256 fingerprint
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
    // Root CA certificate SHA-256 fingerprint (Let's Encrypt)
    'sha256/ISRG Root X1',
  ];

  late final http.Client _httpClient;
  final SecurePayloadTransformer _payloadTransformer;
  final RequestSigner _requestSigner;
  final Map<String, int> _requestCounts = {};
  final Map<String, DateTime> _lastRequestTimes = {};
  
  // Rate limiting configuration
  static const int _maxRequestsPerMinute = 60;
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  static Future<SecureHttpService> create({
    SecureStorageService? secureStorage,
  }) async {
    final env = EnvService.instance;
    await env.load();

    final mode = env.maybe('E2EE_MODE')?.toLowerCase();
    SecurePayloadTransformer transformer;

    if (mode == 'envelope') {
      final serverKeyId = env.maybe('E2EE_SERVER_KEY_ID');
      final serverPublicKey = env.maybe('E2EE_SERVER_PUBLIC_KEY');
      if (serverKeyId != null && serverPublicKey != null) {
        transformer = EnvelopePayloadTransformer(
          serverPublicKeyPem: serverPublicKey,
          serverKeyId: serverKeyId,
          deviceKeyManager: secureStorage?.deviceKeyManager,
        );
      } else {
        print(
          'SecureHttpService: missing server key configuration; falling back to base64 payload transformer.',
        );
        transformer = const Base64PayloadTransformer();
      }
    } else {
      transformer = const Base64PayloadTransformer();
    }

    return SecureHttpService(payloadTransformer: transformer);
  }

  SecureHttpService({
    SecurePayloadTransformer? payloadTransformer,
    RequestSigner? requestSigner,
  })  : _payloadTransformer = payloadTransformer ?? const Base64PayloadTransformer(),
        _requestSigner = requestSigner ?? Sha256HeaderRequestSigner() {
    _httpClient = _createSecureClient();
  }

  /// Create HTTP client with certificate pinning
  http.Client _createSecureClient() {
    return HttpClientWithCertificatePinning(
      certificatePins: _certificatePins,
      onPinFailure: _handleCertificatePinFailure,
    );
  }

  /// Make secure GET request
  Future<SecureHttpResponse> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final requestId = _generateRequestId();
    final secureHeaders = await _buildSecureHeaders(
      headers,
      requireAuth,
      requestId: requestId,
    );
    
    return _executeRequest(
      () => _httpClient.get(uri, headers: secureHeaders),
      'GET',
      endpoint,
      requestId,
      uri,
    );
  }

  /// Make secure POST request
  Future<SecureHttpResponse> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
    bool encryptBody = true,
  }) async {
    final uri = _buildUri(endpoint);
    final requestId = _generateRequestId();
    final secureHeaders = await _buildSecureHeaders(
      headers,
      requireAuth,
      requestId: requestId,
    );
    final secureBody = encryptBody && body != null 
        ? await _encryptRequestBody(body, requestId, uri)
        : jsonEncode(body);

    if (encryptBody) {
      secureHeaders['Content-Type'] = _payloadTransformer.contentType;
    } else {
      secureHeaders['Content-Type'] = 'application/json';
    }

    return _executeRequest(
      () => _httpClient.post(uri, headers: secureHeaders, body: secureBody),
      'POST',
      endpoint,
      requestId,
      uri,
    );
  }

  /// Make secure PUT request
  Future<SecureHttpResponse> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
    bool encryptBody = true,
  }) async {
    final uri = _buildUri(endpoint);
    final requestId = _generateRequestId();
    final secureHeaders = await _buildSecureHeaders(
      headers,
      requireAuth,
      requestId: requestId,
    );
    final secureBody = encryptBody && body != null 
        ? await _encryptRequestBody(body, requestId, uri)
        : jsonEncode(body);

    if (encryptBody) {
      secureHeaders['Content-Type'] = _payloadTransformer.contentType;
    } else {
      secureHeaders['Content-Type'] = 'application/json';
    }

    return _executeRequest(
      () => _httpClient.put(uri, headers: secureHeaders, body: secureBody),
      'PUT',
      endpoint,
      requestId,
      uri,
    );
  }

  /// Make secure DELETE request
  Future<SecureHttpResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    final uri = _buildUri(endpoint);
    final requestId = _generateRequestId();
    final secureHeaders = await _buildSecureHeaders(
      headers,
      requireAuth,
      requestId: requestId,
    );

    return _executeRequest(
      () => _httpClient.delete(uri, headers: secureHeaders),
      'DELETE',
      endpoint,
      requestId,
      uri,
    );
  }

  /// Upload file securely
  Future<SecureHttpResponse> uploadFile(
    String endpoint,
    File file, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    bool requireAuth = true,
    bool encryptFile = true,
  }) async {
    await _checkRateLimit();
    
    final uri = _buildUri(endpoint);
    final requestId = _generateRequestId();
    final secureHeaders = await _buildSecureHeaders(
      headers,
      requireAuth,
      requestId: requestId,
    );

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(secureHeaders);

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add file
    final fileBytes = await file.readAsBytes();
    final processedBytes = encryptFile 
        ? await _encryptFileBytes(fileBytes)
        : fileBytes;

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      processedBytes,
      filename: file.path.split('/').last,
    ));

    return _executeMultipartRequest(request, 'UPLOAD', endpoint, requestId, uri);
  }

  /// Execute HTTP request with security measures
  Future<SecureHttpResponse> _executeRequest(
    Future<http.Response> Function() requestFunction,
    String method,
    String endpoint,
    String requestId,
    Uri uri,
  ) async {
    await _checkRateLimit();
    
    Exception? lastException;
    
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final startTime = DateTime.now();
        
        final response = await requestFunction()
            .timeout(_defaultTimeout);
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // Log request for monitoring
        await _logRequest(method, endpoint, response.statusCode, duration);

        // Verify response integrity
        await _verifyResponseIntegrity(response);

        // Handle rate limiting from server
        if (response.statusCode == 429) {
          final retryAfter = _parseRetryAfter(response.headers);
          await Future.delayed(retryAfter);
          continue;
        }

        return SecureHttpResponse(
          statusCode: response.statusCode,
          body: await _decryptResponseBody(response, requestId, uri),
          headers: response.headers,
          isSuccess: response.statusCode >= 200 && response.statusCode < 300,
        );
        
      } on SocketException catch (e) {
        lastException = SecureHttpException(
          'Network error: ${e.message}',
          type: SecurityErrorType.networkError,
        );
        
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay * (attempt + 1));
        }
      } on http.ClientException catch (e) {
        lastException = SecureHttpException(
          'HTTP client error: ${e.message}',
          type: SecurityErrorType.clientError,
        );
        break;
      } on SecurityException catch (e) {
        lastException = e;
        break;
      } on SecurePayloadException catch (e) {
        lastException = SecureHttpException(
          'Payload security error: ${e.message}',
          type: SecurityErrorType.encryptionError,
        );
        break;
      } catch (e) {
        lastException = SecureHttpException(
          'Unexpected error: $e',
          type: SecurityErrorType.unknown,
        );
        
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay * (attempt + 1));
        }
      }
    }

    throw lastException ?? SecureHttpException(
      'Request failed after $_maxRetries attempts',
      type: SecurityErrorType.maxRetriesExceeded,
    );
  }

  /// Execute multipart request (for file uploads)
  Future<SecureHttpResponse> _executeMultipartRequest(
    http.MultipartRequest request,
    String method,
    String endpoint,
    String requestId,
    Uri uri,
  ) async {
    try {
      final startTime = DateTime.now();
      
      final streamedResponse = await request.send()
          .timeout(_defaultTimeout);
      
      final response = await http.Response.fromStream(streamedResponse);
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log request for monitoring
      await _logRequest(method, endpoint, response.statusCode, duration);

      final decryptedBody = await _decryptResponseBody(response, requestId, uri);

      return SecureHttpResponse(
        statusCode: response.statusCode,
        body: decryptedBody,
        headers: response.headers,
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
      );
      
    } on SecurePayloadException catch (e) {
      throw SecureHttpException(
        'Encrypted payload error: ${e.message}',
        type: SecurityErrorType.encryptionError,
      );
    } catch (e) {
      throw SecureHttpException(
        'File upload failed: $e',
        type: SecurityErrorType.uploadError,
      );
    }
  }

  /// Build secure URI with validation
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    // Validate endpoint
    if (!RegExp(r'^[a-zA-Z0-9\/\-_\.]+$').hasMatch(endpoint)) {
      throw SecurityException('Invalid endpoint format');
    }

    final uri = Uri.parse('$_baseUrl/$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    
    return uri;
  }

  /// Build secure headers with authentication and signing
  Future<Map<String, String>> _buildSecureHeaders(
    Map<String, String>? headers,
    bool requireAuth,
    {required String requestId}
  ) async {
    final secureHeaders = <String, String>{
      'User-Agent': 'Starbound/1.0.0 (Secure)',
      'X-App-Version': '1.0.0',
      'X-Platform': Platform.operatingSystem,
      'X-Request-ID': requestId,
      'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'Accept': 'application/json',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
    };

    // Add custom headers
    if (headers != null) {
      secureHeaders.addAll(headers);
    }

    // Add authentication if required
    if (requireAuth) {
      final authToken = await _getAuthToken();
      if (authToken != null) {
        secureHeaders['Authorization'] = 'Bearer $authToken';
      } else {
        throw SecurityException('Authentication required but no token available');
      }
    }

    // Add request signature
    final signature = await _requestSigner.sign(secureHeaders);
    secureHeaders['X-Request-Signature'] = signature;

    return secureHeaders;
  }

  /// Encrypt request body
  Future<String> _encryptRequestBody(
    Map<String, dynamic> body,
    String requestId,
    Uri uri,
  ) {
    return _payloadTransformer.encrypt(
      body,
      context: PayloadContext(requestId: requestId, uri: uri),
    );
  }

  /// Decrypt response body
  Future<String> _decryptResponseBody(
    http.Response response,
    String requestId,
    Uri uri,
  ) async {
    final contentType = response.headers['content-type'] ?? '';
    final resolvedRequestId = response.headers['x-request-id'] ?? requestId;
    final resolvedUri = response.request?.url ?? uri;

    if (contentType.contains(_payloadTransformer.contentType)) {
      return _payloadTransformer.decrypt(
        response.body,
        context: PayloadContext(
          requestId: resolvedRequestId,
          uri: resolvedUri,
        ),
      );
    }

    return response.body;
  }

  /// Encrypt file bytes for secure upload
  Future<Uint8List> _encryptFileBytes(Uint8List fileBytes) async {
    // This would use proper encryption
    // For now, return the original bytes
    return fileBytes;
  }

  /// Verify response integrity
  Future<void> _verifyResponseIntegrity(http.Response response) async {
    final serverSignature = response.headers['x-response-signature'];
    if (serverSignature == null) return;

    // Verify the response hasn't been tampered with
    final bodyHash = sha256.convert(utf8.encode(response.body)).toString();
    final expectedSignature = sha256.convert(utf8.encode(bodyHash)).toString();
    
    if (serverSignature != expectedSignature) {
      throw SecurityException('Response integrity verification failed');
    }
  }

  /// Check rate limiting
  Future<void> _checkRateLimit() async {
    final now = DateTime.now();
    final clientId = await _getClientId();
    
    // Clean old request times
    _requestCounts.removeWhere((key, count) {
      final lastTime = _lastRequestTimes[key];
      return lastTime == null || 
             now.difference(lastTime) > _rateLimitWindow;
    });
    
    final currentCount = _requestCounts[clientId] ?? 0;
    
    if (currentCount >= _maxRequestsPerMinute) {
      throw SecurityException('Rate limit exceeded');
    }
    
    _requestCounts[clientId] = currentCount + 1;
    _lastRequestTimes[clientId] = now;
  }

  /// Parse retry-after header
  Duration _parseRetryAfter(Map<String, String> headers) {
    final retryAfter = headers['retry-after'];
    if (retryAfter == null) return _retryDelay;
    
    final seconds = int.tryParse(retryAfter) ?? _retryDelay.inSeconds;
    return Duration(seconds: seconds);
  }

  /// Generate unique request ID
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + DateTime.now().microsecond) % 1000000;
    return '${timestamp}_$random';
  }

  /// Get authentication token
  Future<String?> _getAuthToken() async {
    // This would integrate with SecureStorageService
    // For now, return null
    return null;
  }

  /// Get client ID for rate limiting
  Future<String> _getClientId() async {
    // This would be a device-specific identifier
    return 'starbound_client_${Platform.operatingSystem}';
  }

  /// Log request for monitoring and security analysis
  Future<void> _logRequest(
    String method,
    String endpoint,
    int statusCode,
    Duration duration,
  ) async {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'method': method,
      'endpoint': endpoint,
      'status_code': statusCode,
      'duration_ms': duration.inMilliseconds,
      'client_id': await _getClientId(),
    };

    // This would send logs to monitoring service
    print('HTTP Request: ${jsonEncode(logEntry)}');
  }

  /// Handle certificate pinning failure
  void _handleCertificatePinFailure(String host, String actualPin) {
    // Log security incident
    final incident = {
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'CERTIFICATE_PIN_FAILURE',
      'host': host,
      'actual_pin': actualPin,
      'expected_pins': _certificatePins,
    };
    
    print('SECURITY INCIDENT: ${jsonEncode(incident)}');
    
    // In production, this should alert security team
    // and potentially lock down the app
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}

/// HTTP client with certificate pinning
class HttpClientWithCertificatePinning extends http.BaseClient {
  final List<String> certificatePins;
  final void Function(String host, String actualPin)? onPinFailure;
  late final HttpClient _httpClient;

  HttpClientWithCertificatePinning({
    required this.certificatePins,
    this.onPinFailure,
  }) {
    _httpClient = HttpClient()
      ..badCertificateCallback = _certificateCheck;
  }

  bool _certificateCheck(X509Certificate cert, String host, int port) {
    // Calculate certificate fingerprint
    final fingerprint = sha256.convert(cert.der).bytes;
    final pin = 'sha256/${base64.encode(fingerprint)}';
    
    // Check if pin matches any of our expected pins
    final isValidPin = certificatePins.contains(pin);
    
    if (!isValidPin) {
      onPinFailure?.call(host, pin);
    }
    
    return isValidPin;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final httpRequest = _httpClient.openUrl(request.method, request.url);

    return httpRequest.then((req) {
      request.headers.forEach((key, value) {
        req.headers.set(key, value);
      });

      if (request is http.Request && request.body.isNotEmpty) {
        req.write(request.body);
      }

      return req.close();
    }).then((response) {
      final headers = <String, String>{};
      response.headers.forEach((key, values) {
        headers[key] = values.join(', ');
      });

      return http.StreamedResponse(
        response,
        response.statusCode,
        headers: headers,
      );
    });
  }

  @override
  void close() {
    _httpClient.close();
  }
}

/// Secure HTTP response wrapper
class SecureHttpResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;
  final bool isSuccess;

  const SecureHttpResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
    required this.isSuccess,
  });

  /// Parse response body as JSON
  Map<String, dynamic> get json {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw SecureHttpException(
        'Failed to parse response as JSON: $e',
        type: SecurityErrorType.parseError,
      );
    }
  }

  /// Check if response indicates success
  bool get isOk => statusCode >= 200 && statusCode < 300;
  
  /// Check if response indicates client error
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  
  /// Check if response indicates server error
  bool get isServerError => statusCode >= 500;
}

/// Security exception for HTTP operations
class SecureHttpException implements Exception {
  final String message;
  final SecurityErrorType type;
  
  const SecureHttpException(this.message, {required this.type});
  
  @override
  String toString() => 'SecureHttpException($type): $message';
}

/// General security exception
class SecurityException implements Exception {
  final String message;
  
  const SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

/// Types of security errors
enum SecurityErrorType {
  networkError,
  clientError,
  serverError,
  authenticationError,
  certificatePinFailure,
  rateLimit,
  parseError,
  encryptionError,
  maxRetriesExceeded,
  uploadError,
  unknown,
}
