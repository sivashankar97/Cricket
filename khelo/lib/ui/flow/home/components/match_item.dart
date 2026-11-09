import 'package:data/api/match/match_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:khelo/components/tournament_badge.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart'; // needed for .card getter on AppColorScheme

import '../../../../components/image_avatar.dart';
import '../../../../domain/formatter/date_formatter.dart';
import '../../../app_route.dart';

/// Compact Home card for upcoming and finished matches: both teams side by
/// side, the start time (or scores) in the middle and the ground or result
/// at the bottom. Running matches use `LiveMatchCard`.
class MatchItem extends StatelessWidget {
  static const width = 250.0;

  final MatchModel match;

  const MatchItem({
    super.key,
    required this.match,
  });

  bool get _upcoming => match.match_status == MatchStatus.yetToStart;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: () => AppRoute.matchDetailTab(matchId: match.id).push(context),
      child: MediaQuery.withNoTextScaling(
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: cs.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: cs.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _side(context, match.teams.first)),
                  _middle(context),
                  Expanded(child: _side(context, match.teams.elementAt(1))),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: cs.outline),
              const SizedBox(height: 8),
              _footer(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final cs = context.colorScheme;
    return Row(
      children: [
        if (match.tournament_id != null) ...[
          const TournamentBadge(),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            context.l10n.home_match_overs(match.number_of_over),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
          ),
        ),
        if (!_upcoming)
          Text(
            match.match_status.getString(context),
            style: AppTextStyle.caption.copyWith(
              color: cs.textDisabled,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _side(BuildContext context, MatchTeamModel team) {
    final cs = context.colorScheme;
    final opponent = match.teams.firstWhere(
      (t) => t.team_id != team.team_id,
      orElse: () => team,
    );
    return Column(
      children: [
        ImageAvatar(
          initial: team.team.name_initial ?? team.team.name.initials(limit: 1),
          imageUrl: team.team.profile_img_url,
          size: 40,
        ),
        const SizedBox(height: 6),
        Text(
          team.team.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyle.caption.copyWith(
            color: cs.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!_upcoming && team.over > 0)
          Text(
            '${team.run}/${opponent.wicket} (${team.over})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.caption.copyWith(
              color: cs.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _middle(BuildContext context) {
    final cs = context.colorScheme;
    final start = (match.start_at ?? match.start_time)?.toLocal();
    if (!_upcoming || start == null) {
      return Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.containerLow,
          shape: BoxShape.circle,
        ),
        child: Text(
          'VS',
          style: AppTextStyle.caption.copyWith(
            color: cs.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            _dayLabel(context, start),
            style: AppTextStyle.caption.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            start.format(context, DateFormatType.time),
            style: AppTextStyle.subtitle3.copyWith(
              color: cs.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(BuildContext context, DateTime start) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(start.year, start.month, start.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return context.l10n.home_today;
    if (diff == 1) return context.l10n.home_tomorrow;
    return start.format(context, DateFormatType.dayMonth);
  }

  Widget _footer(BuildContext context) {
    final cs = context.colorScheme;
    final result = match.toss_winner_id == null ? null : match.matchResult;
    if (!_upcoming && result != null) {
      final text = result.winType == WinnerByType.tie
          ? context.l10n.score_board_match_tied
          : context.l10n.home_result_won_by(
              result.teamName,
              result.winType.getString(context, result.difference),
            );
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTextStyle.caption.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.location_solid, size: 12, color: cs.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            match.ground,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
          ),
        ),
      ],
    );
  }
}
