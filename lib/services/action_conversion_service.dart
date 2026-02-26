import '../models/habit_model.dart';
import '../models/nudge_model.dart';
import '../services/storage_service.dart';

/// Service for converting journal entries into actionable ideas and tracking repeated patterns
class ActionConversionService {
  final StorageService _storageService = StorageService();
  
  /// Convert a journal entry into an actionable nudge for the Action Vault
  StarboundNudge convertEntryToAction(FreeFormEntry entry) {
    final primaryClassification = entry.classifications.isNotEmpty 
        ? entry.classifications.first 
        : null;
    
    // Determine the main theme/topic from the entry
    String actionTitle;
    String actionDescription;
    String category = 'personal_growth';
    String emoji = '💡';
    
    if (primaryClassification != null) {
      final theme = primaryClassification.themes.isNotEmpty 
          ? primaryClassification.themes.first 
          : primaryClassification.habitKey;
      
      // Generate action based on the theme and sentiment
      final actionSuggestion = _generateActionFromTheme(
        theme, 
        primaryClassification.sentiment,
        entry.originalText,
      );
      
      actionTitle = actionSuggestion['title']!;
      actionDescription = actionSuggestion['description']!;
      category = actionSuggestion['category']!;
      emoji = actionSuggestion['emoji']!;
    } else {
      // Fallback for entries without classifications
      actionTitle = 'Reflect on today\'s experience';
      actionDescription = 'Take a moment to think about: "${_truncateText(entry.originalText, 60)}"';
      category = 'reflection';
      emoji = '🤔';
    }
    
    return StarboundNudge(
      id: 'action_from_entry_${entry.id}',
      theme: category,
      message: actionTitle,
      title: actionTitle,
      content: actionDescription,
      metadata: {
        'source': 'journal_entry',
        'entry_id': entry.id,
        'original_text': entry.originalText,
        'created_from_reflection': true,
        'description': actionDescription,
        'tags': primaryClassification?.themes ?? ['reflection'],
        'emoji': emoji,
      },
      contextTags: primaryClassification?.themes ?? ['reflection'],
      source: NudgeSource.dynamic,
      generatedAt: DateTime.now(),
    );
  }
  
  /// Generate action suggestions based on theme and sentiment
  Map<String, String> _generateActionFromTheme(String theme, String sentiment, String originalText) {
    final lowerTheme = theme.toLowerCase();
    
    // Sleep-related actions
    if (lowerTheme.contains('sleep')) {
      if (sentiment == 'positive') {
        return {
          'title': 'Continue your good sleep routine',
          'description': 'Build on what\'s working: maintain your current bedtime and sleep habits.',
          'category': 'wellness',
          'emoji': '😴',
        };
      } else {
        return {
          'title': 'Improve your sleep quality',
          'description': 'Try setting a consistent bedtime routine or limiting screen time before bed.',
          'category': 'wellness',
          'emoji': '🌙',
        };
      }
    }
    
    // Exercise/movement actions
    if (lowerTheme.contains('exercise') || lowerTheme.contains('movement') || lowerTheme.contains('physical')) {
      if (sentiment == 'positive') {
        return {
          'title': 'Keep up your movement routine',
          'description': 'You\'re doing great! Consider gradually increasing intensity or trying something new.',
          'category': 'fitness',
          'emoji': '💪',
        };
      } else {
        return {
          'title': 'Start with gentle movement',
          'description': 'Begin with a 10-minute walk or some light stretching to get moving.',
          'category': 'fitness',
          'emoji': '🚶',
        };
      }
    }
    
    // Social connection actions
    if (lowerTheme.contains('social') || lowerTheme.contains('friend') || lowerTheme.contains('family')) {
      if (sentiment == 'positive') {
        return {
          'title': 'Nurture your relationships',
          'description': 'Schedule regular check-ins with the people who matter to you.',
          'category': 'social',
          'emoji': '🤝',
        };
      } else {
        return {
          'title': 'Reach out to someone',
          'description': 'Send a message to a friend or family member you haven\'t spoken to in a while.',
          'category': 'social',
          'emoji': '📱',
        };
      }
    }
    
    // Stress/mental health actions
    if (lowerTheme.contains('stress') || lowerTheme.contains('anxiety') || lowerTheme.contains('mental')) {
      return {
        'title': 'Practice stress management',
        'description': 'Try a 5-minute breathing exercise or meditation when feeling overwhelmed.',
        'category': 'mental_health',
        'emoji': '🧘',
      };
    }
    
    // Work/productivity actions
    if (lowerTheme.contains('work') || lowerTheme.contains('productivity') || lowerTheme.contains('goal')) {
      if (sentiment == 'positive') {
        return {
          'title': 'Build on your progress',
          'description': 'Set your next small, achievable goal to maintain momentum.',
          'category': 'productivity',
          'emoji': '🎯',
        };
      } else {
        return {
          'title': 'Break tasks into smaller steps',
          'description': 'Focus on one small action at a time to avoid feeling overwhelmed.',
          'category': 'productivity',
          'emoji': '📝',
        };
      }
    }
    
    // Mood/emotions actions
    if (lowerTheme.contains('mood') || lowerTheme.contains('emotion') || lowerTheme.contains('feeling')) {
      if (sentiment == 'positive') {
        return {
          'title': 'Celebrate your good mood',
          'description': 'Take note of what contributed to feeling good today and try to repeat it.',
          'category': 'emotional_wellbeing',
          'emoji': '✨',
        };
      } else {
        return {
          'title': 'Practice emotional self-care',
          'description': 'Try journaling, calling a friend, or doing something kind for yourself.',
          'category': 'emotional_wellbeing',
          'emoji': '💝',
        };
      }
    }
    
    // Learning/growth actions
    if (lowerTheme.contains('learn') || lowerTheme.contains('growth') || lowerTheme.contains('skill')) {
      return {
        'title': 'Continue learning and growing',
        'description': 'Dedicate 15 minutes today to developing a skill or exploring something new.',
        'category': 'personal_growth',
        'emoji': '📚',
      };
    }
    
    // Default action for general themes
    return {
      'title': 'Take action on your reflection',
      'description': 'Consider one small step you could take related to: "${_truncateText(originalText, 50)}"',
      'category': 'personal_growth',
      'emoji': '💡',
    };
  }
  
  /// Detect repeated tags and suggest habit tracking
  Future<List<String>> detectRepeatedTags(List<FreeFormEntry> entries, {int threshold = 3}) async {
    final tagCounts = <String, int>{};
    final tagLastSeen = <String, DateTime>{};
    
    // Count occurrences of each tag in recent entries (last 30 days)
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    for (final entry in entries) {
      if (entry.timestamp.isBefore(cutoffDate)) continue;
      
      for (final classification in entry.classifications) {
        // Count themes
        for (final theme in classification.themes) {
          tagCounts[theme] = (tagCounts[theme] ?? 0) + 1;
          tagLastSeen[theme] = entry.timestamp;
        }
        
        // Count habit keys
        if (classification.habitKey.isNotEmpty) {
          tagCounts[classification.habitKey] = (tagCounts[classification.habitKey] ?? 0) + 1;
          tagLastSeen[classification.habitKey] = entry.timestamp;
        }
      }
    }
    
    // Find tags that appear frequently and recently
    final repeatedTags = <String>[];
    final recentCutoff = DateTime.now().subtract(const Duration(days: 7)); // Appeared in last week
    
    for (final entry in tagCounts.entries) {
      final tag = entry.key;
      final count = entry.value;
      final lastSeen = tagLastSeen[tag];
      
      if (count >= threshold && lastSeen != null && lastSeen.isAfter(recentCutoff)) {
        // Check if we haven't already suggested this tag for habit tracking
        final alreadySuggested = await _hasBeenSuggestedForHabits(tag);
        if (!alreadySuggested) {
          repeatedTags.add(tag);
        }
      }
    }
    
    return repeatedTags;
  }
  
  /// Check if a tag has already been suggested for habit tracking
  Future<bool> _hasBeenSuggestedForHabits(String tag) async {
    try {
      final prefs = await _storageService.prefs;
      final suggestedTags = prefs.getStringList('habit_suggestions_made') ?? [];
      return suggestedTags.contains(tag);
    } catch (e) {
      return false;
    }
  }
  
  /// Mark a tag as suggested for habit tracking
  Future<void> markTagAsSuggestedForHabits(String tag) async {
    try {
      final prefs = await _storageService.prefs;
      final suggestedTags = prefs.getStringList('habit_suggestions_made') ?? [];
      if (!suggestedTags.contains(tag)) {
        suggestedTags.add(tag);
        await prefs.setStringList('habit_suggestions_made', suggestedTags);
      }
    } catch (e) {
      // Silently fail
    }
  }
  
  /// Generate habit tracking suggestion for a repeated tag
  Map<String, dynamic> generateHabitSuggestion(String tag, int occurrenceCount) {
    final formattedTag = _formatTagName(tag);
    
    return {
      'title': 'Track "$formattedTag" as a habit?',
      'description': 'You\'ve mentioned $formattedTag $occurrenceCount times recently. Would you like to start tracking this as a daily habit?',
      'tag': tag,
      'formatted_name': formattedTag,
      'occurrence_count': occurrenceCount,
      'suggested_frequency': _suggestFrequency(tag),
    };
  }
  
  /// Suggest appropriate frequency for habit tracking based on tag type
  String _suggestFrequency(String tag) {
    final lowerTag = tag.toLowerCase();
    
    if (lowerTag.contains('sleep') || lowerTag.contains('meal') || lowerTag.contains('water')) {
      return 'daily';
    } else if (lowerTag.contains('exercise') || lowerTag.contains('workout')) {
      return '3-4 times per week';
    } else if (lowerTag.contains('social') || lowerTag.contains('friend')) {
      return 'weekly';
    } else {
      return 'daily';
    }
  }
  
  /// Format tag name for display (convert underscores to spaces, capitalize)
  String _formatTagName(String tag) {
    return tag.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  /// Truncate text to specified length with ellipsis
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  /// Get contextual action suggestions based on entry content
  List<Map<String, String>> getContextualActions(FreeFormEntry entry) {
    final suggestions = <Map<String, String>>[];
    
    if (entry.classifications.isEmpty) {
      suggestions.add({
        'title': 'Reflect further',
        'description': 'Take 5 minutes to explore this thought more deeply',
        'category': 'reflection',
        'emoji': '🤔',
      });
      return suggestions;
    }
    
    for (final classification in entry.classifications) {
      // Add theme-specific suggestions
      for (final theme in classification.themes) {
        final action = _generateActionFromTheme(theme, classification.sentiment, entry.originalText);
        suggestions.add(action);
      }
    }
    
    // Remove duplicates and limit to 3 suggestions
    final uniqueSuggestions = <Map<String, String>>[];
    final seenTitles = <String>{};
    
    for (final suggestion in suggestions) {
      if (!seenTitles.contains(suggestion['title']) && uniqueSuggestions.length < 3) {
        uniqueSuggestions.add(suggestion);
        seenTitles.add(suggestion['title']!);
      }
    }
    
    return uniqueSuggestions;
  }
  
  /// Save an action to the Action Vault
  Future<void> saveActionToVault(StarboundNudge action) async {
    try {
      final prefs = await _storageService.prefs;
      
      // Get existing actions
      final existingActions = prefs.getStringList('saved_actions_from_journal') ?? [];
      
      // Add new action (store as JSON string)
      final actionJson = {
        'id': action.id,
        'message': action.message,
        'theme': action.theme,
        'title': action.title,
        'content': action.content,
        'metadata': action.metadata,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      existingActions.add(actionJson.toString());
      await prefs.setStringList('saved_actions_from_journal', existingActions);
      
    } catch (e) {
      throw Exception('Failed to save action to vault: $e');
    }
  }
  
  /// Get all saved actions from journal entries
  Future<List<StarboundNudge>> getSavedActions() async {
    try {
      final prefs = await _storageService.prefs;
      final actionStrings = prefs.getStringList('saved_actions_from_journal') ?? [];
      
      final actions = <StarboundNudge>[];
      for (final actionString in actionStrings) {
        try {
          // Note: This is a simplified implementation
          // In practice, you'd want proper JSON parsing
          // For now, we'll create sample actions
          actions.add(StarboundNudge(
            id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
            theme: 'personal_growth',
            message: 'Saved action from journal',
            title: 'Saved action from journal',
            content: 'This action was saved from a journal reflection',
          ));
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
      
      return actions;
    } catch (e) {
      return [];
    }
  }
}