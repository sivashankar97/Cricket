import 'package:data/api/auction/auction_models.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

import 'auction_providers.dart';
import 'components/auction_widgets.dart';

/// Auction tab. Anyone can browse published auctions, signed in or not;
/// signed-in users also see auctions they administer (drafts included).
class AuctionScreen extends ConsumerWidget {
  const AuctionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserPod)?.id;
    final publishedAsync = ref.watch(publishedAuctionsProvider);
    final published = publishedAsync.valueOrNull ?? [];
    final mine = userId == null
        ? <Auction>[]
        : ref.watch(adminAuctionsProvider(userId)).valueOrNull ?? [];
    final mineIds = mine.map((a) => a.id).toSet();
    final others = published.where((a) => !mineIds.contains(a.id));
    final live = others.where((a) => a.status.isRunning).toList();
    final upcoming =
        others.where((a) => a.status == AuctionStatus.upcoming).toList();
    final completed =
        others.where((a) => a.status == AuctionStatus.completed).toList();

    return AppPage(
      title: context.l10n.auction_screen_title,
      body: ListView(
        padding: context.mediaQueryPadding +
            const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          _heroCard(context, signedIn: userId != null),
          if (mine.isNotEmpty) ...[
            AuctionSectionTitle(context.l10n.auction_section_mine),
            ...mine.map((a) => AuctionTile(auction: a)),
          ],
          if (live.isNotEmpty) ...[
            AuctionSectionTitle(context.l10n.auction_section_live),
            ...live.map((a) => AuctionTile(auction: a)),
          ],
          if (upcoming.isNotEmpty) ...[
            AuctionSectionTitle(context.l10n.auction_section_upcoming),
            ...upcoming.map((a) => AuctionTile(auction: a)),
          ],
          if (completed.isNotEmpty) ...[
            AuctionSectionTitle(context.l10n.auction_section_completed),
            ...completed.map((a) => AuctionTile(auction: a)),
          ],
          if (publishedAsync.isLoading && published.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: AppProgressIndicator()),
            )
          else if (mine.isEmpty && published.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(20),
              decoration: context.colorScheme.cardDecoration(radius: 18),
              child: Text(
                context.l10n.auction_empty,
                textAlign: TextAlign.center,
                style: AppTextStyle.body2
                    .copyWith(color: context.colorScheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroCard(BuildContext context, {required bool signedIn}) {
    return OnTapScale(
      onTap: () => signedIn
          ? AppRoute.auctionForm().push(context)
          : AppRoute.phoneLogin.push(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: liveCardGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: brandRedColor.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.auction_hero_title,
                    style: AppTextStyle.header3
                        .copyWith(color: textPrimaryDarkColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.auction_hero_subtitle,
                    style: AppTextStyle.caption
                        .copyWith(color: textSecondaryDarkColor),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: textPrimaryDarkColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          signedIn ? CupertinoIcons.add : CupertinoIcons.person,
                          size: 16,
                          color: brandRedDeepColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          signedIn
                              ? context.l10n.auction_create_title
                              : context.l10n.auction_sign_in_to_create,
                          style: AppTextStyle.subtitle3.copyWith(
                            color: brandRedDeepColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: textPrimaryDarkColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: textPrimaryDarkColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.hammer_fill,
                color: brandRedColor,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuctionTile extends StatelessWidget {
  final Auction auction;

  const AuctionTile({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final current = auction.currentPlayer;
    final date = auction.auctionDate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnTapScale(
        onTap: () => AppRoute.auctionRoom(auction.id).push(context),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: cs.cardDecoration(radius: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (auction.hasBanner)
                LayoutBuilder(
                  builder: (context, constraints) => AuctionPhoto(
                    photoId: auction.bannerPhotoId,
                    hasPhoto: true,
                    fallback: '',
                    size: constraints.maxWidth,
                    height: 110,
                    radius: 0,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            auction.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.subtitle1.copyWith(
                              color: cs.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AuctionStatusPill(status: auction.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        context.l10n.auction_tile_summary(
                          auction.teams.length,
                          auction.players.length,
                        ),
                        if (date != null) DateFormat.yMMMd().format(date),
                      ].join(' · '),
                      style: AppTextStyle.caption
                          .copyWith(color: cs.textSecondary),
                    ),
                    if (auction.status.isRunning ||
                        auction.status == AuctionStatus.completed) ...[
                      const SizedBox(height: 10),
                      AuctionProgressBar(auction: auction),
                    ],
                    if (current != null && auction.status.isRunning) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          AuctionPhoto.player(current, size: 28, radius: 8),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              current.name,
                              style: AppTextStyle.subtitle3
                                  .copyWith(color: cs.textPrimary),
                            ),
                          ),
                          Text(
                            context.l10n.auction_pts(
                              auction.currentBid ?? current.basePrice,
                            ),
                            style: AppTextStyle.subtitle3.copyWith(
                              color: brandRedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuctionProgressBar extends StatelessWidget {
  final Auction auction;

  const AuctionProgressBar({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final total = auction.auctionPoolCount;
    final done = auction.processedCount;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 6,
              color: positiveGreenColor,
              backgroundColor: cs.containerNormal,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          context.l10n.auction_progress(done, total),
          style: AppTextStyle.caption.copyWith(
            color: cs.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
