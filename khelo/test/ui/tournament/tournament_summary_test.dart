import 'package:data/api/match/match_model.dart';
import 'package:data/api/team/team_model.dart';
import 'package:data/api/tournament/tournament_extras.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/ui/flow/tournament/detail/summary/tournament_summary.dart';

TeamModel _team(String id) =>
    TeamModel(id: id, name: 'Team $id', name_lowercase: 'team $id');

MatchTeamModel _side(String id,
        {int run = 0, double over = 0, int wicket = 0}) =>
    MatchTeamModel(
      team_id: id,
      team: _team(id),
      run: run,
      over: over,
      wicket: wicket,
      squad: [for (var i = 0; i < 11; i++) MatchPlayer(id: '$id$i')],
    );

MatchModel _match(
  String id,
  List<MatchTeamModel> teams, {
  required MatchStatus status,
  String? tossWinner,
  DateTime? at,
}) =>
    MatchModel(
      id: id,
      teams: teams,
      match_type: MatchType.limitedOvers,
      number_of_over: 10,
      over_per_bowler: 2,
      city: '',
      ground: '',
      ball_type: BallType.leather,
      pitch_type: PitchType.turf,
      created_by: 'owner',
      match_status: status,
      toss_winner_id: tossWinner,
      toss_decision: tossWinner == null ? null : TossDecision.bat,
      start_at: at,
    );

void main() {
  test('standings count wins, walkovers, no results and net run rate', () {
    final teams = [_team('a'), _team('b'), _team('c')];
    final matches = [
      _match(
        'm1',
        [
          _side('a', run: 120, over: 10, wicket: 5),
          _side('b', run: 100, over: 10, wicket: 3),
        ],
        status: MatchStatus.finish,
        tossWinner: 'a',
        at: DateTime(2026, 1, 1),
      ),
      _match('m2', [_side('b'), _side('c')],
          status: MatchStatus.abandoned, at: DateTime(2026, 1, 2)),
      _match('m3', [_side('a'), _side('c')],
          status: MatchStatus.abandoned, at: DateTime(2026, 1, 3)),
    ];

    final summary = TournamentSummary.build(
      teams: teams,
      matches: matches,
      balls: const [],
      matchExtras: const {'m2': MatchExtras(walkoverWinnerId: 'c')},
    );

    expect(summary.standings.map((r) => r.team.id), ['a', 'c', 'b']);

    final a = summary.standingOf('a')!;
    expect((a.played, a.won, a.lost, a.noResult, a.points), (2, 1, 0, 1, 3));
    expect(a.nrr, closeTo(2.0, 0.001));
    expect(a.form, [FormResult.win, FormResult.noResult]);

    final c = summary.standingOf('c')!;
    expect((c.played, c.won, c.noResult, c.points), (2, 1, 1, 3));

    final b = summary.standingOf('b')!;
    expect((b.played, b.lost, b.points), (2, 2, 0));
    expect(b.nrr, closeTo(-2.0, 0.001));
    expect(summary.rankOf('b'), 3);
  });
}
