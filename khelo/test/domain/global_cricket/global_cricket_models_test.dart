import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/api/global_cricket/global_cricket_models.dart';
import 'package:data/service/global_cricket/global_cricket_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _cricScore({
  String id = 'm1',
  String series = 'India tour of Australia, 2026',
  String t1 = 'India [IND]',
  String t2 = 'Australia [AUS]',
  String ms = 'live',
  String dateTimeGMT = '2026-11-09T04:00:00',
}) =>
    {
      'id': id,
      'dateTimeGMT': dateTimeGMT,
      'matchType': 'odi',
      'status': 'India opt to bat',
      'ms': ms,
      't1': t1,
      't2': t2,
      't1s': '250/8 (50)',
      't2s': '',
      't1img': 'https://g.cricapi.com/img/ind.png',
      't2img': '',
      'series': series,
    };

void main() {
  group('categorizeGlobalMatch', () {
    GlobalMatchCategory? of(String series, String t1, String t2) =>
        categorizeGlobalMatch(series: series, team1: t1, team2: t2);

    test('senior national teams are international, women included', () {
      expect(of('India tour of Australia', 'India', 'Australia'),
          GlobalMatchCategory.international);
      expect(of('Women T20 series', 'India Women', 'England Women'),
          GlobalMatchCategory.international);
    });

    test('premier leagues are matched by series name', () {
      expect(of("Indian Premier League 2026", 'Chennai', 'Mumbai'),
          GlobalMatchCategory.league);
      expect(of("Women's Premier League 2026", 'Delhi', 'Mumbai'),
          GlobalMatchCategory.league);
    });

    test('domestic, A team and youth matches are dropped', () {
      expect(of('Ranji Trophy', 'Tamil Nadu', 'Kerala'), isNull);
      expect(of('India A tour of England', 'India A', 'England Lions'), isNull);
      expect(of('ICC Under 19 World Cup', 'India', 'Pakistan'), isNull);
      expect(of('Emerging Teams Asia Cup', 'India', 'Sri Lanka'), isNull);
    });
  });

  group('GlobalMatch', () {
    test('parses cricScore and round-trips through Firestore shape', () {
      final match = GlobalMatch.fromCricScore(_cricScore())!;
      expect(match.team1.name, 'India');
      expect(match.team1.shortName, 'IND');
      expect(match.isLive, isTrue);
      expect(match.category, GlobalMatchCategory.international);
      expect(match.startTime, DateTime.utc(2026, 11, 9, 4));

      final copy = GlobalMatch.fromJson(match.toJson());
      expect(copy, match);
      expect(copy.team1.imageUrl, match.team1.imageUrl);
      expect(copy.score1, '250/8 (50)');
      expect(copy.startTime!.isAtSameMomentAs(match.startTime!), isTrue);
    });

    test('filtered matches return null', () {
      expect(
        GlobalMatch.fromCricScore(
          _cricScore(
              series: 'Ranji Trophy', t1: 'Delhi [DEL]', t2: 'Goa [GOA]'),
        ),
        isNull,
      );
    });
  });

  group('GlobalCricketFeed', () {
    test('skips old-shape matches and sorts for display', () {
      GlobalMatch m(String id, String ms, String time) =>
          GlobalMatch.fromCricScore(
            _cricScore(id: id, ms: ms, dateTimeGMT: time),
          )!;
      final feed = GlobalCricketFeed.fromJson({
        'matches': [
          {'id': 'old', 'name': 'Old shape'},
          m('f-late', 'fixture', '2026-11-20T00:00:00').toJson(),
          m('r-old', 'result', '2026-11-01T00:00:00').toJson(),
          m('f-soon', 'fixture', '2026-11-10T00:00:00').toJson(),
          m('live', 'live', '2026-11-09T00:00:00').toJson(),
          m('r-new', 'result', '2026-11-08T00:00:00').toJson(),
        ],
        'fetched_at': Timestamp.fromDate(DateTime(2026, 11, 9)),
      });
      expect(feed.matches.length, 5);
      expect(
        GlobalCricketFeed.sortForDisplay(feed.matches).map((e) => e.id),
        ['live', 'r-new', 'r-old', 'f-soon', 'f-late'],
      );
    });

    test('Home highlights put Test-nation matches first', () {
      final associate = GlobalMatch.fromCricScore(_cricScore(
        id: 'assoc',
        t1: 'Rwanda Women [RWA-W]',
        t2: 'Uganda Women [UGA-W]',
        ms: 'result',
        dateTimeGMT: '2026-11-09T00:00:00',
      ))!;
      final major = GlobalMatch.fromCricScore(_cricScore(
        id: 'major',
        ms: 'result',
        dateTimeGMT: '2026-11-01T00:00:00',
      ))!;
      expect(associate.isHeadline, isFalse);
      expect(
        GlobalCricketFeed.highlights([associate, major], limit: 6)
            .map((e) => e.id),
        ['major', 'assoc'],
      );
      expect(
          GlobalCricketFeed.highlights([associate, major], limit: 1), [major]);
    });
  });

  group('GlobalScorecard', () {
    test('parses the API shape and round-trips through the cache', () {
      final card = GlobalScorecard.fromJson({
        'id': 'm1',
        'name': 'India vs Australia, 1st ODI',
        'status': 'India won by 20 runs',
        'venue': 'MCG',
        'dateTimeGMT': '2026-11-09T04:00:00',
        'tossWinner': 'india',
        'tossChoice': 'batting',
        'teamInfo': [
          {'name': 'India', 'shortname': 'IND', 'img': ''},
        ],
        'score': [
          {'r': 250, 'w': 10, 'o': 49.3, 'inning': 'India Inning 1'},
        ],
        'scorecard': [
          {
            'inning': 'India Inning 1',
            'batting': [
              {
                'batsman': {'name': 'Rohit Sharma'},
                'dismissal-text': 'c Smith b Starc',
                'r': 80,
                'b': 70,
                '4s': 8,
                '6s': 3,
                'sr': 114.28,
              },
            ],
            'bowling': [
              {
                'bowler': {'name': 'Mitchell Starc'},
                'o': 10,
                'm': 1,
                'r': 45,
                'w': 3,
                'eco': 4.5,
              },
            ],
          },
        ],
        'matchEnded': true,
      });
      expect(card.totalFor('India Inning 1'), '250 (49.3)');
      expect(card.innings.single.batting.single.name, 'Rohit Sharma');
      expect(card.innings.single.batting.single.dismissal, 'c Smith b Starc');
      expect(card.innings.single.bowling.single.oversText, '10');

      final copy = GlobalScorecard.fromJson(card.toJson());
      expect(copy.innings.single.batting.single.runs, 80);
      expect(copy.innings.single.bowling.single.wickets, 3);
      expect(copy.startTime!.isAtSameMomentAs(card.startTime!), isTrue);
      expect(copy.ended, isTrue);
    });
  });

  group('canAffordScorecard', () {
    test('keeps room for the remaining feed refreshes today', () {
      // 22:00 UTC leaves 4 half-hour feed refreshes before midnight.
      final now = DateTime.utc(2026, 11, 9, 22);
      expect(
        GlobalCricketService.canAffordScorecard(hitsToday: 86, now: now),
        isTrue,
      );
      expect(
        GlobalCricketService.canAffordScorecard(hitsToday: 87, now: now),
        isFalse,
      );
    });
  });
}
