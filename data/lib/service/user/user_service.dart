import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/user/user_models.dart';
import '../../errors/app_error.dart';
import '../../extensions/list_extensions.dart';
import '../../storage/app_preferences.dart';
import '../../utils/constant/firestore_constant.dart';
import '../../utils/dummy_deactivated_account.dart';
import '../device/device_service.dart';

final userServiceProvider = Provider((ref) {
  final service = UserService(
    ref.read(currentUserPod),
    FirebaseFirestore.instance,
    ref.read(deviceServiceProvider),
  );

  ref.listen(currentUserPod, (_, next) => service._currentUser = next);
  return service;
});

class UserService {
  UserModel? _currentUser;

  final FirebaseFirestore firestore;
  final DeviceService deviceService;

  UserService(
    this._currentUser,
    this.firestore,
    this.deviceService,
  );

  CollectionReference<UserModel> get _userRef => firestore
      .collection(FireStoreConst.usersCollection)
      .withConverter<UserModel>(
        fromFirestore: UserModel.fromFireStore,
        toFirestore: (user, options) => user.toJson(),
      );

  CollectionReference _sessionRef(String userId) => _userRef
      .doc(userId)
      .collection(FireStoreConst.userSessionCollection)
      .withConverter<ApiSession>(
        fromFirestore: ApiSession.fromFireStore,
        toFirestore: (session, _) => session.toJson(),
      );

  CollectionReference<UserStat> _userStatsRef(String userId) => _userRef
      .doc(userId)
      .collection(FireStoreConst.userStatCollection)
      .withConverter(
        fromFirestore: UserStat.fromFireStore,
        toFirestore: (userStat, _) => userStat.toJson(),
      );

  Future<void> clearSession({
    required String uid,
    required String sessionId,
  }) async {
    await _sessionRef(uid).doc(sessionId).delete();
  }

  Future<ApiSession> _createSession(String userId) async {
    final sessionDocRef = _sessionRef(userId).doc();
    final session = ApiSession(
      id: sessionDocRef.id,
      user_id: userId,
      device_type: deviceService.currentPlatformType(),
      device_id: deviceService.deviceId,
      device_name: await deviceService.deviceName,
      app_version: await deviceService.appVersion,
      os_version: await deviceService.osVersion,
      created_at: DateTime.now(),
    );

    await sessionDocRef.set(session);
    return session;
  }

  Future<(UserModel, ApiSession)> upsertUser({
    required String uid,
    required String phone,
    String? email,
  }) async {
    var user = await getUser(uid);
    user ??= await _createUser(uid, phone: phone, email: email);
    if ((user.email == null || user.email!.isEmpty) &&
        email != null &&
        email.isNotEmpty) {
      user = user.copyWith(email: email, updated_at: DateTime.now());
      await updateUser(user);
    }
    final session = await _createSession(uid);
    return (user, session);
  }

  Future<UserModel?> getUser(String id) async {
    try {
      final snapshot = await _userRef.doc(id).get();
      return (snapshot.exists) ? snapshot.data() : null;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];
      final chunks = await Future.wait(
        ids.toSet().toList().chunked(30).map((chunkIds) async {
          final snapshot =
              await _userRef.where(FireStoreConst.id, whereIn: chunkIds).get();
          final found = {
            for (final doc in snapshot.docs) doc.data().id: doc.data(),
          };
          return [
            ...found.values,
            ...chunkIds
                .where((id) => !found.containsKey(id))
                .map(deActiveDummyUserAccount),
          ];
        }),
      );
      return chunks.expand((users) => users).toList();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Stream<UserModel> streamUserById(String id) {
    return _userRef.doc(id).snapshots().map((snapshot) {
      final userModel = snapshot.data();
      if (userModel == null) {
        return deActiveDummyUserAccount(id);
      }
      return userModel;
    }).handleError((error, stack) {
      throw AppError.fromError(error, stack);
    });
  }

  Stream<List<UserStat>?> streamUserStats(String userId) {
    return _userStatsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.isEmpty
          ? null
          : snapshot.docs.map((e) => e.data()).toList();
    }).handleError((error, stack) => throw AppError.fromError(error, stack));
  }

  Future<UserStat?> getUserStats(String userId, UserStatType type) async {
    try {
      final snapshot = await _userStatsRef(userId)
          .where(FireStoreConst.type, isEqualTo: type.name)
          .limit(1)
          .get();
      return snapshot.docs.isEmpty ? null : snapshot.docs.first.data();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final userRef = _userRef.doc(user.id);
      await userRef.set(user, SetOptions(merge: true));
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Owner-only contact details (`user_private/{uid}`); the `users` doc is
  /// public, so the mobile number is kept out of it.
  DocumentReference<Map<String, dynamic>> _privateRef(String userId) =>
      firestore.collection(FireStoreConst.userPrivateCollection).doc(userId);

  Stream<String?> streamPrivatePhone(String userId) => _privateRef(userId)
      .snapshots()
      .map((doc) => doc.data()?[FireStoreConst.phone] as String?)
      .handleError((error, stack) => throw AppError.fromError(error, stack));

  Future<void> savePrivatePhone(String userId, String phone) async {
    try {
      await _privateRef(userId).set(
        {
          FireStoreConst.phone: phone,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<void> updateUserStats(String userId, UserStat stats) async {
    try {
      final userStatsRef = _userStatsRef(userId);

      await userStatsRef
          .doc(stats.type?.name)
          .set(stats, SetOptions(merge: true));
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<UserModel> _createUser(
    String userId, {
    required String phone,
    String? email,
  }) async {
    final trimmedPhone = phone.trim();
    final user = UserModel(
      id: userId,
      phone: trimmedPhone.isEmpty ? null : trimmedPhone,
      email: email,
      created_at: DateTime.now(),
    );
    await _userRef.doc(userId).set(user);
    return user;
  }

  Future<UserModel> createPlayer({
    required String name,
    String? phone,
  }) async {
    try {
      final docRef = _userRef.doc();
      final trimmedName = name.trim();
      final trimmedPhone = phone?.trim() ?? '';
      final user = UserModel(
        id: docRef.id,
        name: trimmedName,
        name_lowercase: trimmedName.toLowerCase(),
        phone: trimmedPhone.isEmpty ? null : trimmedPhone,
        created_at: DateTime.now(),
      );
      // created_by marks profiles made by an organizer rather than by sign-up.
      await firestore
          .collection(FireStoreConst.usersCollection)
          .doc(docRef.id)
          .set({...user.toJson(), 'created_by': _currentUser?.id});
      return user;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<void> deleteUser() async {
    try {
      final id = _currentUser?.id;
      if (id != null) await _privateRef(id).delete();
      await _userRef.doc(id).delete();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Name-prefix search. Ordered by name, then document id, which the
  /// automatic single-field index serves (no composite index needed).
  Future<List<UserModel>> searchUser(
    String searchKey, {
    int limit = 20,
    UserModel? after,
  }) async {
    try {
      final key = searchKey.trim().toLowerCase();
      var query = _userRef
          .where(FireStoreConst.nameLowercase, isGreaterThanOrEqualTo: key)
          .where(FireStoreConst.nameLowercase, isLessThan: '$key\uf8ff')
          .orderBy(FireStoreConst.nameLowercase)
          .orderBy(FieldPath.documentId);

      if (after != null) {
        query = query.startAfter([after.name_lowercase ?? '', after.id]);
      }

      query = query.limit(limit);
      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return doc.data();
      }).toList();
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<void> registerDevice(
    String sessionId, {
    required String userId,
    required String deviceToken,
  }) async {
    await _sessionRef(userId).doc(sessionId).update({
      FireStoreConst.deviceFcmToken: deviceToken,
    });
  }

  Future<void> updateUserNotificationSettings(
    String id,
    bool notifications,
  ) async {
    await _userRef
        .doc(id)
        .update({FireStoreConst.notifications: notifications});
  }
}
