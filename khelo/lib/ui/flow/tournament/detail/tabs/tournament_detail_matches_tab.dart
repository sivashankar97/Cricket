import 'package:data/api/match/match_model.dart';
import 'package:data/api/team/team_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/match_detail_cell.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/tournament/detail/components/filter_tab_view.dart';
import 'package:style/button/action_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

import '../../../../../components/action_bottom_sheet.dart';
import '../../../../../components/empty_screen.dart';
import '../tournament_detail_view_model.dart';

enum TournamentMatchStatusFilter {
  all,
  live,
  upcoming,
  past,
}

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
  TournamentMatchStatusFilter _selectedStatus =
      TournamentMatchStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentDetailStateProvider);

    final canManageTournament = state.tournament != null &&
        (state.tournament!.created_by == state.currentUserId ||
            state.tournament!.members
                .any((element) => element.id == state.currentUserId));

    if (state.filteredMatches.isEmpty && state.matches.isEmpty) {
      return EmptyScreen(
        title: context.l10n.tournament_detail_matches_empty_title,
        description: context.l10n.tournament_detail_matches_empty_description,
        buttonTitle: context.l10n.tournament_detail_matches_schedule_btn,
        isShowButton: canManageTournament,
        onTap: widget.onAddMatchTap,
      );
    }

    final allMatches = state.filteredMatches;
    final liveMatches = allMatches
        .where((m) => m.match_status == MatchStatus.running)
        .toList();
    final upcomingMatches = allMatches
        .where((m) => m.match_status == MatchStatus.yetToStart)
        .toList();
    final pastMatches = allMatches
        .where((m) =>
            m.match_status == MatchStatus.finish ||
            m.match_status == MatchStatus.abandoned)
        .toList();

    return ListView(
      padding: context.mediaQueryPadding.copyWith(top: 0) +
          const EdgeInsets.all(16).copyWith(bottom: 32),
      children: [
        _topActionBar(context, state, canManageTournament),
        const SizedBox(height: 12),
        _statusFilterBar(
          context,
          allCount: allMatches.length,
          liveCount: liveMatches.length,
          upcomingCount: upcomingMatches.length,
          pastCount: pastMatches.length,
        ),
        const SizedBox(height: 16),
        ..._buildFilteredMatchList(
          context,
          liveMatches: liveMatches,
          upcomingMatches: upcomingMatches,
          pastMatches: pastMatches,
          allMatches: allMatches,
        ),
      ],
    );
  }

  Widget _topActionBar(
    BuildContext context,
    TournamentDetailState state,
    bool canManageTournament,
  ) {
    return Row(
      children: [
        Expanded(
          child: FilterTabView(
            title: context.l10n.tournament_detail_matches_filter_by_teams_title,
            onFilter: () => showFilterOptionSelectionSheet(
              context,
              matchFilter: state.matchFilter,
              teams: state.tournament?.teams ?? [],
              onTap: widget.onMatchFilter,
            ),
            filterValue: state.matchFilter ??
                context.l10n.tournament_detail_matches_filter_all_teams_option,
          ),
        ),
        if (canManageTournament) ...[
          const SizedBox(width: 8),
          actionButton(
            context,
            onPressed: widget.onAddMatchTap,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.calendar_badge_plus,
                    size: 16,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.tournament_detail_matches_schedule_btn,
                    style: AppTextStyle.caption.copyWith(
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.w600,
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
    BuildContext context, {
    required int allCount,
    required int liveCount,
    required int upcomingCount,
    required int pastCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statusChip(
            context,
            title: '${context.l10n.tournament_detail_matches_all_status} ($allCount)',
            isSelected: _selectedStatus == TournamentMatchStatusFilter.all,
            onTap: () => setState(() => _selectedStatus = TournamentMatchStatusFilter.all),
          ),
          const SizedBox(width: 8),
          _statusChip(
            context,
            title: '${context.l10n.tournament_detail_matches_live_status} ($liveCount)',
            isSelected: _selectedStatus == TournamentMatchStatusFilter.live,
            badgeColor: liveCount > 0 ? context.colorScheme.alert : null,
            onTap: () => setState(() => _selectedStatus = TournamentMatchStatusFilter.live),
          ),
          const SizedBox(width: 8),
          _statusChip(
            context,
            title: '${context.l10n.tournament_detail_matches_upcoming_status} ($upcomingCount)',
            isSelected: _selectedStatus == TournamentMatchStatusFilter.upcoming,
            onTap: () => setState(() => _selectedStatus = TournamentMatchStatusFilter.upcoming),
          ),
          const SizedBox(width: 8),
          _statusChip(
            context,
            title: '${context.l10n.tournament_detail_matches_past_status} ($pastCount)',
            isSelected: _selectedStatus == TournamentMatchStatusFilter.past,
            onTap: () => setState(() => _selectedStatus = TournamentMatchStatusFilter.past),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    final cs = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.containerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null) ...[
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            Text(
              title,
              style: AppTextStyle.caption.copyWith(
                color: isSelected ? Colors.white : cs.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilteredMatchList(
    BuildContext context, {
    required List<MatchModel> liveMatches,
    required List<MatchModel> upcomingMatches,
    required List<MatchModel> pastMatches,
    required List<MatchModel> allMatches,
  }) {
    switch (_selectedStatus) {
      case TournamentMatchStatusFilter.live:
        if (liveMatches.isEmpty) {
          return [
            _emptyStatusView(
              context,
              title: context.l10n.tournament_detail_matches_no_live,
              icon: CupertinoIcons.dot_radiowaves_left_right,
            )
          ];
        }
        return liveMatches.map((m) => _matchItem(context, m)).toList();

      case TournamentMatchStatusFilter.upcoming:
        if (upcomingMatches.isEmpty) {
          return [
            _emptyStatusView(
              context,
              title: context.l10n.tournament_detail_matches_no_upcoming,
              icon: CupertinoIcons.calendar_today,
            )
          ];
        }
        return upcomingMatches.map((m) => _matchItem(context, m)).toList();

      case TournamentMatchStatusFilter.past:
        if (pastMatches.isEmpty) {
          return [
            _emptyStatusView(
              context,
              title: context.l10n.tournament_detail_matches_no_past,
              icon: CupertinoIcons.checkmark_seal,
            )
          ];
        }
        return pastMatches.map((m) => _matchItem(context, m)).toList();

      case TournamentMatchStatusFilter.all:
        if (allMatches.isEmpty) {
          return [
            _emptyStatusView(
              context,
              title: context.l10n.tournament_detail_matches_filter_empty_title,
              icon: CupertinoIcons.search,
            )
          ];
        }

        final widgets = <Widget>[];

        if (liveMatches.isNotEmpty) {
          widgets.add(_sectionHeader(
            context,
            title: context.l10n.tournament_detail_matches_live_section,
            count: liveMatches.length,
            isLive: true,
          ));
          widgets.addAll(liveMatches.map((m) => _matchItem(context, m)));
          widgets.add(const SizedBox(height: 16));
        }

        if (upcomingMatches.isNotEmpty) {
          widgets.add(_sectionHeader(
            context,
            title: context.l10n.tournament_detail_matches_upcoming_section,
            count: upcomingMatches.length,
            icon: CupertinoIcons.calendar_today,
          ));
          widgets.addAll(upcomingMatches.map((m) => _matchItem(context, m)));
          widgets.add(const SizedBox(height: 16));
        }

        if (pastMatches.isNotEmpty) {
          widgets.add(_sectionHeader(
            context,
            title: context.l10n.tournament_detail_matches_past_section,
            count: pastMatches.length,
            icon: CupertinoIcons.checkmark_seal,
          ));
          widgets.addAll(pastMatches.map((m) => _matchItem(context, m)));
        }

        return widgets;
    }
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    bool isLive = false,
    IconData? icon,
  }) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Row(
        children: [
          if (isLive) ...[
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: cs.alert,
                shape: BoxShape.circle,
              ),
            ),
          ] else if (icon != null) ...[
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 6),
          ],
          Text(
            '$title ($count)',
            style: AppTextStyle.subtitle2.copyWith(
              color: isLive ? cs.alert : cs.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchItem(BuildContext context, MatchModel match) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: MatchDetailCell(
        showTournamentBadge: false,
        backgroundColor: context.colorScheme.surface,
        match: match,
        showActionButtons: match.match_status == MatchStatus.running ||
            match.match_status == MatchStatus.yetToStart,
        onTap: () => _handleMatchTap(context, match),
        onActionTap: () => _handleMatchActionTap(context, match),
      ),
    );
  }

  void _handleMatchTap(BuildContext context, MatchModel match) {
    if (match.match_status == MatchStatus.running) {
      if (match.toss_decision == null || match.toss_winner_id == null) {
        AppRoute.addTossDetail(matchId: match.id).push(context);
      } else {
        AppRoute.scoreBoard(matchId: match.id).push(context);
      }
    } else {
      AppRoute.matchDetailTab(matchId: match.id).push(context);
    }
  }

  void _handleMatchActionTap(BuildContext context, MatchModel match) {
    if (match.match_status == MatchStatus.yetToStart) {
      AppRoute.addMatch(matchId: match.id).push(context);
    } else if (match.match_status == MatchStatus.running) {
      if (match.toss_decision == null || match.toss_winner_id == null) {
        AppRoute.addTossDetail(matchId: match.id).push(context);
      } else {
        AppRoute.scoreBoard(matchId: match.id).push(context);
      }
    }
  }

  Widget _emptyStatusView(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

  void showFilterOptionSelectionSheet(
    BuildContext context, {
    required Function(String) onTap,
    String? matchFilter,
    required List<TeamModel> teams,
  }) async {
    final filterOptions = [
      context.l10n.tournament_detail_matches_filter_all_teams_option,
      ...teams.map((e) => e.name)
    ];
    final matchFiltered = matchFilter ?? filterOptions.first;
    return await showActionBottomSheet(
      context: context,
      items: filterOptions
          .map((option) => BottomSheetAction(
                title: option,
                enabled: matchFiltered != option,
                showCheck: matchFiltered == option,
                onTap: () {
                  context.pop();
                  onTap(option);
                },
              ))
          .toList(),
    );
  }
}
