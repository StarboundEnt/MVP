import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ErrorType {
  network,
  storage,
  validation,
  authentication,
  permission,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  
  AppError({
    required this.type,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now();
  
  @override
  String toString() {
    return 'AppError(type: $type, message: $message, timestamp: $timestamp)';
  }
}

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();
  
  final List<AppError> _errorHistory = [];
  
  // Error handlers
  void handleError(dynamic error, {
    StackTrace? stackTrace,
    String? context,
    ErrorType? type,
    String? userMessage,
  }) {
    final appError = _createAppError(error, stackTrace, context, type, userMessage);
    _logError(appError);
    _addToHistory(appError);
  }
  
  AppError _createAppError(
    dynamic error,
    StackTrace? stackTrace,
    String? context,
    ErrorType? type,
    String? userMessage,
  ) {
    String message;
    ErrorType errorType;
    String? friendlyMessage;
    
    // Determine error type and message
    if (error is PlatformException) {
      errorType = _mapPlatformError(error.code);
      message = 'Platform error: ${error.message}';
      friendlyMessage = _getFriendlyMessage(errorType, error.code);
    } else if (error is FormatException) {
      errorType = ErrorType.validation;
      message = 'Format error: ${error.message}';
      friendlyMessage = 'Invalid data format. Please try again.';
    } else if (error is TypeError) {
      errorType = ErrorType.unknown;
      message = 'Type error: ${error.toString()}';
      friendlyMessage = 'Something went wrong. Please try again.';
    } else if (error is StateError) {
      errorType = ErrorType.unknown;
      message = 'State error: ${error.message}';
      friendlyMessage = 'App state issue. Please restart the app.';
    } else {
      errorType = type ?? ErrorType.unknown;
      message = error.toString();
      friendlyMessage = userMessage ?? 'An unexpected error occurred.';
    }
    
    if (context != null) {
      message = '$context: $message';
    }
    
    return AppError(
      type: errorType,
      message: message,
      userMessage: friendlyMessage,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
  
  ErrorType _mapPlatformError(String code) {
    switch (code) {
      case 'network_error':
      case 'connection_failed':
        return ErrorType.network;
      case 'permission_denied':
      case 'location_permission_denied':
        return ErrorType.permission;
      case 'authentication_failed':
      case 'invalid_credentials':
        return ErrorType.authentication;
      case 'storage_error':
      case 'file_not_found':
        return ErrorType.storage;
      case 'invalid_input':
      case 'validation_failed':
        return ErrorType.validation;
      default:
        return ErrorType.unknown;
    }
  }
  
  String _getFriendlyMessage(ErrorType type, String? code) {
    switch (type) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.storage:
        return 'Unable to save data. Please try again.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.authentication:
        return 'Authentication failed. Please try again.';
      case ErrorType.permission:
        return 'Permission required. Please grant access in settings.';
      case ErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
  
  void _logError(AppError error) {
    if (kDebugMode) {
      print('🚨 [ERROR] ${error.type.name.toUpperCase()}: ${error.message}');
      if (error.stackTrace != null) {
        print('📍 Stack trace: ${error.stackTrace}');
      }
    }
    
    // In production, you might want to send errors to a logging service
    // like Firebase Crashlytics, Sentry, etc.
    // _sendToLoggingService(error);
  }
  
  void _addToHistory(AppError error) {
    _errorHistory.add(error);
    
    // Keep only last 50 errors to prevent memory issues
    if (_errorHistory.length > 50) {
      _errorHistory.removeAt(0);
    }
  }
  
  // Public methods
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);
  
  void clearHistory() {
    _errorHistory.clear();
  }
  
  bool hasRecentErrors({Duration? within}) {
    final cutoff = DateTime.now().subtract(within ?? const Duration(minutes: 5));
    return _errorHistory.any((error) => error.timestamp.isAfter(cutoff));
  }
  
  List<AppError> getRecentErrors({Duration? within}) {
    final cutoff = DateTime.now().subtract(within ?? const Duration(minutes: 5));
    return _errorHistory.where((error) => error.timestamp.isAfter(cutoff)).toList();
  }
  
  // Specific error handling methods
  static void handleNetworkError(dynamic error, [StackTrace? stackTrace]) {
    ErrorService().handleError(
      error,
      stackTrace: stackTrace,
      type: ErrorType.network,
      userMessage: 'Please check your internet connection and try again.',
    );
  }
  
  static void handleStorageError(dynamic error, [StackTrace? stackTrace]) {
    ErrorService().handleError(
      error,
      stackTrace: stackTrace,
      type: ErrorType.storage,
      userMessage: 'Unable to save data. Please try again.',
    );
  }
  
  static void handleValidationError(String message, [dynamic error]) {
    ErrorService().handleError(
      error ?? message,
      type: ErrorType.validation,
      userMessage: message,
    );
  }
  
  static void handlePermissionError(String permission, [dynamic error]) {
    ErrorService().handleError(
      error ?? 'Permission denied: $permission',
      type: ErrorType.permission,
      userMessage: 'Permission required. Please grant access in settings.',
    );
  }
  
  // Enhanced user feedback methods
  static void showUserFeedback(
    BuildContext context,
    String message, {
    ErrorType type = ErrorType.unknown,
    String? actionLabel,
    VoidCallback? action,
    Duration? duration,
  }) {
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case ErrorType.network:
        backgroundColor = Colors.orange;
        icon = Icons.wifi_off;
        break;
      case ErrorType.storage:
        backgroundColor = Colors.red;
        icon = Icons.storage;
        break;
      case ErrorType.validation:
        backgroundColor = Colors.amber;
        icon = Icons.warning_outlined;
        break;
      case ErrorType.authentication:
        backgroundColor = Colors.red[700]!;
        icon = Icons.lock_outline;
        break;
      case ErrorType.permission:
        backgroundColor = Colors.orange[700]!;
        icon = Icons.security;
        break;
      case ErrorType.unknown:
      default:
        backgroundColor = Colors.grey[700]!;
        icon = Icons.info_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: actionLabel != null && action != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: action,
              )
            : null,
      ),
    );
  }
  
  static void showSuccessFeedback(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF27AE60),
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  static void showLoadingFeedback(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF9B5DE5),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  // Sync-specific feedback
  static void showSyncFeedback(
    BuildContext context,
    String message, {
    bool isError = false,
    String? actionLabel,
    VoidCallback? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.sync_problem : Icons.sync,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.orange : const Color(0xFF00F5D4),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: actionLabel != null && action != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: action,
              )
            : null,
      ),
    );
  }
}

// Extension for easy error handling in widgets
extension ErrorHandling on Object {
  void handleError([StackTrace? stackTrace]) {
    ErrorService().handleError(this, stackTrace: stackTrace);
  }
  
  void handleErrorWithContext(String context, [StackTrace? stackTrace]) {
    ErrorService().handleError(this, stackTrace: stackTrace, context: context);
  }
}