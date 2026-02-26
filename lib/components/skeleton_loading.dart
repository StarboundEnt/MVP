import 'package:flutter/material.dart';

class SkeletonLoading extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  
  const SkeletonLoading({
    Key? key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Colors.white.withValues(alpha: _animation.value * 0.15),
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double height;
  final Widget? child;
  final bool showContent;
  
  const SkeletonCard({
    Key? key,
    required this.height,
    this.child,
    this.showContent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: showContent && child != null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoading(width: 120, height: 16),
                const SizedBox(height: 12),
                const SkeletonLoading(width: double.infinity, height: 12),
                const SizedBox(height: 8),
                const SkeletonLoading(width: 200, height: 12),
                const Spacer(),
                Row(
                  children: [
                    const SkeletonLoading(width: 60, height: 24, borderRadius: 12),
                    const SizedBox(width: 12),
                    const SkeletonLoading(width: 80, height: 24, borderRadius: 12),
                    const Spacer(),
                    SkeletonLoading(
                      width: 32,
                      height: 32,
                      borderRadius: 16,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class SkeletonChart extends StatelessWidget {
  final double height;
  final bool showContent;
  final Widget? child;
  
  const SkeletonChart({
    Key? key,
    this.height = 200,
    this.showContent = false,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: showContent && child != null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoading(width: 150, height: 18),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final heights = [40.0, 60.0, 30.0, 80.0, 50.0, 70.0, 45.0];
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SkeletonLoading(
                            height: heights[index],
                            borderRadius: 4,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    return const SkeletonLoading(width: 20, height: 12);
                  }),
                ),
              ],
            ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final bool showContent;
  final Widget? child;
  
  const SkeletonList({
    Key? key,
    this.itemCount = 3,
    this.itemHeight = 80,
    this.showContent = false,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (showContent && child != null) {
      return child!;
    }
    
    return Column(
      children: List.generate(itemCount, (index) {
        return Container(
          height: itemHeight,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              SkeletonLoading(
                width: 48,
                height: 48,
                borderRadius: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonLoading(
                      width: double.infinity * 0.7,
                      height: 16,
                    ),
                    const SizedBox(height: 8),
                    const SkeletonLoading(
                      width: 120,
                      height: 12,
                    ),
                  ],
                ),
              ),
              const SkeletonLoading(width: 24, height: 24, borderRadius: 12),
            ],
          ),
        );
      }),
    );
  }
}

class SkeletonHeader extends StatelessWidget {
  final bool showContent;
  final Widget? child;
  
  const SkeletonHeader({
    Key? key,
    this.showContent = false,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (showContent && child != null) {
      return child!;
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoading(width: 180, height: 24),
                const SizedBox(height: 8),
                const SkeletonLoading(width: 120, height: 16),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const SkeletonLoading(width: 80, height: 32, borderRadius: 16),
        ],
      ),
    );
  }
}