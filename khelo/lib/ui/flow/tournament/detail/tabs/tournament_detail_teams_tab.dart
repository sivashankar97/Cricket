import 'package:data/api/team/team_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/animations/motion.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

import '../../../../../components/empty_screen.dart';
import '../../../../app_route.dart';
import '../../team_picker/tournament_team_picker_view_model.dart';
import '../components/tournament_widgets.dart';
import '../summary/tournament_summary.dart';
import '../summary/tournament_summary_provider.dart';
import '../tournament_detail_view_model.dart';

class TournamentDetailTeamsTab extends ConsumerWidget {
  final Function(TournamentTeamPickerResult) onSelected;

  const TournamentDetailTeamsTab({
    super.key,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tournamentDetailStateProvider);
    final summary = ref.watch(tournamentSummaryProvider);
    final extras = ref.watch(tournamentTeamExtrasProvider);
    final teams = state.tournament!.teams;
    if (teams.isEmpty) {
      return EmptyScreen(
        title: context.l10n.tournament_detail_teams_empty_title,
        description: context.l10n.tournament_detail_teams_empty_description,
        isShowButton: state.tournament!.created_by == state.currentUserId ||
            state.tournament!.members
                .any((element) => element.id == state.currentUserId),
        buttonTitle: context.l10n.tournament_detail_teams_select_btn,
        onTap: () async {
          final result = await AppRoute.tournamentTeamPicker(
                  selectedTeams: state.tournament!.teams)
              .push<TournamentTeamPickerResult>(context);
          if (context.mounted && result != null) {
            onSelected.call(result);
          }
        },
      );
    }

    final ranked = teams.toList()
      ..sort((a, b) {
        int rank(TeamModel t) {
          final r = summary.rankOf(t.id);
          return r == 0 ? 999 : r;
        }

        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : a.name.compareTo(b.name);
      });

    return ListView.separated(
      itemCount: ranked.length,
      padding: context.mediaQueryPadding.copyWith(top: 0) +
          const EdgeInsets.fromLTRB(16, 12, 16, 32),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final team = ranked[index];
        final standing = summary.standingOf(team.id);
        return Appear(
          key: ValueKey(team.id),
          index: index,
          child: OnTapScale(
            onTap: () => AppRoute.teamDetail(teamId: team.id).push(context),
            child: _TeamCard(
              team: team,
              owner: extras[team.id]?.ownerName,
              rank: standing != null && standing.played > 0
                  ? summary.rankOf(team.id)
                  : null,
              standing: standing,
            ),
          ),
        );
      },
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  final String? owner;
  final int? rank;
  final StandingRow? standing;

  const _TeamCard({
    required this.team,
    required this.owner,
    required this.rank,
    required this.standing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final l10n = context.l10n;
    final s = standing;
    return TournamentCard(
      child: MediaQuery.withNoTextScaling(
        child: Column(
          children: [
            Row(
              children: [
                TeamBadge(team, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subtitle1
                            .copyWith(color: cs.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (owner != null) l10n.tournament_team_owner(owner!),
                          l10n.common_players_title(team.players.length),
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.caption
                            .copyWith(color: cs.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (rank != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: rank! <= 4 ? cs.primary : cs.containerLowOnSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#$rank',
                      style: AppTextStyle.subtitle2.copyWith(
                        color: rank! <= 4 ? cs.onPrimary : cs.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            if (s != null && s.played > 0) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  _stat(context, l10n.tournament_col_played, s.played),
                  _stat(context, l10n.tournament_col_won, s.won),
                  _stat(context, l10n.tournament_col_lost, s.lost),
                  _stat(context, l10n.tournament_col_points, s.points,
                      highlight: true),
                  _stat(context, l10n.tournament_col_nrr, s.nrr,
                      decimals: 2, format: formatNrr),
                ],
              ),
              const SizedBox(height: 12),
              GrowBar(
                fraction: s.played == 0 ? 0 : s.won / s.played,
                color: cs.primary,
                height: 5,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    l10n.tournament_col_form,
                    style:
                        AppTextStyle.caption.copyWith(color: cs.textDisabled),
                  ),
                  const Spacer(),
                  FormDots(s.form),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    num value, {
    bool highlight = false,
    int decimals = 0,
    String Function(num)? format,
  }) {
    final cs = context.colorScheme;
    return Expanded(
      child: Column(
        children: [
          CountUp(
            value: value,
            decimals: decimals,
            format: format,
            style: AppTextStyle.subtitle1.copyWith(
              color: highlight ? cs.primary : cs.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: AppTextStyle.caption.copyWith(
              color: cs.textDisabled,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
