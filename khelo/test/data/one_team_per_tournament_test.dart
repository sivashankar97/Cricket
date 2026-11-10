import 'package:data/api/auction/auction_models.dart';
import 'package:data/api/tournament_team/squad_clash.dart';
import 'package:data/service/auction/auction_service.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findSquadClash', () {
    test('finds a player listed in two teams', () {
      final clash = findSquadClash([
        (id: 'a', name: 'Team A', playerIds: ['u1', 'u2']),
        (id: 'b', name: 'Team B', playerIds: ['u3']),
        (id: 'c', name: 'Team C', playerIds: ['u2']),
      ]);
      expect(clash?.playerId, 'u2');
      expect(clash?.team.name, 'Team A');
      expect(clash?.other.name, 'Team C');
    });

    test('allows separate squads', () {
      expect(
        findSquadClash([
          (id: 'a', name: 'Team A', playerIds: ['u1']),
          (id: 'b', name: 'Team B', playerIds: ['u2']),
        ]),
        isNull,
      );
    });
  });

  group('adding to a tournament team', () {
    late FakeFirebaseFirestore db;
    late TournamentTeamService service;

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = TournamentTeamService(db);
      await db.collection('teams').doc('a').set({
        'id': 'a',
        'name': 'Team A',
        'team_players': [
          {'id': 'u1', 'role': 'player'},
        ],
      });
      await db.collection('teams').doc('b').set({
        'id': 'b',
        'name': 'Team B',
        'team_players': <Map<String, dynamic>>[],
      });
      await db.collection('teams').doc('c').set({
        'id': 'c',
        'name': 'Team C',
        'team_players': <Map<String, dynamic>>[],
      });
      await db.collection('tournaments').doc('t1').set({
        'id': 't1',
        'name': 'GCPL',
        'team_ids': ['a', 'b'],
      });
    });

    test('refuses a player who plays for another team there', () async {
      await expectLater(
        service.ensureOneTeamPerTournament(
          teamId: 'b',
          players: {'u1': 'Kumar'},
        ),
        throwsA(
          isA<PlayerTeamClashError>()
              .having((e) => e.teamName, 'team', 'Team A')
              .having((e) => e.tournamentName, 'tournament', 'GCPL')
              .having(
                (e) => e.message,
                'message',
                'Kumar is already in Team A in GCPL.',
              ),
        ),
      );
      await expectLater(
        service.addExistingPlayer(
          teamId: 'b',
          userId: 'u1',
          name: 'Kumar',
          existing: const [],
        ),
        throwsA(isA<PlayerTeamClashError>()),
      );
      final teamB = (await db.collection('teams').doc('b').get()).data()!;
      expect(teamB['team_players'], isEmpty);
    });

    test('allows the same player in a team of another tournament', () async {
      await service.ensureOneTeamPerTournament(
        teamId: 'c',
        players: {'u1': 'Kumar'},
      );
      await service.addExistingPlayer(
        teamId: 'c',
        userId: 'u1',
        name: 'Kumar',
        existing: const [],
      );
      final teamC = (await db.collection('teams').doc('c').get()).data()!;
      expect((teamC['team_players'] as List).single['id'], 'u1');
    });
  });

  test('auction completion refuses one profile in two teams', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('u1').set({
      'id': 'u1',
      'name': 'Kumar',
      'created_by': 'org',
    });
    final auction = Auction(
      id: 'AuctionId0000000002',
      name: 'GCPL Auction',
      tournamentName: 'GCPL',
      createdBy: 'admin',
      createdAt: DateTime(2026, 11, 10),
      teamBudget: 100,
      basePrice: 20,
      bidIncrement: 10,
      teams: [
        AuctionTeam(id: 'A', name: 'Team A', budget: 100),
        AuctionTeam(id: 'B', name: 'Team B', budget: 100),
      ],
    )
        .upsertPlayers([
          const AuctionPlayer(
              id: 'p1', name: 'Kumar', basePrice: 20, userId: 'u1'),
          const AuctionPlayer(id: 'p2', name: 'Ravi', basePrice: 20),
          const AuctionPlayer(id: 'p3', name: 'Unsold', basePrice: 20),
        ])
        .$1
        .retain('p1', 'A', 20)
        .retain('p2', 'B', 20)
        .start();
    final json = auction.toJson();
    final players = (json['players'] as List).cast<Map<String, dynamic>>();
    players.firstWhere((p) => p['id'] == 'p2')['user_id'] = 'u1';
    await db.collection('auctions').doc(auction.id).set(json);

    await expectLater(
      AuctionService(db).completeAndGenerateTournament(
        auction.id,
        'admin',
        markRemainingUnsold: true,
      ),
      throwsA(
        isA<AuctionActionException>()
            .having((e) => e.error, 'error', AuctionError.duplicatePlayer),
      ),
    );
    expect((await db.collection('tournaments').get()).docs, isEmpty);
  });
}
