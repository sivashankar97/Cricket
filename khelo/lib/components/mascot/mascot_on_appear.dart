import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mascot_controller.dart';
import 'mascot_reactions.dart';

/// Shows [reaction] when [child] appears (and again each time a kept-alive
/// tab holding it is reopened). Waits [settle] first and skips the cue if
/// the child is gone by then, so a list that is empty only for a moment
/// doesn't trigger it.
class MascotOnAppear extends ConsumerStatefulWidget {
  final MascotReaction reaction;
  final Widget child;
  final Duration settle;

  const MascotOnAppear({
    super.key,
    required this.reaction,
    required this.child,
    this.settle = const Duration(milliseconds: 700),
  });

  @override
  ConsumerState<MascotOnAppear> createState() => _MascotOnAppearState();
}

class _MascotOnAppearState extends ConsumerState<MascotOnAppear> {
  Timer? _timer;
  bool _wasActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_wasActive) {
      _timer?.cancel();
      _timer = Timer(widget.settle, () {
        if (!mounted || !TickerMode.valuesOf(context).enabled) return;
        ref.read(mascotProvider.notifier).react(widget.reaction);
      });
    } else if (!active) {
      _timer?.cancel();
    }
    _wasActive = active;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
