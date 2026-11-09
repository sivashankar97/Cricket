import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:flutter/widgets.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';

extension TournamentPlayerRoleString on TournamentPlayerRole {
  String getString(BuildContext context) {
    switch (this) {
      case TournamentPlayerRole.batsman:
        return context.l10n.tournament_player_role_batsman;
      case TournamentPlayerRole.bowler:
        return context.l10n.tournament_player_role_bowler;
      case TournamentPlayerRole.allRounder:
        return context.l10n.tournament_player_role_all_rounder;
      case TournamentPlayerRole.wicketKeeper:
        return context.l10n.tournament_player_role_wicket_keeper;
    }
  }
}
