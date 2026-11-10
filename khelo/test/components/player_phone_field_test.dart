import 'package:data/service/user/player_link_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/components/player_phone_field.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:khelo/ui/flow/settings/edit_profile/profile_completion.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/theme.dart';

void main() {
  late FakeFirebaseFirestore db;
  late TextEditingController controller;
  late List<PlayerPhoneMatch> matches;

  setUp(() async {
    db = FakeFirebaseFirestore();
    controller = TextEditingController();
    matches = [];
    await PlayerLinkService(db).createPlayerWithPhone(
      name: 'Kumar',
      e164: '+919876543210',
      organizerId: 'org',
    );
  });

  Widget app({String? selfId}) => ProviderScope(
        overrides: [
          playerLinkServiceProvider.overrideWithValue(PlayerLinkService(db)),
          currentUserPhoneProvider
              .overrideWith((ref) => Stream.value('+919000000000')),
        ],
        child: AppTheme(
          colorScheme: appColorSchemeLight,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: PlayerPhoneField(
                  controller: controller,
                  selfId: selfId,
                  onChanged: matches.add,
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
  }

  testWidgets('a known number finds that player', (tester) async {
    await tester.pumpWidget(app());
    await type(tester, '98765 43210');
    expect(find.text('Linked to Kumar'), findsOneWidget);
    expect(matches.last.player?.name, 'Kumar');
    expect(matches.last.e164, '+919876543210');
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown number is a new player', (tester) async {
    await tester.pumpWidget(app());
    await type(tester, '9123456789');
    expect(find.textContaining('New player'), findsOneWidget);
    expect(matches.last.isNew, isTrue);
  });

  testWidgets('a partial number asks for the full one', (tester) async {
    await tester.pumpWidget(app());
    await type(tester, '98765');
    expect(find.text('Enter the full mobile number'), findsOneWidget);
    expect(matches.where((m) => m.e164 != null), isEmpty);
  });

  testWidgets('the player being edited is not "someone else"', (tester) async {
    final id = await PlayerLinkService(db).playerIdForPhone('+919876543210');
    await tester.pumpWidget(app(selfId: id));
    await type(tester, '9876543210');
    expect(find.text('This number is linked to this player'), findsOneWidget);
  });
}
