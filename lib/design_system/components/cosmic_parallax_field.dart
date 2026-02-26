import 'dart:math';

import 'package:flutter/material.dart';

import '../colors.dart';

/// Animated parallax starfield that reacts to gentle pointer movement and scroll.
class CosmicParallaxField extends StatefulWidget {
  final double scrollOffset;
  final Color baseColor;
  final Gradient? gradient;
  final bool enablePointerInteraction;

  const CosmicParallaxField({
    super.key,
    this.scrollOffset = 0,
    this.baseColor = StarboundColors.deepSpace,
    this.gradient,
    this.enablePointerInteraction = true,
  });

  @override
  State<CosmicParallaxField> createState() => _CosmicParallaxFieldState();
}

class _CosmicParallaxFieldState extends State<CosmicParallaxField>
    with TickerProviderStateMixin {
  late final AnimationController _twinkleController;
  late final AnimationController _driftController;
  Offset _pointerOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  void _handlePointer(PointerEvent event) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || box.hasSize == false) return;

    final Offset local = box.globalToLocal(event.position);
    final double normalizedX =
        ((local.dx / box.size.width) - 0.5).clamp(-0.5, 0.5) * 2;
    final double normalizedY =
        ((local.dy / box.size.height) - 0.5).clamp(-0.5, 0.5) * 2;

    final Offset target = Offset(normalizedX, normalizedY);
    setState(() {
      _pointerOffset = Offset.lerp(_pointerOffset, target, 0.35)!;
    });
  }

  void _resetPointer() {
    setState(() {
      _pointerOffset = Offset.lerp(_pointerOffset, Offset.zero, 0.2)!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget starfield = RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_twinkleController, _driftController]),
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _CosmicParallaxPainter(
              baseColor: widget.baseColor,
              gradient: widget.gradient,
              twinkleValue: _twinkleController.value,
              driftValue: _driftController.value,
              pointerOffset: _pointerOffset,
              scrollOffset: widget.scrollOffset,
            ),
          );
        },
      ),
    );

    if (!widget.enablePointerInteraction) {
      return starfield;
    }

    return Listener(
      onPointerHover: _handlePointer,
      onPointerMove: _handlePointer,
      onPointerDown: _handlePointer,
      onPointerUp: (_) => _resetPointer(),
      onPointerCancel: (_) => _resetPointer(),
      behavior: HitTestBehavior.translucent,
      child: MouseRegion(
        onExit: (_) => _resetPointer(),
        child: starfield,
      ),
    );
  }
}

class _CosmicParallaxPainter extends CustomPainter {
  static const double _twoPi = pi * 2;
  final Color baseColor;
  final Gradient? gradient;
  final double twinkleValue;
  final double driftValue;
  final Offset pointerOffset;
  final double scrollOffset;

  _CosmicParallaxPainter({
    required this.baseColor,
    required this.gradient,
    required this.twinkleValue,
    required this.driftValue,
    required this.pointerOffset,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;

    final Paint backgroundPaint = Paint()..color = baseColor;
    canvas.drawRect(bounds, backgroundPaint);

    if (gradient != null) {
      final Paint gradientPaint = Paint()
        ..shader = gradient!.createShader(bounds);
      canvas.drawRect(bounds, gradientPaint);
    }

    final Paint starPaint = Paint()..style = PaintingStyle.fill;

    const int starCount = 70;
    for (int i = 0; i < starCount; i++) {
      final int layer = i % 3;
      final double depth = 0.35 + (layer * 0.28);

      final double baseX = (bounds.width * 0.17 + i * 47.12) % bounds.width;
      final double baseY = (bounds.height * 0.21 + i * 51.73) % bounds.height;

      final double driftX =
          sin((i + 1) * 0.7 + driftValue * _twoPi) * (6 + layer * 5);
      final double driftY =
          cos((i + 1) * 0.6 + driftValue * _twoPi) * (4 + layer * 4);

      final double pointerX = pointerOffset.dx * 22 * depth;
      final double pointerY = pointerOffset.dy * 18 * depth;

      final double parallaxX = scrollOffset * depth * 0.01;
      final double parallaxY = scrollOffset * depth * -0.06;

      double x = baseX + driftX + pointerX + parallaxX;
      double y = baseY + driftY + pointerY + parallaxY;

      x = (x % bounds.width + bounds.width) % bounds.width;
      y = (y % bounds.height + bounds.height) % bounds.height;

      final double twinklePhase =
          (twinkleValue + (i * 0.23) + layer * 0.08) % 1.0;
      final double luminance =
          (0.3 + sin(twinklePhase * pi) * 0.45).clamp(0.18, 0.85);
      final double radius = 0.9 + layer * 0.7 + (i % 2) * 0.3;

      final Color starColor = _colorForIndex(i).withOpacity(luminance);
      starPaint.color = starColor;
      canvas.drawCircle(Offset(x, y), radius, starPaint);

      if (layer == 2) {
        final Paint glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              starColor.withOpacity(luminance * 0.55),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius * 3));
        canvas.drawCircle(Offset(x, y), radius * 3, glowPaint);
      }
    }
  }

  Color _colorForIndex(int index) {
    switch (index % 5) {
      case 0:
        return StarboundColors.stellarAqua;
      case 1:
        return StarboundColors.cosmicWhite;
      case 2:
        return StarboundColors.nebulaPurple;
      case 3:
        return StarboundColors.starlightBlue;
      default:
        return StarboundColors.stellarYellow;
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicParallaxPainter oldDelegate) {
    return oldDelegate.twinkleValue != twinkleValue ||
        oldDelegate.driftValue != driftValue ||
        oldDelegate.pointerOffset != pointerOffset ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.gradient != gradient;
  }
}
