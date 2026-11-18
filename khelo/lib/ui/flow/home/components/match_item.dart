import 'package:data/api/match/match_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

/// Modern match card matching the reference design for upcoming & recent results:
/// Trophy header with overs, team avatars with 'vs', scores, and prominent
/// pink winner banner at the bottom.
class MatchItem extends StatelessWidget {
  static const width = 270.0;

  final MatchModel match;

  const MatchItem({
    super.key,
    required this.match,
  });

  bool get _upcoming => match.match_status == MatchStatus.yetToStart;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final team1 = match.teams.first;
    final team2 = match.teams.elementAt(1);

    return OnTapScale(
      onTap: () => AppRoute.matchDetailTab(matchId: match.id).push(context),
      child: MediaQuery.withNoTextScaling(
        child: Container(
          width: width,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: cs.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: cs.cardShadow,
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const SizedBox(height: 12),
              _avatarsRow(context, team1, team2),
              const SizedBox(height: 10),
              _scoresRow(context, team1, team2),
              const SizedBox(height: 12),
              _resultBanner(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final cs = context.colorScheme;
    final start = (match.start_at ?? match.start_time)?.toLocal();
    final statusText = _upcoming
        ? (start != null ? _dayLabel(context, start) : 'Upcoming')
        : match.match_status.getString(context);

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFFFFEEED),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            CupertinoIcons.sportscourt_fill,
            size: 13,
            color: brandRedColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.l10n.home_match_overs(match.number_of_over),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.caption.copyWith(
              color: cs.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          statusText,
          style: AppTextStyle.caption.copyWith(
            color: _upcoming ? cs.primary : cs.textDisabled,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _avatarsRow(
    BuildContext context,
    MatchTeamModel team1,
    MatchTeamModel team2,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEDE9FE),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: ImageAvatar(
            initial:
                team1.team.name_initial ?? team1.team.name.initials(limit: 2),
            imageUrl: team1.team.profile_img_url,
            size: 34,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: context.colorScheme.containerLowOnSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'vs',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.colorScheme.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFEF3C7),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: ImageAvatar(
            initial:
                team2.team.name_initial ?? team2.team.name.initials(limit: 2),
            imageUrl: team2.team.profile_img_url,
            size: 34,
          ),
        ),
      ],
    );
  }

  Widget _scoresRow(
    BuildContext context,
    MatchTeamModel team1,
    MatchTeamModel team2,
  ) {
    final cs = context.colorScheme;
    final start = (match.start_at ?? match.start_time)?.toLocal();

    if (_upcoming && start != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              team1.team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyle.subtitle3.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              start.format(context, DateFormatType.time),
              style: AppTextStyle.caption.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              team2.team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyle.subtitle3.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.textPrimary,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                team1.team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyle.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${team1.run}/${team2.wicket} (${team1.over})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption.copyWith(
                  color: cs.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Text(
                team2.team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyle.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${team2.run}/${team1.wicket} (${team2.over})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption.copyWith(
                  color: cs.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultBanner(BuildContext context) {
    final result = match.toss_winner_id == null ? null : match.matchResult;
    String bannerText;

    if (!_upcoming && result != null) {
      bannerText = result.winType == WinnerByType.tie
          ? context.l10n.score_board_match_tied
          : context.l10n.home_result_won_by(
              result.teamName,
              result.winType.getString(context, result.difference),
            );
    } else if (match.ground.trim().isNotEmpty) {
      bannerText = match.ground.trim();
    } else {
      bannerText = match.city;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        bannerText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFDC2626),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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
}
