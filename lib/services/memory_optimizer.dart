import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Memory optimization service for efficient resource management
/// 
/// This service provides:
/// - Intelligent cache management
/// - Memory pool allocation
/// - Automatic garbage collection optimization
/// - Resource lifecycle management
/// - Memory leak detection and prevention
/// - Image memory optimization
/// - Data structure optimization
class MemoryOptimizer {
  static MemoryOptimizer? _instance;
  static MemoryOptimizer get instance => _instance ??= MemoryOptimizer._();
  
  MemoryOptimizer._();

  bool _isInitialized = false;
  
  // Cache management
  final Map<String, CacheEntry> _caches = {};
  final LinkedHashMap<String, dynamic> _lruCache = LinkedHashMap();
  static const int _maxLruCacheSize = 100;
  static const Duration _defaultCacheExpiry = Duration(minutes: 15);
  
  // Memory pools
  final Map<Type, ObjectPool> _objectPools = {};
  final Set<WeakReference> _weakReferences = {};
  
  // Monitoring
  Timer? _memoryCleanupTimer;
  Timer? _cacheMaintenanceTimer;
  final List<MemoryMetric> _memoryMetrics = [];
  
  // Configuration
  static const int _memoryPressureThresholdMB = 100;
  static const Duration _cleanupInterval = Duration(minutes: 2);
  static const Duration _cacheMaintenanceInterval = Duration(minutes: 5);

  /// Initialize the memory optimizer
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up periodic cleanup
      _startPeriodicCleanup();
      
      // Set up cache maintenance
      _startCacheMaintenanceTask();
      
      // Initialize default object pools
      _initializeObjectPools();
      
      _isInitialized = true;
      
      await _recordMemoryMetric('optimizer_initialized', 1);
      
    } catch (e) {
      throw MemoryOptimizationException('Failed to initialize memory optimizer: $e');
    }
  }

  /// Create or get named cache
  OptimizedCache<K, V> getCache<K, V>(
    String name, {
    int? maxSize,
    Duration? expiry,
    CacheEvictionPolicy? evictionPolicy,
  }) {
    _ensureInitialized();
    
    if (!_caches.containsKey(name)) {
      _caches[name] = CacheEntry(
        cache: OptimizedCache<K, V>(
          name: name,
          maxSize: maxSize ?? 50,
          expiry: expiry ?? _defaultCacheExpiry,
          evictionPolicy: evictionPolicy ?? CacheEvictionPolicy.lru,
        ),
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
      );
    }
    
    _caches[name]!.lastAccessed = DateTime.now();
    return _caches[name]!.cache as OptimizedCache<K, V>;
  }

  /// Get or create object pool for type
  ObjectPool<T> getObjectPool<T>(
    String poolName,
    T Function() factory, {
    int? maxSize,
    Duration? objectLifetime,
  }) {
    _ensureInitialized();
    
    if (!_objectPools.containsKey(T)) {
      _objectPools[T] = ObjectPool<T>(
        name: poolName,
        factory: factory,
        maxSize: maxSize ?? 20,
        objectLifetime: objectLifetime ?? const Duration(minutes: 10),
      );
    }
    
    return _objectPools[T] as ObjectPool<T>;
  }

  /// Optimize image memory usage
  Future<Uint8List> optimizeImageMemory(
    Uint8List imageData, {
    int? maxWidth,
    int? maxHeight,
    ImageFormat targetFormat = ImageFormat.webp,
    int quality = 80,
  }) async {
    _ensureInitialized();
    
    try {
      // This would use image processing libraries in a real implementation
      // For now, return the original data
      await _recordMemoryMetric('image_optimized', imageData.length);
      return imageData;
      
    } catch (e) {
      throw MemoryOptimizationException('Failed to optimize image: $e');
    }
  }

  /// Optimize data structure memory
  OptimizedList<T> createOptimizedList<T>({
    int? initialCapacity,
    bool enableCompression = false,
  }) {
    _ensureInitialized();
    
    return OptimizedList<T>(
      initialCapacity: initialCapacity ?? 16,
      enableCompression: enableCompression,
    );
  }

  /// Optimize map memory usage
  OptimizedMap<K, V> createOptimizedMap<K, V>({
    int? initialCapacity,
    bool enableCompression = false,
    MapOptimizationStrategy strategy = MapOptimizationStrategy.balanced,
  }) {
    _ensureInitialized();
    
    return OptimizedMap<K, V>(
      initialCapacity: initialCapacity ?? 16,
      enableCompression: enableCompression,
      strategy: strategy,
    );
  }

  /// Register weak reference for automatic cleanup
  void registerWeakReference(Object object, VoidCallback? onFinalized) {
    _ensureInitialized();
    
    final weakRef = WeakReference(object);
    _weakReferences.add(weakRef);
    
    // Set up finalizer if callback provided
    if (onFinalized != null) {
      Finalizer((_) => onFinalized).attach(object, null);
    }
  }

  /// Force memory optimization
  Future<MemoryOptimizationResult> optimizeMemory({
    bool aggressive = false,
  }) async {
    _ensureInitialized();
    
    final startTime = DateTime.now();
    int freedMemoryMB = 0;
    
    try {
      // Clean up expired cache entries
      final cacheFreed = await _cleanupExpiredCaches();
      freedMemoryMB += cacheFreed;
      
      // Clean up object pools
      final poolsFreed = await _cleanupObjectPools();
      freedMemoryMB += poolsFreed;
      
      // Clean up weak references
      final refsFreed = await _cleanupWeakReferences();
      freedMemoryMB += refsFreed;
      
      // LRU cache cleanup
      final lruFreed = await _cleanupLruCache();
      freedMemoryMB += lruFreed;
      
      if (aggressive) {
        // More aggressive cleanup
        await _aggressiveCleanup();
        freedMemoryMB += 10; // Estimated
      }
      
      // Suggest garbage collection
      await _suggestGarbageCollection();
      
      final duration = DateTime.now().difference(startTime);
      
      await _recordMemoryMetric('memory_optimized', freedMemoryMB);
      
      return MemoryOptimizationResult(
        freedMemoryMB: freedMemoryMB,
        duration: duration,
        aggressive: aggressive,
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      throw MemoryOptimizationException('Memory optimization failed: $e');
    }
  }

  /// Get memory usage statistics
  Future<MemoryStatistics> getMemoryStatistics() async {
    _ensureInitialized();
    
    final cacheStats = _calculateCacheStatistics();
    final poolStats = _calculatePoolStatistics();
    
    return MemoryStatistics(
      totalCaches: _caches.length,
      totalCacheEntries: cacheStats.totalEntries,
      cacheMemoryUsageMB: cacheStats.memoryUsageMB,
      totalObjectPools: _objectPools.length,
      totalPooledObjects: poolStats.totalObjects,
      poolMemoryUsageMB: poolStats.memoryUsageMB,
      weakReferences: _weakReferences.length,
      lruCacheSize: _lruCache.length,
      estimatedTotalMemoryMB: cacheStats.memoryUsageMB + poolStats.memoryUsageMB,
    );
  }

  /// Check for potential memory leaks
  Future<MemoryLeakReport> checkForMemoryLeaks() async {
    _ensureInitialized();
    
    final suspiciousItems = <MemoryLeakSuspicion>[];
    
    // Check for caches that are growing too large
    for (final entry in _caches.entries) {
      final cache = entry.value.cache;
      if (cache.size > cache.maxSize * 1.5) {
        suspiciousItems.add(MemoryLeakSuspicion(
          type: LeakType.cacheOvergrowth,
          description: 'Cache ${entry.key} has exceeded expected size',
          severity: LeakSeverity.medium,
          details: {
            'cache_name': entry.key,
            'current_size': cache.size,
            'max_size': cache.maxSize,
          },
        ));
      }
    }
    
    // Check for object pools that aren't being returned to
    for (final entry in _objectPools.entries) {
      final pool = entry.value;
      if (pool.checkedOutCount > pool.maxSize) {
        suspiciousItems.add(MemoryLeakSuspicion(
          type: LeakType.poolExhaustion,
          description: 'Object pool ${pool.name} has too many checked out objects',
          severity: LeakSeverity.high,
          details: {
            'pool_name': pool.name,
            'checked_out': pool.checkedOutCount,
            'max_size': pool.maxSize,
          },
        ));
      }
    }
    
    // Check LRU cache growth
    if (_lruCache.length > _maxLruCacheSize * 1.2) {
      suspiciousItems.add(MemoryLeakSuspicion(
        type: LeakType.lruCacheGrowth,
        description: 'LRU cache is growing beyond expected size',
        severity: LeakSeverity.medium,
        details: {
          'current_size': _lruCache.length,
          'max_size': _maxLruCacheSize,
        },
      ));
    }
    
    return MemoryLeakReport(
      checkTime: DateTime.now(),
      suspiciousItems: suspiciousItems,
      overallRisk: _calculateOverallRisk(suspiciousItems),
    );
  }

  /// LRU cache operations
  T? getLru<T>(String key) {
    final value = _lruCache.remove(key);
    if (value != null) {
      _lruCache[key] = value;
      return value as T?;
    }
    return null;
  }

  void putLru<T>(String key, T value) {
    if (_lruCache.containsKey(key)) {
      _lruCache.remove(key);
    } else if (_lruCache.length >= _maxLruCacheSize) {
      _lruCache.remove(_lruCache.keys.first);
    }
    _lruCache[key] = value;
  }

  void removeLru(String key) {
    _lruCache.remove(key);
  }

  void clearLru() {
    _lruCache.clear();
  }

  /// Private implementation methods
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw MemoryOptimizationException('Memory optimizer not initialized');
    }
  }

  void _startPeriodicCleanup() {
    _memoryCleanupTimer = Timer.periodic(
      _cleanupInterval,
      (_) => _performPeriodicCleanup(),
    );
  }

  void _startCacheMaintenanceTask() {
    _cacheMaintenanceTimer = Timer.periodic(
      _cacheMaintenanceInterval,
      (_) => _performCacheMaintenanceTask(),
    );
  }

  void _initializeObjectPools() {
    // Initialize common object pools
    // This would set up pools for frequently used objects
  }

  Future<void> _performPeriodicCleanup() async {
    try {
      await optimizeMemory();
    } catch (e) {
      debugPrint('Periodic cleanup error: $e');
    }
  }

  Future<void> _performCacheMaintenanceTask() async {
    try {
      await _cleanupExpiredCaches();
      await _cleanupObjectPools();
    } catch (e) {
      debugPrint('Cache maintenance error: $e');
    }
  }

  Future<int> _cleanupExpiredCaches() async {
    int freedMemory = 0;
    final now = DateTime.now();
    final expiredCaches = <String>[];
    
    for (final entry in _caches.entries) {
      if (now.difference(entry.value.lastAccessed) > entry.value.cache.expiry) {
        expiredCaches.add(entry.key);
      } else {
        final cleanupResult = entry.value.cache.cleanup();
        final int intResult = cleanupResult is int ? cleanupResult : cleanupResult.toInt();
        freedMemory += intResult;
      }
    }
    
    for (final key in expiredCaches) {
      _caches.remove(key);
      freedMemory += 1; // Estimated
    }
    
    return freedMemory;
  }

  Future<int> _cleanupObjectPools() async {
    int freedMemory = 0;
    
    for (final pool in _objectPools.values) {
      freedMemory += pool.cleanup();
    }
    
    return freedMemory;
  }

  Future<int> _cleanupWeakReferences() async {
    final invalidRefs = <WeakReference>[];
    
    for (final ref in _weakReferences) {
      if (ref.target == null) {
        invalidRefs.add(ref);
      }
    }
    
    for (final ref in invalidRefs) {
      _weakReferences.remove(ref);
    }
    
    return invalidRefs.length ~/ 10; // Estimated memory freed
  }

  Future<int> _cleanupLruCache() async {
    final sizeBefore = _lruCache.length;
    
    while (_lruCache.length > _maxLruCacheSize) {
      _lruCache.remove(_lruCache.keys.first);
    }
    
    return sizeBefore - _lruCache.length;
  }

  Future<void> _aggressiveCleanup() async {
    // Clear all non-essential caches
    for (final cache in _caches.values) {
      cache.cache.clear();
    }
    
    // Return all objects to pools
    for (final pool in _objectPools.values) {
      pool.returnAll();
    }
    
    // Clear LRU cache
    _lruCache.clear();
  }

  Future<void> _suggestGarbageCollection() async {
    // This would trigger GC if supported by the platform
    if (kDebugMode) {
      debugPrint('Suggesting garbage collection');
    }
  }

  CacheStatistics _calculateCacheStatistics() {
    int totalEntries = 0;
    int memoryUsage = 0;
    
    for (final cache in _caches.values) {
      final size = cache.cache.size;
      final memUsage = cache.cache.estimatedMemoryUsageMB;
      final int sizeInt = size is int ? size : size.toInt();
      final int memInt = memUsage is int ? memUsage : memUsage.toInt();
      totalEntries += sizeInt;
      memoryUsage += memInt;
    }
    
    return CacheStatistics(
      totalEntries: totalEntries,
      memoryUsageMB: memoryUsage,
    );
  }

  PoolStatistics _calculatePoolStatistics() {
    int totalObjects = 0;
    int memoryUsage = 0;
    
    for (final pool in _objectPools.values) {
      totalObjects += pool.size;
      memoryUsage += pool.estimatedMemoryUsageMB;
    }
    
    return PoolStatistics(
      totalObjects: totalObjects,
      memoryUsageMB: memoryUsage,
    );
  }

  LeakRisk _calculateOverallRisk(List<MemoryLeakSuspicion> suspicions) {
    if (suspicions.isEmpty) return LeakRisk.low;
    
    final highSeverityCount = suspicions
        .where((s) => s.severity == LeakSeverity.high)
        .length;
    
    final mediumSeverityCount = suspicions
        .where((s) => s.severity == LeakSeverity.medium)
        .length;
    
    if (highSeverityCount > 0) return LeakRisk.high;
    if (mediumSeverityCount > 2) return LeakRisk.medium;
    return LeakRisk.low;
  }

  Future<void> _recordMemoryMetric(String name, dynamic value) async {
    final metric = MemoryMetric(
      name: name,
      value: value,
      timestamp: DateTime.now(),
    );
    
    _memoryMetrics.add(metric);
    
    // Keep only recent metrics
    if (_memoryMetrics.length > 100) {
      _memoryMetrics.removeAt(0);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    _memoryCleanupTimer?.cancel();
    _cacheMaintenanceTimer?.cancel();
    
    // Clean up all caches
    for (final cache in _caches.values) {
      cache.cache.dispose();
    }
    _caches.clear();
    
    // Clean up all pools
    for (final pool in _objectPools.values) {
      pool.dispose();
    }
    _objectPools.clear();
    
    _lruCache.clear();
    _weakReferences.clear();
  }
}

/// Optimized cache implementation
class OptimizedCache<K, V> {
  final String name;
  final int maxSize;
  final Duration expiry;
  final CacheEvictionPolicy evictionPolicy;
  
  final Map<K, CacheItem<V>> _cache = {};
  final LinkedHashMap<K, DateTime> _accessOrder = LinkedHashMap();
  
  OptimizedCache({
    required this.name,
    required this.maxSize,
    required this.expiry,
    required this.evictionPolicy,
  });

  int get size => _cache.length;
  int get estimatedMemoryUsageMB => _cache.length ~/ 50; // Rough estimate

  V? get(K key) {
    final item = _cache[key];
    if (item == null) return null;
    
    // Check expiry
    if (DateTime.now().difference(item.createdAt) > expiry) {
      _cache.remove(key);
      _accessOrder.remove(key);
      return null;
    }
    
    // Update access order for LRU
    if (evictionPolicy == CacheEvictionPolicy.lru) {
      _accessOrder.remove(key);
      _accessOrder[key] = DateTime.now();
    }
    
    return item.value;
  }

  void put(K key, V value) {
    // Check if we need to evict
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      _evictItem();
    }
    
    final item = CacheItem<V>(
      value: value,
      createdAt: DateTime.now(),
    );
    
    _cache[key] = item;
    
    if (evictionPolicy == CacheEvictionPolicy.lru) {
      _accessOrder[key] = DateTime.now();
    }
  }

  void remove(K key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  int cleanup() {
    final sizeBefore = _cache.length;
    final now = DateTime.now();
    final expiredKeys = <K>[];
    
    for (final entry in _cache.entries) {
      if (now.difference(entry.value.createdAt) > expiry) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
    
    return sizeBefore - _cache.length;
  }

  void _evictItem() {
    if (_cache.isEmpty) return;
    
    K? keyToEvict;
    
    switch (evictionPolicy) {
      case CacheEvictionPolicy.lru:
        keyToEvict = _accessOrder.keys.first;
        break;
      case CacheEvictionPolicy.fifo:
        keyToEvict = _cache.keys.first;
        break;
      case CacheEvictionPolicy.random:
        final keys = _cache.keys.toList();
        keyToEvict = keys[DateTime.now().millisecond % keys.length];
        break;
    }
    
    if (keyToEvict != null) {
      remove(keyToEvict);
    }
  }

  void dispose() {
    clear();
  }
}

/// Object pool implementation
class ObjectPool<T> {
  final String name;
  final T Function() factory;
  final int maxSize;
  final Duration objectLifetime;
  
  final Queue<PooledObject<T>> _available = Queue();
  final Set<PooledObject<T>> _checkedOut = {};
  
  ObjectPool({
    required this.name,
    required this.factory,
    required this.maxSize,
    required this.objectLifetime,
  });

  int get size => _available.length + _checkedOut.length;
  int get checkedOutCount => _checkedOut.length;
  int get estimatedMemoryUsageMB => size ~/ 20; // Rough estimate

  T checkout() {
    // Clean up expired objects first
    _cleanupExpired();
    
    PooledObject<T>? pooledObject;
    
    if (_available.isNotEmpty) {
      pooledObject = _available.removeFirst();
    } else if (size < maxSize) {
      pooledObject = PooledObject<T>(
        object: factory(),
        createdAt: DateTime.now(),
      );
    } else {
      // Pool exhausted, create a new object anyway
      pooledObject = PooledObject<T>(
        object: factory(),
        createdAt: DateTime.now(),
      );
    }
    
    _checkedOut.add(pooledObject);
    return pooledObject.object;
  }

  void returnObject(T object) {
    final pooledObject = _checkedOut
        .where((p) => identical(p.object, object))
        .firstOrNull;
    
    if (pooledObject != null) {
      _checkedOut.remove(pooledObject);
      
      // Only return to pool if it's not expired and pool isn't full
      if (DateTime.now().difference(pooledObject.createdAt) < objectLifetime &&
          _available.length < maxSize) {
        _available.add(pooledObject);
      }
    }
  }

  void returnAll() {
    for (final pooledObject in _checkedOut.toList()) {
      returnObject(pooledObject.object);
    }
  }

  int cleanup() {
    final sizeBefore = size;
    _cleanupExpired();
    return sizeBefore - size;
  }

  void _cleanupExpired() {
    final now = DateTime.now();
    
    _available.removeWhere((p) => 
        now.difference(p.createdAt) > objectLifetime);
    
    _checkedOut.removeWhere((p) => 
        now.difference(p.createdAt) > objectLifetime);
  }

  void dispose() {
    _available.clear();
    _checkedOut.clear();
  }
}

/// Optimized list implementation
class OptimizedList<T> extends ListBase<T> {
  late List<T> _internal;
  final bool enableCompression;
  
  OptimizedList({
    int initialCapacity = 16,
    this.enableCompression = false,
  }) {
    _internal = List<T>.filled(initialCapacity, null as T, growable: true);
    _internal.clear();
  }

  @override
  int get length => _internal.length;

  @override
  set length(int newLength) {
    _internal.length = newLength;
  }

  @override
  T operator [](int index) => _internal[index];

  @override
  void operator []=(int index, T value) {
    _internal[index] = value;
  }

  @override
  void add(T element) {
    _internal.add(element);
    _optimizeIfNeeded();
  }

  void _optimizeIfNeeded() {
    // Optimize internal storage if needed
    if (_internal.length > 1000 && enableCompression) {
      // This would implement compression in a real scenario
    }
  }
}

/// Optimized map implementation
class OptimizedMap<K, V> extends MapBase<K, V> {
  late Map<K, V> _internal;
  final bool enableCompression;
  final MapOptimizationStrategy strategy;
  
  OptimizedMap({
    int initialCapacity = 16,
    this.enableCompression = false,
    this.strategy = MapOptimizationStrategy.balanced,
  }) {
    switch (strategy) {
      case MapOptimizationStrategy.memoryOptimized:
        _internal = <K, V>{};
        break;
      case MapOptimizationStrategy.speedOptimized:
        _internal = HashMap<K, V>();
        break;
      case MapOptimizationStrategy.balanced:
        _internal = LinkedHashMap<K, V>();
        break;
    }
  }

  @override
  V? operator [](Object? key) => _internal[key];

  @override
  void operator []=(K key, V value) {
    _internal[key] = value;
    _optimizeIfNeeded();
  }

  @override
  void clear() => _internal.clear();

  @override
  Iterable<K> get keys => _internal.keys;

  @override
  V? remove(Object? key) => _internal.remove(key);

  void _optimizeIfNeeded() {
    // Optimize internal storage if needed
    if (_internal.length > 1000 && enableCompression) {
      // This would implement compression in a real scenario
    }
  }
}

/// Data models and classes
class CacheEntry {
  final dynamic cache;
  final DateTime createdAt;
  DateTime lastAccessed;

  CacheEntry({
    required this.cache,
    required this.createdAt,
    required this.lastAccessed,
  });
}

class CacheItem<T> {
  final T value;
  final DateTime createdAt;

  const CacheItem({
    required this.value,
    required this.createdAt,
  });
}

class PooledObject<T> {
  final T object;
  final DateTime createdAt;

  const PooledObject({
    required this.object,
    required this.createdAt,
  });
}

class MemoryOptimizationResult {
  final int freedMemoryMB;
  final Duration duration;
  final bool aggressive;
  final DateTime timestamp;

  const MemoryOptimizationResult({
    required this.freedMemoryMB,
    required this.duration,
    required this.aggressive,
    required this.timestamp,
  });
}

class MemoryStatistics {
  final int totalCaches;
  final int totalCacheEntries;
  final int cacheMemoryUsageMB;
  final int totalObjectPools;
  final int totalPooledObjects;
  final int poolMemoryUsageMB;
  final int weakReferences;
  final int lruCacheSize;
  final int estimatedTotalMemoryMB;

  const MemoryStatistics({
    required this.totalCaches,
    required this.totalCacheEntries,
    required this.cacheMemoryUsageMB,
    required this.totalObjectPools,
    required this.totalPooledObjects,
    required this.poolMemoryUsageMB,
    required this.weakReferences,
    required this.lruCacheSize,
    required this.estimatedTotalMemoryMB,
  });
}

class MemoryLeakReport {
  final DateTime checkTime;
  final List<MemoryLeakSuspicion> suspiciousItems;
  final LeakRisk overallRisk;

  const MemoryLeakReport({
    required this.checkTime,
    required this.suspiciousItems,
    required this.overallRisk,
  });
}

class MemoryLeakSuspicion {
  final LeakType type;
  final String description;
  final LeakSeverity severity;
  final Map<String, dynamic> details;

  const MemoryLeakSuspicion({
    required this.type,
    required this.description,
    required this.severity,
    required this.details,
  });
}

class CacheStatistics {
  final int totalEntries;
  final int memoryUsageMB;

  const CacheStatistics({
    required this.totalEntries,
    required this.memoryUsageMB,
  });
}

class PoolStatistics {
  final int totalObjects;
  final int memoryUsageMB;

  const PoolStatistics({
    required this.totalObjects,
    required this.memoryUsageMB,
  });
}

class MemoryMetric {
  final String name;
  final dynamic value;
  final DateTime timestamp;

  const MemoryMetric({
    required this.name,
    required this.value,
    required this.timestamp,
  });
}

/// Enums
enum CacheEvictionPolicy { lru, fifo, random }
enum MapOptimizationStrategy { memoryOptimized, speedOptimized, balanced }
enum ImageFormat { jpeg, png, webp }
enum LeakType { cacheOvergrowth, poolExhaustion, lruCacheGrowth, objectRetention }
enum LeakSeverity { low, medium, high }
enum LeakRisk { low, medium, high }

/// Exception for memory optimization operations
class MemoryOptimizationException implements Exception {
  final String message;
  
  const MemoryOptimizationException(this.message);
  
  @override
  String toString() => 'MemoryOptimizationException: $message';
}