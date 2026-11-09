import 'package:cloud_firestore/cloud_firestore.dart';

import '../tournament_team/tournament_team_model.dart' show parseFirestoreDate;

enum PlayMode {
  solo('solo'),
  daily('daily'),
  challenge('challenge'),
  match('match');

  final String value;

  const PlayMode(this.value);

  static PlayMode fromValue(Object? value) => PlayMode.values
      .firstWhere((mode) => mode.value == value, orElse: () => PlayMode.solo);
}

/// One finished innings of the Play tab mini game (`play_games`).
class PlayGame {
  /// Name saved for guest players; `firestore.rules` requires exactly this.
  static const guestName = 'Guest';

  final String id;
  final String userId;
  final String userName;
  final String? userImage;
  final PlayMode mode;
  final int seed;
  final int runs;
  final int wickets;
  final int balls;
  final int fours;
  final int sixes;
  final int? target;
  final bool? won;
  final String? dailyDate;
  final String? challengeId;
  final DateTime createdAt;

  const PlayGame({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.mode,
    required this.seed,
    required this.runs,
    required this.wickets,
    required this.balls,
    this.fours = 0,
    this.sixes = 0,
    this.target,
    this.won,
    this.dailyDate,
    this.challengeId,
    required this.createdAt,
  });

  factory PlayGame.fromJson(Map<String, dynamic> json) => PlayGame(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        userName: (json['user_name'] as String?) ?? '',
        userImage: json['user_image'] as String?,
        mode: PlayMode.fromValue(json['mode']),
        seed: (json['seed'] as num?)?.toInt() ?? 0,
        runs: (json['runs'] as num?)?.toInt() ?? 0,
        wickets: (json['wickets'] as num?)?.toInt() ?? 0,
        balls: (json['balls'] as num?)?.toInt() ?? 0,
        fours: (json['fours'] as num?)?.toInt() ?? 0,
        sixes: (json['sixes'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt(),
        won: json['won'] as bool?,
        dailyDate: json['daily_date'] as String?,
        challengeId: json['challenge_id'] as String?,
        createdAt: parseFirestoreDate(json['created_at']) ?? DateTime(2000),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'user_image': userImage,
        'mode': mode.value,
        'seed': seed,
        'runs': runs,
        'wickets': wickets,
        'balls': balls,
        'fours': fours,
        'sixes': sixes,
        'target': target,
        'won': won,
        'daily_date': dailyDate,
        'challenge_id': challengeId,
        'created_at': Timestamp.fromDate(createdAt),
      };
}

/// Best game per player, highest runs first (fewer balls breaks ties).
List<PlayGame> rankBestScores(List<PlayGame> games, {int limit = 20}) {
  int compare(PlayGame a, PlayGame b) {
    final byRuns = b.runs.compareTo(a.runs);
    return byRuns != 0 ? byRuns : a.balls.compareTo(b.balls);
  }

  final best = <String, PlayGame>{};
  for (final game in games) {
    final current = best[game.userId];
    if (current == null || compare(game, current) < 0) {
      best[game.userId] = game;
    }
  }
  return (best.values.toList()..sort(compare)).take(limit).toList();
}

enum PlayChallengeStatus {
  pending('pending'),
  completed('completed');

  final String value;

  const PlayChallengeStatus(this.value);

  static PlayChallengeStatus fromValue(Object? value) =>
      value == completed.value ? completed : pending;
}

class PlayScore {
  final int runs;
  final int wickets;
  final int balls;

  const PlayScore({
    required this.runs,
    required this.wickets,
    required this.balls,
  });

  factory PlayScore.fromJson(Map<dynamic, dynamic> json) => PlayScore(
        runs: (json['runs'] as num?)?.toInt() ?? 0,
        wickets: (json['wickets'] as num?)?.toInt() ?? 0,
        balls: (json['balls'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'runs': runs, 'wickets': wickets, 'balls': balls};

  @override
  String toString() => '$runs/$wickets';
}

/// Async 1v1: the creator bats first, the opponent later faces the same
/// balls ([seed]) and chases (`play_challenges`).
class PlayChallenge {
  final String id;
  final int seed;
  final String creatorId;
  final String creatorName;
  final String opponentId;
  final String opponentName;
  final PlayScore creatorScore;
  final PlayScore? opponentScore;
  final PlayChallengeStatus status;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const PlayChallenge({
    required this.id,
    required this.seed,
    required this.creatorId,
    required this.creatorName,
    required this.opponentId,
    required this.opponentName,
    required this.creatorScore,
    this.opponentScore,
    this.status = PlayChallengeStatus.pending,
    this.winnerId,
    required this.createdAt,
    this.completedAt,
  });

  bool get isPending => status == PlayChallengeStatus.pending;

  int get target => creatorScore.runs + 1;

  factory PlayChallenge.fromJson(Map<String, dynamic> json) => PlayChallenge(
        id: json['id'] as String,
        seed: (json['seed'] as num?)?.toInt() ?? 0,
        creatorId: json['creator_id'] as String,
        creatorName: (json['creator_name'] as String?) ?? '',
        opponentId: json['opponent_id'] as String,
        opponentName: (json['opponent_name'] as String?) ?? '',
        creatorScore:
            PlayScore.fromJson((json['creator_score'] as Map?) ?? const {}),
        opponentScore: json['opponent_score'] is Map
            ? PlayScore.fromJson(json['opponent_score'] as Map)
            : null,
        status: PlayChallengeStatus.fromValue(json['status']),
        winnerId: json['winner_id'] as String?,
        createdAt: parseFirestoreDate(json['created_at']) ?? DateTime(2000),
        completedAt: parseFirestoreDate(json['completed_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'seed': seed,
        'creator_id': creatorId,
        'creator_name': creatorName,
        'opponent_id': opponentId,
        'opponent_name': opponentName,
        'participant_ids': [creatorId, opponentId],
        'creator_score': creatorScore.toJson(),
        'opponent_score': opponentScore?.toJson(),
        'status': status.value,
        'winner_id': winnerId,
        'created_at': Timestamp.fromDate(createdAt),
        'completed_at':
            completedAt == null ? null : Timestamp.fromDate(completedAt!),
      };
}
