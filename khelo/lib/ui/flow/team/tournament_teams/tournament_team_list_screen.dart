import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/action_bottom_sheet.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/confirmation_dialog.dart';
import 'package:khelo/components/empty_screen.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/button/action_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/text/search_text_field.dart';

import 'components/info_dialog.dart';
import 'components/tournament_team_form_sheet.dart';
import 'components/tournament_team_tile.dart';
import 'tournament_team_list_view_model.dart';

/// Teams of one pool (e.g. "GCPL Teams"). A null [poolId] shows the teams
/// created before pools existed, which can be moved into a pool.
class TournamentTeamListScreen extends ConsumerStatefulWidget {
  final String? poolId;

  const TournamentTeamListScreen({super.key, this.poolId});

  @override
  ConsumerState<TournamentTeamListScreen> createState() =>
      _TournamentTeamListScreenState();
}

class _TournamentTeamListScreenState
    extends ConsumerState<TournamentTeamListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isUngrouped => widget.poolId == null;

  TournamentTeamListViewNotifier get _notifier =>
      ref.read(tournamentTeamListStateProvider(widget.poolId).notifier);

  void _addTeam() =>
      TournamentTeamFormSheet.show(context, poolId: widget.poolId);

  @override
  Widget build(BuildContext context) {
    final provider = tournamentTeamListStateProvider(widget.poolId);
    ref.listen(provider.select((s) => s.actionError), (_, next) {
      if (next != null) showErrorSnackBar(context: context, error: next);
    });
    final state = ref.watch(provider);

    return AppPage(
      title: _isUngrouped
          ? context.l10n.team_pools_ungrouped
          : state.pool?.name ?? context.l10n.tournament_teams_title,
      actions: [
        if (!_isUngrouped)
          actionButton(
            context,
            onPressed: _addTeam,
            icon: Icon(
              CupertinoIcons.add,
              color: context.colorScheme.textPrimary,
            ),
          ),
      ],
      body: Builder(builder: (context) => _body(context, state)),
    );
  }

  Widget _body(BuildContext context, TournamentTeamListState state) {
    final teams = state.poolTeams;
    if (state.loading && teams.isEmpty) {
      return const SkeletonList();
    }
    if (state.error != null && teams.isEmpty) {
      return ErrorScreen(error: state.error, onRetryTap: _notifier.load);
    }
    if (teams.isEmpty) {
      return EmptyScreen(
        title: context.l10n.team_pool_teams_empty_title,
        description: context.l10n.team_pool_teams_empty_description,
        isShowButton: !_isUngrouped,
        buttonTitle: context.l10n.tournament_teams_add_first_team,
        onTap: _addTeam,
      );
    }

    final filtered = state.filteredTeams;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8) +
              EdgeInsets.only(top: context.mediaQueryPadding.top),
          child: SearchTextField(
            controller: _searchController,
            hintText: context.l10n.tournament_teams_search_hint,
            onChange: () => _notifier.onSearch(_searchController.text),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    context.l10n
                        .tournament_teams_no_search_result(state.query.trim()),
                    style: AppTextStyle.body2
                        .copyWith(color: context.colorScheme.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24) +
                      EdgeInsets.only(bottom: context.mediaQueryPadding.bottom),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _teamTile(context, state, filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _teamTile(
    BuildContext context,
    TournamentTeamListState state,
    TournamentTeam team,
  ) {
    return TournamentTeamTile(
      team: team,
      onTap: () =>
          AppRoute.tournamentTeamPlayers(teamId: team.id).push(context),
      trailing: IconButton(
        tooltip: context.l10n.team_pools_team_actions,
        icon: Icon(
          CupertinoIcons.ellipsis,
          color: context.colorScheme.textSecondary,
        ),
        onPressed: () => _teamActions(context, state, team),
      ),
    );
  }

  void _teamActions(
    BuildContext context,
    TournamentTeamListState state,
    TournamentTeam team,
  ) {
    showActionBottomSheet(context: context, items: [
      BottomSheetAction(
        title: context.l10n.tournament_teams_edit_team,
        onTap: () {
          context.pop();
          TournamentTeamFormSheet.show(context, team: team);
        },
      ),
      BottomSheetAction(
        title: context.l10n.team_pools_move_to_pool,
        onTap: () {
          context.pop();
          _moveToPool(context, state, team);
        },
      ),
      BottomSheetAction(
        title: context.l10n.common_delete_title,
        onTap: () {
          context.pop();
          _confirmDelete(context, team);
        },
      ),
    ]);
  }

  void _moveToPool(
    BuildContext context,
    TournamentTeamListState state,
    TournamentTeam team,
  ) {
    final targets = state.pools.where((pool) => pool.id != team.poolId);
    if (targets.isEmpty) {
      showInfoDialog(
        context,
        title: context.l10n.team_pools_move_to_pool,
        message: context.l10n.team_pools_no_other_pools,
      );
      return;
    }
    showActionBottomSheet(
      context: context,
      items: targets
          .map((pool) => BottomSheetAction(
                title: pool.name,
                onTap: () {
                  context.pop();
                  _notifier.moveTeam(team, pool);
                },
              ))
          .toList(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, TournamentTeam team) async {
    final int usage;
    try {
      usage = await _notifier.usageCount(team);
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context: context, error: error);
      return;
    }
    if (!context.mounted) return;

    if (usage > 0) {
      showInfoDialog(
        context,
        title: context.l10n.tournament_teams_in_use_title,
        message:
            context.l10n.tournament_teams_in_use_description(team.name, usage),
      );
      return;
    }

    showConfirmationDialog(
      context,
      title: context.l10n.tournament_teams_delete_title,
      message: context.l10n.tournament_teams_delete_description(team.name),
      confirmBtnText: context.l10n.common_delete_title,
      onConfirm: () => _notifier.deleteTeam(team),
    );
  }
}
