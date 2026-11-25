import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/api/ball_score/ball_score_model.dart';
import 'package:data/api/innings/inning_model.dart';
import 'package:data/api/match/match_model.dart';
import 'package:data/service/ball_score/ball_score_service.dart';
import 'package:data/service/innings/inning_service.dart';
import 'package:data/service/match/match_service.dart';
import 'package:data/service/team/team_service.dart';
import 'package:data/service/user/user_service.dart';
import 'package:data/service/device/device_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDevice extends Fake implements DeviceService {}

/// Proves the scoreboard write path updates match team runs + innings for an
/// independent (non-tournament) match — the same path the UI uses when scoring.
void main() {
  test('independent match: addBall updates team runs and innings', () async {
    final db = FakeFirebaseFirestore();
    final users = UserService(null, db, _FakeDevice());
    final teams = TeamService(db, users);
    final matches = MatchService(db, teams, users);
    final innings = InningsService(db);
    final balls = BallScoreService(db, matches, innings);

    const owner = 'owner_1';
    const teamA = 'team_a';
    const teamB = 'team_b';
    const striker = 'p_striker';
    const nonStriker = 'p_non';
    const bowler = 'p_bowler';

    await db.collection('users').doc(striker).set({'id': striker, 'name': 'S'});
    await db.collection('users').doc(nonStriker).set({'id': nonStriker, 'name': 'N'});
    await db.collection('users').doc(bowler).set({'id': bowler, 'name': 'B'});
    await db.collection('teams').doc(teamA).set({
      'id': teamA,
      'name': 'Alpha',
      'name_lowercase': 'alpha',
      'created_by': owner,
    });
    await db.collection('teams').doc(teamB).set({
      'id': teamB,
      'name': 'Beta',
      'name_lowercase': 'beta',
      'created_by': owner,
    });

    final matchId = await matches.updateMatch(MatchModel(
      id: '',
      players: const [striker, nonStriker, bowler],
      team_ids: const [teamA, teamB],
      team_creator_ids: const [owner],
      teams: [
        MatchTeamModel(
          team_id: teamA,
          squad: [
            MatchPlayer(id: striker),
            MatchPlayer(id: nonStriker),
          ],
        ),
        MatchTeamModel(
          team_id: teamB,
          squad: [MatchPlayer(id: bowler)],
        ),
      ],
      match_type: MatchType.limitedOvers,
      number_of_over: 5,
      over_per_bowler: 2,
      city: 'Jaffna',
      ground: 'Score Test Ground',
      start_time: DateTime.now(),
      start_at: DateTime.now(),
      updated_at: DateTime.now(),
      created_by: owner,
      ball_type: BallType.leather,
      pitch_type: PitchType.turf,
      match_status: MatchStatus.running,
      toss_winner_id: teamA,
      toss_decision: TossDecision.bat,
      current_playing_team_id: teamA,
      scorer_ids: const [owner],
    ));

    final inn1 = innings.generateInningId;
    final inn2 = innings.generateInningId;
    await innings.createInnings(innings: [
      InningModel(
        id: inn1,
        match_id: matchId,
        team_id: teamA,
        index: 1,
        innings_status: InningStatus.running,
      ),
      InningModel(
        id: inn2,
        match_id: matchId,
        team_id: teamB,
        index: 2,
        innings_status: InningStatus.yetToStart,
      ),
    ]);

    final ballId = balls.generateBallScoreId;
    await balls.addBallScoreAndUpdateTeamDetails(
      score: BallScoreModel(
        id: ballId,
        inning_id: inn1,
        match_id: matchId,
        over_number: 1,
        ball_number: 1,
        bowler_id: bowler,
        batsman_id: striker,
        non_striker_id: nonStriker,
        runs_scored: 4,
        is_four: true,
        is_six: false,
        legal_delivery: true,
        time: DateTime.now(),
        score_time: DateTime.now(),
      ),
      matchId: matchId,
      battingTeamId: teamA,
      battingTeamInningId: inn1,
      totalRuns: 4,
      bowlingTeamId: teamB,
      bowlingTeamInningId: inn2,
      totalWicketTaken: 0,
      totalBowlingTeamRuns: 0,
    );

    final matchSnap =
        await db.collection('matches').doc(matchId).get();
    final matchTeams = (matchSnap.data()!['teams'] as List).cast<Map>();
    final batting = matchTeams.firstWhere((t) => t['team_id'] == teamA);
    expect(batting['run'], 4);

    final innSnap = await db.collection('innings').doc(inn1).get();
    expect(innSnap.data()!['total_runs'], 4);

    final ballSnap = await db.collection('ball_scores').doc(ballId).get();
    expect(ballSnap.exists, isTrue);
    expect(ballSnap.data()!['runs_scored'], 4);
  });
}
