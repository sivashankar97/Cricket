import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchPermissions {
  final bool manage;
  final bool score;
  final String? activeScorerId;
  final String? activeScorerName;
  final DateTime? activeScorerAt;

  const MatchPermissions({
    this.manage = false,
    this.score = false,
    this.activeScorerId,
    this.activeScorerName,
    this.activeScorerAt,
  });

  /// True when another user holds an active scoring lock (heartbeat < 3 min).
  bool isLockedByOther(String? currentUserId) {
    if (activeScorerId == null || activeScorerId == currentUserId) {
      return false;
    }
    if (activeScorerAt != null &&
        DateTime.now().difference(activeScorerAt!) > const Duration(minutes: 3)) {
      return false;
    }
    return true;
  }
}

/// Watches assignments and active scorer lock so removing a scorer or simultaneous scoring
/// updates controls in real time.
final matchPermissionsProvider =
    StreamProvider.autoDispose.family<MatchPermissions, String>((ref, id) {
  final uid = ref.watch(currentUserPod)?.id;
  if (uid == null) return Stream.value(const MatchPermissions());
  final db = FirebaseFirestore.instance;
  return db
      .collection('matches')
      .doc(id)
      .snapshots()
      .asyncMap((snapshot) async {
    final data = snapshot.data();
    if (data == null) return const MatchPermissions();
    var owner = data['created_by'];
    final tournamentId = data['tournament_id'];
    if (tournamentId is String && tournamentId.isNotEmpty) {
      final tournament =
          await db.collection('tournaments').doc(tournamentId).get();
      owner = tournament.data()?['created_by'];
    }
    final manage = owner == uid;
    final active = data['active_scorer'] as Map<String, dynamic>?;
    final activeId = active?['id'] as String?;
    final activeName = active?['name'] as String?;
    final activeAt = (active?['updated_at'] as Timestamp?)?.toDate();

    return MatchPermissions(
      manage: manage,
      score: manage || ((data['scorer_ids'] as List?)?.contains(uid) ?? false),
      activeScorerId: activeId,
      activeScorerName: activeName,
      activeScorerAt: activeAt,
    );
  });
});

Future<void> claimActiveScorer({
  required String matchId,
  required String userId,
  required String userName,
}) async {
  try {
    await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
      'active_scorer': {
        'id': userId,
        'name': userName,
        'updated_at': FieldValue.serverTimestamp(),
      },
    });
  } catch (_) {}
}

Future<void> releaseActiveScorer({
  required String matchId,
  required String userId,
}) async {
  try {
    final doc =
        await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
    final active = doc.data()?['active_scorer'] as Map<String, dynamic>?;
    if (active?['id'] == userId) {
      await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
        'active_scorer': null,
      });
    }
  } catch (_) {}
}
