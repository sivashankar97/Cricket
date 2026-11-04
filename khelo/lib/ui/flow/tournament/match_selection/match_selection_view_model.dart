import 'dart:async';
import 'dart:collection';

import 'package:data/api/match/match_model.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:data/extensions/string_extensions.dart';
import 'package:data/service/match/match_service.dart';
import 'package:data/service/tournament/tournament_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:khelo/ui/flow/tournament/match_selection/match_scheduler.dart';

part 'match_selection_view_model.freezed.dart';

typedef GroupedMatchMap = Map<MatchGroup, Map<int, List<MatchModel>>>;

final matchSelectionStateProvider = StateNotifierProvider.autoDispose<
        MatchSelectionViewNotifier, MatchSelectionState>(
    (ref) => MatchSelectionViewNotifier(
        ref.read(tournamentServiceProvider), ref.read(matchServiceProvider)));

class MatchSelectionViewNotifier extends StateNotifier<MatchSelectionState> {
  final TournamentService _tournamentService;
  final MatchService _matchService;
  late MatchScheduler _scheduler;

  StreamSubscription? _tournamentSubscription;
  StreamSubscription? _matchSubscription;
  String? _tournamentId;
  Timer? _debounce;

  MatchSelectionViewNotifier(this._tournamentService, this._matchService)
      : super(MatchSelectionState(searchController: TextEditingController()));

  void setData(String tournamentId) {
    _tournamentId = tournamentId;
    loadTournament();
  }

  void loadTournament() async {
    if (_tournamentId == null) return;
    _tournamentSubscription?.cancel();

    state = state.copyWith(loading: true);

    _tournamentSubscription = _tournamentService
        .streamTournamentById(_tournamentId!)
        .listen((tournament) async {
      _matchSubscription?.cancel();
      _matchSubscription = _matchService
          .streamMatchesByIds(tournament.match_ids)
          .listen((matches) {
        _scheduler = MatchScheduler(tournament.teams, matches, tournament.type);
        final scheduledMatches = _scheduler.scheduleMatchesByType();
        final sorted =
            SplayTreeMap<MatchGroup, Map<int, List<MatchModel>>>.from(
                scheduledMatches, (a, b) => a.index.compareTo(b.index));
        if (mounted) {
          state = state.copyWith(
            tournament: tournament,
            matches: sorted,
            loading: false,
          );
        }
      });
    }, onError: (e) {
      state = state.copyWith(error: e, loading: false);
      debugPrint(
          "MatchSelectionViewNotifier: error while loading tournament -> $e");
    });
  }

  Future<void> _search(String searchKey) async {
    state = state.copyWith(searchInProgress: true);

    try {
      final filter = filterMatches(state.matches, searchKey);
      state = state.copyWith(
        searchResults: filter,
        error: null,
        searchInProgress: false,
      );
    } catch (e) {
      state = state.copyWith(
        searchInProgress: false,
        error: e,
      );
      debugPrint(
          "MatchSelectionViewNotifier: error while searching team -> $e");
    }
  }

  void onSearchChanged() {
    if (_debounce != null && _debounce!.isActive) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (state.searchController.text.isNotEmpty) {
        _search(state.searchController.text.trim());
      } else {
        state = state.copyWith(searchResults: {});
      }
    });
  }

  void addGroup(MatchGroup group) {
    final matches = GroupedMatchMap.of(state.matches);
    final groupEntry = Map<int, List<MatchModel>>.of(matches[group] ?? {});
    final nextRound = groupEntry.isEmpty ? 1 : groupEntry.keys.last + 1;

    groupEntry[nextRound] = [];
    matches[group] = groupEntry;
    final sorted = SplayTreeMap<MatchGroup, Map<int, List<MatchModel>>>.from(
        matches, (a, b) => a.index.compareTo(b.index));

    state = state.copyWith(matches: sorted);
  }

  GroupedMatchMap filterMatches(GroupedMatchMap matches, String searchedWord) {
    String normalizedWord = searchedWord.caseAndSpaceInsensitive;

    GroupedMatchMap filteredMatches = {};

    for (var matchGroupEntry in matches.entries) {
      MatchGroup matchGroup = matchGroupEntry.key;
      Map<int, List<MatchModel>> innerMap = matchGroupEntry.value;

      Map<int, List<MatchModel>> filteredInnerMap = {};

      for (var innerEntry in innerMap.entries) {
        int key = innerEntry.key;
        List<MatchModel> matchList = innerEntry.value;

        List<MatchModel> filteredList = matchList.where((match) {
          return match.teams.first.team.name_lowercase
                  .contains(normalizedWord) ||
              match.teams.last.team.name_lowercase.contains(normalizedWord);
        }).toList();

        if (filteredList.isNotEmpty) {
          filteredInnerMap[key] = filteredList;
        }
      }

      if (filteredInnerMap.isNotEmpty) {
        filteredMatches[matchGroup] = filteredInnerMap;
      }
    }

    return filteredMatches;
  }

  List<MatchGroup> getMatchGroupOption() {
    final options = MatchGroup.values.toList();
    final tournamentType = state.tournament?.type;
    if (state.matches.containsKey(MatchGroup.round)) {
      if (tournamentType == TournamentType.miniRobin ||
          (tournamentType == TournamentType.doubleOut &&
              (state.matches[MatchGroup.round]?.entries.length ?? 0) > 1)) {
        options.remove(MatchGroup.round);
      }
    }

    void handleDoubleOutValidation(MatchGroup group) {
      if (tournamentType == TournamentType.doubleOut ||
          state.matches.containsKey(group)) {
        if (tournamentType == TournamentType.doubleOut ||
            tournamentType == TournamentType.miniRobin ||
            tournamentType == TournamentType.boxLeague ||
            tournamentType == TournamentType.custom ||
            tournamentType == TournamentType.knockOut) {
          options.remove(group);
        }
      }
    }

    handleDoubleOutValidation(MatchGroup.quarterfinal);
    handleDoubleOutValidation(MatchGroup.semifinal);

    if (state.matches.containsKey(MatchGroup.finals)) {
      options.remove(MatchGroup.finals);
    }

    return options;
  }

  Future<int> scheduleAllMatches({
    required DateTime startDate,
    required int numberOfOvers,
    required int overPerBowler,
    required String city,
    required String ground,
    required BallType ballType,
    required PitchType pitchType,
    bool staggerTimes = true,
  }) async {
    if (state.tournament == null) return 0;
    state = state.copyWith(loading: true, actionError: null);

    try {
      final List<MatchModel> pendingMatches = [];
      state.matches.forEach((group, rounds) {
        rounds.forEach((roundNumber, matchesList) {
          for (final m in matchesList) {
            if (m.id.isEmpty && m.teams.length >= 2) {
              pendingMatches.add(m);
            }
          }
        });
      });

      if (pendingMatches.isEmpty) {
        state = state.copyWith(loading: false);
        return 0;
      }

      final tournament = state.tournament!;
      final teamsMap = {for (final t in tournament.teams) t.id: t};

      final List<MatchModel> matchesToCreate = [];
      DateTime currentMatchTime = startDate;

      for (int i = 0; i < pendingMatches.length; i++) {
        final pending = pendingMatches[i];
        final teamAId = pending.teams.first.team_id;
        final teamBId = pending.teams.last.team_id;

        final teamA = teamsMap[teamAId] ?? pending.teams.first.team;
        final teamB = teamsMap[teamBId] ?? pending.teams.last.team;

        final squadA = teamA.players
            .where((p) => p.user.isActive)
            .take(11)
            .map((p) => MatchPlayer(id: p.user.id, player: p.user))
            .toList();
        final squadB = teamB.players
            .where((p) => p.user.isActive)
            .take(11)
            .map((p) => MatchPlayer(id: p.user.id, player: p.user))
            .toList();

        final allPlayerIds = {
          ...squadA.map((p) => p.id),
          ...squadB.map((p) => p.id),
        }.toList();

        final matchTime = currentMatchTime;
        if (staggerTimes) {
          currentMatchTime = currentMatchTime.add(const Duration(hours: 3));
        }

        final matchModel = MatchModel(
          id: '',
          players: allPlayerIds,
          team_ids: [teamA.id, teamB.id],
          team_creator_ids: [
            if (teamA.created_by != null) teamA.created_by!,
            if (teamB.created_by != null && teamB.created_by != teamA.created_by)
              teamB.created_by!,
          ],
          teams: [
            MatchTeamModel(
              team_id: teamA.id,
              team: teamA,
              squad: squadA,
              captain_id: squadA.firstOrNull?.id,
              admin_id: squadA.firstOrNull?.id,
            ),
            MatchTeamModel(
              team_id: teamB.id,
              team: teamB,
              squad: squadB,
              captain_id: squadB.firstOrNull?.id,
              admin_id: squadB.firstOrNull?.id,
            ),
          ],
          match_type: MatchType.limitedOvers,
          number_of_over: numberOfOvers,
          over_per_bowler: overPerBowler,
          city: city.isNotEmpty ? city : (pending.city.isNotEmpty ? pending.city : ''),
          ground: ground.isNotEmpty ? ground : (pending.ground.isNotEmpty ? pending.ground : ''),
          match_group: pending.match_group,
          match_group_number: pending.match_group_number,
          tournament_id: tournament.id,
          start_time: matchTime,
          start_at: matchTime,
          ball_type: ballType,
          pitch_type: pitchType,
          created_by: tournament.created_by,
          match_status: MatchStatus.yetToStart,
        );

        matchesToCreate.add(matchModel);
      }

      final createdIds = await _matchService.createMatches(matchesToCreate);
      await _tournamentService.addMatchIdsInTournament(tournament.id, createdIds);

      state = state.copyWith(loading: false);
      return createdIds.length;
    } catch (e) {
      state = state.copyWith(loading: false, actionError: e);
      debugPrint("MatchSelectionViewNotifier: error in scheduleAllMatches -> $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _tournamentSubscription?.cancel();
    _matchSubscription?.cancel();
    state.searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

@freezed
class MatchSelectionState with _$MatchSelectionState {
  const factory MatchSelectionState({
    required TextEditingController searchController,
    Object? error,
    Object? actionError,
    TournamentModel? tournament,
    @Default({}) GroupedMatchMap searchResults,
    @Default({}) GroupedMatchMap matches,
    @Default(false) bool loading,
    @Default(false) bool searchInProgress,
  }) = _MatchSelectionState;
}
