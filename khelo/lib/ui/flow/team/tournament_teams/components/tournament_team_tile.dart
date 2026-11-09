import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:flutter/material.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart';

/// Card row for a [TournamentTeam]: logo, name, short code and player count.
class TournamentTeamTile extends StatelessWidget {
  final TournamentTeam team;
  final Widget? leading;
  final Widget? trailing;
  final String? caption;
  final bool highlighted;
  final VoidCallback? onTap;

  const TournamentTeamTile({
    super.key,
    required this.team,
    this.leading,
    this.trailing,
    this.caption,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final details = [
      if (team.shortName != null) team.shortName!,
      context.l10n.tournament_teams_player_count(team.playerCount),
      if (caption != null) caption!,
    ].join(' · ');

    return OnTapScale(
      onTap: onTap,
      enabled: onTap != null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: cs.cardDecoration(radius: 12).copyWith(
              border: Border.all(
                color: highlighted ? cs.primary : cs.outline,
                width: highlighted ? 1.5 : 0.5,
              ),
            ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            ImageAvatar(
              initial: team.shortName ?? team.name.initials(limit: 1),
              imageUrl: team.logo,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subtitle1
                        .copyWith(color: cs.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyle.caption.copyWith(color: cs.textSecondary),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
