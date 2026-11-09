import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/play/play_models.dart';
import '../../errors/app_error.dart';

final playServiceProvider =
    Provider((ref) => PlayService(FirebaseFirestore.instance));

/// Firestore access for the Play tab mini game. Queries use single-field
/// filters only (no composite indexes); sorting happens in the app.
class PlayService {
  static const _gamesCollection = 'play_games';
  static const _challengesCollection = 'play_challenges';

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
