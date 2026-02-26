/// Resource Matcher Service
/// Calculates match scores and generates personalized match reasons
/// based on user's barriers, location, and language preferences

import '../models/health_resource_model.dart';
import '../models/health_barrier_model.dart';

/// Result of matching a resource to user's needs
class MatchResult {
  final double score;
  final List<String> reasons;

  const MatchResult({
    required this.score,
    required this.reasons,
  });

  MatchResult copyWith({double? score, List<String>? reasons}) {
    return MatchResult(
      score: score ?? this.score,
      reasons: reasons ?? this.reasons,
    );
  }
}

/// Service for matching health resources to user needs
class ResourceMatcherService {
  // Singleton pattern
  static final ResourceMatcherService _instance =
      ResourceMatcherService._internal();
  factory ResourceMatcherService() => _instance;
  ResourceMatcherService._internal();

  /// Calculate match score and generate reasons for a single resource
  MatchResult calculateMatch({
    required HealthResource resource,
    HealthBarrierAssessment? barriers,
    String? userLocation,
    String? userRegion,
    List<String> userLanguages = const ['English'],
  }) {
    double score = 0.0;
    final reasons = <String>[];

    // ─────────────────────────────────────────────────────────────────────────
    // COST BARRIER MATCHING
    // ─────────────────────────────────────────────────────────────────────────
    if (barriers?.hasBarrier(HealthBarrierCategory.cost) == true ||
        barriers?.hasBarrier(HealthBarrierCategory.insurance) == true) {
      if (resource.costInfo.isFreeService) {
        score += 0.35;
        reasons.add('✓ Free service');
      } else if (resource.costInfo.hasBulkBilling) {
        score += 0.30;
        reasons.add('✓ Bulk billing (no gap fees)');
      } else if (resource.costInfo.hasNoGapFees) {
        score += 0.25;
        reasons.add('✓ No gap fees');
      } else if (resource.costInfo.hasConcessionRates) {
        score += 0.20;
        reasons.add('✓ Concession rates available');
      } else if (resource.costInfo.hasSlidingScale) {
        score += 0.20;
        reasons.add('✓ Sliding scale fees');
      }
    } else {
      // Even without cost barrier, free/bulk billing is a positive
      if (resource.costInfo.isFreeService) {
        score += 0.15;
      } else if (resource.costInfo.hasBulkBilling) {
        score += 0.10;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TIME BARRIER MATCHING
    // ─────────────────────────────────────────────────────────────────────────
    if (barriers?.hasBarrier(HealthBarrierCategory.time) == true) {
      if (resource.hasFeature(ResourceFeature.open24Hours) ||
          resource.hours.isOpen24Hours) {
        score += 0.30;
        reasons.add('✓ Open 24/7');
      } else if (resource.hasFeature(ResourceFeature.weekendHours)) {
        score += 0.25;
        reasons.add('✓ Open weekends (fits your schedule)');
      } else if (resource.hasFeature(ResourceFeature.eveningHours)) {
        score += 0.20;
        reasons.add('✓ Evening hours available');
      }

      if (resource.hasFeature(ResourceFeature.walkIn) ||
          resource.hasFeature(ResourceFeature.noReferralNeeded)) {
        score += 0.15;
        if (resource.hasFeature(ResourceFeature.walkIn)) {
          reasons.add('✓ Walk-in welcome (no appointment)');
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TRANSPORTATION BARRIER MATCHING
    // ─────────────────────────────────────────────────────────────────────────
    if (barriers?.hasBarrier(HealthBarrierCategory.transportation) == true) {
      // Telehealth is huge for transportation barriers
      if (resource.hasFeature(ResourceFeature.telehealth) ||
          resource.accessibility.hasTelehealth) {
        score += 0.30;
        reasons.add('✓ Telehealth available (no travel needed)');
      }

      // Location proximity
      if (userRegion != null && resource.region != null) {
        if (resource.region!.toLowerCase() == userRegion.toLowerCase()) {
          score += 0.20;
          reasons.add('✓ In your area ($userRegion)');
        }
      } else if (userLocation != null && resource.neighborhood != null) {
        if (resource.neighborhood!.toLowerCase() == userLocation.toLowerCase()) {
          score += 0.25;
          reasons.add('✓ Near you ($userLocation)');
        }
      }

      if (resource.hasFeature(ResourceFeature.publicTransport) ||
          resource.accessibility.publicTransitNearby) {
        score += 0.10;
        reasons.add('✓ Near public transport');
      }
    } else {
      // Still give location bonus without barrier
      if (userRegion != null &&
          resource.region?.toLowerCase() == userRegion.toLowerCase()) {
        score += 0.10;
        reasons.add('✓ In your area ($userRegion)');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // LANGUAGE BARRIER MATCHING
    // ─────────────────────────────────────────────────────────────────────────
    if (barriers?.hasBarrier(HealthBarrierCategory.language) == true) {
      final resourceLanguages = resource.accessibility.languagesSpoken
          .map((l) => l.toLowerCase())
          .toList();
      final matchedLanguages = userLanguages
          .where((lang) => resourceLanguages.any((rl) =>
              rl.contains(lang.toLowerCase()) ||
              lang.toLowerCase().contains(rl)))
          .toList();

      if (matchedLanguages.isNotEmpty) {
        score += 0.30;
        if (matchedLanguages.length == 1 &&
            matchedLanguages.first.toLowerCase() != 'english') {
          reasons.add('✓ ${matchedLanguages.first} speaking staff');
        } else if (matchedLanguages.length > 1) {
          reasons.add(
              '✓ ${matchedLanguages.take(2).join(" & ")} speaking');
        }
      }

      if (resource.hasFeature(ResourceFeature.interpreterAvailable) ||
          resource.accessibility.hasInterpreter) {
        score += 0.15;
        if (matchedLanguages.isEmpty) {
          reasons.add('✓ Interpreter services available');
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DOCUMENTATION BARRIER MATCHING
    // ─────────────────────────────────────────────────────────────────────────
    if (barriers?.hasBarrier(HealthBarrierCategory.documentation) == true) {
      if (resource.hasFeature(ResourceFeature.noIdRequired)) {
        score += 0.25;
        reasons.add('✓ No ID required');
      }
      if (resource.hasFeature(ResourceFeature.confidential)) {
        score += 0.10;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TRUST BARRIER MATCHING
    // ─────────────────────────────────────────────────────────────────────────
    if (barriers?.hasBarrier(HealthBarrierCategory.trust) == true) {
      if (resource.hasFeature(ResourceFeature.confidential)) {
        score += 0.15;
        reasons.add('✓ Confidential service');
      }
      if (resource.hasFeature(ResourceFeature.noReferralNeeded)) {
        score += 0.10;
        reasons.add('✓ No referral needed');
      }
      if (resource.hasFeature(ResourceFeature.culturallySafe)) {
        score += 0.15;
        reasons.add('✓ Culturally safe environment');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DISABILITY BARRIER MATCHING
    // ─────────────────────────────────────────────────────────────────────────
    if (barriers?.hasBarrier(HealthBarrierCategory.disability) == true) {
      if (resource.hasFeature(ResourceFeature.wheelchairAccess) ||
          resource.accessibility.wheelchairAccessible) {
        score += 0.25;
        reasons.add('✓ Wheelchair accessible');
      }
      if (resource.hasFeature(ResourceFeature.parking) ||
          resource.accessibility.hasParking) {
        score += 0.10;
        reasons.add('✓ Parking available');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CRISIS/EMERGENCY BONUS
    // ─────────────────────────────────────────────────────────────────────────
    if (resource.isCrisisResource) {
      score += 0.10; // Crisis resources always get a small bonus
    }

    // Normalize score to 0.0 - 1.0 range
    final normalizedScore = score.clamp(0.0, 1.0);

    return MatchResult(
      score: normalizedScore,
      reasons: reasons,
    );
  }

  /// Apply match scoring to a list of resources
  List<HealthResource> applyMatching({
    required List<HealthResource> resources,
    HealthBarrierAssessment? barriers,
    String? userLocation,
    String? userRegion,
    List<String> userLanguages = const ['English'],
  }) {
    return resources.map((resource) {
      final match = calculateMatch(
        resource: resource,
        barriers: barriers,
        userLocation: userLocation,
        userRegion: userRegion,
        userLanguages: userLanguages,
      );

      return resource.copyWith(
        matchScore: match.score,
        matchReasons: match.reasons,
      );
    }).toList();
  }

  /// Get resources sorted by match score (highest first)
  List<HealthResource> getMatchedResources({
    required List<HealthResource> resources,
    HealthBarrierAssessment? barriers,
    String? userLocation,
    String? userRegion,
    List<String> userLanguages = const ['English'],
    int? limit,
  }) {
    final matched = applyMatching(
      resources: resources,
      barriers: barriers,
      userLocation: userLocation,
      userRegion: userRegion,
      userLanguages: userLanguages,
    );

    // Sort by match score descending
    matched.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    // Apply limit if specified
    if (limit != null && limit < matched.length) {
      return matched.take(limit).toList();
    }

    return matched;
  }

  /// Get top matched resources (those with score > threshold)
  List<HealthResource> getTopMatches({
    required List<HealthResource> resources,
    HealthBarrierAssessment? barriers,
    String? userLocation,
    String? userRegion,
    List<String> userLanguages = const ['English'],
    double threshold = 0.3,
    int maxResults = 5,
  }) {
    final matched = getMatchedResources(
      resources: resources,
      barriers: barriers,
      userLocation: userLocation,
      userRegion: userRegion,
      userLanguages: userLanguages,
    );

    return matched
        .where((r) => r.matchScore >= threshold)
        .take(maxResults)
        .toList();
  }

  /// Filter resources by type and apply matching
  List<HealthResource> getMatchedByType({
    required List<HealthResource> resources,
    required ResourceType type,
    HealthBarrierAssessment? barriers,
    String? userLocation,
    String? userRegion,
    List<String> userLanguages = const ['English'],
  }) {
    final filtered = resources.where((r) => r.type == type).toList();
    return getMatchedResources(
      resources: filtered,
      barriers: barriers,
      userLocation: userLocation,
      userRegion: userRegion,
      userLanguages: userLanguages,
    );
  }

  /// Filter resources by feature and apply matching
  List<HealthResource> getMatchedByFeature({
    required List<HealthResource> resources,
    required ResourceFeature feature,
    HealthBarrierAssessment? barriers,
    String? userLocation,
    String? userRegion,
    List<String> userLanguages = const ['English'],
  }) {
    final filtered = resources.where((r) => r.hasFeature(feature)).toList();
    return getMatchedResources(
      resources: filtered,
      barriers: barriers,
      userLocation: userLocation,
      userRegion: userRegion,
      userLanguages: userLanguages,
    );
  }

  /// Search resources and apply matching
  List<HealthResource> searchAndMatch({
    required List<HealthResource> resources,
    required String query,
    HealthBarrierAssessment? barriers,
    String? userLocation,
    String? userRegion,
    List<String> userLanguages = const ['English'],
  }) {
    final lowercaseQuery = query.toLowerCase();
    final filtered = resources.where((resource) {
      return resource.name.toLowerCase().contains(lowercaseQuery) ||
          (resource.description?.toLowerCase().contains(lowercaseQuery) ??
              false) ||
          resource.servicesOffered
              .any((s) => s.toLowerCase().contains(lowercaseQuery)) ||
          (resource.neighborhood?.toLowerCase().contains(lowercaseQuery) ??
              false) ||
          (resource.region?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          resource.typeDisplayName.toLowerCase().contains(lowercaseQuery);
    }).toList();

    return getMatchedResources(
      resources: filtered,
      barriers: barriers,
      userLocation: userLocation,
      userRegion: userRegion,
      userLanguages: userLanguages,
    );
  }

  /// Get resources grouped by category with matching applied
  Map<String, List<HealthResource>> getGroupedAndMatched({
    required List<HealthResource> resources,
    HealthBarrierAssessment? barriers,
    String? userLocation,
    String? userRegion,
    List<String> userLanguages = const ['English'],
  }) {
    final matched = applyMatching(
      resources: resources,
      barriers: barriers,
      userLocation: userLocation,
      userRegion: userRegion,
      userLanguages: userLanguages,
    );

    final Map<String, List<HealthResource>> grouped = {};
    for (final resource in matched) {
      final category = resource.category;
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(resource);
    }

    // Sort each group by match score
    for (final category in grouped.keys) {
      grouped[category]!.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    }

    return grouped;
  }
}
