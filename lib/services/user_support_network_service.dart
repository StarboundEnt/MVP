import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/service_model.dart';

/// 🤝 User Support Network Service
/// Manages the user's personal support network (QR code connections)
class UserSupportNetworkService {
  static final UserSupportNetworkService _instance = UserSupportNetworkService._internal();
  factory UserSupportNetworkService() => _instance;
  UserSupportNetworkService._internal();

  static const String _personalConnectionsKey = 'user_personal_connections';
  static const String _supportNetworkMetadataKey = 'support_network_metadata';

  List<SupportService> _personalConnections = [];
  Map<String, dynamic> _networkMetadata = {};

  /// Initialize the service and load saved data
  Future<void> initialize() async {
    try {
      await _loadPersonalConnections();
      await _loadNetworkMetadata();
      debugPrint('✅ UserSupportNetworkService initialized with ${_personalConnections.length} personal connections');
    } catch (e) {
      debugPrint('❌ Error initializing UserSupportNetworkService: $e');
    }
  }

  /// Add a new organization from QR code scan
  Future<bool> addOrganizationFromQR(Map<String, dynamic> qrData) async {
    try {
      // Create service from QR data
      final newService = SupportService.fromQRCode(qrData);
      
      // Check if organization already exists
      final existingIndex = _personalConnections.indexWhere(
        (service) => service.organizationId == newService.organizationId
      );
      
      if (existingIndex != -1) {
        // Update existing service with new data
        _personalConnections[existingIndex] = newService;
        debugPrint('📝 Updated existing organization: ${newService.name}');
      } else {
        // Add new service
        _personalConnections.add(newService);
        debugPrint('➕ Added new organization: ${newService.name}');
      }
      
      await _savePersonalConnections();
      await _updateNetworkMetadata();
      
      return true;
    } catch (e) {
      debugPrint('❌ Error adding organization from QR: $e');
      return false;
    }
  }

  /// Get all personal connections
  List<SupportService> getPersonalConnections() {
    return List.from(_personalConnections);
  }

  /// Get personal connections by category
  List<SupportService> getPersonalConnectionsByCategory(String category) {
    return _personalConnections.where((service) =>
      service.tags.contains(category) ||
      service.offerings.any((offering) => offering.category == category)
    ).toList();
  }

  /// Remove a personal connection
  Future<bool> removePersonalConnection(String organizationId) async {
    try {
      final removedCount = _personalConnections.length;
      _personalConnections.removeWhere((service) => service.organizationId == organizationId);
      
      if (_personalConnections.length < removedCount) {
        await _savePersonalConnections();
        await _updateNetworkMetadata();
        debugPrint('🗑️ Removed organization: $organizationId');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error removing personal connection: $e');
      return false;
    }
  }

  /// Get combined services (system + personal connections)
  List<SupportService> getCombinedServices() {
    final systemServices = StarboundServices.getSampleServices();
    final combinedServices = <SupportService>[];
    
    // Add system services
    combinedServices.addAll(systemServices);
    
    // Add personal connections that aren't duplicates
    for (final personalService in _personalConnections) {
      final isDuplicate = systemServices.any((systemService) =>
        systemService.organizationId == personalService.organizationId
      );
      
      if (!isDuplicate) {
        combinedServices.add(personalService);
      }
    }
    
    return combinedServices;
  }

  /// Get services available near user location
  List<SupportService> getServicesNearLocation({
    required double latitude,
    required double longitude,
    double maxDistanceKm = 10.0,
  }) {
    final allServices = getCombinedServices();
    final nearbyServices = <SupportService>[];
    
    for (final service in allServices) {
      if (service.location != null) {
        final distance = _calculateDistance(
          latitude, longitude,
          service.location!.latitude, service.location!.longitude,
        );
        
        if (distance <= maxDistanceKm) {
          nearbyServices.add(service);
        }
      }
    }
    
    // Sort by distance
    nearbyServices.sort((a, b) {
      final distanceA = _calculateDistance(
        latitude, longitude,
        a.location!.latitude, a.location!.longitude,
      );
      final distanceB = _calculateDistance(
        latitude, longitude,
        b.location!.latitude, b.location!.longitude,
      );
      return distanceA.compareTo(distanceB);
    });
    
    return nearbyServices;
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStats() {
    final stats = <String, dynamic>{};
    
    // Count by category
    final categoryCount = <String, int>{};
    for (final service in _personalConnections) {
      for (final tag in service.tags) {
        categoryCount[tag] = (categoryCount[tag] ?? 0) + 1;
      }
    }
    
    // Count by availability
    final availableNow = _personalConnections.where((s) => s.isAvailableNow).length;
    
    stats.addAll({
      'totalPersonalConnections': _personalConnections.length,
      'categoryCounts': categoryCount,
      'availableNow': availableNow,
      'servicesWithLocation': _personalConnections.where((s) => s.location != null).length,
      'emergencyServices': _personalConnections.where((s) => 
        s.tags.contains('emergency') || s.schedules.any((sch) => sch.isEmergency)
      ).length,
      'lastUpdated': _networkMetadata['lastUpdated'],
    });
    
    return stats;
  }

  /// Update organization data (for when organizations update their QR codes)
  Future<bool> updateOrganization(String organizationId, Map<String, dynamic> newData) async {
    try {
      final index = _personalConnections.indexWhere(
        (service) => service.organizationId == organizationId
      );
      
      if (index != -1) {
        final updatedService = SupportService.fromQRCode(newData);
        _personalConnections[index] = updatedService;
        
        await _savePersonalConnections();
        await _updateNetworkMetadata();
        
        debugPrint('🔄 Updated organization: ${updatedService.name}');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error updating organization: $e');
      return false;
    }
  }

  /// Generate QR code data for sharing user's support preferences
  Map<String, dynamic> generateUserQRData({
    required String userName,
    required List<String> supportNeeds,
    required Map<String, dynamic> preferences,
  }) {
    return {
      'type': 'user_support_profile',
      'userName': userName,
      'supportNeeds': supportNeeds,
      'preferences': preferences,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// Check if organization exists in network
  bool hasOrganization(String organizationId) {
    return _personalConnections.any((service) => service.organizationId == organizationId);
  }

  /// Get organization by ID
  SupportService? getOrganization(String organizationId) {
    try {
      return _personalConnections.firstWhere(
        (service) => service.organizationId == organizationId
      );
    } catch (e) {
      return null;
    }
  }

  /// Private methods
  
  Future<void> _loadPersonalConnections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = prefs.getString(_personalConnectionsKey);
      
      if (connectionsJson != null) {
        final connectionsList = jsonDecode(connectionsJson) as List<dynamic>;
        _personalConnections = connectionsList
            .map((data) => SupportService.fromJson(data))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading personal connections: $e');
      _personalConnections = [];
    }
  }

  Future<void> _savePersonalConnections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = jsonEncode(
        _personalConnections.map((service) => service.toJson()).toList()
      );
      await prefs.setString(_personalConnectionsKey, connectionsJson);
    } catch (e) {
      debugPrint('Error saving personal connections: $e');
    }
  }

  Future<void> _loadNetworkMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString(_supportNetworkMetadataKey);
      
      if (metadataJson != null) {
        _networkMetadata = jsonDecode(metadataJson);
      } else {
        _networkMetadata = {
          'createdAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
          'totalScanned': 0,
        };
      }
    } catch (e) {
      debugPrint('Error loading network metadata: $e');
      _networkMetadata = {};
    }
  }

  Future<void> _updateNetworkMetadata() async {
    try {
      _networkMetadata['lastUpdated'] = DateTime.now().toIso8601String();
      _networkMetadata['totalConnections'] = _personalConnections.length;
      _networkMetadata['totalScanned'] = (_networkMetadata['totalScanned'] ?? 0) + 1;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_supportNetworkMetadataKey, jsonEncode(_networkMetadata));
    } catch (e) {
      debugPrint('Error updating network metadata: $e');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    final double lat1Rad = lat1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double deltaLatRad = (lat2 - lat1) * (pi / 180);
    final double deltaLonRad = (lon2 - lon1) * (pi / 180);
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  /// Clear all personal connections (for testing/reset)
  Future<void> clearAllPersonalConnections() async {
    try {
      _personalConnections.clear();
      await _savePersonalConnections();
      await _updateNetworkMetadata();
      debugPrint('🧹 Cleared all personal connections');
    } catch (e) {
      debugPrint('Error clearing personal connections: $e');
    }
  }
}