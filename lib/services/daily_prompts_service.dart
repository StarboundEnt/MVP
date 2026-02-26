import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing daily reflection prompts that make journaling more inviting
class DailyPromptsService {
  static const String _keyPromptDate = 'daily_prompt_date';
  static const String _keyPromptText = 'daily_prompt_text';
  static const String _keyPromptCategory = 'daily_prompt_category';
  
  SharedPreferences? _prefs;
  
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Health-focused daily prompts organized by category
  static const Map<String, List<String>> _promptCategories = {
    'health_checkin': [
      "How's your body feeling today?",
      "Any symptoms bothering you lately?",
      "How did you sleep last night?",
      "What's your energy level today?",
      "How's your pain or discomfort today?"
    ],
    'medication_tracking': [
      "Did you take your medications today?",
      "Any side effects from your medications?",
      "How are you managing your prescriptions?",
      "Need to refill any medications soon?",
      "Any changes to how your medications make you feel?"
    ],
    'symptom_patterns': [
      "What made your symptoms better or worse today?",
      "Any triggers you noticed today?",
      "How do your symptoms compare to yesterday?",
      "What helps you feel better when symptoms flare?",
      "Any patterns you're noticing with your health?"
    ],
    'healthcare_access': [
      "Any appointments coming up?",
      "What healthcare support do you need right now?",
      "Any barriers to getting care you need?",
      "How's your progress with finding the right care?",
      "What health questions do you have for your next GP visit?"
    ],
    'daily_health': [
      "What helped your health today?",
      "What's one healthy choice you made today?",
      "How did you look after yourself today?",
      "What's something that supported your wellbeing?",
      "What do you need for your health tomorrow?"
    ]
  };

  /// Get all available prompts flattened into a single list
  static List<String> get _allPrompts {
    return _promptCategories.values.expand((prompts) => prompts).toList();
  }

  /// Get today's daily prompt, ensuring consistency throughout the day
  Future<String> getTodaysPrompt() async {
    try {
      final p = await prefs;
      final today = _getTodayString();
      final storedDate = p.getString(_keyPromptDate);
      
      // Check if we already have today's prompt
      if (storedDate == today) {
        final storedPrompt = p.getString(_keyPromptText);
        if (storedPrompt != null && storedPrompt.isNotEmpty) {
          return storedPrompt;
        }
      }
      
      // Generate new prompt for today
      final newPrompt = _generatePromptForDate(today);
      
      // Store the new prompt
      await p.setString(_keyPromptDate, today);
      await p.setString(_keyPromptText, newPrompt);
      
      return newPrompt;
    } catch (e) {
      // Fallback to a simple health prompt
      return "How's your health today?";
    }
  }

  /// Generate a consistent prompt for a given date
  String _generatePromptForDate(String dateString) {
    // Use date as seed for consistent daily selection
    final seed = dateString.hashCode;
    final random = Random(seed);
    
    // Select a random category
    final categories = _promptCategories.keys.toList();
    final selectedCategory = categories[random.nextInt(categories.length)];
    
    // Select a random prompt from that category
    final categoryPrompts = _promptCategories[selectedCategory]!;
    return categoryPrompts[random.nextInt(categoryPrompts.length)];
  }

  /// Get a fresh prompt (for manual refresh)
  Future<String> getNewPrompt() async {
    try {
      final p = await prefs;
      final today = _getTodayString();
      
      // Get current prompt to avoid repeating it
      final currentPrompt = p.getString(_keyPromptText);
      
      // Generate a different prompt
      String newPrompt;
      int attempts = 0;
      do {
        final seed = DateTime.now().millisecondsSinceEpoch + attempts;
        final random = Random(seed);
        newPrompt = _allPrompts[random.nextInt(_allPrompts.length)];
        attempts++;
      } while (newPrompt == currentPrompt && attempts < 10);
      
      // Store the new prompt
      await p.setString(_keyPromptDate, today);
      await p.setString(_keyPromptText, newPrompt);
      
      return newPrompt;
    } catch (e) {
      return "How's your health today?";
    }
  }

  /// Get prompts from a specific category
  Future<List<String>> getPromptsFromCategory(String category) async {
    return _promptCategories[category] ?? [];
  }

  /// Get all available categories
  List<String> getCategories() {
    return _promptCategories.keys.toList();
  }

  /// Get the category of the current prompt
  Future<String?> getCurrentPromptCategory() async {
    try {
      final currentPrompt = await getTodaysPrompt();
      
      for (final entry in _promptCategories.entries) {
        if (entry.value.contains(currentPrompt)) {
          return entry.key;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear stored prompt data (useful for testing)
  Future<void> clearPromptData() async {
    final p = await prefs;
    await p.remove(_keyPromptDate);
    await p.remove(_keyPromptText);
    await p.remove(_keyPromptCategory);
  }

  /// Get today's date as a string for comparison
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check if a new day has started since last prompt
  Future<bool> isNewDay() async {
    try {
      final p = await prefs;
      final today = _getTodayString();
      final storedDate = p.getString(_keyPromptDate);
      return storedDate != today;
    } catch (e) {
      return true;
    }
  }

  /// Get a preview of tomorrow's prompt (useful for notifications)
  String getTomorrowsPrompt() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowString = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    return _generatePromptForDate(tomorrowString);
  }

  /// Get stats about prompt usage (for analytics)
  Future<Map<String, dynamic>> getPromptStats() async {
    try {
      final p = await prefs;
      final storedDate = p.getString(_keyPromptDate);
      final storedPrompt = p.getString(_keyPromptText);
      final category = await getCurrentPromptCategory();
      
      return {
        'last_prompt_date': storedDate,
        'current_prompt': storedPrompt,
        'current_category': category,
        'total_categories': _promptCategories.length,
        'total_prompts': _allPrompts.length,
        'is_new_day': await isNewDay(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'total_categories': _promptCategories.length,
        'total_prompts': _allPrompts.length,
      };
    }
  }
}