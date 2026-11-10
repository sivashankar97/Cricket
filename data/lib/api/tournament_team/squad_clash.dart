import '../../errors/app_error.dart';
import '../../errors/app_error_l10n_codes.dart';

/// A player can play for only one team in a tournament.
class PlayerTeamClashError extends AppError {
  final String playerName;

  /// The team the player already plays for.
  final String teamName;

  /// When picking teams: the other selected team with the same player.
  final String? otherTeamName;
  final String? tournamentName;

  PlayerTeamClashError({
    required this.playerName,
    required this.teamName,
    this.otherTeamName,
    this.tournamentName,
  }) : super(
          l10nCode: AppErrorL10nCodes.playerInOtherTeam,
          message: otherTeamName == null
              ? '$playerName is already in $teamName in ${tournamentName ?? 'this tournament'}.'
              : '$playerName is in both $teamName and $otherTeamName.',
        );
}

/// A team's id, name and player ids, for [findSquadClash].
typedef SquadTeam = ({String id, String name, Iterable<String> playerIds});

/// The first player found in two of [teams], with both teams.
({String playerId, SquadTeam team, SquadTeam other})? findSquadClash(
  Iterable<SquadTeam> teams,
) {
  final teamOf = <String, SquadTeam>{};
  for (final team in teams) {
    for (final playerId in team.playerIds.toSet()) {
      final other = teamOf[playerId];
      if (other != null && other.id != team.id) {
        return (playerId: playerId, team: other, other: team);
      }
      teamOf[playerId] = team;
    }
  }
  return null;
}
