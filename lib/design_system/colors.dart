import 'package:flutter/material.dart';

/// Starbound Design System - Cosmic Color Palette
/// Clean, retro-futuristic colors that support wellbeing and accessibility
class StarboundColors {
  // Private constructor to prevent instantiation
  StarboundColors._();

  // === PRIMARY BRAND COLORS ===
  /// Deep Space - Main background, your signature dark blue
  static const Color deepSpace = Color(0xFF1F0150);
  
  /// Cosmic Beige - Light surfaces and contrast elements
  static const Color cosmicBeige = Color(0xFFF5E6CA);
  
  /// Stellar Aqua - Primary accent, representing growth and vitality
  static const Color stellarAqua = Color(0xFF00F5D4);
  
  /// Cosmic White - Text and surface elements
  static const Color cosmicWhite = Color(0xFFFAFBFC);

  // === ACCENT COLORS (YOUR BRAND PALETTE) ===
  /// Nebula Purple - Secondary actions and highlights
  static const Color nebulaPurple = Color(0xFF9B5DE5);
  
  /// Solar Orange - Warning states and energy indicators
  static const Color solarOrange = Color(0xFFFF6B35);
  
  /// Cosmic Pink - Special states and celebrations
  static const Color cosmicPink = Color(0xFFFF4DA6);
  
  /// Starlight Blue - Information and calm states
  static const Color starlightBlue = Color(0xFF008BF8);
  
  /// Stellar Yellow - Attention and caution states
  static const Color stellarYellow = Color(0xFFFFDA3E);

  // === SURFACE COLORS ===
  /// Primary background
  static const Color background = deepSpace;
  
  /// Card and container backgrounds
  static const Color surface = Color(0xFF2A1B3D);
  
  /// Elevated surface backgrounds
  static const Color surfaceElevated = Color(0xFF3D2C50);
  
  /// Subtle surface overlays
  static const Color surfaceOverlay = Color(0x1AFAFBFC);

  // === TEXT COLORS ===
  /// Primary text - high contrast
  static const Color textPrimary = cosmicWhite;
  
  /// Secondary text - medium contrast
  static const Color textSecondary = Color(0xFFB8C5D1);
  
  /// Tertiary text - low contrast for subtle information
  static const Color textTertiary = Color(0xFF8A9BA8);
  
  /// Disabled text
  static const Color textDisabled = Color(0xFF5A6B78);

  // === STATUS COLORS ===
  /// Success states - excellent/good performance
  static const Color success = stellarAqua;
  
  /// Warning states - fair/moderate performance
  static const Color warning = stellarYellow;
  
  /// Error states - poor performance
  static const Color error = solarOrange;
  
  /// Info states - neutral information
  static const Color info = starlightBlue;

  // === INTERACTIVE COLORS ===
  /// Primary interactive elements
  static const Color interactive = stellarAqua;
  
  /// Pressed/active state
  static const Color interactivePressed = Color(0xFF00B894);
  
  /// Hover state
  static const Color interactiveHover = Color(0xFF1AFBEA);
  
  /// Disabled interactive elements
  static const Color interactiveDisabled = Color(0xFF5A6B78);

  // === BORDER COLORS ===
  /// Subtle borders
  static const Color borderSubtle = Color(0xFF3D2C50);
  
  /// Default borders
  static const Color borderDefault = Color(0xFF5A6B78);
  
  /// Emphasized borders
  static const Color borderEmphasis = stellarAqua;

  // === GRADIENT DEFINITIONS ===
  /// Primary cosmic background gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      deepSpace,
      Color(0xFF0F0228), // Darker deep space
    ],
  );

  /// Accent gradient for interactive elements
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      stellarAqua,
      starlightBlue,
    ],
  );

  /// Warm gradient for energy states
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      solarOrange,
      cosmicPink,
    ],
  );

  /// Cool gradient for calm states
  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      nebulaPurple,
      starlightBlue,
    ],
  );

  /// Card gradient for elevated surfaces
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surface,
      surfaceElevated,
    ],
  );

  // === UTILITY METHODS ===
  
  /// Get habit color based on performance level
  static Color getHabitColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'excellent':
      case 'high':
      case 'good':
      case 'many':
      case 'active':
        return success;
      case 'medium':
      case 'regular':
      case 'moderate':
      case 'some':
        return info;
      case 'low':
      case 'fair':
      case 'light':
      case 'few':
        return warning;
      case 'poor':
      case 'none':
      case 'skipped':
        return error;
      default:
        return textTertiary;
    }
  }

  /// Get color with opacity (helper method)
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Create subtle shadow for floating elements
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: withOpacity(Colors.black, 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Create elevated shadow for important elements
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: withOpacity(Colors.black, 0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: withOpacity(Colors.black, 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Create cosmic glow effect
  static List<BoxShadow> cosmicGlow(Color color, {double intensity = 0.3}) => [
    BoxShadow(
      color: withOpacity(color, intensity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: withOpacity(color, intensity * 0.3),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  /// Create stellar glow for interactive elements
  static List<BoxShadow> get stellarGlow => cosmicGlow(stellarAqua);

  /// Create nebula glow for secondary elements
  static List<BoxShadow> get nebulaGlow => cosmicGlow(nebulaPurple, intensity: 0.2);
}