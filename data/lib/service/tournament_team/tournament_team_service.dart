import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../api/team/team_model.dart';
import '../../api/tournament_team/tournament_team_model.dart';
import '../../errors/app_error.dart';
import '../../errors/app_error_l10n_codes.dart';
import '../../extensions/list_extensions.dart';
import '../../extensions/string_extensions.dart';
import '../../utils/constant/firestore_constant.dart';

final tournamentTeamServiceProvider = Provider(
  (ref) => TournamentTeamService(FirebaseFirestore.instance),
);

class TournamentTeamService {
  final FirebaseFirestore _firestore;

  TournamentTeamService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _teams =>
      _firestore.collection(FireStoreConst.teamsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FireStoreConst.usersCollection);

  CollectionReference<Map<String, dynamic>> get _pools =>
      _firestore.collection(FireStoreConst.teamPoolsCollection);

  Query<Map<String, dynamic>> _poolQuery(String userId) => _teams
      .where(FireStoreConst.createdBy, isEqualTo: userId)
      .where(FireStoreConst.isTournamentTeam, isEqualTo: true);

  String get generateTeamId => _teams.doc().id;

  String get generatePoolId => _pools.doc().id;

  List<TournamentTeam> _sortedTeams(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((doc) => TournamentTeam.fromJson(doc.data())).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// All of the organizer's tournament teams, across every pool.
  Stream<List<TournamentTeam>> streamTeams(String userId) {
    return _poolQuery(userId)
        .snapshots()
        .map(_sortedTeams)
        .handleError((error, stack) => throw AppError.fromError(error, stack));
  }

  Stream<List<TournamentTeam>> streamTeamsInPool(String poolId) {
    return _teams
        .where(FireStoreConst.poolId, isEqualTo: poolId)
        .snapshots()
        .map(_sortedTeams)
        .handleError((error, stack) => throw AppError.fromError(error, stack));
  }

  Stream<List<TeamPool>> streamPools(String userId) {
    return _pools
        .where(FireStoreConst.createdBy, isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamPool.fromJson(doc.data()))
            .toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),),)
        .handleError((error, stack) => throw AppError.fromError(error, stack));
  }

  Stream<TeamPool?> streamPool(String poolId) {
    return _pools.doc(poolId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : TeamPool.fromJson(data);
    }).handleError((error, stack) => throw AppError.fromError(error, stack));
  }

  /// Creates the pool when [poolId] is new, otherwise updates its details.
  Future<void> savePool({
    required String poolId,
    required String userId,
    required String name,
    String? shortName,
    String? logo,
    bool isNew = true,
  }) async {
    try {
      final trimmedName = name.trim();
      final duplicates = await _pools
          .where(FireStoreConst.createdBy, isEqualTo: userId)
          .where(FireStoreConst.nameLowercase,
              isEqualTo: trimmedName.caseAndSpaceInsensitive,)
          .get();
      if (duplicates.docs.any((doc) => doc.id != poolId)) {
        throw AppError(
          l10nCode: AppErrorL10nCodes.duplicatePoolName,
          message: 'A pool named "$trimmedName" already exists.',
        );
      }
      final details = {
        FireStoreConst.name: trimmedName,
        FireStoreConst.nameLowercase: trimmedName.caseAndSpaceInsensitive,
        FireStoreConst.shortName:
            (shortName?.trim().isEmpty ?? true) ? null : shortName!.trim(),
        FireStoreConst.logo: logo,
      };
      if (isNew) {
        await _pools.doc(poolId).set({
          ...details,
          FireStoreConst.id: poolId,
          FireStoreConst.createdBy: userId,
          FireStoreConst.createdAt: DateTime.now().toIso8601String(),
          FireStoreConst.teamIds: [],
        });
      } else {
        await _pools.doc(poolId).update(details);
      }
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<List<String>> _teamIdsInPool(String poolId) async {
    final snapshot =
        await _teams.where(FireStoreConst.poolId, isEqualTo: poolId).get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// Number of distinct tournaments that use any team of the pool.
  Future<int> poolUsageCount(String poolId) async {
    try {
      final teamIds = await _teamIdsInPool(poolId);
      final tournamentIds = <String>{};
      for (final chunk in teamIds.chunked(30)) {
        final snapshot = await _firestore
            .collection(FireStoreConst.tournamentCollection)
            .where(FireStoreConst.teamIds, arrayContainsAny: chunk)
            .get();
        tournamentIds.addAll(snapshot.docs.map((doc) => doc.id));
      }
      return tournamentIds.length;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Deletes the pool and its team docs; player user docs are kept.
  Future<void> deletePool(String poolId) async {
    try {
      final usage = await poolUsageCount(poolId);
      if (usage > 0) {
        throw AppError(
          l10nCode: AppErrorL10nCodes.poolUsedInTournament,
          message: 'This pool is used in $usage tournament(s).',
        );
      }
      final teamIds = await _teamIdsInPool(poolId);
      final batch = _firestore.batch();
      for (final teamId in teamIds) {
        batch.delete(_teams.doc(teamId));
      }
      batch.delete(_pools.doc(poolId));
      await batch.commit();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Moves [team] into [poolId], keeping both pools' `team_ids` in sync.
  Future<void> moveTeamToPool(TournamentTeam team, String poolId) async {
    try {
      if (team.poolId == poolId) return;
      await _ensureNameAvailable(
        team.createdBy ?? '',
        team.name,
        poolId: poolId,
        excludeTeamId: team.id,
      );
      final batch = _firestore.batch()
        ..update(_teams.doc(team.id), {FireStoreConst.poolId: poolId})
        ..update(_pools.doc(poolId), {
          FireStoreConst.teamIds: FieldValue.arrayUnion([team.id]),
        });
      if (team.poolId != null) {
        batch.update(_pools.doc(team.poolId), {
          FireStoreConst.teamIds: FieldValue.arrayRemove([team.id]),
        });
      }
      await batch.commit();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Records which pool a tournament's teams were picked from.
  Future<void> setTournamentPool(String tournamentId, String? poolId) async {
    try {
      await _firestore
          .collection(FireStoreConst.tournamentCollection)
          .doc(tournamentId)
          .update({FireStoreConst.poolId: poolId});
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Stream<TournamentTeam?> streamTeam(String teamId) {
    return _teams.doc(teamId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : TournamentTeam.fromJson(data);
    }).handleError((error, stack) => throw AppError.fromError(error, stack));
  }

  Future<List<TournamentTeamPlayer>> getPlayers(TournamentTeam team) async {
    try {
      if (team.playerIds.isEmpty) return [];
      final players = <TournamentTeamPlayer>[];
      for (final ids in team.playerIds.chunked(10)) {
        final snapshot =
            await _users.where(FieldPath.documentId, whereIn: ids).get();
        players.addAll(snapshot.docs.map((doc) =>
            TournamentTeamPlayer.fromUserJson(
                {...doc.data(), FireStoreConst.id: doc.id},
                teamId: team.id,),),);
      }
      final order = {
        for (var i = 0; i < team.playerIds.length; i++) team.playerIds[i]: i,
      };
      players.sort((a, b) => order[a.id]!.compareTo(order[b.id]!));
      return players;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Team names are unique within a pool; teams without a pool are compared
  /// with each other.
  Future<void> _ensureNameAvailable(
    String userId,
    String name, {
    required String? poolId,
    String? excludeTeamId,
  }) async {
    final snapshot = await _poolQuery(userId)
        .where(FireStoreConst.nameLowercase,
            isEqualTo: name.caseAndSpaceInsensitive,)
        .get();
    if (snapshot.docs.any((doc) =>
        doc.id != excludeTeamId &&
        doc.data()[FireStoreConst.poolId] == poolId,)) {
      throw AppError(
        l10nCode: AppErrorL10nCodes.duplicateTeamName,
        message: 'A team named "$name" already exists.',
      );
    }
  }

  /// Creates the team when [teamId] is new, otherwise updates its details.
  Future<void> saveTeam({
    required String teamId,
    required String userId,
    required String name,
    required String? poolId,
    String? shortName,
    String? logo,
    bool isNew = true,
  }) async {
    try {
      final trimmedName = name.trim();
      await _ensureNameAvailable(
        userId,
        trimmedName,
        poolId: poolId,
        excludeTeamId: teamId,
      );
      final details = {
        FireStoreConst.name: trimmedName,
        FireStoreConst.nameLowercase: trimmedName.caseAndSpaceInsensitive,
        FireStoreConst.nameInitial:
            (shortName?.trim().isEmpty ?? true) ? null : shortName!.trim(),
        FireStoreConst.profileImageUrl: logo,
      };
      if (isNew) {
        final now = DateTime.now();
        final batch = _firestore.batch()
          ..set(_teams.doc(teamId), {
            ...details,
            FireStoreConst.id: teamId,
            FireStoreConst.createdBy: userId,
            FireStoreConst.createdAt: now.toIso8601String(),
            FireStoreConst.createdTime: Timestamp.fromDate(now),
            FireStoreConst.teamPlayers: [],
            FireStoreConst.isTournamentTeam: true,
            FireStoreConst.captainId: null,
            FireStoreConst.wicketKeeperId: null,
            FireStoreConst.poolId: poolId,
          });
        if (poolId != null) {
          batch.update(_pools.doc(poolId), {
            FireStoreConst.teamIds: FieldValue.arrayUnion([teamId]),
          });
        }
        await batch.commit();
      } else {
        await _teams.doc(teamId).update(details);
      }
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<void> setCaptain(String teamId, String? playerId) =>
      _updateField(teamId, FireStoreConst.captainId, playerId);

  Future<void> setWicketKeeper(String teamId, String? playerId) =>
      _updateField(teamId, FireStoreConst.wicketKeeperId, playerId);

  Future<void> _updateField(String teamId, String field, Object? value) async {
    try {
      await _teams.doc(teamId).update({field: value});
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<int> tournamentUsageCount(String teamId) async {
    try {
      final snapshot = await _firestore
          .collection(FireStoreConst.tournamentCollection)
          .where(FireStoreConst.teamIds, arrayContains: teamId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<void> deleteTeam(TournamentTeam team) async {
    try {
      final usage = await tournamentUsageCount(team.id);
      if (usage > 0) {
        throw AppError(
          l10nCode: AppErrorL10nCodes.teamUsedInTournament,
          message: 'This team is used in $usage tournament(s).',
        );
      }
      final batch = _firestore.batch()..delete(_teams.doc(team.id));
      if (team.poolId != null) {
        batch.update(_pools.doc(team.poolId), {
          FireStoreConst.teamIds: FieldValue.arrayRemove([team.id]),
        });
      }
      await batch.commit();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  void _ensureUniquePlayer(
    TournamentTeamPlayer player,
    List<TournamentTeamPlayer> existing,
  ) {
    final others = existing.where((p) => p.id != player.id);
    final name = player.name.trim().toLowerCase();
    if (others.any((p) => p.name.trim().toLowerCase() == name)) {
      throw AppError(
        l10nCode: AppErrorL10nCodes.duplicatePlayerName,
        message: '${player.name} is already in this team.',
      );
    }
    if (player.jerseyNumber != null &&
        others.any((p) => p.jerseyNumber == player.jerseyNumber)) {
      throw AppError(
        l10nCode: AppErrorL10nCodes.duplicateJerseyNumber,
        message: 'Jersey #${player.jerseyNumber} is already taken.',
      );
    }
  }

  Future<TournamentTeamPlayer> addPlayer({
    required TournamentTeamPlayer player,
    required List<TournamentTeamPlayer> existing,
    required String createdBy,
  }) async {
    try {
      _ensureUniquePlayer(player, existing);
      final userRef = _users.doc();
      final created = player.copyWith(id: userRef.id);
      final batch = _firestore.batch()
        ..set(userRef, {
          ...created.toUserJson(),
          FireStoreConst.createdBy: createdBy,
          FireStoreConst.createdAt: DateTime.now().toIso8601String(),
        })
        ..update(_teams.doc(player.teamId), {
          FireStoreConst.teamPlayers: FieldValue.arrayUnion([
            TeamPlayer(id: userRef.id).toJson(),
          ]),
        });
      await batch.commit();
      return created;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<void> updatePlayer({
    required TournamentTeamPlayer player,
    required List<TournamentTeamPlayer> existing,
  }) async {
    try {
      _ensureUniquePlayer(player, existing);
      await _users.doc(player.id).update(player.toUserJson());
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Removes the player from the team only; the user document is kept so
  /// past match scorecards still resolve the player's name.
  Future<void> removePlayer(TournamentTeam team, String playerId) async {
    try {
      await _teams.doc(team.id).update({
        FireStoreConst.teamPlayers: FieldValue.arrayRemove(
          TeamPlayerRole.values
              .map((role) => TeamPlayer(id: playerId, role: role).toJson())
              .toList(),
        ),
        if (team.captainId == playerId) FireStoreConst.captainId: null,
        if (team.wicketKeeperId == playerId)
          FireStoreConst.wicketKeeperId: null,
      });
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }
}
