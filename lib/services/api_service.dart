import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';
  static const String _defaultHealthUrl = 'http://127.0.0.1:8000/health';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  String? _apiKey;
  String? _configuredBaseUrl;
  String? _configuredHealthUrl;

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void configure({String? baseUrl, String? healthUrl}) {
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _configuredBaseUrl = _normalizeForApiVersion(baseUrl);
    }
    if (healthUrl != null && healthUrl.trim().isNotEmpty) {
      _configuredHealthUrl = healthUrl.trim();
    }
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_apiKey != null) {
      headers['Authorization'] = 'Bearer $_apiKey';
    }

    return headers;
  }

  String get _baseUrl => _configuredBaseUrl ?? _defaultBaseUrl;
  String get _healthUrl => _configuredHealthUrl ?? _defaultHealthUrl;

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String _normalizeForApiVersion(String value) {
    var normalized = _normalizeBaseUrl(value);

    if (normalized.endsWith('/api/v1')) {
      return normalized;
    }

    if (normalized.endsWith('/api')) {
      normalized = '$normalized/v1';
    } else if (!normalized.contains('/api/')) {
      normalized = '$normalized/api/v1';
    } else if (!normalized.endsWith('/v1')) {
      normalized = '$normalized/v1';
    }

    return _normalizeBaseUrl(normalized);
  }

  Uri _endpoint(String path) {
    final normalizedPath = path.isEmpty
        ? ''
        : path.startsWith('/')
            ? path
            : '/$path';
    return Uri.parse('${_baseUrl}$normalizedPath');
  }

  Uri _healthEndpoint() => Uri.parse(_healthUrl);

  void _logRequest(String method, String url, {Map<String, dynamic>? body}) {
    if (kDebugMode) {
      print('🌐 API Request: $method $url');
      if (body != null) {
        print('📤 Request Body: ${jsonEncode(body)}');
      }
    }
  }

  void _logResponse(String url, http.Response response) {
    if (kDebugMode) {
      print('📡 API Response: ${response.statusCode} $url');
      print('📥 Response Body: ${response.body}');
    }
  }

  void _logError(String url, dynamic error) {
    if (kDebugMode) {
      print('❌ API Error: $url - $error');
    }
  }

  // User Management
  Future<Map<String, dynamic>> createUser({
    required String username,
    required String displayName,
    required String complexityProfile,
  }) async {
    final uri = _endpoint('/users/');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'display_name': displayName,
        'complexity_profile': complexityProfile,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserByUsername(String username) async {
    final uri = _endpoint('/users/username/$username');
    final response = await _client.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      throw Exception('Failed to get user: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? displayName,
    String? complexityProfile,
    bool? notificationsEnabled,
    String? notificationTime,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (complexityProfile != null) {
      body['complexity_profile'] = complexityProfile;
    }
    if (notificationsEnabled != null) {
      body['notifications_enabled'] = notificationsEnabled;
    }
    if (notificationTime != null) body['notification_time'] = notificationTime;

    final uri = _endpoint('/users/$userId');
    final response = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  Future<void> completeOnboarding(int userId) async {
    final uri = _endpoint('/users/$userId/onboarding-complete');
    final response = await _client.post(
      uri,
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to complete onboarding: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile({String? userId}) async {
    final uri = _endpoint('/user/profile').replace(
      queryParameters: userId != null ? {'userId': userId} : null,
    );

    _logRequest('GET', uri.toString());
    try {
      final response = await _client.get(uri, headers: _headers);
      _logResponse(uri.toString(), response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch user profile: ${response.body}');
    } catch (error) {
      _logError(uri.toString(), error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserProfileDetails({
    String? displayName,
    String? timeZone,
    String? userId,
  }) async {
    final uri = _endpoint('/user/profile').replace(
      queryParameters: userId != null ? {'userId': userId} : null,
    );

    final body = <String, dynamic>{};
    if (displayName != null) {
      body['displayName'] = displayName;
    }
    if (timeZone != null) {
      body['personalization'] = {'timeZone': timeZone};
    }

    if (body.isEmpty) {
      throw ArgumentError('At least one field must be provided to update profile');
    }

    _logRequest('PATCH', uri.toString(), body: body);
    try {
      final response = await _client.patch(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      _logResponse(uri.toString(), response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to update user profile: ${response.body}');
    } catch (error) {
      _logError(uri.toString(), error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> revokeUserSessions({
    required List<String> sessionIds,
    String? userId,
  }) async {
    if (sessionIds.isEmpty) {
      throw ArgumentError('sessionIds cannot be empty');
    }

    final uri = _endpoint('/user/profile/sessions/revoke').replace(
      queryParameters: userId != null ? {'userId': userId} : null,
    );
    final body = {'sessionIds': sessionIds};

    _logRequest('POST', uri.toString(), body: body);
    try {
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      _logResponse(uri.toString(), response);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to revoke sessions: ${response.body}');
    } catch (error) {
      _logError(uri.toString(), error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestUserDataExport({String? userId}) async {
    final uri = _endpoint('/user/profile/data-export').replace(
      queryParameters: userId != null ? {'userId': userId} : null,
    );

    _logRequest('POST', uri.toString());
    try {
      final response = await _client.post(
        uri,
        headers: _headers,
      );
      _logResponse(uri.toString(), response);

      if (response.statusCode == 202 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to request data export: ${response.body}');
    } catch (error) {
      _logError(uri.toString(), error);
      rethrow;
    }
  }

  // Habit Management
  Future<List<Map<String, dynamic>>> getHabitCategories() async {
    final uri = _endpoint('/habits/categories');
    final response = await _client.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get habit categories: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateDailyHabits({
    required int userId,
    required Map<String, String?> habits,
  }) async {
    final uri = _endpoint('/habits/entries/user/$userId/daily');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'habits': habits}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update daily habits: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getUserHabitEntries(int userId) async {
    final uri = _endpoint('/habits/entries/user/$userId');
    final response = await _client.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get habit entries: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getHabitStreaks(int userId) async {
    final uri = _endpoint('/habits/analytics/user/$userId/streaks');
    final response = await _client.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get habit streaks: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getHabitTrends(int userId) async {
    final uri = _endpoint('/habits/analytics/user/$userId/trends');
    final response = await _client.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get habit trends: ${response.body}');
    }
  }

  // Nudge Management
  Future<List<Map<String, dynamic>>> getNudges({
    String? theme,
    String? complexityProfile,
    String? energyRequired,
  }) async {
    final queryParams = <String, String>{};
    if (theme != null) queryParams['theme'] = theme;
    if (complexityProfile != null) {
      queryParams['complexity_profile'] = complexityProfile;
    }
    if (energyRequired != null) {
      queryParams['energy_required'] = energyRequired;
    }

    final uri = _endpoint('/nudges/').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get nudges: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getPersonalizedRecommendation({
    required int userId,
    required Map<String, String?> currentHabits,
    required String complexityProfile,
  }) async {
    final uri = _endpoint('/nudges/recommend');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'current_habits': currentHabits,
        'complexity_profile': complexityProfile,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get recommendation: ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> getCurrentNudge(int userId) async {
    final uri = _endpoint('/nudges/user/$userId/current');
    final response = await _client.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to get current nudge: ${response.body}');
    }
  }

  Future<void> bankNudge({
    required int userId,
    required int nudgeId,
  }) async {
    final uri = _endpoint('/nudges/bank');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'user_id': userId,
        'nudge_id': nudgeId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to bank nudge: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getBankedNudges(int userId) async {
    final uri = _endpoint('/nudges/bank/user/$userId');
    final response = await _client.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get banked nudges: ${response.body}');
    }
  }

  // Chat Management
  Future<Map<String, dynamic>> askQuestion({
    required int userId,
    required String question,
    bool includeContext = true,
  }) async {
    final uri = _endpoint('/chat/ask').replace(queryParameters: {
      'user_id': userId.toString(),
    });

    final payload = {
      'query': question,
      'include_context': includeContext,
    };

    _logRequest('POST', uri.toString(), body: payload);

    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );

    final url = uri.toString();
    _logResponse(url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to ask question: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory(int userId) async {
    final uri = _endpoint('/chat/history/user/$userId');
    final response = await _client.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get chat history: ${response.body}');
    }
  }
  
  Future<List<String>> getSuggestedQuestions(int userId) async {
    final uri = _endpoint('/chat/suggestions/user/$userId');
    final response = await _client.get(
      uri,
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get suggested questions: ${response.body}');
    }
  }

  // Feedback
  Future<void> submitFeedback({
    int? userId,
    required String category,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'message': message,
      'metadata': metadata ?? {},
    };
    if (userId != null) {
      body['user_id'] = userId;
    }
    body['submitted_at'] = DateTime.now().toIso8601String();

    final response = await _client.post(
      _endpoint('/feedback'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit feedback: ${response.body}');
    }
  }
  
  // Health Check
  Future<bool> isServerHealthy() async {
    final uri = _healthEndpoint();
    final url = uri.toString();
    try {
      _logRequest('GET', url);
      final response = await _client
          .get(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 5));

      _logResponse(url, response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print('✅ Backend health check successful: ${data['status']}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print(
              '⚠️ Backend health check failed with status: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      _logError(url, e);
      if (kDebugMode) {
        print('❌ Backend health check error: $e');
      }
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
