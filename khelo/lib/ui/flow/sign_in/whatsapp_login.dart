import 'package:data/service/auth/auth_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/ui/app_route.dart';

/// WhatsApp number users send "Hi login" to (digits only, with country code).
/// Override at build time: `WHATSAPP_LOGIN_NUMBER=...` in `dart_defines.env`.
const String kWhatsAppLoginNumber = String.fromEnvironment(
  'WHATSAPP_LOGIN_NUMBER',
  defaultValue: '94776887978',
);
const String kWhatsAppDisplayNumber = '+$kWhatsAppLoginNumber';
const String kWhatsAppPrefillMessage = 'Hi login';

/// Base URL of the login service in `khelo/whatsapp_login` (served on the VPS).
const String kWhatsAppLoginApi = String.fromEnvironment(
  'WHATSAPP_LOGIN_API',
  defaultValue: 'https://sportstamil.network/wa',
);

/// Pulls the one-time code out of a pasted login link, or returns the input
/// as-is when only the code was pasted.
String whatsAppCodeFromInput(String input) {
  final trimmed = input.trim();
  final match = RegExp(r'[?&]code=([A-Za-z0-9_-]+)').firstMatch(trimmed);
  return match?.group(1) ?? trimmed;
}

Future<void> signInWithWhatsAppCode(
  BuildContext context,
  WidgetRef ref,
  String code,
) async {
  await ref
      .read(authServiceProvider)
      .signInWithWhatsAppCode(code, apiBaseUrl: kWhatsAppLoginApi);
  if (!context.mounted) return;
  final name = ref.read(currentUserPod)?.name;
  if (name == null || name.trim().isEmpty) {
    AppRoute.editProfile(isToCreateAccount: true).go(context);
  } else {
    AppRoute.main.go(context);
  }
}
