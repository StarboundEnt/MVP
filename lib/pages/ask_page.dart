import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/health_response_card.dart';
import '../design_system/design_system.dart';
import '../models/complexity_engine_models.dart';
import '../models/nudge_model.dart';
import '../models/starbound_response.dart';
import '../providers/app_state.dart';
import '../services/complexity_engine_service.dart';
import '../services/openrouter_service.dart';

class AskPage extends StatefulWidget {
  final VoidCallback onGoBack;
  final Function(String) onSubmit;
  final ValueChanged<String>? onNavigateToFeature;
  final bool embedded;
  final bool showSearchBar;

  const AskPage({
    Key? key,
    required this.onGoBack,
    required this.onSubmit,
    this.onNavigateToFeature,
    this.embedded = false,
    this.showSearchBar = true,
  }) : super(key: key);

  @override
  State<AskPage> createState() => AskPageState();
}

class AskPageState extends State<AskPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  final ComplexityEngineService _engine = ComplexityEngineService();
  final OpenRouterService _openRouter = OpenRouterService();

  String _currentQuery = '';
  ComplexityResponseModel? _responseModel;
  String? _answerText;
  StarboundResponse? _healthResponse;
  bool _isLoading = false;
  bool _isAnswerLoading = false;
  FollowUpPlan? _followUpPlan;
  final List<Map<String, String>> _followupAnswers = [];
  String? _primaryEventId;
  DateTime? _primaryEventCreatedAt;

  @override
  void dispose() {
    _controller.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void submitExternalQuery(
    String query, {
    ComplexityResponseModel? responseModel,
    String? engineEventId,
    String? engineCreatedAt,
  }) {
    if (!mounted) return;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _controller.text = trimmed;
    _primaryEventId = engineEventId;
    _primaryEventCreatedAt =
        engineCreatedAt != null ? DateTime.tryParse(engineCreatedAt) : null;
    _handleSubmit(prebuiltModel: responseModel);
  }

  Future<void> _handleSubmit({ComplexityResponseModel? prebuiltModel}) async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    widget.onSubmit(query);
    if (widget.embedded) {
      _controller.clear();
    }

    await _processInput(query, prebuiltModel: prebuiltModel);
  }

  Future<void> _processInput(
    String text, {
    bool isFollowUp = false,
    List<FactorWrite> factorWrites = const [],
    ComplexityResponseModel? prebuiltModel,
  }) async {
    if (text.trim().isEmpty) return;

    if (!isFollowUp) {
      _currentQuery = text.trim();
      _followupAnswers.clear();
      _followUpPlan = null;
      _answerText = null;
      _healthResponse = null;
      if (prebuiltModel == null) {
        _primaryEventId = null;
        _primaryEventCreatedAt = null;
      }
    } else {
      _answerText = null;
      _healthResponse = null;
    }

    setState(() {
      _isLoading = true;
    });

    ComplexityResponseModel? model = prebuiltModel;
    ProcessSmartInputResult? engineResult;

    if (model == null) {
      try {
        engineResult = await _engine.processSmartInput(
          inputText: text,
          intent: EventIntent.ask,
          saveMode: EventSaveMode.saveFactorsOnly,
          factorWrites: factorWrites,
        );
        model = engineResult.responseModel;
      } catch (e) {
        debugPrint('Ask engine error: $e');
      }
    }

    if (model != null) {
      _responseModel = model;
      _followUpPlan = model.followUpPlan;
    }

    if (!isFollowUp && engineResult != null) {
      _primaryEventId = engineResult.event.id;
      _primaryEventCreatedAt = DateTime.tryParse(engineResult.event.createdAt);
    }

    setState(() {
      _isLoading = false;
    });

    // Check if this is a health-related question that should use health navigation
    final isHealthQuestion = _isHealthRelatedQuestion(text);

    if (model != null &&
        (model.mode == ResponseMode.answer || isHealthQuestion)) {
      await _loadAnswerText();
    }
  }

  /// Detect if a question is health-related and should use health navigation
  bool _isHealthRelatedQuestion(String query) {
    final lower = query.toLowerCase();

    // Physical symptoms
    final physicalSymptoms = [
      'pain',
      'ache',
      'hurt',
      'sore',
      'headache',
      'migraine',
      'tired',
      'fatigue',
      'exhausted',
      'dizzy',
      'nausea',
      'fever',
      'temperature',
      'cough',
      'cold',
      'flu',
      'sick',
      'bleeding',
      'blood',
      'rash',
      'itch',
      'swollen',
      'numb',
      'weak',
      'breath',
      'breathing',
      'chest',
      'stomach',
      'vomit',
      'diarrhea',
      'constipation',
      'cramp',
      'injury',
      'broken',
      'sprain',
      'strain',
      'cut',
      'burn',
      'bruise',
      'stubbed',
      'twisted',
      'fell',
      'hit',
    ];

    // Healthcare access questions
    final healthcareQuestions = [
      'doctor',
      'gp',
      'clinic',
      'hospital',
      'emergency',
      'medical',
      'health',
      'medicine',
      'prescription',
      'medication',
      'treatment',
      'diagnosis',
      'specialist',
      'appointment',
      'bulk billing',
      'medicare',
      'telehealth',
    ];

    // Check for matches
    for (final symptom in physicalSymptoms) {
      if (lower.contains(symptom)) return true;
    }

    for (final term in healthcareQuestions) {
      if (lower.contains(term)) return true;
    }

    return false;
  }

  Future<void> _loadAnswerText() async {
    if (_currentQuery.isEmpty) return;

    final appState = context.read<AppState>();
    final model = _responseModel;
    if (model == null) return;
    setState(() {
      _isAnswerLoading = true;
    });

    String? response;
    final isHealthQuestion = _isHealthRelatedQuestion(_currentQuery);

    if (_openRouter.isConfigured) {
      // Get health navigation profile
      final profile = appState.healthNavigationProfile;

      debugPrint(
          '🔍 AskPage: Calling OpenRouter for ${isHealthQuestion ? "HEALTH" : "general"} question');

      response = await _openRouter.generateAskAnswer(
        question: _currentQuery,
        userName: appState.userName,
        complexityProfile:
            appState.complexityProfile.toString().split('.').last,
        symptomKey: model.symptomKey,
        keyFactors: model.keyFactors,
        routerCategory: model.routerCategory?.code ?? 'unspecified',
        whatToDoNow: model.whatToDoNow,
        whatIfWorse: model.whatIfWorse,
        // Health navigation context
        neighborhood: profile?.neighborhood,
        barriers: profile?.barriers,
        languages: profile?.languages,
        workSchedule: profile?.workSchedule,
        healthInterests: profile?.healthInterests,
        // Include follow-up answers for full context
        followUpAnswers: _followupAnswers,
      );

      debugPrint(
          '📥 AskPage: OpenRouter returned ${response == null ? "NULL" : "${response.length} chars"}');
    }

    String answer;
    if (!_openRouter.isConfigured) {
      debugPrint('❌ AskPage: OpenRouter not configured');
      answer = '''
{
  "understanding": "I couldn't reach the OpenRouter service right now.",
  "possible_causes": ["OpenRouter API key is missing", "Service not configured"],
  "immediate_steps": [
    {"step_number": 1, "title": "Add your OpenRouter API key", "description": "Set OPENROUTER_API_KEY and try again.", "estimated_time": "2-5 min", "theme": "self_care"},
    {"step_number": 2, "title": "Retry your question", "description": "Once the key is set, ask again.", "estimated_time": "1 min", "theme": "monitoring"}
  ],
  "when_to_seek_care": {
    "routine": "If this is a health concern, consider speaking with a GP.",
    "urgent": "Seek care today if symptoms are severe or worsening.",
    "emergency": "Call 000 if you feel unsafe or have severe symptoms."
  },
  "resource_needs": [],
  "follow_up_suggestions": ["Check your OpenRouter API key and retry."]
}
''';
    } else if (response != null && response.trim().isNotEmpty) {
      answer = response.trim();
      debugPrint('✅ AskPage: Using OpenRouter response');
    } else {
      debugPrint('❌ AskPage: OpenRouter returned empty response');
      answer = '''
{
  "understanding": "I'm having trouble connecting to the OpenRouter service right now.",
  "possible_causes": ["Connection issue", "Service temporarily unavailable"],
  "immediate_steps": [
    {"step_number": 1, "title": "Try your question again", "description": "Sometimes the connection needs a retry.", "estimated_time": "1 min", "theme": "monitoring"},
    {"step_number": 2, "title": "If this is urgent, seek care", "description": "Contact a GP or pharmacist if symptoms are worrying.", "estimated_time": "today", "theme": "healthcare_access"}
  ],
  "when_to_seek_care": {
    "routine": "See a GP if symptoms persist beyond a few days.",
    "urgent": "Seek care today if symptoms are severe or worsening.",
    "emergency": "Call 000 if you have severe symptoms."
  },
  "resource_needs": [],
  "follow_up_suggestions": ["Retry in a moment or check your connection."]
}
''';
    }

    if (!mounted) return;

    // Try to parse as structured health navigation response
    final healthResponse = _openRouter.parseHealthNavigationResponse(
      responseText: answer,
      userQuery: _currentQuery,
    );

    if (healthResponse == null) {
      debugPrint(
          '⚠️ AskPage: JSON parsing failed - falling back to plain text display');
    } else {
      debugPrint(
          '✅ AskPage: Successfully created StarboundResponse with ${healthResponse.immediateSteps.length} steps');
    }

    setState(() {
      _answerText = answer.trim();
      _healthResponse = healthResponse;
      _responseModel = model.copyWith(answer: answer.trim());
      _isAnswerLoading = false;
    });
  }

  Future<void> _submitFollowupChoice(FollowUpChoice choice) async {
    final question = _followUpPlan?.questionText;
    if (question != null) {
      _followupAnswers.add({
        'question': question,
        'answer': choice.label,
      });
    }

    await _processInput(
      choice.label,
      isFollowUp: true,
      factorWrites: choice.writesFactors,
    );
  }

  Future<void> _refreshResponseModel() async {
    if (_currentQuery.isEmpty) return;
    final previousEventId = _primaryEventId;
    final previousCreatedAt = _primaryEventCreatedAt;
    await _processInput(_currentQuery);
    if (previousEventId != null) {
      _primaryEventId = previousEventId;
      _primaryEventCreatedAt = previousCreatedAt;
    }
  }

  Future<void> _saveToJournal() async {
    if (_currentQuery.isEmpty) return;
    final appState = context.read<AppState>();

    final buffer = StringBuffer();
    buffer.writeln('Q: $_currentQuery');
    if (_followupAnswers.isNotEmpty) {
      buffer.writeln('Follow-up:');
      for (final followup in _followupAnswers) {
        buffer.writeln('Q: ${followup['question']}');
        buffer.writeln('A: ${followup['answer']}');
      }
    }
    final answer = _responseModel?.answer ?? _answerText;
    if (answer != null && answer.isNotEmpty) {
      buffer.writeln('A: $answer');
    }

    if (_primaryEventId != null && _primaryEventCreatedAt != null) {
      await _engine.processSmartInput(
        inputText: _currentQuery,
        intent: EventIntent.ask,
        saveMode: EventSaveMode.saveJournal,
        eventId: _primaryEventId,
        createdAt: _primaryEventCreatedAt,
      );
    }

    try {
      await appState.processFreeFormEntry(buffer.toString().trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to Journal'),
            backgroundColor: StarboundColors.stellarAqua,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save.'),
            backgroundColor: StarboundColors.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _saveSuggestionToVault(VaultActionSuggestion suggestion) async {
    final appState = context.read<AppState>();
    final now = DateTime.now();

    final nudge = StarboundNudge(
      id: 'ask_action_${now.millisecondsSinceEpoch}',
      theme: 'grounding',
      message: suggestion.title,
      title: suggestion.title,
      content: suggestion.steps.join(' '),
      actionableSteps: suggestion.steps,
      tone: 'supportive',
      estimatedTime: suggestion.defaultSchedule ?? 'today',
      energyRequired: 'low',
      complexityProfileFit: [
        appState.complexityProfile.toString().split('.').last
      ],
      triggersFrom: const ['ask_flow'],
      source: NudgeSource.dynamic,
      generatedAt: now,
      metadata: {
        'saved_from': 'ask_page_action',
        'ai_generated': true,
        'vault_payload': suggestion.vaultPayload,
        'energy_required': suggestion.energyRequired,
        'time_required': suggestion.timeRequired,
        'context_tags': suggestion.contextTags,
        'priority_factors': suggestion.priorityFactors,
      },
    );

    try {
      await appState.saveGeminiActionToVault(nudge);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to Action Vault'),
            backgroundColor: StarboundColors.stellarYellow,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save action.'),
            backgroundColor: StarboundColors.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showWhatImUsingSheet() {
    final model = _responseModel?.whatImUsing;
    if (model == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: StarboundColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.title,
                  style: StarboundTypography.heading3.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  model.description,
                  style: StarboundTypography.bodySmall.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildControlsRow(model),
                const SizedBox(height: 16),
                _buildUsedFactorGroups(model),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlsRow(WhatImUsingModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSwitchRow(
          label: 'Use saved context',
          value: model.controls.useSavedContext,
          onChanged: (value) async {
            await _engine.setUseSavedContext(value);
            if (mounted) {
              Navigator.of(context).pop();
            }
            await _refreshResponseModel();
          },
        ),
        const SizedBox(height: 8),
        _buildSwitchRow(
          label: 'Use profile this session',
          value: model.controls.sessionUseProfile,
          onChanged: (value) {
            _engine.setSessionUseProfile(value);
            Navigator.of(context).pop();
            _refreshResponseModel();
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () async {
            await _engine.clearSessionContext();
            if (mounted) {
              Navigator.of(context).pop();
            }
            await _refreshResponseModel();
          },
          style: TextButton.styleFrom(
            foregroundColor: StarboundColors.stellarAqua,
          ),
          child: const Text('Clear session context'),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: StarboundTypography.bodySmall.copyWith(
            color: StarboundColors.textPrimary,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: StarboundColors.stellarAqua,
        ),
      ],
    );
  }

  Widget _buildUsedFactorGroups(WhatImUsingModel model) {
    final grouped = <String, List<UsedFactorChip>>{};
    for (final chip in model.chips) {
      grouped.putIfAbsent(chip.group, () => []).add(chip);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: StarboundTypography.caption.copyWith(
                  color: StarboundColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    entry.value.map((chip) => _buildUsedChip(chip)).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsedChip(UsedFactorChip chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: StarboundColors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: StarboundColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chip.label,
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              await _engine.suppressFactorCode(chip.code);
              if (!mounted) return;
              Navigator.of(context).pop();
              await _refreshResponseModel();
            },
            child: Text(
              'Not true',
              style: StarboundTypography.caption.copyWith(
                color: StarboundColors.stellarAqua,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = _responseModel;
    final showModel = model != null && !_isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputCard(),
        const SizedBox(height: 16),
        if (_isLoading) _buildLoadingCard('Checking in...'),
        if (showModel) ...[
          // Check if we have a health response (overrides mode check)
          if (_healthResponse != null) ...[
            HealthResponseCard(
              response: _healthResponse!,
              onSave: () {
                _saveToJournal();
              },
              onFollowUp: () {
                // Reset to show input for follow-up question
                setState(() {
                  _responseModel = null;
                  _answerText = null;
                  _healthResponse = null;
                });
                _inputFocusNode.requestFocus();
              },
              onEmergency: () {
                // TODO: Navigate to emergency resources
              },
              onBack: () {
                // Reset to show input for new question
                setState(() {
                  _responseModel = null;
                  _answerText = null;
                  _healthResponse = null;
                  _currentQuery = '';
                  _controller.clear();
                });
              },
            ),
          ] else if (model.mode == ResponseMode.askFollowup) ...[
            _buildConfirmationCard(model),
            const SizedBox(height: 12),
            _buildFollowupCard(model),
          ] else if (model.mode == ResponseMode.answer) ...[
            // Fallback to old combined answer card if no health response
            if (_healthResponse == null) ...[
              _buildCombinedAnswerCard(model),
              const SizedBox(height: 12),
              if (model.whatToDoNow.isNotEmpty)
                _buildWhatToDoNowCard(model.whatToDoNow),
              if (model.whatIfWorse.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildWhatIfWorseCard(model.whatIfWorse),
              ],
            ],
            if (model.safetyNet != null) ...[
              const SizedBox(height: 10),
              Text(
                model.safetyNet!,
                style: StarboundTypography.caption.copyWith(
                  color: StarboundColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildFooterActions(model),
          ] else if (model.mode == ResponseMode.safetyEscalation) ...[
            _buildSafetyCard(model),
            if (model.safetyNet != null) ...[
              const SizedBox(height: 10),
              Text(
                model.safetyNet!,
                style: StarboundTypography.caption.copyWith(
                  color: StarboundColors.textTertiary,
                ),
              ),
            ],
          ] else if (model.mode == ResponseMode.logOnly) ...[
            _buildLogOnlyCard(),
          ],
        ],
      ],
    );
  }

  Widget _buildLogOnlyCard() {
    return _brandPanel(
      background: StarboundColors.surfaceElevated,
      child: Text(
        'Saved.',
        style: StarboundTypography.bodySmall.copyWith(
          color: StarboundColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return _brandPanel(
      background: StarboundColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.embedded)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: widget.onGoBack,
                style: TextButton.styleFrom(
                  foregroundColor: StarboundColors.stellarAqua,
                ),
                child: const Text('Back'),
              ),
            ),
          if (!widget.embedded) ...[
            Text(
              'Ask Starbound',
              style: StarboundTypography.heading3.copyWith(
                color: StarboundColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          CosmicInput(
            controller: _controller,
            hintText: 'Ask about symptoms, finding care, or health concerns...',
            maxLines: 4,
            minLines: 2,
            focusNode: _inputFocusNode,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CosmicButton.primary(
                  onPressed: _isLoading ? null : () => _handleSubmit(),
                  icon: Icons.auto_awesome,
                  child: const Text('Answer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueryCard() {
    return _brandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You wrote',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentQuery,
            style: StarboundTypography.bodyLarge.copyWith(
              color: StarboundColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard(ComplexityResponseModel model) {
    return _brandPanel(
      background: StarboundColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.confirmation,
            style: StarboundTypography.bodySmall.copyWith(
              color: StarboundColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _showWhatImUsingSheet,
              style: TextButton.styleFrom(
                foregroundColor: StarboundColors.stellarAqua,
              ),
              child: const Text('What I am using'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowupCard(ComplexityResponseModel model) {
    final plan = _followUpPlan ?? model.followUpPlan;
    if (plan == null) {
      return const SizedBox.shrink();
    }

    return _brandPanel(
      background: StarboundColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.questionText,
            style: StarboundTypography.bodySmall.copyWith(
              color: StarboundColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: plan.choices.map((choice) {
              final isSkip = choice.label.toLowerCase() == 'skip';
              return CosmicButton(
                onPressed:
                    _isLoading ? null : () => _submitFollowupChoice(choice),
                variant: isSkip
                    ? CosmicButtonVariant.ghost
                    : CosmicButtonVariant.secondary,
                child: Text(choice.label),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedAnswerCard(ComplexityResponseModel model) {
    return _brandPanel(
      background: StarboundColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.confirmation,
            style: StarboundTypography.bodySmall.copyWith(
              color: StarboundColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _isAnswerLoading
              ? _buildLoadingCard('Writing a response...')
              : Text(
                  model.answer ??
                      _answerText ??
                      'Thanks for sharing. I am here when you are ready.',
                  style: StarboundTypography.bodySmall.copyWith(
                    color: StarboundColors.textPrimary,
                    height: 1.5,
                  ),
                ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _showWhatImUsingSheet,
              style: TextButton.styleFrom(
                foregroundColor: StarboundColors.stellarAqua,
              ),
              child: const Text('What I am using'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard(ComplexityResponseModel model) {
    return _brandPanel(
      background:
          StarboundColors.warmGradient.colors.first.withValues(alpha: 0.12),
      borderColor: StarboundColors.solarOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety check',
            style: StarboundTypography.heading4.copyWith(
              color: StarboundColors.solarOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'It may be safer to get help now.',
            style: StarboundTypography.bodySmall.copyWith(
              color: StarboundColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            model.confirmation,
            style: StarboundTypography.bodySmall.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatToDoNowCard(List<VaultActionSuggestion> suggestions) {
    return _brandPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'What to do now',
                style: StarboundTypography.heading4.copyWith(
                  color: StarboundColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: StarboundColors.stellarAqua.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: StarboundColors.stellarAqua.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  'Pick one',
                  style: StarboundTypography.caption.copyWith(
                    color: StarboundColors.stellarAqua,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildOrbitDot(StarboundColors.stellarAqua),
              const SizedBox(width: 6),
              _buildOrbitDot(StarboundColors.starlightBlue),
              const SizedBox(width: 6),
              _buildOrbitDot(StarboundColors.cosmicPink),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final accent = _accentForIndex(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.18),
                    StarboundColors.surfaceElevated,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
                boxShadow: StarboundColors.subtleShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.22),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: StarboundTypography.caption.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          style: StarboundTypography.bodySmall.copyWith(
                            color: StarboundColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildActionMetaRow(item, accent),
                  const SizedBox(height: 8),
                  ...item.steps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: accent.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step,
                              style: StarboundTypography.caption.copyWith(
                                color: StarboundColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CosmicButton.ghost(
                      onPressed: _isLoading
                          ? null
                          : () => _saveSuggestionToVault(item),
                      icon: Icons.bookmark_add_outlined,
                      child: const Text('Save to Vault'),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrbitDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Color _accentForIndex(int index) {
    const accents = [
      StarboundColors.stellarAqua,
      StarboundColors.starlightBlue,
      StarboundColors.cosmicPink,
      StarboundColors.solarOrange,
      StarboundColors.nebulaPurple,
    ];
    return accents[index % accents.length];
  }

  Widget _buildActionMetaRow(VaultActionSuggestion item, Color accent) {
    final chips = <String>[];
    if (item.energyRequired != null && item.energyRequired!.isNotEmpty) {
      chips.add('Energy: ${item.energyRequired}');
    }
    if (item.timeRequired != null && item.timeRequired!.isNotEmpty) {
      chips.add('Time: ${item.timeRequired}');
    }
    if (item.contextTags.isNotEmpty) {
      chips.addAll(item.contextTags);
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips.map((label) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: accent.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            label,
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWhatIfWorseCard(List<String> bullets) {
    return _brandPanel(
      background: StarboundColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What if it gets worse?',
            style: StarboundTypography.heading4.copyWith(
              color: StarboundColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...bullets.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: StarboundTypography.caption.copyWith(
                      color: StarboundColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: StarboundTypography.caption.copyWith(
                        color: StarboundColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(ComplexityResponseModel model) {
    return _brandPanel(
      background: StarboundColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save options',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              CosmicButton.secondary(
                onPressed: _saveToJournal,
                child: const Text('Save to Journal'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(String message) {
    return _brandPanel(
      background: StarboundColors.surfaceOverlay,
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandPanel({
    required Widget child,
    Color? background,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background ?? StarboundColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? StarboundColors.borderSubtle),
        boxShadow: StarboundColors.subtleShadow,
      ),
      child: child,
    );
  }
}
