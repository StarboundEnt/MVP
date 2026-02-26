import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your pages
import 'pages/home_page.dart';
import 'pages/resource_finder_page.dart';
import 'pages/journal_page.dart';
import 'pages/saved_items_page.dart';
import 'pages/settings_page.dart';
import 'pages/emergency_resources_page.dart';
import 'pages/complexity_test_page.dart';
import 'pages/feedback_page.dart';
import 'pages/user_profile_page.dart';

// Import models
import 'models/habit_model.dart';
import 'models/nudge_model.dart';

// Import components
import 'components/bottom_nav.dart';

// Import providers and services
import 'providers/app_state.dart';
import 'services/error_service.dart';
import 'services/api_service.dart';
import 'services/env_service.dart';
import 'pages/onboarding_page.dart';
import 'models/complexity_profile.dart';

// Import design system
import 'design_system/design_system.dart';

// Import smooth transitions
import 'utils/transitions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EnvService.instance.load();

  // Set up error handling
  FlutterError.onError = (details) {
    ErrorService().handleError(details.exception, stackTrace: details.stack);
  };

  // Initialize habit categories
  StarboundHabits.initialize();

  final apiService = ApiService();
  apiService.configure(
    baseUrl: EnvService.instance.maybe('COMPLEXITY_API_BASE_URL'),
    healthUrl: EnvService.instance.maybe('COMPLEXITY_API_HEALTH_URL'),
  );

  final complexityApiKey = EnvService.instance.maybe('COMPLEXITY_API_KEY');
  if (complexityApiKey != null && complexityApiKey.isNotEmpty) {
    apiService.setApiKey(complexityApiKey);
  }

  runApp(const StarboundApp());
}

class StarboundApp extends StatelessWidget {
  const StarboundApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
      ],
      child: MaterialApp(
        title: "Starbound",
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: StarboundColors.background,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.purple)
              .copyWith(surface: StarboundColors.background)
              .copyWith(error: StarboundColors.error),
          textTheme: TextTheme(
            bodyMedium: StarboundTypography.body
                .copyWith(color: StarboundColors.textPrimary),
            bodyLarge: StarboundTypography.bodyLarge
                .copyWith(color: StarboundColors.textPrimary),
            bodySmall: StarboundTypography.bodySmall
                .copyWith(color: StarboundColors.textPrimary),
            titleMedium: StarboundTypography.heading3
                .copyWith(color: StarboundColors.textPrimary),
            titleSmall: StarboundTypography.heading3
                .copyWith(color: StarboundColors.textPrimary),
          ),
          // Enhanced page transitions for smooth navigation
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.android: SlidePageTransitionsBuilder(),
            },
          ),
        ),
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Use a post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<AppState>().initialize();
      });
    } catch (e, stackTrace) {
      ErrorService().handleError(e,
          stackTrace: stackTrace, context: 'App initialization');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return Scaffold(
            backgroundColor: StarboundColors.background,
            body: Center(
              child: CosmicLoading.screen(
                style: CosmicLoadingStyle.galaxy,
                message: 'Launching Starbound...',
              ),
            ),
          );
        }

        if (appState.error != null) {
          return Scaffold(
            backgroundColor: StarboundColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: StarboundColors.error,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize app',
                    style: StarboundTypography.heading2.copyWith(
                      color: StarboundColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      appState.error!,
                      style: StarboundTypography.bodyLarge.copyWith(
                        color: StarboundColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _initializeApp(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StarboundColors.stellarAqua,
                      foregroundColor: StarboundColors.background,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Retry',
                      style: StarboundTypography.button,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!appState.isOnboardingComplete) {
          return OnboardingPage(
            onComplete: () {
              // Onboarding completion is handled by the AppState
              // The UI will automatically update when onboarding is complete
            },
          );
        }

        return const StarboundShell();
      },
    );
  }
}

class StarboundShell extends StatefulWidget {
  const StarboundShell({Key? key}) : super(key: key);

  @override
  State<StarboundShell> createState() => _StarboundShellState();
}

class _StarboundShellState extends State<StarboundShell> {
  int _currentIndex = 0;
  StarboundNudge? _currentNudge;
  final GlobalKey<JournalPageState> _journalPageKey =
      GlobalKey<JournalPageState>();

  void _goToPage(int index) {
    setState(() {
      _currentIndex = index;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index == 2) {
        _journalPageKey.currentState?.handlePendingJournalDraft();
      }
    });
  }

  void _updateCurrentNudge(AppState appState) async {
    final nudge = await appState.getCurrentNudge();
    if (mounted) {
      setState(() {
        _currentNudge = nudge;
      });
    }
  }

  void _showDebugMenu(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: StarboundColors.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build, size: 20, color: StarboundColors.textPrimary),
            const SizedBox(width: 8),
            Text('Debug Menu',
                style: StarboundTypography.heading3
                    .copyWith(color: StarboundColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.refresh, color: StarboundColors.stellarAqua),
              title: Text('Reset Onboarding',
                  style: StarboundTypography.bodyLarge
                      .copyWith(color: StarboundColors.textPrimary)),
              subtitle: Text('Clear onboarding to test again',
                  style: StarboundTypography.body
                      .copyWith(color: StarboundColors.textSecondary)),
              onTap: () async {
                await appState.setOnboardingComplete(false);
                await appState.updateUserName('Explorer');
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: StarboundColors.error),
              title: Text('Reset All Data',
                  style: StarboundTypography.bodyLarge
                      .copyWith(color: StarboundColors.textPrimary)),
              subtitle: Text('Clear all app data',
                  style: StarboundTypography.body
                      .copyWith(color: StarboundColors.textSecondary)),
              onTap: () async {
                await appState.resetAllData();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: StarboundColors.stellarYellow),
              title: Text('Change Profile',
                  style: StarboundTypography.bodyLarge
                      .copyWith(color: StarboundColors.textPrimary)),
              subtitle: Text('Current: ${appState.complexityProfile.name}',
                  style: StarboundTypography.body
                      .copyWith(color: StarboundColors.textSecondary)),
              onTap: () {
                Navigator.of(context).pop();
                _showProfileSelector(context, appState);
              },
            ),
            ListTile(
              leading: Icon(Icons.science, color: StarboundColors.nebulaPurple),
              title: Text('Test Complexity Levels',
                  style: StarboundTypography.bodyLarge
                      .copyWith(color: StarboundColors.textPrimary)),
              subtitle: Text('Interactive complexity testing',
                  style: StarboundTypography.body
                      .copyWith(color: StarboundColors.textSecondary)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ComplexityTestPage()),
                );
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.feedback, color: StarboundColors.stellarYellow),
              title: Text('Send Feedback',
                  style: StarboundTypography.bodyLarge
                      .copyWith(color: StarboundColors.textPrimary)),
              subtitle: Text('Share your thoughts and ideas',
                  style: StarboundTypography.body
                      .copyWith(color: StarboundColors.textSecondary)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const FeedbackPage()),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close',
                style: StarboundTypography.button
                    .copyWith(color: StarboundColors.stellarAqua)),
          ),
        ],
      ),
    );
  }

  void _showProfileSelector(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: StarboundColors.surface,
        title: Text('Select Complexity Profile',
            style: StarboundTypography.heading3
                .copyWith(color: StarboundColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ComplexityLevel.values.map((level) {
            return ListTile(
              title: Text(level.name,
                  style: StarboundTypography.bodyLarge
                      .copyWith(color: StarboundColors.textPrimary)),
              trailing: appState.complexityProfile == level
                  ? Icon(Icons.check, color: StarboundColors.stellarAqua)
                  : null,
              onTap: () async {
                await appState.updateComplexityProfile(level);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close',
                style: StarboundTypography.button
                    .copyWith(color: StarboundColors.stellarAqua)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Update current nudge asynchronously
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateCurrentNudge(appState);
        });

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(
                onSupportPressed: () => _goToPage(1),
                onActionVaultPressed: () => _goToPage(3),
                onJournalPressed: () => _goToPage(2),
                onInsightsPressed: () => _goToPage(4),
                onSettingsPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UserProfilePage(),
                    ),
                  );
                },
              ),
              ResourceFinderPage(onGoBack: () => _goToPage(0)),
              JournalPage(
                key: _journalPageKey,
                onGoBack: () => _goToPage(0),
                habits: appState.habits,
                updateHabit: appState.updateHabit,
                nudge: _currentNudge?.message ??
                    "Take a moment to check in with yourself.",
                bankNudge: () {
                  if (_currentNudge != null) {
                    appState.bankNudge(_currentNudge!);
                  }
                },
                onNavigateToAnalytics: () => _goToPage(4),
              ),
              SavedItemsPage(
                onGoBack: () => _goToPage(0),
              ),
              SettingsPage(
                onGoBack: () => _goToPage(0),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EmergencyResourcesPage(),
                ),
              );
            },
            backgroundColor: const Color(0xFFE74C3C),
            icon: const Icon(Icons.emergency, color: Colors.white),
            label: const Text(
              'Emergency',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: StarboundBottomNav(
            currentIndex: _currentIndex,
            onTap: _goToPage,
          ),
        );
      },
    );
  }
}
