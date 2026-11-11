/// Country codes offered on Create Profile, with the length of a local
/// mobile number (without the leading 0).
class PhoneCountry {
  final String code;
  final String name;
  final String flag;
  final String dial;
  final int minDigits;
  final int maxDigits;

  /// First digit of a mobile number, when the country has a fixed one.
  final String? mobileStart;

  const PhoneCountry({
    required this.code,
    required this.name,
    required this.flag,
    required this.dial,
    required this.minDigits,
    required this.maxDigits,
    this.mobileStart,
  });

  static const india = PhoneCountry(
    code: 'IN',
    name: 'India',
    flag: '🇮🇳',
    dial: '+91',
    minDigits: 10,
    maxDigits: 10,
    mobileStart: '6789',
  );

  static const all = [
    india,
    PhoneCountry(
      code: 'LK',
      name: 'Sri Lanka',
      flag: '🇱🇰',
      dial: '+94',
      minDigits: 9,
      maxDigits: 9,
      mobileStart: '7',
    ),
    PhoneCountry(
        code: 'SG',
        name: 'Singapore',
        flag: '🇸🇬',
        dial: '+65',
        minDigits: 8,
        maxDigits: 8),
    PhoneCountry(
        code: 'MY',
        name: 'Malaysia',
        flag: '🇲🇾',
        dial: '+60',
        minDigits: 9,
        maxDigits: 10),
    PhoneCountry(
        code: 'AE',
        name: 'UAE',
        flag: '🇦🇪',
        dial: '+971',
        minDigits: 9,
        maxDigits: 9),
    PhoneCountry(
        code: 'SA',
        name: 'Saudi Arabia',
        flag: '🇸🇦',
        dial: '+966',
        minDigits: 9,
        maxDigits: 9),
    PhoneCountry(
        code: 'QA',
        name: 'Qatar',
        flag: '🇶🇦',
        dial: '+974',
        minDigits: 8,
        maxDigits: 8),
    PhoneCountry(
        code: 'GB',
        name: 'United Kingdom',
        flag: '🇬🇧',
        dial: '+44',
        minDigits: 10,
        maxDigits: 10),
    PhoneCountry(
        code: 'US',
        name: 'USA / Canada',
        flag: '🇺🇸',
        dial: '+1',
        minDigits: 10,
        maxDigits: 10),
    PhoneCountry(
        code: 'AU',
        name: 'Australia',
        flag: '🇦🇺',
        dial: '+61',
        minDigits: 9,
        maxDigits: 9),
  ];
}

enum PhoneError { empty, invalid }

class PhoneNumber {
  final PhoneCountry country;

  /// Local digits only, no leading 0.
  final String digits;

  const PhoneNumber(this.country, this.digits);

  /// Stored form, e.g. `+919876543210`.
  String get e164 => '${country.dial}$digits';

  /// Digits the player typed, without spaces, dashes, the country code or a
  /// leading 0.
  static String clean(PhoneCountry country, String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    final dial = country.dial.substring(1);
    if (input.trim().startsWith('+') && digits.startsWith(dial)) {
      digits = digits.substring(dial.length);
    } else if (digits.length > country.maxDigits && digits.startsWith(dial)) {
      digits = digits.substring(dial.length);
    }
    return digits.replaceFirst(RegExp(r'^0+'), '');
  }

  static PhoneError? validate(PhoneCountry country, String input) {
    final digits = clean(country, input);
    if (digits.isEmpty) return PhoneError.empty;
    if (digits.length < country.minDigits ||
        digits.length > country.maxDigits) {
      return PhoneError.invalid;
    }
    final start = country.mobileStart;
    if (start != null && !start.contains(digits[0])) return PhoneError.invalid;
    return null;
  }

  /// Countries a number without `+` can belong to when it doesn't fit the
  /// default one. Their mobile prefixes don't overlap, so at most one fits.
  static const _localFallbacks = ['IN', 'LK'];

  /// Full number with country code for what someone typed, or null when it
  /// isn't a valid mobile. Numbers without `+` use [defaultCountry], or India /
  /// Sri Lanka when only one of them fits (e.g. `0771234567` → `+94771234567`).
  static String? toE164(String input, PhoneCountry defaultCountry) {
    final trimmed = input.trim();
    if (trimmed.startsWith('+')) {
      final country = parse(trimmed)?.country ?? defaultCountry;
      if (validate(country, trimmed) != null) return null;
      return PhoneNumber(country, clean(country, trimmed)).e164;
    }
    if (validate(defaultCountry, trimmed) == null) {
      return PhoneNumber(defaultCountry, clean(defaultCountry, trimmed)).e164;
    }
    final fits = PhoneCountry.all
        .where((c) =>
            _localFallbacks.contains(c.code) &&
            c.code != defaultCountry.code &&
            validate(c, trimmed) == null)
        .toList();
    if (fits.length != 1) return null;
    return PhoneNumber(fits.single, clean(fits.single, trimmed)).e164;
  }

  /// Reads a stored number (`+919876543210`, `+91 98765 43210`). Unknown
  /// country codes fall back to India with the digits as typed.
  static PhoneNumber? parse(String? stored) {
    if (stored == null) return null;
    final compact = stored.replaceAll(RegExp(r'[^\d+]'), '');
    if (compact.isEmpty) return null;
    final byLongestDial = [...PhoneCountry.all]
      ..sort((a, b) => b.dial.length.compareTo(a.dial.length));
    for (final country in byLongestDial) {
      if (compact.startsWith(country.dial)) {
        return PhoneNumber(country, compact.substring(country.dial.length));
      }
    }
    return PhoneNumber(
      PhoneCountry.india,
      compact.replaceAll('+', '').replaceFirst(RegExp(r'^0+'), ''),
    );
  }
}
