import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/play/play_match.dart';
import '../../api/play/play_models.dart';
import '../../errors/app_error.dart';

final playServiceProvider =
    Provider((ref) => PlayService(FirebaseFirestore.instance));

/// Firestore access for the Play tab mini game. Queries use single-field
/// filters only (no composite indexes); sorting happens in the app.
class PlayService {
  static const _gamesCollection = 'play_games';
  static const _challengesCollection = 'play_challenges';
  static const _matchesCollection = 'play_matches';
  static const _presenceCollection = 'play_presence';

  final FirebaseFirestore _firestore;

  PlayService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _games =>
      _firestore.collection(_gamesCollection);

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _firestore.collection(_challengesCollection);

  String newGameId() => _games.doc().id;

  Future<void> saveGame(PlayGame game) async {
    try {
      await _games.doc(game.id).set(game.toJson());
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<PlayChallenge> createChallenge(
    PlayChallenge Function(String id) build,
  ) async {
    try {
      final challenge = build(_challenges.doc().id);
      await _challenges.doc(challenge.id).set(challenge.toJson());
      return challenge;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<void> completeChallenge({
    required String challengeId,
    required PlayScore opponentScore,
    required String? winnerId,
  }) async {
    try {
      await _challenges.doc(challengeId).update({
        'opponent_score': opponentScore.toJson(),
        'status': PlayChallengeStatus.completed.value,
        'winner_id': winnerId,
        'completed_at': Timestamp.now(),
      });
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Stream<List<PlayGame>> streamRecentGames(
    String userId, {
    int limit = 10,
  }) =>
      _games
          .where('user_id', isEqualTo: userId)
          .snapshots()
          .map(
            (snapshot) => (snapshot.docs
                    .map((doc) => PlayGame.fromJson(doc.data()))
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
                .take(limit)
                .toList(),
          )
          .handleError(
            (error, stack) => throw AppError.fromError(error, stack),
          );

  Stream<List<PlayGame>> streamGamesSince(DateTime since) => _games
      .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => PlayGame.fromJson(doc.data())).toList(),
      )
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  Stream<List<PlayGame>> streamDailyGames(String dateKey) => _games
      .where('daily_date', isEqualTo: dateKey)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => PlayGame.fromJson(doc.data())).toList(),
      )
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  // ── Live 1v1 matches ─────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection(_matchesCollection);

  Future<PlayMatch> createMatch(PlayMatch Function(String id) build) async {
    try {
      final match = build(_matches.doc().id);
      await _matches.doc(match.id).set({
        ...match.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return match;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Stream<PlayMatch?> streamMatch(String id) => _matches
      .doc(id)
      .snapshots()
      .map((doc) => doc.data() == null ? null : PlayMatch.fromJson(doc.data()!))
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  /// Newest first.
  Stream<List<PlayMatch>> streamMatches(String userId) => _matches
      .where('participant_ids', arrayContains: userId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => PlayMatch.fromJson(doc.data())).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      )
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  /// Applies [changes] only while the match is in one of [from]; returns
  /// false when someone else changed it first (e.g. cancelled while accepting).
  Future<bool> _transition(
    String id, {
    required Set<PlayMatchStatus> from,
    required Map<String, dynamic> Function(PlayMatch match) changes,
    bool Function(PlayMatch match)? when,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final ref = _matches.doc(id);
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (data == null) return false;
        final match = PlayMatch.fromJson(data);
        if (!from.contains(match.status)) return false;
        if (when != null && !when(match)) return false;
        transaction.update(ref, {
          ...changes(match),
          'updated_at': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<bool> acceptMatch(String id) => _transition(
        id,
        from: {PlayMatchStatus.requested},
        changes: (_) => {'status': PlayMatchStatus.toss.value},
      );

  Future<bool> declineMatch(String id) => _transition(
        id,
        from: {PlayMatchStatus.requested},
        changes: (_) => {'status': PlayMatchStatus.declined.value},
      );

  Future<bool> cancelMatch(String id) => _transition(
        id,
        from: {PlayMatchStatus.requested},
        changes: (_) => {'status': PlayMatchStatus.cancelled.value},
      );

  /// The guest calls; [winnerId] follows from the seed's coin.
  Future<bool> callToss(
    String id, {
    required String call,
    required String winnerId,
  }) =>
      _transition(
        id,
        from: {PlayMatchStatus.toss},
        when: (match) => match.tossCall == null,
        changes: (_) => {'toss_call': call, 'toss_winner_id': winnerId},
      );

  Future<bool> chooseBattingFirst(String id, {required String batterId}) =>
      _transition(
        id,
        from: {PlayMatchStatus.toss},
        when: (match) => match.tossWinnerId != null,
        changes: (_) => {
          'batting_first_id': batterId,
          'status': PlayMatchStatus.live.value,
          'current_innings': 1,
        },
      );

  /// Saves every ball of [innings] so far (the batter's app calls this after
  /// each ball; lists are written whole because array-union drops repeats).
  Future<void> saveBalls(
    String id, {
    required int innings,
    required List<PlayBall> balls,
  }) async {
    try {
      await _matches.doc(id).update({
        'innings_$innings': balls.map((ball) => ball.toJson()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<bool> startSecondInnings(String id) => _transition(
        id,
        from: {PlayMatchStatus.live},
        when: (match) => match.currentInnings == 1,
        changes: (_) => {'current_innings': 2},
      );

  Future<bool> completeMatch(
    String id, {
    required String? winnerId,
    required PlayMatchResultType resultType,
    required int margin,
  }) =>
      _transition(
        id,
        from: {PlayMatchStatus.toss, PlayMatchStatus.live},
        changes: (_) => {
          'status': PlayMatchStatus.completed.value,
          'winner_id': winnerId,
          'result_type': resultType.value,
          'margin': margin,
        },
      );

  Future<void> markSeen(String id, String userId) async {
    try {
      await _matches
          .doc(id)
          .update({'last_seen.$userId': FieldValue.serverTimestamp()});
    } catch (_) {
      // A missed heartbeat only delays the "online" signal.
    }
  }

  /// Saves both players' games once, keyed by match and player, so a retry
  /// or the other player's app can't add duplicates.
  Future<void> saveMatchGames(List<PlayGame> games) async {
    try {
      final batch = _firestore.batch();
      for (final game in games) {
        batch.set(_games.doc(game.id), game.toJson());
      }
      await batch.commit();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Stream<List<PlayGame>> streamAllGames(String userId) => _games
      .where('user_id', isEqualTo: userId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => PlayGame.fromJson(doc.data())).toList(),
      )
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  // ── Presence ─────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _presence =>
      _firestore.collection(_presenceCollection);

  Future<void> updatePresence({
    required String userId,
    required String name,
    String? image,
  }) async {
    try {
      await _presence.doc(userId).set({
        'user_id': userId,
        'name': name,
        'image': image,
        'last_seen': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Presence is best effort.
    }
  }

  Stream<List<PlayPresence>> streamOnline() => _presence
      .where(
        'last_seen',
        isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime.now().subtract(PlayPresence.onlineWindow),
        ),
      )
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => PlayPresence.fromJson(doc.data()))
            .toList(),
      )
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  Stream<List<PlayChallenge>> streamChallenges(String userId) => _challenges
      .where('participant_ids', arrayContains: userId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => PlayChallenge.fromJson(doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      )
      .handleError((error, stack) => throw AppError.fromError(error, stack));
}
