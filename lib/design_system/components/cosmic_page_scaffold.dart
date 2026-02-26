import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../spacing.dart';
import 'cosmic_parallax_field.dart';
import 'cosmic_capsule_header.dart';

/// Consistent page shell that applies Starbound theming, app bar, and safe areas.
class CosmicPageScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final String? subtitle;
  final IconData? titleIcon;
  final Widget? customHeader;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? floatingActionButton;
  final EdgeInsetsGeometry? contentPadding;
  final Gradient? backgroundGradient;
  final Color? backgroundColor;
  final Color? accentColor;
  final bool safeAreaBottom;
  final bool safeAreaTop;

  const CosmicPageScaffold({
    Key? key,
    required this.body,
    this.title,
    this.subtitle,
    this.titleIcon,
    this.customHeader,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.floatingActionButton,
    this.contentPadding,
    this.backgroundGradient,
    this.backgroundColor,
    this.accentColor,
    this.safeAreaBottom = false,
    this.safeAreaTop = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color baseColor = backgroundColor ?? StarboundColors.background;
    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: baseColor,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: floatingActionButton,
        body: Stack(
          children: [
            Positioned.fill(
              child: CosmicParallaxField(
                baseColor: baseColor,
                gradient: (backgroundGradient ?? StarboundColors.primaryGradient),
                enablePointerInteraction: false,
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                top: safeAreaTop,
                bottom: safeAreaBottom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (customHeader != null)
                      customHeader!
                    else
                      _buildHeader(),
                    Expanded(
                      child: Padding(
                        padding: contentPadding ?? StarboundSpacing.screenWide,
                        child: body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool showHeader =
        title != null || subtitle != null || titleIcon != null || onBack != null || (actions?.isNotEmpty ?? false);

    if (!showHeader) {
      return const SizedBox.shrink();
    }

    return CosmicCapsuleHeader(
      title: title ?? '',
      subtitle: subtitle,
      titleIcon: titleIcon,
      onBack: onBack,
      actions: actions,
      accentColor: accentColor,
    );
  }
}
