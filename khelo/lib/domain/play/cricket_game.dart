import 'dart:math';

/// Rules of the Play tab's mini timing-cricket game.
class GameRules {
  static const balls = 12;
  static const wickets = 3;
  static const minTravelMs = 900;
  static const maxTravelMs = 1500;

  /// How long after the ball reaches the batter a late swing still counts.
  static const lateWindowMs = 230;
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
  if (offset <= 45) return ShotResult.six;
  if (offset <= 100) return ShotResult.four;
  if (offset <= 160) return ShotResult.two;
  if (offset <= GameRules.lateWindowMs) return ShotResult.single;
  return miss;
}

class Innings {
  final int seed;
  final int? target;
  final List<Delivery> deliveries;
  final List<ShotResult> results;

  const Innings._({
    required this.seed,
    required this.target,
    required this.deliveries,
    required this.results,
  });

  factory Innings.start({required int seed, int? target}) => Innings._(
        seed: seed,
        target: target,
        deliveries: deliveriesForSeed(seed),
        results: const [],
      );

  int get runs => results.fold(0, (sum, result) => sum + result.runs);

  int get wickets => results.where((result) => result.isOut).length;

  int get balls => results.length;

  int get ballsLeft => deliveries.length - balls;

  int get fours => results.where((result) => result == ShotResult.four).length;

  int get sixes => results.where((result) => result == ShotResult.six).length;

  int? get runsNeeded => target == null ? null : max(0, target! - runs);

  bool get won => target != null && runs >= target!;

  bool get isOver =>
      balls >= deliveries.length || wickets >= GameRules.wickets || won;

  Delivery? get nextDelivery => isOver ? null : deliveries[balls];

  Innings record(ShotResult result) {
    if (isOver) return this;
    return Innings._(
      seed: seed,
      target: target,
      deliveries: deliveries,
      results: [...results, result],
    );
  }
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
