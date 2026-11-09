import 'package:data/api/match/match_model.dart';
import 'package:data/api/team/team_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:khelo/ui/flow/home/components/live_match_card.dart';
import 'package:khelo/ui/flow/home/components/match_item.dart';
import 'package:khelo/ui/flow/home/components/match_summary.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/theme.dart';

final today = DateTime.now();

MatchTeamModel side(String id, String name,
        {int run = 0, double over = 0, int wicket = 0}) =>
    MatchTeamModel(
      team_id: id,
      team: TeamModel(id: id, name: name, name_lowercase: name.toLowerCase()),
      run: run,
      over: over,
      wicket: wicket,
    );

MatchModel cricketMatch({
  MatchStatus status = MatchStatus.running,
  List<MatchTeamModel>? teams,
  String? tossWinner = 'a',
  TossDecision decision = TossDecision.bat,
  String? batting,
  RevisedTarget? revised,
}) =>
    MatchModel(
      id: 'm1',
      teams: teams ?? [side('a', 'Chennai Kings'), side('b', 'Madurai Lions')],
      match_type: MatchType.limitedOvers,
      number_of_over: 10,
      over_per_bowler: 2,
      city: 'Chennai',
      ground: 'Chepauk',
      ball_type: BallType.tennis,
      pitch_type: PitchType.turf,
      created_by: 'u1',
      match_status: status,
      toss_winner_id: tossWinner,
      toss_decision: tossWinner == null ? null : decision,
      current_playing_team_id: batting,
      revised_target: revised,
      start_at: DateTime(today.year, today.month, today.day, 19, 30),
    );

Widget wrap(Widget child) => AppTheme(
      colorScheme: appColorSchemeLight,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ListView(children: [child])),
      ),
    );

void main() {
  group('MatchSummary', () {
    test('the toss decides who bats first', () {
      final summary =
          MatchSummary.of(cricketMatch(decision: TossDecision.bowl));
      expect(summary.first.team_id, 'b');
      expect(summary.second.team_id, 'a');
    });

    test('first innings shows only the current run rate', () {
      final summary = MatchSummary.of(cricketMatch(
        teams: [side('a', 'A', run: 45, over: 4.3), side('b', 'B')],
        batting: 'a',
      ));
      expect(summary.isChasing, isFalse);
      expect(summary.currentRate, closeTo(10.0, 0.001));
      expect(summary.requiredRate, isNull);
    });

    test('the chase counts runs and balls left', () {
      final summary = MatchSummary.of(cricketMatch(
        teams: [
          side('a', 'A', run: 80, over: 10, wicket: 3),
          side('b', 'B', run: 41, over: 5.0, wicket: 6),
        ],
        batting: 'b',
      ));
      expect(summary.target, 81);
      expect(summary.runsNeeded, 40);
      expect(summary.ballsLeft, 30);
      expect(summary.requiredRate, closeTo(8.0, 0.001));
    });

    test('a revised target replaces runs and overs', () {
      final summary = MatchSummary.of(cricketMatch(
        teams: [
          side('a', 'A', run: 80, over: 10),
          side('b', 'B', run: 20, over: 2.0),
        ],
        batting: 'b',
        revised: const RevisedTarget(runs: 60, overs: 6),
      ));
      expect(summary.target, 60);
      expect(summary.runsNeeded, 40);
      expect(summary.ballsLeft, 24);
    });

    test('no toss yet keeps the listed order and no chase', () {
      final summary = MatchSummary.of(cricketMatch(tossWinner: null));
      expect(summary.tossDone, isFalse);
      expect(summary.first.team_id, 'a');
      expect(summary.isChasing, isFalse);
    });
  });

  const screens = {
    'small phone': Size(320, 568),
    'phone': Size(390, 844),
    'desktop': Size(1440, 900),
  };
  for (final screen in screens.entries) {
    testWidgets('home cards fit a ${screen.key}', (tester) async {
      tester.view.physicalSize = screen.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(Column(
        children: [
          LiveMatchCarousel(matches: [
            cricketMatch(
              teams: [
                side('a', 'Chennai Super Kings Academy',
                    run: 180, over: 20, wicket: 7),
                side('b', 'Madurai Panthers', run: 120, over: 4.2, wicket: 9),
              ],
              batting: 'b',
            ),
            cricketMatch(batting: 'a'),
          ]),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              MatchItem(match: cricketMatch(status: MatchStatus.yetToStart)),
              MatchItem(
                match: cricketMatch(
                  status: MatchStatus.finish,
                  teams: [
                    side('a', 'Chennai Kings', run: 150, over: 10, wicket: 4),
                    side('b', 'Madurai Lions', run: 140, over: 10, wicket: 8),
                  ],
                ),
              ),
            ]),
          ),
        ],
      )));
      await tester.pump();

      expect(find.text('Madurai Panthers need 61 runs in 34 balls'),
          findsOneWidget);
      expect(find.text('RRR 10.76'), findsOneWidget);
      expect(find.text('Chennai Kings won by 10 runs'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
