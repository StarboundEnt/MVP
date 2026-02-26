import '../models/user_profile_payload.dart';
import 'api_service.dart';

DateTime _parseTimestamp(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim())?.toUtc() ?? DateTime.now().toUtc();
  }
  return DateTime.now().toUtc();
}

class RevokeSessionsResult {
  final List<String> revokedSessionIds;
  final List<SessionSummary> activeSessions;

  const RevokeSessionsResult({
    required this.revokedSessionIds,
    required this.activeSessions,
  });
}

class DataExportJob {
  final String jobId;
  final String status;
  final DateTime requestedAt;

  const DataExportJob({
    required this.jobId,
    required this.status,
    required this.requestedAt,
  });
}

class UserProfileService {
  UserProfileService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<UserProfilePayload> fetchProfile({String? userId}) async {
    final response = await _apiService.fetchUserProfile(userId: userId);
    return UserProfilePayload.fromJson(response);
  }

  Future<UserProfilePayload> updateProfile({
    String? displayName,
    String? timeZone,
    String? userId,
  }) async {
    final response = await _apiService.updateUserProfileDetails(
      displayName: displayName,
      timeZone: timeZone,
      userId: userId,
    );
    return UserProfilePayload.fromJson(response);
  }

  Future<RevokeSessionsResult> revokeSessions({
    required List<String> sessionIds,
    String? userId,
  }) async {
    final response = await _apiService.revokeUserSessions(
      sessionIds: sessionIds,
      userId: userId,
    );

    final revoked = List<String>.from(response['revokedSessionIds'] ?? const []);
    final activeSessionsRaw =
        (response['activeSessions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SessionSummary.fromJson)
            .toList(growable: false);

    return RevokeSessionsResult(
      revokedSessionIds: revoked,
      activeSessions: activeSessionsRaw,
    );
  }

  Future<DataExportJob> requestDataExport({String? userId}) async {
    final response =
        await _apiService.requestUserDataExport(userId: userId);

    return DataExportJob(
      jobId: response['jobId'] as String? ?? '',
      status: response['status'] as String? ?? 'queued',
      requestedAt: _parseTimestamp(response['requestedAt']),
    );
  }
}
