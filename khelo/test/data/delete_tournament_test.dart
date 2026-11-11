import 'package:data/errors/app_error.dart';
import 'package:data/errors/app_error_l10n_codes.dart';
import 'package:data/service/device/device_service.dart';
import 'package:data/service/match/match_service.dart';
import 'package:data/service/team/team_service.dart';
import 'package:data/service/tournament/tournament_service.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/service/user/user_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late TournamentService service;

  setUp(() async {
    db = FakeFirebaseFirestore();
    final users = UserService(
      null,
      db,
      _FakeDevice(),
    );
    final teams = TeamService(db, users);
    service = TournamentService(
      db,
      teams,
      MatchService(db, teams, users),
      users,
    );
    await db.collection('team_pools').doc('pool').set({
      'id': 'pool',
      'name': 'Sample Teams',
      'team_ids': ['a', 'b'],
    });
    for (final team in ['a', 'b']) {
      await db.collection('teams').doc(team).set({
        'id': team,
        'name': team,
        'pool_id': 'pool',
        'team_players': <Map<String, dynamic>>[],
      });
    }
    await db.collection('tournaments').doc('t1').set({
      'id': 't1',
      'name': 'Sample premier league',
      'team_ids': ['a', 'b'],
      'match_ids': ['m1'],
      'pool_id': 'pool',
    });
    await db.collection('matches').doc('m1').set({
      'id': 'm1',
      'tournament_id': 't1',
      'match_status': 1,
    });
    await db.collection('matches').doc('m2').set({
      'id': 'm2',
      'tournament_id': 't1',
      'match_status': 1,
    });
  });

  test('deletes the tournament and its scheduled matches', () async {
    await service.deleteTournament('t1');
    expect(
        (await db.collection('tournaments').doc('t1').get()).exists, isFalse);
    expect((await db.collection('matches').get()).docs, isEmpty);
  });

  test('refuses once a match has been played', () async {
    await db.collection('matches').doc('m2').update({'match_status': 3});
    await expectLater(
      service.deleteTournament('t1'),
      throwsA(isA<AppError>().having((e) => e.l10nCode, 'code',
          AppErrorL10nCodes.tournamentHasPlayedMatches)),
    );
    expect((await db.collection('tournaments').doc('t1').get()).exists, isTrue);
    expect((await db.collection('matches').get()).docs, hasLength(2));
  });

  test('its pool can be deleted once the tournament is gone', () async {
    final pools = TournamentTeamService(db);
    final pool = await pools.poolOfTournament('t1');
    expect(pool?.name, 'Sample Teams');
    expect(await pools.poolUsageCount('pool'), 1);

    await service.deleteTournament('t1');
    await pools.deletePool('pool');
    expect((await db.collection('team_pools').get()).docs, isEmpty);
    expect((await db.collection('teams').get()).docs, isEmpty);
  });
}

class _FakeDevice extends Fake implements DeviceService {}
