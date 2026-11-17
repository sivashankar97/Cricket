import 'package:data/api/tournament/tournament_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khelo/l10n/app_localizations.dart';
import 'package:khelo/ui/flow/home/components/tournament_card.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/theme.dart';

TournamentModel createTournament({
  required String id,
  required String name,
  TournamentStatus status = TournamentStatus.upcoming,
  TournamentType type = TournamentType.knockOut,
  List<String> teamIds = const ['t1', 't2', 't3', 't4', 't5', 't6', 't7'],
  List<String> matchIds = const ['m1', 'm2'],
  DateTime? startDate,
  DateTime? endDate,
}) =>
    TournamentModel(
      id: id,
      name: name,
      type: type,
      status: status,
      created_by: 'u1',
      start_date: startDate ?? DateTime(2026, 6, 11),
      end_date: endDate ?? DateTime(2026, 7, 31),
      team_ids: teamIds,
      match_ids: matchIds,
    );

Widget wrap(Widget child) => AppTheme(
      colorScheme: appColorSchemeLight,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ListView(children: [child])),
      ),
    );

void main() {
  testWidgets('TournamentCard displays name, status, teams and dates',
      (tester) async {
    final live = createTournament(
      id: 'tcpl',
      name: 'TCPL',
      status: TournamentStatus.running,
      startDate: DateTime(2026, 6, 11),
      endDate: DateTime(2026, 7, 31),
    );

    await tester.pumpWidget(wrap(TournamentCard(tournament: live)));
    await tester.pump();

    expect(find.text('TCPL'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('7 teams'), findsOneWidget);
    expect(find.text('11 Jun – 31 Jul 2026'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // match / view count
  });

  testWidgets('TournamentCard displays upcoming and completed badges correctly',
      (tester) async {
    final now = DateTime.now();
    final upcoming = createTournament(
      id: 'ngcl',
      name: 'NGCL 2.0',
      status: TournamentStatus.upcoming,
      startDate: DateTime(now.year + 1, 8, 1),
      endDate: DateTime(now.year + 1, 8, 23),
    );

    final completed = createTournament(
      id: 'smpl',
      name: 'SMPL',
      status: TournamentStatus.finish,
      startDate: DateTime(2025, 7, 25),
      endDate: DateTime(2025, 8, 30),
    );

    await tester.pumpWidget(wrap(Column(
      children: [
        TournamentCard(tournament: upcoming, onTap: () {}),
        TournamentCard(tournament: completed, onTap: () {}),
      ],
    )));
    await tester.pump();

    expect(find.text('NGCL 2.0'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('1 – 23 Aug ${now.year + 1}'), findsOneWidget);

    expect(find.text('SMPL'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('25 Jul – 30 Aug 2025'), findsOneWidget);
  });

  testWidgets('TournamentCard favorite toggle triggers callback',
      (tester) async {
    var toggled = false;
    final tournament = createTournament(id: 't1', name: 'Test Cup');

    await tester.pumpWidget(wrap(TournamentCard(
      tournament: tournament,
      isFavorite: false,
      onTap: () {},
      onFavoriteToggle: () => toggled = true,
    )));
    await tester.pump();

    // Tap favorite button
    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await tester.pumpAndSettle();
    expect(toggled, isTrue);
  });

  const screens = {
    'small phone': Size(320, 568),
    'phone': Size(390, 844),
    'desktop': Size(1440, 900),
  };

  for (final screen in screens.entries) {
    testWidgets('TournamentCard fits ${screen.key} without overflow',
        (tester) async {
      tester.view.physicalSize = screen.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final live = createTournament(
        id: 'tcpl',
        name: 'நண்பர்களின் போர் 4.0 Super League',
        status: TournamentStatus.running,
        teamIds: List.generate(12, (i) => 't$i'),
      );

      await tester.pumpWidget(wrap(TournamentCard(
        tournament: live,
        onTap: () {},
      )));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
