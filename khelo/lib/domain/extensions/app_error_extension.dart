import 'package:data/api/tournament_team/squad_clash.dart';
import 'package:data/errors/app_error_l10n_codes.dart';
import 'package:flutter/cupertino.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:data/errors/app_error.dart';

extension AppErrorExtensions on Object {
  String l10nMessage(BuildContext context) {
    final clash = this;
    if (clash is PlayerTeamClashError) {
      return clash.otherTeamName == null
          ? context.l10n.error_player_in_other_team(
              clash.playerName,
              clash.teamName,
              clash.tournamentName ?? context.l10n.error_this_tournament,
            )
          : context.l10n.error_player_in_two_teams(
              clash.playerName,
              clash.teamName,
              clash.otherTeamName!,
            );
    }
    if (this is AppError) {
      switch ((this as AppError).l10nCode) {
        case AppErrorL10nCodes.noInternetConnection:
          return context.l10n.error_no_internet;
        case AppErrorL10nCodes.somethingWentWrongError:
          return context.l10n.error_something_went_wrong;
        case AppErrorL10nCodes.invalidPhoneNumber:
          return context.l10n.sign_in_invalid_phone_number_text;
        case AppErrorL10nCodes.largeAttachmentUpload:
          return context.l10n.large_attachment_upload_error_text;
        case AppErrorL10nCodes.duplicateTeamName:
          return context.l10n.error_duplicate_team_name;
        case AppErrorL10nCodes.duplicatePlayerName:
          return context.l10n.error_duplicate_player_name;
        case AppErrorL10nCodes.mergeNotAllowed:
          return context.l10n.error_merge_not_allowed;
        case AppErrorL10nCodes.tournamentHasPlayedMatches:
          return context.l10n.error_tournament_has_played_matches;
        case AppErrorL10nCodes.duplicateJerseyNumber:
          return context.l10n.error_duplicate_jersey_number;
        case AppErrorL10nCodes.teamUsedInTournament:
          return context.l10n.error_team_used_in_tournament;
        case AppErrorL10nCodes.duplicatePoolName:
          return context.l10n.error_duplicate_pool_name;
        case AppErrorL10nCodes.poolUsedInTournament:
          return context.l10n.error_pool_used_in_tournament;
        default:
          return (this as AppError).message ??
              context.l10n.error_something_went_wrong;
      }
    } else if (this is String) {
      return this as String;
    } else {
      return context.l10n.error_something_went_wrong;
    }
  }
}
