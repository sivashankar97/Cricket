import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/empty_screen.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/tournament/components/sliver_header_delegate.dart';
import 'package:khelo/ui/flow/tournament/detail/components/delete_tournament_dialog.dart';
import 'package:khelo/ui/flow/tournament/detail/components/flexible_space.dart';
import 'package:khelo/ui/flow/tournament/detail/summary/tournament_summary_provider.dart';
import 'package:khelo/ui/flow/tournament/detail/tabs/tournament_detail_matches_tab.dart';
import 'package:khelo/ui/flow/tournament/detail/tabs/tournament_detail_overview_tab.dart';
import 'package:khelo/ui/flow/tournament/detail/tabs/tournament_detail_points_table_tab.dart';
import 'package:khelo/ui/flow/tournament/detail/tabs/tournament_detail_stats_tab.dart';
import 'package:khelo/ui/flow/tournament/detail/tabs/tournament_detail_teams_tab.dart';
import 'package:khelo/ui/flow/tournament/detail/tournament_detail_view_model.dart';
import 'package:khelo/ui/flow/tournament/team_picker/tournament_team_picker_view_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:style/animations/app_animations.dart';
import 'package:style/animations/fade_slide_in.dart';
import 'package:style/button/action_button.dart';
import 'package:style/platform.dart';
import 'package:style/button/more_option_button.dart';
import 'package:style/button/tab_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/theme/colors.dart';

import '../../../../components/action_bottom_sheet.dart';
import '../../../../components/app_page.dart';
import '../../../../components/error_screen.dart';
import '../../../../components/error_snackbar.dart';
import '../../../../domain/extensions/widget_extension.dart';
import '../../../../main.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen> {
  late TournamentDetailStateViewNotifier notifier;
  late PageController _controller;

  int get _selectedTab => _controller.hasClients
      ? _controller.page?.round() ?? 0
      : _controller.initialPage;

  @override
  void initState() {
    super.initState();
    notifier = ref.read(tournamentDetailStateProvider.notifier);
    _controller = PageController(
      initialPage: ref.read(tournamentDetailStateProvider).selectedTab,
    );
    runPostFrame(() => notifier.setData(widget.tournamentId));
    // Tabs are disposed when off screen; keep the shared data loaded so
    // switching tabs doesn't refetch every ball.
    for (final provider in [
      tournamentSummaryProvider,
      tournamentSummaryLoadingProvider,
      tournamentMatchExtrasProvider,
      tournamentTeamExtrasProvider,
      tournamentPlayerPhotosProvider,
    ]) {
      ref.listenManual(provider, (_, __) {});
    }
  }

  void _observeActionError(BuildContext context) {
    ref.listen(
        tournamentDetailStateProvider.select((value) => value.actionError),
        (previous, next) {
      if (next != null) {
        showErrorSnackBar(context: context, error: next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _observeActionError(context);

    final state = ref.watch(tournamentDetailStateProvider);

    return AppPage(
      body: Builder(builder: (context) {
        return _body(context, state);
      }),
    );
  }

  Widget _body(BuildContext context, TournamentDetailState state) {
    if (state.loading) {
      return const Center(child: AppProgressIndicator());
    }
    if (state.error != null) {
      return ErrorScreen(
        error: state.error,
        onRetryTap: notifier.loadTournament,
      );
    }

    if (state.tournament == null) {
      return EmptyScreen(
        title: context.l10n.tournament_detail_not_found_title,
        description: context.l10n.tournament_detail_not_found_description,
        isShowButton: false,
      );
    }

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            pinned: true,
            expandedHeight: FlexibleSpace.expandedHeight,
            backgroundColor: brandNavyColor,
            surfaceTintColor: Colors.transparent,
            leading: _backButton(context),
            flexibleSpace: FlexibleSpace(
              tournament: state.tournament!,
              matches: state.matches,
            ),
            actions: [
              _shareButton(
                context,
                onShareTap: () => Share.shareUri(Uri.parse(
                    "$appBaseUrl/tournament/${state.tournament!.id}")),
              ),
              if (state.tournament!.created_by == state.currentUserId ||
                  state.tournament!.members
                      .any((element) => element.id == state.currentUserId)) ...[
                moreOptionButton(
                  context,
                  size: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  tintColor: Colors.white,
                  onPressed: () => _moreActionButton(context, state),
                )
              ],
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverPersistentDelegate(
              child: FadeSlideIn(child: _tabSelection(context)),
              size: 70,
            ),
          ),
        ];
      },
      body: _content(context, state),
    );
  }

  Widget _content(BuildContext context, TournamentDetailState state) {
    return Container(
      color: context.colorScheme.containerLow,
      child: PageView(
        controller: _controller,
        onPageChanged: notifier.onTabChange,
        children: [
          TournamentDetailOverviewTab(
            controller: _controller,
          ),
          TournamentDetailMatchesTab(
            onMatchFilter: notifier.onMatchFilter,
            onAddMatchTap: () => _handleAddMatchTap(context, state),
          ),
          const TournamentDetailPointsTableTab(),
          const TournamentDetailStatsTab(),
          TournamentDetailTeamsTab(
            onSelected: notifier.onTeamsSelected,
          ),
        ],
      ),
    );
  }

  Widget _tabSelection(BuildContext context) {
    final tabs = [
      context.l10n.tournament_detail_overview_tab,
      context.l10n.common_matches_title,
      context.l10n.tournament_detail_points_table_tab,
      context.l10n.common_stats_title,
      context.l10n.common_teams_title,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TabButton(
              tabs[index],
              selected: index == _selectedTab,
              onTap: () {
                _controller.animateToTab(index);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _moreActionButton(
    BuildContext context,
    TournamentDetailState state,
  ) async {
    return showActionBottomSheet(context: context, items: [
      BottomSheetAction(
        title: context.l10n.tournament_detail_teams_select_btn,
        onTap: () async {
          context.pop();
          final result = await AppRoute.tournamentTeamPicker(
                  selectedTeams: state.tournament!.teams)
              .push<TournamentTeamPickerResult>(context);
          if (context.mounted && result != null) {
            notifier.onTeamsSelected(result);
          }
        },
      ),
      BottomSheetAction(
        title: context.l10n.tournament_detail_matches_add_btn,
        onTap: () async {
          context.pop();
          _handleAddMatchTap(context, state);
        },
      ),
      BottomSheetAction(
        title: context.l10n.tournament_detail_members_title,
        onTap: () async {
          context.pop();
          AppRoute.memberSelection(tournament: state.tournament!).push(context);
        },
      ),
      BottomSheetAction(
        title: context.l10n.tournament_detail_edit_title,
        onTap: () async {
          context.pop();
          AppRoute.addTournament(editTournament: state.tournament!)
              .push(context);
        },
      ),
      if (_isOrganizer(state))
        BottomSheetAction(
          title: context.l10n.tournament_delete_action,
          icon: Icon(Icons.delete_outline, color: context.colorScheme.alert),
          onTap: () {
            context.pop();
            _deleteTournament(context, state);
          },
        ),
    ]);
  }

  bool _isOrganizer(TournamentDetailState state) =>
      state.tournament!.created_by == state.currentUserId ||
      state.tournament!.members.any((member) =>
          member.id == state.currentUserId && member.role.isOrganizer);

  Future<void> _deleteTournament(
    BuildContext context,
    TournamentDetailState state,
  ) async {
    final pool = await notifier.poolDeletableWithTournament();
    if (!context.mounted) return;
    final withPool = await showDeleteTournamentDialog(
      context,
      tournamentName: state.tournament!.name,
      pool: pool,
    );
    if (withPool == null) return;
    final deleted =
        await notifier.deleteTournament(pool: withPool ? pool : null);
    if (deleted && context.mounted) context.pop();
  }

  Widget _backButton(BuildContext context) {
    return actionButton(context,
        onPressed: context.pop,
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white.withValues(alpha: 0.16),
          child: Icon(
            isIOS ? Icons.arrow_back_ios_new : Icons.arrow_back,
            size: 20,
            color: Colors.white,
          ),
        ));
  }

  Widget _shareButton(BuildContext context, {required Function() onShareTap}) {
    return actionButton(
      context,
      onPressed: onShareTap,
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        child: Icon(
          isIOS ? Icons.share : Icons.share_outlined,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  void _handleAddMatchTap(
      BuildContext context, TournamentDetailState state) async {
    if (state.tournament == null) {
      return;
    }
    if (state.tournament!.teams.length >= state.tournament!.type.minTeamReq) {
      await AppRoute.matchSelection(tournamentId: state.tournament!.id)
          .push(context);
    } else {
      showErrorSnackBar(
          context: context,
          error: context.l10n.add_tournament_select_min_team_error(
              state.tournament!.type.minTeamReq));
    }
  }
}
