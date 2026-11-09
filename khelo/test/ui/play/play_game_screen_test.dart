import 'package:data/api/play/play_models.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:data/storage/provider/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/domain/play/cricket_game.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:khelo/ui/flow/play/game/play_arena.dart';
import 'package:khelo/ui/flow/play/game/play_game_screen.dart';
import 'package:khelo/ui/flow/play/game/play_sounds.dart';

Widget gameApp(PlayGameArgs args) => ProviderScope(
      overrides: [
        currentUserPod.overrideWithValue(null),
        mascotProvider.overrideWith((ref) => MascotController(() => false)),
        playSoundsProvider.overrideWithValue(PlaySounds.silent()),
        playSoundOnPod
            .overrideWith((ref) => PreferenceNotifier<bool>(false, null)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayGameScreen(args: args),
      ),
    );

void main() {
  const seed = 2026;
  final daily = DailyChallenge.forDate(DateTime(2026, 11, 6));

  /// Taps to start, then waits out the bowler's run-up.
  Future<void> startBall(WidgetTester tester) async {
    await tester.tapAt(const Offset(400, 300));
    await tester.pump();
    await tester
        .pump(PlayArena.runUpDuration + const Duration(milliseconds: 1));
  }

  testWidgets('starts with an empty scoreboard and a tap-to-start prompt',
      (tester) async {
    await tester.pumpWidget(gameApp(PlayGameArgs.daily(daily)));

    expect(find.text('0/0'), findsOneWidget);
    expect(find.text('Tap to start'), findsOneWidget);
    expect(find.text('Need ${daily.target} off 12'), findsOneWidget);
    expect(find.text('Overs 0.0/2'), findsOneWidget);
  });

  testWidgets('a tap exactly as the ball arrives scores a six', (tester) async {
    await tester.pumpWidget(gameApp(PlayGameArgs.daily(daily)));
    final firstBall = Innings.start(seed: daily.seed).nextDelivery!;

    await startBall(tester);
    await tester.pump(Duration(milliseconds: firstBall.travelMs));
    await tester.tapAt(const Offset(400, 300));
    await tester.pump();

    expect(find.text('SIX!'), findsOneWidget);
    expect(find.text('6/0'), findsOneWidget);
    expect(find.text('Overs 0.1/2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('leaving the ball records it and bowls the next one',
      (tester) async {
    await tester.pumpWidget(gameApp(PlayGameArgs.daily(daily)));
    final firstBall = Innings.start(seed: daily.seed).nextDelivery!;

    await startBall(tester);
    await tester.pump(Duration(
        milliseconds: firstBall.travelMs + GameRules.lateWindowMs + 20));

    expect(find.text('Left alone'), findsOneWidget);
    expect(find.text(firstBall.onStumps ? 'OUT!' : 'Dot ball'), findsOneWidget);
    expect(find.text('Need ${daily.target} off 11'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('taps during the run-up are ignored', (tester) async {
    await tester.pumpWidget(gameApp(PlayGameArgs.daily(daily)));

    await tester.tapAt(const Offset(400, 300));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(const Offset(400, 300));
    await tester.pump();

    expect(find.text('0/0'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  const screens = {
    'small phone': Size(320, 568),
    'phone': Size(390, 844),
    'landscape phone': Size(800, 360),
    'tablet': Size(820, 1180),
    'desktop': Size(1440, 900),
  };
  for (final screen in screens.entries) {
    testWidgets('fits a ${screen.key} without overflowing', (tester) async {
      tester.view.physicalSize = screen.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(gameApp(PlayGameArgs.daily(daily)));

      expect(find.text('Tap to start'), findsOneWidget);
      await tester.tapAt(tester.getCenter(find.byType(PlayArena)));
      await tester.pump();
      await tester
          .pump(PlayArena.runUpDuration + const Duration(milliseconds: 1));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });
  }

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
