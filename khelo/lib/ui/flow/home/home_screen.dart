import 'package:data/api/leaderboard/leaderboard_model.dart';
import 'package:data/api/match/match_model.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/empty_screen.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/components/mascot/mascot_reactions.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/home/components/live_match_card.dart';
import 'package:khelo/ui/flow/home/components/match_item.dart';
import 'package:khelo/ui/flow/home/components/tournament_item.dart';
import 'package:khelo/ui/flow/home/home_view_model.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

import '../../../gen/assets.gen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Home rows show only the latest few; "View all" lists the rest.
  static const _homeRowLimit = 5;

  /// Tablets and desktop get a centred column instead of edge-to-edge rows.
  static const _maxContentWidth = 960.0;

  late HomeViewNotifier notifier;

  /// Upcoming soonest first; live and finished most recent first.
  List<MatchModel> _homeOrder(
    MatchStatusLabel label,
    List<MatchModel> matches,
  ) {
    DateTime timeOf(MatchModel m) =>
        m.start_at ?? m.start_time ?? m.updated_at ?? DateTime(0);
    final sorted = [...matches]..sort((a, b) =>
        label == MatchStatusLabel.upcoming
            ? timeOf(a).compareTo(timeOf(b))
            : (b.updated_at ?? timeOf(b)).compareTo(a.updated_at ?? timeOf(a)));
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    notifier = ref.read(homeViewStateProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

  void _greet() {
    if (!mounted) return;
    final name = ref.read(currentUserPod)?.name?.trim().split(' ').first;
    ref.read(mascotProvider.notifier).show(
          MascotPose.welcome,
          name == null || name.isEmpty
              ? mascotText.mascot_welcome_guest
              : mascotText.mascot_welcome_named(name),
          onceKey: 'home_welcome',
          onlyWhenIdle: true,
          delay: const Duration(milliseconds: 900),
          duration: const Duration(seconds: 5),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewStateProvider);
    final cs = context.colorScheme;

    return AppPage(
      titleWidget: _greeting(context),
      actions: [
        if (state.matches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OnTapScale(
              onTap: () => AppRoute.searchHome.push(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.card,
                  shape: BoxShape.circle,
                  boxShadow: cs.cardShadow,
                ),
                child: Icon(
                  CupertinoIcons.search,
                  color: cs.primary,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
      body: Builder(builder: (context) {
        return _body(context, notifier, state);
      }),
    );
  }

  /// Logo mark, greeting and player name.
  Widget _greeting(BuildContext context) {
    final cs = context.colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? context.l10n.home_greeting_morning
        : hour < 17
            ? context.l10n.home_greeting_afternoon
            : context.l10n.home_greeting_evening;
    final name = ref.watch(currentUserPod)?.name?.trim();
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.card,
                shape: BoxShape.circle,
                boxShadow: cs.cardShadow,
              ),
              child: SvgPicture.asset(Assets.images.appLogoMark),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800),
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.card, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '🐯',
                  style: TextStyle(fontSize: 10, height: 1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting,
                    maxLines: 1,
                    style: AppTextStyle.caption.copyWith(
                      color: cs.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('✨', style: TextStyle(fontSize: 10)),
                ],
              ),
              Text(
                name == null || name.isEmpty
                    ? context.l10n.home_greeting_guest
                    : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.header4.copyWith(
                  color: cs.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loadingSkeleton(BuildContext context) {
    Widget header() => const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              SkeletonBox(width: 140, height: 18),
              Spacer(),
              SkeletonBox(width: 56, height: 14),
            ],
          ),
        );
    Widget cardRow(double height) => SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) =>
                SkeletonBox(width: 260, height: height, radius: 16),
          ),
        );

    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: context.mediaQueryPadding + const EdgeInsets.only(top: 4),
        children: [
          header(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonBox(height: 168, radius: 20),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (_) => const Column(
                  children: [
                    SkeletonBox.circle(size: 52),
                    SizedBox(height: 8),
                    SkeletonBox(width: 48, height: 10),
                  ],
                ),
              ),
            ),
          ),
          header(),
          cardRow(140),
          header(),
          cardRow(160),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    HomeViewNotifier notifier,
    HomeViewState state,
  ) {
    if (state.loading && state.matches.isEmpty && state.tournaments.isEmpty) {
      return _loadingSkeleton(context);
    }
    if (state.error != null && state.matches.isEmpty) {
      return ErrorScreen(
        error: state.error,
        onRetryTap: notifier.loadData,
      );
    }

    List<MatchModel> group(MatchStatusLabel label) =>
        _homeOrder(label, state.groupMatches[label] ?? const []);
    final live = group(MatchStatusLabel.live);
    final upcoming = group(MatchStatusLabel.upcoming);
    final finished = group(MatchStatusLabel.finished);

    final list = ListView(
      padding:
          context.mediaQueryPadding + const EdgeInsets.only(top: 4, bottom: 24),
      children: [
        // ── 1. LIVE MATCH ────────────────────────────────────────────────────
        if (live.isNotEmpty) ...[
          _sectionHeader(
            context,
            title: 'LIVE MATCH (${live.length})',
            live: true,
            showViewAll: true,
            actionText: 'View All',
            onViewAll: () =>
                AppRoute.viewAll(status: MatchStatusLabel.live).push(context),
          ),
          LiveMatchCarousel(matches: live.take(_homeRowLimit).toList()),
        ],

        // ── 2. Quick Actions Dock ────────────────────────────────────────────
        const SizedBox(height: 6),
        _quickActionsRow(context),

        // ── 3. Tournaments Carousel ──────────────────────────────────────────
        if (state.tournaments.isNotEmpty) ...[
          _tournamentSection(context, state.tournaments),
        ],

        // ── 4. Recent results Carousel ───────────────────────────────────────
        if (finished.isNotEmpty)
          _matchRow(
            context,
            title: 'Recent results',
            label: MatchStatusLabel.finished,
            matches: finished,
          ),

        // ── Upcoming matches (if any) ────────────────────────────────────────
        if (upcoming.isNotEmpty)
          _matchRow(
            context,
            title: context.l10n.home_section_upcoming,
            label: MatchStatusLabel.upcoming,
            matches: upcoming,
          ),

        // ── 5. Top Performers (Leaderboard) ──────────────────────────────────
        if (state.leaderboard.isNotEmpty) ...[
          _leaderboardSection(context, state.leaderboard),
        ],

        if (state.matches.isEmpty)
          SizedBox(
            height: context.mediaQuerySize.height /
                (state.tournaments.isEmpty ? 1.3 : 2),
            child: EmptyScreen(
              title: context.l10n.home_screen_no_matches_title,
              description: context.l10n.home_screen_no_matches_description_text,
              isShowButton: false,
            ),
          ),
      ],
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: list,
      ),
    );
  }

  // ── Quick-action launchpad dock ───────────────────────────────────────────────

  Widget _quickActionsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _dockItem(
              context,
              label: 'Create\nmatch',
              icon: CupertinoIcons.sportscourt_fill,
              onTap: () => _pushWhenSignedIn(context, AppRoute.addMatch()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dockItem(
              context,
              label: 'Create\nteam',
              icon: CupertinoIcons.shield_fill,
              onTap: () => _pushWhenSignedIn(context, AppRoute.addTeam()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dockItem(
              context,
              label: 'Tournaments',
              icon: CupertinoIcons.rosette,
              onTap: () => _pushWhenSignedIn(context, AppRoute.addTournament()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dockItem(
              context,
              label: 'Auction',
              icon: CupertinoIcons.hammer_fill,
              onTap: () => _pushWhenSignedIn(context, AppRoute.auctionForm()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dockItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: cs.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: cs.cardShadow,
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEEED),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 22,
                color: brandRedColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyle.caption.copyWith(
                color: cs.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pushWhenSignedIn(BuildContext context, AppRoute route) {
    if (ref.read(hasUserSession)) {
      route.push(context);
    } else {
      ref.read(mascotProvider.notifier).show(
            MascotPose.help,
            mascotText.mascot_sign_in_to_create,
            allowFun: false,
          );
      AppRoute.signIn.push(context);
    }
  }

  // ── Section header ───────────────────────────────────────────────────────────

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    bool live = false,
    bool showViewAll = false,
    String? actionText,
    VoidCallback? onViewAll,
  }) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          if (live) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: brandRedColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: brandRedColor.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTextStyle.header4.copyWith(
                color: cs.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showViewAll)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onViewAll,
              child: Text(
                actionText ?? context.l10n.common_view_all,
                style: AppTextStyle.subtitle3.copyWith(
                  color: brandRedColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tournaments ──────────────────────────────────────────────────────────────

  Widget _tournamentSection(
    BuildContext context,
    List<TournamentModel> tournaments,
  ) {
    final recent = [...tournaments]
      ..sort((a, b) => b.start_date.compareTo(a.start_date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          title: context.l10n.common_tournaments,
          showViewAll: true,
          actionText: 'View All (${tournaments.length})',
          onViewAll: () => AppRoute.viewAll(isTournament: true).push(context),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: recent
                .take(10)
                .map((t) => TournamentItem(
                      tournament: t,
                      size: const Size.fromWidth(280),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Leaderboard (Top Performers) ─────────────────────────────────────────────

  Widget _leaderboardSection(
    BuildContext context,
    List<LeaderboardModel> leaderboard,
  ) {
    LeaderboardPlayer? topBatter;
    LeaderboardPlayer? topBowler;

    for (final lb in leaderboard) {
      if (lb.type == LeaderboardField.batting && lb.players.isNotEmpty) {
        topBatter = lb.players.first;
      } else if (lb.type == LeaderboardField.bowling && lb.players.isNotEmpty) {
        topBowler = lb.players.first;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          title: 'Top Performers',
          showViewAll: true,
          actionText: 'Full Leaderboard',
          onViewAll: () => AppRoute.leaderboard().push(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            children: [
              _topPerformerCard(
                context,
                title: 'MOST RUNS',
                playerName: topBatter?.user?.name ?? 'K. Shankar',
                playerInitials: topBatter?.user?.nameInitial ??
                    (topBatter?.user?.name?.initials(limit: 2) ?? 'KS'),
                statText: '${topBatter?.runs ?? 412} Runs',
                subStatText: 'SR: 164.8 • 5 Inns',
                isDark: false,
                onTap: () => AppRoute.leaderboard(
                  selectedField: LeaderboardField.batting,
                ).push(context),
              ),
              _topPerformerCard(
                context,
                title: 'MOST WICKETS',
                playerName: topBowler?.user?.name ?? 'A. Ramanan',
                playerInitials: topBowler?.user?.nameInitial ??
                    (topBowler?.user?.name?.initials(limit: 2) ?? 'AR'),
                statText: '${topBowler?.wickets ?? 14} Wickets',
                subStatText: 'Econ: 5.4 • 6 Inns',
                isDark: true,
                onTap: () => AppRoute.leaderboard(
                  selectedField: LeaderboardField.bowling,
                ).push(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topPerformerCard(
    BuildContext context, {
    required String title,
    required String playerName,
    required String playerInitials,
    required String statText,
    required String subStatText,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cs = context.colorScheme;
    final cardBg = isDark ? const Color(0xFF0F1E2E) : cs.card;
    final accentColor =
        isDark ? const Color(0xFF10B981) : const Color(0xFFD97706);
    final ringColor =
        isDark ? const Color(0xFF06B6D4) : const Color(0xFFF59E0B);
    final avatarBg =
        isDark ? const Color(0xFF06283D) : const Color(0xFFFFFBEB);
    final badgeBg =
        isDark ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final nameColor = isDark ? Colors.white : cs.textPrimary;
    final subColor = isDark ? const Color(0xFF94A3B8) : cs.textSecondary;

    return Expanded(
      child: OnTapScale(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: cs.cardShadow,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : cs.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              if (isDark)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                )
              else
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              const SizedBox(height: 12),

              // Avatar with ring & badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: avatarBg,
                      border: Border.all(color: ringColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      playerInitials,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : accentColor,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBg, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Player Name
              Text(
                playerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyle.subtitle2.copyWith(
                  color: nameColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),

              const SizedBox(height: 4),

              // Big Stat
              Text(
                statText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 2),

              // Sub Stat
              Text(
                subStatText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Upcoming / finished rows ─────────────────────────────────────────────

  Widget _matchRow(
    BuildContext context, {
    required String title,
    required MatchStatusLabel label,
    required List<MatchModel> matches,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          title: title,
          showViewAll: true,
          actionText: 'View all',
          onViewAll: () => AppRoute.viewAll(status: label).push(context),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: matches
                .take(_homeRowLimit)
                .map((match) => MatchItem(match: match))
                .toList(),
          ),
        ),
      ],
    );
  }
}
