import 'package:data/api/match/match_model.dart';
import 'package:data/api/team/team_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/tournament/detail/components/filter_tab_view.dart';
import 'package:style/animations/app_animations.dart';
import 'package:style/animations/fade_slide_in.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

import '../../../../../components/action_bottom_sheet.dart';
import '../../../../../components/empty_screen.dart';
import '../components/tournament_match_card.dart';
import '../components/tournament_widgets.dart';
import '../summary/tournament_summary_provider.dart';
import '../tournament_detail_view_model.dart';

enum TournamentMatchStatusFilter { all, live, upcoming, completed }

class TournamentDetailMatchesTab extends ConsumerStatefulWidget {
  final Function(String) onMatchFilter;
  final VoidCallback onAddMatchTap;

  const TournamentDetailMatchesTab({
    super.key,
    required this.onMatchFilter,
    required this.onAddMatchTap,
  });

  @override
  ConsumerState<TournamentDetailMatchesTab> createState() =>
      _TournamentDetailMatchesTabState();
}

class _TournamentDetailMatchesTabState
    extends ConsumerState<TournamentDetailMatchesTab> {
  TournamentMatchStatusFilter _status = TournamentMatchStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentDetailStateProvider);
    final extras = ref.watch(tournamentMatchExtrasProvider);

    final canManage = state.tournament != null &&
        (state.tournament!.created_by == state.currentUserId ||
            state.tournament!.members
                .any((element) => element.id == state.currentUserId));

    if (state.matches.isEmpty) {
      return EmptyScreen(
        title: context.l10n.tournament_detail_matches_empty_title,
        description: context.l10n.tournament_detail_matches_empty_description,
        buttonTitle: context.l10n.tournament_detail_matches_schedule_btn,
        isShowButton: canManage,
        onTap: widget.onAddMatchTap,
      );
    }

    int number(MatchModel m) => matchNumberOf(m, state.matches, extras);
    final all = state.filteredMatches;
    final live =
        all.where((m) => m.match_status == MatchStatus.running).toList();
    final upcoming = all
        .where((m) => m.match_status == MatchStatus.yetToStart)
        .toList()
      ..sort((a, b) => number(a).compareTo(number(b)));
    final completed = all
        .where((m) =>
            m.match_status == MatchStatus.finish ||
            m.match_status == MatchStatus.abandoned)
        .toList()
      ..sort((a, b) => number(b).compareTo(number(a)));

    final shown = switch (_status) {
      TournamentMatchStatusFilter.all => [...live, ...upcoming, ...completed],
      TournamentMatchStatusFilter.live => live,
      TournamentMatchStatusFilter.upcoming => upcoming,
      TournamentMatchStatusFilter.completed => completed,
    };

    return ListView(
      padding: context.mediaQueryPadding.copyWith(top: 0) +
          const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        FadeSlideIn(child: _topActionBar(context, state, canManage)),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: AppAnimations.fast ~/ 4,
          child: _statusFilterBar(context, {
            TournamentMatchStatusFilter.all: all.length,
            TournamentMatchStatusFilter.live: live.length,
            TournamentMatchStatusFilter.upcoming: upcoming.length,
            TournamentMatchStatusFilter.completed: completed.length,
          }),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: AppAnimations.fast,
          child: KeyedSubtree(
            key: ValueKey('${_status.name}-${state.matchFilter}'),
            child: shown.isEmpty
                ? _emptyStatusView(context)
                : Column(
                    children: [
                      for (var i = 0; i < shown.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Appear(
                            key: ValueKey(shown[i].id),
                            index: i,
                            child: TournamentMatchCard(
                              match: shown[i],
                              number: number(shown[i]),
                              extras: extras,
                              onTap: () => _handleMatchTap(context, shown[i]),
                              actionLabel: switch (shown[i].match_status) {
                                MatchStatus.yetToStart =>
                                  context.l10n.common_edit,
                                MatchStatus.running => context
                                    .l10n.tournament_match_continue_scoring,
                                _ => null,
                              },
                              onAction: () =>
                                  _handleMatchActionTap(context, shown[i]),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _topActionBar(
    BuildContext context,
    TournamentDetailState state,
    bool canManage,
  ) {
    return Row(
      children: [
        Expanded(
          child: FilterTabView(
            title: context.l10n.tournament_detail_matches_filter_by_teams_title,
            onFilter: () => _showTeamFilterSheet(
              context,
              matchFilter: state.matchFilter,
              teams: state.tournament?.teams ?? [],
              onTap: widget.onMatchFilter,
            ),
            filterValue: state.matchFilter ??
                context.l10n.tournament_detail_matches_filter_all_teams_option,
          ),
        ),
        if (canManage) ...[
          const SizedBox(width: 8),
          OnTapScale(
            onTap: widget.onAddMatchTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: context.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.calendar_badge_plus,
                      size: 16, color: context.colorScheme.onPrimary),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.tournament_detail_matches_schedule_btn,
                    style: AppTextStyle.caption.copyWith(
                      color: context.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statusFilterBar(
    BuildContext context,
    Map<TournamentMatchStatusFilter, int> counts,
  ) {
    final cs = context.colorScheme;
    String label(TournamentMatchStatusFilter f) => switch (f) {
          TournamentMatchStatusFilter.all =>
            context.l10n.tournament_detail_matches_all_status,
          TournamentMatchStatusFilter.live =>
            context.l10n.tournament_detail_matches_live_status,
          TournamentMatchStatusFilter.upcoming =>
            context.l10n.tournament_detail_matches_upcoming_status,
          TournamentMatchStatusFilter.completed =>
            context.l10n.tournament_matches_completed_status,
        };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in TournamentMatchStatusFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OnTapScale(
                onTap: () => setState(() => _status = f),
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  curve: AppAnimations.curve,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: f == _status ? cs.textPrimary : cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: f == _status
                          ? cs.textPrimary
                          : cs.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (f == TournamentMatchStatusFilter.live &&
                          (counts[f] ?? 0) > 0) ...[
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                              color: cs.alert, shape: BoxShape.circle),
                        ),
                      ],
                      Text(
                        '${label(f)} ${counts[f] ?? 0}',
                        style: AppTextStyle.caption.copyWith(
                          color: f == _status ? cs.surface : cs.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleMatchTap(BuildContext context, MatchModel match) {
    if (match.match_status == MatchStatus.running) {
      _openScoring(context, match);
    } else {
      AppRoute.matchDetailTab(matchId: match.id).push(context);
    }
  }

  void _handleMatchActionTap(BuildContext context, MatchModel match) {
    if (match.match_status == MatchStatus.yetToStart) {
      AppRoute.addMatch(matchId: match.id).push(context);
    } else if (match.match_status == MatchStatus.running) {
      _openScoring(context, match);
    }
  }

  void _openScoring(BuildContext context, MatchModel match) {
    if (match.toss_decision == null || match.toss_winner_id == null) {
      AppRoute.addTossDetail(matchId: match.id).push(context);
    } else {
      AppRoute.scoreBoard(matchId: match.id).push(context);
    }
  }

  Widget _emptyStatusView(BuildContext context) {
    final cs = context.colorScheme;
    final (title, icon) = switch (_status) {
      TournamentMatchStatusFilter.live => (
          context.l10n.tournament_detail_matches_no_live,
          CupertinoIcons.dot_radiowaves_left_right
        ),
      TournamentMatchStatusFilter.upcoming => (
          context.l10n.tournament_detail_matches_no_upcoming,
          CupertinoIcons.calendar_today
        ),
      TournamentMatchStatusFilter.completed => (
          context.l10n.tournament_detail_matches_no_past,
          CupertinoIcons.checkmark_seal
        ),
      TournamentMatchStatusFilter.all => (
          context.l10n.tournament_detail_matches_filter_empty_title,
          CupertinoIcons.search
        ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: cs.textDisabled),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyle.body1.copyWith(color: cs.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showTeamFilterSheet(
    BuildContext context, {
    required Function(String) onTap,
    String? matchFilter,
    required List<TeamModel> teams,
  }) async {
    final options = [
      context.l10n.tournament_detail_matches_filter_all_teams_option,
      ...teams.map((e) => e.name),
    ];
    final selected = matchFilter ?? options.first;
    return await showActionBottomSheet(
      context: context,
      items: options
          .map((option) => BottomSheetAction(
                title: option,
                enabled: selected != option,
                showCheck: selected == option,
                onTap: () {
                  context.pop();
                  onTap(option);
                },
              ))
          .toList(),
    );
  }
}
