import 'package:flutter/material.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart';

/// Card row for a team pool: logo or initials, name, team and player counts.
class TeamPoolTile extends StatelessWidget {
  final String name;
  final String? shortName;
  final String? logo;
  final int teamCount;
  final int playerCount;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;

  const TeamPoolTile({
    super.key,
    required this.name,
    this.shortName,
    this.logo,
    required this.teamCount,
    required this.playerCount,
    this.description,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final details = [
      context.l10n.team_pools_team_count(teamCount),
      context.l10n.tournament_teams_player_count(playerCount),
    ].join(' · ');

    return Semantics(
      button: onTap != null,
      label: name,
      child: OnTapScale(
        onTap: onTap,
        enabled: onTap != null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: cs.cardDecoration(radius: 12).copyWith(
                border: Border.all(color: cs.outline, width: 0.5),
              ),
          child: Row(
            children: [
              ImageAvatar(
                initial: shortName ?? name.initials(limit: 2),
                imageUrl: logo,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
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
                      style: AppTextStyle.caption
                          .copyWith(color: cs.textSecondary),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.caption
                            .copyWith(color: cs.textDisabled),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
