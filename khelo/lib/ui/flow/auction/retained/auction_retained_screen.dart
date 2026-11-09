import 'package:data/api/auction/auction_models.dart';
import 'package:data/service/auction/auction_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart';

import '../auction_providers.dart';
import '../components/auction_widgets.dart';
import '../components/pick_auction_player_sheet.dart';
import '../players/auction_players_screen.dart';

/// Assign retained players to teams before the auction starts.
class AuctionRetainedScreen extends ConsumerStatefulWidget {
  final String auctionId;

  const AuctionRetainedScreen({super.key, required this.auctionId});

  @override
  ConsumerState<AuctionRetainedScreen> createState() =>
      _AuctionRetainedScreenState();
}

class _AuctionRetainedScreenState extends ConsumerState<AuctionRetainedScreen> {
  bool _busy = false;

  AuctionService get _service => ref.read(auctionServiceProvider);

  String get _userId => ref.read(currentUserPod)?.id ?? '';

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on AuctionActionException catch (e) {
      if (mounted) showSnackBar(context, e.error.label(context));
    } catch (e) {
      if (mounted) showErrorSnackBar(context: context, error: e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auction = ref.watch(auctionProvider(widget.auctionId)).valueOrNull;
    if (auction == null) {
      return const AppPage(body: Center(child: AppProgressIndicator()));
    }
    final cs = context.colorScheme;
    final editable = auction.status.isSetup;
    return AppPage(
      title: context.l10n.auction_retained_title,
      body: ListView(
        padding: context.mediaQueryPadding +
            const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          Text(
            editable
                ? context.l10n.auction_retained_help
                : context.l10n.auction_error_not_editable,
            style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          for (final team in auction.teams)
            _teamCard(context, auction, team, editable),
        ],
      ),
    );
  }

  Widget _teamCard(
    BuildContext context,
    Auction auction,
    AuctionTeam team,
    bool editable,
  ) {
    final cs = context.colorScheme;
    final retained = auction
        .squadOf(team.id)
        .where((p) => p.status == AuctionPlayerStatus.retained)
        .toList();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: cs.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AuctionTeamBadge(auction: auction, team: team),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: AppTextStyle.subtitle1.copyWith(
                        color: cs.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      context.l10n.auction_budget_line(
                        auction.spentBy(team.id),
                        auction.remainingFor(team),
                        team.budget,
                      ),
                      style: AppTextStyle.caption
                          .copyWith(color: cs.textSecondary),
                    ),
                  ],
                ),
              ),
              if (editable)
                TextButton.icon(
                  onPressed: _busy ? null : () => _retain(auction, team),
                  icon: const Icon(CupertinoIcons.add, size: 16),
                  label: Text(context.l10n.auction_retain_add),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (retained.isEmpty)
            Text(
              context.l10n.auction_retained_none,
              style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
            ),
          for (final player in retained)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AuctionPhoto.player(player),
              title: Text(
                player.name,
                style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
              ),
              subtitle: Text(
                playerDetails(context, player, team: team),
                style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
              ),
              trailing: editable
                  ? TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() => _service.release(
                              auction.id, _userId, player.id,),),
                      child: Text(
                        context.l10n.auction_release,
                        style: TextStyle(color: cs.alert),
                      ),
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  Future<void> _retain(Auction auction, AuctionTeam team) async {
    final player = await showPickAuctionPlayerSheet(
      context,
      players: auction.playersWith(AuctionPlayerStatus.available),
    );
    if (player == null || !mounted) return;
    final controller = TextEditingController(text: '${player.basePrice}');
    final price = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colorScheme.surface,
        title: Text('${player.name} → ${team.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: controller,
              label: context.l10n.auction_retain_price,
              autoFocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              borderType: AppTextFieldBorderType.outline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.common_cancel_title),
          ),
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(int.tryParse(controller.text.trim()) ?? 0),
            child: Text(context.l10n.auction_retain_add),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
    if (price == null) return;
    await _run(() => _service.retain(
          auctionId: auction.id,
          userId: _userId,
          playerId: player.id,
          teamId: team.id,
          price: price,
        ),);
  }
}
