import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

import '../components/info_dialog.dart';
import '../components/team_pool_form_sheet.dart';
import '../components/team_pool_tile.dart';
import 'team_pool_list_view_model.dart';

/// Landing screen of Tournament Teams: the organizer's pools, e.g. "GCPL Teams".
class TeamPoolListScreen extends ConsumerStatefulWidget {
  const TeamPoolListScreen({super.key});

  @override
  ConsumerState<TeamPoolListScreen> createState() => _TeamPoolListScreenState();
}

class _TeamPoolListScreenState extends ConsumerState<TeamPoolListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TeamPoolListViewNotifier get _notifier =>
      ref.read(teamPoolListStateProvider.notifier);

  @override
  Widget build(BuildContext context) {
    ref.listen(teamPoolListStateProvider.select((s) => s.actionError),
        (_, next) {
      if (next != null) showErrorSnackBar(context: context, error: next);
    });
    final state = ref.watch(teamPoolListStateProvider);

    return AppPage(
      title: context.l10n.tournament_teams_title,
      actions: [
        actionButton(
          context,
          onPressed: () => TeamPoolFormSheet.show(context),
          icon:
              Icon(CupertinoIcons.add, color: context.colorScheme.textPrimary),
        ),
      ],
      body: Builder(builder: (context) => _body(context, state)),
    );
  }

  Widget _body(BuildContext context, TeamPoolListState state) {
    final hasData = state.pools.isNotEmpty || state.teams.isNotEmpty;
    if (state.loading && !hasData) {
      return const SkeletonCards(height: 96);
    }
    if (state.error != null && !hasData) {
      return ErrorScreen(error: state.error, onRetryTap: _notifier.load);
    }
    if (!hasData) {
      return EmptyScreen(
        title: context.l10n.team_pools_empty_title,
        description: context.l10n.team_pools_empty_description,
        buttonTitle: context.l10n.team_pools_create_first,
        onTap: () => TeamPoolFormSheet.show(context),
      );
    }

    final pools = state.filteredPools;
    final ungrouped = state.ungroupedTeams;
    final showUngrouped = ungrouped.isNotEmpty && state.query.trim().isEmpty;
    final itemCount = pools.length + (showUngrouped ? 1 : 0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8) +
              EdgeInsets.only(top: context.mediaQueryPadding.top),
          child: SearchTextField(
            controller: _searchController,
            hintText: context.l10n.team_pools_search_hint,
            onChange: () => _notifier.onSearch(_searchController.text),
          ),
        ),
        Expanded(
          child: itemCount == 0
              ? Center(
                  child: Text(
                    context.l10n
                        .team_pools_no_search_result(state.query.trim()),
                    style: AppTextStyle.body2
                        .copyWith(color: context.colorScheme.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24) +
                      EdgeInsets.only(bottom: context.mediaQueryPadding.bottom),
                  itemCount: itemCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == pools.length) {
                      return _ungroupedTile(context, ungrouped);
                    }
                    return _poolTile(context, state, pools[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _poolTile(
      BuildContext context, TeamPoolListState state, TeamPool pool) {
    final cs = context.colorScheme;
    final teams = state.teamsIn(pool.id);
    return TeamPoolTile(
      name: pool.name,
      shortName: pool.shortName,
      logo: pool.logo,
      teamCount: teams.length,
      playerCount: playerCountOf(teams),
      onTap: () => AppRoute.tournamentTeamPool(poolId: pool.id).push(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.l10n.team_pools_edit_pool,
            icon: Icon(CupertinoIcons.pencil, color: cs.textSecondary),
            onPressed: () => TeamPoolFormSheet.show(context, pool: pool),
          ),
          IconButton(
            tooltip: context.l10n.common_delete_title,
            icon: Icon(CupertinoIcons.trash, color: cs.alert),
            onPressed: () => _confirmDelete(context, pool, teams.length),
          ),
        ],
      ),
    );
  }

  Widget _ungroupedTile(BuildContext context, List<TournamentTeam> teams) {
    return TeamPoolTile(
      name: context.l10n.team_pools_ungrouped,
      teamCount: teams.length,
      playerCount: playerCountOf(teams),
      description: context.l10n.team_pools_ungrouped_description,
      onTap: () => AppRoute.tournamentTeamPool().push(context),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        color: context.colorScheme.textDisabled,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TeamPool pool,
    int teamCount,
  ) async {
    final int usage;
    try {
      usage = await _notifier.usageCount(pool);
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context: context, error: error);
      return;
    }
    if (!context.mounted) return;

    if (usage > 0) {
      showInfoDialog(
        context,
        title: context.l10n.team_pools_in_use_title,
        message: context.l10n.team_pools_in_use_description(pool.name, usage),
      );
      return;
    }

    showConfirmationDialog(
      context,
      title: context.l10n.team_pools_delete_title,
      message: context.l10n.team_pools_delete_description(pool.name, teamCount),
      confirmBtnText: context.l10n.common_delete_title,
      onConfirm: () => _notifier.deletePool(pool),
    );
  }
}
