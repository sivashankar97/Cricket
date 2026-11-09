import 'dart:async';

import 'package:data/api/global_cricket/global_cricket_models.dart';
import 'package:data/service/global_cricket/global_cricket_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set at build time: `--dart-define=CRICKETDATA_API_KEY=...`
/// (see `khelo/scripts/` and the vault's Global Cricket note).
const cricketDataApiKey = String.fromEnvironment('CRICKETDATA_API_KEY');

final globalCricketFeedProvider =
    StreamProvider.autoDispose<GlobalCricketFeed>((ref) {
  final service = ref.watch(globalCricketServiceProvider);

  if (ref.watch(hasUserSession) && cricketDataApiKey.isNotEmpty) {
    void refresh() =>
        service.refreshIfStale(cricketDataApiKey).catchError((_) {});
    refresh();
    final timer = Timer.periodic(GlobalCricketService.refreshEvery, (_) {
      refresh();
    });
    ref.onDispose(timer.cancel);
  }

  return service.streamFeed();
});

final globalScorecardProvider =
    StreamProvider.autoDispose.family<GlobalScorecard?, String>((ref, matchId) {
  return ref.watch(globalCricketServiceProvider).streamScorecard(matchId);
});

/// Asks for a fresh scorecard (shared cache, hit budget permitting) and
/// reports why there may be none.
final globalScorecardBlockProvider = FutureProvider.autoDispose
    .family<ScorecardBlock, GlobalMatch>((ref, match) async {
  if (match.isUpcoming) return ScorecardBlock.notStarted;
  if (!ref.watch(hasUserSession)) return ScorecardBlock.signedOut;
  return ref
      .watch(globalCricketServiceProvider)
      .refreshScorecardIfNeeded(apiKey: cricketDataApiKey, match: match)
      .catchError((_) => ScorecardBlock.dailyLimit);
});
