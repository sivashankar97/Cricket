import 'package:data/errors/app_error.dart';
import 'package:data/service/user/player_link_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/domain/phone/phone_number.dart';

void main() {
  group('local numbers without a country code', () {
    final lk = PhoneCountry.all.firstWhere((c) => c.code == 'LK');

    test('a Sri Lankan number works with an Indian default', () {
      expect(
          PhoneNumber.toE164('0771234567', PhoneCountry.india), '+94771234567');
      expect(PhoneNumber.toE164('077 123 4567', lk), '+94771234567');
    });

    test('an Indian number works with a Sri Lankan default', () {
      expect(PhoneNumber.toE164('09876543210', lk), '+919876543210');
      expect(PhoneNumber.toE164('98765 43210', PhoneCountry.india),
          '+919876543210');
    });

    test('the default country wins when the number fits it', () {
      final sg = PhoneCountry.all.firstWhere((c) => c.code == 'SG');
      expect(PhoneNumber.toE164('81234567', sg), '+6581234567');
    });

    test('numbers that fit no country are refused', () {
      expect(PhoneNumber.toE164('0123456', PhoneCountry.india), isNull);
      expect(PhoneNumber.toE164('0571234567', PhoneCountry.india), isNull);
    });
  });

  group('one record per number', () {
    late FakeFirebaseFirestore db;
    late PlayerLinkService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = PlayerLinkService(db);
    });

    test('the same number never creates a second player', () async {
      final first = await service.createPlayerWithPhone(
        name: 'Shankaran',
        e164: '+94771234567',
        organizerId: 'auction_admin',
      );
      final again = await service.createPlayerWithPhone(
        name: 'Shankar',
        e164: '+94771234567',
        organizerId: 'other_organizer',
      );
      expect(again.existing, isTrue);
      expect(again.user.id, first.user.id);
      expect(again.user.name, 'Shankaran');
      expect((await db.collection('users').get()).docs, hasLength(1));
    });

    test('merging a duplicate moves its stats and frees its number', () async {
      final central = await service.createPlayerWithPhone(
        name: 'Shankaran',
        e164: '+94771234567',
        organizerId: 'auction_admin',
      );
      final old = await service.createPlayerWithPhone(
        name: 'Shankar',
        e164: '+94770000000',
        organizerId: 'org',
      );
      final oldId = old.user.id;
      await db
          .collection('users')
          .doc(oldId)
          .collection('user_stat')
          .doc('test')
          .set({'type': 'test', 'matches': 3});

      await expectLater(
        service.mergeDuplicateInto(
          duplicateId: oldId,
          playerId: central.user.id,
          organizerId: 'someone_else',
        ),
        throwsA(isA<AppError>()),
      );

      await service.mergeDuplicateInto(
        duplicateId: oldId,
        playerId: central.user.id,
        organizerId: 'org',
      );
      expect((await db.collection('users').doc(oldId).get()).exists, isFalse);
      final moved = await db
          .collection('users')
          .doc(central.user.id)
          .collection('user_stat')
          .doc('test')
          .get();
      expect(moved.exists, isTrue);

      expect(await service.playerIdForPhone('+94770000000'), isNull);
      final reused = await service.createPlayerWithPhone(
        name: 'New',
        e164: '+94770000000',
        organizerId: 'org',
      );
      expect(reused.existing, isFalse);
      expect(await service.playerIdForPhone('+94770000000'), reused.user.id);
    });
  });
}
