import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../colors.dart';

/// Cosmic Celebration Effects
/// Magical particle animations for achievement moments and celebrations
class CosmicCelebration extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final VoidCallback? onComplete;
  final CelebrationStyle style;
  final Duration duration;

  const CosmicCelebration({
    Key? key,
    required this.child,
    this.isActive = false,
    this.onComplete,
    this.style = CelebrationStyle.confetti,
    this.duration = const Duration(milliseconds: 2000),
  }) : super(key: key);

  @override
  State<CosmicCelebration> createState() => _CosmicCelebrationState();
}

class _CosmicCelebrationState extends State<CosmicCelebration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _particles = [];
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        setState(() {
          _particles.clear();
        });
      }
    });
  }

  @override
  void didUpdateWidget(CosmicCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !_wasActive) {
      _startCelebration();
    }
    
    _wasActive = widget.isActive;
  }

  void _startCelebration() {
    setState(() {
      _particles = _generateParticles();
    });
    _controller.reset();
    _controller.forward();
  }

  List<Particle> _generateParticles() {
    final random = math.Random();
    final particles = <Particle>[];
    final particleCount = widget.style == CelebrationStyle.confetti ? 30 : 15;

    for (int i = 0; i < particleCount; i++) {
      particles.add(Particle(
        startX: random.nextDouble(),
        startY: random.nextDouble() * 0.3 + 0.7, // Start from bottom area
        endX: random.nextDouble(),
        endY: random.nextDouble() * 0.5, // End in upper area
        color: _getRandomColor(random),
        size: random.nextDouble() * 8 + 4,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 4,
        style: widget.style,
      ));
    }

    return particles;
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      StarboundColors.stellarAqua,
      StarboundColors.cosmicPink,
      StarboundColors.nebulaPurple,
      StarboundColors.stellarYellow,
      StarboundColors.success,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlesPainter(
                    particles: _particles,
                    animationValue: _controller.value,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlesPainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      _paintParticle(canvas, size, particle);
    }
  }

  void _paintParticle(Canvas canvas, Size size, Particle particle) {
    final progress = animationValue;
    final fadeOut = progress > 0.8 ? (1.0 - progress) * 5 : 1.0;
    
    // Calculate current position with physics
    final currentX = particle.startX + (particle.endX - particle.startX) * progress;
    final gravity = progress * progress * 0.3; // Gravity effect
    final currentY = particle.startY + (particle.endY - particle.startY) * progress + gravity;
    
    final x = currentX * size.width;
    final y = currentY * size.height;
    
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(particle.rotation + particle.rotationSpeed * progress * math.pi * 2);
    
    final paint = Paint()
      ..color = particle.color.withValues(alpha: fadeOut)
      ..style = PaintingStyle.fill;

    switch (particle.style) {
      case CelebrationStyle.confetti:
        _paintConfetti(canvas, particle, paint);
        break;
      case CelebrationStyle.stars:
        _paintStar(canvas, particle, paint);
        break;
      case CelebrationStyle.sparkles:
        _paintSparkle(canvas, particle, paint);
        break;
    }
    
    canvas.restore();
  }

  void _paintConfetti(Canvas canvas, Particle particle, Paint paint) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: particle.size,
      height: particle.size * 0.6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(particle.size * 0.1)),
      paint,
    );
  }

  void _paintStar(Canvas canvas, Particle particle, Paint paint) {
    final path = Path();
    final radius = particle.size / 2;
    
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Inner point
      final innerAngle = angle + math.pi / 5;
      final innerX = math.cos(innerAngle) * radius * 0.4;
      final innerY = math.sin(innerAngle) * radius * 0.4;
      path.lineTo(innerX, innerY);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintSparkle(Canvas canvas, Particle particle, Paint paint) {
    final size = particle.size;
    canvas.drawCircle(Offset.zero, size / 2, paint);
    
    // Add sparkle lines
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(-size, 0), Offset(size, 0), paint);
    canvas.drawLine(Offset(0, -size), Offset(0, size), paint);
    canvas.drawLine(Offset(-size * 0.7, -size * 0.7), Offset(size * 0.7, size * 0.7), paint);
    canvas.drawLine(Offset(-size * 0.7, size * 0.7), Offset(size * 0.7, -size * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final CelebrationStyle style;

  Particle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.style,
  });
}

enum CelebrationStyle {
  confetti,
  stars,
  sparkles,
}

/// Simple celebration trigger widget
class CelebrationTrigger extends StatefulWidget {
  final Widget child;
  final CelebrationStyle style;
  final bool celebrate;
  final VoidCallback? onCelebrationComplete;

  const CelebrationTrigger({
    Key? key,
    required this.child,
    this.style = CelebrationStyle.confetti,
    this.celebrate = false,
    this.onCelebrationComplete,
  }) : super(key: key);

  @override
  State<CelebrationTrigger> createState() => _CelebrationTriggerState();
}

class _CelebrationTriggerState extends State<CelebrationTrigger> {
  bool _isActive = false;

  @override
  void didUpdateWidget(CelebrationTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.celebrate && !oldWidget.celebrate) {
      setState(() {
        _isActive = true;
      });
      
      // Reset after animation
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() {
            _isActive = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CosmicCelebration(
      isActive: _isActive,
      style: widget.style,
      onComplete: widget.onCelebrationComplete,
      child: widget.child,
    );
  }
}