import 'package:data/api/team/team_model.dart';
import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/confirmation_dialog.dart';
import 'package:khelo/components/empty_screen.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/widget_extension.dart';
import 'package:khelo/ui/flow/team/tournament_teams/components/team_pool_chips.dart';
import 'package:khelo/ui/flow/team/tournament_teams/components/team_pool_form_sheet.dart';
import 'package:khelo/ui/flow/team/tournament_teams/components/team_pool_tile.dart';
import 'package:khelo/ui/flow/team/tournament_teams/components/tournament_team_form_sheet.dart';
import 'package:khelo/ui/flow/team/tournament_teams/components/tournament_team_tile.dart';
import 'package:khelo/ui/flow/team/tournament_teams/pools/team_pool_list_view_model.dart';
import 'package:style/button/bottom_sticky_overlay.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/button/secondary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/text/search_text_field.dart';
import 'package:style/widgets/rounded_check_box.dart';

import 'tournament_team_picker_view_model.dart';

/// "Select Teams" step of tournament creation: choose a pool, then its teams.
/// Pops with a [TournamentTeamPickerResult].
class TournamentTeamPickerScreen extends ConsumerStatefulWidget {
  final List<TeamModel> selectedTeams;

  const TournamentTeamPickerScreen({super.key, this.selectedTeams = const []});

  @override
  ConsumerState<TournamentTeamPickerScreen> createState() =>
      _TournamentTeamPickerScreenState();
}

class _TournamentTeamPickerScreenState
    extends ConsumerState<TournamentTeamPickerScreen> {
  final _searchController = TextEditingController();
  late final TournamentTeamPickerViewNotifier _notifier =
      ref.read(tournamentTeamPickerStateProvider.notifier);

  @override
  void initState() {
    super.initState();
    runPostFrame(() => _notifier.setData(widget.selectedTeams));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TournamentTeamPickerState get _state =>
      ref.read(tournamentTeamPickerStateProvider);

  /// Switching pools while teams are selected asks to clear the selection.
  void _switchPool(String? poolId, {String? poolName}) {
    final state = _state;
    final isCurrent = state.poolChosen &&
        (poolId == null
            ? state.ungroupedSelected
            : !state.ungroupedSelected && state.selectedPoolId == poolId);
    if (isCurrent) return;
    if (state.selectedIds.isEmpty) {
      _notifier.selectPool(poolId);
      return;
    }
    final name = poolName ??
        (poolId == null
            ? context.l10n.team_pools_ungrouped
            : state.pools.where((p) => p.id == poolId).firstOrNull?.name ??
                context.l10n.team_pools_new_pool);
    showConfirmationDialog(
      context,
      title: context.l10n.tournament_team_picker_switch_pool_title,
      message: context.l10n.tournament_team_picker_switch_pool_description(
        name,
        state.selectedIds.length,
      ),
      confirmBtnText: context.l10n.tournament_team_picker_switch,
      onConfirm: () => _notifier.selectPool(poolId, clearSelection: true),
    );
  }

  Future<void> _newPool() async {
    final poolId = await TeamPoolFormSheet.show(context);
    if (poolId != null && mounted) _switchPool(poolId);
  }

  Future<void> _addNewTeam() async {
    final poolId = _state.selectedPool?.id;
    if (poolId == null) return;
    final teamId = await TournamentTeamFormSheet.show(context, poolId: poolId);
    if (teamId != null) _notifier.select(teamId);
  }

  Future<void> _continue() async {
    final result = await _notifier.confirm();
    if (result != null && mounted) context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tournamentTeamPickerStateProvider.select((s) => s.actionError),
        (_, next) {
      if (next != null) showErrorSnackBar(context: context, error: next);
    });
    final state = ref.watch(tournamentTeamPickerStateProvider);

    return AppPage(
      title: context.l10n.tournament_team_picker_title,
      body: Builder(builder: (context) => _body(context, state)),
    );
  }

  Widget _body(BuildContext context, TournamentTeamPickerState state) {
    if (state.loading && !state.hasAnything) {
      return const Center(child: AppProgressIndicator());
    }
    if (state.error != null && !state.hasAnything) {
      return ErrorScreen(error: state.error, onRetryTap: _notifier.load);
    }
    if (!state.hasAnything) {
      return EmptyScreen(
        title: context.l10n.team_pools_empty_title,
        description: context.l10n.team_pools_empty_description,
        buttonTitle: context.l10n.team_pools_create_first,
        onTap: _newPool,
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(height: context.mediaQueryPadding.top + 8),
            TeamPoolChips(
              pools: state.pools,
              showUngrouped: state.ungroupedTeams.isNotEmpty,
              selectedPoolId: state.poolChosen ? state.selectedPoolId : null,
              ungroupedSelected: state.poolChosen && state.ungroupedSelected,
              onSelect: _switchPool,
              onNewPool: _newPool,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SearchTextField(
                controller: _searchController,
                hintText: context.l10n.team_pools_search_hint,
                onChange: () => _notifier.onSearch(_searchController.text),
              ),
            ),
            if (state.searching)
              Expanded(child: _poolResults(context, state))
            else ...[
              _toolbar(context, state),
              Expanded(child: _teamList(context, state)),
            ],
          ],
        ),
        BottomStickyOverlay(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!state.canContinue)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    context.l10n.tournament_team_picker_min_teams,
                    style: AppTextStyle.caption
                        .copyWith(color: context.colorScheme.textSecondary),
                  ),
                ),
              PrimaryButton(
                context.l10n
                    .tournament_team_picker_done(state.selectedIds.length),
                enabled: state.canContinue,
                progress: state.saving,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  EdgeInsets _listPadding(BuildContext context) =>
      const EdgeInsets.fromLTRB(16, 4, 16, 16) +
      EdgeInsets.only(bottom: context.mediaQueryPadding.bottom) +
      BottomStickyOverlay.padding;

  void _openSearchedPool(TeamPool pool) {
    _searchController.clear();
    _notifier.onSearch('');
    FocusScope.of(context).unfocus();
    _switchPool(pool.id, poolName: pool.name);
  }

  Widget _poolResults(BuildContext context, TournamentTeamPickerState state) {
    final pools = state.filteredPools;
    if (pools.isEmpty) {
      return _hint(
        context,
        context.l10n.team_pools_no_search_result(state.query.trim()),
      );
    }
    return ListView.separated(
      padding: _listPadding(context).copyWith(top: 12),
      itemCount: pools.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final pool = pools[index];
        final teams = state.teamsInPool(pool.id);
        return TeamPoolTile(
          name: pool.name,
          shortName: pool.shortName,
          logo: pool.logo,
          teamCount: teams.length,
          playerCount: playerCountOf(teams),
          onTap: () => _openSearchedPool(pool),
        );
      },
    );
  }

  Widget _teamList(BuildContext context, TournamentTeamPickerState state) {
    final teams = state.filteredTeams;
    final canAddTeam = state.selectedPool != null;
    final padding = _listPadding(context);

    if (!state.poolChosen && teams.isEmpty) {
      return _hint(context, context.l10n.tournament_team_picker_choose_pool);
    }

    final header = <Widget>[
      if (canAddTeam) _addNewTeamButton(context),
      if (teams.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: _hint(context, context.l10n.team_pool_teams_empty_title),
        ),
    ];
    return ListView.separated(
      padding: padding,
      itemCount: header.length + teams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        return _teamTile(context, state, teams[index - header.length]);
      },
    );
  }

  Widget _hint(BuildContext context, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyle.body2
              .copyWith(color: context.colorScheme.textSecondary),
        ),
      ),
    );
  }

  Widget _toolbar(BuildContext context, TournamentTeamPickerState state) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n
                  .tournament_team_picker_selected(state.selectedIds.length),
              style: AppTextStyle.subtitle2.copyWith(color: cs.textSecondary),
            ),
          ),
          TextButton(
            onPressed: state.filteredTeams.isEmpty ? null : _notifier.selectAll,
            child: Text(context.l10n.tournament_team_picker_select_all),
          ),
          TextButton(
            onPressed: state.selectedIds.isEmpty ? null : _notifier.clear,
            child: Text(context.l10n.tournament_team_picker_clear),
          ),
        ],
      ),
    );
  }

  Widget _teamTile(
    BuildContext context,
    TournamentTeamPickerState state,
    TournamentTeam team,
  ) {
    final selected = state.selectedIds.contains(team.id);
    final isExtra = state.extraTeams.any((extra) => extra.id == team.id);
    return Semantics(
      label: team.name,
      selected: selected,
      child: TournamentTeamTile(
        team: team,
        highlighted: selected,
        caption:
            isExtra ? context.l10n.tournament_team_picker_not_in_pool : null,
        onTap: () => _notifier.toggle(team.id),
        leading: RoundedCheckBox(
          isSelected: selected,
          onTap: (_) => _notifier.toggle(team.id),
        ),
      ),
    );
  }

  Widget _addNewTeamButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SecondaryButton(
        context.l10n.tournament_team_picker_add_new,
        onPressed: _addNewTeam,
      ),
    );
  }
}
