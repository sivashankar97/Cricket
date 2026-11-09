import 'package:data/api/play/play_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
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
import 'game/play_game_screen.dart';
import 'play_providers.dart';
import 'select_opponent_sheet.dart';

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

    final myDailyBest = rankBestScores(
      dailyGames.where((game) => game.userId == userId).toList(),
      limit: 1,
    ).firstOrNull;
    final dailyPlayers = dailyGames.map((game) => game.userId).toSet().length;

    return AppPage(
      title: context.l10n.play_screen_title,
      body: ListView(
        padding: context.mediaQueryPadding +
            const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          if (isGuest) ...[
            _guestBanner(context),
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
            () => AppRoute.phoneLogin.push(context),
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
                ? AppRoute.phoneLogin.push(context)
                : _challengeFriend(context),
          ),
        ),
      ],
    );
  }

  Future<void> _challengeFriend(BuildContext context) async {
    final opponent = await showSelectOpponentSheet(context);
    if (opponent == null || !context.mounted) return;
    AppRoute.playGame(PlayGameArgs.newChallenge(opponent)).push(context);
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
