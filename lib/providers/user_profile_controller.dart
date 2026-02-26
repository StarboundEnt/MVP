import 'package:flutter/foundation.dart';

import '../models/user_profile_payload.dart';
import '../services/user_profile_service.dart';

class UserProfileController extends ChangeNotifier {
  UserProfileController({UserProfileService? service})
      : _service = service ?? UserProfileService();

  final UserProfileService _service;

  UserProfilePayload? _profile;
  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;
  String? _userId;

  UserProfilePayload? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;
  String? get activeUserId => _userId;

  Future<void> loadProfile({String? userId, bool forceRefresh = false}) async {
    final targetUserId = userId ?? _userId;
    if (!forceRefresh &&
        _profile != null &&
        targetUserId == _userId &&
        !_isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await _service.fetchProfile(userId: targetUserId);
      _profile = profile;
      _userId = targetUserId;
    } catch (error, stackTrace) {
      _error = error.toString();
      debugPrint('Failed to load profile: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Display name cannot be empty');
    }

    _setMutating(true);
    try {
      final updated = await _service.updateProfile(
        displayName: trimmed,
        userId: _userId,
      );
      _profile = updated;
    } catch (error, stackTrace) {
      _error = error.toString();
      debugPrint('Failed to update display name: $error\n$stackTrace');
      rethrow;
    } finally {
      _setMutating(false);
    }
  }

  Future<void> updateTimeZone(String timeZone) async {
    final trimmed = timeZone.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Time zone cannot be empty');
    }

    _setMutating(true);
    try {
      final updated = await _service.updateProfile(
        timeZone: trimmed,
        userId: _userId,
      );
      _profile = updated;
    } catch (error, stackTrace) {
      _error = error.toString();
      debugPrint('Failed to update time zone: $error\n$stackTrace');
      rethrow;
    } finally {
      _setMutating(false);
    }
  }

  Future<RevokeSessionsResult> revokeSessions(List<String> sessionIds) async {
    _setMutating(true);
    try {
      final result = await _service.revokeSessions(
        sessionIds: sessionIds,
        userId: _userId,
      );

      if (_profile != null) {
        final updatedSecurity =
            _profile!.security.copyWith(activeSessions: result.activeSessions);
        _profile = _profile!.copyWith(
          security: updatedSecurity,
          lastUpdatedAt: DateTime.now().toUtc(),
        );
      }

      return result;
    } catch (error, stackTrace) {
      _error = error.toString();
      debugPrint('Failed to revoke sessions: $error\n$stackTrace');
      rethrow;
    } finally {
      _setMutating(false);
    }
  }

  Future<DataExportJob> requestDataExport() async {
    _setMutating(true);
    try {
      final job = await _service.requestDataExport(userId: _userId);
      if (_profile != null) {
        final updatedCompliance =
            _profile!.compliance.copyWith(lastExportAt: job.requestedAt);
        _profile = _profile!.copyWith(
          compliance: updatedCompliance,
          lastUpdatedAt: job.requestedAt,
        );
      }
      return job;
    } catch (error, stackTrace) {
      _error = error.toString();
      debugPrint('Failed to request data export: $error\n$stackTrace');
      rethrow;
    } finally {
      _setMutating(false);
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _setMutating(bool value) {
    if (_isMutating != value) {
      _isMutating = value;
      notifyListeners();
    }
  }
}
