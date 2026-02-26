import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/complexity_profile.dart';
import '../models/health_journal_model.dart';
import '../design_system/design_system.dart';

class ComplexityTestPage extends StatelessWidget {
  const ComplexityTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complexity Profile Tester'),
        backgroundColor: StarboundColors.deepSpace,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final currentLevel = appState.complexityProfile;
          final messaging = appState.getCheckInMessaging();
          final adaptedChoices = appState.getProfileAdaptedChoices();
          final adaptedChances = appState.getProfileAdaptedChances();
          final activePersona = _findActivePersona(appState);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Level Display
                Card(
                  color: _getLevelColor(currentLevel),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Level: ${_getLevelName(currentLevel)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getLevelDescription(currentLevel),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Level Switch Buttons
                const Text(
                  'Switch Complexity Level:',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  children: ComplexityLevel.values.map((level) {
                    final isActive = level == currentLevel;
                    return ElevatedButton(
                      onPressed: () {
                        // Add debug output to console
                        print(
                            '🔄 Switching complexity level from ${_getLevelName(currentLevel)} to ${_getLevelName(level)}');
                        print(
                            '📊 Max habits will change from ${_getMaxItems(currentLevel)} to ${_getMaxItems(level)}');
                        print(
                            '⏰ Nudge frequency will change from ${_getNudgeFrequency(currentLevel)} to ${_getNudgeFrequency(level)}');

                        appState.updateComplexityProfile(level);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isActive ? _getLevelColor(level) : Colors.grey[300],
                        foregroundColor:
                            isActive ? Colors.white : Colors.black87,
                      ),
                      child: Text(_getLevelName(level)),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Persona Presets (Same Context, Different Capacity):',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Apply one persona, then ask the same question in Ask. '
                          'These presets keep context similar so differences mostly come from complexity level.',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        if (activePersona != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Active persona: ${activePersona.label}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        ..._testPersonas.map(
                          (persona) => _buildPersonaCard(
                            context,
                            appState,
                            persona,
                            isActive: activePersona?.id == persona.id,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blueGrey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Use this same question to compare:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '"$_comparisonQuestion"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      const ClipboardData(
                                          text: _comparisonQuestion),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Comparison question copied'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy question'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Messaging Effects
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UI Messaging Effects:',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        _buildMessageItem(
                            'Choice Title', messaging['choiceTitle'] ?? ''),
                        _buildMessageItem(
                            'Chance Title', messaging['chanceTitle'] ?? ''),
                        _buildMessageItem(
                            'Encouragement', messaging['encouragement'] ?? ''),
                        _buildMessageItem(
                            'Completion', messaging['completion'] ?? ''),
                        _buildMessageItem(
                            'Save Button', appState.getSaveButtonText()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Habit Filtering Effects
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Habit Filtering Effects:',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text('Choices shown: ${adaptedChoices.length} habits',
                            style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: adaptedChoices.keys
                              .map((key) => Chip(
                                    label: Text(key,
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.green[100],
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        Text('Chances shown: ${adaptedChances.length} items',
                            style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: adaptedChances.keys
                              .map((key) => Chip(
                                    label: Text(key,
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.orange[100],
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Behavioral Settings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Behavioral Settings:',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        _buildBehaviorItem('Nudge Frequency',
                            _getNudgeFrequency(currentLevel)),
                        _buildBehaviorItem('Max Items Shown',
                            _getMaxItems(currentLevel).toString()),
                        _buildBehaviorItem(
                            'Priority Focus', _getPriorityFocus(currentLevel)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Test Current Habits (if any)
                if (appState.habits.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Habits:',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          ...appState.habits.entries
                              .map((entry) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Text(entry.key,
                                                style: const TextStyle(
                                                    color: Colors.black87))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getHabitValueColor(
                                                entry.value),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            entry.value ?? 'none',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Quick Habit Testing
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Habit Testing:',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add some test habits to see how complexity affects the check-in experience:',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildQuickHabitButton(
                                appState, 'hydration', 'good'),
                            _buildQuickHabitButton(appState, 'sleep', 'poor'),
                            _buildQuickHabitButton(
                                appState, 'movement', 'excellent'),
                            _buildQuickHabitButton(appState, 'mood', 'okay'),
                            _buildQuickHabitButton(appState, 'stress', 'high'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            appState.clearHabits();
                            print('🗑️ Cleared all test habits');
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[100],
                            foregroundColor: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  _ComplexityTestPersona? _findActivePersona(AppState appState) {
    final currentName = appState.userName.trim().toLowerCase();
    for (final persona in _testPersonas) {
      if (appState.complexityProfile == persona.level &&
          currentName == persona.userName.toLowerCase()) {
        return persona;
      }
    }
    return null;
  }

  Widget _buildPersonaCard(
    BuildContext context,
    AppState appState,
    _ComplexityTestPersona persona, {
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  persona.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Applied',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            persona.summary,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            'Barriers: ${persona.barriers.join(', ')}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            'Interests: ${persona.healthInterests.join(', ')}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            'Seeded habits: ${persona.seededHabits.length} • Seeded journal entry: 1',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _applyPersona(context, appState, persona);
              },
              icon: const Icon(Icons.person, size: 16),
              label: const Text('Apply Persona'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isActive ? Colors.green.shade600 : Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyPersona(
    BuildContext context,
    AppState appState,
    _ComplexityTestPersona persona,
  ) async {
    await appState.updateComplexityProfile(persona.level);
    await appState.updateUserName(persona.userName);
    await appState.setHealthNavigationProfile(
      userName: persona.userName,
      neighborhood: persona.neighborhood,
      languages: persona.languages,
      barriers: persona.barriers,
      healthInterests: persona.healthInterests,
      workSchedule: persona.workSchedule,
      checkInFrequency: persona.checkInFrequency,
      additionalNotes: persona.additionalNotes,
    );

    await appState.clearHabits();
    for (final habit in persona.seededHabits.entries) {
      await appState.updateHabit(habit.key, habit.value);
    }

    for (final candidate in _testPersonas) {
      await appState.deleteHealthJournalEntry('persona_${candidate.id}_seed');
    }

    final now = DateTime.now();
    final seededSymptoms = <SymptomTracking>[];
    if (persona.seedSymptom != null) {
      final symptom = persona.seedSymptom!;
      seededSymptoms.add(
        SymptomTracking(
          id: 'persona_${persona.id}_symptom',
          symptomType: symptom.symptomType,
          severity: symptom.severity,
          duration: symptom.duration,
          whatHelps: symptom.whatHelps,
          notes: symptom.notes,
          createdAt: now,
        ),
      );
    }

    await appState.saveHealthJournalEntry(
      id: 'persona_${persona.id}_seed',
      checkIn: HealthCheckIn(
        energy: persona.seedCheckIn.energy,
        painLevel: persona.seedCheckIn.painLevel,
        sleepQuality: persona.seedCheckIn.sleepQuality,
        mood: persona.seedCheckIn.mood,
        stressLevel: persona.seedCheckIn.stressLevel,
        anxietyLevel: persona.seedCheckIn.anxietyLevel,
        ateRegularMeals: persona.seedCheckIn.ateRegularMeals,
        majorStressors: persona.seedCheckIn.majorStressors,
      ),
      symptoms: seededSymptoms,
      journalText: persona.seedJournalText,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Applied ${persona.label} with seeded profile data. Ask the comparison question in Ask.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildMessageItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelName(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return 'Stable';
      case ComplexityLevel.trying:
        return 'Trying';
      case ComplexityLevel.overloaded:
        return 'Overloaded';
      case ComplexityLevel.survival:
        return 'Survival';
    }
  }

  String _getLevelDescription(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return "Good capacity for building new habits and growth";
      case ComplexityLevel.trying:
        return "Navigating challenges but have moments of stability";
      case ComplexityLevel.overloaded:
        return "Dealing with significant stress, limited capacity";
      case ComplexityLevel.survival:
        return "Survival mode, just getting through each day";
    }
  }

  Color _getLevelColor(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return Colors.green;
      case ComplexityLevel.trying:
        return Colors.blue;
      case ComplexityLevel.overloaded:
        return Colors.orange;
      case ComplexityLevel.survival:
        return Colors.red;
    }
  }

  String _getNudgeFrequency(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return "Every 8 hours";
      case ComplexityLevel.trying:
        return "Every 12 hours";
      case ComplexityLevel.overloaded:
        return "Once daily";
      case ComplexityLevel.survival:
        return "Every 2 days";
    }
  }

  int _getMaxItems(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return 12;
      case ComplexityLevel.trying:
        return 8;
      case ComplexityLevel.overloaded:
        return 5;
      case ComplexityLevel.survival:
        return 3;
    }
  }

  String _getPriorityFocus(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return "Full range, growth-oriented";
      case ComplexityLevel.trying:
        return "Moderate, flexible approach";
      case ComplexityLevel.overloaded:
        return "Essential habits only";
      case ComplexityLevel.survival:
        return "Absolute minimum";
    }
  }

  Widget _buildQuickHabitButton(
      AppState appState, String habitKey, String habitValue) {
    return ElevatedButton(
      onPressed: () {
        appState.updateHabit(habitKey, habitValue);
        print('✅ Set $habitKey to $habitValue');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _getHabitValueColor(habitValue),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: Text(
        '$habitKey: $habitValue',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Color _getHabitValueColor(String? value) {
    switch (value?.toLowerCase()) {
      case 'good':
      case 'excellent':
      case 'high':
        return Colors.green;
      case 'okay':
      case 'moderate':
        return Colors.orange;
      case 'poor':
      case 'low':
      case 'none':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

const String _comparisonQuestion =
    'I have had poor sleep and daily headaches this week. What should I do first?';

const List<_ComplexityTestPersona> _testPersonas = [
  _ComplexityTestPersona(
    id: 'maya_stable',
    label: 'Maya - Stable',
    summary:
        'High capacity, organized routine, and support at home. Can handle fuller plans.',
    userName: 'Maya',
    level: ComplexityLevel.stable,
    neighborhood: 'North Shore Sydney',
    languages: ['english', 'mandarin'],
    barriers: ['time'],
    healthInterests: ['sleep', 'nutrition', 'exercise'],
    workSchedule: 'regular_day',
    checkInFrequency: 'weekly',
    additionalNotes: 'Strong family support and predictable weekly schedule.',
    seededHabits: {
      'sleep': 'okay',
      'hydration': 'good',
      'movement': 'excellent',
      'stress': 'moderate',
    },
    seedCheckIn: _PersonaSeedCheckIn(
      energy: 4,
      painLevel: 1,
      sleepQuality: 3,
      mood: 4,
      stressLevel: 2,
      anxietyLevel: 2,
      ateRegularMeals: MealStatus.yes,
      majorStressors: 'Busy work sprint this week',
    ),
    seedJournalText:
        'Sleep has been lighter this week but I still have enough energy to plan and follow through.',
  ),
  _ComplexityTestPersona(
    id: 'jordan_trying',
    label: 'Jordan - Trying',
    summary:
        'Moderate strain and variable energy. Needs practical steps with flexibility.',
    userName: 'Jordan',
    level: ComplexityLevel.trying,
    neighborhood: 'Western Sydney',
    languages: ['english'],
    barriers: ['cost', 'time', 'transportation'],
    healthInterests: ['mental_health', 'blood_pressure'],
    workSchedule: 'irregular',
    checkInFrequency: 'weekly',
    additionalNotes: 'Work hours change weekly and commute is long.',
    seededHabits: {
      'sleep': 'poor',
      'hydration': 'okay',
      'movement': 'low',
      'stress': 'high',
    },
    seedCheckIn: _PersonaSeedCheckIn(
      energy: 3,
      painLevel: 2,
      sleepQuality: 2,
      mood: 3,
      stressLevel: 4,
      anxietyLevel: 3,
      ateRegularMeals: MealStatus.some,
      majorStressors: 'Shift changes and transport delays',
    ),
    seedJournalText:
        'I am trying to stay on top of things, but poor sleep and commute stress are making consistency hard.',
  ),
  _ComplexityTestPersona(
    id: 'priya_overloaded',
    label: 'Priya - Overloaded',
    summary: 'High stress with low bandwidth and competing responsibilities.',
    userName: 'Priya',
    level: ComplexityLevel.overloaded,
    neighborhood: 'South Western Sydney',
    languages: ['english', 'hindi'],
    barriers: ['childcare', 'time', 'cost'],
    healthInterests: ['diabetes', 'mental_health'],
    workSchedule: 'multiple_jobs',
    checkInFrequency: 'weekly',
    additionalNotes:
        'Often skipping meals and appointments due to childcare and work load.',
    seededHabits: {
      'sleep': 'poor',
      'hydration': 'low',
      'movement': 'none',
      'stress': 'high',
      'meals': 'none',
    },
    seedCheckIn: _PersonaSeedCheckIn(
      energy: 2,
      painLevel: 3,
      sleepQuality: 2,
      mood: 2,
      stressLevel: 5,
      anxietyLevel: 4,
      ateRegularMeals: MealStatus.no,
      majorStressors: 'Childcare gaps and double shifts',
    ),
    seedSymptom: _PersonaSeedSymptom(
      symptomType: 'headache',
      severity: 4,
      duration: SymptomDuration.multipleDays,
      whatHelps: ['rest', 'medication'],
      notes: 'Headaches worsen late afternoon after long shifts.',
    ),
    seedJournalText:
        'I feel stretched thin and have had persistent headaches by the end of each day.',
  ),
  _ComplexityTestPersona(
    id: 'sam_survival',
    label: 'Sam - Survival',
    summary:
        'Near-zero capacity with multiple access barriers; needs tiny immediate steps.',
    userName: 'Sam',
    level: ComplexityLevel.survival,
    neighborhood: 'Regional NSW',
    languages: ['english', 'arabic'],
    barriers: ['transportation', 'cost', 'navigation', 'language'],
    healthInterests: ['general_health', 'chronic_illness'],
    workSchedule: 'night_shift',
    checkInFrequency: 'weekly',
    additionalNotes:
        'No car currently, limited support, and often exhausted after night shifts.',
    seededHabits: {
      'sleep': 'poor',
      'hydration': 'low',
      'movement': 'none',
      'stress': 'high',
      'energy': 'low',
    },
    seedCheckIn: _PersonaSeedCheckIn(
      energy: 1,
      painLevel: 4,
      sleepQuality: 1,
      mood: 1,
      stressLevel: 5,
      anxietyLevel: 5,
      ateRegularMeals: MealStatus.no,
      majorStressors: 'Housing instability and transport barriers',
    ),
    seedSymptom: _PersonaSeedSymptom(
      symptomType: 'fatigue',
      severity: 5,
      duration: SymptomDuration.multipleDays,
      whatHelps: ['sleep'],
      notes: 'Severe fatigue most days and cannot keep up with errands.',
    ),
    seedJournalText:
        'I am mostly just trying to get through each day and it feels hard to do even basic tasks.',
  ),
];

class _ComplexityTestPersona {
  final String id;
  final String label;
  final String summary;
  final String userName;
  final ComplexityLevel level;
  final String neighborhood;
  final List<String> languages;
  final List<String> barriers;
  final List<String> healthInterests;
  final String workSchedule;
  final String checkInFrequency;
  final String? additionalNotes;
  final Map<String, String> seededHabits;
  final _PersonaSeedCheckIn seedCheckIn;
  final _PersonaSeedSymptom? seedSymptom;
  final String seedJournalText;

  const _ComplexityTestPersona({
    required this.id,
    required this.label,
    required this.summary,
    required this.userName,
    required this.level,
    required this.neighborhood,
    required this.languages,
    required this.barriers,
    required this.healthInterests,
    required this.workSchedule,
    required this.checkInFrequency,
    this.additionalNotes,
    required this.seededHabits,
    required this.seedCheckIn,
    this.seedSymptom,
    required this.seedJournalText,
  });
}

class _PersonaSeedCheckIn {
  final int energy;
  final int painLevel;
  final int sleepQuality;
  final int mood;
  final int stressLevel;
  final int anxietyLevel;
  final MealStatus ateRegularMeals;
  final String majorStressors;

  const _PersonaSeedCheckIn({
    required this.energy,
    required this.painLevel,
    required this.sleepQuality,
    required this.mood,
    required this.stressLevel,
    required this.anxietyLevel,
    required this.ateRegularMeals,
    required this.majorStressors,
  });
}

class _PersonaSeedSymptom {
  final String symptomType;
  final int severity;
  final SymptomDuration duration;
  final List<String> whatHelps;
  final String notes;

  const _PersonaSeedSymptom({
    required this.symptomType,
    required this.severity,
    required this.duration,
    required this.whatHelps,
    required this.notes,
  });
}
