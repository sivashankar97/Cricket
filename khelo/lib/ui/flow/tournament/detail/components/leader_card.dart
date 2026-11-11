import 'package:flutter/material.dart';
import 'package:style/animations/motion.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

import '../summary/tournament_summary.dart';
import 'tournament_widgets.dart';

/// Navy card highlighting the leader of one stat, e.g. "Most runs".
class LeaderCard extends StatelessWidget {
  final String title;
  final SummaryPlayer player;
  final num value;
  final int decimals;
  final String unit;
  final String? detail;
  final double? width;

  const LeaderCard({
    super.key,
    required this.title,
    required this.player,
    required this.value,
    required this.unit,
    this.decimals = 0,
    this.detail,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.7);
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandNavyColor, Color(0xFF1B1B5E)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -46,
            top: -46,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandRedColor.withValues(alpha: 0.28),
              ),
            ),
          ),
          MediaQuery.withNoTextScaling(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTextStyle.caption.copyWith(
                    color: brandRedColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    PlayerAvatar(player, size: 44, onDark: true),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.user.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.subtitle1
                                .copyWith(color: Colors.white),
                          ),
                          Text(
                            [
                              teamShortName(player.team),
                              if (detail != null) detail!
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.caption.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CountUp(
                          value: value,
                          decimals: decimals,
                          style: AppTextStyle.header1
                              .copyWith(color: Colors.white, height: 1),
                        ),
                        Text(unit,
                            style: AppTextStyle.caption.copyWith(color: muted)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
