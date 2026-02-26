import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design_system/design_system.dart';
import '../models/nudge_model.dart';
import '../models/starbound_response.dart';
import '../providers/app_state.dart';

/// Health navigation response card for Ask page
/// Displays structured health guidance with urgency indicators
class HealthResponseCard extends StatefulWidget {
  final StarboundResponse response;
  final VoidCallback? onSave;
  final VoidCallback? onFollowUp;
  final VoidCallback? onEmergency;
  final VoidCallback? onBack;

  const HealthResponseCard({
    Key? key,
    required this.response,
    this.onSave,
    this.onFollowUp,
    this.onEmergency,
    this.onBack,
  }) : super(key: key);

  @override
  State<HealthResponseCard> createState() => _HealthResponseCardState();
}

class _HealthResponseCardState extends State<HealthResponseCard> {
  final Set<int> _expandedCauses = {};
  final Set<String> _expandedStepIds = {};
  final Set<String> _checkedStepIds = {};
  bool _isSavingChecklist = false;
  static const BorderRadius _topSectionRadius = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(24),
  );

  @override
  void initState() {
    super.initState();
    _initializeChecklistState();
  }

  @override
  void didUpdateWidget(covariant HealthResponseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response.id != widget.response.id) {
      _expandedCauses.clear();
      _expandedStepIds.clear();
      _checkedStepIds.clear();
      _isSavingChecklist = false;
      _initializeChecklistState();
    }
  }

  Color _accentForIndex(int index) {
    const accents = [
      StarboundColors.stellarAqua,
      StarboundColors.starlightBlue,
      StarboundColors.nebulaPurple,
      StarboundColors.cosmicPink,
      StarboundColors.stellarYellow,
      StarboundColors.solarOrange,
    ];
    return accents[index % accents.length];
  }

  TextStyle _sectionLabelStyle(Color accent) {
    return StarboundTypography.caption.copyWith(
      color: accent,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildSectionDivider() {
    return Divider(
      height: 1,
      color: StarboundColors.cosmicWhite.withValues(alpha: 0.1),
    );
  }

  void _initializeChecklistState() {
    for (var i = 0; i < widget.response.immediateSteps.length; i++) {
      final step = widget.response.immediateSteps[i];
      if (step.completed) {
        _checkedStepIds.add(_stepKey(i, step));
      }
    }
  }

  String _stepKey(int index, ActionableStep step) {
    final id = step.id.trim();
    if (id.isNotEmpty) {
      return id;
    }
    return 'step_$index';
  }

  void _toggleStepExpanded(String stepKey) {
    setState(() {
      if (_expandedStepIds.contains(stepKey)) {
        _expandedStepIds.remove(stepKey);
      } else {
        _expandedStepIds.add(stepKey);
      }
    });
  }

  void _toggleStepChecked(String stepKey) {
    setState(() {
      if (_checkedStepIds.contains(stepKey)) {
        _checkedStepIds.remove(stepKey);
      } else {
        _checkedStepIds.add(stepKey);
      }
    });
  }

  Color _accentForTheme(String? theme, Color fallback) {
    switch (theme?.trim().toLowerCase()) {
      case 'self_care':
        return StarboundColors.stellarAqua;
      case 'healthcare_access':
        return StarboundColors.starlightBlue;
      case 'monitoring':
        return StarboundColors.nebulaPurple;
      default:
        return fallback;
    }
  }

  String _themeLabel(String? theme) {
    switch (theme?.trim().toLowerCase()) {
      case 'self_care':
        return 'Self care';
      case 'healthcare_access':
        return 'Healthcare access';
      case 'monitoring':
        return 'Monitoring';
      default:
        if (theme == null || theme.trim().isEmpty) {
          return 'Action';
        }
        return theme.trim().replaceAll('_', ' ').split(' ').map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1)}';
        }).join(' ');
    }
  }

  String _vaultThemeFor(String? stepTheme) {
    switch (stepTheme?.trim().toLowerCase()) {
      case 'self_care':
        return 'wellness';
      case 'healthcare_access':
        return 'planning';
      case 'monitoring':
        return 'awareness';
      default:
        return 'balanced';
    }
  }

  String? _detailForStep(int index, ActionableStep step) {
    final rawDetail = step.details?.trim();
    if (rawDetail != null &&
        rawDetail.isNotEmpty &&
        rawDetail.toLowerCase() != step.text.trim().toLowerCase()) {
      return rawDetail;
    }

    if (index < widget.response.followUpSuggestions.length) {
      final fallbackDetail = widget.response.followUpSuggestions[index].trim();
      if (fallbackDetail.isNotEmpty) {
        return fallbackDetail;
      }
    }
    return null;
  }

  String _estimatedTimeForChecklist(List<ActionableStep> selectedSteps) {
    final times = selectedSteps
        .map((step) => step.estimatedTime?.trim())
        .whereType<String>()
        .where((time) => time.isNotEmpty)
        .toSet();
    if (times.length == 1) {
      return times.first;
    }
    if (times.length > 1) {
      return 'Varies';
    }
    return 'today';
  }

  Future<void> _saveChecklistToVault() async {
    if (_isSavingChecklist) {
      return;
    }

    final selectedEntries = widget.response.immediateSteps
        .asMap()
        .entries
        .where(
          (entry) => _checkedStepIds.contains(_stepKey(entry.key, entry.value)),
        )
        .toList();

    if (selectedEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Select at least one checklist item before saving.'),
          backgroundColor: StarboundColors.solarOrange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isSavingChecklist = true;
    });

    try {
      final appState = context.read<AppState>();
      final now = DateTime.now();
      final selectedSteps =
          selectedEntries.map((entry) => entry.value).toList();
      final selectedStepTexts =
          selectedSteps.map((step) => step.text).toList(growable: false);

      String? primaryTheme;
      for (final step in selectedSteps) {
        final theme = step.theme?.trim();
        if (theme != null && theme.isNotEmpty) {
          primaryTheme = theme;
          break;
        }
      }

      final detailLines = selectedEntries
          .map((entry) => _detailForStep(entry.key, entry.value))
          .whereType<String>()
          .toList(growable: false);

      final nudgeContentParts = <String>[
        widget.response.overview.trim(),
        ...detailLines,
      ].where((part) => part.isNotEmpty).toList(growable: false);

      final nudge = StarboundNudge(
        id: now.microsecondsSinceEpoch.toString(),
        theme: _vaultThemeFor(primaryTheme),
        message: selectedStepTexts.first,
        title: 'Health action checklist',
        content: nudgeContentParts.join(' '),
        actionableSteps: selectedStepTexts,
        tone: 'supportive',
        estimatedTime: _estimatedTimeForChecklist(selectedSteps),
        energyRequired: 'low',
        complexityProfileFit: [
          appState.complexityProfile.toString().split('.').last,
        ],
        triggersFrom: const ['ask_flow', 'health_response_card'],
        source: NudgeSource.dynamic,
        type: NudgeType.suggestion,
        generatedAt: now,
        metadata: {
          'saved_from': 'health_response_checklist',
          'ai_generated': true,
          'user_query': widget.response.userQuery,
          'response_id': widget.response.id,
          'selected_steps': selectedEntries
              .map((entry) => {
                    'id': _stepKey(entry.key, entry.value),
                    'text': entry.value.text,
                    if (_detailForStep(entry.key, entry.value) != null)
                      'details': _detailForStep(entry.key, entry.value),
                    if (entry.value.estimatedTime != null)
                      'estimated_time': entry.value.estimatedTime,
                    if (entry.value.theme != null) 'theme': entry.value.theme,
                  })
              .toList(growable: false),
        },
      );

      await appState.saveGeminiActionToVault(nudge);
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingChecklist = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Checklist added to your Action Vault.'),
          backgroundColor: StarboundColors.success,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'View vault',
            textColor: StarboundColors.cosmicWhite,
            onPressed: () => Navigator.of(context).pushNamed('/action-vault'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSavingChecklist = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not add checklist to vault.'),
          backgroundColor: StarboundColors.error,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // EMERGENCY ALERT (if emergency text exists)
        if (_hasEmergency()) _buildEmergencyAlert(),

        // BACK BUTTON
        if (widget.onBack != null) _buildBackButton(),

        // MAIN CARD
        CosmicGlassPanel(
          padding: EdgeInsets.zero,
          tintColor: StarboundColors.surface.withValues(alpha: 0.9),
          borderColor: StarboundColors.cosmicWhite.withValues(alpha: 0.12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. UNDERSTANDING SECTION
              _buildUnderstandingSection(),

              _buildSectionDivider(),

              // 2. WHAT THIS MIGHT MEAN SECTION
              if (widget.response.insightSections.isNotEmpty)
                _buildPossibleCausesSection(),

              if (widget.response.insightSections.isNotEmpty)
                _buildSectionDivider(),

              // 3. WHAT YOU CAN DO NOW SECTION
              if (widget.response.immediateSteps.isNotEmpty)
                _buildImmediateStepsSection(),

              if (widget.response.immediateSteps.isNotEmpty)
                _buildSectionDivider(),

              // 4. WHEN TO SEEK CARE SECTION
              if (widget.response.whenToSeekCare != null)
                _buildWhenToSeekCareSection(),

              if (widget.response.whenToSeekCare != null)
                _buildSectionDivider(),

              // 5. WHERE TO GO SECTION (Placeholder)
              _buildWhereToGoSection(),

              _buildSectionDivider(),

              // 6. MEDICAL DISCLAIMER
              _buildMedicalDisclaimer(),

              // 7. ACTION CHIPS
              _buildActionChips(),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // EMERGENCY ALERT
  // ============================================
  bool _hasEmergency() {
    final emergency = widget.response.whenToSeekCare?.emergency;
    if (emergency == null || emergency.trim().isEmpty) {
      return false;
    }
    return _isImmediateEmergency(emergency);
  }

  bool _isImmediateEmergency(String text) {
    final normalized = text.toLowerCase().trim();

    // Conditional guidance (e.g. "call 000 if...") should not trigger
    // the emergency-now banner.
    final hasConditionalLanguage =
        RegExp(r'\b(if|when|unless|watch for)\b').hasMatch(normalized);
    if (hasConditionalLanguage) {
      return false;
    }

    const immediateCues = [
      'call 000 now',
      'go to emergency now',
      'seek emergency care now',
      'this is an emergency',
      'right now',
      'immediately',
      'urgent emergency care',
    ];

    return immediateCues.any((cue) => normalized.contains(cue));
  }

  Widget _buildEmergencyAlert() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StarboundColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StarboundColors.error,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: StarboundColors.error,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ This sounds serious',
                  style: StarboundTypography.heading4.copyWith(
                    color: StarboundColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Call 000 or go to Emergency now',
                  style: StarboundTypography.body.copyWith(
                    color: StarboundColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          CosmicButton.primary(
            onPressed: widget.onEmergency,
            accentColor: StarboundColors.error,
            size: CosmicButtonSize.small,
            child: const Text('Get Help'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BACK BUTTON
  // ============================================
  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextButton.icon(
        onPressed: widget.onBack,
        icon: const Icon(Icons.arrow_back),
        label: const Text('Ask another question'),
        style: TextButton.styleFrom(
          foregroundColor: StarboundColors.stellarAqua,
        ),
      ),
    );
  }

  // ============================================
  // 1. UNDERSTANDING SECTION
  // ============================================
  Widget _buildUnderstandingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StarboundColors.nebulaPurple.withValues(alpha: 0.22),
            StarboundColors.deepSpace.withValues(alpha: 0.22),
          ],
        ),
        borderRadius: _topSectionRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UNDERSTANDING',
            style: _sectionLabelStyle(StarboundColors.stellarAqua),
          ),
          const SizedBox(height: 12),
          Text(
            widget.response.overview,
            style: StarboundTypography.bodyLarge.copyWith(
              color: StarboundColors.textPrimary.withValues(alpha: 0.96),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // 2. WHAT THIS MIGHT MEAN SECTION
  // ============================================
  Widget _buildPossibleCausesSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT THIS MIGHT MEAN',
            style: _sectionLabelStyle(StarboundColors.starlightBlue),
          ),
          const SizedBox(height: 12),
          Text(
            'This could be related to:',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.response.insightSections.asMap().entries.map((entry) {
            final index = entry.key;
            final cause = entry.value;
            final isExpanded = _expandedCauses.contains(index);

            return _buildExpandableCause(index, cause, isExpanded);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildExpandableCause(
      int index, InsightSection cause, bool isExpanded) {
    final accent = _accentForIndex(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: StarboundColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
        ),
        boxShadow: StarboundColors.cosmicGlow(accent, intensity: 0.06),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedCauses.remove(index);
            } else {
              _expandedCauses.add(index);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cause.title,
                      style: StarboundTypography.body.copyWith(
                        color: StarboundColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: accent.withValues(alpha: 0.85),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 8),
                Text(
                  cause.summary,
                  style: StarboundTypography.bodySmall.copyWith(
                    color: StarboundColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // 3. WHAT YOU CAN DO NOW SECTION
  // ============================================
  Widget _buildImmediateStepsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT YOU CAN DO NOW',
            style: _sectionLabelStyle(StarboundColors.stellarAqua),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Based on your situation:',
                  style: StarboundTypography.body.copyWith(
                    color: StarboundColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CosmicButton.secondary(
                onPressed: _isSavingChecklist ? null : _saveChecklistToVault,
                icon: Icons.playlist_add_check_circle_outlined,
                size: CosmicButtonSize.small,
                accentColor: StarboundColors.stellarAqua,
                isLoading: _isSavingChecklist,
                loadingLabel: 'Saving',
                child: const Text('Add checklist'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _checkedStepIds.isEmpty
                ? 'Tap the number circle to select checklist items.'
                : '${_checkedStepIds.length} item${_checkedStepIds.length == 1 ? '' : 's'} selected',
            style: StarboundTypography.caption.copyWith(
              color: _checkedStepIds.isEmpty
                  ? StarboundColors.textSecondary
                  : StarboundColors.stellarAqua.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          ...widget.response.immediateSteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final accent = _accentForIndex(index);
            final stepKey = _stepKey(index, step);
            final isExpanded = _expandedStepIds.contains(stepKey);
            final isChecked = _checkedStepIds.contains(stepKey);
            final details = _detailForStep(index, step);

            return _buildActionStep(
              stepNumber: index + 1,
              step: step,
              accent: accent,
              stepKey: stepKey,
              isExpanded: isExpanded,
              isChecked: isChecked,
              details: details,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionStep({
    required int stepNumber,
    required ActionableStep step,
    required Color accent,
    required String stepKey,
    required bool isExpanded,
    required bool isChecked,
    String? details,
  }) {
    final themeAccent = _accentForTheme(step.theme, accent);
    final showMeta = (step.estimatedTime?.trim().isNotEmpty ?? false) ||
        (step.theme?.trim().isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: StarboundColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
        ),
        boxShadow: StarboundColors.cosmicGlow(accent, intensity: 0.06),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _toggleStepChecked(stepKey),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isChecked
                          ? accent.withValues(alpha: 0.28)
                          : accent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: isChecked ? 0.95 : 0.7),
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isChecked
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: accent,
                          )
                        : Text(
                            '$stepNumber',
                            style: StarboundTypography.body.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.text,
                    style: StarboundTypography.body.copyWith(
                      color:
                          StarboundColors.textPrimary.withValues(alpha: 0.95),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      decorationColor:
                          StarboundColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleStepExpanded(stepKey),
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: accent.withValues(alpha: 0.85),
                  ),
                  tooltip: isExpanded ? 'Hide details' : 'Show details',
                ),
              ],
            ),
            if (isExpanded) ...[
              Divider(
                height: 20,
                color: StarboundColors.cosmicWhite.withValues(alpha: 0.12),
              ),
              if (details != null)
                Text(
                  details,
                  style: StarboundTypography.bodySmall.copyWith(
                    color: StarboundColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              if (details != null && showMeta) const SizedBox(height: 10),
              if (showMeta)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (step.estimatedTime != null &&
                        step.estimatedTime!.trim().isNotEmpty)
                      _buildStepInfoChip(
                        icon: Icons.schedule_rounded,
                        label: 'Time: ${step.estimatedTime!.trim()}',
                        color: StarboundColors.starlightBlue,
                      ),
                    if (step.theme != null && step.theme!.trim().isNotEmpty)
                      _buildStepInfoChip(
                        icon: Icons.local_offer_outlined,
                        label: _themeLabel(step.theme),
                        color: themeAccent,
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: StarboundTypography.caption.copyWith(
              color: color.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // 4. WHEN TO SEEK CARE SECTION
  // ============================================
  Widget _buildWhenToSeekCareSection() {
    final whenToSeek = widget.response.whenToSeekCare!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHEN TO SEEK CARE',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.stellarYellow,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // ROUTINE
          if (whenToSeek.routine != null && whenToSeek.routine!.isNotEmpty)
            _buildUrgencyItem(
              icon: Icons.info_outline,
              iconColor: StarboundColors.starlightBlue,
              backgroundColor:
                  StarboundColors.starlightBlue.withValues(alpha: 0.1),
              label: 'Routine',
              text: whenToSeek.routine!,
            ),

          // URGENT
          if (whenToSeek.urgent != null && whenToSeek.urgent!.isNotEmpty)
            _buildUrgencyItem(
              icon: Icons.warning_amber_rounded,
              iconColor: StarboundColors.stellarYellow,
              backgroundColor:
                  StarboundColors.stellarYellow.withValues(alpha: 0.1),
              label: 'Urgent',
              text: whenToSeek.urgent!,
              bulletPoints: _extractBulletPoints(whenToSeek.urgent!),
            ),

          // EMERGENCY
          if (whenToSeek.emergency != null && whenToSeek.emergency!.isNotEmpty)
            _buildUrgencyItem(
              icon: Icons.error_outline,
              iconColor: StarboundColors.error,
              backgroundColor: StarboundColors.error.withValues(alpha: 0.1),
              label: 'Emergency - Call 000',
              text: whenToSeek.emergency!,
              bulletPoints: _extractBulletPoints(whenToSeek.emergency!),
            ),
        ],
      ),
    );
  }

  Widget _buildUrgencyItem({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String label,
    required String text,
    List<String>? bulletPoints,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: StarboundTypography.body.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (bulletPoints == null || bulletPoints.isEmpty)
            Text(
              text,
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.textPrimary,
                height: 1.5,
              ),
            )
          else ...[
            if (bulletPoints.isNotEmpty && !text.startsWith('•'))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  text.split('\n').first,
                  style: StarboundTypography.bodySmall.copyWith(
                    color: StarboundColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ...bulletPoints
                .map((point) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: iconColor)),
                          Expanded(
                            child: Text(
                              point,
                              style: StarboundTypography.bodySmall.copyWith(
                                color: StarboundColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ],
      ),
    );
  }

  List<String>? _extractBulletPoints(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final bullets = lines
        .where((line) => line.startsWith('•') || line.startsWith('-'))
        .toList();

    if (bullets.isEmpty) return null;

    return bullets.map((b) => b.replaceFirst(RegExp(r'^[•-]\s*'), '')).toList();
  }

  // ============================================
  // 5. WHERE TO GO SECTION (Placeholder)
  // ============================================
  Widget _buildWhereToGoSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHERE TO GO',
            style: StarboundTypography.caption.copyWith(
              color: StarboundColors.starlightBlue,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StarboundColors.surfaceElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: StarboundColors.starlightBlue.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: StarboundColors.starlightBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Finding resources that match your barriers...\n(Coming soon)',
                    style: StarboundTypography.bodySmall.copyWith(
                      color: StarboundColors.textTertiary,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // 6. MEDICAL DISCLAIMER
  // ============================================
  Widget _buildMedicalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StarboundColors.surfaceElevated.withValues(alpha: 0.3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.medical_information_outlined,
            size: 16,
            color: StarboundColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This information is for guidance only. Only a healthcare professional can provide proper diagnosis and treatment.',
              style: StarboundTypography.caption.copyWith(
                color: StarboundColors.textTertiary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // 7. ACTION CHIPS
  // ============================================
  Widget _buildActionChips() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (widget.onSave != null)
            CosmicButton.secondary(
              onPressed: widget.onSave,
              icon: Icons.bookmark_outline,
              size: CosmicButtonSize.small,
              child: const Text('Save This'),
            ),
          if (widget.onFollowUp != null)
            CosmicButton.secondary(
              onPressed: widget.onFollowUp,
              icon: Icons.chat_bubble_outline,
              size: CosmicButtonSize.small,
              child: const Text('Ask Follow-up'),
            ),
          if (widget.onEmergency != null)
            CosmicButton.secondary(
              onPressed: widget.onEmergency,
              accentColor: StarboundColors.error,
              icon: Icons.local_hospital,
              size: CosmicButtonSize.small,
              child: const Text('Emergency'),
            ),
        ],
      ),
    );
  }
}
