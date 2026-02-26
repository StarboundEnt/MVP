/// Saved Items Models
/// For storing user-saved health resources and conversations
/// Part of the health navigation transformation

import 'health_resource_model.dart';
import '../data/nsw_health_resources.dart';

/// A health resource saved by the user with personal notes
class SavedResource {
  final String id;
  final String resourceId;
  final DateTime savedAt;
  final DateTime? lastAccessedAt;
  final String? userNotes;

  const SavedResource({
    required this.id,
    required this.resourceId,
    required this.savedAt,
    this.lastAccessedAt,
    this.userNotes,
  });

  /// Look up the actual HealthResource from the data
  HealthResource? get resource {
    // Check emergency resources first
    final emergency = EmergencyResources.all.where((r) => r.id == resourceId);
    if (emergency.isNotEmpty) return emergency.first;

    // Check NSW resources
    final nsw = nswHealthResources.where((r) => r.id == resourceId);
    if (nsw.isNotEmpty) return nsw.first;

    return null;
  }

  factory SavedResource.fromJson(Map<String, dynamic> json) {
    return SavedResource(
      id: json['id'] as String,
      resourceId: json['resourceId'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      userNotes: json['userNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resourceId': resourceId,
      'savedAt': savedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'userNotes': userNotes,
    };
  }

  SavedResource copyWith({
    String? id,
    String? resourceId,
    DateTime? savedAt,
    DateTime? lastAccessedAt,
    String? userNotes,
  }) {
    return SavedResource(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      savedAt: savedAt ?? this.savedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      userNotes: userNotes ?? this.userNotes,
    );
  }

  /// Create a new SavedResource from a resource ID
  static SavedResource create(String resourceId, {String? notes}) {
    return SavedResource(
      id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
      resourceId: resourceId,
      savedAt: DateTime.now(),
      userNotes: notes,
    );
  }

  @override
  String toString() {
    return 'SavedResource(id: $id, resourceId: $resourceId, savedAt: $savedAt)';
  }
}

/// When to seek care guidance from AI
class WhenToSeekCare {
  final String urgency;
  final List<String> warningSignsToWatch;
  final String? recommendedProvider;

  const WhenToSeekCare({
    required this.urgency,
    this.warningSignsToWatch = const [],
    this.recommendedProvider,
  });

  factory WhenToSeekCare.fromJson(Map<String, dynamic> json) {
    return WhenToSeekCare(
      urgency: json['urgency'] as String? ?? 'when needed',
      warningSignsToWatch: (json['warningSignsToWatch'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recommendedProvider: json['recommendedProvider'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urgency': urgency,
      'warningSignsToWatch': warningSignsToWatch,
      'recommendedProvider': recommendedProvider,
    };
  }
}

/// The AI's structured health response
class HealthResponse {
  final String understanding;
  final List<String> possibleCauses;
  final List<String> immediateSteps;
  final WhenToSeekCare? whenToSeekCare;
  final List<String> resourceNeeds;
  final String? summaryAdvice;

  const HealthResponse({
    required this.understanding,
    this.possibleCauses = const [],
    this.immediateSteps = const [],
    this.whenToSeekCare,
    this.resourceNeeds = const [],
    this.summaryAdvice,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      understanding: json['understanding'] as String? ?? '',
      possibleCauses: (json['possibleCauses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      immediateSteps: (json['immediateSteps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      whenToSeekCare: json['whenToSeekCare'] != null
          ? WhenToSeekCare.fromJson(
              json['whenToSeekCare'] as Map<String, dynamic>)
          : null,
      resourceNeeds: (json['resourceNeeds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      summaryAdvice: json['summaryAdvice'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'understanding': understanding,
      'possibleCauses': possibleCauses,
      'immediateSteps': immediateSteps,
      'whenToSeekCare': whenToSeekCare?.toJson(),
      'resourceNeeds': resourceNeeds,
      'summaryAdvice': summaryAdvice,
    };
  }
}

/// A health Q&A conversation saved by the user
class SavedConversation {
  final String id;
  final DateTime askedAt;
  final DateTime savedAt;
  final DateTime? lastAccessedAt;

  /// User's original question
  final String question;

  /// Summary for list display (3-4 main takeaways)
  final List<String> keyPoints;

  /// IDs of resources mentioned in the response
  final List<String> resourceIds;

  /// Full AI response for detail view
  final HealthResponse aiResponse;

  /// Tags for organization
  final List<String> tags;

  const SavedConversation({
    required this.id,
    required this.askedAt,
    required this.savedAt,
    this.lastAccessedAt,
    required this.question,
    this.keyPoints = const [],
    this.resourceIds = const [],
    required this.aiResponse,
    this.tags = const [],
  });

  /// Look up the actual HealthResources from IDs
  List<HealthResource> get resources {
    final allResources = [...EmergencyResources.all, ...nswHealthResources];
    return resourceIds
        .map((id) => allResources.where((r) => r.id == id).firstOrNull)
        .whereType<HealthResource>()
        .toList();
  }

  factory SavedConversation.fromJson(Map<String, dynamic> json) {
    return SavedConversation(
      id: json['id'] as String,
      askedAt: DateTime.parse(json['askedAt'] as String),
      savedAt: DateTime.parse(json['savedAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      question: json['question'] as String,
      keyPoints: (json['keyPoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      resourceIds: (json['resourceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      aiResponse:
          HealthResponse.fromJson(json['aiResponse'] as Map<String, dynamic>),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'askedAt': askedAt.toIso8601String(),
      'savedAt': savedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'question': question,
      'keyPoints': keyPoints,
      'resourceIds': resourceIds,
      'aiResponse': aiResponse.toJson(),
      'tags': tags,
    };
  }

  SavedConversation copyWith({
    String? id,
    DateTime? askedAt,
    DateTime? savedAt,
    DateTime? lastAccessedAt,
    String? question,
    List<String>? keyPoints,
    List<String>? resourceIds,
    HealthResponse? aiResponse,
    List<String>? tags,
  }) {
    return SavedConversation(
      id: id ?? this.id,
      askedAt: askedAt ?? this.askedAt,
      savedAt: savedAt ?? this.savedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      question: question ?? this.question,
      keyPoints: keyPoints ?? this.keyPoints,
      resourceIds: resourceIds ?? this.resourceIds,
      aiResponse: aiResponse ?? this.aiResponse,
      tags: tags ?? this.tags,
    );
  }

  /// Get relative time since asked (e.g., "2 days ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(askedAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1
          ? '1 day ago'
          : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }

  /// Truncated question for display (max 60 chars)
  String get truncatedQuestion {
    if (question.length <= 60) return question;
    return '${question.substring(0, 57)}...';
  }

  @override
  String toString() {
    return 'SavedConversation(id: $id, question: $truncatedQuestion)';
  }
}
