import 'package:data/api/tournament/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

/// Modern tournament card matching the reference design for the Home carousel:
/// Finished tournaments get a dark navy card with green badge, champion, and stats link.
/// Upcoming/running tournaments get a clean card with status badge and fixtures link.
class TournamentItem extends StatelessWidget {
  final TournamentModel tournament;
  final EdgeInsets margin;
  final Size? size;

  const TournamentItem({
    super.key,
    this.size,
    required this.tournament,
    this.margin = EdgeInsets.zero,
  });

  bool get _isFinished {
    if (tournament.status == TournamentStatus.finish) return true;
    final now = DateTime.now();
    return tournament.end_date.isBefore(now);
  }

  bool get _isLive {
    if (tournament.status == TournamentStatus.running) return true;
    final now = DateTime.now();
    return tournament.start_date.isBefore(now) &&
        tournament.end_date.isAfter(now);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final width = size?.width ?? 280.0;
    const height = 160.0;

    final isFinished = _isFinished;
    final isLive = _isLive;

    return OnTapScale(
      onTap: () =>
          AppRoute.tournamentDetail(tournamentId: tournament.id).push(context),
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isFinished ? const Color(0xFF141738) : cs.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: cs.cardShadow,
          border: Border.all(
            color: isFinished
                ? Colors.white.withValues(alpha: 0.1)
                : cs.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top row: Status badge + Teams count
            Row(
              children: [
                _statusBadge(isFinished, isLive),
                const Spacer(),
                Text(
                  '${tournament.team_ids.length} Teams',
                  style: TextStyle(
                    color: isFinished
                        ? const Color(0xFF94A3B8)
                        : cs.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tournament Name
            Text(
              tournament.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subtitle2.copyWith(
                color: isFinished ? Colors.white : cs.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),

            const SizedBox(height: 4),

            // Date Range
            Text(
              _formatDateRange(tournament.start_date, tournament.end_date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    isFinished ? const Color(0xFF94A3B8) : cs.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            // Bottom bar
            if (isFinished)
              const Row(
                children: [
                  Text(
                    '👑 Champion: Titans',
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Stats ›',
                    style: TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Text(
                    isLive ? 'Live standings ›' : 'Fixtures released ›',
                    style: const TextStyle(
                      color: brandRedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool isFinished, bool isLive) {
    if (isFinished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'FINISHED',
          style: TextStyle(
            color: Color(0xFF34D399),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    if (isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'LIVE',
          style: TextStyle(
            color: Color(0xFF16A34A),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'UPCOMING',
        style: TextStyle(
          color: Color(0xFFD97706),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} – ${DateFormat('d MMM yyyy').format(end)}';
    }
    if (start.year == end.year) {
      return '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
    }
    return '${DateFormat('d MMM yyyy').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';
  }
}
