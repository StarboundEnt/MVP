import 'dart:ui';

import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';

/// Shared glassmorphism wrapper for cohesive surfaces across the app.
class CosmicGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final double blurSigma;
  final Gradient? gradient;
  final Color? tintColor;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final Clip clipBehavior;

  const CosmicGlassPanel({
    Key? key,
    required this.child,
    this.padding = StarboundSpacing.card,
    this.margin,
    BorderRadiusGeometry? borderRadius,
    this.blurSigma = 16,
    this.gradient,
    this.tintColor,
    this.borderColor,
    this.shadow,
    this.clipBehavior = Clip.antiAlias,
  })  : borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(24)),
        super(key: key);

  /// Neutral glass surface
  factory CosmicGlassPanel.surface({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = StarboundSpacing.card,
    EdgeInsetsGeometry? margin,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(24)),
    double blurSigma = 16,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return CosmicGlassPanel(
      key: key,
      child: child,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      tintColor: StarboundColors.surfaceOverlay.withValues(alpha: 0.75),
      borderColor: StarboundColors.cosmicWhite.withValues(alpha: 0.15),
      shadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 18,
          offset: const Offset(0, 12),
          spreadRadius: -6,
        ),
      ],
      clipBehavior: clipBehavior,
    );
  }

  /// Cool informational glass surface
  factory CosmicGlassPanel.info({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = StarboundSpacing.card,
    EdgeInsetsGeometry? margin,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(24)),
    double blurSigma = 18,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    final Color base = StarboundColors.starlightBlue;
    return CosmicGlassPanel(
      key: key,
      child: child,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      tintColor: base.withValues(alpha: 0.18),
      borderColor: base.withValues(alpha: 0.4),
      shadow: [
        BoxShadow(
          color: base.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
      clipBehavior: clipBehavior,
    );
  }

  /// Success glass surface with aqua glow
  factory CosmicGlassPanel.success({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = StarboundSpacing.card,
    EdgeInsetsGeometry? margin,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(24)),
    double blurSigma = 18,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    final Color base = StarboundColors.stellarAqua;
    return CosmicGlassPanel(
      key: key,
      child: child,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      tintColor: base.withValues(alpha: 0.18),
      borderColor: base.withValues(alpha: 0.45),
      shadow: [
        BoxShadow(
          color: base.withValues(alpha: 0.28),
          blurRadius: 26,
          offset: const Offset(0, 16),
        ),
      ],
      clipBehavior: clipBehavior,
    );
  }

  /// Warning/alert glass surface with warm gradient
  factory CosmicGlassPanel.alert({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry padding = StarboundSpacing.card,
    EdgeInsetsGeometry? margin,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(24)),
    double blurSigma = 20,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    final Color warm = StarboundColors.solarOrange;
    final Color hot = StarboundColors.cosmicPink;
    return CosmicGlassPanel(
      key: key,
      child: child,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          warm.withValues(alpha: 0.28),
          hot.withValues(alpha: 0.24),
        ],
      ),
      borderColor: warm.withValues(alpha: 0.5),
      shadow: [
        BoxShadow(
          color: warm.withValues(alpha: 0.35),
          blurRadius: 28,
          offset: const Offset(0, 18),
        ),
      ],
      clipBehavior: clipBehavior,
    );
  }

  @override
  Widget build(BuildContext context) {
    final panel = ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: gradient,
            color: gradient == null
                ? (tintColor ?? StarboundColors.surfaceOverlay.withValues(alpha: 0.75))
                : null,
            border: Border.all(
              color: borderColor ?? StarboundColors.cosmicWhite.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: shadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                    spreadRadius: -8,
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      return Container(
        margin: margin,
        child: panel,
      );
    }

    return panel;
  }
}
