import 'dart:async';

import 'package:data/api/leaderboard/leaderboard_model.dart';
import 'package:data/api/match/match_model.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:data/service/leaderboard/leaderboard_service.dart';
import 'package:data/service/match/match_service.dart';
import 'package:data/service/pocketbase/pocketbase_match_service.dart';
import 'package:data/service/tournament/tournament_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:data/utils/combine_latest.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';

part 'home_view_model.freezed.dart';

final homeViewStateProvider =
    StateNotifierProvider.autoDispose<HomeViewNotifier, HomeViewState>(
  (ref) {
    final notifier = HomeViewNotifier(
      ref.read(matchServiceProvider),
      ref.read(tournamentServiceProvider),
      ref.read(leaderboardServiceProvider),
      ref.read(pocketBaseMatchServiceProvider),
    );
    ref.listen(
        hasUserSession, (_, next) => notifier._onUserSessionUpdate(next));
    return notifier;
  },
);

class HomeViewNotifier extends StateNotifier<HomeViewState> {
  final MatchService _matchService;
  final TournamentService _tournamentService;
  final LeaderboardService _leaderboardService;
  final PocketBaseMatchService _pocketBaseMatchService;
  StreamSubscription? _streamSubscription;
  StreamSubscription? _pocketBaseSubscription;
  List<MatchModel> _pocketBaseLive = const [];

  HomeViewNotifier(
    this._matchService,
    this._tournamentService,
    this._leaderboardService,
    this._pocketBaseMatchService,
  ) : super(const HomeViewState()) {
    loadData();
  }

  void _onUserSessionUpdate(bool hasSession) => loadData();

  void loadData() async {
    _streamSubscription?.cancel();
    _pocketBaseSubscription?.cancel();
    state = state.copyWith(loading: state.matches.isEmpty);

    _pocketBaseSubscription =
        _pocketBaseMatchService.streamLiveMatches().listen((pbLive) {
      _pocketBaseLive = pbLive;
      _applyPocketBaseLive();
    }, onError: (e) {
      debugPrint("HomeViewNotifier: PocketBase live stream error -> $e");
    });

    final combineFutures = combineLatest5(
      _matchService.streamActiveRunningMatches(),
      _matchService.streamUpcomingMatches(),
      _matchService.streamFinishedMatches(),
      _tournamentService.streamActiveTournaments(),
      _leaderboardService.streamLeaderboard(limit: 4),
    );

    _streamSubscription = combineFutures.listen(
      (results) {
        final live = _mergeLive(results.$1);
        state = state.copyWith(
          matches: [...live, ...results.$2, ...results.$3],
          groupMatches: {
            MatchStatusLabel.live: live,
            MatchStatusLabel.upcoming: results.$2,
            MatchStatusLabel.finished: results.$3,
          },
          tournaments: results.$4,
          leaderboard: results.$5,
          loading: false,
          error: null,
        );
      },
      onError: (e) {
        // Firestore Spark 429: still show PocketBase live if we have any.
        final live = _mergeLive(const []);
        state = state.copyWith(
          matches: live.isEmpty ? state.matches : live,
          groupMatches: {
            ...state.groupMatches,
            if (live.isNotEmpty) MatchStatusLabel.live: live,
          },
          error: live.isEmpty ? e : null,
          loading: false,
        );
        debugPrint("HomeViewNotifier: error while load matches -> $e");
      },
    );
  }

  List<MatchModel> _mergeLive(List<MatchModel> firestoreLive) {
    final withoutPb = firestoreLive
        .where((m) => !PocketBaseMatchService.isPocketBaseMatchId(m.id))
        .toList();
    return [..._pocketBaseLive, ...withoutPb];
  }

  void _applyPocketBaseLive() {
    final currentLive =
        state.groupMatches[MatchStatusLabel.live] ?? const <MatchModel>[];
    final live = _mergeLive(currentLive);
    final upcoming =
        state.groupMatches[MatchStatusLabel.upcoming] ?? const <MatchModel>[];
    final finished =
        state.groupMatches[MatchStatusLabel.finished] ?? const <MatchModel>[];
    state = state.copyWith(
      matches: [...live, ...upcoming, ...finished],
      groupMatches: {
        MatchStatusLabel.live: live,
        MatchStatusLabel.upcoming: upcoming,
        MatchStatusLabel.finished: finished,
      },
      loading: false,
      error: live.isNotEmpty ? null : state.error,
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _pocketBaseSubscription?.cancel();
    super.dispose();
  }
}

@freezed
class HomeViewState with _$HomeViewState {
  const factory HomeViewState({
    Object? error,
    @Default(false) bool loading,
    @Default([]) List<MatchModel> matches,
    @Default([]) List<TournamentModel> tournaments,
    @Default([]) List<LeaderboardModel> leaderboard,
    @Default({}) Map<MatchStatusLabel, List<MatchModel>> groupMatches,
  }) = _HomeViewState;
}

enum MatchStatusLabel {
  live,
  upcoming,
  finished;

  String getString(BuildContext context) {
    switch (this) {
      case MatchStatusLabel.live:
        return context.l10n.home_screen_live_title;
      case MatchStatusLabel.upcoming:
        return context.l10n.home_screen_upcoming_title;
      case MatchStatusLabel.finished:
        return context.l10n.home_screen_finished_title;
    }
  }

  List<MatchStatus> convertStatus() {
    switch (this) {
      case MatchStatusLabel.live:
        return [MatchStatus.running];
      case MatchStatusLabel.upcoming:
        return [MatchStatus.yetToStart];
      case MatchStatusLabel.finished:
        return [MatchStatus.finish, MatchStatus.abandoned];
    }
  }
}
