import 'package:data/api/play/play_models.dart';
import 'package:data/service/auth/auth_service.dart';
import 'package:data/service/play/play_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      imageUrl: user.profile_img_url,
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
  return ref.watch(playServiceProvider).streamGamesSince(weekStart);
});

/// Guests can't send or receive challenges.
final playChallengesProvider =
    StreamProvider.autoDispose<List<PlayChallenge>>((ref) {
  final identity = ref.watch(playIdentityProvider);
  if (identity == null || identity.isGuest) return Stream.value(const []);
  return ref.watch(playServiceProvider).streamChallenges(identity.id);
});
