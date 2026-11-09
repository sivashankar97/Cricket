import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/domain/play/cricket_game.dart';

void main() {
  const onStumps = Delivery(travelMs: 1200, onStumps: true, line: 0);
  const wide = Delivery(travelMs: 1200, onStumps: false, line: 0.8);

  group('judgeShot', () {
    test('a tap within 45ms of the ball arriving is a six', () {
      expect(judgeShot(onStumps, tapOffsetMs: -40), ShotResult.six);
      expect(judgeShot(onStumps, tapOffsetMs: 45), ShotResult.six);
    });

    test('a tap within 100ms is a four', () {
      expect(judgeShot(onStumps, tapOffsetMs: 90), ShotResult.four);
    });

    test('a tap within 160ms is two runs', () {
      expect(judgeShot(onStumps, tapOffsetMs: -150), ShotResult.two);
    });

    test('a tap within 230ms is a single', () {
      expect(judgeShot(onStumps, tapOffsetMs: 230), ShotResult.single);
    });

    test('a badly mistimed swing at a ball on the stumps is bowled out', () {
      expect(judgeShot(onStumps, tapOffsetMs: -400), ShotResult.out);
    });

    test('a badly mistimed swing at a ball off the stumps is a dot', () {
      expect(judgeShot(wide, tapOffsetMs: -400), ShotResult.dot);
    });

    test('leaving a ball on the stumps is out, leaving a wide one is a dot',
        () {
      expect(judgeShot(onStumps, tapOffsetMs: null), ShotResult.out);
      expect(judgeShot(wide, tapOffsetMs: null), ShotResult.dot);
    });
  });

  group('deliveriesForSeed', () {
    test('the same seed always bowls the same deliveries', () {
      expect(deliveriesForSeed(42), deliveriesForSeed(42));
    });

    test('different seeds bowl different deliveries', () {
      expect(deliveriesForSeed(1), isNot(deliveriesForSeed(2)));
    });

    test('bowls one innings worth of balls within the speed range', () {
      final balls = deliveriesForSeed(7);
      expect(balls, hasLength(GameRules.balls));
      for (final ball in balls) {
        expect(ball.travelMs, inInclusiveRange(900, 1500));
        expect(ball.line, inInclusiveRange(-1, 1));
      }
    });
  });

  group('Innings', () {
    test('adds runs, boundaries and balls for each shot', () {
      final innings = Innings.start(seed: 1)
          .record(ShotResult.six)
          .record(ShotResult.four)
          .record(ShotResult.single)
          .record(ShotResult.dot);

      expect(innings.runs, 11);
      expect(innings.sixes, 1);
      expect(innings.fours, 1);
      expect(innings.balls, 4);
      expect(innings.wickets, 0);
      expect(innings.isOver, isFalse);
    });

    test('ends after all balls are bowled', () {
      var innings = Innings.start(seed: 1);
      for (var i = 0; i < GameRules.balls; i++) {
        innings = innings.record(ShotResult.dot);
      }
      expect(innings.isOver, isTrue);
      expect(innings.nextDelivery, isNull);
    });

    test('ends when all wickets fall', () {
      var innings = Innings.start(seed: 1);
      for (var i = 0; i < GameRules.wickets; i++) {
        innings = innings.record(ShotResult.out);
      }
      expect(innings.wickets, GameRules.wickets);
      expect(innings.isOver, isTrue);
    });

    test('ends as soon as the target is reached and counts as won', () {
      final innings = Innings.start(seed: 1, target: 10)
          .record(ShotResult.six)
          .record(ShotResult.four);
      expect(innings.isOver, isTrue);
      expect(innings.won, isTrue);
    });

    test('is lost when the balls run out below the target', () {
      var innings = Innings.start(seed: 1, target: 50);
      for (var i = 0; i < GameRules.balls; i++) {
        innings = innings.record(ShotResult.single);
      }
      expect(innings.won, isFalse);
    });

    test('recording after the innings is over changes nothing', () {
      var innings = Innings.start(seed: 1);
      for (var i = 0; i < GameRules.wickets; i++) {
        innings = innings.record(ShotResult.out);
      }
      expect(innings.record(ShotResult.six).runs, 0);
    });

    test('runsNeeded counts down to the target', () {
      final innings =
          Innings.start(seed: 1, target: 20).record(ShotResult.four);
      expect(innings.runsNeeded, 16);
      expect(innings.ballsLeft, GameRules.balls - 1);
    });
  });

  group('DailyChallenge', () {
    test('is the same for every player on the same day', () {
      final morning = DailyChallenge.forDate(DateTime(2026, 11, 6, 8));
      final night = DailyChallenge.forDate(DateTime(2026, 11, 6, 23));
      expect(morning.seed, night.seed);
      expect(morning.target, night.target);
      expect(morning.dateKey, '2026-11-06');
    });

    test('changes the next day', () {
      final today = DailyChallenge.forDate(DateTime(2026, 11, 6));
      final tomorrow = DailyChallenge.forDate(DateTime(2026, 11, 7));
      expect(today.seed, isNot(tomorrow.seed));
    });

    test('target is between 16 and 30', () {
      for (var day = 1; day <= 60; day++) {
        final target = DailyChallenge.forDate(DateTime(2026, 1, day)).target;
        expect(target, inInclusiveRange(16, 30));
      }
    });
  });

  group('challengeWinner', () {
    test('the higher score wins', () {
      expect(challengeWinner(creatorRuns: 30, opponentRuns: 31),
          ChallengeWinner.opponent);
      expect(challengeWinner(creatorRuns: 30, opponentRuns: 12),
          ChallengeWinner.creator);
    });

    test('equal scores are a tie', () {
      expect(challengeWinner(creatorRuns: 24, opponentRuns: 24),
          ChallengeWinner.tie);
    });
  });
}
