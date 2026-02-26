import 'package:flutter/material.dart';
import 'colors.dart';

/// Starbound Design System - Futuristic Typography Hierarchy
/// Clean, readable typography with subtle futuristic touches
class StarboundTypography {
  // Private constructor to prevent instantiation
  StarboundTypography._();

  // === FONT WEIGHTS ===
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // === TEXT STYLES ===
  
  /// Display text - Hero headings and major titles
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: bold,
    color: StarboundColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Heading 1 - Section titles
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: semiBold,
    color: StarboundColors.textPrimary,
    letterSpacing: -0.25,
    height: 1.3,
  );

  /// Heading 2 - Subsection titles
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: semiBold,
    color: StarboundColors.textPrimary,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Heading 3 - Card titles and smaller headings
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: medium,
    color: StarboundColors.textPrimary,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Heading 4 - Smaller section headings
  static const TextStyle heading4 = TextStyle(
    fontSize: 16,
    fontWeight: medium,
    color: StarboundColors.textPrimary,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Body Large - Primary content text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: regular,
    color: StarboundColors.textPrimary,
    letterSpacing: 0,
    height: 1.5,
  );

  /// Body Medium - Medium content text  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: regular,
    color: StarboundColors.textPrimary,
    letterSpacing: 0,
    height: 1.5,
  );

  /// Body - Secondary content text
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    color: StarboundColors.textSecondary,
    letterSpacing: 0,
    height: 1.5,
  );

  /// Body Small - Tertiary content text
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: regular,
    color: StarboundColors.textTertiary,
    letterSpacing: 0.25,
    height: 1.4,
  );

  /// Caption - Metadata and labels
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: medium,
    color: StarboundColors.textTertiary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  /// Button text - Interactive element labels
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: semiBold,
    letterSpacing: 0.25,
    height: 1.2,
  );

  /// Button Large - Primary action buttons
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    letterSpacing: 0.25,
    height: 1.2,
  );

  /// Monospace - Data display and technical information
  static const TextStyle monospace = TextStyle(
    fontSize: 14,
    fontWeight: regular,
    color: StarboundColors.textSecondary,
    fontFamily: 'monospace',
    letterSpacing: 0,
    height: 1.4,
  );

  // === SPECIALIZED STYLES ===

  /// Stellar text with cosmic glow effect
  static TextStyle get stellar => display.copyWith(
    color: StarboundColors.stellarAqua,
    shadows: [
      Shadow(
        color: StarboundColors.withOpacity(StarboundColors.stellarAqua, 0.5),
        blurRadius: 8,
      ),
    ],
  );

  /// Nebula text with purple accent
  static TextStyle get nebula => heading1.copyWith(
    color: StarboundColors.nebulaPurple,
    shadows: [
      Shadow(
        color: StarboundColors.withOpacity(StarboundColors.nebulaPurple, 0.3),
        blurRadius: 4,
      ),
    ],
  );

  /// Error text styling
  static TextStyle get error => body.copyWith(
    color: StarboundColors.error,
  );

  /// Success text styling
  static TextStyle get success => body.copyWith(
    color: StarboundColors.success,
  );

  /// Warning text styling
  static TextStyle get warning => body.copyWith(
    color: StarboundColors.warning,
  );

  /// Info text styling
  static TextStyle get info => body.copyWith(
    color: StarboundColors.info,
  );

  // === UTILITY METHODS ===

  /// Create text style with custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Create text style with opacity
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(
      color: style.color?.withValues(alpha: opacity),
    );
  }

  /// Create text style with custom weight
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Create text style with custom size
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Create Flutter TextTheme for the app
  static TextTheme get textTheme => const TextTheme(
    displayLarge: display,
    displayMedium: display,
    displaySmall: heading1,
    headlineLarge: heading1,
    headlineMedium: heading2,
    headlineSmall: heading3,
    titleLarge: heading2,
    titleMedium: heading3,
    titleSmall: bodyLarge,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: bodySmall,
    labelLarge: button,
    labelMedium: caption,
    labelSmall: caption,
  );
}