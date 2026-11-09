import 'package:data/api/auction/auction_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

import '../auction_providers.dart';
import '../components/auction_action_runner.dart';
import '../components/auction_widgets.dart';
import '../players/auction_players_screen.dart';

/// Every team with its budget and squad (retained and bought players).
class AuctionTeamsTab extends StatelessWidget {
  final Auction auction;
  final bool isAdmin;

  const AuctionTeamsTab({super.key, required this.auction, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final showMoney = isAdmin || auction.showBudgets;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 40 + context.mediaQueryPadding.bottom),
      children: [
        for (final team in auction.teams)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: cs.cardDecoration(radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AuctionTeamBadge(auction: auction, team: team),
                    const SizedBox(width: 12),
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
                            [
                              context.l10n.auction_players_count(
                                  auction.squadOf(team.id).length,),
                              if (showMoney)
                                context.l10n.auction_budget_line(
                                  auction.spentBy(team.id),
                                  auction.remainingFor(team),
                                  team.budget,
                                ),
                            ].join(' · '),
                            style: AppTextStyle.caption
                                .copyWith(color: cs.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (auction.squadOf(team.id).isEmpty)
                  Text(
                    context.l10n.auction_squad_empty,
                    style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
                  ),
                for (final player in auction.squadOf(team.id))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        AuctionPhoto.player(player, size: 36, radius: 10),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            player.name,
                            style: AppTextStyle.subtitle2
                                .copyWith(color: cs.textPrimary),
                          ),
                        ),
                        Text(
                          player.status == AuctionPlayerStatus.retained
                              ? context.l10n.auction_tag_retained
                              : context.l10n.auction_tag_sold,
                          style: AppTextStyle.caption.copyWith(
                            color: player.status == AuctionPlayerStatus.retained
                                ? cs.primary
                                : positiveGreenColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          context.l10n.auction_pts(player.price ?? 0),
                          style: AppTextStyle.subtitle3.copyWith(
                            color: cs.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// All players with status filters; admins can put one up directly.
class AuctionPlayersTab extends ConsumerStatefulWidget {
  final Auction auction;
  final bool isAdmin;

  const AuctionPlayersTab({super.key, required this.auction, required this.isAdmin});

  @override
  ConsumerState<AuctionPlayersTab> createState() => _AuctionPlayersTabState();
}

class _AuctionPlayersTabState extends ConsumerState<AuctionPlayersTab>
    with AuctionActionRunner {
  final _search = TextEditingController();
  AuctionPlayerStatus? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final auction = widget.auction;
    final query = _search.text.trim().toLowerCase();
    final players = auction.orderedPlayers.where((p) {
      if (_filter != null && p.status != _filter) return false;
      return query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          (p.code?.toLowerCase().contains(query) ?? false) ||
          '${p.number ?? ''}' == query;
    }).toList();
    final canShow = widget.isAdmin && auction.status == AuctionStatus.live;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: AppTextField(
            controller: _search,
            hintText: context.l10n.auction_player_search,
            prefixIcon:
                Icon(CupertinoIcons.search, size: 18, color: cs.textSecondary),
            onChanged: (_) => setState(() {}),
            borderType: AppTextFieldBorderType.outline,
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            scrollDirection: Axis.horizontal,
            children: [
              _chip(context, null, auction.players.length),
              for (final s in AuctionPlayerStatus.values)
                _chip(context, s, auction.playersWith(s).length),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, 40 + context.mediaQueryPadding.bottom,),
            itemCount: players.length,
            itemBuilder: (context, i) {
              final player = players[i];
              final team = auction.teamById(player.teamId);
              final showable = canShow &&
                  auction.bids.isEmpty &&
                  (player.status == AuctionPlayerStatus.available ||
                      player.status == AuctionPlayerStatus.unsold);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: cs.cardDecoration(radius: 14),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: AuctionPhoto.player(player),
                  title: Text(
                    player.name,
                    style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
                  ),
                  subtitle: Text(
                    playerDetails(context, player, team: team),
                    style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
                  ),
                  trailing: showable
                      ? TextButton(
                          onPressed: busy
                              ? null
                              : () => run(() => service.showPlayer(
                                  auction.id, userId, player.id,),),
                          child: Text(context.l10n.auction_show_now),
                        )
                      : AuctionPlayerTag(status: player.status),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, AuctionPlayerStatus? status, int count) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(
              '${status?.label(context) ?? context.l10n.auction_filter_all} ($count)',),
          selected: _filter == status,
          onSelected: (_) => setState(() => _filter = status),
        ),
      );
}

/// Auction transaction history, newest first.
class AuctionHistoryTab extends ConsumerWidget {
  final Auction auction;

  const AuctionHistoryTab({super.key, required this.auction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final log = ref.watch(auctionLogProvider(auction.id)).valueOrNull ?? [];
    if (log.isEmpty) {
      return Center(
        child: Text(
          context.l10n.auction_history_empty,
          style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 40 + context.mediaQueryPadding.bottom),
      itemCount: log.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: cs.outline),
      itemBuilder: (context, i) {
        final entry = log[i];
        final (icon, color) = _style(context, entry.type);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(icon, color: color, size: 22),
          title: Text(
            _text(context, entry),
            style: AppTextStyle.subtitle3.copyWith(color: cs.textPrimary),
          ),
          trailing: Text(
            DateFormat.Hms().format(entry.createdAt),
            style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
          ),
        );
      },
    );
  }

  (IconData, Color) _style(BuildContext context, AuctionLogType type) {
    final cs = context.colorScheme;
    return switch (type) {
      AuctionLogType.sold => (CupertinoIcons.checkmark_seal_fill, positiveGreenColor),
      AuctionLogType.unsold => (CupertinoIcons.xmark_circle, cs.warning),
      AuctionLogType.bid => (CupertinoIcons.hand_raised_fill, brandRedColor),
      AuctionLogType.bidUndone => (CupertinoIcons.arrow_uturn_left, cs.textSecondary),
      AuctionLogType.retained => (CupertinoIcons.star_fill, cs.primary),
      AuctionLogType.completed => (CupertinoIcons.flag_fill, positiveGreenColor),
      AuctionLogType.paused => (CupertinoIcons.pause_fill, cs.warning),
      _ => (CupertinoIcons.circle_fill, cs.textSecondary),
    };
  }

  String _text(BuildContext context, AuctionLogEntry e) {
    final player = auction.playerById(e.playerId)?.name ?? '';
    final team = auction.teamById(e.teamId)?.name ?? '';
    final amount = e.amount ?? 0;
    final l10n = context.l10n;
    return switch (e.type) {
      AuctionLogType.created => l10n.auction_log_created,
      AuctionLogType.published => l10n.auction_log_published,
      AuctionLogType.started => l10n.auction_log_started,
      AuctionLogType.paused => l10n.auction_log_paused,
      AuctionLogType.resumed => l10n.auction_log_resumed,
      AuctionLogType.shown => l10n.auction_log_shown(player),
      AuctionLogType.biddingStarted => l10n.auction_log_bidding_started(player),
      AuctionLogType.bid => l10n.auction_log_bid(team, amount, player),
      AuctionLogType.bidUndone => l10n.auction_log_bid_undone(amount, team),
      AuctionLogType.sold => l10n.auction_log_sold(player, team, amount),
      AuctionLogType.unsold => l10n.auction_log_unsold(player),
      AuctionLogType.reopened => l10n.auction_log_reopened,
      AuctionLogType.retained => l10n.auction_log_retained(player, team, amount),
      AuctionLogType.released => l10n.auction_log_released(player),
      AuctionLogType.completed => l10n.auction_log_completed,
    };
  }
}
