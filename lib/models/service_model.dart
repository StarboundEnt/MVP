import 'package:flutter/material.dart';

// 🌍 Location data for services
class ServiceLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  
  const ServiceLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
  });
  
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'landmark': landmark,
  };
  
  factory ServiceLocation.fromJson(Map<String, dynamic> json) => ServiceLocation(
    latitude: json['latitude']?.toDouble() ?? 0.0,
    longitude: json['longitude']?.toDouble() ?? 0.0,
    address: json['address'] ?? '',
    landmark: json['landmark'],
  );
}

// ⏰ Service availability and scheduling
class ServiceSchedule {
  final String day; // "Monday", "Tuesday", etc.
  final String startTime; // "09:00"
  final String endTime; // "17:00"
  final bool isEmergency; // 24/7 service
  final String? notes; // "By appointment only"
  
  const ServiceSchedule({
    required this.day,
    required this.startTime,
    required this.endTime,
    this.isEmergency = false,
    this.notes,
  });
  
  Map<String, dynamic> toJson() => {
    'day': day,
    'startTime': startTime,
    'endTime': endTime,
    'isEmergency': isEmergency,
    'notes': notes,
  };
  
  factory ServiceSchedule.fromJson(Map<String, dynamic> json) => ServiceSchedule(
    day: json['day'] ?? '',
    startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '',
    isEmergency: json['isEmergency'] ?? false,
    notes: json['notes'],
  );
}

// 🎯 Specific service offerings
class ServiceOffering {
  final String name; // "Free meals", "Counseling", "Housing assistance"
  final String category; // "nutrition", "mental_health", "housing"
  final String? cost; // "Free", "$20", "Sliding scale"
  final String? requirements; // "Students only", "No ID required"
  final bool isAvailable; // Current availability
  
  const ServiceOffering({
    required this.name,
    required this.category,
    this.cost,
    this.requirements,
    this.isAvailable = true,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'cost': cost,
    'requirements': requirements,
    'isAvailable': isAvailable,
  };
  
  factory ServiceOffering.fromJson(Map<String, dynamic> json) => ServiceOffering(
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    cost: json['cost'],
    requirements: json['requirements'],
    isAvailable: json['isAvailable'] ?? true,
  );
}

// 🔹 Enhanced Support Service
class SupportService {
  final String name;
  final String icon;
  final String reason;
  final String description;
  final String contact;
  final List<String> tags;
  
  // Enhanced fields
  final String organizationId;
  final ServiceLocation? location;
  final List<ServiceSchedule> schedules;
  final List<ServiceOffering> offerings;
  final bool isPersonalConnection; // Added via QR vs. system default
  final DateTime? lastUpdated;
  final Map<String, dynamic> metadata;

  const SupportService({
    required this.name,
    required this.icon,
    required this.reason,
    required this.description,
    required this.contact,
    required this.tags,
    required this.organizationId,
    this.location,
    this.schedules = const [],
    this.offerings = const [],
    this.isPersonalConnection = false,
    this.lastUpdated,
    this.metadata = const {},
  });

  // Create from QR code data
  factory SupportService.fromQRCode(Map<String, dynamic> qrData) {
    return SupportService(
      name: qrData['name'] ?? '',
      icon: qrData['icon'] ?? '🏢',
      reason: qrData['reason'] ?? 'Community support',
      description: qrData['description'] ?? '',
      contact: qrData['contact'] ?? '',
      tags: List<String>.from(qrData['tags'] ?? []),
      organizationId: qrData['organizationId'] ?? qrData['name'] ?? '',
      location: qrData['location'] != null 
          ? ServiceLocation.fromJson(qrData['location']) 
          : null,
      schedules: (qrData['schedules'] as List<dynamic>?)
          ?.map((s) => ServiceSchedule.fromJson(s))
          .toList() ?? [],
      offerings: (qrData['offerings'] as List<dynamic>?)
          ?.map((o) => ServiceOffering.fromJson(o))
          .toList() ?? [],
      isPersonalConnection: true,
      lastUpdated: DateTime.now(),
      metadata: Map<String, dynamic>.from(qrData['metadata'] ?? {}),
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'reason': reason,
    'description': description,
    'contact': contact,
    'tags': tags,
    'organizationId': organizationId,
    'location': location?.toJson(),
    'schedules': schedules.map((s) => s.toJson()).toList(),
    'offerings': offerings.map((o) => o.toJson()).toList(),
    'isPersonalConnection': isPersonalConnection,
    'lastUpdated': lastUpdated?.toIso8601String(),
    'metadata': metadata,
  };

  // Create from stored JSON
  factory SupportService.fromJson(Map<String, dynamic> json) {
    return SupportService(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '🏢',
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      contact: json['contact'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      organizationId: json['organizationId'] ?? '',
      location: json['location'] != null 
          ? ServiceLocation.fromJson(json['location']) 
          : null,
      schedules: (json['schedules'] as List<dynamic>?)
          ?.map((s) => ServiceSchedule.fromJson(s))
          .toList() ?? [],
      offerings: (json['offerings'] as List<dynamic>?)
          ?.map((o) => ServiceOffering.fromJson(o))
          .toList() ?? [],
      isPersonalConnection: json['isPersonalConnection'] ?? false,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // Helper methods
  bool get isAvailableNow {
    if (schedules.isEmpty) return true; // Assume always available if no schedule
    
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    for (final schedule in schedules) {
      if (schedule.isEmergency) return true; // 24/7 service
      if (schedule.day == dayName && 
          _isTimeInRange(currentTime, schedule.startTime, schedule.endTime)) {
        return true;
      }
    }
    return false;
  }

  String get availabilityStatus {
    if (schedules.isEmpty) return 'Available';
    
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    
    for (final schedule in schedules) {
      if (schedule.isEmergency) return '24/7 Available';
      if (schedule.day == dayName) {
        if (isAvailableNow) {
          return 'Open until ${schedule.endTime}';
        } else {
          return 'Opens at ${schedule.startTime}';
        }
      }
    }
    return 'Check schedule';
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  bool _isTimeInRange(String currentTime, String startTime, String endTime) {
    try {
      final current = TimeOfDay(
        hour: int.parse(currentTime.split(':')[0]),
        minute: int.parse(currentTime.split(':')[1]),
      );
      final start = TimeOfDay(
        hour: int.parse(startTime.split(':')[0]),
        minute: int.parse(startTime.split(':')[1]),
      );
      final end = TimeOfDay(
        hour: int.parse(endTime.split(':')[0]),
        minute: int.parse(endTime.split(':')[1]),
      );
      
      final currentMinutes = current.hour * 60 + current.minute;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } catch (e) {
      return false;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportService &&
          runtimeType == other.runtimeType &&
          organizationId == other.organizationId;

  @override
  int get hashCode => organizationId.hashCode;

  @override
  String toString() => '$runtimeType(name: "$name", organizationId: "$organizationId")';
}

// 🧭 All Sample Services
class StarboundServices {
  static final List<SupportService> all = [
    SupportService(
      name: "Student Carer Support Program",
      icon: "🧠",
      reason: "Recommended for carers",
      description: "Free check-ins with a youth mental health worker, no referral needed.",
      contact: "Call 1800 123 456",
      tags: ["carer", "student", "counselling"],
      organizationId: "student_carer_support",
      schedules: [
        ServiceSchedule(day: "Monday", startTime: "09:00", endTime: "17:00"),
        ServiceSchedule(day: "Tuesday", startTime: "09:00", endTime: "17:00"),
        ServiceSchedule(day: "Wednesday", startTime: "09:00", endTime: "17:00"),
        ServiceSchedule(day: "Thursday", startTime: "09:00", endTime: "17:00"),
        ServiceSchedule(day: "Friday", startTime: "09:00", endTime: "17:00"),
      ],
      offerings: [
        ServiceOffering(name: "Mental health check-ins", category: "mental_health", cost: "Free"),
        ServiceOffering(name: "Carer support groups", category: "support", cost: "Free"),
      ],
    ),
    SupportService(
      name: "Mindful Eating Workshops",
      icon: "🍎",
      reason: "Great for study stress",
      description: "Learn simple strategies for eating well even when life gets busy.",
      contact: "Email info@wellness.org",
      tags: ["nutrition", "study", "stress"],
      organizationId: "wellness_nutrition",
      schedules: [
        ServiceSchedule(day: "Thursday", startTime: "18:00", endTime: "19:30", notes: "Weekly workshop"),
        ServiceSchedule(day: "Saturday", startTime: "10:00", endTime: "11:30", notes: "Weekend session"),
      ],
      offerings: [
        ServiceOffering(name: "Nutrition workshops", category: "nutrition", cost: "Free"),
        ServiceOffering(name: "Meal planning guidance", category: "nutrition", cost: "Free"),
      ],
      location: ServiceLocation(
        latitude: -31.9505, 
        longitude: 115.8605, 
        address: "123 Wellness St, Perth WA 6000",
        landmark: "Next to the library"
      ),
    ),
    SupportService(
      name: "Nightline Youth Chat",
      icon: "💬",
      reason: "24/7 anonymous peer chat",
      description: "Anonymous chat service run by trained peers. Available anytime.",
      contact: "Visit nightline.org/chat",
      tags: ["crisis", "chat", "peer support"],
      organizationId: "nightline_youth_chat",
      schedules: [ServiceSchedule(day: "Monday", startTime: "00:00", endTime: "23:59", isEmergency: true)],
    ),
    SupportService(
      name: "Campus Housing Aid",
      icon: "🏠",
      reason: "For students facing housing instability",
      description: "Emergency accommodation and advice for students.",
      contact: "Text 0412 345 678",
      tags: ["housing", "student", "emergency"],
      organizationId: "campus_housing_aid",
    ),
    SupportService(
      name: "Budgeting Buddy",
      icon: "💰",
      reason: "Help with managing money",
      description: "One-on-one budgeting sessions to help you plan and prioritise.",
      contact: "Book online at budgetbuddy.gov.au",
      tags: ["money", "budgeting", "support"],
      organizationId: "budgeting_buddy",
    ),
    SupportService(
      name: "Crisis Care Line",
      icon: "🆘",
      reason: "Immediate crisis support",
      description: "24/7 crisis intervention and emotional support. Professional counsellors available.",
      contact: "Call 1800 246 247",
      tags: ["crisis", "counselling", "emergency"],
      organizationId: "crisis_care_line",
      schedules: [ServiceSchedule(day: "Monday", startTime: "00:00", endTime: "23:59", isEmergency: true)],
    ),
    SupportService(
      name: "Student Financial Aid",
      icon: "🎓",
      reason: "Financial assistance for students",
      description: "Emergency financial support and advice for students in need.",
      contact: "Visit studentaid.gov.au",
      tags: ["money", "student", "emergency"],
      organizationId: "student_financial_aid",
    ),
    SupportService(
      name: "Anxiety Support Groups",
      icon: "🫂",
      reason: "Peer support for anxiety",
      description: "Weekly group sessions with others experiencing similar challenges.",
      contact: "Email groups@anxietysupport.org",
      tags: ["stress", "counselling", "support"],
      organizationId: "anxiety_support_groups",
    ),
    SupportService(
      name: "Nutrition Counselling",
      icon: "🥗",
      reason: "Professional nutrition guidance",
      description: "Individual sessions with registered dietitians to develop healthy eating habits.",
      contact: "Call 1300 668 775",
      tags: ["nutrition", "counselling", "health"],
      organizationId: "nutrition_counselling",
    ),
    SupportService(
      name: "Career Counselling Service",
      icon: "💼",
      reason: "Career guidance and support",
      description: "Help with career planning, job searching, and interview preparation.",
      contact: "Book online at careers.edu.au",
      tags: ["student", "career", "support"],
      organizationId: "career_counselling",
    ),
    SupportService(
      name: "Mental Health First Aid",
      icon: "🧘",
      reason: "Mental health education",
      description: "Training programs to recognize and respond to mental health challenges.",
      contact: "Visit mhfa.com.au",
      tags: ["counselling", "education", "support"],
      organizationId: "mental_health_first_aid",
    ),
    SupportService(
      name: "Housing Support Network",
      icon: "🏘️",
      reason: "Housing assistance",
      description: "Help finding affordable housing and understanding rental rights.",
      contact: "Call 1300 135 513",
      tags: ["housing", "support", "emergency"],
      organizationId: "housing_support_network",
    ),
    SupportService(
      name: "Study Skills Workshop",
      icon: "📚",
      reason: "Academic support",
      description: "Learn effective study techniques and time management skills.",
      contact: "Email study@university.edu",
      tags: ["student", "education", "stress"],
      organizationId: "study_skills_workshop",
    ),
    SupportService(
      name: "Peer Support Network",
      icon: "👥",
      reason: "Connect with peers",
      description: "Facilitated peer support groups for young people facing similar challenges.",
      contact: "Text 0400 123 456",
      tags: ["support", "peer", "counselling"],
      organizationId: "peer_support_network",
    ),
    SupportService(
      name: "Emergency Food Relief",
      icon: "🍞",
      reason: "Food security support",
      description: "Emergency food parcels and meal programs for those in need.",
      contact: "Call 1800 108 001",
      tags: ["nutrition", "emergency", "support"],
      organizationId: "emergency_food_relief",
      schedules: [
        ServiceSchedule(day: "Tuesday", startTime: "16:00", endTime: "18:00", notes: "Food distribution"),
        ServiceSchedule(day: "Thursday", startTime: "16:00", endTime: "18:00", notes: "Food distribution"),
        ServiceSchedule(day: "Saturday", startTime: "10:00", endTime: "12:00", notes: "Weekend distribution"),
      ],
      offerings: [
        ServiceOffering(name: "Emergency food parcels", category: "nutrition", cost: "Free", requirements: "No ID required"),
        ServiceOffering(name: "Hot meal program", category: "nutrition", cost: "Free"),
        ServiceOffering(name: "Grocery vouchers", category: "emergency", cost: "Free", requirements: "Referral preferred"),
      ],
      location: ServiceLocation(
        latitude: -31.9523, 
        longitude: 115.8613, 
        address: "456 Community Centre Dr, Perth WA 6000",
        landmark: "Behind the community hall"
      ),
    ),
  ];

  // Filter services by tag
  static List<SupportService> filterByTags(List<String> selectedTags) {
    if (selectedTags.isEmpty) return all;
    return all.where((service) {
      return service.tags.any((tag) => selectedTags.contains(tag));
    }).toList();
  }

  // Helper: Find services by keyword
  static List<SupportService> search(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return all.where((service) {
      return service.name.toLowerCase().contains(lowerQuery) ||
             service.description.toLowerCase().contains(lowerQuery) ||
             service.tags.map((t) => t.toLowerCase()).any((t) => t.contains(lowerQuery));
    }).toList();
  }

  // Helper: Get sample services (alias for 'all')
  static List<SupportService> getSampleServices() {
    return all;
  }
}