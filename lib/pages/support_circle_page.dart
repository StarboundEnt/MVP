import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/service_model.dart';
import '../providers/app_state.dart';
import '../utils/tag_utils.dart';
import '../design_system/design_system.dart';

const Map<String, String> _supportTagMapping = {
  'need_fuel': 'nutrition',
  'balanced_meal': 'nutrition',
  'hydration_reset': 'nutrition',
  'need_rest': 'sleep',
  'sleep_hygiene': 'sleep',
  'rest_day': 'sleep',
  'overwhelmed': 'stress',
  'anxious_underlying': 'stress',
  'time_pressure': 'stress',
  'busy_day': 'stress',
  'need_clarity': 'counselling',
  'supportive_chat': 'counselling',
  'need_connection': 'support',
  'lonely': 'support',
  'family_duty': 'carer',
};

class SupportCirclePage extends HookWidget {
  final VoidCallback onGoBack;

  const SupportCirclePage({Key? key, required this.onGoBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedFilters = useState<List<String>>([]);
    final allServices = useState(StarboundServices.getSampleServices());
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final showFavoritesOnly = useState(false);
    final sortOption = useState(
        'relevance'); // 'relevance', 'availability', 'alphabetical', 'distance'

    // Debounced search query - only updates after user stops typing for 300ms
    final debouncedSearchQuery =
        useDebounced(searchQuery.value, const Duration(milliseconds: 300));

    // Current time state for real-time availability updates
    final currentTime = useState(DateTime.now());

    // Timer to update availability status every minute
    useEffect(() {
      final timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        currentTime.value = DateTime.now();
      });
      return timer.cancel;
    }, []);

    // Available filters
    final availableTags = [
      'carer',
      'student',
      'nutrition',
      'stress',
      'sleep',
      'crisis',
      'housing',
      'money',
      'counselling',
      'emergency',
      'support'
    ];
    final recentTagHighlights = context.watch<AppState>().getTopTags(
          limit: 5,
          timeframe: const Duration(days: 14),
        );
    final recommendedFilters = recentTagHighlights
        .map((entry) {
          final filter = _supportTagMapping[entry.key];
          if (filter == null || !availableTags.contains(filter)) {
            return null;
          }
          return MapEntry(entry.key, filter);
        })
        .whereType<MapEntry<String, String>>()
        .toList();

    // Filtered services - recalculates based on current state
    List<SupportService> getFilteredServices() {
      var services = allServices.value;
      final appState = Provider.of<AppState>(context, listen: false);

      // Apply favorites filter
      if (showFavoritesOnly.value) {
        services = services.where((service) {
          return appState.favoriteServices.contains(service.name);
        }).toList();
      }

      // Apply search filter (using debounced query for better performance)
      if (debouncedSearchQuery?.isNotEmpty == true) {
        services = services.where((service) {
          final query = debouncedSearchQuery!.toLowerCase();
          return service.name.toLowerCase().contains(query) ||
              service.description.toLowerCase().contains(query) ||
              service.reason.toLowerCase().contains(query) ||
              service.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }

      // Apply tag filters
      if (selectedFilters.value.isNotEmpty) {
        services = services.where((service) {
          return service.tags.any((tag) => selectedFilters.value.contains(tag));
        }).toList();
      }

      // Apply sorting
      services = _applySorting(services, sortOption.value);

      return services;
    }

    final filteredServices = getFilteredServices();

    void toggleFilter(String tag) {
      final currentFilters = List<String>.from(selectedFilters.value);
      if (currentFilters.contains(tag)) {
        currentFilters.remove(tag);
      } else {
        currentFilters.add(tag);
      }
      selectedFilters.value = currentFilters;
    }

    Future<void> launchContact(String contact) async {
      Uri? uri;

      if (contact.toLowerCase().startsWith('call ')) {
        // Extract phone number and create tel: URI
        final phone = contact.substring(5).replaceAll(' ', '');
        uri = Uri(scheme: 'tel', path: phone);
      } else if (contact.toLowerCase().startsWith('email ')) {
        // Extract email and create mailto: URI
        final email = contact.substring(6);
        uri = Uri(scheme: 'mailto', path: email);
      } else if (contact.toLowerCase().startsWith('text ')) {
        // Extract phone number and create sms: URI
        final phone = contact.substring(5).replaceAll(' ', '');
        uri = Uri(scheme: 'sms', path: phone);
      } else if (contact.toLowerCase().startsWith('visit ')) {
        // Extract URL
        final url = contact.substring(6);
        uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      } else if (contact.toLowerCase().startsWith('book online at ')) {
        // Extract URL
        final url = contact.substring(15);
        uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      }

      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: copy to clipboard
        await Clipboard.setData(ClipboardData(text: contact));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contact info copied to clipboard: $contact'),
              backgroundColor: const Color(0xFF00F5D4),
            ),
          );
        }
      }
    }

    final double horizontalPadding =
        MediaQuery.of(context).size.width < 600 ? StarboundSpacing.md : StarboundSpacing.lg;

    return CosmicPageScaffold(
      title: "Support Circle",
      subtitle: "Curated services matched to your recent needs",
      titleIcon: Icons.people_alt_outlined,
      onBack: onGoBack,
      accentColor: StarboundColors.cosmicPink,
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: StarboundSpacing.md,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demo Banner
          CosmicGlassPanel.info(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.only(bottom: StarboundSpacing.sm),
            child: Row(
              children: [
                CosmicIconBadge.info(icon: Icons.info_outline),
                StarboundSpacing.hSpaceMD,
                Expanded(
                  child: Text(
                    "Demo Feature — this support circle is for demonstration purposes only.",
                    style: StarboundTypography.bodySmall.copyWith(
                      color: StarboundColors.cosmicWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                StarboundSpacing.hSpaceMD,
                CosmicButton.secondary(
                  size: CosmicButtonSize.small,
                  icon: Icons.feedback_outlined,
                  onPressed: () {
                    Clipboard.setData(
                        const ClipboardData(text: "feedback@starbound.com"));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Let us know what you think at feedback@starbound.com!',
                        ),
                        backgroundColor: StarboundColors.starlightBlue,
                      ),
                    );
                  },
                  child: const Text("Share feedback"),
                ),
              ],
            ),
          ),

          // Urgent Banner
          CosmicGlassPanel.alert(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: StarboundSpacing.md),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: StarboundColors.success
                                  .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: StarboundColors.success),
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
                        "You can contact Crisis Care 24/7 — no judgment, just someone to talk to.",
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
                  onPressed: () => launchContact("Call 1800 246 247"),
                  child: const Text("Call Now"),
                ),
              ],
            ),
          ),

          if (recommendedFilters.isNotEmpty) ...[
            Text(
              'Based on your recent patterns',
            style: StarboundTypography.bodySmall.copyWith(
              color: StarboundColors.cosmicWhite.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recommendedFilters.map((entry) {
                final canonical = entry.key;
                final filter = entry.value;
                final isApplied = selectedFilters.value.contains(filter);
                final color = TagUtils.color(canonical);
                return ActionChip(
                  label: Text(
                    filter[0].toUpperCase() + filter.substring(1),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  avatar: Text(
                    TagUtils.emoji(canonical),
                    style: const TextStyle(fontSize: 13),
                  ),
                  backgroundColor:
                      color.withValues(alpha: isApplied ? 0.28 : 0.16),
                  shape: StadiumBorder(
                    side: BorderSide(color: color.withValues(alpha: 0.35)),
                  ),
                  onPressed: () => toggleFilter(filter),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Search & Filter Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CosmicSearchBar(
                controller: searchController,
                hintText: 'Search services...',
                semanticsLabel: 'Search support services',
                semanticsHint:
                    'Type to search through available support services',
                onChanged: (value) {
                  searchQuery.value = value;
                },
                accentColor: StarboundColors.cosmicPink,
                trailing: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color:
                              StarboundColors.cosmicWhite.withValues(alpha: 0.7),
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

              // Filters Header and Sort Options
              Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters & Sort',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          // Sort Dropdown
                          Semantics(
                            label: 'Sort services by',
                            hint:
                                'Choose how to sort the list of support services',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: sortOption.value,
                                  dropdownColor: const Color(0xFF2A0D5A),
                                  iconEnabledColor: Colors.white,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'relevance',
                                        child: Text('Relevance')),
                                    DropdownMenuItem(
                                        value: 'availability',
                                        child: Text('Available Now')),
                                    DropdownMenuItem(
                                        value: 'alphabetical',
                                        child: Text('A-Z')),
                                    DropdownMenuItem(
                                        value: 'distance',
                                        child: Text('Distance')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      sortOption.value = value;
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Favorites Toggle
                          Semantics(
                            label: 'Show favorites only',
                            hint: showFavoritesOnly.value
                                ? 'Currently showing only favorite services. Tap to show all services.'
                                : 'Tap to show only your favorite services',
                            button: true,
                            child: GestureDetector(
                              onTap: () {
                                showFavoritesOnly.value =
                                    !showFavoritesOnly.value;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: showFavoritesOnly.value
                                      ? const Color(0xFF00F5D4)
                                      : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: showFavoritesOnly.value
                                        ? const Color(0xFF00F5D4)
                                        : Colors.white.withValues(alpha: 0.5),
                                    width: showFavoritesOnly.value ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      showFavoritesOnly.value
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 16,
                                      color: showFavoritesOnly.value
                                          ? const Color(0xFF1F0150)
                                          : Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Favorites',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: showFavoritesOnly.value
                                            ? const Color(0xFF1F0150)
                                            : Colors.white,
                                        fontWeight: showFavoritesOnly.value
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Quick Filters Row
                  if (selectedFilters.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '${selectedFilters.value.length} filter${selectedFilters.value.length > 1 ? 's' : ''} active',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF00F5D4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              selectedFilters.value = [];
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.clear,
                                      size: 10, color: Colors.red),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Clear all',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.red,
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

                  // Filter Tags
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableTags.map((tag) {
                        final bool isSelected =
                            selectedFilters.value.contains(tag);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Semantics(
                            label: 'Filter by $tag',
                            hint: isSelected
                                ? '$tag filter is active. Tap to remove.'
                                : 'Tap to filter services by $tag',
                            button: true,
                            selected: isSelected,
                            child: Container(
                              height: 32,
                              child: InputChip(
                                label: Text(tag,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF1F0150)
                                          : Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 11,
                                    )),
                                backgroundColor: isSelected
                                    ? const Color(0xFF00F5D4)
                                    : Colors.white.withValues(alpha: 0.15),
                                selected: isSelected,
                                selectedColor: const Color(0xFF00F5D4),
                                onSelected: (_) => toggleFilter(tag),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF00F5D4)
                                        : Colors.white.withValues(alpha: 0.5),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ), // Close Search & Filter Section

              const SizedBox(height: 12),

              // Services Summary
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Showing ${filteredServices.length} services',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Service Cards
              Expanded(
                child: ListView.separated(
                  itemCount: filteredServices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final service = filteredServices[index];
                    final themeColor = getThemeColor(service.tags.firstWhere(
                      (t) => availableTags.contains(t),
                      orElse: () => "default",
                    ));
                    return Consumer<AppState>(
                      builder: (context, appState, child) {
                        final isFavorite =
                            appState.favoriteServices.contains(service.name);
                        return Semantics(
                          label: '${service.name} - ${service.reason}',
                          hint:
                              '${service.description}. Availability: ${service.isAvailableNow ? "Open now" : "Closed"}. ${service.schedules.isNotEmpty ? service.availabilityStatus : ""} Contact: ${service.contact}. ${isFavorite ? "Marked as favorite" : "Not in favorites"}',
                          child: SupportCard(
                            service: service,
                            themeColor: themeColor,
                            isFavorite: isFavorite,
                            onHeartPressed: () {
                              HapticFeedback.lightImpact();
                              appState.toggleFavoriteService(service.name);
                            },
                            onContactPressed: () =>
                                launchContact(service.contact),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ], // Close main children array
          ), // Close main Column (body parameter)
    ); // Close CosmicPageScaffold
  }

  // Apply sorting helper function
  List<SupportService> _applySorting(
      List<SupportService> services, String sortBy) {
    final servicesCopy = List<SupportService>.from(services);

    switch (sortBy) {
      case 'availability':
        servicesCopy.sort((a, b) {
          // Available services first
          if (a.isAvailableNow && !b.isAvailableNow) return -1;
          if (!a.isAvailableNow && b.isAvailableNow) return 1;

          // 24/7 services get priority
          final aIs24_7 = a.schedules.any((s) => s.isEmergency);
          final bIs24_7 = b.schedules.any((s) => s.isEmergency);
          if (aIs24_7 && !bIs24_7) return -1;
          if (!aIs24_7 && bIs24_7) return 1;

          // Then by name
          return a.name.compareTo(b.name);
        });
        break;

      case 'alphabetical':
        servicesCopy.sort((a, b) => a.name.compareTo(b.name));
        break;

      case 'distance':
        // For now, prioritize services with location data
        servicesCopy.sort((a, b) {
          final aHasLocation = a.location != null;
          final bHasLocation = b.location != null;
          if (aHasLocation && !bHasLocation) return -1;
          if (!aHasLocation && bHasLocation) return 1;
          return a.name.compareTo(b.name);
        });
        break;

      case 'relevance':
      default:
        // Default: Available services first, then emergency services, then alphabetical
        servicesCopy.sort((a, b) {
          if (a.isAvailableNow && !b.isAvailableNow) return -1;
          if (!a.isAvailableNow && b.isAvailableNow) return 1;

          final aIsEmergency =
              a.tags.contains('emergency') || a.tags.contains('crisis');
          final bIsEmergency =
              b.tags.contains('emergency') || b.tags.contains('crisis');
          if (aIsEmergency && !bIsEmergency) return -1;
          if (!aIsEmergency && bIsEmergency) return 1;

          return a.name.compareTo(b.name);
        });
        break;
    }

    return servicesCopy;
  }

  // Helper function to get theme color based on tag
  Color getThemeColor(String tag) {
    switch (tag) {
      case 'carer':
        return const Color(0xFF00F5D4);
      case 'student':
        return const Color(0xFFF5E6CA);
      case 'nutrition':
        return const Color(0xFFFF6B35);
      case 'stress':
        return const Color(0xFF9B59B6);
      case 'crisis':
        return const Color(0xFFE91E63);
      case 'housing':
        return const Color(0xFF3498DB);
      case 'money':
        return const Color(0xFF27AE60);
      case 'counselling':
        return const Color(0xFFAB47BC);
      case 'emergency':
        return const Color(0xFFFF4757);
      case 'support':
        return const Color(0xFF1ABC9C);
      default:
        return const Color(0xFF00F5D4);
    }
  }
}

// Support Card Widget
class SupportCard extends StatelessWidget {
  final SupportService service;
  final Color themeColor;
  final bool isFavorite;
  final VoidCallback onHeartPressed;
  final VoidCallback onContactPressed;

  const SupportCard({
    Key? key,
    required this.service,
    required this.themeColor,
    required this.isFavorite,
    required this.onHeartPressed,
    required this.onContactPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: themeColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(service.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Availability indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: service.isAvailableNow
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: service.isAvailableNow
                                  ? Colors.green
                                  : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                service.isAvailableNow
                                    ? Icons.access_time_filled
                                    : Icons.schedule,
                                size: 10,
                                color: service.isAvailableNow
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                service.isAvailableNow ? 'Open' : 'Closed',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: service.isAvailableNow
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.reason,
                            style: TextStyle(
                              fontSize: 11,
                              color: themeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (service.schedules.isNotEmpty)
                          Text(
                            service.availabilityStatus,
                            style: TextStyle(
                              fontSize: 9,
                              color: service.isAvailableNow
                                  ? Colors.green.withValues(alpha: 0.8)
                                  : Colors.orange.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Semantics(
                label:
                    isFavorite ? 'Remove from favorites' : 'Add to favorites',
                hint: isFavorite
                    ? 'This service is in your favorites. Tap to remove.'
                    : 'Tap to add this service to your favorites',
                button: true,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: onHeartPressed,
                  tooltip:
                      isFavorite ? 'Remove from favorites' : 'Add to favorites',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            service.description,
            style:
                const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Contact ${service.name}',
            hint: 'Tap to ${service.contact}',
            button: true,
            child: GestureDetector(
              onTap: onContactPressed,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: themeColor.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getContactIcon(service.contact),
                      size: 12,
                      color: themeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      service.contact,
                      style: TextStyle(
                        fontSize: 11,
                        color: themeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContactIcon(String contact) {
    final lowerContact = contact.toLowerCase();
    if (lowerContact.startsWith('call ')) {
      return Icons.phone;
    } else if (lowerContact.startsWith('email ')) {
      return Icons.email;
    } else if (lowerContact.startsWith('text ')) {
      return Icons.sms;
    } else if (lowerContact.startsWith('visit ') ||
        lowerContact.startsWith('book online at ')) {
      return Icons.open_in_browser;
    } else {
      return Icons.contact_support;
    }
  }
}
