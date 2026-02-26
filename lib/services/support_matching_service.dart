import 'package:flutter/foundation.dart';
import '../models/service_model.dart';
import '../models/support_recommendation_model.dart';
import '../models/complexity_profile.dart';

/// 🧠 AI-powered support matching service
/// Analyzes user questions and matches them to relevant support services
class SupportMatchingService {
  static final SupportMatchingService _instance = SupportMatchingService._internal();
  factory SupportMatchingService() => _instance;
  SupportMatchingService._internal();

  // Keywords mapped to support categories
  static const Map<String, List<String>> _categoryKeywords = {
    'nutrition': [
      'hungry', 'food', 'eat', 'meal', 'starving', 'cooking', 'grocery', 'groceries',
      'nutrition', 'diet', 'weight', 'eating', 'fasting', 'breakfast', 'lunch', 'dinner'
    ],
    'mental_health': [
      'stressed', 'anxious', 'worried', 'depressed', 'sad', 'overwhelmed', 'panic',
      'therapy', 'counseling', 'counselling', 'mental', 'psychology', 'psychiatrist',
      'mood', 'emotional', 'feelings', 'thoughts', 'suicidal', 'self-harm'
    ],
    'housing': [
      'homeless', 'housing', 'shelter', 'accommodation', 'rent', 'evicted', 'eviction',
      'place to stay', 'nowhere to sleep', 'couch surfing', 'temporary housing'
    ],
    'financial': [
      'money', 'broke', 'poor', 'financial', 'budget', 'debt', 'bills', 'rent',
      'payment', 'income', 'welfare', 'centrelink', 'unemployment', 'job', 'work'
    ],
    'crisis': [
      'crisis', 'emergency', 'urgent', 'immediate', 'help', 'desperate', 'danger',
      'suicide', 'self-harm', 'abuse', 'violence', 'threat', 'scared', 'afraid'
    ],
    'education': [
      'study', 'school', 'university', 'uni', 'college', 'student', 'assignment',
      'exam', 'grade', 'academic', 'course', 'class', 'education', 'learning'
    ],
    'support': [
      'alone', 'lonely', 'isolated', 'friends', 'social', 'community', 'connect',
      'talk', 'someone', 'support', 'help', 'guidance', 'advice'
    ]
  };

  // Urgency detection keywords
  static const Map<String, List<String>> _urgencyKeywords = {
    'immediate': [
      'now', 'urgent', 'emergency', 'immediately', 'desperate', 'crisis',
      'today', 'asap', 'right now', 'help me', 'suicidal', 'danger'
    ],
    'soon': [
      'soon', 'this week', 'quickly', 'fast', 'tomorrow', 'next few days',
      'running out', 'almost out', 'getting worse', 'can\'t wait'
    ],
    'routine': [
      'eventually', 'when possible', 'sometime', 'planning', 'thinking about',
      'considering', 'maybe', 'might', 'could use', 'would like'
    ]
  };

  // Emotional state keywords
  static const List<String> _emotionKeywords = [
    'stressed', 'anxious', 'worried', 'scared', 'overwhelmed', 'desperate',
    'frustrated', 'angry', 'sad', 'depressed', 'hopeless', 'confused',
    'tired', 'exhausted', 'burnt out', 'isolated', 'lonely'
  ];

  /// Analyze user question to extract support needs
  QuestionAnalysis analyzeQuestion(String question) {
    final normalizedQuestion = question.toLowerCase().trim();
    final words = normalizedQuestion.split(RegExp(r'\s+'));
    
    // Extract keywords
    final Set<String> extractedKeywords = {};
    final Set<String> detectedEmotions = {};
    
    // Check for category keywords
    String primaryCategory = 'support'; // Default category
    double maxCategoryScore = 0.0;
    
    for (final entry in _categoryKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;
      double categoryScore = 0.0;
      
      for (final keyword in keywords) {
        if (normalizedQuestion.contains(keyword)) {
          extractedKeywords.add(keyword);
          categoryScore += 1.0;
          
          // Boost score for exact word matches
          if (words.contains(keyword)) {
            categoryScore += 0.5;
          }
        }
      }
      
      if (categoryScore > maxCategoryScore) {
        maxCategoryScore = categoryScore;
        primaryCategory = category;
      }
    }
    
    // Detect urgency level
    String urgencyLevel = 'routine';
    for (final entry in _urgencyKeywords.entries) {
      final urgency = entry.key;
      final keywords = entry.value;
      
      for (final keyword in keywords) {
        if (normalizedQuestion.contains(keyword)) {
          urgencyLevel = urgency;
          extractedKeywords.add(keyword);
          break;
        }
      }
      
      if (urgencyLevel != 'routine') break;
    }
    
    // Extract emotional indicators
    for (final emotion in _emotionKeywords) {
      if (normalizedQuestion.contains(emotion)) {
        detectedEmotions.add(emotion);
      }
    }
    
    return QuestionAnalysis(
      originalQuestion: question,
      keywords: extractedKeywords.toList(),
      category: primaryCategory,
      urgency: urgencyLevel,
      emotions: detectedEmotions.toList(),
      context: {
        'categoryScore': maxCategoryScore,
        'wordCount': words.length,
        'hasPersonalPronouns': _hasPersonalPronouns(normalizedQuestion),
      },
    );
  }

  /// Generate support recommendations based on user question
  Future<List<SupportRecommendation>> getRecommendations({
    required String userQuestion,
    required List<SupportService> availableServices,
    ComplexityLevel? userComplexityProfile,
    double? userLatitude,
    double? userLongitude,
    int maxRecommendations = 5,
  }) async {
    try {
      // Analyze the user's question
      final analysis = analyzeQuestion(userQuestion);
      
      // Create AI analysis map for recommendation generation
      final aiAnalysis = {
        'category': analysis.category,
        'urgency': analysis.urgency,
        'emotions': analysis.emotions,
        'keywords': analysis.keywords,
      };
      
      // Generate recommendations for all services
      final allRecommendations = <SupportRecommendation>[];
      
      for (final service in availableServices) {
        final recommendation = SupportRecommendation.fromAnalysis(
          service: service,
          userKeywords: analysis.keywords,
          aiAnalysis: aiAnalysis,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        );
        
        // Only include recommendations with relevance > 0.1
        if (recommendation.relevanceScore > 0.1) {
          allRecommendations.add(recommendation);
        }
      }
      
      // Sort by priority (highest first)
      allRecommendations.sort((a, b) => b.priority.compareTo(a.priority));
      
      // Apply complexity profile filtering if provided
      List<SupportRecommendation> filteredRecommendations = allRecommendations;
      if (userComplexityProfile != null) {
        filteredRecommendations = _filterByComplexityProfile(
          allRecommendations, 
          userComplexityProfile
        );
      }
      
      // Return top recommendations
      return filteredRecommendations.take(maxRecommendations).toList();
      
    } catch (e) {
      debugPrint('Error generating support recommendations: $e');
      return [];
    }
  }

  /// Filter recommendations based on user's complexity profile
  List<SupportRecommendation> _filterByComplexityProfile(
    List<SupportRecommendation> recommendations,
    ComplexityLevel complexityProfile,
  ) {
    switch (complexityProfile) {
      case ComplexityLevel.survival:
        // For survival users, prioritize:
        // - Emergency services
        // - Simple contact methods (call vs online booking)
        // - Immediate availability
        return recommendations.where((rec) {
          final service = rec.service;
          
          // Prioritize emergency services
          if (service.tags.contains('emergency') || 
              service.schedules.any((s) => s.isEmergency)) {
            return true;
          }
          
          // Prefer services with simple contact methods
          if (service.contact.toLowerCase().startsWith('call')) {
            return true;
          }
          
          // Include if high relevance
          return rec.relevanceScore > 0.6;
        }).toList();

      case ComplexityLevel.overloaded:
        // For overloaded users, prioritize:
        // - Services available outside business hours
        // - Low-barrier services (no referral needed)
        // - Online services
        return recommendations.where((rec) {
          final service = rec.service;
          
          // Prefer flexible timing
          if (service.schedules.any((s) => s.isEmergency) ||
              service.schedules.any((s) => 
                s.startTime.compareTo('18:00') > 0 || // Evening services
                s.day == 'Saturday' || s.day == 'Sunday')) { // Weekend services
            return true;
          }
          
          // Prefer online/text contact
          if (service.contact.toLowerCase().contains('online') ||
              service.contact.toLowerCase().startsWith('text') ||
              service.contact.toLowerCase().startsWith('email')) {
            return true;
          }
          
          return rec.relevanceScore > 0.4;
        }).toList();

      case ComplexityLevel.trying:
        // For trying users, balance immediate and future needs
        return recommendations.where((rec) => rec.relevanceScore > 0.3).toList();

      case ComplexityLevel.stable:
        // For stable users, show all relevant options including longer-term support
        return recommendations;
    }
  }

  /// Check if question contains personal pronouns (indicates personal need vs general inquiry)
  bool _hasPersonalPronouns(String question) {
    final personalPronouns = ['i', 'me', 'my', 'myself', 'i\'m', 'i\'ve', 'i\'ll'];
    final words = question.split(RegExp(r'\s+'));
    
    return words.any((word) => personalPronouns.contains(word.toLowerCase()));
  }

  /// Get quick support options for emergency situations
  List<SupportRecommendation> getEmergencyRecommendations(
    List<SupportService> availableServices,
  ) {
    final emergencyServices = availableServices.where((service) =>
      service.tags.contains('crisis') ||
      service.tags.contains('emergency') ||
      service.schedules.any((s) => s.isEmergency)
    ).toList();

    return emergencyServices.map((service) => SupportRecommendation(
      service: service,
      matchReason: 'Emergency support available',
      relevanceScore: 1.0,
      timingInfo: '24/7 Available',
      actionable: 'Call now',
      urgencyLevel: 'immediate',
    )).toList();
  }

  /// Search services by location proximity
  List<SupportService> searchByLocation({
    required List<SupportService> services,
    required double userLatitude,
    required double userLongitude,
    double maxDistanceKm = 10.0,
  }) {
    final nearbyServices = <SupportService>[];
    
    for (final service in services) {
      if (service.location != null) {
        final distance = SupportRecommendation.calculateDistance(
          userLatitude, userLongitude,
          service.location!.latitude, service.location!.longitude,
        );
        
        if (distance <= maxDistanceKm) {
          nearbyServices.add(service);
        }
      }
    }
    
    // Sort by distance (closest first)
    nearbyServices.sort((a, b) {
      final distanceA = SupportRecommendation.calculateDistance(
        userLatitude, userLongitude,
        a.location!.latitude, a.location!.longitude,
      );
      final distanceB = SupportRecommendation.calculateDistance(
        userLatitude, userLongitude,
        b.location!.latitude, b.location!.longitude,
      );
      return distanceA.compareTo(distanceB);
    });
    
    return nearbyServices;
  }
}