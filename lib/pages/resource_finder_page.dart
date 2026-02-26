import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/health_resource_model.dart';
import '../models/health_barrier_model.dart';
import '../models/complexity_profile.dart';
import '../data/nsw_health_resources.dart';
import '../services/resource_matcher_service.dart';
import '../providers/app_state.dart';
import '../design_system/design_system.dart';

/// Resource category filter options
enum ResourceCategory {
  all,
  clinics,
  mentalHealth,
  pharmacies,
  food,
  emergency,
  community,
}

extension ResourceCategoryExtension on ResourceCategory {
  String get displayName {
    switch (this) {
      case ResourceCategory.all:
        return 'All';
      case ResourceCategory.clinics:
        return 'Clinics';
      case ResourceCategory.mentalHealth:
        return 'Mental Health';
      case ResourceCategory.pharmacies:
        return 'Pharmacies';
      case ResourceCategory.food:
        return 'Food';
      case ResourceCategory.emergency:
        return 'Emergency';
      case ResourceCategory.community:
        return 'Community';
    }
  }

  IconData get icon {
    switch (this) {
      case ResourceCategory.all:
        return Icons.apps;
      case ResourceCategory.clinics:
        return Icons.local_hospital;
      case ResourceCategory.mentalHealth:
        return Icons.psychology;
      case ResourceCategory.pharmacies:
        return Icons.medication;
      case ResourceCategory.food:
        return Icons.restaurant;
      case ResourceCategory.emergency:
        return Icons.emergency;
      case ResourceCategory.community:
        return Icons.people;
    }
  }

  List<ResourceType> get types {
    switch (this) {
      case ResourceCategory.all:
        return ResourceType.values;
      case ResourceCategory.clinics:
        return [ResourceType.clinic, ResourceType.hospital, ResourceType.urgentCare];
      case ResourceCategory.mentalHealth:
        return [ResourceType.mentalHealth, ResourceType.substanceUse];
      case ResourceCategory.pharmacies:
        return [ResourceType.pharmacy];
      case ResourceCategory.food:
        return [ResourceType.foodBank];
      case ResourceCategory.emergency:
        return [ResourceType.hotline, ResourceType.hospital];
      case ResourceCategory.community:
        return [
          ResourceType.community,
          ResourceType.housing,
          ResourceType.transportation,
          ResourceType.telehealth,
        ];
    }
  }
}

class ResourceFinderPage extends HookWidget {
  final VoidCallback onGoBack;

  const ResourceFinderPage({Key? key, required this.onGoBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedCategory = useState(ResourceCategory.all);
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final showFavoritesOnly = useState(false);
    final expandedResourceId = useState<String?>(null);

    // Debounced search query
    final debouncedSearchQuery =
        useDebounced(searchQuery.value, const Duration(milliseconds: 300));

    // Get all resources including emergency resources
    final allResources = useMemoized(() {
      return [...EmergencyResources.all, ...nswHealthResources];
    }, []);

    // Get real user data from AppState
    final appProfile = context.watch<AppState>().healthNavigationProfile;
    final userComplexity = context.watch<AppState>().complexityProfile;

    final userBarriers = useMemoized(() {
      return _barrierIdsToAssessment(
        barrierIds: appProfile?.barriers ?? [],
        complexity: userComplexity,
        preferredLanguage: appProfile?.languages.isNotEmpty == true
            ? appProfile!.languages.first
            : 'English',
        location: appProfile?.neighborhood,
      );
    }, [appProfile?.barriers, userComplexity, appProfile?.neighborhood]);

    final userRegion = appProfile?.neighborhood ?? '';
    final userLanguages = appProfile?.languages ?? const ['English'];

    // Apply matching to resources
    final matcherService = ResourceMatcherService();
    final matchedResources = useMemoized(() {
      return matcherService.getMatchedResources(
        resources: allResources,
        barriers: userBarriers,
        userRegion: userRegion,
        userLanguages: userLanguages,
      );
    }, [allResources, userBarriers]);

    // Filter resources based on category and search
    List<HealthResource> getFilteredResources() {
      var resources = matchedResources;
      final appState = Provider.of<AppState>(context, listen: false);

      // Apply category filter
      if (selectedCategory.value != ResourceCategory.all) {
        final types = selectedCategory.value.types;
        resources = resources.where((r) => types.contains(r.type)).toList();
      }

      // Apply favorites filter
      if (showFavoritesOnly.value) {
        resources = resources.where((resource) {
          return appState.favoriteResources.contains(resource.id);
        }).toList();
      }

      // Apply search filter
      if (debouncedSearchQuery?.isNotEmpty == true) {
        final query = debouncedSearchQuery!.toLowerCase();
        resources = resources.where((resource) {
          return resource.name.toLowerCase().contains(query) ||
              (resource.description?.toLowerCase().contains(query) ?? false) ||
              resource.servicesOffered
                  .any((s) => s.toLowerCase().contains(query)) ||
              (resource.neighborhood?.toLowerCase().contains(query) ?? false) ||
              (resource.region?.toLowerCase().contains(query) ?? false) ||
              resource.typeDisplayName.toLowerCase().contains(query);
        }).toList();
      }

      return resources;
    }

    final filteredResources = getFilteredResources();

    // Get top matched resources for "Matched for you" section
    final topMatches = useMemoized(() {
      return matchedResources
          .where((r) => r.matchScore >= 0.25 && r.matchReasons.isNotEmpty)
          .take(5)
          .toList();
    }, [matchedResources]);

    // Group remaining resources by category
    Map<String, List<HealthResource>> getGroupedResources() {
      final topMatchIds = topMatches.map((r) => r.id).toSet();
      final remaining = filteredResources
          .where((r) => !topMatchIds.contains(r.id))
          .toList();

      final Map<String, List<HealthResource>> grouped = {};
      for (final resource in remaining) {
        final category = resource.category;
        grouped.putIfAbsent(category, () => []);
        grouped[category]!.add(resource);
      }
      return grouped;
    }

    final groupedResources = getGroupedResources();

    final double horizontalPadding =
        MediaQuery.of(context).size.width < 600 ? StarboundSpacing.md : StarboundSpacing.lg;

    return CosmicPageScaffold(
      title: "Find Resources",
      subtitle: "Local health services matched to your needs",
      titleIcon: Icons.location_on_outlined,
      onBack: onGoBack,
      accentColor: StarboundColors.starlightBlue,
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: StarboundSpacing.md,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crisis Banner
          _buildCrisisBanner(context),

          const SizedBox(height: 12),

          // Search Bar
          CosmicSearchBar(
            controller: searchController,
            hintText: 'What do you need help with?',
            semanticsLabel: 'Search health resources',
            semanticsHint: 'Type to search through available health services',
            onChanged: (value) {
              searchQuery.value = value;
            },
            accentColor: StarboundColors.starlightBlue,
            trailing: searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: StarboundColors.cosmicWhite.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    onPressed: () {
                      searchController.clear();
                      searchQuery.value = '';
                    },
                    tooltip: 'Clear search',
                  )
                : null,
          ),

          const SizedBox(height: 12),

          // Quick Filters Row
          _buildQuickFilters(
            context,
            selectedCategory,
            showFavoritesOnly,
          ),

          const SizedBox(height: 16),

          // Main content
          Expanded(
            child: ListView(
              children: [
                // Matched for you section (only show if not searching/filtering)
                if (selectedCategory.value == ResourceCategory.all &&
                    !showFavoritesOnly.value &&
                    (debouncedSearchQuery?.isEmpty ?? true) &&
                    topMatches.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Matched for you',
                    subtitle: 'Based on your barriers & location',
                    icon: Icons.star_outline,
                  ),
                  const SizedBox(height: 8),
                  ...topMatches.map((resource) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Consumer<AppState>(
                          builder: (context, appState, child) {
                            return ResourceCard(
                              resource: resource,
                              isFavorite:
                                  appState.favoriteResources.contains(resource.id),
                              isExpanded: expandedResourceId.value == resource.id,
                              onToggleExpand: () {
                                expandedResourceId.value =
                                    expandedResourceId.value == resource.id
                                        ? null
                                        : resource.id;
                              },
                              onFavoritePressed: () {
                                HapticFeedback.lightImpact();
                                appState.toggleFavoriteResource(resource.id);
                              },
                              showMatchReasons: true,
                            );
                          },
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // All Resources or Filtered Results
                if (selectedCategory.value != ResourceCategory.all ||
                    showFavoritesOnly.value ||
                    (debouncedSearchQuery?.isNotEmpty ?? false)) ...[
                  // Show flat list when filtering
                  _buildSectionHeader(
                    context,
                    showFavoritesOnly.value
                        ? 'Saved Resources'
                        : selectedCategory.value != ResourceCategory.all
                            ? selectedCategory.value.displayName
                            : 'Search Results',
                    subtitle: '${filteredResources.length} resources',
                  ),
                  const SizedBox(height: 8),
                  if (filteredResources.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...filteredResources.map((resource) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Consumer<AppState>(
                            builder: (context, appState, child) {
                              return ResourceCard(
                                resource: resource,
                                isFavorite:
                                    appState.favoriteResources.contains(resource.id),
                                isExpanded:
                                    expandedResourceId.value == resource.id,
                                onToggleExpand: () {
                                  expandedResourceId.value =
                                      expandedResourceId.value == resource.id
                                          ? null
                                          : resource.id;
                                },
                                onFavoritePressed: () {
                                  HapticFeedback.lightImpact();
                                  appState.toggleFavoriteResource(resource.id);
                                },
                                showMatchReasons: true,
                              );
                            },
                          ),
                        )),
                ] else ...[
                  // Show grouped resources when not filtering
                  ...groupedResources.entries.map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            context,
                            entry.key,
                            subtitle: '${entry.value.length} resources',
                          ),
                          const SizedBox(height: 8),
                          ...entry.value.take(3).map((resource) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Consumer<AppState>(
                                  builder: (context, appState, child) {
                                    return ResourceCard(
                                      resource: resource,
                                      isFavorite: appState.favoriteResources
                                          .contains(resource.id),
                                      isExpanded:
                                          expandedResourceId.value == resource.id,
                                      onToggleExpand: () {
                                        expandedResourceId.value =
                                            expandedResourceId.value == resource.id
                                                ? null
                                                : resource.id;
                                      },
                                      onFavoritePressed: () {
                                        HapticFeedback.lightImpact();
                                        appState.toggleFavoriteResource(resource.id);
                                      },
                                      showMatchReasons: false,
                                    );
                                  },
                                ),
                              )),
                          if (entry.value.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextButton(
                                onPressed: () {
                                  // Find matching category
                                  for (final cat in ResourceCategory.values) {
                                    if (cat.displayName == entry.key ||
                                        entry.key.contains(cat.displayName)) {
                                      selectedCategory.value = cat;
                                      break;
                                    }
                                  }
                                },
                                child: Text(
                                  'See all ${entry.value.length} ${entry.key.toLowerCase()} resources →',
                                  style: TextStyle(
                                    color: StarboundColors.starlightBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      )),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisBanner(BuildContext context) {
    return CosmicGlassPanel.alert(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CosmicIconBadge.alert(icon: LucideIcons.alertTriangle),
          StarboundSpacing.hSpaceMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Need immediate support?",
                      style: StarboundTypography.heading4.copyWith(
                        color: StarboundColors.cosmicWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    StarboundSpacing.hSpaceSM,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: StarboundColors.success.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: StarboundColors.success),
                      ),
                      child: Text(
                        "24/7",
                        style: StarboundTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: StarboundColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                StarboundSpacing.spaceXS,
                Text(
                  "Lifeline: 13 11 14 — free, confidential support anytime",
                  style: StarboundTypography.bodySmall.copyWith(
                    height: 1.4,
                    color: StarboundColors.cosmicWhite,
                  ),
                ),
              ],
            ),
          ),
          StarboundSpacing.hSpaceMD,
          CosmicButton.primary(
            size: CosmicButtonSize.small,
            icon: Icons.phone,
            onPressed: () async {
              final uri = Uri(scheme: 'tel', path: '131114');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: const Text("Call"),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(
    BuildContext context,
    ValueNotifier<ResourceCategory> selectedCategory,
    ValueNotifier<bool> showFavoritesOnly,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Filters',
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.cosmicWhite.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            // Favorites Toggle
            GestureDetector(
              onTap: () {
                showFavoritesOnly.value = !showFavoritesOnly.value;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: showFavoritesOnly.value
                      ? StarboundColors.starlightBlue
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: showFavoritesOnly.value
                        ? StarboundColors.starlightBlue
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showFavoritesOnly.value ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: showFavoritesOnly.value
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Saved',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: showFavoritesOnly.value
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ResourceCategory.values.map((category) {
              final isSelected = selectedCategory.value == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    selectedCategory.value = category;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? StarboundColors.starlightBlue
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? StarboundColors.starlightBlue
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? subtitle,
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: StarboundColors.starlightBlue, size: 18),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: StarboundTypography.heading4.copyWith(
                  color: StarboundColors.cosmicWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: StarboundTypography.caption.copyWith(
                    color: StarboundColors.cosmicWhite.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: StarboundColors.cosmicWhite.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No resources found',
              style: StarboundTypography.heading4.copyWith(
                color: StarboundColors.cosmicWhite.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: StarboundTypography.bodySmall.copyWith(
                color: StarboundColors.cosmicWhite.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resource Card Widget
class ResourceCard extends StatelessWidget {
  final HealthResource resource;
  final bool isFavorite;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onFavoritePressed;
  final bool showMatchReasons;

  const ResourceCard({
    Key? key,
    required this.resource,
    required this.isFavorite,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onFavoritePressed,
    this.showMatchReasons = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor(resource.type);

    return GestureDetector(
      onTap: onToggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: themeColor.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource.typeEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        resource.typeDisplayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: themeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Availability / 24-7 badge
                if (resource.hours.isOpen24Hours)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: StarboundColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: StarboundColors.success),
                    ),
                    child: Text(
                      '24/7',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: StarboundColors.success,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Favorite button
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white.withValues(alpha: 0.7),
                    size: 22,
                  ),
                  onPressed: onFavoritePressed,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: isFavorite ? 'Remove from saved' : 'Save resource',
                ),
              ],
            ),

            // Match Reasons (if showing)
            if (showMatchReasons && resource.matchReasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StarboundColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: StarboundColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good fit for you:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: StarboundColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...resource.matchReasons.take(3).map((reason) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],

            // Description
            if (resource.description != null) ...[
              const SizedBox(height: 10),
              Text(
                resource.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.3,
                ),
                maxLines: isExpanded ? null : 2,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
              ),
            ],

            // Expanded content
            if (isExpanded) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),

              // Services
              if (resource.servicesOffered.isNotEmpty) ...[
                Text(
                  'Services:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: resource.servicesOffered.map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service,
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Hours
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    resource.hours.getDisplayText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      resource.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),

              // Phone
              if (resource.phone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      resource.phone!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],

              // Cost info
              if (resource.costInfo.isAffordable) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 14, color: StarboundColors.success),
                    const SizedBox(width: 6),
                    Text(
                      resource.costInfo.getDisplayText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: StarboundColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Special notes
              if (resource.specialNotes != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          resource.specialNotes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  if (resource.phone != null)
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.phone,
                        label: 'Call',
                        color: themeColor,
                        onPressed: () => _launchPhone(resource.phone!),
                      ),
                    ),
                  if (resource.phone != null) const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.directions,
                      label: 'Directions',
                      color: themeColor,
                      onPressed: () => _launchMaps(resource.address),
                    ),
                  ),
                  if (resource.website != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.open_in_browser,
                        label: 'Website',
                        color: themeColor,
                        onPressed: () => _launchWebsite(resource.website!),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Expand/collapse indicator
            if (!isExpanded) ...[
              const SizedBox(height: 8),
              Center(
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getThemeColor(ResourceType type) {
    switch (type) {
      case ResourceType.clinic:
      case ResourceType.hospital:
      case ResourceType.urgentCare:
        return const Color(0xFF3498DB); // Blue
      case ResourceType.mentalHealth:
      case ResourceType.substanceUse:
        return const Color(0xFF9B59B6); // Purple
      case ResourceType.pharmacy:
        return const Color(0xFF00F5D4); // Cyan
      case ResourceType.foodBank:
        return const Color(0xFFFF6B35); // Orange
      case ResourceType.hotline:
        return const Color(0xFFE91E63); // Pink/Red
      case ResourceType.community:
      case ResourceType.housing:
        return const Color(0xFF27AE60); // Green
      default:
        return const Color(0xFF00F5D4);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final cleanPhone = phone.replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://maps.apple.com/?q=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWebsite(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps string barrier IDs from HealthNavigationProfile to a HealthBarrierAssessment.
HealthBarrierAssessment _barrierIdsToAssessment({
  required List<String> barrierIds,
  required ComplexityLevel complexity,
  String preferredLanguage = 'English',
  String? location,
}) {
  const idToCategory = <String, HealthBarrierCategory>{
    'cost': HealthBarrierCategory.cost,
    'insurance': HealthBarrierCategory.insurance,
    'transportation': HealthBarrierCategory.transportation,
    'language': HealthBarrierCategory.language,
    'digital': HealthBarrierCategory.digital,
    'time': HealthBarrierCategory.time,
    'bad_experiences': HealthBarrierCategory.trust,
    'trust': HealthBarrierCategory.trust,
    'literacy': HealthBarrierCategory.literacy,
    'immigration': HealthBarrierCategory.documentation,
    'accessibility': HealthBarrierCategory.disability,
  };

  final primary = barrierIds
      .map((id) => idToCategory[id])
      .whereType<HealthBarrierCategory>()
      .toList();

  final severity = {for (final b in primary) b: 3};

  return HealthBarrierAssessment(
    primaryBarriers: primary,
    barrierSeverity: severity,
    navigationComplexity: complexity,
    preferredLanguage: preferredLanguage,
    location: location,
    assessmentDate: DateTime.now(),
  );
}
