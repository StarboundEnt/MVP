import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complexity_profile.dart';
import 'storage_service.dart';

enum AchievementCategory {
  streak,      // Consecutive days
  consistency, // Overall completion rate
  milestone,   // Special moments
  growth,      // Personal progress
  discovery,   // New habits or insights
  resilience,  // Bouncing back from setbacks
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final AchievementTier tier;
  final int points;
  final DateTime? unlockedAt;
  final Map<String, dynamic> metadata;
  final bool isSecret; // Hidden until unlocked
  final ComplexityLevel? requiredComplexity; // Minimum complexity to see this achievement
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.tier,
    required this.points,
    this.unlockedAt,
    this.metadata = const {},
    this.isSecret = false,
    this.requiredComplexity,
  });
  
  bool get isUnlocked => unlockedAt != null;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'emoji': emoji,
    'category': category.index,
    'tier': tier.index,
    'points': points,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'metadata': metadata,
    'isSecret': isSecret,
    'requiredComplexity': requiredComplexity?.index,
  };
  
  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    emoji: json['emoji'],
    category: AchievementCategory.values[json['category']],
    tier: AchievementTier.values[json['tier']],
    points: json['points'],
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    isSecret: json['isSecret'] ?? false,
    requiredComplexity: json['requiredComplexity'] != null 
        ? ComplexityLevel.values[json['requiredComplexity']] 
        : null,
  );
  
  Achievement unlock({Map<String, dynamic>? additionalMetadata}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      emoji: emoji,
      category: category,
      tier: tier,
      points: points,
      unlockedAt: DateTime.now(),
      metadata: {...metadata, ...?additionalMetadata},
      isSecret: isSecret,
      requiredComplexity: requiredComplexity,
    );
  }
}

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();
  
  final StorageService _storageService = StorageService();
  static const String _achievementsKey = 'user_achievements';
  
  List<Achievement> _userAchievements = [];
  final List<Achievement> _allAchievements = [];
  
  // Initialize with predefined achievements
  Future<void> initialize() async {
    _defineAchievements();
    await _loadUserAchievements();
  }
  
  // Define all possible achievements
  void _defineAchievements() {
    _allAchievements.clear();
    
    // STREAK ACHIEVEMENTS
    _allAchievements.addAll([
      Achievement(
        id: 'first_step',
        title: 'First Step',
        description: 'Complete your first habit entry',
        emoji: '👣',
        category: AchievementCategory.milestone,
        tier: AchievementTier.bronze,
        points: 10,
      ),
      
      Achievement(
        id: 'streak_3',
        title: 'Getting Started',
        description: 'Maintain a 3-day streak',
        emoji: '🔥',
        category: AchievementCategory.streak,
        tier: AchievementTier.bronze,
        points: 25,
      ),
      
      Achievement(
        id: 'streak_7',
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        emoji: '🏆',
        category: AchievementCategory.streak,
        tier: AchievementTier.silver,
        points: 50,
      ),
      
      Achievement(
        id: 'streak_30',
        title: 'Month Master',
        description: 'Maintain a 30-day streak',
        emoji: '👑',
        category: AchievementCategory.streak,
        tier: AchievementTier.gold,
        points: 150,
      ),
      
      Achievement(
        id: 'streak_100',
        title: 'Century Achiever',
        description: 'Maintain a 100-day streak',
        emoji: '💎',
        category: AchievementCategory.streak,
        tier: AchievementTier.diamond,
        points: 500,
        isSecret: true,
      ),
    ]);
    
    // CONSISTENCY ACHIEVEMENTS
    _allAchievements.addAll([
      Achievement(
        id: 'consistent_week',
        title: 'Steady Progress',
        description: 'Complete 80% of habits for a week',
        emoji: '📈',
        category: AchievementCategory.consistency,
        tier: AchievementTier.bronze,
        points: 30,
      ),
      
      Achievement(
        id: 'consistent_month',
        title: 'Reliability Champion',
        description: 'Complete 75% of habits for a month',
        emoji: '🎯',
        category: AchievementCategory.consistency,
        tier: AchievementTier.silver,
        points: 100,
      ),
      
      Achievement(
        id: 'perfectionist',
        title: 'Perfectionist',
        description: 'Complete 100% of habits for a week',
        emoji: '⭐',
        category: AchievementCategory.consistency,
        tier: AchievementTier.gold,
        points: 200,
      ),
    ]);
    
    // MILESTONE ACHIEVEMENTS
    _allAchievements.addAll([
      Achievement(
        id: 'habit_collector',
        title: 'Habit Collector',
        description: 'Track 5 different habits',
        emoji: '📝',
        category: AchievementCategory.milestone,
        tier: AchievementTier.bronze,
        points: 40,
      ),
      
      Achievement(
        id: 'custom_creator',
        title: 'Custom Creator',
        description: 'Create your first custom habit',
        emoji: '🎨',
        category: AchievementCategory.discovery,
        tier: AchievementTier.silver,
        points: 60,
      ),
      
      Achievement(
        id: 'week_perfect',
        title: 'Perfect Week',
        description: 'Complete all habits every day for a week',
        emoji: '🌟',
        category: AchievementCategory.milestone,
        tier: AchievementTier.gold,
        points: 250,
      ),
    ]);
    
    // GROWTH ACHIEVEMENTS
    _allAchievements.addAll([
      Achievement(
        id: 'comeback_kid',
        title: 'Comeback Kid',
        description: 'Start a new streak after missing days',
        emoji: '💪',
        category: AchievementCategory.resilience,
        tier: AchievementTier.silver,
        points: 75,
      ),
      
      Achievement(
        id: 'habit_evolution',
        title: 'Evolution',
        description: 'Improve from survival to trying complexity',
        emoji: '🦋',
        category: AchievementCategory.growth,
        tier: AchievementTier.gold,
        points: 150,
        requiredComplexity: ComplexityLevel.trying,
      ),
      
      Achievement(
        id: 'stability_master',
        title: 'Stability Master',
        description: 'Reach stable complexity level',
        emoji: '🧘',
        category: AchievementCategory.growth,
        tier: AchievementTier.platinum,
        points: 300,
        requiredComplexity: ComplexityLevel.stable,
      ),
    ]);
    
    // DISCOVERY ACHIEVEMENTS
    _allAchievements.addAll([
      Achievement(
        id: 'pattern_finder',
        title: 'Pattern Finder',
        description: 'Discover your first habit correlation',
        emoji: '🔍',
        category: AchievementCategory.discovery,
        tier: AchievementTier.silver,
        points: 80,
        requiredComplexity: ComplexityLevel.trying,
      ),
      
      Achievement(
        id: 'insight_seeker',
        title: 'Insight Seeker',
        description: 'View your analytics dashboard 10 times',
        emoji: '📊',
        category: AchievementCategory.discovery,
        tier: AchievementTier.bronze,
        points: 35,
      ),
      
      Achievement(
        id: 'synergy_master',
        title: 'Synergy Master',
        description: 'Build habits with strong positive correlations',
        emoji: '🔗',
        category: AchievementCategory.discovery,
        tier: AchievementTier.gold,
        points: 200,
        isSecret: true,
        requiredComplexity: ComplexityLevel.stable,
      ),
    ]);
    
    // COMPLEXITY-SPECIFIC ACHIEVEMENTS
    _allAchievements.addAll([
      Achievement(
        id: 'gentle_progress',
        title: 'Gentle Progress',
        description: 'Complete any habit 3 days in a row while in survival mode',
        emoji: '🌱',
        category: AchievementCategory.resilience,
        tier: AchievementTier.gold,
        points: 100,
        requiredComplexity: ComplexityLevel.survival,
      ),
      
      Achievement(
        id: 'overload_warrior',
        title: 'Overload Warrior',
        description: 'Maintain habits during overloaded period',
        emoji: '⚡',
        category: AchievementCategory.resilience,
        tier: AchievementTier.platinum,
        points: 250,
        requiredComplexity: ComplexityLevel.overloaded,
      ),
    ]);
  }
  
  // Check and unlock achievements based on user progress
  Future<List<Achievement>> checkForNewAchievements({
    required Map<String, String?> currentHabits,
    required Map<String, int> habitStreaks,
    required ComplexityLevel complexityProfile,
    required List<dynamic> correlations,
  }) async {
    final newAchievements = <Achievement>[];
    
    for (final achievement in _allAchievements) {
      // Skip if already unlocked
      if (_isAchievementUnlocked(achievement.id)) continue;
      
      // Skip if user's complexity level is too low
      if (achievement.requiredComplexity != null &&
          _getComplexityIndex(complexityProfile) < _getComplexityIndex(achievement.requiredComplexity!)) {
        continue;
      }
      
      final shouldUnlock = await _checkAchievementCondition(
        achievement,
        currentHabits,
        habitStreaks,
        complexityProfile,
        correlations,
      );
      
      if (shouldUnlock) {
        final unlockedAchievement = achievement.unlock();
        newAchievements.add(unlockedAchievement);
        _userAchievements.add(unlockedAchievement);
      }
    }
    
    if (newAchievements.isNotEmpty) {
      await _saveUserAchievements();
    }
    
    return newAchievements;
  }
  
  // Check specific achievement condition
  Future<bool> _checkAchievementCondition(
    Achievement achievement,
    Map<String, String?> currentHabits,
    Map<String, int> habitStreaks,
    ComplexityLevel complexityProfile,
    List<dynamic> correlations,
  ) async {
    switch (achievement.id) {
      case 'first_step':
        return currentHabits.values.any((value) => value != null && value.isNotEmpty);
        
      case 'streak_3':
        return habitStreaks.values.any((streak) => streak >= 3);
        
      case 'streak_7':
        return habitStreaks.values.any((streak) => streak >= 7);
        
      case 'streak_30':
        return habitStreaks.values.any((streak) => streak >= 30);
        
      case 'streak_100':
        return habitStreaks.values.any((streak) => streak >= 100);
        
      case 'consistent_week':
        return await _checkWeeklyConsistency(0.8);
        
      case 'consistent_month':
        return await _checkMonthlyConsistency(0.75);
        
      case 'perfectionist':
        return await _checkWeeklyConsistency(1.0);
        
      case 'habit_collector':
        return currentHabits.length >= 5;
        
      case 'custom_creator':
        // Check if user has created any custom habits
        return await _hasCustomHabits();
        
      case 'week_perfect':
        return await _checkPerfectWeek();
        
      case 'comeback_kid':
        return await _checkComebackPattern(habitStreaks);
        
      case 'habit_evolution':
        return complexityProfile == ComplexityLevel.trying;
        
      case 'stability_master':
        return complexityProfile == ComplexityLevel.stable;
        
      case 'pattern_finder':
        return correlations.isNotEmpty;
        
      case 'insight_seeker':
        return await _checkAnalyticsViews();
        
      case 'synergy_master':
        return await _checkSynergyPattern(correlations);
        
      case 'gentle_progress':
        return complexityProfile == ComplexityLevel.survival && 
               habitStreaks.values.any((streak) => streak >= 3);
        
      case 'overload_warrior':
        return complexityProfile == ComplexityLevel.overloaded &&
               habitStreaks.values.any((streak) => streak >= 7);
        
      default:
        return false;
    }
  }
  
  // Helper methods for achievement checking
  Future<bool> _checkWeeklyConsistency(double threshold) async {
    // Check last 7 days completion rate
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    
    int totalPossible = 0;
    int totalCompleted = 0;
    
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final entries = await _storageService.getHabitEntriesForDate(date);
      
      for (final value in entries.values) {
        totalPossible++;
        if (value != null && value.isNotEmpty && value != 'skipped' && value != 'poor') {
          totalCompleted++;
        }
      }
    }
    
    return totalPossible > 0 && (totalCompleted / totalPossible) >= threshold;
  }
  
  Future<bool> _checkMonthlyConsistency(double threshold) async {
    // Check last 30 days completion rate
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    
    int totalPossible = 0;
    int totalCompleted = 0;
    
    for (int i = 0; i < 30; i++) {
      final date = startDate.add(Duration(days: i));
      final entries = await _storageService.getHabitEntriesForDate(date);
      
      for (final value in entries.values) {
        totalPossible++;
        if (value != null && value.isNotEmpty && value != 'skipped' && value != 'poor') {
          totalCompleted++;
        }
      }
    }
    
    return totalPossible > 0 && (totalCompleted / totalPossible) >= threshold;
  }
  
  Future<bool> _hasCustomHabits() async {
    // This would check if any custom habits have been created
    // For now, we'll simulate based on habit count > default habits
    return false; // Placeholder - would need integration with custom habit tracking
  }
  
  Future<bool> _checkPerfectWeek() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final entries = await _storageService.getHabitEntriesForDate(date);
      
      if (entries.isEmpty) return false;
      
      for (final value in entries.values) {
        if (value == null || value.isEmpty || value == 'skipped' || value == 'poor') {
          return false;
        }
      }
    }
    
    return true;
  }
  
  Future<bool> _checkComebackPattern(Map<String, int> habitStreaks) async {
    // Check if user has restarted a habit after a break
    // This would require more sophisticated tracking
    return habitStreaks.values.any((streak) => streak >= 3); // Simplified
  }
  
  Future<bool> _checkAnalyticsViews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final views = prefs.getInt('analytics_views') ?? 0;
      return views >= 10;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _checkSynergyPattern(List<dynamic> correlations) async {
    // Check for strong positive correlations
    return correlations.any((correlation) {
      if (correlation is Map<String, dynamic>) {
        final strength = correlation['strength'] as double? ?? 0.0;
        final type = correlation['type'] as String? ?? '';
        return type == 'positive' && strength >= 0.7;
      }
      return false;
    });
  }
  
  // Increment analytics views
  Future<void> incrementAnalyticsViews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final views = prefs.getInt('analytics_views') ?? 0;
      await prefs.setInt('analytics_views', views + 1);
    } catch (e) {
      debugPrint('Error incrementing analytics views: $e');
    }
  }
  
  // Helper to get complexity index for comparison
  int _getComplexityIndex(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.survival: return 0;
      case ComplexityLevel.overloaded: return 1;
      case ComplexityLevel.trying: return 2;
      case ComplexityLevel.stable: return 3;
    }
  }
  
  // Check if achievement is already unlocked
  bool _isAchievementUnlocked(String achievementId) {
    return _userAchievements.any((a) => a.id == achievementId);
  }
  
  // Load user achievements from storage
  Future<void> _loadUserAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsJson = prefs.getString(_achievementsKey);
      
      if (achievementsJson != null) {
        final achievementsData = jsonDecode(achievementsJson) as List;
        _userAchievements = achievementsData
            .map((data) => Achievement.fromJson(data))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading user achievements: $e');
      _userAchievements = [];
    }
  }
  
  // Save user achievements to storage
  Future<void> _saveUserAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final achievementsData = _userAchievements.map((a) => a.toJson()).toList();
      await prefs.setString(_achievementsKey, jsonEncode(achievementsData));
    } catch (e) {
      debugPrint('Error saving user achievements: $e');
    }
  }
  
  // Public getters
  List<Achievement> get unlockedAchievements => 
      _userAchievements.where((a) => a.isUnlocked).toList();
  
  List<Achievement> getAvailableAchievements(ComplexityLevel userComplexity) {
    return _allAchievements.where((achievement) {
      // Filter out secret achievements that aren't unlocked
      if (achievement.isSecret && !_isAchievementUnlocked(achievement.id)) {
        return false;
      }
      
      // Filter by complexity level
      if (achievement.requiredComplexity != null &&
          _getComplexityIndex(userComplexity) < _getComplexityIndex(achievement.requiredComplexity!)) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _allAchievements.where((a) => a.category == category).toList();
  }
  
  List<Achievement> getUnlockableAchievements({
    required Map<String, String?> currentHabits,
    required ComplexityLevel complexityProfile,
  }) {
    return _allAchievements.where((achievement) {
      // Skip if already unlocked
      if (_isAchievementUnlocked(achievement.id)) return false;
      
      // Skip if user's complexity level is too low
      if (achievement.requiredComplexity != null &&
          _getComplexityIndex(complexityProfile) < _getComplexityIndex(achievement.requiredComplexity!)) {
        return false;
      }
      
      // Skip secret achievements
      if (achievement.isSecret) return false;
      
      return true;
    }).toList();
  }
  
  int get totalPoints => _userAchievements.fold(0, (sum, a) => sum + a.points);
  
  int get unlockedCount => _userAchievements.length;
  
  Achievement? getAchievement(String id) {
    try {
      return _allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get user's achievement progress
  Map<String, dynamic> getAchievementStats(ComplexityLevel userComplexity) {
    final available = getAvailableAchievements(userComplexity);
    final unlocked = unlockedAchievements;
    
    return {
      'total_available': available.length,
      'unlocked': unlocked.length,
      'completion_rate': available.isNotEmpty ? unlocked.length / available.length : 0.0,
      'total_points': totalPoints,
      'by_category': {
        for (final category in AchievementCategory.values)
          category.name: unlocked.where((a) => a.category == category).length,
      },
      'by_tier': {
        for (final tier in AchievementTier.values)
          tier.name: unlocked.where((a) => a.tier == tier).length,
      },
    };
  }
}