import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/nudge_model.dart';
import '../utils/tag_utils.dart';
import '../design_system/design_system.dart';

class ActionVaultPage extends StatefulWidget {
  final VoidCallback onGoBack;

  const ActionVaultPage({
    Key? key,
    required this.onGoBack,
  }) : super(key: key);

  @override
  State<ActionVaultPage> createState() => _ActionVaultPageState();
}

class _ActionVaultPageState extends State<ActionVaultPage> {
  static const bool _kThemeFilterEnabled = false;
  late TextEditingController searchController;
  List<String> selectedTags = [];
  List<String> selectedTimeFilters = [];
  List<String> selectedEnergyFilters = [];
  List<String> selectedContextFilters = [];

  // Available tags for filtering
  late final List<String> availableTags;
  final List<String> timeFilters = [
    '<1 min',
    '1-2 mins',
    '2-5 mins',
    '5-10 mins',
    '10+ mins'
  ];
  final List<String> energyFilters = ['very low', 'low', 'medium', 'high'];
  final List<String> contextFilters = [
    'in bed',
    'at home',
    'at work/school',
    'on the go',
    'needs quiet',
    'needs supplies',
    'anywhere',
  ];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    if (_kThemeFilterEnabled) {
      availableTags = TagUtils.allCanonicalTags()
        ..sort((a, b) => TagUtils.displayName(a)
            .toLowerCase()
            .compareTo(TagUtils.displayName(b).toLowerCase()));
    } else {
      availableTags = const [];
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<StarboundNudge> filterNudges(String query, List<StarboundNudge> nudges) {
    List<StarboundNudge> result = nudges.map(_withCanonicalTheme).toList();

    // Search filter
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      result = result
          .where((nudge) =>
              nudge.message.toLowerCase().contains(lowerQuery) ||
              TagUtils.displayName(nudge.theme)
                  .toLowerCase()
                  .contains(lowerQuery))
          .toList();
    }

    // Theme filter
    if (_kThemeFilterEnabled && selectedTags.isNotEmpty) {
      result =
          result.where((nudge) => selectedTags.contains(nudge.theme)).toList();
    }

    // Time filter
    if (selectedTimeFilters.isNotEmpty) {
      result = result.where((nudge) {
        final timeBucket =
            _normalizeTimeForNudge(nudge.estimatedTime, nudge.message);
        return selectedTimeFilters.contains(timeBucket);
      }).toList();
    }

    // Energy filter
    if (selectedEnergyFilters.isNotEmpty) {
      result = result.where((nudge) {
        final energyBucket = _normalizeEnergyForNudge(nudge.energyRequired);
        return selectedEnergyFilters.contains(energyBucket);
      }).toList();
    }

    // Context filter (simplified - in a real app this would be more sophisticated)
    if (selectedContextFilters.isNotEmpty) {
      result = result.where((nudge) {
        final contextTags = _resolveContextTags(nudge);
        if (contextTags.isEmpty) {
          return selectedContextFilters.contains('anywhere');
        }

        for (final filter in selectedContextFilters) {
          if (filter == 'anywhere') {
            if (contextTags.contains('anywhere') || contextTags.isEmpty) {
              return true;
            }
          } else if (contextTags.contains(filter)) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    return result;
  }

  StarboundNudge _withCanonicalTheme(StarboundNudge nudge) {
    final metadata = Map<String, dynamic>.from(nudge.metadata ?? {});
    final canonicalTheme = _canonicalThemeForNudge(nudge, metadata: metadata);

    final canonicalTags = <String>{canonicalTheme};
    final rawTags = metadata['canonical_tags'];
    if (rawTags is List) {
      for (final dynamic tag in rawTags) {
        final resolved = TagUtils.resolveCanonicalTag(tag?.toString());
        if (resolved != null) canonicalTags.add(resolved);
      }
    }
    metadata['canonical_theme'] = canonicalTheme;
    metadata['canonical_tags'] = canonicalTags.toList();

    if (nudge.theme == canonicalTheme && identical(metadata, nudge.metadata)) {
      return nudge;
    }

    return nudge.copyWith(theme: canonicalTheme, metadata: metadata);
  }

  String _canonicalThemeForNudge(
    StarboundNudge nudge, {
    Map<String, dynamic>? metadata,
  }) {
    final data = metadata ?? nudge.metadata ?? {};

    if (data['canonical_theme'] != null) {
      final resolved =
          TagUtils.resolveCanonicalTag(data['canonical_theme'].toString());
      if (resolved != null) return resolved;
    }

    if (data['canonical_tags'] is List) {
      for (final dynamic value in (data['canonical_tags'] as List)) {
        final resolved = TagUtils.resolveCanonicalTag(value?.toString());
        if (resolved != null) return resolved;
      }
    }

    return TagUtils.resolveCanonicalTag(nudge.theme) ?? 'balanced';
  }

  List<String> _resolveContextTags(StarboundNudge nudge) {
    if (nudge.contextTags.isNotEmpty) {
      return nudge.contextTags
          .map((entry) => entry.toLowerCase())
          .toList(growable: false);
    }

    final raw = nudge.metadata?['context_tags'];
    if (raw is List) {
      final tags = raw
          .whereType<dynamic>()
          .map((entry) => entry.toString().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
      return tags;
    }

    if (raw is String && raw.isNotEmpty) {
      return raw
          .split(',')
          .map((entry) => entry.trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }

  static const Set<String> _allowedTimeBuckets = {
    '<1 min',
    '1-2 mins',
    '2-5 mins',
    '5-10 mins',
    '10+ mins',
  };

  String _normalizeTimeForNudge(String? raw, String message) {
    final candidate = raw?.trim() ?? '';
    if (_allowedTimeBuckets.contains(candidate)) {
      return candidate;
    }
    if (candidate.isNotEmpty) {
      return _bucketizeTime(candidate);
    }
    return _bucketizeTime(message);
  }

  String _bucketizeTime(String source) {
    final trimmed = source.trim();
    if (_allowedTimeBuckets.contains(trimmed)) {
      return trimmed;
    }

    final plusMatch = RegExp(r'(\d+)\s*\+\s*(minute|min|second|sec|hour|hr)s?',
            caseSensitive: false)
        .firstMatch(trimmed);
    if (plusMatch != null) {
      final baseValue = int.tryParse(plusMatch.group(1) ?? '');
      final unit = plusMatch.group(2)?.toLowerCase() ?? '';
      if (baseValue != null) {
        double minutes;
        if (unit.startsWith('sec')) {
          minutes = baseValue / 60;
        } else if (unit.startsWith('hour') || unit.startsWith('hr')) {
          minutes = baseValue * 60;
        } else {
          minutes = baseValue.toDouble();
        }
        return _bucketFromMinutes(minutes);
      }
    }

    final rangeMatch = RegExp(
            r'(\d+)\s*(?:-|to)\s*(\d+)\s*(minute|min|second|sec|hour|hr)s?',
            caseSensitive: false)
        .firstMatch(trimmed);
    if (rangeMatch != null) {
      final end = int.tryParse(rangeMatch.group(2) ?? '');
      final unit = rangeMatch.group(3)?.toLowerCase() ?? '';
      if (end != null) {
        double minutes = end.toDouble();
        if (unit.startsWith('sec')) {
          minutes = end / 60;
        } else if (unit.startsWith('hour') || unit.startsWith('hr')) {
          minutes = end * 60;
        }
        return _bucketFromMinutes(minutes);
      }
    }

    final timeMatch = RegExp(r'(\d+)\s*(minute|min|second|sec|hour|hr)s?',
            caseSensitive: false)
        .firstMatch(trimmed);
    if (timeMatch != null) {
      final value = int.tryParse(timeMatch.group(1) ?? '');
      final unit = timeMatch.group(2)?.toLowerCase() ?? '';
      if (value != null) {
        double minutes;
        if (unit.startsWith('sec')) {
          minutes = value / 60;
        } else if (unit.startsWith('hour') || unit.startsWith('hr')) {
          minutes = value * 60;
        } else {
          minutes = value.toDouble();
        }
        return _bucketFromMinutes(minutes);
      }
    }

    if (trimmed
        .contains(RegExp(r'breath|sip|drink|moment', caseSensitive: false))) {
      return '<1 min';
    }
    if (trimmed.contains(RegExp(r'stretch|walk|write', caseSensitive: false))) {
      return '2-5 mins';
    }
    if (trimmed.contains(RegExp(r'meditat|plan|cook', caseSensitive: false))) {
      return '5-10 mins';
    }

    return '1-2 mins';
  }

  String _bucketFromMinutes(double minutes) {
    if (minutes <= 1) return '<1 min';
    if (minutes <= 2) return '1-2 mins';
    if (minutes <= 5) return '2-5 mins';
    if (minutes <= 10) return '5-10 mins';
    return '10+ mins';
  }

  static const Set<String> _allowedEnergyBuckets = {
    'very low',
    'low',
    'medium',
    'high',
  };

  String _normalizeEnergyForNudge(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'low';
    }

    final value = raw.trim().toLowerCase();
    if (_allowedEnergyBuckets.contains(value)) {
      return value;
    }
    if (value.contains('very') || value.contains('minimal')) {
      return 'very low';
    }
    if (value.contains('high') || value.contains('intense')) {
      return 'high';
    }
    if (value.contains('medium') || value.contains('moderate')) {
      return 'medium';
    }
    if (value.contains('low')) {
      return 'low';
    }

    return 'low';
  }

  void toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
  }

  void toggleTimeFilter(String filter) {
    setState(() {
      if (selectedTimeFilters.contains(filter)) {
        selectedTimeFilters.remove(filter);
      } else {
        selectedTimeFilters.add(filter);
      }
    });
  }

  void toggleEnergyFilter(String filter) {
    setState(() {
      if (selectedEnergyFilters.contains(filter)) {
        selectedEnergyFilters.remove(filter);
      } else {
        selectedEnergyFilters.add(filter);
      }
    });
  }

  void toggleContextFilter(String filter) {
    setState(() {
      if (selectedContextFilters.contains(filter)) {
        selectedContextFilters.remove(filter);
      } else {
        selectedContextFilters.add(filter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF1F0150),
    ));

    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Show only the user's banked nudges in the Action Vault
        final availableNudges = appState.bankedNudges;

        final filteredNudges =
            filterNudges(searchController.text, availableNudges);

        final searchField = CosmicSearchBar(
          controller: searchController,
          hintText: 'Find your perfect action...',
          semanticsLabel: 'Search your saved actions',
          semanticsHint: 'Type to filter actions in the vault',
          onChanged: (_) => setState(() {}),
          accentColor: StarboundColors.solarOrange,
          trailing: searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: StarboundColors.cosmicWhite.withValues(alpha: 0.8),
                  ),
                  onPressed: () {
                    searchController.clear();
                    setState(() {});
                  },
                  tooltip: 'Clear search',
                )
              : null,
        );

        return CosmicPageScaffold(
          title: "Action Vault",
          titleIcon: Icons.star_outline,
          onBack: widget.onGoBack,
          accentColor: StarboundColors.solarOrange,
          backgroundColor: StarboundColors.deepSpace,
          contentPadding: EdgeInsets.zero,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 900;
              final filtersPanel = _buildFiltersPanel(isWide: isWide);
              final resultsPanel = _buildResultsPanel(
                filteredNudges: filteredNudges,
                appState: appState,
                isWide: isWide,
              );

              final Widget layout = isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        filtersPanel,
                        const SizedBox(width: 20),
                        Expanded(child: resultsPanel),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        filtersPanel,
                        const SizedBox(height: 16),
                        Expanded(child: resultsPanel),
                      ],
                    );

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 20),
                    Expanded(child: layout),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFiltersPanel({required bool isWide}) {
    final filterContent = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_kThemeFilterEnabled) ...[
            _buildFilterSection(
              "Theme",
              availableTags,
              selectedTags,
              toggleTag,
              showEmojis: true,
              labelBuilder: (tag) => TagUtils.displayName(tag),
            ),
            const SizedBox(height: 20),
          ],
          _buildFilterSection(
            "Time Available",
            timeFilters,
            selectedTimeFilters,
            toggleTimeFilter,
          ),
          const SizedBox(height: 20),
          _buildFilterSection(
            "Energy Level",
            energyFilters,
            selectedEnergyFilters,
            toggleEnergyFilter,
          ),
          const SizedBox(height: 20),
          _buildFilterSection(
            "Context",
            contextFilters,
            selectedContextFilters,
            toggleContextFilter,
          ),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isWide ? 320 : double.infinity,
      ),
      child: Container(
        width: isWide ? 320 : double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Filters",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_hasActiveFilters())
                  GestureDetector(
                    onTap: _clearAllFilters,
                    child: Text(
                      "Clear all",
                      style: TextStyle(
                        color: const Color(0xFF00F5D4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (isWide) Expanded(child: filterContent) else filterContent,
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPanel({
    required List<StarboundNudge> filteredNudges,
    required AppState appState,
    required bool isWide,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "${filteredNudges.length} nudge${filteredNudges.length == 1 ? '' : 's'} found",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (filteredNudges.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00F5D4).withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "Perfect for you right now",
                  style: TextStyle(
                    color: Color(0xFF00F5D4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredNudges.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: EdgeInsets.only(bottom: isWide ? 0 : 24),
                  itemCount: filteredNudges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final nudge = filteredNudges[index];
                    final themeColor = TagUtils.color(nudge.theme);
                    final isFavorite =
                        appState.favoriteActions.contains(nudge.id);
                    final isBanked =
                        appState.bankedNudges.any((n) => n.id == nudge.id);
                    final isCompleted = appState.isActionCompleted(nudge.id);

                    return NudgeCard(
                      nudge: nudge,
                      themeColor: themeColor,
                      isFavorite: isFavorite,
                      isBanked: isBanked,
                      isCompleted: isCompleted,
                      onHeartPressed: () {
                        HapticFeedback.lightImpact();
                        appState.toggleFavoriteAction(nudge.id);
                      },
                      onSavePressed: () {
                        HapticFeedback.mediumImpact();
                        if (isBanked) {
                          appState.removeBankedNudge(nudge.id);
                          _showActionDialog(context, "Removed from vault!");
                        } else {
                          appState.bankNudge(nudge);
                          _showActionDialog(context, "Saved to vault!");
                        }
                      },
                      onDoPressed: () {
                        HapticFeedback.mediumImpact();
                        final togglingToCompleted = !isCompleted;
                        appState.toggleActionCompleted(nudge.id, nudge: nudge);
                        _showActionDialog(
                          context,
                          togglingToCompleted
                              ? 'Checked off!'
                              : 'Marked as not done.',
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> filters,
    List<String> selectedFilters,
    Function(String) onToggle, {
    bool showEmojis = false,
    String Function(String)? labelBuilder,
  }) {
    final buildLabel = labelBuilder ?? (String value) => value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filters.map((filter) {
            final bool isSelected = selectedFilters.contains(filter);
            final Color themeColor =
                showEmojis ? TagUtils.color(filter) : const Color(0xFF00F5D4);

            return FilterChip(
              label: Text(
                buildLabel(filter),
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              avatar: showEmojis
                  ? Text(
                      TagUtils.emoji(filter),
                      style: const TextStyle(fontSize: 14),
                    )
                  : null,
              selected: isSelected,
              onSelected: (_) => onToggle(filter),
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              selectedColor: themeColor.withValues(alpha: 0.7),
              checkmarkColor: Colors.white,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? themeColor.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              clipBehavior: Clip.antiAlias,
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return selectedTags.isNotEmpty ||
        selectedTimeFilters.isNotEmpty ||
        selectedEnergyFilters.isNotEmpty ||
        selectedContextFilters.isNotEmpty;
  }

  void _clearAllFilters() {
    setState(() {
      selectedTags.clear();
      selectedTimeFilters.clear();
      selectedEnergyFilters.clear();
      selectedContextFilters.clear();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No nudges in your vault yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Save nudges from the home page to build your personal action vault",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showActionDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF27AE60),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Single Nudge Card
class NudgeCard extends StatelessWidget {
  final StarboundNudge nudge;
  final Color themeColor;
  final bool isFavorite;
  final bool isBanked;
  final bool isCompleted;
  final VoidCallback onHeartPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onDoPressed;

  const NudgeCard({
    Key? key,
    required this.nudge,
    required this.themeColor,
    required this.isFavorite,
    required this.isBanked,
    required this.isCompleted,
    required this.onHeartPressed,
    required this.onSavePressed,
    required this.onDoPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAIGenerated = nudge.source == NudgeSource.dynamic &&
        nudge.metadata?['ai_generated'] == true;
    final favoriteTooltip =
        isFavorite ? 'Remove from favorites' : 'Add to favorites';
    final saveTooltip = 'Remove from vault';
    final semanticsLabel = _buildSemanticsDescription(isAIGenerated);
    final String primaryActionLabel =
        isCompleted ? 'Mark as not done' : 'Mark as done';
    final IconData primaryIcon = isCompleted ? Icons.undo : Icons.check_circle;
    final String primaryTooltip = isCompleted
        ? 'Mark this action as not done'
        : 'Mark this action as done';
    final displayTheme = TagUtils.displayName(nudge.theme);

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: isCompleted ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAIGenerated
                ? const Color(0xFF00F5D4).withValues(alpha: 0.4)
                : themeColor.withValues(alpha: isCompleted ? 0.35 : 0.2),
            width: isAIGenerated ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            if (isAIGenerated)
              BoxShadow(
                color: const Color(0xFF00F5D4).withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with theme icon and favorite
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    TagUtils.emoji(nudge.theme),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTheme.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      // AI indicator for AI-generated nudges
                      if (nudge.source == NudgeSource.dynamic &&
                          nudge.metadata?['ai_generated'] == true) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 10,
                              color: const Color(0xFF00F5D4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI Generated',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF00F5D4),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (isCompleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 22,
                    color:
                        isFavorite ? Colors.red : Colors.white.withValues(alpha: 0.7),
                  ),
                  onPressed: onHeartPressed,
                  tooltip: favoriteTooltip,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Main message
            Builder(
              builder: (context) {
                final displayText = _displayText();
                return Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Info chips
            Align(
              alignment: Alignment.centerLeft,
              child: _buildInfoChip("⏱", nudge.estimatedTime, themeColor),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: primaryTooltip,
                    child: CosmicButton.primary(
                      onPressed: onDoPressed,
                      accentColor: themeColor,
                      icon: primaryIcon,
                      child: Text(primaryActionLabel),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (isBanked)
                  Semantics(
                    button: true,
                    label: saveTooltip,
                    child: Tooltip(
                      message: saveTooltip,
                      child: CosmicButton.secondary(
                        onPressed: onSavePressed,
                        accentColor: themeColor,
                        icon: Icons.bookmark_remove,
                        child: const Text('Remove'),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String icon, String text, Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _buildSemanticsDescription(bool isAIGenerated) {
    final buffer = StringBuffer();
    final displayText = _displayText();
    final themeLabel = TagUtils.displayName(nudge.theme);

    if (displayText.isNotEmpty) {
      final spoken = displayText.replaceAll('\n', ' ');
      final capitalizedDisplay = spoken[0].toUpperCase() + spoken.substring(1);
      buffer.write(capitalizedDisplay);
      if (!capitalizedDisplay.endsWith('.')) {
        buffer.write('.');
      }
      buffer.write(' ');
    }

    buffer.write('Theme $themeLabel. ');

    final trimmedTime = nudge.estimatedTime.trim();
    if (trimmedTime.isNotEmpty) {
      buffer.write('Estimated time $trimmedTime. ');
    }

    final trimmedEnergy = nudge.energyRequired.trim();
    if (trimmedEnergy.isNotEmpty) {
      buffer.write('Energy required $trimmedEnergy. ');
    }

    final trimmedTone = nudge.tone.trim();
    if (trimmedTone.isNotEmpty) {
      buffer.write('Tone $trimmedTone. ');
    }

    if (isAIGenerated) {
      buffer.write('AI generated suggestion. ');
    }

    if (isFavorite) {
      buffer.write('Currently marked as favorite. ');
    }

    if (isBanked) {
      buffer.write('Already saved in your vault. ');
    }

    if (isCompleted) {
      buffer.write('Marked as completed. ');
    }

    final actions = <String>[
      isCompleted ? 'mark as not done' : 'mark as done',
      if (isBanked) 'remove from vault',
      isFavorite ? 'remove favorite' : 'add to favorites',
    ];

    buffer.write('Available actions: ${actions.join(', ')}.'.trim());

    return buffer.toString();
  }

  String _displayText() {
    final title = _formatTitle();
    final message = _formatMessage();
    if (message.isEmpty) {
      return title;
    }
    return '$title\n$message';
  }

  String _formatTitle() {
    final rawTitle = nudge.title.trim().isNotEmpty
        ? nudge.title.trim()
        : _firstSentence(nudge.message);
    if (rawTitle.isEmpty) {
      return 'Simple task';
    }
    return _sentenceCase(rawTitle);
  }

  String _formatMessage() {
    final trimmedMessage = nudge.message.trim();
    if (trimmedMessage.isEmpty) {
      return '';
    }

    final formattedTitle = _normalizeForComparison(_formatTitle());
    final firstSentence = _firstSentence(trimmedMessage);
    final normalizedFirst = _normalizeForComparison(firstSentence);

    String body = trimmedMessage;
    if (formattedTitle == normalizedFirst) {
      body = trimmedMessage.substring(firstSentence.length).trimLeft();
    }

    if (body.startsWith(':')) {
      body = body.substring(1).trimLeft();
    }

    if (body.isEmpty) {
      return '';
    }

    final firstChar = body[0].toUpperCase();
    return '$firstChar${body.substring(1)}';
  }

  String _firstSentence(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final colonIndex = trimmed.indexOf(':');
    if (colonIndex != -1) {
      return trimmed.substring(0, colonIndex).trim();
    }
    final match = RegExp(r'[^.!?]+').firstMatch(trimmed);
    return match?.group(0)?.trim() ?? trimmed;
  }

  String _sentenceCase(String input) {
    final words = input.split(RegExp(r'\s+'));
    if (words.isEmpty) {
      return input;
    }

    final transformed = <String>[];
    for (final word in words) {
      if (word.isEmpty) {
        continue;
      }
      final hasInnerUppercase =
          word.length > 1 && word.substring(1).contains(RegExp(r'[A-Z]'));
      final isAllCaps = word.length > 1 && word == word.toUpperCase();
      if (hasInnerUppercase || isAllCaps) {
        transformed.add(word);
      } else {
        transformed.add(word.toLowerCase());
      }
    }

    if (transformed.isEmpty) {
      return input;
    }

    final sentence = transformed.join(' ');
    return sentence[0].toUpperCase() + sentence.substring(1);
  }

  String _normalizeForComparison(String input) {
    return input.trim().toLowerCase();
  }
}
