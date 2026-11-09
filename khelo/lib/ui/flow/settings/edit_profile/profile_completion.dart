import 'package:data/api/user/user_models.dart';
import 'package:data/service/user/user_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in player's private mobile number (`user_private/{uid}`).
final currentUserPhoneProvider = StreamProvider.autoDispose<String?>((ref) {
  final userId = ref.watch(currentUserPod.select((user) => user?.id));
  if (userId == null) return Stream.value(null);
  return ref.watch(userServiceProvider).streamPrivatePhone(userId);
});

/// True when a signed-in player still has to fill Create Profile; false when
/// done or signed out; null while the mobile number is loading.
final profileIncompleteProvider = Provider.autoDispose<bool?>((ref) {
  final user = ref.watch(currentUserPod);
  if (user == null) return false;
  final phone = ref.watch(currentUserPhoneProvider);
  if (phone.isLoading && !phone.hasValue) return null;
  // A failed read (offline) shouldn't lock the player out.
  if (phone.hasError) return !hasProfileName(user);
  return !isProfileComplete(user, phone.valueOrNull);
});

bool hasProfileName(UserModel user) =>
    (user.name?.trim().length ?? 0) >= ProfileRules.minNameLength;

/// Name and mobile are required. Phone sign-in accounts already have a
/// number on their public profile.
bool isProfileComplete(UserModel user, String? privatePhone) =>
    hasProfileName(user) &&
    ((privatePhone?.isNotEmpty ?? false) || (user.phone?.isNotEmpty ?? false));

class ProfileRules {
  static const minNameLength = 2;
}
