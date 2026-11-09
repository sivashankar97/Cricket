import 'dart:math';

import 'package:data/api/play/play_match.dart';
import 'package:data/api/play/play_models.dart';
import 'package:data/service/play/play_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

import '../../../domain/play/cricket_game.dart';
import '../../../domain/play/play_progress.dart';
import 'game/play_game_screen.dart';
import 'match/play_match_screen.dart';
import 'play_opponent_sheet.dart';
import 'play_providers.dart';

/// Play tab dashboard: daily challenge, quick play / challenge actions,
/// challenges, leaderboard and recent games.
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  bool _weekly = false;

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(playIdentityProvider);
    final userId = identity?.id;
    final isGuest = identity?.isGuest ?? false;
    final daily = ref.watch(todayChallengeProvider);
    final dailyGames = ref.watch(playDailyGamesProvider).valueOrNull ?? [];
    final challenges = ref.watch(playChallengesProvider).valueOrNull ?? [];
    final recent = ref.watch(playRecentGamesProvider).valueOrNull ?? [];
    final weekly = ref.watch(playWeeklyGamesProvider).valueOrNull ?? [];
    final allGames = ref.watch(playAllGamesProvider).valueOrNull;
    final progress = allGames == null ? null : PlayProgress.fromGames(allGames);
    final now = DateTime.now();
    final liveMatches = (ref.watch(playMatchesProvider).valueOrNull ?? [])
        .where((match) => match.status.isOpen && !match.isExpired(now))
        .toList();
    ref.listen(playAllGamesProvider, (previous, next) {
      final before = previous?.valueOrNull;
      final after = next.valueOrNull;
      if (before == null || after == null) return;
      final had = PlayProgress.fromGames(before).badges;
      for (final badge in PlayProgress.fromGames(after).badges) {
        if (!had.contains(badge)) _announceBadge(badge);
      }
    });

    final myDailyBest = rankBestScores(
      dailyGames.where((game) => game.userId == userId).toList(),
      limit: 1,
    ).firstOrNull;
    final dailyPlayers = dailyGames.map((game) => game.userId).toSet().length;

    // Centered column on tablets and desktop.
    final side = max(16.0, (MediaQuery.sizeOf(context).width - 720) / 2);
    return AppPage(
      title: context.l10n.play_screen_title,
      body: ListView(
        padding: context.mediaQueryPadding +
            EdgeInsets.fromLTRB(side, 12, side, 120),
        children: [
          if (isGuest) ...[
            _guestBanner(context),
            const SizedBox(height: 14),
          ],
          if (progress != null) ...[
            _progressCard(context, progress),
            const SizedBox(height: 14),
          ],
          _dailyCard(context, daily, myDailyBest, dailyPlayers),
          const SizedBox(height: 14),
          _actions(context, isGuest: isGuest),
          const SizedBox(height: 10),
          Text(
            context.l10n.play_how_to,
            style: AppTextStyle.caption
                .copyWith(color: context.colorScheme.textSecondary),
          ),
          if (liveMatches.isNotEmpty) ...[
            _sectionTitle(context, context.l10n.play_match_section),
            ...liveMatches.map((match) => _matchTile(context, match, userId)),
          ],
          if (challenges.isNotEmpty) ...[
            _sectionTitle(context, context.l10n.play_challenges_title),
            ...challenges
                .take(6)
                .map((c) => _challengeTile(context, c, userId)),
          ],
          _sectionTitle(
            context,
            context.l10n.play_leaderboard_title,
            trailing: _leaderboardToggle(context),
          ),
          _leaderboard(
            context,
            rankBestScores(_weekly ? weekly : dailyGames, limit: 10),
            userId,
          ),
          _sectionTitle(context, context.l10n.play_recent_title),
          if (recent.isEmpty)
            _emptyCard(context, context.l10n.play_recent_empty)
          else
            ...recent.map((game) => _recentTile(context, game)),
        ],
      ),
    );
  }

  // ── Guest ────────────────────────────────────────────────────────────────

  Widget _guestBanner(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: cs.cardDecoration(radius: 18),
      child: Row(
        children: [
          ImageAvatar(initial: PlayGame.guestName[0], size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.play_guest_title,
                  style: AppTextStyle.subtitle2.copyWith(
                    color: cs.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.play_guest_description,
                  style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _smallButton(
            context.l10n.sign_in_options_title,
            () => AppRoute.signIn.push(context),
          ),
        ],
      ),
    );
  }

  // ── Daily challenge ──────────────────────────────────────────────────────

  Widget _dailyCard(
    BuildContext context,
    DailyChallenge daily,
    PlayGame? myBest,
    int players,
  ) {
    return OnTapScale(
      onTap: () => AppRoute.playGame(PlayGameArgs.daily(daily)).push(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: liveCardGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: brandRedColor.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pill(context.l10n.play_daily_title.toUpperCase()),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.play_daily_target(daily.target),
                    style: AppTextStyle.header3
                        .copyWith(color: textPrimaryDarkColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    myBest != null
                        ? context.l10n
                            .play_daily_best('${myBest.runs}/${myBest.wickets}')
                        : context.l10n.play_daily_not_played,
                    style: AppTextStyle.caption
                        .copyWith(color: textSecondaryDarkColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.play_daily_players(players),
                    style: AppTextStyle.caption
                        .copyWith(color: textSecondaryDarkColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _glowCircle(CupertinoIcons.play_fill, size: 56),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: textPrimaryDarkColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppTextStyle.caption.copyWith(
            color: brandRedDeepColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _glowCircle(IconData icon, {double size = 44}) => Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: brandRedColor,
          shape: BoxShape.circle,
          border: Border.all(color: textPrimaryDarkColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: brandRedColor.withValues(alpha: 0.5),
              blurRadius: 14,
            ),
          ],
        ),
        child: Icon(icon, color: textPrimaryDarkColor, size: size * 0.45),
      );

  // ── Quick play / challenge ───────────────────────────────────────────────

  Widget _actions(BuildContext context, {required bool isGuest}) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            context,
            icon: CupertinoIcons.sportscourt_fill,
            title: context.l10n.play_quick_play,
            subtitle: context.l10n.play_quick_play_hint,
            onTap: () => AppRoute.playGame(PlayGameArgs.quick()).push(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            context,
            icon: CupertinoIcons.person_2_fill,
            title: context.l10n.play_challenge_friend,
            subtitle: isGuest
                ? context.l10n.play_guest_challenge_hint
                : context.l10n.play_challenge_friend_hint,
            onTap: () => isGuest
                ? AppRoute.signIn.push(context)
                : _challengeFriend(context),
          ),
        ),
      ],
    );
  }

  Future<void> _challengeFriend(BuildContext context) async {
    final opponent = await showPlayOpponentSheet(context);
    if (opponent == null || !context.mounted) return;
    final format = await showMatchFormatSheet(context, opponent);
    if (format == null || !context.mounted) return;
    try {
      final match = await createPlayMatch(ref, opponent, format);
      if (context.mounted) AppRoute.playMatch(match.id).push(context);
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context: context, error: error);
    }
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cs.cardDecoration(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _glowCircle(icon, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyle.subtitle2.copyWith(
                color: cs.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Progress ─────────────────────────────────────────────────────────────

  void _announceBadge(PlayBadge badge) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(_badgeIcon(badge), color: awarenessWarningColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                context.l10n.play_badge_unlocked(_badgeName(context, badge))),
          ),
        ],
      ),
    ));
  }

  IconData _badgeIcon(PlayBadge badge) => switch (badge) {
        PlayBadge.firstSix => Icons.looks_6_rounded,
        PlayBadge.sixHitter => Icons.local_fire_department_rounded,
        PlayBadge.thirty => Icons.sports_cricket_rounded,
        PlayBadge.matchWinner => Icons.emoji_events_rounded,
        PlayBadge.dailyStreak => Icons.calendar_month_rounded,
        PlayBadge.century => Icons.military_tech_rounded,
        PlayBadge.veteran => Icons.workspace_premium_rounded,
      };

  String _badgeName(BuildContext context, PlayBadge badge) => switch (badge) {
        PlayBadge.firstSix => context.l10n.play_badge_first_six,
        PlayBadge.sixHitter => context.l10n.play_badge_six_hitter,
        PlayBadge.thirty => context.l10n.play_badge_thirty,
        PlayBadge.matchWinner => context.l10n.play_badge_match_winner,
        PlayBadge.dailyStreak => context.l10n.play_badge_daily_streak,
        PlayBadge.century => context.l10n.play_badge_century,
        PlayBadge.veteran => context.l10n.play_badge_veteran,
      };

  Widget _progressCard(BuildContext context, PlayProgress progress) {
    final fraction =
        progress.xpForNext == 0 ? 0.0 : progress.xpInLevel / progress.xpForNext;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandNavyCardColor, Color(0xFF1C1C6B)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD166), awarenessWarningColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: awarenessWarningColor.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  '${progress.level}',
                  style: AppTextStyle.header3.copyWith(
                    color: brandNavyColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.l10n.play_level(progress.level),
                          style: AppTextStyle.subtitle1.copyWith(
                            color: textPrimaryDarkColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          context.l10n.play_xp_progress(
                              progress.xpInLevel, progress.xpForNext),
                          style: AppTextStyle.caption
                              .copyWith(color: textSecondaryDarkColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: fraction),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor:
                              textPrimaryDarkColor.withValues(alpha: 0.12),
                          color: awarenessWarningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat(Icons.local_fire_department_rounded,
                  context.l10n.play_stat_streak(progress.streak)),
              _stat(Icons.emoji_events_rounded,
                  context.l10n.play_stat_wins(progress.wins)),
              _stat(Icons.sports_cricket_rounded,
                  context.l10n.play_stat_best(progress.best)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.play_badges_title.toUpperCase(),
            style: AppTextStyle.caption.copyWith(
              color: textSecondaryDarkColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            const count = 7;
            final size = min(40.0, (constraints.maxWidth - 6 * 6) / count);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final badge in PlayBadge.values)
                  _badge(context, badge,
                      size: size, unlocked: progress.badges.contains(badge)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String text) => Expanded(
        child: Row(
          children: [
            Icon(icon, size: 16, color: awarenessWarningColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption.copyWith(
                  color: textPrimaryDarkColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _badge(BuildContext context, PlayBadge badge,
      {required double size, required bool unlocked}) {
    return Tooltip(
      message: _badgeName(context, badge),
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: unlocked
              ? awarenessWarningColor.withValues(alpha: 0.18)
              : textPrimaryDarkColor.withValues(alpha: 0.06),
          border: Border.all(
            color: unlocked
                ? awarenessWarningColor
                : textPrimaryDarkColor.withValues(alpha: 0.12),
          ),
        ),
        child: Icon(
          _badgeIcon(badge),
          size: size * 0.5,
          color: unlocked
              ? awarenessWarningColor
              : textPrimaryDarkColor.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  // ── Live matches ─────────────────────────────────────────────────────────

  Widget _matchTile(BuildContext context, PlayMatch match, String? userId) {
    final cs = context.colorScheme;
    final me = userId ?? '';
    final other = match.otherThan(me);
    final format = formatLabel(context, match.format);
    void open() => AppRoute.playMatch(match.id).push(context);

    final String text;
    Widget? trailing;
    if (match.status == PlayMatchStatus.requested) {
      if (match.isHost(me)) {
        text = context.l10n.play_match_request_to(other.name, format);
      } else {
        text = context.l10n.play_match_request_from(other.name, format);
        trailing = _smallButton(context.l10n.play_match_accept, () async {
          try {
            await ref.read(playServiceProvider).acceptMatch(match.id);
            if (context.mounted) open();
          } catch (error) {
            if (context.mounted) {
              showErrorSnackBar(context: context, error: error);
            }
          }
        });
      }
    } else {
      text = context.l10n.play_match_in_progress(other.name, format);
      trailing = _smallButton(context.l10n.play_match_join, open);
    }

    return OnTapScale(
      onTap: open,
      child: _rowCard(
        context,
        leading: ImageAvatar(
          initial: other.name.isEmpty ? '?' : other.name[0].toUpperCase(),
          imageUrl: other.image,
          size: 36,
        ),
        title: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.subtitle3.copyWith(color: cs.textPrimary),
        ),
        trailing: trailing,
      ),
    );
  }

  // ── Challenges ───────────────────────────────────────────────────────────

  Widget _challengeTile(
    BuildContext context,
    PlayChallenge challenge,
    String? userId,
  ) {
    final cs = context.colorScheme;
    final iAmCreator = challenge.creatorId == userId;
    final otherName =
        iAmCreator ? challenge.opponentName : challenge.creatorName;
    final canPlay = challenge.isPending && !iAmCreator;

    final String text;
    Widget? trailing;
    if (canPlay) {
      text = context.l10n
          .play_challenge_incoming(otherName, challenge.creatorScore.runs);
      trailing = _smallButton(
        context.l10n.play_challenge_play,
        () => AppRoute.playGame(PlayGameArgs.answerChallenge(challenge))
            .push(context),
      );
    } else if (challenge.isPending) {
      text = context.l10n
          .play_challenge_waiting(otherName, challenge.creatorScore.toString());
    } else {
      final mine =
          iAmCreator ? challenge.creatorScore : challenge.opponentScore;
      final theirs =
          iAmCreator ? challenge.opponentScore : challenge.creatorScore;
      text = context.l10n.play_challenge_result(
        mine.toString(),
        theirs.toString(),
        otherName,
      );
      trailing = _resultChip(
        context,
        challenge.winnerId == null ? null : challenge.winnerId == userId,
      );
    }

    return _rowCard(
      context,
      leading: ImageAvatar(
        initial: otherName.isEmpty ? '?' : otherName[0].toUpperCase(),
        size: 36,
      ),
      title: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.subtitle3.copyWith(color: cs.textPrimary),
      ),
      trailing: trailing,
    );
  }

  Widget _smallButton(String text, VoidCallback onTap) => OnTapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: liveCardGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: AppTextStyle.caption.copyWith(
              color: textPrimaryDarkColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

  /// [won] null means a tie.
  Widget _resultChip(BuildContext context, bool? won) {
    final color = won == null
        ? awarenessWarningColor
        : won
            ? positiveGreenColor
            : brandRedColor;
    final text = won == null
        ? context.l10n.play_result_tie
        : won
            ? context.l10n.play_result_won
            : context.l10n.play_result_lost;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyle.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Leaderboard ──────────────────────────────────────────────────────────

  Widget _leaderboardToggle(BuildContext context) {
    return CupertinoSlidingSegmentedControl<bool>(
      groupValue: _weekly,
      padding: const EdgeInsets.all(3),
      onValueChanged: (value) => setState(() => _weekly = value ?? false),
      children: {
        false: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(context.l10n.play_leaderboard_today,
              style: AppTextStyle.caption),
        ),
        true: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(context.l10n.play_leaderboard_week,
              style: AppTextStyle.caption),
        ),
      },
    );
  }

  Widget _leaderboard(
    BuildContext context,
    List<PlayGame> ranked,
    String? userId,
  ) {
    if (ranked.isEmpty) {
      return _emptyCard(context, context.l10n.play_leaderboard_empty);
    }
    final cs = context.colorScheme;
    return Container(
      decoration: cs.cardDecoration(radius: 18),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < ranked.length; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: ranked[i].userId == userId
                    ? cs.primary.withValues(alpha: 0.10)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _rankBadge(context, i + 1),
                  const SizedBox(width: 10),
                  ImageAvatar(
                    initial: ranked[i].userName.isEmpty
                        ? '?'
                        : ranked[i].userName[0].toUpperCase(),
                    imageUrl: ranked[i].userImage,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ranked[i].userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subtitle3
                          .copyWith(color: cs.textPrimary),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: '${ranked[i].runs}/${ranked[i].wickets}',
                      style: AppTextStyle.subtitle2.copyWith(
                        color: cs.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: '  ${context.l10n.play_balls(ranked[i].balls)}',
                          style: AppTextStyle.caption
                              .copyWith(color: cs.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _rankBadge(BuildContext context, int rank) {
    final top = rank <= 3;
    return Container(
      height: 24,
      width: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: top ? positiveGreenColor : context.colorScheme.containerLow,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: AppTextStyle.caption.copyWith(
          color: top ? brandNavyColor : context.colorScheme.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Recent games ─────────────────────────────────────────────────────────

  Widget _recentTile(BuildContext context, PlayGame game) {
    final cs = context.colorScheme;
    final (icon, label) = switch (game.mode) {
      PlayMode.daily => (CupertinoIcons.calendar, context.l10n.play_mode_daily),
      PlayMode.challenge => (
          CupertinoIcons.person_2_fill,
          context.l10n.play_mode_challenge
        ),
      PlayMode.solo => (
          CupertinoIcons.sportscourt_fill,
          context.l10n.play_mode_solo
        ),
      PlayMode.match => (
          CupertinoIcons.bolt_fill,
          context.l10n.play_mode_match
        ),
    };
    return _rowCard(
      context,
      leading: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: cs.primary),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${game.runs}/${game.wickets}  ·  ${context.l10n.play_balls(game.balls)}',
            style: AppTextStyle.subtitle2.copyWith(
              color: cs.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$label · ${game.createdAt.format(context, DateFormatType.dateAndTime)}',
            style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
          ),
        ],
      ),
      trailing: game.won == null ? null : _resultChip(context, game.won),
    );
  }

  // ── Shared ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyle.header4.copyWith(
                color: context.colorScheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _rowCard(
    BuildContext context, {
    required Widget leading,
    required Widget title,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: context.colorScheme.cardDecoration(radius: 16),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(child: title),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context, String text) => Container(
        padding: const EdgeInsets.all(18),
        decoration: context.colorScheme.cardDecoration(radius: 16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyle.body2
              .copyWith(color: context.colorScheme.textSecondary),
        ),
      );
}
