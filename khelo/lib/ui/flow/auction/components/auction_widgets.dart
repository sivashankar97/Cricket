import 'package:data/api/auction/auction_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

import '../auction_providers.dart';

const _teamColors = [
  Color(0xFF3532B8),
  Color(0xFFF2426E),
  Color(0xFF1ED7A0),
  Color(0xFFFF9F1C),
  Color(0xFF7B61FF),
  Color(0xFF2EC4F1),
  Color(0xFF6D6875),
  Color(0xFF06A77D),
];

/// Colors follow the team order, so the first teams never share a color.
Color auctionTeamColor(Auction auction, AuctionTeam team) {
  final index = auction.teams.indexWhere((t) => t.id == team.id);
  final key = index >= 0
      ? index
      : team.id.codeUnits.fold<int>(0, (a, b) => a + b);
  return _teamColors[key % _teamColors.length];
}

/// The team's logo, or its initials on the team color.
class AuctionTeamBadge extends ConsumerWidget {
  final Auction auction;
  final AuctionTeam team;
  final double size;

  const AuctionTeamBadge({
    super.key,
    required this.auction,
    required this.team,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logo = team.hasLogo
        ? ref.watch(auctionPhotoProvider(auction.teamLogoId(team))).valueOrNull
        : null;
    if (logo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: Image.memory(
          logo,
          height: size,
          width: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: auctionTeamColor(auction, team),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        team.initials.toUpperCase(),
        maxLines: 1,
        style: AppTextStyle.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.3,
        ),
      ),
    );
  }
}

/// A photo stored in the `photos` collection, or the [fallback] initial.
class AuctionPhoto extends ConsumerWidget {
  final String photoId;
  final bool hasPhoto;
  final String fallback;
  final double size;

  /// Defaults to [size] (square).
  final double? height;
  final double radius;

  const AuctionPhoto({
    super.key,
    required this.photoId,
    required this.hasPhoto,
    required this.fallback,
    this.size = 44,
    this.height,
    this.radius = 12,
  });

  AuctionPhoto.player(
    AuctionPlayer player, {
    super.key,
    this.size = 44,
    this.height,
    this.radius = 12,
  })  : photoId = player.id,
        hasPhoto = player.hasPhoto,
        fallback = player.nameInitial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final bytes =
        hasPhoto ? ref.watch(auctionPhotoProvider(photoId)).valueOrNull : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height ?? size,
        width: size,
        color: cs.containerHigh,
        alignment: Alignment.center,
        child: bytes == null
            ? Text(
                fallback,
                style: AppTextStyle.subtitle1.copyWith(
                  color: cs.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.38,
                ),
              )
            : Image.memory(
                bytes,
                height: height ?? size,
                width: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
      ),
    );
  }
}

class AuctionStatusPill extends StatelessWidget {
  final AuctionStatus status;

  const AuctionStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AuctionStatus.draft => context.colorScheme.textSecondary,
      AuctionStatus.upcoming => context.colorScheme.warning,
      AuctionStatus.live => brandRedColor,
      AuctionStatus.paused => context.colorScheme.warning,
      AuctionStatus.completed => positiveGreenColor,
    };
    return _Pill(
      label: status.label(context),
      color: color,
      dot: status == AuctionStatus.live,
    );
  }
}

class AuctionPlayerTag extends StatelessWidget {
  final AuctionPlayerStatus status;

  const AuctionPlayerTag({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AuctionPlayerStatus.available => context.colorScheme.textSecondary,
      AuctionPlayerStatus.retained => context.colorScheme.primary,
      AuctionPlayerStatus.inAuction => brandRedColor,
      AuctionPlayerStatus.sold => positiveGreenColor,
      AuctionPlayerStatus.unsold => context.colorScheme.warning,
    };
    return _Pill(label: status.label(context), color: color);
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;

  const _Pill({required this.label, required this.color, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              height: 6,
              width: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: AppTextStyle.caption.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

extension AuctionStatusLabel on AuctionStatus {
  String label(BuildContext context) => switch (this) {
        AuctionStatus.draft => context.l10n.auction_status_draft,
        AuctionStatus.upcoming => context.l10n.auction_status_upcoming,
        AuctionStatus.live => context.l10n.auction_status_live,
        AuctionStatus.paused => context.l10n.auction_status_paused,
        AuctionStatus.completed => context.l10n.auction_status_completed,
      };
}

extension AuctionPlayerStatusLabel on AuctionPlayerStatus {
  String label(BuildContext context) => switch (this) {
        AuctionPlayerStatus.available =>
          context.l10n.auction_player_status_available,
        AuctionPlayerStatus.retained =>
          context.l10n.auction_player_status_retained,
        AuctionPlayerStatus.inAuction =>
          context.l10n.auction_player_status_in_auction,
        AuctionPlayerStatus.sold => context.l10n.auction_player_status_sold,
        AuctionPlayerStatus.unsold => context.l10n.auction_player_status_unsold,
      };
}

extension AuctionErrorLabel on AuctionError {
  String label(BuildContext context) => switch (this) {
        AuctionError.notEditable => context.l10n.auction_error_not_editable,
        AuctionError.notLive => context.l10n.auction_error_not_live,
        AuctionError.paused => context.l10n.auction_error_paused,
        AuctionError.noPlayer => context.l10n.auction_error_no_player,
        AuctionError.biddingClosed => context.l10n.auction_error_bidding_closed,
        AuctionError.alreadyLeading =>
          context.l10n.auction_error_already_leading,
        AuctionError.squadFull => context.l10n.auction_error_squad_full,
        AuctionError.overBudget => context.l10n.auction_error_over_budget,
        AuctionError.bidMoved => context.l10n.auction_error_bid_moved,
        AuctionError.hasBids => context.l10n.auction_error_has_bids,
        AuctionError.noBid => context.l10n.auction_error_no_bid,
        AuctionError.playerUnavailable =>
          context.l10n.auction_error_player_unavailable,
        AuctionError.noPlayersLeft => context.l10n.auction_error_no_players_left,
        AuctionError.noPreviousPlayer => context.l10n.auction_error_no_previous,
        AuctionError.needTeams => context.l10n.auction_error_need_teams,
        AuctionError.needPlayers => context.l10n.auction_error_need_players,
        AuctionError.duplicatePlayer =>
          context.l10n.auction_error_duplicate_player,
        AuctionError.invalidTeam => context.l10n.auction_error_invalid_team,
        AuctionError.notAdmin => context.l10n.auction_error_not_admin,
        AuctionError.alreadyCompleted =>
          context.l10n.auction_error_already_completed,
        AuctionError.incomplete => context.l10n.auction_error_incomplete,
        AuctionError.tooManyPlayers =>
          context.l10n.auction_error_too_many_players,
      };
}

/// Section heading used across auction screens.
class AuctionSectionTitle extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const AuctionSectionTitle(this.title, {super.key, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 0, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyle.header4.copyWith(
                color: context.colorScheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
