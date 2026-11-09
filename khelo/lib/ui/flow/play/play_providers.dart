import 'package:data/api/play/play_match.dart';
import 'package:data/api/play/play_models.dart';
import 'package:data/service/auth/auth_service.dart';
import 'package:data/service/play/play_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/image/profile_photo.dart';

import '../../../domain/play/cricket_game.dart';

/// Who is playing: the signed-in user, or a guest whose scores are saved
/// under [PlayGame.guestName].
class PlayIdentity {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isGuest;

  const PlayIdentity({
    required this.id,
    required this.name,
    this.imageUrl,
    this.isGuest = false,
  });
}

final playIdentityProvider = Provider<PlayIdentity?>((ref) {
  final user = ref.watch(currentUserPod);
  if (user != null) {
    return PlayIdentity(
      id: user.id,
      name: user.name ?? '',
      imageUrl: ProfilePhoto.shareable(user.profile_img_url),
    );
  }
  final guestId = ref.watch(guestUserIdProvider).valueOrNull;
  if (guestId == null) return null;
  return PlayIdentity(id: guestId, name: PlayGame.guestName, isGuest: true);
});

final todayChallengeProvider = Provider.autoDispose<DailyChallenge>(
  (ref) => DailyChallenge.forDate(DateTime.now()),
);

final playRecentGamesProvider =
    StreamProvider.autoDispose<List<PlayGame>>((ref) {
  final userId = ref.watch(playIdentityProvider)?.id;
  if (userId == null) return Stream.value(const []);
  return ref.watch(playServiceProvider).streamRecentGames(userId);
});

final playDailyGamesProvider =
    StreamProvider.autoDispose<List<PlayGame>>((ref) {
  final dateKey = ref.watch(todayChallengeProvider).dateKey;
  return ref.watch(playServiceProvider).streamDailyGames(dateKey);
});

final playWeeklyGamesProvider =
    StreamProvider.autoDispose<List<PlayGame>>((ref) {
  final now = DateTime.now();
  final weekStart =
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  // Live matches can be longer than 2 overs, so they don't rank here.
  return ref.watch(playServiceProvider).streamGamesSince(weekStart).map(
      (games) => games.where((game) => game.mode != PlayMode.match).toList());
});

/// Guests can't send or receive challenges.
final playChallengesProvider =
    StreamProvider.autoDispose<List<PlayChallenge>>((ref) {
  final identity = ref.watch(playIdentityProvider);
  if (identity == null || identity.isGuest) return Stream.value(const []);
  return ref.watch(playServiceProvider).streamChallenges(identity.id);
});

/// Live 1v1 matches I sent or received, newest first. Guests can't play them.
final playMatchesProvider = StreamProvider.autoDispose<List<PlayMatch>>((ref) {
  final identity = ref.watch(playIdentityProvider);
  if (identity == null || identity.isGuest) return Stream.value(const []);
  return ref.watch(playServiceProvider).streamMatches(identity.id);
});

final playMatchProvider = StreamProvider.autoDispose.family<PlayMatch?, String>(
  (ref, id) => ref.watch(playServiceProvider).streamMatch(id),
);

final playOnlineProvider = StreamProvider.autoDispose<List<PlayPresence>>(
  (ref) => ref.watch(playServiceProvider).streamOnline(),
);

/// Every game I played, for XP, streaks and badges.
final playAllGamesProvider = StreamProvider.autoDispose<List<PlayGame>>((ref) {
  final userId = ref.watch(playIdentityProvider)?.id;
  if (userId == null) return Stream.value(const []);
  return ref.watch(playServiceProvider).streamAllGames(userId);
});

extension PlayMatchGame on PlayMatch {
  MatchFormat get format => MatchFormat(overs, wickets);

  /// [number] 1 or 2; the second innings chases the first's score + 1.
  Innings innings(int number) => Innings.replay(
        seed: seed,
        target: number == 2 ? innings(1).runs + 1 : null,
        format: format,
        balls: (number == 1 ? innings1 : innings2)
            .map((ball) => (shotFromName(ball.result), ball.offset))
            .toList(),
      );
}

ShotResult shotFromName(String name) =>
    ShotResult.values.where((shot) => shot.name == name).firstOrNull ??
    ShotResult.dot;

List<PlayBall> ballsOf(Innings innings) => [
      for (var i = 0; i < innings.balls; i++)
        PlayBall(innings.results[i].name, innings.offsets[i]),
    ];
