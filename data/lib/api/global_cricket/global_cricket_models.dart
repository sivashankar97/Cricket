import 'package:cloud_firestore/cloud_firestore.dart';

/// Which Home / Global cricket tab a match belongs to. Everything else
/// (domestic, A teams, U19, other franchise leagues) is dropped.
enum GlobalMatchCategory {
  international,
  league;

  static GlobalMatchCategory? fromValue(Object? value) =>
      values.where((e) => e.name == value).firstOrNull;
}

/// CricketData.org's `ms` field: fixture, live or result.
enum GlobalMatchState {
  fixture,
  live,
  result;

  static GlobalMatchState fromValue(Object? value) =>
      values.where((e) => e.name == value).firstOrNull ?? fixture;
}

/// Senior national teams; a match is international when both sides are on
/// this list (a trailing " Women" is ignored).
const _nationalTeams = {
  'afghanistan',
  'australia',
  'bangladesh',
  'england',
  'india',
  'ireland',
  'new zealand',
  'pakistan',
  'south africa',
  'sri lanka',
  'west indies',
  'zimbabwe',
  'argentina',
  'austria',
  'bahamas',
  'bahrain',
  'belgium',
  'belize',
  'bermuda',
  'bhutan',
  'botswana',
  'brazil',
  'bulgaria',
  'cambodia',
  'cameroon',
  'canada',
  'cayman islands',
  'chile',
  'china',
  'cook islands',
  'costa rica',
  'croatia',
  'cyprus',
  'czech republic',
  'denmark',
  'estonia',
  'eswatini',
  'fiji',
  'finland',
  'france',
  'gambia',
  'germany',
  'ghana',
  'gibraltar',
  'greece',
  'guernsey',
  'hong kong',
  'hungary',
  'indonesia',
  'iran',
  'isle of man',
  'israel',
  'italy',
  'ivory coast',
  'japan',
  'jersey',
  'kenya',
  'kuwait',
  'lesotho',
  'luxembourg',
  'malawi',
  'malaysia',
  'maldives',
  'mali',
  'malta',
  'mexico',
  'mongolia',
  'mozambique',
  'myanmar',
  'namibia',
  'nepal',
  'netherlands',
  'nigeria',
  'norway',
  'oman',
  'panama',
  'papua new guinea',
  'peru',
  'philippines',
  'portugal',
  'qatar',
  'romania',
  'rwanda',
  'samoa',
  'saudi arabia',
  'scotland',
  'serbia',
  'seychelles',
  'sierra leone',
  'singapore',
  'slovenia',
  'south korea',
  'spain',
  'st helena',
  'sweden',
  'switzerland',
  'tanzania',
  'thailand',
  'turkey',
  'uganda',
  'united arab emirates',
  'uae',
  'united states of america',
  'usa',
  'vanuatu',
  'zambia',
};

/// Full-member (Test) nations; their matches lead the Home row.
const _testNations = {
  'afghanistan',
  'australia',
  'bangladesh',
  'england',
  'india',
  'ireland',
  'new zealand',
  'pakistan',
  'south africa',
  'sri lanka',
  'west indies',
  'zimbabwe',
};

String _teamKey(String team) =>
    team.toLowerCase().replaceFirst(RegExp(r'\s+women$'), '').trim();

/// Major franchise leagues shown under "Premier leagues", matched against the
/// series name (lower case, apostrophes removed).
const premierLeagueSeries = [
  'indian premier league',
  'womens premier league',
  'big bash league',
  'pakistan super league',
  'caribbean premier league',
  'sa20',
  'international league t20',
  'the hundred',
  'major league cricket',
  'lanka premier league',
  'bangladesh premier league',
  'nepal premier league',
];

/// Series that use national team names but aren't senior internationals.
const _excludedSeriesWords = ['emerging', 'u19', 'under-19', 'under 19'];

GlobalMatchCategory? categorizeGlobalMatch({
  required String series,
  required String team1,
  required String team2,
}) {
  final seriesKey = series.toLowerCase().replaceAll(RegExp("['’]"), '');
  if (premierLeagueSeries.any(seriesKey.contains)) {
    return GlobalMatchCategory.league;
  }
  if (_excludedSeriesWords.any(seriesKey.contains)) return null;

  bool isNational(String team) => _nationalTeams.contains(_teamKey(team));

  return isNational(team1) && isNational(team2)
      ? GlobalMatchCategory.international
      : null;
}

DateTime? _parseGmt(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value.endsWith('Z') ? value : '${value}Z');
}

class GlobalTeam {
  final String name;
  final String shortName;
  final String imageUrl;

  const GlobalTeam({
    required this.name,
    required this.shortName,
    this.imageUrl = '',
  });

  /// CricketData.org's `cricScore` team text, e.g. "India [IND]".
  factory GlobalTeam.fromLabel(String text, {String imageUrl = ''}) {
    final match = RegExp(r'^(.*?)\s*\[(.+)\]\s*$').firstMatch(text.trim());
    return GlobalTeam(
      name: (match?.group(1) ?? text).trim(),
      shortName: (match?.group(2) ?? '').trim(),
      imageUrl: imageUrl,
    );
  }

  factory GlobalTeam.fromJson(Map<String, dynamic> json) => GlobalTeam(
        name: json['name']?.toString() ?? '',
        shortName: json['shortname']?.toString() ?? '',
        imageUrl: json['img']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'name': name, 'shortname': shortName, 'img': imageUrl};

  String get label => shortName.isNotEmpty ? shortName : name;

  String get initial => label.isEmpty ? '?' : label.substring(0, 1);
}

/// One match from CricketData.org's `cricScore` endpoint (shared cache shape).
class GlobalMatch {
  final String id;
  final String series;
  final String matchType;
  final String status;
  final GlobalMatchState state;
  final GlobalMatchCategory category;
  final DateTime? startTime;
  final GlobalTeam team1;
  final GlobalTeam team2;

  /// Score text as sent by the API, e.g. "250/8 (50)"; empty before batting.
  final String score1;
  final String score2;

  const GlobalMatch({
    required this.id,
    required this.series,
    required this.matchType,
    required this.status,
    required this.state,
    required this.category,
    required this.startTime,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
  });

  bool get isLive => state == GlobalMatchState.live;

  bool get isResult => state == GlobalMatchState.result;

  bool get isUpcoming => state == GlobalMatchState.fixture;

  String get title => '${team1.name} vs ${team2.name}';

  /// Premier-league matches, and internationals with a Test nation playing.
  bool get isHeadline =>
      category == GlobalMatchCategory.league ||
      _testNations.contains(_teamKey(team1.name)) ||
      _testNations.contains(_teamKey(team2.name));

  @override
  bool operator ==(Object other) =>
      other is GlobalMatch && other.id == id && other.state == state;

  @override
  int get hashCode => Object.hash(id, state);

  /// Null when the match is neither international nor a premier league.
  static GlobalMatch? fromCricScore(Map<String, dynamic> json) {
    final t1 = json['t1']?.toString() ?? '';
    final t2 = json['t2']?.toString() ?? '';
    final series = json['series']?.toString() ?? '';
    final team1 = GlobalTeam.fromLabel(t1, imageUrl: '${json['t1img'] ?? ''}');
    final team2 = GlobalTeam.fromLabel(t2, imageUrl: '${json['t2img'] ?? ''}');
    final category = categorizeGlobalMatch(
      series: series,
      team1: team1.name,
      team2: team2.name,
    );
    if (category == null) return null;
    return GlobalMatch(
      id: json['id']?.toString() ?? '',
      series: series,
      matchType: json['matchType']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      state: GlobalMatchState.fromValue(json['ms']),
      category: category,
      startTime: _parseGmt(json['dateTimeGMT']),
      team1: team1,
      team2: team2,
      score1: json['t1s']?.toString() ?? '',
      score2: json['t2s']?.toString() ?? '',
    );
  }

  factory GlobalMatch.fromJson(Map<String, dynamic> json) => GlobalMatch(
        id: json['id']?.toString() ?? '',
        series: json['series']?.toString() ?? '',
        matchType: json['match_type']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        state: GlobalMatchState.fromValue(json['state']),
        category: GlobalMatchCategory.fromValue(json['category']) ??
            GlobalMatchCategory.international,
        startTime: _parseGmt(json['start_time']),
        team1: GlobalTeam.fromJson(
          Map<String, dynamic>.from((json['team1'] as Map?) ?? const {}),
        ),
        team2: GlobalTeam.fromJson(
          Map<String, dynamic>.from((json['team2'] as Map?) ?? const {}),
        ),
        score1: json['score1']?.toString() ?? '',
        score2: json['score2']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'series': series,
        'match_type': matchType,
        'status': status,
        'state': state.name,
        'category': category.name,
        'start_time': startTime == null ? null : Timestamp.fromDate(startTime!),
        'team1': team1.toJson(),
        'team2': team2.toJson(),
        'score1': score1,
        'score2': score2,
      };
}

/// The shared cache document `global_cricket/current_matches`.
class GlobalCricketFeed {
  final List<GlobalMatch> matches;
  final DateTime? fetchedAt;

  const GlobalCricketFeed({required this.matches, required this.fetchedAt});

  static const empty = GlobalCricketFeed(matches: [], fetchedAt: null);

  factory GlobalCricketFeed.fromJson(Map<String, dynamic> json) =>
      GlobalCricketFeed(
        // Docs written before the cricScore switch have no `state`; skip them.
        matches: ((json['matches'] as List?) ?? const [])
            .whereType<Map>()
            .where((e) => e['state'] != null)
            .map((e) => GlobalMatch.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        fetchedAt: (json['fetched_at'] as Timestamp?)?.toDate(),
      );

  GlobalMatch? byId(String id) => matches.where((m) => m.id == id).firstOrNull;

  List<GlobalMatch> of(GlobalMatchCategory category) =>
      matches.where((m) => m.category == category).toList();

  /// Live (latest start first), then recent results (newest first), then
  /// upcoming (soonest first).
  static List<GlobalMatch> sortForDisplay(Iterable<GlobalMatch> matches) {
    int rank(GlobalMatch m) => switch (m.state) {
          GlobalMatchState.live => 0,
          GlobalMatchState.result => 1,
          GlobalMatchState.fixture => 2,
        };
    final list = [...matches];
    list.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      final at = a.startTime ?? DateTime(0);
      final bt = b.startTime ?? DateTime(0);
      return a.isUpcoming ? at.compareTo(bt) : bt.compareTo(at);
    });
    return list;
  }

  /// The Home row: headline matches first (each group in display order),
  /// then the rest, capped at [limit].
  static List<GlobalMatch> highlights(
    Iterable<GlobalMatch> matches, {
    required int limit,
  }) {
    final sorted = sortForDisplay(matches);
    return [
      ...sorted.where((m) => m.isHeadline),
      ...sorted.where((m) => !m.isHeadline),
    ].take(limit).toList();
  }
}

/// One innings line, e.g. "India Inning 1": 250/8 (50).
class GlobalInningScore {
  final String inning;
  final int runs;
  final int wickets;
  final double overs;

  const GlobalInningScore({
    required this.inning,
    required this.runs,
    required this.wickets,
    required this.overs,
  });

  factory GlobalInningScore.fromJson(Map<String, dynamic> json) =>
      GlobalInningScore(
        inning: json['inning']?.toString() ?? '',
        runs: (json['r'] as num?)?.toInt() ?? 0,
        wickets: (json['w'] as num?)?.toInt() ?? 0,
        overs: (json['o'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'inning': inning, 'r': runs, 'w': wickets, 'o': overs};

  /// "250/8 (50)"; wickets are left out when all out (10).
  String get display {
    final score = wickets >= 10 ? '$runs' : '$runs/$wickets';
    return '$score (${_overs(overs)})';
  }
}

String _overs(double overs) =>
    overs == overs.truncateToDouble() ? '${overs.toInt()}' : '$overs';

num _num(Object? value) => value is num ? value : num.tryParse('$value') ?? 0;

class GlobalBatter {
  final String name;
  final String dismissal;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;

  const GlobalBatter({
    required this.name,
    required this.dismissal,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
  });

  factory GlobalBatter.fromJson(Map<String, dynamic> json) => GlobalBatter(
        name: json['name']?.toString() ??
            (json['batsman'] as Map?)?['name']?.toString() ??
            '',
        dismissal: json['dismissal_text']?.toString() ??
            json['dismissal-text']?.toString() ??
            '',
        runs: _num(json['r']).toInt(),
        balls: _num(json['b']).toInt(),
        fours: _num(json['4s']).toInt(),
        sixes: _num(json['6s']).toInt(),
        strikeRate: _num(json['sr']).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'dismissal_text': dismissal,
        'r': runs,
        'b': balls,
        '4s': fours,
        '6s': sixes,
        'sr': strikeRate,
      };
}

class GlobalBowler {
  final String name;
  final double overs;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;

  const GlobalBowler({
    required this.name,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });

  factory GlobalBowler.fromJson(Map<String, dynamic> json) => GlobalBowler(
        name: json['name']?.toString() ??
            (json['bowler'] as Map?)?['name']?.toString() ??
            '',
        overs: _num(json['o']).toDouble(),
        maidens: _num(json['m']).toInt(),
        runs: _num(json['r']).toInt(),
        wickets: _num(json['w']).toInt(),
        economy: _num(json['eco']).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'o': overs,
        'm': maidens,
        'r': runs,
        'w': wickets,
        'eco': economy,
      };

  String get oversText => _overs(overs);
}

class GlobalInnings {
  final String title;
  final List<GlobalBatter> batting;
  final List<GlobalBowler> bowling;

  const GlobalInnings({
    required this.title,
    required this.batting,
    required this.bowling,
  });

  factory GlobalInnings.fromJson(Map<String, dynamic> json) => GlobalInnings(
        title: json['inning']?.toString() ?? '',
        batting: ((json['batting'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => GlobalBatter.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        bowling: ((json['bowling'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => GlobalBowler.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'inning': title,
        'batting': batting.map((e) => e.toJson()).toList(),
        'bowling': bowling.map((e) => e.toJson()).toList(),
      };
}

/// Cached `match_scorecard` result in `global_cricket/scorecards/matches/{id}`.
class GlobalScorecard {
  final String id;
  final String name;
  final String status;
  final String venue;
  final DateTime? startTime;
  final String tossWinner;
  final String tossChoice;
  final List<GlobalTeam> teams;
  final List<GlobalInningScore> scores;
  final List<GlobalInnings> innings;
  final bool ended;
  final DateTime? fetchedAt;

  const GlobalScorecard({
    required this.id,
    required this.name,
    required this.status,
    required this.venue,
    required this.startTime,
    required this.tossWinner,
    required this.tossChoice,
    required this.teams,
    required this.scores,
    required this.innings,
    required this.ended,
    required this.fetchedAt,
  });

  /// Accepts both the API `data` object and the cached Firestore shape.
  factory GlobalScorecard.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(Object? list) => ((list as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return GlobalScorecard(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      startTime: _parseGmt(json['dateTimeGMT']),
      tossWinner: json['tossWinner']?.toString() ?? '',
      tossChoice: json['tossChoice']?.toString() ?? '',
      teams: maps(json['teamInfo']).map(GlobalTeam.fromJson).toList(),
      scores: maps(json['score']).map(GlobalInningScore.fromJson).toList(),
      innings: maps(json['scorecard']).map(GlobalInnings.fromJson).toList(),
      ended: json['matchEnded'] == true,
      fetchedAt: (json['fetched_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status,
        'venue': venue,
        'dateTimeGMT':
            startTime == null ? null : Timestamp.fromDate(startTime!),
        'tossWinner': tossWinner,
        'tossChoice': tossChoice,
        'teamInfo': teams.map((e) => e.toJson()).toList(),
        'score': scores.map((e) => e.toJson()).toList(),
        'scorecard': innings.map((e) => e.toJson()).toList(),
        'matchEnded': ended,
      };

  /// Total for an innings title like "India Inning 1", e.g. "250/8 (50)".
  String totalFor(String inning) =>
      scores.where((s) => s.inning == inning).firstOrNull?.display ?? '';
}
