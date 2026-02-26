import 'package:flutter/material.dart';

/// Starbound Design System - Orbital Grid Spacing System
/// Consistent spacing based on 8px cosmic units for harmonious layouts
class StarboundSpacing {
  // Private constructor to prevent instantiation
  StarboundSpacing._();

  // === BASE COSMIC UNIT ===
  static const double _cosmicUnit = 8.0;

  // === SPACING SCALE ===
  /// Extra small spacing - 4px
  static const double xs = _cosmicUnit * 0.5;
  
  /// Small spacing - 8px
  static const double sm = _cosmicUnit;
  
  /// Medium spacing - 16px
  static const double md = _cosmicUnit * 2;
  
  /// Large spacing - 24px
  static const double lg = _cosmicUnit * 3;
  
  /// Extra large spacing - 32px
  static const double xl = _cosmicUnit * 4;
  
  /// Extra extra large spacing - 48px
  static const double xxl = _cosmicUnit * 6;
  
  /// Massive spacing - 64px
  static const double massive = _cosmicUnit * 8;
  
  /// Orbital spacing - 96px (for major layout sections)
  static const double orbital = _cosmicUnit * 12;

  // === EDGE INSETS ===
  
  /// No padding
  static const EdgeInsets none = EdgeInsets.zero;
  
  /// Extra small padding - 4px all around
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  
  /// Small padding - 8px all around
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  
  /// Medium padding - 16px all around
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  
  /// Large padding - 24px all around
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  
  /// Extra large padding - 32px all around
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);

  // === HORIZONTAL PADDING ===
  
  /// Small horizontal padding
  static const EdgeInsets horizontalSM = EdgeInsets.symmetric(horizontal: sm);
  
  /// Medium horizontal padding
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  
  /// Large horizontal padding
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);
  
  /// Extra large horizontal padding
  static const EdgeInsets horizontalXL = EdgeInsets.symmetric(horizontal: xl);

  // === VERTICAL PADDING ===
  
  /// Small vertical padding
  static const EdgeInsets verticalSM = EdgeInsets.symmetric(vertical: sm);
  
  /// Medium vertical padding
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
  
  /// Large vertical padding
  static const EdgeInsets verticalLG = EdgeInsets.symmetric(vertical: lg);
  
  /// Extra large vertical padding
  static const EdgeInsets verticalXL = EdgeInsets.symmetric(vertical: xl);

  // === CARD PADDING ===
  
  /// Standard card padding
  static const EdgeInsets card = EdgeInsets.all(md);
  
  /// Compact card padding
  static const EdgeInsets cardCompact = EdgeInsets.all(sm);
  
  /// Spacious card padding
  static const EdgeInsets cardSpacious = EdgeInsets.all(lg);

  // === SCREEN MARGINS ===
  
  /// Standard screen margin
  static const EdgeInsets screen = EdgeInsets.all(md);
  
  /// Screen margin with extra horizontal space
  static const EdgeInsets screenWide = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // === COMPONENT SPACING ===
  
  /// Button padding
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
  
  /// Large button padding
  static const EdgeInsets buttonLarge = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: md,
  );
  
  /// Compact button padding
  static const EdgeInsets buttonCompact = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );

  // === SIZED BOXES FOR SPACING ===
  
  /// Extra small vertical space
  static const SizedBox spaceXS = SizedBox(height: xs);
  
  /// Small vertical space
  static const SizedBox spaceSM = SizedBox(height: sm);
  
  /// Medium vertical space
  static const SizedBox spaceMD = SizedBox(height: md);
  
  /// Large vertical space
  static const SizedBox spaceLG = SizedBox(height: lg);
  
  /// Extra large vertical space
  static const SizedBox spaceXL = SizedBox(height: xl);
  
  /// Extra extra large vertical space
  static const SizedBox spaceXXL = SizedBox(height: xxl);

  // === HORIZONTAL SIZED BOXES ===
  
  /// Extra small horizontal space
  static const SizedBox hSpaceXS = SizedBox(width: xs);
  
  /// Small horizontal space
  static const SizedBox hSpaceSM = SizedBox(width: sm);
  
  /// Medium horizontal space
  static const SizedBox hSpaceMD = SizedBox(width: md);
  
  /// Large horizontal space
  static const SizedBox hSpaceLG = SizedBox(width: lg);
  
  /// Extra large horizontal space
  static const SizedBox hSpaceXL = SizedBox(width: xl);

  // === BORDER RADIUS ===
  
  /// Small border radius - 4px
  static const BorderRadius radiusXS = BorderRadius.all(Radius.circular(xs));
  
  /// Medium border radius - 8px
  static const BorderRadius radiusSM = BorderRadius.all(Radius.circular(sm));
  
  /// Large border radius - 16px
  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(md));
  
  /// Extra large border radius - 24px
  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(lg));
  
  /// Circular border radius - 32px
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(xl));
  
  /// Pill-shaped border radius - 999px
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(999));

  // === UTILITY METHODS ===
  
  /// Create custom padding with cosmic units
  static EdgeInsets cosmic(double units) {
    return EdgeInsets.all(_cosmicUnit * units);
  }
  
  /// Create custom horizontal padding with cosmic units
  static EdgeInsets cosmicHorizontal(double units) {
    return EdgeInsets.symmetric(horizontal: _cosmicUnit * units);
  }
  
  /// Create custom vertical padding with cosmic units
  static EdgeInsets cosmicVertical(double units) {
    return EdgeInsets.symmetric(vertical: _cosmicUnit * units);
  }
  
  /// Create custom sized box with cosmic units
  static SizedBox cosmicSpace(double units) {
    return SizedBox(height: _cosmicUnit * units);
  }
  
  /// Create custom horizontal sized box with cosmic units
  static SizedBox cosmicHSpace(double units) {
    return SizedBox(width: _cosmicUnit * units);
  }
  
  /// Create custom border radius with cosmic units
  static BorderRadius cosmicRadius(double units) {
    return BorderRadius.all(Radius.circular(_cosmicUnit * units));
  }

  // === LAYOUT HELPERS ===
  
  /// Standard gap between list items
  static const double listGap = md;
  
  /// Gap between form fields
  static const double formGap = lg;
  
  /// Gap between sections
  static const double sectionGap = xl;
  
  /// Minimum touch target size (44px for accessibility)
  static const double minTouchTarget = 44.0;
  
  /// Standard app bar height
  static const double appBarHeight = 56.0;
  
  /// Bottom navigation height
  static const double bottomNavHeight = 80.0;
}