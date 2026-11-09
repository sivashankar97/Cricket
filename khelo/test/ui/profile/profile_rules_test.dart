import 'package:data/api/user/user_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/domain/phone/phone_number.dart';
import 'package:khelo/ui/flow/settings/edit_profile/profile_completion.dart';

void main() {
  const india = PhoneCountry.india;
  final sriLanka = PhoneCountry.all.firstWhere((c) => c.code == 'LK');
  final uae = PhoneCountry.all.firstWhere((c) => c.code == 'AE');

  group('PhoneNumber.clean', () {
    test('strips spaces, dashes, country code and leading zero', () {
      expect(PhoneNumber.clean(india, '98765 43210'), '9876543210');
      expect(PhoneNumber.clean(india, '+91 98765-43210'), '9876543210');
      expect(PhoneNumber.clean(india, '919876543210'), '9876543210');
      expect(PhoneNumber.clean(india, '09876543210'), '9876543210');
      expect(PhoneNumber.clean(sriLanka, '077 123 4567'), '771234567');
    });
  });

  group('PhoneNumber.validate', () {
    test('empty and wrong numbers are rejected', () {
      expect(PhoneNumber.validate(india, '  '), PhoneError.empty);
      expect(PhoneNumber.validate(india, '98765'), PhoneError.invalid);
      expect(PhoneNumber.validate(india, '5876543210'), PhoneError.invalid);
      expect(PhoneNumber.validate(sriLanka, '612345678'), PhoneError.invalid);
    });

    test('valid mobiles pass', () {
      expect(PhoneNumber.validate(india, '98765 43210'), isNull);
      expect(PhoneNumber.validate(sriLanka, '0771234567'), isNull);
      expect(PhoneNumber.validate(uae, '501234567'), isNull);
    });
  });

  group('PhoneNumber.parse', () {
    test('finds the country from the stored number', () {
      final lk = PhoneNumber.parse('+94771234567')!;
      expect(lk.country.code, 'LK');
      expect(lk.digits, '771234567');

      final ae = PhoneNumber.parse('+971 50 123 4567')!;
      expect(ae.country.code, 'AE');
      expect(ae.e164, '+971501234567');
    });

    test('falls back to India and handles empty values', () {
      expect(PhoneNumber.parse(null), isNull);
      expect(PhoneNumber.parse(''), isNull);
      final local = PhoneNumber.parse('09876543210')!;
      expect(local.country.code, 'IN');
      expect(local.digits, '9876543210');
    });
  });

  group('isProfileComplete', () {
    test('needs a name and a mobile number', () {
      expect(isProfileComplete(const UserModel(id: 'u'), null), isFalse);
      expect(
        isProfileComplete(const UserModel(id: 'u', name: 'Anu'), null),
        isFalse,
      );
      expect(isProfileComplete(const UserModel(id: 'u', name: 'A'), '+91'),
          isFalse);
      expect(
        isProfileComplete(
            const UserModel(id: 'u', name: 'Anu'), '+919876543210'),
        isTrue,
      );
    });

    test('accepts the public number of phone sign-in accounts', () {
      expect(
        isProfileComplete(
          const UserModel(id: 'u', name: 'Anu', phone: '+919876543210'),
          null,
        ),
        isTrue,
      );
    });
  });
}
