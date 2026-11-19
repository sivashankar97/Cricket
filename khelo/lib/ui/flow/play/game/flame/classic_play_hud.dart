import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/play/cricket_game.dart';

/// Stick Sports–style top chrome (matched to Stick Cricket PL web game).
/// Mid-field SIXES/STREAK is drawn inside the Flame arena.
class ClassicPlayHud extends StatelessWidget {
  final Innings innings;
  final String batterName;
  final VoidCallback onClose;
  final VoidCallback? onRestart;
  final List<Widget> trailing;

  const ClassicPlayHud({
    super.key,
    required this.innings,
    required this.batterName,
    required this.onClose,
    this.onRestart,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          _pill(
            child: Text(
              '${innings.runs}/${innings.wickets}  ·  ${oversText(innings.balls)} ov',
              style: const TextStyle(
                color: Color(0xFFFFEB3B),
                fontWeight: FontWeight.w900,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const Spacer(),
          _chromeBtn(
            icon: CupertinoIcons.arrow_clockwise,
            label: 'RESTART',
            onTap: onRestart ?? onClose,
          ),
          _chromeBtn(
            icon: CupertinoIcons.xmark,
            label: 'EXIT',
            onTap: onClose,
            accent: const Color(0xFFE53935),
          ),
          ...trailing,
        ],
      ),
    );
  }

  Widget _pill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEE000000),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }

  Widget _chromeBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color accent = Colors.white,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: accent),
      label: Text(
        label,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: accent,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
