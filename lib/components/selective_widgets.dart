import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Performance-optimized widget that only listens to loading state
class SelectiveLoadingIndicator extends StatelessWidget {
  final Widget child;
  
  const SelectiveLoadingIndicator({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    
    return ValueListenableBuilder<bool>(
      valueListenable: appState.isLoadingNotifier,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return child;
      },
    );
  }
}

/// Performance-optimized widget that only listens to error state
class SelectiveErrorDisplay extends StatelessWidget {
  final Widget child;
  
  const SelectiveErrorDisplay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    
    return ValueListenableBuilder<String?>(
      valueListenable: appState.errorNotifier,
      builder: (context, error, _) {
        return Column(
          children: [
            if (error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.red.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => appState.clearError(),
                    ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

/// Performance-optimized widget that only listens to habits state
class SelectiveHabitDisplay extends StatelessWidget {
  final Widget Function(BuildContext context, Map<String, String?> habits) builder;
  
  const SelectiveHabitDisplay({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    
    return ValueListenableBuilder<Map<String, String?>>(
      valueListenable: appState.habitsNotifier,
      builder: (context, habits, _) => builder(context, habits),
    );
  }
}

/// Performance-optimized widget that only listens to user name
class SelectiveUserNameDisplay extends StatelessWidget {
  final Widget Function(BuildContext context, String userName) builder;
  
  const SelectiveUserNameDisplay({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    
    return ValueListenableBuilder<String>(
      valueListenable: appState.userNameNotifier,
      builder: (context, userName, _) => builder(context, userName),
    );
  }
}

/// Performance-optimized widget that only listens to sync status
class SelectiveSyncStatus extends StatelessWidget {
  final Widget Function(BuildContext context, bool hasPendingSync) builder;
  
  const SelectiveSyncStatus({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    
    return ValueListenableBuilder<bool>(
      valueListenable: appState.syncStatusNotifier,
      builder: (context, hasPendingSync, _) => builder(context, hasPendingSync),
    );
  }
}

/// Selector-based widget for specific AppState properties
class AppStateSelector<T> extends StatelessWidget {
  final T Function(AppState appState) selector;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;
  
  const AppStateSelector({
    Key? key,
    required this.selector,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, T>(
      selector: (context, appState) => selector(appState),
      builder: builder,
      child: child,
    );
  }
}

/// Performance-optimized achievements display
class SelectiveAchievementBanner extends StatelessWidget {
  const SelectiveAchievementBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppStateSelector<bool>(
      selector: (appState) => appState.achievementsChanged,
      builder: (context, achievementsChanged, child) {
        // Only rebuild when achievements actually change
        return Selector<AppState, int>(
          selector: (context, appState) => appState.getUnlockableAchievements().length,
          builder: (context, achievementCount, _) {
            if (achievementCount == 0) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.withValues(alpha: 0.2), Colors.orange.withValues(alpha: 0.2)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Achievement Progress',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'You have $achievementCount achievements available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Optimized habit streak display that caches results
class CachedHabitStreak extends StatefulWidget {
  final String habitKey;
  
  const CachedHabitStreak({
    Key? key,
    required this.habitKey,
  }) : super(key: key);

  @override
  State<CachedHabitStreak> createState() => _CachedHabitStreakState();
}

class _CachedHabitStreakState extends State<CachedHabitStreak> {
  int? _cachedStreak;
  DateTime? _lastUpdate;
  
  @override
  Widget build(BuildContext context) {
    return AppStateSelector<bool>(
      selector: (appState) => appState.habitsChanged,
      builder: (context, habitsChanged, child) {
        // Only recalculate streak when habits actually change
        if (habitsChanged || _cachedStreak == null || 
            _lastUpdate == null || 
            DateTime.now().difference(_lastUpdate!).inMinutes > 5) {
          
          return FutureBuilder<Map<String, int>>(
            future: context.read<AppState>().getHabitStreak(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _cachedStreak = snapshot.data![widget.habitKey] ?? 0;
                _lastUpdate = DateTime.now();
                
                // Reset change tracking after processing
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<AppState>().resetChangeTracking();
                });
              }
              
              final streak = _cachedStreak ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: streak > 0 ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${streak}d',
                  style: TextStyle(
                    color: streak > 0 ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          );
        }
        
        // Use cached value if no changes
        final streak = _cachedStreak ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: streak > 0 ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${streak}d',
            style: TextStyle(
              color: streak > 0 ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}