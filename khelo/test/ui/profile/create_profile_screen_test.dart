import 'package:data/api/user/user_models.dart';
import 'package:data/service/auth/auth_service.dart';
import 'package:data/service/file_upload/file_upload_service.dart';
import 'package:data/service/match/match_service.dart';
import 'package:data/service/team/team_service.dart';
import 'package:data/service/tournament/tournament_service.dart';
import 'package:data/service/user/user_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:data/storage/provider/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:khelo/ui/flow/settings/edit_profile/edit_profile_screen.dart';
import 'package:khelo/ui/flow/settings/edit_profile/edit_profile_view_model.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/theme.dart';

class _Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Upload extends _Fake implements FileUploadService {}

class _Users extends _Fake implements UserService {
  @override
  Stream<String?> streamPrivatePhone(String userId) => Stream.value(null);
}

class _Auth extends _Fake implements AuthService {}

class _Teams extends _Fake implements TeamService {}

class _Matches extends _Fake implements MatchService {}

class _Tournaments extends _Fake implements TournamentService {}

void main() {
  const user = UserModel(id: 'u1', email: 'player@example.com');

  Widget app() => ProviderScope(
        overrides: [
          currentUserPod.overrideWithValue(user),
          mascotProvider.overrideWith((ref) => MascotController(() => false)),
          editProfileStateProvider
              .overrideWith((ref) => EditProfileViewNotifier(
                    _Upload(),
                    _Users(),
                    _Auth(),
                    _Teams(),
                    _Matches(),
                    _Tournaments(),
                    user,
                    PreferenceNotifier<String?>(null, null),
                  )),
        ],
        child: AppTheme(
          colorScheme: appColorSchemeLight,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const EditProfileScreen(isToCreateAccount: true),
          ),
        ),
      );

  for (final size in const [Size(390, 844), Size(320, 568), Size(1280, 800)]) {
    testWidgets(
        'create profile fits ${size.width.toInt()} px and flags empty name and mobile',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Create profile'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Enter your name (at least 2 letters)'), findsOneWidget);
      expect(find.text('Enter your mobile number'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
