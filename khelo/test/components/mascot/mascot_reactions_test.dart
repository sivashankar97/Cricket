import 'package:data/api/ball_score/ball_score_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/components/mascot/mascot_reactions.dart';
import 'package:khelo/domain/play/cricket_game.dart';

BallScoreModel _ball({
  int runs = 0,
  bool four = false,
  bool six = false,
  ExtrasType? extras,
  int? extrasAwarded,
  WicketType? wicket,
}) =>
    BallScoreModel(
      id: 'b',
      inning_id: 'i',
      match_id: 'm',
      over_number: 1,
      ball_number: 1,
      bowler_id: 'bowler',
      batsman_id: 'bat',
      non_striker_id: 'ns',
      runs_scored: runs,
      extras_type: extras,
      extras_awarded: extrasAwarded,
      wicket_type: wicket,
      is_four: four,
      is_six: six,
    );

void main() {
  group('reactionForBall', () {
    test('six, four and wicket', () {
      expect(reactionForBall(_ball(runs: 6, six: true)), MascotReaction.six);
      expect(reactionForBall(_ball(runs: 4, four: true)), MascotReaction.four);
      expect(reactionForBall(_ball(wicket: WicketType.bowled)),
          MascotReaction.wicket);
    });

    test('a wicket beats a boundary on the same ball', () {
      expect(reactionForBall(_ball(six: true, wicket: WicketType.runOut)),
          MascotReaction.wicket);
    });

    test('retirements are not wickets or dot balls', () {
      expect(reactionForBall(_ball(wicket: WicketType.retired)), isNull);
      expect(reactionForBall(_ball(wicket: WicketType.retiredHurt)), isNull);
    });

    test('only a clean 0-run delivery is a dot ball', () {
      expect(reactionForBall(_ball()), MascotReaction.dotBall);
      expect(reactionForBall(_ball(extras: ExtrasType.wide, extrasAwarded: 1)),
          isNull);
      expect(reactionForBall(_ball(extras: ExtrasType.noBall)), isNull);
      expect(
          reactionForBall(_ball(extras: ExtrasType.legBye, extrasAwarded: 2)),
          isNull);
      expect(reactionForBall(_ball(runs: 2)), isNull);
    });
  });

  group('reactionForShot', () {
    test('out and no swing', () {
      expect(reactionForShot(ShotResult.out, 10), MascotReaction.wicket);
      expect(reactionForShot(ShotResult.dot, null), MascotReaction.dotBall);
    });

    test('timing inside the perfect window', () {
      expect(reactionForShot(ShotResult.six, GameRules.perfectWindowMs),
          MascotReaction.perfectTiming);
      expect(reactionForShot(ShotResult.six, -GameRules.perfectWindowMs),
          MascotReaction.perfectTiming);
    });

    test('four, early and late', () {
      expect(reactionForShot(ShotResult.four, 80), MascotReaction.four);
      expect(
          reactionForShot(ShotResult.single, -150), MascotReaction.earlyShot);
      expect(reactionForShot(ShotResult.single, 150), MascotReaction.lateShot);
    });
  });

  group('Tamil lines', () {
    test('every reaction and movie line has text', () {
      for (final reaction in MascotReaction.values) {
        expect(reaction.message(mascotText), isNotEmpty);
      }
      expect(mascotMovieLines(mascotText), everyElement(isNotEmpty));
    });

    test('the tiger speaks Tamil', () {
      expect(mascotText.localeName, 'ta');
    });
  });

  group('movie lines on tap', () {
    test('replace a fun cue and never repeat back to back', () {
      final mascot = MascotController(() => true);
      mascot.react(MascotReaction.six, duration: const Duration(seconds: 5));
      final seen = <String>[];
      for (var i = 0; i < 10; i++) {
        mascot.playMovieLine();
        seen.add(mascot.current!.message);
      }
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], isNot(seen[i - 1]));
      }
      expect(mascotMovieLines(mascotText), containsAll(seen.toSet()));
      mascot.dispose();
    });

    test('never replace a serious cue', () {
      final mascot = MascotController(() => true);
      mascot.react(MascotReaction.internet,
          duration: const Duration(seconds: 5));
      final message = mascot.current!.message;
      mascot.playMovieLine();
      expect(mascot.current!.message, message);

      mascot.react(MascotReaction.wicket,
          duration: const Duration(seconds: 5), allowFun: false);
      mascot.playMovieLine();
      expect(
          mascot.current!.message, MascotReaction.wicket.message(mascotText));
      mascot.dispose();
    });

    test('do nothing when no cue is showing', () {
      final mascot = MascotController(() => true);
      mascot.playMovieLine();
      expect(mascot.current, isNull);
      mascot.dispose();
    });
  });

  test('reading time grows with length and stays within bounds', () {
    final short = MascotController.readingTime('Hi');
    final long = MascotController.readingTime('x' * 500);
    expect(short, const Duration(milliseconds: 2500));
    expect(long, const Duration(milliseconds: 8000));
    expect(MascotController.readingTime('x' * 60),
        greaterThan(MascotController.readingTime('x' * 20)));
  });
}
