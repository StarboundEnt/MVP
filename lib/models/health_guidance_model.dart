/// Health guidance response model for AI-generated health navigation responses
/// Part of the health navigation transformation

import 'package:flutter/material.dart';
import 'health_question_model.dart';
import 'health_resource_model.dart';
import 'starbound_response.dart'; // Reuse ActionableStep from existing model

class WhenToSeekCare {
  final String seekCareNowIf;
  final String seekCareSoonIf;
  final String monitorFor;
  final List<String> warningSignsToWatch;

  const WhenToSeekCare({
    required this.seekCareNowIf,
    required this.seekCareSoonIf,
    required this.monitorFor,
    this.warningSignsToWatch = const [],
  });

  factory WhenToSeekCare.fromJson(Map<String, dynamic> json) {
    return WhenToSeekCare(
      seekCareNowIf: json['seekCareNowIf'] as String? ?? '',
      seekCareSoonIf: json['seekCareSoonIf'] as String? ?? '',
      monitorFor: json['monitorFor'] as String? ?? '',
      warningSignsToWatch: (json['warningSignsToWatch'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seekCareNowIf': seekCareNowIf,
      'seekCareSoonIf': seekCareSoonIf,
      'monitorFor': monitorFor,
      'warningSignsToWatch': warningSignsToWatch,
    };
  }
}

class HealthGuidanceResponse {
  final String id;
  final HealthQuestion question;
  final String overview; // Plain-language explanation (<=100 words)
  final UrgencyLevel urgency;
  final List<ActionableStep> immediateSteps;
  final List<HealthResource> recommendedResources;
  final WhenToSeekCare whenToSeekCare;
  final List<String> additionalInfo;
  final String medicalDisclaimer;
  final DateTime timestamp;
  final double confidence; // AI confidence (0.0-1.0)
  final String aiSource; // Which AI model generated this
  final bool isEmergency;

  const HealthGuidanceResponse({
    required this.id,
    required this.question,
    required this.overview,
    required this.urgency,
    required this.immediateSteps,
    required this.recommendedResources,
    required this.whenToSeekCare,
    this.additionalInfo = const [],
    required this.medicalDisclaimer,
    required this.timestamp,
    this.confidence = 0.0,
    this.aiSource = 'unknown',
    this.isEmergency = false,
  });

  factory HealthGuidanceResponse.fromJson(Map<String, dynamic> json) {
    return HealthGuidanceResponse(
      id: json['id'] as String,
      question: HealthQuestion.fromJson(json['question'] as Map<String, dynamic>),
      overview: json['overview'] as String,
      urgency: UrgencyLevel.values.firstWhere(
        (e) => e.toString() == 'UrgencyLevel.${json['urgency']}',
        orElse: () => UrgencyLevel.routine,
      ),
      immediateSteps: (json['immediateSteps'] as List<dynamic>?)
          ?.map((e) => ActionableStep.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      recommendedResources: (json['recommendedResources'] as List<dynamic>?)
          ?.map((e) => HealthResource.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      whenToSeekCare: WhenToSeekCare.fromJson(
        json['whenToSeekCare'] as Map<String, dynamic>? ?? {},
      ),
      additionalInfo: (json['additionalInfo'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? const [],
      medicalDisclaimer: json['medicalDisclaimer'] as String? ?? _defaultDisclaimer,
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      aiSource: json['aiSource'] as String? ?? 'unknown',
      isEmergency: json['isEmergency'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question.toJson(),
      'overview': overview,
      'urgency': urgency.name,
      'immediateSteps': immediateSteps.map((step) => step.toJson()).toList(),
      'recommendedResources': recommendedResources.map((r) => r.toJson()).toList(),
      'whenToSeekCare': whenToSeekCare.toJson(),
      'additionalInfo': additionalInfo,
      'medicalDisclaimer': medicalDisclaimer,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'aiSource': aiSource,
      'isEmergency': isEmergency,
    };
  }

  HealthGuidanceResponse copyWith({
    String? id,
    HealthQuestion? question,
    String? overview,
    UrgencyLevel? urgency,
    List<ActionableStep>? immediateSteps,
    List<HealthResource>? recommendedResources,
    WhenToSeekCare? whenToSeekCare,
    List<String>? additionalInfo,
    String? medicalDisclaimer,
    DateTime? timestamp,
    double? confidence,
    String? aiSource,
    bool? isEmergency,
  }) {
    return HealthGuidanceResponse(
      id: id ?? this.id,
      question: question ?? this.question,
      overview: overview ?? this.overview,
      urgency: urgency ?? this.urgency,
      immediateSteps: immediateSteps ?? this.immediateSteps,
      recommendedResources: recommendedResources ?? this.recommendedResources,
      whenToSeekCare: whenToSeekCare ?? this.whenToSeekCare,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      medicalDisclaimer: medicalDisclaimer ?? this.medicalDisclaimer,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      aiSource: aiSource ?? this.aiSource,
      isEmergency: isEmergency ?? this.isEmergency,
    );
  }

  // Default medical disclaimer
  static const String _defaultDisclaimer = '''
⚕️ This information is for educational purposes only and is not medical advice.
Starbound provides health navigation support, not diagnosis or treatment.

If you're experiencing a medical emergency, call 911.
For urgent concerns, please contact a healthcare provider.''';

  // Get urgency color based on level
  Color get urgencyColor {
    switch (urgency) {
      case UrgencyLevel.routine:
        return Colors.blue;
      case UrgencyLevel.monitor:
        return Colors.lightBlue;
      case UrgencyLevel.seekCareSoon:
        return Colors.orange;
      case UrgencyLevel.seekCareNow:
        return Colors.deepOrange;
      case UrgencyLevel.emergency:
        return Colors.red;
    }
  }

  // Get urgency icon
  IconData get urgencyIcon {
    switch (urgency) {
      case UrgencyLevel.routine:
        return Icons.calendar_today;
      case UrgencyLevel.monitor:
        return Icons.visibility;
      case UrgencyLevel.seekCareSoon:
        return Icons.schedule;
      case UrgencyLevel.seekCareNow:
        return Icons.local_hospital;
      case UrgencyLevel.emergency:
        return Icons.emergency;
    }
  }

  // Check if disclaimer acknowledgment is required
  bool get requiresDisclaimerAcknowledgment =>
      urgency == UrgencyLevel.seekCareNow ||
      urgency == UrgencyLevel.seekCareSoon ||
      isEmergency;

  // Check if resources are available
  bool get hasResources => recommendedResources.isNotEmpty;

  // Get number of steps completed
  int get completedStepsCount =>
      immediateSteps.where((step) => step.completed).length;

  // Get progress percentage
  double get stepsProgress =>
      immediateSteps.isEmpty ? 0.0 : completedStepsCount / immediateSteps.length;

  // Check if all steps are completed
  bool get allStepsCompleted =>
      immediateSteps.isNotEmpty && completedStepsCount == immediateSteps.length;

  @override
  String toString() {
    return 'HealthGuidanceResponse(id: $id, urgency: ${urgency.name}, resources: ${recommendedResources.length})';
  }
}

/// Emergency response for critical situations
class EmergencyGuidanceResponse extends HealthGuidanceResponse {
  final List<HealthResource> emergencyResources;
  final String emergencyInstructions;

  EmergencyGuidanceResponse({
    required super.id,
    required super.question,
    required super.overview,
    required super.immediateSteps,
    required this.emergencyResources,
    required this.emergencyInstructions,
    required super.timestamp,
  }) : super(
          urgency: UrgencyLevel.emergency,
          recommendedResources: emergencyResources,
          whenToSeekCare: const WhenToSeekCare(
            seekCareNowIf: 'Right now - this is an emergency',
            seekCareSoonIf: 'Not applicable',
            monitorFor: 'Not applicable - seek immediate care',
            warningSignsToWatch: [],
          ),
          medicalDisclaimer: '🚨 MEDICAL EMERGENCY - Call 911 immediately',
          isEmergency: true,
          additionalInfo: const ['Do not wait', 'Call 911 or go to emergency room now'],
        );

  // Create emergency response for common emergency scenarios
  factory EmergencyGuidanceResponse.create({
    required String id,
    required HealthQuestion question,
    required String emergencyType,
  }) {
    late String overview;
    late String instructions;
    late List<ActionableStep> steps;

    switch (emergencyType.toLowerCase()) {
      case 'chest_pain':
        overview = 'Chest pain can be a sign of a heart attack or other serious condition. This requires immediate medical attention.';
        instructions = 'Call 911 immediately. Do not drive yourself to the hospital.';
        steps = [
          const ActionableStep(
            id: 'step_1',
            text: 'Call 911 right now',
            estimatedTime: '<1 min',
          ),
          const ActionableStep(
            id: 'step_2',
            text: 'Sit or lie down in a comfortable position',
            estimatedTime: '<1 min',
          ),
          const ActionableStep(
            id: 'step_3',
            text: 'If you have aspirin and are not allergic, chew one adult aspirin (check with 911 operator)',
            estimatedTime: '<1 min',
          ),
        ];
        break;

      case 'breathing':
        overview = 'Severe difficulty breathing is a medical emergency that requires immediate attention.';
        instructions = 'Call 911 immediately. Do not wait to see if it gets better.';
        steps = [
          const ActionableStep(
            id: 'step_1',
            text: 'Call 911 right now',
            estimatedTime: '<1 min',
          ),
          const ActionableStep(
            id: 'step_2',
            text: 'Try to stay calm and sit upright',
            estimatedTime: '<1 min',
          ),
          const ActionableStep(
            id: 'step_3',
            text: 'Use your rescue inhaler if you have one',
            estimatedTime: '<1 min',
          ),
        ];
        break;

      case 'mental_health_crisis':
        overview = 'If you are thinking about suicide or self-harm, help is available right now.';
        instructions = 'Call 988 Suicide & Crisis Lifeline for immediate support from trained counselors.';
        steps = [
          const ActionableStep(
            id: 'step_1',
            text: 'Call or text 988 right now',
            estimatedTime: '<1 min',
          ),
          const ActionableStep(
            id: 'step_2',
            text: 'If in immediate danger, call 911',
            estimatedTime: '<1 min',
          ),
          const ActionableStep(
            id: 'step_3',
            text: 'Move to a safe location away from means of harm',
            estimatedTime: '<1 min',
          ),
        ];
        break;

      default:
        overview = 'This appears to be a medical emergency that requires immediate professional attention.';
        instructions = 'Call 911 immediately for emergency medical services.';
        steps = [
          const ActionableStep(
            id: 'step_1',
            text: 'Call 911 right now',
            estimatedTime: '<1 min',
          ),
          const ActionableStep(
            id: 'step_2',
            text: 'Stay calm and describe your symptoms to the operator',
            estimatedTime: '<1 min',
          ),
        ];
    }

    return EmergencyGuidanceResponse(
      id: id,
      question: question,
      overview: overview,
      immediateSteps: steps,
      emergencyResources: _getEmergencyResourcesForType(emergencyType),
      emergencyInstructions: instructions,
      timestamp: DateTime.now(),
    );
  }

  static List<HealthResource> _getEmergencyResourcesForType(String type) {
    switch (type.toLowerCase()) {
      case 'mental_health_crisis':
        return [
          EmergencyResources.all[1], // 988 Crisis Line
          EmergencyResources.all[0], // 911
        ];
      case 'poisoning':
      case 'overdose':
        return [
          EmergencyResources.all[3], // Poison Control
          EmergencyResources.all[0], // 911
        ];
      case 'domestic_violence':
        return [
          EmergencyResources.all[2], // Domestic Violence Hotline
          EmergencyResources.all[0], // 911
        ];
      default:
        return [EmergencyResources.all[0]]; // 911 only
    }
  }
}

/// Helper class for building health guidance responses from AI responses
class HealthGuidanceBuilder {
  /// Build guidance response from OpenRouter/AI response
  static HealthGuidanceResponse fromAiResponse({
    required String id,
    required HealthQuestion question,
    required Map<String, dynamic> aiResponse,
    required List<HealthResource> matchedResources,
  }) {
    final overview = aiResponse['overview'] as String? ?? '';
    final urgencyStr = aiResponse['urgency'] as String? ?? 'routine';
    final urgency = UrgencyLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == urgencyStr.toLowerCase(),
      orElse: () => UrgencyLevel.routine,
    );

    final immediateSteps = (aiResponse['immediate_steps'] as List<dynamic>?)
        ?.asMap()
        .entries
        .map((entry) {
          final step = entry.value;
          if (step is String) {
            return ActionableStep(
              id: 'step_${entry.key}',
              text: step,
            );
          } else if (step is Map<String, dynamic>) {
            return ActionableStep.fromJson(step);
          }
          return null;
        })
        .whereType<ActionableStep>()
        .toList() ?? [];

    final whenToSeekCare = WhenToSeekCare(
      seekCareNowIf: aiResponse['seek_care_now_if'] as String? ??
          'Symptoms worsen significantly or become severe',
      seekCareSoonIf: aiResponse['seek_care_soon_if'] as String? ??
          'Symptoms persist for more than a few days',
      monitorFor: aiResponse['monitor_for'] as String? ??
          'Changes in symptoms',
      warningSignsToWatch: (aiResponse['warning_signs'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );

    final additionalInfo = (aiResponse['additional_info'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    return HealthGuidanceResponse(
      id: id,
      question: question,
      overview: overview,
      urgency: urgency,
      immediateSteps: immediateSteps,
      recommendedResources: matchedResources,
      whenToSeekCare: whenToSeekCare,
      additionalInfo: additionalInfo,
      medicalDisclaimer: HealthGuidanceResponse._defaultDisclaimer,
      timestamp: DateTime.now(),
      confidence: (aiResponse['confidence'] as num?)?.toDouble() ?? 0.0,
      aiSource: aiResponse['model'] as String? ?? 'unknown',
      isEmergency: urgency == UrgencyLevel.emergency,
    );
  }
}
