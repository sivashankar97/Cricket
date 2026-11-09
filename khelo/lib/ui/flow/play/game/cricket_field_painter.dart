import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:style/theme/colors.dart';

import '../../../../domain/play/cricket_game.dart';

/// Night stadium seen from behind the bowler's arm: floodlights and crowd at
/// the top, the bowler running in, batter and stumps at the bottom, the ball
/// travelling down the strip.
class CricketFieldPainter extends CustomPainter {
  final Delivery? delivery;

  /// 0 at release, 1 when the ball reaches the bat (can run past 1 when late).
  final double ballProgress;

  /// Bowler's run-up 0..1 (1 = ball released).
  final double runUp;

  /// Bat swing 0..1.
  final double swing;

  /// Ball flight / stumps scatter after the shot, 0..1.
  final double after;
  final ShotResult? shot;

  /// Crowd celebration 0..1 (boundaries and wins): camera flashes, waving.
  final double celebrate;

  CricketFieldPainter({
    required this.delivery,
    required this.ballProgress,
    required this.swing,
    required this.after,
    required this.shot,
    this.runUp = 1,
    this.celebrate = 0,
  });

  static const _skyTop = Color(0xFF060B1F);
  static const _skyBottom = Color(0xFF16234D);
  static const _grassLight = Color(0xFF2FA35A);
  static const _grassDark = Color(0xFF268E4C);
  static const _pitch = Color(0xFFD9B77E);
  static const _pitchWorn = Color(0xFFC9A26A);
  static const _crease = Color(0xFFFFFFFF);
  static const _stump = Color(0xFFF5E6C8);
  static const _ballColor = Color(0xFFE53950);
  static const _skin = Color(0xFFE9B98F);
  static const _pads = Color(0xFFF4F4F4);
  static const _bat = Color(0xFFE8C887);
  static const _fielderShirt = Color(0xFF1E3A8A);

  static final List<({double x, double y, int color, double r})> _crowd = () {
    final random = Random(3);
    const palette = 6;
    return List.generate(320, (i) {
      final row = i % 8;
      return (
        x: random.nextDouble(),
        y: row / 8 + random.nextDouble() * 0.08,
        color: random.nextInt(palette),
        r: 0.8 + random.nextDouble() * 0.9,
      );
    });
  }();

  static const _crowdColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFB131A),
    Color(0xFFFFC93C),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFF472B6),
  ];

  /// Width of the playing strip, batter and bowler. On wide screens the
  /// stadium spreads across the full width but these keep phone proportions.
  static double coreWidth(Size size) => min(size.width, size.height * 0.85);

  @override
  void paint(Canvas canvas, Size size) {
    final w = coreWidth(size);
    final h = size.height;
    final cx = size.width / 2;

    final standsTop = h * 0.05;
    final standsBottom = h * 0.20;
    final boardsBottom = h * 0.225;

    _drawSky(canvas, size, standsBottom);
    _drawCrowd(canvas, size, standsTop, standsBottom);
    _drawFloodlights(canvas, size, standsBottom);
    _drawBoards(canvas, size, standsBottom, boardsBottom);
    _drawOutfield(canvas, size, boardsBottom);
    _drawFielders(canvas, size);

    final topY = h * 0.30;
    final bottomY = h * 0.985;
    final topHalf = w * 0.065;
    final bottomHalf = w * 0.23;
    double halfAt(double y) =>
        lerpDouble(topHalf, bottomHalf, (y - topY) / (bottomY - topY))!;

    final pitch = Path()
      ..moveTo(cx - topHalf, topY)
      ..lineTo(cx + topHalf, topY)
      ..lineTo(cx + bottomHalf, bottomY)
      ..lineTo(cx - bottomHalf, bottomY)
      ..close();
    canvas.drawPath(pitch, Paint()..color = _pitch);
    final worn = Path()
      ..moveTo(cx - halfAt(h * 0.68) * 0.5, h * 0.68)
      ..lineTo(cx + halfAt(h * 0.68) * 0.5, h * 0.68)
      ..lineTo(cx + halfAt(h * 0.80) * 0.55, h * 0.80)
      ..lineTo(cx - halfAt(h * 0.80) * 0.55, h * 0.80)
      ..close();
    canvas.drawPath(worn, Paint()..color = _pitchWorn.withValues(alpha: 0.6));

    final creasePaint = Paint()
      ..color = _crease
      ..strokeWidth = 2;
    final bowlCreaseY = topY + h * 0.045;
    final batCreaseY = h * 0.80;
    for (final y in [bowlCreaseY, batCreaseY]) {
      canvas.drawLine(Offset(cx - halfAt(y) * 1.3, y),
          Offset(cx + halfAt(y) * 1.3, y), creasePaint);
    }

    _drawStumps(canvas, Offset(cx, topY + h * 0.035), h * 0.032, 3, 0);
    _drawBowler(canvas, size, topY);

    final stumpsBase = Offset(cx, h * 0.86);
    final scatter = shot == ShotResult.out && (delivery?.onStumps ?? false)
        ? Curves.easeOut.transform(after)
        : 0.0;
    _drawStumps(canvas, stumpsBase, h * 0.10, 6, scatter);

    _drawBatter(canvas, Offset(cx - w * 0.10, h * 0.915), h * 0.24);

    if (delivery != null && runUp >= 1) {
      _drawBall(canvas, size, topY, batCreaseY, halfAt);
    }
  }

  // ── Stadium ──────────────────────────────────────────────────────────────

  void _drawSky(Canvas canvas, Size size, double bottom) {
    final rect = Rect.fromLTWH(0, 0, size.width, bottom + 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyBottom],
        ).createShader(rect),
    );
  }

  void _drawCrowd(Canvas canvas, Size size, double top, double bottom) {
    final height = bottom - top;
    final tiers = Paint()..color = const Color(0xFF0E1736);
    canvas.drawRect(Rect.fromLTWH(0, top, size.width, height), tiers);
    final wave = celebrate > 0 ? sin(celebrate * pi * 6) : 0.0;
    for (var i = 0; i < _crowd.length; i++) {
      final fan = _crowd[i];
      final curve = sin(fan.x * pi) * height * 0.08;
      final jump = celebrate > 0 && i.isEven ? wave * 2.5 : 0.0;
      final center = Offset(
        fan.x * size.width,
        top + fan.y * height * 0.92 + curve - jump,
      );
      canvas.drawCircle(
        center,
        fan.r * coreWidth(size) / 360,
        Paint()
          ..color = _crowdColors[fan.color]
              .withValues(alpha: 0.75 + 0.25 * celebrate),
      );
      if (celebrate > 0 && (i * 7 + (celebrate * 20).floor()) % 23 == 0) {
        canvas.drawCircle(
          center,
          fan.r * 3.2,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.85 * (1 - celebrate))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
    final roof = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, top, size.width, height * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, top, size.width, height * 0.5), roof);
  }

  void _drawFloodlights(Canvas canvas, Size size, double groundY) {
    for (final fx in [0.07, 0.93]) {
      final x = size.width * fx;
      final top = size.height * 0.015;
      canvas.drawLine(
        Offset(x, groundY),
        Offset(x, top + 10),
        Paint()
          ..color = const Color(0xFF2A3560)
          ..strokeWidth = 3,
      );
      final panel = Rect.fromCenter(
          center: Offset(x, top + 6),
          width: coreWidth(size) * 0.09,
          height: 12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(panel, const Radius.circular(2)),
        Paint()..color = const Color(0xFFFFF7D6),
      );
      canvas.drawCircle(
        panel.center,
        coreWidth(size) * 0.16,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF3C4).withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(
              center: panel.center, radius: coreWidth(size) * 0.16)),
      );
    }
  }

  void _drawBoards(Canvas canvas, Size size, double top, double bottom) {
    final height = bottom - top;
    final segments = max(6, (size.width / (coreWidth(size) / 6)).round());
    final segment = size.width / segments;
    for (var i = 0; i < segments; i++) {
      final rect = Rect.fromLTWH(i * segment, top, segment + 1, height);
      canvas.drawRect(
        rect,
        Paint()..color = i.isEven ? brandRedColor : brandNavyColor,
      );
      final label = TextPainter(
        text: TextSpan(
          text: i.isEven ? 'SPORTS TAMIL' : '#KHELO',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: height * 0.48,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: segment - 4);
      label.paint(
        canvas,
        Offset(rect.left + (segment - label.width) / 2,
            top + (height - label.height) / 2),
      );
    }
  }

  void _drawOutfield(Canvas canvas, Size size, double top) {
    final field = Rect.fromLTWH(0, top, size.width, size.height - top);
    const stripes = 9;
    final stripeH = field.height / stripes;
    for (var i = 0; i < stripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, top + i * stripeH, size.width, stripeH + 1),
        Paint()..color = i.isEven ? _grassLight : _grassDark,
      );
    }
    final rope = Rect.fromCenter(
      center: Offset(size.width / 2, top + field.height * 0.62),
      width: max(size.width * 1.1, coreWidth(size) * 1.5),
      height: field.height * 1.32,
    );
    canvas.drawOval(
      rope,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      field,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.2),
          radius: 0.9,
          colors: [Colors.transparent, brandNavyColor.withValues(alpha: 0.35)],
          stops: const [0.65, 1],
        ).createShader(field),
    );
  }

  void _drawFielders(Canvas canvas, Size size) {
    const spots = [
      Offset(0.14, 0.40),
      Offset(0.86, 0.38),
      Offset(0.08, 0.66),
      Offset(0.92, 0.62),
      Offset(0.30, 0.30),
      Offset(0.72, 0.29),
    ];
    final spread = min(size.width, coreWidth(size) * 2.2);
    final left = (size.width - spread) / 2;
    for (final spot in spots) {
      final feet = Offset(left + spot.dx * spread, spot.dy * size.height);
      final height = size.height * (0.035 + spot.dy * 0.03);
      _drawFigure(canvas, feet, height, shirt: _fielderShirt);
    }
  }

  // ── Players ──────────────────────────────────────────────────────────────

  void _drawFigure(
    Canvas canvas,
    Offset feet,
    double height, {
    required Color shirt,
    double armAngle = 0.35,
    double stride = 0.12,
  }) {
    final limb = Paint()
      ..color = Colors.white
      ..strokeWidth = max(1.5, height * 0.09)
      ..strokeCap = StrokeCap.round;
    final hip = feet.translate(0, -height * 0.45);
    final neck = feet.translate(0, -height * 0.82);
    canvas.drawLine(hip, feet.translate(-height * stride, 0), limb);
    canvas.drawLine(hip, feet.translate(height * stride, 0), limb);
    canvas.drawLine(
      neck,
      hip,
      Paint()
        ..color = shirt
        ..strokeWidth = max(2.5, height * 0.2)
        ..strokeCap = StrokeCap.round,
    );
    final arm = Paint()
      ..color = shirt
      ..strokeWidth = max(1.5, height * 0.08)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(neck.translate(0, height * 0.04),
        neck.translate(-height * 0.22, height * 0.25), arm);
    canvas.drawLine(
      neck.translate(0, height * 0.04),
      neck.translate(sin(armAngle) * height * 0.32,
          -cos(armAngle) * height * 0.32 + height * 0.04),
      arm,
    );
    canvas.drawCircle(
        neck.translate(0, -height * 0.1), height * 0.1, Paint()..color = _skin);
  }

  void _drawBowler(Canvas canvas, Size size, double topY) {
    final r = Curves.easeIn.transform(runUp.clamp(0.0, 1.0));
    final w = coreWidth(size);
    final start = Offset(size.width / 2 + w * 0.06, topY - size.height * 0.035);
    final crease =
        Offset(size.width / 2 + w * 0.03, topY + size.height * 0.012);
    final feet = Offset.lerp(start, crease, r)!;
    final height = size.height * lerpDouble(0.065, 0.09, r)!;
    final strideWave = runUp < 1 ? sin(runUp * pi * 8) * 0.18 : 0.1;
    final released = runUp >= 1 && delivery != null;
    final armAngle = released
        ? lerpDouble(-0.2, 2.6, min(1.0, ballProgress * 4))!
        : lerpDouble(0.4, -0.3, r)!;
    _drawFigure(canvas, feet, height,
        shirt: _fielderShirt,
        armAngle: armAngle,
        stride: 0.06 + strideWave.abs());
  }

  void _drawStumps(
    Canvas canvas,
    Offset base,
    double height,
    double gap,
    double scatter,
  ) {
    final paint = Paint()
      ..color = _stump
      ..strokeWidth = max(2, height * 0.06)
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      final angle = scatter * (0.5 + i * 0.35);
      final x = base.dx + i * gap * 1.6;
      final top = Offset(
        x + sin(angle) * height,
        base.dy - cos(angle) * height,
      );
      canvas.drawLine(Offset(x, base.dy), top, paint);
    }
    final bailY = base.dy - height - scatter * height * 0.8;
    final bailPaint = Paint()
      ..color = _stump
      ..strokeWidth = max(1.5, height * 0.04)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(base.dx - gap * 1.6 - scatter * 12, bailY),
      Offset(base.dx - scatter * 6, bailY - scatter * 8),
      bailPaint,
    );
    canvas.drawLine(
      Offset(base.dx + scatter * 6, bailY - scatter * 10),
      Offset(base.dx + gap * 1.6 + scatter * 14, bailY),
      bailPaint,
    );
  }

  void _drawBatter(Canvas canvas, Offset feet, double height) {
    final hip = feet.translate(0, -height * 0.45);
    final neck = feet.translate(height * 0.04, -height * 0.78);

    canvas.drawOval(
      Rect.fromCenter(
          center: feet.translate(0, 2),
          width: height * 0.5,
          height: height * 0.07),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    final pad = Paint()
      ..color = _pads
      ..strokeWidth = height * 0.085
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hip, feet.translate(-height * 0.12, 0), pad);
    canvas.drawLine(hip, feet.translate(height * 0.14, 0), pad);

    canvas.drawLine(
      neck,
      hip,
      Paint()
        ..color = brandNavyCardColor
        ..strokeWidth = height * 0.17
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      neck.translate(-height * 0.05, height * 0.06),
      hip.translate(-height * 0.05, 0),
      Paint()
        ..color = brandRedColor
        ..strokeWidth = height * 0.025,
    );

    canvas.drawCircle(neck.translate(height * 0.02, -height * 0.09),
        height * 0.065, Paint()..color = _skin);
    final helmet = Rect.fromCircle(
        center: neck.translate(0, -height * 0.1), radius: height * 0.095);
    canvas.drawArc(
        helmet, pi, pi * 1.05, true, Paint()..color = brandNavyColor);
    canvas.drawLine(
      neck.translate(height * 0.06, -height * 0.11),
      neck.translate(height * 0.08, -height * 0.05),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5,
    );

    // Bat swings from raised behind (-100°) through to follow-through (60°).
    final hands = neck.translate(height * 0.12, height * 0.22);
    canvas.drawLine(
      neck.translate(0, height * 0.05),
      hands,
      Paint()
        ..color = brandNavyCardColor
        ..strokeWidth = height * 0.06
        ..strokeCap = StrokeCap.round,
    );
    final eased = Curves.easeOut.transform(swing);
    final angle = (-100 + eased * 160) * pi / 180;
    final batLength = height * 0.5;
    final direction = Offset(cos(angle + pi / 2), sin(angle + pi / 2));
    final handle = hands + direction * batLength * 0.22;
    final batEnd = hands + direction * batLength;
    canvas.drawLine(
      hands,
      handle,
      Paint()
        ..color = const Color(0xFF3B2A1A)
        ..strokeWidth = height * 0.03
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      handle,
      batEnd,
      Paint()
        ..color = _bat
        ..strokeWidth = height * 0.07
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawBall(
    Canvas canvas,
    Size size,
    double topY,
    double batY,
    double Function(double) halfAt,
  ) {
    final d = delivery!;
    final cx = size.width / 2;
    final t = ballProgress.clamp(0.0, 1.25);

    Offset groundAt(double p) {
      final y = topY + (batY - topY) * pow(p, 1.1);
      final x = cx + d.line * halfAt(y) * 0.9 * min(p, 1.0);
      return Offset(x, y);
    }

    double radiusAt(double p) => lerpDouble(3, 10, min(p, 1.15))!;

    double airAt(double p) => p < 0.7
        ? (1 - pow(p / 0.7, 2)) * size.height * 0.05
        : sin(pi * min((p - 0.7) / 0.6, 1)) * size.height * 0.035;

    Offset ballPos;
    double radius;
    double opacity = 1;
    final hit =
        shot != null && shot != ShotResult.dot && shot != ShotResult.out;

    if (hit) {
      final contact = groundAt(1).translate(0, -airAt(1));
      final dir = d.line >= 0 ? 1.0 : -1.0;
      final a = Curves.easeOut.transform(after);
      final target = switch (shot!) {
        ShotResult.six =>
          Offset(cx + dir * coreWidth(size) * 0.55, -size.height * 0.1),
        ShotResult.four =>
          Offset(cx + dir * coreWidth(size) * 0.7, size.height * 0.35),
        _ => Offset(cx + dir * coreWidth(size) * 0.35, size.height * 0.6),
      };
      ballPos = Offset.lerp(contact, target, a)!;
      final lift =
          shot == ShotResult.six ? sin(pi * a) * size.height * 0.15 : 0.0;
      ballPos = ballPos.translate(0, -lift);
      radius =
          radiusAt(1) * (shot == ShotResult.six ? 1 + a * 0.8 : 1 - a * 0.3);
      final trail = Paint()
        ..color = Colors.white.withValues(alpha: 0.35 * (1 - a))
        ..strokeWidth = radius * 0.9
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(contact, ballPos, trail);
    } else {
      final ground = groundAt(t);
      ballPos = ground.translate(0, -airAt(t));
      radius = radiusAt(t);
      if (shot != null) opacity = (1 - after).clamp(0.0, 1.0);
      canvas.drawOval(
        Rect.fromCenter(
            center: ground, width: radius * 2.2, height: radius * 0.8),
        Paint()..color = Colors.black.withValues(alpha: 0.25 * opacity),
      );
    }

    canvas.drawCircle(
      ballPos,
      radius,
      Paint()..color = _ballColor.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      ballPos.translate(-radius * 0.3, -radius * 0.3),
      radius * 0.35,
      Paint()..color = Colors.white.withValues(alpha: 0.45 * opacity),
    );
  }

  @override
  bool shouldRepaint(CricketFieldPainter old) =>
      old.ballProgress != ballProgress ||
      old.runUp != runUp ||
      old.swing != swing ||
      old.after != after ||
      old.shot != shot ||
      old.celebrate != celebrate ||
      old.delivery != delivery;
}
