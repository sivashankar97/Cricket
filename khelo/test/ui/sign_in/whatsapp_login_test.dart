import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/ui/flow/sign_in/whatsapp_login.dart';

void main() {
  test('reads the code from a full login link', () {
    expect(
      whatsAppCodeFromInput(
        'https://sportstamil.network/#/whatsapp-login?code=Ab_c-12',
      ),
      'Ab_c-12',
    );
  });

  test('reads the code when other parameters come first', () {
    expect(
      whatsAppCodeFromInput('https://x.app/#/whatsapp-login?a=1&code=XyZ9'),
      'XyZ9',
    );
  });

  test('accepts a bare code', () {
    expect(whatsAppCodeFromInput('  XyZ9  '), 'XyZ9');
  });
}
