import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/complexity_profile.dart';
import '../utils/constants.dart';
import '../components/achievement_banner.dart';
import '../components/skeleton_loading.dart';
import '../utils/tag_utils.dart';
import '../design_system/design_system.dart';

enum AnalyticsTimeRange { week, month, quarter, year }

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

const bool _kShowTopTagSection = false;

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> 
    with TickerProviderStateMixin {
  AnalyticsTimeRange _selectedTimeRange = AnalyticsTimeRange.week;
  String? _selectedHabit;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Map<String, int> _habitStreaks = {};
  Map<String, List<String>> _habitTrends = {};
  Map<String, double> _completionRates = {};
  Map<String, int> _weeklyProgress = {};
  List<MapEntry<String, int>> _topTagEntries = [];
  List<Map<String, dynamic>> _correlationInsights = [];
  List<dynamic> _habitCorrelations = [];
  List<dynamic> _successPatterns = [];
  List<Map<String, dynamic>> _actionableInsights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadAnalytics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Progressive loading for better perceived performance
  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appState = context.read<AppState>();

      // Track analytics view for achievements
      await appState.incrementAnalyticsViews();

      // Phase 1: Load essential data first (fast)
      await _loadEssentialData(appState);

      // Phase 2: Load analytics data (medium speed)
      await _loadAnalyticsData(appState);

      // Phase 3: Load advanced insights (slower, but runs in background)
      await _loadAdvancedInsights(appState);

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showRetryDialog();
      }
    }
  }

  // Phase 1: Load essential data first for immediate display
  Future<void> _loadEssentialData(AppState appState) async {
    final streaks = await appState.getHabitStreak();
    final completionRates = await _calculateCompletionRates(appState);
    final topTags = _kShowTopTagSection
        ? appState.getTopTags(
            limit: 6,
            timeframe: _getSelectedDuration(),
          )
        : <MapEntry<String, int>>[];

    setState(() {
      _habitStreaks = streaks;
      _completionRates = completionRates;
      _topTagEntries = topTags;
      // Show first phase of data
    });
  }

  // Phase 2: Load analytics data
  Future<void> _loadAnalyticsData(AppState appState) async {
    final trends = await appState.getHabitTrends();
    final weeklyProgress = await _calculateWeeklyProgress(appState);

    setState(() {
      _habitTrends = trends;
      _weeklyProgress = weeklyProgress;
      // Show second phase of data
    });
  }

  // Phase 3: Load advanced insights (most expensive operations)
  Future<void> _loadAdvancedInsights(AppState appState) async {
    final daysToAnalyze =
        _selectedTimeRange == AnalyticsTimeRange.week ? 14 : 30;

    // Load these in parallel since they're independent
    final results = await Future.wait([
      appState.getCorrelationInsights(daysToAnalyze: daysToAnalyze),
      appState.getHabitCorrelations(daysToAnalyze: daysToAnalyze),
      appState.getSuccessPatterns(analysisDepthDays: daysToAnalyze),
      appState.getActionableInsights(analysisDepthDays: daysToAnalyze),
    ]);

    setState(() {
      _correlationInsights = List<Map<String, dynamic>>.from(results[0]);
      _habitCorrelations = results[1];
      _successPatterns = results[2];
      _actionableInsights = List<Map<String, dynamic>>.from(results[3]);
      _isLoading = false; // All loading complete
    });
  }

  // Enhanced error handling with retry option
  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F0150),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFFF6B35)),
            SizedBox(width: 8),
            Text('Loading Failed', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Failed to load analytics data. This might be due to a network issue or heavy processing. Would you like to try again?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          CosmicButton.primary(
            size: CosmicButtonSize.small,
            accentColor: StarboundColors.stellarAqua,
            onPressed: () {
              Navigator.of(context).pop();
              _loadAnalytics();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, double>> _calculateCompletionRates(
      AppState appState) async {
    final rates = <String, double>{};
    final daysToAnalyze =
        _selectedTimeRange == AnalyticsTimeRange.week ? 7 : 30;

    // This would ideally use the storage service to get historical data
    // For now, we'll simulate based on current habits and streaks
    for (final habitKey in appState.habits.keys) {
      if (habitKey.isNotEmpty) {
        final streak = _habitStreaks[habitKey] ?? 0;
        // Simulate completion rate based on streak (longer streaks = higher consistency)
        final baseRate =
            streak > 0 ? (streak.clamp(0, daysToAnalyze) / daysToAnalyze) : 0.0;
        rates[habitKey] =
            (baseRate * 0.8 + 0.1).clamp(0.0, 1.0); // Add some realism
      }
    }

    return rates;
  }

  Future<Map<String, int>> _calculateWeeklyProgress(AppState appState) async {
    final progress = <String, int>{};

    // Simulate weekly progress based on current habits
    for (final habitKey in appState.habits.keys) {
      if (habitKey.isNotEmpty) {
        final streak = _habitStreaks[habitKey] ?? 0;
        progress[habitKey] =
            (streak.clamp(0, 7) + (streak > 7 ? 7 : 0)).clamp(0, 7);
      }
    }

    return progress;
  }

  @override
  Widget build(BuildContext context) {
    return CosmicPageScaffold(
      title: 'Analytics Dashboard',
      titleIcon: Icons.auto_graph,
      onBack: () => Navigator.of(context).pop(),
      accentColor: StarboundColors.starlightBlue,
      actions: [
        CosmicCapsuleIconButton.glass(
          icon: Icons.refresh,
          tooltip: 'Refresh insights',
          onPressed: _loadAnalytics,
        ),
      ],
      contentPadding: EdgeInsets.zero,
      backgroundColor: StarboundColors.deepSpace,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: AppConstants.paddingL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeRangeSelector(),
              const SizedBox(height: AppConstants.spacingL),

              _buildOverviewCards(),
              const SizedBox(height: AppConstants.spacingL),

              if (_kShowTopTagSection) _buildTopTagsSection(),
              if (_kShowTopTagSection && _topTagEntries.isNotEmpty)
                const SizedBox(height: AppConstants.spacingL),

              const AchievementBanner(showFullStats: true),
              const SizedBox(height: AppConstants.spacingL),

              _buildProgressChart(),
              const SizedBox(height: AppConstants.spacingL),

              _buildHabitBreakdown(),
              const SizedBox(height: AppConstants.spacingL),

              _buildCorrelationInsights(),
              const SizedBox(height: AppConstants.spacingL),

              _buildSuccessPatternsSection(),
              const SizedBox(height: AppConstants.spacingL),

              _buildInsightsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Duration? _getSelectedDuration() {
    switch (_selectedTimeRange) {
      case AnalyticsTimeRange.week:
        return const Duration(days: 7);
      case AnalyticsTimeRange.month:
        return const Duration(days: 30);
      case AnalyticsTimeRange.quarter:
        return const Duration(days: 90);
      case AnalyticsTimeRange.year:
        return const Duration(days: 365);
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
          SizedBox(height: AppConstants.spacingL),
          Text(
            'Analyzing your habits...',
            style: AppConstants.bodyText,
          ),
        ],
      ),
    );
  }

  Widget _buildTopTagsSection() {
    if (_topTagEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Patterns',
          style: AppConstants.heading2,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Container(
          width: double.infinity,
          padding: AppConstants.paddingM,
          decoration: AppDecorations.cardDecoration,
          child: Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: _topTagEntries.map((entry) {
              final canonical = entry.key;
              final display = TagUtils.displayName(canonical);
              final emoji = TagUtils.emoji(canonical);
              final chipColor = TagUtils.color(canonical);
              final count = entry.value;
              final subdomain = TagUtils.subdomain(canonical);

              return Chip(
                avatar: CircleAvatar(
                  radius: 14,
                  backgroundColor: chipColor.withValues(alpha: 0.18),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$display ($count)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subdomain != null)
                      Text(
                        subdomain,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                backgroundColor: chipColor.withValues(alpha: 0.12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: AppConstants.paddingM,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Range',
            style: AppConstants.bodyText,
          ),
          const SizedBox(height: AppConstants.spacingM),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AnalyticsTimeRange.values.map((range) {
                final isSelected = _selectedTimeRange == range;
                return Padding(
                  padding: const EdgeInsets.only(right: AppConstants.spacingS),
                  child: FilterChip(
                    label: Text(_getTimeRangeLabel(range)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTimeRange = range;
                        });
                        _loadAnalytics();
                      }
                    },
                    selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppConstants.primaryColor,
                    side: BorderSide(
                      color: isSelected
                          ? AppConstants.primaryColor
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppConstants.primaryColor
                          : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    // Show skeleton loading until essential data is loaded
    if (_habitStreaks.isEmpty && _isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: AppConstants.heading2,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Expanded(child: SkeletonCard(height: 100)),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(child: SkeletonCard(height: 100)),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Expanded(child: SkeletonCard(height: 100)),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(child: SkeletonCard(height: 100)),
            ],
          ),
        ],
      );
    }

    final totalHabits = _habitStreaks.length;
    final activeStreaks =
        _habitStreaks.values.where((streak) => streak > 0).length;
    final averageCompletion = _completionRates.values.isNotEmpty
        ? _completionRates.values.reduce((a, b) => a + b) /
            _completionRates.length
        : 0.0;
    final longestStreak = _habitStreaks.values.isNotEmpty
        ? _habitStreaks.values.reduce((a, b) => a > b ? a : b)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: AppConstants.heading2,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'Active Habits',
                value: '$totalHabits',
                subtitle: '$activeStreaks with streaks',
                icon: Icons.track_changes,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildOverviewCard(
                title: 'Completion Rate',
                value: '${(averageCompletion * 100).round()}%',
                subtitle: _getTimeRangeLabel(_selectedTimeRange).toLowerCase(),
                icon: Icons.trending_up,
                color: AppConstants.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'Longest Streak',
                value: '$longestStreak',
                subtitle: longestStreak == 1 ? 'day' : 'days',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: _buildOverviewCard(
                title: 'This Week',
                value:
                    '${_weeklyProgress.values.fold(0, (sum, days) => sum + days)}',
                subtitle: 'total completions',
                icon: Icons.calendar_today,
                color: AppConstants.secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: AppConstants.paddingM,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppConstants.borderRadiusM,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    return Container(
      padding: AppConstants.paddingL,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Weekly Progress',
                style: AppConstants.bodyText,
              ),
              const Spacer(),
              Consumer<AppState>(
                builder: (context, appState, child) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getComplexityColor(appState.complexityProfile)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appState.complexityProfile.name.toUpperCase(),
                      style: TextStyle(
                        color: _getComplexityColor(appState.complexityProfile),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          _buildWeeklyChart(),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxCompletions = _weeklyProgress.values.isNotEmpty
        ? _weeklyProgress.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final dayCompletions = _getDayCompletions(index);
          final height = maxCompletions > 0
              ? (dayCompletions / maxCompletions) * 160
              : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: AppConstants.mediumAnimation,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppConstants.primaryColor,
                          AppConstants.primaryColor.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    days[index],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dayCompletions',
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHabitBreakdown() {
    return Container(
      padding: AppConstants.paddingL,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Habit Breakdown',
            style: AppConstants.bodyText,
          ),
          const SizedBox(height: AppConstants.spacingL),
          ..._habitStreaks.entries.map((entry) {
            final habitKey = entry.key;
            final streak = entry.value;
            final completionRate = _completionRates[habitKey] ?? 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
              child: _buildHabitProgressBar(
                habitKey: habitKey,
                streak: streak,
                completionRate: completionRate,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHabitProgressBar({
    required String habitKey,
    required int streak,
    required double completionRate,
  }) {
    final habitName = habitKey.replaceAll('_', ' ').toUpperCase();
    final progressColor = _getProgressColor(completionRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              habitName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: progressColor,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$streak',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: completionRate,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(completionRate * 100).round()}% completion rate',
          style: TextStyle(
            color: progressColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      padding: AppConstants.paddingL,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppConstants.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              const Text(
                'Insights',
                style: AppConstants.bodyText,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),

          ..._generateInsights()
              .map((insight) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppConstants.spacingM),
                    child: _buildInsightCard(insight),
                  ))
              .toList(),

          // Add actionable insights from pattern recognition
          if (_actionableInsights.isNotEmpty) ...{
            const SizedBox(height: AppConstants.spacingM),
            const Divider(color: Colors.white24),
            const SizedBox(height: AppConstants.spacingM),
            ..._actionableInsights
                .take(3)
                .map((insight) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.spacingM),
                      child: _buildActionableInsightCard(insight),
                    ))
                .toList(),
          },
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    final type = insight['type'] as String;
    final message = insight['message'] as String;
    final color = insight['color'] as Color;
    final icon = insight['icon'] as IconData;

    return Container(
      padding: AppConstants.paddingM,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppConstants.borderRadiusS,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getTimeRangeLabel(AnalyticsTimeRange range) {
    switch (range) {
      case AnalyticsTimeRange.week:
        return 'This Week';
      case AnalyticsTimeRange.month:
        return 'This Month';
      case AnalyticsTimeRange.quarter:
        return 'This Quarter';
      case AnalyticsTimeRange.year:
        return 'This Year';
    }
  }

  Color _getComplexityColor(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.stable:
        return AppConstants.successColor;
      case ComplexityLevel.trying:
        return AppConstants.primaryColor;
      case ComplexityLevel.overloaded:
        return Colors.orange;
      case ComplexityLevel.survival:
        return AppConstants.secondaryColor;
    }
  }

  Color _getProgressColor(double rate) {
    if (rate >= 0.8) return AppConstants.successColor;
    if (rate >= 0.6) return AppConstants.primaryColor;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }

  int _getDayCompletions(int dayIndex) {
    // Simulate daily completions based on habit progress
    // In a real implementation, this would come from actual daily data
    final totalHabits = _habitStreaks.length;
    final avgCompletion = _completionRates.values.isNotEmpty
        ? _completionRates.values.reduce((a, b) => a + b) /
            _completionRates.length
        : 0.0;

    // Add some daily variation
    final variance = [0.9, 1.0, 0.8, 1.1, 0.7, 0.6, 0.8][dayIndex];
    return ((totalHabits * avgCompletion * variance))
        .round()
        .clamp(0, totalHabits);
  }

  List<Map<String, dynamic>> _generateInsights() {
    final insights = <Map<String, dynamic>>[];

    // Streak insights
    final longestStreak = _habitStreaks.values.isNotEmpty
        ? _habitStreaks.values.reduce((a, b) => a > b ? a : b)
        : 0;

    if (longestStreak >= 7) {
      insights.add({
        'type': 'STREAK MASTER',
        'message':
            'Your $longestStreak-day streak shows incredible consistency! Keep it up.',
        'color': Colors.orange,
        'icon': Icons.local_fire_department,
      });
    }

    // Completion rate insights
    final avgCompletion = _completionRates.values.isNotEmpty
        ? _completionRates.values.reduce((a, b) => a + b) /
            _completionRates.length
        : 0.0;

    if (avgCompletion >= 0.8) {
      insights.add({
        'type': 'HIGH ACHIEVER',
        'message':
            'You\'re completing ${(avgCompletion * 100).round()}% of your habits. Excellent work!',
        'color': AppConstants.successColor,
        'icon': Icons.star,
      });
    } else if (avgCompletion < 0.5) {
      insights.add({
        'type': 'ROOM TO GROW',
        'message': 'Try focusing on 1-2 habits first to build momentum.',
        'color': AppConstants.primaryColor,
        'icon': Icons.trending_up,
      });
    }

    // Pattern insights
    final consistentHabits =
        _habitStreaks.values.where((streak) => streak >= 3).length;
    if (consistentHabits > 0) {
      insights.add({
        'type': 'BUILDING MOMENTUM',
        'message':
            'You have $consistentHabits habit${consistentHabits == 1 ? '' : 's'} with active streaks.',
        'color': AppConstants.primaryColor,
        'icon': Icons.timeline,
      });
    }

    return insights;
  }

  Widget _buildCorrelationInsights() {
    if (_correlationInsights.isEmpty) {
      return Container(
        padding: AppConstants.paddingL,
        decoration: AppDecorations.cardDecoration,
        child: Column(
          children: [
            Icon(
              Icons.psychology_outlined,
              color: Colors.white.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Pattern Discovery',
              style: AppConstants.bodyText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Keep tracking for a few more days to discover connections between your habits.',
              style: AppConstants.bodyTextSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: AppConstants.paddingL,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.connect_without_contact,
                color: AppConstants.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              const Text(
                'Habit Connections',
                style: AppConstants.bodyText,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_habitCorrelations.length} patterns found',
                  style: TextStyle(
                    color: AppConstants.secondaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          ..._correlationInsights
              .take(4)
              .map((insight) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppConstants.spacingM),
                    child: _buildCorrelationInsightCard(insight),
                  ))
              .toList(),
          if (_correlationInsights.length > 4)
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to detailed correlations page
                },
                child: Text(
                  'View all ${_correlationInsights.length} insights',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorrelationInsightCard(Map<String, dynamic> insight) {
    final type = insight['type'] as String;
    final message = insight['message'] as String;
    final detail = insight['detail'] as String? ?? '';
    final actionable = insight['actionable'] as bool? ?? false;
    final action = insight['action'] as String? ?? '';
    final complexityAppropriate =
        insight['complexity_appropriate'] as bool? ?? true;

    Color cardColor;
    IconData cardIcon;

    switch (type) {
      case 'HABIT SYNERGY':
        cardColor = AppConstants.successColor;
        cardIcon = Icons.sync;
        break;
      case 'MOMENTUM PATTERN':
        cardColor = AppConstants.primaryColor;
        cardIcon = Icons.trending_up;
        break;
      case 'KEYSTONE HABIT':
        cardColor = Colors.purple;
        cardIcon = Icons.star;
        break;
      case 'HABIT CONFLICT':
        cardColor = Colors.orange;
        cardIcon = Icons.warning_outlined;
        break;
      default:
        cardColor = AppConstants.secondaryColor;
        cardIcon = Icons.lightbulb_outline;
    }

    return Container(
      padding: AppConstants.paddingM,
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: complexityAppropriate ? 0.1 : 0.05),
        borderRadius: AppConstants.borderRadiusS,
        border: Border.all(
          color: cardColor.withValues(alpha: complexityAppropriate ? 0.3 : 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cardIcon, color: cardColor, size: 16),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  type,
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!complexityAppropriate)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ADVANCED',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            message,
            style: TextStyle(
              color: complexityAppropriate ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              style: TextStyle(
                color: complexityAppropriate ? Colors.white70 : Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
          if (actionable && action.isNotEmpty && complexityAppropriate) ...[
            const SizedBox(height: AppConstants.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: cardColor,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      action,
                      style: TextStyle(
                        color: cardColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessPatternsSection() {
    if (_successPatterns.isEmpty) {
      return Container(
        padding: AppConstants.paddingL,
        decoration: AppDecorations.cardDecoration,
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: Colors.white.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Success Patterns',
              style: AppConstants.bodyText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Keep tracking consistently to discover your personal success patterns.',
              style: AppConstants.bodyTextSecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: AppConstants.paddingL,
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.purple,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              const Text(
                'Success Patterns',
                style: AppConstants.bodyText,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_successPatterns.length} discovered',
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          ..._successPatterns
              .take(4)
              .map((pattern) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppConstants.spacingM),
                    child: _buildSuccessPatternCard(pattern),
                  ))
              .toList(),
          if (_successPatterns.length > 4)
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to detailed patterns page
                },
                child: Text(
                  'View all ${_successPatterns.length} patterns',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessPatternCard(dynamic pattern) {
    if (pattern is! Map<String, dynamic>) return const SizedBox.shrink();

    final type = pattern['type']?.toString() ?? '';
    final title = pattern['title']?.toString() ?? 'Pattern';
    final insight = pattern['insight']?.toString() ?? '';
    final confidence = pattern['confidence'] as double? ?? 0.0;

    Color patternColor;
    IconData patternIcon;

    switch (type) {
      case 'successStreak':
        patternColor = Colors.orange;
        patternIcon = Icons.local_fire_department;
        break;
      case 'recoveryPattern':
        patternColor = Colors.green;
        patternIcon = Icons.restore;
        break;
      case 'weeklyRhythm':
        patternColor = Colors.blue;
        patternIcon = Icons.calendar_today;
        break;
      case 'timeOptimal':
        patternColor = Colors.indigo;
        patternIcon = Icons.schedule;
        break;
      case 'correlationBoost':
        patternColor = Colors.teal;
        patternIcon = Icons.link;
        break;
      default:
        patternColor = Colors.purple;
        patternIcon = Icons.insights;
    }

    return Container(
      padding: AppConstants.paddingM,
      decoration: BoxDecoration(
        color: patternColor.withValues(alpha: 0.1),
        borderRadius: AppConstants.borderRadiusS,
        border: Border.all(color: patternColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(patternIcon, color: patternColor, size: 16),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: patternColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: patternColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(confidence * 100).round()}%',
                  style: TextStyle(
                    color: patternColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            insight,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableInsightCard(Map<String, dynamic> insight) {
    final title = insight['title'] as String? ?? '';
    final advice = insight['advice'] as String? ?? '';
    final confidence = insight['confidence'] as double? ?? 0.0;
    final isHighPriority = insight['high_priority'] as bool? ?? false;

    final cardColor = isHighPriority ? Colors.amber : Colors.blue;
    final cardIcon =
        isHighPriority ? Icons.priority_high : Icons.lightbulb_outline;

    return Container(
      padding: AppConstants.paddingM,
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.1),
        borderRadius: AppConstants.borderRadiusS,
        border: Border.all(color: cardColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cardIcon, color: cardColor, size: 16),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isHighPriority)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRIORITY',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            advice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(cardColor),
          ),
        ],
      ),
    );
  }
}
