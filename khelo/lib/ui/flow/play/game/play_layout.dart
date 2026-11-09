import 'dart:math';

import 'package:flutter/material.dart';

/// Screen-size rules shared by the Play game and match screens.
class PlayLayout {
  /// Widest the game column gets on tablets and desktop.
  static const maxGameWidth = 600.0;

  /// Widest a panel (lobby, toss, result) gets.
  static const maxPanelWidth = 480.0;

  /// Short and wide, e.g. a phone held sideways or a small browser window.
  static bool isLandscape(Size size) =>
      size.width > size.height * 1.15 && size.height < 560;

  /// Small phones (iPhone SE, older Androids).
  static bool isSmall(Size size) => size.width < 360 || size.height < 600;

  /// Scales sizes designed for a 390 px wide phone: smaller on small
  /// phones, a little bigger on tablets.
  static double scale(Size size) =>
      (min(size.width, size.height * 0.62) / 390).clamp(0.78, 1.2);
}

/// The batting screen layout: top bar, optional banners, scoreboard and
/// arena stacked on phones; side by side when the screen is short and wide.
/// On tablets and desktop the stadium spans the full width under a centred
/// scoreboard.
class PlayArenaLayout extends StatelessWidget {
  static const _skyColor = Color(0xFF060B1F);

  final Widget topBar;
  final List<Widget> banners;
  final Widget scoreboard;
  final Widget arena;

  const PlayArenaLayout({
    super.key,
    required this.topBar,
    this.banners = const [],
    required this.scoreboard,
    required this.arena,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (PlayLayout.isLandscape(size)) {
      final side = (size.width * 0.36).clamp(250.0, 340.0);
      return Row(
        children: [
          SizedBox(
            width: side,
            child: SingleChildScrollView(
              child: Column(children: [topBar, ...banners, scoreboard]),
            ),
          ),
          Expanded(child: arena),
        ],
      );
    }
    if (size.width <= PlayLayout.maxGameWidth + 1) {
      return Column(
        children: [topBar, ...banners, scoreboard, Expanded(child: arena)],
      );
    }
    return ColoredBox(
      color: _skyColor,
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: PlayLayout.maxGameWidth),
              child: Column(children: [topBar, ...banners, scoreboard]),
            ),
          ),
          Expanded(child: arena),
        ],
      ),
    );
  }
}
