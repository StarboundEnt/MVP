import 'dart:convert';

class ForecastHorizon {
  final String id; // e.g., month1, month6, year1, year5
  final String label;
  final String timeframe;
  final String outlook;
  final String recommendedMove;
  final List<String> drivingSignals;
  final double confidence; // 0.0 - 1.0
  final String riskLevel; // descriptive label for UI (e.g., low, medium, high)
  final String? trend; // optional descriptor like rising, steady

  const ForecastHorizon({
    required this.id,
    required this.label,
    required this.timeframe,
    required this.outlook,
    required this.recommendedMove,
    required this.drivingSignals,
    required this.confidence,
    required this.riskLevel,
    this.trend,
  });

  factory ForecastHorizon.fromJson(Map<String, dynamic> json) {
    final confidenceValue = json['confidence'];
    final parsedConfidence = confidenceValue is num
        ? confidenceValue.toDouble().clamp(0.0, 1.0)
        : double.tryParse(confidenceValue?.toString() ?? '')?.clamp(0.0, 1.0) ??
            0.5;

    final signals = <String>[];
    final rawSignals = json['driving_signals'] ?? json['top_signals'];
    if (rawSignals is List) {
      for (final signal in rawSignals) {
        final asString = signal?.toString().trim();
        if (asString != null && asString.isNotEmpty) {
          signals.add(asString);
        }
      }
    }

    return ForecastHorizon(
      id: json['id']?.toString().trim() ?? 'unknown',
      label: json['label']?.toString().trim() ?? 'Forecast',
      timeframe: json['timeframe']?.toString().trim() ?? '',
      outlook: json['outlook']?.toString().trim() ?? '',
      recommendedMove:
          json['recommended_move']?.toString().trim() ?? '',
      drivingSignals: signals,
      confidence: parsedConfidence,
      riskLevel: json['risk_level']?.toString().trim() ?? 'medium',
      trend: json['trend']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'timeframe': timeframe,
      'outlook': outlook,
      'recommended_move': recommendedMove,
      'driving_signals': drivingSignals,
      'confidence': confidence,
      'risk_level': riskLevel,
      if (trend != null && trend!.isNotEmpty) 'trend': trend,
    };
  }

  ForecastHorizon copyWith({
    String? id,
    String? label,
    String? timeframe,
    String? outlook,
    String? recommendedMove,
    List<String>? drivingSignals,
    double? confidence,
    String? riskLevel,
    String? trend,
  }) {
    return ForecastHorizon(
      id: id ?? this.id,
      label: label ?? this.label,
      timeframe: timeframe ?? this.timeframe,
      outlook: outlook ?? this.outlook,
      recommendedMove: recommendedMove ?? this.recommendedMove,
      drivingSignals: drivingSignals ?? this.drivingSignals,
      confidence: confidence ?? this.confidence,
      riskLevel: riskLevel ?? this.riskLevel,
      trend: trend ?? this.trend,
    );
  }
}

class ForecastEntry {
  final String id;
  final String habit;
  final DateTime createdAt;
  final String complexityProfile;
  final String summary;
  final String immediateAction;
  final String encouragement;
  final String whyItMatters;
  final List<String> keySignals;
  final List<ForecastHorizon> horizons;
  final Map<String, String> impactAreas; // mental/physical/social
  final Map<String, dynamic> metadata;

  const ForecastEntry({
    required this.id,
    required this.habit,
    required this.createdAt,
    required this.complexityProfile,
    required this.summary,
    required this.immediateAction,
    required this.encouragement,
    required this.whyItMatters,
    required this.keySignals,
    required this.horizons,
    this.impactAreas = const {},
    this.metadata = const {},
  });

  factory ForecastEntry.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'];
    DateTime parsedCreatedAt;
    if (createdAtValue is String) {
      parsedCreatedAt = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else if (createdAtValue is int) {
      parsedCreatedAt =
          DateTime.fromMillisecondsSinceEpoch(createdAtValue, isUtc: false);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    final keySignals = <String>[];
    final rawSignals = json['key_signals'];
    if (rawSignals is List) {
      for (final signal in rawSignals) {
        final asString = signal?.toString().trim();
        if (asString != null && asString.isNotEmpty) {
          keySignals.add(asString);
        }
      }
    }

    final horizons = <ForecastHorizon>[];
    final rawHorizons = json['horizons'];
    if (rawHorizons is List) {
      for (final horizon in rawHorizons) {
        if (horizon is Map<String, dynamic>) {
          horizons.add(ForecastHorizon.fromJson(horizon));
        } else if (horizon is Map) {
          horizons.add(ForecastHorizon.fromJson(
              horizon.map((key, value) => MapEntry(key.toString(), value))));
        }
      }
    }

    final impactAreas = _parseImpactAreas(json['impact_areas']);
    if (impactAreas.isEmpty) {
      final metadataAreas = _normalizeMetadata(json['metadata'])['impact_areas'];
      impactAreas.addAll(_parseImpactAreas(metadataAreas));
    }

    return ForecastEntry(
      id: json['id']?.toString().trim() ??
          'forecast-${DateTime.now().millisecondsSinceEpoch}',
      habit: json['habit']?.toString().trim() ?? 'current habit',
      createdAt: parsedCreatedAt,
      complexityProfile:
          json['complexity_profile']?.toString().trim() ?? 'stable',
      summary: json['summary']?.toString().trim() ?? '',
      immediateAction:
          json['immediate_action']?.toString().trim() ?? '',
      encouragement: json['encouragement']?.toString().trim() ?? '',
      whyItMatters: json['why_it_matters']?.toString().trim() ?? '',
      keySignals: keySignals,
      horizons: horizons,
      impactAreas: impactAreas.isNotEmpty
          ? impactAreas
          : _defaultImpactAreas(json['habit']?.toString() ?? ''),
      metadata: _normalizeMetadata(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit': habit,
      'created_at': createdAt.toIso8601String(),
      'complexity_profile': complexityProfile,
      'summary': summary,
      'immediate_action': immediateAction,
      'encouragement': encouragement,
      'why_it_matters': whyItMatters,
      'key_signals': keySignals,
      'horizons': horizons.map((h) => h.toJson()).toList(),
      if (impactAreas.isNotEmpty) 'impact_areas': impactAreas,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  ForecastEntry copyWith({
    String? id,
    String? habit,
    DateTime? createdAt,
    String? complexityProfile,
    String? summary,
    String? immediateAction,
    String? encouragement,
    String? whyItMatters,
    List<String>? keySignals,
    List<ForecastHorizon>? horizons,
    Map<String, String>? impactAreas,
    Map<String, dynamic>? metadata,
  }) {
    return ForecastEntry(
      id: id ?? this.id,
      habit: habit ?? this.habit,
      createdAt: createdAt ?? this.createdAt,
      complexityProfile: complexityProfile ?? this.complexityProfile,
      summary: summary ?? this.summary,
      immediateAction: immediateAction ?? this.immediateAction,
      encouragement: encouragement ?? this.encouragement,
      whyItMatters: whyItMatters ?? this.whyItMatters,
      keySignals: keySignals ?? this.keySignals,
      horizons: horizons ?? this.horizons,
      impactAreas: impactAreas ?? this.impactAreas,
      metadata: metadata ?? this.metadata,
    );
  }

  static Map<String, dynamic> _normalizeMetadata(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return {'raw': value};
      }
    }
    return const {};
  }

  static Map<String, String> _parseImpactAreas(dynamic value) {
    final result = <String, String>{};
    if (value is Map<String, dynamic>) {
      value.forEach((key, val) {
        final normalizedValue = val?.toString().trim();
        if (normalizedValue != null && normalizedValue.isNotEmpty) {
          result[key.toLowerCase()] = normalizedValue;
        }
      });
    } else if (value is Map) {
      value.forEach((key, val) {
        final normalizedValue = val?.toString().trim();
        if (normalizedValue != null && normalizedValue.isNotEmpty) {
          result[key.toString().toLowerCase()] = normalizedValue;
        }
      });
    }
    return result;
  }

  static Map<String, String> _defaultImpactAreas(String habit) {
    final lower = habit.toLowerCase();
    final impacts = <String, String>{};

    if (lower.contains(RegExp(r'sleep|rest|bed'))) {
      impacts['mental'] =
          'Sleep debt makes focus and mood fragile, so even small stressors feel heavy.';
      impacts['physical'] = 'Recovery slows and immunity dips, raising fatigue risk.';
      impacts['social'] = 'Irritability and low bandwidth make connection feel harder.';
    } else if (lower.contains(RegExp(r'meal|eat|food|nutrition'))) {
      impacts['mental'] = 'Blood sugar swings bring fog, irritability, and low motivation.';
      impacts['physical'] = 'Energy crashes strain metabolism and hormone balance.';
      impacts['social'] = 'Skipping meals can disrupt shared routines or meals with others.';
    } else if (lower.contains(RegExp(r'vape|nicotine|smok|e-?cig'))) {
      impacts['mental'] =
          'Nicotine primes reward pathways, so everyday cues start to trigger cravings and mood swings.';
      impacts['physical'] =
          'Vape aerosols irritate lungs and heart, reducing stamina and recovery even in the short term.';
      impacts['social'] =
          'Stepping away for hits—or hiding the habit—can distance you from routines and relationships.';
    } else if (lower.contains(RegExp(r'water|hydration|drink'))) {
      impacts['mental'] = 'Dehydration blunts concentration and increases stress sensitivity.';
      impacts['physical'] = 'Cells struggle to regulate temperature, joints, and digestion.';
      impacts['social'] = 'Low energy makes it easier to withdraw from plans and check-ins.';
    } else {
      impacts['mental'] = 'Mindset and resilience shift first—watch for focus and mood dips.';
      impacts['physical'] = 'Body signals like energy, sleep quality, and tension respond next.';
      impacts['social'] = 'Habits ripple into communication, boundaries, and follow-through.';
    }

    return impacts;
  }

  static Map<String, String> defaultImpactAreasFor(String habit) {
    return _defaultImpactAreas(habit);
  }
}
