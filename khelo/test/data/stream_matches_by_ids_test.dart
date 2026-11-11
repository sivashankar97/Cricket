import 'package:data/api/match/match_model.dart';
import 'package:data/service/device/device_service.dart';
import 'package:data/service/match/match_service.dart';
import 'package:data/service/team/team_service.dart';
import 'package:data/service/user/user_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('streams more matches than one whereIn query allows', () async {
    final db = FakeFirebaseFirestore();
    final users = UserService(null, db, _FakeDevice());
    final service = MatchService(db, TeamService(db, users), users);
    final ids = <String>[];
    for (var i = 0; i < 32; i++) {
      ids.add(await service.updateMatch(MatchModel(
        id: 'm$i',
        teams: const [
          MatchTeamModel(team_id: 'a', squad: [MatchPlayer(id: 'p1')]),
          MatchTeamModel(team_id: 'b', squad: [MatchPlayer(id: 'p2')]),
        ],
        match_type: MatchType.limitedOvers,
        number_of_over: 10,
        over_per_bowler: 2,
        city: '',
        ground: '',
        ball_type: BallType.leather,
        pitch_type: PitchType.turf,
        created_by: 'owner',
        match_status: MatchStatus.finish,
      )));
    }

    final matches = await service.streamMatchesByIds(ids).first;

    expect(matches.map((m) => m.id).toSet(), ids.toSet());
  });
}

class _FakeDevice extends Fake implements DeviceService {}
