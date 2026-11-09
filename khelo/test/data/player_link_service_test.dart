import 'package:data/api/user/player_claim.dart';
import 'package:data/api/user/user_models.dart';
import 'package:data/service/user/player_link_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/ui/flow/team/add_team_member/add_team_member_view_model.dart';

const _number = '+94771234567';

void main() {
  late FakeFirebaseFirestore db;
  late PlayerLinkService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = PlayerLinkService(db);
  });

  group('phoneKey', () {
    test('ignores formatting and never contains the number', () {
      final key = PlayerLinkService.phoneKey(_number);
      expect(PlayerLinkService.phoneKey('+94 77-123 4567'), key);
      expect(key, isNot(contains('771234567')));
      expect(PlayerLinkService.phoneKey('+94771234568'), isNot(key));
    });
  });

  group('createPlayerWithPhone', () {
    test('creates a player and finds it again by number', () async {
      final created = await service.createPlayerWithPhone(
        name: ' Kumar ',
        e164: _number,
        organizerId: 'organizer',
      );
      expect(created.existing, isFalse);
      expect(created.user.name, 'Kumar');

      final user = await db.collection('users').doc(created.user.id).get();
      expect(user.data()!['created_by'], 'organizer');
      expect(user.data()!['phone'], isNull);

      final again = await service.createPlayerWithPhone(
        name: 'Someone else',
        e164: _number,
        organizerId: 'other',
      );
      expect(again.existing, isTrue);
      expect(again.user.id, created.user.id);
    });
  });

  group('registerOwnPhone', () {
    test('keeps a number already held by an added player', () async {
      final added = await service.createPlayerWithPhone(
        name: 'Kumar',
        e164: _number,
        organizerId: 'organizer',
      );
      await service.registerOwnPhone(userId: 'me', e164: _number);
      expect(await service.playerIdForPhone(_number), added.user.id);
    });

    test('moves own number when it changes', () async {
      await service.registerOwnPhone(userId: 'me', e164: _number);
      await service.registerOwnPhone(
        userId: 'me',
        e164: '+94770000000',
        previousE164: _number,
      );
      expect(await service.playerIdForPhone(_number), isNull);
      expect(await service.playerIdForPhone('+94770000000'), 'me');
    });
  });

  group('claim and merge', () {
    late String playerId;
    const me = UserModel(id: 'me', name: 'Kumar Real');

    setUp(() async {
      playerId = (await service.createPlayerWithPhone(
        name: 'Kumar',
        e164: _number,
        organizerId: 'organizer',
      ))
          .user
          .id;
      await db.collection('users').doc('me').set({'id': 'me', 'name': 'Me'});
      await db.collection('teams').doc('t1').set({
        'id': 't1',
        'team_players': [
          {'id': playerId, 'role': 'player'},
          {'id': 'organizer', 'role': 'admin'},
        ],
      });
      await db.collection('matches').doc('m1').set({
        'id': 'm1',
        'players': [playerId, 'organizer'],
        'tournament_id': 'tour1',
        'teams': [
          {
            'team_id': 't1',
            'squad': [
              {'id': playerId, 'status': 'played'},
            ],
          },
        ],
      });
      await db.collection('ball_scores').doc('b1').set({
        'match_id': 'm1',
        'batting_team_id': 't1',
        'player_out_id': playerId,
        'runs_scored': 4,
      });
      await db.collection('tournaments').doc('tour1').set({
        'id': 'tour1',
        'team_ids': ['t1'],
        'members': [
          {'id': 'organizer', 'role': 'organizer'},
        ],
      });
      await db
          .collection('tournaments')
          .doc('tour1')
          .collection('player_key_stats')
          .doc(playerId)
          .set({'player_id': playerId, 'runs': 30});
      await db
          .collection('leaderboard')
          .doc('all_time')
          .collection('data')
          .doc(playerId)
          .set({'user_id': playerId, 'runs': 30});
      await db
          .collection('leaderboard')
          .doc('all_time')
          .collection('data')
          .doc('me')
          .set({'user_id': 'me', 'runs': 12});
      await db
          .collection('users')
          .doc(playerId)
          .collection('user_stat')
          .doc('test')
          .set(const UserStat(matches: 3).toJson());
    });

    test('finds the claimable player with counts', () async {
      final claimable =
          await service.findClaimable(userId: 'me', e164: _number);
      expect(claimable, isNotNull);
      expect(claimable!.playerName, 'Kumar');
      expect(claimable.organizerId, 'organizer');
      // The fake matches `team_players` maps by identity, so team counts
      // only work against real Firestore.
      expect(claimable.matches, 1);
    });

    test('"Not me" hides the prompt and sends no request', () async {
      final claimable =
          await service.findClaimable(userId: 'me', e164: _number);
      await service.answerClaim(
        player: claimable!,
        claimant: me,
        e164: _number,
        isMe: false,
      );
      expect(await service.findClaimable(userId: 'me', e164: _number), isNull);
      final requests =
          await service.streamRequestsForOrganizer('organizer').first;
      expect(requests, isEmpty);
    });

    test('approving moves everything to the real account', () async {
      final claimable =
          await service.findClaimable(userId: 'me', e164: _number);
      await service.answerClaim(
        player: claimable!,
        claimant: me,
        e164: _number,
        isMe: true,
      );
      final requests =
          await service.streamRequestsForOrganizer('organizer').first;
      expect(requests.single.claimantId, 'me');

      await service.approveClaim(requests.single);

      final match = (await db.collection('matches').doc('m1').get()).data()!;
      expect(match['players'], ['me', 'organizer']);
      expect(match['teams'][0]['squad'][0]['id'], 'me');

      final ball = (await db.collection('ball_scores').doc('b1').get()).data()!;
      expect(ball['player_out_id'], 'me');
      expect(ball['runs_scored'], 4);

      final keyStats = db
          .collection('tournaments')
          .doc('tour1')
          .collection('player_key_stats');
      expect((await keyStats.doc(playerId).get()).exists, isFalse);
      expect((await keyStats.doc('me').get()).data()!['player_id'], 'me');

      final board =
          db.collection('leaderboard').doc('all_time').collection('data');
      expect((await board.doc(playerId).get()).exists, isFalse);
      expect((await board.doc('me').get()).data()!['runs'], 42);

      final stat = await db
          .collection('users')
          .doc('me')
          .collection('user_stat')
          .doc('test')
          .get();
      expect(stat.data()!['matches'], 3);

      expect((await db.collection('users').doc(playerId).get()).exists, false);
      expect(await service.playerIdForPhone(_number), 'me');

      final claim = await db
          .collection('player_claims')
          .doc(PlayerClaim.idFor(playerId, 'me'))
          .get();
      expect(claim.data()!['status'], 'approved');

      await expectLater(
        service.approveClaim(requests.single),
        throwsA(anything),
      );
    });
  });

  group('AddTeamMemberViewNotifier phone input', () {
    test('looksLikePhone', () {
      expect(AddTeamMemberViewNotifier.looksLikePhone('077 123 4567'), isTrue);
      expect(AddTeamMemberViewNotifier.looksLikePhone('+94771234567'), isTrue);
      expect(AddTeamMemberViewNotifier.looksLikePhone('Kumar'), isFalse);
      expect(AddTeamMemberViewNotifier.looksLikePhone('12345'), isFalse);
    });
  });
}
