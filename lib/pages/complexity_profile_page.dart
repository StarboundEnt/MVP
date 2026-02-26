import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../models/complexity_profile.dart';
import '../providers/app_state.dart';
import '../design_system/design_system.dart';
import 'onboarding_page.dart';

class ComplexityProfilePage extends StatefulWidget {
  const ComplexityProfilePage({Key? key}) : super(key: key);

  @override
  State<ComplexityProfilePage> createState() => _ComplexityProfilePageState();
}

class _ComplexityProfilePageState extends State<ComplexityProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StarboundColors.background,
      body: Stack(
        children: [
          const _ComplexityBackground(),
          const _TwinklingStars(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(context),
                      const SizedBox(height: 32),
                      _buildCurrentProfileCard(context),
                      const SizedBox(height: 24),
                      _buildCategoryBreakdown(context),
                      const SizedBox(height: 24),
                      _buildInsightsSection(context),
                      const SizedBox(height: 24),
                      _buildHistorySection(context),
                      const SizedBox(height: 24),
                      _buildUpdateSection(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 20,
                    color: StarboundColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Profile",
                style: StarboundTypography.heading1.copyWith(
                  color: StarboundColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Understanding your complexity level",
                style: StarboundTypography.bodyLarge.copyWith(
                  color: StarboundColors.textSecondary,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentProfileCard(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final level = appState.complexityProfile;
        final effectiveLevel = appState.getEffectiveComplexityLevel();
        final assessment = appState.getCurrentComplexityAssessment();
        final hasLivedExperience = appState.hasComplexityProfileDiscrepancy();
        
        // Use effective level for display if there's a discrepancy
        final displayLevel = hasLivedExperience ? effectiveLevel : level;
        final levelMessage = ComplexityProfileService.getComplexityLevelMessage(displayLevel);
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _getLevelColor(displayLevel).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                  ...StarboundColors.cosmicGlow(
                    _getLevelColor(displayLevel).withValues(alpha: 0.2),
                    intensity: 0.1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Level indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getLevelColor(displayLevel).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getLevelColor(displayLevel).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Icon(
                          _getLevelIcon(displayLevel),
                          size: 16,
                          color: _getLevelColor(displayLevel),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            levelMessage,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: StarboundTypography.heading3.copyWith(
                              color: _getLevelColor(displayLevel),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Description
                  Text(
                    levelMessage,
                    textAlign: TextAlign.center,
                    style: StarboundTypography.bodyLarge.copyWith(
                      color: StarboundColors.textPrimary,
                      fontSize: 16,
                      height: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Approach
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.compass,
                              size: 16,
                              color: StarboundColors.stellarAqua,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Your Approach",
                              style: StarboundTypography.heading3.copyWith(
                                color: StarboundColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          assessment?.getApproach() ?? _getDefaultApproach(displayLevel),
                          style: StarboundTypography.bodyLarge.copyWith(
                            color: StarboundColors.textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final insights = appState.getCategoryInsights();
        final categories = ComplexityCategory.values
            .map((category) => insights[category])
            .whereType<Map<String, dynamic>>()
            .toList();

        categories.sort((a, b) {
          final aStress = (a['stressRatio'] as double? ?? 0.0);
          final bStress = (b['stressRatio'] as double? ?? 0.0);
          return bStress.compareTo(aStress);
        });
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Life Areas",
              style: StarboundTypography.heading2.copyWith(
                color: StarboundColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "How different areas of your life are affecting your capacity",
              style: StarboundTypography.bodyLarge.copyWith(
                color: StarboundColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.map((category) => _buildCategoryCard(category)),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final isStressful = category['isStressful'] as bool? ?? false;
    final color =
        isStressful ? StarboundColors.error : StarboundColors.stellarAqua;
    final statusLabel = category['statusLabel'] as String? ??
        (isStressful ? 'Needs support' : 'Supportive');
    final description = category['description'] as String? ?? '';
    final answers = category['answers'] as int? ?? 0;
    final hasResponses = category['hasResponses'] as bool? ?? false;
    final stressRatio = category['stressRatio'] as double?;
    final iconData = _resolveCategoryIcon(category['icon']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    iconData,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['name'] as String? ?? 'Life area',
                        style: StarboundTypography.heading3.copyWith(
                          color: StarboundColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: StarboundTypography.bodySmall.copyWith(
                          color: StarboundColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      if (stressRatio != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stressRatio,
                            minHeight: 4,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.05),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                      if (hasResponses) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Based on $answers recent answers',
                          style: StarboundTypography.caption.copyWith(
                            color: StarboundColors.textTertiary.withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: StarboundTypography.bodySmall.copyWith(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  IconData _resolveCategoryIcon(dynamic icon) {
    if (icon is IconData) {
      return icon;
    }
    final iconName = (icon as String?) ?? '';
    switch (iconName) {
      case 'home':
        return LucideIcons.home;
      case 'brain':
        return LucideIcons.brain;
      case 'heart':
        return LucideIcons.heart;
      case 'users':
        return LucideIcons.users;
      case 'clock':
        return LucideIcons.clock;
      case 'dollar-sign':
        return LucideIcons.dollarSign;
      case 'baby':
        return LucideIcons.baby;
      default:
        return LucideIcons.circle;
    }
  }

  Widget _buildInsightsSection(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final level = appState.complexityProfile;
        final assessment = appState.getCurrentComplexityAssessment();
        final insights = appState.getComplexityInsights();
        final hasLivedExperience = appState.hasComplexityProfileDiscrepancy();
        final effectiveLevel = appState.getEffectiveComplexityLevel();
        
        return Column(
          children: [
            // Lived Experience Section (if available)
            if (hasLivedExperience) ...[
              _buildLivedExperienceCard(appState, level, effectiveLevel),
              const SizedBox(height: 16),
            ],
            
            // Main Insights Section
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: StarboundColors.stellarYellow.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.lightbulb,
                            size: 20,
                            color: StarboundColors.stellarYellow,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Insights from Your Reflections",
                            style: StarboundTypography.heading3.copyWith(
                              color: StarboundColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Dynamic insights from reflections
                      if (insights.isNotEmpty) ...[
                        ...insights.map((insight) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildInsightItem(
                            "Pattern Detected",
                            insight,
                            LucideIcons.brain,
                          ),
                        )),
                        const SizedBox(height: 8),
                      ],
                      
                      // Static profile information
                      _buildInsightItem(
                        "Nudge Frequency",
                        _getNudgeFrequencyText(assessment?.getRecommendedNudgeFrequency() ?? const Duration(hours: 12)),
                        LucideIcons.clock,
                      ),
                      const SizedBox(height: 12),
                      _buildInsightItem(
                        "AI Response Style",
                        _getAIStyleText(effectiveLevel),
                        LucideIcons.messageSquare,
                      ),
                      const SizedBox(height: 12),
                      _buildInsightItem(
                        "Recommended Focus",
                        _getFocusText(effectiveLevel),
                        LucideIcons.target,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Recent Tags Section (if available)
            if (assessment?.recentTagFrequency?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _buildRecentTagsCard(assessment!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final history = appState.complexityHistory.reversed.take(5).toList();
        final trendScores = appState.complexityTrendScores;
        final hasTrend = trendScores.values.any((value) => value > 0.05);

        if (history.isEmpty && !hasTrend) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: StarboundColors.textSecondary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.compass,
                      size: 20,
                      color: StarboundColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Living profile in progress',
                            style: StarboundTypography.heading3.copyWith(
                              color: StarboundColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Keep logging reflections and habits to see how your capacity shifts over time.',
                            style: StarboundTypography.bodyMedium.copyWith(
                              color: StarboundColors.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: StarboundColors.textSecondary.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.activity,
                        size: 20,
                        color: StarboundColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recent shifts & trends',
                        style: StarboundTypography.heading3.copyWith(
                          color: StarboundColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (hasTrend) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: trendScores.entries
                          .where((entry) => entry.value > 0.05)
                          .map((entry) => _buildTrendChip(entry.key, entry.value))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  ...history.map((transition) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildHistoryItem(transition),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendChip(ComplexityLevel level, double score) {
    final percent = (score * 100).clamp(0, 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getLevelColor(level).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getLevelColor(level).withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(
            _getLevelIcon(level),
            size: 14,
            color: _getLevelColor(level),
          ),
          const SizedBox(width: 6),
          Text(
            '${ComplexityProfileService.getComplexityLevelTagline(level)} ${(percent as num).toStringAsFixed(0)}%',
            style: StarboundTypography.bodySmall.copyWith(
              color: _getLevelColor(level),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ComplexityProfileTransition transition) {
    final toMessage =
        ComplexityProfileService.getComplexityLevelTagline(transition.toLevel);
    final fromMessage =
        ComplexityProfileService.getComplexityLevelTagline(transition.fromLevel);
    final relativeTime = _formatRelativeTime(transition.timestamp);
    final highlightColor = _getLevelColor(transition.toLevel);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlightColor.withValues(alpha: 0.18),
            border: Border.all(color: highlightColor.withValues(alpha: 0.35)),
          ),
          child: Icon(
            _getLevelIcon(transition.toLevel),
            size: 18,
            color: highlightColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                toMessage,
                style: StarboundTypography.heading4.copyWith(
                  color: StarboundColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$relativeTime • previously $fromMessage',
                style: StarboundTypography.bodySmall.copyWith(
                  color: StarboundColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                transition.reason,
                style: StarboundTypography.bodyMedium.copyWith(
                  color: StarboundColors.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (transition.confidence != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Confidence ${(transition.confidence! * 100).toStringAsFixed(0)}%',
                  style: StarboundTypography.bodySmall.copyWith(
                    color: StarboundColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
    if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    return 'just now';
  }

  Widget _buildInsightItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: StarboundColors.stellarYellow.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: StarboundTypography.bodyLarge.copyWith(
                  color: StarboundColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: StarboundTypography.bodySmall.copyWith(
                  color: StarboundColors.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLivedExperienceCard(AppState appState, ComplexityLevel staticLevel, ComplexityLevel effectiveLevel) {
    final assessment = appState.getCurrentComplexityAssessment();
    if (assessment == null) return const SizedBox.shrink();
    
    final confidence = assessment.livedExperienceConfidence ?? 0.0;
    final confidenceText = "${(confidence * 100).round()}%";
    final isHigherComplexity = _getComplexityLevelIndex(effectiveLevel) > _getComplexityLevelIndex(staticLevel);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isHigherComplexity 
                ? StarboundColors.warning.withValues(alpha: 0.1)
                : StarboundColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHigherComplexity 
                  ? StarboundColors.warning.withValues(alpha: 0.3)
                  : StarboundColors.success.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isHigherComplexity ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 20,
                    color: isHigherComplexity ? StarboundColors.warning : StarboundColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Lived Experience Insight",
                    style: StarboundTypography.heading3.copyWith(
                      color: StarboundColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHigherComplexity 
                          ? StarboundColors.warning.withValues(alpha: 0.2)
                          : StarboundColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      confidenceText,
                      style: StarboundTypography.bodySmall.copyWith(
                        color: isHigherComplexity ? StarboundColors.warning : StarboundColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                assessment.getLivedExperienceInsight(),
                style: StarboundTypography.bodyLarge.copyWith(
                  color: StarboundColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildProfileBadge(staticLevel, "Assessment", false),
                  const SizedBox(width: 12),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 16,
                    color: StarboundColors.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  _buildProfileBadge(effectiveLevel, "Reflections", true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileBadge(ComplexityLevel level, String label, bool isHighlighted) {
    final color = _getLevelColor(level);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHighlighted ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: isHighlighted ? Border.all(color: color.withValues(alpha: 0.4), width: 1) : null,
          ),
          child: Text(
            ComplexityProfileService.getComplexityLevelTagline(level),
            style: StarboundTypography.bodySmall.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: StarboundTypography.bodySmall.copyWith(
            color: StarboundColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentTagsCard(ComplexityAssessment assessment) {
    final tagFrequency = assessment.recentTagFrequency!;
    final criticalTags = assessment.criticalIndicators ?? [];
    final positiveTags = assessment.positiveIndicators ?? [];
    
    // Get top 6 most frequent tags
    final sortedTags = tagFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(6).toList();
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: StarboundColors.stellarAqua.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.tag,
                    size: 20,
                    color: StarboundColors.stellarAqua,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Recent Reflection Patterns",
                    style: StarboundTypography.heading3.copyWith(
                      color: StarboundColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topTags.map((entry) {
                  final tag = entry.key;
                  final count = entry.value;
                  final isCritical = criticalTags.contains(tag);
                  final isPositive = positiveTags.contains(tag);
                  
                  Color tagColor = StarboundColors.stellarAqua;
                  if (isCritical) {
                    tagColor = StarboundColors.error;
                  } else if (isPositive) {
                    tagColor = StarboundColors.success;
                  }
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tagColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          tag.replaceAll('_', ' '),
                          style: StarboundTypography.bodySmall.copyWith(
                            color: tagColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            count.toString(),
                            style: StarboundTypography.bodySmall.copyWith(
                              color: tagColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  int _getComplexityLevelIndex(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable: return 0;
      case ComplexityLevel.trying: return 1;
      case ComplexityLevel.overloaded: return 2;
      case ComplexityLevel.survival: return 3;
    }
  }

  Widget _buildUpdateSection(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _retakeAssessment,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: StarboundColors.stellarAqua.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: StarboundColors.stellarAqua.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: StarboundColors.cosmicGlow(
                  StarboundColors.stellarAqua,
                  intensity: 0.05,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.refreshCw,
                    size: 24,
                    color: StarboundColors.stellarAqua,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Update Your Profile",
                    style: StarboundTypography.heading3.copyWith(
                      color: StarboundColors.stellarAqua,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Life changes? Take the assessment again to get better personalized support",
                    textAlign: TextAlign.center,
                    style: StarboundTypography.bodyLarge.copyWith(
                      color: StarboundColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
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

  void _retakeAssessment() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OnboardingPage(
          onComplete: () {
            Navigator.of(context).pop(); // Close onboarding
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(LucideIcons.checkCircle, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Profile updated successfully!'),
                  ],
                ),
                backgroundColor: StarboundColors.success,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
            ),
            child: child,
          );
        },
      ),
    );
  }

  // Helper methods for colors and data
  Color _getLevelColor(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return StarboundColors.success;
      case ComplexityLevel.trying:
        return StarboundColors.stellarYellow;
      case ComplexityLevel.overloaded:
        return StarboundColors.warning;
      case ComplexityLevel.survival:
        return StarboundColors.error;
    }
  }

  IconData _getLevelIcon(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return LucideIcons.check;
      case ComplexityLevel.trying:
        return LucideIcons.trendingUp;
      case ComplexityLevel.overloaded:
        return LucideIcons.zap;
      case ComplexityLevel.survival:
        return LucideIcons.shield;
    }
  }
  String _getNudgeFrequencyText(Duration frequency) {
    if (frequency.inHours < 24) {
      return "Every ${frequency.inHours} hours - frequent gentle reminders";
    } else {
      return "Every ${frequency.inDays} day${frequency.inDays > 1 ? 's' : ''} - space to breathe";
    }
  }

  String _getAIStyleText(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return "Growth-focused with challenges and goal-setting";
      case ComplexityLevel.trying:
        return "Encouraging with flexible, manageable suggestions";
      case ComplexityLevel.overloaded:
        return "Gentle and non-demanding, focused on maintenance";
      case ComplexityLevel.survival:
        return "Immediate support with crisis-aware responses";
    }
  }

  String _getFocusText(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return "Building new habits and long-term growth";
      case ComplexityLevel.trying:
        return "Small wins and celebrating progress";
      case ComplexityLevel.overloaded:
        return "Maintaining essentials without pressure";
      case ComplexityLevel.survival:
        return "Getting through today, one moment at a time";
    }
  }

  String _getDefaultApproach(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return "Build sustainable habits, set meaningful goals, and explore new areas of growth. You can handle complexity and long-term planning.";
      case ComplexityLevel.trying:
        return "Focus on one small thing at a time, celebrate micro-wins, and be flexible with your goals. Some days will be better than others.";
      case ComplexityLevel.overloaded:
        return "Prioritize bare essentials, use shortcuts and convenience options, and don't add pressure to change. Maintenance is success.";
      case ComplexityLevel.survival:
        return "Any small step counts as a victory. Focus on immediate needs, use all available support, and remember that this phase will pass.";
    }
  }
}

// Background components
class _ComplexityBackground extends StatelessWidget {
  const _ComplexityBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: StarboundColors.deepSpace,
    );
  }
}

class _TwinklingStars extends StatefulWidget {
  const _TwinklingStars();

  @override
  State<_TwinklingStars> createState() => _TwinklingStarsState();
}

class _TwinklingStarsState extends State<_TwinklingStars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _StarPainter(_controller.value),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  final double animationValue;

  _StarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < 20; i++) {
      final x = (size.width * 0.1 + (i * 47.3)) % size.width;
      final y = (size.height * 0.2 + (i * 31.7)) % size.height;
      
      final phase = (i * 0.3) % 1.0;
      final opacity = 0.1 + (0.3 * ((animationValue + phase) % 1.0));
      
      paint.color = StarboundColors.stellarAqua.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 1.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
