import 'package:data/api/auction/auction_models.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/grouped_list.dart';
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

    final all = [...mine, ...others];
    final counts = (
      live: all.where((a) => a.status.isRunning).length,
      upcoming: all.where((a) => a.status == AuctionStatus.upcoming).length,
      completed: all.where((a) => a.status == AuctionStatus.completed).length,
    );

    return AppPage(
      title: context.l10n.auction_screen_title,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: context.mediaQueryPadding +
                const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              _heroCard(context, signedIn: userId != null, counts: counts),
              if (mine.isNotEmpty) ...[
                _caption(context.l10n.auction_section_mine, mine.length),
                ...mine.map((a) => AuctionTile(auction: a)),
              ],
              if (live.isNotEmpty) ...[
                _caption(context.l10n.auction_section_live, live.length),
                ...live.map((a) => AuctionTile(auction: a)),
              ],
              if (upcoming.isNotEmpty) ...[
                _caption(
                    context.l10n.auction_section_upcoming, upcoming.length),
                ...upcoming.map((a) => AuctionTile(auction: a)),
              ],
              if (completed.isNotEmpty) ...[
                _caption(
                    context.l10n.auction_section_completed, completed.length),
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
                  decoration: context.colorScheme.cardDecoration(radius: 18),
                  child: BrandEmptyState(
                    icon: CupertinoIcons.hammer_fill,
                    title: context.l10n.auction_empty,
                    description: context.l10n.auction_empty_body,
                    buttonTitle: userId != null
                        ? context.l10n.auction_create_title
                        : null,
                    onTap: () => AppRoute.auctionForm().push(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _caption(String title, int count) {
    return Builder(
      builder: (context) => SectionCaption(
        title,
        trailing: Text(
          '$count',
          style: AppTextStyle.caption.copyWith(
            color: context.colorScheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _heroCard(
    BuildContext context, {
    required bool signedIn,
    required ({int live, int upcoming, int completed}) counts,
  }) {
    final stats = [
      if (counts.live > 0)
        (
          context.l10n.auction_hero_stat_live(counts.live),
          CupertinoIcons.dot_radiowaves_left_right
        ),
      if (counts.upcoming > 0)
        (
          context.l10n.auction_hero_stat_upcoming(counts.upcoming),
          CupertinoIcons.calendar
        ),
      if (counts.completed > 0)
        (
          context.l10n.auction_hero_stat_completed(counts.completed),
          CupertinoIcons.checkmark_seal_fill
        ),
    ];
    return BrandHeroCard(
      glowSize: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.auction_hero_title,
                      style: AppTextStyle.header3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.auction_hero_subtitle,
                      style: AppTextStyle.caption
                          .copyWith(color: textSecondaryDarkColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.hammer_fill,
                  color: brandRedColor,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OnTapScale(
                onTap: () => signedIn
                    ? AppRoute.auctionForm().push(context)
                    : AppRoute.signIn.push(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: brandRedColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        signedIn ? CupertinoIcons.add : CupertinoIcons.person,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          signedIn
                              ? context.l10n.auction_create_title
                              : context.l10n.auction_sign_in_to_create,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.subtitle3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final (label, icon) in stats)
                InfoChip(
                  label,
                  icon: icon,
                  color: Colors.white,
                  background: Colors.white.withValues(alpha: 0.12),
                ),
            ],
          ),
        ],
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
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!auction.hasBanner) ...[
                          const BrandIconThumb(CupertinoIcons.hammer_fill,
                              size: 48),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auction.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.subtitle1.copyWith(
                                  color: cs.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  AuctionStatusPill(status: auction.status),
                                  InfoChip(
                                    context.l10n.auction_tile_summary(
                                      auction.teams.length,
                                      auction.players.length,
                                    ),
                                    icon: CupertinoIcons.person_2_fill,
                                  ),
                                  if (date != null)
                                    InfoChip(
                                      DateFormat.yMMMd().format(date),
                                      icon: CupertinoIcons.calendar,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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
              color: auction.status == AuctionStatus.completed
                  ? positiveGreenColor
                  : brandRedColor,
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
