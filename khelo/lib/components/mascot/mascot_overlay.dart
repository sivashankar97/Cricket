import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

import 'mascot_controller.dart';
import 'mascot_reactions.dart';

/// Shows the tiger peeking in from the right edge with a speech bubble.
/// Only the tiger's body takes taps (for a movie line); the bubble and the
/// rest of the screen pass taps through. Any tap or scroll elsewhere sends
/// the tiger away, so it never sits in the user's way.
class MascotOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const MascotOverlay({super.key, required this.child});

  @override
  ConsumerState<MascotOverlay> createState() => _MascotOverlayState();
}

class _MascotOverlayState extends ConsumerState<MascotOverlay>
    with TickerProviderStateMixin {
  static const _mascotHeight = 118.0;
  static const _mascotWidth = 140.0;

  /// Taps right after the tiger appears are usually the action that
  /// triggered it, so they don't dismiss it.
  static const _dismissGrace = Duration(milliseconds: 700);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
    reverseDuration: const Duration(milliseconds: 340),
  );
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    value: 1,
  );

  MascotCue? _cue;
  Timer? _graceTimer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<MascotCue?>(mascotProvider, _onCue);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      for (final pose in MascotPose.values) {
        precacheImage(AssetImage(pose.asset), context);
      }
    });
  }

  void _onCue(MascotCue? previous, MascotCue? next) {
    if (next == null) {
      _entrance.reverse().whenCompleteOrCancel(() {
        if (!mounted || ref.read(mascotProvider) != null) return;
        _idle.stop();
        setState(() => _cue = null);
      });
      return;
    }

    final alreadyOut = _cue != null &&
        _entrance.status != AnimationStatus.reverse &&
        _entrance.value > 0.5;
    _graceTimer?.cancel();
    _graceTimer = Timer(_dismissGrace, () {});
    setState(() => _cue = next);
    if (alreadyOut) {
      if (previous?.pose != next.pose) _pop.forward(from: 0);
    } else {
      _entrance.forward();
    }
    if (!MediaQuery.of(context).disableAnimations && !_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _idle.dispose();
    _pop.dispose();
    _graceTimer?.cancel();
    super.dispose();
  }

  void _onUserAction() {
    if (ref.read(mascotProvider) == null || _graceTimer?.isActive != false) {
      return;
    }
    ref.read(mascotProvider.notifier).hide();
  }

  @override
  Widget build(BuildContext context) {
    final cue = _cue;
    return Stack(
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _onUserAction(),
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) _onUserAction();
          },
          child: widget.child,
        ),
        if (cue != null) _peek(context, cue),
      ],
    );
  }

  Widget _peek(BuildContext context, MascotCue cue) {
    final media = MediaQuery.of(context);
    final bottom =
        math.max(media.viewInsets.bottom, media.viewPadding.bottom) + cue.lift;
    const bubbleRight = _mascotWidth * 0.8;
    final bubbleWidth = math.min(260.0, media.size.width - bubbleRight - 16);

    return Positioned(
      left: 0,
      right: 0,
      top: cue.top ? media.viewPadding.top + 64 : null,
      bottom: cue.top ? null : bottom,
      height: _mascotHeight,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          liveRegion: true,
          label: cue.message,
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: Listenable.merge([_entrance, _idle, _pop]),
              builder: (context, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      ignoring: !cue.allowFun || _entrance.value < 0.9,
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(mascotProvider.notifier).playMovieLine(),
                        child: _mascot(cue),
                      ),
                    ),
                  ),
                  Positioned(
                    right: bubbleRight,
                    top: cue.top ? _mascotHeight * 0.12 : null,
                    bottom: cue.top ? null : _mascotHeight * 0.42,
                    child: IgnorePointer(
                      child: _bubble(context, cue, bubbleWidth),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mascot(MascotCue cue) {
    final slide = Curves.easeOutBack.transform(_entrance.value);
    final wave = math.sin(_idle.value * 2 * math.pi);
    final pop = Curves.elasticOut.transform(_pop.value);

    return Transform.translate(
      offset: Offset(
        _mascotWidth * (1 - slide) + _mascotWidth * 0.14,
        wave * 2.5,
      ),
      child: Transform.rotate(
        alignment: Alignment.bottomRight,
        angle: 0.55 * (1 - slide) - 0.07 - wave * 0.022,
        child: Transform.scale(
          alignment: Alignment.bottomCenter,
          scaleX: 1.06 - 0.06 * pop,
          scaleY: 0.92 + 0.08 * pop,
          child: SizedBox(
            width: _mascotWidth,
            height: _mascotHeight,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: [0, 0.74, 0.95, 1],
              ).createShader(rect),
              child: Image.asset(
                cue.pose.asset,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(BuildContext context, MascotCue cue, double maxWidth) {
    final cs = context.colorScheme;
    final appear = Curves.easeOutBack
        .transform(((_entrance.value - 0.45) / 0.55).clamp(0.0, 1.0));

    return Opacity(
      opacity: appear.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.7 + 0.3 * appear,
        alignment: Alignment.bottomRight,
        child: CustomPaint(
          painter: _BubblePainter(
            color: cs.surface,
            border: cs.outline,
            accent: cs.primary,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 14, 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  cue.message,
                  key: ValueKey(cue.id),
                  style: AppTextStyle.subtitle2.copyWith(
                    fontFamilyFallback: const ['NotoSansTamil'],
                    color: cs.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded speech bubble with a tail pointing down-right at the mascot.
class _BubblePainter extends CustomPainter {
  final Color color;
  final Color border;
  final Color accent;

  const _BubblePainter({
    required this.color,
    required this.border,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    final tail = Path()
      ..moveTo(size.width - 10, size.height - 14)
      ..lineTo(size.width + 7, size.height + 8)
      ..lineTo(size.width - 26, size.height - 1)
      ..close();
    final shape = Path.combine(
      PathOperation.union,
      Path()..addRRect(body),
      tail,
    );

    canvas.drawShadow(shape, Colors.black, 6, false);
    canvas.drawPath(shape, Paint()..color = color);
    canvas.drawPath(
      shape,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 4, size.height),
      Paint()..color = accent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.color != color || old.border != border || old.accent != accent;
}
