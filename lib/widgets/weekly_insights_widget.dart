import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../services/journal_insights_service.dart';
import '../design_system/design_system.dart';

/// Widget that displays weekly insights and patterns from journal entries
class WeeklyInsightsWidget extends StatefulWidget {
  final List<WeeklyInsight> insights;
  final Map<String, dynamic> weeklySummary;
  final VoidCallback? onViewAll;
  final VoidCallback? onRefresh;

  const WeeklyInsightsWidget({
    Key? key,
    required this.insights,
    required this.weeklySummary,
    this.onViewAll,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<WeeklyInsightsWidget> createState() => _WeeklyInsightsWidgetState();
}

class _WeeklyInsightsWidgetState extends State<WeeklyInsightsWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  int _currentInsightIndex = 0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty && widget.weeklySummary['total_entries'] == 0) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    StarboundColors.stellarAqua.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: StarboundColors.stellarAqua.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  
                  if (widget.weeklySummary['total_entries'] > 0) ...[
                    _buildWeeklySummary(),
                    const SizedBox(height: 16),
                  ],
                  
                  if (widget.insights.isNotEmpty) ...[
                    _buildMainInsight(),
                    const SizedBox(height: 16),
                  ],
                  
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: StarboundColors.stellarAqua.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            LucideIcons.trendingUp,
            size: 20,
            color: StarboundColors.stellarAqua,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Insights',
                style: StarboundTypography.heading3.copyWith(
                  color: StarboundColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Patterns from your health journal',
                style: StarboundTypography.bodySmall.copyWith(
                  color: StarboundColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (widget.onRefresh != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onRefresh,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  LucideIcons.refreshCw,
                  size: 16,
                  color: StarboundColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklySummary() {
    final summary = widget.weeklySummary;
    final totalEntries = summary['total_entries'] as int;
    final topTags = List<Map<String, dynamic>>.from(summary['top_tags'] ?? []);
    final averageMood = summary['average_mood'] as String;

    return Container(
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
                LucideIcons.calendar,
                size: 14,
                color: StarboundColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'This week at a glance',
                style: StarboundTypography.bodyLarge.copyWith(
                  color: StarboundColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Entry count and mood
          Row(
            children: [
              _buildSummaryItem(
                icon: LucideIcons.edit3,
                label: '$totalEntries ${totalEntries == 1 ? 'entry' : 'entries'}',
                color: StarboundColors.stellarAqua,
              ),
              const SizedBox(width: 16),
              _buildSummaryItem(
                icon: _getMoodIcon(averageMood),
                label: '${_capitalize(averageMood)} mood',
                color: _getMoodColor(averageMood),
              ),
            ],
          ),
          
          // Top tags
          if (topTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Top themes:',
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: topTags.map((tagData) {
                final tag = tagData['tag'] as String;
                final count = tagData['count'] as int;
                return _buildTagChip(tag, count);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: StarboundTypography.bodySmall.copyWith(
            color: StarboundColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: StarboundColors.stellarYellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: StarboundColors.stellarYellow.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        '$tag ($count)',
        style: StarboundTypography.bodySmall.copyWith(
          color: StarboundColors.stellarYellow,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMainInsight() {
    if (widget.insights.isEmpty) return const SizedBox.shrink();

    final insight = widget.insights[_currentInsightIndex];
    final hasMultiple = widget.insights.length > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getInsightCategoryColor(insight.category).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getInsightCategoryColor(insight.category).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getInsightCategoryColor(insight.category).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getInsightCategoryIcon(insight.category),
                  size: 16,
                  color: _getInsightCategoryColor(insight.category),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.title,
                  style: StarboundTypography.bodyLarge.copyWith(
                    color: StarboundColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasMultiple) _buildInsightNavigation(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.description,
            style: StarboundTypography.bodyLarge.copyWith(
              color: StarboundColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildConfidenceIndicator(insight.confidence),
        ],
      ),
    );
  }

  Widget _buildInsightNavigation() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_currentInsightIndex + 1}/${widget.insights.length}',
          style: StarboundTypography.bodySmall.copyWith(
            color: StarboundColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _previousInsight,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 14,
                color: _currentInsightIndex > 0 
                  ? StarboundColors.textSecondary 
                  : StarboundColors.textTertiary,
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _nextInsight,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: _currentInsightIndex < widget.insights.length - 1 
                  ? StarboundColors.textSecondary 
                  : StarboundColors.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    final percentage = (confidence * 100).round();
    
    return Row(
      children: [
        Icon(
          LucideIcons.target,
          size: 12,
          color: StarboundColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          '$percentage% confidence',
          style: StarboundTypography.bodySmall.copyWith(
            color: StarboundColors.textTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: confidence,
              child: Container(
                decoration: BoxDecoration(
                  color: StarboundColors.stellarAqua,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (widget.insights.isNotEmpty) ...[
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onViewAll,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.eye,
                        size: 14,
                        color: StarboundColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'View All Insights',
                        style: StarboundTypography.bodySmall.copyWith(
                          color: StarboundColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: Text(
              'Keep journaling to discover more patterns!',
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.lightbulb,
            size: 32,
            color: StarboundColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Your insights will appear here',
            style: StarboundTypography.bodyLarge.copyWith(
              color: StarboundColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start journaling to discover patterns and trends',
            style: StarboundTypography.bodySmall.copyWith(
              color: StarboundColors.textTertiary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _previousInsight() {
    if (_currentInsightIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentInsightIndex--;
      });
    }
  }

  void _nextInsight() {
    if (_currentInsightIndex < widget.insights.length - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentInsightIndex++;
      });
    }
  }

  Color _getInsightCategoryColor(String category) {
    switch (category) {
      case 'mood':
        return StarboundColors.stellarYellow;
      case 'correlation':
        return StarboundColors.stellarAqua;
      case 'growth':
        return StarboundColors.success;
      case 'concern':
        return StarboundColors.warning;
      default:
        return StarboundColors.nebulaPurple;
    }
  }

  IconData _getInsightCategoryIcon(String category) {
    switch (category) {
      case 'mood':
        return LucideIcons.heart;
      case 'correlation':
        return LucideIcons.link;
      case 'growth':
        return LucideIcons.trendingUp;
      case 'concern':
        return LucideIcons.alertTriangle;
      default:
        return LucideIcons.sparkles;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'positive':
        return LucideIcons.smile;
      case 'negative':
        return LucideIcons.frown;
      default:
        return LucideIcons.meh;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'positive':
        return StarboundColors.success;
      case 'negative':
        return StarboundColors.warning;
      default:
        return StarboundColors.textSecondary;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}