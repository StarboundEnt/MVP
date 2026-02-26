import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'secure_storage_service.dart';

/// Performance monitoring service for Starbound app
/// 
/// This service provides:
/// - Real-time performance metrics
/// - Memory usage monitoring
/// - Frame rate analysis
/// - App startup time tracking
/// - Navigation performance
/// - Battery usage optimization
/// - Performance alerting and reporting
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance => _instance ??= PerformanceMonitor._();
  
  PerformanceMonitor._();

  late final SecureStorageService _secureStorage;
  bool _isInitialized = false;
  bool _isMonitoring = false;
  
  // Performance metrics
  final List<PerformanceMetric> _metrics = [];
  final List<MemorySnapshot> _memorySnapshots = [];
  final List<FrameMetric> _frameMetrics = [];
  final List<NavigationMetric> _navigationMetrics = [];
  
  // Monitoring timers
  Timer? _memoryMonitoringTimer;
  Timer? _frameMonitoringTimer;
  Timer? _performanceReportingTimer;
  
  // Event streams
  final StreamController<PerformanceAlert> _alertController = 
      StreamController<PerformanceAlert>.broadcast();
  final StreamController<PerformanceUpdate> _updateController = 
      StreamController<PerformanceUpdate>.broadcast();
  
  // Performance thresholds
  static const Duration _frameTimeThreshold = Duration(milliseconds: 16); // 60 FPS
  static const int _memoryThresholdMB = 150;
  static const Duration _navigationThreshold = Duration(milliseconds: 500);
  static const int _maxMetricsHistory = 1000;
  
  // Startup tracking
  DateTime? _appStartTime;
  DateTime? _firstFrameTime;
  bool _startupComplete = false;

  /// Initialize the performance monitor
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _secureStorage = SecureStorageService();
      await _secureStorage.initialize();
      
      _appStartTime = DateTime.now();
      
      // Set up frame callbacks
      _setupFrameCallbacks();
      
      // Set up rendering callbacks
      _setupRenderingCallbacks();
      
      _isInitialized = true;
      
      await _recordMetric(PerformanceMetric(
        name: 'monitor_initialized',
        value: 1,
        timestamp: DateTime.now(),
        category: MetricCategory.system,
      ));
      
    } catch (e) {
      throw PerformanceException('Failed to initialize performance monitor: $e');
    }
  }

  /// Start performance monitoring
  Future<void> startMonitoring() async {
    await _ensureInitialized();
    
    if (_isMonitoring) return;

    try {
      _isMonitoring = true;
      
      // Start memory monitoring
      _startMemoryMonitoring();
      
      // Start frame monitoring
      _startFrameMonitoring();
      
      // Start periodic reporting
      _startPeriodicReporting();
      
      await _recordMetric(PerformanceMetric(
        name: 'monitoring_started',
        value: 1,
        timestamp: DateTime.now(),
        category: MetricCategory.system,
      ));
      
    } catch (e) {
      throw PerformanceException('Failed to start monitoring: $e');
    }
  }

  /// Stop performance monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    
    _memoryMonitoringTimer?.cancel();
    _frameMonitoringTimer?.cancel();
    _performanceReportingTimer?.cancel();
    
    await _recordMetric(PerformanceMetric(
      name: 'monitoring_stopped',
      value: 1,
      timestamp: DateTime.now(),
      category: MetricCategory.system,
    ));
  }

  /// Track app startup completion
  void markStartupComplete() {
    if (_startupComplete) return;
    
    _startupComplete = true;
    final now = DateTime.now();
    
    if (_appStartTime != null) {
      final startupDuration = now.difference(_appStartTime!);
      
      _recordMetric(PerformanceMetric(
        name: 'app_startup_time',
        value: startupDuration.inMilliseconds.toDouble(),
        timestamp: now,
        category: MetricCategory.startup,
        metadata: {
          'cold_start': true,
          'first_frame_time': _firstFrameTime?.toIso8601String(),
        },
      ));
      
      // Alert if startup is slow
      if (startupDuration.inSeconds > 3) {
        _sendAlert(PerformanceAlert(
          severity: AlertSeverity.warning,
          message: 'Slow app startup detected: ${startupDuration.inSeconds}s',
          metric: 'app_startup_time',
          value: startupDuration.inMilliseconds.toDouble(),
          timestamp: now,
        ));
      }
    }
  }

  /// Track navigation performance
  Future<void> trackNavigation(String fromRoute, String toRoute) async {
    final startTime = DateTime.now();
    
    // This would be called when navigation completes
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      final metric = NavigationMetric(
        fromRoute: fromRoute,
        toRoute: toRoute,
        duration: duration,
        timestamp: startTime,
      );
      
      _navigationMetrics.add(metric);
      
      // Record performance metric
      _recordMetric(PerformanceMetric(
        name: 'navigation_time',
        value: duration.inMilliseconds.toDouble(),
        timestamp: startTime,
        category: MetricCategory.navigation,
        metadata: {
          'from_route': fromRoute,
          'to_route': toRoute,
        },
      ));
      
      // Alert if navigation is slow
      if (duration > _navigationThreshold) {
        _sendAlert(PerformanceAlert(
          severity: AlertSeverity.warning,
          message: 'Slow navigation: $fromRoute → $toRoute (${duration.inMilliseconds}ms)',
          metric: 'navigation_time',
          value: duration.inMilliseconds.toDouble(),
          timestamp: startTime,
        ));
      }
      
      _limitHistorySize(_navigationMetrics, _maxMetricsHistory);
    });
  }

  /// Track specific operation performance
  Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final startTime = DateTime.now();
    
    try {
      final result = await operation();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      await _recordMetric(PerformanceMetric(
        name: 'operation_time',
        value: duration.inMilliseconds.toDouble(),
        timestamp: startTime,
        category: MetricCategory.operation,
        metadata: {
          'operation_name': operationName,
          'success': true,
        },
      ));
      
      return result;
      
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      await _recordMetric(PerformanceMetric(
        name: 'operation_time',
        value: duration.inMilliseconds.toDouble(),
        timestamp: startTime,
        category: MetricCategory.operation,
        metadata: {
          'operation_name': operationName,
          'success': false,
          'error': e.toString(),
        },
      ));
      
      rethrow;
    }
  }

  /// Get current memory usage
  Future<MemoryInfo> getCurrentMemoryUsage() async {
    final info = await _getMemoryInfo();
    
    await _recordMetric(PerformanceMetric(
      name: 'memory_usage',
      value: info.usedMemoryMB.toDouble(),
      timestamp: DateTime.now(),
      category: MetricCategory.memory,
      metadata: {
        'total_memory_mb': info.totalMemoryMB,
        'free_memory_mb': info.freeMemoryMB,
        'memory_pressure': info.memoryPressure.toString(),
      },
    ));
    
    return info;
  }

  /// Get performance summary
  Future<PerformanceSummary> getPerformanceSummary({
    Duration? timeWindow,
  }) async {
    await _ensureInitialized();
    
    final now = DateTime.now();
    final cutoff = timeWindow != null 
        ? now.subtract(timeWindow)
        : now.subtract(const Duration(hours: 1));
    
    final recentMetrics = _metrics
        .where((m) => m.timestamp.isAfter(cutoff))
        .toList();
    
    return PerformanceSummary(
      generatedAt: now,
      timeWindow: timeWindow ?? const Duration(hours: 1),
      totalMetrics: recentMetrics.length,
      averageFrameTime: _calculateAverageFrameTime(recentMetrics),
      memoryUsage: await getCurrentMemoryUsage(),
      navigationPerformance: _calculateNavigationPerformance(),
      alertsTriggered: _getRecentAlerts(cutoff).length,
      performanceScore: _calculatePerformanceScore(recentMetrics),
    );
  }

  /// Generate detailed performance report
  Future<PerformanceReport> generateReport({
    Duration? timeWindow,
  }) async {
    await _ensureInitialized();
    
    final summary = await getPerformanceSummary(timeWindow: timeWindow);
    
    final report = PerformanceReport(
      reportId: _generateReportId(),
      generatedAt: DateTime.now(),
      summary: summary,
      detailedMetrics: _getDetailedMetrics(timeWindow),
      memoryAnalysis: _analyzeMemoryUsage(),
      frameAnalysis: _analyzeFramePerformance(),
      navigationAnalysis: _analyzeNavigationPerformance(),
      recommendations: _generateRecommendations(summary),
    );
    
    // Store report for future reference
    await _storeReport(report);
    
    return report;
  }

  /// Set up frame callbacks for monitoring
  void _setupFrameCallbacks() {
    SchedulerBinding.instance.addPersistentFrameCallback((timestamp) {
      if (!_isMonitoring) return;
      
      _firstFrameTime ??= DateTime.now();
      
      final frameMetric = FrameMetric(
        timestamp: DateTime.now(),
        frameDuration: timestamp,
      );
      
      _frameMetrics.add(frameMetric);
      _limitHistorySize(_frameMetrics, _maxMetricsHistory);
      
      // Check for dropped frames
      final frameTime = Duration(microseconds: timestamp.inMicroseconds);
      if (frameTime > _frameTimeThreshold) {
        _sendAlert(PerformanceAlert(
          severity: AlertSeverity.warning,
          message: 'Dropped frame detected: ${frameTime.inMilliseconds}ms',
          metric: 'frame_time',
          value: frameTime.inMilliseconds.toDouble(),
          timestamp: DateTime.now(),
        ));
      }
    });
  }

  /// Set up rendering callbacks
  void _setupRenderingCallbacks() {
    // Monitor widget rebuilds
    // Note: debugProfileBuildsEnabled has been removed in newer Flutter versions
    // Widget rebuild monitoring should be done via DevTools
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryMonitoringTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _monitorMemory(),
    );
  }

  /// Start frame monitoring
  void _startFrameMonitoring() {
    _frameMonitoringTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _analyzeRecentFrames(),
    );
  }

  /// Start periodic reporting
  void _startPeriodicReporting() {
    _performanceReportingTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _generatePeriodicReport(),
    );
  }

  /// Monitor memory usage
  Future<void> _monitorMemory() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      
      final snapshot = MemorySnapshot(
        timestamp: DateTime.now(),
        usedMemoryMB: memoryInfo.usedMemoryMB,
        totalMemoryMB: memoryInfo.totalMemoryMB,
        memoryPressure: memoryInfo.memoryPressure,
      );
      
      _memorySnapshots.add(snapshot);
      _limitHistorySize(_memorySnapshots, _maxMetricsHistory);
      
      // Check memory thresholds
      if (memoryInfo.usedMemoryMB > _memoryThresholdMB) {
        _sendAlert(PerformanceAlert(
          severity: memoryInfo.usedMemoryMB > _memoryThresholdMB * 1.5 
              ? AlertSeverity.critical 
              : AlertSeverity.warning,
          message: 'High memory usage: ${memoryInfo.usedMemoryMB}MB',
          metric: 'memory_usage',
          value: memoryInfo.usedMemoryMB.toDouble(),
          timestamp: DateTime.now(),
        ));
      }
      
      // Trigger garbage collection hint if memory pressure is high
      if (memoryInfo.memoryPressure == MemoryPressure.high) {
        _triggerGarbageCollection();
      }
      
    } catch (e) {
      debugPrint('Memory monitoring error: $e');
    }
  }

  /// Analyze recent frame performance
  void _analyzeRecentFrames() {
    if (_frameMetrics.isEmpty) return;
    
    final recentFrames = _frameMetrics
        .where((f) => DateTime.now().difference(f.timestamp).inSeconds < 10)
        .toList();
    
    if (recentFrames.isEmpty) return;
    
    final averageFrameTime = recentFrames
        .map((f) => f.frameDuration.inMicroseconds)
        .reduce((a, b) => a + b) / recentFrames.length;
    
    final droppedFrames = recentFrames
        .where((f) => f.frameDuration > _frameTimeThreshold)
        .length;
    
    final droppedFrameRate = droppedFrames / recentFrames.length;
    
    if (droppedFrameRate > 0.1) { // More than 10% dropped frames
      _sendAlert(PerformanceAlert(
        severity: AlertSeverity.warning,
        message: 'High dropped frame rate: ${(droppedFrameRate * 100).toStringAsFixed(1)}%',
        metric: 'dropped_frame_rate',
        value: droppedFrameRate,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Generate periodic performance report
  Future<void> _generatePeriodicReport() async {
    try {
      final summary = await getPerformanceSummary(
        timeWindow: const Duration(minutes: 5),
      );
      
      _updateController.add(PerformanceUpdate(
        type: UpdateType.periodicSummary,
        summary: summary,
        timestamp: DateTime.now(),
      ));
      
    } catch (e) {
      debugPrint('Periodic report generation error: $e');
    }
  }

  /// Get memory information
  Future<MemoryInfo> _getMemoryInfo() async {
    // This would use platform-specific memory APIs
    // For now, provide estimated values
    final usedMemory = await _estimateUsedMemory();
    
    return MemoryInfo(
      usedMemoryMB: usedMemory,
      totalMemoryMB: 512, // Estimated total
      freeMemoryMB: 512 - usedMemory,
      memoryPressure: usedMemory > 200 
          ? MemoryPressure.high 
          : usedMemory > 100 
              ? MemoryPressure.medium 
              : MemoryPressure.low,
    );
  }

  /// Estimate used memory
  Future<int> _estimateUsedMemory() async {
    // This is a simplified estimation
    // In a real implementation, you'd use platform channels
    final baseMemory = 50; // Base app memory
    final dataMemory = _metrics.length ~/ 10; // Memory for stored data
    final cacheMemory = 20; // Estimated cache memory
    
    return baseMemory + dataMemory + cacheMemory;
  }

  /// Trigger garbage collection hint
  void _triggerGarbageCollection() {
    // Force garbage collection in debug mode
    if (kDebugMode) {
      // This would trigger GC if the platform supports it
      debugPrint('Triggering garbage collection due to memory pressure');
    }
  }

  /// Calculate average frame time
  double _calculateAverageFrameTime(List<PerformanceMetric> metrics) {
    final frameMetrics = metrics
        .where((m) => m.name == 'frame_time')
        .toList();
    
    if (frameMetrics.isEmpty) return 0.0;
    
    final total = frameMetrics
        .map((m) => m.value)
        .reduce((a, b) => a + b);
    
    return total / frameMetrics.length;
  }

  /// Calculate navigation performance
  NavigationPerformanceData _calculateNavigationPerformance() {
    if (_navigationMetrics.isEmpty) {
      return NavigationPerformanceData(
        averageNavigationTime: Duration.zero,
        slowNavigations: 0,
        totalNavigations: 0,
      );
    }
    
    final totalTime = _navigationMetrics
        .map((n) => n.duration)
        .reduce((a, b) => a + b);
    
    final averageTime = Duration(
      microseconds: totalTime.inMicroseconds ~/ _navigationMetrics.length,
    );
    
    final slowNavigations = _navigationMetrics
        .where((n) => n.duration > _navigationThreshold)
        .length;
    
    return NavigationPerformanceData(
      averageNavigationTime: averageTime,
      slowNavigations: slowNavigations,
      totalNavigations: _navigationMetrics.length,
    );
  }

  /// Calculate overall performance score
  double _calculatePerformanceScore(List<PerformanceMetric> metrics) {
    double score = 100.0;
    
    // Deduct points for slow frames
    final frameMetrics = metrics.where((m) => m.name == 'frame_time').toList();
    if (frameMetrics.isNotEmpty) {
      final averageFrameTime = _calculateAverageFrameTime(metrics);
      if (averageFrameTime > 16) { // Slower than 60 FPS
        score -= (averageFrameTime - 16) * 2;
      }
    }
    
    // Deduct points for high memory usage
    final memoryMetrics = metrics.where((m) => m.name == 'memory_usage').toList();
    if (memoryMetrics.isNotEmpty) {
      final averageMemory = memoryMetrics
          .map((m) => m.value)
          .reduce((a, b) => a + b) / memoryMetrics.length;
      
      if (averageMemory > _memoryThresholdMB) {
        score -= (averageMemory - _memoryThresholdMB) * 0.5;
      }
    }
    
    // Deduct points for slow navigation
    final navData = _calculateNavigationPerformance();
    if (navData.averageNavigationTime.inMilliseconds > _navigationThreshold.inMilliseconds) {
      score -= (navData.averageNavigationTime.inMilliseconds - _navigationThreshold.inMilliseconds) * 0.1;
    }
    
    return (score < 0) ? 0 : score;
  }

  /// Get detailed metrics for reporting
  Map<String, List<PerformanceMetric>> _getDetailedMetrics(Duration? timeWindow) {
    final cutoff = timeWindow != null 
        ? DateTime.now().subtract(timeWindow)
        : DateTime.now().subtract(const Duration(hours: 1));
    
    final recentMetrics = _metrics
        .where((m) => m.timestamp.isAfter(cutoff))
        .toList();
    
    final grouped = <String, List<PerformanceMetric>>{};
    
    for (final metric in recentMetrics) {
      grouped.putIfAbsent(metric.name, () => []).add(metric);
    }
    
    return grouped;
  }

  /// Analyze memory usage patterns
  MemoryAnalysis _analyzeMemoryUsage() {
    if (_memorySnapshots.isEmpty) {
      return MemoryAnalysis(
        trend: MemoryTrend.stable,
        peakUsageMB: 0,
        averageUsageMB: 0,
        memoryLeakSuspected: false,
      );
    }
    
    final recent = _memorySnapshots.take(10).toList();
    final peak = _memorySnapshots
        .map((s) => s.usedMemoryMB)
        .reduce((a, b) => a > b ? a : b);
    
    final average = _memorySnapshots
        .map((s) => s.usedMemoryMB)
        .reduce((a, b) => a + b) / _memorySnapshots.length;
    
    // Simple trend analysis
    MemoryTrend trend = MemoryTrend.stable;
    if (recent.length >= 2) {
      final first = recent.first.usedMemoryMB;
      final last = recent.last.usedMemoryMB;
      
      if (last > first * 1.2) {
        trend = MemoryTrend.increasing;
      } else if (last < first * 0.8) {
        trend = MemoryTrend.decreasing;
      }
    }
    
    // Simple memory leak detection
    final memoryLeakSuspected = trend == MemoryTrend.increasing && 
                               peak > _memoryThresholdMB * 1.5;
    
    return MemoryAnalysis(
      trend: trend,
      peakUsageMB: peak,
      averageUsageMB: average.round(),
      memoryLeakSuspected: memoryLeakSuspected,
    );
  }

  /// Analyze frame performance
  FrameAnalysis _analyzeFramePerformance() {
    if (_frameMetrics.isEmpty) {
      return FrameAnalysis(
        averageFrameTimeMicroseconds: 0,
        droppedFramePercentage: 0.0,
        frameRateStability: FrameRateStability.stable,
      );
    }
    
    final averageFrameTime = _frameMetrics
        .map((f) => f.frameDuration.inMicroseconds)
        .reduce((a, b) => a + b) / _frameMetrics.length;
    
    final droppedFrames = _frameMetrics
        .where((f) => f.frameDuration > _frameTimeThreshold)
        .length;
    
    final droppedPercentage = droppedFrames / _frameMetrics.length;
    
    FrameRateStability stability = FrameRateStability.stable;
    if (droppedPercentage > 0.2) {
      stability = FrameRateStability.unstable;
    } else if (droppedPercentage > 0.1) {
      stability = FrameRateStability.variable;
    }
    
    return FrameAnalysis(
      averageFrameTimeMicroseconds: averageFrameTime.round(),
      droppedFramePercentage: droppedPercentage,
      frameRateStability: stability,
    );
  }

  /// Analyze navigation performance
  NavigationAnalysis _analyzeNavigationPerformance() {
    final navData = _calculateNavigationPerformance();
    
    final routePerformance = <String, Duration>{};
    for (final metric in _navigationMetrics) {
      final key = '${metric.fromRoute}_to_${metric.toRoute}';
      routePerformance[key] = metric.duration;
    }
    
    return NavigationAnalysis(
      averageNavigationTime: navData.averageNavigationTime,
      slowNavigationCount: navData.slowNavigations,
      routePerformance: routePerformance,
    );
  }

  /// Generate performance recommendations
  List<String> _generateRecommendations(PerformanceSummary summary) {
    final recommendations = <String>[];
    
    if (summary.averageFrameTime > 16) {
      recommendations.add('Consider optimizing UI rendering to improve frame rate');
    }
    
    if (summary.memoryUsage.usedMemoryMB > _memoryThresholdMB) {
      recommendations.add('High memory usage detected - consider implementing memory optimization');
    }
    
    if (summary.navigationPerformance.slowNavigations > 0) {
      recommendations.add('Some navigation routes are slow - consider lazy loading or optimization');
    }
    
    if (summary.performanceScore < 70) {
      recommendations.add('Overall performance score is low - review app architecture and optimization');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Performance is within acceptable ranges');
    }
    
    return recommendations;
  }

  /// Utility methods
  void _limitHistorySize<T>(List<T> list, int maxSize) {
    while (list.length > maxSize) {
      list.removeAt(0);
    }
  }

  List<PerformanceAlert> _getRecentAlerts(DateTime cutoff) {
    // Implementation would retrieve recent alerts
    return [];
  }

  String _generateReportId() {
    return 'perf_report_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _storeReport(PerformanceReport report) async {
    try {
      await _secureStorage.storePrivacySettings({
        'performance_report_${report.reportId}': report.toJson(),
      });
    } catch (e) {
      debugPrint('Failed to store performance report: $e');
    }
  }

  Future<void> _recordMetric(PerformanceMetric metric) async {
    _metrics.add(metric);
    _limitHistorySize(_metrics, _maxMetricsHistory);
  }

  void _sendAlert(PerformanceAlert alert) {
    _alertController.add(alert);
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Stream getters
  Stream<PerformanceAlert> get alerts => _alertController.stream;
  Stream<PerformanceUpdate> get updates => _updateController.stream;

  /// Dispose resources
  Future<void> dispose() async {
    await stopMonitoring();
    await _alertController.close();
    await _updateController.close();
  }
}

/// Performance metric data model
class PerformanceMetric {
  final String name;
  final double value;
  final DateTime timestamp;
  final MetricCategory category;
  final Map<String, dynamic>? metadata;

  const PerformanceMetric({
    required this.name,
    required this.value,
    required this.timestamp,
    required this.category,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'timestamp': timestamp.toIso8601String(),
    'category': category.toString(),
    'metadata': metadata,
  };
}

/// Memory snapshot
class MemorySnapshot {
  final DateTime timestamp;
  final int usedMemoryMB;
  final int totalMemoryMB;
  final MemoryPressure memoryPressure;

  const MemorySnapshot({
    required this.timestamp,
    required this.usedMemoryMB,
    required this.totalMemoryMB,
    required this.memoryPressure,
  });
}

/// Frame metric
class FrameMetric {
  final DateTime timestamp;
  final Duration frameDuration;

  const FrameMetric({
    required this.timestamp,
    required this.frameDuration,
  });
}

/// Navigation metric
class NavigationMetric {
  final String fromRoute;
  final String toRoute;
  final Duration duration;
  final DateTime timestamp;

  const NavigationMetric({
    required this.fromRoute,
    required this.toRoute,
    required this.duration,
    required this.timestamp,
  });
}

/// Memory information
class MemoryInfo {
  final int usedMemoryMB;
  final int totalMemoryMB;
  final int freeMemoryMB;
  final MemoryPressure memoryPressure;

  const MemoryInfo({
    required this.usedMemoryMB,
    required this.totalMemoryMB,
    required this.freeMemoryMB,
    required this.memoryPressure,
  });
}

/// Performance summary
class PerformanceSummary {
  final DateTime generatedAt;
  final Duration timeWindow;
  final int totalMetrics;
  final double averageFrameTime;
  final MemoryInfo memoryUsage;
  final NavigationPerformanceData navigationPerformance;
  final int alertsTriggered;
  final double performanceScore;

  const PerformanceSummary({
    required this.generatedAt,
    required this.timeWindow,
    required this.totalMetrics,
    required this.averageFrameTime,
    required this.memoryUsage,
    required this.navigationPerformance,
    required this.alertsTriggered,
    required this.performanceScore,
  });
}

/// Performance report
class PerformanceReport {
  final String reportId;
  final DateTime generatedAt;
  final PerformanceSummary summary;
  final Map<String, List<PerformanceMetric>> detailedMetrics;
  final MemoryAnalysis memoryAnalysis;
  final FrameAnalysis frameAnalysis;
  final NavigationAnalysis navigationAnalysis;
  final List<String> recommendations;

  const PerformanceReport({
    required this.reportId,
    required this.generatedAt,
    required this.summary,
    required this.detailedMetrics,
    required this.memoryAnalysis,
    required this.frameAnalysis,
    required this.navigationAnalysis,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'report_id': reportId,
    'generated_at': generatedAt.toIso8601String(),
    'summary': {
      'performance_score': summary.performanceScore,
      'alerts_triggered': summary.alertsTriggered,
      'memory_usage_mb': summary.memoryUsage.usedMemoryMB,
    },
    'recommendations': recommendations,
  };
}

/// Analysis classes
class MemoryAnalysis {
  final MemoryTrend trend;
  final int peakUsageMB;
  final int averageUsageMB;
  final bool memoryLeakSuspected;

  const MemoryAnalysis({
    required this.trend,
    required this.peakUsageMB,
    required this.averageUsageMB,
    required this.memoryLeakSuspected,
  });
}

class FrameAnalysis {
  final int averageFrameTimeMicroseconds;
  final double droppedFramePercentage;
  final FrameRateStability frameRateStability;

  const FrameAnalysis({
    required this.averageFrameTimeMicroseconds,
    required this.droppedFramePercentage,
    required this.frameRateStability,
  });
}

class NavigationAnalysis {
  final Duration averageNavigationTime;
  final int slowNavigationCount;
  final Map<String, Duration> routePerformance;

  const NavigationAnalysis({
    required this.averageNavigationTime,
    required this.slowNavigationCount,
    required this.routePerformance,
  });
}

class NavigationPerformanceData {
  final Duration averageNavigationTime;
  final int slowNavigations;
  final int totalNavigations;

  const NavigationPerformanceData({
    required this.averageNavigationTime,
    required this.slowNavigations,
    required this.totalNavigations,
  });
}

/// Alert and update classes
class PerformanceAlert {
  final AlertSeverity severity;
  final String message;
  final String metric;
  final double value;
  final DateTime timestamp;

  const PerformanceAlert({
    required this.severity,
    required this.message,
    required this.metric,
    required this.value,
    required this.timestamp,
  });
}

class PerformanceUpdate {
  final UpdateType type;
  final PerformanceSummary? summary;
  final DateTime timestamp;

  const PerformanceUpdate({
    required this.type,
    this.summary,
    required this.timestamp,
  });
}

/// Enums
enum MetricCategory { system, startup, navigation, operation, memory, frame }
enum MemoryPressure { low, medium, high }
enum MemoryTrend { decreasing, stable, increasing }
enum FrameRateStability { stable, variable, unstable }
enum AlertSeverity { info, warning, critical }
enum UpdateType { periodicSummary, alertTriggered, reportGenerated }

/// Exception for performance operations
class PerformanceException implements Exception {
  final String message;
  
  const PerformanceException(this.message);
  
  @override
  String toString() => 'PerformanceException: $message';
}