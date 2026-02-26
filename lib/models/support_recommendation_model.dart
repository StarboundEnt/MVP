import 'dart:math';
import 'service_model.dart';

// 🎯 Support recommendation with AI context
class SupportRecommendation {
  final SupportService service;
  final String matchReason; // Why this service was recommended
  final double relevanceScore; // 0.0 to 1.0
  final String timingInfo; // "Open until 5pm", "Next available Thursday"
  final String actionable; // "Call now", "Visit Thursday 4-6pm"
  final List<String> matchedKeywords; // Keywords from user query that matched
  final String? urgencyLevel; // "immediate", "soon", "routine"
  final double? distance; // Distance in km if location available
  
  const SupportRecommendation({
    required this.service,
    required this.matchReason,
    required this.relevanceScore,
    required this.timingInfo,
    required this.actionable,
    this.matchedKeywords = const [],
    this.urgencyLevel,
    this.distance,
  });
  
  // Create recommendation from AI analysis
  factory SupportRecommendation.fromAnalysis({
    required SupportService service,
    required List<String> userKeywords,
    required Map<String, dynamic> aiAnalysis,
    double? userLatitude,
    double? userLongitude,
  }) {
    // Calculate relevance score based on keyword matches and AI analysis
    final matchedKeywords = <String>[];
    double relevanceScore = 0.0;
    
    // Check for keyword matches in service tags and offerings
    for (final keyword in userKeywords) {
      if (service.tags.any((tag) => tag.toLowerCase().contains(keyword.toLowerCase()))) {
        matchedKeywords.add(keyword);
        relevanceScore += 0.3;
      }
      if (service.offerings.any((offering) => 
          offering.category.toLowerCase().contains(keyword.toLowerCase()) ||
          offering.name.toLowerCase().contains(keyword.toLowerCase()))) {
        matchedKeywords.add(keyword);
        relevanceScore += 0.4;
      }
    }
    
    // Boost score for AI-detected urgency/category matches
    final urgencyLevel = aiAnalysis['urgency'] as String?;
    final category = aiAnalysis['category'] as String?;
    
    if (urgencyLevel == 'immediate' && service.schedules.any((s) => s.isEmergency)) {
      relevanceScore += 0.5;
    }
    
    if (category != null && service.tags.contains(category)) {
      relevanceScore += 0.3;
    }
    
    // Cap relevance score at 1.0
    relevanceScore = relevanceScore.clamp(0.0, 1.0);
    
    // Calculate distance if both locations available
    double? distance;
    if (userLatitude != null && userLongitude != null && service.location != null) {
      distance = calculateDistance(
        userLatitude, userLongitude,
        service.location!.latitude, service.location!.longitude,
      );
    }
    
    // Generate match reason
    String matchReason = 'Matches your ';
    if (matchedKeywords.isNotEmpty) {
      matchReason += '${matchedKeywords.join(', ')} needs';
    } else {
      matchReason += '${category ?? 'support'} request';
    }
    
    // Generate timing info
    String timingInfo = service.availabilityStatus;
    
    // Generate actionable advice
    String actionable;
    if (urgencyLevel == 'immediate' && service.schedules.any((s) => s.isEmergency)) {
      actionable = 'Call now - available 24/7';
    } else if (service.isAvailableNow) {
      actionable = 'Contact now - currently open';
    } else {
      // Find next available time
      actionable = 'Contact when they open';
      for (final schedule in service.schedules) {
        final now = DateTime.now();
        final dayName = _getDayName(now.weekday);
        if (schedule.day == dayName) {
          actionable = 'Contact at ${schedule.startTime}';
          break;
        }
      }
    }
    
    return SupportRecommendation(
      service: service,
      matchReason: matchReason,
      relevanceScore: relevanceScore,
      timingInfo: timingInfo,
      actionable: actionable,
      matchedKeywords: matchedKeywords,
      urgencyLevel: urgencyLevel,
      distance: distance,
    );
  }
  
  // Helper method to calculate distance between coordinates
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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
  
  static String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
  
  // Get display text for distance
  String get distanceText {
    if (distance == null) return '';
    if (distance! < 1.0) {
      return '${(distance! * 1000).round()}m away';
    } else {
      return '${distance!.toStringAsFixed(1)}km away';
    }
  }
  
  // Get priority level for sorting
  int get priority {
    // Higher number = higher priority
    int basePriority = (relevanceScore * 100).round();
    
    // Boost for urgency
    if (urgencyLevel == 'immediate') basePriority += 50;
    if (urgencyLevel == 'soon') basePriority += 25;
    
    // Boost for availability
    if (service.isAvailableNow) basePriority += 20;
    
    // Slight boost for proximity (closer = better)
    if (distance != null && distance! < 5.0) {
      basePriority += (10 - distance! * 2).round();
    }
    
    return basePriority;
  }
  
  Map<String, dynamic> toJson() => {
    'service': service.toJson(),
    'matchReason': matchReason,
    'relevanceScore': relevanceScore,
    'timingInfo': timingInfo,
    'actionable': actionable,
    'matchedKeywords': matchedKeywords,
    'urgencyLevel': urgencyLevel,
    'distance': distance,
  };
  
  factory SupportRecommendation.fromJson(Map<String, dynamic> json) {
    return SupportRecommendation(
      service: SupportService.fromJson(json['service']),
      matchReason: json['matchReason'] ?? '',
      relevanceScore: json['relevanceScore']?.toDouble() ?? 0.0,
      timingInfo: json['timingInfo'] ?? '',
      actionable: json['actionable'] ?? '',
      matchedKeywords: List<String>.from(json['matchedKeywords'] ?? []),
      urgencyLevel: json['urgencyLevel'],
      distance: json['distance']?.toDouble(),
    );
  }
  
  @override
  String toString() => 'SupportRecommendation(${service.name}, score: $relevanceScore)';
}

// 🧠 User question analysis result
class QuestionAnalysis {
  final String originalQuestion;
  final List<String> keywords; // Extracted keywords
  final String category; // "nutrition", "mental_health", "housing", etc.
  final String urgency; // "immediate", "soon", "routine"
  final List<String> emotions; // "stressed", "worried", "desperate"
  final Map<String, dynamic> context; // Additional context
  
  const QuestionAnalysis({
    required this.originalQuestion,
    required this.keywords,
    required this.category,
    required this.urgency,
    this.emotions = const [],
    this.context = const {},
  });
  
  Map<String, dynamic> toJson() => {
    'originalQuestion': originalQuestion,
    'keywords': keywords,
    'category': category,
    'urgency': urgency,
    'emotions': emotions,
    'context': context,
  };
  
  factory QuestionAnalysis.fromJson(Map<String, dynamic> json) {
    return QuestionAnalysis(
      originalQuestion: json['originalQuestion'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
      category: json['category'] ?? '',
      urgency: json['urgency'] ?? 'routine',
      emotions: List<String>.from(json['emotions'] ?? []),
      context: Map<String, dynamic>.from(json['context'] ?? {}),
    );
  }
}