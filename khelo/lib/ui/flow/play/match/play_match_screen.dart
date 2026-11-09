import 'dart:async';
import 'dart:math';

import 'package:data/api/play/play_match.dart';
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
import 'package:khelo/ui/app_route.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

import '../../../../domain/play/cricket_game.dart';
import '../game/play_arena.dart';
import '../game/play_game_screen.dart';
import '../game/play_layout.dart';
import '../game/play_sounds.dart';
import '../play_opponent_sheet.dart';
import '../play_providers.dart';
import 'match_widgets.dart';

/// Sends a live match request from me to [opponent].
Future<PlayMatch> createPlayMatch(
  WidgetRef ref,
  PlayMatchPlayer opponent,
  MatchFormat format,
) {
  final me = ref.read(playIdentityProvider)!;
  return ref.read(playServiceProvider).createMatch((id) => PlayMatch(
        id: id,
        seed: Random().nextInt(1 << 31),
        overs: format.overs,
        wickets: format.wickets,
        host: PlayMatchPlayer(id: me.id, name: me.name, image: me.imageUrl),
        guest: opponent,
        createdAt: DateTime.now(),
      ));
}

/// A live 1v1 match from request to result. Whoever bats plays the balls;
/// the other player watches them replayed as they arrive.
class PlayMatchScreen extends ConsumerStatefulWidget {
  final String matchId;

  const PlayMatchScreen({super.key, required this.matchId});

  @override
  ConsumerState<PlayMatchScreen> createState() => _PlayMatchScreenState();
}

class _PlayMatchScreenState extends ConsumerState<PlayMatchScreen> {
  static const _introDuration = Duration(milliseconds: 2600);
  static const _coinDuration = Duration(milliseconds: 1800);

  Timer? _heartbeat;
  Timer? _clock;
  DateTime? _opponentSeen;
  DateTime _opponentHeardAt = DateTime.now();

  bool _introShown = false;
  bool _introRunning = false;
  bool _coinSpinning = false;
  String? _coinRevealedFor;
  int? _countdownInnings;
  int _countdownValue = 0;
  Timer? _countdownTimer;
  final Set<int> _countdownDone = {};
  final List<Timer> _timers = [];

  Innings? _batting;
  int _battingNumber = 0;
  bool _finishing = false;
  Object? _finishError;
  final Map<int, int> _watchShown = {};

  bool _resultHandled = false;
  bool _expiredHandled = false;
  bool _busy = false;
  bool _leaving = false;

  String get _me => ref.read(playIdentityProvider)?.id ?? '';

  PlayService get _service => ref.read(playServiceProvider);

  PlaySounds get _sounds => ref.read(playSoundsProvider);

  PlayMatch? get _latest =>
      ref.read(playMatchProvider(widget.matchId)).valueOrNull;

  @override
  void initState() {
    super.initState();
    _beat();
    _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) => _beat());
    _clock = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
    ref.listenManual<AsyncValue<PlayMatch?>>(
      playMatchProvider(widget.matchId),
      (previous, next) {
        final match = next.valueOrNull;
        if (match != null) _onMatch(previous?.valueOrNull, match);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _clock?.cancel();
    _countdownTimer?.cancel();
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  void _beat() {
    final me = _me;
    if (me.isNotEmpty) _service.markSeen(widget.matchId, me);
  }

  void _later(Duration delay, VoidCallback action) {
    _timers.add(Timer(delay, () {
      if (mounted) action();
    }));
  }

  void _reevaluate() {
    final match = _latest;
    if (match != null) _onMatch(null, match);
  }

  // ── Reacting to match changes ────────────────────────────────────────────

  void _onMatch(PlayMatch? previous, PlayMatch match) {
    final me = _me;
    if (me.isEmpty || !match.involves(me)) return;
    final opponent = match.otherThan(me).id;
    final seen = match.lastSeen[opponent];
    final opponentPlayed = previous != null &&
        match.currentBatterId == opponent &&
        match.currentBalls.length != previous.currentBalls.length;
    if (seen != _opponentSeen || opponentPlayed) {
      _opponentSeen = seen;
      _opponentHeardAt = DateTime.now();
    }

    switch (match.status) {
      case PlayMatchStatus.requested:
        if (match.isHost(me) &&
            match.isExpired(DateTime.now()) &&
            !_expiredHandled) {
          _expiredHandled = true;
          _service.cancelMatch(match.id).catchError((_) => false);
        }
      case PlayMatchStatus.toss:
        _maybeIntro(match);
        if (!_introRunning &&
            match.tossCall != null &&
            !_coinSpinning &&
            _coinRevealedFor == null) {
          _spinCoin(match);
        }
      case PlayMatchStatus.live:
        _maybeIntro(match);
        _syncBatting(match);
        _maybeCountdown(match);
      case PlayMatchStatus.completed:
        _onCompleted(match);
      case PlayMatchStatus.declined:
      case PlayMatchStatus.cancelled:
        break;
    }
  }

  void _maybeIntro(PlayMatch match) {
    if (_introShown) return;
    _introShown = true;
    final fresh = match.status == PlayMatchStatus.toss ||
        (match.currentInnings == 1 && match.innings1.isEmpty);
    if (!fresh) return;
    _introRunning = true;
    _sounds.play(PlaySound.crowdCheer, volume: 0.5);
    _later(_introDuration, () {
      setState(() => _introRunning = false);
      _reevaluate();
    });
    _rebuild();
  }

  void _spinCoin(PlayMatch match) {
    _coinSpinning = true;
    _sounds.play(PlaySound.coin);
    _later(_coinDuration, () {
      setState(() {
        _coinSpinning = false;
        _coinRevealedFor = match.tossCall;
      });
      HapticFeedback.mediumImpact();
    });
    _rebuild();
  }

  void _rebuild() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _syncBatting(PlayMatch match) {
    if (match.currentBatterId != _me) return;
    final number = match.currentInnings;
    if (_battingNumber != number) {
      _battingNumber = number;
      _batting = match.innings(number);
      _rebuild();
    }
    // Reopened after the last ball but before the innings was closed.
    if (_batting!.isOver && !_finishing) _finishInnings();
  }

  void _maybeCountdown(PlayMatch match) {
    final number = match.currentInnings;
    if (_introRunning ||
        _countdownInnings != null ||
        _countdownDone.contains(number)) {
      return;
    }
    if (match.currentBalls.isNotEmpty) {
      _countdownDone.add(number);
      return;
    }
    _countdownInnings = number;
    _countdownValue = number == 2 ? 6 : 4;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _countdownValue--);
      if (_countdownValue >= 1 && _countdownValue <= 3) {
        _sounds.play(PlaySound.countdown);
      } else if (_countdownValue == 0) {
        _sounds.play(PlaySound.go);
        HapticFeedback.heavyImpact();
      } else if (_countdownValue < 0) {
        timer.cancel();
        setState(() {
          _countdownDone.add(number);
          _countdownInnings = null;
        });
      }
    });
    _rebuild();
  }

  void _onCompleted(PlayMatch match) {
    if (_resultHandled) return;
    _resultHandled = true;
    _countdownTimer?.cancel();
    _countdownInnings = null;
    final winner = match.winnerId;
    final mascot = ref.read(mascotProvider.notifier);
    if (winner == null) {
      _sounds.play(PlaySound.crowdCheer);
      mascot.react(MascotReaction.matchTied, top: true);
    } else if (winner == _me) {
      _sounds.play(PlaySound.win);
      mascot.react(MascotReaction.matchWon, top: true);
    } else {
      _sounds.play(PlaySound.lose);
      mascot.react(MascotReaction.matchLost, top: true);
    }
    _rebuild();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) showErrorSnackBar(context: context, error: error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _callToss(PlayMatch match, bool heads) => _run(() async {
        final won = heads == tossLandsHeads(match.seed);
        await _service.callToss(
          match.id,
          call: heads ? 'heads' : 'tails',
          winnerId: won ? match.guest.id : match.host.id,
        );
      });

  void _choose(PlayMatch match, bool bat) => _run(() async {
        await _service.chooseBattingFirst(
          match.id,
          batterId: bat ? _me : match.otherThan(_me).id,
        );
      });

  void _onBall(ShotResult result, int? offsetMs) {
    final batting = _batting;
    if (batting == null) return;
    final number = _battingNumber;
    final next = batting.record(result, offsetMs: offsetMs);
    setState(() => _batting = next);
    ref.read(mascotProvider.notifier).react(
          reactionForShot(result, offsetMs),
          top: true,
          allowFun: false,
          duration: const Duration(milliseconds: 2200),
        );
    _service
        .saveBalls(widget.matchId, innings: number, balls: ballsOf(next))
        .catchError((Object error) {
      if (mounted) showErrorSnackBar(context: context, error: error);
    });
    if (next.isOver) _later(const Duration(milliseconds: 1600), _finishInnings);
  }

  /// Closes my innings: hands over to the chaser, or settles the match.
  Future<void> _finishInnings() async {
    final match = _latest;
    final batting = _batting;
    if (match == null || batting == null || _finishing) return;
    setState(() {
      _finishing = true;
      _finishError = null;
    });
    try {
      await _service.saveBalls(
        match.id,
        innings: _battingNumber,
        balls: ballsOf(batting),
      );
      if (_battingNumber == 1) {
        await _service.startSecondInnings(match.id);
      } else {
        final first = match.innings(1);
        final outcome = matchOutcome(
          firstRuns: first.runs,
          secondRuns: batting.runs,
          secondWickets: batting.wickets,
          format: match.format,
        );
        final winnerId = switch (outcome.winner) {
          MatchWinner.firstBatter => match.battingFirstId,
          MatchWinner.secondBatter => match.battingSecondId,
          MatchWinner.tie => null,
        };
        final done = await _service.completeMatch(
          match.id,
          winnerId: winnerId,
          resultType: switch (outcome.winner) {
            MatchWinner.firstBatter => PlayMatchResultType.runs,
            MatchWinner.secondBatter => PlayMatchResultType.wickets,
            MatchWinner.tie => PlayMatchResultType.tie,
          },
          margin: outcome.margin,
        );
        if (done) await _saveGames(match, winnerId, first, batting);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _finishing = false;
        _finishError = error;
      });
    }
  }

  /// One game per player, keyed by match so retries overwrite.
  Future<void> _saveGames(
    PlayMatch match,
    String? winnerId,
    Innings first,
    Innings second,
  ) async {
    final firstId = match.battingFirstId;
    final secondId = match.battingSecondId;
    if (firstId == null || secondId == null) return;
    PlayGame game(String playerId, Innings innings, int? target) {
      final player = match.playerById(playerId);
      return PlayGame(
        id: '${match.id}_$playerId',
        userId: playerId,
        userName: player.name,
        userImage: player.image,
        mode: PlayMode.match,
        seed: match.seed,
        runs: innings.runs,
        wickets: innings.wickets,
        balls: innings.balls,
        fours: innings.fours,
        sixes: innings.sixes,
        target: target,
        won: winnerId == null ? null : winnerId == playerId,
        createdAt: DateTime.now(),
      );
    }

    await _service.saveMatchGames([
      game(firstId, first, null),
      game(secondId, second, first.runs + 1),
    ]);
  }

  /// Ends the match with [winnerId] winning because the other side left.
  Future<void> _forfeit(PlayMatch match, String winnerId) async {
    final done = await _service.completeMatch(
      match.id,
      winnerId: winnerId,
      resultType: PlayMatchResultType.forfeit,
      margin: 0,
    );
    if (!done) return;
    final mine = _batting;
    Innings current(int number) =>
        mine != null && _battingNumber == number ? mine : match.innings(number);
    await _saveGames(match, winnerId, current(1), current(2));
  }

  Future<void> _confirmLeave(PlayMatch match) async {
    final other = match.otherThan(_me);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.play_leave_title),
        content: Text(context.l10n.play_leave_body(other.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.play_leave_stay),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.l10n.play_leave_confirm,
              style: const TextStyle(color: brandRedColor),
            ),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    await _run(() => _forfeit(match, other.id));
    if (!mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  void _close() {
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _rematch(PlayMatch match) => _run(() async {
        final created =
            await createPlayMatch(ref, match.otherThan(_me), match.format);
        if (mounted) AppRoute.playMatch(created.id).pushReplacement(context);
      });

  // ── UI ───────────────────────────────────────────────────────────────────

  bool _inPlay(PlayMatch? match) =>
      match != null &&
      (match.status == PlayMatchStatus.toss ||
          match.status == PlayMatchStatus.live);

  Duration get _opponentSilence => DateTime.now().difference(_opponentHeardAt);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(playMatchProvider(widget.matchId));
    final match = async.valueOrNull;
    final me = ref.watch(playIdentityProvider)?.id ?? '';

    final Widget body;
    if (match == null || !match.involves(me)) {
      body = async.isLoading
          ? const Center(child: AppProgressIndicator())
          : _message(context, context.l10n.play_match_unavailable);
    } else {
      body = switch (match.status) {
        PlayMatchStatus.requested => _lobby(context, match),
        PlayMatchStatus.declined => _message(
            context,
            match.isHost(me)
                ? context.l10n.play_match_declined(match.guest.name)
                : context.l10n.play_match_cancelled,
          ),
        PlayMatchStatus.cancelled => _message(
            context,
            (match.updatedAt ?? match.createdAt).difference(match.createdAt) >
                    PlayMatch.requestLifetime
                ? context.l10n.play_match_expired
                : context.l10n.play_match_cancelled,
          ),
        PlayMatchStatus.toss => _tossView(context, match),
        PlayMatchStatus.live => _liveView(context, match),
        PlayMatchStatus.completed => _resultView(context, match),
      };
    }

    return PopScope(
      canPop: _leaving || !_inPlay(match),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && match != null) _confirmLeave(match);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: brandNavyColor,
          body: body,
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, PlayMatch? match) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, color: textPrimaryDarkColor),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              match == null
                  ? context.l10n.play_mode_match
                  : '${context.l10n.play_mode_match} · '
                      '${formatLabel(context, match.format)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subtitle2.copyWith(
                color: textPrimaryDarkColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const PlaySoundToggle(),
        ],
      ),
    );
  }

  /// Stadium behind a centered panel, for every phase except batting.
  Widget _stage(
    BuildContext context,
    PlayMatch? match,
    Widget child, {
    double celebrate = 0,
  }) {
    return Stack(
      children: [
        Positioned.fill(child: StadiumBackdrop(celebrate: celebrate)),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: PlayLayout.maxGameWidth),
              child: Column(
                children: [
                  _topBar(context, match),
                  if (_inPlay(match)) _connectionBanner(context, match!),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panel(List<Widget> children) => Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
              PlayLayout.isSmall(MediaQuery.sizeOf(context)) ? 16 : 24),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: PlayLayout.maxPanelWidth),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      );

  Widget _title(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyle.header3.copyWith(
          color: textPrimaryDarkColor,
          fontWeight: FontWeight.w800,
        ),
      );

  Widget _body(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyle.subtitle2.copyWith(color: textSecondaryDarkColor),
      );

  Widget _message(BuildContext context, String text) => _stage(
        context,
        null,
        _panel([
          _title(text),
          const SizedBox(height: 24),
          PlayButton(
            text: context.l10n.play_match_back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ]),
      );

  Widget _connectionBanner(BuildContext context, PlayMatch match) {
    final silence = _opponentSilence;
    if (silence < PlayMatch.disconnectedAfter) return const SizedBox.shrink();
    final canClaim = silence >= PlayMatch.forfeitAfter;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: brandRedDeepColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: textPrimaryDarkColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.play_opponent_offline(match.otherThan(_me).name),
              style: AppTextStyle.caption.copyWith(
                color: textPrimaryDarkColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canClaim)
            TextButton(
              onPressed: _busy ? null : () => _run(() => _forfeit(match, _me)),
              style: TextButton.styleFrom(
                backgroundColor: textPrimaryDarkColor,
                foregroundColor: brandRedDeepColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(context.l10n.play_claim_win),
            ),
        ],
      ),
    );
  }

  // ── Request lobby ────────────────────────────────────────────────────────

  Widget _lobby(BuildContext context, PlayMatch match) {
    final iAmHost = match.isHost(_me);
    final format = formatLabel(context, match.format);
    final expired = match.isExpired(DateTime.now());
    final List<Widget> children;
    if (iAmHost) {
      children = [
        VersusRow(
          left: match.host,
          right: match.guest,
          leftCaption: context.l10n.play_you,
          pulseRight: !expired,
        ),
        const SizedBox(height: 32),
        _title(expired
            ? context.l10n.play_match_expired
            : context.l10n.play_match_waiting_title(match.guest.name)),
        const SizedBox(height: 8),
        _body(expired
            ? format
            : '$format\n${context.l10n.play_match_waiting_body}'),
        const SizedBox(height: 28),
        expired
            ? PlayButton(
                text: context.l10n.play_match_back,
                onTap: () => Navigator.of(context).maybePop(),
              )
            : PlayButton(
                text: context.l10n.play_match_cancel,
                secondary: true,
                onTap: _busy
                    ? null
                    : () => _run(() async {
                          await _service.cancelMatch(match.id);
                          _close();
                        }),
              ),
      ];
    } else {
      children = [
        VersusRow(
          left: match.host,
          right: match.guest,
          rightCaption: context.l10n.play_you,
        ),
        const SizedBox(height: 32),
        _title(context.l10n.play_match_incoming_title(match.host.name)),
        const SizedBox(height: 8),
        _body(expired
            ? context.l10n.play_match_expired
            : context.l10n.play_match_incoming_body(format)),
        const SizedBox(height: 28),
        if (!expired) ...[
          PlayButton(
            text: context.l10n.play_match_accept,
            onTap:
                _busy ? null : () => _run(() => _service.acceptMatch(match.id)),
          ),
          const SizedBox(height: 10),
        ],
        PlayButton(
          text: expired
              ? context.l10n.play_match_back
              : context.l10n.play_match_decline,
          secondary: true,
          onTap: _busy
              ? null
              : () => _run(() async {
                    if (!expired) await _service.declineMatch(match.id);
                    _close();
                  }),
        ),
      ];
    }
    return _stage(context, match, _panel(children));
  }

  // ── Toss ─────────────────────────────────────────────────────────────────

  Widget _intro(BuildContext context, PlayMatch match) => _stage(
        context,
        match,
        VersusIntro(
          host: match.host,
          guest: match.guest,
          format: formatLabel(context, match.format),
        ),
        celebrate: 0.5,
      );

  Widget _tossView(BuildContext context, PlayMatch match) {
    if (_introRunning) return _intro(context, match);
    final me = _me;
    final call = match.tossCall;
    final revealed = call != null && !_coinSpinning && _coinRevealedFor != null;
    final children = <Widget>[
      _title(context.l10n.play_toss_title),
      const SizedBox(height: 28),
      TossCoin(
        spinning: _coinSpinning,
        heads: revealed ? tossLandsHeads(match.seed) : null,
      ),
      const SizedBox(height: 28),
    ];

    if (call == null) {
      if (match.guest.id == me) {
        children.addAll([
          _body(context.l10n.play_toss_call_prompt),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PlayButton(
                  text: context.l10n.play_toss_heads,
                  onTap: _busy ? null : () => _callToss(match, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PlayButton(
                  text: context.l10n.play_toss_tails,
                  onTap: _busy ? null : () => _callToss(match, false),
                ),
              ),
            ],
          ),
        ]);
      } else {
        children
            .add(_body(context.l10n.play_toss_waiting_call(match.guest.name)));
      }
    } else {
      final callName = call == 'heads'
          ? context.l10n.play_toss_heads
          : context.l10n.play_toss_tails;
      children.add(_body(context.l10n.play_toss_called(
        match.guest.id == me ? context.l10n.play_you : match.guest.name,
        callName,
      )));
      if (revealed) {
        final winner = match.tossWinnerId;
        final iWon = winner == me;
        children.addAll([
          const SizedBox(height: 14),
          Text(
            iWon
                ? context.l10n.play_toss_won
                : context.l10n
                    .play_toss_lost(match.playerById(winner ?? '').name),
            textAlign: TextAlign.center,
            style: AppTextStyle.header4.copyWith(
              color: iWon ? positiveGreenColor : awarenessWarningColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (iWon) ...[
            _body(context.l10n.play_toss_choose),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PlayButton(
                    text: context.l10n.play_toss_bat,
                    onTap: _busy ? null : () => _choose(match, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PlayButton(
                    text: context.l10n.play_toss_bowl,
                    secondary: true,
                    onTap: _busy ? null : () => _choose(match, false),
                  ),
                ),
              ],
            ),
          ] else
            _body(context.l10n
                .play_toss_waiting_choice(match.playerById(winner ?? '').name)),
        ]);
      }
    }
    return _stage(context, match, _panel(children));
  }

  // ── Live innings ─────────────────────────────────────────────────────────

  Widget _liveView(BuildContext context, PlayMatch match) {
    if (_introRunning) return _intro(context, match);
    final number = match.currentInnings;
    final batterId = match.currentBatterId ?? '';
    final batter = match.playerById(batterId);
    final iBat = batterId == _me && _batting != null;
    final full = match.innings(number);
    final first = match.innings(1);

    final Innings shown;
    if (iBat) {
      shown = _batting!;
    } else {
      final count = _watchShown.putIfAbsent(number, () => full.balls);
      shown = Innings.replay(
        seed: full.seed,
        target: full.target,
        format: full.format,
        balls: [
          for (var i = 0; i < min(count, full.balls); i++)
            (full.results[i], full.offsets[i]),
        ],
      );
    }

    final label = iBat
        ? context.l10n.play_live_your_innings
        : number == 1
            ? context.l10n.play_live_watch_first
            : context.l10n.play_live_watch_second(batter.name, first.runs + 1);

    return Stack(
      children: [
        SafeArea(
          child: PlayArenaLayout(
            topBar: _topBar(context, match),
            banners: [_connectionBanner(context, match)],
            scoreboard: ArenaScoreboard(
              innings: shown,
              batterName: batter.name,
              batterImage: batter.image,
              label: label,
            ),
            arena: PlayArena(
              key: ValueKey('arena-$number-$iBat'),
              innings: iBat ? _batting! : full,
              batterName: batter.name,
              interactive: iBat,
              paused: _countdownInnings != null || _finishing,
              onBall: iBat ? _onBall : null,
              onReplayed: iBat
                  ? null
                  : (count) => setState(() => _watchShown[number] = count),
            ),
          ),
        ),
        if (_countdownInnings == number) _countdown(context, match),
        if (_finishError != null) _finishRetry(context),
      ],
    );
  }

  Widget _countdown(BuildContext context, PlayMatch match) {
    final number = match.currentInnings;
    final batterId = match.currentBatterId ?? '';
    if (number == 1) {
      return CountdownOverlay(
        value: _countdownValue,
        heading: batterId == _me
            ? context.l10n.play_live_your_innings
            : context.l10n.play_bats_first(match.playerById(batterId).name),
      );
    }
    final first = match.innings(1);
    final firstBatter = match.playerById(match.battingFirstId ?? '');
    final chaser = match.playerById(batterId);
    return CountdownOverlay(
      value: _countdownValue,
      heading: context.l10n.play_innings_break,
      body: context.l10n.play_innings_break_body(
        firstBatter.name,
        '${first.runs}/${first.wickets}',
        chaser.name,
        first.runs + 1,
      ),
    );
  }

  Widget _finishRetry(BuildContext context) => Positioned(
        left: 24,
        right: 24,
        bottom: 40,
        child: PlayButton(
          text: context.l10n.play_retry_save,
          onTap: _finishInnings,
        ),
      );

  // ── Result ───────────────────────────────────────────────────────────────

  Widget _resultView(BuildContext context, PlayMatch match) {
    final me = _me;
    final winnerId = match.winnerId;
    final (banner, color) = winnerId == null
        ? (context.l10n.play_result_tie_banner, awarenessWarningColor)
        : winnerId == me
            ? (context.l10n.play_result_you_win, positiveGreenColor)
            : (context.l10n.play_result_you_lose, brandRedColor);
    final winnerName = winnerId == null ? '' : match.playerById(winnerId).name;
    final line = switch (match.resultType) {
      PlayMatchResultType.forfeit =>
        context.l10n.play_result_forfeit(winnerName),
      PlayMatchResultType.runs =>
        context.l10n.play_result_by_runs(winnerName, match.margin ?? 0),
      PlayMatchResultType.wickets =>
        context.l10n.play_result_by_wickets(winnerName, match.margin ?? 0),
      PlayMatchResultType.tie || null => context.l10n.play_result_tied,
    };

    final firstId = match.battingFirstId;
    final secondId = match.battingSecondId;
    final first = match.innings(1);
    final second = match.innings(2);
    final rows = firstId == null || secondId == null
        ? const <(PlayMatchPlayer, Innings)>[]
        : [
            (match.playerById(firstId), first),
            (match.playerById(secondId), second),
          ];
    final mine = firstId == me
        ? first
        : secondId == me
            ? second
            : null;
    final xp = mine == null
        ? null
        : xpForGame(
            runs: mine.runs,
            fours: mine.fours,
            sixes: mine.sixes,
            won: winnerId == me,
          );

    return _stage(
      context,
      match,
      celebrate: winnerId == me ? 1 : 0,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              banner,
              textAlign: TextAlign.center,
              style: AppTextStyle.header1.copyWith(
                color: color,
                fontSize: 46,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.6), blurRadius: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          _body(line),
          const SizedBox(height: 20),
          if (rows.isNotEmpty) MatchScorecard(rows: rows),
          if (xp != null) ...[
            const SizedBox(height: 16),
            Center(child: XpPill(xp: xp)),
          ],
          const SizedBox(height: 24),
          PlayButton(
            text: context.l10n.play_rematch,
            onTap: _busy ? null : () => _rematch(match),
          ),
          const SizedBox(height: 10),
          PlayButton(
            text: context.l10n.play_done,
            secondary: true,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
