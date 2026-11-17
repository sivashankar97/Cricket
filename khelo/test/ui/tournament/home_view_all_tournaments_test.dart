import 'package:data/api/match/match_model.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:data/service/match/match_service.dart';
import 'package:data/service/tournament/tournament_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:khelo/ui/flow/home/view_all/home_view_all_screen.dart';
import 'package:khelo/ui/flow/home/view_all/home_view_all_view_model.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/theme.dart';

class _Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Matches extends _Fake implements MatchService {
  @override
  Future<List<MatchModel>> getMatchesByStatus({
    required List<MatchStatus> status,
    String? lastMatchId,
    int limit = 10,
  }) async =>
      [];
}

class _Tournaments extends _Fake implements TournamentService {
  final List<TournamentModel> tournaments;
  _Tournaments(this.tournaments);

  @override
  Future<List<TournamentModel>> getTournaments({
    String? lastMatchId,
    int limit = 10,
  }) async =>
      tournaments;
}

TournamentModel createTournament({
  required String id,
  required String name,
  TournamentStatus status = TournamentStatus.upcoming,
  DateTime? startDate,
  DateTime? endDate,
}) =>
    TournamentModel(
      id: id,
      name: name,
      type: TournamentType.knockOut,
      status: status,
      created_by: 'u1',
      start_date: startDate ?? DateTime(2027, 1, 1),
      end_date: endDate ?? DateTime(2027, 2, 1),
      team_ids: const ['t1', 't2', 't3', 't4'],
      match_ids: const ['m1'],
    );

void main() {
  final testTournaments = [
    createTournament(
      id: 'tcpl',
      name: 'TCPL',
      status: TournamentStatus.running,
    ),
    createTournament(
      id: 'ngcl',
      name: 'NGCL 2.0',
      status: TournamentStatus.upcoming,
    ),
    createTournament(
      id: 'smpl',
      name: 'SMPL',
      status: TournamentStatus.finish,
    ),
  ];

  Widget wrapWithScope(Widget child) => ProviderScope(
        overrides: [
          homeViewAllViewProvider.overrideWith((ref) =>
              HomeViewAllViewNotifier(_Matches(), _Tournaments(testTournaments))),
        ],
        child: AppTheme(
          colorScheme: appColorSchemeLight,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: child,
          ),
        ),
      );

  testWidgets('HomeViewAllScreen shows all tournaments with tabs and search',
      (tester) async {
    await tester.pumpWidget(wrapWithScope(
      const HomeViewAllScreen(isTournament: true),
    ));
    await tester.pumpAndSettle();

    // Verify Title and count
    expect(find.text('All tournaments'), findsOneWidget);
    expect(find.text('3'), findsAtLeastNWidgets(1)); // count badge

    // Verify Tabs
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Live'), findsNWidgets(2)); // tab + badge
    expect(find.text('Upcoming'), findsNWidgets(2)); // tab + badge
    expect(find.text('Completed'), findsNWidgets(2)); // tab + badge

    // Verify all 3 cards are displayed initially
    expect(find.text('TCPL'), findsOneWidget);
    expect(find.text('NGCL 2.0'), findsOneWidget);
    expect(find.text('SMPL'), findsOneWidget);

    // Filter by 'Live' tab
    await tester.tap(find.text('Live').first);
    await tester.pumpAndSettle();

    expect(find.text('TCPL'), findsOneWidget);
    expect(find.text('NGCL 2.0'), findsNothing);
    expect(find.text('SMPL'), findsNothing);

    // Filter by 'Completed' tab
    await tester.tap(find.text('Completed').first);
    await tester.pumpAndSettle();

    expect(find.text('TCPL'), findsNothing);
    expect(find.text('NGCL 2.0'), findsNothing);
    expect(find.text('SMPL'), findsOneWidget);

    // Switch back to 'All'
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    // Toggle Search button
    await tester.tap(find.byIcon(CupertinoIcons.search));
    await tester.pumpAndSettle();

    // Search bar should now be visible
    final searchInput = find.byType(EditableText).first;
    await tester.enterText(searchInput, 'NGCL');
    await tester.pumpAndSettle();

    // Only NGCL should be found
    expect(find.text('NGCL 2.0'), findsOneWidget);
    expect(find.text('TCPL'), findsNothing);
    expect(find.text('SMPL'), findsNothing);
  });
}
