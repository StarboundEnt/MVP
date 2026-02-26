import 'package:flutter/material.dart';

import '../models/habit_model.dart';
import '../models/smart_tag_model.dart';

/// Utility helpers for working with canonical smart tags across the app.
class TagUtils {
  static final Set<String> _canonicalTags = {
    for (final category in CanonicalOntology.structure.values)
      for (final subdomain in category.values) ...subdomain
  };

  /// Returns the resolved canonical tag for [raw] input, or null if unsupported.
  static String? resolveCanonicalTag(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final attempts = <String>{
      raw,
      raw.trim(),
      raw.trim().toLowerCase(),
      raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
    };

    for (final attempt in attempts) {
      final resolved = CanonicalOntology.resolveCanonicalKey(attempt);
      if (resolved != null) {
        return resolved;
      }
    }
    return null;
  }

  /// Extract canonical tags from a classification result.
  static Set<String> extractFromClassification(
    ClassificationResult classification,
  ) {
    final tags = <String>{};

    void add(String? value) {
      final resolved = resolveCanonicalTag(value);
      if (resolved != null) {
        tags.add(resolved);
      }
    }

    for (final theme in classification.themes) {
      add(theme);
    }
    for (final keyword in classification.keywords) {
      add(keyword);
    }
    add(classification.habitKey);
    add(classification.categoryTitle);

    if (classification.sentiment != 'neutral') {
      add(classification.sentiment);
    }

    return tags;
  }

  /// Extract canonical tags from an entire free-form entry.
  static Set<String> extractFromEntry(FreeFormEntry entry) {
    final tags = <String>{};
    for (final classification in entry.classifications) {
      tags.addAll(extractFromClassification(classification));
    }

    if (tags.isEmpty) {
      for (final classification in entry.classifications) {
        final fallback = resolveCanonicalTag(classification.habitKey) ??
            resolveCanonicalTag(classification.categoryTitle);
        if (fallback != null) {
          tags.add(fallback);
        }
      }
    }

    if (tags.isEmpty) {
      tags.add('balanced');
    }

    return tags;
  }

  static String displayName(String canonicalTag) {
    return CanonicalOntology.getDisplayName(canonicalTag);
  }

  static String? subdomain(String canonicalTag) {
    return CanonicalOntology.getSubdomain(canonicalTag);
  }

  static TagCategory? category(String canonicalTag) {
    return CanonicalOntology.getCategory(canonicalTag);
  }

  static List<String> allCanonicalTags() =>
      _canonicalTags.toList(growable: false);

  static String emoji(String canonicalTag) {
    return _emojiOverrides[canonicalTag] ?? _emojiForCategory(canonicalTag);
  }

  static Color color(String canonicalTag) {
    final subdomainName = subdomain(canonicalTag)?.toLowerCase() ?? '';
    if (subdomainName.contains('movement')) {
      return const Color(0xFFFFDA3E);
    }
    if (subdomainName.contains('mindful') || subdomainName.contains('reset')) {
      return const Color(0xFF9B5DE5);
    }
    if (subdomainName.contains('nourish') || subdomainName.contains('restore')) {
      return const Color(0xFFFF6B35);
    }
    if (subdomainName.contains('connection') || subdomainName.contains('joy')) {
      return const Color(0xFF00F5D4);
    }
    if (subdomainName.contains('focus') || subdomainName.contains('progress')) {
      return const Color(0xFF4895EF);
    }

    final categoryName = category(canonicalTag)?.name;
    switch (categoryName) {
      case 'chance':
        return const Color(0xFFFF6B35);
      case 'outcome':
        return const Color(0xFF9B5DE5);
      default:
        return const Color(0xFF00F5D4);
    }
  }

  static String _emojiForCategory(String canonicalTag) {
    final categoryName = category(canonicalTag)?.name;
    switch (categoryName) {
      case 'choice':
        return '✨';
      case 'chance':
        return '🧭';
      case 'outcome':
        return '🧠';
      default:
        return '✨';
    }
  }

  static const Map<String, String> _emojiOverrides = {
    'movement_boost': '🏃‍♀️',
    'energy_plan': '⚡️',
    'rest_day': '🛋️',
    'mindful_break': '🧘',
    'breathing_reset': '🌬️',
    'digital_detox': '📵',
    'reset_routine': '🔄',
    'balanced_meal': '🥗',
    'hydration_reset': '💧',
    'sleep_hygiene': '😴',
    'self_compassion': '💛',
    'social_checkin': '🤝',
    'gratitude_moment': '🙏',
    'creative_play': '🎨',
    'focus_sprint': '🎯',
    'busy_day': '📅',
    'time_pressure': '⏱️',
    'deadline_mode': '📝',
    'unexpected_event': '⚡️',
    'travel_disruption': '🚌',
    'workspace_shift': '💼',
    'weather_slump': '🌧️',
    'nature_time': '🌿',
    'supportive_chat': '💬',
    'family_duty': '👪',
    'morning_check': '🌅',
    'midday_reset': '☀️',
    'evening_reflection': '🌙',
    'calm_grounded': '🪴',
    'hopeful': '✨',
    'relief': '😌',
    'balanced': '⚖️',
    'overwhelmed': '🌊',
    'lonely': '🌑',
    'anxious_underlying': '💭',
    'energized': '⚡️',
    'drained': '🪫',
    'restless': '🌀',
    'foggy': '🌫️',
    'proud_progress': '🏅',
    'micro_win': '🎉',
    'setback': '🛑',
    'learning': '📚',
    'habit_chain': '⛓️',
    'first_step': '👣',
    'need_rest': '🛌',
    'need_connection': '🤗',
    'need_fuel': '🍽️',
    'need_clarity': '🔍',
  };
}
