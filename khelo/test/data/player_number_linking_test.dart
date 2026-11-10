import 'package:data/api/auction/auction_models.dart';
import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/errors/app_error.dart';
import 'package:data/service/auction/auction_service.dart';
import 'package:data/service/tournament_team/tournament_team_service.dart';
import 'package:data/service/user/player_link_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/domain/phone/phone_number.dart';

void main() {
  group('PhoneNumber.toE164', () {
    test('uses the default country without a +', () {
      expect(PhoneNumber.toE164('98765 43210', PhoneCountry.india),
          '+919876543210');
      final lk = PhoneCountry.all.firstWhere((c) => c.dial == '+94');
      expect(PhoneNumber.toE164('077 123 4567', lk), '+94771234567');
    });

    test('reads the country from a + code', () {
      expect(PhoneNumber.toE164('+94 77 123 4567', PhoneCountry.india),
          '+94771234567');
    });

    test('rejects partial or non-mobile numbers', () {
      expect(PhoneNumber.toE164('98765', PhoneCountry.india), isNull);
      expect(PhoneNumber.toE164('1234567890', PhoneCountry.india), isNull);
      expect(PhoneNumber.toE164('', PhoneCountry.india), isNull);
    });
  });

  group('AuctionPlayer link', () {
    test('keeps the linked profile id, never a number', () {
      const player =
          AuctionPlayer(id: 'p1', name: 'Arun', basePrice: 20, userId: 'u1');
      final json = player.toJson();
      expect(json['user_id'], 'u1');
      expect(json.values, isNot(contains(startsWith('+'))));
      expect(AuctionPlayer.fromJson(json).userId, 'u1');
      expect(player.copyWith(userId: null).userId, isNull);
    });

    test('the same profile twice is a duplicate', () {
      final auction = _auction([
        const AuctionPlayer(
            id: 'p1', name: 'Arun', basePrice: 20, userId: 'u1'),
      ]);
      const again =
          AuctionPlayer(id: 'p2', name: 'Arun K', basePrice: 20, userId: 'u1');
      expect(auction.duplicateOf(again)?.id, 'p1');
    });
  });

  group('auction completion', () {
    test('linked players join under their own profile', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('u_added').set({
        'id': 'u_added',
        'name': 'Kumar',
        'created_by': 'someone',
      });
      await db.collection('users').doc('u_account').set({
        'id': 'u_account',
        'name': 'Ravi',
      });
      final auction = _auction([
        const AuctionPlayer(id: 'p1', name: 'Plain', basePrice: 20),
        const AuctionPlayer(
          id: 'p2',
          name: 'Kumar S',
          basePrice: 20,
          number: 7,
          userId: 'u_added',
        ),
        const AuctionPlayer(
          id: 'p3',
          name: 'Ravi',
          basePrice: 20,
          number: 9,
          userId: 'u_account',
        ),
        const AuctionPlayer(
          id: 'p4',
          name: 'Gone',
          basePrice: 20,
          userId: 'u_deleted',
        ),
        const AuctionPlayer(id: 'p5', name: 'Unsold', basePrice: 20),
      ])
          .retain('p1', 'A', 20)
          .retain('p2', 'A', 20)
          .retain('p3', 'B', 20)
          .retain('p4', 'B', 20)
          .start();
      await db
          .collection('auctions')
          .doc('AuctionId0000000001')
          .set(auction.toJson());

      await AuctionService(db).completeAndGenerateTournament(
        'AuctionId0000000001',
        'admin',
        markRemainingUnsold: true,
      );

      final teamA = (await db
              .collection('teams')
              .doc('auction_AuctionId0000000001_A')
              .get())
          .data()!['team_players'] as List;
      final teamB = (await db
              .collection('teams')
              .doc('auction_AuctionId0000000001_B')
              .get())
          .data()!['team_players'] as List;
      expect(teamA.map((p) => p['id']),
          ['auction_AuctionId0000000001_p1', 'u_added']);
      expect(teamB.map((p) => p['id']),
          ['u_account', 'auction_AuctionId0000000001_p4']);

      final added = (await db.collection('users').doc('u_added').get()).data()!;
      expect(added['name'], 'Kumar');
      expect(added['jersey_number'], 7);
      expect(added['created_by'], 'someone');

      final account =
          (await db.collection('users').doc('u_account').get()).data()!;
      expect(account, {'id': 'u_account', 'name': 'Ravi'});

      expect(
        (await db
                .collection('users')
                .doc('auction_AuctionId0000000001_p2')
                .get())
            .exists,
        isFalse,
      );
      expect(
        (await db
                .collection('users')
                .doc('auction_AuctionId0000000001_p4')
                .get())
            .exists,
        isTrue,
      );
    });
  });

  group('tournament pool players', () {
    late FakeFirebaseFirestore db;
    late TournamentTeamService service;

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = TournamentTeamService(db);
      await db.collection('teams').doc('t1').set({
        'id': 't1',
        'team_players': <Map<String, dynamic>>[],
      });
    });

    test('a new player with a number owns that number', () async {
      final created = await service.addPlayer(
        player: const TournamentTeamPlayer(id: '', teamId: 't1', name: 'Siva'),
        existing: const [],
        createdBy: 'org',
        e164: '+919876543210',
      );
      final index = await db
          .collection('phone_index')
          .doc(PlayerLinkService.phoneKey('+919876543210'))
          .get();
      expect(index.data()!['user_id'], created.id);
      expect(index.data()!['created_by'], 'org');
    });

    test('an existing player is added without changing their profile',
        () async {
      await service.addExistingPlayer(
        teamId: 't1',
        userId: 'u1',
        name: 'Kumar',
        existing: const [],
      );
      final team = (await db.collection('teams').doc('t1').get()).data()!;
      expect((team['team_players'] as List).single['id'], 'u1');
      expect((await db.collection('users').doc('u1').get()).exists, isFalse);

      await expectLater(
        service.addExistingPlayer(
          teamId: 't1',
          userId: 'u1',
          name: 'Kumar',
          existing: const [
            TournamentTeamPlayer(id: 'u1', teamId: 't1', name: 'Kumar'),
          ],
        ),
        throwsA(isA<AppError>()),
      );
    });
  });
}

Auction _auction(List<AuctionPlayer> players) => Auction(
      id: 'AuctionId0000000001',
      name: 'GCPL Auction',
      tournamentName: 'GCPL',
      createdBy: 'admin',
      createdAt: DateTime(2026, 11, 6),
      teamBudget: 100,
      basePrice: 20,
      bidIncrement: 10,
      teams: [
        AuctionTeam(id: 'A', name: 'Team A', budget: 100),
        AuctionTeam(id: 'B', name: 'Team B', budget: 100),
      ],
    ).upsertPlayers(players).$1;
