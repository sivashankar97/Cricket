import 'package:data/api/match/match_model.dart';
import 'package:data/api/tournament/tournament_extras.dart';
import 'package:flutter/material.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

import 'tournament_widgets.dart';

class TournamentMatchCard extends StatelessWidget {
  final MatchModel match;
  final int number;
  final Map<String, MatchExtras> extras;
  final VoidCallback onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TournamentMatchCard({
    super.key,
    required this.match,
    required this.number,
    required this.extras,
    required this.onTap,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final walkover = extras[match.id]?.walkoverWinnerId != null;
    final winner = matchWinnerId(match, extras);
    final result = matchResultText(context, match, extras);
    final (label, color) = switch (match.match_status) {
      MatchStatus.running => (context.l10n.tournament_live_pill, cs.alert),
      MatchStatus.yetToStart => (
          context.l10n.tournament_upcoming_pill,
          cs.warning
        ),
      MatchStatus.finish => (context.l10n.tournament_result_pill, cs.positive),
      MatchStatus.abandoned => walkover
          ? (context.l10n.tournament_walkover_pill, cs.textSecondary)
          : (context.l10n.tournament_no_result_pill, cs.textSecondary),
    };
    final played = match.match_status == MatchStatus.finish ||
        match.match_status == MatchStatus.running;

    return OnTapScale(
      onTap: onTap,
      child: TournamentCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${context.l10n.tournament_match_number(number)} · '
                    '${matchStageOf(context, match, extras)}',
                    style: AppTextStyle.caption.copyWith(
                      color: cs.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusPill(
                  label,
                  color: color,
                  dot: match.match_status == MatchStatus.running,
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final (i, side) in _battingOrder(match).indexed) ...[
              if (i > 0) const SizedBox(height: 10),
              _teamRow(context, match, side, played, winner),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: cs.outline),
            const SizedBox(height: 10),
            if (result != null)
              Text(
                result,
                style: AppTextStyle.subtitle3.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              [
                if (match.ground.trim().isNotEmpty) match.ground.trim(),
                if (match.start_at != null)
                  match.start_at!.format(context, DateFormatType.shortDateTime),
              ].join(' · '),
              style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OnTapScale(
                onTap: onAction,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: match.match_status == MatchStatus.running
                        ? cs.primary
                        : cs.containerLowOnSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTextStyle.subtitle3.copyWith(
                      color: match.match_status == MatchStatus.running
                          ? cs.onPrimary
                          : cs.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _teamRow(
    BuildContext context,
    MatchModel match,
    MatchTeamModel side,
    bool played,
    String? winner,
  ) {
    final cs = context.colorScheme;
    final other = match.teams.firstWhere((t) => t != side, orElse: () => side);
    final isWinner = winner == side.team_id;
    final batted = side.over > 0 || side.run > 0;
    final emphasis = winner == null || isWinner;
    return Row(
      children: [
        TeamBadge(side.team, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            side.team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.subtitle2.copyWith(
              color: emphasis ? cs.textPrimary : cs.textSecondary,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (played && batted) ...[
          Text(
            '${side.run}/${other.wicket}',
            style: AppTextStyle.subtitle1.copyWith(
              color: emphasis ? cs.textPrimary : cs.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.tournament_overs_short(_overs(side.over)),
            style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
          ),
        ],
        if (isWinner) ...[
          const SizedBox(width: 6),
          Icon(Icons.emoji_events_rounded, size: 16, color: cs.primary),
        ],
      ],
    );
  }

  static List<MatchTeamModel> _battingOrder(MatchModel match) {
    final toss = match.toss_winner_id;
    if (toss == null ||
        match.toss_decision == null ||
        match.teams.length != 2) {
      return match.teams;
    }
    final batsFirst = match.toss_decision == TossDecision.bat
        ? match.teams.where((t) => t.team.id == toss).firstOrNull
        : match.teams.where((t) => t.team.id != toss).firstOrNull;
    if (batsFirst == null) return match.teams;
    return [batsFirst, ...match.teams.where((t) => t != batsFirst)];
  }

  static String _overs(double overs) =>
      overs == overs.roundToDouble() ? overs.toInt().toString() : '$overs';
}
