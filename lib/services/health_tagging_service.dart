import 'package:flutter/foundation.dart';
import '../models/health_journal_model.dart';

/// Service for extracting health tags from journal text
/// Uses keyword matching (privacy-first) with optional AI enhancement
class HealthTaggingService {
  static final HealthTaggingService _instance = HealthTaggingService._internal();
  factory HealthTaggingService() => _instance;
  HealthTaggingService._internal();

  /// Extract health tags from text, check-in data, and symptoms
  Future<List<HealthTag>> extractHealthTags({
    required String? text,
    HealthCheckIn? checkIn,
    List<SymptomTracking>? symptoms,
  }) async {
    final tags = <HealthTag>[];

    // 1. Extract tags from free-form text using keyword matching
    if (text != null && text.trim().isNotEmpty) {
      tags.addAll(_extractTagsFromText(text));
    }

    // 2. Extract tags from check-in data
    if (checkIn != null) {
      tags.addAll(_extractTagsFromCheckIn(checkIn));
    }

    // 3. Extract tags from symptom tracking
    if (symptoms != null && symptoms.isNotEmpty) {
      tags.addAll(_extractTagsFromSymptoms(symptoms));
    }

    // Deduplicate by canonical key (keep highest confidence)
    final uniqueTags = _deduplicateTags(tags);

    debugPrint('HealthTaggingService: Extracted ${uniqueTags.length} unique tags');

    return uniqueTags;
  }

  /// Extract tags from free-form text using keyword matching
  List<HealthTag> _extractTagsFromText(String text) {
    final tags = <HealthTag>[];
    final lowerText = text.toLowerCase();

    // Check each tag category
    for (final category in HealthTagCategory.values) {
      final categoryTags = HealthTagTaxonomy.getTagsByCategory(category);

      for (final entry in categoryTags.entries) {
        final canonicalKey = entry.key;
        final displayName = entry.value;

        // Check for keyword matches
        final matches = _findKeywordMatches(lowerText, canonicalKey, displayName);

        if (matches.isNotEmpty) {
          // Found a match - extract evidence span
          final evidenceSpan = _extractEvidenceSpan(text, matches.first);

          tags.add(HealthTag.fromKeyword(
            canonicalKey: canonicalKey,
            category: category,
            evidenceSpan: evidenceSpan,
            confidence: _calculateConfidence(matches.length, lowerText, canonicalKey),
          ));
        }
      }
    }

    // Check for additional contextual keywords
    tags.addAll(_extractContextualTags(lowerText, text));

    return tags;
  }

  /// Find keyword matches in text
  List<RegExpMatch> _findKeywordMatches(String lowerText, String canonicalKey, String displayName) {
    final matches = <RegExpMatch>[];

    // Try canonical key (e.g., "headache")
    final keyPattern = RegExp(r'\b' + RegExp.escape(canonicalKey.replaceAll('-', ' ')) + r'\b');
    matches.addAll(keyPattern.allMatches(lowerText));

    // Try display name if different (e.g., "Headache")
    if (displayName.toLowerCase() != canonicalKey.replaceAll('-', ' ')) {
      final displayPattern = RegExp(r'\b' + RegExp.escape(displayName.toLowerCase()) + r'\b');
      matches.addAll(displayPattern.allMatches(lowerText));
    }

    // Try variations/synonyms
    final synonyms = _getSynonyms(canonicalKey);
    for (final synonym in synonyms) {
      final synonymPattern = RegExp(r'\b' + RegExp.escape(synonym) + r'\b');
      matches.addAll(synonymPattern.allMatches(lowerText));
    }

    return matches;
  }

  /// Get synonyms for common health terms
  List<String> _getSynonyms(String canonicalKey) {
    switch (canonicalKey) {
      case 'fatigue':
        return ['tired', 'exhausted', 'worn out', 'drained', 'wiped'];
      case 'headache':
        return ['head hurts', 'head pain', 'head ache', 'sore head'];
      case 'migraine':
        return ['migraine'];
      case 'pain':
        return ['hurts', 'hurting', 'aching', 'sore'];
      case 'nausea':
        return ['nauseous', 'sick', 'queasy', 'feel sick'];
      case 'dizziness':
        return ['dizzy', 'lightheaded', 'light headed', 'faint'];
      case 'anxiety':
        return ['anxious', 'nervous', 'worried', 'panicky'];
      case 'depression':
        return ['depressed', 'down', 'low mood'];
      case 'stress':
        return ['stressed', 'stressful', 'under pressure'];
      case 'overwhelmed':
        return ['overwhelm', 'too much', 'cant cope', "can't cope"];
      case 'insomnia':
        return ["can't sleep", 'cant sleep', 'trouble sleeping', 'no sleep'];
      case 'stomach-pain':
        return ['stomach ache', 'stomach hurts', 'tummy ache', 'belly pain'];
      case 'back-pain':
        return ['back hurts', 'backache', 'back ache', 'sore back'];
      case 'cost-barrier':
        return ["can't afford", 'cant afford', 'no money', 'too expensive'];
      case 'food-insecurity':
        return ['no food', 'skipped meal', 'hungry', "can't eat", 'cant eat'];
      case 'work-stress':
        return ['work is', 'job stress', 'workplace', 'boss', 'workload'];
      case 'social-isolation':
        return ['alone', 'lonely', 'isolated', 'no friends'];
      case 'feeling-better':
        return ['feel better', 'improving', 'getting better'];
      case 'good-day':
        return ['great day', 'nice day', 'wonderful day'];
      default:
        return [];
    }
  }

  /// Extract a short evidence span around the match
  String _extractEvidenceSpan(String originalText, RegExpMatch match) {
    const contextLength = 30;
    final start = (match.start - contextLength).clamp(0, originalText.length);
    final end = (match.end + contextLength).clamp(0, originalText.length);

    var span = originalText.substring(start, end);

    // Add ellipsis if truncated
    if (start > 0) span = '...$span';
    if (end < originalText.length) span = '$span...';

    return span.trim();
  }

  /// Calculate confidence based on match quality
  double _calculateConfidence(int matchCount, String text, String key) {
    double confidence = 0.6; // Base confidence for keyword match

    // Boost for multiple mentions
    if (matchCount > 1) confidence += 0.1;
    if (matchCount > 2) confidence += 0.1;

    // Boost for longer text (more context)
    if (text.length > 100) confidence += 0.05;
    if (text.length > 200) confidence += 0.05;

    return confidence.clamp(0.0, 1.0);
  }

  /// Extract contextual tags that require more analysis
  List<HealthTag> _extractContextualTags(String lowerText, String originalText) {
    final tags = <HealthTag>[];

    // Detect financial stress
    if (_containsAny(lowerText, ['bills', 'rent', 'mortgage', 'debt', 'broke', 'poor'])) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'financial-stress',
        category: HealthTagCategory.lifeContext,
        evidenceSpan: _findSpanContaining(originalText, ['bills', 'rent', 'mortgage', 'debt', 'broke', 'poor']),
        confidence: 0.7,
      ));
    }

    // Detect childcare issues
    if (_containsAny(lowerText, ['childcare', 'babysitter', 'kids are', 'children']) &&
        _containsAny(lowerText, ['problem', 'issue', 'difficult', 'hard', 'struggle'])) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'childcare-problem',
        category: HealthTagCategory.barrier,
        evidenceSpan: null,
        confidence: 0.6,
      ));
    }

    // Detect transportation issues
    if (_containsAny(lowerText, ['no car', 'no transport', 'cant get there', "can't get there", 'bus', 'train']) &&
        _containsAny(lowerText, ['problem', 'issue', 'difficult', 'hard', 'miss'])) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'transportation-issue',
        category: HealthTagCategory.barrier,
        evidenceSpan: null,
        confidence: 0.6,
      ));
    }

    // Detect positive progress
    if (_containsAny(lowerText, ['better today', 'improved', 'progress', 'good news', 'finally'])) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'progress',
        category: HealthTagCategory.positive,
        evidenceSpan: null,
        confidence: 0.7,
      ));
    }

    // Detect relationship issues
    if (_containsAny(lowerText, ['partner', 'husband', 'wife', 'boyfriend', 'girlfriend']) &&
        _containsAny(lowerText, ['fight', 'argue', 'problem', 'issue', 'difficult', 'broke up'])) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'relationship-issues',
        category: HealthTagCategory.lifeContext,
        evidenceSpan: null,
        confidence: 0.6,
      ));
    }

    return tags;
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  String? _findSpanContaining(String text, List<String> keywords) {
    final lowerText = text.toLowerCase();
    for (final keyword in keywords) {
      final index = lowerText.indexOf(keyword);
      if (index >= 0) {
        const contextLength = 25;
        final start = (index - contextLength).clamp(0, text.length);
        final end = (index + keyword.length + contextLength).clamp(0, text.length);
        return text.substring(start, end).trim();
      }
    }
    return null;
  }

  /// Extract tags from check-in data
  List<HealthTag> _extractTagsFromCheckIn(HealthCheckIn checkIn) {
    final tags = <HealthTag>[];

    // Low energy (1-2)
    if (checkIn.energy != null && checkIn.energy! <= 2) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'fatigue',
        category: HealthTagCategory.physicalSymptom,
        evidenceSpan: 'Check-in: Energy level ${checkIn.energy}/5',
        confidence: 0.8,
      ));
    }

    // High pain (3+)
    if (checkIn.painLevel != null && checkIn.painLevel! >= 3) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'pain',
        category: HealthTagCategory.physicalSymptom,
        evidenceSpan: 'Check-in: Pain level ${checkIn.painLevel}/5',
        confidence: 0.9,
      ));
    }

    // Poor sleep (1-2)
    if (checkIn.sleepQuality != null && checkIn.sleepQuality! <= 2) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'insomnia',
        category: HealthTagCategory.physicalSymptom,
        evidenceSpan: 'Check-in: Sleep quality ${checkIn.sleepQuality}/5',
        confidence: 0.7,
      ));
    }

    // Low mood (1-2)
    if (checkIn.mood != null && checkIn.mood! <= 2) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'sad',
        category: HealthTagCategory.mentalEmotional,
        evidenceSpan: 'Check-in: Mood ${checkIn.mood}/5',
        confidence: 0.7,
      ));
    }

    // High stress (4-5)
    if (checkIn.stressLevel != null && checkIn.stressLevel! >= 4) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'stress',
        category: HealthTagCategory.mentalEmotional,
        evidenceSpan: 'Check-in: Stress level ${checkIn.stressLevel}/5',
        confidence: 0.85,
      ));
    }

    // High anxiety (4-5)
    if (checkIn.anxietyLevel != null && checkIn.anxietyLevel! >= 4) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'anxiety',
        category: HealthTagCategory.mentalEmotional,
        evidenceSpan: 'Check-in: Anxiety level ${checkIn.anxietyLevel}/5',
        confidence: 0.85,
      ));
    }

    // Skipped meals
    if (checkIn.ateRegularMeals == MealStatus.no) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'food-insecurity',
        category: HealthTagCategory.lifeContext,
        evidenceSpan: 'Check-in: Did not eat regular meals',
        confidence: 0.6,
      ));
    }

    // Good metrics -> positive tags
    if (checkIn.energy != null && checkIn.energy! >= 4 &&
        checkIn.mood != null && checkIn.mood! >= 4) {
      tags.add(HealthTag.fromKeyword(
        canonicalKey: 'good-day',
        category: HealthTagCategory.positive,
        evidenceSpan: 'Check-in: High energy and mood',
        confidence: 0.8,
      ));
    }

    return tags;
  }

  /// Extract tags from symptom tracking
  List<HealthTag> _extractTagsFromSymptoms(List<SymptomTracking> symptoms) {
    final tags = <HealthTag>[];

    for (final symptom in symptoms) {
      // Get the category for this symptom type
      final category = HealthTagTaxonomy.getCategoryForKey(symptom.symptomType)
          ?? HealthTagCategory.physicalSymptom;

      tags.add(HealthTag.fromKeyword(
        canonicalKey: symptom.symptomType,
        category: category,
        evidenceSpan: 'Tracked: ${symptom.severityText} ${symptom.symptomType} (${symptom.durationText})',
        confidence: 0.95, // High confidence for explicitly tracked symptoms
      ));

      // Add severity-based tags for severe symptoms
      if (symptom.isSevere) {
        tags.add(HealthTag.fromKeyword(
          canonicalKey: 'pain',
          category: HealthTagCategory.physicalSymptom,
          evidenceSpan: 'Tracked severe ${symptom.symptomType}',
          confidence: 0.9,
        ));
      }

      // Add persistence tag for long-duration symptoms
      if (symptom.isPersistent) {
        tags.add(HealthTag.fromKeyword(
          canonicalKey: 'chronic-pain',
          category: HealthTagCategory.healthConcern,
          evidenceSpan: 'Persistent ${symptom.symptomType} over multiple days',
          confidence: 0.7,
        ));
      }
    }

    return tags;
  }

  /// Deduplicate tags by canonical key, keeping highest confidence
  List<HealthTag> _deduplicateTags(List<HealthTag> tags) {
    final tagMap = <String, HealthTag>{};

    for (final tag in tags) {
      final existing = tagMap[tag.canonicalKey];
      if (existing == null || tag.confidence > existing.confidence) {
        tagMap[tag.canonicalKey] = tag;
      }
    }

    // Sort by category, then by confidence
    final sortedTags = tagMap.values.toList();
    sortedTags.sort((a, b) {
      final categoryCompare = a.category.index.compareTo(b.category.index);
      if (categoryCompare != 0) return categoryCompare;
      return b.confidence.compareTo(a.confidence);
    });

    return sortedTags;
  }

  /// Quick check if text likely contains health-related content
  bool containsHealthContent(String text) {
    if (text.trim().isEmpty) return false;
    final lowerText = text.toLowerCase();

    // Check for any symptom keywords
    for (final tags in [
      HealthTagTaxonomy.physicalSymptomTags.keys,
      HealthTagTaxonomy.mentalEmotionalTags.keys,
    ]) {
      for (final key in tags) {
        if (lowerText.contains(key.replaceAll('-', ' '))) {
          return true;
        }
      }
    }

    // Check common health words
    const healthWords = [
      'doctor', 'gp', 'pain', 'hurt', 'sick', 'tired', 'stressed',
      'worried', 'anxious', 'headache', 'stomach', 'sleep', 'fatigue',
    ];

    return healthWords.any((word) => lowerText.contains(word));
  }
}
