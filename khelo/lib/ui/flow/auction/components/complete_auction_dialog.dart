import 'package:data/api/auction/auction_models.dart';
import 'package:data/service/auction/auction_service.dart';
import 'package:flutter/material.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

import 'auction_widgets.dart';

/// Confirms completing the auction and generating its tournament.
/// Returns the tournament id on success.
Future<String?> showCompleteAuctionDialog(
  BuildContext context, {
  required Auction auction,
  required AuctionService service,
  required String userId,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _CompleteAuctionDialog(
        auction: auction,
        service: service,
        userId: userId,
      ),
    );

class _CompleteAuctionDialog extends StatefulWidget {
  final Auction auction;
  final AuctionService service;
  final String userId;

  const _CompleteAuctionDialog({
    required this.auction,
    required this.service,
    required this.userId,
  });

  @override
  State<_CompleteAuctionDialog> createState() => _CompleteAuctionDialogState();
}

class _CompleteAuctionDialogState extends State<_CompleteAuctionDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _complete() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await widget.service.completeAndGenerateTournament(
        widget.auction.id,
        widget.userId,
        markRemainingUnsold: true,
      );
      if (mounted) Navigator.of(context).pop(id);
    } on AuctionActionException catch (e) {
      if (mounted) setState(() => _error = e.error.label(context));
    } catch (e) {
      if (mounted) setState(() => _error = context.l10n.error_something_went_wrong);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final auction = widget.auction;
    final check = auction.completionCheck;
    final retry = auction.status == AuctionStatus.completed;
    final style = AppTextStyle.body2.copyWith(color: cs.textPrimary);
    return AlertDialog(
      backgroundColor: cs.surface,
      title: Text(retry
          ? context.l10n.auction_create_tournament_retry
          : context.l10n.auction_complete,),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              retry
                  ? context.l10n.auction_create_tournament_retry_message(
                      auction.tournamentName,
                      auction.teams.length,
                    )
                  : context.l10n.auction_complete_message(
                      auction.tournamentName,
                      auction.teams.length,
                    ),
              style: style,
            ),
            const SizedBox(height: 12),
            for (final team in auction.teams)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    AuctionTeamBadge(auction: auction, team: team, size: 24),
                    const SizedBox(width: 8),
                    Expanded(child: Text(team.name, style: style)),
                    Text(
                      context.l10n.auction_players_count(
                          auction.squadOf(team.id).length,),
                      style: AppTextStyle.caption
                          .copyWith(color: cs.textSecondary),
                    ),
                  ],
                ),
              ),
            if (!retry && check.availableLeft > 0) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n.auction_complete_left(check.availableLeft),
                style: AppTextStyle.caption.copyWith(color: cs.warning),
              ),
            ],
            if (!retry && check.playerInAuction) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n.auction_complete_blocked,
                style: AppTextStyle.caption.copyWith(color: cs.alert),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: AppTextStyle.caption.copyWith(color: cs.alert),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.common_cancel_title),
        ),
        PrimaryButton(
          retry
              ? context.l10n.auction_create_tournament_retry
              : context.l10n.auction_complete_confirm,
          expanded: false,
          progress: _saving,
          enabled: retry || !check.hasBlockingIssues,
          onPressed: _complete,
        ),
      ],
    );
  }
}
