import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../design_system/design_system.dart';
import '../services/search_service.dart';
import '../components/unified_search_widget.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  final SearchResults results;
  final VoidCallback? onBack;

  const SearchResultsPage({
    Key? key,
    required this.query,
    required this.results,
    this.onBack,
  }) : super(key: key);

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Determine initial tab based on detected intent and results
    int initialTab = 0;
    switch (widget.results.detectedIntent) {
      case SearchIntent.journal:
        initialTab = widget.results.hasJournalResults ? 0 : _getFirstAvailableTab();
        break;
      case SearchIntent.askStarbound:
        initialTab = widget.results.hasConversationResults ? 1 : _getFirstAvailableTab();
        break;
      case SearchIntent.healthForecast:
        initialTab = widget.results.hasForecastResults ? 2 : _getFirstAvailableTab();
        break;
      case SearchIntent.unknown:
        initialTab = _getFirstAvailableTab();
        break;
    }
    
    _selectedTabIndex = initialTab;
    _tabController = TabController(
      length: 4, // All, Journal, Conversations, Forecasts
      vsync: this,
      initialIndex: initialTab,
    );
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getFirstAvailableTab() {
    if (widget.results.allResults.isNotEmpty) return 0; // All results
    if (widget.results.hasJournalResults) return 1;
    if (widget.results.hasConversationResults) return 2;
    if (widget.results.hasForecastResults) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StarboundColors.background,
      body: Stack(
        children: [
          // Cosmic background
          Container(
            decoration: BoxDecoration(
              gradient: StarboundColors.primaryGradient,
            ),
          ),
          
          // Twinkling stars background
          Positioned.fill(
            child: CustomPaint(
              painter: StarfieldPainter(
                starCount: 100,
                animationValue: 0.5,
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: _buildTabContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and search summary
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack ?? () => Navigator.pop(context),
                icon: Icon(
                  LucideIcons.arrowLeft,
                  color: StarboundColors.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Results',
                      style: StarboundTypography.heading2.copyWith(
                        color: StarboundColors.textPrimary,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${widget.query}"',
                      style: StarboundTypography.body.copyWith(
                        color: StarboundColors.textSecondary,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Results summary with intent detection
          _buildResultsSummary(),
        ],
      ),
    );
  }

  Widget _buildResultsSummary() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getIntentIcon(widget.results.detectedIntent),
                color: _getIntentColor(widget.results.detectedIntent),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getIntentLabel(widget.results.detectedIntent),
                      style: StarboundTypography.bodySmall.copyWith(
                        color: _getIntentColor(widget.results.detectedIntent),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.results.totalResults} results in ${widget.results.searchTime.inMilliseconds}ms',
                      style: StarboundTypography.caption.copyWith(
                        color: StarboundColors.textTertiary,
                        fontSize: 11,
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                _buildTab('All', widget.results.allResults.length, 0),
                _buildTab('Journal', widget.results.journalResults.length, 1),
                _buildTab('Conversations', widget.results.conversationResults.length, 2),
                _buildTab('Forecasts', widget.results.forecastResults.length, 3),
              ],
              indicator: BoxDecoration(
                color: StarboundColors.stellarAqua.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: StarboundColors.stellarAqua,
              unselectedLabelColor: StarboundColors.textTertiary,
              labelStyle: StarboundTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              unselectedLabelStyle: StarboundTypography.caption.copyWith(
                fontSize: 11,
              ),
              indicatorPadding: const EdgeInsets.all(4),
              dividerColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count, int index) {
    final isSelected = _selectedTabIndex == index;
    
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? StarboundColors.stellarAqua.withValues(alpha: 0.3)
                    : StarboundColors.textTertiary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: StarboundTypography.caption.copyWith(
                  color: isSelected ? StarboundColors.stellarAqua : StarboundColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildResultsGrid(widget.results.allResults),
          _buildResultsGrid(widget.results.journalResults),
          _buildResultsGrid(widget.results.conversationResults),
          _buildResultsGrid(widget.results.forecastResults),
        ],
      ),
    );
  }

  Widget _buildResultsGrid(List<SearchResult> results) {
    if (results.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildResultCard(result),
        );
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type icon and timestamp
              Row(
                children: [
                  Icon(
                    _getResultTypeIcon(result.type),
                    color: _getResultTypeColor(result.type),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.title,
                      style: StarboundTypography.bodySmall.copyWith(
                        color: StarboundColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatTimestamp(result.timestamp),
                    style: StarboundTypography.caption.copyWith(
                      color: StarboundColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Content snippet
              Text(
                result.snippet,
                style: StarboundTypography.body.copyWith(
                  color: StarboundColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Relevance score and metadata
              if (result.metadata.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildResultMetadata(result),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultMetadata(SearchResult result) {
    final tags = <Widget>[];
    
    // Add type-specific metadata tags
    switch (result.type) {
      case SearchResultType.journalEntry:
        if (result.metadata['themes'] != null) {
          for (final theme in (result.metadata['themes'] as List).take(2)) {
            tags.add(_buildMetadataTag(theme.toString(), StarboundColors.success));
          }
        }
        break;
      case SearchResultType.conversation:
        if (result.metadata['mainTopic'] != null) {
          tags.add(_buildMetadataTag(result.metadata['mainTopic'], StarboundColors.nebulaPurple));
        }
        break;
      case SearchResultType.habitEntry:
        if (result.metadata['category'] != null) {
          tags.add(_buildMetadataTag(result.metadata['category'], StarboundColors.stellarAqua));
        }
        break;
      default:
        break;
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags,
    );
  }

  Widget _buildMetadataTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: StarboundTypography.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.search,
            size: 64,
            color: StarboundColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: StarboundTypography.heading3.copyWith(
              color: StarboundColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            style: StarboundTypography.body.copyWith(
              color: StarboundColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for icons and colors
  IconData _getIntentIcon(SearchIntent intent) {
    switch (intent) {
      case SearchIntent.journal:
        return LucideIcons.bookOpen;
      case SearchIntent.askStarbound:
        return LucideIcons.messageCircle;
      case SearchIntent.healthForecast:
        return LucideIcons.trendingUp;
      case SearchIntent.unknown:
      default:
        return LucideIcons.search;
    }
  }

  Color _getIntentColor(SearchIntent intent) {
    switch (intent) {
      case SearchIntent.journal:
        return StarboundColors.stellarAqua;
      case SearchIntent.askStarbound:
        return StarboundColors.nebulaPurple;
      case SearchIntent.healthForecast:
        return StarboundColors.success;
      case SearchIntent.unknown:
      default:
        return StarboundColors.textTertiary;
    }
  }

  String _getIntentLabel(SearchIntent intent) {
    switch (intent) {
      case SearchIntent.journal:
        return 'Journal Search';
      case SearchIntent.askStarbound:
        return 'Ask Starbound';
      case SearchIntent.healthForecast:
        return 'Health Forecast';
      case SearchIntent.unknown:
      default:
        return 'General Search';
    }
  }

  IconData _getResultTypeIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.journalEntry:
        return LucideIcons.fileText;
      case SearchResultType.conversation:
        return LucideIcons.messageSquare;
      case SearchResultType.habitEntry:
        return LucideIcons.activity;
      case SearchResultType.forecast:
        return LucideIcons.barChart3;
      case SearchResultType.recommendation:
        return LucideIcons.lightbulb;
    }
  }

  Color _getResultTypeColor(SearchResultType type) {
    switch (type) {
      case SearchResultType.journalEntry:
        return StarboundColors.stellarAqua;
      case SearchResultType.conversation:
        return StarboundColors.nebulaPurple;
      case SearchResultType.habitEntry:
        return StarboundColors.success;
      case SearchResultType.forecast:
        return StarboundColors.solarOrange;
      case SearchResultType.recommendation:
        return StarboundColors.stellarAqua;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}';
  }
}

// Starfield painter for background
class StarfieldPainter extends CustomPainter {
  final int starCount;
  final double animationValue;

  StarfieldPainter({
    required this.starCount,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    
    for (int i = 0; i < starCount; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 73) % size.height;
      final opacity = (0.3 + (i % 3) * 0.2) * (0.5 + animationValue * 0.5);
      
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 1.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}