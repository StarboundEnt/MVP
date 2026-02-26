import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'user_service.dart';
import '../models/complexity_profile.dart';

enum SyncActionType {
  updateHabit,
  updateMultipleHabits,
  bankNudge,
  updateComplexityProfile,
  updateUserProfile,
  createCustomHabit,
  removeCustomHabit,
  submitFeedback,
}

class SyncAction {
  final String id;
  final SyncActionType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  SyncAction({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      id: json['id'],
      type: SyncActionType.values[json['type']],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }

  SyncAction withRetry() {
    return SyncAction(
      id: id,
      type: type,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount + 1,
    );
  }
}

class SyncService {
  static const String _queueKey = 'sync_queue';
  static const String _lastSyncKey = 'last_sync_time';
  static const int maxRetries = 3;
  
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final UserService _userService = UserService();
  
  List<SyncAction> _pendingActions = [];
  bool _isSyncing = false;
  
  // Performance optimization: Debounce timers
  Timer? _saveTimer;
  Timer? _syncTimer;
  static const _debounceDelay = Duration(milliseconds: 500);
  
  // Callbacks for UI updates
  VoidCallback? onSyncStarted;
  VoidCallback? onSyncCompleted;
  Function(String)? onSyncError;
  Function(int)? onSyncProgress;

  // Initialize the sync service
  Future<void> initialize() async {
    await _loadPendingActions();
  }

  // Add action to sync queue with deduplication
  Future<void> queueAction(SyncActionType type, Map<String, dynamic> data) async {
    // Performance optimization: Remove duplicate actions of the same type
    if (type == SyncActionType.updateHabit || type == SyncActionType.updateMultipleHabits) {
      _pendingActions.removeWhere((action) => 
        action.type == SyncActionType.updateHabit || 
        action.type == SyncActionType.updateMultipleHabits
      );
    }
    
    final action = SyncAction(
      id: _generateId(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );

    _pendingActions.add(action);
    
    // Performance optimization: Batch save operations
    _debouncedSave();
    
    debugPrint('Queued sync action: ${type.name} with data: $data');
    
    // Try to sync immediately if online (with debounce)
    if (!_isSyncing && await _userService.isServerAvailable()) {
      _debouncedSync();
    }
  }

  // Check if there are pending actions
  bool get hasPendingActions => _pendingActions.isNotEmpty;
  
  // Get pending actions count
  int get pendingActionsCount => _pendingActions.length;

  // Manual sync trigger
  Future<bool> syncNow() async {
    if (_isSyncing) return false;
    
    return await _performSync();
  }

  // Background sync (doesn't throw errors)
  void _syncInBackground() {
    _performSync().catchError((error) {
      debugPrint('Background sync failed: $error');
      onSyncError?.call(error.toString());
    });
  }

  // Perform actual sync
  Future<bool> _performSync() async {
    if (_isSyncing || _pendingActions.isEmpty) return true;
    
    // Check if backend is available
    if (!await _userService.isServerAvailable()) {
      debugPrint('Backend not available, skipping sync');
      return false;
    }

    if (!_userService.isLoggedIn) {
      debugPrint('User not logged in, skipping sync');
      return false;
    }

    _isSyncing = true;
    onSyncStarted?.call();
    
    final actionsToSync = List<SyncAction>.from(_pendingActions);
    final failedActions = <SyncAction>[];
    int processedCount = 0;

    try {
      for (final action in actionsToSync) {
        try {
          final success = await _executeSyncAction(action);
          if (success) {
            _pendingActions.remove(action);
            processedCount++;
            onSyncProgress?.call(processedCount);
          } else {
            // Retry logic
            if (action.retryCount < maxRetries) {
              final retryAction = action.withRetry();
              failedActions.add(retryAction);
              debugPrint('Retrying action ${action.id}, attempt ${retryAction.retryCount}');
            } else {
              debugPrint('Max retries reached for action ${action.id}, removing from queue');
              _pendingActions.remove(action);
            }
          }
        } catch (e) {
          debugPrint('Error executing sync action ${action.id}: $e');
          if (action.retryCount < maxRetries) {
            failedActions.add(action.withRetry());
          } else {
            _pendingActions.remove(action);
          }
        }
      }

      // Add failed actions back for retry
      _pendingActions.addAll(failedActions);
      
      // Save updated queue
      await _savePendingActions();
      
      // Update last sync time
      await _updateLastSyncTime();
      
      onSyncCompleted?.call();
      debugPrint('Sync completed. Processed: $processedCount, Remaining: ${_pendingActions.length}');
      
      return _pendingActions.isEmpty;
      
    } catch (e) {
      debugPrint('Sync process failed: $e');
      onSyncError?.call(e.toString());
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // Execute individual sync action
  Future<bool> _executeSyncAction(SyncAction action) async {
    try {
      switch (action.type) {
        case SyncActionType.updateHabit:
          await _apiService.updateDailyHabits(
            userId: _userService.currentUserId!,
            habits: Map<String, String?>.from(action.data['habits']),
          );
          break;
          
        case SyncActionType.updateMultipleHabits:
          await _apiService.updateDailyHabits(
            userId: _userService.currentUserId!,
            habits: Map<String, String?>.from(action.data['habits']),
          );
          break;
          
        case SyncActionType.bankNudge:
          await _apiService.bankNudge(
            userId: _userService.currentUserId!,
            nudgeId: action.data['nudgeId'],
          );
          break;
          
        case SyncActionType.updateComplexityProfile:
          await _userService.updateProfile(
            complexityProfile: _parseComplexityLevel(action.data['profile']),
          );
          break;
          
        case SyncActionType.updateUserProfile:
          await _userService.updateProfile(
            displayName: action.data['displayName'],
          );
          break;
          
        case SyncActionType.createCustomHabit:
          // Note: This would require backend support for custom habits
          // For now, we'll just mark as synced since it's stored locally
          debugPrint('Custom habit creation sync - backend support needed');
          break;
          
        case SyncActionType.removeCustomHabit:
          // Note: This would require backend support for custom habits
          // For now, we'll just mark as synced since it's handled locally
          debugPrint('Custom habit removal sync - backend support needed');
          break;

        case SyncActionType.submitFeedback:
          await _apiService.submitFeedback(
            userId: (action.data['userId'] as int?) ?? _userService.currentUserId,
            category: action.data['category'] as String,
            message: action.data['message'] as String,
            metadata: action.data['metadata'] != null
                ? Map<String, dynamic>.from(action.data['metadata'])
                : null,
          );
          break;
      }
      
      return true;
    } catch (e) {
      debugPrint('Failed to execute sync action ${action.type.name}: $e');
      return false;
    }
  }

  // Helper method to parse complexity level from string
  ComplexityLevel _parseComplexityLevel(String levelName) {
    return ComplexityLevel.values.firstWhere(
      (level) => level.name == levelName,
      orElse: () => ComplexityLevel.stable,
    );
  }

  // Load pending actions from storage
  Future<void> _loadPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      
      if (queueJson != null) {
        final queueData = jsonDecode(queueJson) as List;
        _pendingActions = queueData
            .map((item) => SyncAction.fromJson(item))
            .toList();
        debugPrint('Loaded ${_pendingActions.length} pending sync actions');
      }
    } catch (e) {
      debugPrint('Error loading pending actions: $e');
      _pendingActions = [];
    }
  }

  // Save pending actions to storage
  Future<void> _savePendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(_pendingActions.map((a) => a.toJson()).toList());
      await prefs.setString(_queueKey, queueJson);
    } catch (e) {
      debugPrint('Error saving pending actions: $e');
    }
  }

  // Update last sync time
  Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error updating last sync time: $e');
    }
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      return lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;
    } catch (e) {
      debugPrint('Error getting last sync time: $e');
      return null;
    }
  }

  // Clear all pending actions (use with caution)
  Future<void> clearPendingActions() async {
    _pendingActions.clear();
    await _savePendingActions();
  }

  // Generate unique ID for actions
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_pendingActions.length}';
  }

  // Get sync status info
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'pendingCount': _pendingActions.length,
      'hasPendingActions': hasPendingActions,
    };
  }
  
  // Performance optimization: Debounced operations
  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_debounceDelay, () async {
      await _savePendingActions();
    });
  }
  
  void _debouncedSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(_debounceDelay, () {
      _syncInBackground();
    });
  }
  
  // Clean up timers
  void dispose() {
    _saveTimer?.cancel();
    _syncTimer?.cancel();
  }
}
