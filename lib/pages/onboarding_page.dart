import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../design_system/design_system.dart';
import '../models/complexity_profile.dart';
import '../providers/app_state.dart';
import '../services/error_service.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final Map<String, dynamic> _responses = {}; // Changed to dynamic for multi-select
  bool _isLoading = false;
  String _futureNote = '';

  late final Map<String, OnboardingQuestionDefinition> _questionsById;
  late final List<_OnboardingStep> _steps;
  late final AnimationController _introController;
  late final Animation<double> _progressOpacity;
  late final Animation<Offset> _progressOffset;

  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();

    final sections = [
      onboardingSectionA,
      onboardingSectionB,
      onboardingSectionC,
      onboardingSectionD,
    ];

    _questionsById = {
      for (final section in sections)
        for (final question in section.questions) question.id: question,
    };

    _introController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    );

    _progressOffset = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
      ),
    );

    _steps = [
      const _OnboardingStep(
        id: 'step_about_you',
        title: 'About You',
        description: 'Help us get to know you.',
        summary: 'Your info helps us find the right resources for your area.',
        questionIds: ['A1', 'A2', 'A3'],
      ),
      const _OnboardingStep(
        id: 'step_barriers',
        title: 'Understanding Your Situation',
        description: 'What makes accessing healthcare hard?',
        summary: 'Knowing your barriers helps us match you with accessible options.',
        questionIds: ['B1'],
      ),
      const _OnboardingStep(
        id: 'step_health_focus',
        title: 'Health Focus',
        description: 'What health topics matter to you right now?',
        summary: 'This is optional, but helps us prioritize relevant information.',
        questionIds: ['C1', 'C2'],
      ),
      const _OnboardingStep(
        id: 'step_preferences',
        title: 'Your Preferences',
        description: 'How should we stay in touch?',
        summary: 'We will check in at your preferred pace.',
        questionIds: ['D1', 'D2'],
      ),
    ];

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  double get _progressValue {
    final totalItems = _questionsById.length + 1; // include optional note
    if (totalItems == 0) return 0;

    final answeredCount = _responses.length + (_futureNote.trim().isNotEmpty ? 1 : 0);
    return (answeredCount / totalItems).clamp(0, 1);
  }



  bool _isQuestionAnswered(String questionId) => _responses.containsKey(questionId);

  bool _isStepComplete(_OnboardingStep step) {
    return step.questionIds.every(_isQuestionAnswered);
  }





  IconData _iconFor(String? iconKey) {
    switch (iconKey) {
      case 'user':
      case 'user-circle':
        return Icons.person_outline;
      case 'battery-full':
        return Icons.battery_full;
      case 'battery-three-quarters':
        return Icons.battery_4_bar;
      case 'battery-half':
        return Icons.battery_3_bar;
      case 'battery-quarter':
        return Icons.battery_2_bar;
      case 'target':
        return Icons.track_changes;
      case 'leaf':
        return Icons.eco_outlined;
      case 'heart':
        return Icons.favorite_outline;
      case 'lifebuoy':
        return Icons.health_and_safety_outlined;
      case 'book-open':
        return Icons.menu_book_outlined;
      case 'chart-bar':
        return Icons.bar_chart;
      case 'wind':
        return Icons.air;
      case 'calendar-day':
        return Icons.today_outlined;
      case 'flag':
        return Icons.flag_outlined;
      case 'compass':
        return Icons.explore_outlined;
      case 'utensils':
        return Icons.restaurant_outlined;
      case 'bed':
        return Icons.bed_outlined;
      case 'shower':
        return Icons.shower_outlined;
      case 'rotate-ccw':
        return Icons.refresh;
      case 'hourglass':
        return Icons.hourglass_bottom;
      case 'triangle-alert':
        return Icons.warning_amber_outlined;
      case 'brain':
        return Icons.psychology_outlined;
      case 'clock':
        return Icons.access_time;
      case 'ban':
        return Icons.block;
      case 'sliders':
        return Icons.tune;
      case 'droplet':
        return Icons.water_drop_outlined;
      case 'explosion':
        return Icons.flash_on_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'shuffle':
        return Icons.shuffle;
      case 'warning':
        return Icons.warning;
      case 'users':
        return Icons.groups_outlined;
      case 'user-plus':
        return Icons.group_add_outlined;
      case 'user-x':
        return Icons.person_off_outlined;
      case 'steering-wheel':
        return Icons.sports_motorsports;
      case 'adjust':
        return Icons.adjust;
      case 'lock':
        return Icons.lock_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'stethoscope':
        return Icons.monitor_heart_outlined;
      case 'heart-handshake':
        return Icons.diversity_3;
      case 'calendar-check':
        return Icons.event_available_outlined;
      case 'sunrise':
        return Icons.wb_twilight;
      case 'calendar-range':
        return Icons.date_range;
      case 'calendar':
        return Icons.calendar_month;
      case 'bell-off':
        return Icons.notifications_off_outlined;
      default:
        return Icons.brightness_6_outlined;
    }
  }

  void _selectOption(String questionId, String optionId) {
    final question = _questionsById[questionId];
    if (question == null) return;

    setState(() {
      if (question.isMultiSelect) {
        // Multi-select: toggle the option in the list
        final currentSelections = _responses[questionId] as List<String>? ?? [];
        if (currentSelections.contains(optionId)) {
          currentSelections.remove(optionId);
        } else {
          currentSelections.add(optionId);
        }
        _responses[questionId] = currentSelections;
      } else {
        // Single select: replace the value
        _responses[questionId] = optionId;
      }
    });
  }

  void _skipCurrentStep() {
    _goToStep((_currentStepIndex + 1).clamp(0, _steps.length - 1));
  }

  void _goToStep(int index) {
    setState(() {
      _currentStepIndex = index;
    });
  }

  void _goToPreviousStep() {
    if (_currentStepIndex > 0) {
      _goToStep(_currentStepIndex - 1);
    }
  }

  void _goToNextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _goToStep(_currentStepIndex + 1);
    }
  }

  Future<void> _completeOnboarding() async {
    print('🎯 Starting onboarding completion...');
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = context.read<AppState>();

      // Extract data from responses
      String userName = 'Explorer';
      String? neighborhood;
      List<String> languages = [];
      List<String> barriers = [];
      List<String> healthInterests = [];
      String? workSchedule;
      String checkInFrequency = 'weekly';
      String? additionalNotes;

      // Parse responses
      final a1Response = _responses['A1'];
      if (a1Response == 'a1_custom') {
        // TODO: Show dialog to enter custom name
        userName = 'Explorer';
      }

      final a2Response = _responses['A2'];
      if (a2Response != null && a2Response != 'a2_prefer_not') {
        // Extract neighborhood from response ID
        neighborhood = (a2Response as String).replaceAll('a2_', '').replaceAll('_', ' ');
      }

      final a3Response = _responses['A3'];
      if (a3Response is List<String>) {
        languages = a3Response.map((id) => id.replaceAll('a3_', '')).toList();
      }

      final b1Response = _responses['B1'];
      if (b1Response is List<String>) {
        barriers = b1Response.map((id) => id.replaceAll('b1_', '')).toList();
      }

      final c1Response = _responses['C1'];
      if (c1Response is List<String>) {
        healthInterests = c1Response.map((id) => id.replaceAll('c1_', '')).toList();
      }

      final c2Response = _responses['C2'];
      if (c2Response != null && c2Response != 'c2_prefer_not') {
        workSchedule = (c2Response as String).replaceAll('c2_', '');
      }

      final d1Response = _responses['D1'];
      if (d1Response != null) {
        checkInFrequency = (d1Response as String).replaceAll('d1_', '');
      }

      final d2Response = _responses['D2'];
      if (d2Response is String && d2Response.trim().isNotEmpty) {
        additionalNotes = d2Response.trim();
      }

      print('📊 Creating health navigation profile...');
      print('  - userName: $userName');
      print('  - neighborhood: $neighborhood');
      print('  - languages: $languages');
      print('  - barriers: $barriers');
      print('  - healthInterests: $healthInterests');
      print('  - workSchedule: $workSchedule');
      print('  - checkInFrequency: $checkInFrequency');

      await appState.setHealthNavigationProfile(
        userName: userName,
        neighborhood: neighborhood,
        languages: languages,
        barriers: barriers,
        healthInterests: healthInterests,
        workSchedule: workSchedule,
        checkInFrequency: checkInFrequency,
        additionalNotes: additionalNotes,
      );
      print('✅ Health navigation profile created');

      await appState.setOnboardingComplete(true);
      print('✅ Onboarding marked as complete');

      if (!mounted) return;
      widget.onComplete();
      print('🎉 Onboarding completion callback executed');
    } catch (e, stackTrace) {
      print('❌ Error completing onboarding: $e');
      print('Stack trace: $stackTrace');
      ErrorService().handleError(
        e,
        stackTrace: stackTrace,
        context: 'Onboarding completion',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went sideways. Please try again soon.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStepIndex];
    final progressValue = _progressValue;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyN):
            const _NextStepIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS):
            const _SkipStepIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NextStepIntent: CallbackAction<_NextStepIntent>(
            onInvoke: (intent) {
              if (_currentStepIndex < _steps.length - 1) {
                _goToNextStep();
              }
              return null;
            },
          ),
          _SkipStepIntent: CallbackAction<_SkipStepIntent>(
            onInvoke: (intent) {
              if (_currentStepIndex < _steps.length - 1) {
                _skipCurrentStep();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: StarboundColors.deepSpace,
            body: Stack(
              children: [
                _buildAmbientBackground(),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeader(),
                                    const SizedBox(height: 36),
                                    _OnboardingCard(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FadeTransition(
                                            opacity: _progressOpacity,
                                            child: SlideTransition(
                                              position: _progressOffset,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildProgressPanel(progressValue),
                                                  const SizedBox(height: 8),
                                                  _buildMissionSummary(currentStep.summary),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 300),
                                            switchInCurve: Curves.easeInOut,
                                            child: _buildStepContent(currentStep),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                StarboundColors.deepSpace,
                Color(0xFF1B0B4B),
                Color(0xFF2E0B5C),
              ],
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0.85, -0.9),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        StarboundColors.stellarAqua.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(-0.8, 0.9),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        StarboundColors.cosmicPink.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
              ...List.generate(40, (index) {
                final alignment = Alignment(((index % 8) - 4) / 5.0, ((index / 8).floor() - 2) / 4.0);
                return Align(
                  alignment: alignment,
                  child: Icon(
                    Icons.blur_on,
                    size: 6,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMissionSummary(String? summary) {
    if (summary == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: StarboundColors.cosmicPink.withValues(alpha: 0.1),
        border: Border.all(
          color: StarboundColors.cosmicPink.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: StarboundColors.cosmicPink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionLog() {
    final entries = <Widget>[];
    final completedModules = _steps.where(_isStepComplete).length;
    final totalModules = _steps.length;
    for (var i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      final answered = step.questionIds.where(_isQuestionAnswered).length;
      final total = step.questionIds.length;
      final isCurrent = i == _currentStepIndex;
      final isComplete = answered == total;
      entries.add(_buildMissionLogRow(step.title, answered, total, isCurrent, isComplete, i));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: StarboundColors.starlightBlue,
              ),
              const SizedBox(width: 8),
              const Text(
                'Mission log',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$completedModules of $totalModules complete',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entries,
        ],
      ),
    );
  }

  Widget _buildMissionLogRow(String title, int answered, int total, bool isCurrent, bool isComplete, int index) {
    final palette = [
      StarboundColors.nebulaPurple,
      StarboundColors.cosmicPink,
      StarboundColors.stellarAqua,
      StarboundColors.starlightBlue,
      StarboundColors.solarOrange,
      StarboundColors.stellarYellow,
    ];
    final tone = palette[index % palette.length];
    final color = isComplete
        ? tone
        : (isCurrent ? tone.withValues(alpha: 0.75) : Colors.white54);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: isCurrent ? 0.06 : 0.02),
        border: Border.all(
          color: color.withValues(alpha: isCurrent ? 0.45 : 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$answered/$total',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/Logo.png',
          height: 72,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 28),
        const Text(
          'Welcome to Starbound',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Let’s make this yours — one small step at a time.',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }







  Widget _buildProgressPanel(double progressValue) {
    final totalSteps = _steps.length;
    final completedSteps = _steps.where(_isStepComplete).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                StarboundColors.cosmicBeige.withValues(alpha: 0.18),
                StarboundColors.stellarAqua.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(
              color: StarboundColors.stellarAqua.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.dashboard_customize_outlined,
                        size: 16,
                        color: StarboundColors.stellarAqua,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Mission status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(progressValue * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(totalSteps, (index) {
                  final palette = [
                    StarboundColors.nebulaPurple,
                    StarboundColors.cosmicPink,
                    StarboundColors.stellarAqua,
                    StarboundColors.starlightBlue,
                    StarboundColors.solarOrange,
                    StarboundColors.stellarYellow,
                  ];
                  final tone = palette[index % palette.length];
                  final step = _steps[index];
                  final isComplete = _isStepComplete(step);
                  final isCurrent = index == _currentStepIndex;
                  return Padding(
                    padding: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isComplete
                            ? tone
                            : (isCurrent
                                ? tone.withValues(alpha: 0.75)
                                : Colors.white.withValues(alpha: 0.16)),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: tone.withValues(alpha: 0.55),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),


      ],
    );
  }





  Widget _buildStepContent(_OnboardingStep step) {
    final questions = step.questionIds
        .map((id) => _questionsById[id])
        .whereType<OnboardingQuestionDefinition>()
        .toList();

    return Column(
      key: ValueKey(step.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (step.description != null) ...[
          const SizedBox(height: 6),
          Text(
            step.description!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
        const SizedBox(height: 18),
        for (final question in questions) ...[
          _buildQuestion(question),
          const SizedBox(height: 18),
        ],
        if (step.includeNote) ...[
          _buildNoteField(),
          const SizedBox(height: 12),
          const Text(
            'Optional — leave a line for your future self or a reminder for us.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            if (_currentStepIndex > 0)
              OutlinedButton.icon(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: StarboundColors.cosmicBeige,
                  side: BorderSide(
                    color: StarboundColors.cosmicBeige.withValues(alpha: 0.6),
                  ),
                ),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Back'),
              ),
            if (_currentStepIndex > 0) const SizedBox(width: 12),
            TextButton(
              onPressed: _skipCurrentStep,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('Skip for now (Shift+S)'),
            ),
            const Spacer(),
            if (_currentStepIndex < _steps.length - 1)
              ElevatedButton.icon(
                onPressed: _goToNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StarboundColors.stellarAqua,
                  foregroundColor: StarboundColors.deepSpace,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  'Next (Shift+N)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestion(OnboardingQuestionDefinition question) {
    final response = _responses[question.id];
    final profileSignal = question.profileSignal;

    // Handle text area questions specially
    if (question.isTextArea) {
      return _buildTextAreaQuestion(question);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconFor(question.icon),
              color: StarboundColors.cosmicPink,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (profileSignal.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      profileSignal,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: question.options.map((option) {
            final bool isSelected;
            if (question.isMultiSelect) {
              final selections = response as List<String>? ?? [];
              isSelected = selections.contains(option.id);
            } else {
              isSelected = option.id == response;
            }

            return _buildOptionChip(
              questionId: question.id,
              option: option,
              isSelected: isSelected,
              isMultiSelect: question.isMultiSelect,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextAreaQuestion(OnboardingQuestionDefinition question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconFor(question.icon),
              color: StarboundColors.cosmicPink,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (question.profileSignal.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      question.profileSignal,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildNoteField(questionId: question.id),
      ],
    );
  }

  Widget _buildOptionChip({
    required String questionId,
    required OnboardingOptionDefinition option,
    required bool isSelected,
    bool isMultiSelect = false,
  }) {
    final IconData? optionIcon =
        option.icon != null ? _iconFor(option.icon) : null;

    return _AnswerChip(
      label: option.label,
      icon: optionIcon,
      isSelected: isSelected,
      isMultiSelect: isMultiSelect,
      onPressed: () => _selectOption(questionId, option.id),
    );
  }

  Widget _buildNoteField({String? questionId}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: StarboundColors.cosmicBeige.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        minLines: 3,
        maxLines: 5,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Leave a note for future you (optional)',
          hintStyle: TextStyle(color: Colors.white54),
        ),
        onChanged: (value) => setState(() {
          if (questionId != null) {
            _responses[questionId] = value;
          } else {
            _futureNote = value;
          }
        }),
      ),
    );
  }

  Widget _buildFooter() {
    final allComplete = _steps.every(_isStepComplete);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allComplete)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  StarboundColors.stellarAqua.withValues(alpha: 0.18),
                  StarboundColors.cosmicPink.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: StarboundColors.stellarAqua.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.rocket_launch_outlined, size: 18, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You\'re all set. Ready to enter Starbound whenever you are.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All set — you can always return to onboarding later.'),
                backgroundColor: Colors.black54,
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white70,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: const Text('Come back later'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _completeOnboarding,
          style: ElevatedButton.styleFrom(
            backgroundColor: StarboundColors.stellarAqua,
            foregroundColor: StarboundColors.deepSpace,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      StarboundColors.deepSpace,
                    ),
                  ),
                )
              : const Text(
                  'Start Your Journey — Find Health Resources That Work For You',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}

class _AnswerChip extends StatefulWidget {
  const _AnswerChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.icon,
    this.isMultiSelect = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isMultiSelect;

  @override
  State<_AnswerChip> createState() => _AnswerChipState();
}

class _AnswerChipState extends State<_AnswerChip> with SingleTickerProviderStateMixin {
  bool _showFocusHighlight = false;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    if (widget.isSelected) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnswerChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isSelected
        ? StarboundColors.stellarAqua
        : _showFocusHighlight
            ? StarboundColors.stellarAqua.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.2);
    final Color backgroundColor = widget.isSelected
        ? StarboundColors.cosmicBeige.withValues(alpha: 0.45)
        : StarboundColors.cosmicBeige.withValues(alpha: 0.15);
    final Color textColor =
        widget.isSelected ? StarboundColors.deepSpace : Colors.white;

    return FocusableActionDetector(
      onShowFocusHighlight: (value) {
        if (mounted) {
          setState(() => _showFocusHighlight = value);
        }
      },
      onShowHoverHighlight: (_) {},
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.enter): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: Semantics(
        label: widget.label,
        button: true,
        selected: widget.isSelected,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(18),
              focusColor: StarboundColors.stellarAqua.withValues(alpha: 0.2),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: backgroundColor,
                      border: Border.all(color: borderColor, width: 1.8),
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: StarboundColors.stellarAqua
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (widget.icon != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            widget.icon,
                            size: 18,
                            color: textColor.withValues(alpha: 0.9),
                          ),
                        ],
                        const SizedBox(width: 12),
                        Icon(
                          widget.isMultiSelect
                              ? (widget.isSelected
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank)
                              : (widget.isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off),
                          color: widget.isSelected
                              ? StarboundColors.deepSpace
                              : Colors.white70,
                        ),
                      ],
                    ),
                  ),
                  if (widget.isSelected)
                    IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: RadialGradient(
                                colors: [
                                  StarboundColors.stellarAqua
                                      .withValues(alpha: 0.18 * (1 - _glowAnimation.value)),
                                  Colors.transparent,
                                ],
                                radius: 0.9 + (_glowAnimation.value * 0.2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextStepIntent extends Intent {
  const _NextStepIntent();
}

class _SkipStepIntent extends Intent {
  const _SkipStepIntent();
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: StarboundColors.cosmicBeige.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6],
          tileMode: TileMode.repeated,
          transform: const GradientRotation(0.6),
        ),
      ),
      child: child,
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.id,
    required this.title,
    required this.questionIds,
    this.summary,
    this.description,
    this.includeNote = false
  });

  final String id;
  final String title;
  final List<String> questionIds;
  final String? summary;
  final String? description;
  final bool includeNote;
}
