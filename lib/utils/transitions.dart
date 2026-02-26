import 'package:flutter/material.dart';

/// Custom page transitions for smooth navigation throughout the app
class AppTransitions {
  
  /// Slide transition from right to left (default iOS-style)
  static PageTransitionsTheme slideFromRight = const PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: SlidePageTransitionsBuilder(),
    },
  );
  
  /// Fade transition for overlay-style pages
  static PageTransitionsTheme fadeTransition = const PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: FadePageTransitionsBuilder(),
      TargetPlatform.android: FadePageTransitionsBuilder(),
    },
  );
  
  /// Scale transition with fade for dialog-style navigation
  static PageTransitionsTheme scaleTransition = const PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: ScalePageTransitionsBuilder(),
      TargetPlatform.android: ScalePageTransitionsBuilder(),
    },
  );
}

/// Custom slide transition builder
class SlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlidePageTransitionsBuilder();
  
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }
}

/// Custom fade transition builder
class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();
  
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: child,
    );
  }
}

/// Custom scale transition builder
class ScalePageTransitionsBuilder extends PageTransitionsBuilder {
  const ScalePageTransitionsBuilder();
  
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

/// Custom page route with enhanced transitions
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final TransitionType transitionType;
  final Duration duration;
  final Curve curve;
  
  SmoothPageRoute({
    required this.page,
    this.transitionType = TransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    RouteSettings? settings,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    settings: settings,
  );
  
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );
    
    switch (transitionType) {
      case TransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
        
      case TransitionType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
        
      case TransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
        
      case TransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
        
      case TransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
        
      case TransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.1,
            end: 0.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
    }
  }
}

enum TransitionType {
  slide,
  fade,
  scale,
  slideUp,
  slideDown,
  rotation,
}

/// Hero transition wrapper for seamless element transitions
class HeroWrapper extends StatelessWidget {
  final String tag;
  final Widget child;
  final Duration duration;
  
  const HeroWrapper({
    Key? key,
    required this.tag,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: flightDirection == HeroFlightDirection.push ? 1.0 : 1.1,
              end: flightDirection == HeroFlightDirection.push ? 1.1 : 1.0,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animated list item for smooth list transitions
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  
  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);
  
  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    // Stagger animation based on index
    Future.delayed(
      Duration(milliseconds: widget.index * widget.delay.inMilliseconds),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Smooth container with interactive animations
class InteractiveContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double scaleOnPress;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  
  const InteractiveContainer({
    Key? key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
    this.scaleOnPress = 0.95,
    this.decoration,
    this.padding,
    this.margin,
  }) : super(key: key);
  
  @override
  State<InteractiveContainer> createState() => _InteractiveContainerState();
}

class _InteractiveContainerState extends State<InteractiveContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnPress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: widget.decoration,
              padding: widget.padding,
              margin: widget.margin,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Navigation helper with smooth transitions
class SmoothNavigator {
  /// Navigate with slide transition
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    TransitionType transition = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Navigator.of(context).push<T>(
      SmoothPageRoute<T>(
        page: page,
        transitionType: transition,
        duration: duration,
        curve: curve,
      ),
    );
  }
  
  /// Navigate and replace current page
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    TO? result,
    TransitionType transition = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      SmoothPageRoute<T>(
        page: page,
        transitionType: transition,
        duration: duration,
        curve: curve,
      ),
      result: result,
    );
  }
  
  /// Navigate and clear all previous routes
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate, {
    TransitionType transition = TransitionType.slide,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      SmoothPageRoute<T>(
        page: page,
        transitionType: transition,
        duration: duration,
        curve: curve,
      ),
      predicate,
    );
  }
}