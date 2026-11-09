import 'package:data/api/match/match_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/grouped_list.dart';
import 'package:khelo/components/match_detail_cell.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/callback/on_visible_callback.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:khelo/components/mascot/mascot_on_appear.dart';
import 'package:khelo/components/mascot/mascot_reactions.dart';

import '../../../domain/extensions/widget_extension.dart';
import 'match_list_view_model.dart';

class MatchListScreen extends ConsumerStatefulWidget {
  const MatchListScreen({super.key});

  @override
  ConsumerState createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen>
    with WidgetsBindingObserver {
  late MatchListViewNotifier notifier;

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
    final state = ref.watch(matchListStateProvider);
    notifier = ref.watch(matchListStateProvider.notifier);

    return _matchList(context, notifier, state);
  }

  Widget _matchList(
    BuildContext context,
    MatchListViewNotifier notifier,
    MatchListViewState state,
  ) {
    if (state.loading && state.matches.isEmpty) {
      return const Center(child: AppProgressIndicator());
    }
    if (state.error != null && state.matches.isEmpty) {
      return ErrorScreen(
        error: state.error,
        onRetryTap: notifier.loadMatches,
      );
    }

    return (state.matches.isNotEmpty)
        ? ListView.separated(
            padding: context.mediaQueryPadding +
                const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: state.matches.length + (notifier.hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index < state.matches.length) {
                final match = state.matches[index];
                return MatchDetailCell(
                  match: match,
                  showActionButtons: match.created_by == state.currentUserId,
                  onTap: () =>
                      AppRoute.matchDetailTab(matchId: match.id).push(context),
                  onActionTap: () {
                    if (match.match_status == MatchStatus.yetToStart) {
                      AppRoute.addMatch(matchId: match.id).push(context);
                    } else if (match.match_status == MatchStatus.running) {
                      if (match.toss_decision == null ||
                          match.toss_winner_id == null) {
                        AppRoute.addTossDetail(matchId: match.id).push(context);
                      } else {
                        AppRoute.scoreBoard(matchId: match.id).push(context);
                      }
                    }
                  },
                );
              }
              return OnVisibleCallback(
                onVisible: () => runPostFrame(notifier.loadMore),
                child: (state.loading && state.matches.isNotEmpty)
                    ? const Center(child: AppProgressIndicator())
                    : const SizedBox(),
              );
            },
          )
        : MascotOnAppear(
            reaction: MascotReaction.emptyMatches,
            child: BrandEmptyState(
              icon: CupertinoIcons.sportscourt_fill,
              title: context.l10n.match_list_no_match_here_title,
              description: context.l10n.my_cricket_empty_matches_body,
              buttonTitle: context.l10n.home_screen_create_match_btn,
              onTap: () => AppRoute.addMatch().push(context),
            ),
          );
  }
}
