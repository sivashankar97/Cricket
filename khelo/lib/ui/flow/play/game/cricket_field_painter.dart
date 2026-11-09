import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:style/theme/colors.dart';

import '../../../../domain/play/cricket_game.dart';

/// Stick-figure pitch seen from behind the bowler's arm: bowler at the top,
/// batter and stumps at the bottom, the ball travelling down the strip.
class CricketFieldPainter extends CustomPainter {
  final Delivery? delivery;

  /// 0 at release, 1 when the ball reaches the bat (can run past 1 when late).
  final double ballProgress;

  /// Bat swing 0..1.
  final double swing;

  /// Ball flight / stumps scatter after the shot, 0..1.
  final double after;
  final ShotResult? shot;

  CricketFieldPainter({
    required this.delivery,
    required this.ballProgress,
    required this.swing,
    required this.after,
    required this.shot,
  });

  static const _grassLight = Color(0xFF2FA35A);
  static const _grassDark = Color(0xFF27914E);
  static const _pitch = Color(0xFFD9B77E);
  static const _crease = Color(0xFFFFFFFF);
  static const _stump = Color(0xFFF5E6C8);
  static const _ballColor = Color(0xFFE53950);
  static const _figure = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    _drawGrass(canvas, size);

    final topY = h * 0.10;
    final bottomY = h * 0.96;
    final topHalf = w * 0.07;
    final bottomHalf = w * 0.24;
    double halfAt(double y) =>
        lerpDouble(topHalf, bottomHalf, (y - topY) / (bottomY - topY))!;

    final pitch = Path()
      ..moveTo(cx - topHalf, topY)
      ..lineTo(cx + topHalf, topY)
      ..lineTo(cx + bottomHalf, bottomY)
      ..lineTo(cx - bottomHalf, bottomY)
      ..close();
    canvas.drawPath(pitch, Paint()..color = _pitch);

    final creasePaint = Paint()
      ..color = _crease
      ..strokeWidth = 2;
    final bowlCreaseY = topY + h * 0.05;
    final batCreaseY = h * 0.80;
    canvas.drawLine(Offset(cx - halfAt(bowlCreaseY) * 1.3, bowlCreaseY),
        Offset(cx + halfAt(bowlCreaseY) * 1.3, bowlCreaseY), creasePaint);
    canvas.drawLine(Offset(cx - halfAt(batCreaseY) * 1.3, batCreaseY),
        Offset(cx + halfAt(batCreaseY) * 1.3, batCreaseY), creasePaint);

    // Bowler's stumps and bowler.
    _drawStumps(canvas, Offset(cx, topY + h * 0.04), h * 0.035, 3, 0);
    _drawStickFigure(canvas, Offset(cx + w * 0.03, topY - h * 0.005), h * 0.07,
        armUp: (ballProgress < 0.15 && delivery != null));

    // Batter's stumps.
    final stumpsBase = Offset(cx, h * 0.86);
    final scatter = shot == ShotResult.out && (delivery?.onStumps ?? false)
        ? Curves.easeOut.transform(after)
        : 0.0;
    _drawStumps(canvas, stumpsBase, h * 0.10, 6, scatter);

    // Batter (right-hander standing to the off side of the stumps).
    final batterFeet = Offset(cx - w * 0.09, h * 0.90);
    _drawBatter(canvas, batterFeet, h * 0.20);

    if (delivery != null) _drawBall(canvas, size, topY, batCreaseY, halfAt);
  }

  void _drawGrass(Canvas canvas, Size size) {
    const stripes = 10;
    final stripeH = size.height / stripes;
    for (var i = 0; i < stripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeH, size.width, stripeH + 1),
        Paint()..color = i.isEven ? _grassLight : _grassDark,
      );
    }
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, brandNavyColor.withValues(alpha: 0.3)],
        stops: const [0.7, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
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
    // Bails.
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

  Paint get _figurePaint => Paint()
    ..color = _figure
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  void _drawStickFigure(Canvas canvas, Offset feet, double height,
      {bool armUp = false}) {
    final paint = _figurePaint..strokeWidth = 2;
    final hip = feet.translate(0, -height * 0.45);
    final neck = feet.translate(0, -height * 0.8);
    canvas.drawCircle(neck.translate(0, -height * 0.1), height * 0.1,
        Paint()..color = _figure);
    canvas.drawLine(neck, hip, paint);
    canvas.drawLine(hip, feet.translate(-height * 0.15, 0), paint);
    canvas.drawLine(hip, feet.translate(height * 0.15, 0), paint);
    canvas.drawLine(neck, neck.translate(-height * 0.25, height * 0.2), paint);
    canvas.drawLine(
      neck,
      armUp
          ? neck.translate(height * 0.1, -height * 0.35)
          : neck.translate(height * 0.25, height * 0.2),
      paint,
    );
  }

  void _drawBatter(Canvas canvas, Offset feet, double height) {
    final paint = _figurePaint..strokeWidth = 4;
    final hip = feet.translate(0, -height * 0.45);
    final neck = feet.translate(height * 0.04, -height * 0.78);
    canvas.drawLine(hip, feet.translate(-height * 0.12, 0), paint);
    canvas.drawLine(hip, feet.translate(height * 0.14, 0), paint);
    canvas.drawLine(neck, hip, paint);
    // Helmet.
    canvas.drawCircle(neck.translate(0, -height * 0.1), height * 0.09,
        Paint()..color = brandNavyCardColor);
    canvas.drawCircle(neck.translate(height * 0.02, -height * 0.09),
        height * 0.06, Paint()..color = const Color(0xFFF2C9A0));

    // Bat swings from raised behind (-100°) through to follow-through (60°).
    final hands = neck.translate(height * 0.12, height * 0.22);
    canvas.drawLine(neck, hands, paint);
    final eased = Curves.easeOut.transform(swing);
    final angle = (-100 + eased * 160) * pi / 180;
    final batLength = height * 0.48;
    final batEnd =
        hands + Offset(cos(angle + pi / 2), sin(angle + pi / 2)) * batLength;
    canvas.drawLine(
      hands,
      batEnd,
      Paint()
        ..color = const Color(0xFFE8C887)
        ..strokeWidth = height * 0.06
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

    // Height above the ground: falls to a bounce at 70%, then rises a little.
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
          Offset(cx + dir * size.width * 0.55, -size.height * 0.1),
        ShotResult.four =>
          Offset(cx + dir * size.width * 0.7, size.height * 0.35),
        _ => Offset(cx + dir * size.width * 0.35, size.height * 0.6),
      };
      ballPos = Offset.lerp(contact, target, a)!;
      final lift =
          shot == ShotResult.six ? sin(pi * a) * size.height * 0.15 : 0.0;
      ballPos = ballPos.translate(0, -lift);
      radius =
          radiusAt(1) * (shot == ShotResult.six ? 1 + a * 0.8 : 1 - a * 0.3);
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
      old.swing != swing ||
      old.after != after ||
      old.shot != shot ||
      old.delivery != delivery;
}
