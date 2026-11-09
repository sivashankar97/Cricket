import 'dart:async';
import 'dart:math';

import 'package:data/api/play/play_models.dart';
import 'package:data/service/play/play_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/components/mascot/mascot_reactions.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

import '../../../../domain/play/cricket_game.dart';
import '../play_providers.dart';
import 'play_arena.dart';
import 'play_layout.dart';
import 'play_sounds.dart';

/// A single-innings game: Quick play, the Daily challenge, or replying to an
/// older turn-based challenge. Live 1v1 matches use `PlayMatchScreen`.
class PlayGameArgs {
  final PlayMode mode;
  final int seed;
  final int? target;
  final PlayChallenge? challenge;

  const PlayGameArgs._({
    required this.mode,
    required this.seed,
    this.target,
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

  factory PlayGameArgs.answerChallenge(PlayChallenge challenge) =>
      PlayGameArgs._(
        mode: PlayMode.challenge,
        seed: challenge.seed,
        target: challenge.target,
        challenge: challenge,
      );
}

class PlayGameScreen extends ConsumerStatefulWidget {
  final PlayGameArgs args;

  const PlayGameScreen({super.key, required this.args});

  @override
  ConsumerState<PlayGameScreen> createState() => _PlayGameScreenState();
}

class _PlayGameScreenState extends ConsumerState<PlayGameScreen> {
  late int _seed = widget.args.seed;
  late Innings _innings =
      Innings.start(seed: _seed, target: widget.args.target);
  bool _finished = false;
  bool _saving = false;
  bool _saved = false;
  Object? _saveError;
  Timer? _finishTimer;

  /// Whether the last finished game was a loss, to cheer a retry.
  bool _lostLastGame = false;

  MascotController get _mascot => ref.read(mascotProvider.notifier);

  @override
  void dispose() {
    _finishTimer?.cancel();
    super.dispose();
  }

  void _onBall(ShotResult result, int? offsetMs) {
    setState(() => _innings = _innings.record(result, offsetMs: offsetMs));
    _mascot.react(
      reactionForShot(result, offsetMs),
      top: true,
      allowFun: false,
      duration: const Duration(milliseconds: 2200),
    );
    if (_innings.isOver) {
      _finishTimer = Timer(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        setState(() => _finished = true);
        _save();
      });
    }
  }

  void _reactToOutcome({required bool? won}) {
    final args = widget.args;
    final MascotReaction? reaction;
    if (args.challenge != null) {
      reaction = switch (won) {
        true => MascotReaction.challengeWon,
        false => MascotReaction.challengeLost,
        null => null,
      };
    } else if (args.mode == PlayMode.daily) {
      reaction =
          won == true ? MascotReaction.matchWon : MascotReaction.matchLost;
    } else {
      reaction = null;
    }
    if (won != null) {
      ref.read(playSoundsProvider).play(won ? PlaySound.win : PlaySound.lose);
    }
    _lostLastGame = won == false;
    if (reaction != null) _mascot.react(reaction, top: true);
  }

  void _restart() {
    if (_lostLastGame) _mascot.react(MascotReaction.comeback, top: true);
    _lostLastGame = false;
    _finishTimer?.cancel();
    setState(() {
      _seed = Random().nextInt(1 << 31);
      _innings = Innings.start(seed: _seed, target: widget.args.target);
      _finished = false;
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
    try {
      bool? won;
      if (args.mode == PlayMode.daily) won = _innings.won;

      final challenge = args.challenge;
      if (challenge != null) {
        final winner = challengeWinner(
          creatorRuns: challenge.creatorScore.runs,
          opponentRuns: _innings.runs,
        );
        won = winner == ChallengeWinner.tie
            ? null
            : winner == ChallengeWinner.opponent;
        await service.completeChallenge(
          challengeId: challenge.id,
          opponentScore: PlayScore(
            runs: _innings.runs,
            wickets: _innings.wickets,
            balls: _innings.balls,
          ),
          winnerId: switch (winner) {
            ChallengeWinner.creator => challenge.creatorId,
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
        challengeId: challenge?.id,
        createdAt: DateTime.now(),
      ));
      if (mounted) {
        setState(() => _saved = true);
        _reactToOutcome(won: won);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saveError = error);
      showErrorSnackBar(context: context, error: error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  String _label(BuildContext context) => switch (widget.args.mode) {
        PlayMode.daily => context.l10n.play_daily_title,
        PlayMode.challenge =>
          context.l10n.play_game_vs(widget.args.challenge?.creatorName ?? ''),
        PlayMode.match => context.l10n.play_mode_match,
        PlayMode.solo => context.l10n.play_quick_play,
      };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(playIdentityProvider);
    final name = user?.name ?? context.l10n.play_you;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: brandNavyColor,
        body: SafeArea(
          child: Stack(
            children: [
              PlayArenaLayout(
                topBar: _topBar(context),
                scoreboard: ArenaScoreboard(
                  innings: _innings,
                  batterName: name,
                  batterImage: user?.imageUrl,
                  label: _label(context),
                ),
                arena: PlayArena(
                  key: ValueKey(_seed),
                  innings: _innings,
                  batterName: name,
                  paused: _finished,
                  onBall: _onBall,
                ),
              ),
              if (_finished) _endOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final target = widget.args.target;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, color: textPrimaryDarkColor),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          if (target != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: awarenessWarningColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.play_hud_target(target),
                style: AppTextStyle.caption.copyWith(
                  color: awarenessWarningColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const PlaySoundToggle(),
        ],
      ),
    );
  }

  Widget _endOverlay(BuildContext context) {
    final args = widget.args;
    final challenge = args.challenge;
    String? headline;
    Color headlineColor = positiveGreenColor;
    if (challenge != null) {
      final name = challenge.creatorName;
      switch (challengeWinner(
        creatorRuns: challenge.creatorScore.runs,
        opponentRuns: _innings.runs,
      )) {
        case ChallengeWinner.opponent:
          headline = context.l10n.play_end_challenge_won(name);
        case ChallengeWinner.creator:
          headline = context.l10n.play_end_challenge_lost(name);
          headlineColor = brandRedColor;
        case ChallengeWinner.tie:
          headline = context.l10n.play_end_challenge_tie(name);
          headlineColor = awarenessWarningColor;
      }
    } else if (args.target != null) {
      headline = _innings.won
          ? context.l10n.play_end_target_won
          : context.l10n.play_end_target_lost(args.target!);
      if (!_innings.won) headlineColor = brandRedColor;
    }
    final xp = xpForGame(
      runs: _innings.runs,
      fours: _innings.fours,
      sixes: _innings.sixes,
      won: args.target != null && _innings.won,
    );

    return Positioned.fill(
      child: ColoredBox(
        color: brandNavyColor.withValues(alpha: 0.85),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints:
                  const BoxConstraints(maxWidth: PlayLayout.maxPanelWidth - 60),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: brandNavyCardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final result in _innings.results)
                        BallChip(result: result, size: 18),
                    ],
                  ),
                  if (headline != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.subtitle1.copyWith(
                        color: headlineColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_saved) ...[
                    const SizedBox(height: 10),
                    XpPill(xp: xp),
                  ],
                  const SizedBox(height: 22),
                  if (_saving)
                    Text(
                      context.l10n.play_end_saving,
                      style: AppTextStyle.caption
                          .copyWith(color: textSecondaryDarkColor),
                    )
                  else if (_saveError != null)
                    PlayButton(text: context.l10n.play_retry_save, onTap: _save)
                  else ...[
                    if (args.mode == PlayMode.solo)
                      PlayButton(
                          text: context.l10n.play_again, onTap: _restart),
                    const SizedBox(height: 10),
                    PlayButton(
                      text: context.l10n.play_done,
                      onTap: () => Navigator.of(context).maybePop(),
                      secondary: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "+42 XP" chip shown after a game.
class XpPill extends StatelessWidget {
  final int xp;

  const XpPill({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: awarenessWarningColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded,
              size: 18, color: awarenessWarningColor),
          const SizedBox(width: 4),
          Text(
            context.l10n.play_xp_earned(xp),
            style: AppTextStyle.subtitle3.copyWith(
              color: awarenessWarningColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width rounded button used on Play end and match screens.
class PlayButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool secondary;

  const PlayButton({
    super.key,
    required this.text,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return OnTapScale(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: secondary ? null : liveCardGradient,
            color:
                secondary ? textPrimaryDarkColor.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: AppTextStyle.button.copyWith(color: textPrimaryDarkColor),
          ),
        ),
      ),
    );
  }
}
