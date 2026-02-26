/// NSW Health Resources - Sample data for Resource Finder
/// Contains 25+ curated health and community resources across Sydney
///
/// Categories:
/// - Medical Care (GP clinics, hospitals)
/// - Mental Health (counselling, psychiatry, youth services)
/// - Pharmacies
/// - Food & Basic Needs
/// - Emergency & Crisis
/// - Community Services (legal, financial, housing)

import '../models/health_resource_model.dart';

/// All NSW health resources
final List<HealthResource> nswHealthResources = [
  // ═══════════════════════════════════════════════════════════════════════════
  // MEDICAL CARE - GP CLINICS
  // ═══════════════════════════════════════════════════════════════════════════

  const HealthResource(
    id: 'auburn_medical',
    name: 'Auburn Medical Centre',
    type: ResourceType.clinic,
    description: 'Bulk billing GP clinic with multilingual staff',
    address: '62 Queen Street, Auburn NSW 2144',
    phone: '(02) 9649 1234',
    website: 'https://auburnmedical.com.au',
    neighborhood: 'Auburn',
    region: 'Cumberland',
    latitude: -33.8495,
    longitude: 151.0332,
    servicesOffered: [
      'General practice',
      'Chronic disease management',
      'Women\'s health',
      'Vaccinations',
      'Health assessments',
      'Skin checks',
    ],
    features: [
      ResourceFeature.bulkBilling,
      ResourceFeature.weekendHours,
      ResourceFeature.parking,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.wheelchairAccess,
    ],
    costInfo: CostInfo(
      hasBulkBilling: true,
      acceptsMedicare: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Vietnamese', 'Chinese (Mandarin)', 'Turkish'],
      hasInterpreter: true,
      wheelchairAccessible: true,
      hasParking: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '8am - 6pm',
        'tuesday': '8am - 6pm',
        'wednesday': '8am - 6pm',
        'thursday': '8am - 6pm',
        'friday': '8am - 6pm',
        'saturday': '9am - 1pm',
        'sunday': 'Closed',
      },
    ),
  ),

  const HealthResource(
    id: 'canterbury_community_health',
    name: 'Canterbury Community Health Centre',
    type: ResourceType.clinic,
    description: 'Free community health services with interpreter support',
    address: '63 Tudor Street, Belmore NSW 2192',
    phone: '(02) 9718 2000',
    neighborhood: 'Belmore',
    region: 'Canterbury-Bankstown',
    latitude: -33.9167,
    longitude: 151.0833,
    servicesOffered: [
      'General health clinics',
      'Child & family health',
      'Women\'s health',
      'Diabetes education',
      'Chronic disease programs',
      'Health promotion',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.publicTransport,
      ResourceFeature.culturallySafe,
    ],
    costInfo: CostInfo(
      isFreeService: true,
      acceptsMedicare: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Greek', 'Vietnamese', 'Chinese'],
      hasInterpreter: true,
      wheelchairAccessible: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '8:30am - 5pm',
        'tuesday': '8:30am - 5pm',
        'wednesday': '8:30am - 5pm',
        'thursday': '8:30am - 5pm',
        'friday': '8:30am - 5pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
  ),

  const HealthResource(
    id: 'fairfield_heights_medical',
    name: 'Fairfield Heights Medical Practice',
    type: ResourceType.clinic,
    description: 'Family medical practice with evening appointments',
    address: '244 The Boulevarde, Fairfield Heights NSW 2165',
    phone: '(02) 9727 3355',
    neighborhood: 'Fairfield Heights',
    region: 'Fairfield',
    latitude: -33.8667,
    longitude: 150.9500,
    servicesOffered: [
      'General practice',
      'Family medicine',
      'Chronic disease management',
      'Mental health plans',
      'Vaccinations',
      'Travel medicine',
    ],
    features: [
      ResourceFeature.bulkBilling,
      ResourceFeature.eveningHours,
      ResourceFeature.parking,
      ResourceFeature.interpreterAvailable,
    ],
    costInfo: CostInfo(
      hasBulkBilling: true,
      acceptsMedicare: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Spanish', 'Arabic', 'Vietnamese'],
      hasInterpreter: true,
      hasParking: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '8am - 8pm',
        'tuesday': '8am - 8pm',
        'wednesday': '8am - 8pm',
        'thursday': '8am - 8pm',
        'friday': '8am - 6pm',
        'saturday': '9am - 2pm',
        'sunday': 'Closed',
      },
    ),
  ),

  const HealthResource(
    id: 'bankstown_superclinic',
    name: 'Bankstown GP Super Clinic',
    type: ResourceType.clinic,
    description: 'Walk-in welcome, no appointment needed for urgent care',
    address: '36 Rickard Road, Bankstown NSW 2200',
    phone: '(02) 9708 2888',
    neighborhood: 'Bankstown',
    region: 'Canterbury-Bankstown',
    latitude: -33.9167,
    longitude: 151.0333,
    servicesOffered: [
      'General practice',
      'Urgent care',
      'Pathology on-site',
      'Mental health',
      'Chronic disease',
      'Women\'s health',
    ],
    features: [
      ResourceFeature.bulkBilling,
      ResourceFeature.walkIn,
      ResourceFeature.weekendHours,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.publicTransport,
    ],
    costInfo: CostInfo(
      hasBulkBilling: true,
      acceptsMedicare: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Vietnamese', 'Chinese', 'Greek'],
      hasInterpreter: true,
      wheelchairAccessible: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '7am - 10pm',
        'tuesday': '7am - 10pm',
        'wednesday': '7am - 10pm',
        'thursday': '7am - 10pm',
        'friday': '7am - 10pm',
        'saturday': '8am - 6pm',
        'sunday': '9am - 5pm',
      },
    ),
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // MENTAL HEALTH
  // ═══════════════════════════════════════════════════════════════════════════

  const HealthResource(
    id: 'headspace_bankstown',
    name: 'headspace Bankstown',
    type: ResourceType.mentalHealth,
    description: 'Free mental health support for young people 12-25',
    address: 'Level 2, 66-72 Rickard Road, Bankstown NSW 2200',
    phone: '(02) 9393 9669',
    website: 'https://headspace.org.au/headspace-centres/bankstown/',
    neighborhood: 'Bankstown',
    region: 'Canterbury-Bankstown',
    latitude: -33.9167,
    longitude: 151.0333,
    servicesOffered: [
      'Mental health support',
      'Counselling',
      'Drug and alcohol services',
      'Work and study support',
      'Physical and sexual health',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.noReferralNeeded,
      ResourceFeature.telehealth,
      ResourceFeature.youthFriendly,
      ResourceFeature.confidential,
      ResourceFeature.lgbtqFriendly,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      hasTelehealth: true,
      publicTransitNearby: true,
      wheelchairAccessible: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '9am - 5pm',
        'tuesday': '9am - 7pm',
        'wednesday': '9am - 5pm',
        'thursday': '9am - 7pm',
        'friday': '9am - 5pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
    specialNotes: 'For young people aged 12-25. No Medicare card required.',
  ),

  const HealthResource(
    id: 'headspace_campbelltown',
    name: 'headspace Campbelltown',
    type: ResourceType.mentalHealth,
    description: 'Free mental health support for young people 12-25',
    address: '1 Queen Street, Campbelltown NSW 2560',
    phone: '(02) 4628 2955',
    website: 'https://headspace.org.au/headspace-centres/campbelltown/',
    neighborhood: 'Campbelltown',
    region: 'Macarthur',
    latitude: -34.0667,
    longitude: 150.8167,
    servicesOffered: [
      'Mental health support',
      'Counselling',
      'Drug and alcohol services',
      'Work and study support',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.noReferralNeeded,
      ResourceFeature.telehealth,
      ResourceFeature.youthFriendly,
      ResourceFeature.eveningHours,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      hasTelehealth: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '9am - 5pm',
        'tuesday': '9am - 5pm',
        'wednesday': '9am - 8pm',
        'thursday': '9am - 5pm',
        'friday': '9am - 5pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
    specialNotes: 'For young people aged 12-25. Walk-ins welcome.',
  ),

  const HealthResource(
    id: 'liverpool_mental_health',
    name: 'Liverpool Mental Health Service',
    type: ResourceType.mentalHealth,
    description: 'Public mental health services including psychiatry',
    address: 'Cnr Elizabeth & Goulburn Streets, Liverpool NSW 2170',
    phone: '(02) 8738 4600',
    neighborhood: 'Liverpool',
    region: 'Liverpool',
    latitude: -33.9200,
    longitude: 150.9233,
    servicesOffered: [
      'Psychiatric assessment',
      'Community mental health',
      'Crisis intervention',
      'Case management',
      'Group therapy',
    ],
    features: [
      ResourceFeature.bulkBilling,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.publicTransport,
    ],
    costInfo: CostInfo(
      hasBulkBilling: true,
      acceptsMedicare: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Vietnamese', 'Chinese', 'Spanish'],
      hasInterpreter: true,
      wheelchairAccessible: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '8:30am - 5pm',
        'tuesday': '8:30am - 5pm',
        'wednesday': '8:30am - 5pm',
        'thursday': '8:30am - 5pm',
        'friday': '8:30am - 5pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
    specialNotes: 'GP referral recommended. Emergency presentations welcome at Liverpool Hospital ED.',
  ),

  const HealthResource(
    id: 'wayahead_workways',
    name: 'WayAhead Workways',
    type: ResourceType.mentalHealth,
    description: 'Mental health employment and peer support services',
    address: 'Level 5, 80 William Street, Woolloomooloo NSW 2011',
    phone: '1300 794 991',
    website: 'https://wayahead.org.au',
    neighborhood: 'Woolloomooloo',
    region: 'Inner Sydney',
    servicesOffered: [
      'Peer support',
      'Employment support',
      'Mental health education',
      'Support groups',
      'Recovery programs',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.noReferralNeeded,
      ResourceFeature.telehealth,
      ResourceFeature.confidential,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      hasTelehealth: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '9am - 5pm',
        'tuesday': '9am - 5pm',
        'wednesday': '9am - 5pm',
        'thursday': '9am - 5pm',
        'friday': '9am - 5pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // PHARMACIES
  // ═══════════════════════════════════════════════════════════════════════════

  const HealthResource(
    id: 'chemist_warehouse_bankstown',
    name: 'Chemist Warehouse Bankstown',
    type: ResourceType.pharmacy,
    description: 'Discount pharmacy with PBS medications and health services',
    address: 'Bankstown Central, North Terrace, Bankstown NSW 2200',
    phone: '(02) 9790 3055',
    website: 'https://chemistwarehouse.com.au',
    neighborhood: 'Bankstown',
    region: 'Canterbury-Bankstown',
    latitude: -33.9167,
    longitude: 151.0333,
    servicesOffered: [
      'PBS medications',
      'Flu vaccinations',
      'Blood pressure checks',
      'Diabetes support',
      'Scripts on file',
      'Webster packs',
    ],
    features: [
      ResourceFeature.weekendHours,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.publicTransport,
      ResourceFeature.parking,
    ],
    costInfo: CostInfo(
      hasPBS: true,
      acceptsMedicare: true,
      hasConcessionRates: true,
    ),
    accessibility: AccessibilityInfo(
      wheelchairAccessible: true,
      hasParking: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '8am - 9pm',
        'tuesday': '8am - 9pm',
        'wednesday': '8am - 9pm',
        'thursday': '8am - 9pm',
        'friday': '8am - 9pm',
        'saturday': '8am - 6pm',
        'sunday': '10am - 5pm',
      },
    ),
  ),

  const HealthResource(
    id: 'priceline_auburn',
    name: 'Priceline Pharmacy Auburn',
    type: ResourceType.pharmacy,
    description: 'Community pharmacy with health checks and diabetes support',
    address: 'Auburn Central, 62 Queen Street, Auburn NSW 2144',
    phone: '(02) 9643 2355',
    website: 'https://priceline.com.au',
    neighborhood: 'Auburn',
    region: 'Cumberland',
    latitude: -33.8495,
    longitude: 151.0332,
    servicesOffered: [
      'PBS medications',
      'Diabetes management',
      'Blood pressure monitoring',
      'Weight management',
      'Vaccinations',
    ],
    features: [
      ResourceFeature.weekendHours,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.parking,
      ResourceFeature.interpreterAvailable,
    ],
    costInfo: CostInfo(
      hasPBS: true,
      acceptsMedicare: true,
      hasConcessionRates: true,
      hasHealthCareCard: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Vietnamese'],
      wheelchairAccessible: true,
      hasParking: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '8:30am - 6pm',
        'tuesday': '8:30am - 6pm',
        'wednesday': '8:30am - 6pm',
        'thursday': '8:30am - 9pm',
        'friday': '8:30am - 6pm',
        'saturday': '9am - 5pm',
        'sunday': '10am - 4pm',
      },
    ),
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // FOOD & BASIC NEEDS
  // ═══════════════════════════════════════════════════════════════════════════

  const HealthResource(
    id: 'foodbank_nsw',
    name: 'Foodbank NSW & ACT',
    type: ResourceType.foodBank,
    description: 'Free groceries and food relief for those in need',
    address: '20 Roberts Road, Wetherill Park NSW 2164',
    phone: '(02) 9756 3099',
    website: 'https://foodbank.org.au/NSW-ACT/',
    neighborhood: 'Wetherill Park',
    region: 'Fairfield',
    servicesOffered: [
      'Free groceries',
      'Fresh produce',
      'Pantry staples',
      'Baby supplies',
      'Hygiene products',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.noIdRequired,
      ResourceFeature.parking,
      ResourceFeature.wheelchairAccess,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      wheelchairAccessible: true,
      hasParking: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '9am - 3pm',
        'tuesday': '9am - 3pm',
        'wednesday': '9am - 3pm',
        'thursday': '9am - 3pm',
        'friday': '9am - 3pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
    specialNotes: 'Bring your own bags. No ID required but Centrelink card helps.',
  ),

  const HealthResource(
    id: 'ozharvest_market',
    name: 'OzHarvest Market',
    type: ResourceType.foodBank,
    description: 'Free rescued food supermarket - take what you need',
    address: '46 Addison Road, Marrickville NSW 2204',
    phone: '(02) 9516 3877',
    website: 'https://ozharvest.org/ozharvest-market/',
    neighborhood: 'Marrickville',
    region: 'Inner West',
    servicesOffered: [
      'Free groceries',
      'Fresh fruit & vegetables',
      'Bread & bakery',
      'Dairy products',
      'Canned goods',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.noIdRequired,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.publicTransport,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      wheelchairAccessible: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': 'Closed',
        'tuesday': 'Closed',
        'wednesday': '10am - 2pm',
        'thursday': '10am - 2pm',
        'friday': 'Closed',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
    specialNotes: 'No questions asked. Take what you need, give if you can.',
  ),

  const HealthResource(
    id: 'vinnies_bankstown',
    name: 'St Vincent de Paul - Bankstown',
    type: ResourceType.foodBank,
    description: 'Emergency food relief, financial assistance, and support',
    address: '31 Meredith Street, Bankstown NSW 2200',
    phone: '(02) 9796 6022',
    website: 'https://vinnies.org.au',
    neighborhood: 'Bankstown',
    region: 'Canterbury-Bankstown',
    servicesOffered: [
      'Emergency food',
      'Financial assistance',
      'Utility bill support',
      'Clothing',
      'Furniture',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.confidential,
      ResourceFeature.interpreterAvailable,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Vietnamese'],
      hasInterpreter: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '10am - 2pm',
        'tuesday': '10am - 2pm',
        'wednesday': '10am - 2pm',
        'thursday': '10am - 2pm',
        'friday': '10am - 2pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // HOSPITALS & EMERGENCY
  // ═══════════════════════════════════════════════════════════════════════════

  const HealthResource(
    id: 'liverpool_hospital_ed',
    name: 'Liverpool Hospital Emergency',
    type: ResourceType.hospital,
    description: '24/7 emergency department',
    address: 'Elizabeth Street, Liverpool NSW 2170',
    phone: '(02) 8738 3000',
    website: 'https://swslhd.health.nsw.gov.au/liverpool/',
    neighborhood: 'Liverpool',
    region: 'Liverpool',
    latitude: -33.9200,
    longitude: 150.9233,
    servicesOffered: [
      'Emergency care',
      'Trauma services',
      'Cardiac care',
      'Stroke services',
      'Pediatric emergency',
    ],
    features: [
      ResourceFeature.open24Hours,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.parking,
      ResourceFeature.publicTransport,
    ],
    costInfo: CostInfo(
      isFreeService: true,
      acceptsMedicare: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English'],
      hasInterpreter: true,
      wheelchairAccessible: true,
      hasParking: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(isOpen24Hours: true),
    specialNotes: 'For emergencies call 000. For less urgent issues visit your GP or call HealthDirect 1800 022 222.',
  ),

  const HealthResource(
    id: 'bankstown_hospital_ed',
    name: 'Bankstown-Lidcombe Hospital Emergency',
    type: ResourceType.hospital,
    description: '24/7 emergency department',
    address: 'Eldridge Road, Bankstown NSW 2200',
    phone: '(02) 9722 8000',
    website: 'https://swslhd.health.nsw.gov.au/bankstown/',
    neighborhood: 'Bankstown',
    region: 'Canterbury-Bankstown',
    latitude: -33.9167,
    longitude: 151.0333,
    servicesOffered: [
      'Emergency care',
      'Maternity',
      'Cardiac services',
      'General medicine',
      'Surgery',
    ],
    features: [
      ResourceFeature.open24Hours,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.parking,
      ResourceFeature.publicTransport,
    ],
    costInfo: CostInfo(
      isFreeService: true,
      acceptsMedicare: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Vietnamese', 'Chinese', 'Greek'],
      hasInterpreter: true,
      wheelchairAccessible: true,
      hasParking: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(isOpen24Hours: true),
  ),

  const HealthResource(
    id: 'canterbury_hospital_ed',
    name: 'Canterbury Hospital Emergency',
    type: ResourceType.hospital,
    description: '24/7 emergency department',
    address: '575 Canterbury Road, Campsie NSW 2194',
    phone: '(02) 9787 0000',
    website: 'https://slhd.health.nsw.gov.au/canterbury/',
    neighborhood: 'Campsie',
    region: 'Canterbury-Bankstown',
    latitude: -33.9100,
    longitude: 151.1033,
    servicesOffered: [
      'Emergency care',
      'Aged care',
      'Rehabilitation',
      'Palliative care',
    ],
    features: [
      ResourceFeature.open24Hours,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.parking,
      ResourceFeature.publicTransport,
    ],
    costInfo: CostInfo(
      isFreeService: true,
      acceptsMedicare: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Chinese', 'Greek', 'Korean'],
      hasInterpreter: true,
      wheelchairAccessible: true,
      hasParking: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(isOpen24Hours: true),
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // TELEHEALTH & HEALTH INFO
  // ═══════════════════════════════════════════════════════════════════════════

  const HealthResource(
    id: 'healthdirect',
    name: 'healthdirect',
    type: ResourceType.telehealth,
    description: '24/7 health advice from registered nurses',
    address: 'Australia-wide phone service',
    phone: '1800 022 222',
    website: 'https://healthdirect.gov.au',
    region: 'Australia',
    servicesOffered: [
      'Health advice',
      'Symptom checker',
      'Service finder',
      'After hours GP helpline',
      'Video consultations',
    ],
    features: [
      ResourceFeature.open24Hours,
      ResourceFeature.freeService,
      ResourceFeature.telehealth,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.confidential,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      hasInterpreter: true,
      hasTelehealth: true,
    ),
    hours: HoursOfOperation(isOpen24Hours: true),
    specialNotes: 'Speak to a registered nurse anytime. For emergencies call 000.',
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMUNITY SERVICES
  // ═══════════════════════════════════════════════════════════════════════════

  const HealthResource(
    id: 'legal_aid_nsw',
    name: 'Legal Aid NSW',
    type: ResourceType.community,
    description: 'Free legal advice and representation',
    address: '323 Castlereagh Street, Sydney NSW 2000',
    phone: '1300 888 529',
    website: 'https://legalaid.nsw.gov.au',
    neighborhood: 'Sydney CBD',
    region: 'Sydney',
    servicesOffered: [
      'Legal advice',
      'Court representation',
      'Family law',
      'Criminal law',
      'Civil law',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.telehealth,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.confidential,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English'],
      hasInterpreter: true,
      hasTelehealth: true,
      wheelchairAccessible: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '9am - 5pm',
        'tuesday': '9am - 5pm',
        'wednesday': '9am - 5pm',
        'thursday': '9am - 5pm',
        'friday': '9am - 5pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
    specialNotes: 'Call LawAccess NSW on 1300 888 529 for free legal information.',
  ),

  const HealthResource(
    id: 'centrelink_bankstown',
    name: 'Services Australia - Bankstown',
    type: ResourceType.community,
    description: 'Centrelink, Medicare, and government services',
    address: 'Level 1, 7-9 Jacobs Street, Bankstown NSW 2200',
    phone: '136 240',
    website: 'https://servicesaustralia.gov.au',
    neighborhood: 'Bankstown',
    region: 'Canterbury-Bankstown',
    latitude: -33.9167,
    longitude: 151.0333,
    servicesOffered: [
      'Centrelink payments',
      'Medicare services',
      'JobSeeker support',
      'Disability support',
      'Carer payments',
      'Family Tax Benefit',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.wheelchairAccess,
      ResourceFeature.publicTransport,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Vietnamese', 'Chinese'],
      hasInterpreter: true,
      wheelchairAccessible: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '8:30am - 4:30pm',
        'tuesday': '8:30am - 4:30pm',
        'wednesday': '8:30am - 4:30pm',
        'thursday': '8:30am - 4:30pm',
        'friday': '8:30am - 4:30pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
    specialNotes: 'Book online or call ahead. Translators available.',
  ),

  const HealthResource(
    id: 'settlement_services',
    name: 'Settlement Services International',
    type: ResourceType.community,
    description: 'Support for refugees and migrants settling in Australia',
    address: 'Level 2, 158 Liverpool Road, Ashfield NSW 2131',
    phone: '(02) 8799 6700',
    website: 'https://ssi.org.au',
    neighborhood: 'Ashfield',
    region: 'Inner West',
    servicesOffered: [
      'Settlement support',
      'Employment assistance',
      'English classes',
      'Housing support',
      'Case management',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.culturallySafe,
      ResourceFeature.confidential,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Dari', 'Farsi', 'Tamil', 'Chinese'],
      hasInterpreter: true,
      publicTransitNearby: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '9am - 5pm',
        'tuesday': '9am - 5pm',
        'wednesday': '9am - 5pm',
        'thursday': '9am - 5pm',
        'friday': '9am - 5pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
  ),

  const HealthResource(
    id: 'housing_nsw',
    name: 'DCJ Housing Contact Centre',
    type: ResourceType.housing,
    description: 'Public and social housing assistance',
    address: 'NSW-wide service',
    phone: '1800 422 322',
    website: 'https://www.facs.nsw.gov.au/housing',
    region: 'NSW',
    servicesOffered: [
      'Social housing applications',
      'Rent assistance',
      'Crisis accommodation',
      'Private rental assistance',
      'Housing pathways',
    ],
    features: [
      ResourceFeature.freeService,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.telehealth,
      ResourceFeature.confidential,
    ],
    costInfo: CostInfo(
      isFreeService: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English'],
      hasInterpreter: true,
      hasTelehealth: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '8am - 5pm',
        'tuesday': '8am - 5pm',
        'wednesday': '8am - 5pm',
        'thursday': '8am - 5pm',
        'friday': '8am - 5pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
    specialNotes: 'For crisis accommodation call Link2Home 1800 152 152 (24/7)',
  ),

  // ═══════════════════════════════════════════════════════════════════════════
  // WOMEN'S HEALTH
  // ═══════════════════════════════════════════════════════════════════════════

  const HealthResource(
    id: 'family_planning_nsw',
    name: 'Family Planning NSW - Fairfield',
    type: ResourceType.womensHealth,
    description: 'Reproductive and sexual health services',
    address: '28 Hamilton Road, Fairfield NSW 2165',
    phone: '(02) 9716 6455',
    website: 'https://www.fpnsw.org.au',
    neighborhood: 'Fairfield',
    region: 'Fairfield',
    servicesOffered: [
      'Contraception',
      'STI testing',
      'Pregnancy options counselling',
      'Cervical screening',
      'LGBTQ+ health',
    ],
    features: [
      ResourceFeature.bulkBilling,
      ResourceFeature.noReferralNeeded,
      ResourceFeature.interpreterAvailable,
      ResourceFeature.confidential,
      ResourceFeature.lgbtqFriendly,
      ResourceFeature.wheelchairAccess,
    ],
    costInfo: CostInfo(
      hasBulkBilling: true,
      hasConcessionRates: true,
      acceptsMedicare: true,
    ),
    accessibility: AccessibilityInfo(
      languagesSpoken: ['English', 'Arabic', 'Vietnamese', 'Chinese'],
      hasInterpreter: true,
      wheelchairAccessible: true,
    ),
    hours: HoursOfOperation(
      schedule: {
        'monday': '9am - 5pm',
        'tuesday': '9am - 7pm',
        'wednesday': '9am - 5pm',
        'thursday': '9am - 5pm',
        'friday': '9am - 5pm',
        'saturday': 'Closed',
        'sunday': 'Closed',
      },
    ),
    specialNotes: 'Services for all genders. No Medicare card required for some services.',
  ),
];

/// Get all resources of a specific type
List<HealthResource> getResourcesByType(ResourceType type) {
  return nswHealthResources.where((r) => r.type == type).toList();
}

/// Get all resources in a specific region
List<HealthResource> getResourcesByRegion(String region) {
  return nswHealthResources
      .where((r) => r.region?.toLowerCase() == region.toLowerCase())
      .toList();
}

/// Get all resources by category
Map<String, List<HealthResource>> getResourcesByCategory() {
  final Map<String, List<HealthResource>> grouped = {};
  for (final resource in nswHealthResources) {
    final category = resource.category;
    grouped.putIfAbsent(category, () => []);
    grouped[category]!.add(resource);
  }
  return grouped;
}

/// Get crisis resources (24/7 hotlines)
List<HealthResource> getCrisisResources() {
  return [
    ...EmergencyResources.all,
    ...nswHealthResources.where((r) => r.isCrisisResource),
  ];
}

/// Search resources by keyword
List<HealthResource> searchResources(String query) {
  final lowercaseQuery = query.toLowerCase();
  return nswHealthResources.where((resource) {
    return resource.name.toLowerCase().contains(lowercaseQuery) ||
        (resource.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
        resource.servicesOffered.any((s) => s.toLowerCase().contains(lowercaseQuery)) ||
        (resource.neighborhood?.toLowerCase().contains(lowercaseQuery) ?? false) ||
        (resource.region?.toLowerCase().contains(lowercaseQuery) ?? false);
  }).toList();
}
