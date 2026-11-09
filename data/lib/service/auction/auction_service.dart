import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/auction/auction_models.dart';
import '../../api/team/team_model.dart';
import '../../api/tournament/tournament_model.dart';
import '../../errors/app_error.dart';
import '../../extensions/string_extensions.dart';
import '../../utils/constant/firestore_constant.dart';

final auctionServiceProvider =
    Provider((ref) => AuctionService(FirebaseFirestore.instance));

/// Firestore access for player auctions.
///
/// Every change re-reads the auction inside a transaction, checks the caller
/// is one of its admins, applies a pure [Auction] method and appends a log
/// entry, so simultaneous admins can't double-sell or double-bid.
/// Queries use single-field filters only (no composite indexes).
class AuctionService {
  static const _auctionsCollection = 'auctions';
  static const _logCollection = 'log';
  static const _photosCollection = 'photos';

  /// Firestore allows 500 writes per transaction; generation needs a few
  /// extra for the tournament, pool, teams and the auction itself.
  static const _maxGeneratedPlayers = 450;

  final FirebaseFirestore _firestore;

  AuctionService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _auctions =>
      _firestore.collection(_auctionsCollection);

  CollectionReference<Map<String, dynamic>> get _photos =>
      _firestore.collection(_photosCollection);

  CollectionReference<Map<String, dynamic>> _log(String auctionId) =>
      _auctions.doc(auctionId).collection(_logCollection);

  String newId() => _auctions.doc().id;

  // ── Streams ──────────────────────────────────────────────────────────────

  Stream<Auction?> streamAuction(String auctionId) => _auctions
      .doc(auctionId)
      .snapshots()
      .map((doc) => doc.data() == null ? null : Auction.fromJson(doc.data()!))
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  /// Upcoming, live, paused and completed auctions; readable signed out.
  Stream<List<Auction>> streamPublishedAuctions() => _auctions
      .where(
        'status',
        whereIn: AuctionStatus.published.map((s) => s.value).toList(),
      )
      .snapshots()
      .map(_sorted)
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  /// Auctions the user administers, drafts included.
  Stream<List<Auction>> streamAdminAuctions(String userId) => _auctions
      .where('admin_ids', arrayContains: userId)
      .snapshots()
      .map(_sorted)
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  Stream<List<AuctionLogEntry>> streamLog(String auctionId, {int limit = 40}) =>
      _log(auctionId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) =>
              s.docs.map((d) => AuctionLogEntry.fromJson(d.data())).toList(),)
          .handleError(
            (error, stack) => throw AppError.fromError(error, stack),
          );

  Stream<Uint8List?> streamPhoto(String photoId) => _photos
      .doc(photoId)
      .snapshots()
      .map((doc) => (doc.data()?['data'] as Blob?)?.bytes)
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  List<Auction> _sorted(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((doc) => Auction.fromJson(doc.data())).toList()
        ..sort((a, b) => (b.auctionDate ?? b.createdAt)
            .compareTo(a.auctionDate ?? a.createdAt),);

  // ── Setup ────────────────────────────────────────────────────────────────

  Future<void> createAuction(Auction auction) async {
    try {
      final batch = _firestore.batch()
        ..set(_auctions.doc(auction.id), auction.toJson());
      _addLog(batch.set, auction.id, AuctionLogType.created, auction.createdBy);
      await batch.commit();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Saves the details form onto the latest version of the auction. Teams
  /// can only change before the auction starts.
  Future<void> saveDetails(String auctionId, String userId, Auction details) =>
      _update(auctionId, userId, (auction) {
        var updated = auction.copyWith(
          name: details.name,
          tournamentName: details.tournamentName,
          description: details.description,
          auctionDate: details.auctionDate,
          teamBudget: details.teamBudget,
          basePrice: details.basePrice,
          bidIncrement: details.bidIncrement,
          minSquad: details.minSquad,
          maxSquad: details.maxSquad,
          showBudgets: details.showBudgets,
          adminIds: userId == auction.createdBy ? details.adminIds : null,
        );
        if (auction.status.isSetup) updated = updated.setTeams(details.teams);
        return (updated, null);
      });

  /// Returns how many players were skipped as duplicates.
  Future<int> upsertPlayers(
    String auctionId,
    String userId,
    List<AuctionPlayer> players,
  ) async {
    var skipped = 0;
    await _update(auctionId, userId, (auction) {
      final (updated, duplicates) = auction.upsertPlayers(players);
      skipped = duplicates;
      return (updated, null);
    });
    return skipped;
  }

  Future<void> removePlayer(String auctionId, String userId, String playerId) =>
      _update(
        auctionId,
        userId,
        (auction) => (auction.removePlayer(playerId), null),
      );

  Future<void> retain({
    required String auctionId,
    required String userId,
    required String playerId,
    required String teamId,
    required int price,
  }) =>
      _update(
        auctionId,
        userId,
        (auction) => (
          auction.retain(playerId, teamId, price),
          _entry(AuctionLogType.retained,
              playerId: playerId, teamId: teamId, amount: price,),
        ),
      );

  Future<void> release(String auctionId, String userId, String playerId) =>
      _update(
        auctionId,
        userId,
        (auction) => (
          auction.release(playerId),
          _entry(AuctionLogType.released, playerId: playerId),
        ),
      );

  /// Uploads compressed photos (one `photos` doc per player) and bumps each
  /// player's photo version so screens reload them.
  Future<void> uploadPlayerPhotos(
    String auctionId,
    String userId,
    Map<String, Uint8List> photosByPlayerId,
  ) async {
    final entries = photosByPlayerId.entries.toList();
    final version = DateTime.now().millisecondsSinceEpoch;
    try {
      // Requests are capped at 10 MiB; ~60 KB photos stay well under it.
      for (var i = 0; i < entries.length; i += 25) {
        final batch = _firestore.batch();
        for (final entry in entries.skip(i).take(25)) {
          batch.set(_photos.doc(entry.key), _photoJson(auctionId, userId, entry.value));
        }
        await batch.commit();
      }
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
    await _update(auctionId, userId, (auction) {
      var updated = auction;
      for (final entry in entries) {
        updated = updated.setPhotoVersion(entry.key, version);
      }
      return (updated, null);
    });
  }

  Future<void> uploadBanner(
    String auctionId,
    String userId,
    Uint8List bytes,
  ) async {
    try {
      await _photos
          .doc('banner_$auctionId')
          .set(_photoJson(auctionId, userId, bytes));
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
    await _update(
      auctionId,
      userId,
      (auction) => (
        auction.copyWith(bannerVersion: DateTime.now().millisecondsSinceEpoch),
        null,
      ),
    );
  }

  Map<String, dynamic> _photoJson(
    String auctionId,
    String userId,
    Uint8List bytes,
  ) =>
      {
        'data': Blob(bytes),
        'auction_id': auctionId,
        'created_by': userId,
        'updated_at': FieldValue.serverTimestamp(),
      };

  /// Deletes the auction, its history and photos. The generated tournament,
  /// if any, is kept.
  Future<void> deleteAuction(String auctionId) async {
    try {
      final photos =
          await _photos.where('auction_id', isEqualTo: auctionId).get();
      final log = await _log(auctionId).get();
      final refs = [
        ...photos.docs.map((d) => d.reference),
        ...log.docs.map((d) => d.reference),
      ];
      for (var i = 0; i < refs.length; i += 400) {
        final batch = _firestore.batch();
        for (final ref in refs.skip(i).take(400)) {
          batch.delete(ref);
        }
        await batch.commit();
      }
      await _auctions.doc(auctionId).delete();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  // ── Running ──────────────────────────────────────────────────────────────

  Future<void> publish(String auctionId, String userId) => _simple(
        auctionId,
        userId,
        (a) => a.publish(),
        AuctionLogType.published,
      );

  Future<void> unpublish(String auctionId, String userId) =>
      _simple(auctionId, userId, (a) => a.unpublish(), null);

  Future<void> start(String auctionId, String userId) =>
      _simple(auctionId, userId, (a) => a.start(), AuctionLogType.started);

  Future<void> pause(String auctionId, String userId) =>
      _simple(auctionId, userId, (a) => a.pause(), AuctionLogType.paused);

  Future<void> resume(String auctionId, String userId) =>
      _simple(auctionId, userId, (a) => a.resume(), AuctionLogType.resumed);

  Future<void> showPlayer(String auctionId, String userId, String playerId) =>
      _simple(auctionId, userId, (a) => a.showPlayer(playerId), AuctionLogType.shown);

  Future<void> nextPlayer(String auctionId, String userId) =>
      _simple(auctionId, userId, (a) => a.nextPlayer(), AuctionLogType.shown);

  Future<void> previousPlayer(String auctionId, String userId) =>
      _simple(auctionId, userId, (a) => a.previousPlayer(), AuctionLogType.shown);

  Future<void> startBidding(String auctionId, String userId) => _simple(
        auctionId,
        userId,
        (a) => a.startBidding(),
        AuctionLogType.biddingStarted,
      );

  Future<void> placeBid({
    required String auctionId,
    required String userId,
    required String teamId,
    required int amount,
  }) =>
      _update(auctionId, userId, (auction) {
        final updated = auction.placeBid(teamId, amount);
        return (
          updated,
          _entry(AuctionLogType.bid,
              playerId: auction.currentPlayerId, teamId: teamId, amount: amount,),
        );
      });

  Future<void> undoBid(String auctionId, String userId) =>
      _update(auctionId, userId, (auction) {
        final undone = auction.leadingBid;
        return (
          auction.undoBid(),
          _entry(AuctionLogType.bidUndone,
              playerId: auction.currentPlayerId,
              teamId: undone?.teamId,
              amount: undone?.amount,),
        );
      });

  Future<void> sell(String auctionId, String userId) =>
      _update(auctionId, userId, (auction) {
        return (
          auction.sell(),
          _entry(AuctionLogType.sold,
              playerId: auction.currentPlayerId,
              teamId: auction.leadingTeamId,
              amount: auction.currentBid,),
        );
      });

  Future<void> markUnsold(String auctionId, String userId) =>
      _update(auctionId, userId, (auction) {
        return (
          auction.markUnsold(),
          _entry(AuctionLogType.unsold, playerId: auction.currentPlayerId),
        );
      });

  Future<void> reopenUnsold(String auctionId, String userId) => _simple(
        auctionId,
        userId,
        (a) => a.reopenUnsold(),
        AuctionLogType.reopened,
      );

  // ── Completion + tournament ──────────────────────────────────────────────

  /// Completes the auction and creates its tournament in one transaction:
  /// the tournament (no matches, no fixtures), a team pool, one team per
  /// auction team and one player per sold / retained player.
  ///
  /// All generated ids derive from the auction, and the tournament doc is
  /// read first, so a retry after a failure (or a second admin pressing the
  /// button) can never create a duplicate. Returns the tournament id.
  Future<String> completeAndGenerateTournament(
    String auctionId,
    String userId, {
    bool markRemainingUnsold = false,
  }) async {
    final ids = _GeneratedIds(auctionId);
    try {
      final before = await _auctions.doc(auctionId).get();
      final beforeData = before.data();
      if (beforeData == null) {
        throw const AuctionActionException(AuctionError.notLive);
      }
      final poolName = await _availablePoolName(Auction.fromJson(beforeData));

      return await _firestore.runTransaction((tx) async {
        final auctionRef = _auctions.doc(auctionId);
        final data = (await tx.get(auctionRef)).data();
        if (data == null) {
          throw const AuctionActionException(AuctionError.notLive);
        }
        final auction = Auction.fromJson(data);
        if (!auction.isAdmin(userId)) {
          throw const AuctionActionException(AuctionError.notAdmin);
        }
        final tournamentRef = _firestore
            .collection(FireStoreConst.tournamentCollection)
            .doc(ids.tournament);
        final tournamentExists = (await tx.get(tournamentRef)).exists;

        if (tournamentExists) {
          // Generated earlier; make sure the auction points at it.
          if (auction.tournamentId != ids.tournament) {
            tx.update(auctionRef, {'tournament_id': ids.tournament});
          }
          return ids.tournament;
        }

        final now = DateTime.now();
        final completed = auction.status == AuctionStatus.completed
            ? auction
            : auction.complete(
                now: now,
                markRemainingUnsold: markRemainingUnsold,
              );
        final onTeams = completed.players.where((p) => p.status.isOnTeam).toList();
        if (onTeams.length > _maxGeneratedPlayers) {
          throw const AuctionActionException(AuctionError.tooManyPlayers);
        }

        _writeTournament(tx, completed, ids, poolName, now);
        tx.set(
          auctionRef,
          completed.withTournament(ids.tournament).toJson(),
        );
        final logRef = _log(auctionId).doc();
        tx.set(
          logRef,
          _entry(AuctionLogType.completed)(userId, now, logRef.id).toJson(),
        );
        return ids.tournament;
      });
    } on AuctionActionException {
      rethrow;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Pool names are unique per organizer; pick "{name} Teams", adding the
  /// auction name if that is already taken.
  Future<String> _availablePoolName(Auction auction) async {
    final candidates = [
      '${auction.tournamentName} Teams',
      '${auction.tournamentName} Teams (${auction.name})',
      '${auction.tournamentName} Teams (${auction.id.substring(0, 5)})',
    ];
    final pools = _firestore.collection(FireStoreConst.teamPoolsCollection);
    for (final name in candidates) {
      final taken = await pools
          .where(FireStoreConst.createdBy, isEqualTo: auction.createdBy)
          .where(FireStoreConst.nameLowercase,
              isEqualTo: name.caseAndSpaceInsensitive,)
          .get();
      if (taken.docs.every((d) => d.id == _GeneratedIds(auction.id).pool)) {
        return name;
      }
    }
    return candidates.last;
  }

  void _writeTournament(
    Transaction tx,
    Auction auction,
    _GeneratedIds ids,
    String poolName,
    DateTime now,
  ) {
    final owner = auction.createdBy;
    final teamsRef = _firestore.collection(FireStoreConst.teamsCollection);
    final usersRef = _firestore.collection(FireStoreConst.usersCollection);
    final teamIds = auction.teams.map((t) => ids.team(t.id)).toList();

    tx.set(
      _firestore.collection(FireStoreConst.teamPoolsCollection).doc(ids.pool),
      {
        FireStoreConst.id: ids.pool,
        FireStoreConst.name: poolName,
        FireStoreConst.nameLowercase: poolName.caseAndSpaceInsensitive,
        FireStoreConst.shortName: null,
        FireStoreConst.logo: null,
        FireStoreConst.createdBy: owner,
        FireStoreConst.createdAt: now.toIso8601String(),
        FireStoreConst.teamIds: teamIds,
        'auction_id': auction.id,
      },
    );

    for (final team in auction.teams) {
      final squad = auction.squadOf(team.id);
      for (final player in squad) {
        tx.set(usersRef.doc(ids.player(player.id)), {
          FireStoreConst.id: ids.player(player.id),
          FireStoreConst.name: player.name,
          FireStoreConst.nameLowercase: player.name.toLowerCase(),
          FireStoreConst.playerRole: player.role?.playerRole.value,
          FireStoreConst.jerseyNumber: player.number,
          FireStoreConst.createdBy: owner,
          FireStoreConst.createdAt: now.toIso8601String(),
          'photo_id': player.hasPhoto ? player.id : null,
          'auction_id': auction.id,
          'auction_player_code': player.code,
          'auction_status': player.status.value,
          'auction_price': player.price,
        });
      }
      tx.set(teamsRef.doc(ids.team(team.id)), {
        FireStoreConst.id: ids.team(team.id),
        FireStoreConst.name: team.name,
        FireStoreConst.nameLowercase: team.name.caseAndSpaceInsensitive,
        FireStoreConst.nameInitial: team.initials.toUpperCase(),
        FireStoreConst.profileImageUrl: null,
        FireStoreConst.createdBy: owner,
        FireStoreConst.createdAt: now.toIso8601String(),
        FireStoreConst.createdTime: Timestamp.fromDate(now),
        FireStoreConst.teamPlayers: [
          for (final player in squad) TeamPlayer(id: ids.player(player.id)).toJson(),
        ],
        FireStoreConst.isTournamentTeam: true,
        FireStoreConst.captainId: null,
        FireStoreConst.wicketKeeperId: null,
        FireStoreConst.poolId: ids.pool,
        'auction_id': auction.id,
      });
    }

    final date = auction.auctionDate ?? now;
    final tournament = TournamentModel(
      id: ids.tournament,
      name: auction.tournamentName,
      type: TournamentType.custom,
      created_by: owner,
      created_at: now,
      start_date: date,
      end_date: date,
      team_ids: teamIds,
      members: [
        TournamentMember(id: owner, role: TournamentMemberRole.organizer),
        for (final admin in auction.adminIds.where((a) => a != owner))
          TournamentMember(id: admin, role: TournamentMemberRole.admin),
      ],
    );
    tx.set(
      _firestore.collection(FireStoreConst.tournamentCollection).doc(ids.tournament),
      {
        ...tournament.toJson(),
        FireStoreConst.poolId: ids.pool,
        'auction_id': auction.id,
        'schedule_status': 'not_scheduled',
      },
    );
  }

  // ── Plumbing ─────────────────────────────────────────────────────────────

  Future<void> _simple(
    String auctionId,
    String userId,
    Auction Function(Auction) apply,
    AuctionLogType? logType,
  ) =>
      _update(auctionId, userId, (auction) {
        final updated = apply(auction);
        return (
          updated,
          logType == null
              ? null
              : _entry(logType, playerId: updated.currentPlayerId),
        );
      });

  _LogBuilder _entry(
    AuctionLogType type, {
    String? playerId,
    String? teamId,
    int? amount,
  }) =>
      (by, at, id) => AuctionLogEntry(
            id: id,
            type: type,
            playerId: playerId,
            teamId: teamId,
            amount: amount,
            byUserId: by,
            createdAt: at,
          );

  void _addLog(
    void Function(DocumentReference<Map<String, dynamic>>, Map<String, dynamic>)
        set,
    String auctionId,
    AuctionLogType type,
    String userId,
  ) {
    final ref = _log(auctionId).doc();
    set(ref, _entry(type)(userId, DateTime.now(), ref.id).toJson());
  }

  Future<void> _update(
    String auctionId,
    String userId,
    (Auction, _LogBuilder?) Function(Auction auction) apply,
  ) async {
    try {
      await _firestore.runTransaction((tx) async {
        final ref = _auctions.doc(auctionId);
        final data = (await tx.get(ref)).data();
        if (data == null) {
          throw const AuctionActionException(AuctionError.notLive);
        }
        final auction = Auction.fromJson(data);
        if (!auction.isAdmin(userId)) {
          throw const AuctionActionException(AuctionError.notAdmin);
        }
        final (updated, log) = apply(auction);
        tx.set(ref, updated.toJson());
        if (log != null) {
          final logRef = _log(auctionId).doc();
          tx.set(logRef, log(userId, DateTime.now(), logRef.id).toJson());
        }
      });
    } on AuctionActionException {
      rethrow;
    } catch (error, stack) {
      if (error is AuctionActionException) rethrow;
      throw AppError.fromError(error, stack);
    }
  }
}

typedef _LogBuilder = AuctionLogEntry Function(
  String byUserId,
  DateTime at,
  String id,
);

/// Deterministic ids for everything generated from one auction.
class _GeneratedIds {
  final String auctionId;

  const _GeneratedIds(this.auctionId);

  String get tournament => 'auction_$auctionId';

  String get pool => 'auction_$auctionId';

  String team(String auctionTeamId) => 'auction_${auctionId}_$auctionTeamId';

  String player(String auctionPlayerId) =>
      'auction_${auctionId}_$auctionPlayerId';
}
