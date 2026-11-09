import 'dart:math';

/// Overs and wickets for one innings.
class MatchFormat {
  final int overs;
  final int wickets;

  const MatchFormat(this.overs, this.wickets);

  static const oneOver = MatchFormat(1, 2);
  static const twoOvers = MatchFormat(2, 3);
  static const fiveOvers = MatchFormat(5, 5);
  static const options = [oneOver, twoOvers, fiveOvers];

  /// Formats saved with an unknown over count fall back to two overs.
  static MatchFormat fromOvers(int overs) => options.firstWhere(
        (format) => format.overs == overs,
        orElse: () => twoOvers,
      );

  int get balls => overs * 6;

  @override
  bool operator ==(Object other) =>
      other is MatchFormat && other.overs == overs && other.wickets == wickets;

  @override
  int get hashCode => Object.hash(overs, wickets);
}

/// "1.4" for 10 balls.
String oversText(int balls) => '${balls ~/ 6}.${balls % 6}';

/// Rules of the Play tab's mini timing-cricket game.
class GameRules {
  /// Quick Play and the Daily Challenge always use two overs, three wickets.
  static const format = MatchFormat.twoOvers;
  static const balls = 12;
  static const wickets = 3;
  static const minTravelMs = 900;
  static const maxTravelMs = 1500;

  /// How long after the ball reaches the batter a late swing still counts.
  static const lateWindowMs = 230;

  /// A swing this close to the ball's arrival is perfect timing (a six).
  static const perfectWindowMs = 45;
}

enum ShotResult {
  dot(0),
  single(1),
  two(2),
  four(4),
  six(6),
  out(0);

  final int runs;

  const ShotResult(this.runs);

  bool get isOut => this == ShotResult.out;
}

class Delivery {
  /// Time from release to reaching the batter.
  final int travelMs;

  /// Missing a ball that is on the stumps gets the batter bowled.
  final bool onStumps;

  /// Sideways position at the batter, -1 (off side) to 1 (leg side).
  final double line;

  const Delivery({
    required this.travelMs,
    required this.onStumps,
    required this.line,
  });

  @override
  bool operator ==(Object other) =>
      other is Delivery &&
      other.travelMs == travelMs &&
      other.onStumps == onStumps &&
      other.line == line;

  @override
  int get hashCode => Object.hash(travelMs, onStumps, line);
}

/// Every player who gets the same [seed] faces exactly the same balls.
List<Delivery> deliveriesForSeed(int seed, {int count = GameRules.balls}) {
  final random = Random(seed);
  return List.generate(count, (_) {
    final travelMs = GameRules.minTravelMs +
        random.nextInt(GameRules.maxTravelMs - GameRules.minTravelMs + 1);
    final onStumps = random.nextDouble() < 0.6;
    final spread = random.nextDouble() * 2 - 1;
    final line =
        onStumps ? spread * 0.25 : spread.sign * (0.45 + spread.abs() * 0.55);
    return Delivery(travelMs: travelMs, onStumps: onStumps, line: line);
  });
}

/// [tapOffsetMs] is tap time minus the ball's arrival time (negative = early);
/// null means the batter did not swing.
ShotResult judgeShot(Delivery delivery, {required int? tapOffsetMs}) {
  final miss = delivery.onStumps ? ShotResult.out : ShotResult.dot;
  if (tapOffsetMs == null) return miss;
  final offset = tapOffsetMs.abs();
  if (offset <= GameRules.perfectWindowMs) return ShotResult.six;
  if (offset <= 100) return ShotResult.four;
  if (offset <= 160) return ShotResult.two;
  if (offset <= GameRules.lateWindowMs) return ShotResult.single;
  return miss;
}

class Innings {
  final int seed;
  final int? target;
  final MatchFormat format;
  final List<Delivery> deliveries;
  final List<ShotResult> results;

  /// Tap offset per ball (null = not swung), so others can replay it.
  final List<int?> offsets;

  const Innings._({
    required this.seed,
    required this.target,
    required this.format,
    required this.deliveries,
    required this.results,
    required this.offsets,
  });

  factory Innings.start({
    required int seed,
    int? target,
    MatchFormat format = MatchFormat.twoOvers,
  }) =>
      Innings._(
        seed: seed,
        target: target,
        format: format,
        deliveries: deliveriesForSeed(seed, count: format.balls),
        results: const [],
        offsets: const [],
      );

  /// Rebuilds an innings from saved balls (e.g. a live opponent's).
  factory Innings.replay({
    required int seed,
    int? target,
    required MatchFormat format,
    required List<(ShotResult, int?)> balls,
  }) {
    var innings = Innings.start(seed: seed, target: target, format: format);
    for (final (result, offset) in balls) {
      innings = innings.record(result, offsetMs: offset);
    }
    return innings;
  }

  int get runs => results.fold(0, (sum, result) => sum + result.runs);

  int get wickets => results.where((result) => result.isOut).length;

  int get balls => results.length;

  int get ballsLeft => deliveries.length - balls;

  int get fours => results.where((result) => result == ShotResult.four).length;

  int get sixes => results.where((result) => result == ShotResult.six).length;

  int? get runsNeeded => target == null ? null : max(0, target! - runs);

  bool get won => target != null && runs >= target!;

  bool get isOver =>
      balls >= deliveries.length || wickets >= format.wickets || won;

  Delivery? get nextDelivery => isOver ? null : deliveries[balls];

  double get strikeRate => balls == 0 ? 0 : runs * 100 / balls;

  Innings record(ShotResult result, {int? offsetMs}) {
    if (isOver) return this;
    return Innings._(
      seed: seed,
      target: target,
      format: format,
      deliveries: deliveries,
      results: [...results, result],
      offsets: [...offsets, offsetMs],
    );
  }
}

/// Which of the few commentary lines to use for a ball; the same for every
/// viewer of the same match.
int commentaryVariant(int seed, int ball, {int variants = 3}) =>
    (seed + ball * 31).abs() % variants;

/// The coin lands heads for even seeds, so both players see the same toss.
bool tossLandsHeads(int seed) => seed.isEven;

enum MatchWinner { firstBatter, secondBatter, tie }

class MatchOutcome {
  final MatchWinner winner;

  /// Runs (first batter won) or wickets left (chaser won); 0 for a tie.
  final int margin;

  const MatchOutcome(this.winner, this.margin);

  bool get byWickets => winner == MatchWinner.secondBatter;
}

/// First batter sets the score; the chaser needs one run more.
MatchOutcome matchOutcome({
  required int firstRuns,
  required int secondRuns,
  required int secondWickets,
  required MatchFormat format,
}) {
  if (secondRuns > firstRuns) {
    return MatchOutcome(
        MatchWinner.secondBatter, format.wickets - secondWickets);
  }
  if (secondRuns < firstRuns) {
    return MatchOutcome(MatchWinner.firstBatter, firstRuns - secondRuns);
  }
  return const MatchOutcome(MatchWinner.tie, 0);
}

/// XP for one finished game: runs, boundaries and a bonus for winning.
int xpForGame({
  required int runs,
  required int fours,
  required int sixes,
  bool? won,
}) =>
    runs + fours * 2 + sixes * 4 + (won == true ? 25 : 5);

/// Levels get 50 XP longer each time: 100, 150, 200…
({int level, int xpInLevel, int xpForNext}) levelForXp(int xp) {
  var level = 1;
  var need = 100;
  var left = xp;
  while (left >= need) {
    left -= need;
    level++;
    need += 50;
  }
  return (level: level, xpInLevel: left, xpForNext: need);
}

/// One shared chase per calendar day for every player.
class DailyChallenge {
  final String dateKey;
  final int seed;
  final int target;

  const DailyChallenge._(this.dateKey, this.seed, this.target);

  factory DailyChallenge.forDate(DateTime date) {
    final key =
        '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
    final seed =
        (date.year * 10000 + date.month * 100 + date.day) * 7919 % 2147483647;
    final target = 16 + Random(seed).nextInt(15);
    return DailyChallenge._(key, seed, target);
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

enum ChallengeWinner { creator, opponent, tie }

ChallengeWinner challengeWinner({
  required int creatorRuns,
  required int opponentRuns,
}) {
  if (opponentRuns > creatorRuns) return ChallengeWinner.opponent;
  if (opponentRuns < creatorRuns) return ChallengeWinner.creator;
  return ChallengeWinner.tie;
}
