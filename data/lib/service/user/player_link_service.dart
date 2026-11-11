import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/tournament_team/squad_clash.dart';
import '../../api/user/player_claim.dart';
import '../../api/user/user_models.dart';
import '../../errors/app_error.dart';
import '../../errors/app_error_l10n_codes.dart';
import '../../utils/constant/firestore_constant.dart';

final playerLinkServiceProvider = Provider(
  (ref) => PlayerLinkService(FirebaseFirestore.instance),
);

/// Finds players by mobile number and links an organizer-added player to the
/// account of the person who later signs up with that number.
///
/// Numbers live only in `phone_index/{hash}` (`user_id`, `created_by`); the
/// public `users` docs never hold them.
class PlayerLinkService {
  final FirebaseFirestore _db;

  PlayerLinkService(this._db);

  static const _phoneIndex = 'phone_index';
  static const _claims = 'player_claims';
  static const _batchLimit = 400;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FireStoreConst.usersCollection);

  /// Index key for an E.164 number such as `+94771234567`.
  static String phoneKey(String e164) {
    final normalized = e164.replaceAll(RegExp(r'[^\d+]'), '');
    return sha256.convert(utf8.encode('sportstamil:$normalized')).toString();
  }

  // ── Number lookup ────────────────────────────────────────────────────────

  /// The player holding [e164]. A number whose player was deleted or merged
  /// away counts as free.
  Future<String?> playerIdForPhone(String e164) async {
    try {
      final doc = await _db.collection(_phoneIndex).doc(phoneKey(e164)).get();
      final id = doc.data()?['user_id'] as String?;
      if (id == null || id.isEmpty) return null;
      return (await _users.doc(id).get()).exists ? id : null;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<UserModel?> findPlayerByPhone(String e164) async {
    final id = await playerIdForPhone(e164);
    if (id == null) return null;
    final doc = await _users.doc(id).get();
    final data = doc.data();
    return data == null ? null : UserModel.fromJson(data);
  }

  /// Creates a player owned by [organizerId] with a private number, or returns
  /// the existing player with that number (`existing: true`).
  Future<({UserModel user, bool existing})> createPlayerWithPhone({
    required String name,
    required String e164,
    required String organizerId,
  }) async {
    final existing = await findPlayerByPhone(e164);
    if (existing != null) return (user: existing, existing: true);
    try {
      final ref = _users.doc();
      final trimmed = name.trim();
      final user = UserModel(
        id: ref.id,
        name: trimmed,
        name_lowercase: trimmed.toLowerCase(),
        created_at: DateTime.now(),
      );
      final batch = _db.batch()
        ..set(ref, {...user.toJson(), 'created_by': organizerId});
      addPhoneEntry(
        _db,
        batch,
        userId: ref.id,
        e164: e164,
        createdBy: organizerId,
      );
      await batch.commit();
      return (user: user, existing: false);
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Adds the index entry for a player created in the same [batch].
  static void addPhoneEntry(
    FirebaseFirestore db,
    WriteBatch batch, {
    required String userId,
    required String e164,
    required String createdBy,
  }) {
    batch.set(db.collection(_phoneIndex).doc(phoneKey(e164)), {
      'user_id': userId,
      'created_by': createdBy,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Gives a player the organizer added (and has no number yet) [e164].
  /// Throws when the number already belongs to another player.
  Future<void> linkPlayerPhone({
    required String playerId,
    required String e164,
    required String organizerId,
  }) async {
    final owner = await playerIdForPhone(e164);
    if (owner == playerId) return;
    if (owner != null) {
      throw const AppError(
        message: 'This number already belongs to another player.',
      );
    }
    try {
      final batch = _db.batch();
      addPhoneEntry(
        _db,
        batch,
        userId: playerId,
        e164: e164,
        createdBy: organizerId,
      );
      await batch.commit();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Points the signed-up user's own number at their account, unless another
  /// player already holds it (that one can be claimed instead). Frees the old
  /// number when it changed.
  Future<void> registerOwnPhone({
    required String userId,
    required String e164,
    String? previousE164,
  }) async {
    try {
      final ref = _db.collection(_phoneIndex).doc(phoneKey(e164));
      if (await playerIdForPhone(e164) == null) {
        await ref.set({
          'user_id': userId,
          'created_by': userId,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      if (previousE164 != null && phoneKey(previousE164) != phoneKey(e164)) {
        final old = _db.collection(_phoneIndex).doc(phoneKey(previousE164));
        final oldDoc = await old.get();
        if (oldDoc.data()?['user_id'] == userId) await old.delete();
      }
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  // ── Claims ───────────────────────────────────────────────────────────────

  /// The organizer-added player holding [e164], if the signed-in user hasn't
  /// answered for it yet.
  Future<ClaimablePlayer?> findClaimable({
    required String userId,
    required String e164,
  }) async {
    try {
      final playerId = await playerIdForPhone(e164);
      if (playerId == null || playerId == userId) return null;
      final claim = await _db
          .collection(_claims)
          .doc(PlayerClaim.idFor(playerId, userId))
          .get();
      if (claim.exists) return null;
      final player = (await _users.doc(playerId).get()).data();
      final organizerId = player?['created_by'] as String?;
      if (player == null || organizerId == null || organizerId.isEmpty) {
        return null;
      }
      final teams = await _teamsWithPlayer(playerId).count().get();
      final matches = await _db
          .collection(FireStoreConst.matchesCollection)
          .where(FireStoreConst.players, arrayContains: playerId)
          .count()
          .get();
      return ClaimablePlayer(
        playerId: playerId,
        playerName: player['name'] as String? ?? '',
        photoUrl: player['profile_img_url'] as String?,
        organizerId: organizerId,
        teams: teams.count ?? 0,
        matches: matches.count ?? 0,
      );
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<void> answerClaim({
    required ClaimablePlayer player,
    required UserModel claimant,
    required String e164,
    required bool isMe,
  }) async {
    try {
      final id = PlayerClaim.idFor(player.playerId, claimant.id);
      final claim = PlayerClaim(
        id: id,
        playerId: player.playerId,
        playerName: player.playerName,
        claimantId: claimant.id,
        claimantName: claimant.name ?? '',
        organizerId: player.organizerId,
        status: isMe ? PlayerClaimStatus.pending : PlayerClaimStatus.dismissed,
        phoneKey: phoneKey(e164),
      );
      await _db.collection(_claims).doc(id).set({
        ...claim.toJson(),
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Stream<List<PlayerClaim>> streamRequestsForOrganizer(String organizerId) {
    return _db
        .collection(_claims)
        .where('organizer_id', isEqualTo: organizerId)
        .where('status', isEqualTo: PlayerClaimStatus.pending.name)
        .snapshots()
        .map((s) => s.docs.map((d) => PlayerClaim.fromJson(d.data())).toList())
        .handleError((error, stack) => throw AppError.fromError(error, stack));
  }

  Stream<List<PlayerClaim>> streamMyClaims(String claimantId) {
    return _db
        .collection(_claims)
        .where('claimant_id', isEqualTo: claimantId)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => PlayerClaim.fromJson(d.data()))
              .where((c) => c.status != PlayerClaimStatus.dismissed)
              .toList(),
        )
        .handleError((error, stack) => throw AppError.fromError(error, stack));
  }

  Future<void> declineClaim(PlayerClaim claim) async {
    try {
      await _db.collection(_claims).doc(claim.id).update({
        'status': PlayerClaimStatus.declined.name,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Moves everything of the added player to the claimant's account, then
  /// marks the claim approved. Runs on the organizer's device.
  Future<void> approveClaim(PlayerClaim claim) async {
    try {
      final player = await _users.doc(claim.playerId).get();
      if (!player.exists) {
        throw const AppError(
          message: 'This player is already linked to an account.',
        );
      }
      await mergePlayer(
        from: claim.playerId,
        to: claim.claimantId,
        phoneKey: claim.phoneKey,
        claimId: claim.id,
      );
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  // ── Merge ────────────────────────────────────────────────────────────────

  /// Folds [duplicateId], a player [organizerId] added, into [playerId], the
  /// player who holds the number: teams, matches and stats move over and the
  /// duplicate is deleted. Its own number (if any) becomes free.
  Future<void> mergeDuplicateInto({
    required String duplicateId,
    required String playerId,
    required String organizerId,
  }) async {
    if (duplicateId == playerId) return;
    try {
      final duplicate = (await _users.doc(duplicateId).get()).data();
      if (duplicate == null || duplicate['created_by'] != organizerId) {
        throw const AppError(
          l10nCode: AppErrorL10nCodes.mergeNotAllowed,
          message: 'Only the organizer who added this player can merge it.',
        );
      }
      await _ensureMergeKeepsOneTeam(
        duplicateId: duplicateId,
        playerId: playerId,
      );
      await mergePlayer(from: duplicateId, to: playerId);
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Refuses a merge that would put [playerId] in two teams of a tournament
  /// (or twice in one team).
  Future<void> _ensureMergeKeepsOneTeam({
    required String duplicateId,
    required String playerId,
  }) async {
    final player = (await _users.doc(playerId).get()).data();
    final playerName = player?['name'] as String? ?? '';
    final duplicateTeams = await _teamsWithPlayer(duplicateId).get();
    final playerTeams = {
      for (final doc in (await _teamsWithPlayer(playerId).get()).docs)
        doc.id: doc.data()[FireStoreConst.name] as String? ?? '',
    };
    if (playerTeams.isEmpty) return;
    for (final doc in duplicateTeams.docs) {
      if (playerTeams.containsKey(doc.id)) {
        throw PlayerTeamClashError(
          playerName: playerName,
          teamName: playerTeams[doc.id]!,
        );
      }
    }
    final duplicateTeamIds = duplicateTeams.docs.map((d) => d.id).toList();
    for (final chunk in _chunks(duplicateTeamIds, 30)) {
      final tournaments = await _db
          .collection(FireStoreConst.tournamentCollection)
          .where(FireStoreConst.teamIds, arrayContainsAny: chunk)
          .get();
      for (final tournament in tournaments.docs) {
        final teamIds =
            (tournament.data()[FireStoreConst.teamIds] as List? ?? const [])
                .whereType<String>();
        final clash = teamIds.where(playerTeams.containsKey).firstOrNull;
        if (clash != null) {
          throw PlayerTeamClashError(
            playerName: playerName,
            teamName: playerTeams[clash]!,
            tournamentName: tournament.data()[FireStoreConst.name] as String?,
          );
        }
      }
    }
  }

  Query<Map<String, dynamic>> _teamsWithPlayer(String playerId) =>
      _db.collection(FireStoreConst.teamsCollection).where(
        FireStoreConst.teamPlayers,
        arrayContainsAny: [
          for (final role in ['admin', 'player'])
            {'id': playerId, 'role': role},
        ],
      );

  /// Replaces [from] with [to] in every team, match, innings, ball, event,
  /// partnership and tournament it appears in, and moves its stats, leaderboard
  /// rows and phone number. Finally deletes the [from] user.
  ///
  /// The claim approval, number move and delete commit in one batch: the
  /// `phone_index` rule only lets the number move with an approved claim.
  Future<void> mergePlayer({
    required String from,
    required String to,
    String? phoneKey,
    String? claimId,
  }) async {
    final writer = _BatchWriter(_db, _batchLimit);
    final seen = <String>{};

    Future<void> rewrite(DocumentSnapshot<Map<String, dynamic>> doc) async {
      if (!seen.add(doc.reference.path)) return;
      final data = doc.data();
      if (data == null) return;
      final (updated, changed) = _swapIds(data, from, to);
      if (changed) await writer.set(doc.reference, updated);
    }

    final teams = await _teamsWithPlayer(from).get();
    for (final doc in teams.docs) {
      await rewrite(doc);
    }

    final matches = await _db
        .collection(FireStoreConst.matchesCollection)
        .where(FireStoreConst.players, arrayContains: from)
        .get();
    final matchIds = <String>[];
    final tournamentIds = <String>{};
    for (final doc in matches.docs) {
      matchIds.add(doc.id);
      final tournamentId = doc.data()['tournament_id'] as String?;
      if (tournamentId != null && tournamentId.isNotEmpty) {
        tournamentIds.add(tournamentId);
      }
      await rewrite(doc);
    }

    for (final collection in [
      FireStoreConst.inningsCollection,
      FireStoreConst.ballScoresCollection,
      FireStoreConst.partnershipsCollection,
      FireStoreConst.matchEventsCollection,
    ]) {
      for (final chunk in _chunks(matchIds, 30)) {
        final snapshot = await _db
            .collection(collection)
            .where(FireStoreConst.matchId, whereIn: chunk)
            .get();
        for (final doc in snapshot.docs) {
          await rewrite(doc);
        }
      }
    }

    final teamIds = teams.docs.map((d) => d.id).toList();
    for (final chunk in _chunks(teamIds, 30)) {
      final snapshot = await _db
          .collection(FireStoreConst.tournamentCollection)
          .where(FireStoreConst.teamIds, arrayContainsAny: chunk)
          .get();
      tournamentIds.addAll(snapshot.docs.map((d) => d.id));
    }
    final memberTournaments =
        await _db.collection(FireStoreConst.tournamentCollection).where(
      FireStoreConst.members,
      arrayContainsAny: [
        for (final role in ['organizer', 'admin']) {'id': from, 'role': role},
      ],
    ).get();
    tournamentIds.addAll(memberTournaments.docs.map((d) => d.id));

    for (final id in tournamentIds) {
      final ref = _db.collection(FireStoreConst.tournamentCollection).doc(id);
      await rewrite(await ref.get());
      await _moveDoc(
        writer,
        ref.collection(FireStoreConst.tournamentPlayerKeyStatsCollection),
        from,
        to,
      );
    }

    for (final type in [
      FireStoreConst.allTimeDocument,
      FireStoreConst.weeklyDocument,
      FireStoreConst.monthlyDocument,
    ]) {
      await _moveDoc(
        writer,
        _db
            .collection(FireStoreConst.leaderboardCollection)
            .doc(type)
            .collection(FireStoreConst.dataCollection),
        from,
        to,
      );
    }

    await _mergeStats(writer, from, to);
    await writer.commit();

    final finish = _db.batch();
    if (claimId != null) {
      finish.update(_db.collection(_claims).doc(claimId), {
        'status': PlayerClaimStatus.approved.name,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    if (phoneKey != null) {
      finish.update(_db.collection(_phoneIndex).doc(phoneKey), {
        'user_id': to,
        'created_by': to,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    finish.delete(_users.doc(from));
    await finish.commit();
  }

  /// Moves `collection/{from}` to `collection/{to}`, adding up numbers when
  /// `{to}` already exists.
  Future<void> _moveDoc(
    _BatchWriter writer,
    CollectionReference<Map<String, dynamic>> collection,
    String from,
    String to,
  ) async {
    final source = await collection.doc(from).get();
    final data = source.data();
    if (data == null) return;
    final target = (await collection.doc(to).get()).data();
    final (moved, _) = _swapIds(data, from, to);
    await writer.set(
      collection.doc(to),
      target == null ? moved : _sumNumbers(target, moved),
    );
    await writer.delete(source.reference);
  }

  Future<void> _mergeStats(_BatchWriter writer, String from, String to) async {
    final fromStats = await _users
        .doc(from)
        .collection(FireStoreConst.userStatCollection)
        .get();
    for (final doc in fromStats.docs) {
      final targetRef = _users
          .doc(to)
          .collection(FireStoreConst.userStatCollection)
          .doc(doc.id);
      final target = await targetRef.get();
      final incoming = UserStat.fromJson(doc.data());
      final merged = target.exists
          ? UserStat.fromJson(target.data()!).updateStat(incoming)
          : incoming;
      await writer.set(targetRef, merged.toJson());
      await writer.delete(doc.reference);
    }
  }

  static Iterable<List<String>> _chunks(List<String> ids, int size) sync* {
    for (var i = 0; i < ids.length; i += size) {
      yield ids.sublist(i, i + size > ids.length ? ids.length : i + size);
    }
  }

  /// Deep copy of [value] with every string (and map key) equal to [from]
  /// replaced by [to]. Player ids are random 20+ character strings, so other
  /// values can't match by accident.
  static (Map<String, dynamic>, bool) _swapIds(
    Map<String, dynamic> value,
    String from,
    String to,
  ) {
    var changed = false;
    Object? swap(Object? v) {
      if (v is String) {
        if (v == from) {
          changed = true;
          return to;
        }
        return v;
      }
      if (v is List) return v.map(swap).toList();
      if (v is Map) {
        return {
          for (final e in v.entries)
            (swap(e.key) as String? ?? e.key.toString()): swap(e.value),
        };
      }
      return v;
    }

    final result = swap(value) as Map<String, dynamic>;
    return (result, changed);
  }

  static Map<String, dynamic> _sumNumbers(
    Map<String, dynamic> base,
    Map<String, dynamic> extra,
  ) {
    final result = Map<String, dynamic>.from(base);
    extra.forEach((key, value) {
      final current = result[key];
      if (current is num && value is num) {
        result[key] = current + value;
      } else if (current is Timestamp && value is Timestamp) {
        result[key] = current.compareTo(value) >= 0 ? current : value;
      } else {
        result.putIfAbsent(key, () => value);
      }
    });
    return result;
  }
}

class _BatchWriter {
  final FirebaseFirestore _db;
  final int _limit;
  WriteBatch? _batch;
  int _count = 0;

  _BatchWriter(this._db, this._limit);

  Future<void> set(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    (_batch ??= _db.batch()).set(ref, data);
    await _maybeCommit();
  }

  Future<void> delete(DocumentReference<Map<String, dynamic>> ref) async {
    (_batch ??= _db.batch()).delete(ref);
    await _maybeCommit();
  }

  Future<void> _maybeCommit() async {
    if (++_count >= _limit) await commit();
  }

  Future<void> commit() async {
    final batch = _batch;
    _batch = null;
    _count = 0;
    await batch?.commit();
  }
}
