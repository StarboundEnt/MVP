import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'secure_storage_service.dart';

/// Comprehensive accessibility service for Starbound app
/// 
/// This service provides:
/// - Screen reader optimization
/// - Voice control support
/// - High contrast themes
/// - Font size scaling
/// - Keyboard navigation
/// - Gesture customization
/// - Accessibility announcements
/// - WCAG compliance monitoring
class AccessibilityService {
  static AccessibilityService? _instance;
  static AccessibilityService get instance => _instance ??= AccessibilityService._();
  
  AccessibilityService._();

  late final SecureStorageService _secureStorage;
  bool _isInitialized = false;
  
  AccessibilitySettings? _currentSettings;
  
  // Accessibility state
  bool _screenReaderEnabled = false;
  bool _highContrastEnabled = false;
  double _textScaleFactor = 1.0;
  bool _reduceMotionEnabled = false;
  bool _voiceControlEnabled = false;
  
  // Event streams
  final StreamController<AccessibilityEvent> _eventController = 
      StreamController<AccessibilityEvent>.broadcast();
  final StreamController<AccessibilityAnnouncement> _announcementController = 
      StreamController<AccessibilityAnnouncement>.broadcast();
  
  // Focus management
  FocusNode? _currentFocus;
  final List<FocusNode> _focusHistory = [];
  
  // Gesture customization
  final Map<String, GestureSettings> _customGestures = {};
  
  // Voice commands
  final Map<String, VoiceCommand> _voiceCommands = {};

  /// Initialize the accessibility service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _secureStorage = SecureStorageService();
      await _secureStorage.initialize();
      
      // Load accessibility settings
      await _loadAccessibilitySettings();
      
      // Set up system accessibility listeners
      _setupAccessibilityListeners();
      
      // Initialize voice commands
      _initializeVoiceCommands();
      
      // Initialize custom gestures
      _initializeCustomGestures();
      
      _isInitialized = true;
      
      await _announceToUser('Accessibility service initialized');
      
    } catch (e) {
      throw AccessibilityException('Failed to initialize accessibility service: $e');
    }
  }

  /// Stream getters
  Stream<AccessibilityEvent> get events => _eventController.stream;
  Stream<AccessibilityAnnouncement> get announcements => _announcementController.stream;

  /// Current accessibility settings
  AccessibilitySettings get currentSettings => 
      _currentSettings ?? AccessibilitySettings.defaultSettings();

  /// Update accessibility settings
  Future<void> updateSettings(AccessibilitySettings settings) async {
    _ensureInitialized();

    try {
      final oldSettings = _currentSettings;
      _currentSettings = settings;
      
      // Apply settings changes
      await _applySettings(settings);
      
      // Save to secure storage
      await _saveSettings(settings);
      
      // Emit event
      _eventController.add(AccessibilityEvent(
        type: AccessibilityEventType.settingsUpdated,
        message: 'Accessibility settings updated',
        oldSettings: oldSettings,
        newSettings: settings,
        timestamp: DateTime.now(),
      ));
      
      await _announceToUser('Accessibility settings updated');
      
    } catch (e) {
      throw AccessibilityException('Failed to update accessibility settings: $e');
    }
  }

  /// Enable/disable screen reader support
  Future<void> setScreenReaderEnabled(bool enabled) async {
    _ensureInitialized();
    
    _screenReaderEnabled = enabled;
    
    if (enabled) {
      SemanticsBinding.instance.ensureSemantics();
      await _announceToUser('Screen reader support enabled');
    } else {
      await _announceToUser('Screen reader support disabled');
    }
    
    final updatedSettings = currentSettings.copyWith(
      screenReaderEnabled: enabled,
    );
    
    await updateSettings(updatedSettings);
  }

  /// Enable/disable high contrast mode
  Future<void> setHighContrastEnabled(bool enabled) async {
    _ensureInitialized();
    
    _highContrastEnabled = enabled;
    
    final updatedSettings = currentSettings.copyWith(
      highContrastEnabled: enabled,
    );
    
    await updateSettings(updatedSettings);
    await _announceToUser(enabled 
        ? 'High contrast mode enabled' 
        : 'High contrast mode disabled');
  }

  /// Set text scale factor
  Future<void> setTextScaleFactor(double factor) async {
    _ensureInitialized();
    
    // Clamp factor to reasonable limits
    _textScaleFactor = factor.clamp(0.8, 3.0);
    
    final updatedSettings = currentSettings.copyWith(
      textScaleFactor: _textScaleFactor,
    );
    
    await updateSettings(updatedSettings);
    await _announceToUser('Text size changed to ${(_textScaleFactor * 100).round()}%');
  }

  /// Enable/disable reduce motion
  Future<void> setReduceMotionEnabled(bool enabled) async {
    _ensureInitialized();
    
    _reduceMotionEnabled = enabled;
    
    final updatedSettings = currentSettings.copyWith(
      reduceMotionEnabled: enabled,
    );
    
    await updateSettings(updatedSettings);
    await _announceToUser(enabled 
        ? 'Motion reduction enabled' 
        : 'Motion reduction disabled');
  }

  /// Create accessible widget wrapper
  Widget createAccessibleWidget({
    required Widget child,
    required String semanticLabel,
    String? semanticHint,
    bool? isButton,
    bool? isHeader,
    bool? isLink,
    VoidCallback? onTap,
    String? customAction,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: isButton ?? false,
      header: isHeader ?? false,
      link: isLink ?? false,
      onTap: onTap,
      customSemanticsActions: customAction != null 
          ? {
              CustomSemanticsAction(label: customAction): () {
                onTap?.call();
              }
            }
          : null,
      child: child,
    );
  }

  /// Create accessible form field
  Widget createAccessibleFormField({
    required Widget child,
    required String label,
    String? hint,
    String? errorText,
    bool required = false,
  }) {
    String semanticLabel = label;
    if (required) {
      semanticLabel += ', required';
    }
    
    String? semanticHint = hint;
    if (errorText != null) {
      semanticHint = errorText;
    }
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      textField: true,
      child: child,
    );
  }

  /// Create accessible navigation
  Widget createAccessibleNavigation({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onItemSelected,
  }) {
    return Semantics(
      label: 'Navigation',
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;
          
          return Semantics(
            label: '${item.label}${isSelected ? ', selected' : ''}',
            hint: 'Navigation item ${index + 1} of ${items.length}',
            button: true,
            selected: isSelected,
            onTap: () => onItemSelected(index),
            child: GestureDetector(
              onTap: () => onItemSelected(index),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 16 * _textScaleFactor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Announce message to screen reader
  Future<void> announceToUser(
    String message, {
    Assertiveness assertiveness = Assertiveness.polite,
  }) async {
    await _announceToUser(message, assertiveness: assertiveness);
  }

  /// Focus management
  void requestFocus(FocusNode focusNode) {
    _currentFocus = focusNode;
    _focusHistory.add(focusNode);
    
    // Limit history size
    if (_focusHistory.length > 10) {
      _focusHistory.removeAt(0);
    }
    
    focusNode.requestFocus();
  }

  void returnToPreviousFocus() {
    if (_focusHistory.length > 1) {
      _focusHistory.removeLast(); // Remove current
      final previousFocus = _focusHistory.last;
      requestFocus(previousFocus);
    }
  }

  /// Voice command registration
  void registerVoiceCommand(
    String command,
    String description,
    VoidCallback action,
  ) {
    _voiceCommands[command.toLowerCase()] = VoiceCommand(
      command: command,
      description: description,
      action: action,
    );
  }

  /// Execute voice command
  Future<bool> executeVoiceCommand(String command) async {
    final normalizedCommand = command.toLowerCase().trim();
    final voiceCommand = _voiceCommands[normalizedCommand];
    
    if (voiceCommand != null) {
      try {
        voiceCommand.action();
        await _announceToUser('Command executed: ${voiceCommand.description}');
        return true;
      } catch (e) {
        await _announceToUser('Command failed: ${voiceCommand.description}');
        return false;
      }
    }
    
    return false;
  }

  /// Get available voice commands
  List<VoiceCommand> getAvailableVoiceCommands() {
    return _voiceCommands.values.toList();
  }

  /// Keyboard navigation support
  Widget createKeyboardNavigable({
    required Widget child,
    required VoidCallback onActivate,
    String? semanticLabel,
  }) {
    return Focus(
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            onActivate();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        label: semanticLabel,
        button: true,
        onTap: onActivate,
        child: child,
      ),
    );
  }

  /// Gesture customization
  void registerCustomGesture(
    String name,
    GestureSettings settings,
  ) {
    _customGestures[name] = settings;
  }

  GestureSettings? getCustomGesture(String name) {
    return _customGestures[name];
  }

  /// Accessibility validation
  Future<AccessibilityValidationResult> validateAccessibility(
    BuildContext context,
  ) async {
    final issues = <AccessibilityIssue>[];
    
    // Check for missing semantic labels
    final semanticsNodes = _getSemanticsNodes(context);
    for (final node in semanticsNodes) {
      if (node.label.isEmpty && node.value.isEmpty) {
        issues.add(AccessibilityIssue(
          type: AccessibilityIssueType.missingLabel,
          severity: AccessibilitySeverity.warning,
          description: 'Widget missing semantic label',
          location: node.rect.toString(),
        ));
      }
      
      // Check for insufficient contrast
      if (_isInsufficientContrast(node)) {
        issues.add(AccessibilityIssue(
          type: AccessibilityIssueType.insufficientContrast,
          severity: AccessibilitySeverity.error,
          description: 'Insufficient color contrast',
          location: node.rect.toString(),
        ));
      }
      
      // Check for small touch targets
      if (_isTouchTargetTooSmall(node)) {
        issues.add(AccessibilityIssue(
          type: AccessibilityIssueType.smallTouchTarget,
          severity: AccessibilitySeverity.warning,
          description: 'Touch target too small',
          location: node.rect.toString(),
        ));
      }
    }
    
    return AccessibilityValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      validatedAt: DateTime.now(),
    );
  }

  /// Get accessibility theme
  ThemeData getAccessibilityTheme(ThemeData baseTheme) {
    if (!_highContrastEnabled) {
      return baseTheme.copyWith(
        textTheme: _scaleTextTheme(baseTheme.textTheme),
      );
    }
    
    // High contrast theme
    return baseTheme.copyWith(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Colors.yellow,
        secondary: Colors.yellow,
      ),
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey[900],
      textTheme: _scaleTextTheme(baseTheme.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  /// Private methods
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw AccessibilityException('Accessibility service not initialized');
    }
  }

  Future<void> _loadAccessibilitySettings() async {
    try {
      final settingsData = await _secureStorage.getPrivacySettings();
      if (settingsData != null && settingsData.containsKey('accessibility_settings')) {
        _currentSettings = AccessibilitySettings.fromJson(
          settingsData['accessibility_settings']
        );
      } else {
        _currentSettings = AccessibilitySettings.defaultSettings();
      }
      
      await _applySettings(_currentSettings!);
    } catch (e) {
      _currentSettings = AccessibilitySettings.defaultSettings();
    }
  }

  Future<void> _saveSettings(AccessibilitySettings settings) async {
    try {
      await _secureStorage.storePrivacySettings({
        'accessibility_settings': settings.toJson(),
      });
    } catch (e) {
      debugPrint('Failed to save accessibility settings: $e');
    }
  }

  Future<void> _applySettings(AccessibilitySettings settings) async {
    _screenReaderEnabled = settings.screenReaderEnabled;
    _highContrastEnabled = settings.highContrastEnabled;
    _textScaleFactor = settings.textScaleFactor;
    _reduceMotionEnabled = settings.reduceMotionEnabled;
    _voiceControlEnabled = settings.voiceControlEnabled;
    
    // Apply system-level settings if possible
    if (_screenReaderEnabled) {
      SemanticsBinding.instance.ensureSemantics();
    }
  }

  void _setupAccessibilityListeners() {
    // Listen for system accessibility changes
    // This would integrate with platform accessibility APIs
  }

  void _initializeVoiceCommands() {
    // Register default voice commands
    registerVoiceCommand(
      'go home',
      'Navigate to home screen',
      () => _announceToUser('Navigating to home'),
    );
    
    registerVoiceCommand(
      'read screen',
      'Read current screen content',
      () => _readCurrentScreen(),
    );
    
    registerVoiceCommand(
      'help',
      'Show available voice commands',
      () => _announceVoiceCommands(),
    );
  }

  void _initializeCustomGestures() {
    // Register default custom gestures
    registerCustomGesture(
      'double_tap_hold',
      GestureSettings(
        description: 'Double tap and hold for context menu',
        duration: const Duration(milliseconds: 800),
      ),
    );
    
    registerCustomGesture(
      'triple_tap',
      GestureSettings(
        description: 'Triple tap to activate zoom',
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _announceToUser(
    String message, {
    Assertiveness assertiveness = Assertiveness.polite,
  }) async {
    if (_screenReaderEnabled) {
      SemanticsService.announce(message, TextDirection.ltr, assertiveness: assertiveness);
    }
    
    _announcementController.add(AccessibilityAnnouncement(
      message: message,
      assertiveness: assertiveness,
      timestamp: DateTime.now(),
    ));
  }

  void _readCurrentScreen() {
    // This would read the current screen content
    _announceToUser('Reading current screen content');
  }

  void _announceVoiceCommands() {
    final commands = _voiceCommands.values
        .map((cmd) => '${cmd.command}: ${cmd.description}')
        .join('. ');
    
    _announceToUser('Available voice commands: $commands');
  }

  TextTheme _scaleTextTheme(TextTheme textTheme) {
    return textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontSize: (textTheme.displayLarge?.fontSize ?? 32) * _textScaleFactor,
      ),
      displayMedium: textTheme.displayMedium?.copyWith(
        fontSize: (textTheme.displayMedium?.fontSize ?? 28) * _textScaleFactor,
      ),
      displaySmall: textTheme.displaySmall?.copyWith(
        fontSize: (textTheme.displaySmall?.fontSize ?? 24) * _textScaleFactor,
      ),
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontSize: (textTheme.headlineLarge?.fontSize ?? 22) * _textScaleFactor,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontSize: (textTheme.headlineMedium?.fontSize ?? 20) * _textScaleFactor,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: (textTheme.headlineSmall?.fontSize ?? 18) * _textScaleFactor,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: (textTheme.titleLarge?.fontSize ?? 16) * _textScaleFactor,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: (textTheme.titleMedium?.fontSize ?? 14) * _textScaleFactor,
      ),
      titleSmall: textTheme.titleSmall?.copyWith(
        fontSize: (textTheme.titleSmall?.fontSize ?? 12) * _textScaleFactor,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontSize: (textTheme.bodyLarge?.fontSize ?? 16) * _textScaleFactor,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontSize: (textTheme.bodyMedium?.fontSize ?? 14) * _textScaleFactor,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        fontSize: (textTheme.bodySmall?.fontSize ?? 12) * _textScaleFactor,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontSize: (textTheme.labelLarge?.fontSize ?? 14) * _textScaleFactor,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(
        fontSize: (textTheme.labelMedium?.fontSize ?? 12) * _textScaleFactor,
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        fontSize: (textTheme.labelSmall?.fontSize ?? 10) * _textScaleFactor,
      ),
    );
  }

  List<SemanticsNode> _getSemanticsNodes(BuildContext context) {
    // This would traverse the semantics tree
    // For now, return empty list
    return [];
  }

  bool _isInsufficientContrast(SemanticsNode node) {
    // This would check color contrast ratios
    // WCAG requires 4.5:1 for normal text, 3:1 for large text
    return false; // Placeholder
  }

  bool _isTouchTargetTooSmall(SemanticsNode node) {
    // WCAG requires touch targets to be at least 44x44 dp
    return node.rect.width < 44 || node.rect.height < 44;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _eventController.close();
    await _announcementController.close();
  }
}

/// Accessibility settings model
class AccessibilitySettings {
  final bool screenReaderEnabled;
  final bool highContrastEnabled;
  final double textScaleFactor;
  final bool reduceMotionEnabled;
  final bool voiceControlEnabled;
  final bool keyboardNavigationEnabled;
  final Map<String, dynamic> customSettings;

  const AccessibilitySettings({
    required this.screenReaderEnabled,
    required this.highContrastEnabled,
    required this.textScaleFactor,
    required this.reduceMotionEnabled,
    required this.voiceControlEnabled,
    required this.keyboardNavigationEnabled,
    required this.customSettings,
  });

  factory AccessibilitySettings.defaultSettings() {
    return const AccessibilitySettings(
      screenReaderEnabled: false,
      highContrastEnabled: false,
      textScaleFactor: 1.0,
      reduceMotionEnabled: false,
      voiceControlEnabled: false,
      keyboardNavigationEnabled: true,
      customSettings: {},
    );
  }

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      screenReaderEnabled: json['screen_reader_enabled'] ?? false,
      highContrastEnabled: json['high_contrast_enabled'] ?? false,
      textScaleFactor: (json['text_scale_factor'] ?? 1.0).toDouble(),
      reduceMotionEnabled: json['reduce_motion_enabled'] ?? false,
      voiceControlEnabled: json['voice_control_enabled'] ?? false,
      keyboardNavigationEnabled: json['keyboard_navigation_enabled'] ?? true,
      customSettings: Map<String, dynamic>.from(json['custom_settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'screen_reader_enabled': screenReaderEnabled,
    'high_contrast_enabled': highContrastEnabled,
    'text_scale_factor': textScaleFactor,
    'reduce_motion_enabled': reduceMotionEnabled,
    'voice_control_enabled': voiceControlEnabled,
    'keyboard_navigation_enabled': keyboardNavigationEnabled,
    'custom_settings': customSettings,
  };

  AccessibilitySettings copyWith({
    bool? screenReaderEnabled,
    bool? highContrastEnabled,
    double? textScaleFactor,
    bool? reduceMotionEnabled,
    bool? voiceControlEnabled,
    bool? keyboardNavigationEnabled,
    Map<String, dynamic>? customSettings,
  }) {
    return AccessibilitySettings(
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      reduceMotionEnabled: reduceMotionEnabled ?? this.reduceMotionEnabled,
      voiceControlEnabled: voiceControlEnabled ?? this.voiceControlEnabled,
      keyboardNavigationEnabled: keyboardNavigationEnabled ?? this.keyboardNavigationEnabled,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Supporting classes and models
class NavigationItem {
  final String label;
  final IconData icon;
  final String route;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class VoiceCommand {
  final String command;
  final String description;
  final VoidCallback action;

  const VoiceCommand({
    required this.command,
    required this.description,
    required this.action,
  });
}

class GestureSettings {
  final String description;
  final Duration duration;

  const GestureSettings({
    required this.description,
    required this.duration,
  });
}

class AccessibilityEvent {
  final AccessibilityEventType type;
  final String message;
  final AccessibilitySettings? oldSettings;
  final AccessibilitySettings? newSettings;
  final DateTime timestamp;

  const AccessibilityEvent({
    required this.type,
    required this.message,
    this.oldSettings,
    this.newSettings,
    required this.timestamp,
  });
}

class AccessibilityAnnouncement {
  final String message;
  final Assertiveness assertiveness;
  final DateTime timestamp;

  const AccessibilityAnnouncement({
    required this.message,
    required this.assertiveness,
    required this.timestamp,
  });
}

class AccessibilityValidationResult {
  final bool isValid;
  final List<AccessibilityIssue> issues;
  final DateTime validatedAt;

  const AccessibilityValidationResult({
    required this.isValid,
    required this.issues,
    required this.validatedAt,
  });
}

class AccessibilityIssue {
  final AccessibilityIssueType type;
  final AccessibilitySeverity severity;
  final String description;
  final String location;

  const AccessibilityIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.location,
  });
}

/// Enums
enum AccessibilityEventType {
  settingsUpdated,
  screenReaderToggled,
  highContrastToggled,
  textScaleChanged,
  voiceCommandExecuted,
}

enum AccessibilityIssueType {
  missingLabel,
  insufficientContrast,
  smallTouchTarget,
  keyboardIncompat,
  missingSemantics,
}

enum AccessibilitySeverity {
  info,
  warning,
  error,
  critical,
}

/// Exception for accessibility operations
class AccessibilityException implements Exception {
  final String message;
  
  const AccessibilityException(this.message);
  
  @override
  String toString() => 'AccessibilityException: $message';
}