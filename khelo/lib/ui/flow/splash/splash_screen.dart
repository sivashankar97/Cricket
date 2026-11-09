import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _red = Color(0xFFFB131A);
const _navy = Color(0xFF010127);

/// Animated Sports Tamil splash: a navy dot draws a ring, shoots up as a
/// stroke, sweeps the screen navy, red bars spin into the four rings, then
/// the words and swoosh reveal.
///
/// Starts on plain red, so the native launch screen and the web loading
/// screen (`web/index.html`) are plain red too for a seamless handoff.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const animationDuration = Duration(milliseconds: 5800);

  /// The finished logo stays up this long before the app opens.
  static const _hold = Duration(milliseconds: 600);

  static bool get _reduceMotion => WidgetsBinding
      .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  /// How long `main` should keep the splash up so the animation can finish.
  static Duration get minVisibleDuration =>
      _reduceMotion ? Duration.zero : animationDuration + _hold;

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
  _SplashImages? _images;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final images = await _SplashImages.load();
    if (!mounted) return;
    setState(() => _images = images);
    if (SplashScreen._reduceMotion) {
      _controller.value = 1;
    } else {
      await _controller.forward();
    }
    // Only shows if the app is still loading after the logo has held.
    await Future.delayed(
        SplashScreen._hold + const Duration(milliseconds: 600));
    if (mounted) _dots.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    if (images == null) return const ColoredBox(color: _red);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _dots]),
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _SplashPainter(
                _controller.value *
                    SplashScreen.animationDuration.inMilliseconds /
                    1000,
                images,
              ),
            ),
            if (_dots.isAnimating)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.sizeOf(context).height * 0.12,
                child: _LoadingDots(value: _dots.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _SplashImages {
  const _SplashImages(this.rings, this.text, this.swoosh);

  final List<ui.Image> rings;
  final ui.Image text;
  final ui.Image swoosh;

  static Future<ui.Image> _image(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  static Future<_SplashImages> load() async {
    final (rings, text, swoosh) = await (
      Future.wait(
          [for (var i = 0; i < 4; i++) _image('assets/splash/ring$i.png')]),
      _image('assets/splash/text.png'),
      _image('assets/splash/swoosh.png'),
    ).wait;
    return _SplashImages(rings, text, swoosh);
  }
}

/// Paints frame [t] (seconds). Positions are in the 1659×948 source artwork.
class _SplashPainter extends CustomPainter {
  _SplashPainter(this.t, this.images);

  final double t;
  final _SplashImages images;

  static const _markX = 788.0, _markY = 295.0, _centerY = 479.0;
  static const _ringRects = [
    Rect.fromLTWH(695, 83, 219, 224),
    Rect.fromLTWH(747, 229, 178, 182),
    Rect.fromLTWH(565, 292, 209, 214),
    Rect.fromLTWH(799, 292, 212, 214),
  ];
  static const _textRect = Rect.fromLTWH(490, 520, 630, 270);
  static const _swooshRect = Rect.fromLTWH(540, 790, 520, 85);

  /// Last text strip lands at 4.5 + .5 + .25 (max random delay) + .25.
  static const _textDone = 5.5;

  static double _clamp(double x) => x.clamp(0.0, 1.0);
  static double _seg(double t, double a, double b) => _clamp((t - a) / (b - a));
  static double _lerp(double a, double b, double k) => a + (b - a) * k;
  static double _easeOut(double k) => 1 - math.pow(1 - k, 3).toDouble();
  static double _easeInOut(double k) =>
      k < .5 ? 4 * k * k * k : 1 - math.pow(-2 * k + 2, 3) / 2;
  static double _easeBack(double k) {
    const c = 1.9;
    return 1 + (c + 1) * math.pow(k - 1, 3) + c * math.pow(k - 1, 2);
  }

  static double _random(int i) {
    final x = math.sin(i * 127.1 + 311.7) * 43758.5453;
    return x - x.floorToDouble();
  }

  static Paint _fill(Color color) => Paint()
    ..color = color
    ..isAntiAlias = true;
  static final Paint _imagePaint = Paint()..filterQuality = FilterQuality.high;

  void _barPair(Canvas c, double x, double y, double angle, double length,
      double width, double gap, Color color) {
    c.save();
    c.translate(x, y);
    c.rotate(angle);
    final paint = _fill(color);
    c.drawRect(
        Rect.fromLTWH(-gap / 2 - width, -length / 2, width, length), paint);
    c.drawRect(Rect.fromLTWH(gap / 2, -length / 2, width, length), paint);
    c.restore();
  }

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, _fill(t >= 2.35 ? _navy : _red));

    // The logo is about 600 art px wide and 792 tall; keep it inside the
    // screen on phones, tablets and wide desktops.
    final logoWidth = math.min(
      420.0,
      math.min(size.width * 0.8, size.height * 0.55),
    );
    final s = logoWidth / 600;
    c.save();
    c.translate(size.width / 2, size.height / 2);
    c.scale(s);
    c.translate(-805, -_centerY);
    final top = _centerY - size.height / 2 / s;
    final bottom = _centerY + size.height / 2 / s;
    final stageWidth = size.width / s;

    if (t < 2.35) {
      _paintIntro(c, top, bottom, stageWidth);
    } else if (t < 4.4) {
      _paintBars(c, bottom);
    }
    if (t >= 4.0) _paintRings(c);
    if (t >= 4.5) _paintText(c);
    if (t >= 5.0) _paintSwoosh(c);
    c.restore();
  }

  /// Dot → ring → rising stroke → navy sweep.
  void _paintIntro(Canvas c, double top, double bottom, double stageWidth) {
    final drop = _easeBack(_seg(t, 0, .3)), ring = _seg(t, .3, .95);
    if (t < 1.0) {
      c.drawCircle(
        const Offset(_markX, _centerY),
        math.max(16 * drop * (1 - _easeOut(_seg(t, .4, .8))), 0),
        _fill(_navy),
      );
    }
    if (t >= .3 && t < 1.55) {
      final grow = _easeOut(ring), shrink = _easeInOut(_seg(t, .95, 1.55));
      final radius = _lerp(_lerp(0, 70, grow), 14, shrink);
      final y = _lerp(_centerY, _centerY - 300, shrink);
      c.drawArc(
        Rect.fromCircle(
            center: Offset(_markX, y), radius: math.max(radius, .1)),
        -1.2 + grow * 3.2,
        math.pi * 2 * grow,
        false,
        Paint()
          ..color = _navy
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = _lerp(18, 10, shrink)
          ..isAntiAlias = true,
      );
    }
    if (t >= .95) {
      final rise = _easeInOut(_seg(t, .95, 1.55));
      final straighten = _easeInOut(_seg(t, 1.55, 1.95));
      final tip =
          _lerp(_lerp(_centerY, _centerY - 300, rise), top + 40, straighten);
      final startX = _lerp(_markX + 110, _markX, straighten);
      final controlX = _lerp(_markX + 130, _markX, straighten);
      final baseWidth = _lerp(80 * rise, 14, straighten);
      final tipWidth = _lerp(10, 3, straighten);
      final startY = bottom + 20, controlY = _lerp(startY, tip, .5);
      final left = <Offset>[], right = <Offset>[];
      for (var i = 0; i <= 40; i++) {
        final q = i / 40, u = 1 - q;
        final x = u * u * startX + 2 * u * q * controlX + q * q * _markX;
        final y = u * u * startY + 2 * u * q * controlY + q * q * tip;
        final w = _lerp(baseWidth, tipWidth, q) / 2;
        left.add(Offset(x - w, y));
        right.add(Offset(x + w, y));
      }
      c.drawPath(
        Path()..addPolygon([...left, ...right.reversed], true),
        _fill(_navy),
      );
    }
    if (t >= 1.95) {
      final k = _easeInOut(_seg(t, 1.95, 2.35));
      final w = _lerp(14, stageWidth * 1.1, k * k);
      c.drawRect(
        Rect.fromLTWH(_markX - w / 2, top - 10, w, bottom - top + 20),
        _fill(_navy),
      );
    }
  }

  /// Red bar pair rises, splits into seven and spins into the logo centre.
  void _paintBars(Canvas c, double bottom) {
    final base = bottom + 20;
    const barTop = 229.0;
    final length0 = base - barTop, distance0 = (barTop + base) / 2 - _markY;
    final rise = _easeOut(_seg(t, 2.35, 2.85));
    final spread = _easeInOut(_seg(t, 2.85, 3.45));
    final gather = _easeInOut(_seg(t, 3.45, 4.05));
    final fade = 1 - _seg(t, 4.05, 4.4);
    if (t < 2.85) {
      final l = length0 * rise;
      _barPair(c, _markX, base - l / 2, 0, l, 34, 30, _red);
      return;
    }
    const count = 7;
    for (var i = 0; i < count; i++) {
      final angle = math.pi / 2 +
          i * (math.pi * 2 / count) * spread +
          spread * 1.4 +
          gather * 1.6;
      final d = _lerp(_lerp(distance0, 330, spread), 40, gather);
      final l = _lerp(_lerp(length0, 200, spread), 26, gather);
      final w = _lerp(34, 5, spread * .4 + gather * .6);
      _barPair(
        c,
        _markX + math.cos(angle) * d,
        _markY + math.sin(angle) * d,
        angle + math.pi / 2,
        l,
        w,
        _lerp(30, 7, gather),
        _red.withValues(alpha: fade),
      );
    }
  }

  void _paintRings(Canvas c) {
    for (var i = 0; i < images.rings.length; i++) {
      final k = _seg(t, 4.0 + i * .09, 4.6 + i * .09);
      if (k <= 0) continue;
      final rect = _ringRects[i], image = images.rings[i];
      final move = _easeOut(k);
      c.save();
      c.translate(_lerp(_markX, rect.center.dx, move),
          _lerp(_markY, rect.center.dy, move));
      c.rotate((1 - move) * (i.isOdd ? 2.4 : -2.4));
      c.scale(math.max(_easeBack(k), 0.0));
      c.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCenter(
            center: Offset.zero, width: rect.width, height: rect.height),
        _imagePaint,
      );
      c.restore();
    }
  }

  /// The words drop in as thin vertical strips.
  void _paintText(Canvas c) {
    if (t >= _textDone) {
      // One piece once every strip has landed, so no seams show on the hold.
      c.drawImageRect(
        images.text,
        Rect.fromLTWH(0, 0, _textRect.width, _textRect.height),
        _textRect,
        _imagePaint,
      );
      return;
    }
    const strip = 18.0;
    final count = (_textRect.width / strip).ceil();
    for (var i = 0; i < count; i++) {
      final start = 4.5 + i / count * .5 + _random(i) * .25;
      final k = _easeOut(_seg(t, start, start + .25));
      if (k <= 0) continue;
      final h = _textRect.height * k;
      final y0 = (_textRect.height - h) * _random(i + 9) * .8;
      final x = i * strip, w = math.min(strip, _textRect.width - x);
      c.drawImageRect(
        images.text,
        Rect.fromLTWH(x, y0, w, h),
        Rect.fromLTWH(
            _textRect.left + x + (1 - k) * 24, _textRect.top + y0, w + .75, h),
        _imagePaint,
      );
    }
  }

  void _paintSwoosh(Canvas c) {
    final k = _easeOut(_seg(t, 5.0, 5.6));
    final w = _swooshRect.width * k;
    c.drawImageRect(
      images.swoosh,
      Rect.fromLTWH(0, 0, w, _swooshRect.height),
      Rect.fromLTWH(_swooshRect.left, _swooshRect.top, w, _swooshRect.height),
      _imagePaint,
    );
  }

  @override
  bool shouldRepaint(_SplashPainter oldDelegate) => oldDelegate.t != t;
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
      opacity: (0.3 + 0.7 * pulse) * .85,
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
