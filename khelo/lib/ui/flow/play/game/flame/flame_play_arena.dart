import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/play/cricket_game.dart';
import '../../../../../domain/play/play_quality.dart';
import 'stick_cricket_game.dart';

/// Stick Cricket (Stick Sports) shell: full-bleed arena + bottom control bar.
class FlamePlayArena extends ConsumerStatefulWidget {
  final Innings innings;
  final String batterName;
  final bool paused;
  final void Function(ShotResult result, int? offsetMs)? onBall;

  const FlamePlayArena({
    super.key,
    required this.innings,
    required this.batterName,
    this.paused = false,
    this.onBall,
  });

  @override
  ConsumerState<FlamePlayArena> createState() => _FlamePlayArenaState();
}

class _FlamePlayArenaState extends ConsumerState<FlamePlayArena>
    with WidgetsBindingObserver {
  StickCricketGame? _game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = _createGame();
    if (widget.paused) _game!.pauseEngine();
  }

  StickCricketGame _createGame() {
    final quality = ref.read(playQualityProvider);
    final effects = ref.read(playEffectsOnPod);
    return StickCricketGame(
      innings: widget.innings,
      batterName: widget.batterName,
      haptics: quality.haptics && effects,
      onBall: (result, offset) => widget.onBall?.call(result, offset),
    );
  }

  @override
  void didUpdateWidget(FlamePlayArena old) {
    super.didUpdateWidget(old);
    if (widget.innings.seed != old.innings.seed) {
      _game?.pauseEngine();
      _game = _createGame();
      if (widget.paused) _game!.pauseEngine();
      setState(() {});
      return;
    }
    if (widget.innings.balls != old.innings.balls ||
        widget.innings.runs != old.innings.runs) {
      _game?.syncInnings(widget.innings);
    }
    if (widget.paused != old.paused) {
      _game?.setPaused(widget.paused);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final inactive = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
    if (inactive || widget.paused) {
      _game?.pauseEngine();
    } else {
      _game?.resumeEngine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game?.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return ColoredBox(
      color: const Color(0xFF0A1020),
      child: Column(
        children: [
          Expanded(
            child: game == null
                ? const SizedBox.expand()
                : GameWidget(game: game),
          ),
          // Stick Sports–style bottom controls strip
          Container(
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: LayoutBuilder(
              builder: (context, c) {
                final tight = c.maxWidth < 420;
                return Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: tight ? 6 : 12,
                  runSpacing: 6,
                  children: [
                    const Text(
                      'CONTROLS:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    _KeyChip(
                      label: '←',
                      caption: tight ? 'Pull' : 'Pull/Hook',
                      onTap: () => _game?.playShot(-0.75),
                    ),
                    _KeyChip(
                      label: '↑',
                      caption: tight ? 'Drive' : 'Drive/Defend',
                      onTap: () => _game?.playShot(0),
                    ),
                    _KeyChip(
                      label: '→',
                      caption: tight ? 'Cut' : 'Off Drive/Cut',
                      onTap: () => _game?.playShot(0.75),
                    ),
                    _KeyChip(
                      label: '↓',
                      caption: 'Duck',
                      onTap: () => _game?.playShot(null),
                    ),
                    _KeyChip(
                      label: '␣',
                      caption: 'Pause',
                      onTap: () {
                        final g = _game;
                        if (g == null) return;
                        if (g.paused) {
                          g.resumeEngine();
                        } else {
                          g.pauseEngine();
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  final String label;
  final String caption;
  final VoidCallback onTap;

  const _KeyChip({
    required this.label,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF212121),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white54),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            caption,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
