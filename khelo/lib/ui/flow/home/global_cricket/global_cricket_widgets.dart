import 'package:data/api/global_cricket/global_cricket_models.dart';
import 'package:flutter/material.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

extension GlobalMatchCategoryText on GlobalMatchCategory {
  String label(BuildContext context) => switch (this) {
        GlobalMatchCategory.international =>
          context.l10n.global_cricket_international,
        GlobalMatchCategory.league => context.l10n.global_cricket_leagues,
      };
}

extension GlobalMatchText on GlobalMatch {
  /// Result / live text from the API, or the local start time for fixtures.
  String statusText(BuildContext context) => isUpcoming && startTime != null
      ? context.l10n.global_cricket_starts(
          startTime!.format(context, DateFormatType.dateAndTime),
        )
      : status;
}

/// Match card: series line, both teams with flag and score, status.
/// Fixed [width] for horizontal Home rows; full width in lists.
class GlobalMatchCard extends StatelessWidget {
  final GlobalMatch match;
  final double? width;
  final EdgeInsets margin;

  const GlobalMatchCard({
    super.key,
    required this.match,
    this.width,
    this.margin = const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: () => AppRoute.globalCricketMatch(match).push(context),
      child: Container(
        width: width,
        margin: margin,
        padding: const EdgeInsets.all(14),
        decoration: cs.cardDecoration(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (match.isLive) ...[
                  const GlobalLiveBadge(),
                  const SizedBox(width: 6),
                ],
                if (match.matchType.isNotEmpty) ...[
                  Text(
                    match.matchType.toUpperCase(),
                    style: AppTextStyle.caption.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    match.series,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyle.caption.copyWith(color: cs.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _teamRow(context, match.team1, match.score1),
            _teamRow(context, match.team2, match.score2),
            const SizedBox(height: 2),
            Text(
              match.statusText(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.caption.copyWith(
                color: match.isLive ? brandRedDeepColor : cs.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamRow(BuildContext context, GlobalTeam team, String score) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GlobalTeamFlag(team: team),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              team.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subtitle2.copyWith(
                color: cs.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (score.isNotEmpty)
            Text(
              score,
              style: AppTextStyle.subtitle3.copyWith(
                color: cs.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class GlobalTeamFlag extends StatelessWidget {
  final GlobalTeam team;
  final double size;

  const GlobalTeamFlag({super.key, required this.team, this.size = 28});

  @override
  Widget build(BuildContext context) => ImageAvatar(
        size: size,
        initial: team.initial,
        imageUrl: team.imageUrl.isEmpty ? null : team.imageUrl,
        backgroundColor: context.colorScheme.containerLowOnSurface,
      );
}

class GlobalLiveBadge extends StatelessWidget {
  const GlobalLiveBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: brandRedColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          context.l10n.home_global_cricket_live,
          style: AppTextStyle.caption.copyWith(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

/// Row of pill filters, the selected one filled with the primary colour.
class GlobalFilterPills<T> extends StatelessWidget {
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const GlobalFilterPills({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in options.entries)
          OnTapScale(
            onTap: () => onSelected(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: entry.key == selected ? cs.primary : cs.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: entry.key == selected ? null : cs.cardShadow,
              ),
              child: Text(
                entry.value,
                style: AppTextStyle.subtitle3.copyWith(
                  color: entry.key == selected ? cs.onPrimary : cs.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
