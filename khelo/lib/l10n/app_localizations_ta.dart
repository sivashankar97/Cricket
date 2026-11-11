// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get app_title => 'Sports Tamil';

  @override
  String get common_none_title => 'None';

  @override
  String get common_anonymous_title => 'Anonymous';

  @override
  String get common_delete_title => 'Delete';

  @override
  String get common_cancel_title => 'Cancel';

  @override
  String get common_sign_out_title => 'Sign out';

  @override
  String get common_add_title => 'Add';

  @override
  String get common_edit_title => 'Edit';

  @override
  String get common_remove_title => 'Remove';

  @override
  String get common_reset_title => 'Reset';

  @override
  String get common_okay_title => 'Okay';

  @override
  String get common_save_title => 'Save';

  @override
  String get common_next_title => 'Next';

  @override
  String get common_yes_title => 'Yes';

  @override
  String get common_no_title => 'No';

  @override
  String get common_retry_title => 'Retry';

  @override
  String get common_submit_title => 'Submit';

  @override
  String get common_not_now => 'Not now';

  @override
  String get common_create => 'Create';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_not_specified_title => 'Not Specified';

  @override
  String get commonRunning => 'Running';

  @override
  String get commonFinish => 'Finish';

  @override
  String get commonDeactivatedUser => 'Deactivated User';

  @override
  String common_runs_title(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count runs',
      one: '$count run',
      zero: '$count runs',
    );
    return '$_temp0';
  }

  @override
  String common_wickets_title(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wickets',
      one: '$count wicket',
      zero: '$count wickets',
    );
    return '$_temp0';
  }

  @override
  String common_players_title(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Players',
      one: '$count Player',
      zero: '$count Players',
    );
    return '$_temp0';
  }

  @override
  String get common_tie_title => 'Tie';

  @override
  String get common_wicket_taken_title => ' Wicket taken';

  @override
  String get common_matches_title => 'Matches';

  @override
  String get common_teams_title => 'Teams';

  @override
  String get common_stats_title => 'Stats';

  @override
  String get common_edit_team_title => 'Edit team';

  @override
  String get common_create_team_title => 'Create team';

  @override
  String get common_create_team_description =>
      'Create Your Dream Cricket Team Today!';

  @override
  String get common_your_teams_title => 'Your Teams';

  @override
  String get common_location_title => 'Location';

  @override
  String get common_gender_title => 'Gender';

  @override
  String get common_batting_style_title => 'Batting style';

  @override
  String get common_bowling_style_title => 'Bowling style';

  @override
  String get common_camera_text => 'Camera';

  @override
  String get common_gallery_text => 'Gallery';

  @override
  String get common_versus_short_title => 'VS';

  @override
  String get common_other_title => 'Other';

  @override
  String get common_city_title => 'City';

  @override
  String get common_select_squad_title => 'Select Squad';

  @override
  String get common_power_play_title => 'Power Play Overs';

  @override
  String get common_select_title => 'Select';

  @override
  String get common_a_title => 'A';

  @override
  String get common_m_title => 'M';

  @override
  String get common_batting_average_title => 'Batting Average';

  @override
  String get common_bowling_average_title => 'Bowling Average';

  @override
  String get common_overs_title => 'Overs';

  @override
  String get common_run_out_title => 'Run Out';

  @override
  String get common_wickets_text => 'Wickets';

  @override
  String get common_end_match_title => 'End Match';

  @override
  String get common_first_inning_title => 'First inning';

  @override
  String get common_second_inning_title => 'Second inning';

  @override
  String get common_qr_code_title => 'QR Code';

  @override
  String get common_verify_title => 'Verify';

  @override
  String get common_verified_title => 'Verified';

  @override
  String get common_view_all => 'View all';

  @override
  String get common_today => 'Today';

  @override
  String get common_tomorrow => 'Tomorrow';

  @override
  String get common_owner => 'Owner';

  @override
  String get common_make_admin => 'Make admin';

  @override
  String get common_remove_admin => 'Remove admin';

  @override
  String get common_transfer_ownership => 'Transfer ownership';

  @override
  String get common_tournaments => 'Tournaments';

  @override
  String get common_leaderboard => 'Leaderboard';

  @override
  String get common_batting => 'Batting';

  @override
  String get common_bowling => 'Bowling';

  @override
  String get common_fielding => 'Fielding';

  @override
  String common_obscure_phone_number_text(
      String countryCode, String lastDigits) {
    return '$countryCode ***** ***$lastDigits';
  }

  @override
  String get alert_confirm_default_title => 'Are you sure?';

  @override
  String alert_confirm_default_message(String deleteText) {
    return 'Are you sure you want to $deleteText?';
  }

  @override
  String get error_something_went_wrong =>
      'Something went wrong! Please try again later.';

  @override
  String get error_no_internet =>
      'No internet connection! Please check your network connectivity.';

  @override
  String get no_internet_error_title => 'No internet!';

  @override
  String get no_internet_error_description =>
      'Network error. Please check connection and try again.';

  @override
  String get something_went_wrong_error_title => 'Something went wrong';

  @override
  String get something_went_wrong_error_description =>
      'This is all the information we have, but we won\'t rest until we resolve the issue!';

  @override
  String get intro_get_your_cricket_title => 'Get Your Cricket On!';

  @override
  String get intro_get_your_cricket_description =>
      'Turn backyard games into pro matches with our app. Create matches, manage teams, and track stats!';

  @override
  String get intro_continue_btn_text => 'Continue';

  @override
  String get sign_in_verify_phone_number_title => 'Enter phone number';

  @override
  String get sign_in_verify_phone_number_description =>
      'We’ll verify your phone number with a verification code.';

  @override
  String get sign_in_phone_number_placeholder => '00000 00000';

  @override
  String get sign_in_get_otp_btn_text => 'Get OTP';

  @override
  String get sign_in_invalid_phone_number_text =>
      'Please enter valid phone number';

  @override
  String get sign_in_options_title => 'Sign in';

  @override
  String get sign_in_guest_option => 'Continue as guest';

  @override
  String get sign_in_guest_hint =>
      'Play cricket without an account. Your scores show as \"Guest\".';

  @override
  String get sign_in_email_title => 'Welcome back';

  @override
  String get sign_in_email_description =>
      'Sign in to score matches, follow tournaments and see your stats.';

  @override
  String get sign_in_email_create_title => 'Create your account';

  @override
  String get sign_in_email_create_description =>
      'Set up teams, matches and tournaments, and keep all your cricket in one place.';

  @override
  String get sign_in_password_placeholder => 'Enter your password';

  @override
  String get sign_in_email_sign_in_btn => 'Sign in';

  @override
  String get sign_in_email_create_btn => 'Create account';

  @override
  String get sign_in_email_label => 'Email';

  @override
  String get sign_in_password_label => 'Password';

  @override
  String get sign_in_password_create_placeholder => 'Choose a password';

  @override
  String get sign_in_password_rule => 'At least 6 characters';

  @override
  String get sign_in_mode_label => 'Sign in or create an account';

  @override
  String get sign_in_or => 'or';

  @override
  String get sign_in_show_password => 'Show password';

  @override
  String get sign_in_hide_password => 'Hide password';

  @override
  String get sign_in_forgot_password => 'Forgot password?';

  @override
  String sign_in_reset_email_sent(String email) {
    return 'Password reset link sent to $email. Check your inbox and spam folder.';
  }

  @override
  String get sign_in_reset_enter_email =>
      'Enter your email first, then tap Forgot password.';

  @override
  String get sign_in_email_placeholder => 'name@example.com';

  @override
  String get sign_in_required_title => 'Sign in to continue';

  @override
  String get sign_in_required_description =>
      'Sign in to see your matches, teams, stats, and profile.';

  @override
  String get otp_verification_verification_title => 'Verification code';

  @override
  String get otp_verification_incorrect_otp_error_text =>
      '*Please enter correct OTP';

  @override
  String get otp_verification_verify_placeholder => '0 0 0 0 0 0';

  @override
  String otp_verification_verification_description(Object phone) {
    return 'We\'ve sent a verification code to your phone $phone';
  }

  @override
  String get home_screen_title => 'Home';

  @override
  String get home_screen_live_title => 'Live';

  @override
  String get home_screen_upcoming_title => 'Upcoming';

  @override
  String get home_screen_finished_title => 'Finished';

  @override
  String get home_screen_set_up_match_title => 'Set up a match in minutes.';

  @override
  String get home_screen_create_match_btn => 'Create match';

  @override
  String get home_screen_set_up_team_title => 'Set up a team in minutes.';

  @override
  String get home_screen_create_team_btn => 'Create team';

  @override
  String get home_screen_set_up_tournament_title =>
      'Set up a tournament in minutes.';

  @override
  String get home_screen_create_tournament_btn => 'Create tournament';

  @override
  String get home_global_cricket_title => 'Global cricket';

  @override
  String home_global_cricket_updated(String time) {
    return 'Updated $time · CricketData.org';
  }

  @override
  String get home_global_cricket_live => 'LIVE';

  @override
  String get global_cricket_international => 'International';

  @override
  String get global_cricket_leagues => 'Premier leagues';

  @override
  String get global_cricket_no_matches => 'No matches right now';

  @override
  String get global_cricket_live => 'Live';

  @override
  String get global_cricket_recent => 'Recent';

  @override
  String get global_cricket_upcoming => 'Upcoming';

  @override
  String get global_cricket_scorecard => 'Scorecard';

  @override
  String get global_cricket_info => 'Info';

  @override
  String get global_cricket_batter => 'Batter';

  @override
  String get global_cricket_bowler => 'Bowler';

  @override
  String get global_cricket_batting => 'batting';

  @override
  String get global_cricket_info_match => 'Match';

  @override
  String get global_cricket_info_series => 'Series';

  @override
  String get global_cricket_info_date => 'Date & time';

  @override
  String get global_cricket_info_venue => 'Venue';

  @override
  String get global_cricket_info_toss => 'Toss';

  @override
  String get global_cricket_info_format => 'Format';

  @override
  String global_cricket_toss_text(String team, String choice) {
    return '$team won the toss and chose to $choice';
  }

  @override
  String global_cricket_starts(String time) {
    return 'Starts $time';
  }

  @override
  String global_cricket_scorecard_updated(String time) {
    return 'Scorecard updated $time · refreshes hourly while live';
  }

  @override
  String get global_cricket_scorecard_not_started =>
      'The scorecard will appear once the match starts.';

  @override
  String get global_cricket_scorecard_sign_in =>
      'Sign in to load the full scorecard.';

  @override
  String get global_cricket_scorecard_limit =>
      'The full scorecard isn\'t available right now (free data limit). The live score above still updates every 30 minutes.';

  @override
  String get global_cricket_scorecard_loading => 'Loading scorecard…';

  @override
  String get home_screen_no_matches_title => 'No Matches in this area!';

  @override
  String get home_screen_no_matches_description_text =>
      'Enjoy the freedom of creating your own cricket matches or teams.';

  @override
  String get home_greeting_morning => 'Good morning!';

  @override
  String get home_greeting_afternoon => 'Good afternoon!';

  @override
  String get home_greeting_evening => 'Good evening!';

  @override
  String get home_greeting_guest => 'Guest mode';

  @override
  String home_section_live(int count) {
    return 'Live matches ($count)';
  }

  @override
  String get home_section_upcoming => 'Upcoming matches';

  @override
  String get home_section_finished => 'Recent results';

  @override
  String home_match_overs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overs match',
      one: '1 over match',
    );
    return '$_temp0';
  }

  @override
  String home_live_need(String team, int runs, int balls) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs runs',
      one: '1 run',
    );
    String _temp1 = intl.Intl.pluralLogic(
      balls,
      locale: localeName,
      other: '$balls balls',
      one: '1 ball',
    );
    return '$team need $_temp0 in $_temp1';
  }

  @override
  String home_live_batting(String team) {
    return '$team batting';
  }

  @override
  String home_live_toss(String team) {
    return '$team won the toss';
  }

  @override
  String get home_live_starting => 'Match about to start';

  @override
  String home_live_target(int target) {
    return 'Target $target';
  }

  @override
  String home_crr(String rate) {
    return 'CRR $rate';
  }

  @override
  String home_rrr(String rate) {
    return 'RRR $rate';
  }

  @override
  String get home_today => 'Today';

  @override
  String get home_tomorrow => 'Tomorrow';

  @override
  String home_result_won_by(String team, String margin) {
    return '$team won by $margin';
  }

  @override
  String get home_search_hint_title => 'Search matches by team name...';

  @override
  String get home_search_empty_title => 'Start your search here!';

  @override
  String get home_search_empty_message =>
      'Type your search above to find what you need fast.';

  @override
  String get home_search_results_title => 'Results';

  @override
  String get home_search_users_title => 'Users';

  @override
  String get home_search_list_empty_title => 'No results';

  @override
  String get home_search_list_empty_message =>
      'We couldn\'t find any results for your search. Please try different keywords.';

  @override
  String get leaderboard_empty_title => 'Nothing to Show Yet';

  @override
  String get leaderboard_empty_description =>
      'No scores available yet. Make your move and take the lead!';

  @override
  String leaderboard_catches_title(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catches',
      one: '$count catch',
      zero: '$count catches',
    );
    return '$_temp0';
  }

  @override
  String get notification_popup_title => 'Turn on notifications?';

  @override
  String get notification_popup_description =>
      'Never miss a moment of your matches. \nTurn on notifications for real-time updates and important match information.';

  @override
  String get notification_popup_later => 'Later';

  @override
  String get my_cricket_screen_title => 'My Cricket';

  @override
  String get my_cricket_header_subtitle =>
      'Your matches, teams and tournaments';

  @override
  String get my_cricket_empty_matches_body =>
      'Create a match, pick both teams and score it ball by ball.';

  @override
  String get my_cricket_empty_teams_body =>
      'Build your squad and invite players to join your team.';

  @override
  String get my_cricket_empty_tournaments_body =>
      'Set up a league or knockout, then add teams and matches.';

  @override
  String get add_tournament_screen_title => 'Add Tournament';

  @override
  String get add_tournament_name => 'Tournament Name';

  @override
  String get add_tournament_type => 'Tournament Type';

  @override
  String get add_tournament_type_placeholder => 'Select tournament type';

  @override
  String get add_tournament_start_date => 'Start Date';

  @override
  String get add_tournament_end_date => 'End Date';

  @override
  String get add_tournament_venue_title => 'Venue';

  @override
  String get add_tournament_match_format_title => 'Match Format';

  @override
  String get add_tournament_schedule_title => 'Tournament Schedule';

  @override
  String get add_tournament_teams_hint =>
      'Tap to pick teams from a tournament team pool';

  @override
  String get add_tournament_change_teams => 'Change teams';

  @override
  String get add_tournament_city => 'City';

  @override
  String get add_tournament_ground => 'Ground / Venue';

  @override
  String get add_tournament_ball_type => 'Ball Type';

  @override
  String get add_tournament_ball_type_placeholder => 'Select ball type';

  @override
  String get add_tournament_overs => 'Overs per match';

  @override
  String add_tournament_overs_hint(int max) {
    return '1 to $max';
  }

  @override
  String add_tournament_details_required(int max) {
    return 'Fill in city, ground, ball type and overs (1–$max) to continue';
  }

  @override
  String get add_tournament_team_selection => 'Team selection';

  @override
  String get add_tournament_match_selection => 'Match selection';

  @override
  String get add_tournament_edit_banner => 'Edit banner';

  @override
  String get add_tournament_add_banner_placeholder => 'Add banner image';

  @override
  String get add_tournament_delete_title => 'Delete tournament!';

  @override
  String get tournament_delete_action => 'Delete tournament';

  @override
  String tournament_delete_title(String name) {
    return 'Delete $name?';
  }

  @override
  String get tournament_delete_message =>
      'The tournament and its scheduled matches are removed. This can\'t be undone.';

  @override
  String tournament_delete_with_pool(String pool) {
    return 'Also delete the team pool \"$pool\" and its teams';
  }

  @override
  String get tournament_delete_pool_note =>
      'Player profiles and stats are kept.';

  @override
  String get error_tournament_has_played_matches =>
      'This tournament has played matches. Their scores and player stats depend on it, so it can\'t be deleted.';

  @override
  String get add_tournament_delete_description =>
      'This action will permanently delete the tournament, along with all match data. Are you sure you want to delete?';

  @override
  String get add_tournament_date_error =>
      'End date should be greater than start date';

  @override
  String add_tournament_select_min_team_error(Object count) {
    return 'Please select minimum $count teams';
  }

  @override
  String add_tournament_teams_title(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Teams',
      one: '$count Team',
      zero: 'No teams',
    );
    return '$_temp0';
  }

  @override
  String get tournament_list_empty_list_title => 'No tournaments created';

  @override
  String get tournament_list_empty_list_description =>
      'Tap on the “ + ” icon to create a tournament';

  @override
  String tournament_list_match_title(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Matches',
      one: '$count Match',
      zero: 'No matches',
    );
    return '$_temp0';
  }

  @override
  String get team_selection_screen_title => 'Select Teams';

  @override
  String get team_selection_select_team_title => 'Select teams';

  @override
  String get team_selection_verify_team_to_add_title => 'Verify teams to add';

  @override
  String get match_selection_screen_title => 'Select Matches';

  @override
  String get match_selection_select_matches_title => 'Select matches';

  @override
  String match_selection_round_title(Object round) {
    return 'Round $round';
  }

  @override
  String get match_selection_no_matches_title => 'No Matches Scheduled Yet';

  @override
  String get match_selection_no_matches_description =>
      'There are currently no matches scheduled. Tap the \'+\' button to schedule new matches.';

  @override
  String match_selection_not_found_title(Object team) {
    return 'No Matches Found for $team';
  }

  @override
  String match_selection_not_found_description(Object team) {
    return 'We couldn’t find any match results for $team at this time. Please check again later.';
  }

  @override
  String get match_group_round_title => 'Round';

  @override
  String get match_group_quarter_final_title => 'Quarter final';

  @override
  String get match_group_semi_final_title => 'Semi final';

  @override
  String get match_group_final_title => 'Final';

  @override
  String get tournament_detail_not_found_title => 'No Tournament found';

  @override
  String get tournament_detail_not_found_description =>
      'The tournament you are looking for is not available.';

  @override
  String tournament_detail_start_from_title(String date) {
    return 'Start from $date';
  }

  @override
  String get tournament_detail_overview_tab => 'Overview';

  @override
  String get tournament_detail_points_table_tab => 'Points Table';

  @override
  String get tournament_detail_edit_title => 'Edit tournament';

  @override
  String get tournament_detail_members_title => 'Members';

  @override
  String get tournament_detail_overview_info_title => 'Tournament info';

  @override
  String get tournament_detail_overview_name_title => 'Tournament Name';

  @override
  String get tournament_detail_overview_type_title => 'Type';

  @override
  String get tournament_detail_overview_duration_title => 'Duration';

  @override
  String get tournament_detail_overview_teams_squads_title => 'Teams Squads';

  @override
  String get tournament_detail_overview_key_stats_title => 'Key Stats';

  @override
  String get tournament_detail_overview_featured_matches_title =>
      'Featured Matches';

  @override
  String get tournament_detail_teams_empty_title => 'Select Your Teams!';

  @override
  String get tournament_detail_teams_empty_description =>
      'You haven\'t added any teams to this tournament yet. Please select or create teams to get started.';

  @override
  String get tournament_detail_teams_select_btn => 'Add teams';

  @override
  String get tournament_detail_matches_empty_title => 'Schedule Your Matches!';

  @override
  String get tournament_detail_matches_empty_description =>
      'Create matches to kick off your tournament and get the games started!';

  @override
  String get tournament_detail_matches_filter_empty_title => 'No Results Found';

  @override
  String get tournament_detail_matches_filter_empty_description =>
      'No matches match the selected filters. Try adjusting them.';

  @override
  String get tournament_detail_matches_add_btn => 'Add matches';

  @override
  String get tournament_detail_matches_filter_by_teams_title =>
      'Filter by teams';

  @override
  String get tournament_detail_matches_filter_all_teams_option => 'All Teams';

  @override
  String get tournament_detail_matches_schedule_btn => 'Schedule Matches';

  @override
  String get tournament_detail_matches_all_status => 'All';

  @override
  String get tournament_detail_matches_live_status => 'Live';

  @override
  String get tournament_detail_matches_upcoming_status => 'Upcoming';

  @override
  String get tournament_detail_matches_past_status => 'Past';

  @override
  String get tournament_detail_matches_live_section => 'Live Matches';

  @override
  String get tournament_detail_matches_upcoming_section => 'Upcoming Matches';

  @override
  String get tournament_detail_matches_past_section => 'Past Matches';

  @override
  String get tournament_detail_matches_no_live => 'No live matches right now';

  @override
  String get tournament_detail_matches_no_upcoming =>
      'No upcoming matches scheduled';

  @override
  String get tournament_detail_matches_no_past =>
      'No past matches recorded yet';

  @override
  String get tournament_schedule_whole_title => 'Schedule Whole Tournament';

  @override
  String get tournament_schedule_whole_description =>
      'Schedule all pending fixtures with default match settings at once.';

  @override
  String get tournament_schedule_all_matches_btn => 'Schedule All Matches';

  @override
  String get tournament_schedule_success_msg =>
      'Successfully scheduled all matches!';

  @override
  String get tournament_schedule_start_date => 'Starting Date & Time';

  @override
  String get tournament_schedule_overs => 'Total Overs';

  @override
  String get tournament_schedule_overs_per_bowler => 'Overs per Bowler';

  @override
  String get tournament_schedule_venue => 'Ground / Venue';

  @override
  String get tournament_schedule_city => 'City';

  @override
  String get tournament_schedule_spacing => 'Match Spacing';

  @override
  String get tournament_schedule_spacing_same_day =>
      'Same day (spaced 3 hours)';

  @override
  String get tournament_schedule_spacing_consecutive => 'Consecutive days';

  @override
  String get tournament_schedule_no_pending =>
      'No pending fixtures to schedule.';

  @override
  String get tournament_detail_key_stat_most_runs_title => 'Most Runs';

  @override
  String get tournament_detail_key_stat_most_wickets_title => 'Most Wickets';

  @override
  String get tournament_detail_key_stat_most_fours_title => 'Most Fours';

  @override
  String get tournament_detail_key_stat_most_sixes_title => 'Most Sixes';

  @override
  String get key_stat_all => 'All';

  @override
  String get key_stat_filter_runs => 'Runs';

  @override
  String get key_stat_filter_wickets => 'Wickets';

  @override
  String get key_stat_filter_fours => 'Fours';

  @override
  String get key_stat_filter_sixes => 'Sixes';

  @override
  String get key_stat_filter_most_hundreds => 'Most hundreds';

  @override
  String get key_stat_filter_most_fifties => 'Most fifties';

  @override
  String get key_stat_filter_boundaries => 'Boundaries';

  @override
  String get tournament_detail_points_table_points_title => 'Points';

  @override
  String get tournament_detail_points_table_empty_title => 'No Points Yet!';

  @override
  String get tournament_detail_points_table_empty_description =>
      'The points table will be updated once matches begin. Stay tuned for the latest standings!';

  @override
  String get tournament_detail_points_table_team => 'Team';

  @override
  String get tournament_detail_points_table_wins => 'W';

  @override
  String get tournament_detail_points_table_losses => 'L';

  @override
  String get tournament_detail_points_table_pts => 'Pts';

  @override
  String get tournament_detail_points_table_nrr => 'NRR';

  @override
  String get tournament_detail_stats_empty_title => 'No stats available yet!';

  @override
  String get tournament_detail_stats_empty_description =>
      'The players are warming up! Stay tuned for exciting stats as the team progresses.';

  @override
  String get tournament_detail_stats_empty_filter_title => 'No Stats Found';

  @override
  String get tournament_detail_stats_empty_filter_description =>
      'Please try a different filter.';

  @override
  String get tournament_detail_stats_player_title => 'Player';

  @override
  String get tournament_detail_stats_avg_title => 'Avg';

  @override
  String get tournament_detail_stats_runs_title => 'Runs';

  @override
  String get tournament_members_empty_title => 'No members yet!';

  @override
  String get tournament_members_empty_description =>
      'Tap the + button to add members and start managing your tournament effectively!';

  @override
  String get tournament_members_search_member_empty_title =>
      'Assign Tournament Role';

  @override
  String get tournament_members_search_member_empty_description =>
      'Search for a user to assign a management role. This role will empower them to help organize and lead the tournament effectively.';

  @override
  String get tournament_members_remove_self => 'Remove self';

  @override
  String get tournament_members_make_organizer => 'Make organizer';

  @override
  String get tournament_members_remove_member => 'Remove member';

  @override
  String get tournament_members_transfer_ownership_description =>
      'Search for a user to transfer tournament ownership. This grants them full management control. Choose someone who can effectively lead the tournament.';

  @override
  String get tournament_type_knock_out => 'Knockout';

  @override
  String get tournament_type_mini_robin => 'Mini Robin';

  @override
  String get tournament_type_box_league => 'Box League';

  @override
  String get tournament_type_double_out => 'Double Out';

  @override
  String get tournament_type_best_of_three => 'Best Of three';

  @override
  String get tournament_type_custom => 'Custom';

  @override
  String tournament_type_knock_out_description(Object count) {
    return 'Teams face off in a single elimination, with the loser immediately knocked out.\nMinimum $count teams required.';
  }

  @override
  String tournament_type_mini_robin_description(Object count) {
    return 'A smaller round-robin format where each team plays once against all others.\nMinimum $count teams required.';
  }

  @override
  String tournament_type_box_league_description(Object count) {
    return 'Teams are divided into groups, with top teams advancing to the knockout stage.\nMinimum $count teams required.';
  }

  @override
  String tournament_type_double_out_description(Object count) {
    return 'Teams get two chances before being knocked out, with a winners and losers bracket.\nMinimum $count teams required.';
  }

  @override
  String tournament_type_best_of_three_description(Object count) {
    return 'Teams play a series of matches, and the first to win the majority is the champion.\nMinimum $count teams required.';
  }

  @override
  String tournament_type_custom_description(Object count) {
    return 'Fully flexible, create a structure that suits your needs.\nMinimum $count teams required.';
  }

  @override
  String get add_team_screen_title => 'Add Team';

  @override
  String get add_team_edit_team_screen_title => 'Edit Team';

  @override
  String get add_team_add_as_member_description_text =>
      'Add me as a team member';

  @override
  String get add_team_enter_team_name_placeholder_text => 'Enter team name';

  @override
  String get add_team_team_initial_placeholder_text =>
      'Team initials (e.g. IND, AUS, PBKS)';

  @override
  String get add_team_player_role_title => 'Playing role';

  @override
  String get add_team_players_text => 'Players';

  @override
  String get add_team_already_added => 'Team already added';

  @override
  String get add_team_add_hint_text =>
      'Added user will be shown here, tap on \'+\' button to add team member.';

  @override
  String get scan_qr_code => 'Scan QR code';

  @override
  String get scan_qr_code_description => 'Place the QR code into the frame';

  @override
  String get scan_qr_permission_title =>
      'Allow camera access to use scanning features';

  @override
  String get scan_qr_permission_description =>
      'Please enable camera access in your device settings to use the scanning feature.';

  @override
  String get scan_qr_permission_settings => 'Go to settings';

  @override
  String get add_team_member_screen_title => 'Add Team Member';

  @override
  String get add_team_member_details_title => 'Details';

  @override
  String get add_team_member_search_placeholder_text =>
      'Search by name or mobile number';

  @override
  String get add_team_member_empty_title => 'Your cricket crew awaits!';

  @override
  String get add_team_member_empty_description_text =>
      'Search for players already on Sports Tamil, or create a new player with just a name — no app account needed.';

  @override
  String get add_team_member_search_no_result_title => 'Oops! No User Found';

  @override
  String get add_team_member_search_description_text =>
      'No one on Sports Tamil by that name. Create them as a new player and add them right away.';

  @override
  String get add_team_member_create_player_title => 'New player';

  @override
  String get add_team_member_create_player_description =>
      'Add a player who isn\'t on Sports Tamil yet. Only the name is required. The mobile number stays private and lets them link their account when they sign up.';

  @override
  String get add_team_member_create_player_name => 'Player name';

  @override
  String get add_team_member_create_player_phone => 'Mobile number (optional)';

  @override
  String get add_team_member_phone_not_found_title =>
      'No player with this number';

  @override
  String get add_team_member_phone_not_found_body =>
      'Create the player with this number. When they sign up with it, they can link their account.';

  @override
  String get add_team_member_create_with_number =>
      'Create player with this number';

  @override
  String add_team_member_phone_invalid(String dial) {
    return 'Enter a valid mobile number. Add the country code if it isn\'t $dial.';
  }

  @override
  String add_team_member_player_exists(String name) {
    return '$name already has this number, so they were added instead.';
  }

  @override
  String get player_phone_checking => 'Checking number…';

  @override
  String player_phone_found(String name) {
    return 'Linked to $name';
  }

  @override
  String get player_phone_found_hint =>
      'Same player everywhere: their profile and stats carry over';

  @override
  String get player_phone_new =>
      'New player. When they sign up with this number, their account is linked';

  @override
  String get player_phone_incomplete => 'Enter the full mobile number';

  @override
  String get player_phone_linked => 'Mobile number linked';

  @override
  String get player_phone_self => 'This number is linked to this player';

  @override
  String player_phone_taken(String name) {
    return 'This number belongs to $name';
  }

  @override
  String player_merge_title(String name) {
    return 'Same player as $name?';
  }

  @override
  String player_merge_message(String current, String name) {
    return '$name already has this number. $current\'s teams, matches and stats move to $name, and the duplicate $current record is removed. This can\'t be undone.';
  }

  @override
  String player_merge_confirm(String name) {
    return 'Merge into $name';
  }

  @override
  String player_merge_hint(String name) {
    return 'This number belongs to $name. Saving merges this player into $name.';
  }

  @override
  String get error_merge_not_allowed =>
      'Only the organizer who added this player can merge it.';

  @override
  String player_phone_add_existing(String name) {
    return 'Add $name';
  }

  @override
  String get add_team_member_create_player_button => 'Create player';

  @override
  String add_team_member_create_named_player(String name) {
    return 'Create \"$name\"';
  }

  @override
  String get add_team_member_added_text => 'ADDED';

  @override
  String get add_team_member_already_added => 'Member already added';

  @override
  String get add_team_member_verify_error_text => 'Please enter correct digits';

  @override
  String add_team_member_verify_placeholder_text(int count) {
    return 'Enter the last $count digits of the phone number of the selected player.';
  }

  @override
  String get team_list_add_members_title => 'Add Members';

  @override
  String get team_list_all_teams_title => 'All teams';

  @override
  String get team_list_created_by_me_title => 'Created by me';

  @override
  String get team_list_me_as_member_title => 'Me as member';

  @override
  String get team_list_me_as_admin_title => 'Me as admin';

  @override
  String get team_list_no_teams_created_title => 'No teams created';

  @override
  String get team_list_empty_list_description =>
      'Tap on the “ + ” icon to create a team';

  @override
  String get match_list_no_match_here_title => 'No matches here';

  @override
  String get match_list_empty_list_description =>
      'Tap on the “ + ” icon to create a match';

  @override
  String match_list_overs_title(int overs) {
    String _temp0 = intl.Intl.pluralLogic(
      overs,
      locale: localeName,
      other: '$overs overs',
      one: '$overs over',
      zero: '$overs overs',
    );
    return '$_temp0';
  }

  @override
  String get add_match_screen_title => 'Add Match';

  @override
  String get add_match_screen_edit_match_title => 'Edit Match';

  @override
  String get add_match_team_b_title => 'B';

  @override
  String get add_match_team_name_placeholder => 'Team Name';

  @override
  String get add_match_match_type_title => 'Match Type';

  @override
  String get add_match_match_type_limited_overs_title => 'Limited overs';

  @override
  String get add_match_match_type_test_match_title => 'Test match';

  @override
  String get add_match_match_type_the_hundred_title => 'The hundred';

  @override
  String get add_match_match_type_pair_cricket_title => 'Pair cricket';

  @override
  String get add_match_match_type_box_cricket_title => 'Box cricket';

  @override
  String get add_match_ball_type_title => 'Ball Type';

  @override
  String get add_match_ball_type_leather_title => 'Leather';

  @override
  String get add_match_ball_type_tennis_title => 'Tennis';

  @override
  String get add_match_pitch_type_title => 'Pitch Type';

  @override
  String get add_match_pitch_type_rough_title => 'Rough';

  @override
  String get add_match_pitch_type_cement_title => 'Cement';

  @override
  String get add_match_pitch_type_turf_title => 'Turf';

  @override
  String get add_match_pitch_type_astroturf_title => 'Astroturf';

  @override
  String get add_match_pitch_type_matting_title => 'Matting';

  @override
  String get add_match_match_officials_title => 'Match Officials';

  @override
  String get match_rules_title => 'Match Rules';

  @override
  String get match_rules_balls_per_over_title => 'Balls per over';

  @override
  String match_rules_balls_per_over_summary(int count) {
    return '$count-ball overs';
  }

  @override
  String get match_rules_wide_runs_title => 'Runs for a wide';

  @override
  String get match_rules_no_ball_runs_title => 'Runs for a no-ball';

  @override
  String get match_rules_wide_rebowl_title => 'Re-bowl wides';

  @override
  String get match_rules_wide_rebowl_description =>
      'When off, a wide counts as one of the balls in the over';

  @override
  String get match_rules_free_hit_title => 'Free hit after no-ball';

  @override
  String get match_rules_free_hit_description =>
      'The next ball after a no-ball can only be a run out';

  @override
  String get match_rules_last_man_standing_title => 'Last man standing';

  @override
  String get match_rules_last_man_standing_description =>
      'The last batter can keep batting alone';

  @override
  String get add_match_officials_umpires_title => 'Umpires';

  @override
  String get add_match_officials_scorers_title => 'Scorers';

  @override
  String get add_match_officials_live_streamers_title => 'Live Streamers';

  @override
  String get add_match_officials_referee_title => 'Referee';

  @override
  String get add_match_officials_commentators_title => 'Commentators';

  @override
  String get add_match_officials_others_title => 'Others';

  @override
  String get add_match_ground_title => 'Ground';

  @override
  String get add_match_match_schedule_title => 'Match Schedule';

  @override
  String get add_match_start_match_title => 'Start Match';

  @override
  String get add_match_date_title => 'Date';

  @override
  String get add_match_time_title => 'Time';

  @override
  String get add_match_no_of_over_title => 'No. of over';

  @override
  String get add_match_over_per_bowler_title => 'Over per bowler';

  @override
  String get add_match_joined_on_title => 'Joined on';

  @override
  String get add_match_officials_screen_title => 'Add Match Officials';

  @override
  String get add_match_officials_add_officials_title => 'Add officials';

  @override
  String get add_match_invalid_over_count_error =>
      'Please enter valid total over';

  @override
  String get add_match_empty_fields_error => 'Please fill the required details';

  @override
  String get add_match_unselected_team_error => 'Please select teams';

  @override
  String get add_match_invalid_squad_error => 'Please select valid squad';

  @override
  String get search_user_hint_title => 'Search user name';

  @override
  String get search_user_empty_title => 'Time to gather your officials!';

  @override
  String get search_user_empty_description_text =>
      'Search and assign officials for your next match. Get ready for cricket action!';

  @override
  String get search_team_screen_title => 'Search Team';

  @override
  String get search_team_selection_error_text =>
      'The team must have at least 2 players to add it in a match.';

  @override
  String get search_team_search_placeholder_title => 'Search team name';

  @override
  String power_play_text(int count) {
    return 'Power play $count';
  }

  @override
  String get select_squad_select_admin_captain_title =>
      'Select Captain and Admin';

  @override
  String get select_squad_captain_short_title => 'C';

  @override
  String get select_squad_playing_squad_title => 'Playing Squad';

  @override
  String get select_squad_least_require_text =>
      '*At-least two players required';

  @override
  String get select_squad_rest_of_team_title => 'Rest of The Team';

  @override
  String get select_squad_empty_squad_text =>
      'Select squad via adding it from team members list.';

  @override
  String get select_squad_empty_team_member_text =>
      'No team member added in this team, try to add people you know as a team member.';

  @override
  String get add_toss_detail_screen_title => 'Add Toss Detail';

  @override
  String get add_toss_detail_who_won_toss_text => 'Who won the toss?';

  @override
  String get add_toss_detail_winner_elected_to_text =>
      'Toss-winner elected to - ?';

  @override
  String get add_substitute_search_substitute_title =>
      'Who’s ready to step in?';

  @override
  String get add_substitute_search_substitute_description =>
      'Search and assign a substitute fielder to maintain your fielding edge.';

  @override
  String get team_detail_screen_title => 'Team Detail';

  @override
  String get team_detail_member_tab_title => 'Member';

  @override
  String get team_detail_empty_matches_title => 'No matches scheduled yet!';

  @override
  String get team_detail_empty_matches_description_text =>
      'Get your cricket game on! Schedule your cricket match with ease!';

  @override
  String get team_detail_visitor_empty_matches_description_text =>
      'Until now, the team has not competed.';

  @override
  String get team_detail_empty_member_title => 'You haven\'t any member!';

  @override
  String get team_detail_empty_member_description_text =>
      'Invite your friends to build your dream team and start tracking matches together.';

  @override
  String get team_detail_visitor_empty_member_description_text =>
      'No member has been added to the team.';

  @override
  String get team_detail_empty_stat_title => 'No stats available yet!';

  @override
  String get team_detail_empty_stat_description_text =>
      'The players are warming up! Stay tuned for exciting stats as the team progresses.';

  @override
  String get team_detail_add_members_title => 'Add members';

  @override
  String get team_detail_add_match_title => 'Add match';

  @override
  String get team_detail_use_qr_description =>
      'Use your phone camera or a QR code app to scan the code above and easily add the team to the tournament';

  @override
  String get make_admin_selection_error =>
      'Can\'t select deactivated user as admin';

  @override
  String team_detail_admin(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count admins',
      one: '$count admin',
      zero: '$count admins',
    );
    return '$_temp0';
  }

  @override
  String get team_detail_remove_ownership_title => 'Remove ownership';

  @override
  String get team_detail_transfer_ownership_description =>
      'Search for a user to transfer team ownership. This grants them full management control. Choose someone who can effectively lead the team.';

  @override
  String get team_detail_match_tab_title => 'Match';

  @override
  String get team_detail_stat_tab_title => 'Stat';

  @override
  String team_detail_won_title(int win) {
    return 'Won($win)';
  }

  @override
  String team_detail_lost_title(int lost) {
    return 'Lost($lost)';
  }

  @override
  String team_detail_tie_title(int tie) {
    return 'Tie($tie)';
  }

  @override
  String team_detail_match_title(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Matches',
      one: '$count Match',
      zero: '$count Matches',
    );
    return '$_temp0';
  }

  @override
  String get team_detail_runs_made_title => 'Runs Made';

  @override
  String get team_detail_wickets_taken_title => 'Wickets Taken';

  @override
  String get team_detail_highest_runs_title => 'Highest Runs';

  @override
  String get team_detail_lowest_runs_title => 'Lowest Runs';

  @override
  String get team_detail_run_rate_title => 'Run Rate';

  @override
  String get user_detail_info_title => 'Info';

  @override
  String get user_detail_personal_information_title => 'Personal information';

  @override
  String get user_detail_participation_title => 'Participation';

  @override
  String get user_detail_role_title => 'Role';

  @override
  String get user_detail_joining_date_title => 'Joining date';

  @override
  String get user_detail_test_title => 'Test';

  @override
  String get user_detail_matches_title => 'Matches';

  @override
  String get user_detail_innings_title => 'Innings';

  @override
  String get user_detail_runs_title => 'Runs';

  @override
  String get user_detail_balls_title => 'Balls';

  @override
  String get user_detail_average_title => 'Average';

  @override
  String get user_detail_strike_rate_title => 'SR';

  @override
  String get user_detail_fours_title => 'Fours';

  @override
  String get user_detail_sixes_title => 'Sixes';

  @override
  String get user_detail_fifties_title => '50s';

  @override
  String get user_detail_hundreds_title => '100s';

  @override
  String get user_detail_ducks_title => 'Ducks';

  @override
  String get user_detail_maidens_title => 'Maidens';

  @override
  String get user_detail_wickets_title => 'Wickets';

  @override
  String get user_detail_eco_title => 'Eco';

  @override
  String get user_detail_no_ball_title => 'NB';

  @override
  String get user_detail_wide_ball_title => 'WB';

  @override
  String get user_detail_catches_title => 'Catches';

  @override
  String get user_detail_run_out_title => 'Run out';

  @override
  String get user_detail_stumping_title => 'Stumping';

  @override
  String get match_status_yet_to_start_title => 'Yet to start';

  @override
  String get match_status_abandoned_title => 'Abandoned';

  @override
  String get wicket_type_bowled_title => 'Bowled';

  @override
  String get wicket_type_caught_title => 'Caught';

  @override
  String get wicket_type_caught_behind_title => 'Caught Behind';

  @override
  String get wicket_type_caught_bowled_title => 'Caught And Bowled';

  @override
  String get wicket_type_leg_before_wicket_title => 'Leg Before Wicket';

  @override
  String get wicket_type_stumped_title => 'Stumped';

  @override
  String get wicket_type_hit_wicket_title => 'Hit Wicket';

  @override
  String get wicket_type_hit_ball_twice_title => 'Hit Ball Twice';

  @override
  String get wicket_type_handled_ball_title => 'Handled Ball';

  @override
  String get wicket_type_obstructing_field_title => 'Obstructing the Field';

  @override
  String get wicket_type_timed_out_title => 'Timed Out';

  @override
  String get wicket_type_retired_title => 'Retired';

  @override
  String get wicket_type_retired_hurt_title => 'Retired Hurt';

  @override
  String get wicket_type_short_timed_out_title => 'TO';

  @override
  String get wicket_type_short_retired_title => 'RT';

  @override
  String get wicket_type_short_retired_hurt_title => 'RTH';

  @override
  String get match_detail_screen_title => 'Match Detail';

  @override
  String get match_detail_commentary_tab_title => 'Commentary';

  @override
  String get match_detail_scorecard_tab_title => 'Scorecard';

  @override
  String get match_detail_squad_tab_title => 'Squad';

  @override
  String get match_detail_match_info_tab_title => 'Info';

  @override
  String get match_detail_highlight_tab_title => 'Highlight';

  @override
  String get match_detail_overs_tab_title => 'Overs';

  @override
  String get match_detail_match_not_started_error_title =>
      'Match has not started yet.';

  @override
  String get match_detail_error_description_text =>
      'The detailed will be available after the start of the match.';

  @override
  String get match_detail_highlight_empty_title =>
      'No highlights currently available.';

  @override
  String get match_detail_highlight_empty_description_text =>
      'No events recorded yet. Check back later for updates and highlights.';

  @override
  String get match_info_match_title => 'Match';

  @override
  String get match_info_date_title => 'Date';

  @override
  String get match_info_toss_title => 'Toss';

  @override
  String get match_info_time_title => 'Time';

  @override
  String get match_info_umpire_title => 'Umpire';

  @override
  String get match_info_referee_title => 'Referee';

  @override
  String get match_info_date_and_time_title => 'Date & Time';

  @override
  String match_info_squad_title(String name) {
    return '$name Squad';
  }

  @override
  String get match_info_venue_title => 'Venue';

  @override
  String get match_info_ground_title => 'Ground';

  @override
  String get match_info_city_title => 'City';

  @override
  String get match_info_captain_short_title => '(c)';

  @override
  String match_info_toss_detail_text(String name, String decision) {
    return '$name won the toss and opt to $decision';
  }

  @override
  String match_commentary_bowler_to_batsman_text(
      String bowler, String batsman) {
    return '$bowler to $batsman';
  }

  @override
  String match_commentary_b_bowler_text(String bowler) {
    return ' b $bowler';
  }

  @override
  String match_commentary_c_fielder_text(String fielder) {
    return ' c $fielder';
  }

  @override
  String match_commentary_by_fielder_text(String fielder) {
    return ' by $fielder';
  }

  @override
  String match_commentary_runs_fours_sixes_text(
      int run, int ballCount, int fours, int sixes) {
    return ' $run($ballCount) [4s-$fours 6s-$sixes]';
  }

  @override
  String match_commentary_runs_text(int run) {
    String _temp0 = intl.Intl.pluralLogic(
      run,
      locale: localeName,
      other: '$run runs',
      one: '$run run',
      zero: 'no runs',
    );
    return '$_temp0';
  }

  @override
  String match_commentary_former_over_short_text(int over) {
    return 'Ov $over';
  }

  @override
  String get match_commentary_four_text => 'Four';

  @override
  String get match_commentary_six_text => 'Six';

  @override
  String get match_commentary_out_text => 'OUT,';

  @override
  String get match_commentary_back_to_attack_text => ' is back to attack';

  @override
  String get match_commentary_end_inning_text_part_1 =>
      ' wraps up their innings, leaving ';

  @override
  String get match_commentary_end_inning_text_part_2 => ' for victory.';

  @override
  String match_commentary_inning_count_text(int count) {
    return 'Inning $count';
  }

  @override
  String get match_scorecard_fall_of_wicket_text => 'Fall of Wicket';

  @override
  String get match_scorecard_over_text => 'Over';

  @override
  String get match_scorecard_run_text => 'Run';

  @override
  String get match_scorecard_power_play_text => 'PowerPlay';

  @override
  String get match_scorecard_run_short_text => 'R';

  @override
  String get match_scorecard_ball_short_text => 'B';

  @override
  String get match_scorecard_fours_short_text => '4s';

  @override
  String get match_scorecard_sixes_short_text => '6s';

  @override
  String get match_scorecard_strike_rate_short_text => 'SR';

  @override
  String get match_scorecard_over_short_text => 'O';

  @override
  String get match_scorecard_maiden_short_text => 'M';

  @override
  String get match_scorecard_wicket_short_text => 'W';

  @override
  String get match_scorecard_no_ball_short_text => 'NB';

  @override
  String get match_scorecard_wide_ball_short_text => 'WB';

  @override
  String get match_scorecard_economy_short_text => 'ECO';

  @override
  String get match_scorecard_batter_text => 'Batter';

  @override
  String get match_scorecard_bowler_text => 'Bowler';

  @override
  String get match_scorecard_not_out_text => 'Not out';

  @override
  String get match_scorecard_did_not_bat_text => 'Did not bat';

  @override
  String match_scorecard_bowler_catcher_short_text(
      String bowler, String fielder) {
    return 'b $bowler c $fielder';
  }

  @override
  String get match_scorecard_extra_text => 'Extra';

  @override
  String get match_scorecard_total_text => 'Total';

  @override
  String get match_scorecard_empty_scorecard_text =>
      'Scorecard will appear once the match starts';

  @override
  String match_scorecard_extras_short_text(
      int bye, int legBye, int wide, int noBall, int penalty) {
    return 'b $bye lb $legBye w $wide  nb $noBall p $penalty';
  }

  @override
  String match_scorecard_wicket_over_text(int wicket, double over) {
    String _temp0 = intl.Intl.pluralLogic(
      wicket,
      locale: localeName,
      other: '$wicket wickets',
      one: '$wicket wicket',
      zero: 'no wickets',
    );
    return '$_temp0 $over over';
  }

  @override
  String match_commentary_trailing_over_short_text(double over) {
    return '($over Ov)';
  }

  @override
  String get match_squad_playing_title => 'Playing';

  @override
  String get match_squad_bench_title => 'Bench';

  @override
  String get match_highlight_filter_all_text => 'All';

  @override
  String get match_highlight_filter_fours_text => 'Fours';

  @override
  String get match_highlight_filter_sixes_text => 'Sixes';

  @override
  String get score_board_screen_title => 'Score Board';

  @override
  String get score_board_wicket_short_text => 'W';

  @override
  String get score_board_no_ball_short_text => 'NB';

  @override
  String get score_board_wide_ball_short_text => 'WB';

  @override
  String get score_board_leg_bye_short_text => 'L';

  @override
  String get score_board_bye_short_text => 'B';

  @override
  String get score_board_zero_text => '0';

  @override
  String get score_board_one_text => '1';

  @override
  String get score_board_two_text => '2';

  @override
  String get score_board_three_text => '3';

  @override
  String get score_board_four_text => '4';

  @override
  String get score_board_four_title => 'Four';

  @override
  String get score_board_six_text => '6';

  @override
  String get score_board_six_title => 'Six';

  @override
  String get score_board_five_or_seven_text => '5, 7';

  @override
  String get score_board_five_text => '5';

  @override
  String get score_board_seven_text => '7';

  @override
  String get score_board_out_text => 'OUT';

  @override
  String get score_board_wicket_text => 'WICKET';

  @override
  String get score_board_leg_bye_text => 'LB';

  @override
  String get score_board_bye_text => 'BYE';

  @override
  String get score_board_undo_title => 'Undo';

  @override
  String get score_board_player_title => 'Player';

  @override
  String get score_board_extras_title => 'Extras';

  @override
  String get score_board_runs_title => 'Runs';

  @override
  String get score_board_not_from_bat_text => 'Not from bat?';

  @override
  String get score_board_is_boundary_text => 'Is that a boundary?';

  @override
  String get score_board_over_complete_title => 'Over complete';

  @override
  String get score_board_inning_complete_title => 'Inning complete';

  @override
  String get score_board_match_complete_title => 'Match complete';

  @override
  String get score_board_match_tied_text => 'The match has been tied';

  @override
  String get score_board_match_tied => 'Match tied';

  @override
  String get score_board_start_next_inning_title => 'Start Next Inning';

  @override
  String get score_board_end_inning_title => 'End Inning';

  @override
  String get score_board_current_team_title => 'Current Team';

  @override
  String get score_board_team_title => 'Team';

  @override
  String get score_board_r_title => 'R';

  @override
  String get score_board_w_title => 'W';

  @override
  String get score_board_o_title => 'O';

  @override
  String get score_board_won_by_title => ' Won By ';

  @override
  String get score_board_won_title => 'Won';

  @override
  String get score_board_by_title => 'by';

  @override
  String get score_board_choose_opening_batsmen_title =>
      'Choose opening Batsmen';

  @override
  String get score_board_choose_fielder_title => 'Choose fielder';

  @override
  String get score_board_injured_tag_title => 'Injured';

  @override
  String get score_board_who_on_strike_title => 'Who\'s on Strike?';

  @override
  String get score_board_who_got_out_title => 'Who got out';

  @override
  String get score_board_start_next_over_title => 'Start Next Over';

  @override
  String get score_board_batsman_title => 'batsMan';

  @override
  String get score_board_bowler_title => 'bowler';

  @override
  String get score_board_change_striker_title => 'Change striker';

  @override
  String get score_board_free_hit_text => 'FREE HIT';

  @override
  String get score_board_edit_match_title => 'Edit match details';

  @override
  String get score_board_replace_player_title => 'Replace player';

  @override
  String get score_board_replace_player_description =>
      'Swap a Playing XI player who hasn\'t batted, bowled or fielded yet';

  @override
  String get score_board_replace_team_title => 'Team';

  @override
  String get score_board_replace_out_title => 'Player going out';

  @override
  String get score_board_replace_in_title => 'Player coming in';

  @override
  String get score_board_replace_no_player_text => 'No eligible players';

  @override
  String get score_board_option_end_match => 'End match';

  @override
  String get score_board_option_handover_scoring => 'Handover scoring';

  @override
  String get score_board_handover_scoring_empty_title =>
      'Handover scoring control';

  @override
  String get score_board_handover_scoring_empty_description =>
      'Find and select another user to hand over the scoring responsibilities. Keep the game flowing with a quick and easy transfer.';

  @override
  String get score_board_can_undo_till_running_over_title =>
      'Undo is only allowed till running over';

  @override
  String get score_board_undo_last_ball_title => 'Undo Last Ball';

  @override
  String get score_board_undo_last_ball_description_text =>
      'are you sure you want to undo last ball?';

  @override
  String get score_board_pause_scoring_title => 'Pause scoring';

  @override
  String get score_board_add_substitute_title => 'Add substitute';

  @override
  String get score_board_substitute_title => 'Substitute';

  @override
  String get score_board_penalty_run_title => 'Penalty run';

  @override
  String get score_board_awarded_to_text => 'Awarded to - ?';

  @override
  String get score_board_continue_with_injured_player_title =>
      'Continue with injured player';

  @override
  String get score_board_show_wheel_for_less_run_title =>
      'Show wheel for 1s, 2s and 3s';

  @override
  String get score_board_show_wheel_for_dot_ball_title =>
      'Show wheel for dot balls';

  @override
  String get score_board_select_fielding_position_title =>
      'Select fielding position';

  @override
  String get score_board_pause_title => 'Pause';

  @override
  String get score_board_revised_target_title => 'Revised target';

  @override
  String get score_board_enter_manual_target_text =>
      'Enter your manually calculated target';

  @override
  String get score_board_runs_text => 'Runs :';

  @override
  String get score_board_in_overs_text => 'in Overs :';

  @override
  String get score_board_confirm_target_text => 'Confirm target';

  @override
  String score_board_current_target_text(num run, num over) {
    String _temp0 = intl.Intl.pluralLogic(
      run,
      locale: localeName,
      other: '$run runs',
      one: '$run run',
      zero: '$run runs',
    );
    String _temp1 = intl.Intl.pluralLogic(
      over,
      locale: localeName,
      other: '$over overs',
      one: '$over over',
      zero: '$over overs',
    );
    return 'Current target is $_temp0 in $_temp1';
  }

  @override
  String get score_board_target_invalid_input_error =>
      'Please enter valid target';

  @override
  String get score_board_pause_scoring_description_text =>
      'are you sure you want to pause scoring?';

  @override
  String get score_board_end_match_description_text =>
      'are you sure you want to end match?';

  @override
  String score_board_run_sup_script_text(String run, Object extra) {
    String _temp0 = intl.Intl.selectLogic(
      run,
      {
        '1': '$extra',
        '2': '$extra²',
        '3': '$extra³',
        '4': '$extra⁴',
        '5': '$extra⁵',
        '6': '$extra⁶',
        '7': '$extra⁷',
        '8': '$extra⁸',
        '9': '$extra⁹',
        'other': '$extra',
      },
    );
    return '$_temp0';
  }

  @override
  String score_board_choose_batsman_title(int pos) {
    return 'Choose Batsman at position $pos';
  }

  @override
  String score_board_choose_bowler_for_over_title(int over) {
    return 'Choose Bowler for over $over';
  }

  @override
  String score_board_end_of_over_by_title(int overNumber, String player) {
    return 'End Of Over $overNumber by $player';
  }

  @override
  String score_board_need_run_text(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Runs',
      one: '$count Run',
      zero: '$count Runs',
    );
    return 'Need $_temp0';
  }

  @override
  String score_board_run_need_in_ball_text(int run, int ball) {
    return 'Need $run in $ball';
  }

  @override
  String get fielding_position_deep_mid_wicket_title => 'Deep mid wicket';

  @override
  String get fielding_position_long_on_title => 'Long on';

  @override
  String get fielding_position_long_off_title => 'Long off';

  @override
  String get fielding_position_deep_cover_title => 'Deep cover';

  @override
  String get fielding_position_deep_point_title => 'Deep point';

  @override
  String get fielding_position_third_man_title => 'Third man';

  @override
  String get fielding_position_deep_fine_leg_title => 'Deep fine leg';

  @override
  String get fielding_position_deep_square_leg_title => 'Deep square leg';

  @override
  String get side_off_title => 'OFF';

  @override
  String get side_leg_title => 'LEG';

  @override
  String get tab_profile_title => 'Profile';

  @override
  String get edit_profile_create_profile_screen_title => 'Create Profile';

  @override
  String get edit_profile_screen_title => 'Edit Profile';

  @override
  String get edit_profile_select_birth_date_placeholder =>
      'Select your date of birth';

  @override
  String get edit_profile_name_placeholder => 'Name';

  @override
  String get edit_profile_email_placeholder => 'Email';

  @override
  String get edit_profile_dob_placeholder => 'Date of birth';

  @override
  String get edit_profile_player_role_placeholder => 'Player role';

  @override
  String get edit_profile_gender_male_title => 'Male';

  @override
  String get edit_profile_gender_female_title => 'Female';

  @override
  String get edit_profile_gender_prefer_not_to_say_title => 'Prefer not to say';

  @override
  String get edit_profile_delete_account_btn_title => 'Delete account';

  @override
  String get edit_profile_delete_account_description_text =>
      'This can not undone. if you delete your account, your data will be gone forever.';

  @override
  String get profile_form_create_heading => 'Create your player profile';

  @override
  String get profile_form_create_subtitle =>
      'Takes less than a minute. Name and mobile number are required.';

  @override
  String get profile_form_edit_heading => 'Your player profile';

  @override
  String get profile_form_edit_subtitle =>
      'Keep your details up to date so teams can find you.';

  @override
  String get profile_form_photo_add => 'Add photo';

  @override
  String get profile_form_photo_change => 'Change photo';

  @override
  String get profile_form_photo_remove => 'Remove';

  @override
  String get profile_form_photo_optional => 'Optional';

  @override
  String get profile_form_section_basic => 'Basic details';

  @override
  String get profile_form_section_personal => 'Personal';

  @override
  String get profile_form_section_cricket => 'Cricket profile';

  @override
  String get profile_form_name_label => 'Full name';

  @override
  String get profile_form_name_hint => 'e.g. Arun Kumar';

  @override
  String get profile_form_phone_label => 'Mobile number';

  @override
  String get profile_form_phone_private => 'Only you can see your number';

  @override
  String get profile_form_email_label => 'Email';

  @override
  String get profile_form_email_hint => 'you@example.com';

  @override
  String get profile_form_location_label => 'City';

  @override
  String get profile_form_location_hint => 'e.g. Chennai';

  @override
  String get profile_form_optional => 'Optional';

  @override
  String get profile_form_required => 'Required';

  @override
  String get profile_form_dob_label => 'Date of birth';

  @override
  String get profile_form_dob_add => 'Add date';

  @override
  String get profile_form_gender_label => 'Gender';

  @override
  String get profile_form_role_label => 'Playing role';

  @override
  String get profile_form_batting_label => 'Batting';

  @override
  String get profile_form_bowling_label => 'Bowling';

  @override
  String get profile_form_choose => 'Choose';

  @override
  String get profile_form_error_name => 'Enter your name (at least 2 letters)';

  @override
  String get profile_form_error_phone_empty => 'Enter your mobile number';

  @override
  String profile_form_error_phone_invalid(String country) {
    return 'Enter a valid $country mobile number';
  }

  @override
  String get profile_form_error_email =>
      'Enter a valid email or leave it empty';

  @override
  String get profile_form_error_photo =>
      'Couldn\'t use that photo. Try another one.';

  @override
  String get profile_form_create_btn => 'Create profile';

  @override
  String get profile_form_save_btn => 'Save changes';

  @override
  String get profile_form_sign_out => 'Not you? Sign out';

  @override
  String get profile_form_country_title => 'Country code';

  @override
  String profile_form_progress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get transfer_teams_title => 'Before You Go...';

  @override
  String get transfer_teams_description =>
      'We\'re sorry to see you go. Before deleting your account, please:\n• Assign new owners and admins for your teams or delete the teams\n• Transfer scoring for ongoing matches\n• Remove any scheduled matches\n•Transfer or assign responsibilities for ongoing tournaments\nThis will ensure everything is properly managed after you leave.';

  @override
  String get transfer_teams_go_to_my_cricket => 'Go to My Cricket';

  @override
  String get profile_settings_title => 'Settings';

  @override
  String get profile_setting_contact_support => 'Contact support';

  @override
  String get profile_setting_privacy_policy_title => 'Privacy policy';

  @override
  String get profile_setting_terms_and_condition_title => 'Terms and condition';

  @override
  String get profile_setting_share_app_title => 'Share app';

  @override
  String get profile_setting_rate_us_title => 'Rate us';

  @override
  String profile_setting_app_version_text(Object version) {
    return 'App Version: $version';
  }

  @override
  String get profile_setting_scan_to_play_text => 'Scan to play!';

  @override
  String get profile_setting_scan_to_play_description =>
      'This QR code allows you to easily add the player to the team.';

  @override
  String get profile_setting_use_scanner_description =>
      'Use your phone camera or a QR code app to scan the code above and easily add the player to the team.';

  @override
  String profile_setting_share_app_message(String androidLink, String iosLink) {
    return 'Elevate your cricket scoring game with Sports Tamil! 🏏\n\nEffortlessly score matches, track stats, and manage your teams.\n\n👉 Download Now:\n📱 Android: $androidLink\n🍎 iOS: $iosLink\n\nStart scoring smarter today!';
  }

  @override
  String get notification_title => 'Notifications';

  @override
  String get notification_turn_on_title =>
      'It seems that your notifications have been turned off. Turn on notifications to stay updated on your teams and matches.';

  @override
  String get notification_turn_on_btn_title => 'Turn on';

  @override
  String get contact_support_screen_title => 'Contact Support';

  @override
  String get contact_support_title_placeholder_text => 'Title';

  @override
  String get contact_support_description_placeholder_text => 'Description...';

  @override
  String get contact_support_attachment => 'Attachment (if any)';

  @override
  String get large_attachment_upload_error_text =>
      'Oops! Your file exceeds the maximum allowed size of 25 MB. Please choose a smaller file and try again.';

  @override
  String get profile_complete_your_profile_title => 'Complete your profile';

  @override
  String get profile_complete_description_title =>
      'Enhance your profile with more details to make it better!';

  @override
  String get profile_section_activity => 'Activity';

  @override
  String get profile_section_preferences => 'Preferences';

  @override
  String get profile_section_support => 'Help & support';

  @override
  String get profile_section_about => 'About';

  @override
  String get profile_edit_button => 'Edit profile';

  @override
  String profile_complete_percent(int percent) {
    return 'Profile $percent% complete';
  }

  @override
  String get profile_complete_finish => 'Finish';

  @override
  String get profile_qr_title => 'My player QR';

  @override
  String get profile_qr_subtitle => 'Teammates scan it to add you';

  @override
  String get profile_stats_subtitle => 'Runs, wickets and match history';

  @override
  String get profile_notifications_off_title => 'Notifications are off';

  @override
  String get profile_notifications_off_body =>
      'Turn them on to hear about your teams and matches.';

  @override
  String get profile_mascot_subtitle => 'Tips and cheers from the tiger';

  @override
  String get profile_section_player_links => 'Player links';

  @override
  String get player_claim_title => 'Is this you?';

  @override
  String player_claim_body(String name, int teams, int matches) {
    return 'An organizer added $name with your mobile number, in $teams teams and $matches matches. Link this player to your account to get those matches and stats.';
  }

  @override
  String get player_claim_yes => 'Yes, that\'s me';

  @override
  String get player_claim_no => 'Not me';

  @override
  String get player_claim_sent =>
      'Request sent. The organizer will confirm it.';

  @override
  String player_claim_request_row(String claimant, String player) {
    return '$claimant says they are $player';
  }

  @override
  String get player_claim_request_hint =>
      'Approving moves this player\'s teams, matches and stats to their account.';

  @override
  String get player_claim_approve => 'Approve';

  @override
  String get player_claim_decline => 'Decline';

  @override
  String player_claim_approved_toast(String player, String claimant) {
    return 'Linked. $player\'s matches and stats now belong to $claimant.';
  }

  @override
  String player_claim_waiting(String player) {
    return 'Waiting for the organizer to confirm $player';
  }

  @override
  String player_claim_declined(String player) {
    return 'The organizer didn\'t confirm $player';
  }

  @override
  String get profile_complete_add_profile_picture => 'Add profile picture';

  @override
  String get profile_complete_add_personal_details => 'Add personal details';

  @override
  String get profile_complete_add_playing_style => 'Add playing style';

  @override
  String get image_picker_choose_option_title => 'Choose an option';

  @override
  String get image_picker_camera_option_text => 'Camera';

  @override
  String get image_picker_gallery_option_text => 'Gallery';

  @override
  String get image_picker_crop_image_title => 'Crop Image';

  @override
  String get batting_style_right_hand_bat_title => 'Right hand bat';

  @override
  String get batting_style_left_hand_bat_title => 'Left hand bat';

  @override
  String get bowling_style_right_arm_fast_title => 'Right arm fast';

  @override
  String get bowling_style_right_arm_medium_title => 'Right arm medium';

  @override
  String get bowling_style_left_arm_fast_title => 'Left arm fast';

  @override
  String get bowling_style_left_arm_medium_title => 'Left arm medium';

  @override
  String get bowling_style_slow_left_arm_orthodox_title =>
      'Slow left arm orthodox';

  @override
  String get bowling_style_slow_left_arm_chinaman_title =>
      'Slow left arm chinaman';

  @override
  String get bowling_style_right_arm_off_break_title => 'Right arm off break';

  @override
  String get bowling_style_right_arm_leg_break_title => 'Right arm leg break';

  @override
  String get player_role_top_order_batter_title => 'Top order batter';

  @override
  String get player_role_middle_order_batter_title => 'Middle order batter';

  @override
  String get player_role_wicket_keeper_batter_title => 'Wicket keeper batter';

  @override
  String get player_role_wicket_keeper_title => 'Wicket keeper';

  @override
  String get player_role_bowler_title => 'Bowler';

  @override
  String get player_role_all_rounder_title => 'All rounder';

  @override
  String get player_role_lower_order_batter_title => 'Lower order batter';

  @override
  String get player_role_opening_batter_title => 'Opening batter';

  @override
  String get tournament_teams_title => 'Tournament Teams';

  @override
  String get tournament_teams_entry_description =>
      'Pools of teams for each series, like GCPL or PSPL';

  @override
  String get tournament_teams_search_hint => 'Search teams';

  @override
  String get tournament_teams_empty_title => 'No teams yet';

  @override
  String get tournament_teams_empty_description =>
      'Add your first team and its players once, then pick it in any tournament.';

  @override
  String get tournament_teams_add_first_team => 'Add your first team';

  @override
  String get tournament_teams_add_team => 'Add team';

  @override
  String get tournament_teams_edit_team => 'Edit team';

  @override
  String tournament_teams_no_search_result(Object query) {
    return 'No teams match “$query”';
  }

  @override
  String tournament_teams_player_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
      zero: 'No players',
    );
    return '$_temp0';
  }

  @override
  String get tournament_teams_delete_title => 'Delete team?';

  @override
  String tournament_teams_delete_description(Object name) {
    return '$name will be removed from your Tournament Teams.';
  }

  @override
  String get tournament_teams_in_use_title => 'Team in use';

  @override
  String tournament_teams_in_use_description(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tournaments',
      one: '1 tournament',
    );
    return '$name is part of $_temp0. Remove it from those tournaments before deleting it.';
  }

  @override
  String get tournament_team_name_label => 'Team name *';

  @override
  String get tournament_team_short_name_label => 'Short name / code';

  @override
  String get tournament_team_captain_label => 'Captain';

  @override
  String get tournament_team_captain_placeholder => 'Select captain (optional)';

  @override
  String get tournament_team_wicket_keeper_label => 'Wicket-keeper';

  @override
  String get tournament_team_add_players => 'Add players';

  @override
  String get tournament_team_players_empty_title => 'No players yet';

  @override
  String get tournament_team_players_empty_description =>
      'Add players so this team is ready for matches.';

  @override
  String get tournament_team_add_player => 'Add player';

  @override
  String get tournament_team_edit_player => 'Edit player';

  @override
  String get tournament_team_player_name_label => 'Player name *';

  @override
  String get tournament_team_player_role_label => 'Role';

  @override
  String get tournament_team_jersey_label => 'Jersey number';

  @override
  String get tournament_team_make_captain => 'Make captain';

  @override
  String get tournament_team_remove_captain => 'Remove as captain';

  @override
  String get tournament_team_make_wicket_keeper => 'Make wicket-keeper';

  @override
  String get tournament_team_remove_wicket_keeper => 'Remove as wicket-keeper';

  @override
  String get tournament_team_remove_player_title => 'Remove player?';

  @override
  String tournament_team_remove_player_description(Object name) {
    return '$name will be removed from this team.';
  }

  @override
  String get tournament_team_captain_short => 'C';

  @override
  String get tournament_team_wicket_keeper_short => 'WK';

  @override
  String get tournament_player_role_batsman => 'Batsman';

  @override
  String get tournament_player_role_bowler => 'Bowler';

  @override
  String get tournament_player_role_all_rounder => 'All-rounder';

  @override
  String get tournament_player_role_wicket_keeper => 'Wicket-keeper';

  @override
  String get tournament_team_picker_title => 'Select teams';

  @override
  String get tournament_team_picker_select_all => 'Select all';

  @override
  String get tournament_team_picker_clear => 'Clear';

  @override
  String get tournament_team_picker_add_new => '+ Add new team';

  @override
  String get tournament_team_picker_min_teams =>
      'Select at least 2 teams to continue';

  @override
  String tournament_team_picker_done(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teams',
      one: '1 team',
    );
    return 'Continue with $_temp0';
  }

  @override
  String tournament_team_picker_selected(int count) {
    return '$count selected';
  }

  @override
  String get tournament_team_picker_not_in_pool => 'Not in Tournament Teams';

  @override
  String get tournament_team_picker_choose_pool =>
      'Choose a pool to see its teams';

  @override
  String get tournament_team_picker_switch_pool_title =>
      'Clear current selection?';

  @override
  String tournament_team_picker_switch_pool_description(
      String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected teams',
      one: '1 selected team',
    );
    return 'Switching to $name clears $_temp0.';
  }

  @override
  String get tournament_team_picker_switch => 'Switch';

  @override
  String get team_pools_search_hint => 'Search pools';

  @override
  String get team_pools_empty_title => 'No pools yet';

  @override
  String get team_pools_empty_description =>
      'Create a pool for each tournament series, like “GCPL Teams”, then add its teams and players.';

  @override
  String get team_pools_create_first => 'Create your first pool';

  @override
  String get team_pools_new_pool => 'New pool';

  @override
  String get team_pools_add_new => '+ New pool';

  @override
  String get team_pools_edit_pool => 'Edit pool';

  @override
  String get team_pools_name_label => 'Pool name *';

  @override
  String get team_pools_short_name_label => 'Short code';

  @override
  String team_pools_team_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teams',
      one: '1 team',
      zero: 'No teams',
    );
    return '$_temp0';
  }

  @override
  String team_pools_no_search_result(String query) {
    return 'No pools match “$query”';
  }

  @override
  String get team_pools_ungrouped => 'Ungrouped teams';

  @override
  String get team_pools_ungrouped_description =>
      'Teams created before pools. Move them into a pool.';

  @override
  String get team_pools_delete_title => 'Delete pool?';

  @override
  String team_pools_delete_description(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teams',
      one: '1 team',
      zero: 'teams',
    );
    return 'Delete $name and its $_temp0? Players are kept.';
  }

  @override
  String get team_pools_in_use_title => 'Pool in use';

  @override
  String team_pools_in_use_description(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tournaments',
      one: '1 tournament',
    );
    return '$name has teams in $_temp0. Remove them from those tournaments before deleting the pool.';
  }

  @override
  String get team_pools_move_to_pool => 'Move to pool…';

  @override
  String get team_pools_team_actions => 'Team actions';

  @override
  String get team_pools_no_other_pools => 'Create another pool first.';

  @override
  String get team_pool_teams_empty_title => 'No teams in this pool';

  @override
  String get team_pool_teams_empty_description =>
      'Add the teams and players for this series.';

  @override
  String get error_duplicate_team_name =>
      'A team with this name already exists in this pool.';

  @override
  String get error_duplicate_player_name =>
      'This player is already in the team.';

  @override
  String error_player_in_other_team(
      String player, String team, String tournament) {
    return '$player is already in $team in $tournament. A player can play for one team per tournament.';
  }

  @override
  String error_player_in_two_teams(String player, String team, String other) {
    return '$player is in both $team and $other. A player can play for one team per tournament.';
  }

  @override
  String get error_this_tournament => 'this tournament';

  @override
  String get error_duplicate_jersey_number =>
      'This jersey number is already taken in this team.';

  @override
  String get error_team_used_in_tournament =>
      'This team is used in a tournament and can\'t be deleted.';

  @override
  String get error_duplicate_pool_name =>
      'A pool with this name already exists.';

  @override
  String get error_pool_used_in_tournament =>
      'This pool has teams used in a tournament and can\'t be deleted.';

  @override
  String get tab_play_title => 'Play';

  @override
  String get play_screen_title => 'Play Cricket';

  @override
  String get play_guest_title => 'Playing as Guest';

  @override
  String get play_guest_description =>
      'Your scores show as \"Guest\". Sign in to use your name and challenge friends.';

  @override
  String get play_guest_challenge_hint => 'Sign in to challenge';

  @override
  String get play_daily_title => 'Daily Challenge';

  @override
  String play_daily_target(int target) {
    return 'Chase $target in 2 overs';
  }

  @override
  String play_daily_best(String score) {
    return 'Your best today: $score';
  }

  @override
  String get play_daily_not_played =>
      'Same balls for everyone today. Can you chase it?';

  @override
  String play_daily_players(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players today',
      one: '1 player today',
      zero: 'Be the first to play today',
    );
    return '$_temp0';
  }

  @override
  String get play_quick_play => 'Quick Play';

  @override
  String get play_quick_play_hint => '2 overs · 3 wickets';

  @override
  String get play_challenge_friend => 'Challenge';

  @override
  String get play_challenge_friend_hint => 'Beat a friend\'s score';

  @override
  String get play_how_to =>
      'Tap anywhere as the ball reaches the bat. Perfect timing hits a six; miss a ball on the stumps and you\'re bowled.';

  @override
  String get play_challenges_title => 'Challenges';

  @override
  String play_challenge_incoming(String name, int runs) {
    return '$name challenged you · beat $runs';
  }

  @override
  String play_challenge_waiting(String name, String score) {
    return 'Waiting for $name · you scored $score';
  }

  @override
  String play_challenge_result(String me, String other, String name) {
    return '$me vs $other · $name';
  }

  @override
  String get play_challenge_play => 'Play';

  @override
  String get play_result_won => 'Won';

  @override
  String get play_result_lost => 'Lost';

  @override
  String get play_result_tie => 'Tie';

  @override
  String get play_leaderboard_title => 'Leaderboard';

  @override
  String get play_leaderboard_today => 'Today';

  @override
  String get play_leaderboard_week => 'This week';

  @override
  String get play_leaderboard_empty =>
      'No scores yet. Play a game to get on the board!';

  @override
  String get play_recent_title => 'Recent Games';

  @override
  String get play_recent_empty => 'Your games will show up here.';

  @override
  String get play_mode_solo => 'Quick Play';

  @override
  String get play_mode_daily => 'Daily';

  @override
  String get play_mode_challenge => 'Challenge';

  @override
  String play_balls(int count) {
    return '$count balls';
  }

  @override
  String get play_select_opponent_title => 'Challenge a friend';

  @override
  String get play_select_opponent_hint => 'Search players by name';

  @override
  String get play_select_opponent_empty => 'No players found';

  @override
  String get play_game_tap_to_start => 'Tap to start';

  @override
  String play_game_balls_left(int count) {
    return '$count balls left';
  }

  @override
  String play_game_need(int runs, int balls) {
    return 'Need $runs off $balls';
  }

  @override
  String play_game_vs(String name) {
    return 'vs $name';
  }

  @override
  String get play_shot_six => 'SIX!';

  @override
  String get play_shot_four => 'FOUR!';

  @override
  String get play_shot_two => '2 runs';

  @override
  String get play_shot_single => '1 run';

  @override
  String get play_shot_dot => 'Dot ball';

  @override
  String get play_shot_out => 'OUT!';

  @override
  String get play_timing_perfect => 'Perfect timing';

  @override
  String get play_timing_early => 'Early';

  @override
  String get play_timing_late => 'Late';

  @override
  String get play_timing_left => 'Left alone';

  @override
  String get play_end_title => 'Innings over';

  @override
  String play_end_score(int runs, int wickets, int balls) {
    return '$runs/$wickets in $balls balls';
  }

  @override
  String get play_end_target_won => 'Target chased!';

  @override
  String play_end_target_lost(int target) {
    return 'Fell short of $target';
  }

  @override
  String play_end_challenge_sent(String name) {
    return 'Challenge sent to $name';
  }

  @override
  String play_end_challenge_won(String name) {
    return 'You beat $name!';
  }

  @override
  String play_end_challenge_lost(String name) {
    return '$name wins this one';
  }

  @override
  String play_end_challenge_tie(String name) {
    return 'It\'s a tie with $name';
  }

  @override
  String get play_end_saving => 'Saving…';

  @override
  String get play_again => 'Play again';

  @override
  String get play_done => 'Done';

  @override
  String get play_retry_save => 'Retry';

  @override
  String play_comm_six_0(String name) {
    return '$name launches it over long-on. That\'s huge!';
  }

  @override
  String play_comm_six_1(String name) {
    return 'Into the crowd! A monster hit from $name.';
  }

  @override
  String play_comm_six_2(String name) {
    return 'Clean strike from $name, and that\'s out of the ground!';
  }

  @override
  String play_comm_four_0(String name) {
    return '$name finds the gap and it races away to the rope.';
  }

  @override
  String play_comm_four_1(String name) {
    return 'Beautifully timed by $name. Four runs.';
  }

  @override
  String play_comm_four_2(String name) {
    return 'Through the covers by $name. Nobody\'s stopping that.';
  }

  @override
  String play_comm_two_0(String name) {
    return '$name pushes it into the gap and comes back for two.';
  }

  @override
  String play_comm_two_1(String name) {
    return 'Good running from $name. Two more.';
  }

  @override
  String play_comm_two_2(String name) {
    return 'Worked away by $name for a couple.';
  }

  @override
  String play_comm_single_0(String name) {
    return '$name nudges it for a quick single.';
  }

  @override
  String play_comm_single_1(String name) {
    return 'Just a single. $name keeps the board moving.';
  }

  @override
  String play_comm_single_2(String name) {
    return 'Soft hands from $name. One run.';
  }

  @override
  String get play_comm_dot_0 => 'Dot ball. Tight from the bowler.';

  @override
  String play_comm_dot_1(String name) {
    return '$name can\'t get that one away.';
  }

  @override
  String get play_comm_dot_2 => 'Beaten! That one went past the edge.';

  @override
  String get play_comm_out_0 => 'Bowled! The stumps are everywhere.';

  @override
  String play_comm_out_1(String name) {
    return 'Clean bowled! $name has to walk back.';
  }

  @override
  String play_comm_out_2(String name) {
    return 'Timber! What a ball to get rid of $name.';
  }

  @override
  String get play_you => 'You';

  @override
  String get play_sound_on => 'Sound on';

  @override
  String get play_sound_off => 'Sound off';

  @override
  String get play_this_over => 'This over';

  @override
  String play_hud_overs(String overs, int total) {
    return 'Overs $overs/$total';
  }

  @override
  String play_hud_target(int target) {
    return 'Target $target';
  }

  @override
  String get play_mode_match => 'Live match';

  @override
  String get play_format_title => 'Pick the format';

  @override
  String get play_format_subtitle =>
      'Both of you face the same balls. Highest score wins.';

  @override
  String get play_format_quick => 'Quick';

  @override
  String get play_format_classic => 'Classic';

  @override
  String get play_format_long => 'Long';

  @override
  String play_format_detail(int overs, int wickets) {
    String _temp0 = intl.Intl.pluralLogic(
      overs,
      locale: localeName,
      other: '$overs overs',
      one: '1 over',
    );
    return '$_temp0 · $wickets wickets';
  }

  @override
  String get play_send_request => 'Send match request';

  @override
  String get play_online_now => 'Online now';

  @override
  String get play_recent_opponents => 'Played before';

  @override
  String get play_online_label => 'Online';

  @override
  String get play_select_opponent_more => 'Type a name to find more players';

  @override
  String get play_select_opponent_none_online =>
      'No one else is on Play right now. Search for a friend and send a request.';

  @override
  String play_match_waiting_title(String name) {
    return 'Waiting for $name';
  }

  @override
  String get play_match_waiting_body =>
      'Your match request is on its way. It expires in 10 minutes.';

  @override
  String get play_match_cancel => 'Cancel request';

  @override
  String play_match_declined(String name) {
    return '$name can\'t play right now.';
  }

  @override
  String get play_match_cancelled => 'This match request was cancelled.';

  @override
  String get play_match_expired => 'This match request expired.';

  @override
  String get play_match_back => 'Back to Play';

  @override
  String play_match_incoming_title(String name) {
    return '$name challenges you!';
  }

  @override
  String play_match_incoming_body(String format) {
    return 'Live match · $format. Ready to play?';
  }

  @override
  String get play_match_accept => 'Accept';

  @override
  String get play_match_decline => 'Decline';

  @override
  String get play_match_section => 'Live matches';

  @override
  String play_match_request_from(String name, String format) {
    return '$name wants to play · $format';
  }

  @override
  String play_match_request_to(String name, String format) {
    return 'Waiting for $name · $format';
  }

  @override
  String play_match_in_progress(String name, String format) {
    return 'Live vs $name · $format';
  }

  @override
  String get play_match_join => 'Join';

  @override
  String get play_match_unavailable => 'This match is no longer available.';

  @override
  String get play_challenge_live_hint => 'Live 1v1 match';

  @override
  String get play_vs => 'VS';

  @override
  String get play_toss_title => 'Toss time';

  @override
  String get play_toss_call_prompt => 'Call it!';

  @override
  String get play_toss_heads => 'Heads';

  @override
  String get play_toss_tails => 'Tails';

  @override
  String play_toss_waiting_call(String name) {
    return '$name is calling the toss…';
  }

  @override
  String play_toss_called(String name, String call) {
    return '$name called $call';
  }

  @override
  String get play_toss_won => 'You won the toss!';

  @override
  String play_toss_lost(String name) {
    return '$name won the toss';
  }

  @override
  String get play_toss_choose => 'Bat or bowl first?';

  @override
  String get play_toss_bat => 'Bat first';

  @override
  String get play_toss_bowl => 'Bowl first';

  @override
  String play_toss_waiting_choice(String name) {
    return '$name is choosing…';
  }

  @override
  String play_bats_first(String name) {
    return '$name bats first';
  }

  @override
  String get play_live_your_innings => 'Your innings';

  @override
  String play_live_batting(String name) {
    return '$name is batting';
  }

  @override
  String get play_live_watch_first => 'Watch live. You chase this score next.';

  @override
  String play_live_watch_second(String name, int target) {
    return 'Watch live. $name needs $target to win.';
  }

  @override
  String get play_live_waiting_ball => 'Waiting for the next ball…';

  @override
  String get play_innings_break => 'Innings break';

  @override
  String play_innings_break_body(
      String name, String score, String chaser, int target) {
    return '$name scored $score. $chaser needs $target to win.';
  }

  @override
  String get play_countdown_go => 'GO!';

  @override
  String get play_get_ready => 'Get ready';

  @override
  String play_opponent_offline(String name) {
    return '$name disconnected. Waiting for them to come back…';
  }

  @override
  String get play_claim_win => 'Claim win';

  @override
  String get play_leave_title => 'Leave the match?';

  @override
  String play_leave_body(String name) {
    return 'You will forfeit and $name wins.';
  }

  @override
  String get play_leave_confirm => 'Forfeit';

  @override
  String get play_leave_stay => 'Stay';

  @override
  String play_result_by_runs(String name, int runs) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs runs',
      one: '1 run',
    );
    return '$name won by $_temp0';
  }

  @override
  String play_result_by_wickets(String name, int wickets) {
    String _temp0 = intl.Intl.pluralLogic(
      wickets,
      locale: localeName,
      other: '$wickets wickets',
      one: '1 wicket',
    );
    return '$name won by $_temp0';
  }

  @override
  String get play_result_tied => 'It\'s a tie!';

  @override
  String play_result_forfeit(String name) {
    return '$name won. The other player left.';
  }

  @override
  String get play_result_you_win => 'YOU WIN!';

  @override
  String get play_result_you_lose => 'YOU LOSE';

  @override
  String get play_result_tie_banner => 'TIE!';

  @override
  String get play_scorecard => 'Scorecard';

  @override
  String get play_sc_runs => 'R';

  @override
  String get play_sc_balls => 'B';

  @override
  String get play_sc_fours => '4s';

  @override
  String get play_sc_sixes => '6s';

  @override
  String get play_sc_strike_rate => 'SR';

  @override
  String get play_rematch => 'Rematch';

  @override
  String play_xp_earned(int xp) {
    return '+$xp XP';
  }

  @override
  String play_level(int level) {
    return 'Level $level';
  }

  @override
  String play_xp_progress(int xp, int next) {
    return '$xp/$next XP';
  }

  @override
  String play_stat_streak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day streak',
      one: '1-day streak',
      zero: 'No streak',
    );
    return '$_temp0';
  }

  @override
  String play_stat_wins(int wins) {
    String _temp0 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins wins',
      one: '1 win',
    );
    return '$_temp0';
  }

  @override
  String play_stat_best(int runs) {
    return 'Best $runs';
  }

  @override
  String get play_badges_title => 'Badges';

  @override
  String get play_badge_first_six => 'First six';

  @override
  String get play_badge_six_hitter => '3 sixes in a game';

  @override
  String get play_badge_thirty => '30 in a game';

  @override
  String get play_badge_match_winner => 'Won a live match';

  @override
  String get play_badge_daily_streak => '3-day streak';

  @override
  String get play_badge_century => '100 career runs';

  @override
  String get play_badge_veteran => '25 games played';

  @override
  String play_badge_unlocked(String badge) {
    return 'Badge unlocked: $badge';
  }

  @override
  String get profile_my_stats => 'My stats';

  @override
  String get tab_auction_title => 'Auction';

  @override
  String get auction_screen_title => 'Player Auctions';

  @override
  String get auction_hero_title => 'Run a player auction';

  @override
  String get auction_hero_subtitle =>
      'Register players, set retained players and run live bidding. The tournament is created for you at the end.';

  @override
  String get auction_create_title => 'Create auction';

  @override
  String get auction_sign_in_to_create => 'Sign in to create';

  @override
  String get auction_section_mine => 'My auctions';

  @override
  String get auction_section_live => 'Live now';

  @override
  String get auction_section_upcoming => 'Upcoming';

  @override
  String get auction_section_completed => 'Completed';

  @override
  String get auction_empty => 'No auctions yet.';

  @override
  String get auction_empty_body =>
      'Create one to register players and run live bidding.';

  @override
  String auction_hero_stat_live(int count) {
    return '$count live';
  }

  @override
  String auction_hero_stat_upcoming(int count) {
    return '$count upcoming';
  }

  @override
  String auction_hero_stat_completed(int count) {
    return '$count completed';
  }

  @override
  String get auction_not_found =>
      'This auction doesn\'t exist or isn\'t public yet.';

  @override
  String get auction_status_draft => 'Draft';

  @override
  String get auction_status_upcoming => 'Upcoming';

  @override
  String get auction_status_live => 'Live';

  @override
  String get auction_status_paused => 'Paused';

  @override
  String get auction_status_completed => 'Completed';

  @override
  String auction_tile_summary(int teams, int players) {
    return '$teams teams · $players players';
  }

  @override
  String auction_progress(int done, int total) {
    return '$done/$total processed';
  }

  @override
  String get auction_progress_label => 'Auction progress';

  @override
  String auction_pts(int amount) {
    return '$amount pts';
  }

  @override
  String get auction_edit_title => 'Edit auction';

  @override
  String get auction_name_label => 'Auction name';

  @override
  String get auction_name_hint => 'e.g. GCPL Auction';

  @override
  String get auction_tournament_name_label => 'Tournament name';

  @override
  String get auction_tournament_name_hint => 'e.g. GCPL';

  @override
  String get auction_tournament_name_help =>
      'The tournament created when the auction is completed gets this name.';

  @override
  String get auction_description_label => 'Description';

  @override
  String get auction_description_hint =>
      'Season, venue, anything players should know';

  @override
  String get auction_date_label => 'Auction date';

  @override
  String get auction_date_pick => 'Pick a date';

  @override
  String get auction_banner_add => 'Add banner';

  @override
  String get auction_banner_change => 'Change banner';

  @override
  String get auction_rules_title => 'Budget and bidding';

  @override
  String get auction_team_budget => 'Team budget (pts)';

  @override
  String get auction_base_price => 'Starting bid (pts)';

  @override
  String get auction_bid_increment => 'Bid increment (pts)';

  @override
  String get auction_min_squad => 'Min squad (0 = none)';

  @override
  String get auction_max_squad => 'Max squad (0 = no limit)';

  @override
  String get auction_show_budgets => 'Show team budgets on the public screen';

  @override
  String get auction_teams_title => 'Teams';

  @override
  String auction_team_name(int number) {
    return 'Team $number name';
  }

  @override
  String get auction_team_short => 'Short';

  @override
  String get auction_add_team => 'Add team';

  @override
  String get auction_teams_locked =>
      'Teams can\'t change after the auction starts.';

  @override
  String get auction_admins_title => 'Admins';

  @override
  String get auction_admins_help => 'Admins can edit and run this auction.';

  @override
  String get auction_add_admin => 'Add admin';

  @override
  String get auction_select_admin => 'Select an admin';

  @override
  String get auction_creator => 'Creator';

  @override
  String get auction_save => 'Save';

  @override
  String get auction_validation_name =>
      'Enter the auction name and tournament name';

  @override
  String get auction_validation_teams => 'Add at least 2 teams with names';

  @override
  String get auction_validation_team_names => 'Team names must be different';

  @override
  String get auction_validation_rules =>
      'Budget, starting bid and increment must be above 0, and min squad can\'t be more than max squad';

  @override
  String get auction_players_title => 'Players';

  @override
  String auction_players_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
    );
    return '$_temp0';
  }

  @override
  String get auction_players_empty =>
      'No players yet. Add them one by one, paste a list, or upload photos named after the players.';

  @override
  String get auction_player_search => 'Search name, ID or number';

  @override
  String get auction_filter_all => 'All';

  @override
  String get auction_player_status_available => 'Available';

  @override
  String get auction_player_status_retained => 'Retained';

  @override
  String get auction_player_status_in_auction => 'In auction';

  @override
  String get auction_player_status_sold => 'Sold';

  @override
  String get auction_player_status_unsold => 'Unsold';

  @override
  String get auction_add_player => 'Add player';

  @override
  String get auction_edit_player => 'Edit player';

  @override
  String get auction_add_players_bulk => 'Add many';

  @override
  String get auction_upload_photos => 'Upload photos';

  @override
  String get auction_bulk_title => 'Add many players';

  @override
  String get auction_bulk_hint =>
      'One player per line:\nName, Player ID, Number, Role, Base price\nOnly the name is required. Roles: bat, bowl, all, wk';

  @override
  String auction_bulk_result(int added, int skipped) {
    return '$added added, $skipped duplicates skipped';
  }

  @override
  String get auction_player_name => 'Player name';

  @override
  String get auction_player_code => 'Player ID';

  @override
  String get auction_player_number => 'Number';

  @override
  String get auction_player_base => 'Base price';

  @override
  String get auction_photo_add => 'Add photo';

  @override
  String get auction_photo_change => 'Change photo';

  @override
  String get auction_remove_player => 'Remove player';

  @override
  String auction_remove_player_confirm(String name) {
    return 'Remove $name from the auction?';
  }

  @override
  String get auction_photos_title => 'Match photos to players';

  @override
  String get auction_photos_help =>
      'Photos are matched by file name: player ID, number or name, e.g. P001.jpg, 7.jpg or Arun Kumar.jpg.';

  @override
  String auction_photos_summary(int matched, int unmatched) {
    return '$matched matched · $unmatched not matched';
  }

  @override
  String get auction_photo_skip => 'Skip';

  @override
  String auction_photo_new_player(String name) {
    return 'New player: $name';
  }

  @override
  String auction_photos_upload(int count) {
    return 'Upload $count';
  }

  @override
  String auction_photos_done(int count) {
    return '$count photos uploaded';
  }

  @override
  String get auction_pick_player => 'Pick a player';

  @override
  String get auction_retained_title => 'Retained players';

  @override
  String get auction_retained_help =>
      'Retained players join their team before bidding, skip the auction, and their cost comes out of the team budget.';

  @override
  String get auction_retain_add => 'Retain player';

  @override
  String get auction_retained_none => 'No retained players';

  @override
  String get auction_retain_price => 'Retained cost (pts)';

  @override
  String get auction_release => 'Release';

  @override
  String auction_budget_line(int spent, int remaining, int budget) {
    return '$spent spent · $remaining left of $budget';
  }

  @override
  String auction_remaining(int amount) {
    return '$amount left';
  }

  @override
  String get auction_tab_live => 'Live';

  @override
  String get auction_tab_teams => 'Teams';

  @override
  String get auction_tab_players => 'Players';

  @override
  String get auction_tab_history => 'History';

  @override
  String get auction_setup_title => 'Get the auction ready';

  @override
  String get auction_setup_details => 'Details and teams';

  @override
  String auction_setup_players(int count) {
    return 'Players ($count)';
  }

  @override
  String auction_setup_retained(int count) {
    return 'Retained players ($count)';
  }

  @override
  String get auction_publish => 'Publish';

  @override
  String get auction_publish_help =>
      'Published auctions are visible to everyone, even without signing in.';

  @override
  String get auction_unpublish => 'Back to draft';

  @override
  String get auction_start => 'Start auction';

  @override
  String auction_starts_on(String date) {
    return 'Starts $date';
  }

  @override
  String get auction_not_started => 'The auction hasn\'t started yet.';

  @override
  String get auction_view_only => 'Live view · updates automatically';

  @override
  String auction_player_of(int current, int total) {
    return 'Player $current of $total';
  }

  @override
  String auction_base(int amount) {
    return 'Base $amount pts';
  }

  @override
  String get auction_current_bid => 'Current bid';

  @override
  String get auction_no_bids => 'No bids yet';

  @override
  String get auction_bidding_closed => 'Bidding not started';

  @override
  String auction_leading(String team) {
    return '$team leading';
  }

  @override
  String get auction_paused_banner => 'The auction is paused';

  @override
  String get auction_prev_player => 'Previous';

  @override
  String get auction_next_player => 'Next player';

  @override
  String get auction_start_bidding => 'Start bidding';

  @override
  String auction_bid_amount(int amount) {
    return 'Bid $amount';
  }

  @override
  String get auction_undo_bid => 'Undo bid';

  @override
  String get auction_sell => 'Sell player';

  @override
  String get auction_mark_unsold => 'Mark unsold';

  @override
  String get auction_pause => 'Pause';

  @override
  String get auction_resume => 'Resume';

  @override
  String auction_reopen_unsold(int count) {
    return 'Re-auction unsold ($count)';
  }

  @override
  String get auction_all_processed => 'Every player has been processed';

  @override
  String auction_last_sold(String player, String team, int amount) {
    return '$player → $team · $amount pts';
  }

  @override
  String get auction_count_sold => 'Sold';

  @override
  String get auction_count_unsold => 'Unsold';

  @override
  String get auction_count_retained => 'Retained';

  @override
  String get auction_count_left => 'Left';

  @override
  String get auction_tag_retained => 'RETAINED';

  @override
  String get auction_tag_sold => 'SOLD';

  @override
  String get auction_squad_empty => 'No players yet';

  @override
  String get auction_show_now => 'Put up now';

  @override
  String get auction_history_empty => 'No activity yet';

  @override
  String get auction_log_created => 'Auction created';

  @override
  String get auction_log_published => 'Auction published';

  @override
  String get auction_log_started => 'Auction started';

  @override
  String get auction_log_paused => 'Auction paused';

  @override
  String get auction_log_resumed => 'Auction resumed';

  @override
  String auction_log_shown(String player) {
    return '$player is up';
  }

  @override
  String auction_log_bidding_started(String player) {
    return 'Bidding open for $player';
  }

  @override
  String auction_log_bid(String team, int amount, String player) {
    return '$team bid $amount for $player';
  }

  @override
  String auction_log_bid_undone(int amount, String team) {
    return 'Bid of $amount by $team undone';
  }

  @override
  String auction_log_sold(String player, String team, int amount) {
    return '$player sold to $team for $amount';
  }

  @override
  String auction_log_unsold(String player) {
    return '$player unsold';
  }

  @override
  String get auction_log_reopened => 'Unsold players back in the pool';

  @override
  String auction_log_retained(String player, String team, int amount) {
    return '$player retained by $team for $amount';
  }

  @override
  String auction_log_released(String player) {
    return '$player released';
  }

  @override
  String get auction_log_completed =>
      'Auction completed and tournament created';

  @override
  String get auction_share => 'Copy public link';

  @override
  String get auction_link_copied => 'Public link copied';

  @override
  String get auction_edit => 'Edit details';

  @override
  String get auction_manage_players => 'Manage players';

  @override
  String get auction_manage_retained => 'Retained players';

  @override
  String get auction_delete => 'Delete auction';

  @override
  String get auction_delete_confirm =>
      'Delete this auction, its history and photos? A tournament already created from it is kept.';

  @override
  String get auction_complete => 'Complete auction';

  @override
  String auction_complete_message(String name, int teams) {
    return 'This ends the auction and creates the tournament \"$name\" with $teams teams and their players. No matches, fixtures or dates are created.';
  }

  @override
  String auction_complete_left(int count) {
    return '$count players were never auctioned. They will be marked unsold.';
  }

  @override
  String get auction_complete_blocked =>
      'A player with bids is still up. Sell them or undo the bids first.';

  @override
  String get auction_complete_confirm => 'Complete and create tournament';

  @override
  String auction_tournament_created(String name) {
    return 'Tournament created: $name';
  }

  @override
  String get auction_open_tournament => 'Open tournament';

  @override
  String get auction_home => 'Home';

  @override
  String get auction_create_tournament_retry => 'Create tournament';

  @override
  String auction_create_tournament_retry_message(String name, int teams) {
    return 'The auction is complete but its tournament wasn\'t created. Create \"$name\" with $teams teams and their players now. No matches, fixtures or dates are created.';
  }

  @override
  String get auction_error_not_editable =>
      'This can only be changed before the auction starts.';

  @override
  String get auction_error_not_live => 'The auction isn\'t live.';

  @override
  String get auction_error_paused => 'The auction is paused.';

  @override
  String get auction_error_no_player => 'No player is up.';

  @override
  String get auction_error_bidding_closed => 'Start bidding first.';

  @override
  String get auction_error_already_leading => 'Leading';

  @override
  String get auction_error_squad_full => 'Squad full';

  @override
  String get auction_error_over_budget => 'Over budget';

  @override
  String get auction_error_bid_moved => 'The bid changed. Try again.';

  @override
  String get auction_error_has_bids => 'This player already has bids.';

  @override
  String get auction_error_no_bid => 'No bids yet.';

  @override
  String get auction_error_player_unavailable =>
      'This player isn\'t available.';

  @override
  String get auction_error_no_players_left => 'No players left in the pool.';

  @override
  String get auction_error_no_previous =>
      'No earlier unsold player to go back to.';

  @override
  String get auction_error_need_teams => 'Add at least 2 teams.';

  @override
  String get auction_error_need_players => 'Add players to the auction first.';

  @override
  String get auction_error_duplicate_player =>
      'A player with the same ID, or the same name and number, already exists.';

  @override
  String get auction_error_invalid_team =>
      'That team has players assigned. Release them first.';

  @override
  String get auction_error_not_admin => 'Only auction admins can do this.';

  @override
  String get auction_error_already_completed =>
      'The auction is already completed.';

  @override
  String get auction_error_incomplete =>
      'Some players still need to be processed.';

  @override
  String get auction_error_too_many_players =>
      'Too many players for one auction.';

  @override
  String get mascot_setting_title => 'Tiger Guide 🐯';

  @override
  String mascot_welcome_named(String name) {
    return 'வந்துட்டீங்களா $name! வாங்க... இன்னைக்கு மைதானத்துல நம்ம ஆட்டம் ஆரம்பிக்கட்டுமா? 🔥';
  }

  @override
  String get mascot_welcome_guest =>
      'வாங்க பாஸ்! Guest-ஆ வந்தாலும் ஆட்டம் மட்டும் Mass-ஆ இருக்கணும். ஆரம்பிக்கலாமா? 🏏';

  @override
  String get mascot_sign_in_options =>
      'Login பண்ணி உங்க பெயர்ல விளையாடுங்க... இல்ல Guest-ஆ நேரா களமிறங்குங்க!';

  @override
  String get mascot_sign_in_required =>
      'இந்த வசதிக்குள் வர Login தேவை பாஸ். ஒரு சின்ன Entry தான்!';

  @override
  String get mascot_sign_in_to_create =>
      'முதல்ல Login பண்ணுங்க... அப்புறம் Team, Match, Tournament எல்லாம் நம்ம கையில!';

  @override
  String get mascot_email_new_account =>
      'புதுசா வந்திருக்கீங்களா? வாங்க, உங்களுக்கான Account-ஐ உருவாக்கி ஆட்டத்துக்குள் Entry கொடுப்போம்!';

  @override
  String get mascot_email_looks_good =>
      'Email சரியா இருக்கு பாஸ்! அடுத்த Step-க்கு போகலாம்.';

  @override
  String get mascot_password_hidden =>
      'உங்க Password-ஐ நான் பார்க்கல... ரகசியம் ரகசியம்தான்! 🤫';

  @override
  String get mascot_password_shown =>
      'Password திரையில் தெரியுது பாஸ்! பக்கத்தில யாரும் பார்க்கலன்னு ஒருமுறை Check பண்ணுங்க.';

  @override
  String get mascot_wrong_password =>
      'அடடா! Login விவரம் பொருந்தலையே. Password மறந்துட்டீங்களா? \'Forgot password\' அழுத்துங்க; Reset Link அனுப்புறேன்.';

  @override
  String get mascot_email_in_use =>
      'இந்த Email-க்கு ஏற்கனவே Account இருக்கு பாஸ். புதுசா உருவாக்க வேண்டாம்; Sign In பண்ணிப் பாருங்க!';

  @override
  String get mascot_enter_email_first =>
      'முதல்ல உங்க Email-ஐ உள்ளிடுங்க. அப்புறம் \'Forgot password\' அழுத்துங்க!';

  @override
  String get mascot_reset_sent =>
      'Reset Link அனுப்பியாச்சு! Inbox-உம் Spam Folder-உம் Check பண்ணுங்க.';

  @override
  String get mascot_something_wrong =>
      'அடடா, ஒரு சின்ன தடங்கல்! மீண்டும் முயற்சி பண்ணுங்க; ஆட்டம் தொடரட்டும்.';

  @override
  String get mascot_login_success =>
      'Entry கிடைச்சாச்சு பாஸ்! இனிமே ஆட்டம் நம்ம கையில! 🔥';

  @override
  String get mascot_registered =>
      'Account ரெடி! Sports Tamil Team-க்கு Welcome பாஸ்! உங்க ஆட்டம் இப்போதான் ஆரம்பம்!';

  @override
  String get mascot_guest_joined =>
      'Guest-ஆ களமிறங்கிட்டீங்க பாஸ்! உங்க Score \'Guest\'ன்னு காட்டும். வாங்க, ஆட்டத்தை ஆரம்பிப்போம்!';

  @override
  String get mascot_profile_intro =>
      'உங்க பெயரைச் சொல்லுங்க பாஸ்... அப்போதான் Friends உங்களை கண்டுபிடிக்க முடியும்!';

  @override
  String mascot_profile_name(String name) {
    return '$name, பெயரே Mass-ஆ இருக்கு! Sports Tamil-க்கு வரவேற்கிறோம்!';
  }

  @override
  String mascot_profile_created(String name) {
    return 'வாங்க $name! Sports Tamil குடும்பத்துல உங்க Entry ஆகிடுச்சு! இனிமே கலக்கலாம்! 🏏';
  }

  @override
  String get mascot_profile_saved =>
      'Profile Save ஆயிடுச்சு பாஸ்! அடுத்த ஆட்டத்துக்கு Ready!';

  @override
  String get mascot_profile_required =>
      'ஆட்டத்துக்கு முன்னாடி Profile-ஐ முடிச்சிடுங்க பாஸ்! பெயரும் Mobile Number-ம் போதும் 🙂';

  @override
  String get mascot_profile_need_name =>
      'முதல்ல உங்க பெயரைச் சொல்லுங்க பாஸ்! பெயர் இல்லாம Team-ல சேர்க்க முடியாது 🙂';

  @override
  String get mascot_profile_need_phone =>
      'உங்க Mobile Number-ஐக் கொடுங்க பாஸ்... அது உங்களுக்கு மட்டும்தான் தெரியும், பயப்படாதீங்க! 🔒';

  @override
  String get mascot_profile_bad_phone =>
      'இந்த Number சரியா இல்லையே பாஸ்... ஒருக்கா திரும்பப் பாருங்க!';

  @override
  String get mascot_profile_need_both =>
      'பெயரும் Mobile Number-ம் கட்டாயம் வேணும் பாஸ்! ரெண்டையும் நிரப்புங்க, அப்புறம் ஆட்டம் ஆரம்பம்! 🏏';

  @override
  String get mascot_profile_bad_email =>
      'Email சரியா இல்லை பாஸ்... திருத்துங்க, இல்லாட்டி காலியா விடுங்க.';

  @override
  String get mascot_profile_photo_added =>
      'சூப்பர் Photo பாஸ்! Hero மாதிரி இருக்கீங்க 😎';

  @override
  String get mascot_profile_photo_failed =>
      'இந்த Photo-வை ஏத்த முடியல பாஸ்... வேற ஒரு Photo-வைத் தெரிவு செய்யுங்க!';

  @override
  String get mascot_fun_six =>
      'சிக்ஸர்! பந்து எல்லை தாண்டிச்சு... ரசிகர்கள் கொண்டாட்டம் ஆரம்பம்! 🔥';

  @override
  String get mascot_fun_four =>
      'பவுண்டரி! என்ன ஒரு ஷாட் பாஸ்... கைதட்டல் கேட்குதே! 👏';

  @override
  String get mascot_fun_wicket =>
      'விக்கெட்! ஒரே பந்துல ஆட்டத்தோட கதை திரும்பிடுச்சே! 😎';

  @override
  String get mascot_fun_dot_ball =>
      'Dot Ball தான்... ஆனா Tension மட்டும் Full-ஆ ஏறுதே! 😂';

  @override
  String get mascot_fun_perfect_timing =>
      'டைமிங் வேற லெவல்! பேட்டும் பந்தும் சரியான நேரத்துல சந்திச்சாச்சு! 🔥';

  @override
  String get mascot_fun_early_shot =>
      'கொஞ்சம் பொறுமை பாஸ்... பந்து வர்றதுக்குள்ள ஷாட் ஆடிட்டீங்களே! 😅';

  @override
  String get mascot_fun_late_shot =>
      'அடடா! ஷாட் கொஞ்சம் Late ஆயிடுச்சு. அடுத்த Ball-ல Comeback கொடுங்க!';

  @override
  String get mascot_fun_match_won =>
      'கிளைமாக்ஸ் நம்ம பக்கம்! Match ஜெயிச்சாச்சு பாஸ்... கொண்டாடுங்க! 🏆';

  @override
  String get mascot_fun_match_lost =>
      'இது முடிவு இல்ல பாஸ்... அடுத்த வெற்றிக்கான ஆரம்பம்! அடுத்த Match-ல Comeback கொடுப்போம்!';

  @override
  String get mascot_fun_last_over =>
      'கடைசி ஓவர் வந்தாச்சு! இப்போதான் ஆட்டத்துக்கு உண்மையான கிளைமாக்ஸ்!';

  @override
  String get mascot_fun_comeback =>
      'Comeback கொடுக்க இன்னும் நேரம் இருக்கு பாஸ்! அடுத்த பந்திலிருந்து ஆட்டத்தை மாற்றுங்க! 💪';

  @override
  String get mascot_fun_team_created =>
      'Team ரெடி! இனிமேல் மைதானத்துல நம்ம ஆட்டம்தான்! 😎';

  @override
  String get mascot_fun_tournament_created =>
      'Tournament ஆரம்பிச்சாச்சு! கோப்பையைத் தூக்கப்போறது யாருன்னு பார்ப்போம்!';

  @override
  String get mascot_fun_challenge_won =>
      'Challenge ஜெயிச்சாச்சு! Scoreboard-ஏ உங்க பேரைச் சொல்லுது! 🔥';

  @override
  String get mascot_fun_challenge_lost =>
      'இந்த Round அவங்களுக்குப் போச்சு. அடுத்த Round-ஐ நம்ம பக்கம் திருப்பலாம்!';

  @override
  String get mascot_fun_empty_matches =>
      'மைதானம் காலியா இருக்கு பாஸ்! ஒரு Match உருவாக்கி நண்பர்களைக் கூப்பிடுங்க!';

  @override
  String get mascot_fun_no_players =>
      'Team-க்கு இன்னும் வீரர்கள் தேவை! நண்பர்களைச் சேர்த்து Dream Team உருவாக்குங்க!';

  @override
  String get mascot_fun_internet =>
      'Network Connection துண்டிக்கப்பட்டிருக்கு பாஸ். இணையத்தைச் சரிபார்த்து மீண்டும் முயற்சி செய்யுங்க.';

  @override
  String get mascot_fun_auction_sold =>
      'Sold! Bid முடிஞ்சாச்சு... இந்த வீரர் இனிமேல் அந்த அணியோட பலம்!';

  @override
  String get mascot_fun_auction_unsold =>
      'இந்த முறை வாய்ப்பு அமையல. ஆனா ஆட்டம் இன்னும் முடியல; அடுத்த வாய்ப்பு வரட்டும்!';

  @override
  String get mascot_movie_baasha_style =>
      'சொல்ல வேண்டியதைச் சொல்லிட்டேன் பாஸ்... இனிமே Scoreboard பேசட்டும்!';

  @override
  String get mascot_movie_padayappa_style =>
      'என் ஆட்டம் என் ஸ்டைல்... வெற்றி வந்தா அது நம்ம Style!';

  @override
  String get mascot_movie_mass_entry =>
      'வந்துட்டேன்னு மட்டும் நினைக்காதீங்க... Scoreboard-ல தடம் பதிக்க வந்திருக்கேன்! 💥';

  @override
  String get mascot_movie_comedy_scene =>
      'பந்தைப் பார்த்ததும் பேட் ஏன் அமைதியா நிக்குது பாஸ்? 😂';

  @override
  String get mascot_movie_climax_scene =>
      'கடைசி பந்து விழும் வரை கதை முடியாது... இது நம்ம கிரிக்கெட் கிளைமாக்ஸ்!';

  @override
  String get mascot_movie_hero_intro =>
      'ஹீரோ Entry கொடுத்தாச்சு! இனிமே ஒவ்வொரு Ball-உம் முக்கியம்! 😎';

  @override
  String get mascot_movie_interval =>
      'இது Interval தான் பாஸ்... இரண்டாவது Innings-ல சந்திப்போம்!';

  @override
  String get mascot_movie_dialogue_hint =>
      'ஒரு Mass Dialogue வேணுமா? Tiger ரெடியா இருக்கு!';

  @override
  String get mascot_movie_cool_attitude =>
      'அமைதியா ஆடுவோம்... பதிலை Scoreboard சொல்லட்டும்!';

  @override
  String get mascot_movie_youth_energy =>
      'விசில் ரெடியா? அடுத்த Shot-ல மைதானமே அதிரட்டும்!';

  @override
  String get mascot_movie_mass_punch =>
      'நம்ம ஆட்டத்துக்கு சத்தம் தேவையில்லை... Scoreboard போதும்!';

  @override
  String get mascot_fun_match_tied =>
      'ஆட்டம் சமன்ல முடிஞ்சிருக்கு! இரு அணிகளும் கடைசி வரை போராடிட்டாங்க!';

  @override
  String get tournament_col_player => 'Player';

  @override
  String get tournament_col_team => 'Team';

  @override
  String get tournament_col_innings => 'Inn';

  @override
  String get tournament_col_runs => 'Runs';

  @override
  String get tournament_col_highest => 'HS';

  @override
  String get tournament_col_average => 'Avg';

  @override
  String get tournament_col_strike_rate => 'SR';

  @override
  String get tournament_col_fours => '4s';

  @override
  String get tournament_col_sixes => '6s';

  @override
  String get tournament_col_fifties => '50s';

  @override
  String get tournament_col_hundreds => '100s';

  @override
  String get tournament_col_overs => 'Ov';

  @override
  String get tournament_col_maidens => 'Mdn';

  @override
  String get tournament_col_runs_conceded => 'Runs';

  @override
  String get tournament_col_wickets => 'Wkts';

  @override
  String get tournament_col_best => 'Best';

  @override
  String get tournament_col_economy => 'Econ';

  @override
  String get tournament_col_catches => 'Ct';

  @override
  String get tournament_col_run_outs => 'RO';

  @override
  String get tournament_col_stumpings => 'St';

  @override
  String get tournament_col_total => 'Total';

  @override
  String get tournament_col_points => 'Pts';

  @override
  String get tournament_col_bat => 'Bat';

  @override
  String get tournament_col_bowl => 'Bowl';

  @override
  String get tournament_col_field => 'Field';

  @override
  String get tournament_col_played => 'P';

  @override
  String get tournament_col_won => 'W';

  @override
  String get tournament_col_lost => 'L';

  @override
  String get tournament_col_nrr => 'NRR';

  @override
  String get tournament_col_form => 'Last 5';

  @override
  String get tournament_form_win => 'W';

  @override
  String get tournament_form_loss => 'L';

  @override
  String get tournament_form_tie => 'T';

  @override
  String get tournament_form_no_result => 'N';

  @override
  String get tournament_live_pill => 'Live';

  @override
  String get tournament_upcoming_pill => 'Upcoming';

  @override
  String get tournament_result_pill => 'Result';

  @override
  String get tournament_walkover_pill => 'Walkover';

  @override
  String get tournament_no_result_pill => 'No result';

  @override
  String tournament_match_number(int number) {
    return 'Match $number';
  }

  @override
  String tournament_won_by_walkover(String team) {
    return '$team won by walkover';
  }

  @override
  String get tournament_match_tied => 'Match tied';

  @override
  String tournament_won_by_runs(String team, int runs) {
    String _temp0 = intl.Intl.pluralLogic(
      runs,
      locale: localeName,
      other: '$runs runs',
      one: '1 run',
    );
    return '$team won by $_temp0';
  }

  @override
  String tournament_won_by_wickets(String team, int wickets) {
    String _temp0 = intl.Intl.pluralLogic(
      wickets,
      locale: localeName,
      other: '$wickets wickets',
      one: '1 wicket',
    );
    return '$team won by $_temp0';
  }

  @override
  String tournament_overs_short(String overs) {
    return '($overs ov)';
  }

  @override
  String get tournament_match_continue_scoring => 'Continue scoring';

  @override
  String get tournament_matches_completed_status => 'Completed';

  @override
  String get tournament_stat_matches_played => 'Played';

  @override
  String get tournament_stat_players => 'Players';

  @override
  String get tournament_stats_batting => 'Batting';

  @override
  String get tournament_stats_bowling => 'Bowling';

  @override
  String get tournament_stats_fielding => 'Fielding';

  @override
  String get tournament_stats_records => 'Records';

  @override
  String get tournament_stats_mvp => 'MVP';

  @override
  String get tournament_stats_loading => 'Crunching ball-by-ball stats…';

  @override
  String get tournament_stats_empty_title => 'No stats yet';

  @override
  String get tournament_stats_empty_description =>
      'Player stats appear here once matches are completed.';

  @override
  String get tournament_stats_most_runs => 'Most runs';

  @override
  String get tournament_stats_most_wickets => 'Most wickets';

  @override
  String get tournament_stats_best_fielder => 'Best fielder';

  @override
  String get tournament_stats_mvp_leader => 'Most valuable player';

  @override
  String tournament_stats_innings_sr(int innings, String sr) {
    String _temp0 = intl.Intl.pluralLogic(
      innings,
      locale: localeName,
      other: '$innings innings',
      one: '1 innings',
    );
    return '$_temp0 · SR $sr';
  }

  @override
  String tournament_stats_best_economy(String best, String economy) {
    return 'Best $best · Econ $economy';
  }

  @override
  String get tournament_stats_dismissals => 'Dismissals';

  @override
  String tournament_stats_catches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catches',
      one: '1 catch',
    );
    return '$_temp0';
  }

  @override
  String get tournament_stats_mvp_formula =>
      'MVP points: 1 per run, +1 per four, +2 per six, +10 per fifty or hundred; 20 per wicket, 10 per maiden; 8 per catch, 10 per run out or stumping.';

  @override
  String get tournament_record_highest_score => 'Highest individual score';

  @override
  String get tournament_record_best_average => 'Best batting average';

  @override
  String tournament_record_min_innings(int count) {
    return 'Min. $count innings';
  }

  @override
  String get tournament_record_best_strike_rate => 'Best strike rate';

  @override
  String tournament_record_min_balls(int count) {
    return 'Min. $count balls';
  }

  @override
  String get tournament_record_most_fours => 'Most fours';

  @override
  String get tournament_record_most_sixes => 'Most sixes';

  @override
  String get tournament_record_best_bowling => 'Best bowling in a match';

  @override
  String get tournament_record_best_economy => 'Best economy';

  @override
  String tournament_record_min_overs(int count) {
    return 'Min. $count overs';
  }

  @override
  String get tournament_overview_champions => 'Champions';

  @override
  String get tournament_overview_recent_results => 'Recent results';

  @override
  String get tournament_overview_top_performers => 'Top performers';

  @override
  String get tournament_points_note =>
      '2 points for a win, 1 for a tie or no result. Teams level on points are ranked by net run rate (NRR). Top 4 qualify for the playoffs.';

  @override
  String tournament_team_owner(String name) {
    return 'Owner: $name';
  }
}
