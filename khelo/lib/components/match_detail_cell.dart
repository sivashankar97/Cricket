import 'package:collection/collection.dart';
import 'package:data/api/match/match_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/components/match_status_tag.dart';
import 'package:khelo/components/tournament_badge.dart';
import 'package:khelo/components/won_by_message_text.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/theme/shadows.dart';
import 'package:style/text/app_text_style.dart';

/// iOS-style match card.
///
/// Uses a white rounded card on the systemGroupedBackground.
/// Inner content follows iOS list-row spacing (16pt edges, 12pt row gaps).
/// Divider is a 0.5pt hairline at 100% width — no indent.
class MatchDetailCell extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;
  final bool showStatusTag;
  final bool showTournamentBadge;
  final bool showActionButtons;
  final VoidCallback? onActionTap;
  final Color? backgroundColor;

  const MatchDetailCell({
    super.key,
    required this.match,
    required this.onTap,
    this.showStatusTag = true,
    this.showActionButtons = false,
    this.showTournamentBadge = true,
    this.backgroundColor,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? cs.card,
          borderRadius: BorderRadius.circular(12),
          // iOS: no shadow — background separation does the work
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _matchTimeAndGroundView(context),
            const SizedBox(height: 14),
            ...match.teams.map(
              (team) => _teamRow(
                context,
                team,
                wicketsLost: match.teams
                        .firstWhereOrNull((e) => e.team_id != team.team_id)
                        ?.wicket ??
                    0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Container(
                height: 0.5,
                color: cs.outline,
              ),
            ),
            Row(
              children: [
                Expanded(child: _winnerMessageText(context)),
                if (showStatusTag)
                  StatusTag(
                    matchStatus: match.match_status,
                    onTap: showActionButtons &&
                            match.match_status != MatchStatus.finish &&
                            match.match_status != MatchStatus.abandoned
                        ? onActionTap
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchTimeAndGroundView(BuildContext context) {
    final cs = context.colorScheme;
    return Row(
      children: [
        if (showTournamentBadge && match.tournament_id != null) ...[
          TournamentBadge(),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 2,
          child: Text(
            (match.start_at ?? match.start_time ?? DateTime.now())
                .format(context, DateFormatType.dateAndTime),
            style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.location,
              size: 13,
              color: cs.textDisabled,
            ),
            const SizedBox(width: 3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                match.ground,
                style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _teamRow(
    BuildContext context,
    MatchTeamModel matchTeam, {
    required int wicketsLost,
  }) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ImageAvatar(
            initial: matchTeam.team.name.characters.first.toUpperCase(),
            imageUrl: matchTeam.team.profile_img_url,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              matchTeam.team.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
            ),
          ),
          if (!(matchTeam.run == 0 && wicketsLost == 0 && matchTeam.over == 0))
            Text.rich(
              TextSpan(
                text: '${matchTeam.run}-$wicketsLost',
                style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
                children: [
                  TextSpan(
                    text: '  (${matchTeam.over})',
                    style: AppTextStyle.caption
                        .copyWith(color: cs.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _winnerMessageText(BuildContext context) {
    if (match.match_status == MatchStatus.finish) {
      return WonByMessageText(matchResult: match.matchResult);
    } else {
      return Text(
        '${match.match_type.getString(context)} '
        '${context.l10n.match_list_overs_title(match.number_of_over)}',
        style: AppTextStyle.caption.copyWith(
          color: context.colorScheme.textSecondary,
        ),
      );
    }
  }
}
