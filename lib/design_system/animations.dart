import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Starbound Design System - Stellar Animation System
/// Smooth, purposeful animations with cosmic timing and space-themed effects
class StarboundAnimations {
  // Private constructor to prevent instantiation
  StarboundAnimations._();

  // === DURATION CONSTANTS ===
  
  /// Ultra fast - 100ms (micro-interactions)
  static const Duration ultraFast = Duration(milliseconds: 100);
  
  /// Fast - 150ms (button presses, quick feedback)
  static const Duration fast = Duration(milliseconds: 150);
  
  /// Medium - 200ms (standard transitions)
  static const Duration medium = Duration(milliseconds: 200);
  
  /// Slow - 300ms (page transitions, complex animations)
  static const Duration slow = Duration(milliseconds: 300);
  
  /// Extra slow - 500ms (loading states, major transitions)
  static const Duration extraSlow = Duration(milliseconds: 500);

  // === COSMIC TIMING CURVES ===
  
  /// Smooth ease-out for natural motion
  static const Curve cosmicEase = Curves.easeOutCubic;
  
  /// Gentle ease-in-out for balanced motion
  static const Curve stellarEase = Curves.easeInOutCubic;
  
  /// Bouncy ease for playful interactions
  static const Curve nebulaEase = Curves.easeOutBack;
  
  /// Sharp ease for quick interactions
  static const Curve solarEase = Curves.easeOutQuart;

  // === SCALE ANIMATIONS ===
  
  /// Button press scale (slightly smaller)
  static const double buttonPressScale = 0.95;
  
  /// Card press scale (subtle feedback)
  static const double cardPressScale = 0.98;
  
  /// Icon press scale (more pronounced)
  static const double iconPressScale = 0.9;
  
  /// Hover scale (slight growth)
  static const double hoverScale = 1.05;

  // === ANIMATION BUILDERS ===
  
  /// Create a fade transition
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    Duration duration = medium,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Create a scale transition with cosmic easing
  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    Alignment alignment = Alignment.center,
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: cosmicEase,
      ),
      alignment: alignment,
      child: child,
    );
  }

  /// Create a slide transition
  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: cosmicEase,
      )),
      child: child,
    );
  }

  /// Create an orbital rotation animation
  static Widget orbitalRotation({
    required Widget child,
    required Animation<double> animation,
    bool clockwise = true,
  }) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.0,
        end: clockwise ? 1.0 : -1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.linear,
      )),
      child: child,
    );
  }

  /// Create a pulsing glow effect
  static Widget pulseGlow({
    required Widget child,
    required Animation<double> animation,
    Color glowColor = const Color(0xFF00F5D4),
    double maxGlow = 20.0,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.3 * animation.value),
                blurRadius: maxGlow * animation.value,
                spreadRadius: 2 * animation.value,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  /// Create a stellar constellation effect
  static Widget stellarConstellation({
    required Widget child,
    required Animation<double> animation,
    Color starColor = const Color(0xFF00F5D4),
    int starCount = 8,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: ConstellationPainter(
            animationValue: animation.value,
            starColor: starColor,
            starCount: starCount,
          ),
          child: child,
        );
      },
    );
  }

  /// Create a floating orbital effect for elements
  static Widget orbitalFloat({
    required Widget child,
    required Animation<double> animation,
    double radius = 2.0,
    Duration period = const Duration(seconds: 3),
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final angle = animation.value * 2 * math.pi;
        final offsetX = radius * math.cos(angle);
        final offsetY = radius * math.sin(angle) * 0.5; // Elliptical motion
        
        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: child,
        );
      },
    );
  }

  /// Create a breathing/pulsing scale effect
  static Widget breathingScale({
    required Widget child,
    required Animation<double> animation,
    double minScale = 0.98,
    double maxScale = 1.02,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final scale = minScale + (maxScale - minScale) * animation.value;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }

  /// Create a shooting star transition effect
  static Widget shootingStar({
    required Widget child,
    required Animation<double> animation,
    Alignment startAlignment = Alignment.topRight,
    Alignment endAlignment = Alignment.bottomLeft,
    Color trailColor = const Color(0xFF00F5D4),
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          children: [
            // Star trail
            if (animation.value > 0.1)
              Positioned.fill(
                child: CustomPaint(
                  painter: ShootingStarPainter(
                    animationValue: animation.value,
                    startAlignment: startAlignment,
                    endAlignment: endAlignment,
                    trailColor: trailColor,
                  ),
                ),
              ),
            // Main content
            child,
          ],
        );
      },
    );
  }

  /// Create a shimmer effect for loading states
  static Widget shimmerEffect({
    required Widget child,
    required Animation<double> animation,
    Color baseColor = const Color(0xFF1F0150),
    Color highlightColor = const Color(0xFF00F5D4),
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [
                baseColor,
                highlightColor.withValues(alpha: 0.7),
                baseColor,
              ],
              stops: [
                0.0,
                0.5 + 0.3 * animation.value,
                1.0,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }

  // === PAGE TRANSITIONS ===
  
  /// Cosmic slide page transition
  static PageRouteBuilder<T> cosmicSlideTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: medium,
      reverseTransitionDuration: medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: cosmicEase,
          )),
          child: child,
        );
      },
    );
  }

  /// Stellar fade page transition
  static PageRouteBuilder<T> stellarFadeTransition<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: medium,
      reverseTransitionDuration: medium,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: cosmicEase,
          ),
          child: child,
        );
      },
    );
  }

  // === UTILITY METHODS ===
  
  /// Create an animation controller with cosmic timing
  static AnimationController createCosmicController({
    required TickerProvider vsync,
    Duration duration = medium,
  }) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
    );
  }

  /// Create a curved animation with stellar easing
  static CurvedAnimation createStellarCurve({
    required AnimationController parent,
    Curve curve = cosmicEase,
  }) {
    return CurvedAnimation(
      parent: parent,
      curve: curve,
    );
  }

  /// Create a repeating pulse animation
  static void startPulseAnimation(AnimationController controller) {
    controller.repeat(reverse: true);
  }

  /// Create a one-time bounce animation
  static void startBounceAnimation(AnimationController controller) {
    controller.forward().then((_) {
      controller.reverse();
    });
  }

  /// Stop all animations gracefully
  static void stopAnimation(AnimationController controller) {
    controller.stop();
    controller.reset();
  }

  // === PRESET ANIMATIONS ===
  
  /// Button press animation preset
  static void animateButtonPress(AnimationController controller) {
    controller.forward().then((_) {
      Future.delayed(ultraFast, () {
        controller.reverse();
      });
    });
  }

  /// Card hover animation preset
  static void animateCardHover(AnimationController controller, bool isHovering) {
    if (isHovering) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  /// Loading animation preset
  static void startLoadingAnimation(AnimationController controller) {
    controller.repeat();
  }

  /// Success animation preset
  static void animateSuccess(AnimationController controller) {
    controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        controller.reverse();
      });
    });
  }
}

/// Custom painter for constellation effects
class ConstellationPainter extends CustomPainter {
  final double animationValue;
  final Color starColor;
  final int starCount;
  
  ConstellationPainter({
    required this.animationValue,
    required this.starColor,
    required this.starCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = starColor.withValues(alpha: animationValue * 0.8)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = starColor.withValues(alpha: animationValue * 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Generate star positions in a constellation pattern
    final stars = <Offset>[];
    final random = math.Random(42); // Fixed seed for consistent pattern
    
    for (int i = 0; i < starCount; i++) {
      final angle = (i / starCount) * 2 * math.pi + (animationValue * math.pi / 4);
      final distance = size.width * 0.3 + (random.nextDouble() * size.width * 0.2);
      final x = size.width / 2 + math.cos(angle) * distance;
      final y = size.height / 2 + math.sin(angle) * distance * 0.6;
      stars.add(Offset(x, y));
    }

    // Draw constellation lines
    if (animationValue > 0.3) {
      final lineAlpha = math.min(1.0, (animationValue - 0.3) / 0.4);
      linePaint.color = starColor.withValues(alpha: lineAlpha * 0.3);
      
      for (int i = 0; i < stars.length - 1; i++) {
        if (i % 2 == 0) { // Only connect some stars to avoid overcrowding
          canvas.drawLine(stars[i], stars[i + 1], linePaint);
        }
      }
    }

    // Draw stars
    for (final star in stars) {
      final starSize = 3 + (animationValue * 2);
      
      // Star center
      canvas.drawCircle(star, starSize, paint);
      
      // Star rays
      final rayPaint = Paint()
        ..color = starColor.withValues(alpha: animationValue * 0.6)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(star.dx - starSize * 1.5, star.dy),
        Offset(star.dx + starSize * 1.5, star.dy),
        rayPaint,
      );
      canvas.drawLine(
        Offset(star.dx, star.dy - starSize * 1.5),
        Offset(star.dx, star.dy + starSize * 1.5),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for shooting star effects
class ShootingStarPainter extends CustomPainter {
  final double animationValue;
  final Alignment startAlignment;
  final Alignment endAlignment;
  final Color trailColor;
  
  ShootingStarPainter({
    required this.animationValue,
    required this.startAlignment,
    required this.endAlignment,
    required this.trailColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue <= 0) return;

    final start = Offset(
      startAlignment.x * size.width / 2 + size.width / 2,
      startAlignment.y * size.height / 2 + size.height / 2,
    );
    final end = Offset(
      endAlignment.x * size.width / 2 + size.width / 2,
      endAlignment.y * size.height / 2 + size.height / 2,
    );
    
    // Calculate current position based on animation
    final current = Offset.lerp(start, end, animationValue)!;
    
    // Create trail effect
    final trailLength = 50.0;
    final trailStart = Offset.lerp(start, current, math.max(0, animationValue - 0.2))!;
    
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        trailColor.withValues(alpha: 0.0),
        trailColor.withValues(alpha: 0.8 * animationValue),
      ],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromPoints(trailStart, current))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(trailStart, current, paint);
    
    // Draw star at current position
    final starPaint = Paint()
      ..color = trailColor.withValues(alpha: animationValue)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(current, 3, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}