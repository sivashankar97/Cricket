import 'package:flutter/material.dart';

import 'app_animations.dart';

class AppPageTransitions {
  static Widget slideFade(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final incoming = CurvedAnimation(
      parent: animation,
      curve: AppAnimations.curve,
      reverseCurve: AppAnimations.reverseCurve,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppAnimations.curve,
      reverseCurve: AppAnimations.reverseCurve,
    );
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: const Offset(-0.06, 0))
          .animate(outgoing),
      child: FadeTransition(
        opacity: incoming,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.08, 0), end: Offset.zero)
              .animate(incoming),
          child: child,
        ),
      ),
    );
  }

  static Widget slideUp(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final incoming = CurvedAnimation(
      parent: animation,
      curve: AppAnimations.curve,
      reverseCurve: AppAnimations.reverseCurve,
    );
    return FadeTransition(
      opacity: incoming,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(incoming),
        child: child,
      ),
    );
  }
}
