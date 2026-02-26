import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/design_system.dart';
import '../models/journal_prompt_model.dart';
import '../services/guided_journal_flow_controller.dart';
import '../services/guided_journal_service.dart';

class GuidedJournalFlow extends StatefulWidget {
  final List<JournalPrompt> prompts;
  final GuidedJournalService service;
  final String? initialEventText;
  final Color accentColor;
  final ValueChanged<GuidedJournalResult>? onCompleted;
  final ValueChanged<String>? onHealthGuidanceRequested;
  final EdgeInsetsGeometry? margin;
  final bool useSafeArea;

  const GuidedJournalFlow({
    Key? key,
    required this.prompts,
    required this.service,
    this.initialEventText,
    this.accentColor = StarboundColors.stellarAqua,
    this.onCompleted,
    this.onHealthGuidanceRequested,
    this.margin,
    this.useSafeArea = true,
  }) : super(key: key);

  @override
  State<GuidedJournalFlow> createState() => _GuidedJournalFlowState();
}

class _GuidedJournalFlowState extends State<GuidedJournalFlow> {
  late GuidedJournalFlowController _controller;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Set<String> _selectedOptions = {};

  GuidedJournalResult? _completionResult;

  @override
  void initState() {
    super.initState();
    _controller = GuidedJournalFlowController(prompts: widget.prompts);
    _seedInitialText();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _seedInitialText() {
    final draft = widget.initialEventText?.trim();
    if (draft == null || draft.isEmpty) return;
    if (_controller.currentPrompt.domain == JournalPromptDomain.event) {
      _textController.text = draft;
    }
  }

  void _handleOptionToggle(String option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
      } else {
        _selectedOptions.add(option);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _handleSkip() {
    _controller.skipCurrent();
    _moveToNext();
  }

  void _handleContinue() {
    final prompt = _controller.currentPrompt;
    final response = JournalPromptResponse(
      promptId: prompt.id,
      selectedOptions: _selectedOptions.toList(),
      text: _textController.text.trim().isEmpty
          ? null
          : _textController.text.trim(),
    );
    _controller.submitResponse(response);
    _moveToNext();
  }

  void _moveToNext() {
    if (_controller.isComplete) {
      final result = widget.service.buildResult(
        prompts: widget.prompts,
        responses:
            Map<String, JournalPromptResponse>.from(_controller.responses),
      );
      setState(() {
        _completionResult = result;
      });
      return;
    }
    setState(() {
      _selectedOptions.clear();
      _textController.clear();
      _focusNode.unfocus();
    });
  }

  bool _hasInput(JournalPrompt prompt) {
    final hasText = _textController.text.trim().isNotEmpty;
    if (prompt.inputType == JournalPromptInputType.chips) {
      return _selectedOptions.isNotEmpty;
    }
    if (prompt.inputType == JournalPromptInputType.shortText) {
      return hasText;
    }
    return _selectedOptions.isNotEmpty || hasText;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final content = Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        margin: widget.margin ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StarboundColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.accentColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _completionResult == null
              ? _buildPromptView()
              : _buildCloseView(),
        ),
      ),
    );

    if (widget.useSafeArea) {
      return SafeArea(child: content);
    }
    return content;
  }

  Widget _buildPromptView() {
    final prompt = _controller.currentPrompt;
    final progressText =
        '${_controller.currentIndex + 1} of ${widget.prompts.length}';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Health check-in',
                style: StarboundTypography.heading3.copyWith(
                  color: StarboundColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                progressText,
                style: StarboundTypography.caption.copyWith(
                  color: StarboundColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (prompt.prefaceText != null &&
              prompt.prefaceText!.trim().isNotEmpty) ...[
            Text(
              prompt.prefaceText!,
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            prompt.promptText,
            style: StarboundTypography.heading2.copyWith(
              color: StarboundColors.textPrimary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          _buildPromptInput(prompt),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: prompt.skippable ? _handleSkip : null,
                style: TextButton.styleFrom(
                  foregroundColor: StarboundColors.textSecondary,
                ),
                child: const Text('Skip'),
              ),
              const Spacer(),
              CosmicButton.primary(
                onPressed: _hasInput(prompt) ? _handleContinue : null,
                accentColor: widget.accentColor,
                icon: _controller.isLastPrompt
                    ? Icons.check_circle_outline
                    : Icons.arrow_forward,
                size: CosmicButtonSize.medium,
                child: Text(_controller.isLastPrompt ? 'Finish' : 'Continue'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCloseView() {
    final hasHealthSymptoms = _completionResult?.hasHealthSymptoms ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thanks for logging your health today.',
          style: StarboundTypography.heading2.copyWith(
            color: StarboundColors.textPrimary,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tracking helps you spot patterns and prepare for appointments.',
          style: StarboundTypography.body.copyWith(
            color: StarboundColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        if (hasHealthSymptoms) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StarboundColors.stellarAqua.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: StarboundColors.stellarAqua.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: StarboundColors.stellarAqua,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I noticed you mentioned some health concerns. Would you like personalized guidance?',
                    style: StarboundTypography.bodySmall.copyWith(
                      color: StarboundColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CosmicButton.primary(
              onPressed: () {
                final healthQuestion = _completionResult?.healthQuestion;
                if (healthQuestion == null) return;

                // Request guidance first so parent callbacks can still read
                // any in-memory draft context before completion handlers clear it.
                final completed = _completionResult;
                if (widget.onHealthGuidanceRequested != null) {
                  widget.onHealthGuidanceRequested!(healthQuestion);
                }
                if (completed != null && widget.onCompleted != null) {
                  widget.onCompleted!(completed);
                }
              },
              accentColor: StarboundColors.stellarAqua,
              icon: Icons.health_and_safety,
              size: CosmicButtonSize.medium,
              child: const Text('Get Health Guidance'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: CosmicButton.primary(
            onPressed: () {
              final completed = _completionResult;
              if (completed == null) return;
              if (widget.onCompleted != null) {
                widget.onCompleted!(completed);
              } else {
                Navigator.of(context).pop(completed);
              }
            },
            accentColor: widget.accentColor,
            icon: Icons.done,
            size: CosmicButtonSize.medium,
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptInput(JournalPrompt prompt) {
    final showChips = prompt.inputType == JournalPromptInputType.chips ||
        prompt.inputType == JournalPromptInputType.mixed;
    final showText = prompt.inputType == JournalPromptInputType.shortText ||
        prompt.inputType == JournalPromptInputType.mixed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showChips) _buildChips(prompt.options),
        if (showText) ...[
          if (showChips) const SizedBox(height: 12),
          _buildTextField(prompt),
        ],
      ],
    );
  }

  Widget _buildChips(List<String> options) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = _selectedOptions.contains(option);
        return CosmicChip.choice(
          label: _controller.currentPrompt.labelForOption(option),
          isSelected: isSelected,
          color: widget.accentColor,
          onTap: () => _handleOptionToggle(option),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(JournalPrompt prompt) {
    final hint = prompt.domain == JournalPromptDomain.event
        ? 'Add a detail if you want...'
        : 'Short note (optional)';
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      maxLines: 2,
      style: StarboundTypography.body.copyWith(
        color: StarboundColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: StarboundTypography.body.copyWith(
          color: StarboundColors.textTertiary,
        ),
        filled: true,
        fillColor: StarboundColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: StarboundColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: StarboundColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: widget.accentColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}
