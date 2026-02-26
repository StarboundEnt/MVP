import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';

class AchievementBanner extends StatelessWidget {
  final bool showFullStats;
  final VoidCallback? onTap;
  
  const AchievementBanner({
    Key? key,
    this.showFullStats = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final stats = appState.achievementStats;
        final points = appState.achievementPoints;
        final unlockedCount = appState.achievementCount;
        final totalAvailable = stats['total_available'] as int? ?? 0;
        final completionRate = stats['completion_rate'] as double? ?? 0.0;
        
        if (showFullStats) {
          return _buildFullStatsBanner(
            context,
            points,
            unlockedCount,
            totalAvailable,
            completionRate,
            stats,
          );
        } else {
          return _buildCompactBanner(
            context,
            points,
            unlockedCount,
            completionRate,
          );
        }
      },
    );
  }
  
  Widget _buildCompactBanner(
    BuildContext context,
    int points,
    int unlockedCount,
    double completionRate,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppConstants.paddingM,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.2),
              Colors.orange.withValues(alpha: 0.1),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: AppConstants.borderRadiusM,
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$points Points',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$unlockedCount achievements unlocked',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(completionRate * 100).round()}%',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            if (onTap != null) ...[
              const SizedBox(width: AppConstants.spacingS),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildFullStatsBanner(
    BuildContext context,
    int points,
    int unlockedCount,
    int totalAvailable,
    double completionRate,
    Map<String, dynamic> stats,
  ) {
    final byCategory = stats['by_category'] as Map<String, dynamic>? ?? {};
    final byTier = stats['by_tier'] as Map<String, dynamic>? ?? {};
    
    return Container(
      padding: AppConstants.paddingL,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppConstants.borderRadiusL,
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievements',
                      style: AppConstants.heading2.copyWith(
                        color: Colors.amber,
                      ),
                    ),
                    Text(
                      '$points total points earned',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingL),
          
          // Progress overview
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Unlocked',
                  '$unlockedCount',
                  'of $totalAvailable',
                  Icons.lock_open,
                  Colors.green,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildStatCard(
                  'Progress',
                  '${(completionRate * 100).round()}%',
                  'completion',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingL),
          
          // Category breakdown
          Text(
            'By Category',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: [
              _buildCategoryChip('Streaks', byCategory['streak'] ?? 0, Icons.local_fire_department),
              _buildCategoryChip('Consistency', byCategory['consistency'] ?? 0, Icons.trending_up),
              _buildCategoryChip('Milestones', byCategory['milestone'] ?? 0, Icons.flag),
              _buildCategoryChip('Growth', byCategory['growth'] ?? 0, Icons.psychology),
              _buildCategoryChip('Discovery', byCategory['discovery'] ?? 0, Icons.lightbulb),
              _buildCategoryChip('Resilience', byCategory['resilience'] ?? 0, Icons.shield),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacingL),
          
          // Tier breakdown
          Text(
            'By Tier',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          
          Row(
            children: [
              _buildTierIndicator('Bronze', byTier['bronze'] ?? 0, const Color(0xFFCD7F32)),
              _buildTierIndicator('Silver', byTier['silver'] ?? 0, const Color(0xFFC0C0C0)),
              _buildTierIndicator('Gold', byTier['gold'] ?? 0, const Color(0xFFFFD700)),
              _buildTierIndicator('Platinum', byTier['platinum'] ?? 0, const Color(0xFFE5E4E2)),
              _buildTierIndicator('Diamond', byTier['diamond'] ?? 0, const Color(0xFFB9F2FF)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: AppConstants.paddingM,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppConstants.borderRadiusS,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChip(String name, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTierIndicator(String tier, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tier,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}