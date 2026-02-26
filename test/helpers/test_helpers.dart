import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starbound/providers/app_state.dart';
import 'package:starbound/models/habit_model.dart';
import 'package:starbound/models/nudge_model.dart';
import 'package:starbound/models/complexity_profile.dart';

/// Test utilities and helpers for Starbound tests
class TestHelpers {
  /// Creates a MaterialApp wrapper with necessary providers for testing
  static Widget createTestApp({
    required Widget child,
    AppState? appState,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (context) => appState ?? AppState(),
        ),
      ],
      child: MaterialApp(
        home: child,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1F0150),
        ),
      ),
    );
  }

  /// Creates a test app with scaffolding for full page tests
  static Widget createScaffoldTestApp({
    required Widget body,
    AppState? appState,
  }) {
    return createTestApp(
      appState: appState,
      child: Scaffold(body: body),
    );
  }

  /// Sets up SharedPreferences with mock data for testing
  static Future<void> setupMockSharedPreferences({
    Map<String, Object?>? initialValues,
  }) async {
    final source = initialValues ?? <String, Object?>{};
    SharedPreferences.setMockInitialValues({
      for (final entry in source.entries) entry.key: entry.value ?? ''
    });
  }

  /// Creates a mock AppState with predefined data for testing
  static AppState createMockAppState({
    bool isLoading = false,
    String? error,
    Map<String, String?>? habits,
    String userName = 'Test User',
    bool isOnboardingComplete = true,
    ComplexityLevel complexityProfile = ComplexityLevel.stable,
  }) {
    final appState = AppState();
    
    // Set initial state values
    appState.setLoading(isLoading);
    if (error != null) {
      appState.setError(error);
    }
    
    // This would require exposing more methods in AppState or using reflection
    // For now, we'll initialize through proper channels
    return appState;
  }

  /// Creates a sample habit for testing
  static StarboundHabit createTestHabit({
    String id = 'test-habit-id',
    String title = 'Test Habit',
    String category = 'Health',
    HabitType habitType = HabitType.choice,
    bool isCompleted = false,
    List<String>? completionDates,
    int streak = 0,
  }) {
    return StarboundHabit(
      id: id,
      title: title,
      category: category,
      habitType: habitType,
      isCompleted: isCompleted,
      completionDates: completionDates ?? [],
      streak: streak,
    );
  }

  /// Creates a sample nudge for testing
  static StarboundNudge createTestNudge({
    String id = 'test-nudge-id',
    String message = 'Test nudge message',
    NudgeType type = NudgeType.encouragement,
    String targetHabitId = 'test-habit-id',
    int priority = 1,
    DateTime? createdAt,
    bool isActive = true,
    int views = 0,
  }) {
    return StarboundNudge(
      id: id,
      message: message,
      type: type,
      targetHabitId: targetHabitId,
      priority: priority,
      createdAt: createdAt ?? DateTime.now(),
      isActive: isActive,
      views: views,
    );
  }

  /// Pumps a widget and waits for all animations to complete
  static Future<void> pumpAndSettleWidget(
    WidgetTester tester,
    Widget widget, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(timeout);
  }

  /// Simulates entering text in a TextField with proper settling
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  /// Simulates tapping a widget with proper settling
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  /// Verifies that a specific error message is displayed
  static void expectErrorMessage(String expectedMessage) {
    expect(find.textContaining(expectedMessage), findsOneWidget);
  }

  /// Verifies that a loading indicator is present
  static void expectLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// Verifies that no loading indicator is present
  static void expectNoLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  /// Creates test analytics data
  static Map<String, dynamic> createTestAnalyticsData({
    int totalHabits = 5,
    int completedHabits = 3,
    int currentStreak = 7,
    double completionRate = 0.6,
  }) {
    return {
      'totalHabits': totalHabits,
      'completedHabits': completedHabits,
      'currentStreak': currentStreak,
      'completionRate': completionRate,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Simulates a long press gesture
  static Future<void> longPressAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.longPress(finder);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  /// Simulates scrolling in a scrollable widget
  static Future<void> scrollAndSettle(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  /// Verifies that a specific widget type exists with given properties
  static void expectWidgetWithProperty<T extends Widget>(
    Type widgetType,
    bool Function(T widget) predicate,
  ) {
    final widgets = find.byType(widgetType).evaluate();
    expect(widgets.isNotEmpty, true, reason: 'Widget of type $widgetType not found');
    
    final widget = widgets.first.widget as T;
    expect(predicate(widget), true, reason: 'Widget does not match expected properties');
  }

  /// Creates a custom finder for text that contains a substring
  static Finder findTextContaining(String substring) {
    return find.byWidgetPredicate(
      (widget) => widget is Text && 
                   widget.data != null && 
                   widget.data!.contains(substring),
    );
  }

  /// Verifies that all expected navigation items are present
  static void expectNavigationItems(List<String> expectedItems) {
    for (final item in expectedItems) {
      expect(find.text(item), findsOneWidget, 
             reason: 'Navigation item "$item" not found');
    }
  }

  /// Simulates device rotation for responsive testing
  static Future<void> simulateDeviceRotation(
    WidgetTester tester, {
    bool isLandscape = false,
  }) async {
    final size = isLandscape 
        ? const Size(800, 600)  // Landscape
        : const Size(400, 800); // Portrait
    
    await tester.binding.setSurfaceSize(size);
    await tester.pump();
  }

  /// Verifies accessibility semantics for a widget
  static void expectAccessibilitySemantics(
    WidgetTester tester,
    Finder finder, {
    String? expectedLabel,
    String? expectedHint,
    bool? expectFocusable,
  }) {
    final semantics = tester.getSemantics(finder);
    
    if (expectedLabel != null) {
      expect(semantics.label, contains(expectedLabel));
    }
    
    if (expectedHint != null) {
      expect(semantics.hint, contains(expectedHint));
    }
    
    if (expectFocusable != null) {
      expect(
        semantics.hasFlag(SemanticsFlag.isFocusable),
        expectFocusable,
      );
    }
  }

  /// Waits for a specific condition to be true
  static Future<void> waitForCondition(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (!condition() && stopwatch.elapsed < timeout) {
      await tester.pump(interval);
    }
    
    if (!condition()) {
      throw TimeoutException('Condition not met within timeout', timeout);
    }
  }

  /// Creates a test environment with specific screen size
  static Future<void> setTestScreenSize(
    WidgetTester tester, {
    double width = 400,
    double height = 800,
    double pixelRatio = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, height));
    tester.view.physicalSize = Size(width * pixelRatio, height * pixelRatio);
    tester.view.devicePixelRatio = pixelRatio;
  }

  /// Verifies theme consistency across widgets
  static void expectThemeConsistency(BuildContext context) {
    final theme = Theme.of(context);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF1F0150));
    expect(theme.brightness, Brightness.dark);
  }

  /// Creates mock data for different test scenarios
  static Map<String, dynamic> createMockUserData({
    String userName = 'Test User',
    bool onboardingComplete = true,
    String complexityProfile = 'beginner',
    Map<String, String>? habits,
    List<String>? achievements,
  }) {
    return {
      'userName': userName,
      'onboardingComplete': onboardingComplete,
      'complexityProfile': complexityProfile,
      'habits': habits ?? {},
      'achievements': achievements ?? [],
      'lastSyncTime': DateTime.now().toIso8601String(),
    };
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Matcher for verifying habit completion status
  static Matcher hasHabitStatus(String habitId, String expectedStatus) {
    return predicate<Map<String, String?>>(
      (habits) => habits[habitId] == expectedStatus,
      'has habit $habitId with status $expectedStatus',
    );
  }

  /// Matcher for verifying streak count
  static Matcher hasStreak(int expectedStreak) {
    return predicate<StarboundHabit>(
      (habit) => habit.getCurrentStreak() == expectedStreak,
      'has streak of $expectedStreak',
    );
  }

  /// Matcher for verifying nudge priority
  static Matcher hasNudgePriority(int expectedPriority) {
    return predicate<StarboundNudge>(
      (nudge) => nudge.priority == expectedPriority,
      'has priority of $expectedPriority',
    );
  }
}

/// Exception for test timeouts
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  const TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}
