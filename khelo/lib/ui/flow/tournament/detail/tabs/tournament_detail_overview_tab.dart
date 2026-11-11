import 'package:data/api/match/match_model.dart';
import 'package:data/api/team/team_model.dart';
import 'package:data/api/tournament/tournament_details.dart';
import 'package:data/api/tournament/tournament_extras.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:data/service/tournament/tournament_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/app_animations.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

import '../components/leader_card.dart';
import '../components/tournament_match_card.dart';
import '../components/tournament_widgets.dart';
import '../summary/tournament_summary.dart';
import '../summary/tournament_summary_provider.dart';
import '../tournament_detail_view_model.dart';
import 'tournament_detail_points_table_tab.dart';

final _tournamentDetailsProvider = StreamProvider.autoDispose
    .family<TournamentDetails, String>((ref, tournamentId) => ref
        .read(tournamentServiceProvider)
        .streamTournamentDetails(tournamentId));

/// Tab indexes in [TournamentDetailScreen].
const _matchesTab = 1;
const _pointsTab = 2;
const _statsTab = 3;

class TournamentDetailOverviewTab extends ConsumerWidget {
  final PageController controller;

  const TournamentDetailOverviewTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tournamentDetailStateProvider);
    final summary = ref.watch(tournamentSummaryProvider);
    final matchExtras = ref.watch(tournamentMatchExtrasProvider);
    final teamExtras = ref.watch(tournamentTeamExtrasProvider);
    final tournament = state.tournament!;
    final details =
        ref.watch(_tournamentDetailsProvider(tournament.id)).valueOrNull;

    final champion = _champion(state.matches, matchExtras);
    final standings = summary.standings.where((row) => row.played > 0).toList();
    final live = state.matches
        .where((m) => m.match_status == MatchStatus.running)
        .toList();
    final upcoming = state.matches
        .where((m) => m.match_status == MatchStatus.yetToStart)
        .toList()
      ..sort((a, b) => (a.start_at ?? DateTime(2100))
          .compareTo(b.start_at ?? DateTime(2100)));
    final recent = state.matches
        .where((m) =>
            m.match_status == MatchStatus.finish ||
            m.match_status == MatchStatus.abandoned)
        .toList()
      ..sort((a, b) => matchNumberOf(b, state.matches, matchExtras)
          .compareTo(matchNumberOf(a, state.matches, matchExtras)));
    final featured = [...live, ...upcoming.take(2), ...recent].take(3).toList();

    var index = 0;
    final sections = <Widget>[
      if (champion != null)
        _ChampionCard(
          team: champion.$1,
          finalMatch: champion.$2,
          extras: matchExtras,
          owner: teamExtras[champion.$1.id]?.ownerName,
        ),
      if (featured.isNotEmpty) ...[
        SectionTitle(
          live.isNotEmpty || upcoming.isNotEmpty
              ? context.l10n.tournament_detail_overview_featured_matches_title
              : context.l10n.tournament_overview_recent_results,
          action: state.matches.length > featured.length
              ? context.l10n.common_view_all
              : null,
          onAction: () => controller.animateToTab(_matchesTab),
        ),
        for (final match in featured)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TournamentMatchCard(
              match: match,
              number: matchNumberOf(match, state.matches, matchExtras),
              extras: matchExtras,
              onTap: () =>
                  AppRoute.matchDetailTab(matchId: match.id).push(context),
            ),
          ),
      ],
      if (standings.isNotEmpty) ...[
        SectionTitle(
          context.l10n.tournament_detail_points_table_tab,
          action: standings.length > 4 ? context.l10n.common_view_all : null,
          onAction: () => controller.animateToTab(_pointsTab),
        ),
        PointsTable(
          rows: standings.take(4).toList(),
          extras: teamExtras,
          showForm: false,
        ),
      ],
      if (summary.batting.isNotEmpty || summary.bowling.isNotEmpty) ...[
        SectionTitle(
          context.l10n.tournament_overview_top_performers,
          action: context.l10n.common_view_all,
          onAction: () => controller.animateToTab(_statsTab),
        ),
        _leaders(context, summary),
      ],
      _infoView(context, tournament, details, state.matches),
    ];

    return ListView(
      padding: context.mediaQueryPadding.copyWith(top: 0) +
          const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        for (final section in sections) Appear(index: index++, child: section),
      ],
    );
  }

  (TeamModel, MatchModel)? _champion(
    List<MatchModel> matches,
    Map<String, MatchExtras> extras,
  ) {
    final finals = matches.where((m) {
      final stage = extras[m.id]?.stage?.trim().toLowerCase();
      return stage == 'final' ||
          (stage == null && m.match_group == MatchGroup.finals);
    });
    for (final match in finals) {
      final winner = matchWinnerId(match, extras);
      final side = match.teams.where((t) => t.team_id == winner).firstOrNull;
      if (side != null) return (side.team, match);
    }
    return null;
  }

  Widget _leaders(BuildContext context, TournamentSummary summary) {
    final l10n = context.l10n;
    const width = 280.0;
    final cards = <Widget>[
      if (summary.batting.isNotEmpty)
        LeaderCard(
          width: width,
          title: l10n.tournament_stats_most_runs,
          player: summary.batting.first.player,
          value: summary.batting.first.runs,
          unit: l10n.tournament_col_runs,
        ),
      if (summary.bowling.isNotEmpty)
        LeaderCard(
          width: width,
          title: l10n.tournament_stats_most_wickets,
          player: summary.bowling.first.player,
          value: summary.bowling.first.wickets,
          unit: l10n.tournament_col_wickets,
        ),
      if (summary.fielding.isNotEmpty)
        LeaderCard(
          width: width,
          title: l10n.tournament_stats_best_fielder,
          player: summary.fielding.first.player,
          value: summary.fielding.first.total,
          unit: l10n.tournament_stats_dismissals,
        ),
      if (summary.mvp.isNotEmpty)
        LeaderCard(
          width: width,
          title: l10n.tournament_stats_mvp_leader,
          player: summary.mvp.first.player,
          value: summary.mvp.first.total,
          unit: l10n.tournament_col_points,
        ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cards.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == cards.length - 1 ? 0 : 12),
              child: Appear(index: i, child: cards[i]),
            ),
        ],
      ),
    );
  }

  Widget _infoView(
    BuildContext context,
    TournamentModel tournament,
    TournamentDetails? details,
    List<MatchModel> matches,
  ) {
    final rows = <(IconData, String, String?)>[
      (
        Icons.calendar_today_rounded,
        context.l10n.tournament_detail_overview_duration_title,
        DateFormatter.formatDateRange(
          context,
          startDate: tournament.start_date,
          endDate: tournament.end_date,
          formatType: DateFormatType.dayMonth,
        ),
      ),
      (
        Icons.category_rounded,
        context.l10n.tournament_detail_overview_type_title,
        tournament.type.getString(context),
      ),
      (
        Icons.location_city_rounded,
        context.l10n.add_tournament_city,
        details?.city
      ),
      (
        Icons.stadium_rounded,
        context.l10n.add_tournament_ground,
        details?.ground
      ),
      (
        Icons.sports_cricket_rounded,
        context.l10n.add_tournament_ball_type,
        details?.ballType?.getString(context)
      ),
      (
        Icons.timer_outlined,
        context.l10n.add_tournament_overs,
        details?.oversPerMatch?.toString()
      ),
    ].where((row) => row.$3?.trim().isNotEmpty ?? false).toList();
    final cs = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(context.l10n.tournament_detail_overview_info_title),
        TournamentCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(color: cs.outline, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(rows[i].$1, size: 18, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rows[i].$2,
                          style: AppTextStyle.subtitle3
                              .copyWith(color: cs.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          rows[i].$3!,
                          textAlign: TextAlign.end,
                          style: AppTextStyle.subtitle2
                              .copyWith(color: cs.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChampionCard extends StatelessWidget {
  final TeamModel team;
  final MatchModel finalMatch;
  final Map<String, MatchExtras> extras;
  final String? owner;

  const _ChampionCard({
    required this.team,
    required this.finalMatch,
    required this.extras,
    this.owner,
  });

  @override
  Widget build(BuildContext context) {
    final result = matchResultText(context, finalMatch, extras);
    return OnTapScale(
      onTap: () => AppRoute.teamDetail(teamId: team.id).push(context),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brandNavyColor, Color(0xFF1A1A4A)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brandRedColor.withValues(alpha: 0.18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: MediaQuery.withNoTextScaling(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: brandRedColor,
                      ),
                      child: TeamBadge(team, size: 60),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded,
                                  size: 16, color: brandRedColor),
                              const SizedBox(width: 6),
                              Text(
                                context.l10n.tournament_overview_champions
                                    .toUpperCase(),
                                style: AppTextStyle.caption.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            team.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.header3
                                .copyWith(color: Colors.white),
                          ),
                          if (owner != null || result != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (owner != null)
                                  context.l10n.tournament_team_owner(owner!),
                                if (result != null) result,
                              ].join('  ·  '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.caption
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
