import 'package:data/api/ball_score/ball_score_model.dart';
import 'package:flutter/widgets.dart';
import 'package:khelo/domain/play/cricket_game.dart';
import 'package:khelo/l10n/app_localizations.dart';

import 'mascot_controller.dart';

/// The tiger always speaks Tamil (`app_ta.arb`), whatever the app language.
final AppLocalizations mascotText = lookupAppLocalizations(const Locale('ta'));

/// App events the tiger reacts to, with its pose and line for each.
enum MascotReaction {
  six(MascotPose.celebrate),
  four(MascotPose.success),
  wicket(MascotPose.error),
  dotBall(MascotPose.thinking),
  perfectTiming(MascotPose.celebrate),
  earlyShot(MascotPose.warning),
  lateShot(MascotPose.thinking),
  matchWon(MascotPose.celebrate),
  matchLost(MascotPose.noRecords),
  matchTied(MascotPose.success),
  lastOver(MascotPose.notification),
  comeback(MascotPose.help),
  teamCreated(MascotPose.registered),
  tournamentCreated(MascotPose.success),
  challengeWon(MascotPose.celebrate),
  challengeLost(MascotPose.noRecords),
  emptyMatches(MascotPose.noRecords),
  noPlayers(MascotPose.search),
  internet(MascotPose.noInternet, allowFun: false),
  auctionSold(MascotPose.celebrate),
  auctionUnsold(MascotPose.noRecords);

  const MascotReaction(this.pose, {this.allowFun = true});

  final MascotPose pose;
  final bool allowFun;

  String message(AppLocalizations text) => switch (this) {
        six => text.mascot_fun_six,
        four => text.mascot_fun_four,
        wicket => text.mascot_fun_wicket,
        dotBall => text.mascot_fun_dot_ball,
        perfectTiming => text.mascot_fun_perfect_timing,
        earlyShot => text.mascot_fun_early_shot,
        lateShot => text.mascot_fun_late_shot,
        matchWon => text.mascot_fun_match_won,
        matchLost => text.mascot_fun_match_lost,
        matchTied => text.mascot_fun_match_tied,
        lastOver => text.mascot_fun_last_over,
        comeback => text.mascot_fun_comeback,
        teamCreated => text.mascot_fun_team_created,
        tournamentCreated => text.mascot_fun_tournament_created,
        challengeWon => text.mascot_fun_challenge_won,
        challengeLost => text.mascot_fun_challenge_lost,
        emptyMatches => text.mascot_fun_empty_matches,
        noPlayers => text.mascot_fun_no_players,
        internet => text.mascot_fun_internet,
        auctionSold => text.mascot_fun_auction_sold,
        auctionUnsold => text.mascot_fun_auction_unsold,
      };
}

/// Short cinema-style lines shown when the tiger is tapped.
List<String> mascotMovieLines(AppLocalizations text) => [
      text.mascot_movie_baasha_style,
      text.mascot_movie_padayappa_style,
      text.mascot_movie_mass_entry,
      text.mascot_movie_comedy_scene,
      text.mascot_movie_climax_scene,
      text.mascot_movie_hero_intro,
      text.mascot_movie_interval,
      text.mascot_movie_dialogue_hint,
      text.mascot_movie_cool_attitude,
      text.mascot_movie_youth_energy,
      text.mascot_movie_mass_punch,
    ];

extension MascotReactionsX on MascotController {
  void react(
    MascotReaction reaction, {
    Duration? duration,
    Duration delay = Duration.zero,
    bool top = false,
    double lift = MascotController.defaultLift,
    bool allowFun = true,
  }) {
    show(
      reaction.pose,
      reaction.message(mascotText),
      duration: duration,
      delay: delay,
      top: top,
      lift: lift,
      allowFun: allowFun && reaction.allowFun,
    );
  }

  /// Swaps the current cue for a movie line. Does nothing when no cue is
  /// showing or the cue is one the user needs to read (sign-in, errors).
  void playMovieLine() {
    final cue = current;
    if (cue == null || !cue.allowFun) return;
    final lines = mascotMovieLines(mascotText);
    show(
      MascotPose.celebrate,
      lines[takeMovieTurn() % lines.length],
      top: cue.top,
      lift: cue.lift,
    );
  }
}

/// Reaction for a delivery that has been saved on the score board, or null.
/// Extras (wides, no-balls, byes, leg-byes, penalties) are never dot balls;
/// retirements are not wickets.
MascotReaction? reactionForBall(BallScoreModel ball) {
  final wicket = ball.wicket_type;
  if (wicket != null &&
      wicket != WicketType.retired &&
      wicket != WicketType.retiredHurt) {
    return MascotReaction.wicket;
  }
  if (ball.is_six) return MascotReaction.six;
  if (ball.is_four) return MascotReaction.four;
  if (wicket == null &&
      ball.extras_type == null &&
      ball.runs_scored == 0 &&
      (ball.extras_awarded ?? 0) == 0) {
    return MascotReaction.dotBall;
  }
  return null;
}

/// Play mini-game: one reaction per shot, from its result and swing timing.
/// [offsetMs] is null when the batter didn't swing.
MascotReaction reactionForShot(ShotResult result, int? offsetMs) {
  if (result.isOut) return MascotReaction.wicket;
  if (offsetMs == null) return MascotReaction.dotBall;
  if (offsetMs.abs() <= GameRules.perfectWindowMs) {
    return MascotReaction.perfectTiming;
  }
  if (result == ShotResult.four) return MascotReaction.four;
  return offsetMs < 0 ? MascotReaction.earlyShot : MascotReaction.lateShot;
}
