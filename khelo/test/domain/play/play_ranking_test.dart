import 'package:data/api/play/play_models.dart';
import 'package:flutter_test/flutter_test.dart';

PlayGame game(String userId, int runs, {int balls = 12}) => PlayGame(
      id: '$userId-$runs-$balls',
      userId: userId,
      userName: userId,
      mode: PlayMode.solo,
      seed: 1,
      runs: runs,
      wickets: 0,
      balls: balls,
      createdAt: DateTime(2026, 11, 6),
    );

void main() {
  group('rankBestScores', () {
    test('keeps only each player\'s best game', () {
      final ranked = rankBestScores([
        game('ravi', 12),
        game('ravi', 30),
        game('anu', 18),
      ]);
      expect(ranked.map((g) => g.userId), ['ravi', 'anu']);
      expect(ranked.first.runs, 30);
    });

    test('ranks higher runs first', () {
      final ranked =
          rankBestScores([game('a', 10), game('b', 40), game('c', 25)]);
      expect(ranked.map((g) => g.runs), [40, 25, 10]);
    });

    test('breaks ties by fewer balls', () {
      final ranked = rankBestScores(
          [game('slow', 24, balls: 12), game('fast', 24, balls: 7)]);
      expect(ranked.first.userId, 'fast');
    });

    test('limits the list', () {
      final games = List.generate(30, (i) => game('p$i', i));
      expect(rankBestScores(games, limit: 10), hasLength(10));
    });
  });

  group('PlayGame json', () {
    test('round-trips through Firestore json', () {
      final original = PlayGame(
        id: 'g1',
        userId: 'u1',
        userName: 'Anu',
        mode: PlayMode.daily,
        seed: 99,
        runs: 26,
        wickets: 1,
        balls: 10,
        fours: 2,
        sixes: 2,
        target: 25,
        won: true,
        dailyDate: '2026-11-06',
        createdAt: DateTime(2026, 11, 6, 10),
      );
      final copy = PlayGame.fromJson(original.toJson());
      expect(copy.mode, PlayMode.daily);
      expect(copy.runs, 26);
      expect(copy.won, isTrue);
      expect(copy.dailyDate, '2026-11-06');
      expect(copy.createdAt, original.createdAt);
    });
  });
}
