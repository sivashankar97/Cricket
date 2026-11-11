import 'package:data/api/match/match_model.dart';
import 'package:data/api/team/team_model.dart';
import 'package:data/api/tournament/tournament_extras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:style/animations/fade_slide_in.dart';
import 'package:style/animations/motion.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart';

import '../../../../../components/image_avatar.dart';
import '../../../auction/components/auction_widgets.dart';
import '../summary/tournament_summary.dart';
import '../summary/tournament_summary_provider.dart';

/// List item entrance: fades in, staggered by position.
class Appear extends StatelessWidget {
  final int index;
  final Widget child;

  const Appear({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) =>
      FadeSlideIn(delay: AppStagger.of(index), child: child);
}

class TournamentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const TournamentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: context.colorScheme.cardDecoration(radius: 16),
        child: child,
      );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppTextStyle.header4
                  .copyWith(color: context.colorScheme.textPrimary),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: AppTextStyle.subtitle3
                    .copyWith(color: context.colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class TeamBadge extends StatelessWidget {
  final TeamModel team;
  final double size;

  const TeamBadge(this.team, {super.key, this.size = 36});

  @override
  Widget build(BuildContext context) => ImageAvatar(
        initial: teamShortName(team),
        imageUrl: team.profile_img_url,
        size: size,
        backgroundColor: context.colorScheme.containerLow,
      );
}

/// Round player photo: the auction photo when there is one, else the profile
/// image or initials.
class PlayerAvatar extends ConsumerWidget {
  final SummaryPlayer player;
  final double size;
  final bool onDark;

  const PlayerAvatar(this.player,
      {super.key, this.size = 32, this.onDark = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoId = ref.watch(
        tournamentPlayerPhotosProvider.select((photos) => photos[player.id]));
    final border = onDark ? Border.all(color: Colors.white, width: 1.5) : null;
    if (photoId != null) {
      return Container(
        decoration: BoxDecoration(shape: BoxShape.circle, border: border),
        child: AuctionPhoto(
          photoId: photoId,
          hasPhoto: true,
          fallback: player.user.nameInitial,
          size: size,
          radius: size / 2,
        ),
      );
    }
    return ImageAvatar(
      initial: player.user.nameInitial,
      imageUrl: player.user.profile_img_url,
      size: size,
      border: border,
      foregroundColor: onDark ? Colors.white : null,
      backgroundColor: onDark ? Colors.white.withValues(alpha: 0.12) : null,
    );
  }
}

String teamShortName(TeamModel team) =>
    (team.name_initial?.trim().isNotEmpty ?? false)
        ? team.name_initial!.trim()
        : team.name.initials(limit: 3).toUpperCase();

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;

  const StatusPill(this.label,
      {super.key, required this.color, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyle.caption
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class FormDots extends StatelessWidget {
  final List<FormResult> form;
  final double size;

  const FormDots(this.form, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < form.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
            child: FadeSlideIn(
              delay: AppStagger.of(i),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: switch (form[i]) {
                    FormResult.win => cs.positive,
                    FormResult.loss => cs.alert,
                    _ => cs.textDisabled,
                  },
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  switch (form[i]) {
                    FormResult.win => context.l10n.tournament_form_win,
                    FormResult.loss => context.l10n.tournament_form_loss,
                    FormResult.tie => context.l10n.tournament_form_tie,
                    FormResult.noResult =>
                      context.l10n.tournament_form_no_result,
                  },
                  style: AppTextStyle.caption.copyWith(
                    color: Colors.white,
                    fontSize: size * 0.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String formatNrr(num value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}';

/// Match number from the stored field, else its place in date order.
int matchNumberOf(
  MatchModel match,
  List<MatchModel> all,
  Map<String, MatchExtras> extras,
) {
  final stored = extras[match.id]?.number;
  if (stored != null) return stored;
  final ordered = all.toList()
    ..sort((a, b) =>
        (a.start_at ?? DateTime(2000)).compareTo(b.start_at ?? DateTime(2000)));
  return ordered.indexWhere((m) => m.id == match.id) + 1;
}

String matchStageOf(
  BuildContext context,
  MatchModel match,
  Map<String, MatchExtras> extras,
) =>
    extras[match.id]?.stage ??
    (match.match_group ?? MatchGroup.round).getString(context);

/// "RK won by 8 wickets", "Match tied", "ER won by walkover", or null.
String? matchResultText(
  BuildContext context,
  MatchModel match,
  Map<String, MatchExtras> extras,
) {
  final walkover = extras[match.id]?.walkoverWinnerId;
  if (walkover != null) {
    final team = match.teams.where((t) => t.team_id == walkover).firstOrNull;
    return context.l10n.tournament_won_by_walkover(
        team == null ? '' : teamShortName(team.team));
  }
  final result = match.matchResult;
  if (result == null) return null;
  if (result.winType == WinnerByType.tie) {
    return context.l10n.tournament_match_tied;
  }
  final team = match.teams.where((t) => t.team.id == result.teamId).firstOrNull;
  final name = team == null ? result.teamName : teamShortName(team.team);
  return result.winType == WinnerByType.run
      ? context.l10n.tournament_won_by_runs(name, result.difference)
      : context.l10n.tournament_won_by_wickets(name, result.difference);
}

String? matchWinnerId(MatchModel match, Map<String, MatchExtras> extras) {
  final walkover = extras[match.id]?.walkoverWinnerId;
  if (walkover != null) return walkover;
  final result = match.matchResult;
  if (result == null || result.winType == WinnerByType.tie) return null;
  return result.teamId;
}
