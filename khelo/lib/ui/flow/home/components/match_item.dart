import 'package:data/api/match/match_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:khelo/components/tournament_badge.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart'; // needed for .card getter on AppColorScheme

import '../../../../components/image_avatar.dart';
import '../../../../domain/formatter/date_formatter.dart';
import '../../../app_route.dart';

/// iOS-style match card for the home screen horizontal scroll list.
///
/// White card on grouped background, 12pt radius, no shadow.
/// Width 320pt — slightly narrower for better glimpse of next card.
class MatchItem extends StatelessWidget {
  final MatchModel match;

  const MatchItem({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: () => AppRoute.matchDetailTab(matchId: match.id).push(context),
      child: MediaQuery.withNoTextScaling(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: cs.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _matchMetaRow(context),
              const SizedBox(height: 16),
              _teamRow(context, match.teams.first,
                  match.teams.elementAt(1).wicket),
              const SizedBox(height: 10),
              _teamRow(context, match.teams.elementAt(1),
                  match.teams.first.wicket),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(BuildContext context, MatchTeamModel team, int wicket) {
    final cs = context.colorScheme;
    return Row(
      children: [
        ImageAvatar(
          initial:
              team.team.name_initial ?? team.team.name.initials(limit: 1),
          imageUrl: team.team.profile_img_url,
          size: 28,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            team.team.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTextStyle.subtitle3.copyWith(color: cs.textPrimary),
          ),
        ),
        if (team.over != 0)
          Text.rich(
            TextSpan(
              text: '${team.run}-$wicket',
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
              children: [
                TextSpan(
                  text: ' (${team.over})',
                  style:
                      AppTextStyle.caption.copyWith(color: cs.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _matchMetaRow(BuildContext context) {
    final cs = context.colorScheme;
    return Row(
      children: [
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
              style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    height: 3,
                    width: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.textDisabled,
                    ),
                  ),
                ),
                TextSpan(
                  text: match.ground,
                  style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
