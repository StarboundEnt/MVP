import 'package:flutter/material.dart';

// Performance optimization: Pre-defined constant values to avoid recreating objects
class AppConstants {
  // Colors - const values for better performance
  static const Color primaryColor = Color(0xFF00F5D4);
  static const Color secondaryColor = Color(0xFF9B5DE5);
  static const Color backgroundColor = Color(0xFF1F0150);
  static const Color surfaceColor = Color(0xFF1F0150);
  static const Color errorColor = Colors.red;
  static const Color successColor = Color(0xFF27AE60);
  static const Color warningColor = Colors.orange;
  
  // Text Styles - const values to prevent recreation
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: Colors.white,
  );
  
  static const TextStyle bodyTextSecondary = TextStyle(
    fontSize: 14,
    color: Colors.white70,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.white60,
  );
  
  // Durations - const values for animations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Spacing - const values for consistent spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border Radius - const values for consistent rounded corners
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  
  // Common EdgeInsets - const values to prevent recreation
  static const EdgeInsets paddingXS = EdgeInsets.all(spacingXS);
  static const EdgeInsets paddingS = EdgeInsets.all(spacingS);
  static const EdgeInsets paddingM = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingL = EdgeInsets.all(spacingL);
  static const EdgeInsets paddingXL = EdgeInsets.all(spacingXL);
  
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: spacingM);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: spacingM);
  
  // Common BorderRadius - const values to prevent recreation
  static const BorderRadius borderRadiusS = BorderRadius.all(Radius.circular(radiusS));
  static const BorderRadius borderRadiusM = BorderRadius.all(Radius.circular(radiusM));
  static const BorderRadius borderRadiusL = BorderRadius.all(Radius.circular(radiusL));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
  
  // Common Curves - const values for animations
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve quickCurve = Curves.easeOut;
  
  // Cache expiry times
  static const int cacheExpiryMinutes = 5;
  static const int longCacheExpiryMinutes = 30;
  
  // Performance thresholds
  static const int maxCachedItems = 100;
  static const int debounceMilliseconds = 500;
  static const int animationFrameRate = 60;
}

// Pre-defined decoration objects for better performance
class AppDecorations {
  static const BoxDecoration cardDecoration = BoxDecoration(
    color: Color(0x1AFFFFFF),
    borderRadius: AppConstants.borderRadiusM,
    border: Border.fromBorderSide(BorderSide(
      color: Color(0x33FFFFFF),
      width: 1,
    )),
  );
  
  static const BoxDecoration selectedCardDecoration = BoxDecoration(
    color: Color(0x3300F5D4),
    borderRadius: AppConstants.borderRadiusM,
    border: Border.fromBorderSide(BorderSide(
      color: AppConstants.primaryColor,
      width: 2,
    )),
  );
  
  static const BoxDecoration buttonDecoration = BoxDecoration(
    color: AppConstants.primaryColor,
    borderRadius: AppConstants.borderRadiusM,
  );
  
  static const BoxDecoration surfaceDecoration = BoxDecoration(
    color: AppConstants.surfaceColor,
    borderRadius: AppConstants.borderRadiusL,
  );
}
