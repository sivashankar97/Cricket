import 'dart:async';

import 'package:data/api/play/play_match.dart';
import 'package:data/api/play/play_models.dart';
import 'package:data/service/play/play_service.dart';
import 'package:data/storage/provider/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/domain/play/cricket_game.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:khelo/ui/flow/play/game/play_arena.dart';
import 'package:khelo/ui/flow/play/game/play_sounds.dart';
import 'package:khelo/ui/flow/play/match/play_match_screen.dart';
import 'package:khelo/ui/flow/play/play_providers.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/theme.dart';

class FakePlayService implements PlayService {
  final calls = <String>[];

  @override
  Future<void> markSeen(String id, String userId) async {}

  @override
  Future<bool> acceptMatch(String id) async {
    calls.add('accept');
    return true;
  }

  @override
  Future<bool> declineMatch(String id) async {
    calls.add('decline');
    return true;
  }

  @override
  Future<bool> cancelMatch(String id) async {
    calls.add('cancel');
    return true;
  }

  @override
  Future<bool> callToss(
    String id, {
    required String call,
    required String winnerId,
  }) async {
    calls.add('toss:$call:$winnerId');
    return true;
  }

  @override
  Future<bool> chooseBattingFirst(String id, {required String batterId}) async {
    calls.add('bat:$batterId');
    return true;
  }

  @override
  Future<void> saveBalls(
    String id, {
    required int innings,
    required List<PlayBall> balls,
  }) async {
    calls.add('balls:$innings:${balls.map((ball) => ball.result).join(',')}');
  }

  @override
  Future<bool> startSecondInnings(String id) async {
    calls.add('second');
    return true;
  }

  @override
  Future<bool> completeMatch(
    String id, {
    required String? winnerId,
    required PlayMatchResultType resultType,
    required int margin,
  }) async {
    calls.add('complete:$winnerId:${resultType.value}:$margin');
    return true;
  }

  @override
  Future<void> saveMatchGames(List<PlayGame> games) async {
    calls.add('games:${games.map((game) => game.id).join(',')}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const host = PlayMatchPlayer(id: 'h', name: 'Arun');
const guest = PlayMatchPlayer(id: 'g', name: 'Bala');

PlayMatch match({
  PlayMatchStatus status = PlayMatchStatus.requested,
  String? tossCall,
  String? tossWinnerId,
  String? battingFirstId,
  List<PlayBall> innings1 = const [],
  String? winnerId,
  PlayMatchResultType? resultType,
  int? margin,
}) =>
    PlayMatch(
      id: 'm1',
      seed: 42,
      overs: 1,
      wickets: 2,
      host: host,
      guest: guest,
      status: status,
      tossCall: tossCall,
      tossWinnerId: tossWinnerId,
      battingFirstId: battingFirstId,
      innings1: innings1,
      winnerId: winnerId,
      resultType: resultType,
      margin: margin,
      createdAt: DateTime.now(),
    );

void main() {
  late FakePlayService service;
  late StreamController<PlayMatch?> updates;

  setUp(() {
    service = FakePlayService();
    updates = StreamController<PlayMatch?>();
  });

  tearDown(() {
    updates.close();
  });

  Future<void> open(WidgetTester tester, PlayMatch first,
      {String me = 'g'}) async {
    updates.add(first);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        playServiceProvider.overrideWithValue(service),
        playMatchProvider('m1').overrideWith((ref) => updates.stream),
        playIdentityProvider.overrideWithValue(
          PlayIdentity(id: me, name: me == 'g' ? 'Bala' : 'Arun'),
        ),
        mascotProvider.overrideWith((ref) => MascotController(() => false)),
        playSoundsProvider.overrideWithValue(PlaySounds.silent()),
        playSoundOnPod
            .overrideWith((ref) => PreferenceNotifier<bool>(false, null)),
      ],
      child: AppTheme(
        colorScheme: appColorSchemeLight,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlayMatchScreen(matchId: 'm1'),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('the invited player can accept a match request', (tester) async {
    await open(tester, match());

    expect(find.text('Arun challenges you!'), findsOneWidget);
    expect(find.text('Live match · 1 over · 2 wickets. Ready to play?'),
        findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pump();
    expect(service.calls, ['accept']);
    await close(tester);
  });

  testWidgets('the host waits in the lobby and can cancel', (tester) async {
    await open(tester, match(), me: 'h');

    expect(find.text('Waiting for Bala'), findsOneWidget);
    await tester.tap(find.text('Cancel request'));
    await tester.pump();
    expect(service.calls, ['cancel']);
    await close(tester);
  });

  testWidgets('after the VS intro the guest calls the toss', (tester) async {
    await open(tester, match(status: PlayMatchStatus.toss));

    expect(find.text('VS'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Call it!'), findsOneWidget);
    await tester.tap(find.text('Heads'));
    await tester.pump();
    // Seed 42 is even, so the coin lands heads and the guest wins.
    expect(service.calls, ['toss:heads:g']);
    await close(tester);
  });

  testWidgets('the toss winner picks bat or bowl after the coin lands',
      (tester) async {
    await open(
      tester,
      match(
        status: PlayMatchStatus.toss,
        tossCall: 'heads',
        tossWinnerId: 'g',
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('You won the toss!'), findsOneWidget);
    await tester.tap(find.text('Bowl first'));
    await tester.pump();
    expect(service.calls, ['bat:h']);
    await close(tester);
  });

  testWidgets('the watcher sees each ball replayed, then the score',
      (tester) async {
    final live = match(
      status: PlayMatchStatus.live,
      tossCall: 'heads',
      tossWinnerId: 'h',
      battingFirstId: 'h',
      innings1: const [PlayBall('four', 10)],
    );
    await open(tester, live);

    expect(find.text('Arun'), findsOneWidget);
    expect(find.text('4/0'), findsOneWidget);
    expect(find.text('Watch live. You chase this score next.'), findsOneWidget);

    updates.add(match(
      status: PlayMatchStatus.live,
      tossCall: 'heads',
      tossWinnerId: 'h',
      battingFirstId: 'h',
      innings1: const [PlayBall('four', 10), PlayBall('six', 0)],
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('4/0'), findsOneWidget);

    final second =
        Innings.start(seed: 42, format: MatchFormat.oneOver).deliveries[1];
    await tester
        .pump(PlayArena.runUpDuration + const Duration(milliseconds: 1));
    await tester.pump(Duration(milliseconds: second.travelMs + 20));
    await tester.pump();

    expect(find.text('SIX!'), findsOneWidget);
    expect(find.text('10/0'), findsOneWidget);
    await close(tester);
  });

  testWidgets('the batter counts down, plays and saves every ball',
      (tester) async {
    await open(
      tester,
      match(
        status: PlayMatchStatus.live,
        tossCall: 'heads',
        tossWinnerId: 'h',
        battingFirstId: 'h',
      ),
      me: 'h',
    );
    // VS intro, then "Get ready" and 3, 2, 1, GO.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('Your innings'), findsWidgets);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('Tap to start'), findsOneWidget);

    final first =
        Innings.start(seed: 42, format: MatchFormat.oneOver).deliveries[0];
    await tester.tapAt(const Offset(400, 350));
    await tester.pump();
    await tester
        .pump(PlayArena.runUpDuration + const Duration(milliseconds: 1));
    await tester.pump(Duration(milliseconds: first.travelMs));
    await tester.tapAt(const Offset(400, 350));
    await tester.pump();

    expect(find.text('SIX!'), findsOneWidget);
    expect(service.calls, ['balls:1:six']);
    await close(tester);
  });

  testWidgets('a batter who reopens a finished innings hands over',
      (tester) async {
    await open(
      tester,
      match(
        status: PlayMatchStatus.live,
        tossCall: 'heads',
        tossWinnerId: 'h',
        battingFirstId: 'h',
        innings1: const [PlayBall('out'), PlayBall('four', 3), PlayBall('out')],
      ),
      me: 'h',
    );
    await tester.pump();

    expect(service.calls, ['balls:1:out,four,out', 'second']);
    await close(tester);
  });

  testWidgets('the chaser settles the match and saves both games',
      (tester) async {
    await open(
      tester,
      PlayMatch(
        id: 'm1',
        seed: 42,
        overs: 1,
        wickets: 2,
        host: host,
        guest: guest,
        status: PlayMatchStatus.live,
        battingFirstId: 'h',
        currentInnings: 2,
        innings1: const [PlayBall('four', 1), PlayBall('out'), PlayBall('out')],
        innings2: const [PlayBall('six', 0)],
        createdAt: DateTime.now(),
      ),
    );
    await tester.pump();

    expect(service.calls, [
      'balls:2:six',
      'complete:g:wickets:2',
      'games:m1_h,m1_g',
    ]);
    await close(tester);
  });

  testWidgets('a finished match shows the winner and both scorecards',
      (tester) async {
    await open(
      tester,
      PlayMatch(
        id: 'm1',
        seed: 42,
        overs: 1,
        wickets: 2,
        host: host,
        guest: guest,
        status: PlayMatchStatus.completed,
        battingFirstId: 'h',
        innings1: const [PlayBall('six', 0), PlayBall('dot')],
        innings2: const [PlayBall('four', 5), PlayBall('out')],
        winnerId: 'h',
        resultType: PlayMatchResultType.runs,
        margin: 2,
        createdAt: DateTime.now(),
      ),
    );

    expect(find.text('YOU LOSE'), findsOneWidget);
    expect(find.text('Arun won by 2 runs'), findsOneWidget);
    expect(find.text('SCORECARD'), findsOneWidget);
    expect(find.text('Rematch'), findsOneWidget);
    await close(tester);
  });

  const screens = {
    'small phone': Size(320, 568),
    'landscape phone': Size(800, 360),
    'desktop': Size(1440, 900),
  };
  for (final screen in screens.entries) {
    testWidgets('every stage fits a ${screen.key}', (tester) async {
      tester.view.physicalSize = screen.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await open(tester, match());
      expect(find.text('Accept'), findsOneWidget);

      updates.add(match(status: PlayMatchStatus.toss));
      await tester.pump();
      await tester.pump();
      expect(find.text('VS'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('Call it!'), findsOneWidget);

      updates.add(PlayMatch(
        id: 'm1',
        seed: 42,
        overs: 1,
        wickets: 2,
        host: host,
        guest: guest,
        status: PlayMatchStatus.completed,
        battingFirstId: 'h',
        innings1: const [PlayBall('six', 0), PlayBall('dot')],
        innings2: const [PlayBall('four', 5), PlayBall('out')],
        winnerId: 'h',
        resultType: PlayMatchResultType.runs,
        margin: 2,
        createdAt: DateTime.now(),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('SCORECARD'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }

  test('matches turn stored balls back into innings', () {
    final played = match(
      battingFirstId: 'h',
      innings1: const [PlayBall('six', 3), PlayBall('out')],
    );
    final innings = played.innings(1);
    expect(innings.runs, 6);
    expect(innings.wickets, 1);
    expect(innings.offsets, [3, null]);
    expect(ballsOf(innings), played.innings1);
    expect(played.innings(2).target, 7);
    expect(shotFromName('nonsense'), ShotResult.dot);
  });

  test('a format is stored as overs and wickets', () {
    expect(match().format, MatchFormat.oneOver);
    expect(PlayMode.values.map((mode) => mode.value), contains('match'));
  });
}
