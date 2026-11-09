import 'package:data/api/play/play_models.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/domain/play/cricket_game.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:khelo/ui/flow/play/game/play_game_screen.dart';

Widget gameApp(PlayGameArgs args) => ProviderScope(
      overrides: [currentUserPod.overrideWithValue(null)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayGameScreen(args: args),
      ),
    );

void main() {
  const seed = 2026;
  final daily = DailyChallenge.forDate(DateTime(2026, 11, 6));

  testWidgets('starts with an empty scorecard and a tap-to-start prompt',
      (tester) async {
    await tester.pumpWidget(gameApp(PlayGameArgs.daily(daily)));

    expect(find.text('0/0'), findsOneWidget);
    expect(find.text('Tap to start'), findsOneWidget);
    expect(find.text('Need ${daily.target} off 12'), findsOneWidget);
  });

  testWidgets('a tap exactly as the ball arrives scores a six', (tester) async {
    await tester.pumpWidget(gameApp(PlayGameArgs.daily(daily)));
    final firstBall = Innings.start(seed: daily.seed).nextDelivery!;

    await tester.tapAt(const Offset(200, 500));
    await tester.pump();
    await tester.pump(Duration(milliseconds: firstBall.travelMs));
    await tester.tapAt(const Offset(200, 500));
    await tester.pump();

    expect(find.text('SIX!'), findsOneWidget);
    expect(find.text('6/0'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('leaving the ball records it and bowls the next one',
      (tester) async {
    await tester.pumpWidget(gameApp(PlayGameArgs.daily(daily)));
    final firstBall = Innings.start(seed: daily.seed).nextDelivery!;

    await tester.tapAt(const Offset(200, 500));
    await tester.pump();
    await tester.pump(Duration(
        milliseconds: firstBall.travelMs + GameRules.lateWindowMs + 20));

    expect(find.text('Left alone'), findsOneWidget);
    expect(find.text(firstBall.onStumps ? 'OUT!' : 'Dot ball'), findsOneWidget);
    expect(find.text('Need ${daily.target} off 11'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  test('quick play seeds differ between games', () {
    expect(PlayGameArgs.quick().seed, isNot(PlayGameArgs.quick().seed));
  });

  test('a challenge reply faces the creator\'s balls and chases their score',
      () {
    final challenge = PlayChallenge(
      id: 'c1',
      seed: seed,
      creatorId: 'a',
      creatorName: 'Arun',
      opponentId: 'b',
      opponentName: 'Bala',
      creatorScore: const PlayScore(runs: 28, wickets: 1, balls: 12),
      createdAt: DateTime(2026, 11, 6),
    );
    final args = PlayGameArgs.answerChallenge(challenge);
    expect(args.seed, seed);
    expect(args.target, 29);
    expect(args.mode, PlayMode.challenge);
  });
}
