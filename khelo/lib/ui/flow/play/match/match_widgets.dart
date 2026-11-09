import 'dart:math';

import 'package:data/api/play/play_match.dart';
import 'package:flutter/material.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

import '../../../../domain/play/cricket_game.dart';
import '../game/cricket_field_painter.dart';
import '../game/play_arena.dart';
import '../game/play_layout.dart';

/// The empty stadium, dimmed, behind lobby, toss and result screens.
class StadiumBackdrop extends StatelessWidget {
  final double dim;
  final double celebrate;

  const StadiumBackdrop({super.key, this.dim = 0.55, this.celebrate = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: CricketFieldPainter(
            delivery: null,
            ballProgress: 0,
            swing: 0,
            after: 0,
            shot: null,
            celebrate: celebrate,
          ),
        ),
        ColoredBox(color: brandNavyColor.withValues(alpha: dim)),
      ],
    );
  }
}

/// Two players facing off; [pulse] rings the side still waiting.
class VersusRow extends StatelessWidget {
  final PlayMatchPlayer left;
  final PlayMatchPlayer right;
  final String leftCaption;
  final String rightCaption;
  final bool pulseRight;

  const VersusRow({
    super.key,
    required this.left,
    required this.right,
    this.leftCaption = '',
    this.rightCaption = '',
    this.pulseRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scale = PlayLayout.scale(MediaQuery.sizeOf(context));
    return Row(
      children: [
        Expanded(child: _side(context, left, leftCaption, scale, pulse: false)),
        Text(
          context.l10n.play_vs,
          style: AppTextStyle.header1.copyWith(
            color: awarenessWarningColor,
            fontSize: 30 * scale,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            shadows: [
              Shadow(
                color: awarenessWarningColor.withValues(alpha: 0.6),
                blurRadius: 16,
              ),
            ],
          ),
        ),
        Expanded(
          child: _side(context, right, rightCaption, scale, pulse: pulseRight),
        ),
      ],
    );
  }

  Widget _side(
    BuildContext context,
    PlayMatchPlayer player,
    String caption,
    double scale, {
    required bool pulse,
  }) {
    final size = 76 * scale;
    final badge = PlayerBadge(
      name: player.name,
      image: player.image,
      size: size,
      ring: Colors.white38,
    );
    return Column(
      children: [
        pulse ? _Pulse(size: size, child: badge) : badge,
        const SizedBox(height: 10),
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.subtitle1.copyWith(
            color: textPrimaryDarkColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (caption.isNotEmpty)
          Text(
            caption,
            style: AppTextStyle.caption.copyWith(color: textSecondaryDarkColor),
          ),
      ],
    );
  }
}

class _Pulse extends StatefulWidget {
  final Widget child;
  final double size;

  const _Pulse({required this.child, required this.size});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.scale(
            scale: 1 + _controller.value * 0.5,
            child: Container(
              height: widget.size,
              width: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: positiveGreenColor.withValues(
                      alpha: 1 - _controller.value),
                  width: 3,
                ),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: widget.child,
    );
  }
}

/// Full-screen VS card that slides both players in.
class VersusIntro extends StatelessWidget {
  final PlayMatchPlayer host;
  final PlayMatchPlayer guest;
  final String format;

  const VersusIntro({
    super.key,
    required this.host,
    required this.guest,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = PlayLayout.scale(size);
    final gap = PlayLayout.isLandscape(size) ? 12.0 : 28.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.play_mode_match.toUpperCase(),
            style: AppTextStyle.subtitle2.copyWith(
              color: awarenessWarningColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: gap),
          Row(
            children: [
              Expanded(
                child: Transform.translate(
                  offset: Offset(-160 * (1 - t), 0),
                  child: _player(host, scale),
                ),
              ),
              Transform.scale(
                scale: t.clamp(0, 2),
                child: Text(
                  context.l10n.play_vs,
                  style: AppTextStyle.header1.copyWith(
                    color: awarenessWarningColor,
                    fontSize: 48 * scale,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(
                        color: awarenessWarningColor.withValues(alpha: 0.7),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: Offset(160 * (1 - t), 0),
                  child: _player(guest, scale),
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
          Opacity(
            opacity: t.clamp(0, 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                format,
                style: AppTextStyle.subtitle3
                    .copyWith(color: textPrimaryDarkColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _player(PlayMatchPlayer player, double scale) => Column(
        children: [
          PlayerBadge(
            name: player.name,
            image: player.image,
            size: 92 * scale,
            ring: awarenessWarningColor,
          ),
          const SizedBox(height: 12),
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.header4.copyWith(
              color: textPrimaryDarkColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}

/// A gold coin; spins while [spinning], then shows heads or tails.
class TossCoin extends StatefulWidget {
  final bool spinning;
  final bool? heads;

  const TossCoin({super.key, required this.spinning, this.heads});

  @override
  State<TossCoin> createState() => _TossCoinState();
}

class _TossCoinState extends State<TossCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _spin.repeat();
  }

  @override
  void didUpdateWidget(TossCoin old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_spin.isAnimating) _spin.repeat();
    if (!widget.spinning && _spin.isAnimating) _spin.reset();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heads = widget.heads;
    final label = widget.spinning || heads == null
        ? ''
        : heads
            ? context.l10n.play_toss_heads[0]
            : context.l10n.play_toss_tails[0];
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateX(_spin.value * 2 * pi)
          ..translateByDouble(
              0, widget.spinning ? -sin(_spin.value * pi) * 16 : 0, 0, 1),
        child: child,
      ),
      child: Container(
        height: 96,
        width: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFE08A), Color(0xFFE0A91E), Color(0xFFA8740A)],
            stops: [0.2, 0.75, 1],
          ),
          border: Border.all(color: const Color(0xFFFFF1C2), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE0A91E).withValues(alpha: 0.5),
              blurRadius: 24,
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTextStyle.header1.copyWith(
            color: const Color(0xFF7A5205),
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// Big 3, 2, 1, GO! over the arena, with an optional heading above.
class CountdownOverlay extends StatelessWidget {
  /// 3, 2, 1, then 0 for GO; above 3 only the heading shows.
  final int value;
  final String heading;
  final String? body;

  const CountdownOverlay({
    super.key,
    required this.value,
    required this.heading,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    final scale = PlayLayout.scale(MediaQuery.sizeOf(context));
    return Positioned.fill(
      child: ColoredBox(
        color: brandNavyColor.withValues(alpha: 0.72),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                heading,
                textAlign: TextAlign.center,
                style: AppTextStyle.header3.copyWith(
                  color: textPrimaryDarkColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.subtitle2
                      .copyWith(color: textSecondaryDarkColor),
                ),
              ),
            ],
            SizedBox(height: 16 * scale),
            SizedBox(
              height: 120 * scale,
              child: value > 3
                  ? Text(
                      context.l10n.play_get_ready,
                      style: AppTextStyle.subtitle1.copyWith(
                        color: awarenessWarningColor,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : TweenAnimationBuilder<double>(
                      key: ValueKey(value),
                      tween: Tween(begin: 2.2, end: 1),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Text(
                        value == 0 ? context.l10n.play_countdown_go : '$value',
                        style: AppTextStyle.header1.copyWith(
                          color: value == 0
                              ? positiveGreenColor
                              : textPrimaryDarkColor,
                          fontSize: 88 * scale,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: (value == 0
                                      ? positiveGreenColor
                                      : awarenessWarningColor)
                                  .withValues(alpha: 0.7),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Both innings: runs, balls, 4s, 6s, strike rate and every ball.
class MatchScorecard extends StatelessWidget {
  final List<(PlayMatchPlayer, Innings)> rows;

  const MatchScorecard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        // Five stat columns must leave room for the name on small phones.
        final column = constraints.maxWidth < 340 ? 30.0 : 38.0;
        return _card(context, column);
      });

  Widget _card(BuildContext context, double column) {
    final head = AppTextStyle.caption.copyWith(
      color: textSecondaryDarkColor,
      fontWeight: FontWeight.w700,
    );
    final cell = AppTextStyle.subtitle3.copyWith(
      color: textPrimaryDarkColor,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brandNavyCardColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.play_scorecard.toUpperCase(),
            style: head.copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: SizedBox()),
              for (final label in [
                context.l10n.play_sc_runs,
                context.l10n.play_sc_balls,
                context.l10n.play_sc_fours,
                context.l10n.play_sc_sixes,
                context.l10n.play_sc_strike_rate,
              ])
                SizedBox(
                  width: column,
                  child: Text(label, textAlign: TextAlign.end, style: head),
                ),
            ],
          ),
          for (final (player, innings) in rows) ...[
            const Divider(color: Colors.white12, height: 18),
            Row(
              children: [
                PlayerBadge(name: player.name, image: player.image, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cell.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final value in [
                  '${innings.runs}${innings.wickets > 0 ? '/${innings.wickets}' : ''}',
                  '${innings.balls}',
                  '${innings.fours}',
                  '${innings.sixes}',
                  innings.strikeRate.toStringAsFixed(0),
                ])
                  SizedBox(
                    width: column,
                    child: Text(value, textAlign: TextAlign.end, style: cell),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final result in innings.results)
                  BallChip(result: result, size: 18),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
