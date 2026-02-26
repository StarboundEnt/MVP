import 'package:flutter/material.dart';

/// Starbound Design System - Responsive Breakpoints
/// Consistent breakpoints for responsive design across different screen sizes
class StarboundBreakpoints {
  // Private constructor to prevent instantiation
  StarboundBreakpoints._();

  // === BREAKPOINT VALUES ===
  /// Mobile small screens (up to 360px)
  static const double mobileSmall = 360;
  
  /// Mobile large screens (up to 480px)
  static const double mobileLarge = 480;
  
  /// Tablet portrait (up to 768px)
  static const double tablet = 768;
  
  /// Tablet landscape / small desktop (up to 1024px)
  static const double tabletLarge = 1024;
  
  /// Desktop (up to 1280px)
  static const double desktop = 1280;
  
  /// Large desktop (1280px+)
  static const double desktopLarge = 1440;

  // === SCREEN TYPE DETECTION ===
  
  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }
  
  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }
  
  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }
  
  /// Check if screen is small mobile
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= mobileSmall;
  }
  
  /// Check if screen is large mobile
  static bool isLargeMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileSmall && width < tablet;
  }

  // === RESPONSIVE VALUES ===
  
  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }
  
  /// Get responsive content width
  static double getContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isDesktop(context)) {
      return (screenWidth * 0.8).clamp(600, 1200);
    } else if (isTablet(context)) {
      return screenWidth * 0.9;
    } else {
      return screenWidth;
    }
  }
  
  /// Get responsive columns for grid layouts
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) {
      return 4;
    } else if (isTablet(context)) {
      return 3;
    } else if (isLargeMobile(context)) {
      return 2;
    } else {
      return 1;
    }
  }
  
  /// Get responsive font scale
  static double getFontScale(BuildContext context) {
    if (isSmallMobile(context)) {
      return 0.9;
    } else if (isDesktop(context)) {
      return 1.1;
    } else {
      return 1.0;
    }
  }
  
  /// Get responsive spacing multiplier
  static double getSpacingScale(BuildContext context) {
    if (isSmallMobile(context)) {
      return 0.8;
    } else if (isDesktop(context)) {
      return 1.2;
    } else {
      return 1.0;
    }
  }

  // === RESPONSIVE HELPER WIDGETS ===
  
  /// Responsive container with max width constraints
  static Widget responsiveContainer({
    required Widget child,
    required BuildContext context,
    double? maxWidth,
  }) {
    final contentWidth = maxWidth ?? getContentWidth(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentWidth),
        child: child,
      ),
    );
  }
  
  /// Responsive padding wrapper
  static Widget responsivePadding({
    required Widget child,
    required BuildContext context,
    EdgeInsets? customPadding,
  }) {
    return Padding(
      padding: customPadding ?? getResponsivePadding(context),
      child: child,
    );
  }

  // === LAYOUT BUILDERS ===
  
  /// Build different layouts based on screen size
  static Widget responsive({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    required BuildContext context,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
  
  /// Build layout with breakpoint-specific configurations
  static T breakpointValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    required BuildContext context,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

/// Extension methods for BuildContext to make responsive design easier
extension ResponsiveContext on BuildContext {
  /// Check if current screen is mobile
  bool get isMobile => StarboundBreakpoints.isMobile(this);
  
  /// Check if current screen is tablet
  bool get isTablet => StarboundBreakpoints.isTablet(this);
  
  /// Check if current screen is desktop
  bool get isDesktop => StarboundBreakpoints.isDesktop(this);
  
  /// Check if current screen is small mobile
  bool get isSmallMobile => StarboundBreakpoints.isSmallMobile(this);
  
  /// Check if current screen is large mobile
  bool get isLargeMobile => StarboundBreakpoints.isLargeMobile(this);
  
  /// Get responsive padding
  EdgeInsets get responsivePadding => StarboundBreakpoints.getResponsivePadding(this);
  
  /// Get content width
  double get contentWidth => StarboundBreakpoints.getContentWidth(this);
  
  /// Get grid columns
  int get gridColumns => StarboundBreakpoints.getGridColumns(this);
  
  /// Get font scale
  double get fontScale => StarboundBreakpoints.getFontScale(this);
  
  /// Get spacing scale
  double get spacingScale => StarboundBreakpoints.getSpacingScale(this);
}