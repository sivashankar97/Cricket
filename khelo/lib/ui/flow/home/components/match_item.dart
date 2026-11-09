import 'package:data/api/match/match_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:khelo/components/tournament_badge.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart'; // needed for .card getter on AppColorScheme

import '../../../../components/image_avatar.dart';
import '../../../../domain/formatter/date_formatter.dart';
import '../../../app_route.dart';

/// Home-screen match card. Live matches use the pink-red hero gradient;
/// others are soft white (light) / indigo (dark) cards.
class MatchItem extends StatelessWidget {
  final MatchModel match;

  const MatchItem({
    super.key,
    required this.match,
  });

  bool get _isLive => match.match_status == MatchStatus.running;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final textColor = _isLive ? textPrimaryDarkColor : cs.textPrimary;
    final subColor = _isLive ? textSecondaryDarkColor : cs.textSecondary;

    return OnTapScale(
      onTap: () => AppRoute.matchDetailTab(matchId: match.id).push(context),
      child: MediaQuery.withNoTextScaling(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: _isLive ? null : cs.card,
            gradient: _isLive ? liveCardGradient : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isLive
                ? [
                    BoxShadow(
                      color: brandRedColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : cs.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _matchMetaRow(context, subColor),
              const SizedBox(height: 16),
              _teamRow(context, match.teams.first,
                  match.teams.elementAt(1).wicket, textColor, subColor),
              const SizedBox(height: 10),
              _teamRow(context, match.teams.elementAt(1),
                  match.teams.first.wicket, textColor, subColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(
    BuildContext context,
    MatchTeamModel team,
    int wicket,
    Color textColor,
    Color subColor,
  ) {
    return Row(
      children: [
        ImageAvatar(
          initial: team.team.name_initial ?? team.team.name.initials(limit: 1),
          imageUrl: team.team.profile_img_url,
          size: 30,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            team.team.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTextStyle.subtitle3.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (team.over != 0)
          Text.rich(
            TextSpan(
              text: '${team.run}-$wicket',
              style: (_isLive ? AppTextStyle.header4 : AppTextStyle.subtitle2)
                  .copyWith(color: textColor, fontWeight: FontWeight.w700),
              children: [
                TextSpan(
                  text: ' (${team.over})',
                  style: AppTextStyle.caption.copyWith(color: subColor),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _matchMetaRow(BuildContext context, Color subColor) {
    return Row(
      children: [
        if (_isLive) ...[
          _livePill(context),
          const SizedBox(width: 6),
        ],
        if (match.tournament_id != null) ...[
          TournamentBadge(),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text.rich(
            overflow: TextOverflow.ellipsis,
            TextSpan(
              text: (match.start_at ?? match.start_time)
                  ?.format(context, DateFormatType.dateAndTime),
              style: AppTextStyle.caption.copyWith(color: subColor),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    height: 3,
                    width: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: subColor,
                    ),
                  ),
                ),
                TextSpan(
                  text: match.ground,
                  style: AppTextStyle.caption.copyWith(color: subColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _livePill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: textPrimaryDarkColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: const BoxDecoration(
              color: positiveGreenColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.home_screen_live_title.toUpperCase(),
            style: AppTextStyle.caption.copyWith(
              color: brandRedDeepColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
