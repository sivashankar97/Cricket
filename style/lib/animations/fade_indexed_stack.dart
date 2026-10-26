import 'package:flutter/material.dart';

import 'app_animations.dart';

/// Keeps every visited child alive and cross-fades between them.
/// Children are built the first time they become selected.
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> {
  late final Set<int> _built = {widget.index};

  @override
  void didUpdateWidget(covariant FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _built.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          _built.contains(i)
              ? _layer(active: i == widget.index, child: widget.children[i])
              : const SizedBox.shrink(),
      ],
    );
  }

  Widget _layer({required bool active, required Widget child}) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.curve,
          child: AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.02),
            duration: AppAnimations.normal,
            curve: AppAnimations.curve,
            child: TickerMode(enabled: active, child: child),
          ),
        ),
      ),
    );
  }
}
