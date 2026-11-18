import 'package:khelo/domain/permissions/match_access.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:data/api/match/match_model.dart';
import 'assign_scorer_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/confirmation_dialog.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:khelo/domain/extensions/widget_extension.dart';
import 'package:khelo/main.dart';
import 'package:khelo/ui/flow/matches/match_detail/match_detail_tab_view_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:style/animations/app_animations.dart';
import 'package:style/button/action_button.dart';
import 'package:style/platform.dart';
import 'package:style/button/tab_button.dart';
import 'package:style/extensions/context_extensions.dart';

class MatchDetailTabScreen extends ConsumerStatefulWidget {
  final String matchId;

  const MatchDetailTabScreen({super.key, required this.matchId});

  @override
  ConsumerState createState() => _MatchDetailTabScreenState();
}

class _MatchDetailTabScreenState extends ConsumerState<MatchDetailTabScreen> {
  late MatchDetailTabViewNotifier notifier;
  late PageController _controller;
  final ScrollController _scrollController = ScrollController();

  int get _selectedTab => _controller.hasClients
      ? _controller.page?.round() ?? 0
      : _controller.initialPage;

  @override
  void initState() {
    super.initState();
    notifier = ref.read(matchDetailTabStateProvider.notifier);
    runPostFrame(() => notifier.setData(widget.matchId));
    _controller = PageController(
      initialPage: ref.read(matchDetailTabStateProvider).selectedTab,
    );
  }

  final List<GlobalKey> _keys = List.generate(50, (index) => GlobalKey());

  void _scrollToIndex(int index) {
    _scrollController.position.ensureVisible(
        _keys[index].currentContext!.findRenderObject() as RenderBox,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchDetailTabStateProvider);

    return AppPage(
      title: _getScreenTitle(context, state),
      actions: [
        if (ref
                .watch(matchPermissionsProvider(widget.matchId))
                .valueOrNull
                ?.manage ==
            true) ...[
          IconButton(
            tooltip: context.l10n.common_edit,
            icon: Icon(
              CupertinoIcons.pencil,
              size: 20,
              color: context.colorScheme.textPrimary,
            ),
            onPressed: () =>
                AppRoute.addMatch(matchId: widget.matchId).push(context),
          ),
          IconButton(
            tooltip: context.l10n.common_delete_title,
            icon: Icon(
              CupertinoIcons.trash,
              size: 20,
              color: context.colorScheme.alert,
            ),
            onPressed: () => _confirmDelete(context, state.match),
          ),
          IconButton(
              tooltip: 'Assign scorer',
              icon: const Icon(Icons.person_add),
              onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AssignScorerSheet(matchId: widget.matchId))),
        ],
        if (ref
                    .watch(matchPermissionsProvider(widget.matchId))
                    .valueOrNull
                    ?.score ==
                true &&
            state.match != null &&
            state.match!.match_status != MatchStatus.finish &&
            state.match!.match_status != MatchStatus.abandoned)
          IconButton(
              tooltip: 'Start / resume scoring',
              icon: const Icon(Icons.sports_cricket),
              onPressed: () => (state.match!.toss_decision == null ||
                          state.match!.toss_winner_id == null
                      ? AppRoute.addTossDetail(matchId: widget.matchId)
                      : AppRoute.scoreBoard(matchId: widget.matchId))
                  .push(context)),
        actionButton(
          context,
          icon: Icon(
            isIOS ? CupertinoIcons.share : Icons.share_outlined,
            size: 20,
            color: context.colorScheme.textPrimary,
          ),
          onPressed: () =>
              Share.shareUri(Uri.parse("$appBaseUrl/match/${widget.matchId}")),
        )
      ],
      body: Builder(
        builder: (context) {
          return _content(context, notifier);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, MatchModel? match) {
    if (match == null) return;
    final teamA = match.teams.isNotEmpty ? match.teams.first.team.name : '';
    final teamB = match.teams.length > 1 ? match.teams[1].team.name : '';
    showConfirmationDialog(
      context,
      title: context.l10n.match_delete_title,
      message: context.l10n.match_delete_message(teamA, teamB),
      confirmBtnText: context.l10n.common_delete_title,
      onConfirm: () async {
        try {
          await notifier.deleteMatch();
          if (context.mounted) context.pop();
        } catch (error) {
          if (context.mounted) {
            showErrorSnackBar(context: context, error: error);
          }
        }
      },
    );
  }

  String _getScreenTitle(BuildContext context, MatchDetailTabState state) {
    if (state.match != null) {
      String title = state.match!.teams
          .map((e) => e.team.name_initial ?? e.team.name.initials(limit: 3))
          .join(" ${context.l10n.common_versus_short_title} ");
      return title;
    }
    return "${context.l10n.common_a_title} ${context.l10n.common_versus_short_title} ${context.l10n.add_match_team_b_title}";
  }

  Widget _content(BuildContext context, MatchDetailTabViewNotifier notifier) {
    return SafeArea(
      child: Column(
        children: [
          _tabView(context),
          Expanded(
            child: PageView(
              controller: _controller,
              children: MatchDetailTab.values
                  .map((tab) => tab.getTabScreen())
                  .toList(),
              onPageChanged: (index) {
                notifier.onTabChange(index);
                _scrollToIndex(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabView(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      child: Row(
          children: MatchDetailTab.values
              .map(
                (tab) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TabButton(
                    tab.getString(context),
                    selected: _selectedTab == tab.index,
                    globalKey: _keys[tab.index],
                    onTap: () {
                      _controller.animateToTab(tab.index);
                    },
                  ),
                ),
              )
              .toList()),
    );
  }
}
