import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart';

/// Clean card matching the modern tournament list design:
/// Left color stripe (green/amber/slate), logo thumbnail, title + status badge,
/// type badge, team count, date range, and a heart action button.
class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onTap,
  });

  TournamentStatus get effectiveStatus {
    if (tournament.status == TournamentStatus.running) {
      return TournamentStatus.running;
    }
    if (tournament.status == TournamentStatus.finish) {
      return TournamentStatus.finish;
    }
    final now = DateTime.now();
    if (tournament.start_date.isAfter(now)) {
      return TournamentStatus.upcoming;
    }
    if (tournament.end_date.isBefore(now)) {
      return TournamentStatus.finish;
    }
    if (tournament.start_date.isBefore(now) &&
        tournament.end_date.isAfter(now)) {
      return TournamentStatus.running;
    }
    return tournament.status;
  }

  Color get _stripeColor {
    switch (effectiveStatus) {
      case TournamentStatus.running:
        return const Color(0xFF10B981); // Emerald Green
      case TournamentStatus.upcoming:
        return const Color(0xFFF59E0B); // Amber
      case TournamentStatus.finish:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onTap ??
          () => AppRoute.tournamentDetail(tournamentId: tournament.id)
              .push(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cs.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.25),
          ),
          boxShadow: cs.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Left color accent stripe
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4.5,
              child: Container(
                color: _stripeColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  _logo(context),
                  const SizedBox(width: 12),
                  Expanded(child: _content(context)),
                  const SizedBox(width: 8),
                  _favoriteButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo(BuildContext context) {
    final cs = context.colorScheme;
    final url = tournament.profile_img_url;
    final status = effectiveStatus;

    Color bg;
    Color iconColor;
    switch (status) {
      case TournamentStatus.running:
        bg = const Color(0xFFECFDF5);
        iconColor = const Color(0xFF059669);
        break;
      case TournamentStatus.upcoming:
        bg = const Color(0xFFFFFBEB);
        iconColor = const Color(0xFFD97706);
        break;
      case TournamentStatus.finish:
        bg = const Color(0xFFF1F5F9);
        iconColor = const Color(0xFF475569);
        break;
    }

    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) => Center(
                child: CupertinoActivityIndicator(
                  radius: 8,
                  color: iconColor,
                ),
              ),
              errorWidget: (_, __, ___) => Icon(
                CupertinoIcons.sportscourt_fill,
                size: 26,
                color: iconColor,
              ),
            )
          : Icon(
              CupertinoIcons.sportscourt_fill,
              size: 26,
              color: iconColor,
            ),
    );
  }

  Widget _content(BuildContext context) {
    final cs = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                tournament.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.subtitle1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _statusBadge(),
          ],
        ),
        const SizedBox(height: 6),
        _metadataRow(context),
      ],
    );
  }

  Widget _statusBadge() {
    final status = effectiveStatus;
    Color bg;
    Color dot;
    Color text;
    String label;

    switch (status) {
      case TournamentStatus.running:
        bg = const Color(0xFFDCFCE7);
        dot = const Color(0xFF16A34A);
        text = const Color(0xFF16A34A);
        label = 'Live';
        break;
      case TournamentStatus.upcoming:
        bg = const Color(0xFFFEF3C7);
        dot = const Color(0xFFD97706);
        text = const Color(0xFFD97706);
        label = 'Upcoming';
        break;
      case TournamentStatus.finish:
        bg = const Color(0xFFF1F5F9);
        dot = const Color(0xFF64748B);
        text = const Color(0xFF64748B);
        label = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadataRow(BuildContext context) {
    final cs = context.colorScheme;
    final typeText = tournament.type.getString(context).toUpperCase();
    final teamCount = tournament.team_ids.length;
    final dateStr = _formatDateRange(tournament.start_date, tournament.end_date);
    final matchCount = tournament.match_ids.length;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Type Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: cs.containerLowOnSurface,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            typeText,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: cs.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Team count
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.person_2_fill,
              size: 12,
              color: cs.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$teamCount teams',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption.copyWith(
                  color: cs.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),

        // Date range
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 12,
              color: cs.textSecondary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                dateStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption.copyWith(
                  color: cs.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),

        // Views or matches indicator if any
        if (matchCount > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.eye,
                size: 12,
                color: cs.textDisabled,
              ),
              const SizedBox(width: 4),
              Text(
                '$matchCount',
                style: AppTextStyle.caption.copyWith(
                  color: cs.textDisabled,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _favoriteButton(BuildContext context) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onFavoriteToggle,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.35),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          size: 18,
          color: isFavorite
              ? const Color(0xFFE11D48)
              : cs.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return 'From ${DateFormat('d MMM yyyy').format(start)}';
    }
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} – ${DateFormat('d MMM yyyy').format(end)}';
    }
    if (start.year == end.year) {
      return '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
    }
    return '${DateFormat('d MMM yyyy').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
  }
}
