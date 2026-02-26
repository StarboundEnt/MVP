/// Health resource model for local healthcare facilities and services
/// Part of the health navigation transformation
/// Adapted for Australian (NSW) healthcare system

import 'package:flutter/material.dart';

enum ResourceType {
  clinic,             // GP clinic / Community health center
  hospital,           // Hospital
  urgentCare,         // Urgent care / After hours clinic
  pharmacy,           // Pharmacy / Chemist
  mentalHealth,       // Mental health provider
  substanceUse,       // Substance use treatment
  dental,             // Dental care
  vision,             // Vision/eye care
  foodBank,           // Food assistance
  housing,            // Housing support
  transportation,     // Transportation services
  hotline,            // Crisis/support hotline
  telehealth,         // Telemedicine service
  community,          // Community services (legal, financial, etc.)
  womensHealth,       // Women's health services
  youth,              // Youth-specific services
  other,              // Other resource type
}

/// Features that a resource can have (for barrier matching)
enum ResourceFeature {
  bulkBilling,         // Medicare bulk billing (no out-of-pocket)
  noGapFees,           // No gap after Medicare rebate
  freeService,         // Completely free service
  weekendHours,        // Open on weekends
  eveningHours,        // Open after 6pm
  earlyMorning,        // Open before 8am
  open24Hours,         // Open 24/7
  telehealth,          // Telehealth/video consultations
  walkIn,              // Walk-in welcome (no appointment)
  noReferralNeeded,    // No GP referral required
  noIdRequired,        // No ID/documentation required
  interpreterAvailable,// Interpreter services
  wheelchairAccess,    // Wheelchair accessible
  publicTransport,     // Near public transport
  parking,             // Has parking
  confidential,        // Confidential service
  youthFriendly,       // Designed for young people
  culturallySafe,      // Culturally safe/appropriate
  lgbtqFriendly,       // LGBTQ+ inclusive
}

extension ResourceFeatureExtension on ResourceFeature {
  String get displayName {
    switch (this) {
      case ResourceFeature.bulkBilling:
        return 'Bulk billing';
      case ResourceFeature.noGapFees:
        return 'No gap fees';
      case ResourceFeature.freeService:
        return 'Free service';
      case ResourceFeature.weekendHours:
        return 'Weekend hours';
      case ResourceFeature.eveningHours:
        return 'Evening hours';
      case ResourceFeature.earlyMorning:
        return 'Early morning';
      case ResourceFeature.open24Hours:
        return 'Open 24/7';
      case ResourceFeature.telehealth:
        return 'Telehealth';
      case ResourceFeature.walkIn:
        return 'Walk-in welcome';
      case ResourceFeature.noReferralNeeded:
        return 'No referral needed';
      case ResourceFeature.noIdRequired:
        return 'No ID required';
      case ResourceFeature.interpreterAvailable:
        return 'Interpreter available';
      case ResourceFeature.wheelchairAccess:
        return 'Wheelchair access';
      case ResourceFeature.publicTransport:
        return 'Near public transport';
      case ResourceFeature.parking:
        return 'Parking available';
      case ResourceFeature.confidential:
        return 'Confidential';
      case ResourceFeature.youthFriendly:
        return 'Youth friendly';
      case ResourceFeature.culturallySafe:
        return 'Culturally safe';
      case ResourceFeature.lgbtqFriendly:
        return 'LGBTQ+ friendly';
    }
  }

  IconData get icon {
    switch (this) {
      case ResourceFeature.bulkBilling:
      case ResourceFeature.noGapFees:
      case ResourceFeature.freeService:
        return Icons.attach_money;
      case ResourceFeature.weekendHours:
      case ResourceFeature.eveningHours:
      case ResourceFeature.earlyMorning:
      case ResourceFeature.open24Hours:
        return Icons.schedule;
      case ResourceFeature.telehealth:
        return Icons.video_call;
      case ResourceFeature.walkIn:
        return Icons.directions_walk;
      case ResourceFeature.noReferralNeeded:
        return Icons.check_circle_outline;
      case ResourceFeature.noIdRequired:
        return Icons.badge_outlined;
      case ResourceFeature.interpreterAvailable:
        return Icons.translate;
      case ResourceFeature.wheelchairAccess:
        return Icons.accessible;
      case ResourceFeature.publicTransport:
        return Icons.directions_bus;
      case ResourceFeature.parking:
        return Icons.local_parking;
      case ResourceFeature.confidential:
        return Icons.lock_outline;
      case ResourceFeature.youthFriendly:
        return Icons.child_care;
      case ResourceFeature.culturallySafe:
        return Icons.diversity_3;
      case ResourceFeature.lgbtqFriendly:
        return Icons.favorite;
    }
  }
}

/// Cost information adapted for Australian healthcare system
class CostInfo {
  final bool hasBulkBilling;       // Medicare bulk billing (no out-of-pocket)
  final bool hasNoGapFees;         // No gap after Medicare rebate
  final bool isFreeService;        // Completely free (community services)
  final bool acceptsMedicare;      // Accepts Medicare card
  final bool hasPBS;               // PBS medications available (pharmacies)
  final bool hasSlidingScale;      // Income-based fees
  final bool hasConcessionRates;   // Concession card holder rates
  final bool hasHealthCareCard;    // Accepts Health Care Card
  final String? costDescription;

  const CostInfo({
    this.hasBulkBilling = false,
    this.hasNoGapFees = false,
    this.isFreeService = false,
    this.acceptsMedicare = true,
    this.hasPBS = false,
    this.hasSlidingScale = false,
    this.hasConcessionRates = false,
    this.hasHealthCareCard = false,
    this.costDescription,
  });

  factory CostInfo.fromJson(Map<String, dynamic> json) {
    return CostInfo(
      hasBulkBilling: json['hasBulkBilling'] as bool? ?? false,
      hasNoGapFees: json['hasNoGapFees'] as bool? ?? false,
      isFreeService: json['isFreeService'] as bool? ?? false,
      acceptsMedicare: json['acceptsMedicare'] as bool? ?? true,
      hasPBS: json['hasPBS'] as bool? ?? false,
      hasSlidingScale: json['hasSlidingScale'] as bool? ?? false,
      hasConcessionRates: json['hasConcessionRates'] as bool? ?? false,
      hasHealthCareCard: json['hasHealthCareCard'] as bool? ?? false,
      costDescription: json['costDescription'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasBulkBilling': hasBulkBilling,
      'hasNoGapFees': hasNoGapFees,
      'isFreeService': isFreeService,
      'acceptsMedicare': acceptsMedicare,
      'hasPBS': hasPBS,
      'hasSlidingScale': hasSlidingScale,
      'hasConcessionRates': hasConcessionRates,
      'hasHealthCareCard': hasHealthCareCard,
      'costDescription': costDescription,
    };
  }

  CostInfo copyWith({
    bool? hasBulkBilling,
    bool? hasNoGapFees,
    bool? isFreeService,
    bool? acceptsMedicare,
    bool? hasPBS,
    bool? hasSlidingScale,
    bool? hasConcessionRates,
    bool? hasHealthCareCard,
    String? costDescription,
  }) {
    return CostInfo(
      hasBulkBilling: hasBulkBilling ?? this.hasBulkBilling,
      hasNoGapFees: hasNoGapFees ?? this.hasNoGapFees,
      isFreeService: isFreeService ?? this.isFreeService,
      acceptsMedicare: acceptsMedicare ?? this.acceptsMedicare,
      hasPBS: hasPBS ?? this.hasPBS,
      hasSlidingScale: hasSlidingScale ?? this.hasSlidingScale,
      hasConcessionRates: hasConcessionRates ?? this.hasConcessionRates,
      hasHealthCareCard: hasHealthCareCard ?? this.hasHealthCareCard,
      costDescription: costDescription ?? this.costDescription,
    );
  }

  /// Get user-friendly cost description for display
  String getDisplayText() {
    if (isFreeService) return 'Free service';
    if (hasBulkBilling) return 'Bulk billing available';
    if (hasNoGapFees) return 'No gap fees';
    if (hasConcessionRates) return 'Concession rates available';
    if (hasSlidingScale) return 'Sliding scale fees';
    if (costDescription != null) return costDescription!;
    return 'Contact for pricing';
  }

  /// Check if resource is accessible for low-income individuals
  bool get isAffordable =>
      isFreeService ||
      hasBulkBilling ||
      hasNoGapFees ||
      hasConcessionRates ||
      hasSlidingScale;

  /// Get list of cost-related features for display
  List<String> getCostFeatures() {
    final features = <String>[];
    if (isFreeService) features.add('Free service');
    if (hasBulkBilling) features.add('Bulk billing');
    if (hasNoGapFees) features.add('No gap fees');
    if (hasPBS) features.add('PBS medications');
    if (hasConcessionRates) features.add('Concession rates');
    if (hasHealthCareCard) features.add('Health Care Card accepted');
    return features;
  }
}

class AccessibilityInfo {
  final bool wheelchairAccessible;
  final bool hasParking;
  final bool publicTransitNearby;
  final bool hasTelehealth;
  final List<String> languagesSpoken;
  final bool hasInterpreter;
  final String? accessibilityNotes;

  const AccessibilityInfo({
    this.wheelchairAccessible = false,
    this.hasParking = false,
    this.publicTransitNearby = false,
    this.hasTelehealth = false,
    this.languagesSpoken = const ['English'],
    this.hasInterpreter = false,
    this.accessibilityNotes,
  });

  factory AccessibilityInfo.fromJson(Map<String, dynamic> json) {
    return AccessibilityInfo(
      wheelchairAccessible: json['wheelchairAccessible'] as bool? ?? false,
      hasParking: json['hasParking'] as bool? ?? false,
      publicTransitNearby: json['publicTransitNearby'] as bool? ?? false,
      hasTelehealth: json['hasTelehealth'] as bool? ?? false,
      languagesSpoken: (json['languagesSpoken'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? const ['English'],
      hasInterpreter: json['hasInterpreter'] as bool? ?? false,
      accessibilityNotes: json['accessibilityNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wheelchairAccessible': wheelchairAccessible,
      'hasParking': hasParking,
      'publicTransitNearby': publicTransitNearby,
      'hasTelehealth': hasTelehealth,
      'languagesSpoken': languagesSpoken,
      'hasInterpreter': hasInterpreter,
      'accessibilityNotes': accessibilityNotes,
    };
  }

  // Get list of accessibility features
  List<String> getFeatures() {
    final features = <String>[];
    if (wheelchairAccessible) features.add('Wheelchair accessible');
    if (hasParking) features.add('Parking available');
    if (publicTransitNearby) features.add('Near public transit');
    if (hasTelehealth) features.add('Telehealth available');
    if (hasInterpreter) features.add('Interpreter services');
    if (languagesSpoken.length > 1) {
      features.add('${languagesSpoken.length} languages spoken');
    }
    return features;
  }
}

class HoursOfOperation {
  final Map<String, String> schedule; // e.g., {'monday': '9am-5pm', 'tuesday': '9am-5pm'}
  final bool isOpen24Hours;
  final String? specialHours;

  const HoursOfOperation({
    this.schedule = const {},
    this.isOpen24Hours = false,
    this.specialHours,
  });

  factory HoursOfOperation.fromJson(Map<String, dynamic> json) {
    return HoursOfOperation(
      schedule: Map<String, String>.from(json['schedule'] as Map? ?? {}),
      isOpen24Hours: json['isOpen24Hours'] as bool? ?? false,
      specialHours: json['specialHours'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule': schedule,
      'isOpen24Hours': isOpen24Hours,
      'specialHours': specialHours,
    };
  }

  // Check if currently open (simplified - would need full implementation)
  bool isCurrentlyOpen() {
    if (isOpen24Hours) return true;
    // TODO: Implement actual time checking logic
    return true;
  }

  String getDisplayText() {
    if (isOpen24Hours) return 'Open 24/7';
    if (schedule.isEmpty) return 'Call for hours';

    // Show today's hours if available
    final today = DateTime.now().weekday;
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final todayName = dayNames[today - 1];

    if (schedule.containsKey(todayName)) {
      return 'Today: ${schedule[todayName]}';
    }

    return 'See full schedule';
  }
}

class HealthResource {
  final String id;
  final String name;
  final ResourceType type;
  final String? description;
  final String address;
  final String? phone;
  final String? website;
  final String? email;

  // NSW-specific location fields
  final String? neighborhood;  // e.g., "Auburn", "Canterbury", "Bankstown"
  final String? region;        // e.g., "Canterbury-Bankstown", "Inner West"

  final List<String> servicesOffered;
  final List<ResourceFeature> features; // For barrier matching
  final CostInfo costInfo;
  final AccessibilityInfo accessibility;
  final HoursOfOperation hours;
  final double? latitude;
  final double? longitude;
  final double? distance; // Distance from user in km
  final double matchScore; // How well it matches user's needs (0.0-1.0)
  final List<String> matchReasons; // Why this resource matches the user
  final String? specialNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HealthResource({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    required this.address,
    this.phone,
    this.website,
    this.email,
    this.neighborhood,
    this.region,
    this.servicesOffered = const [],
    this.features = const [],
    this.costInfo = const CostInfo(),
    this.accessibility = const AccessibilityInfo(),
    this.hours = const HoursOfOperation(),
    this.latitude,
    this.longitude,
    this.distance,
    this.matchScore = 0.0,
    this.matchReasons = const [],
    this.specialNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory HealthResource.fromJson(Map<String, dynamic> json) {
    return HealthResource(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ResourceType.values.firstWhere(
        (e) => e.toString() == 'ResourceType.${json['type']}',
        orElse: () => ResourceType.other,
      ),
      description: json['description'] as String?,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      neighborhood: json['neighborhood'] as String?,
      region: json['region'] as String?,
      servicesOffered: (json['servicesOffered'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? const [],
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => ResourceFeature.values.firstWhere(
                (f) => f.name == e.toString(),
                orElse: () => ResourceFeature.freeService,
              ))
          .toList() ?? const [],
      costInfo: json['costInfo'] != null
          ? CostInfo.fromJson(json['costInfo'] as Map<String, dynamic>)
          : const CostInfo(),
      accessibility: json['accessibility'] != null
          ? AccessibilityInfo.fromJson(json['accessibility'] as Map<String, dynamic>)
          : const AccessibilityInfo(),
      hours: json['hours'] != null
          ? HoursOfOperation.fromJson(json['hours'] as Map<String, dynamic>)
          : const HoursOfOperation(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      matchReasons: (json['matchReasons'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? const [],
      specialNotes: json['specialNotes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'description': description,
      'address': address,
      'phone': phone,
      'website': website,
      'email': email,
      'neighborhood': neighborhood,
      'region': region,
      'servicesOffered': servicesOffered,
      'features': features.map((f) => f.name).toList(),
      'costInfo': costInfo.toJson(),
      'accessibility': accessibility.toJson(),
      'hours': hours.toJson(),
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'matchScore': matchScore,
      'matchReasons': matchReasons,
      'specialNotes': specialNotes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  HealthResource copyWith({
    String? id,
    String? name,
    ResourceType? type,
    String? description,
    String? address,
    String? phone,
    String? website,
    String? email,
    String? neighborhood,
    String? region,
    List<String>? servicesOffered,
    List<ResourceFeature>? features,
    CostInfo? costInfo,
    AccessibilityInfo? accessibility,
    HoursOfOperation? hours,
    double? latitude,
    double? longitude,
    double? distance,
    double? matchScore,
    List<String>? matchReasons,
    String? specialNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthResource(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      email: email ?? this.email,
      neighborhood: neighborhood ?? this.neighborhood,
      region: region ?? this.region,
      servicesOffered: servicesOffered ?? this.servicesOffered,
      features: features ?? this.features,
      costInfo: costInfo ?? this.costInfo,
      accessibility: accessibility ?? this.accessibility,
      hours: hours ?? this.hours,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      matchScore: matchScore ?? this.matchScore,
      matchReasons: matchReasons ?? this.matchReasons,
      specialNotes: specialNotes ?? this.specialNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get display name for resource type
  String get typeDisplayName {
    switch (type) {
      case ResourceType.clinic:
        return 'GP Clinic';
      case ResourceType.hospital:
        return 'Hospital';
      case ResourceType.urgentCare:
        return 'Urgent Care';
      case ResourceType.pharmacy:
        return 'Pharmacy';
      case ResourceType.mentalHealth:
        return 'Mental Health';
      case ResourceType.substanceUse:
        return 'Drug & Alcohol';
      case ResourceType.dental:
        return 'Dental Care';
      case ResourceType.vision:
        return 'Vision Care';
      case ResourceType.foodBank:
        return 'Food Assistance';
      case ResourceType.housing:
        return 'Housing Support';
      case ResourceType.transportation:
        return 'Transport';
      case ResourceType.hotline:
        return 'Crisis Line';
      case ResourceType.telehealth:
        return 'Telehealth';
      case ResourceType.community:
        return 'Community Service';
      case ResourceType.womensHealth:
        return "Women's Health";
      case ResourceType.youth:
        return 'Youth Services';
      case ResourceType.other:
        return 'Other Services';
    }
  }

  // Get icon for resource type
  IconData get typeIcon {
    switch (type) {
      case ResourceType.clinic:
        return Icons.local_hospital;
      case ResourceType.hospital:
        return Icons.emergency;
      case ResourceType.urgentCare:
        return Icons.medical_services;
      case ResourceType.pharmacy:
        return Icons.medication;
      case ResourceType.mentalHealth:
        return Icons.psychology;
      case ResourceType.substanceUse:
        return Icons.healing;
      case ResourceType.dental:
        return Icons.sentiment_satisfied; // Substitute for dental icon
      case ResourceType.vision:
        return Icons.visibility;
      case ResourceType.foodBank:
        return Icons.restaurant;
      case ResourceType.housing:
        return Icons.home;
      case ResourceType.transportation:
        return Icons.directions_bus;
      case ResourceType.hotline:
        return Icons.phone_in_talk;
      case ResourceType.telehealth:
        return Icons.video_call;
      case ResourceType.community:
        return Icons.people;
      case ResourceType.womensHealth:
        return Icons.female;
      case ResourceType.youth:
        return Icons.child_care;
      case ResourceType.other:
        return Icons.location_on;
    }
  }

  // Get emoji for resource type (for cards)
  String get typeEmoji {
    switch (type) {
      case ResourceType.clinic:
        return '🏥';
      case ResourceType.hospital:
        return '🏨';
      case ResourceType.urgentCare:
        return '🚑';
      case ResourceType.pharmacy:
        return '💊';
      case ResourceType.mentalHealth:
        return '🧠';
      case ResourceType.substanceUse:
        return '💚';
      case ResourceType.dental:
        return '🦷';
      case ResourceType.vision:
        return '👁️';
      case ResourceType.foodBank:
        return '🍎';
      case ResourceType.housing:
        return '🏠';
      case ResourceType.transportation:
        return '🚌';
      case ResourceType.hotline:
        return '📞';
      case ResourceType.telehealth:
        return '💻';
      case ResourceType.community:
        return '🤝';
      case ResourceType.womensHealth:
        return '👩';
      case ResourceType.youth:
        return '🧒';
      case ResourceType.other:
        return '📍';
    }
  }

  // Get formatted distance text (in km for Australia)
  String get distanceText {
    if (distance == null) return '';
    if (distance! < 1.0) {
      return '${(distance! * 1000).round()}m away';
    }
    return '${distance!.toStringAsFixed(1)}km away';
  }

  // Get location text for display
  String get locationText {
    if (neighborhood != null && region != null) {
      return '$neighborhood, $region';
    }
    if (neighborhood != null) return neighborhood!;
    if (region != null) return region!;
    return address;
  }

  // Check if resource has a specific feature
  bool hasFeature(ResourceFeature feature) => features.contains(feature);

  // Check if resource has coordinates
  bool get hasCoordinates => latitude != null && longitude != null;

  // Check if resource is a crisis/emergency resource
  bool get isCrisisResource =>
      type == ResourceType.hotline ||
      hours.isOpen24Hours ||
      features.contains(ResourceFeature.open24Hours);

  // Get category for grouping
  String get category {
    switch (type) {
      case ResourceType.clinic:
      case ResourceType.hospital:
      case ResourceType.urgentCare:
        return 'Medical Care';
      case ResourceType.mentalHealth:
      case ResourceType.substanceUse:
        return 'Mental Health';
      case ResourceType.pharmacy:
        return 'Pharmacies';
      case ResourceType.foodBank:
        return 'Food & Basic Needs';
      case ResourceType.hotline:
        return 'Emergency & Crisis';
      case ResourceType.womensHealth:
        return "Women's Health";
      case ResourceType.youth:
        return 'Youth Services';
      case ResourceType.dental:
      case ResourceType.vision:
        return 'Specialist Care';
      case ResourceType.housing:
      case ResourceType.transportation:
      case ResourceType.community:
      case ResourceType.telehealth:
      case ResourceType.other:
        return 'Community Services';
    }
  }

  @override
  String toString() {
    return 'HealthResource(id: $id, name: $name, type: ${type.name}, matchScore: $matchScore)';
  }
}

/// Australian emergency resources that are always available
class EmergencyResources {
  static final List<HealthResource> all = [
    const HealthResource(
      id: 'emergency_000',
      name: 'Triple Zero (000)',
      type: ResourceType.hotline,
      description: 'Emergency services for life-threatening situations',
      address: 'Australia-wide',
      phone: '000',
      region: 'Australia',
      servicesOffered: [
        'Police',
        'Ambulance',
        'Fire',
      ],
      features: [ResourceFeature.open24Hours, ResourceFeature.freeService],
      hours: HoursOfOperation(isOpen24Hours: true),
      costInfo: CostInfo(isFreeService: true),
      accessibility: AccessibilityInfo(
        languagesSpoken: ['English'],
        hasInterpreter: true,
      ),
      matchScore: 1.0,
      specialNotes: 'For life-threatening emergencies only. For non-emergencies, call Police Assistance Line 131 444',
    ),
    const HealthResource(
      id: 'lifeline',
      name: 'Lifeline',
      type: ResourceType.hotline,
      description: '24/7 crisis support and suicide prevention',
      address: 'Australia-wide',
      phone: '13 11 14',
      website: 'https://lifeline.org.au',
      region: 'Australia',
      servicesOffered: [
        'Crisis support',
        'Suicide prevention',
        'Emotional support',
        'Text and online chat',
      ],
      features: [ResourceFeature.open24Hours, ResourceFeature.freeService, ResourceFeature.confidential],
      hours: HoursOfOperation(isOpen24Hours: true),
      costInfo: CostInfo(isFreeService: true),
      accessibility: AccessibilityInfo(
        languagesSpoken: ['English'],
        hasInterpreter: true,
      ),
      matchScore: 1.0,
      specialNotes: 'Free and confidential. Text 0477 13 11 14 or chat online.',
    ),
    const HealthResource(
      id: 'beyond_blue',
      name: 'Beyond Blue',
      type: ResourceType.hotline,
      description: 'Mental health support for anxiety and depression',
      address: 'Australia-wide',
      phone: '1300 22 4636',
      website: 'https://beyondblue.org.au',
      region: 'Australia',
      servicesOffered: [
        'Anxiety support',
        'Depression support',
        'Mental health information',
        'Online chat',
      ],
      features: [ResourceFeature.open24Hours, ResourceFeature.freeService, ResourceFeature.confidential],
      hours: HoursOfOperation(isOpen24Hours: true),
      costInfo: CostInfo(isFreeService: true),
      accessibility: AccessibilityInfo(
        languagesSpoken: ['English'],
        hasInterpreter: true,
      ),
      matchScore: 1.0,
      specialNotes: '24/7 support available',
    ),
    const HealthResource(
      id: '1800respect',
      name: '1800RESPECT',
      type: ResourceType.hotline,
      description: 'National sexual assault, domestic and family violence counselling',
      address: 'Australia-wide',
      phone: '1800 737 732',
      website: 'https://1800respect.org.au',
      region: 'Australia',
      servicesOffered: [
        'Domestic violence support',
        'Sexual assault counselling',
        'Safety planning',
        'Referrals',
      ],
      features: [ResourceFeature.open24Hours, ResourceFeature.freeService, ResourceFeature.confidential],
      hours: HoursOfOperation(isOpen24Hours: true),
      costInfo: CostInfo(isFreeService: true),
      accessibility: AccessibilityInfo(
        languagesSpoken: ['English'],
        hasInterpreter: true,
      ),
      matchScore: 1.0,
      specialNotes: 'Confidential support 24/7',
    ),
    const HealthResource(
      id: 'kids_helpline',
      name: 'Kids Helpline',
      type: ResourceType.hotline,
      description: 'Free counselling service for young people aged 5-25',
      address: 'Australia-wide',
      phone: '1800 55 1800',
      website: 'https://kidshelpline.com.au',
      region: 'Australia',
      servicesOffered: [
        'Counselling for young people',
        'Mental health support',
        'Family issues',
        'Bullying support',
      ],
      features: [ResourceFeature.open24Hours, ResourceFeature.freeService, ResourceFeature.confidential, ResourceFeature.youthFriendly],
      hours: HoursOfOperation(isOpen24Hours: true),
      costInfo: CostInfo(isFreeService: true),
      accessibility: AccessibilityInfo(
        languagesSpoken: ['English'],
      ),
      matchScore: 1.0,
      specialNotes: 'For ages 5-25. Free, private and confidential.',
    ),
    const HealthResource(
      id: 'poisons_info',
      name: 'Poisons Information Centre',
      type: ResourceType.hotline,
      description: 'Expert advice on poisoning and medication questions',
      address: 'Australia-wide',
      phone: '13 11 26',
      website: 'https://poisonsinfo.nsw.gov.au',
      region: 'Australia',
      servicesOffered: [
        'Poisoning advice',
        'Medication overdose',
        'Chemical exposure',
        'Bites and stings',
      ],
      features: [ResourceFeature.open24Hours, ResourceFeature.freeService],
      hours: HoursOfOperation(isOpen24Hours: true),
      costInfo: CostInfo(isFreeService: true),
      matchScore: 1.0,
      specialNotes: '24/7 expert advice for all poisoning emergencies',
    ),
  ];

  static HealthResource? getForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'emergency':
        return all[0]; // 000
      case 'mental_health':
      case 'crisis':
      case 'suicide':
        return all[1]; // Lifeline
      case 'anxiety':
      case 'depression':
        return all[2]; // Beyond Blue
      case 'domestic_violence':
      case 'abuse':
      case 'sexual_assault':
        return all[3]; // 1800RESPECT
      case 'youth':
      case 'kids':
      case 'children':
        return all[4]; // Kids Helpline
      case 'poisoning':
      case 'overdose':
        return all[5]; // Poisons Info
      default:
        return null;
    }
  }
}
