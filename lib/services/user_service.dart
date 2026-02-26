import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/complexity_profile.dart';

class UserService {
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _displayNameKey = 'display_name';
  static const String _complexityProfileKey = 'complexity_profile';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _deviceIdKey = 'device_id';
  
  final ApiService _apiService = ApiService();
  
  // Current user session
  int? _currentUserId;
  String? _currentUsername;
  String? _currentDisplayName;
  ComplexityLevel? _currentComplexityProfile;
  bool _isOnboardingComplete = false;
  
  // Getters
  int? get currentUserId => _currentUserId;
  String? get currentUsername => _currentUsername;
  String? get currentDisplayName => _currentDisplayName;
  ComplexityLevel? get currentComplexityProfile => _currentComplexityProfile;
  bool get isOnboardingComplete => _isOnboardingComplete;
  bool get isLoggedIn => _currentUserId != null;
  
  // Initialize user session from local storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentUserId = prefs.getInt(_userIdKey);
    _currentUsername = prefs.getString(_usernameKey);
    _currentDisplayName = prefs.getString(_displayNameKey);
    _isOnboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;
    
    final complexityProfileString = prefs.getString(_complexityProfileKey);
    if (complexityProfileString != null) {
      _currentComplexityProfile = ComplexityLevel.values.firstWhere(
        (level) => level.name == complexityProfileString,
        orElse: () => ComplexityLevel.stable,
      );
    }
  }
  
  // Create or login user
  Future<void> createOrLoginUser({
    required String username,
    required String displayName,
    required ComplexityLevel complexityProfile,
  }) async {
    try {
      // Try to get existing user first
      Map<String, dynamic> userData;
      try {
        userData = await _apiService.getUserByUsername(username);
      } catch (e) {
        // User doesn't exist, create new one
        userData = await _apiService.createUser(
          username: username,
          displayName: displayName,
          complexityProfile: complexityProfile.name,
        );
      }
      
      // Set current user data
      _currentUserId = userData['id'];
      _currentUsername = userData['username'];
      _currentDisplayName = userData['display_name'];
      _isOnboardingComplete = userData['onboarding_complete'] ?? false;
      
      final profileString = userData['complexity_profile'];
      _currentComplexityProfile = ComplexityLevel.values.firstWhere(
        (level) => level.name == profileString,
        orElse: () => ComplexityLevel.stable,
      );
      
      // Save to local storage
      await _saveUserDataToLocal();
    } catch (e) {
      throw Exception('Failed to create or login user: $e');
    }
  }
  
  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    ComplexityLevel? complexityProfile,
    bool? notificationsEnabled,
    String? notificationTime,
  }) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }
    
    try {
      final userData = await _apiService.updateUser(
        userId: _currentUserId!,
        displayName: displayName,
        complexityProfile: complexityProfile?.name,
        notificationsEnabled: notificationsEnabled,
        notificationTime: notificationTime,
      );
      
      // Update local data
      if (displayName != null) _currentDisplayName = displayName;
      if (complexityProfile != null) _currentComplexityProfile = complexityProfile;
      
      await _saveUserDataToLocal();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
  
  // Complete onboarding
  Future<void> completeOnboarding() async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }
    
    try {
      await _apiService.completeOnboarding(_currentUserId!);
      _isOnboardingComplete = true;
      await _saveUserDataToLocal();
    } catch (e) {
      throw Exception('Failed to complete onboarding: $e');
    }
  }
  
  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear local storage
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_complexityProfileKey);
    await prefs.remove(_onboardingCompleteKey);
    
    // Clear session data
    _currentUserId = null;
    _currentUsername = null;
    _currentDisplayName = null;
    _currentComplexityProfile = null;
    _isOnboardingComplete = false;
  }
  
  // Save user data to local storage
  Future<void> _saveUserDataToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_currentUserId != null) {
      await prefs.setInt(_userIdKey, _currentUserId!);
    }
    if (_currentUsername != null) {
      await prefs.setString(_usernameKey, _currentUsername!);
    }
    if (_currentDisplayName != null) {
      await prefs.setString(_displayNameKey, _currentDisplayName!);
    }
    if (_currentComplexityProfile != null) {
      await prefs.setString(_complexityProfileKey, _currentComplexityProfile!.name);
    }
    await prefs.setBool(_onboardingCompleteKey, _isOnboardingComplete);
  }
  
  // Check if server is available
  Future<bool> isServerAvailable() async {
    return await _apiService.isServerHealthy();
  }

  // Get or create a stable device-based unique ID
  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_deviceIdKey);
    if (stored != null && stored.isNotEmpty) return stored;
    final id = _generateUuid();
    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  static String _generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}