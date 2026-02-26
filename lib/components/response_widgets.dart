import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/starbound_response.dart';
import '../design_system/colors.dart';
import '../design_system/design_system.dart';

/// Widget that displays the main overview/insight from Starbound's response
class ResponseOverviewWidget extends StatelessWidget {
  final String overview;
  final String? mood;
  final double? confidence;

  const ResponseOverviewWidget({
    Key? key,
    required this.overview,
    this.mood,
    this.confidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final highContrast = mediaQuery?.highContrast ?? false;

    final baseContainer = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highContrast
            ? StarboundColors.surfaceElevated
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highContrast
              ? StarboundColors.borderSubtle.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.18),
          width: 1.5,
        ),
        boxShadow: highContrast
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: StarboundColors.stellarAqua.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 0),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StarboundColors.nebulaPurple.withValues(alpha: 0.18),
                  boxShadow: StarboundColors.cosmicGlow(
                    StarboundColors.nebulaPurple,
                    intensity: 0.25,
                  ),
                ),
                child: Icon(
                  LucideIcons.brain,
                  size: 18,
                  color: StarboundColors.nebulaPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Behavioural insight",
                      style: StarboundTypography.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (confidence != null)
                      Text(
                        "${(confidence! * 100).round()}% confidence",
                        style: StarboundTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (mood != null) _buildMoodIndicator(mood!),
            ],
          ),
          const SizedBox(height: 16),
          _buildMarkdownText(overview),
        ],
      ),
    );

    final content = highContrast
        ? baseContainer
        : BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: baseContainer,
          );

    return Semantics(
      label: 'Behavioural insight',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }

  Widget _buildMarkdownText(String text) {
    final List<InlineSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');

    final baseStyle = StarboundTypography.bodyLarge.copyWith(
      color: Colors.white.withValues(alpha: 0.95),
      fontSize: 17,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );

    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: Colors.white.withValues(alpha: 0.98),
    );

    int lastEnd = 0;
    for (final Match match in boldPattern.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // Add the bold part
      spans.add(TextSpan(
        text: match.group(1) ?? '',
        style: boldStyle,
      ));

      lastEnd = match.end;
    }

    // Add remaining text after the last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    // If no bold text found, return normal text
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: baseStyle,
      ));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      semanticsLabel: text.replaceAll('**', ''),
    );
  }

  Widget _buildMoodIndicator(String mood) {
    IconData icon;
    Color color;

    switch (mood.toLowerCase()) {
      case 'encouraging':
        icon = LucideIcons.thumbsUp;
        color = StarboundColors.stellarAqua;
        break;
      case 'gentle':
        icon = LucideIcons.heart;
        color = StarboundColors.cosmicPink;
        break;
      case 'supportive':
        icon = LucideIcons.shield;
        color = StarboundColors.starlightBlue;
        break;
      case 'energetic':
        icon = LucideIcons.zap;
        color = StarboundColors.stellarYellow;
        break;
      default:
        icon = LucideIcons.messageCircle;
        color = StarboundColors.nebulaPurple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
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
          const SizedBox(width: 4),
          Text(
            mood,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays immediate actionable steps with checkboxes
class ImmediateStepsWidget extends StatefulWidget {
  final List<ActionableStep> steps;
  final Function(ActionableStep)? onStepToggled;
  final bool showProgress;

  const ImmediateStepsWidget({
    Key? key,
    required this.steps,
    this.onStepToggled,
    this.showProgress = true,
  }) : super(key: key);

  @override
  State<ImmediateStepsWidget> createState() => _ImmediateStepsWidgetState();
}

class _ImmediateStepsWidgetState extends State<ImmediateStepsWidget> {
  late List<ActionableStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = List.from(widget.steps);
  }

  @override
  void didUpdateWidget(ImmediateStepsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.steps != oldWidget.steps) {
      _steps = List.from(widget.steps);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) return const SizedBox.shrink();

    final completedCount = _steps.where((step) => step.completed).length;
    final progress = _steps.isNotEmpty ? completedCount / _steps.length : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: StarboundColors.cosmicPink.withValues(alpha: 0.08),
                blurRadius: 15,
                spreadRadius: -3,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with progress
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: StarboundColors.cosmicPink.withValues(alpha: 0.15),
                      boxShadow: StarboundColors.cosmicGlow(
                        StarboundColors.cosmicPink,
                        intensity: 0.2,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.checkSquare,
                      size: 16,
                      color: StarboundColors.cosmicPink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Take Action Now",
                          style: StarboundTypography.heading3.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.showProgress)
                          Text(
                            "$completedCount of ${_steps.length} completed",
                            style: StarboundTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.showProgress) _buildProgressIndicator(progress),
                ],
              ),

              const SizedBox(height: 16),

              // Steps list
              ..._steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index < _steps.length - 1 ? 12 : 0),
                  child: _buildStepItem(step, index),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(ActionableStep step, int index) {
    return GestureDetector(
      onTap: () => _toggleStep(step),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: step.completed
              ? StarboundColors.stellarAqua.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: step.completed
                ? StarboundColors.stellarAqua.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Step number/checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.completed
                    ? StarboundColors.stellarAqua
                    : Colors.transparent,
                border: Border.all(
                  color: step.completed
                      ? StarboundColors.stellarAqua
                      : Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: step.completed
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // Step content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.text,
                    style: TextStyle(
                      color: step.completed
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.95),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration:
                          step.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (step.estimatedTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "≈ ${step.estimatedTime}",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Optional icon
            if (step.icon != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  step.icon,
                  size: 18,
                  color: step.color ?? Colors.white.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Container(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                StarboundColors.stellarAqua,
              ),
            ),
          ),
          // Progress text
          Center(
            child: Text(
              "${(progress * 100).round()}%",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleStep(ActionableStep step) {
    setState(() {
      final index = _steps.indexWhere((s) => s.id == step.id);
      if (index != -1) {
        _steps[index] = step.copyWith(completed: !step.completed);
        widget.onStepToggled?.call(_steps[index]);
      }
    });
  }
}

/// Widget that displays follow-up recommendations and future considerations
class NextStepsWidget extends StatefulWidget {
  final List<NextStepItem> nextSteps;
  final Function(NextStepItem)? onItemSaved;
  final Function(NextStepItem)? onItemTapped;

  const NextStepsWidget({
    Key? key,
    required this.nextSteps,
    this.onItemSaved,
    this.onItemTapped,
  }) : super(key: key);

  @override
  State<NextStepsWidget> createState() => _NextStepsWidgetState();
}

class _NextStepsWidgetState extends State<NextStepsWidget> {
  late List<NextStepItem> _nextSteps;

  @override
  void initState() {
    super.initState();
    _nextSteps = List.from(widget.nextSteps);
  }

  @override
  void didUpdateWidget(NextStepsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nextSteps != oldWidget.nextSteps) {
      _nextSteps = List.from(widget.nextSteps);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_nextSteps.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: StarboundColors.nebulaPurple.withValues(alpha: 0.06),
                blurRadius: 12,
                spreadRadius: -2,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          StarboundColors.nebulaPurple.withValues(alpha: 0.15),
                      boxShadow: StarboundColors.cosmicGlow(
                        StarboundColors.nebulaPurple,
                        intensity: 0.15,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.compass,
                      size: 16,
                      color: StarboundColors.nebulaPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Consider Next",
                    style: StarboundTypography.heading3.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Next steps list
              ..._nextSteps.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index < _nextSteps.length - 1 ? 10 : 0),
                  child: _buildNextStepItem(item),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextStepItem(NextStepItem item) {
    return GestureDetector(
      onTap: () => widget.onItemTapped?.call(item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Category indicator
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getCategoryColor(item.category),
              ),
            ),

            const SizedBox(width: 12),

            // Item content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (item.relatedFeature != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "→ ${item.relatedFeature}",
                        style: TextStyle(
                          color: _getCategoryColor(item.category)
                              .withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Save button
            GestureDetector(
              onTap: () => _toggleSaved(item),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isSaved
                      ? StarboundColors.stellarYellow.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  item.isSaved
                      ? LucideIcons.bookmark
                      : LucideIcons.bookmarkPlus,
                  size: 16,
                  color: item.isSaved
                      ? StarboundColors.stellarYellow
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'monitor':
        return StarboundColors.starlightBlue;
      case 'explore':
        return StarboundColors.cosmicPink;
      case 'consider':
        return StarboundColors.nebulaPurple;
      case 'track':
        return StarboundColors.stellarAqua;
      default:
        return StarboundColors.textSecondary;
    }
  }

  void _toggleSaved(NextStepItem item) {
    setState(() {
      final index = _nextSteps.indexWhere((s) => s.id == item.id);
      if (index != -1) {
        _nextSteps[index] = item.copyWith(isSaved: !item.isSaved);
        widget.onItemSaved?.call(_nextSteps[index]);
      }
    });
  }
}

/// Widget that extracts and displays structured steps from AI response text
class StepsExtractorWidget extends StatefulWidget {
  final String? responseText;
  final List<ExtractedStep>? preExtractedSteps;
  final Function(ExtractedStep)? onStepToggled;
  final Function(ExtractedStep)? onStepSavedToVault;
  final bool showProgress;

  const StepsExtractorWidget({
    Key? key,
    this.responseText,
    this.preExtractedSteps,
    this.onStepToggled,
    this.onStepSavedToVault,
    this.showProgress = true,
  }) : super(key: key);

  @override
  State<StepsExtractorWidget> createState() => _StepsExtractorWidgetState();
}

class _StepsExtractorWidgetState extends State<StepsExtractorWidget> {
  late List<ExtractedStep> _extractedSteps;

  void _limitSteps() {
    if (_extractedSteps.length > 5) {
      _extractedSteps = _extractedSteps.take(5).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.preExtractedSteps != null) {
      _extractedSteps = List.from(widget.preExtractedSteps!);
    } else if (widget.responseText != null) {
      _extractedSteps = _extractStepsFromText(widget.responseText!);
    } else {
      _extractedSteps = [];
    }
    _limitSteps();
  }

  @override
  void didUpdateWidget(StepsExtractorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.preExtractedSteps != null &&
        widget.preExtractedSteps != oldWidget.preExtractedSteps) {
      _extractedSteps = List.from(widget.preExtractedSteps!);
    } else if (widget.responseText != null &&
        widget.responseText != oldWidget.responseText) {
      _extractedSteps = _extractStepsFromText(widget.responseText!);
    }
    _limitSteps();
  }

  /// Extract structured steps from AI response text
  List<ExtractedStep> _extractStepsFromText(String text) {
    final List<ExtractedStep> steps = [];

    // Pattern to match various step formats:
    // **Step 1: Title** Description
    // Step 1: Title - Description
    // 1. Title: Description
    // **1. Title** Description
    final stepPatterns = [
      RegExp(
          r'\*\*Step\s+(\d+)[:.]?\s*([^*]*?)\*\*\s*(.+?)(?=(?:\*\*Step\s+\d+|$))',
          caseSensitive: false,
          multiLine: true,
          dotAll: true),
      RegExp(r'Step\s+(\d+)[:.]?\s*([^-\n]+?)[-:]?\s*(.+?)(?=(?:Step\s+\d+|$))',
          caseSensitive: false, multiLine: true, dotAll: true),
      RegExp(r'\*\*(\d+)\.?\s*([^*]*?)\*\*\s*(.+?)(?=(?:\*\*\d+\.|$))',
          multiLine: true, dotAll: true),
      RegExp(r'^(\d+)\.?\s*([^:\n]+?)[:.]?\s*(.+?)(?=(?:^\d+\.|$))',
          multiLine: true, dotAll: true),
    ];

    for (final pattern in stepPatterns) {
      final matches = pattern.allMatches(text);

      for (final match in matches) {
        final stepNumber = int.tryParse(match.group(1) ?? '0') ?? 0;
        final title = (match.group(2) ?? '').trim();
        final description = (match.group(3) ?? '').trim();

        if (stepNumber > 0 && (title.isNotEmpty || description.isNotEmpty)) {
          // Combine title and description intelligently
          String fullText;
          if (title.isNotEmpty && description.isNotEmpty) {
            // If title ends with punctuation, don't add colon
            final separator = title.endsWith('.') ||
                    title.endsWith(':') ||
                    title.endsWith('!') ||
                    title.endsWith('?')
                ? ' '
                : ': ';
            fullText = '$title$separator$description';
          } else {
            fullText = title.isNotEmpty ? title : description;
          }

          // Clean up the text
          fullText = fullText
              .replaceAll('\n', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // Extract time estimate if present
          final timeMatch = RegExp(r'(\d+)\s*(minute|min|second|sec|hour|hr)s?',
                  caseSensitive: false)
              .firstMatch(fullText);
          String? estimatedTime;
          if (timeMatch != null) {
            estimatedTime = '${timeMatch.group(1)} ${timeMatch.group(2)}';
          }

          steps.add(ExtractedStep(
            id: 'extracted_$stepNumber',
            stepNumber: stepNumber,
            text: fullText,
            estimatedTime: estimatedTime,
            completed: false,
          ));
        }
      }

      // If we found steps with this pattern, use them and stop
      if (steps.isNotEmpty) {
        break;
      }
    }

    // Sort by step number and return
    steps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    if (_extractedSteps.isEmpty) return const SizedBox.shrink();

    final completedCount =
        _extractedSteps.where((step) => step.completed).length;
    final progress = _extractedSteps.isNotEmpty
        ? completedCount / _extractedSteps.length
        : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: StarboundColors.stellarAqua.withValues(alpha: 0.08),
                blurRadius: 15,
                spreadRadius: -3,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with progress
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          StarboundColors.stellarAqua.withValues(alpha: 0.15),
                      boxShadow: StarboundColors.cosmicGlow(
                        StarboundColors.stellarAqua,
                        intensity: 0.2,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.listChecks,
                      size: 16,
                      color: StarboundColors.stellarAqua,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Action plan",
                          style: StarboundTypography.heading3.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.showProgress)
                          Text(
                            "$completedCount of ${_extractedSteps.length} completed",
                            style: StarboundTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.showProgress) _buildProgressIndicator(progress),
                ],
              ),

              const SizedBox(height: 16),

              // Extracted steps list
              ..._extractedSteps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index < _extractedSteps.length - 1 ? 12 : 0),
                  child: _buildExtractedStepItem(step),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtractedStepItem(ExtractedStep step) {
    return GestureDetector(
      onTap: () => _toggleStep(step),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: step.completed
              ? StarboundColors.stellarAqua.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: step.completed
                ? StarboundColors.stellarAqua.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Step number/checkbox
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.completed
                    ? StarboundColors.stellarAqua
                    : Colors.transparent,
                border: Border.all(
                  color: step.completed
                      ? StarboundColors.stellarAqua
                      : Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: step.completed
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : Center(
                      child: Text(
                        '${step.stepNumber}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),

            const SizedBox(width: 14),

            // Step content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepMarkdownText(
                    step.text,
                    isCompleted: step.completed,
                  ),
                  if (step.estimatedTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            step.estimatedTime!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Add to vault button
            if (widget.onStepSavedToVault != null)
              GestureDetector(
                onTap: () => widget.onStepSavedToVault!(step),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color:
                        StarboundColors.stellarYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          StarboundColors.stellarYellow.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.bookmarkPlus,
                        size: 14,
                        color: StarboundColors.stellarYellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add to Vault',
                        style: TextStyle(
                          color: StarboundColors.stellarYellow,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Container(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                StarboundColors.stellarAqua,
              ),
            ),
          ),
          // Progress text
          Center(
            child: Text(
              "${(progress * 100).round()}%",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleStep(ExtractedStep step) {
    setState(() {
      final index = _extractedSteps.indexWhere((s) => s.id == step.id);
      if (index != -1) {
        _extractedSteps[index] = step.copyWith(completed: !step.completed);
        widget.onStepToggled?.call(_extractedSteps[index]);
      }
    });
  }

  Widget _buildStepMarkdownText(String text, {required bool isCompleted}) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');

    int lastEnd = 0;
    for (final Match match in boldPattern.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            color: isCompleted
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.95),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            height: 1.4,
          ),
        ));
      }

      // Add the bold part
      spans.add(TextSpan(
        text: match.group(1) ?? '',
        style: TextStyle(
          color: isCompleted
              ? Colors.white.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.98),
          fontSize: 15,
          fontWeight: FontWeight.w700, // Bold
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          height: 1.4,
        ),
      ));

      lastEnd = match.end;
    }

    // Add remaining text after the last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          color: isCompleted
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.95),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          height: 1.4,
        ),
      ));
    }

    // If no bold text found, return normal text
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: isCompleted
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.95),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          height: 1.4,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

/// Model for steps extracted from AI response text
class ExtractedStep {
  final String id;
  final int stepNumber;
  final String text;
  final String? estimatedTime;
  final bool completed;

  const ExtractedStep({
    required this.id,
    required this.stepNumber,
    required this.text,
    this.estimatedTime,
    this.completed = false,
  });

  ExtractedStep copyWith({
    String? id,
    int? stepNumber,
    String? text,
    String? estimatedTime,
    bool? completed,
  }) {
    return ExtractedStep(
      id: id ?? this.id,
      stepNumber: stepNumber ?? this.stepNumber,
      text: text ?? this.text,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() {
    return 'ExtractedStep(id: $id, stepNumber: $stepNumber, completed: $completed)';
  }
}

/// Widget that extracts and displays "Next Steps" from AI response text
class NextStepsExtractorWidget extends StatefulWidget {
  final String? responseText;
  final List<ExtractedNextStep>? preExtractedNextSteps;
  final Function(ExtractedNextStep)? onNextStepToggled;
  final bool showSaveOption;

  const NextStepsExtractorWidget({
    Key? key,
    this.responseText,
    this.preExtractedNextSteps,
    this.onNextStepToggled,
    this.showSaveOption = true,
  }) : super(key: key);

  @override
  State<NextStepsExtractorWidget> createState() =>
      _NextStepsExtractorWidgetState();
}

class _NextStepsExtractorWidgetState extends State<NextStepsExtractorWidget> {
  late List<ExtractedNextStep> _extractedNextSteps;

  @override
  void initState() {
    super.initState();
    if (widget.preExtractedNextSteps != null) {
      _extractedNextSteps = List.from(widget.preExtractedNextSteps!);
    } else if (widget.responseText != null) {
      _extractedNextSteps = _extractNextStepsFromText(widget.responseText!);
    } else {
      _extractedNextSteps = [];
    }
  }

  @override
  void didUpdateWidget(NextStepsExtractorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.preExtractedNextSteps != null &&
        widget.preExtractedNextSteps != oldWidget.preExtractedNextSteps) {
      _extractedNextSteps = List.from(widget.preExtractedNextSteps!);
    } else if (widget.responseText != null &&
        widget.responseText != oldWidget.responseText) {
      _extractedNextSteps = _extractNextStepsFromText(widget.responseText!);
    }
  }

  /// Extract "Next Steps" from AI response text
  List<ExtractedNextStep> _extractNextStepsFromText(String text) {
    final List<ExtractedNextStep> nextSteps = [];

    // Pattern to match various "Next Steps" formats:
    // **Next Steps:** 1) Item 2) Item
    // Next Steps: 1. Item 2. Item
    // **Next Steps** 1) Item 2) Item
    final nextStepsPatterns = [
      RegExp(r'\*\*Next\s+Steps?[:.]?\*\*\s*(.+?)(?=(?:\n\n|$))',
          caseSensitive: false, multiLine: true, dotAll: true),
      RegExp(r'Next\s+Steps?[:.]?\s*(.+?)(?=(?:\n\n|$))',
          caseSensitive: false, multiLine: true, dotAll: true),
      RegExp(r'\*\*Next[:.]?\*\*\s*(.+?)(?=(?:\n\n|$))',
          caseSensitive: false, multiLine: true, dotAll: true),
    ];

    for (final pattern in nextStepsPatterns) {
      final match = pattern.firstMatch(text);

      if (match != null) {
        final nextStepsContent = match.group(1)?.trim() ?? '';

        // Parse individual next steps from the content
        // Look for patterns like: 1) Item 2) Item or 1. Item 2. Item
        final itemPatterns = [
          RegExp(r'(\d+)\)\s*([^0-9]+?)(?=(?:\d+\)|$))', multiLine: true),
          RegExp(r'(\d+)\.?\s*([^0-9]+?)(?=(?:\d+\.|$))', multiLine: true),
        ];

        for (final itemPattern in itemPatterns) {
          final itemMatches = itemPattern.allMatches(nextStepsContent);

          if (itemMatches.isNotEmpty) {
            for (final itemMatch in itemMatches) {
              final itemNumber = int.tryParse(itemMatch.group(1) ?? '0') ?? 0;
              final itemText = (itemMatch.group(2) ?? '').trim();

              if (itemNumber > 0 && itemText.isNotEmpty) {
                // Clean up the text
                final cleanText = itemText
                    .replaceAll('\n', ' ')
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim();

                // Determine category based on content
                String category = 'consider';
                if (cleanText.toLowerCase().contains('schedule') ||
                    cleanText.toLowerCase().contains('track') ||
                    cleanText.toLowerCase().contains('monitor')) {
                  category = 'track';
                } else if (cleanText.toLowerCase().contains('explore') ||
                    cleanText.toLowerCase().contains('try') ||
                    cleanText.toLowerCase().contains('find')) {
                  category = 'explore';
                }

                nextSteps.add(ExtractedNextStep(
                  id: 'extracted_next_$itemNumber',
                  stepNumber: itemNumber,
                  text: cleanText,
                  category: category,
                  isSaved: false,
                ));
              }
            }
            break; // Use first successful pattern
          }
        }

        // If no numbered items found, treat the whole content as one next step
        if (nextSteps.isEmpty && nextStepsContent.isNotEmpty) {
          final cleanText = nextStepsContent
              .replaceAll('\n', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          nextSteps.add(ExtractedNextStep(
            id: 'extracted_next_1',
            stepNumber: 1,
            text: cleanText,
            category: 'consider',
            isSaved: false,
          ));
        }
        break; // Use first successful pattern
      }
    }

    // Sort by step number
    nextSteps.sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
    return nextSteps;
  }

  @override
  Widget build(BuildContext context) {
    if (_extractedNextSteps.isEmpty) return const SizedBox.shrink();

    final savedCount = _extractedNextSteps.where((step) => step.isSaved).length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: StarboundColors.nebulaPurple.withValues(alpha: 0.06),
                blurRadius: 12,
                spreadRadius: -2,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          StarboundColors.nebulaPurple.withValues(alpha: 0.15),
                      boxShadow: StarboundColors.cosmicGlow(
                        StarboundColors.nebulaPurple,
                        intensity: 0.15,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.arrowRight,
                      size: 16,
                      color: StarboundColors.nebulaPurple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Keep in Mind",
                          style: StarboundTypography.heading3.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.showSaveOption && savedCount > 0)
                          Text(
                            "$savedCount saved for later",
                            style: StarboundTypography.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Next steps list
              ..._extractedNextSteps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index < _extractedNextSteps.length - 1 ? 10 : 0),
                  child: _buildExtractedNextStepItem(step),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtractedNextStepItem(ExtractedNextStep step) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Step number indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getCategoryColor(step.category).withValues(alpha: 0.15),
              border: Border.all(
                color: _getCategoryColor(step.category).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: TextStyle(
                  color: _getCategoryColor(step.category),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Step content
          Expanded(
            child: Text(
              step.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),

          // Save button
          if (widget.showSaveOption)
            GestureDetector(
              onTap: () => _toggleSaved(step),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.isSaved
                      ? StarboundColors.stellarYellow.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  step.isSaved
                      ? LucideIcons.bookmark
                      : LucideIcons.bookmarkPlus,
                  size: 16,
                  color: step.isSaved
                      ? StarboundColors.stellarYellow
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'track':
        return StarboundColors.stellarAqua;
      case 'explore':
        return StarboundColors.cosmicPink;
      case 'consider':
        return StarboundColors.nebulaPurple;
      default:
        return StarboundColors.textSecondary;
    }
  }

  void _toggleSaved(ExtractedNextStep step) {
    setState(() {
      final index = _extractedNextSteps.indexWhere((s) => s.id == step.id);
      if (index != -1) {
        _extractedNextSteps[index] = step.copyWith(isSaved: !step.isSaved);
        widget.onNextStepToggled?.call(_extractedNextSteps[index]);
      }
    });
  }
}

/// Model for next steps extracted from AI response text
class ExtractedNextStep {
  final String id;
  final int stepNumber;
  final String text;
  final String category;
  final bool isSaved;

  const ExtractedNextStep({
    required this.id,
    required this.stepNumber,
    required this.text,
    required this.category,
    this.isSaved = false,
  });

  ExtractedNextStep copyWith({
    String? id,
    int? stepNumber,
    String? text,
    String? category,
    bool? isSaved,
  }) {
    return ExtractedNextStep(
      id: id ?? this.id,
      stepNumber: stepNumber ?? this.stepNumber,
      text: text ?? this.text,
      category: category ?? this.category,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  String toString() {
    return 'ExtractedNextStep(id: $id, stepNumber: $stepNumber, category: $category, isSaved: $isSaved)';
  }
}

/// Widget that displays contextual action buttons based on response content
class ContextualActionsWidget extends StatelessWidget {
  final List<ContextualAction> actions;
  final MainAxisAlignment alignment;

  const ContextualActionsWidget({
    Key? key,
    required this.actions,
    this.alignment = MainAxisAlignment.spaceEvenly,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children:
                actions.map((action) => _buildActionButton(action)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(ContextualAction action) {
    return GestureDetector(
      onTap: action.onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: action.isPrimary
                  ? action.color.withValues(alpha: 0.15)
                  : action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: action.isPrimary
                    ? action.color.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.2),
                width: action.isPrimary ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
                if (action.isPrimary)
                  BoxShadow(
                    color: action.color.withValues(alpha: 0.15),
                    blurRadius: 6,
                    spreadRadius: -2,
                    offset: const Offset(0, 0),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  size: 16,
                  color: action.isPrimary ? action.color : Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  action.label,
                  style: TextStyle(
                    color: action.isPrimary ? action.color : Colors.white,
                    fontSize: 14,
                    fontWeight:
                        action.isPrimary ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
