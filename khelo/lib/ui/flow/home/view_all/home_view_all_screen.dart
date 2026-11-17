import 'package:data/api/tournament/tournament_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/empty_screen.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/match_detail_cell.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/extensions/widget_extension.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/home/components/tournament_card.dart';
import 'package:khelo/ui/flow/home/home_view_model.dart';
import 'package:khelo/ui/flow/home/view_all/home_view_all_view_model.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/callback/on_visible_callback.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/text/search_text_field.dart';
import 'package:style/theme/shadows.dart';

class HomeViewAllScreen extends ConsumerStatefulWidget {
  final MatchStatusLabel? status;
  final bool isTournament;

  const HomeViewAllScreen({
    super.key,
    this.status,
    this.isTournament = false,
  });

  @override
  ConsumerState<HomeViewAllScreen> createState() => _HomeViewAllScreenState();
}

class _HomeViewAllScreenState extends ConsumerState<HomeViewAllScreen> {
  late HomeViewAllViewNotifier notifier;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;
  String _searchQuery = '';
  int _selectedTabIndex = 0; // 0: All, 1: Live, 2: Upcoming, 3: Completed
  final Set<String> _favoriteIds = <String>{};

  @override
  void initState() {
    super.initState();
    notifier = ref.read(homeViewAllViewProvider.notifier);
    runPostFrame(() => notifier.setData(
          widget.status?.convertStatus() ?? [],
          widget.isTournament,
        ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TournamentStatus _effectiveStatus(TournamentModel t) {
    if (t.status == TournamentStatus.running ||
        t.status == TournamentStatus.finish) {
      return t.status;
    }
    final now = DateTime.now();
    if (t.end_date.isBefore(now)) return TournamentStatus.finish;
    if (t.start_date.isBefore(now) && t.end_date.isAfter(now)) {
      return TournamentStatus.running;
    }
    return TournamentStatus.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewAllViewProvider);

    return AppPage(
      titleWidget: widget.isTournament
          ? _tournamentTitle(context, state.tournaments.length)
          : null,
      title: widget.isTournament ? null : widget.status?.getString(context),
      actions: widget.isTournament ? [_searchButton(context)] : null,
      body: Builder(builder: (context) {
        return widget.isTournament
            ? _tournamentBody(context, state)
            : _matchBody(context, state);
      }),
    );
  }

  Widget _tournamentTitle(BuildContext context, int totalCount) {
    final cs = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'All tournaments',
          style: AppTextStyle.header3.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: cs.containerLowOnSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$totalCount',
            style: AppTextStyle.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchButton(BuildContext context) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: OnTapScale(
        onTap: () {
          setState(() {
            _isSearchOpen = !_isSearchOpen;
            if (!_isSearchOpen) {
              _searchController.clear();
              _searchQuery = '';
            }
          });
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _isSearchOpen
                ? cs.primary.withValues(alpha: 0.12)
                : cs.card,
            shape: BoxShape.circle,
            boxShadow: cs.cardShadow,
            border: Border.all(
              color: _isSearchOpen
                  ? cs.primary
                  : cs.outline.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            _isSearchOpen ? CupertinoIcons.clear : CupertinoIcons.search,
            size: 18,
            color: _isSearchOpen ? cs.primary : cs.textPrimary,
          ),
        ),
      ),
    );
  }

  // ── Tournament Body with Search, Filter Tabs & Cards ─────────────────────

  Widget _tournamentBody(BuildContext context, HomeViewAllViewState state) {
    final cs = context.colorScheme;

    if (state.loading && state.tournaments.isEmpty) {
      return const SkeletonCards();
    }
    if (state.error != null && state.tournaments.isEmpty) {
      return ErrorScreen(
        error: state.error,
        onRetryTap: notifier.loadTournaments,
      );
    }

    // Apply search filter
    var list = state.tournaments;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((t) {
        final nameMatch = t.name.toLowerCase().contains(q);
        final typeMatch =
            t.type.getString(context).toLowerCase().contains(q);
        return nameMatch || typeMatch;
      }).toList();
    }

    // Tab counts
    final allCount = list.length;
    final liveCount = list
        .where((t) => _effectiveStatus(t) == TournamentStatus.running)
        .length;
    final upcomingCount = list
        .where((t) => _effectiveStatus(t) == TournamentStatus.upcoming)
        .length;
    final completedCount = list
        .where((t) => _effectiveStatus(t) == TournamentStatus.finish)
        .length;

    // Filter by selected tab
    List<TournamentModel> displayed;
    switch (_selectedTabIndex) {
      case 1:
        displayed = list
            .where((t) => _effectiveStatus(t) == TournamentStatus.running)
            .toList();
        break;
      case 2:
        displayed = list
            .where((t) => _effectiveStatus(t) == TournamentStatus.upcoming)
            .toList();
        break;
      case 3:
        displayed = list
            .where((t) => _effectiveStatus(t) == TournamentStatus.finish)
            .toList();
        break;
      default:
        displayed = list;
        break;
    }

    return Column(
      children: [
        // Collapsible Search Bar
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _isSearchOpen
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: SearchTextField(
                    controller: _searchController,
                    hintText: 'Search tournaments by name...',
                    onChange: () {
                      setState(() {
                        _searchQuery = _searchController.text;
                      });
                    },
                    suffixIcon: _searchQuery.isNotEmpty
                        ? CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(
                              CupertinoIcons.clear_circled_solid,
                              size: 18,
                              color: cs.textDisabled,
                            ),
                          )
                        : null,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Filter Tabs (All, Live, Upcoming, Completed)
        _filterTabs(
          context,
          allCount: allCount,
          liveCount: liveCount,
          upcomingCount: upcomingCount,
          completedCount: completedCount,
        ),

        const SizedBox(height: 4),

        // Tournament List or Empty State
        Expanded(
          child: displayed.isEmpty
              ? _tournamentEmptyState(context)
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    4,
                    0,
                    context.mediaQueryPadding.bottom + 20,
                  ),
                  itemCount: displayed.length + 1,
                  itemBuilder: (context, index) {
                    if (index < displayed.length) {
                      final item = displayed[index];
                      final isFav = _favoriteIds.contains(item.id);
                      return TournamentCard(
                        tournament: item,
                        isFavorite: isFav,
                        onFavoriteToggle: () {
                          setState(() {
                            if (isFav) {
                              _favoriteIds.remove(item.id);
                            } else {
                              _favoriteIds.add(item.id);
                            }
                          });
                        },
                      );
                    }
                    return OnVisibleCallback(
                      onVisible: () => runPostFrame(notifier.loadTournaments),
                      child: (state.loading && state.tournaments.isNotEmpty)
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: AppProgressIndicator()),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterTabs(
    BuildContext context, {
    required int allCount,
    required int liveCount,
    required int upcomingCount,
    required int completedCount,
  }) {
    final cs = context.colorScheme;
    final tabs = [
      ('All', allCount),
      ('Live', liveCount),
      ('Upcoming', upcomingCount),
      ('Completed', completedCount),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.containerLowOnSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            final tab = tabs[index];

            Color badgeBg;
            Color badgeText;
            if (isSelected) {
              if (index == 1) {
                badgeBg = const Color(0xFFDCFCE7);
                badgeText = const Color(0xFF16A34A);
              } else if (index == 2) {
                badgeBg = const Color(0xFFFEF3C7);
                badgeText = const Color(0xFFD97706);
              } else if (index == 3) {
                badgeBg = const Color(0xFFE2E8F0);
                badgeText = const Color(0xFF64748B);
              } else {
                badgeBg = cs.containerLowOnSurface;
                badgeText = cs.textPrimary;
              }
            } else {
              badgeBg = cs.outline.withValues(alpha: 0.14);
              badgeText = cs.textSecondary;
            }

            return OnTapScale(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? cs.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? cs.cardShadow : null,
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

  Widget _tournamentEmptyState(BuildContext context) {
    String message;
    switch (_selectedTabIndex) {
      case 1:
        message = 'No live tournaments right now';
        break;
      case 2:
        message = 'No upcoming tournaments scheduled';
        break;
      case 3:
        message = 'No completed tournaments yet';
        break;
      default:
        message = _searchQuery.isNotEmpty
            ? 'No tournaments matching "$_searchQuery"'
            : 'No tournaments found';
        break;
    }

    return EmptyScreen(
      title: 'No Tournaments',
      description: message,
      isShowButton: false,
    );
  }

  // ── Match List Body (Matches View All) ───────────────────────────────────

  Widget _matchBody(BuildContext context, HomeViewAllViewState state) {
    if (state.loading && state.matches.isEmpty) {
      return const SkeletonCards();
    }
    if (state.error != null && state.matches.isEmpty) {
      return ErrorScreen(
        error: state.error,
        onRetryTap: notifier.loadMatches,
      );
    }

    return Padding(
      padding: context.mediaQueryPadding,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.matches.length + 1,
        itemBuilder: (context, index) {
          if (index < state.matches.length) {
            final match = state.matches[index];
            return MatchDetailCell(
              match: match,
              onTap: () =>
                  AppRoute.matchDetailTab(matchId: match.id).push(context),
            );
          }
          return OnVisibleCallback(
            onVisible: () => runPostFrame(notifier.loadMatches),
            child: (state.loading && state.matches.isNotEmpty)
                ? const Center(child: AppProgressIndicator())
                : const SizedBox.shrink(),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
      ),
    );
  }
}
