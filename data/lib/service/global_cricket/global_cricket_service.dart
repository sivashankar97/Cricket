import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../api/global_cricket/global_cricket_models.dart';
import '../../errors/app_error.dart';

final globalCricketServiceProvider =
    Provider((ref) => GlobalCricketService(FirebaseFirestore.instance));

/// Why a full scorecard isn't shown.
enum ScorecardBlock { none, notStarted, signedOut, dailyLimit }

/// International and premier-league scores from CricketData.org (free tier:
/// 100 hits a day for the whole app). Every client reads shared Firestore
/// docs; a signed-in client refreshes them, so usage doesn't grow with users.
///
/// Costs: the `cricScore` feed is 1 hit, a `match_scorecard` is 10 hits.
class GlobalCricketService {
  static const _collection = 'global_cricket';
  static const _feedDocId = 'current_matches';
  static const refreshEvery = Duration(minutes: 30);
  static const liveScorecardRefreshEvery = Duration(hours: 1);
  static const _lockFor = Duration(minutes: 1);
  static const scorecardCost = 10;
  static const dailyLimit = 100;

  final FirebaseFirestore _firestore;

  GlobalCricketService(this._firestore);

  DocumentReference<Map<String, dynamic>> get _feedDoc =>
      _firestore.collection(_collection).doc(_feedDocId);

  DocumentReference<Map<String, dynamic>> _scorecardDoc(String matchId) =>
      _firestore
          .collection(_collection)
          .doc('scorecards')
          .collection('matches')
          .doc(matchId);

  Stream<GlobalCricketFeed> streamFeed() => _feedDoc.snapshots().map((doc) {
        final data = doc.data();
        return data == null
            ? GlobalCricketFeed.empty
            : GlobalCricketFeed.fromJson(data);
      }).handleError((error, stack) => throw AppError.fromError(error, stack));

  Stream<GlobalScorecard?> streamScorecard(String matchId) =>
      _scorecardDoc(matchId).snapshots().map((doc) {
        final data = doc.data();
        return data == null ? null : GlobalScorecard.fromJson(data);
      }).handleError((error, stack) => throw AppError.fromError(error, stack));

  /// Fetches fresh scores when the cache is older than [refreshEvery] and no
  /// other client is already fetching. Needs a signed-in user (rules).
  Future<void> refreshIfStale(String apiKey) async {
    if (apiKey.isEmpty) return;
    try {
      final claimed = await _claim(_feedDoc, (data, now) {
        final fetchedAt = (data?['fetched_at'] as Timestamp?)?.toDate();
        return fetchedAt == null || now.difference(fetchedAt) >= refreshEvery;
      });
      if (!claimed) return;

      final body = await _get('cricScore', {'apikey': apiKey});
      if (body['status'] != 'success') {
        // Still stamp fetched_at so a bad key or used-up quota isn't retried
        // on every Home open; the old matches stay visible.
        await _feedDoc.set(
          {
            'fetched_at': Timestamp.now(),
            'last_error': body['reason']?.toString() ?? 'Request failed',
          },
          SetOptions(merge: true),
        );
        return;
      }

      final matches = ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => GlobalMatch.fromCricScore(Map<String, dynamic>.from(e)))
          .nonNulls
          .map((e) => e.toJson())
          .toList();
      await _feedDoc.set(
        {
          'matches': matches,
          'fetched_at': Timestamp.now(),
          'last_error': null,
          ..._hits(body),
        },
        SetOptions(merge: true),
      );
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// Fetches the full scorecard when there is none yet, when a cached live
  /// one is older than [liveScorecardRefreshEvery], or when a cached live one
  /// has since finished. Returns why it was skipped, if it was blocked.
  Future<ScorecardBlock> refreshScorecardIfNeeded({
    required String apiKey,
    required GlobalMatch match,
  }) async {
    if (match.isUpcoming) return ScorecardBlock.notStarted;
    if (apiKey.isEmpty) return ScorecardBlock.none;
    try {
      var block = ScorecardBlock.none;
      final claimed = await _firestore.runTransaction((tx) async {
        final now = DateTime.now();
        final cached = (await tx.get(_scorecardDoc(match.id))).data();
        final lockUntil = (cached?['lock_until'] as Timestamp?)?.toDate();
        if (lockUntil != null && lockUntil.isAfter(now)) return false;
        if (cached != null && cached['id'] != null) {
          final card = GlobalScorecard.fromJson(cached);
          final age = now.difference(card.fetchedAt ?? DateTime(0));
          final stale = !card.ended &&
              (match.isResult || age >= liveScorecardRefreshEvery);
          if (!stale) return false;
        }

        final feed = (await tx.get(_feedDoc)).data();
        if (!canAffordScorecard(
          hitsToday: _hitsToday(feed, now),
          now: now,
        )) {
          block = ScorecardBlock.dailyLimit;
          return false;
        }
        tx.set(
          _scorecardDoc(match.id),
          {'lock_until': Timestamp.fromDate(now.add(_lockFor))},
          SetOptions(merge: true),
        );
        return true;
      });
      if (!claimed) return block;

      final body = await _get('match_scorecard', {
        'apikey': apiKey,
        'id': match.id,
      });
      await _feedDoc.set(_hits(body), SetOptions(merge: true));
      if (body['status'] != 'success' || body['data'] is! Map) {
        await _scorecardDoc(match.id).set(
          {
            'lock_until': Timestamp.fromDate(
              DateTime.now().add(liveScorecardRefreshEvery),
            ),
            'last_error': body['reason']?.toString() ?? 'Request failed',
          },
          SetOptions(merge: true),
        );
        return ScorecardBlock.dailyLimit;
      }

      final card = GlobalScorecard.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
      await _scorecardDoc(match.id).set({
        ...card.toJson(),
        'fetched_at': Timestamp.now(),
        'lock_until': null,
        'last_error': null,
      });
      return ScorecardBlock.none;
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  /// A scorecard (10 hits) is allowed only while enough hits stay free for
  /// the feed refreshes left before the quota resets at UTC midnight.
  static bool canAffordScorecard({
    required int hitsToday,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    final midnight = DateTime.utc(utc.year, utc.month, utc.day + 1);
    final feedCallsLeft =
        (midnight.difference(utc).inMinutes / refreshEvery.inMinutes).ceil();
    return hitsToday + scorecardCost + feedCallsLeft <= dailyLimit;
  }

  Future<bool> _claim(
    DocumentReference<Map<String, dynamic>> doc,
    bool Function(Map<String, dynamic>? data, DateTime now) needsRefresh,
  ) =>
      _firestore.runTransaction((tx) async {
        final data = (await tx.get(doc)).data();
        final now = DateTime.now();
        final lockUntil = (data?['lock_until'] as Timestamp?)?.toDate();
        if (!needsRefresh(data, now)) return false;
        if (lockUntil != null && lockUntil.isAfter(now)) return false;
        tx.set(
          doc,
          {'lock_until': Timestamp.fromDate(now.add(_lockFor))},
          SetOptions(merge: true),
        );
        return true;
      });

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final response =
        await http.get(Uri.https('api.cricapi.com', '/v1/$path', query));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static String _utcDay(DateTime time) =>
      time.toUtc().toIso8601String().substring(0, 10);

  Map<String, dynamic> _hits(Map<String, dynamic> body) {
    final info = body['info'] as Map?;
    if (info?['hitsToday'] == null) return const {};
    return {
      'hits_today': info!['hitsToday'],
      'hits_limit': info['hitsLimit'],
      'hits_day': _utcDay(DateTime.now()),
    };
  }

  int _hitsToday(Map<String, dynamic>? feed, DateTime now) {
    if (feed?['hits_day'] != _utcDay(now)) return 0;
    return (feed?['hits_today'] as num?)?.toInt() ?? 0;
  }
}
