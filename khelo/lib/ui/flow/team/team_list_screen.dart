import 'package:data/api/team/team_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/action_bottom_sheet.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/grouped_list.dart';
import 'package:khelo/components/team_detail_cell.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/team/team_list_view_model.dart';
import 'package:khelo/ui/flow/team/tournament_teams/components/tournament_teams_entry_card.dart';
import 'package:style/callback/on_visible_callback.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/text/app_text_style.dart';

import '../../../domain/extensions/widget_extension.dart';
import '../../../gen/assets.gen.dart';

class TeamListScreen extends ConsumerStatefulWidget {
  const TeamListScreen({super.key});

  @override
  ConsumerState createState() => _TeamListScreenState();
}

class _TeamListScreenState extends ConsumerState<TeamListScreen>
    with WidgetsBindingObserver {
  late TeamListViewNotifier notifier;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // deallocate resources
      notifier.dispose();
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    notifier = ref.watch(teamListViewStateProvider.notifier);
    _observeShowFilterOptionSheet(context, ref);

    return AppPage(
      body: Builder(builder: (context) {
        return _body(context);
      }),
    );
  }

  Widget _body(BuildContext context) {
    final state = ref.watch(teamListViewStateProvider);
    if (state.loading && state.teams.isEmpty) {
      return const SkeletonList();
    }
    if (state.error != null && state.teams.isEmpty) {
      return ErrorScreen(
        error: state.error,
        onRetryTap: notifier.loadTeamList,
      );
    }

    const entryCard = Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TournamentTeamsEntryCard(),
    );
    if (state.filteredTeams.isEmpty) {
      return Column(
        children: [
          entryCard,
          Expanded(
            child: BrandEmptyState(
              icon: CupertinoIcons.person_3_fill,
              title: context.l10n.team_list_no_teams_created_title,
              description: context.l10n.my_cricket_empty_teams_body,
              buttonTitle: context.l10n.home_screen_create_team_btn,
              onTap: () => AppRoute.addTeam().push(context),
            ),
          ),
        ],
      );
    }

    final teams = state.filteredTeams;
    return ListView.builder(
      itemCount: teams.length + 2 + (notifier.hasMore ? 1 : 0),
      padding: const EdgeInsets.only(bottom: 120) + context.mediaQueryPadding,
      itemBuilder: (context, index) {
        if (index == 0) return entryCard;
        if (index == 1) {
          return SectionCaption(
            context.l10n.common_teams_title,
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 6),
            trailing: Text(
              '${teams.length}',
              style: AppTextStyle.caption.copyWith(
                color: context.colorScheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        final i = index - 2;
        if (i < teams.length) {
          return _teamRow(
            context,
            teams[i],
            state,
            isFirst: i == 0,
            isLast: i == teams.length - 1,
          );
        }
        return OnVisibleCallback(
          onVisible: () => runPostFrame(notifier.loadMore),
          child: (state.loading && state.teams.isNotEmpty)
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: AppProgressIndicator()),
                )
              : const SizedBox(),
        );
      },
    );
  }

  Widget _teamRow(
    BuildContext context,
    TeamModel team,
    TeamListViewState state, {
    required bool isFirst,
    required bool isLast,
  }) {
    final cs = context.colorScheme;
    const radius = Radius.circular(14);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? radius : Radius.zero,
          bottom: isLast ? radius : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          TeamDetailCell(
            team: team,
            showMoreOptionButton: team.isAdminOrOwner(state.currentUserId),
            onTap: () => AppRoute.teamDetail(teamId: team.id).push(context),
            onMoreOptionTap: () => _moreActionButton(context, team),
          ),
          if (!isLast)
            Divider(
              height: 0.5,
              thickness: 0.5,
              indent: 56,
              color: cs.outline,
            ),
        ],
      ),
    );
  }

  void _moreActionButton(
    BuildContext context,
    TeamModel team,
  ) async {
    return await showActionBottomSheet(context: context, items: [
      BottomSheetAction(
        title: context.l10n.team_detail_add_members_title,
        onTap: () {
          context.pop();
          AppRoute.addTeamMember(team: team).push(context);
        },
      ),
      BottomSheetAction(
        title: context.l10n.common_edit_team_title,
        onTap: () {
          context.pop();
          AppRoute.addTeam(team: team).push(context);
        },
      ),
    ]);
  }

  void _filterActionSheet(
      BuildContext context, TeamFilterOption selectedFilter) async {
    return await showActionBottomSheet(
        context: context,
        items: TeamFilterOption.values
            .map((option) => BottomSheetAction(
                title: option.getString(context),
                enabled: selectedFilter != option,
                child: selectedFilter == option
                    ? SvgPicture.asset(
                        Assets.images.icCheck,
                        colorFilter: ColorFilter.mode(
                          context.colorScheme.primary,
                          BlendMode.srcATop,
                        ),
                      )
                    : null,
                onTap: () {
                  context.pop();
                  notifier.onFilterOptionSelect(option);
                }))
            .toList());
  }

  void _observeShowFilterOptionSheet(
    BuildContext context,
    WidgetRef ref,
  ) {
    ref.listen(
        teamListViewStateProvider
            .select((value) => value.showFilterOptionSheet), (previous, next) {
      if (next != null) {
        final selectedFilter = ref.watch(
            teamListViewStateProvider.select((value) => value.selectedFilter));
        _filterActionSheet(context, selectedFilter);
      }
    });
  }
}
