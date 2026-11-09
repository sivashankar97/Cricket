import 'dart:async';
import 'dart:math';

import 'package:data/api/play/play_models.dart';
import 'package:data/api/user/user_models.dart';
import 'package:data/service/play/play_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

import '../../../../domain/play/cricket_game.dart';
import '../play_providers.dart';
import 'cricket_field_painter.dart';

class PlayGameArgs {
  final PlayMode mode;
  final int seed;
  final int? target;
  final UserModel? opponent;
  final PlayChallenge? challenge;

  const PlayGameArgs._({
    required this.mode,
    required this.seed,
    this.target,
    this.opponent,
    this.challenge,
  });

  factory PlayGameArgs.quick() => PlayGameArgs._(
        mode: PlayMode.solo,
        seed: Random().nextInt(1 << 31),
      );

  factory PlayGameArgs.daily(DailyChallenge daily) => PlayGameArgs._(
        mode: PlayMode.daily,
        seed: daily.seed,
        target: daily.target,
      );

  /// Creator bats first; the opponent later faces the same [seed].
  factory PlayGameArgs.newChallenge(UserModel opponent) => PlayGameArgs._(
        mode: PlayMode.challenge,
        seed: Random().nextInt(1 << 31),
        opponent: opponent,
      );

  factory PlayGameArgs.answerChallenge(PlayChallenge challenge) =>
      PlayGameArgs._(
        mode: PlayMode.challenge,
        seed: challenge.seed,
        target: challenge.target,
        challenge: challenge,
      );
}

enum _Phase { ready, bowling, shot, finished }

class PlayGameScreen extends ConsumerStatefulWidget {
  final PlayGameArgs args;

  const PlayGameScreen({super.key, required this.args});

  @override
  ConsumerState<PlayGameScreen> createState() => _PlayGameScreenState();
}

class _PlayGameScreenState extends ConsumerState<PlayGameScreen>
    with TickerProviderStateMixin {
  late int _seed;
  late Innings _innings;
  late final AnimationController _ball;
  late final AnimationController _swing;
  late final AnimationController _after;
  _Phase _phase = _Phase.ready;
  ShotResult? _lastShot;
  int? _lastOffset;
  bool _swung = false;
  bool _saving = false;
  bool _saved = false;
  Object? _saveError;
  Timer? _nextBallTimer;

  Delivery? get _delivery => _innings.nextDelivery;

  int get _totalMs => (_delivery?.travelMs ?? 1200) + GameRules.lateWindowMs;

  @override
  void initState() {
    super.initState();
    _seed = widget.args.seed;
    _innings = Innings.start(seed: _seed, target: widget.args.target);
    _ball = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _phase == _Phase.bowling) {
          _resolve(null);
        }
      });
    _swing = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _after = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _nextBallTimer?.cancel();
    _ball.dispose();
    _swing.dispose();
    _after.dispose();
    super.dispose();
  }

  void _bowl() {
    if (_delivery == null) return;
    setState(() {
      _phase = _Phase.bowling;
      _lastShot = null;
      _lastOffset = null;
      _swung = false;
    });
    _swing.reset();
    _after.reset();
    _ball.duration = Duration(milliseconds: _totalMs);
    _ball.forward(from: 0);
  }

  void _onTap() {
    switch (_phase) {
      case _Phase.ready:
        _bowl();
      case _Phase.bowling:
        if (_swung) return;
        _swung = true;
        _swing.forward(from: 0);
        final elapsed = (_ball.value * _totalMs).round();
        _resolve(elapsed - _delivery!.travelMs);
      case _Phase.shot:
      case _Phase.finished:
        break;
    }
  }

  void _resolve(int? offsetMs) {
    final delivery = _delivery;
    if (delivery == null) return;
    final result = judgeShot(delivery, tapOffsetMs: offsetMs);
    _ball.stop();
    if (result != ShotResult.dot || offsetMs != null) {
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _phase = _Phase.shot;
      _lastShot = result;
      _lastOffset = offsetMs;
      _innings = _innings.record(result);
    });
    _after.forward(from: 0);
    _nextBallTimer = Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      if (_innings.isOver) {
        setState(() => _phase = _Phase.finished);
        _save();
      } else {
        _bowl();
      }
    });
  }

  void _restart() {
    _nextBallTimer?.cancel();
    _ball.reset();
    _swing.reset();
    _after.reset();
    setState(() {
      _seed = Random().nextInt(1 << 31);
      _innings = Innings.start(seed: _seed, target: widget.args.target);
      _phase = _Phase.ready;
      _lastShot = null;
      _lastOffset = null;
      _saved = false;
      _saveError = null;
    });
  }

  // ── Saving ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final user = ref.read(playIdentityProvider);
    if (user == null || _saving || _saved) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final service = ref.read(playServiceProvider);
    final args = widget.args;
    final score = PlayScore(
      runs: _innings.runs,
      wickets: _innings.wickets,
      balls: _innings.balls,
    );
    try {
      String? challengeId = args.challenge?.id;
      bool? won;
      if (args.mode == PlayMode.daily) won = _innings.won;

      if (args.opponent != null) {
        final created = await service.createChallenge((id) => PlayChallenge(
              id: id,
              seed: args.seed,
              creatorId: user.id,
              creatorName: user.name,
              opponentId: args.opponent!.id,
              opponentName: args.opponent!.name ?? '',
              creatorScore: score,
              createdAt: DateTime.now(),
            ));
        challengeId = created.id;
      } else if (args.challenge != null) {
        final winner = challengeWinner(
          creatorRuns: args.challenge!.creatorScore.runs,
          opponentRuns: _innings.runs,
        );
        won = winner == ChallengeWinner.tie
            ? null
            : winner == ChallengeWinner.opponent;
        await service.completeChallenge(
          challengeId: args.challenge!.id,
          opponentScore: score,
          winnerId: switch (winner) {
            ChallengeWinner.creator => args.challenge!.creatorId,
            ChallengeWinner.opponent => user.id,
            ChallengeWinner.tie => null,
          },
        );
      }

      await service.saveGame(PlayGame(
        id: service.newGameId(),
        userId: user.id,
        userName: user.name,
        userImage: user.imageUrl,
        mode: args.mode,
        seed: _seed,
        runs: _innings.runs,
        wickets: _innings.wickets,
        balls: _innings.balls,
        fours: _innings.fours,
        sixes: _innings.sixes,
        target: args.target,
        won: won,
        dailyDate: args.mode == PlayMode.daily
            ? DailyChallenge.forDate(DateTime.now()).dateKey
            : null,
        challengeId: challengeId,
        createdAt: DateTime.now(),
      ));
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saveError = error);
      showErrorSnackBar(context: context, error: error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: brandNavyColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _topBar(context),
                  _scoreHud(context),
                  const SizedBox(height: 10),
                  _ballDots(),
                  const SizedBox(height: 12),
                  Expanded(child: _field(context)),
                  _bottomHint(context),
                ],
              ),
              if (_phase == _Phase.finished) _endOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final args = widget.args;
    final label = switch (args.mode) {
      PlayMode.daily => context.l10n.play_daily_title,
      PlayMode.challenge => context.l10n.play_game_vs(
          args.opponent?.name ?? args.challenge?.creatorName ?? ''),
      PlayMode.solo => context.l10n.play_quick_play,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, color: textPrimaryDarkColor),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subtitle1.copyWith(
                color: textPrimaryDarkColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreHud(BuildContext context) {
    final needed = _innings.runsNeeded;
    final subtitle = needed != null && !_innings.isOver
        ? context.l10n.play_game_need(needed, _innings.ballsLeft)
        : context.l10n.play_game_balls_left(_innings.ballsLeft);
    return Column(
      children: [
        Text(
          '${_innings.runs}/${_innings.wickets}',
          style: AppTextStyle.header1.copyWith(
            color: textPrimaryDarkColor,
            fontSize: 44,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subtitle,
          style: AppTextStyle.subtitle3.copyWith(color: textSecondaryDarkColor),
        ),
      ],
    );
  }

  Widget _ballDots() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(GameRules.balls, (index) {
        final result =
            index < _innings.results.length ? _innings.results[index] : null;
        final color = switch (result) {
          null => textPrimaryDarkColor.withValues(alpha: 0.12),
          ShotResult.out => brandRedColor,
          ShotResult.six || ShotResult.four => positiveGreenColor,
          _ => textPrimaryDarkColor.withValues(alpha: 0.35),
        };
        return Container(
          height: 22,
          width: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: result == null
              ? null
              : Text(
                  result.isOut ? 'W' : '${result.runs}',
                  style: AppTextStyle.caption.copyWith(
                    color: result == ShotResult.six || result == ShotResult.four
                        ? brandNavyColor
                        : textPrimaryDarkColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        );
      }),
    );
  }

  Widget _field(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _onTap(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_ball, _swing, _after]),
              builder: (context, _) => CustomPaint(
                painter: CricketFieldPainter(
                  delivery: _phase == _Phase.ready ? null : _lastDelivery,
                  ballProgress: _ballProgress,
                  swing: _swing.value,
                  after: _after.value,
                  shot: _lastShot,
                ),
              ),
            ),
          ),
          if (_lastShot != null && _phase == _Phase.shot) _shotBanner(context),
        ],
      ),
    );
  }

  /// The delivery being bowled, or the one just played while showing a shot.
  Delivery? get _lastDelivery {
    if (_phase == _Phase.bowling) return _delivery;
    final index = _innings.balls - 1;
    if (index < 0) return _delivery;
    return _innings.deliveries[index];
  }

  double get _ballProgress {
    final delivery = _lastDelivery;
    if (delivery == null) return 0;
    return _ball.value * _totalMsFor(delivery) / delivery.travelMs;
  }

  int _totalMsFor(Delivery delivery) =>
      delivery.travelMs + GameRules.lateWindowMs;

  Widget _shotBanner(BuildContext context) {
    final shot = _lastShot!;
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
    final offset = _lastOffset;
    final timing = offset == null
        ? context.l10n.play_timing_left
        : offset.abs() <= 45
            ? context.l10n.play_timing_perfect
            : offset < 0
                ? context.l10n.play_timing_early
                : context.l10n.play_timing_late;
    return Positioned(
      top: 24,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(_innings.balls),
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Column(
          children: [
            Text(
              text,
              style: AppTextStyle.header1.copyWith(
                color: color,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            Text(
              timing,
              style: AppTextStyle.subtitle3.copyWith(
                color: textPrimaryDarkColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomHint(BuildContext context) {
    final text = _phase == _Phase.ready
        ? context.l10n.play_game_tap_to_start
        : context.l10n.play_how_to;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: (_phase == _Phase.ready
                ? AppTextStyle.subtitle1
                : AppTextStyle.caption)
            .copyWith(
          color: _phase == _Phase.ready
              ? positiveGreenColor
              : textSecondaryDarkColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _endOverlay(BuildContext context) {
    final args = widget.args;
    final opponentName =
        args.opponent?.name ?? args.challenge?.creatorName ?? '';
    String? headline;
    Color headlineColor = positiveGreenColor;
    if (args.opponent != null) {
      headline = context.l10n.play_end_challenge_sent(opponentName);
    } else if (args.challenge != null) {
      final winner = challengeWinner(
        creatorRuns: args.challenge!.creatorScore.runs,
        opponentRuns: _innings.runs,
      );
      switch (winner) {
        case ChallengeWinner.opponent:
          headline = context.l10n.play_end_challenge_won(opponentName);
        case ChallengeWinner.creator:
          headline = context.l10n.play_end_challenge_lost(opponentName);
          headlineColor = brandRedColor;
        case ChallengeWinner.tie:
          headline = context.l10n.play_end_challenge_tie(opponentName);
          headlineColor = awarenessWarningColor;
      }
    } else if (args.target != null) {
      headline = _innings.won
          ? context.l10n.play_end_target_won
          : context.l10n.play_end_target_lost(args.target!);
      if (!_innings.won) headlineColor = brandRedColor;
    }

    return Positioned.fill(
      child: ColoredBox(
        color: brandNavyColor.withValues(alpha: 0.85),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: brandNavyCardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.play_end_title,
                  style: AppTextStyle.subtitle2
                      .copyWith(color: textSecondaryDarkColor),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.play_end_score(
                      _innings.runs, _innings.wickets, _innings.balls),
                  textAlign: TextAlign.center,
                  style: AppTextStyle.header3
                      .copyWith(color: textPrimaryDarkColor),
                ),
                if (headline != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.subtitle1.copyWith(
                      color: headlineColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                if (_saving)
                  Text(
                    context.l10n.play_end_saving,
                    style: AppTextStyle.caption
                        .copyWith(color: textSecondaryDarkColor),
                  )
                else if (_saveError != null)
                  _endButton(context.l10n.play_retry_save, _save)
                else ...[
                  if (args.mode == PlayMode.solo)
                    _endButton(context.l10n.play_again, _restart),
                  const SizedBox(height: 10),
                  _endButton(
                    context.l10n.play_done,
                    () => Navigator.of(context).maybePop(),
                    secondary: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _endButton(String text, VoidCallback onTap, {bool secondary = false}) {
    return OnTapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: secondary ? null : liveCardGradient,
          color: secondary ? textPrimaryDarkColor.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: AppTextStyle.button.copyWith(color: textPrimaryDarkColor),
        ),
      ),
    );
  }
}
