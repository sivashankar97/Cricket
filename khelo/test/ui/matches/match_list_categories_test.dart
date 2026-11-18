import 'dart:async';

import 'package:data/api/match/match_model.dart';
import 'package:data/api/team/team_model.dart';
import 'package:data/api/user/user_models.dart';
import 'package:data/service/match/match_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:khelo/ui/flow/matches/match_list_screen.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/theme.dart';

class _Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _MockMatchService extends _Fake implements MatchService {
  final List<MatchModel> matches;

  _MockMatchService(this.matches);

  @override
  Stream<List<MatchModel>> streamUserRelatedMatches({
    required String userId,
    int limit = 10,
  }) {
    return Stream.value(matches);
  }
}

MatchModel _createMatch({
  required String id,
  String? tournamentId,
  required String teamAName,
  required String teamBName,
}) {
  return MatchModel(
    id: id,
    tournament_id: tournamentId,
    teams: [
      MatchTeamModel(
        team_id: 'team_a_$id',
        team: TeamModel(
          id: 'team_a_$id',
          name: teamAName,
          name_lowercase: teamAName.toLowerCase(),
          created_at: DateTime(2026, 1, 1),
        ),
      ),
      MatchTeamModel(
        team_id: 'team_b_$id',
        team: TeamModel(
          id: 'team_b_$id',
          name: teamBName,
          name_lowercase: teamBName.toLowerCase(),
          created_at: DateTime(2026, 1, 1),
        ),
      ),
    ],
    match_type: MatchType.limitedOvers,
    number_of_over: 10,
    over_per_bowler: 2,
    city: 'Jaffna',
    ground: 'Central Ground',
    start_time: DateTime(2026, 11, 17, 10, 0),
    start_at: DateTime(2026, 11, 17, 10, 0),
    ball_type: BallType.leather,
    pitch_type: PitchType.turf,
    created_by: 'user_1',
    match_status: MatchStatus.yetToStart,
    updated_at: DateTime.now(),
  );
}

void main() {
  testWidgets(
      'MatchListScreen categorizes independent and tournament matches with tabs',
      (tester) async {
    final matches = [
      _createMatch(
        id: 'm1',
        tournamentId: null,
        teamAName: 'Titans Independent',
        teamBName: 'Warriors Independent',
      ),
      _createMatch(
        id: 'm2',
        tournamentId: null,
        teamAName: 'Lions Independent',
        teamBName: 'Kings Independent',
      ),
      _createMatch(
        id: 'm3',
        tournamentId: 'tourney_1',
        teamAName: 'Super Kings Tourney',
        teamBName: 'Royals Tourney',
      ),
    ];

    final mockService = _MockMatchService(matches);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchServiceProvider.overrideWithValue(mockService),
          currentUserPod.overrideWith((ref) => const UserModel(id: 'user_1', name: 'Tester')),
        ],
        child: AppTheme(
          colorScheme: appColorSchemeLight,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: MatchListScreen()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify tabs with count badges exist:
    // All (3), Independent (2), Tournaments (1)
    expect(find.text('All'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    expect(find.text('Independent'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    expect(find.text('Tournaments'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // On "All" tab: all 3 matches should be rendered
    expect(find.text('Titans Independent'), findsOneWidget);
    expect(find.text('Lions Independent'), findsOneWidget);
    expect(find.text('Super Kings Tourney'), findsOneWidget);

    // Switch to "Independent" tab
    await tester.tap(find.text('Independent'));
    await tester.pumpAndSettle();

    // Now only independent matches should be visible
    expect(find.text('Titans Independent'), findsOneWidget);
    expect(find.text('Lions Independent'), findsOneWidget);
    expect(find.text('Super Kings Tourney'), findsNothing);

    // Switch to "Tournaments" tab
    await tester.tap(find.text('Tournaments'));
    await tester.pumpAndSettle();

    // Now only tournament matches should be visible
    expect(find.text('Titans Independent'), findsNothing);
    expect(find.text('Lions Independent'), findsNothing);
    expect(find.text('Super Kings Tourney'), findsOneWidget);
  });
}
