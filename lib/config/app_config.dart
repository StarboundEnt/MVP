/// Application configuration for different environments
/// Supports dev, staging, and production environments
library;

import 'package:flutter/foundation.dart';

enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  final Environment environment;
  final String appName;
  final String apiBaseUrl;
  final String geminiApiKey;
  final String complexityApiBaseUrl;
  final Duration apiTimeout;
  final bool useLocalStore;
  final bool enableLogging;
  final bool enableAnalytics;
  final bool enableCrashReporting;

  const AppConfig({
    required this.environment,
    required this.appName,
    required this.apiBaseUrl,
    required this.geminiApiKey,
    required this.complexityApiBaseUrl,
    required this.apiTimeout,
    required this.useLocalStore,
    required this.enableLogging,
    required this.enableAnalytics,
    required this.enableCrashReporting,
  });

  /// Development configuration
  static const AppConfig development = AppConfig(
    environment: Environment.development,
    appName: 'Starbound (Dev)',
    apiBaseUrl: 'http://localhost:8080',
    geminiApiKey: '', // Set via environment variable
    complexityApiBaseUrl: 'http://localhost:8080',
    apiTimeout: Duration(seconds: 30),
    useLocalStore: true,
    enableLogging: true,
    enableAnalytics: false,
    enableCrashReporting: false,
  );

  /// Staging configuration
  static const AppConfig staging = AppConfig(
    environment: Environment.staging,
    appName: 'Starbound (Staging)',
    apiBaseUrl: 'https://staging-api.starbound.app',
    geminiApiKey: '', // Set via environment variable
    complexityApiBaseUrl: 'https://staging-api.starbound.app',
    apiTimeout: Duration(seconds: 20),
    useLocalStore: false,
    enableLogging: true,
    enableAnalytics: true,
    enableCrashReporting: true,
  );

  /// Production configuration
  static const AppConfig production = AppConfig(
    environment: Environment.production,
    appName: 'Starbound',
    apiBaseUrl: 'https://api.starbound.app',
    geminiApiKey: '', // Set via environment variable
    complexityApiBaseUrl: 'https://api.starbound.app',
    apiTimeout: Duration(seconds: 15),
    useLocalStore: false,
    enableLogging: false,
    enableAnalytics: true,
    enableCrashReporting: true,
  );

  /// Get current configuration based on build mode and flavor
  static AppConfig get current {
    // Check for environment variable override
    const envOverride = String.fromEnvironment('ENV');

    if (envOverride.isNotEmpty) {
      switch (envOverride.toLowerCase()) {
        case 'dev':
        case 'development':
          return development;
        case 'staging':
          return staging;
        case 'prod':
        case 'production':
          return production;
      }
    }

    // Fallback to build mode detection
    if (kReleaseMode) {
      // In release mode, check app name suffix
      const flavor = String.fromEnvironment('FLAVOR');
      if (flavor == 'staging') {
        return staging;
      }
      return production;
    } else {
      return development;
    }
  }

  /// Helper getters
  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;

  String get ingestEndpoint => '$complexityApiBaseUrl/ingest';
  String get batchEndpoint => '$complexityApiBaseUrl/ingest/batch';
  String profileEndpoint(String userId) =>
      '$complexityApiBaseUrl/users/$userId/complexity-profile';

  @override
  String toString() {
    return 'AppConfig(environment: $environment, apiBaseUrl: $apiBaseUrl)';
  }
}
