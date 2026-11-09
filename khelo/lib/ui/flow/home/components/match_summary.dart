import 'dart:math';

import 'package:collection/collection.dart';
import 'package:data/api/match/match_model.dart';
import 'package:data/extensions/double_extensions.dart';

/// Innings order, run rates and the chase for the Home match cards.
class MatchSummary {
  final MatchTeamModel first;
  final MatchTeamModel second;
  final MatchTeamModel? batting;
  final bool tossDone;
  final double? currentRate;
  final int? target;
  final int? runsNeeded;
  final int? ballsLeft;
  final double? requiredRate;

  const MatchSummary._({
    required this.first,
    required this.second,
    required this.batting,
    required this.tossDone,
    this.currentRate,
    this.target,
    this.runsNeeded,
    this.ballsLeft,
    this.requiredRate,
  });

  bool get isChasing => target != null;

  factory MatchSummary.of(MatchModel match) {
    final teams = match.teams;
    final winnerId = match.toss_winner_id;
    final decision = match.toss_decision;
    final tossDone = winnerId != null && decision != null;

    var first = teams.first;
    var second = teams.elementAt(1);
    if (tossDone) {
      final winner = teams.firstWhereOrNull((t) => t.team_id == winnerId);
      final other = teams.firstWhereOrNull((t) => t.team_id != winnerId);
      if (winner != null && other != null) {
        first = decision == TossDecision.bat ? winner : other;
        second = decision == TossDecision.bat ? other : winner;
      }
    }

    final batting = teams
        .firstWhereOrNull((t) => t.team_id == match.current_playing_team_id);
    final bpo = match.rules.balls_per_over;
    final battingBalls = batting?.over.toBalls(ballsPerOver: bpo) ?? 0;
    final currentRate = batting != null && battingBalls > 0
        ? batting.run * bpo / battingBalls
        : null;

    final chasing = tossDone &&
        batting != null &&
        batting.team_id == second.team_id &&
        match.match_type != MatchType.testMatch;
    if (!chasing) {
      return MatchSummary._(
        first: first,
        second: second,
        batting: batting,
        tossDone: tossDone,
        currentRate: currentRate,
      );
    }

    final revised = match.revised_target;
    final target =
        revised != null && revised.runs > 0 ? revised.runs : first.run + 1;
    final totalBalls = revised != null && revised.overs > 0
        ? revised.overs.toBalls(ballsPerOver: bpo)
        : match.number_of_over * bpo;
    final runsNeeded = max(0, target - second.run);
    final ballsLeft = max(0, totalBalls - battingBalls);
    return MatchSummary._(
      first: first,
      second: second,
      batting: batting,
      tossDone: tossDone,
      currentRate: currentRate,
      target: target,
      runsNeeded: runsNeeded,
      ballsLeft: ballsLeft,
      requiredRate: ballsLeft > 0 ? runsNeeded * bpo / ballsLeft : null,
    );
  }
}
