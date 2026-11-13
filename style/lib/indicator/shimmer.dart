import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Sweeps a soft highlight across [child]. Place [SkeletonBox]es inside to
/// draw the placeholder shapes. With reduced motion the boxes stay static.
class AppShimmer extends StatefulWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final base = cs.containerNormalOnSurface;
    final highlight = cs.surface;
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            if (!_controller.isAnimating) return child!;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [base, highlight, base],
                stops: const [0.25, 0.5, 0.75],
                transform: _SlideGradient(_controller.value),
              ).createShader(bounds),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double percent;

  const _SlideGradient(this.percent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
}

/// A placeholder block drawn in the skeleton colour.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  }) : circle = false;

  const SkeletonBox.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = 0,
        circle = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colorScheme.containerNormalOnSurface,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Rows with an optional round avatar and two text lines, for people/team
/// lists.
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final bool avatar;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;

  const SkeletonList({
    super.key,
    this.itemCount = 8,
    this.avatar = true,
    this.padding = const EdgeInsets.all(16),
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: shrinkWrap,
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) => Row(
          children: [
            if (avatar) ...[
              const SkeletonBox.circle(size: 44),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: index.isEven ? 0.6 : 0.45,
                    child: const SkeletonBox(height: 14),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: index.isEven ? 0.35 : 0.5,
                    child: const SkeletonBox(height: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stacked rounded cards, for match/tournament/auction lists.
class SkeletonCards extends StatelessWidget {
  final int itemCount;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;

  const SkeletonCards({
    super.key,
    this.itemCount = 5,
    this.height = 132,
    this.padding = const EdgeInsets.all(16),
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: shrinkWrap,
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => SkeletonBox(height: height, radius: 16),
      ),
    );
  }
}

/// A header block followed by rows, for profile and detail pages.
class SkeletonDetail extends StatelessWidget {
  final double headerHeight;

  const SkeletonDetail({super.key, this.headerHeight = 160});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          SkeletonBox(height: headerHeight, radius: 20),
          const SizedBox(height: 20),
          Row(
            children: List.generate(
              3,
              (index) => const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: SkeletonBox(height: 64, radius: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < 4; i++) ...[
            const SkeletonBox(height: 72, radius: 14),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
