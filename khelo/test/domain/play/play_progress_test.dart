import 'package:data/api/play/play_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/domain/play/play_progress.dart';

PlayGame game(
  DateTime day, {
  int runs = 10,
  int fours = 0,
  int sixes = 0,
  bool? won,
  PlayMode mode = PlayMode.solo,
}) =>
    PlayGame(
      id: '${day.toIso8601String()}-$runs',
      userId: 'u',
      userName: 'U',
      mode: mode,
      seed: 1,
      runs: runs,
      wickets: 0,
      balls: 12,
      fours: fours,
      sixes: sixes,
      won: won,
      createdAt: day,
    );

void main() {
  final now = DateTime(2026, 11, 9, 18);

  test('no games: level 1, nothing earned', () {
    final progress = PlayProgress.fromGames(const [], now: now);
    expect(progress.level, 1);
    expect(progress.xp, 0);
    expect(progress.streak, 0);
    expect(progress.badges, isEmpty);
  });

  test('adds XP, wins and best score over games', () {
    final progress = PlayProgress.fromGames([
      game(now, runs: 20, fours: 1, sixes: 1, won: true),
      game(now, runs: 8, won: false),
    ], now: now);
    // 20 + 2 + 4 + 25, then 8 + 5.
    expect(progress.xp, 64);
    expect(progress.wins, 1);
    expect(progress.best, 20);
    expect(progress.games, 2);
  });

  test('streak counts days in a row ending today or yesterday', () {
    final days = [9, 8, 7, 5].map((d) => DateTime(2026, 11, d, 10));
    expect(
      PlayProgress.fromGames(days.map(game).toList(), now: now).streak,
      3,
    );
    final fromYesterday = [8, 7].map((d) => DateTime(2026, 11, d, 10));
    expect(
      PlayProgress.fromGames(fromYesterday.map(game).toList(), now: now).streak,
      2,
    );
    final broken = [6, 5].map((d) => DateTime(2026, 11, d, 10));
    expect(
      PlayProgress.fromGames(broken.map(game).toList(), now: now).streak,
      0,
    );
  });

  test('badges unlock from single games and career totals', () {
    final progress = PlayProgress.fromGames([
      game(DateTime(2026, 11, 1), runs: 34, sixes: 3),
      game(DateTime(2026, 11, 2), runs: 40),
      game(DateTime(2026, 11, 3), runs: 30, won: true, mode: PlayMode.match),
    ], now: now);
    expect(
      progress.badges,
      {
        PlayBadge.firstSix,
        PlayBadge.sixHitter,
        PlayBadge.thirty,
        PlayBadge.matchWinner,
        PlayBadge.century,
        PlayBadge.dailyStreak,
      },
    );
  });

  test('a daily win does not count as a live match win', () {
    final progress = PlayProgress.fromGames(
      [game(now, won: true, mode: PlayMode.daily)],
      now: now,
    );
    expect(progress.badges, isNot(contains(PlayBadge.matchWinner)));
  });
}
