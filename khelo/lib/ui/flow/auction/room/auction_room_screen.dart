import 'package:collection/collection.dart';
import 'package:data/api/auction/auction_models.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/confirmation_dialog.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/components/mascot/mascot_reactions.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

import '../auction_providers.dart';
import '../components/auction_action_runner.dart';
import '../components/auction_widgets.dart';
import '../components/complete_auction_dialog.dart';
import 'auction_live_tab.dart';
import 'auction_room_tabs.dart';

/// One auction: live view, teams, players and history. Admins of the auction
/// also get the setup and live controls; everyone else is read-only.
class AuctionRoomScreen extends ConsumerStatefulWidget {
  final String auctionId;

  const AuctionRoomScreen({super.key, required this.auctionId});

  @override
  ConsumerState<AuctionRoomScreen> createState() => _AuctionRoomScreenState();
}

class _AuctionRoomScreenState extends ConsumerState<AuctionRoomScreen>
    with AuctionActionRunner {
  Set<String>? _seenLogIds;

  /// Cheers players sold or left unsold while the room is open (admins and
  /// viewers alike); history that was already there is skipped.
  void _reactToLog(
    AsyncValue<List<AuctionLogEntry>>? previous,
    AsyncValue<List<AuctionLogEntry>> next,
  ) {
    final entries = next.valueOrNull;
    if (entries == null) return;
    final seen = _seenLogIds ??=
        (previous?.valueOrNull ?? entries).map((e) => e.id).toSet();
    final fresh = entries.where((e) => seen.add(e.id)).toList();
    final last = fresh.lastWhereOrNull((e) =>
        e.type == AuctionLogType.sold || e.type == AuctionLogType.unsold);
    if (last == null) return;
    ref.read(mascotProvider.notifier).react(
          last.type == AuctionLogType.sold
              ? MascotReaction.auctionSold
              : MascotReaction.auctionUnsold,
          top: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(auctionLogProvider(widget.auctionId), _reactToLog);
    final state = ref.watch(auctionProvider(widget.auctionId));
    final auction = state.valueOrNull;
    final uid = ref.watch(currentUserPod)?.id;
    if (auction == null) {
      return AppPage(
        title: context.l10n.auction_screen_title,
        body: state.isLoading
            ? const SkeletonDetail()
            : state.hasError
                ? ErrorScreen(
                    error: state.error,
                    onRetryTap: () =>
                        ref.invalidate(auctionProvider(widget.auctionId)),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.l10n.auction_not_found,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.body1.copyWith(
                          color: context.colorScheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
      );
    }
    final isAdmin = uid != null && auction.isAdmin(uid);
    return DefaultTabController(
      length: 4,
      child: AppPage(
        titleWidget: _title(context, auction),
        leading: Navigator.of(context).canPop()
            ? null
            : IconButton(
                tooltip: context.l10n.auction_home,
                onPressed: () => AppRoute.main.go(context),
                icon: Icon(
                  CupertinoIcons.house,
                  color: context.colorScheme.textPrimary,
                ),
              ),
        actions: [
          IconButton(
            tooltip: context.l10n.auction_share,
            onPressed: () => _copyLink(auction),
            icon: Icon(CupertinoIcons.link,
                color: context.colorScheme.textPrimary),
          ),
          if (isAdmin) _menu(context, auction, uid),
        ],
        body: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle:
                  AppTextStyle.subtitle2.copyWith(fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: context.l10n.auction_tab_live),
                Tab(text: context.l10n.auction_tab_teams),
                Tab(text: context.l10n.auction_tab_players),
                Tab(text: context.l10n.auction_tab_history),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  AuctionLiveTab(auction: auction, isAdmin: isAdmin),
                  AuctionTeamsTab(auction: auction, isAdmin: isAdmin),
                  AuctionPlayersTab(auction: auction, isAdmin: isAdmin),
                  AuctionHistoryTab(auction: auction),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context, Auction auction) => Row(
        children: [
          if (auction.bannerVersion > 0) ...[
            AuctionPhoto(
              photoId: auction.bannerPhotoId,
              hasPhoto: true,
              fallback:
                  auction.name.isEmpty ? '?' : auction.name[0].toUpperCase(),
              size: 34,
              radius: 8,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              auction.name,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.header3
                  .copyWith(color: context.colorScheme.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          AuctionStatusPill(status: auction.status),
        ],
      );

  Future<void> _copyLink(Auction auction) async {
    final origin =
        kIsWeb ? Uri.base.origin : 'https://khelo-hexshankar.web.app';
    await Clipboard.setData(
        ClipboardData(text: '$origin/#/auction/${auction.id}'));
    if (mounted) showSnackBar(context, context.l10n.auction_link_copied);
  }

  Widget _menu(BuildContext context, Auction auction, String uid) {
    final running = auction.status.isRunning;
    final setup = auction.status.isSetup;
    return PopupMenuButton<VoidCallback>(
      icon: Icon(Icons.more_vert, color: context.colorScheme.textPrimary),
      color: context.colorScheme.surface,
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        if (auction.status != AuctionStatus.completed)
          PopupMenuItem(
            value: () => AppRoute.auctionForm(auction: auction).push(context),
            child: Text(context.l10n.auction_edit),
          ),
        PopupMenuItem(
          value: () => AppRoute.auctionPlayers(auction.id).push(context),
          child: Text(context.l10n.auction_manage_players),
        ),
        if (setup)
          PopupMenuItem(
            value: () => AppRoute.auctionRetained(auction.id).push(context),
            child: Text(context.l10n.auction_manage_retained),
          ),
        if (auction.status == AuctionStatus.live)
          PopupMenuItem(
            value: () => run(() => service.pause(auction.id, uid)),
            child: Text(context.l10n.auction_pause),
          ),
        if (auction.status == AuctionStatus.paused)
          PopupMenuItem(
            value: () => run(() => service.resume(auction.id, uid)),
            child: Text(context.l10n.auction_resume),
          ),
        if (running)
          PopupMenuItem(
            value: () => _complete(auction),
            child: Text(
              context.l10n.auction_complete,
              style: const TextStyle(color: positiveGreenColor),
            ),
          ),
        if (auction.createdBy == uid)
          PopupMenuItem(
            value: () => _delete(auction),
            child: Text(
              context.l10n.auction_delete,
              style: TextStyle(color: context.colorScheme.alert),
            ),
          ),
      ],
    );
  }

  Future<void> _complete(Auction auction) async {
    final id = await showCompleteAuctionDialog(
      context,
      auction: auction,
      service: service,
      userId: userId,
    );
    if (id != null && mounted) {
      showSnackBar(
        context,
        context.l10n.auction_tournament_created(auction.tournamentName),
      );
    }
  }

  void _delete(Auction auction) {
    showConfirmationDialog(
      context,
      title: context.l10n.auction_delete,
      message: context.l10n.auction_delete_confirm,
      confirmBtnText: context.l10n.common_delete_title,
      onConfirm: () async {
        final ok = await run(() => service.deleteAuction(auction.id));
        if (!ok || !mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          AppRoute.main.go(context);
        }
      },
    );
  }
}
