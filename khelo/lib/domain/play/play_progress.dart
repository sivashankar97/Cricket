import 'dart:math';

import 'package:data/api/play/play_models.dart';

import 'cricket_game.dart';

enum PlayBadge {
  firstSix,
  sixHitter,
  thirty,
  matchWinner,
  dailyStreak,
  century,
  veteran,
}

/// XP, level, streaks and badges, worked out from every game a player saved.
class PlayProgress {
  final int xp;
  final int level;
  final int xpInLevel;
  final int xpForNext;
  final int games;
  final int wins;
  final int best;

  /// Days in a row with a game, ending today or yesterday.
  final int streak;
  final Set<PlayBadge> badges;

  const PlayProgress({
    required this.xp,
    required this.level,
    required this.xpInLevel,
    required this.xpForNext,
    required this.games,
    required this.wins,
    required this.best,
    required this.streak,
    required this.badges,
  });

  factory PlayProgress.fromGames(List<PlayGame> games, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    var xp = 0;
    var wins = 0;
    var best = 0;
    var totalRuns = 0;
    final badges = <PlayBadge>{};
    final days = <DateTime>{};

    for (final game in games) {
      final won = game.won == true;
      xp += xpForGame(
        runs: game.runs,
        fours: game.fours,
        sixes: game.sixes,
        won: won,
      );
      if (won) wins++;
      best = max(best, game.runs);
      totalRuns += game.runs;
      days.add(_day(game.createdAt));
      if (game.sixes > 0) badges.add(PlayBadge.firstSix);
      if (game.sixes >= 3) badges.add(PlayBadge.sixHitter);
      if (game.runs >= 30) badges.add(PlayBadge.thirty);
      if (won && game.mode == PlayMode.match) {
        badges.add(PlayBadge.matchWinner);
      }
    }
    if (totalRuns >= 100) badges.add(PlayBadge.century);
    if (games.length >= 25) badges.add(PlayBadge.veteran);
    if (_longestRun(days) >= 3) badges.add(PlayBadge.dailyStreak);

    var streak = 0;
    var day =
        days.contains(today) ? today : today.subtract(const Duration(days: 1));
    while (days.contains(day)) {
      streak++;
      day = _day(day.subtract(const Duration(hours: 12)));
    }

    final level = levelForXp(xp);
    return PlayProgress(
      xp: xp,
      level: level.level,
      xpInLevel: level.xpInLevel,
      xpForNext: level.xpForNext,
      games: games.length,
      wins: wins,
      best: best,
      streak: streak,
      badges: badges,
    );
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _longestRun(Set<DateTime> days) {
    var longest = 0;
    for (final day in days) {
      final previous = _day(day.subtract(const Duration(hours: 12)));
      if (days.contains(previous)) continue;
      var length = 1;
      var next = _day(day.add(const Duration(hours: 36)));
      while (days.contains(next)) {
        length++;
        next = _day(next.add(const Duration(hours: 36)));
      }
      longest = max(longest, length);
    }
    return longest;
  }
}
