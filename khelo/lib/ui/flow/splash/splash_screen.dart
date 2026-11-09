import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khelo/gen/assets.gen.dart';

const _navy = Color(0xFF010127);
const _red = Color(0xFFF9151D);

const _easeOut = Cubic(.16, 1, .3, 1);
const _easeInOut = Cubic(.65, 0, .35, 1);

/// Logo layer SVGs share the viewBox "300 40 400 505"; positions below are in
/// those units so the layers line up with the source artwork.
const _boxLeft = 300.0;
const _boxTop = 40.0;
const _boxWidth = 400.0;
const _boxHeight = 505.0;

/// Mirrors the CSS splash in `web/index.html`; keep the timings in sync.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.animate = !kIsWeb});

  /// On web the HTML splash plays the animation while Flutter loads, so the
  /// Flutter splash only shows the final frame.
  final bool animate;

  static const animationDuration = Duration(milliseconds: 2800);

  static bool get _reduceMotion => WidgetsBinding
      .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  /// How long `main` should keep the splash up so the animation can finish.
  static Duration get minVisibleDuration =>
      kIsWeb || _reduceMotion ? Duration.zero : animationDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashScreen.animationDuration,
  );
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate && !SplashScreen._reduceMotion) {
      _controller.forward().whenComplete(() async {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) _dots.repeat();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _navy,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final logoWidth = math.min(
              280.0,
              math.min(size.width * 0.58, size.height * 0.40),
            );
            return AnimatedBuilder(
              animation: Listenable.merge([_controller, _dots]),
              builder: (context, _) {
                final t = _controller.value *
                    SplashScreen.animationDuration.inMilliseconds /
                    1000;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _GlowPainter(_seg(t, .1, 1.7))),
                    Center(child: _AnimatedLogo(t: t, width: logoWidth)),
                    if (_dots.isAnimating)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: size.height * 0.12,
                        child: _LoadingDots(value: _dots.value),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Progress of [t] (seconds) through the window [start]..[end], eased by [curve].
double _seg(double t, double start, double end, [Curve curve = Curves.linear]) {
  if (t <= start) return 0;
  if (t >= end) return 1;
  return curve.transform((t - start) / (end - start));
}

double _lerp(double a, double b, double p) => a + (b - a) * p;

Alignment _alignAt(double x, double y) => Alignment(
      (x - _boxLeft) / _boxWidth * 2 - 1,
      (y - _boxTop) / _boxHeight * 2 - 1,
    );

class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo({required this.t, required this.width});

  final double t;
  final double width;

  @override
  Widget build(BuildContext context) {
    final unit = width / _boxWidth;
    final height = _boxHeight * unit;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _mark(unit),
          _text(Assets.images.splashSports, unit, 1.3, from: 313, to: 700),
          _fadeIn(Assets.images.splashComma, 669, 393, _seg(t, 2.1, 2.6)),
          _text(Assets.images.splashTamil, unit, 1.5, from: 395, to: 655),
          _fadeIn(Assets.images.splashDot, 630, 460, _seg(t, 2.25, 2.75)),
          _swoosh(unit),
        ],
      ),
    );
  }

  Widget _layer(String asset) => SvgPicture.asset(asset, fit: BoxFit.fill);

  Widget _mark(double unit) {
    final appear = _seg(t, .15, .95, _easeOut);
    final move = _seg(t, 1.0, 1.7, _easeInOut);
    final scale = _lerp(.62, 1, move) * _lerp(.7, 1, appear);
    return Transform.translate(
      offset: Offset(-12 * unit, 111 * unit) * (1 - move),
      child: Opacity(
        opacity: appear,
        child: Transform.scale(
          scale: scale,
          alignment: _alignAt(512, 181),
          child: _layer(Assets.images.splashMark),
        ),
      ),
    );
  }

  /// A word that wipes in left to right while rising slightly.
  Widget _text(
    String asset,
    double unit,
    double start, {
    required double from,
    required double to,
  }) {
    final rise = _seg(t, start, start + .75, _easeOut);
    return Transform.translate(
      offset: Offset(0, 10 * unit * (1 - rise)),
      child: Opacity(
        opacity: rise,
        child: _Wipe(
          progress: _seg(t, start, start + .75, _easeInOut),
          from: from,
          to: to,
          child: _layer(asset),
        ),
      ),
    );
  }

  Widget _fadeIn(String asset, double cx, double cy, double progress) {
    if (progress == 0) return const SizedBox.shrink();
    final eased = _easeOut.transform(progress);
    return Opacity(
      opacity: eased,
      child: Transform.scale(
        scale: _lerp(.6, 1, eased),
        alignment: _alignAt(cx, cy),
        child: _layer(asset),
      ),
    );
  }

  Widget _swoosh(double unit) {
    final progress = _seg(t, 1.9, 2.55, _easeOut);
    return Transform.translate(
      offset: Offset(-16 * unit * (1 - progress), 0),
      child: _Wipe(
        progress: progress,
        from: 343,
        to: 629,
        child: _layer(Assets.images.splashSwoosh),
      ),
    );
  }
}

/// Reveals [child] left to right with a soft edge, between viewBox x [from]..[to].
class _Wipe extends StatelessWidget {
  const _Wipe({
    required this.progress,
    required this.from,
    required this.to,
    required this.child,
  });

  final double progress;
  final double from;
  final double to;
  final Widget child;

  static const _feather = 0.08;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();
    if (progress >= 1) return child;
    final start = (from - _boxLeft) / _boxWidth - _feather;
    final end = (to - _boxLeft) / _boxWidth;
    final edge = _lerp(start, end, progress).clamp(0.0, 1.0);
    final fade = (edge + _feather).clamp(edge, 1.0);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        colors: const [
          Colors.white,
          Colors.white,
          Colors.transparent,
          Colors.transparent,
        ],
        stops: [0, edge, fade, 1],
      ).createShader(rect),
      child: child,
    );
  }
}

/// Soft red light behind the logo.
class _GlowPainter extends CustomPainter {
  _GlowPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final eased = _easeOut.transform(progress);
    final diameter = math.min(
      760.0,
      math.min(size.width * 1.3, size.height * 1.1),
    );
    final radius = diameter / 2 * _lerp(.55, 1, eased);
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _red.withValues(alpha: .22 * eased),
            _red.withValues(alpha: .07 * eased),
            _red.withValues(alpha: 0),
          ],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _dot((value - i * 0.125) % 1),
        ],
      ],
    );
  }

  Widget _dot(double phase) {
    final pulse = (math.sin(phase * 2 * math.pi - math.pi / 2) + 1) / 2;
    return Opacity(
      opacity: _lerp(0.3, 1, pulse) * .85,
      child: const SizedBox.square(
        dimension: 7,
        child: DecoratedBox(
          decoration:
              BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
