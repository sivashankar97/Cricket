import 'package:cloud_firestore/cloud_firestore.dart';

import '../tournament_team/tournament_team_model.dart' show parseFirestoreDate;

/// Life of a live 1v1 match (`play_matches`):
/// requested → toss → live → completed, or declined / cancelled on the way.
enum PlayMatchStatus {
  requested('requested'),
  declined('declined'),
  cancelled('cancelled'),
  toss('toss'),
  live('live'),
  completed('completed');

  final String value;

  const PlayMatchStatus(this.value);

  static PlayMatchStatus fromValue(Object? value) =>
      PlayMatchStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => PlayMatchStatus.cancelled,
      );

  bool get isOpen => this == requested || this == toss || this == live;
}

enum PlayMatchResultType {
  runs('runs'),
  wickets('wickets'),
  tie('tie'),
  forfeit('forfeit');

  final String value;

  const PlayMatchResultType(this.value);

  static PlayMatchResultType? fromValue(Object? value) =>
      PlayMatchResultType.values
          .where((type) => type.value == value)
          .firstOrNull;
}

/// One ball as played: the shot name (`ShotResult.name`) and the tap offset
/// in ms (null = not swung), so the other player can replay it.
class PlayBall {
  final String result;
  final int? offset;

  const PlayBall(this.result, [this.offset]);

  factory PlayBall.fromJson(Map<dynamic, dynamic> json) => PlayBall(
        (json['r'] as String?) ?? 'dot',
        (json['o'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {'r': result, 'o': offset};

  @override
  bool operator ==(Object other) =>
      other is PlayBall && other.result == result && other.offset == offset;

  @override
  int get hashCode => Object.hash(result, offset);
}

class PlayMatchPlayer {
  final String id;
  final String name;
  final String? image;

  const PlayMatchPlayer({required this.id, required this.name, this.image});
}

/// A live 1v1 match. The host sends the request; the guest accepts, calls
/// the toss; the toss winner picks bat or bowl. Both innings face the same
/// balls ([seed]); the batter's app writes each ball as it is played.
class PlayMatch {
  /// A request nobody answers within this time counts as expired.
  static const requestLifetime = Duration(minutes: 10);

  /// A player not heard from for this long is shown as disconnected.
  static const disconnectedAfter = Duration(seconds: 30);

  /// After this long without the opponent, the other player may claim the win.
  static const forfeitAfter = Duration(seconds: 60);

  final String id;
  final int seed;
  final int overs;
  final int wickets;
  final PlayMatchPlayer host;
  final PlayMatchPlayer guest;
  final PlayMatchStatus status;
  final String? tossCall;
  final String? tossWinnerId;
  final String? battingFirstId;
  final int currentInnings;
  final List<PlayBall> innings1;
  final List<PlayBall> innings2;
  final String? winnerId;
  final PlayMatchResultType? resultType;
  final int? margin;
  final Map<String, DateTime> lastSeen;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PlayMatch({
    required this.id,
    required this.seed,
    required this.overs,
    required this.wickets,
    required this.host,
    required this.guest,
    this.status = PlayMatchStatus.requested,
    this.tossCall,
    this.tossWinnerId,
    this.battingFirstId,
    this.currentInnings = 1,
    this.innings1 = const [],
    this.innings2 = const [],
    this.winnerId,
    this.resultType,
    this.margin,
    this.lastSeen = const {},
    required this.createdAt,
    this.updatedAt,
  });

  bool isHost(String userId) => host.id == userId;

  bool involves(String userId) => host.id == userId || guest.id == userId;

  PlayMatchPlayer playerById(String id) => host.id == id ? host : guest;

  PlayMatchPlayer otherThan(String userId) => host.id == userId ? guest : host;

  String? get battingSecondId => battingFirstId == null
      ? null
      : (battingFirstId == host.id ? guest.id : host.id);

  /// Who bats in the innings being played now.
  String? get currentBatterId =>
      currentInnings == 1 ? battingFirstId : battingSecondId;

  List<PlayBall> get currentBalls => currentInnings == 1 ? innings1 : innings2;

  bool isExpired(DateTime now) =>
      status == PlayMatchStatus.requested &&
      now.difference(createdAt) > requestLifetime;

  /// Seconds since [userId] was last heard from (null = never).
  Duration? silenceOf(String userId, DateTime now) {
    final seen = lastSeen[userId];
    return seen == null ? null : now.difference(seen);
  }

  factory PlayMatch.fromJson(Map<String, dynamic> json) {
    List<PlayBall> balls(Object? value) => value is List
        ? value.whereType<Map>().map(PlayBall.fromJson).toList()
        : const [];
    final seen = <String, DateTime>{};
    if (json['last_seen'] is Map) {
      (json['last_seen'] as Map).forEach((key, value) {
        final date = parseFirestoreDate(value);
        if (date != null) seen['$key'] = date;
      });
    }
    return PlayMatch(
      id: json['id'] as String,
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      overs: (json['overs'] as num?)?.toInt() ?? 2,
      wickets: (json['wickets'] as num?)?.toInt() ?? 3,
      host: PlayMatchPlayer(
        id: json['host_id'] as String,
        name: (json['host_name'] as String?) ?? '',
        image: json['host_image'] as String?,
      ),
      guest: PlayMatchPlayer(
        id: json['guest_id'] as String,
        name: (json['guest_name'] as String?) ?? '',
        image: json['guest_image'] as String?,
      ),
      status: PlayMatchStatus.fromValue(json['status']),
      tossCall: json['toss_call'] as String?,
      tossWinnerId: json['toss_winner_id'] as String?,
      battingFirstId: json['batting_first_id'] as String?,
      currentInnings: (json['current_innings'] as num?)?.toInt() ?? 1,
      innings1: balls(json['innings_1']),
      innings2: balls(json['innings_2']),
      winnerId: json['winner_id'] as String?,
      resultType: PlayMatchResultType.fromValue(json['result_type']),
      margin: (json['margin'] as num?)?.toInt(),
      lastSeen: seen,
      createdAt: parseFirestoreDate(json['created_at']) ?? DateTime(2000),
      updatedAt: parseFirestoreDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seed': seed,
        'overs': overs,
        'wickets': wickets,
        'host_id': host.id,
        'host_name': host.name,
        'host_image': host.image,
        'guest_id': guest.id,
        'guest_name': guest.name,
        'guest_image': guest.image,
        'participant_ids': [host.id, guest.id],
        'status': status.value,
        'toss_call': tossCall,
        'toss_winner_id': tossWinnerId,
        'batting_first_id': battingFirstId,
        'current_innings': currentInnings,
        'innings_1': innings1.map((ball) => ball.toJson()).toList(),
        'innings_2': innings2.map((ball) => ball.toJson()).toList(),
        'winner_id': winnerId,
        'result_type': resultType?.value,
        'margin': margin,
        'last_seen': lastSeen
            .map((key, value) => MapEntry(key, Timestamp.fromDate(value))),
        'created_at': Timestamp.fromDate(createdAt),
        'updated_at': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      };
}

/// Who has the Play tab open right now (`play_presence/{userId}`).
class PlayPresence {
  /// Seen within this time counts as online.
  static const onlineWindow = Duration(minutes: 2);

  final String userId;
  final String name;
  final String? image;
  final DateTime lastSeen;

  const PlayPresence({
    required this.userId,
    required this.name,
    this.image,
    required this.lastSeen,
  });

  bool isOnline(DateTime now) => now.difference(lastSeen) <= onlineWindow;

  factory PlayPresence.fromJson(Map<String, dynamic> json) => PlayPresence(
        userId: json['user_id'] as String,
        name: (json['name'] as String?) ?? '',
        image: json['image'] as String?,
        lastSeen: parseFirestoreDate(json['last_seen']) ?? DateTime(2000),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'image': image,
        'last_seen': Timestamp.fromDate(lastSeen),
      };
}
