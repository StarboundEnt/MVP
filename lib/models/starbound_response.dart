import 'package:flutter/material.dart';
import 'nudge_model.dart';

class InsightSection {
  final String title;
  final String summary;
  final List<String> contextSignals;

  const InsightSection({
    required this.title,
    required this.summary,
    this.contextSignals = const [],
  });

  InsightSection copyWith({
    String? title,
    String? summary,
    List<String>? contextSignals,
  }) {
    return InsightSection(
      title: title ?? this.title,
      summary: summary ?? this.summary,
      contextSignals: contextSignals ?? this.contextSignals,
    );
  }

  factory InsightSection.fromJson(Map<String, dynamic> json) {
    final rawSignals = json['context_signals'];
    final contextSignals = rawSignals is List
        ? rawSignals
            .whereType<dynamic>()
            .map((signal) => signal.toString().trim())
            .where((signal) => signal.isNotEmpty)
            .toList()
        : const <String>[];

    return InsightSection(
      title: json['title']?.toString().trim() ?? '',
      summary: json['summary']?.toString().trim() ?? '',
      contextSignals: contextSignals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      if (contextSignals.isNotEmpty) 'context_signals': contextSignals,
    };
  }
}

/// Represents a single actionable step that the user can take immediately
class ActionableStep {
  final String id;
  final String text;
  final String? details;
  final String? estimatedTime;
  final String? theme;
  final IconData? icon;
  final bool completed;
  final Color? color;

  const ActionableStep({
    required this.id,
    required this.text,
    this.details,
    this.estimatedTime,
    this.theme,
    this.icon,
    this.completed = false,
    this.color,
  });

  ActionableStep copyWith({
    String? id,
    String? text,
    String? details,
    String? estimatedTime,
    String? theme,
    IconData? icon,
    bool? completed,
    Color? color,
  }) {
    return ActionableStep(
      id: id ?? this.id,
      text: text ?? this.text,
      details: details ?? this.details,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      theme: theme ?? this.theme,
      icon: icon ?? this.icon,
      completed: completed ?? this.completed,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'details': details,
      'estimatedTime': estimatedTime,
      'theme': theme,
      'completed': completed,
    };
  }

  factory ActionableStep.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'] ?? json['description'];
    final detailsText = rawDetails?.toString().trim();
    final rawTheme = json['theme'];
    final themeText = rawTheme?.toString().trim();
    final rawEstimatedTime = json['estimatedTime'] ?? json['estimated_time'];
    final estimatedTimeText = rawEstimatedTime?.toString().trim();
    return ActionableStep(
      id: json['id'],
      text: json['text'],
      details:
          (detailsText == null || detailsText.isEmpty) ? null : detailsText,
      estimatedTime: (estimatedTimeText == null || estimatedTimeText.isEmpty)
          ? null
          : estimatedTimeText,
      theme: (themeText == null || themeText.isEmpty) ? null : themeText,
      completed: json['completed'] ?? false,
    );
  }
}

/// Represents a follow-up recommendation or future consideration
class NextStepItem {
  final String id;
  final String text;
  final String category; // e.g., 'monitor', 'explore', 'consider'
  final String? relatedFeature; // e.g., 'habits', 'journal', 'forecast'
  final IconData? icon;
  final Color? color;
  final bool isSaved;

  const NextStepItem({
    required this.id,
    required this.text,
    required this.category,
    this.relatedFeature,
    this.icon,
    this.color,
    this.isSaved = false,
  });

  NextStepItem copyWith({
    String? id,
    String? text,
    String? category,
    String? relatedFeature,
    IconData? icon,
    Color? color,
    bool? isSaved,
  }) {
    return NextStepItem(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      relatedFeature: relatedFeature ?? this.relatedFeature,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'relatedFeature': relatedFeature,
      'isSaved': isSaved,
    };
  }

  factory NextStepItem.fromJson(Map<String, dynamic> json) {
    return NextStepItem(
      id: json['id'],
      text: json['text'],
      category: json['category'],
      relatedFeature: json['relatedFeature'],
      isSaved: json['isSaved'] ?? false,
    );
  }
}

/// Represents a contextual action button that the user can take
class ContextualAction {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? description;
  final bool isPrimary;

  const ContextualAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.description,
    this.isPrimary = false,
  });

  ContextualAction copyWith({
    String? id,
    String? label,
    IconData? icon,
    Color? color,
    VoidCallback? onPressed,
    String? description,
    bool? isPrimary,
  }) {
    return ContextualAction(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      onPressed: onPressed ?? this.onPressed,
      description: description ?? this.description,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

/// When to seek care guidance for health navigation
class WhenToSeekCare {
  final String? routine;
  final String? urgent;
  final String? emergency;

  const WhenToSeekCare({
    this.routine,
    this.urgent,
    this.emergency,
  });

  factory WhenToSeekCare.fromJson(Map<String, dynamic> json) {
    return WhenToSeekCare(
      routine: json['routine']?.toString().trim(),
      urgent: json['urgent']?.toString().trim(),
      emergency: json['emergency']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (routine != null) 'routine': routine,
      if (urgent != null) 'urgent': urgent,
      if (emergency != null) 'emergency': emergency,
    };
  }
}

/// Main structured response from Starbound containing all response components
class StarboundResponse {
  final String id;
  final String userQuery;
  final String overview; // Also serves as "understanding" for health navigation
  final List<ActionableStep> immediateSteps;
  final List<NextStepItem> nextSteps;
  final List<ContextualAction> actions;
  final List<StarboundNudge>
      geminiActions; // AI-generated actions that can be saved to vault
  final DateTime timestamp;
  final String? mood; // e.g., 'encouraging', 'gentle', 'supportive'
  final double? confidence; // AI confidence in the response (0.0 - 1.0)
  final List<InsightSection>
      insightSections; // Also serves as "possible_causes"
  final String aiSource;
  final bool isSimulated;
  final List<String> diagnostics;

  // NEW: Health navigation fields
  final WhenToSeekCare? whenToSeekCare;
  final List<String> resourceNeeds; // e.g., ["bulk-billing-gp", "journaling"]
  final List<String> followUpSuggestions;

  const StarboundResponse({
    required this.id,
    required this.userQuery,
    required this.overview,
    required this.immediateSteps,
    required this.nextSteps,
    required this.actions,
    this.geminiActions = const [],
    required this.timestamp,
    this.mood,
    this.confidence,
    this.insightSections = const [],
    this.aiSource = 'unknown',
    this.isSimulated = false,
    this.diagnostics = const [],
    this.whenToSeekCare,
    this.resourceNeeds = const [],
    this.followUpSuggestions = const [],
  });

  StarboundResponse copyWith({
    String? id,
    String? userQuery,
    String? overview,
    List<ActionableStep>? immediateSteps,
    List<NextStepItem>? nextSteps,
    List<ContextualAction>? actions,
    List<StarboundNudge>? geminiActions,
    DateTime? timestamp,
    String? mood,
    double? confidence,
    List<InsightSection>? insightSections,
    String? aiSource,
    bool? isSimulated,
    List<String>? diagnostics,
    WhenToSeekCare? whenToSeekCare,
    List<String>? resourceNeeds,
    List<String>? followUpSuggestions,
  }) {
    return StarboundResponse(
      id: id ?? this.id,
      userQuery: userQuery ?? this.userQuery,
      overview: overview ?? this.overview,
      immediateSteps: immediateSteps ?? this.immediateSteps,
      nextSteps: nextSteps ?? this.nextSteps,
      actions: actions ?? this.actions,
      geminiActions: geminiActions ?? this.geminiActions,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
      confidence: confidence ?? this.confidence,
      insightSections: insightSections ?? this.insightSections,
      aiSource: aiSource ?? this.aiSource,
      isSimulated: isSimulated ?? this.isSimulated,
      diagnostics: diagnostics ?? this.diagnostics,
      whenToSeekCare: whenToSeekCare ?? this.whenToSeekCare,
      resourceNeeds: resourceNeeds ?? this.resourceNeeds,
      followUpSuggestions: followUpSuggestions ?? this.followUpSuggestions,
    );
  }

  /// Get total number of actionable items (immediate steps + next steps)
  int get totalActionableItems => immediateSteps.length + nextSteps.length;

  /// Get number of completed immediate steps
  int get completedStepsCount =>
      immediateSteps.where((step) => step.completed).length;

  /// Check if all immediate steps are completed
  bool get allStepsCompleted =>
      immediateSteps.isNotEmpty && completedStepsCount == immediateSteps.length;

  /// Get progress percentage for immediate steps
  double get stepsProgress => immediateSteps.isEmpty
      ? 0.0
      : completedStepsCount / immediateSteps.length;

  /// Get number of saved next steps
  int get savedNextStepsCount => nextSteps.where((item) => item.isSaved).length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userQuery': userQuery,
      'overview': overview,
      'immediateSteps': immediateSteps.map((step) => step.toJson()).toList(),
      'nextSteps': nextSteps.map((item) => item.toJson()).toList(),
      'geminiActions': geminiActions.map((action) => action.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
      'confidence': confidence,
      'insightSections':
          insightSections.map((section) => section.toJson()).toList(),
      'aiSource': aiSource,
      'isSimulated': isSimulated,
      'diagnostics': diagnostics,
      if (whenToSeekCare != null) 'when_to_seek_care': whenToSeekCare!.toJson(),
      'resource_needs': resourceNeeds,
      'follow_up_suggestions': followUpSuggestions,
    };
  }

  factory StarboundResponse.fromJson(Map<String, dynamic> json) {
    return StarboundResponse(
      id: json['id'],
      userQuery: json['userQuery'],
      overview: json['overview'],
      immediateSteps: (json['immediateSteps'] as List)
          .map((step) => ActionableStep.fromJson(step))
          .toList(),
      nextSteps: (json['nextSteps'] as List)
          .map((item) => NextStepItem.fromJson(item))
          .toList(),
      actions: [], // Actions are not serialized as they contain callbacks
      geminiActions: (json['geminiActions'] as List?)
              ?.map((action) => StarboundNudge.fromJson(action))
              .toList() ??
          [],
      timestamp: DateTime.parse(json['timestamp']),
      mood: json['mood'],
      confidence: json['confidence']?.toDouble(),
      insightSections: (json['insightSections'] as List?)
              ?.map((section) => InsightSection.fromJson(section))
              .toList() ??
          const [],
      aiSource: json['aiSource']?.toString() ?? 'unknown',
      isSimulated: json['isSimulated'] ?? false,
      diagnostics: (json['diagnostics'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
      whenToSeekCare: json['when_to_seek_care'] != null
          ? WhenToSeekCare.fromJson(json['when_to_seek_care'])
          : null,
      resourceNeeds: (json['resource_needs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
      followUpSuggestions: (json['follow_up_suggestions'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const [],
    );
  }

  /// Create a StarboundResponse from a plain text response (for backward compatibility)
  factory StarboundResponse.fromPlainText({
    required String id,
    required String userQuery,
    required String plainTextResponse,
    List<String>? actionLabels,
    DateTime? timestamp,
    String aiSource = 'unknown',
    bool isSimulated = false,
    List<String> diagnostics = const [],
  }) {
    // Simple parsing to extract overview and potential steps
    final lines = plainTextResponse
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    String overview = plainTextResponse;
    List<ActionableStep> steps = [];
    List<NextStepItem> nextSteps = [];

    // Try to identify step-like content (lines that start with numbers, bullets, or action words)
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Look for numbered steps or bullet points
      if (RegExp(r'^\d+\.').hasMatch(line) ||
          line.startsWith('•') ||
          line.startsWith('-') ||
          line.toLowerCase().startsWith('try ') ||
          line.toLowerCase().startsWith('consider ')) {
        final stepText = line
            .replaceFirst(RegExp(r'^\d+\.\s*'), '')
            .replaceFirst(RegExp(r'^[•-]\s*'), '');

        if (line.toLowerCase().contains('try') ||
            line.toLowerCase().contains('start')) {
          steps.add(ActionableStep(
            id: 'step_$i',
            text: stepText,
            estimatedTime: _extractTimeEstimate(stepText),
          ));
        } else {
          nextSteps.add(NextStepItem(
            id: 'next_$i',
            text: stepText,
            category: 'consider',
          ));
        }
      }
    }

    // If no steps were found, create overview-only response
    if (steps.isEmpty && nextSteps.isEmpty) {
      overview = plainTextResponse;
    } else {
      // Create overview from first sentences that aren't steps
      final nonStepLines = lines
          .where((line) =>
              !RegExp(r'^\d+\.').hasMatch(line.trim()) &&
              !line.trim().startsWith('•') &&
              !line.trim().startsWith('-'))
          .toList();

      if (nonStepLines.isNotEmpty) {
        overview = nonStepLines.take(2).join(' ');
      }
    }

    return StarboundResponse(
      id: id,
      userQuery: userQuery,
      overview: overview,
      immediateSteps: steps,
      nextSteps: nextSteps,
      actions: [], // Will be populated by the UI
      geminiActions: [], // No AI actions in plain text mode
      timestamp: timestamp ?? DateTime.now(),
      insightSections: [
        InsightSection(
          title: "What's happening",
          summary: overview,
        ),
      ],
      aiSource: aiSource,
      isSimulated: isSimulated,
      diagnostics: diagnostics,
    );
  }

  static String? _extractTimeEstimate(String text) {
    final timePattern = RegExp(r'(\d+)\s*(minute|min|second|sec|hour|hr)s?',
        caseSensitive: false);
    final match = timePattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)} ${match.group(2)}';
    }

    // Default estimates based on content
    if (text.toLowerCase().contains('drink') ||
        text.toLowerCase().contains('breathe')) {
      return '1 min';
    } else if (text.toLowerCase().contains('walk') ||
        text.toLowerCase().contains('stretch')) {
      return '2-5 min';
    } else if (text.toLowerCase().contains('write') ||
        text.toLowerCase().contains('plan')) {
      return '5-10 min';
    }

    return null;
  }

  @override
  String toString() {
    return 'StarboundResponse(id: $id, userQuery: $userQuery, stepsCount: ${immediateSteps.length}, nextStepsCount: ${nextSteps.length}, aiSource: $aiSource, isSimulated: $isSimulated)';
  }
}
