import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/confirmation_dialog.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

/// Asks to delete [tournamentName]. When [pool] is given, offers to delete it
/// and its teams too. Returns null when cancelled, otherwise whether to delete
/// the pool.
Future<bool?> showDeleteTournamentDialog(
  BuildContext context, {
  required String tournamentName,
  TeamPool? pool,
}) {
  var withPool = pool != null;
  return showAdaptiveDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog.adaptive(
        surfaceTintColor: context.colorScheme.containerNormalOnSurface,
        title: Text(context.l10n.tournament_delete_title(tournamentName)),
        content: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.tournament_delete_message),
              if (pool != null) ...[
                const SizedBox(height: 12),
                CheckboxListTile.adaptive(
                  value: withPool,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) =>
                      setState(() => withPool = value ?? false),
                  title: Text(
                    context.l10n.tournament_delete_with_pool(pool.name),
                    style: AppTextStyle.body2
                        .copyWith(color: context.colorScheme.textPrimary),
                  ),
                  subtitle: Text(
                    context.l10n.tournament_delete_pool_note,
                    style: AppTextStyle.caption
                        .copyWith(color: context.colorScheme.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          adaptiveAction(
            context,
            onPressed: () => context.pop(),
            child: Text(context.l10n.common_cancel_title),
          ),
          adaptiveAction(
            context,
            isDestructiveAction: true,
            onPressed: () => context.pop(withPool),
            child: Text(context.l10n.common_delete_title),
          ),
        ],
      ),
    ),
  );
}
