import 'package:data/api/match/match_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/grouped_list.dart';
import 'package:khelo/components/match_detail_cell.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/callback/on_visible_callback.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/theme/shadows.dart';
import 'package:khelo/components/mascot/mascot_on_appear.dart';
import 'package:khelo/components/mascot/mascot_reactions.dart';
import 'package:style/text/app_text_style.dart';

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
  int _selectedCategoryIndex = 0; // 0: All, 1: Independent, 2: Tournaments

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
      return const SkeletonCards();
    }
    if (state.error != null && state.matches.isEmpty) {
      return ErrorScreen(
        error: state.error,
        onRetryTap: notifier.loadMatches,
      );
    }

    if (state.matches.isEmpty) {
      return MascotOnAppear(
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

    final allMatches = state.matches;
    final independentMatches = allMatches
        .where((m) => m.tournament_id == null || m.tournament_id!.isEmpty)
        .toList();
    final tournamentMatches = allMatches
        .where((m) => m.tournament_id != null && m.tournament_id!.isNotEmpty)
        .toList();

    List<MatchModel> displayMatches;
    if (_selectedCategoryIndex == 1) {
      displayMatches = independentMatches;
    } else if (_selectedCategoryIndex == 2) {
      displayMatches = tournamentMatches;
    } else {
      displayMatches = allMatches;
    }

    return Column(
      children: [
        _categoryTabs(
          context,
          allCount: allMatches.length,
          independentCount: independentMatches.length,
          tournamentCount: tournamentMatches.length,
        ),
        Expanded(
          child: displayMatches.isNotEmpty
              ? ListView.separated(
                  padding: context.mediaQueryPadding +
                      const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: displayMatches.length + (notifier.hasMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index < displayMatches.length) {
                      final match = displayMatches[index];
                      return MatchDetailCell(
                        match: match,
                        showActionButtons: match.canScore(state.currentUserId),
                        onTap: () => AppRoute.matchDetailTab(matchId: match.id)
                            .push(context),
                        onActionTap: () {
                          if (match.match_status == MatchStatus.yetToStart &&
                              match.canManage(state.currentUserId)) {
                            AppRoute.addMatch(matchId: match.id).push(context);
                          } else if (match.match_status ==
                                  MatchStatus.running ||
                              match.match_status == MatchStatus.yetToStart) {
                            if (match.toss_decision == null ||
                                match.toss_winner_id == null) {
                              AppRoute.addTossDetail(matchId: match.id)
                                  .push(context);
                            } else {
                              AppRoute.scoreBoard(matchId: match.id)
                                  .push(context);
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
              : _emptyCategoryView(context),
        ),
      ],
    );
  }

  Widget _categoryTabs(
    BuildContext context, {
    required int allCount,
    required int independentCount,
    required int tournamentCount,
  }) {
    final cs = context.colorScheme;
    final tabs = [
      (context.l10n.key_stat_all, allCount),
      ('Independent', independentCount),
      (context.l10n.common_tournaments, tournamentCount),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.containerLowOnSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedCategoryIndex == index;
            final tab = tabs[index];

            Color badgeBg;
            Color badgeText;
            if (isSelected) {
              if (index == 1) {
                // Independent matches
                badgeBg = const Color(0xFFDBEAFE);
                badgeText = const Color(0xFF1D4ED8);
              } else if (index == 2) {
                // Tournament matches
                badgeBg = const Color(0xFFFEF3C7);
                badgeText = const Color(0xFFD97706);
              } else {
                badgeBg = cs.containerLowOnSurface;
                badgeText = cs.textPrimary;
              }
            } else {
              badgeBg = cs.outline.withValues(alpha: 0.14);
              badgeText = cs.textSecondary;
            }

            return OnTapScale(
              onTap: () => setState(() => _selectedCategoryIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? cs.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? context.colorScheme.cardShadow : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.$1,
                      style: AppTextStyle.caption.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? cs.textPrimary : cs.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tab.$2}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _emptyCategoryView(BuildContext context) {
    if (_selectedCategoryIndex == 1) {
      return BrandEmptyState(
        icon: CupertinoIcons.sportscourt,
        title: 'No Independent Matches',
        description:
            'Independent bilateral matches between two teams will appear here.',
        buttonTitle: context.l10n.home_screen_create_match_btn,
        onTap: () => AppRoute.addMatch().push(context),
      );
    }
    return BrandEmptyState(
      icon: CupertinoIcons.sportscourt_fill,
      title: 'No Tournament Matches',
      description:
          'Matches scheduled or played inside tournaments will appear here.',
      buttonTitle: 'View Tournaments',
      onTap: () =>
          AppRoute.viewAll(isTournament: true).push(context),
    );
  }
}
