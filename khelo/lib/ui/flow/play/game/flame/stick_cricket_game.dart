import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../../../../domain/play/ball_flight.dart';
import '../../../../../domain/play/cricket_game.dart';

/// Stick Cricket (Stick Sports) style arena — matched to
/// sticksports.com Stick Cricket Premier League / Stick Arena.
///
/// Night stadium, thin stick batsman, behind-batter camera.
/// Shot directions: Left / Up / Right / Duck (Down).
class StickCricketGame extends FlameGame with HasKeyboardHandlerComponents {
  StickCricketGame({
    required Innings innings,
    required this.batterName,
    required this.onBall,
    this.haptics = true,
  }) : _innings = innings;

  Innings _innings;
  final String batterName;
  final void Function(ShotResult result, int? offsetMs) onBall;
  final bool haptics;

  late final ArenaScene scene;

  Innings get innings => _innings;

  void syncInnings(Innings next) {
    _innings = next;
    scene.innings = next;
  }

  @override
  Color backgroundColor() => const Color(0xFF0A1020);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    scene = ArenaScene(
      innings: _innings,
      batterName: batterName,
      onBall: onBall,
      haptics: haptics,
    );
    world.add(scene);
  }

  void setPaused(bool paused) {
    if (paused) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

  /// [dir]: -1 left (pull), 0 straight (drive), 1 right (cut), null = duck/leave.
  void playShot(double? dir) => scene.playShot(dir);
}

enum _Phase { ready, runUp, bowling, shot }

class ArenaScene extends PositionComponent
    with DragCallbacks, KeyboardHandler, HasGameReference<StickCricketGame> {
  ArenaScene({
    required this.innings,
    required this.batterName,
    required this.onBall,
    required this.haptics,
  });

  Innings innings;
  final String batterName;
  final void Function(ShotResult result, int? offsetMs) onBall;
  final bool haptics;

  _Phase _phase = _Phase.ready;
  Delivery? _delivery;
  ShotResult? _shot;
  bool _swung = false;
  double _aimLine = 0;
  bool _ducked = false;

  final BallFlight _flight = BallFlight();
  double _runUp = 0;
  double _swing = 0;
  double _after = 0;
  double _between = 0;
  final List<Offset> _trail = [];

  static const runUpSec = 0.65;
  static const swingSec = 0.28;
  static const afterSec = 0.85;
  static const betweenSec = 1.35;

  int get _totalMs => (_delivery?.travelMs ?? 1200) + GameRules.lateWindowMs;
  int get sixes => innings.sixes;
  int get streak {
    var s = 0;
    for (final r in innings.results.reversed) {
      if (r == ShotResult.six || r == ShotResult.four) {
        s++;
      } else {
        break;
      }
    }
    return s;
  }

  void playShot(double? dir) {
    if (_phase == _Phase.ready) {
      final d = innings.nextDelivery;
      if (d != null) _startDelivery(d);
      return;
    }
    if (_phase != _Phase.bowling || _swung) return;
    if (dir == null) {
      // Duck / leave — same as not swinging.
      _ducked = true;
      _swung = true;
      _resolve(null);
      return;
    }
    _aimLine = dir;
    _swingAt(dir);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      playShot(-0.75);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      playShot(0.75);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW) {
      playShot(0);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      playShot(null);
      return true;
    }
    if (key == LogicalKeyboardKey.space) {
      if (game.paused) {
        game.resumeEngine();
      } else {
        game.pauseEngine();
      }
      return true;
    }
    return false;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (_phase) {
      case _Phase.ready:
        break;
      case _Phase.runUp:
        _runUp = min(1, _runUp + dt / runUpSec);
        if (_runUp >= 1) {
          _phase = _Phase.bowling;
          _flight.reset();
        }
      case _Phase.bowling:
        _flight.advance(dt);
        if (_flight.elapsedMs() >= _totalMs && !_swung) {
          _resolve(null);
        }
      case _Phase.shot:
        if (_swing < 1) _swing = min(1, _swing + dt / swingSec);
        if (_after < 1) {
          _after = min(1, _after + dt / afterSec);
          _updateTrail();
        }
        _between += dt;
        if (_between >= betweenSec) {
          _between = 0;
          _trail.clear();
          final next = innings.nextDelivery;
          if (next == null) {
            _phase = _Phase.ready;
            _delivery = null;
          } else {
            _startDelivery(next);
          }
        }
    }
  }

  void _startDelivery(Delivery delivery) {
    _phase = _Phase.runUp;
    _delivery = delivery;
    _shot = null;
    _swung = false;
    _ducked = false;
    _aimLine = 0;
    _runUp = 0;
    _swing = 0;
    _after = 0;
    _between = 0;
    _trail.clear();
    _flight.reset();
  }

  void _swingAt(double swingLine) {
    if (_swung || _phase != _Phase.bowling) return;
    _swung = true;
    _swing = 0;
    final elapsed = _flight.elapsedMs();
    _resolve(elapsed - _delivery!.travelMs, swingLine: swingLine);
  }

  void _resolve(int? offsetMs, {double? swingLine}) {
    final delivery = _delivery;
    if (delivery == null) return;
    final result =
        judgeShot(delivery, tapOffsetMs: offsetMs, swingLine: swingLine);
    if (haptics && (result != ShotResult.dot || offsetMs != null)) {
      HapticFeedback.mediumImpact();
    }
    _shot = result;
    _phase = _Phase.shot;
    _after = 0;
    _between = 0;
    _trail.clear();
    onBall(result, offsetMs);
  }

  double get ballProgress {
    final d = _delivery;
    if (d == null || _phase == _Phase.runUp) return 0;
    return _flight.progress(d.travelMs);
  }

  void _updateTrail() {
    if (_shot == null ||
        _shot == ShotResult.dot ||
        _shot == ShotResult.out ||
        _delivery == null) {
      return;
    }
    final w = size.x;
    final h = size.y;
    final topY = h * 0.22;
    final batY = h * 0.70;
    final topHalf = w * 0.05;
    final bottomHalf = w * 0.18;
    double halfAt(double y) =>
        lerpDouble(topHalf, bottomHalf, ((y - topY) / (batY - topY)).clamp(0, 1))!;
    final contact =
        _groundAt(1, w / 2, topY, batY, halfAt).translate(0, -_airAt(1, h));
    final dir = _aimLine != 0 ? _aimLine.sign : 1.0;
    final a = Curves.easeOut.transform(_after);
    final target = switch (_shot!) {
      ShotResult.six => Offset(w / 2 + dir * w * 0.45, h * 0.1),
      ShotResult.four => Offset(w / 2 + dir * w * 0.5, h * 0.28),
      _ => Offset(w / 2 + dir * w * 0.25, h * 0.45),
    };
    final pos = Offset.lerp(contact, target, a)!;
    if (_trail.isEmpty || (pos - _trail.last).distance > 5) {
      _trail.add(pos);
      if (_trail.length > 30) _trail.removeAt(0);
    }
  }

  Offset _groundAt(
    double p,
    double cx,
    double topY,
    double batY,
    double Function(double) halfAt,
  ) {
    final d = _delivery!;
    final y = topY + (batY - topY) * pow(p.clamp(0.0, 1.2), 1.05);
    final x = cx + d.line * halfAt(y) * 0.85 * min(p, 1.0);
    return Offset(x, y);
  }

  double _airAt(double p, double h) => p < 0.65
      ? (1 - pow(p / 0.65, 2)) * h * 0.04
      : sin(pi * min((p - 0.65) / 0.55, 1)) * h * 0.028;

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    // Tap pitch to start / straight drive.
    if (_phase == _Phase.ready) {
      playShot(0);
    } else if (_phase == _Phase.bowling) {
      playShot(0);
    }
  }

  // ── Stick Arena render (matched to Stick Sports PL) ─────────────────────

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;

    _drawNightSky(canvas, w, h);
    _drawStands(canvas, w, h);
    _drawFloodlights(canvas, w, h);
    _drawOutfield(canvas, w, h);
    _drawWelcomeBoards(canvas, w, h);

    final topY = h * 0.22;
    final batY = h * 0.70;
    final bottomY = h * 0.88;
    final topHalf = w * 0.05;
    final bottomHalf = w * 0.18;
    double halfAt(double y) {
      final t = ((y - topY) / (bottomY - topY)).clamp(0.0, 1.0);
      return lerpDouble(topHalf, bottomHalf, t)!;
    }

    // Pitch
    final pitch = Path()
      ..moveTo(cx - topHalf, topY)
      ..lineTo(cx + topHalf, topY)
      ..lineTo(cx + bottomHalf, bottomY)
      ..lineTo(cx - bottomHalf, bottomY)
      ..close();
    canvas.drawPath(pitch, Paint()..color = const Color(0xFFC9A87C));

    final crease = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..strokeWidth = 2;
    for (final y in [topY + h * 0.03, batY]) {
      canvas.drawLine(
        Offset(cx - halfAt(y) * 1.2, y),
        Offset(cx + halfAt(y) * 1.2, y),
        crease,
      );
    }

    // Far stumps + bowler
    _drawStumps(canvas, Offset(cx, topY + 4), h * 0.025, thin: true);
    final bowlerY = topY - 10 + Curves.easeIn.transform(_runUp) * 22;
    _drawStickBowler(
      canvas,
      Offset(cx + (_delivery?.line ?? 0) * 6, bowlerY),
      h * 0.055,
    );

    // Near stumps
    _drawStumps(canvas, Offset(cx, batY + h * 0.015), h * 0.09);

    // Stick batsman (thin limbs — Stick Sports style)
    final swingDir = _aimLine != 0 ? _aimLine.sign : 1.0;
    final batAngle = _ducked ? 0.0 : (_swing * pi / 1.7) * swingDir;
    _drawStickBatter(
      canvas,
      Offset(cx + w * 0.01, batY + h * 0.06),
      h * 0.19,
      batAngle,
      ducked: _ducked,
    );

    if (_delivery != null && _phase != _Phase.ready && _runUp >= 1) {
      _drawBall(canvas, Size(w, h), topY, batY, halfAt);
    }

    if (_trail.length >= 2) {
      final path = Path()..moveTo(_trail.first.dx, _trail.first.dy);
      for (var i = 1; i < _trail.length; i++) {
        path.lineTo(_trail[i].dx, _trail[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xEEFFFFFF)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    _drawMidHud(canvas, w, h);

    if (_shot != null && _phase == _Phase.shot) {
      final label = switch (_shot!) {
        ShotResult.six => 'SIX!',
        ShotResult.four => 'FOUR!',
        ShotResult.two => 'TWO',
        ShotResult.single => 'ONE',
        ShotResult.dot => _ducked ? 'DUCK' : 'DOT',
        ShotResult.out => 'OUT!',
      };
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: _shot == ShotResult.out
                ? const Color(0xFFFF1744)
                : const Color(0xFFFFEB3B),
            fontSize: min(w, h) * 0.09,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((w - tp.width) / 2, h * 0.36));
    }

    if (_phase == _Phase.ready && innings.balls == 0) {
      final tip = TextPainter(
        text: const TextSpan(
          text: '←  ↑  →  to bat   ↓ duck',
          style: TextStyle(
            color: Color(0xEEFFFFFF),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tip.paint(canvas, Offset((w - tip.width) / 2, h * 0.48));
    }
  }

  void _drawNightSky(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Offset.zero & Size(w, h * 0.28),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A080C), Color(0xFF2A1018), Color(0xFF152028)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & Size(w, h * 0.28)),
    );
    // Moon (top-center, Stick Arena)
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.045),
      9,
      Paint()..color = const Color(0xFFF5F5F5),
    );
  }

  void _drawStands(Canvas canvas, double w, double h) {
    final top = h * 0.10;
    final band = h * 0.12;
    // Grey grandstand curve
    canvas.drawRect(
      Rect.fromLTWH(0, top, w, band),
      Paint()..color = const Color(0xFF37474F),
    );
    // Speckled crowd
    const colors = [
      Color(0xFFE53935),
      Color(0xFF1E88E5),
      Color(0xFFFFEB3B),
      Color(0xFF8E24AA),
      Color(0xFFFF9800),
      Color(0xFF212121),
      Color(0xFFFFFFFF),
      Color(0xFF43A047),
    ];
    final cols = max(30, (w / 7).round());
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < cols; c++) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(
              (c + 0.5) / cols * w,
              top + (r + 0.4) / 8 * band,
            ),
            width: 3.5,
            height: 4.5,
          ),
          Paint()..color = colors[(c * 3 + r * 5) % colors.length],
        );
      }
    }
  }

  void _drawFloodlights(Canvas canvas, double w, double h) {
    final pole = Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 3;
    for (final fx in [0.12, 0.35, 0.65, 0.88]) {
      final x = w * fx;
      canvas.drawLine(Offset(x, h * 0.12), Offset(x, h * 0.02), pole);
      // Lens flare glow
      canvas.drawCircle(
        Offset(x, h * 0.025),
        14,
        Paint()
          ..color = const Color(0x66FFF59D)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(x, h * 0.025),
        5,
        Paint()..color = const Color(0xFFFFFDE7),
      );
    }
  }

  void _drawOutfield(Canvas canvas, double w, double h) {
    final top = h * 0.22;
    canvas.drawRect(
      Rect.fromLTWH(0, top, w, h - top),
      Paint()..color = const Color(0xFF2E7D32),
    );
    // Subtle stripes
    for (var i = 0; i < 8; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, top + i * (h - top) / 8, w, (h - top) / 16),
        Paint()..color = const Color(0x22200000),
      );
    }
  }

  void _drawWelcomeBoards(Canvas canvas, double w, double h) {
    final y = h * 0.195;
    for (final side in [-1.0, 1.0]) {
      final rect = Rect.fromCenter(
        center: Offset(w * 0.5 + side * w * 0.28, y),
        width: w * 0.22,
        height: h * 0.035,
      );
      canvas.drawRect(rect, Paint()..color = const Color(0xFF111111));
      final tp = TextPainter(
        text: TextSpan(
          text: side < 0 ? 'WELCOME TO' : 'STICK ARENA',
          style: TextStyle(
            color: side < 0 ? Colors.white : const Color(0xFFE53935),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width);
      tp.paint(
        canvas,
        Offset(rect.left + (rect.width - tp.width) / 2,
            rect.top + (rect.height - tp.height) / 2),
      );
    }
  }

  void _drawMidHud(Canvas canvas, double w, double h) {
    final box = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.30),
      width: max(160.0, w * 0.30),
      height: h * 0.055,
    );
    // Three status lights above the board (Stick Sports)
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(box.left + box.width * (0.28 + i * 0.22), box.top - 8),
        4,
        Paint()..color = const Color(0xFF66BB6A),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(2)),
      Paint()..color = const Color(0xF0000000),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'SIXES = $sixes   STREAK = $streak',
        style: const TextStyle(
          color: Color(0xFFFFEB3B),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(box.left + (box.width - tp.width) / 2,
          box.top + (box.height - tp.height) / 2),
    );

    // Pause hint + Stick Sports watermark
    final hint = TextPainter(
      text: const TextSpan(
        text: "hit 'SPACE' to pause game",
        style: TextStyle(
          color: Color(0x88FFFFFF),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hint.paint(canvas, Offset((w - hint.width) / 2, h * 0.90));

    final brand = TextPainter(
      text: const TextSpan(
        text: 'STICK SPORTS',
        style: TextStyle(
          color: Color(0x55FFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    brand.paint(canvas, Offset(w - brand.width - 12, h * 0.86));
  }

  void _drawStumps(Canvas canvas, Offset base, double height, {bool thin = false}) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = thin ? 2 : 3.5
      ..strokeCap = StrokeCap.round;
    final gap = thin ? 3.0 : 6.5;
    for (final dx in [-gap, 0.0, gap]) {
      canvas.drawLine(base.translate(dx, 0), base.translate(dx, -height), paint);
    }
    if (!thin) {
      canvas.drawLine(
        base.translate(-gap, -height),
        base.translate(gap, -height),
        Paint()
          ..color = const Color(0xFFE53935)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawStickBowler(Canvas canvas, Offset feet, double height) {
    final stroke = Paint()
      ..color = const Color(0xFF212121)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final head = feet.translate(0, -height);
    canvas.drawCircle(head, height * 0.1, Paint()..color = const Color(0xFFFFCC80));
    canvas.drawLine(head.translate(0, height * 0.1), feet.translate(0, -height * 0.35), stroke);
    canvas.drawLine(
        feet.translate(0, -height * 0.5), feet.translate(height * 0.25, -height * 0.75), stroke);
    canvas.drawLine(
        feet.translate(0, -height * 0.35), feet.translate(-height * 0.1, 0), stroke);
    canvas.drawLine(
        feet.translate(0, -height * 0.35), feet.translate(height * 0.1, 0), stroke);
  }

  /// Classic Stick Sports stickman: thin limbs, grey top, black pants, white pads.
  void _drawStickBatter(
    Canvas canvas,
    Offset feet,
    double height,
    double batAngle, {
    required bool ducked,
  }) {
    const limb = Color(0xFF1A1A1A);
    const kit = Color(0xFFB0BEC5);
    const pants = Color(0xFF212121);
    const skin = Color(0xFFFFCC80);
    const pad = Color(0xFFF5F5F5);

    // Sharp shadow (Stick Arena style)
    canvas.drawOval(
      Rect.fromCenter(
        center: feet.translate(0, 3),
        width: height * 0.32,
        height: height * 0.05,
      ),
      Paint()..color = const Color(0x88000000),
    );

    final headY = ducked ? -height * 0.55 : -height * 0.90;
    final head = feet.translate(ducked ? height * 0.08 : 0, headY);
    final hip = feet.translate(0, -height * 0.40);
    final shoulder = feet.translate(0, ducked ? -height * 0.42 : -height * 0.68);

    canvas.drawCircle(head, height * 0.09, Paint()..color = skin);
    // Hair
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: height * 0.095),
      pi,
      pi,
      true,
      Paint()..color = limb,
    );

    // Torso (grey kit)
    canvas.drawLine(
      shoulder,
      hip,
      Paint()
        ..color = kit
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );

    // Arms + yellow/red Stick Sports bat
    final hands = shoulder.translate(
      sin(batAngle) * height * 0.22,
      height * 0.12,
    );
    canvas.drawLine(
      shoulder,
      hands,
      Paint()
        ..color = limb
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(hands, height * 0.035, Paint()..color = pad);

    final tip = Offset(
      hands.dx + sin(batAngle) * height * 0.55,
      hands.dy - cos(batAngle) * height * 0.5,
    );
    final mid = Offset.lerp(hands, tip, 0.35)!;
    canvas.drawLine(
      hands,
      mid,
      Paint()
        ..color = const Color(0xFFE53935)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      mid,
      tip,
      Paint()
        ..color = const Color(0xFFFFEB3B)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Black pants + white pads
    canvas.drawLine(
      hip,
      feet.translate(-height * 0.1, 0),
      Paint()
        ..color = pants
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      hip,
      feet.translate(height * 0.1, 0),
      Paint()
        ..color = pants
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    for (final s in [-1.0, 1.0]) {
      canvas.drawLine(
        feet.translate(s * height * 0.1, -height * 0.22),
        feet.translate(s * height * 0.1, -height * 0.02),
        Paint()
          ..color = pad
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawBall(
    Canvas canvas,
    Size size,
    double topY,
    double batY,
    double Function(double) halfAt,
  ) {
    final cx = size.width / 2;
    final t = ballProgress.clamp(0.0, 1.25);
    final hit =
        _shot != null && _shot != ShotResult.dot && _shot != ShotResult.out;

    Offset ballPos;
    double radius;
    if (hit) {
      final contact =
          _groundAt(1, cx, topY, batY, halfAt).translate(0, -_airAt(1, size.height));
      final dir = _aimLine != 0 ? _aimLine.sign : 1.0;
      final a = Curves.easeOut.transform(_after);
      final target = switch (_shot!) {
        ShotResult.six => Offset(cx + dir * size.width * 0.45, size.height * 0.1),
        ShotResult.four =>
          Offset(cx + dir * size.width * 0.5, size.height * 0.28),
        _ => Offset(cx + dir * size.width * 0.25, size.height * 0.45),
      };
      ballPos = Offset.lerp(contact, target, a)!;
      radius = lerpDouble(7, 4, a)!;
    } else {
      final ground = _groundAt(t, cx, topY, batY, halfAt);
      ballPos = ground.translate(0, -_airAt(t, size.height));
      radius = lerpDouble(2.2, 8.5, min(t, 1.1))!;
      canvas.drawOval(
        Rect.fromCenter(
            center: ground, width: radius * 2.2, height: radius * 0.65),
        Paint()..color = const Color(0x66000000),
      );
    }
    canvas.drawCircle(ballPos, radius, Paint()..color = const Color(0xFF111111));
  }
}
