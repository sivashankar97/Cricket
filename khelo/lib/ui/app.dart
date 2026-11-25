import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khelo/components/mascot/mascot_overlay.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/platform.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/theme.dart';

import 'app_route.dart';

/// `app_ta.arb` only holds the mascot's lines (see `mascotText`), so the app
/// itself stays English.
const _appLocales = [Locale('en')];

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late GoRouter _router;
  final _authRefresh = ValueNotifier<int>(0);

  /// Deep-linkable routes that need a real (non-guest) session.
  /// Firestore rules remain the real ACL; this is UX / deep-link hygiene.
  static const _authRequiredPrefixes = [
    AppRoute.pathScoreBoard,
    AppRoute.pathAddMatch,
    AppRoute.pathAddMatchOfficials,
    AppRoute.pathMakeTeamAdmin,
    AppRoute.pathAuctionForm,
    AppRoute.pathAuctionPlayers,
    AppRoute.pathAuctionRetained,
    AppRoute.pathEditProfile,
  ];

  @override
  void initState() {
    super.initState();

    final AppRoute initialRoute;
    if (ref.read(hasUserSession)) {
      final currentUser = ref.read(currentUserPod);
      if (currentUser?.name == null || currentUser!.name!.isEmpty) {
        initialRoute = AppRoute.editProfile(isToCreateAccount: true);
      } else {
        initialRoute = AppRoute.main;
      }
    } else {
      initialRoute = AppRoute.main;
    }

    _router = GoRouter(
      initialLocation: initialRoute.path,
      refreshListenable: _authRefresh,
      redirect: (context, state) {
        final loggedIn = ref.read(hasUserSession);
        final loc = state.matchedLocation;
        final needsAuth =
            _authRequiredPrefixes.any((p) => loc == p || loc.startsWith('$p/'));
        if (!loggedIn && needsAuth) {
          return AppRoute.signIn.path;
        }
        return null;
      },
      routes: AppRoute.routes,
    );
  }

  @override
  void dispose() {
    _authRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserPod, (_, __) {
      _authRefresh.value++;
    });
    final isDarkMode = context.brightness == Brightness.dark;
    final colorScheme = isDarkMode ? appColorSchemeDark : appColorSchemeLight;

    return AppTheme(
      colorScheme: colorScheme,
      child: Builder(
        builder: (context) {
          if (isIOS) {
            return CupertinoApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: _router,
              builder: (context, child) => MascotOverlay(child: child!),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: _appLocales,
              theme: CupertinoThemeData(
                brightness: context.brightness,
                primaryColor: colorScheme.primary,
                primaryContrastingColor: colorScheme.onPrimary,
                barBackgroundColor:
                    colorScheme.groupedBackground.withValues(alpha: 0.95),
                // Grouped screen background
                scaffoldBackgroundColor: colorScheme.groupedBackground,
                applyThemeToAll: true,
                textTheme: CupertinoTextThemeData(
                  // Nav bar title — matches our navTitle style
                  navTitleTextStyle: TextStyle(
                    fontFamily: 'Poppins',
                    package: 'style',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.41,
                    color: colorScheme.textPrimary,
                  ),
                  // Large nav title for expanded nav bars
                  navLargeTitleTextStyle: TextStyle(
                    fontFamily: 'Poppins',
                    package: 'style',
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.37,
                    color: colorScheme.textPrimary,
                  ),
                  primaryColor: colorScheme.primary,
                ),
              ),
            );
          } else {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: _router,
              builder: (context, child) => MascotOverlay(child: child!),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: _appLocales,
              theme: materialThemeDataLight,
              darkTheme: materialThemeDataDark,
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            );
          }
        },
      ),
    );
  }
}
