import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../colors.dart';
import '../animations.dart';

/// Gravitational Floating Action Button
/// Advanced FAB with gravitational pull effects and cosmic physics
class GravitationalFAB extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool extended;
  final String? tooltip;
  final String? heroTag;
  final double gravityStrength;
  final int particleCount;
  final Duration animationDuration;

  const GravitationalFAB({
    Key? key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 56.0,
    this.extended = false,
    this.tooltip,
    this.heroTag,
    this.gravityStrength = 0.8,
    this.particleCount = 6,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<GravitationalFAB> createState() => _GravitationalFABState();
}

class _GravitationalFABState extends State<GravitationalFAB>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _gravitationalController;
  late AnimationController _orbitalController;
  late AnimationController _pulseController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _gravitationalAnimation;

  final List<GravityParticle> _particles = [];
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _pressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _gravitationalController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _orbitalController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
    
    _gravitationalAnimation = CurvedAnimation(
      parent: _gravitationalController,
      curve: Curves.easeInOut,
    );
    
    // Initialize particles
    _initializeParticles();
    
    // Start continuous animations
    _gravitationalController.repeat();
    _orbitalController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _initializeParticles() {
    _particles.clear();
    final random = math.Random();
    
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(GravityParticle(
        angle: random.nextDouble() * 2 * math.pi,
        radius: 40 + random.nextDouble() * 30,
        speed: 0.5 + random.nextDouble() * 0.5,
        size: 2 + random.nextDouble() * 3,
        color: Color.lerp(
          widget.backgroundColor ?? StarboundColors.cosmicPink,
          StarboundColors.stellarAqua,
          random.nextDouble(),
        )!,
        opacity: 0.3 + random.nextDouble() * 0.5,
      ));
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _pressController.forward();
    HapticFeedback.mediumImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  @override
  void dispose() {
    _pressController.dispose();
    _gravitationalController.dispose();
    _orbitalController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? StarboundColors.cosmicPink;
    final foregroundColor = widget.foregroundColor ?? StarboundColors.cosmicWhite;

    Widget fabWidget = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Gravitational particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _gravitationalController,
                _orbitalController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: GravitationalFieldPainter(
                    particles: _particles,
                    gravitationalValue: _gravitationalAnimation.value,
                    orbitalValue: _orbitalController.value,
                    isPressed: _isPressed,
                    gravityStrength: widget.gravityStrength,
                  ),
                );
              },
            ),
          ),
          
          // Main FAB with cosmic effects
          Center(
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: widget.onPressed,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _pressController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            backgroundColor,
                            backgroundColor.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: backgroundColor.withValues(alpha: 0.4 + (0.2 * _pulseController.value)),
                            blurRadius: 12 + (8 * _pulseController.value),
                            spreadRadius: 2 + (3 * _pulseController.value),
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: IconTheme(
                          data: IconThemeData(
                            color: foregroundColor,
                            size: 24,
                          ),
                          child: widget.child,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    // Add orbital motion
    fabWidget = StarboundAnimations.orbitalFloat(
      animation: _orbitalController,
      radius: 1.0,
      child: fabWidget,
    );

    if (widget.tooltip != null) {
      fabWidget = Tooltip(
        message: widget.tooltip!,
        child: fabWidget,
      );
    }

    if (widget.heroTag != null) {
      fabWidget = Hero(
        tag: widget.heroTag!,
        child: fabWidget,
      );
    }

    return fabWidget;
  }
}

/// Data class for gravity particles
class GravityParticle {
  double angle;
  final double radius;
  final double speed;
  final double size;
  final Color color;
  final double opacity;

  GravityParticle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.color,
    required this.opacity,
  });

  void update(double deltaTime, bool isPressed, double gravityStrength) {
    // Normal orbital motion
    angle += speed * deltaTime;
    
    // Gravitational acceleration when pressed
    if (isPressed) {
      // Particles get pulled in faster
      angle += gravityStrength * deltaTime;
    }
  }
}

/// Custom painter for gravitational field effects
class GravitationalFieldPainter extends CustomPainter {
  final List<GravityParticle> particles;
  final double gravitationalValue;
  final double orbitalValue;
  final bool isPressed;
  final double gravityStrength;

  GravitationalFieldPainter({
    required this.particles,
    required this.gravitationalValue,
    required this.orbitalValue,
    required this.isPressed,
    required this.gravityStrength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (final particle in particles) {
      // Update particle position
      particle.update(0.016, isPressed, gravityStrength); // Assuming 60fps
      
      // Calculate gravitational effects
      double effectiveRadius = particle.radius;
      if (isPressed) {
        // Pull particles closer when pressed
        effectiveRadius *= 0.7 + 0.3 * (1.0 - gravityStrength);
      }
      
      // Add orbital motion
      final orbitalOffset = 2 * math.sin(orbitalValue * 2 * math.pi + particle.angle);
      effectiveRadius += orbitalOffset;
      
      // Calculate position
      final position = Offset(
        center.dx + math.cos(particle.angle) * effectiveRadius,
        center.dy + math.sin(particle.angle) * effectiveRadius,
      );
      
      // Draw particle with gravitational glow
      final glowRadius = particle.size + (isPressed ? 2 : 0);
      final glowOpacity = particle.opacity * (isPressed ? 1.5 : 1.0);
      
      // Glow effect
      final glowPaint = Paint()
        ..color = particle.color.withValues(alpha: glowOpacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(position, glowRadius * 2, glowPaint);
      
      // Main particle
      final particlePaint = Paint()
        ..color = particle.color.withValues(alpha: glowOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, particle.size, particlePaint);
      
      // Draw gravitational field lines when pressed
      if (isPressed) {
        final fieldPaint = Paint()
          ..color = particle.color.withValues(alpha: 0.2)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;
        
        final fieldPath = Path();
        fieldPath.moveTo(position.dx, position.dy);
        fieldPath.quadraticBezierTo(
          center.dx + (position.dx - center.dx) * 0.5,
          center.dy + (position.dy - center.dy) * 0.5,
          center.dx,
          center.dy,
        );
        canvas.drawPath(fieldPath, fieldPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Extended gravitational FAB for more content
class ExtendedGravitationalFAB extends StatelessWidget {
  final Widget icon;
  final Widget label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final String? heroTag;

  const ExtendedGravitationalFAB({
    Key? key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GravitationalFAB(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      tooltip: tooltip,
      heroTag: heroTag,
      extended: true,
      size: 48.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          label,
        ],
      ),
    );
  }
}

/// Mini gravitational FAB for smaller actions
class MiniGravitationalFAB extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final String? heroTag;

  const MiniGravitationalFAB({
    Key? key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GravitationalFAB(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      tooltip: tooltip,
      heroTag: heroTag,
      size: 40.0,
      particleCount: 4,
      gravityStrength: 0.6,
      child: child,
    );
  }
}