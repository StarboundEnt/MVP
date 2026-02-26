import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../colors.dart';

/// Cosmic Loading Animations
/// Beautiful loading indicators with orbiting planets, shooting stars, and stellar effects
class CosmicLoading extends StatelessWidget {
  final CosmicLoadingStyle style;
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;
  final String? message;
  final Duration duration;

  const CosmicLoading({
    Key? key,
    this.style = CosmicLoadingStyle.orbital,
    this.size = 60.0,
    this.primaryColor,
    this.secondaryColor,
    this.message,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  /// Create a small inline loading indicator
  const CosmicLoading.small({
    Key? key,
    this.style = CosmicLoadingStyle.pulse,
    this.primaryColor,
    this.secondaryColor,
  }) : size = 24.0, message = null, duration = const Duration(seconds: 1), super(key: key);

  /// Create a large screen loading indicator
  const CosmicLoading.screen({
    Key? key,
    this.style = CosmicLoadingStyle.galaxy,
    this.primaryColor,
    this.secondaryColor,
    this.message = 'Loading...',
  }) : size = 120.0, duration = const Duration(seconds: 3), super(key: key);

  @override
  Widget build(BuildContext context) {
    final color1 = primaryColor ?? StarboundColors.stellarAqua;
    final color2 = secondaryColor ?? StarboundColors.cosmicPink;

    Widget loadingWidget;
    
    switch (style) {
      case CosmicLoadingStyle.orbital:
        loadingWidget = _OrbitalLoader(size: size, color: color1, duration: duration);
        break;
      case CosmicLoadingStyle.galaxy:
        loadingWidget = _GalaxyLoader(size: size, color1: color1, color2: color2, duration: duration);
        break;
      case CosmicLoadingStyle.pulse:
        loadingWidget = _PulseLoader(size: size, color: color1, duration: duration);
        break;
      case CosmicLoadingStyle.shootingStar:
        loadingWidget = _ShootingStarLoader(size: size, color: color1, duration: duration);
        break;
      case CosmicLoadingStyle.constellation:
        loadingWidget = _ConstellationLoader(size: size, color: color1, duration: duration);
        break;
    }

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingWidget,
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              color: StarboundColors.cosmicWhite.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return loadingWidget;
  }
}

enum CosmicLoadingStyle {
  orbital,
  galaxy,
  pulse,
  shootingStar,
  constellation,
}

/// Orbital loading with planets rotating around a center
class _OrbitalLoader extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _OrbitalLoader({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  State<_OrbitalLoader> createState() => _OrbitalLoaderState();
}

class _OrbitalLoaderState extends State<_OrbitalLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: OrbitalPainter(
              animationValue: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

/// Galaxy loading with multiple spinning rings
class _GalaxyLoader extends StatefulWidget {
  final double size;
  final Color color1;
  final Color color2;
  final Duration duration;

  const _GalaxyLoader({
    required this.size,
    required this.color1,
    required this.color2,
    required this.duration,
  });

  @override
  State<_GalaxyLoader> createState() => _GalaxyLoaderState();
}

class _GalaxyLoaderState extends State<_GalaxyLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: GalaxyPainter(
              animationValue: _controller.value,
              color1: widget.color1,
              color2: widget.color2,
            ),
          );
        },
      ),
    );
  }
}

/// Pulsing cosmic orb
class _PulseLoader extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _PulseLoader({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.1 + (0.4 * _controller.value)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5 * _controller.value),
                  blurRadius: 20 * _controller.value,
                  spreadRadius: 5 * _controller.value,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shooting star loader
class _ShootingStarLoader extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _ShootingStarLoader({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  State<_ShootingStarLoader> createState() => _ShootingStarLoaderState();
}

class _ShootingStarLoaderState extends State<_ShootingStarLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: ShootingStarLoaderPainter(
              animationValue: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

/// Constellation loading effect
class _ConstellationLoader extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _ConstellationLoader({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  State<_ConstellationLoader> createState() => _ConstellationLoaderState();
}

class _ConstellationLoaderState extends State<_ConstellationLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: ConstellationLoaderPainter(
              animationValue: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for orbital loading animation
class OrbitalPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  OrbitalPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;
    
    // Draw center star
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerPaint);
    
    // Draw orbiting planets
    for (int i = 0; i < 3; i++) {
      final angle = (animationValue * 2 * math.pi) + (i * 2 * math.pi / 3);
      final planetRadius = radius + (i * 8);
      final planetPosition = Offset(
        center.dx + math.cos(angle) * planetRadius,
        center.dy + math.sin(angle) * planetRadius,
      );
      
      final planetPaint = Paint()
        ..color = color.withValues(alpha: 0.8 - (i * 0.2))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(planetPosition, (3 - i).toDouble(), planetPaint);
      
      // Draw orbit path
      final pathPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, planetRadius, pathPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for galaxy loading animation
class GalaxyPainter extends CustomPainter {
  final double animationValue;
  final Color color1;
  final Color color2;

  GalaxyPainter({
    required this.animationValue,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw multiple rotating rings
    for (int ring = 0; ring < 3; ring++) {
      final ringRadius = (size.width * 0.2) + (ring * 12);
      final ringColor = Color.lerp(color1, color2, ring / 2.0)!;
      
      for (int dot = 0; dot < 8; dot++) {
        final angle = (animationValue * 2 * math.pi * (ring % 2 == 0 ? 1 : -1)) + 
                     (dot * 2 * math.pi / 8);
        final dotPosition = Offset(
          center.dx + math.cos(angle) * ringRadius,
          center.dy + math.sin(angle) * ringRadius,
        );
        
        final dotPaint = Paint()
          ..color = ringColor.withValues(alpha: 0.6 + 0.4 * math.sin(animationValue * 4 * math.pi + dot))
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(dotPosition, 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for shooting star loading animation
class ShootingStarLoaderPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  ShootingStarLoaderPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < 3; i++) {
      final progress = (animationValue + (i * 0.33)) % 1.0;
      final angle = i * 2 * math.pi / 3;
      
      final startRadius = size.width * 0.1;
      final endRadius = size.width * 0.4;
      final currentRadius = startRadius + (endRadius - startRadius) * progress;
      
      final starPosition = Offset(
        center.dx + math.cos(angle) * currentRadius,
        center.dy + math.sin(angle) * currentRadius,
      );
      
      // Draw star
      final starPaint = Paint()
        ..color = color.withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(starPosition, 3 * (1.0 - progress), starPaint);
      
      // Draw trail
      if (progress > 0.1) {
        final trailStart = Offset(
          center.dx + math.cos(angle) * (currentRadius - 20),
          center.dy + math.sin(angle) * (currentRadius - 20),
        );
        
        final trailPaint = Paint()
          ..color = color.withValues(alpha: 0.5 * (1.0 - progress))
          ..strokeWidth = 2 * (1.0 - progress)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        
        canvas.drawLine(trailStart, starPosition, trailPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for constellation loading animation
class ConstellationLoaderPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  ConstellationLoaderPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Define star positions
    final stars = [
      Offset(center.dx - 15, center.dy - 10),
      Offset(center.dx + 10, center.dy - 15),
      Offset(center.dx + 15, center.dy + 5),
      Offset(center.dx - 5, center.dy + 15),
      Offset(center.dx - 10, center.dy),
    ];
    
    // Draw connecting lines with animation
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < stars.length; i++) {
      final progress = ((animationValue * 2) - (i * 0.2)).clamp(0.0, 1.0);
      if (progress > 0) {
        final nextIndex = (i + 1) % stars.length;
        final start = stars[i];
        final end = stars[nextIndex];
        final current = Offset.lerp(start, end, progress)!;
        
        canvas.drawLine(start, current, linePaint);
      }
    }
    
    // Draw stars
    final starPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < stars.length; i++) {
      final starProgress = ((animationValue * 2) - (i * 0.1)).clamp(0.0, 1.0);
      if (starProgress > 0) {
        final glowRadius = 2 + (2 * math.sin(animationValue * 4 * math.pi + i));
        canvas.drawCircle(stars[i], glowRadius, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Full screen cosmic loading overlay
class CosmicLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final CosmicLoadingStyle style;

  const CosmicLoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
    this.message,
    this.style = CosmicLoadingStyle.galaxy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: StarboundColors.deepSpace.withValues(alpha: 0.8),
            child: Center(
              child: CosmicLoading.screen(
                style: style,
                message: message,
              ),
            ),
          ),
      ],
    );
  }
}