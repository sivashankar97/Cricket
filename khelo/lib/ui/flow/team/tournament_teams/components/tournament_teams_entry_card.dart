import 'package:flutter/cupertino.dart';
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
        decoration: cs.cardDecoration(radius: 12).copyWith(
              border: Border.all(color: cs.outline, width: 0.5),
            ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(CupertinoIcons.person_3_fill, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.tournament_teams_title,
                    style:
                        AppTextStyle.subtitle1.copyWith(color: cs.textPrimary),
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
            Icon(CupertinoIcons.chevron_right, color: cs.textDisabled),
          ],
        ),
      ),
    );
  }
}
