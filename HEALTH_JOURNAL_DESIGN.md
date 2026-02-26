# Health Journal Design Document

## Overview
Transform journal from **mental wellness focus** to **health navigation focus** while preserving core journaling functionality and privacy.

---

## 1. NEW DATA MODEL

### HealthJournalEntry Model

```dart
/// Health-focused journal entry with structured check-ins and free-form text
class HealthJournalEntry {
  final String id;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  // === STRUCTURED CHECK-IN DATA ===
  final HealthCheckIn checkIn;

  // === OPTIONAL SYMPTOM TRACKING ===
  final List<SymptomTracking> symptoms;

  // === FREE-FORM JOURNAL ===
  final String? journalText;

  // === AI-GENERATED HEALTH TAGS ===
  final List<HealthTag> healthTags;

  // === PATTERN DETECTION ===
  final bool hasPatternDetected;
  final String? patternInsightId; // Reference to pattern insight if generated

  // === METADATA ===
  final Map<String, dynamic> metadata;
  final bool isProcessed; // Has AI tagging completed?
}
```

### HealthCheckIn Model

```dart
/// Structured daily health check-in (takes ~1-2 minutes)
class HealthCheckIn {
  // Physical Health (3 metrics)
  final int? energy;        // 1-5: Low → High
  final int? painLevel;     // 0-5: None → Severe (0 = no pain)
  final int? sleepQuality;  // 1-5: Poor → Great

  // Mental/Emotional Health (3 metrics)
  final int? mood;          // 1-5: Low → Good
  final int? stressLevel;   // 1-5: None → Very high
  final int? anxietyLevel;  // 1-5: None → Very high

  // Context (quick yes/no/some)
  final MealStatus? ateRegularMeals; // yes, no, some
  final String? majorStressors; // Optional free text

  const HealthCheckIn({
    this.energy,
    this.painLevel,
    this.sleepQuality,
    this.mood,
    this.stressLevel,
    this.anxietyLevel,
    this.ateRegularMeals,
    this.majorStressors,
  });

  // Computed properties
  bool get hasPhysicalData => energy != null || painLevel != null || sleepQuality != null;
  bool get hasMentalData => mood != null || stressLevel != null || anxietyLevel != null;
  bool get isComplete => hasPhysicalData && hasMentalData;

  // Health status assessment
  HealthStatus get overallPhysicalHealth {
    if (!hasPhysicalData) return HealthStatus.unknown;
    final avg = ((energy ?? 3) + (6 - (painLevel ?? 0)) + (sleepQuality ?? 3)) / 3;
    if (avg >= 4) return HealthStatus.good;
    if (avg >= 3) return HealthStatus.moderate;
    return HealthStatus.concerning;
  }

  HealthStatus get overallMentalHealth {
    if (!hasMentalData) return HealthStatus.unknown;
    final avg = ((mood ?? 3) + (6 - (stressLevel ?? 3)) + (6 - (anxietyLevel ?? 3))) / 3;
    if (avg >= 4) return HealthStatus.good;
    if (avg >= 3) return HealthStatus.moderate;
    return HealthStatus.concerning;
  }
}

enum MealStatus { yes, no, some }
enum HealthStatus { unknown, good, moderate, concerning }
```

### SymptomTracking Model

```dart
/// Optional symptom tracking for specific health concerns
class SymptomTracking {
  final String id;
  final String symptomType; // "headache", "nausea", "fatigue", etc.
  final int severity;       // 1-5: Mild → Severe
  final String duration;    // "few_hours", "all_day", "multiple_days"
  final List<String> whatHelps; // ["rest", "medication", "nothing"]
  final String? notes;

  const SymptomTracking({
    required this.id,
    required this.symptomType,
    required this.severity,
    required this.duration,
    this.whatHelps = const [],
    this.notes,
  });

  bool get isSevere => severity >= 4;
  bool get isPersistent => duration == "multiple_days";
}
```

### HealthTag Model

```dart
/// AI-extracted health theme tags (replaces Choice/Chance/Outcome)
class HealthTag {
  final String id;
  final String canonicalKey;  // "fatigue", "work-stress", "cost-barrier"
  final String displayName;   // "Fatigue", "Work Stress", "Cost Barrier"
  final HealthTagCategory category;
  final double confidence;    // 0.0 - 1.0
  final String? evidenceSpan; // Text that triggered this tag
  final DateTime createdAt;

  const HealthTag({
    required this.id,
    required this.canonicalKey,
    required this.displayName,
    required this.category,
    required this.confidence,
    this.evidenceSpan,
    required this.createdAt,
  });

  bool get isHighConfidence => confidence >= 0.7;
}

/// New health-focused tag taxonomy
enum HealthTagCategory {
  physicalSymptom,  // fatigue, headache, pain, nausea, etc.
  mentalEmotional,  // anxiety, depression, stress, overwhelmed
  healthConcern,    // diabetes-concern, blood-pressure, chronic-pain
  barrier,          // cost-barrier, transportation-issue, time-pressure
  lifeContext,      // work-stress, food-insecurity, housing-stress
  positive,         // feeling-better, good-day, progress, supported
}
```

---

## 2. HEALTH TAG TAXONOMY

### Physical Symptoms
```dart
static const physicalSymptomTags = {
  'fatigue': 'Fatigue',
  'headache': 'Headache',
  'pain': 'Pain',
  'nausea': 'Nausea',
  'dizziness': 'Dizziness',
  'fever': 'Fever',
  'cough': 'Cough',
  'shortness-of-breath': 'Shortness of Breath',
  'chest-pain': 'Chest Pain',
  'stomach-pain': 'Stomach Pain',
  'back-pain': 'Back Pain',
  'joint-pain': 'Joint Pain',
  'muscle-ache': 'Muscle Ache',
  'insomnia': 'Insomnia',
  'appetite-loss': 'Appetite Loss',
};
```

### Mental/Emotional
```dart
static const mentalEmotionalTags = {
  'anxiety': 'Anxiety',
  'depression': 'Depression',
  'stress': 'Stress',
  'overwhelmed': 'Overwhelmed',
  'hopeless': 'Hopeless',
  'panic': 'Panic',
  'irritable': 'Irritable',
  'lonely': 'Lonely',
  'worried': 'Worried',
};
```

### Health Concerns
```dart
static const healthConcernTags = {
  'diabetes-concern': 'Diabetes Concern',
  'blood-pressure': 'Blood Pressure',
  'heart-health': 'Heart Health',
  'pregnancy': 'Pregnancy',
  'chronic-pain': 'Chronic Pain',
  'medication-concern': 'Medication Concern',
  'weight-concern': 'Weight Concern',
};
```

### Barriers
```dart
static const barrierTags = {
  'cost-barrier': 'Cost Barrier',
  'transportation-issue': 'Transportation Issue',
  'time-pressure': 'Time Pressure',
  'childcare-problem': 'Childcare Problem',
  'language-barrier': 'Language Barrier',
  'no-insurance': 'No Insurance',
  'cant-take-time-off': 'Can\'t Take Time Off',
};
```

### Life Context
```dart
static const lifeContextTags = {
  'work-stress': 'Work Stress',
  'food-insecurity': 'Food Insecurity',
  'housing-stress': 'Housing Stress',
  'social-isolation': 'Social Isolation',
  'family-stress': 'Family Stress',
  'financial-stress': 'Financial Stress',
  'relationship-issues': 'Relationship Issues',
};
```

### Positive
```dart
static const positiveTags = {
  'feeling-better': 'Feeling Better',
  'good-day': 'Good Day',
  'progress': 'Progress',
  'supported': 'Supported',
  'accomplished': 'Accomplished',
  'hopeful': 'Hopeful',
};
```

---

## 3. JOURNAL FORM STRUCTURE

### Form Sections (in order)

#### Section 1: Today's Check-In (Required, ~1 minute)
```
┌─────────────────────────────────────┐
│ 📊 TODAY'S CHECK-IN                 │
├─────────────────────────────────────┤
│                                     │
│ Physical Health                     │
│                                     │
│ Energy  ●●●○○  [Tap to rate 1-5]   │
│ Pain    ●○○○○  [Tap to rate 0-5]   │
│ Sleep   ●●●●○  [Tap to rate 1-5]   │
│                                     │
│ Mental & Emotional                  │
│                                     │
│ Mood    ●●●○○  [Tap to rate 1-5]   │
│ Stress  ●●●●○  [Tap to rate 1-5]   │
│ Anxiety ●●○○○  [Tap to rate 1-5]   │
│                                     │
│ Quick Context                       │
│                                     │
│ Ate regular meals?                  │
│ [Yes] [Some] [No]                   │
│                                     │
│ Major stressors? (optional)         │
│ [Text input - single line]          │
│                                     │
└─────────────────────────────────────┘
```

**Implementation Notes:**
- Use slider widgets for ratings (like volume control)
- Visual feedback: dots fill in as you slide
- Optional: Add emoji next to ratings (😴 → 😊 for energy)
- Default to middle value (3) when empty
- Can skip entire section if user wants to journal only

#### Section 2: Track a Symptom (Optional, expandable)
```
┌─────────────────────────────────────┐
│ 🩺 TRACK A SYMPTOM (Optional)       │
│ [+ Add symptom] [Collapsed by default]
│                                     │
│ [When expanded]:                    │
│                                     │
│ What symptom?                       │
│ [Dropdown: Headache ▼]             │
│ Common: Headache, Fatigue, Nausea   │
│ [+ Add custom symptom]              │
│                                     │
│ How severe?                         │
│ ●●●○○ [1-5 slider]                 │
│                                     │
│ How long?                           │
│ [Few hours] [All day] [3+ days]     │
│                                     │
│ What helps?                         │
│ [✓ Rest] [✓ Medication] [ ] Nothing]
│                                     │
│ Notes (optional)                    │
│ [Text input - single line]          │
│                                     │
│ [Remove symptom] [Add another symptom]
└─────────────────────────────────────┘
```

**Implementation Notes:**
- Collapsed by default (not required)
- Can track multiple symptoms per entry
- Dropdown has common symptoms + "Custom" option
- Duration buttons (not slider)
- What helps: multi-select checkboxes

#### Section 3: Free-Form Journal (Optional, main value)
```
┌─────────────────────────────────────┐
│ 📝 HOW ARE YOU FEELING?             │
├─────────────────────────────────────┤
│                                     │
│ Write about your health, how you're│
│ feeling, what's affecting you...    │
│                                     │
│ [Large text area - multiline]       │
│ Minimum 3 lines visible             │
│ Expands as you type                 │
│                                     │
│                                     │
│ AI will auto-tag health themes      │
│ from your entry (behind scenes)     │
│                                     │
└─────────────────────────────────────┘
```

**Implementation Notes:**
- **This is the core value** - keep prominent
- Prompt changes based on check-in data:
  - High stress: "What's been causing stress today?"
  - High pain: "Tell me about the pain you're experiencing"
  - Low energy: "What's been draining your energy?"
  - Default: "How are you feeling today?"
- Auto-save draft every 30 seconds
- Character counter (optional): "0/1000 characters"

#### Section 4: Actions
```
┌─────────────────────────────────────┐
│ [Save Entry] [Save as Draft] [Cancel]
└─────────────────────────────────────┘
```

---

## 4. ENTRY DISPLAY (CARD VIEW)

### Individual Entry Card
```
┌───────────────────────────────────────┐
│ 📔 Today at 2:34 PM                   │
├───────────────────────────────────────┤
│                                       │
│ Check-In Summary                      │
│ ┌─────────────┐ ┌─────────────┐     │
│ │ PHYSICAL    │ │ MENTAL      │     │
│ │ ●●●○○       │ │ ●●○○○       │     │
│ │ Moderate    │ │ Concerning  │     │
│ └─────────────┘ └─────────────┘     │
│                                       │
│ Energy ●●●○○  Pain ●●○○○            │
│ Sleep  ●●●●○  Mood ●●○○○            │
│                                       │
│ Symptoms Tracked                      │
│ 🤕 Headache (severe, all day)         │
│    Helped by: Rest, Medication        │
│                                       │
│ Journal Entry                         │
│ "Exhausted after double shift.        │
│  Headache all day. Couldn't afford    │
│  lunch so skipped it."                │
│                                       │
│ Health Themes                         │
│ #fatigue #headache #food-insecurity   │
│ #work-stress                          │
│                                       │
│ [View full] [Track pattern] [Share]  │
│                                       │
└───────────────────────────────────────┘
```

**Implementation Notes:**
- Color-coded check-in summary:
  - Green (●●●●○+): Good health
  - Orange (●●●○○): Moderate
  - Red (●●○○○-): Concerning
- Tags are clickable → filter by tag
- "Track pattern" button if symptom mentioned 2+ times
- Expandable to show full text if truncated

---

## 5. PATTERN RECOGNITION SYSTEM

### PatternInsight Model

```dart
/// Detected health pattern across multiple journal entries
class PatternInsight {
  final String id;
  final DateTime createdAt;
  final DateTime startDate; // First entry in pattern
  final DateTime endDate;   // Most recent entry

  // Pattern details
  final String symptomKey;        // "headache", "fatigue", etc.
  final int occurrenceCount;      // How many times mentioned
  final int daySpan;              // Days between first and last

  // Co-occurring factors (what else happens when symptom occurs)
  final List<CoOccurrence> coOccurrences;

  // Generated insight
  final String insight;           // "You've mentioned headaches 5 times this week"
  final String possibleConnection; // "They seem to happen after stressful workdays"
  final List<String> suggestions; // Actionable steps

  // User interaction
  final bool isDismissed;
  final bool isBookmarked;
  final DateTime? dismissedAt;

  const PatternInsight({
    required this.id,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.symptomKey,
    required this.occurrenceCount,
    required this.daySpan,
    required this.coOccurrences,
    required this.insight,
    required this.possibleConnection,
    required this.suggestions,
    this.isDismissed = false,
    this.isBookmarked = false,
    this.dismissedAt,
  });

  bool get isSignificant => occurrenceCount >= 3 && daySpan <= 14;
  bool get isRecent => DateTime.now().difference(endDate).inDays <= 7;
}

/// Co-occurring factor with a symptom
class CoOccurrence {
  final String factorKey;         // "high_stress", "skipped_meals", "poor_sleep"
  final String factorDisplay;     // "High stress", "Skipped meals"
  final int coOccurrenceCount;    // How many times they happened together
  final double correlation;       // 0.0 - 1.0 (percentage of times together)

  const CoOccurrence({
    required this.factorKey,
    required this.factorDisplay,
    required this.coOccurrenceCount,
    required this.correlation,
  });

  bool get isStrongCorrelation => correlation >= 0.6;
}
```

### Pattern Detection Logic

**Trigger Conditions:**
- Analyze last 7-14 entries
- Symptom mentioned 3+ times
- OR check-in metric consistently low/high (e.g., energy ≤2 for 5+ days)

**Analysis Steps:**
1. **Count symptom mentions** in journal text + symptom tracking
2. **Identify co-occurring factors:**
   - Check-in data (stress ≥4 when symptom occurs)
   - Context data (skipped meals)
   - Other tags (work-stress, poor-sleep)
3. **Calculate correlation** (% of times they occur together)
4. **Generate insight** if correlation ≥60%

**Example Pattern Detection:**
```
Entries analyzed: 7 (last 7 days)

Symptom: "headache"
Mentioned: 5 times

Co-occurrences:
- High stress (≥4): 4/5 times (80% correlation)
- Skipped meals: 3/5 times (60% correlation)
- Poor sleep (≤2): 4/5 times (80% correlation)

Generated Insight:
"You've mentioned headaches 5 times this week. They seem to happen:
- After stressful workdays (4/5 times)
- When you skip meals (3/5 times)
- With poor sleep (4/5 times)

Possible connection: Stress + hunger headaches?"
```

### Pattern Insight Card UI
```
┌─────────────────────────────────────────┐
│ 💡 PATTERN DETECTED                     │
├─────────────────────────────────────────┤
│                                         │
│ You've mentioned headaches 5 times      │
│ this week.                              │
│                                         │
│ They seem to happen:                    │
│ • After stressful workdays (4/5 times)  │
│ • When you skip meals (3/5 times)       │
│ • With poor sleep (4/5 times)           │
│                                         │
│ Possible connection:                    │
│ Stress + hunger headaches?              │
│                                         │
│ What might help:                        │
│ • Keep snacks at work                   │
│ • Try stress breaks during day          │
│ • Talk to GP if continues               │
│                                         │
│ [Get more help] [Dismiss] [Track more]  │
│                                         │
└─────────────────────────────────────────┘
```

---

## 6. MIGRATION STRATEGY

### Option A: Parallel Systems (RECOMMENDED)

**Keep both entry types separate:**

```dart
// In AppState
List<SmartJournalEntry> _legacyWellnessEntries = [];
List<HealthJournalEntry> _healthJournalEntries = [];
```

**Pros:**
- No data loss
- No complex migration
- Users can still view old entries
- Clean separation

**Cons:**
- Two separate lists
- Slightly more storage

**Implementation:**
- Show tab switcher in Journal page: [Health Journal] [Past Wellness Entries]
- Old entries display in read-only mode
- New entries use health journal format

### Option B: Show Migration Banner

Show one-time banner:
```
┌─────────────────────────────────────────┐
│ 🎉 JOURNAL UPDATED                      │
├─────────────────────────────────────────┤
│                                         │
│ Your journal is now focused on health   │
│ navigation! Your old entries are safe   │
│ and can be viewed anytime.              │
│                                         │
│ [Got it] [Learn more]                   │
│                                         │
└─────────────────────────────────────────┘
```

---

## 7. PRIVACY & DATA HANDLING

### Principles (UNCHANGED from current system)
- ✅ All entries stored locally (SQLite/SharedPreferences)
- ✅ AI tagging runs locally OR with explicit user permission
- ✅ Never send full journal text to server without consent
- ✅ Pattern detection runs locally
- ✅ User can delete entries permanently
- ✅ No cloud backup unless explicitly enabled

### AI Tagging Options

**Option 1: Local keyword matching (privacy-first)**
```dart
// Simple keyword-based tagging (no AI)
if (text.contains('headache')) tags.add('headache');
if (text.contains('stressed')) tags.add('stress');
```

**Option 2: Send to AI with permission**
```dart
// Show consent dialog first time
"Allow Starbound to analyze your journal entries
 for health themes? This helps detect patterns."

[Allow once] [Always allow] [No thanks]
```

**Option 3: On-device ML model (future)**
- Train small model for health theme extraction
- Runs entirely on device
- Best of both worlds

---

## 8. NEW SERVICES REQUIRED

### 1. HealthJournalService
```dart
class HealthJournalService {
  Future<HealthJournalEntry> createEntry({...});
  Future<HealthJournalEntry> updateEntry({...});
  Future<void> deleteEntry(String id);
  Future<List<HealthJournalEntry>> getEntries({DateTime? startDate, DateTime? endDate});
  Future<HealthJournalEntry?> getTodayEntry();
  Future<List<HealthJournalEntry>> searchByTag(String tagKey);
  Future<void> saveDraft(HealthJournalEntry entry);
  Future<HealthJournalEntry?> getDraft();
}
```

### 2. HealthTaggingService
```dart
class HealthTaggingService {
  Future<List<HealthTag>> extractHealthTags({
    required String text,
    HealthCheckIn? checkIn,
    List<SymptomTracking>? symptoms,
  });

  List<HealthTag> keywordBasedTagging(String text);
  Future<List<HealthTag>> aiBasedTagging(String text);
}
```

### 3. PatternDetectionService
```dart
class PatternDetectionService {
  Future<List<PatternInsight>> detectPatterns({
    required List<HealthJournalEntry> entries,
    int dayWindow = 14,
    int minOccurrences = 3,
  });

  Future<PatternInsight?> analyzeSymptomPattern({
    required String symptomKey,
    required List<HealthJournalEntry> entries,
  });

  List<CoOccurrence> findCoOccurrences({
    required List<HealthJournalEntry> symptomEntries,
    required List<HealthJournalEntry> allEntries,
  });
}
```

---

## 9. UI COMPONENT UPDATES

### Components to Create

1. **HealthCheckInWidget**
   - 6 slider inputs (energy, pain, sleep, mood, stress, anxiety)
   - Visual feedback (colored dots, emoji)
   - Location: `lib/widgets/health_check_in_widget.dart`

2. **SymptomTrackingWidget**
   - Expandable section
   - Symptom dropdown + custom input
   - Severity slider
   - Duration buttons
   - What helps checkboxes
   - Location: `lib/widgets/symptom_tracking_widget.dart`

3. **HealthEntryCard**
   - Replaces current entry card
   - Shows check-in summary (colored bars)
   - Shows symptoms if tracked
   - Shows journal text (truncated)
   - Shows health tags
   - Location: `lib/components/health_entry_card.dart`

4. **PatternInsightCard**
   - Shows detected pattern
   - Co-occurrence list
   - Suggestions
   - Actions (dismiss, bookmark, get help)
   - Location: `lib/components/pattern_insight_card.dart`

5. **HealthTagChip**
   - Similar to InteractiveTagChip but health-themed
   - Category-specific colors
   - Location: `lib/components/health_tag_chip.dart`

---

## 10. IMPLEMENTATION PHASES

### Phase 1: Models & Services (Foundation)
- [ ] Create `HealthJournalEntry` model
- [ ] Create `HealthCheckIn` model
- [ ] Create `SymptomTracking` model
- [ ] Create `HealthTag` model
- [ ] Create `PatternInsight` model
- [ ] Create `HealthJournalService`
- [ ] Create `HealthTaggingService` (keyword-based first)
- [ ] Update AppState to store health entries

### Phase 2: UI Components
- [ ] Create `HealthCheckInWidget`
- [ ] Create `SymptomTrackingWidget`
- [ ] Create `HealthEntryCard`
- [ ] Create `HealthTagChip`
- [ ] Update `JournalPage` to use new widgets

### Phase 3: Pattern Detection
- [ ] Create `PatternDetectionService`
- [ ] Create `PatternInsightCard`
- [ ] Add pattern detection to journal flow
- [ ] Show pattern insights proactively

### Phase 4: Migration & Polish
- [ ] Add tab switcher for legacy entries
- [ ] Show migration banner
- [ ] Update entry history view
- [ ] Add search/filter by health tags
- [ ] Performance optimization

---

## 11. EXAMPLE USER FLOW

### Day 1: First Health Journal Entry
1. User opens Journal page
2. Sees new health-focused interface
3. Fills check-in sliders (30 seconds)
   - Energy: ●●○○○ (2/5)
   - Pain: ●○○○○ (1/5)
   - Sleep: ●●○○○ (2/5)
   - Mood: ●●○○○ (2/5)
   - Stress: ●●●●○ (4/5)
   - Anxiety: ●●●○○ (3/5)
4. Skips symptom tracking
5. Writes free-form: "Exhausted today. Work was overwhelming and I barely slept."
6. Taps "Save Entry"
7. AI auto-tags: #fatigue #work-stress #insomnia
8. Entry saved, returns to timeline

### Day 5: Pattern Detected
1. User has journaled 5 times
2. Mentioned "headache" 4 times
3. Pattern detection runs automatically
4. Detects: headache + high stress (4/4 times)
5. Shows pattern insight card:
   ```
   💡 PATTERN DETECTED
   You've mentioned headaches 4 times this week,
   always on high-stress days.

   What might help:
   • Try stress breaks during workday
   • Keep water + snacks nearby
   • Talk to GP if continues
   ```
6. User taps "Get more help"
7. Navigates to Ask page with pre-filled question:
   "I've been having headaches when I'm stressed. What can I do?"

---

## 12. OPEN QUESTIONS FOR DISCUSSION

1. **AI Tagging Privacy:**
   - Use keyword matching only (simpler, privacy-first)?
   - OR ask permission to use AI (better accuracy)?

2. **Pattern Detection Frequency:**
   - Run daily in background?
   - Run when user opens journal?
   - Run on-demand only?

3. **Check-In Requirements:**
   - Make check-in required for journal entry?
   - OR fully optional (journal-only entries allowed)?

4. **Legacy Entry Display:**
   - Separate tab?
   - Integrated timeline with type indicator?
   - Hide completely (archive)?

5. **Symptom Tracking:**
   - Always visible (encourage tracking)?
   - Collapsed by default (optional)?
   - Prompt based on check-in data (e.g., high pain → suggest symptom tracking)?

---

## 13. SUCCESS METRICS

After implementation, measure:
- **Adoption:** % of users who use health journal vs wellness journal
- **Completion rate:** % of entries with check-in data vs journal-only
- **Pattern insights:** How many patterns detected per user
- **Engagement:** Pattern insight click-through rate
- **Value:** Do users find pattern insights helpful? (survey)

---

## SUMMARY

This design transforms the journal from **mental wellness tracking** to **comprehensive health navigation** while:

✅ Preserving core journaling functionality (free-form text)
✅ Adding structured health check-ins (fast, 1-2 minutes)
✅ Optional symptom tracking (for specific concerns)
✅ Smart health tagging (symptoms, barriers, context)
✅ Pattern recognition (links symptoms to life factors)
✅ Maintaining privacy (local-first, no forced AI)
✅ Supporting migration (old entries preserved)

**Next Step:** Review this design, answer open questions, then implement Phase 1 (Models & Services).
