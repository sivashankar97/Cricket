import 'package:flutter/cupertino.dart';
import 'package:khelo/components/grouped_list.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart';

/// Shortcut shown at the top of the Teams tab that opens Tournament Teams.
class TournamentTeamsEntryCard extends StatelessWidget {
  const TournamentTeamsEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: () => AppRoute.tournamentTeams.push(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cs.cardDecoration(radius: 18),
        child: Row(
          children: [
            const BrandIconThumb(CupertinoIcons.person_3_fill, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.tournament_teams_title,
                    style: AppTextStyle.subtitle1.copyWith(
                      color: cs.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.tournament_teams_entry_description,
                    style:
                        AppTextStyle.caption.copyWith(color: cs.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_forward,
                size: 15, color: cs.textDisabled),
          ],
        ),
      ),
    );
  }
}
