import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class LoggingService {
  static const String _tag = 'StarBound';
  
  /// Log debug messages (development only)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final logTag = tag ?? _tag;
      developer.log(message, name: logTag, level: 500);
      debugPrint('🐛 [$logTag] $message');
    }
  }
  
  /// Log info messages
  static void info(String message, {String? tag}) {
    final logTag = tag ?? _tag;
    developer.log(message, name: logTag, level: 800);
    if (kDebugMode) {
      debugPrint('ℹ️ [$logTag] $message');
    }
  }
  
  /// Log warning messages
  static void warning(String message, {String? tag, Object? error}) {
    final logTag = tag ?? _tag;
    final fullMessage = error != null ? '$message: $error' : message;
    developer.log(fullMessage, name: logTag, level: 900);
    if (kDebugMode) {
      debugPrint('⚠️ [$logTag] $fullMessage');
    }
  }
  
  /// Log error messages
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logTag = tag ?? _tag;
    final fullMessage = error != null ? '$message: $error' : message;
    
    developer.log(
      fullMessage,
      name: logTag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    
    if (kDebugMode) {
      debugPrint('❌ [$logTag] $fullMessage');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
    
    // In production, you could send to crash reporting service here
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
  
  /// Log critical errors that should be reported immediately
  static void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logTag = tag ?? _tag;
    final fullMessage = 'CRITICAL: $message${error != null ? ': $error' : ''}';
    
    developer.log(
      fullMessage,
      name: logTag,
      level: 1200,
      error: error,
      stackTrace: stackTrace,
    );
    
    // Always print critical errors
    debugPrint('🔥 [$logTag] $fullMessage');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
    
    // In production, immediately report critical errors
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
  }
}