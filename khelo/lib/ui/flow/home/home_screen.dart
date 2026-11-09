import 'package:data/api/leaderboard/leaderboard_model.dart';
import 'package:data/api/match/match_model.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:data/api/user/user_models.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/empty_screen.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/home/components/match_item.dart';
import 'package:khelo/ui/flow/home/components/tournament_item.dart';
import 'package:khelo/ui/flow/home/global_cricket/global_cricket_section.dart';
import 'package:khelo/ui/flow/home/home_view_model.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/button/action_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
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
              ? context.l10n.mascot_welcome_guest
              : context.l10n.mascot_welcome_named(name),
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
      titleWidget: SvgPicture.asset(
        Assets.images.appLogoWordmark,
        height: 40,
        theme: SvgTheme(currentColor: cs.textPrimary),
      ),
      actions: state.matches.isNotEmpty
          ? [
              actionButton(
                context,
                icon: Icon(
                  CupertinoIcons.search,
                  color: cs.primary,
                  size: 22,
                ),
                onPressed: () => AppRoute.searchHome.push(context),
              ),
            ]
          : null,
      body: Builder(builder: (context) {
        return _body(context, notifier, state);
      }),
    );
  }

  Widget _body(
    BuildContext context,
    HomeViewNotifier notifier,
    HomeViewState state,
  ) {
    if (state.loading && state.matches.isEmpty && state.tournaments.isEmpty) {
      return const Center(child: AppProgressIndicator());
    }
    if (state.error != null && state.matches.isEmpty) {
      return ErrorScreen(
        error: state.error,
        onRetryTap: notifier.loadData,
      );
    }

    return ListView(
      padding:
          context.mediaQueryPadding + const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        // ── Quick Actions ────────────────────────────────────────────────────
        _quickActionsRow(context),
        const SizedBox(height: 4),

        // ── Tournaments ──────────────────────────────────────────────────────
        if (state.tournaments.isNotEmpty) ...[
          _tournamentSection(context, state.tournaments),
        ],

        // ── Global cricket (CricketData.org) ─────────────────────────────────
        GlobalCricketSection(
          header: (title, onViewAll) => _sectionHeader(
            context,
            title: title,
            showViewAll: true,
            onViewAll: onViewAll,
          ),
        ),

        // ── Leaderboard ──────────────────────────────────────────────────────
        if (state.leaderboard.isNotEmpty) ...[
          _leaderboardSection(context, state.leaderboard),
        ],

        // ── Matches ──────────────────────────────────────────────────────────
        state.matches.isNotEmpty
            ? _matchesSection(context, state)
            : SizedBox(
                height: context.mediaQuerySize.height /
                    (state.tournaments.isEmpty ? 1.3 : 2),
                child: EmptyScreen(
                  title: context.l10n.home_screen_no_matches_title,
                  description:
                      context.l10n.home_screen_no_matches_description_text,
                  isShowButton: false,
                ),
              ),
      ],
    );
  }

  // ── Quick-action horizontal strip ───────────────────────────────────────────

  Widget _quickActionsRow(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _actionChip(
            context,
            label: context.l10n.common_create_team_title,
            icon: CupertinoIcons.person_3_fill,
            onTap: () => _pushWhenSignedIn(context, AppRoute.addTeam()),
          ),
          const SizedBox(width: 10),
          _actionChip(
            context,
            label: context.l10n.home_screen_create_match_btn,
            icon: CupertinoIcons.sportscourt_fill,
            onTap: () => _pushWhenSignedIn(context, AppRoute.addMatch()),
          ),
          const SizedBox(width: 10),
          _actionChip(
            context,
            label: context.l10n.home_screen_create_tournament_btn,
            icon: CupertinoIcons.rosette,
            onTap: () => _pushWhenSignedIn(context, AppRoute.addTournament()),
          ),
        ],
      ),
    );
  }

  /// Card chip with a glowing mint icon circle, like the concept's
  /// Fixtures / Results / Tours rows.
  Widget _actionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
        decoration: BoxDecoration(
          color: cs.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: cs.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: brandRedColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: brandRedColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(icon, size: 16, color: textPrimaryDarkColor),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTextStyle.subtitle2.copyWith(
                color: cs.textPrimary,
                fontWeight: FontWeight.w600,
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
            context.l10n.mascot_sign_in_to_create,
            lift: MascotController.signInOptionsLift,
          );
      AppRoute.phoneLogin.push(context);
    }
  }

  // ── Section header ───────────────────────────────────────────────────────────

  /// iOS-style section header: left-aligned title, right-aligned "See All" in
  /// primary blue. Tighter padding (16pt left, 10pt top, 12pt bottom).
  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    bool showViewAll = false,
    VoidCallback? onViewAll,
  }) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
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
                context.l10n.common_view_all,
                style: AppTextStyle.subtitle3.copyWith(color: cs.primary),
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
          onViewAll: () => AppRoute.viewAll(isTournament: true).push(context),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: recent
                .take(_homeRowLimit)
                .map((t) => TournamentItem(
                      tournament: t,
                      size: const Size.fromWidth(320),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Leaderboard ──────────────────────────────────────────────────────────────

  Widget _leaderboardSection(
    BuildContext context,
    List<LeaderboardModel> leaderboard,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          title: context.l10n.common_leaderboard,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: leaderboard
                .map((data) => _leaderboardCard(context, data))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _leaderboardCard(BuildContext context, LeaderboardModel lb) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: () => AppRoute.leaderboard(selectedField: lb.type).push(context),
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: cs.cardDecoration(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lb.type.getString(context),
                    style: AppTextStyle.caption.copyWith(
                      color: cs.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: cs.textDisabled,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _leaderboardPlayers(lb.players),
          ],
        ),
      ),
    );
  }

  Widget _leaderboardPlayers(List<LeaderboardPlayer> players) {
    return Row(
      children: [
        for (int i = 0; i < players.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < players.length - 1 ? 6 : 0),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colorScheme.containerLowOnSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _playerCell(players[i].user, i < 3 ? i + 1 : null),
            ),
          ),
      ],
    );
  }

  Widget _playerCell(UserModel? user, int? rank) {
    final cs = context.colorScheme;
    return Column(
      children: [
        Stack(
          children: [
            ImageAvatar(
              initial: user?.nameInitial ?? '?',
              imageUrl: user?.profile_img_url,
              size: 44,
            ),
            if (rank != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: AppTextStyle.caption.copyWith(
                      color: cs.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          user?.name ?? context.l10n.commonDeactivatedUser,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.caption.copyWith(color: cs.textPrimary),
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Matches section ──────────────────────────────────────────────────────────

  Widget _matchesSection(BuildContext context, HomeViewState state) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.groupMatches.length,
      itemBuilder: (context, index) {
        final entry = state.groupMatches.entries.elementAt(index);
        if (entry.value.isEmpty) return const SizedBox();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              context,
              title: entry.key.getString(context),
              showViewAll: true,
              onViewAll: () =>
                  AppRoute.viewAll(status: entry.key).push(context),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: _homeOrder(entry.key, entry.value)
                    .take(_homeRowLimit)
                    .map((match) => MatchItem(match: match))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
