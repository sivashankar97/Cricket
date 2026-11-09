import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:khelo/components/app_image_provider.dart';

import '../../../../domain/play/cricket_game.dart';
import 'cricket_field_painter.dart';
import 'play_sounds.dart';

enum _Phase { ready, runUp, bowling, shot }

/// The stadium, the bowler and the batter for one innings.
///
/// [interactive]: the player bats; every tap is judged and reported through
/// [onBall]. Otherwise the arena replays new balls of [innings] as they
/// arrive (a live opponent's), using the saved tap offsets.
class PlayArena extends ConsumerStatefulWidget {
  static const runUpDuration = Duration(milliseconds: 650);
  static const betweenBalls = Duration(milliseconds: 1500);

  final Innings innings;
  final String batterName;
  final bool interactive;

  /// Ignores taps (e.g. while a countdown or result is on top).
  final bool paused;
  final void Function(ShotResult result, int? offsetMs)? onBall;

  /// Watching: how many balls have been shown so far, after each replay.
  final ValueChanged<int>? onReplayed;

  const PlayArena({
    super.key,
    required this.innings,
    required this.batterName,
    this.interactive = true,
    this.paused = false,
    this.onBall,
    this.onReplayed,
  });

  @override
  ConsumerState<PlayArena> createState() => _PlayArenaState();
}

class _PlayArenaState extends ConsumerState<PlayArena>
    with TickerProviderStateMixin {
  late final AnimationController _runUp = AnimationController(
    vsync: this,
    duration: PlayArena.runUpDuration,
  )..addStatusListener(_onRunUpStatus);
  late final AnimationController _ball = AnimationController(vsync: this)
    ..addListener(_onBallTick)
    ..addStatusListener(_onBallStatus);
  late final AnimationController _swing = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));
  late final AnimationController _after = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _celebrate = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  _Phase _phase = _Phase.ready;
  Delivery? _delivery;
  int _ballIndex = 0;
  ShotResult? _shot;
  int? _offset;
  bool _swung = false;
  Timer? _next;

  /// Watching: balls of [PlayArena.innings] already replayed.
  late int _shownBalls;
  ShotResult? _replayResult;
  int? _replayOffset;

  PlaySounds get _sounds => ref.read(playSoundsProvider);

  int get _totalMs => (_delivery?.travelMs ?? 1200) + GameRules.lateWindowMs;

  @override
  void initState() {
    super.initState();
    _shownBalls = widget.innings.balls;
  }

  @override
  void didUpdateWidget(PlayArena old) {
    super.didUpdateWidget(old);
    if (widget.innings.seed != old.innings.seed ||
        widget.innings.balls < old.innings.balls) {
      _reset();
      _shownBalls = widget.innings.balls;
    }
    if (!widget.interactive && _phase == _Phase.ready) _replayNext();
  }

  @override
  void dispose() {
    _next?.cancel();
    _runUp.dispose();
    _ball.dispose();
    _swing.dispose();
    _after.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  void _reset() {
    _next?.cancel();
    _runUp.reset();
    _ball.reset();
    _swing.reset();
    _after.reset();
    _phase = _Phase.ready;
    _delivery = null;
    _shot = null;
    _offset = null;
  }

  // ── Bowling ──────────────────────────────────────────────────────────────

  void _startDelivery(Delivery delivery, int index) {
    setState(() {
      _phase = _Phase.runUp;
      _delivery = delivery;
      _ballIndex = index;
      _shot = null;
      _offset = null;
      _swung = false;
    });
    _swing.reset();
    _after.reset();
    _ball.reset();
    _runUp.forward(from: 0);
  }

  void _onRunUpStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _phase != _Phase.runUp) return;
    setState(() => _phase = _Phase.bowling);
    _ball.duration = Duration(milliseconds: _totalMs);
    _ball.forward(from: 0);
  }

  void _onBallTick() {
    if (widget.interactive || _phase != _Phase.bowling) return;
    final offset = _replayOffset;
    if (offset == null || _swung) return;
    final elapsed = _ball.value * _totalMs;
    if (elapsed >= _delivery!.travelMs + offset) {
      _swung = true;
      _swing.forward(from: 0);
      _showResult(_replayResult!, offset);
    }
  }

  void _onBallStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _phase != _Phase.bowling) return;
    if (widget.interactive) {
      _resolve(null);
    } else if (_replayResult != null) {
      _showResult(_replayResult!, null);
    }
  }

  // ── Batting ──────────────────────────────────────────────────────────────

  void _onTap() {
    if (!widget.interactive || widget.paused) return;
    switch (_phase) {
      case _Phase.ready:
        final delivery = widget.innings.nextDelivery;
        if (delivery != null) _startDelivery(delivery, widget.innings.balls);
      case _Phase.bowling:
        if (_swung) return;
        _swung = true;
        _swing.forward(from: 0);
        final elapsed = (_ball.value * _totalMs).round();
        _resolve(elapsed - _delivery!.travelMs);
      case _Phase.runUp:
      case _Phase.shot:
        break;
    }
  }

  void _resolve(int? offsetMs) {
    final delivery = _delivery;
    if (delivery == null) return;
    final result = judgeShot(delivery, tapOffsetMs: offsetMs);
    if (result != ShotResult.dot || offsetMs != null) {
      HapticFeedback.mediumImpact();
    }
    _showResult(result, offsetMs);
    widget.onBall?.call(result, offsetMs);
  }

  void _showResult(ShotResult result, int? offsetMs) {
    _ball.stop();
    setState(() {
      _phase = _Phase.shot;
      _shot = result;
      _offset = offsetMs;
    });
    _sounds.shot(result, swung: offsetMs != null);
    if (result == ShotResult.six || result == ShotResult.four) {
      _celebrate.forward(from: 0);
    }
    _after.forward(from: 0);
    _next?.cancel();
    _next = Timer(PlayArena.betweenBalls, _afterBall);
    if (!widget.interactive) widget.onReplayed?.call(_ballIndex + 1);
  }

  void _afterBall() {
    if (!mounted) return;
    if (widget.interactive) {
      final delivery = widget.innings.nextDelivery;
      if (delivery == null) return;
      _startDelivery(delivery, widget.innings.balls);
    } else {
      _shownBalls = _ballIndex + 1;
      setState(() => _phase = _Phase.ready);
      _replayNext();
    }
  }

  /// Watching: replays the next ball that arrived, if any.
  void _replayNext() {
    final innings = widget.innings;
    if (_phase != _Phase.ready || _shownBalls >= innings.balls) return;
    final index = _shownBalls;
    _replayResult = innings.results[index];
    _replayOffset =
        index < innings.offsets.length ? innings.offsets[index] : null;
    _startDelivery(innings.deliveries[index], index);
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  double get _ballProgress {
    final delivery = _delivery;
    if (delivery == null || _phase == _Phase.runUp) return 0;
    return _ball.value * _totalMs / delivery.travelMs;
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 600;
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _onTap(),
            child: ColoredBox(
              color: _skyColor,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Wide spaces get the whole stadium (the painter keeps the
                  // pitch in proportion); very tall ones leave sky above and
                  // below.
                  final width = constraints.maxWidth;
                  final height =
                      min(constraints.maxHeight, constraints.maxWidth * 1.9);
                  return Center(
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: _field(context, Size(width, height)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        _commentary(context, compact: compact),
        _hint(context, compact: compact),
      ],
    );
  }

  static const _skyColor = Color(0xFF060B1F);

  Widget _field(BuildContext context, Size size) {
    final showBall = _phase != _Phase.ready;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation:
                Listenable.merge([_runUp, _ball, _swing, _after, _celebrate]),
            builder: (context, _) => CustomPaint(
              painter: CricketFieldPainter(
                delivery: showBall ? _delivery : null,
                ballProgress: _ballProgress,
                runUp: _phase == _Phase.runUp ? _runUp.value : 1,
                swing: _swing.value,
                after: _after.value,
                shot: _shot,
                celebrate: _celebrate.isAnimating ? _celebrate.value : 0,
              ),
            ),
          ),
        ),
        if (_shot != null && _phase == _Phase.shot) _shotBanner(context, size),
      ],
    );
  }

  Widget _shotBanner(BuildContext context, Size field) {
    final scale = (field.width / 390).clamp(0.72, 1.2);
    final shot = _shot!;
    final (text, color) = switch (shot) {
      ShotResult.six => (context.l10n.play_shot_six, positiveGreenColor),
      ShotResult.four => (context.l10n.play_shot_four, positiveGreenColor),
      ShotResult.two => (context.l10n.play_shot_two, textPrimaryDarkColor),
      ShotResult.single => (
          context.l10n.play_shot_single,
          textPrimaryDarkColor
        ),
      ShotResult.dot => (context.l10n.play_shot_dot, textSecondaryDarkColor),
      ShotResult.out => (context.l10n.play_shot_out, brandRedColor),
    };
    final offset = _offset;
    final timing = offset == null
        ? context.l10n.play_timing_left
        : offset.abs() <= GameRules.perfectWindowMs
            ? context.l10n.play_timing_perfect
            : offset < 0
                ? context.l10n.play_timing_early
                : context.l10n.play_timing_late;
    return Positioned(
      top: field.height * 0.14,
      left: 8,
      right: 8,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_ballIndex),
        tween: Tween(begin: 0.4, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.elasticOut,
        builder: (context, pop, child) =>
            Transform.scale(scale: pop, child: child),
        child: Column(
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: AppTextStyle.header1.copyWith(
                color: color,
                fontSize: (shot == ShotResult.six ? 52 : 40) * scale,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 18,
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                timing,
                style: AppTextStyle.subtitle3.copyWith(
                  color: textPrimaryDarkColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _commentary(BuildContext context, {required bool compact}) {
    final height = compact ? 32.0 : 40.0;
    final shot = _shot;
    final line = shot == null || _phase != _Phase.shot
        ? null
        : commentaryLine(
            context.l10n,
            shot,
            commentaryVariant(widget.innings.seed, _ballIndex),
            widget.batterName,
          );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: line == null
          ? SizedBox(height: height, width: double.infinity)
          : Container(
              key: ValueKey('c$_ballIndex'),
              height: height,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.black.withValues(alpha: 0.35),
              child: Row(
                children: [
                  const Icon(Icons.mic_rounded,
                      size: 16, color: awarenessWarningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.caption.copyWith(
                        color: textPrimaryDarkColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _hint(BuildContext context, {required bool compact}) {
    final ready = _phase == _Phase.ready;
    final String text;
    if (!widget.interactive) {
      text = ready && !widget.innings.isOver
          ? context.l10n.play_live_waiting_ball
          : '';
    } else if (ready && widget.innings.balls == 0) {
      text = context.l10n.play_game_tap_to_start;
    } else {
      text = context.l10n.play_how_to;
    }
    final big = widget.interactive && ready && widget.innings.balls == 0;
    return Padding(
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 6, 16, 8)
          : const EdgeInsets.fromLTRB(24, 10, 24, 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: compact ? 1 : 2,
        overflow: TextOverflow.ellipsis,
        style: (big ? AppTextStyle.subtitle1 : AppTextStyle.caption).copyWith(
          color: big ? positiveGreenColor : textSecondaryDarkColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The commentary line for a ball; [variant] from [commentaryVariant].
String commentaryLine(
  AppLocalizations l10n,
  ShotResult result,
  int variant,
  String name,
) =>
    switch ((result, variant)) {
      (ShotResult.six, 0) => l10n.play_comm_six_0(name),
      (ShotResult.six, 1) => l10n.play_comm_six_1(name),
      (ShotResult.six, _) => l10n.play_comm_six_2(name),
      (ShotResult.four, 0) => l10n.play_comm_four_0(name),
      (ShotResult.four, 1) => l10n.play_comm_four_1(name),
      (ShotResult.four, _) => l10n.play_comm_four_2(name),
      (ShotResult.two, 0) => l10n.play_comm_two_0(name),
      (ShotResult.two, 1) => l10n.play_comm_two_1(name),
      (ShotResult.two, _) => l10n.play_comm_two_2(name),
      (ShotResult.single, 0) => l10n.play_comm_single_0(name),
      (ShotResult.single, 1) => l10n.play_comm_single_1(name),
      (ShotResult.single, _) => l10n.play_comm_single_2(name),
      (ShotResult.dot, 0) => l10n.play_comm_dot_0,
      (ShotResult.dot, 1) => l10n.play_comm_dot_1(name),
      (ShotResult.dot, _) => l10n.play_comm_dot_2,
      (ShotResult.out, 0) => l10n.play_comm_out_0,
      (ShotResult.out, 1) => l10n.play_comm_out_1(name),
      (ShotResult.out, _) => l10n.play_comm_out_2(name),
    };

/// Broadcast-style score panel: batter, score, overs, target and this over.
class ArenaScoreboard extends StatelessWidget {
  final Innings innings;
  final String batterName;
  final String? batterImage;
  final String label;

  const ArenaScoreboard({
    super.key,
    required this.innings,
    required this.batterName,
    required this.label,
    this.batterImage,
  });

  @override
  Widget build(BuildContext context) {
    final needed = innings.runsNeeded;
    final status = needed != null && !innings.isOver
        ? context.l10n.play_game_need(needed, innings.ballsLeft)
        : context.l10n.play_game_balls_left(innings.ballsLeft);
    final overStart = innings.balls == 0 ? 0 : ((innings.balls - 1) ~/ 6) * 6;
    final thisOver = innings.results.skip(overStart).take(6).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow phones: smaller text, and the target goes under the chips.
        final narrow = constraints.maxWidth < 360;
        final chip = narrow ? 17.0 : 20.0;
        final statusText = Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: narrow ? TextAlign.start : TextAlign.end,
          style: AppTextStyle.subtitle3.copyWith(
            color:
                needed != null ? awarenessWarningColor : textSecondaryDarkColor,
            fontWeight: FontWeight.w700,
          ),
        );
        final chips = [
          Text(
            context.l10n.play_this_over,
            style: AppTextStyle.caption
                .copyWith(color: textSecondaryDarkColor, fontSize: 11),
          ),
          const SizedBox(width: 6),
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: BallChip(
                result: i < thisOver.length ? thisOver[i] : null,
                size: chip,
              ),
            ),
        ];

        return Container(
          margin: EdgeInsets.fromLTRB(narrow ? 8 : 12, 4, narrow ? 8 : 12, 8),
          padding: EdgeInsets.fromLTRB(narrow ? 10 : 12, narrow ? 8 : 10,
              narrow ? 10 : 14, narrow ? 8 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                brandNavyCardColor.withValues(alpha: 0.95),
                const Color(0xFF101A3F).withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlayerBadge(
                    name: batterName,
                    image: batterImage,
                    size: narrow ? 32 : 38,
                  ),
                  SizedBox(width: narrow ? 8 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batterName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.subtitle2.copyWith(
                            color: textPrimaryDarkColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          label,
                          maxLines: narrow ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.caption
                              .copyWith(color: textSecondaryDarkColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${innings.runs}/${innings.wickets}',
                        style: AppTextStyle.header1.copyWith(
                          color: textPrimaryDarkColor,
                          fontSize: narrow ? 28 : 34,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        context.l10n.play_hud_overs(
                            oversText(innings.balls), innings.format.overs),
                        style: AppTextStyle.caption
                            .copyWith(color: textSecondaryDarkColor),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (narrow) ...[
                Row(children: chips),
                const SizedBox(height: 4),
                statusText,
              ] else
                Row(
                  children: [
                    ...chips,
                    const SizedBox(width: 4),
                    Expanded(child: statusText),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One ball as a small coloured circle: W, 6, 4, 2, 1 or •.
class BallChip extends StatelessWidget {
  final ShotResult? result;
  final double size;

  const BallChip({super.key, required this.result, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    final color = switch (result) {
      null => textPrimaryDarkColor.withValues(alpha: 0.10),
      ShotResult.out => brandRedColor,
      ShotResult.six || ShotResult.four => positiveGreenColor,
      ShotResult.dot => textPrimaryDarkColor.withValues(alpha: 0.22),
      _ => const Color(0xFF3B82F6),
    };
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: result == null
          ? null
          : Text(
              result.isOut
                  ? 'W'
                  : result == ShotResult.dot
                      ? '•'
                      : '${result.runs}',
              style: AppTextStyle.caption.copyWith(
                color: result == ShotResult.six || result == ShotResult.four
                    ? brandNavyColor
                    : textPrimaryDarkColor,
                fontSize: size * 0.48,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

/// Round photo, or the first letter on brand red when there is no photo.
class PlayerBadge extends StatelessWidget {
  final String name;
  final String? image;
  final double size;
  final Color ring;

  const PlayerBadge({
    super.key,
    required this.name,
    this.image,
    this.size = 40,
    this.ring = Colors.white24,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final image = this.image;
    return Container(
      height: size,
      width: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
      child: CircleAvatar(
        backgroundColor: brandRedColor,
        foregroundImage:
            image == null || image.isEmpty ? null : appImageProvider(image),
        child: Text(
          initial,
          style: AppTextStyle.subtitle2.copyWith(
            color: textPrimaryDarkColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
