import 'package:data/service/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:khelo/ui/flow/sign_in/sign_in_screen.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/theme.dart';

Widget signInApp({String? guestId}) => ProviderScope(
      overrides: [
        mascotProvider.overrideWith((ref) => MascotController(() => false)),
        guestUserIdProvider.overrideWith((ref) => Stream.value(guestId)),
      ],
      child: AppTheme(
        colorScheme: appColorSchemeLight,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: [Locale('en')],
          home: SignInScreen(),
        ),
      ),
    );

PrimaryButton _submitButton(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.byType(PrimaryButton));

Future<void> _type(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Column)),
    matching: find.byType(TextField),
  );
  await tester.enterText(field.first, text);
  await tester.pump();
}

void main() {
  testWidgets('shows only email sign in, no WhatsApp', (tester) async {
    await tester.pumpWidget(signInApp());
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.textContaining('WhatsApp'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('sign in button turns on only for a valid email and password',
      (tester) async {
    await tester.pumpWidget(signInApp());
    await tester.pump();
    expect(_submitButton(tester).enabled, isFalse);

    await _type(tester, 'Email', 'player@example');
    await _type(tester, 'Password', 'secret1');
    expect(_submitButton(tester).enabled, isFalse);

    await _type(tester, 'Email', 'player@example.com');
    expect(_submitButton(tester).enabled, isTrue);

    await _type(tester, 'Password', '12345');
    expect(_submitButton(tester).enabled, isFalse);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('create account mode shows the password rule', (tester) async {
    await tester.pumpWidget(signInApp());
    await tester.pump();

    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
    expect(find.text('Forgot password?'), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);

    await _type(tester, 'Password', 'secret1');
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('offers guest play to new visitors', (tester) async {
    await tester.pumpWidget(signInApp());
    await tester.pump();
    expect(find.text('Continue as guest'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('hides guest play for an existing guest', (tester) async {
    await tester.pumpWidget(signInApp(guestId: 'guest-uid'));
    await tester.pump();
    expect(find.text('Continue as guest'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });
}
