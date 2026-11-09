import 'package:data/api/auction/auction_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

import '../../team/tournament_teams/components/tournament_player_role_extension.dart';
import '../auction_providers.dart';
import '../auction_screen.dart';
import '../components/auction_action_runner.dart';
import '../components/auction_widgets.dart';
import '../components/complete_auction_dialog.dart';

/// The main auction screen: setup checklist before the start, the player on
/// the block with admin controls while live, and the result afterwards.
/// Everyone else sees the same screen read-only, updating in real time.
class AuctionLiveTab extends ConsumerStatefulWidget {
  final Auction auction;
  final bool isAdmin;

  const AuctionLiveTab({super.key, required this.auction, required this.isAdmin});

  @override
  ConsumerState<AuctionLiveTab> createState() => _AuctionLiveTabState();
}

class _AuctionLiveTabState extends ConsumerState<AuctionLiveTab>
    with AuctionActionRunner {
  Auction get auction => widget.auction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return ListView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 40 + context.mediaQueryPadding.bottom,),
          children: [
            if (auction.status.isSetup)
              widget.isAdmin ? _setupCard(context) : _upcomingCard(context)
            else if (auction.status == AuctionStatus.completed)
              _completedCard(context)
            else ...[
              if (auction.status == AuctionStatus.paused) _pausedBanner(context),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _stageColumn(context, wide)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _sideColumn(context)),
                  ],
                )
              else ...[
                _stageColumn(context, wide),
                const SizedBox(height: 16),
                _sideColumn(context),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _stageColumn(BuildContext context, bool wide) {
    final current = auction.currentPlayer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (current != null)
          _PlayerStage(auction: auction, player: current, wide: wide)
        else
          _allProcessedCard(context),
        if (widget.isAdmin && current != null) ...[
          const SizedBox(height: 14),
          _controls(context, current),
        ],
        if (!widget.isAdmin)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.dot_radiowaves_left_right,
                    size: 14, color: brandRedColor,),
                const SizedBox(width: 6),
                Text(
                  context.l10n.auction_view_only,
                  style: AppTextStyle.caption
                      .copyWith(color: context.colorScheme.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sideColumn(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _lastSold(context),
          _progressCard(context),
          const SizedBox(height: 14),
          _budgets(context),
        ],
      );

  // ── Setup / upcoming / completed ─────────────────────────────────────────

  Widget _setupCard(BuildContext context) {
    final cs = context.colorScheme;
    final retained = auction.playersWith(AuctionPlayerStatus.retained).length;
    Widget step(IconData icon, String label, bool done, VoidCallback onTap) =>
        ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
          leading: Icon(
            done ? CupertinoIcons.checkmark_circle_fill : icon,
            color: done ? positiveGreenColor : cs.primary,
          ),
          title: Text(label,
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),),
          trailing: Icon(CupertinoIcons.chevron_right,
              size: 16, color: cs.textDisabled,),
        );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cs.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.auction_setup_title,
                  style: AppTextStyle.header4.copyWith(
                      color: cs.textPrimary, fontWeight: FontWeight.w700,),
                ),
              ),
              AuctionStatusPill(status: auction.status),
            ],
          ),
          const SizedBox(height: 6),
          step(CupertinoIcons.doc_text, context.l10n.auction_setup_details,
              auction.teams.length >= 2,
              () => AppRoute.auctionForm(auction: auction).push(context),),
          step(
            CupertinoIcons.person_3,
            context.l10n.auction_setup_players(auction.players.length),
            auction.players.isNotEmpty,
            () => AppRoute.auctionPlayers(auction.id).push(context),
          ),
          step(
            CupertinoIcons.star,
            context.l10n.auction_setup_retained(retained),
            retained > 0,
            () => AppRoute.auctionRetained(auction.id).push(context),
          ),
          const SizedBox(height: 10),
          if (auction.status == AuctionStatus.draft) ...[
            Text(
              context.l10n.auction_publish_help,
              style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: auction.status == AuctionStatus.draft
                    ? _secondary(context, context.l10n.auction_publish,
                        () => run(() => service.publish(auction.id, userId)),)
                    : _secondary(context, context.l10n.auction_unpublish,
                        () => run(() => service.unpublish(auction.id, userId)),),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  context.l10n.auction_start,
                  progress: busy,
                  onPressed: () => run(() => service.start(auction.id, userId)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _upcomingCard(BuildContext context) {
    final cs = context.colorScheme;
    final date = auction.auctionDate;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cs.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date == null
                ? context.l10n.auction_not_started
                : context.l10n.auction_starts_on(DateFormat.yMMMEd().format(date)),
            style: AppTextStyle.header4
                .copyWith(color: cs.textPrimary, fontWeight: FontWeight.w700),
          ),
          if (auction.description != null) ...[
            const SizedBox(height: 8),
            Text(auction.description!,
                style: AppTextStyle.body2.copyWith(color: cs.textSecondary),),
          ],
          const SizedBox(height: 12),
          Text(
            context.l10n.auction_tile_summary(
                auction.teams.length, auction.players.length,),
            style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final team in auction.teams)
                Chip(
                  avatar: AuctionTeamBadge(auction: auction, team: team, size: 22),
                  label: Text(team.name),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _completedCard(BuildContext context) {
    final cs = context.colorScheme;
    final tournamentId = auction.tournamentId;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cs.cardDecoration(radius: 18),
      child: Column(
        children: [
          const Icon(CupertinoIcons.checkmark_seal_fill,
              size: 40, color: positiveGreenColor,),
          const SizedBox(height: 10),
          Text(
            context.l10n.auction_status_completed,
            style: AppTextStyle.header3.copyWith(color: cs.textPrimary),
          ),
          const SizedBox(height: 14),
          AuctionProgressBar(auction: auction),
          const SizedBox(height: 16),
          if (tournamentId != null) ...[
            Text(
              context.l10n.auction_tournament_created(auction.tournamentName),
              textAlign: TextAlign.center,
              style: AppTextStyle.subtitle1.copyWith(color: cs.textPrimary),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              context.l10n.auction_open_tournament,
              onPressed: () =>
                  AppRoute.tournamentDetail(tournamentId: tournamentId)
                      .push(context),
            ),
          ] else if (widget.isAdmin)
            PrimaryButton(
              context.l10n.auction_create_tournament_retry,
              onPressed: () => _complete(context),
            ),
        ],
      ),
    );
  }

  Widget _pausedBanner(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.pause_circle_fill, color: cs.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.auction_paused_banner,
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
            ),
          ),
          if (widget.isAdmin)
            TextButton(
              onPressed: () => run(() => service.resume(auction.id, userId)),
              child: Text(context.l10n.auction_resume),
            ),
        ],
      ),
    );
  }

  Widget _allProcessedCard(BuildContext context) {
    final cs = context.colorScheme;
    final unsold = auction.playersWith(AuctionPlayerStatus.unsold).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cs.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(CupertinoIcons.hammer_fill, size: 36, color: cs.primary),
          const SizedBox(height: 10),
          Text(
            context.l10n.auction_all_processed,
            textAlign: TextAlign.center,
            style: AppTextStyle.subtitle1.copyWith(color: cs.textPrimary),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(height: 16),
            if (unsold > 0) ...[
              PrimaryButton(
                context.l10n.auction_reopen_unsold(unsold),
                progress: busy,
                onPressed: () =>
                    run(() => service.reopenUnsold(auction.id, userId)),
              ),
              const SizedBox(height: 10),
            ],
            PrimaryButton(
              context.l10n.auction_complete,
              background: positiveGreenColor,
              foreground: brandNavyColor,
              onPressed: () => _complete(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _complete(BuildContext context) async {
    final id = await showCompleteAuctionDialog(
      context,
      auction: auction,
      service: service,
      userId: userId,
    );
    if (id != null && context.mounted) {
      showSnackBar(
        context,
        context.l10n.auction_tournament_created(auction.tournamentName),
      );
    }
  }

  // ── Admin controls ───────────────────────────────────────────────────────

  Widget _secondary(BuildContext context, String label, VoidCallback? onTap,
          {Color? color,}) =>
      OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: color ?? context.colorScheme.primary,
          side: BorderSide(
              color: (color ?? context.colorScheme.primary)
                  .withValues(alpha: 0.4),),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style: AppTextStyle.subtitle2.copyWith(fontWeight: FontWeight.w700),),
      );

  Widget _controls(BuildContext context, AuctionPlayer current) {
    final cs = context.colorScheme;
    final hasBids = auction.bids.isNotEmpty;
    final live = auction.status == AuctionStatus.live;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cs.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _secondary(
                  context,
                  '‹ ${context.l10n.auction_prev_player}',
                  live && !hasBids
                      ? () => run(() => service.previousPlayer(auction.id, userId))
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _secondary(
                  context,
                  '${context.l10n.auction_next_player} ›',
                  live && !hasBids
                      ? () => run(() => service.nextPlayer(auction.id, userId))
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: live ? context.l10n.auction_pause : context.l10n.auction_resume,
                onPressed: busy
                    ? null
                    : () => run(() => live
                        ? service.pause(auction.id, userId)
                        : service.resume(auction.id, userId),),
                icon: Icon(live
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!auction.biddingOpen)
            PrimaryButton(
              context.l10n.auction_start_bidding,
              enabled: live,
              progress: busy,
              background: brandRedColor,
              onPressed: () =>
                  run(() => service.startBidding(auction.id, userId)),
            )
          else
            _bidGrid(context),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _secondary(
                  context,
                  context.l10n.auction_undo_bid,
                  live && hasBids
                      ? () => run(() => service.undoBid(auction.id, userId))
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _secondary(
                  context,
                  context.l10n.auction_mark_unsold,
                  live && !hasBids
                      ? () => run(() => service.markUnsold(auction.id, userId))
                      : null,
                  color: cs.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  context.l10n.auction_sell,
                  enabled: live && hasBids && !busy,
                  background: positiveGreenColor,
                  foreground: brandNavyColor,
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    run(() => service.sell(auction.id, userId));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bidGrid(BuildContext context) {
    final cs = context.colorScheme;
    final next = auction.nextBidAmount ?? 0;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: 62,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      children: auction.teams.map((team) {
        final block = auction.bidBlock(team.id);
        final leading = auction.leadingTeamId == team.id;
        return Material(
          color: leading
              ? positiveGreenColor.withValues(alpha: 0.18)
              : cs.containerLow,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: block != null || busy
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    run(() => service.placeBid(
                          auctionId: auction.id,
                          userId: userId,
                          teamId: team.id,
                          amount: next,
                        ),);
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  AuctionTeamBadge(auction: auction, team: team, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.subtitle2
                              .copyWith(color: cs.textPrimary),
                        ),
                        Text(
                          block == null
                              ? context.l10n.auction_bid_amount(next)
                              : block.label(context),
                          style: AppTextStyle.caption.copyWith(
                            color: block == null
                                ? brandRedColor
                                : cs.textDisabled,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Side panel ───────────────────────────────────────────────────────────

  Widget _lastSold(BuildContext context) {
    final log = ref.watch(auctionLogProvider(auction.id)).valueOrNull ?? [];
    final sold = log.where((e) => e.type == AuctionLogType.sold).firstOrNull;
    final player = auction.playerById(sold?.playerId);
    final team = auction.teamById(sold?.teamId);
    if (sold == null || player == null || team == null) {
      return const SizedBox();
    }
    final cs = context.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: positiveGreenColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          AuctionPhoto.player(player, size: 36, radius: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.auction_last_sold(
                  player.name, team.name, sold.amount ?? 0,),
              style: AppTextStyle.subtitle3.copyWith(color: cs.textPrimary),
            ),
          ),
          const Icon(CupertinoIcons.checkmark_seal_fill,
              color: positiveGreenColor, size: 20,),
        ],
      ),
    );
  }

  Widget _progressCard(BuildContext context) {
    final cs = context.colorScheme;
    Widget count(String label, int value, Color color) => Expanded(
          child: Column(
            children: [
              Text(
                '$value',
                style: AppTextStyle.header3
                    .copyWith(color: color, fontWeight: FontWeight.w800),
              ),
              Text(label,
                  style: AppTextStyle.caption.copyWith(color: cs.textSecondary),),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cs.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.auction_progress_label,
            style: AppTextStyle.subtitle2
                .copyWith(color: cs.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          AuctionProgressBar(auction: auction),
          const SizedBox(height: 12),
          Row(
            children: [
              count(context.l10n.auction_count_sold,
                  auction.playersWith(AuctionPlayerStatus.sold).length,
                  positiveGreenColor,),
              count(context.l10n.auction_count_unsold,
                  auction.playersWith(AuctionPlayerStatus.unsold).length,
                  cs.warning,),
              count(context.l10n.auction_count_retained,
                  auction.playersWith(AuctionPlayerStatus.retained).length,
                  cs.primary,),
              count(
                context.l10n.auction_count_left,
                auction.playersWith(AuctionPlayerStatus.available).length +
                    (auction.currentPlayerId == null ? 0 : 1),
                cs.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _budgets(BuildContext context) {
    final cs = context.colorScheme;
    final showMoney = widget.isAdmin || auction.showBudgets;
    return Column(
      children: [
        for (final team in auction.teams)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: cs.cardDecoration(radius: 14),
            child: Row(
              children: [
                AuctionTeamBadge(auction: auction, team: team, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subtitle2
                            .copyWith(color: cs.textPrimary),
                      ),
                      Text(
                        context.l10n.auction_players_count(
                            auction.squadOf(team.id).length,),
                        style: AppTextStyle.caption
                            .copyWith(color: cs.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (showMoney)
                  Text(
                    context.l10n.auction_remaining(auction.remainingFor(team)),
                    style: AppTextStyle.subtitle2.copyWith(
                      color: cs.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Player on the block: large photo, details and the current bid.
class _PlayerStage extends StatelessWidget {
  final Auction auction;
  final AuctionPlayer player;
  final bool wide;

  const _PlayerStage({
    required this.auction,
    required this.player,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final pool = auction.orderedPlayers
        .where((p) => p.status != AuctionPlayerStatus.retained)
        .toList();
    final position = pool.indexWhere((p) => p.id == player.id) + 1;
    final leading = auction.leadingTeam;
    final photoSize = wide ? 260.0 : 200.0;

    final photo = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textPrimaryDarkColor, width: 3),
      ),
      child: AuctionPhoto.player(player, size: photoSize, radius: 18),
    );

    final details = Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: textPrimaryDarkColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            context.l10n.auction_player_of(position, pool.length),
            style: AppTextStyle.caption.copyWith(
              color: textPrimaryDarkColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          player.name,
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: AppTextStyle.header1.copyWith(
            color: textPrimaryDarkColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (player.role != null) player.role!.getString(context),
            if (player.number != null) '#${player.number}',
            if (player.code?.isNotEmpty ?? false) player.code!,
            context.l10n.auction_base(player.basePrice),
          ].join(' · '),
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: AppTextStyle.subtitle2.copyWith(color: textSecondaryDarkColor),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: brandNavyColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment:
                wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Text(
                context.l10n.auction_current_bid.toUpperCase(),
                style: AppTextStyle.caption.copyWith(
                  color: textSecondaryDarkColor,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.auction_pts(auction.currentBid ?? player.basePrice),
                style: AppTextStyle.header1.copyWith(
                  color: textPrimaryDarkColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 38,
                ),
              ),
              const SizedBox(height: 6),
              if (leading != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuctionTeamBadge(auction: auction, team: leading, size: 26),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.l10n.auction_leading(leading.name),
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subtitle1.copyWith(
                          color: textPrimaryDarkColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  auction.biddingOpen
                      ? context.l10n.auction_no_bids
                      : context.l10n.auction_bidding_closed,
                  style: AppTextStyle.subtitle2
                      .copyWith(color: textSecondaryDarkColor),
                ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: liveCardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: brandRedColor.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                photo,
                const SizedBox(width: 20),
                Expanded(child: details),
              ],
            )
          : Column(
              children: [photo, const SizedBox(height: 16), details],
            ),
    );
  }
}
