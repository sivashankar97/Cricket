import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/constant/firestore_constant.dart';
import '../team/team_model.dart';
import '../user/user_models.dart';

/// A reusable team from the organizer's "Tournament Teams" pool.
///
/// Stored as a regular document in the `teams` collection (flagged with
/// [FireStoreConst.isTournamentTeam]) so matches and fixtures can use it
/// exactly like any other [TeamModel].
class TournamentTeam {
  final String id;
  final String name;
  final String? shortName;
  final String? logo;
  final String? captainId;
  final String? wicketKeeperId;
  final String? createdBy;
  final DateTime? createdAt;
  final List<String> playerIds;

  /// The [TeamPool] this team belongs to; null for teams created before pools.
  final String? poolId;

  const TournamentTeam({
    required this.id,
    required this.name,
    this.shortName,
    this.logo,
    this.captainId,
    this.wicketKeeperId,
    this.createdBy,
    this.createdAt,
    this.playerIds = const [],
    this.poolId,
  });

  int get playerCount => playerIds.length;

  factory TournamentTeam.fromJson(Map<String, dynamic> json) {
    final players = (json[FireStoreConst.teamPlayers] as List?) ?? const [];
    return TournamentTeam(
      id: json[FireStoreConst.id] as String,
      name: (json[FireStoreConst.name] as String?) ?? '',
      shortName: json[FireStoreConst.nameInitial] as String?,
      logo: json[FireStoreConst.profileImageUrl] as String?,
      captainId: json[FireStoreConst.captainId] as String?,
      wicketKeeperId: json[FireStoreConst.wicketKeeperId] as String?,
      createdBy: json[FireStoreConst.createdBy] as String?,
      createdAt: parseFirestoreDate(json[FireStoreConst.createdAt]),
      playerIds: players
          .whereType<Map>()
          .map((player) => player[FireStoreConst.id] as String?)
          .whereType<String>()
          .toList(),
      poolId: json[FireStoreConst.poolId] as String?,
    );
  }

  factory TournamentTeam.fromTeamModel(TeamModel team) => TournamentTeam(
        id: team.id,
        name: team.name,
        shortName: team.name_initial,
        logo: team.profile_img_url,
        createdBy: team.created_by,
        createdAt: team.created_at,
        playerIds: team.players.map((player) => player.id).toList(),
      );

  TournamentTeam copyWith({List<String>? playerIds}) => TournamentTeam(
        id: id,
        name: name,
        shortName: shortName,
        logo: logo,
        captainId: captainId,
        wicketKeeperId: wicketKeeperId,
        createdBy: createdBy,
        createdAt: createdAt,
        playerIds: playerIds ?? this.playerIds,
        poolId: poolId,
      );
}

/// A named group of [TournamentTeam]s for one tournament series,
/// e.g. "GCPL Teams". Stored in the `team_pools` collection.
class TeamPool {
  final String id;
  final String name;
  final String? shortName;
  final String? logo;
  final String? createdBy;
  final DateTime? createdAt;
  final List<String> teamIds;

  const TeamPool({
    required this.id,
    required this.name,
    this.shortName,
    this.logo,
    this.createdBy,
    this.createdAt,
    this.teamIds = const [],
  });

  factory TeamPool.fromJson(Map<String, dynamic> json) => TeamPool(
        id: json[FireStoreConst.id] as String,
        name: (json[FireStoreConst.name] as String?) ?? '',
        shortName: json[FireStoreConst.shortName] as String?,
        logo: json[FireStoreConst.logo] as String?,
        createdBy: json[FireStoreConst.createdBy] as String?,
        createdAt: parseFirestoreDate(json[FireStoreConst.createdAt]),
        teamIds: ((json[FireStoreConst.teamIds] as List?) ?? const [])
            .whereType<String>()
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        FireStoreConst.id: id,
        FireStoreConst.name: name,
        FireStoreConst.shortName: shortName,
        FireStoreConst.logo: logo,
        FireStoreConst.createdBy: createdBy,
        FireStoreConst.createdAt: createdAt?.toIso8601String(),
        FireStoreConst.teamIds: teamIds,
      };

  TeamPool copyWith({
    String? name,
    Object? shortName = _unset,
    Object? logo = _unset,
    List<String>? teamIds,
  }) =>
      TeamPool(
        id: id,
        name: name ?? this.name,
        shortName: shortName == _unset ? this.shortName : shortName as String?,
        logo: logo == _unset ? this.logo : logo as String?,
        createdBy: createdBy,
        createdAt: createdAt,
        teamIds: teamIds ?? this.teamIds,
      );
}

const _unset = Object();

enum TournamentPlayerRole {
  batsman(PlayerRole.topOrderBatter),
  bowler(PlayerRole.bowler),
  allRounder(PlayerRole.allRounder),
  wicketKeeper(PlayerRole.wicketKeeper);

  /// The profile [PlayerRole] this role is saved as on the user document.
  final PlayerRole playerRole;

  const TournamentPlayerRole(this.playerRole);

  static TournamentPlayerRole? fromPlayerRole(PlayerRole? role) {
    switch (role) {
      case PlayerRole.bowler:
        return TournamentPlayerRole.bowler;
      case PlayerRole.allRounder:
        return TournamentPlayerRole.allRounder;
      case PlayerRole.wicketKeeper:
      case PlayerRole.wickerKeeperBatter:
        return TournamentPlayerRole.wicketKeeper;
      case PlayerRole.topOrderBatter:
      case PlayerRole.middleOrderBatter:
      case PlayerRole.lowerOrderBatter:
      case PlayerRole.openingBatter:
        return TournamentPlayerRole.batsman;
      case PlayerRole.none:
      case null:
        return null;
    }
  }
}

/// A player inside a [TournamentTeam]; backed by a `users` document so the
/// player can be picked for squads, scored and ranked like any other user.
class TournamentTeamPlayer {
  final String id;
  final String teamId;
  final String name;
  final TournamentPlayerRole? role;
  final BattingStyle? battingStyle;
  final BowlingStyle? bowlingStyle;
  final int? jerseyNumber;

  /// Id of a `photos` doc, set for players that came from an auction.
  final String? photoId;

  const TournamentTeamPlayer({
    required this.id,
    required this.teamId,
    required this.name,
    this.role,
    this.battingStyle,
    this.bowlingStyle,
    this.jerseyNumber,
    this.photoId,
  });

  String get nameInitial => name.isEmpty ? '?' : name[0].toUpperCase();

  factory TournamentTeamPlayer.fromUserJson(
    Map<String, dynamic> json, {
    required String teamId,
  }) {
    T? byValue<T extends Enum>(List<T> values, Object? raw, int Function(T) v) {
      for (final value in values) {
        if (v(value) == raw) return value;
      }
      return null;
    }

    return TournamentTeamPlayer(
      id: json[FireStoreConst.id] as String,
      teamId: teamId,
      name: (json[FireStoreConst.name] as String?) ?? '',
      role: TournamentPlayerRole.fromPlayerRole(
        byValue(PlayerRole.values, json[FireStoreConst.playerRole],
            (e) => e.value,),
      ),
      battingStyle: byValue(BattingStyle.values,
          json[FireStoreConst.battingStyle], (e) => e.value,),
      bowlingStyle: byValue(BowlingStyle.values,
          json[FireStoreConst.bowlingStyle], (e) => e.value,),
      jerseyNumber: (json[FireStoreConst.jerseyNumber] as num?)?.toInt(),
      photoId: json['photo_id'] as String?,
    );
  }

  Map<String, dynamic> toUserJson() => {
        FireStoreConst.id: id,
        FireStoreConst.name: name,
        FireStoreConst.nameLowercase: name.toLowerCase(),
        FireStoreConst.playerRole: role?.playerRole.value,
        FireStoreConst.battingStyle: battingStyle?.value,
        FireStoreConst.bowlingStyle: bowlingStyle?.value,
        FireStoreConst.jerseyNumber: jerseyNumber,
      };

  TournamentTeamPlayer copyWith({String? id}) => TournamentTeamPlayer(
        id: id ?? this.id,
        teamId: teamId,
        name: name,
        role: role,
        battingStyle: battingStyle,
        bowlingStyle: bowlingStyle,
        jerseyNumber: jerseyNumber,
        photoId: photoId,
      );
}

DateTime? parseFirestoreDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
