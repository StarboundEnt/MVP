import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nudge_model.dart';
import '../models/complexity_profile.dart';
import '../models/health_navigation_profile.dart';
import '../models/habit_model.dart';
import '../models/conversation_thread.dart';
import '../models/forecast_model.dart';
import '../models/saved_items_model.dart';
import 'search_service.dart' show HabitLogEntry;

class StorageService {
  static const String _keyComplexityProfile = 'complexity_profile';
  static const String _keyComplexityAssessment = 'complexity_assessment';
  static const String _keyAssessmentHistory = 'assessment_history';
  static const String _keyComplexityTrend = 'complexity_trend';
  static const String _keyComplexityHistory = 'complexity_history';
  static const String _keyHealthNavigationProfile = 'health_navigation_profile'; // NEW
  static const String _keyHabits = 'habits';
  static const String _keyBankedNudges = 'banked_nudges';
  static const String _keyFavoriteActions = 'favorite_actions';
  static const String _keyCompletedActions = 'completed_actions';
  static const String _keyFavoriteServices = 'favorite_services';
  static const String _keyFavoriteResources = 'favorite_resources';
  static const String _keySavedResources = 'saved_resources';
  static const String _keySavedConversations = 'saved_conversations';
  static const String _keyUserName = 'user_name';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyNotificationTime = 'notification_time';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyLastUsed = 'last_used';
  static const String _keyHabitHistory = 'habit_history';
  static const String _keyFreeFormEntries = 'free_form_entries';
  static const String _keyConversationThreads = 'conversation_threads';
  static const String _keyForecastEntries = 'health_forecasts';
  static const String _keyHomeMemoryEnabled = 'home_memory_enabled';
  
  SharedPreferences? _prefs;
  
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
  
  // Complexity Profile
  Future<void> saveComplexityProfile(ComplexityLevel profile) async {
    final p = await prefs;
    await p.setString(_keyComplexityProfile, profile.name);
  }
  
  Future<ComplexityLevel> loadComplexityProfile() async {
    final p = await prefs;
    final profileName = p.getString(_keyComplexityProfile) ?? 'stable';
    return ComplexityLevel.values.firstWhere(
      (e) => e.name == profileName,
      orElse: () => ComplexityLevel.stable,
    );
  }
  
  // Complexity Assessment with Dynamic Analysis
  Future<void> saveComplexityAssessment(ComplexityAssessment assessment) async {
    final p = await prefs;
    final jsonString = jsonEncode(assessment.toJson());
    await p.setString(_keyComplexityAssessment, jsonString);
  }
  
  Future<ComplexityAssessment?> loadComplexityAssessment() async {
    final p = await prefs;
    final jsonString = p.getString(_keyComplexityAssessment);
    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return ComplexityAssessment.fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  // Assessment History
  Future<void> saveAssessmentHistory(List<ComplexityAssessment> history) async {
    final p = await prefs;
    final jsonList = history.map((a) => a.toJson()).toList();
    await p.setString(_keyAssessmentHistory, jsonEncode(jsonList));
  }

  Future<List<ComplexityAssessment>> loadAssessmentHistory() async {
    final p = await prefs;
    final jsonString = p.getString(_keyAssessmentHistory);
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((m) => ComplexityAssessment.fromJson(m))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Complexity Trend Tracking
  Future<void> saveComplexityTrend(Map<ComplexityLevel, double> trend) async {
    final p = await prefs;
    final trendJson = trend.map((level, value) => MapEntry(level.name, value));
    await p.setString(_keyComplexityTrend, jsonEncode(trendJson));
  }

  Future<Map<ComplexityLevel, double>> loadComplexityTrend() async {
    final p = await prefs;
    final jsonString = p.getString(_keyComplexityTrend);
    if (jsonString == null) {
      return {
        for (final level in ComplexityLevel.values) level: 0.0,
      };
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final trend = decoded.map((key, value) {
        final level = ComplexityLevel.values.firstWhere(
          (l) => l.name == key,
          orElse: () => ComplexityLevel.trying,
        );
        return MapEntry(level, (value as num).toDouble());
      });

      for (final level in ComplexityLevel.values) {
        trend.putIfAbsent(level, () => 0.0);
      }

      return trend;
    } catch (e) {
      return {
        for (final level in ComplexityLevel.values) level: 0.0,
      };
    }
  }

  Future<void> saveComplexityHistory(List<ComplexityProfileTransition> history) async {
    final p = await prefs;
    final jsonList = history.map((event) => event.toJson()).toList();
    await p.setString(_keyComplexityHistory, jsonEncode(jsonList));
  }

  Future<List<ComplexityProfileTransition>> loadComplexityHistory() async {
    final p = await prefs;
    final jsonString = p.getString(_keyComplexityHistory);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((json) => ComplexityProfileTransition.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // NEW: Health Navigation Profile
  Future<void> saveHealthNavigationProfile(HealthNavigationProfile profile) async {
    final p = await prefs;
    final jsonString = jsonEncode(profile.toJson());
    await p.setString(_keyHealthNavigationProfile, jsonString);
    await _updateLastUsed();
  }

  Future<HealthNavigationProfile?> loadHealthNavigationProfile() async {
    final p = await prefs;
    final jsonString = p.getString(_keyHealthNavigationProfile);
    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return HealthNavigationProfile.fromJson(decoded);
    } catch (e) {
      debugPrint('Error loading health navigation profile: $e');
      return null;
    }
  }

  // Habits
  Future<void> saveHabits(Map<String, String?> habits) async {
    final p = await prefs;
    final jsonString = jsonEncode(habits);
    await p.setString(_keyHabits, jsonString);
    await _updateLastUsed();
  }
  
  Future<Map<String, String?>> loadHabits() async {
    final p = await prefs;
    final jsonString = p.getString(_keyHabits);
    if (jsonString == null) return {};
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value as String?));
    } catch (e) {
      return {};
    }
  }
  
  Future<void> clearHabits() async {
    final p = await prefs;
    await p.remove(_keyHabits);
  }

  // Forecast entries
  Future<List<ForecastEntry>> loadForecastEntries() async {
    final p = await prefs;
    final jsonString = p.getString(_keyForecastEntries);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ForecastEntry.fromJson)
          .toList();
    } catch (e) {
      debugPrint('StorageService: Failed to load forecasts: $e');
      return [];
    }
  }

  Future<void> saveForecastEntries(List<ForecastEntry> entries) async {
    final p = await prefs;
    final jsonList = entries.map((entry) => entry.toJson()).toList();
    await p.setString(_keyForecastEntries, jsonEncode(jsonList));
    await _updateLastUsed();
  }

  Future<void> saveHomeMemoryEnabled(bool enabled) async {
    final p = await prefs;
    await p.setBool(_keyHomeMemoryEnabled, enabled);
  }

  Future<bool> loadHomeMemoryEnabled() async {
    final p = await prefs;
    return p.getBool(_keyHomeMemoryEnabled) ?? true;
  }

  Future<void> addForecastEntry(ForecastEntry entry,
      {int maxEntries = 16}) async {
    final existing = await loadForecastEntries();

    // Remove any entry that matches the new id to prevent duplicates
    final filtered = existing.where((e) => e.id != entry.id).toList();
    filtered.insert(0, entry);

    if (maxEntries > 0 && filtered.length > maxEntries) {
      filtered.removeRange(maxEntries, filtered.length);
    }

    await saveForecastEntries(filtered);
  }

  // Banked Nudges
  Future<void> saveBankedNudges(List<StarboundNudge> nudges) async {
    final p = await prefs;
    final jsonList = nudges.map((nudge) => _nudgeToJson(nudge)).toList();
    await p.setString(_keyBankedNudges, jsonEncode(jsonList));
  }
  
  Future<List<StarboundNudge>> loadBankedNudges() async {
    final p = await prefs;
    final jsonString = p.getString(_keyBankedNudges);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((json) => _nudgeFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Favorite Actions
  Future<void> saveFavoriteActions(List<String> actions) async {
    final p = await prefs;
    await p.setStringList(_keyFavoriteActions, actions);
  }

  Future<List<String>> loadFavoriteActions() async {
    final p = await prefs;
    return p.getStringList(_keyFavoriteActions) ?? [];
  }

  // Completed Actions
  Future<void> saveCompletedActions(List<String> actions) async {
    final p = await prefs;
    await p.setStringList(_keyCompletedActions, actions);
  }

  Future<List<String>> loadCompletedActions() async {
    final p = await prefs;
    return p.getStringList(_keyCompletedActions) ?? [];
  }
  
  // Favorite Services
  Future<void> saveFavoriteServices(List<String> services) async {
    final p = await prefs;
    await p.setStringList(_keyFavoriteServices, services);
  }
  
  Future<List<String>> loadFavoriteServices() async {
    final p = await prefs;
    return p.getStringList(_keyFavoriteServices) ?? [];
  }

  // Favorite Resources (Health Resources)
  Future<void> saveFavoriteResources(List<String> resourceIds) async {
    final p = await prefs;
    await p.setStringList(_keyFavoriteResources, resourceIds);
  }

  Future<List<String>> loadFavoriteResources() async {
    final p = await prefs;
    return p.getStringList(_keyFavoriteResources) ?? [];
  }

  // Saved Resources (with notes and metadata)
  Future<void> saveSavedResources(List<SavedResource> resources) async {
    final p = await prefs;
    final jsonList = resources.map((r) => r.toJson()).toList();
    await p.setString(_keySavedResources, jsonEncode(jsonList));
    await _updateLastUsed();
  }

  Future<List<SavedResource>> loadSavedResources() async {
    final p = await prefs;
    final jsonString = p.getString(_keySavedResources);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((json) => SavedResource.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading saved resources: $e');
      return [];
    }
  }

  Future<void> addSavedResource(SavedResource resource) async {
    final existing = await loadSavedResources();
    // Check if resource already saved (by resourceId)
    if (existing.any((r) => r.resourceId == resource.resourceId)) {
      return; // Already saved
    }
    existing.insert(0, resource);
    await saveSavedResources(existing);
  }

  Future<void> removeSavedResource(String resourceId) async {
    final existing = await loadSavedResources();
    existing.removeWhere((r) => r.resourceId == resourceId);
    await saveSavedResources(existing);
  }

  Future<void> updateSavedResource(SavedResource updated) async {
    final existing = await loadSavedResources();
    final index = existing.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      existing[index] = updated;
      await saveSavedResources(existing);
    }
  }

  Future<bool> isResourceSaved(String resourceId) async {
    final existing = await loadSavedResources();
    return existing.any((r) => r.resourceId == resourceId);
  }

  // Saved Conversations (health Q&A)
  Future<void> saveSavedConversations(List<SavedConversation> conversations) async {
    final p = await prefs;
    final jsonList = conversations.map((c) => c.toJson()).toList();
    await p.setString(_keySavedConversations, jsonEncode(jsonList));
    await _updateLastUsed();
  }

  Future<List<SavedConversation>> loadSavedConversations() async {
    final p = await prefs;
    final jsonString = p.getString(_keySavedConversations);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((json) => SavedConversation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading saved conversations: $e');
      return [];
    }
  }

  Future<void> addSavedConversation(SavedConversation conversation) async {
    final existing = await loadSavedConversations();
    // Check if conversation already saved (by id)
    if (existing.any((c) => c.id == conversation.id)) {
      return; // Already saved
    }
    existing.insert(0, conversation);
    await saveSavedConversations(existing);
  }

  Future<void> removeSavedConversation(String conversationId) async {
    final existing = await loadSavedConversations();
    existing.removeWhere((c) => c.id == conversationId);
    await saveSavedConversations(existing);
  }

  Future<void> updateSavedConversation(SavedConversation updated) async {
    final existing = await loadSavedConversations();
    final index = existing.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      existing[index] = updated;
      await saveSavedConversations(existing);
    }
  }

  Future<SavedConversation?> getSavedConversation(String conversationId) async {
    final existing = await loadSavedConversations();
    try {
      return existing.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  // Free-form Entries
  Future<void> saveFreeFormEntries(List<FreeFormEntry> entries) async {
    final p = await prefs;
    final jsonList = entries.map((entry) => entry.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await p.setString(_keyFreeFormEntries, jsonString);
    await _updateLastUsed();
  }

  Future<List<FreeFormEntry>> loadFreeFormEntries() async {
    final p = await prefs;
    final jsonString = p.getString(_keyFreeFormEntries);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((json) => FreeFormEntry.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Conversation Threads
  Future<void> saveConversationThread(ConversationThread thread) async {
    final p = await prefs;
    
    // Load existing threads
    final existingThreads = await loadConversationThreads();
    
    // Check if thread already exists (update) or add new
    final existingIndex = existingThreads.indexWhere((t) => t.id == thread.id);
    if (existingIndex != -1) {
      existingThreads[existingIndex] = thread;
    } else {
      existingThreads.add(thread);
    }
    
    // Sort by last activity (most recent first)
    existingThreads.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    
    // Keep only the most recent 50 threads to prevent storage bloat
    final threadsToSave = existingThreads.take(50).toList();
    
    // Convert to JSON and save
    final jsonList = threadsToSave.map((thread) => thread.toJson()).toList();
    await p.setString(_keyConversationThreads, jsonEncode(jsonList));
    await _updateLastUsed();
  }
  
  Future<List<ConversationThread>> loadConversationThreads() async {
    final p = await prefs;
    final jsonString = p.getString(_keyConversationThreads);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      final threads = decoded.map((json) => ConversationThread.fromJson(json)).toList();
      
      // Sort by last activity (most recent first)
      threads.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      return threads;
    } catch (e) {
      return [];
    }
  }
  
  Future<ConversationThread?> loadConversationThread(String threadId) async {
    final threads = await loadConversationThreads();
    try {
      return threads.firstWhere((thread) => thread.id == threadId);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> deleteConversationThread(String threadId) async {
    final threads = await loadConversationThreads();
    threads.removeWhere((thread) => thread.id == threadId);
    
    final p = await prefs;
    final jsonList = threads.map((thread) => thread.toJson()).toList();
    await p.setString(_keyConversationThreads, jsonEncode(jsonList));
  }
  
  Future<void> clearConversationThreads() async {
    final p = await prefs;
    await p.remove(_keyConversationThreads);
  }
  
  Future<List<ConversationThread>> searchConversationThreads(String query) async {
    final threads = await loadConversationThreads();
    final lowercaseQuery = query.toLowerCase();
    
    return threads.where((thread) {
      final titleMatch = thread.title.toLowerCase().contains(lowercaseQuery);
      final topicMatch = thread.mainTopic?.toLowerCase().contains(lowercaseQuery) ?? false;
      final exchangeMatch = thread.exchanges.any((exchange) => 
        exchange.question.toLowerCase().contains(lowercaseQuery) ||
        exchange.response.overview.toLowerCase().contains(lowercaseQuery)
      );
      
      return titleMatch || topicMatch || exchangeMatch;
    }).toList();
  }

  // Search helper methods for unified search
  Future<List<FreeFormEntry>> getAllFreeFormEntries() async {
    return await loadFreeFormEntries();
  }

  Future<List<ConversationThread>> getAllConversationThreads() async {
    return await loadConversationThreads();
  }

  Future<List<HabitLogEntry>> getAllHabitEntries() async {
    // This is a placeholder as habit entries might be stored differently
    // For now, return empty list until proper habit log storage is implemented
    return [];
  }
  
  // User Name
  Future<void> saveUserName(String name) async {
    final p = await prefs;
    await p.setString(_keyUserName, name);
  }
  
  Future<String> loadUserName() async {
    final p = await prefs;
    return p.getString(_keyUserName) ?? 'Explorer';
  }
  
  // Notification Settings
  Future<void> saveNotificationSettings(bool enabled, String time) async {
    final p = await prefs;
    await p.setBool(_keyNotificationsEnabled, enabled);
    await p.setString(_keyNotificationTime, time);
  }
  
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    final p = await prefs;
    return {
      'enabled': p.getBool(_keyNotificationsEnabled) ?? true,
      'time': p.getString(_keyNotificationTime) ?? '19:00',
    };
  }
  
  // Onboarding and First Launch
  Future<void> setOnboardingComplete(bool complete) async {
    final p = await prefs;
    await p.setBool(_keyOnboardingComplete, complete);
  }
  
  Future<bool> isOnboardingComplete() async {
    final p = await prefs;
    return p.getBool(_keyOnboardingComplete) ?? false;
  }
  
  Future<void> setFirstLaunch(bool isFirst) async {
    final p = await prefs;
    await p.setBool(_keyFirstLaunch, isFirst);
  }
  
  Future<bool> isFirstLaunch() async {
    final p = await prefs;
    return p.getBool(_keyFirstLaunch) ?? true;
  }
  
  // Usage Analytics
  Future<void> _updateLastUsed() async {
    final p = await prefs;
    await p.setString(_keyLastUsed, DateTime.now().toIso8601String());
  }
  
  Future<DateTime?> getLastUsed() async {
    final p = await prefs;
    final dateString = p.getString(_keyLastUsed);
    if (dateString == null) return null;
    
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  // Clear all data
  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
  
  // Helper methods for serialization
  Map<String, dynamic> _nudgeToJson(StarboundNudge nudge) {
    return {
      'id': nudge.id,
      'theme': nudge.theme,
      'message': nudge.message,
      'tone': nudge.tone,
      'estimatedTime': nudge.estimatedTime,
      'energyRequired': nudge.energyRequired,
      'complexityProfileFit': nudge.complexityProfileFit,
      'triggersFrom': nudge.triggersFrom,
    };
  }
  
  StarboundNudge _nudgeFromJson(Map<String, dynamic> json) {
    return StarboundNudge(
      id: json['id'],
      theme: json['theme'],
      message: json['message'],
      tone: json['tone'] ?? 'gentle',
      estimatedTime: json['estimatedTime'] ?? '<1 min',
      energyRequired: json['energyRequired'] ?? 'low',
      complexityProfileFit: List<String>.from(json['complexityProfileFit'] ?? ['stable']),
      triggersFrom: List<String>.from(json['triggersFrom'] ?? []),
    );
  }
  
  // Data export/import (for user data portability)
  Future<Map<String, dynamic>> exportUserData() async {
    final p = await prefs;
    final keys = p.getKeys();
    final data = <String, dynamic>{};
    
    for (final key in keys) {
      final value = p.get(key);
      if (value != null) {
        data[key] = value;
      }
    }
    
    return data;
  }
  
  Future<void> importUserData(Map<String, dynamic> data) async {
    final p = await prefs;
    await p.clear();
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String) {
        await p.setString(key, value);
      } else if (value is int) {
        await p.setInt(key, value);
      } else if (value is double) {
        await p.setDouble(key, value);
      } else if (value is bool) {
        await p.setBool(key, value);
      } else if (value is List<String>) {
        await p.setStringList(key, value);
      }
    }
  }
  
  // Habit History for Local Analytics
  Future<void> saveHabitEntry(String habitKey, String value, DateTime date) async {
    final p = await prefs;
    final dateKey = _formatDateKey(date);
    final historyKey = '${_keyHabitHistory}_${dateKey}';
    
    // Load existing entries for this date
    final existingJson = p.getString(historyKey) ?? '{}';
    final existingEntries = Map<String, String>.from(jsonDecode(existingJson));
    
    // Add or update the habit entry
    existingEntries[habitKey] = value;
    
    // Save back to storage
    await p.setString(historyKey, jsonEncode(existingEntries));
  }
  
  Future<Map<String, String>> getHabitEntriesForDate(DateTime date) async {
    final p = await prefs;
    final dateKey = _formatDateKey(date);
    final historyKey = '${_keyHabitHistory}_${dateKey}';
    
    final entriesJson = p.getString(historyKey) ?? '{}';
    return Map<String, String>.from(jsonDecode(entriesJson));
  }
  
  Future<Map<DateTime, Map<String, String>>> getHabitHistoryRange(DateTime startDate, DateTime endDate) async {
    final p = await prefs;
    final history = <DateTime, Map<String, String>>{};
    
    // Get all habit history keys
    final allKeys = p.getKeys().where((key) => key.startsWith(_keyHabitHistory));
    
    for (final key in allKeys) {
      final dateStr = key.substring('${_keyHabitHistory}_'.length);
      final date = _parseDateKey(dateStr);
      
      if (date != null && 
          (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
          (date.isBefore(endDate) || date.isAtSameMomentAs(endDate))) {
        final entriesJson = p.getString(key) ?? '{}';
        history[date] = Map<String, String>.from(jsonDecode(entriesJson));
      }
    }
    
    return history;
  }
  
  Future<int> calculateHabitStreak(String habitKey, DateTime endDate) async {
    int streak = 0;
    DateTime currentDate = endDate;
    
    // Check backwards from end date until we find a gap
    while (true) {
      final entries = await getHabitEntriesForDate(currentDate);
      final value = entries[habitKey];
      
      // If habit was tracked and has a positive value, continue streak
      if (value != null && value.isNotEmpty && value != 'skipped' && value != 'poor') {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
      
      // Safety limit to prevent infinite loops
      if (streak > 365) break;
    }
    
    return streak;
  }
  
  Future<List<String>> getHabitTrendData(String habitKey, int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final history = await getHabitHistoryRange(startDate, endDate);
    
    final trendData = <String>[];
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      final entries = history[dateKey] ?? {};
      final value = entries[habitKey];
      
      if (value != null && value.isNotEmpty) {
        trendData.add(value);
      }
    }
    
    return trendData;
  }
  
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  DateTime? _parseDateKey(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }

  // Direct SharedPreferences wrapper methods for compatibility
  Future<bool> containsKey(String key) async {
    final p = await prefs;
    return p.containsKey(key);
  }

  Future<Set<String>> getKeys() async {
    final p = await prefs;
    return p.getKeys();
  }

  Future<String?> getString(String key, {String? defaultValue}) async {
    final p = await prefs;
    return p.getString(key) ?? defaultValue;
  }

  Future<bool> setString(String key, String value) async {
    final p = await prefs;
    return await p.setString(key, value);
  }

  Future<int?> getInt(String key, {int? defaultValue}) async {
    final p = await prefs;
    return p.getInt(key) ?? defaultValue;
  }

  Future<bool> setInt(String key, int value) async {
    final p = await prefs;
    return await p.setInt(key, value);
  }

  Future<bool?> getBool(String key, {bool? defaultValue}) async {
    final p = await prefs;
    return p.getBool(key) ?? defaultValue;
  }

  Future<bool> setBool(String key, bool value) async {
    final p = await prefs;
    return await p.setBool(key, value);
  }

  Future<double?> getDouble(String key, {double? defaultValue}) async {
    final p = await prefs;
    return p.getDouble(key) ?? defaultValue;
  }

  Future<bool> setDouble(String key, double value) async {
    final p = await prefs;
    return await p.setDouble(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    final p = await prefs;
    return p.getStringList(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    final p = await prefs;
    return await p.setStringList(key, value);
  }

  Future<bool> remove(String key) async {
    final p = await prefs;
    return await p.remove(key);
  }

  Future<void> clearAllData() async {
    final p = await prefs;
    await p.clear();
  }

  Future<bool> clear() async {
    final p = await prefs;
    return await p.clear();
  }
}
