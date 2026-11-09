import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta')
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Sports Tamil'**
  String get app_title;

  /// No description provided for @common_none_title.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get common_none_title;

  /// No description provided for @common_anonymous_title.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get common_anonymous_title;

  /// No description provided for @common_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete_title;

  /// No description provided for @common_cancel_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel_title;

  /// No description provided for @common_sign_out_title.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get common_sign_out_title;

  /// No description provided for @common_add_title.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add_title;

  /// No description provided for @common_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit_title;

  /// No description provided for @common_remove_title.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get common_remove_title;

  /// No description provided for @common_reset_title.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get common_reset_title;

  /// No description provided for @common_okay_title.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get common_okay_title;

  /// No description provided for @common_save_title.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save_title;

  /// No description provided for @common_next_title.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next_title;

  /// No description provided for @common_yes_title.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes_title;

  /// No description provided for @common_no_title.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no_title;

  /// No description provided for @common_retry_title.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry_title;

  /// No description provided for @common_submit_title.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get common_submit_title;

  /// No description provided for @common_not_now.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get common_not_now;

  /// No description provided for @common_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get common_create;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_not_specified_title.
  ///
  /// In en, this message translates to:
  /// **'Not Specified'**
  String get common_not_specified_title;

  /// No description provided for @commonRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get commonRunning;

  /// No description provided for @commonFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get commonFinish;

  /// No description provided for @commonDeactivatedUser.
  ///
  /// In en, this message translates to:
  /// **'Deactivated User'**
  String get commonDeactivatedUser;

  /// No description provided for @common_runs_title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{count} runs} =1{{count} run} other{{count} runs}}'**
  String common_runs_title(num count);

  /// No description provided for @common_wickets_title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{count} wickets} =1{{count} wicket} other{{count} wickets}}'**
  String common_wickets_title(num count);

  /// No description provided for @common_players_title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{count} Players} =1{{count} Player} other{{count} Players}}'**
  String common_players_title(num count);

  /// No description provided for @common_tie_title.
  ///
  /// In en, this message translates to:
  /// **'Tie'**
  String get common_tie_title;

  /// No description provided for @common_wicket_taken_title.
  ///
  /// In en, this message translates to:
  /// **' Wicket taken'**
  String get common_wicket_taken_title;

  /// No description provided for @common_matches_title.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get common_matches_title;

  /// No description provided for @common_teams_title.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get common_teams_title;

  /// No description provided for @common_stats_title.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get common_stats_title;

  /// No description provided for @common_edit_team_title.
  ///
  /// In en, this message translates to:
  /// **'Edit team'**
  String get common_edit_team_title;

  /// No description provided for @common_create_team_title.
  ///
  /// In en, this message translates to:
  /// **'Create team'**
  String get common_create_team_title;

  /// No description provided for @common_create_team_description.
  ///
  /// In en, this message translates to:
  /// **'Create Your Dream Cricket Team Today!'**
  String get common_create_team_description;

  /// No description provided for @common_your_teams_title.
  ///
  /// In en, this message translates to:
  /// **'Your Teams'**
  String get common_your_teams_title;

  /// No description provided for @common_location_title.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get common_location_title;

  /// No description provided for @common_gender_title.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get common_gender_title;

  /// No description provided for @common_batting_style_title.
  ///
  /// In en, this message translates to:
  /// **'Batting style'**
  String get common_batting_style_title;

  /// No description provided for @common_bowling_style_title.
  ///
  /// In en, this message translates to:
  /// **'Bowling style'**
  String get common_bowling_style_title;

  /// No description provided for @common_camera_text.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get common_camera_text;

  /// No description provided for @common_gallery_text.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get common_gallery_text;

  /// No description provided for @common_versus_short_title.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get common_versus_short_title;

  /// No description provided for @common_other_title.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get common_other_title;

  /// No description provided for @common_city_title.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get common_city_title;

  /// No description provided for @common_select_squad_title.
  ///
  /// In en, this message translates to:
  /// **'Select Squad'**
  String get common_select_squad_title;

  /// No description provided for @common_power_play_title.
  ///
  /// In en, this message translates to:
  /// **'Power Play Overs'**
  String get common_power_play_title;

  /// No description provided for @common_select_title.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get common_select_title;

  /// No description provided for @common_a_title.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get common_a_title;

  /// No description provided for @common_m_title.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get common_m_title;

  /// No description provided for @common_batting_average_title.
  ///
  /// In en, this message translates to:
  /// **'Batting Average'**
  String get common_batting_average_title;

  /// No description provided for @common_bowling_average_title.
  ///
  /// In en, this message translates to:
  /// **'Bowling Average'**
  String get common_bowling_average_title;

  /// No description provided for @common_overs_title.
  ///
  /// In en, this message translates to:
  /// **'Overs'**
  String get common_overs_title;

  /// No description provided for @common_run_out_title.
  ///
  /// In en, this message translates to:
  /// **'Run Out'**
  String get common_run_out_title;

  /// No description provided for @common_wickets_text.
  ///
  /// In en, this message translates to:
  /// **'Wickets'**
  String get common_wickets_text;

  /// No description provided for @common_end_match_title.
  ///
  /// In en, this message translates to:
  /// **'End Match'**
  String get common_end_match_title;

  /// No description provided for @common_first_inning_title.
  ///
  /// In en, this message translates to:
  /// **'First inning'**
  String get common_first_inning_title;

  /// No description provided for @common_second_inning_title.
  ///
  /// In en, this message translates to:
  /// **'Second inning'**
  String get common_second_inning_title;

  /// No description provided for @common_qr_code_title.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get common_qr_code_title;

  /// No description provided for @common_verify_title.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get common_verify_title;

  /// No description provided for @common_verified_title.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get common_verified_title;

  /// No description provided for @common_view_all.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get common_view_all;

  /// No description provided for @common_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get common_today;

  /// No description provided for @common_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get common_tomorrow;

  /// No description provided for @common_owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get common_owner;

  /// No description provided for @common_make_admin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get common_make_admin;

  /// No description provided for @common_remove_admin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get common_remove_admin;

  /// No description provided for @common_transfer_ownership.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get common_transfer_ownership;

  /// No description provided for @common_tournaments.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get common_tournaments;

  /// No description provided for @common_leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get common_leaderboard;

  /// No description provided for @common_batting.
  ///
  /// In en, this message translates to:
  /// **'Batting'**
  String get common_batting;

  /// No description provided for @common_bowling.
  ///
  /// In en, this message translates to:
  /// **'Bowling'**
  String get common_bowling;

  /// No description provided for @common_fielding.
  ///
  /// In en, this message translates to:
  /// **'Fielding'**
  String get common_fielding;

  /// +{countryCode} ***** ***{lastDigits}
  ///
  /// In en, this message translates to:
  /// **'{countryCode} ***** ***{lastDigits}'**
  String common_obscure_phone_number_text(
      String countryCode, String lastDigits);

  /// No description provided for @alert_confirm_default_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get alert_confirm_default_title;

  /// Are you sure you want to {deleteText}?
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to {deleteText}?'**
  String alert_confirm_default_message(String deleteText);

  /// No description provided for @error_something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong! Please try again later.'**
  String get error_something_went_wrong;

  /// No description provided for @error_no_internet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection! Please check your network connectivity.'**
  String get error_no_internet;

  /// No description provided for @no_internet_error_title.
  ///
  /// In en, this message translates to:
  /// **'No internet!'**
  String get no_internet_error_title;

  /// No description provided for @no_internet_error_description.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check connection and try again.'**
  String get no_internet_error_description;

  /// No description provided for @something_went_wrong_error_title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get something_went_wrong_error_title;

  /// No description provided for @something_went_wrong_error_description.
  ///
  /// In en, this message translates to:
  /// **'This is all the information we have, but we won\'t rest until we resolve the issue!'**
  String get something_went_wrong_error_description;

  /// No description provided for @intro_get_your_cricket_title.
  ///
  /// In en, this message translates to:
  /// **'Get Your Cricket On!'**
  String get intro_get_your_cricket_title;

  /// No description provided for @intro_get_your_cricket_description.
  ///
  /// In en, this message translates to:
  /// **'Turn backyard games into pro matches with our app. Create matches, manage teams, and track stats!'**
  String get intro_get_your_cricket_description;

  /// No description provided for @intro_continue_btn_text.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get intro_continue_btn_text;

  /// No description provided for @sign_in_verify_phone_number_title.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get sign_in_verify_phone_number_title;

  /// No description provided for @sign_in_verify_phone_number_description.
  ///
  /// In en, this message translates to:
  /// **'We’ll verify your phone number with a verification code.'**
  String get sign_in_verify_phone_number_description;

  /// No description provided for @sign_in_phone_number_placeholder.
  ///
  /// In en, this message translates to:
  /// **'00000 00000'**
  String get sign_in_phone_number_placeholder;

  /// No description provided for @sign_in_get_otp_btn_text.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get sign_in_get_otp_btn_text;

  /// No description provided for @sign_in_invalid_phone_number_text.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid phone number'**
  String get sign_in_invalid_phone_number_text;

  /// No description provided for @sign_in_options_title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in_options_title;

  /// No description provided for @sign_in_guest_option.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get sign_in_guest_option;

  /// No description provided for @sign_in_guest_hint.
  ///
  /// In en, this message translates to:
  /// **'Play cricket without an account. Your scores show as \"Guest\".'**
  String get sign_in_guest_hint;

  /// No description provided for @sign_in_email_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get sign_in_email_title;

  /// No description provided for @sign_in_email_description.
  ///
  /// In en, this message translates to:
  /// **'Sign in to score matches, follow tournaments and see your stats.'**
  String get sign_in_email_description;

  /// No description provided for @sign_in_email_create_title.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get sign_in_email_create_title;

  /// No description provided for @sign_in_email_create_description.
  ///
  /// In en, this message translates to:
  /// **'Set up teams, matches and tournaments, and keep all your cricket in one place.'**
  String get sign_in_email_create_description;

  /// No description provided for @sign_in_password_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get sign_in_password_placeholder;

  /// No description provided for @sign_in_email_sign_in_btn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in_email_sign_in_btn;

  /// No description provided for @sign_in_email_create_btn.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get sign_in_email_create_btn;

  /// No description provided for @sign_in_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get sign_in_email_label;

  /// No description provided for @sign_in_password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get sign_in_password_label;

  /// No description provided for @sign_in_password_create_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get sign_in_password_create_placeholder;

  /// No description provided for @sign_in_password_rule.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get sign_in_password_rule;

  /// No description provided for @sign_in_mode_label.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account'**
  String get sign_in_mode_label;

  /// No description provided for @sign_in_or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get sign_in_or;

  /// No description provided for @sign_in_show_password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get sign_in_show_password;

  /// No description provided for @sign_in_hide_password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get sign_in_hide_password;

  /// No description provided for @sign_in_forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get sign_in_forgot_password;

  /// No description provided for @sign_in_reset_email_sent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {email}. Check your inbox and spam folder.'**
  String sign_in_reset_email_sent(String email);

  /// No description provided for @sign_in_reset_enter_email.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first, then tap Forgot password.'**
  String get sign_in_reset_enter_email;

  /// No description provided for @sign_in_email_placeholder.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get sign_in_email_placeholder;

  /// No description provided for @sign_in_required_title.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get sign_in_required_title;

  /// No description provided for @sign_in_required_description.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your matches, teams, stats, and profile.'**
  String get sign_in_required_description;

  /// No description provided for @otp_verification_verification_title.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otp_verification_verification_title;

  /// No description provided for @otp_verification_incorrect_otp_error_text.
  ///
  /// In en, this message translates to:
  /// **'*Please enter correct OTP'**
  String get otp_verification_incorrect_otp_error_text;

  /// No description provided for @otp_verification_verify_placeholder.
  ///
  /// In en, this message translates to:
  /// **'0 0 0 0 0 0'**
  String get otp_verification_verify_placeholder;

  /// No description provided for @otp_verification_verification_description.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification code to your phone {phone}'**
  String otp_verification_verification_description(Object phone);

  /// No description provided for @home_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_screen_title;

  /// No description provided for @home_screen_live_title.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get home_screen_live_title;

  /// No description provided for @home_screen_upcoming_title.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get home_screen_upcoming_title;

  /// No description provided for @home_screen_finished_title.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get home_screen_finished_title;

  /// No description provided for @home_screen_set_up_match_title.
  ///
  /// In en, this message translates to:
  /// **'Set up a match in minutes.'**
  String get home_screen_set_up_match_title;

  /// No description provided for @home_screen_create_match_btn.
  ///
  /// In en, this message translates to:
  /// **'Create match'**
  String get home_screen_create_match_btn;

  /// No description provided for @home_screen_set_up_team_title.
  ///
  /// In en, this message translates to:
  /// **'Set up a team in minutes.'**
  String get home_screen_set_up_team_title;

  /// No description provided for @home_screen_create_team_btn.
  ///
  /// In en, this message translates to:
  /// **'Create team'**
  String get home_screen_create_team_btn;

  /// No description provided for @home_screen_set_up_tournament_title.
  ///
  /// In en, this message translates to:
  /// **'Set up a tournament in minutes.'**
  String get home_screen_set_up_tournament_title;

  /// No description provided for @home_screen_create_tournament_btn.
  ///
  /// In en, this message translates to:
  /// **'Create tournament'**
  String get home_screen_create_tournament_btn;

  /// No description provided for @home_global_cricket_title.
  ///
  /// In en, this message translates to:
  /// **'Global cricket'**
  String get home_global_cricket_title;

  /// No description provided for @home_global_cricket_updated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time} · CricketData.org'**
  String home_global_cricket_updated(String time);

  /// No description provided for @home_global_cricket_live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get home_global_cricket_live;

  /// No description provided for @global_cricket_international.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get global_cricket_international;

  /// No description provided for @global_cricket_leagues.
  ///
  /// In en, this message translates to:
  /// **'Premier leagues'**
  String get global_cricket_leagues;

  /// No description provided for @global_cricket_no_matches.
  ///
  /// In en, this message translates to:
  /// **'No matches right now'**
  String get global_cricket_no_matches;

  /// No description provided for @global_cricket_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get global_cricket_live;

  /// No description provided for @global_cricket_recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get global_cricket_recent;

  /// No description provided for @global_cricket_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get global_cricket_upcoming;

  /// No description provided for @global_cricket_scorecard.
  ///
  /// In en, this message translates to:
  /// **'Scorecard'**
  String get global_cricket_scorecard;

  /// No description provided for @global_cricket_info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get global_cricket_info;

  /// No description provided for @global_cricket_batter.
  ///
  /// In en, this message translates to:
  /// **'Batter'**
  String get global_cricket_batter;

  /// No description provided for @global_cricket_bowler.
  ///
  /// In en, this message translates to:
  /// **'Bowler'**
  String get global_cricket_bowler;

  /// No description provided for @global_cricket_batting.
  ///
  /// In en, this message translates to:
  /// **'batting'**
  String get global_cricket_batting;

  /// No description provided for @global_cricket_info_match.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get global_cricket_info_match;

  /// No description provided for @global_cricket_info_series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get global_cricket_info_series;

  /// No description provided for @global_cricket_info_date.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get global_cricket_info_date;

  /// No description provided for @global_cricket_info_venue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get global_cricket_info_venue;

  /// No description provided for @global_cricket_info_toss.
  ///
  /// In en, this message translates to:
  /// **'Toss'**
  String get global_cricket_info_toss;

  /// No description provided for @global_cricket_info_format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get global_cricket_info_format;

  /// No description provided for @global_cricket_toss_text.
  ///
  /// In en, this message translates to:
  /// **'{team} won the toss and chose to {choice}'**
  String global_cricket_toss_text(String team, String choice);

  /// No description provided for @global_cricket_starts.
  ///
  /// In en, this message translates to:
  /// **'Starts {time}'**
  String global_cricket_starts(String time);

  /// No description provided for @global_cricket_scorecard_updated.
  ///
  /// In en, this message translates to:
  /// **'Scorecard updated {time} · refreshes hourly while live'**
  String global_cricket_scorecard_updated(String time);

  /// No description provided for @global_cricket_scorecard_not_started.
  ///
  /// In en, this message translates to:
  /// **'The scorecard will appear once the match starts.'**
  String get global_cricket_scorecard_not_started;

  /// No description provided for @global_cricket_scorecard_sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in to load the full scorecard.'**
  String get global_cricket_scorecard_sign_in;

  /// No description provided for @global_cricket_scorecard_limit.
  ///
  /// In en, this message translates to:
  /// **'The full scorecard isn\'t available right now (free data limit). The live score above still updates every 30 minutes.'**
  String get global_cricket_scorecard_limit;

  /// No description provided for @global_cricket_scorecard_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading scorecard…'**
  String get global_cricket_scorecard_loading;

  /// No description provided for @home_screen_no_matches_title.
  ///
  /// In en, this message translates to:
  /// **'No Matches in this area!'**
  String get home_screen_no_matches_title;

  /// No description provided for @home_screen_no_matches_description_text.
  ///
  /// In en, this message translates to:
  /// **'Enjoy the freedom of creating your own cricket matches or teams.'**
  String get home_screen_no_matches_description_text;

  /// No description provided for @home_greeting_morning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get home_greeting_morning;

  /// No description provided for @home_greeting_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get home_greeting_afternoon;

  /// No description provided for @home_greeting_evening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get home_greeting_evening;

  /// No description provided for @home_greeting_guest.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get home_greeting_guest;

  /// No description provided for @home_section_live.
  ///
  /// In en, this message translates to:
  /// **'Live matches ({count})'**
  String home_section_live(int count);

  /// No description provided for @home_section_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming matches'**
  String get home_section_upcoming;

  /// No description provided for @home_section_finished.
  ///
  /// In en, this message translates to:
  /// **'Recent results'**
  String get home_section_finished;

  /// No description provided for @home_match_overs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 over match} other{{count} overs match}}'**
  String home_match_overs(int count);

  /// No description provided for @home_live_need.
  ///
  /// In en, this message translates to:
  /// **'{team} need {runs, plural, =1{1 run} other{{runs} runs}} in {balls, plural, =1{1 ball} other{{balls} balls}}'**
  String home_live_need(String team, int runs, int balls);

  /// No description provided for @home_live_batting.
  ///
  /// In en, this message translates to:
  /// **'{team} batting'**
  String home_live_batting(String team);

  /// No description provided for @home_live_toss.
  ///
  /// In en, this message translates to:
  /// **'{team} won the toss'**
  String home_live_toss(String team);

  /// No description provided for @home_live_starting.
  ///
  /// In en, this message translates to:
  /// **'Match about to start'**
  String get home_live_starting;

  /// No description provided for @home_live_target.
  ///
  /// In en, this message translates to:
  /// **'Target {target}'**
  String home_live_target(int target);

  /// No description provided for @home_crr.
  ///
  /// In en, this message translates to:
  /// **'CRR {rate}'**
  String home_crr(String rate);

  /// No description provided for @home_rrr.
  ///
  /// In en, this message translates to:
  /// **'RRR {rate}'**
  String home_rrr(String rate);

  /// No description provided for @home_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get home_today;

  /// No description provided for @home_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get home_tomorrow;

  /// No description provided for @home_result_won_by.
  ///
  /// In en, this message translates to:
  /// **'{team} won by {margin}'**
  String home_result_won_by(String team, String margin);

  /// No description provided for @home_search_hint_title.
  ///
  /// In en, this message translates to:
  /// **'Search matches by team name...'**
  String get home_search_hint_title;

  /// No description provided for @home_search_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Start your search here!'**
  String get home_search_empty_title;

  /// No description provided for @home_search_empty_message.
  ///
  /// In en, this message translates to:
  /// **'Type your search above to find what you need fast.'**
  String get home_search_empty_message;

  /// No description provided for @home_search_results_title.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get home_search_results_title;

  /// No description provided for @home_search_users_title.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get home_search_users_title;

  /// No description provided for @home_search_list_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get home_search_list_empty_title;

  /// No description provided for @home_search_list_empty_message.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any results for your search. Please try different keywords.'**
  String get home_search_list_empty_message;

  /// No description provided for @leaderboard_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Nothing to Show Yet'**
  String get leaderboard_empty_title;

  /// No description provided for @leaderboard_empty_description.
  ///
  /// In en, this message translates to:
  /// **'No scores available yet. Make your move and take the lead!'**
  String get leaderboard_empty_description;

  /// No description provided for @leaderboard_catches_title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{count} catches} =1{{count} catch} other{{count} catches}}'**
  String leaderboard_catches_title(num count);

  /// No description provided for @notification_popup_title.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications?'**
  String get notification_popup_title;

  /// No description provided for @notification_popup_description.
  ///
  /// In en, this message translates to:
  /// **'Never miss a moment of your matches. \nTurn on notifications for real-time updates and important match information.'**
  String get notification_popup_description;

  /// No description provided for @notification_popup_later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get notification_popup_later;

  /// No description provided for @my_cricket_screen_title.
  ///
  /// In en, this message translates to:
  /// **'My Cricket'**
  String get my_cricket_screen_title;

  /// No description provided for @my_cricket_header_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your matches, teams and tournaments'**
  String get my_cricket_header_subtitle;

  /// No description provided for @my_cricket_empty_matches_body.
  ///
  /// In en, this message translates to:
  /// **'Create a match, pick both teams and score it ball by ball.'**
  String get my_cricket_empty_matches_body;

  /// No description provided for @my_cricket_empty_teams_body.
  ///
  /// In en, this message translates to:
  /// **'Build your squad and invite players to join your team.'**
  String get my_cricket_empty_teams_body;

  /// No description provided for @my_cricket_empty_tournaments_body.
  ///
  /// In en, this message translates to:
  /// **'Set up a league or knockout, then add teams and matches.'**
  String get my_cricket_empty_tournaments_body;

  /// No description provided for @add_tournament_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Add Tournament'**
  String get add_tournament_screen_title;

  /// No description provided for @add_tournament_name.
  ///
  /// In en, this message translates to:
  /// **'Tournament Name'**
  String get add_tournament_name;

  /// No description provided for @add_tournament_type.
  ///
  /// In en, this message translates to:
  /// **'Tournament Type'**
  String get add_tournament_type;

  /// No description provided for @add_tournament_type_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Select tournament type'**
  String get add_tournament_type_placeholder;

  /// No description provided for @add_tournament_start_date.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get add_tournament_start_date;

  /// No description provided for @add_tournament_end_date.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get add_tournament_end_date;

  /// No description provided for @add_tournament_venue_title.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get add_tournament_venue_title;

  /// No description provided for @add_tournament_match_format_title.
  ///
  /// In en, this message translates to:
  /// **'Match Format'**
  String get add_tournament_match_format_title;

  /// No description provided for @add_tournament_schedule_title.
  ///
  /// In en, this message translates to:
  /// **'Tournament Schedule'**
  String get add_tournament_schedule_title;

  /// No description provided for @add_tournament_teams_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick teams from a tournament team pool'**
  String get add_tournament_teams_hint;

  /// No description provided for @add_tournament_change_teams.
  ///
  /// In en, this message translates to:
  /// **'Change teams'**
  String get add_tournament_change_teams;

  /// No description provided for @add_tournament_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get add_tournament_city;

  /// No description provided for @add_tournament_ground.
  ///
  /// In en, this message translates to:
  /// **'Ground / Venue'**
  String get add_tournament_ground;

  /// No description provided for @add_tournament_ball_type.
  ///
  /// In en, this message translates to:
  /// **'Ball Type'**
  String get add_tournament_ball_type;

  /// No description provided for @add_tournament_ball_type_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Select ball type'**
  String get add_tournament_ball_type_placeholder;

  /// No description provided for @add_tournament_overs.
  ///
  /// In en, this message translates to:
  /// **'Overs per match'**
  String get add_tournament_overs;

  /// No description provided for @add_tournament_overs_hint.
  ///
  /// In en, this message translates to:
  /// **'1 to {max}'**
  String add_tournament_overs_hint(int max);

  /// No description provided for @add_tournament_details_required.
  ///
  /// In en, this message translates to:
  /// **'Fill in city, ground, ball type and overs (1–{max}) to continue'**
  String add_tournament_details_required(int max);

  /// No description provided for @add_tournament_team_selection.
  ///
  /// In en, this message translates to:
  /// **'Team selection'**
  String get add_tournament_team_selection;

  /// No description provided for @add_tournament_match_selection.
  ///
  /// In en, this message translates to:
  /// **'Match selection'**
  String get add_tournament_match_selection;

  /// No description provided for @add_tournament_edit_banner.
  ///
  /// In en, this message translates to:
  /// **'Edit banner'**
  String get add_tournament_edit_banner;

  /// No description provided for @add_tournament_add_banner_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Add banner image'**
  String get add_tournament_add_banner_placeholder;

  /// No description provided for @add_tournament_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete tournament!'**
  String get add_tournament_delete_title;

  /// No description provided for @add_tournament_delete_description.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete the tournament, along with all match data. Are you sure you want to delete?'**
  String get add_tournament_delete_description;

  /// No description provided for @add_tournament_date_error.
  ///
  /// In en, this message translates to:
  /// **'End date should be greater than start date'**
  String get add_tournament_date_error;

  /// No description provided for @add_tournament_select_min_team_error.
  ///
  /// In en, this message translates to:
  /// **'Please select minimum {count} teams'**
  String add_tournament_select_min_team_error(Object count);

  /// No description provided for @add_tournament_teams_title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No teams} =1{{count} Team} other{{count} Teams}}'**
  String add_tournament_teams_title(num count);

  /// No description provided for @tournament_list_empty_list_title.
  ///
  /// In en, this message translates to:
  /// **'No tournaments created'**
  String get tournament_list_empty_list_title;

  /// No description provided for @tournament_list_empty_list_description.
  ///
  /// In en, this message translates to:
  /// **'Tap on the “ + ” icon to create a tournament'**
  String get tournament_list_empty_list_description;

  /// No description provided for @tournament_list_match_title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matches} =1{{count} Match} other{{count} Matches}}'**
  String tournament_list_match_title(num count);

  /// No description provided for @team_selection_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Select Teams'**
  String get team_selection_screen_title;

  /// No description provided for @team_selection_select_team_title.
  ///
  /// In en, this message translates to:
  /// **'Select teams'**
  String get team_selection_select_team_title;

  /// No description provided for @team_selection_verify_team_to_add_title.
  ///
  /// In en, this message translates to:
  /// **'Verify teams to add'**
  String get team_selection_verify_team_to_add_title;

  /// No description provided for @match_selection_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Select Matches'**
  String get match_selection_screen_title;

  /// No description provided for @match_selection_select_matches_title.
  ///
  /// In en, this message translates to:
  /// **'Select matches'**
  String get match_selection_select_matches_title;

  /// No description provided for @match_selection_round_title.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String match_selection_round_title(Object round);

  /// No description provided for @match_selection_no_matches_title.
  ///
  /// In en, this message translates to:
  /// **'No Matches Scheduled Yet'**
  String get match_selection_no_matches_title;

  /// No description provided for @match_selection_no_matches_description.
  ///
  /// In en, this message translates to:
  /// **'There are currently no matches scheduled. Tap the \'+\' button to schedule new matches.'**
  String get match_selection_no_matches_description;

  /// No description provided for @match_selection_not_found_title.
  ///
  /// In en, this message translates to:
  /// **'No Matches Found for {team}'**
  String match_selection_not_found_title(Object team);

  /// No description provided for @match_selection_not_found_description.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find any match results for {team} at this time. Please check again later.'**
  String match_selection_not_found_description(Object team);

  /// No description provided for @match_group_round_title.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get match_group_round_title;

  /// No description provided for @match_group_quarter_final_title.
  ///
  /// In en, this message translates to:
  /// **'Quarter final'**
  String get match_group_quarter_final_title;

  /// No description provided for @match_group_semi_final_title.
  ///
  /// In en, this message translates to:
  /// **'Semi final'**
  String get match_group_semi_final_title;

  /// No description provided for @match_group_final_title.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get match_group_final_title;

  /// No description provided for @tournament_detail_not_found_title.
  ///
  /// In en, this message translates to:
  /// **'No Tournament found'**
  String get tournament_detail_not_found_title;

  /// No description provided for @tournament_detail_not_found_description.
  ///
  /// In en, this message translates to:
  /// **'The tournament you are looking for is not available.'**
  String get tournament_detail_not_found_description;

  /// Start from {date}
  ///
  /// In en, this message translates to:
  /// **'Start from {date}'**
  String tournament_detail_start_from_title(String date);

  /// No description provided for @tournament_detail_overview_tab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tournament_detail_overview_tab;

  /// No description provided for @tournament_detail_points_table_tab.
  ///
  /// In en, this message translates to:
  /// **'Points Table'**
  String get tournament_detail_points_table_tab;

  /// No description provided for @tournament_detail_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit tournament'**
  String get tournament_detail_edit_title;

  /// No description provided for @tournament_detail_members_title.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get tournament_detail_members_title;

  /// No description provided for @tournament_detail_overview_info_title.
  ///
  /// In en, this message translates to:
  /// **'Tournament info'**
  String get tournament_detail_overview_info_title;

  /// No description provided for @tournament_detail_overview_name_title.
  ///
  /// In en, this message translates to:
  /// **'Tournament Name'**
  String get tournament_detail_overview_name_title;

  /// No description provided for @tournament_detail_overview_type_title.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get tournament_detail_overview_type_title;

  /// No description provided for @tournament_detail_overview_duration_title.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get tournament_detail_overview_duration_title;

  /// No description provided for @tournament_detail_overview_teams_squads_title.
  ///
  /// In en, this message translates to:
  /// **'Teams Squads'**
  String get tournament_detail_overview_teams_squads_title;

  /// No description provided for @tournament_detail_overview_key_stats_title.
  ///
  /// In en, this message translates to:
  /// **'Key Stats'**
  String get tournament_detail_overview_key_stats_title;

  /// No description provided for @tournament_detail_overview_featured_matches_title.
  ///
  /// In en, this message translates to:
  /// **'Featured Matches'**
  String get tournament_detail_overview_featured_matches_title;

  /// No description provided for @tournament_detail_teams_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Select Your Teams!'**
  String get tournament_detail_teams_empty_title;

  /// No description provided for @tournament_detail_teams_empty_description.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any teams to this tournament yet. Please select or create teams to get started.'**
  String get tournament_detail_teams_empty_description;

  /// No description provided for @tournament_detail_teams_select_btn.
  ///
  /// In en, this message translates to:
  /// **'Add teams'**
  String get tournament_detail_teams_select_btn;

  /// No description provided for @tournament_detail_matches_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Schedule Your Matches!'**
  String get tournament_detail_matches_empty_title;

  /// No description provided for @tournament_detail_matches_empty_description.
  ///
  /// In en, this message translates to:
  /// **'Create matches to kick off your tournament and get the games started!'**
  String get tournament_detail_matches_empty_description;

  /// No description provided for @tournament_detail_matches_filter_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No Results Found'**
  String get tournament_detail_matches_filter_empty_title;

  /// No description provided for @tournament_detail_matches_filter_empty_description.
  ///
  /// In en, this message translates to:
  /// **'No matches match the selected filters. Try adjusting them.'**
  String get tournament_detail_matches_filter_empty_description;

  /// No description provided for @tournament_detail_matches_add_btn.
  ///
  /// In en, this message translates to:
  /// **'Add matches'**
  String get tournament_detail_matches_add_btn;

  /// No description provided for @tournament_detail_matches_filter_by_teams_title.
  ///
  /// In en, this message translates to:
  /// **'Filter by teams'**
  String get tournament_detail_matches_filter_by_teams_title;

  /// No description provided for @tournament_detail_matches_filter_all_teams_option.
  ///
  /// In en, this message translates to:
  /// **'All Teams'**
  String get tournament_detail_matches_filter_all_teams_option;

  /// No description provided for @tournament_detail_matches_schedule_btn.
  ///
  /// In en, this message translates to:
  /// **'Schedule Matches'**
  String get tournament_detail_matches_schedule_btn;

  /// No description provided for @tournament_detail_matches_all_status.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tournament_detail_matches_all_status;

  /// No description provided for @tournament_detail_matches_live_status.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get tournament_detail_matches_live_status;

  /// No description provided for @tournament_detail_matches_upcoming_status.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tournament_detail_matches_upcoming_status;

  /// No description provided for @tournament_detail_matches_past_status.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get tournament_detail_matches_past_status;

  /// No description provided for @tournament_detail_matches_live_section.
  ///
  /// In en, this message translates to:
  /// **'Live Matches'**
  String get tournament_detail_matches_live_section;

  /// No description provided for @tournament_detail_matches_upcoming_section.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Matches'**
  String get tournament_detail_matches_upcoming_section;

  /// No description provided for @tournament_detail_matches_past_section.
  ///
  /// In en, this message translates to:
  /// **'Past Matches'**
  String get tournament_detail_matches_past_section;

  /// No description provided for @tournament_detail_matches_no_live.
  ///
  /// In en, this message translates to:
  /// **'No live matches right now'**
  String get tournament_detail_matches_no_live;

  /// No description provided for @tournament_detail_matches_no_upcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming matches scheduled'**
  String get tournament_detail_matches_no_upcoming;

  /// No description provided for @tournament_detail_matches_no_past.
  ///
  /// In en, this message translates to:
  /// **'No past matches recorded yet'**
  String get tournament_detail_matches_no_past;

  /// No description provided for @tournament_schedule_whole_title.
  ///
  /// In en, this message translates to:
  /// **'Schedule Whole Tournament'**
  String get tournament_schedule_whole_title;

  /// No description provided for @tournament_schedule_whole_description.
  ///
  /// In en, this message translates to:
  /// **'Schedule all pending fixtures with default match settings at once.'**
  String get tournament_schedule_whole_description;

  /// No description provided for @tournament_schedule_all_matches_btn.
  ///
  /// In en, this message translates to:
  /// **'Schedule All Matches'**
  String get tournament_schedule_all_matches_btn;

  /// No description provided for @tournament_schedule_success_msg.
  ///
  /// In en, this message translates to:
  /// **'Successfully scheduled all matches!'**
  String get tournament_schedule_success_msg;

  /// No description provided for @tournament_schedule_start_date.
  ///
  /// In en, this message translates to:
  /// **'Starting Date & Time'**
  String get tournament_schedule_start_date;

  /// No description provided for @tournament_schedule_overs.
  ///
  /// In en, this message translates to:
  /// **'Total Overs'**
  String get tournament_schedule_overs;

  /// No description provided for @tournament_schedule_overs_per_bowler.
  ///
  /// In en, this message translates to:
  /// **'Overs per Bowler'**
  String get tournament_schedule_overs_per_bowler;

  /// No description provided for @tournament_schedule_venue.
  ///
  /// In en, this message translates to:
  /// **'Ground / Venue'**
  String get tournament_schedule_venue;

  /// No description provided for @tournament_schedule_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get tournament_schedule_city;

  /// No description provided for @tournament_schedule_spacing.
  ///
  /// In en, this message translates to:
  /// **'Match Spacing'**
  String get tournament_schedule_spacing;

  /// No description provided for @tournament_schedule_spacing_same_day.
  ///
  /// In en, this message translates to:
  /// **'Same day (spaced 3 hours)'**
  String get tournament_schedule_spacing_same_day;

  /// No description provided for @tournament_schedule_spacing_consecutive.
  ///
  /// In en, this message translates to:
  /// **'Consecutive days'**
  String get tournament_schedule_spacing_consecutive;

  /// No description provided for @tournament_schedule_no_pending.
  ///
  /// In en, this message translates to:
  /// **'No pending fixtures to schedule.'**
  String get tournament_schedule_no_pending;

  /// No description provided for @tournament_detail_key_stat_most_runs_title.
  ///
  /// In en, this message translates to:
  /// **'Most Runs'**
  String get tournament_detail_key_stat_most_runs_title;

  /// No description provided for @tournament_detail_key_stat_most_wickets_title.
  ///
  /// In en, this message translates to:
  /// **'Most Wickets'**
  String get tournament_detail_key_stat_most_wickets_title;

  /// No description provided for @tournament_detail_key_stat_most_fours_title.
  ///
  /// In en, this message translates to:
  /// **'Most Fours'**
  String get tournament_detail_key_stat_most_fours_title;

  /// No description provided for @tournament_detail_key_stat_most_sixes_title.
  ///
  /// In en, this message translates to:
  /// **'Most Sixes'**
  String get tournament_detail_key_stat_most_sixes_title;

  /// No description provided for @key_stat_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get key_stat_all;

  /// No description provided for @key_stat_filter_runs.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get key_stat_filter_runs;

  /// No description provided for @key_stat_filter_wickets.
  ///
  /// In en, this message translates to:
  /// **'Wickets'**
  String get key_stat_filter_wickets;

  /// No description provided for @key_stat_filter_fours.
  ///
  /// In en, this message translates to:
  /// **'Fours'**
  String get key_stat_filter_fours;

  /// No description provided for @key_stat_filter_sixes.
  ///
  /// In en, this message translates to:
  /// **'Sixes'**
  String get key_stat_filter_sixes;

  /// No description provided for @key_stat_filter_most_hundreds.
  ///
  /// In en, this message translates to:
  /// **'Most hundreds'**
  String get key_stat_filter_most_hundreds;

  /// No description provided for @key_stat_filter_most_fifties.
  ///
  /// In en, this message translates to:
  /// **'Most fifties'**
  String get key_stat_filter_most_fifties;

  /// No description provided for @key_stat_filter_boundaries.
  ///
  /// In en, this message translates to:
  /// **'Boundaries'**
  String get key_stat_filter_boundaries;

  /// No description provided for @tournament_detail_points_table_points_title.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get tournament_detail_points_table_points_title;

  /// No description provided for @tournament_detail_points_table_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No Points Yet!'**
  String get tournament_detail_points_table_empty_title;

  /// No description provided for @tournament_detail_points_table_empty_description.
  ///
  /// In en, this message translates to:
  /// **'The points table will be updated once matches begin. Stay tuned for the latest standings!'**
  String get tournament_detail_points_table_empty_description;

  /// No description provided for @tournament_detail_points_table_team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get tournament_detail_points_table_team;

  /// No description provided for @tournament_detail_points_table_wins.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get tournament_detail_points_table_wins;

  /// No description provided for @tournament_detail_points_table_losses.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get tournament_detail_points_table_losses;

  /// No description provided for @tournament_detail_points_table_pts.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get tournament_detail_points_table_pts;

  /// No description provided for @tournament_detail_points_table_nrr.
  ///
  /// In en, this message translates to:
  /// **'NRR'**
  String get tournament_detail_points_table_nrr;

  /// No description provided for @tournament_detail_stats_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No stats available yet!'**
  String get tournament_detail_stats_empty_title;

  /// No description provided for @tournament_detail_stats_empty_description.
  ///
  /// In en, this message translates to:
  /// **'The players are warming up! Stay tuned for exciting stats as the team progresses.'**
  String get tournament_detail_stats_empty_description;

  /// No description provided for @tournament_detail_stats_empty_filter_title.
  ///
  /// In en, this message translates to:
  /// **'No Stats Found'**
  String get tournament_detail_stats_empty_filter_title;

  /// No description provided for @tournament_detail_stats_empty_filter_description.
  ///
  /// In en, this message translates to:
  /// **'Please try a different filter.'**
  String get tournament_detail_stats_empty_filter_description;

  /// No description provided for @tournament_detail_stats_player_title.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get tournament_detail_stats_player_title;

  /// No description provided for @tournament_detail_stats_avg_title.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get tournament_detail_stats_avg_title;

  /// No description provided for @tournament_detail_stats_runs_title.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get tournament_detail_stats_runs_title;

  /// No description provided for @tournament_members_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No members yet!'**
  String get tournament_members_empty_title;

  /// No description provided for @tournament_members_empty_description.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add members and start managing your tournament effectively!'**
  String get tournament_members_empty_description;

  /// No description provided for @tournament_members_search_member_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Assign Tournament Role'**
  String get tournament_members_search_member_empty_title;

  /// No description provided for @tournament_members_search_member_empty_description.
  ///
  /// In en, this message translates to:
  /// **'Search for a user to assign a management role. This role will empower them to help organize and lead the tournament effectively.'**
  String get tournament_members_search_member_empty_description;

  /// No description provided for @tournament_members_remove_self.
  ///
  /// In en, this message translates to:
  /// **'Remove self'**
  String get tournament_members_remove_self;

  /// No description provided for @tournament_members_make_organizer.
  ///
  /// In en, this message translates to:
  /// **'Make organizer'**
  String get tournament_members_make_organizer;

  /// No description provided for @tournament_members_remove_member.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get tournament_members_remove_member;

  /// No description provided for @tournament_members_transfer_ownership_description.
  ///
  /// In en, this message translates to:
  /// **'Search for a user to transfer tournament ownership. This grants them full management control. Choose someone who can effectively lead the tournament.'**
  String get tournament_members_transfer_ownership_description;

  /// No description provided for @tournament_type_knock_out.
  ///
  /// In en, this message translates to:
  /// **'Knockout'**
  String get tournament_type_knock_out;

  /// No description provided for @tournament_type_mini_robin.
  ///
  /// In en, this message translates to:
  /// **'Mini Robin'**
  String get tournament_type_mini_robin;

  /// No description provided for @tournament_type_box_league.
  ///
  /// In en, this message translates to:
  /// **'Box League'**
  String get tournament_type_box_league;

  /// No description provided for @tournament_type_double_out.
  ///
  /// In en, this message translates to:
  /// **'Double Out'**
  String get tournament_type_double_out;

  /// No description provided for @tournament_type_best_of_three.
  ///
  /// In en, this message translates to:
  /// **'Best Of three'**
  String get tournament_type_best_of_three;

  /// No description provided for @tournament_type_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get tournament_type_custom;

  /// No description provided for @tournament_type_knock_out_description.
  ///
  /// In en, this message translates to:
  /// **'Teams face off in a single elimination, with the loser immediately knocked out.\nMinimum {count} teams required.'**
  String tournament_type_knock_out_description(Object count);

  /// No description provided for @tournament_type_mini_robin_description.
  ///
  /// In en, this message translates to:
  /// **'A smaller round-robin format where each team plays once against all others.\nMinimum {count} teams required.'**
  String tournament_type_mini_robin_description(Object count);

  /// No description provided for @tournament_type_box_league_description.
  ///
  /// In en, this message translates to:
  /// **'Teams are divided into groups, with top teams advancing to the knockout stage.\nMinimum {count} teams required.'**
  String tournament_type_box_league_description(Object count);

  /// No description provided for @tournament_type_double_out_description.
  ///
  /// In en, this message translates to:
  /// **'Teams get two chances before being knocked out, with a winners and losers bracket.\nMinimum {count} teams required.'**
  String tournament_type_double_out_description(Object count);

  /// No description provided for @tournament_type_best_of_three_description.
  ///
  /// In en, this message translates to:
  /// **'Teams play a series of matches, and the first to win the majority is the champion.\nMinimum {count} teams required.'**
  String tournament_type_best_of_three_description(Object count);

  /// No description provided for @tournament_type_custom_description.
  ///
  /// In en, this message translates to:
  /// **'Fully flexible, create a structure that suits your needs.\nMinimum {count} teams required.'**
  String tournament_type_custom_description(Object count);

  /// No description provided for @add_team_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Add Team'**
  String get add_team_screen_title;

  /// No description provided for @add_team_edit_team_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Team'**
  String get add_team_edit_team_screen_title;

  /// No description provided for @add_team_add_as_member_description_text.
  ///
  /// In en, this message translates to:
  /// **'Add me as a team member'**
  String get add_team_add_as_member_description_text;

  /// No description provided for @add_team_enter_team_name_placeholder_text.
  ///
  /// In en, this message translates to:
  /// **'Enter team name'**
  String get add_team_enter_team_name_placeholder_text;

  /// No description provided for @add_team_team_initial_placeholder_text.
  ///
  /// In en, this message translates to:
  /// **'Team initials (e.g. IND, AUS, PBKS)'**
  String get add_team_team_initial_placeholder_text;

  /// No description provided for @add_team_player_role_title.
  ///
  /// In en, this message translates to:
  /// **'Playing role'**
  String get add_team_player_role_title;

  /// No description provided for @add_team_players_text.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get add_team_players_text;

  /// No description provided for @add_team_already_added.
  ///
  /// In en, this message translates to:
  /// **'Team already added'**
  String get add_team_already_added;

  /// No description provided for @add_team_add_hint_text.
  ///
  /// In en, this message translates to:
  /// **'Added user will be shown here, tap on \'+\' button to add team member.'**
  String get add_team_add_hint_text;

  /// No description provided for @scan_qr_code.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scan_qr_code;

  /// No description provided for @scan_qr_code_description.
  ///
  /// In en, this message translates to:
  /// **'Place the QR code into the frame'**
  String get scan_qr_code_description;

  /// No description provided for @scan_qr_permission_title.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access to use scanning features'**
  String get scan_qr_permission_title;

  /// No description provided for @scan_qr_permission_description.
  ///
  /// In en, this message translates to:
  /// **'Please enable camera access in your device settings to use the scanning feature.'**
  String get scan_qr_permission_description;

  /// No description provided for @scan_qr_permission_settings.
  ///
  /// In en, this message translates to:
  /// **'Go to settings'**
  String get scan_qr_permission_settings;

  /// No description provided for @add_team_member_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Add Team Member'**
  String get add_team_member_screen_title;

  /// No description provided for @add_team_member_details_title.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get add_team_member_details_title;

  /// No description provided for @add_team_member_search_placeholder_text.
  ///
  /// In en, this message translates to:
  /// **'Search by name or mobile number'**
  String get add_team_member_search_placeholder_text;

  /// No description provided for @add_team_member_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Your cricket crew awaits!'**
  String get add_team_member_empty_title;

  /// No description provided for @add_team_member_empty_description_text.
  ///
  /// In en, this message translates to:
  /// **'Search for players already on Sports Tamil, or create a new player with just a name — no app account needed.'**
  String get add_team_member_empty_description_text;

  /// No description provided for @add_team_member_search_no_result_title.
  ///
  /// In en, this message translates to:
  /// **'Oops! No User Found'**
  String get add_team_member_search_no_result_title;

  /// No description provided for @add_team_member_search_description_text.
  ///
  /// In en, this message translates to:
  /// **'No one on Sports Tamil by that name. Create them as a new player and add them right away.'**
  String get add_team_member_search_description_text;

  /// No description provided for @add_team_member_create_player_title.
  ///
  /// In en, this message translates to:
  /// **'New player'**
  String get add_team_member_create_player_title;

  /// No description provided for @add_team_member_create_player_description.
  ///
  /// In en, this message translates to:
  /// **'Add a player who isn\'t on Sports Tamil yet. Only the name is required. The mobile number stays private and lets them link their account when they sign up.'**
  String get add_team_member_create_player_description;

  /// No description provided for @add_team_member_create_player_name.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get add_team_member_create_player_name;

  /// No description provided for @add_team_member_create_player_phone.
  ///
  /// In en, this message translates to:
  /// **'Mobile number (optional)'**
  String get add_team_member_create_player_phone;

  /// No description provided for @add_team_member_phone_not_found_title.
  ///
  /// In en, this message translates to:
  /// **'No player with this number'**
  String get add_team_member_phone_not_found_title;

  /// No description provided for @add_team_member_phone_not_found_body.
  ///
  /// In en, this message translates to:
  /// **'Create the player with this number. When they sign up with it, they can link their account.'**
  String get add_team_member_phone_not_found_body;

  /// No description provided for @add_team_member_create_with_number.
  ///
  /// In en, this message translates to:
  /// **'Create player with this number'**
  String get add_team_member_create_with_number;

  /// No description provided for @add_team_member_phone_invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number. Add the country code if it isn\'t {dial}.'**
  String add_team_member_phone_invalid(String dial);

  /// No description provided for @add_team_member_player_exists.
  ///
  /// In en, this message translates to:
  /// **'{name} already has this number, so they were added instead.'**
  String add_team_member_player_exists(String name);

  /// No description provided for @add_team_member_create_player_button.
  ///
  /// In en, this message translates to:
  /// **'Create player'**
  String get add_team_member_create_player_button;

  /// No description provided for @add_team_member_create_named_player.
  ///
  /// In en, this message translates to:
  /// **'Create \"{name}\"'**
  String add_team_member_create_named_player(String name);

  /// No description provided for @add_team_member_added_text.
  ///
  /// In en, this message translates to:
  /// **'ADDED'**
  String get add_team_member_added_text;

  /// No description provided for @add_team_member_already_added.
  ///
  /// In en, this message translates to:
  /// **'Member already added'**
  String get add_team_member_already_added;

  /// No description provided for @add_team_member_verify_error_text.
  ///
  /// In en, this message translates to:
  /// **'Please enter correct digits'**
  String get add_team_member_verify_error_text;

  /// Enter the last {count} digits of the phone number of the selected player.
  ///
  /// In en, this message translates to:
  /// **'Enter the last {count} digits of the phone number of the selected player.'**
  String add_team_member_verify_placeholder_text(int count);

  /// No description provided for @team_list_add_members_title.
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get team_list_add_members_title;

  /// No description provided for @team_list_all_teams_title.
  ///
  /// In en, this message translates to:
  /// **'All teams'**
  String get team_list_all_teams_title;

  /// No description provided for @team_list_created_by_me_title.
  ///
  /// In en, this message translates to:
  /// **'Created by me'**
  String get team_list_created_by_me_title;

  /// No description provided for @team_list_me_as_member_title.
  ///
  /// In en, this message translates to:
  /// **'Me as member'**
  String get team_list_me_as_member_title;

  /// No description provided for @team_list_me_as_admin_title.
  ///
  /// In en, this message translates to:
  /// **'Me as admin'**
  String get team_list_me_as_admin_title;

  /// No description provided for @team_list_no_teams_created_title.
  ///
  /// In en, this message translates to:
  /// **'No teams created'**
  String get team_list_no_teams_created_title;

  /// No description provided for @team_list_empty_list_description.
  ///
  /// In en, this message translates to:
  /// **'Tap on the “ + ” icon to create a team'**
  String get team_list_empty_list_description;

  /// No description provided for @match_list_no_match_here_title.
  ///
  /// In en, this message translates to:
  /// **'No matches here'**
  String get match_list_no_match_here_title;

  /// No description provided for @match_list_empty_list_description.
  ///
  /// In en, this message translates to:
  /// **'Tap on the “ + ” icon to create a match'**
  String get match_list_empty_list_description;

  /// overs, plural, =0{{overs} overs} =1{{overs} over} other{{overs} overs}}
  ///
  /// In en, this message translates to:
  /// **'{overs, plural, =0{{overs} overs} =1{{overs} over} other{{overs} overs}}'**
  String match_list_overs_title(int overs);

  /// No description provided for @add_match_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Add Match'**
  String get add_match_screen_title;

  /// No description provided for @add_match_screen_edit_match_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Match'**
  String get add_match_screen_edit_match_title;

  /// No description provided for @add_match_team_b_title.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get add_match_team_b_title;

  /// No description provided for @add_match_team_name_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get add_match_team_name_placeholder;

  /// No description provided for @add_match_match_type_title.
  ///
  /// In en, this message translates to:
  /// **'Match Type'**
  String get add_match_match_type_title;

  /// No description provided for @add_match_match_type_limited_overs_title.
  ///
  /// In en, this message translates to:
  /// **'Limited overs'**
  String get add_match_match_type_limited_overs_title;

  /// No description provided for @add_match_match_type_test_match_title.
  ///
  /// In en, this message translates to:
  /// **'Test match'**
  String get add_match_match_type_test_match_title;

  /// No description provided for @add_match_match_type_the_hundred_title.
  ///
  /// In en, this message translates to:
  /// **'The hundred'**
  String get add_match_match_type_the_hundred_title;

  /// No description provided for @add_match_match_type_pair_cricket_title.
  ///
  /// In en, this message translates to:
  /// **'Pair cricket'**
  String get add_match_match_type_pair_cricket_title;

  /// No description provided for @add_match_match_type_box_cricket_title.
  ///
  /// In en, this message translates to:
  /// **'Box cricket'**
  String get add_match_match_type_box_cricket_title;

  /// No description provided for @add_match_ball_type_title.
  ///
  /// In en, this message translates to:
  /// **'Ball Type'**
  String get add_match_ball_type_title;

  /// No description provided for @add_match_ball_type_leather_title.
  ///
  /// In en, this message translates to:
  /// **'Leather'**
  String get add_match_ball_type_leather_title;

  /// No description provided for @add_match_ball_type_tennis_title.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get add_match_ball_type_tennis_title;

  /// No description provided for @add_match_pitch_type_title.
  ///
  /// In en, this message translates to:
  /// **'Pitch Type'**
  String get add_match_pitch_type_title;

  /// No description provided for @add_match_pitch_type_rough_title.
  ///
  /// In en, this message translates to:
  /// **'Rough'**
  String get add_match_pitch_type_rough_title;

  /// No description provided for @add_match_pitch_type_cement_title.
  ///
  /// In en, this message translates to:
  /// **'Cement'**
  String get add_match_pitch_type_cement_title;

  /// No description provided for @add_match_pitch_type_turf_title.
  ///
  /// In en, this message translates to:
  /// **'Turf'**
  String get add_match_pitch_type_turf_title;

  /// No description provided for @add_match_pitch_type_astroturf_title.
  ///
  /// In en, this message translates to:
  /// **'Astroturf'**
  String get add_match_pitch_type_astroturf_title;

  /// No description provided for @add_match_pitch_type_matting_title.
  ///
  /// In en, this message translates to:
  /// **'Matting'**
  String get add_match_pitch_type_matting_title;

  /// No description provided for @add_match_match_officials_title.
  ///
  /// In en, this message translates to:
  /// **'Match Officials'**
  String get add_match_match_officials_title;

  /// No description provided for @match_rules_title.
  ///
  /// In en, this message translates to:
  /// **'Match Rules'**
  String get match_rules_title;

  /// No description provided for @match_rules_balls_per_over_title.
  ///
  /// In en, this message translates to:
  /// **'Balls per over'**
  String get match_rules_balls_per_over_title;

  /// No description provided for @match_rules_balls_per_over_summary.
  ///
  /// In en, this message translates to:
  /// **'{count}-ball overs'**
  String match_rules_balls_per_over_summary(int count);

  /// No description provided for @match_rules_wide_runs_title.
  ///
  /// In en, this message translates to:
  /// **'Runs for a wide'**
  String get match_rules_wide_runs_title;

  /// No description provided for @match_rules_no_ball_runs_title.
  ///
  /// In en, this message translates to:
  /// **'Runs for a no-ball'**
  String get match_rules_no_ball_runs_title;

  /// No description provided for @match_rules_wide_rebowl_title.
  ///
  /// In en, this message translates to:
  /// **'Re-bowl wides'**
  String get match_rules_wide_rebowl_title;

  /// No description provided for @match_rules_wide_rebowl_description.
  ///
  /// In en, this message translates to:
  /// **'When off, a wide counts as one of the balls in the over'**
  String get match_rules_wide_rebowl_description;

  /// No description provided for @match_rules_free_hit_title.
  ///
  /// In en, this message translates to:
  /// **'Free hit after no-ball'**
  String get match_rules_free_hit_title;

  /// No description provided for @match_rules_free_hit_description.
  ///
  /// In en, this message translates to:
  /// **'The next ball after a no-ball can only be a run out'**
  String get match_rules_free_hit_description;

  /// No description provided for @match_rules_last_man_standing_title.
  ///
  /// In en, this message translates to:
  /// **'Last man standing'**
  String get match_rules_last_man_standing_title;

  /// No description provided for @match_rules_last_man_standing_description.
  ///
  /// In en, this message translates to:
  /// **'The last batter can keep batting alone'**
  String get match_rules_last_man_standing_description;

  /// No description provided for @add_match_officials_umpires_title.
  ///
  /// In en, this message translates to:
  /// **'Umpires'**
  String get add_match_officials_umpires_title;

  /// No description provided for @add_match_officials_scorers_title.
  ///
  /// In en, this message translates to:
  /// **'Scorers'**
  String get add_match_officials_scorers_title;

  /// No description provided for @add_match_officials_live_streamers_title.
  ///
  /// In en, this message translates to:
  /// **'Live Streamers'**
  String get add_match_officials_live_streamers_title;

  /// No description provided for @add_match_officials_referee_title.
  ///
  /// In en, this message translates to:
  /// **'Referee'**
  String get add_match_officials_referee_title;

  /// No description provided for @add_match_officials_commentators_title.
  ///
  /// In en, this message translates to:
  /// **'Commentators'**
  String get add_match_officials_commentators_title;

  /// No description provided for @add_match_officials_others_title.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get add_match_officials_others_title;

  /// No description provided for @add_match_ground_title.
  ///
  /// In en, this message translates to:
  /// **'Ground'**
  String get add_match_ground_title;

  /// No description provided for @add_match_match_schedule_title.
  ///
  /// In en, this message translates to:
  /// **'Match Schedule'**
  String get add_match_match_schedule_title;

  /// No description provided for @add_match_start_match_title.
  ///
  /// In en, this message translates to:
  /// **'Start Match'**
  String get add_match_start_match_title;

  /// No description provided for @add_match_date_title.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get add_match_date_title;

  /// No description provided for @add_match_time_title.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get add_match_time_title;

  /// No description provided for @add_match_no_of_over_title.
  ///
  /// In en, this message translates to:
  /// **'No. of over'**
  String get add_match_no_of_over_title;

  /// No description provided for @add_match_over_per_bowler_title.
  ///
  /// In en, this message translates to:
  /// **'Over per bowler'**
  String get add_match_over_per_bowler_title;

  /// No description provided for @add_match_joined_on_title.
  ///
  /// In en, this message translates to:
  /// **'Joined on'**
  String get add_match_joined_on_title;

  /// No description provided for @add_match_officials_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Add Match Officials'**
  String get add_match_officials_screen_title;

  /// No description provided for @add_match_officials_add_officials_title.
  ///
  /// In en, this message translates to:
  /// **'Add officials'**
  String get add_match_officials_add_officials_title;

  /// No description provided for @add_match_invalid_over_count_error.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid total over'**
  String get add_match_invalid_over_count_error;

  /// No description provided for @add_match_empty_fields_error.
  ///
  /// In en, this message translates to:
  /// **'Please fill the required details'**
  String get add_match_empty_fields_error;

  /// No description provided for @add_match_unselected_team_error.
  ///
  /// In en, this message translates to:
  /// **'Please select teams'**
  String get add_match_unselected_team_error;

  /// No description provided for @add_match_invalid_squad_error.
  ///
  /// In en, this message translates to:
  /// **'Please select valid squad'**
  String get add_match_invalid_squad_error;

  /// No description provided for @search_user_hint_title.
  ///
  /// In en, this message translates to:
  /// **'Search user name'**
  String get search_user_hint_title;

  /// No description provided for @search_user_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Time to gather your officials!'**
  String get search_user_empty_title;

  /// No description provided for @search_user_empty_description_text.
  ///
  /// In en, this message translates to:
  /// **'Search and assign officials for your next match. Get ready for cricket action!'**
  String get search_user_empty_description_text;

  /// No description provided for @search_team_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Search Team'**
  String get search_team_screen_title;

  /// No description provided for @search_team_selection_error_text.
  ///
  /// In en, this message translates to:
  /// **'The team must have at least 2 players to add it in a match.'**
  String get search_team_selection_error_text;

  /// No description provided for @search_team_search_placeholder_title.
  ///
  /// In en, this message translates to:
  /// **'Search team name'**
  String get search_team_search_placeholder_title;

  /// Power play {count}
  ///
  /// In en, this message translates to:
  /// **'Power play {count}'**
  String power_play_text(int count);

  /// No description provided for @select_squad_select_admin_captain_title.
  ///
  /// In en, this message translates to:
  /// **'Select Captain and Admin'**
  String get select_squad_select_admin_captain_title;

  /// No description provided for @select_squad_captain_short_title.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get select_squad_captain_short_title;

  /// No description provided for @select_squad_playing_squad_title.
  ///
  /// In en, this message translates to:
  /// **'Playing Squad'**
  String get select_squad_playing_squad_title;

  /// No description provided for @select_squad_least_require_text.
  ///
  /// In en, this message translates to:
  /// **'*At-least two players required'**
  String get select_squad_least_require_text;

  /// No description provided for @select_squad_rest_of_team_title.
  ///
  /// In en, this message translates to:
  /// **'Rest of The Team'**
  String get select_squad_rest_of_team_title;

  /// No description provided for @select_squad_empty_squad_text.
  ///
  /// In en, this message translates to:
  /// **'Select squad via adding it from team members list.'**
  String get select_squad_empty_squad_text;

  /// No description provided for @select_squad_empty_team_member_text.
  ///
  /// In en, this message translates to:
  /// **'No team member added in this team, try to add people you know as a team member.'**
  String get select_squad_empty_team_member_text;

  /// No description provided for @add_toss_detail_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Add Toss Detail'**
  String get add_toss_detail_screen_title;

  /// No description provided for @add_toss_detail_who_won_toss_text.
  ///
  /// In en, this message translates to:
  /// **'Who won the toss?'**
  String get add_toss_detail_who_won_toss_text;

  /// No description provided for @add_toss_detail_winner_elected_to_text.
  ///
  /// In en, this message translates to:
  /// **'Toss-winner elected to - ?'**
  String get add_toss_detail_winner_elected_to_text;

  /// No description provided for @add_substitute_search_substitute_title.
  ///
  /// In en, this message translates to:
  /// **'Who’s ready to step in?'**
  String get add_substitute_search_substitute_title;

  /// No description provided for @add_substitute_search_substitute_description.
  ///
  /// In en, this message translates to:
  /// **'Search and assign a substitute fielder to maintain your fielding edge.'**
  String get add_substitute_search_substitute_description;

  /// No description provided for @team_detail_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Team Detail'**
  String get team_detail_screen_title;

  /// No description provided for @team_detail_member_tab_title.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get team_detail_member_tab_title;

  /// No description provided for @team_detail_empty_matches_title.
  ///
  /// In en, this message translates to:
  /// **'No matches scheduled yet!'**
  String get team_detail_empty_matches_title;

  /// No description provided for @team_detail_empty_matches_description_text.
  ///
  /// In en, this message translates to:
  /// **'Get your cricket game on! Schedule your cricket match with ease!'**
  String get team_detail_empty_matches_description_text;

  /// No description provided for @team_detail_visitor_empty_matches_description_text.
  ///
  /// In en, this message translates to:
  /// **'Until now, the team has not competed.'**
  String get team_detail_visitor_empty_matches_description_text;

  /// No description provided for @team_detail_empty_member_title.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t any member!'**
  String get team_detail_empty_member_title;

  /// No description provided for @team_detail_empty_member_description_text.
  ///
  /// In en, this message translates to:
  /// **'Invite your friends to build your dream team and start tracking matches together.'**
  String get team_detail_empty_member_description_text;

  /// No description provided for @team_detail_visitor_empty_member_description_text.
  ///
  /// In en, this message translates to:
  /// **'No member has been added to the team.'**
  String get team_detail_visitor_empty_member_description_text;

  /// No description provided for @team_detail_empty_stat_title.
  ///
  /// In en, this message translates to:
  /// **'No stats available yet!'**
  String get team_detail_empty_stat_title;

  /// No description provided for @team_detail_empty_stat_description_text.
  ///
  /// In en, this message translates to:
  /// **'The players are warming up! Stay tuned for exciting stats as the team progresses.'**
  String get team_detail_empty_stat_description_text;

  /// No description provided for @team_detail_add_members_title.
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get team_detail_add_members_title;

  /// No description provided for @team_detail_add_match_title.
  ///
  /// In en, this message translates to:
  /// **'Add match'**
  String get team_detail_add_match_title;

  /// No description provided for @team_detail_use_qr_description.
  ///
  /// In en, this message translates to:
  /// **'Use your phone camera or a QR code app to scan the code above and easily add the team to the tournament'**
  String get team_detail_use_qr_description;

  /// No description provided for @make_admin_selection_error.
  ///
  /// In en, this message translates to:
  /// **'Can\'t select deactivated user as admin'**
  String get make_admin_selection_error;

  /// No description provided for @team_detail_admin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{count} admins} =1{{count} admin} other{{count} admins}}'**
  String team_detail_admin(num count);

  /// No description provided for @team_detail_remove_ownership_title.
  ///
  /// In en, this message translates to:
  /// **'Remove ownership'**
  String get team_detail_remove_ownership_title;

  /// No description provided for @team_detail_transfer_ownership_description.
  ///
  /// In en, this message translates to:
  /// **'Search for a user to transfer team ownership. This grants them full management control. Choose someone who can effectively lead the team.'**
  String get team_detail_transfer_ownership_description;

  /// No description provided for @team_detail_match_tab_title.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get team_detail_match_tab_title;

  /// No description provided for @team_detail_stat_tab_title.
  ///
  /// In en, this message translates to:
  /// **'Stat'**
  String get team_detail_stat_tab_title;

  /// Won({win})
  ///
  /// In en, this message translates to:
  /// **'Won({win})'**
  String team_detail_won_title(int win);

  /// Lost({lost})
  ///
  /// In en, this message translates to:
  /// **'Lost({lost})'**
  String team_detail_lost_title(int lost);

  /// Tie({tie})
  ///
  /// In en, this message translates to:
  /// **'Tie({tie})'**
  String team_detail_tie_title(int tie);

  /// No description provided for @team_detail_match_title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{{count} Matches} =1{{count} Match} other{{count} Matches}}'**
  String team_detail_match_title(num count);

  /// No description provided for @team_detail_runs_made_title.
  ///
  /// In en, this message translates to:
  /// **'Runs Made'**
  String get team_detail_runs_made_title;

  /// No description provided for @team_detail_wickets_taken_title.
  ///
  /// In en, this message translates to:
  /// **'Wickets Taken'**
  String get team_detail_wickets_taken_title;

  /// No description provided for @team_detail_highest_runs_title.
  ///
  /// In en, this message translates to:
  /// **'Highest Runs'**
  String get team_detail_highest_runs_title;

  /// No description provided for @team_detail_lowest_runs_title.
  ///
  /// In en, this message translates to:
  /// **'Lowest Runs'**
  String get team_detail_lowest_runs_title;

  /// No description provided for @team_detail_run_rate_title.
  ///
  /// In en, this message translates to:
  /// **'Run Rate'**
  String get team_detail_run_rate_title;

  /// No description provided for @user_detail_info_title.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get user_detail_info_title;

  /// No description provided for @user_detail_personal_information_title.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get user_detail_personal_information_title;

  /// No description provided for @user_detail_participation_title.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get user_detail_participation_title;

  /// No description provided for @user_detail_role_title.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get user_detail_role_title;

  /// No description provided for @user_detail_joining_date_title.
  ///
  /// In en, this message translates to:
  /// **'Joining date'**
  String get user_detail_joining_date_title;

  /// No description provided for @user_detail_test_title.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get user_detail_test_title;

  /// No description provided for @user_detail_matches_title.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get user_detail_matches_title;

  /// No description provided for @user_detail_innings_title.
  ///
  /// In en, this message translates to:
  /// **'Innings'**
  String get user_detail_innings_title;

  /// No description provided for @user_detail_runs_title.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get user_detail_runs_title;

  /// No description provided for @user_detail_balls_title.
  ///
  /// In en, this message translates to:
  /// **'Balls'**
  String get user_detail_balls_title;

  /// No description provided for @user_detail_average_title.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get user_detail_average_title;

  /// No description provided for @user_detail_strike_rate_title.
  ///
  /// In en, this message translates to:
  /// **'SR'**
  String get user_detail_strike_rate_title;

  /// No description provided for @user_detail_fours_title.
  ///
  /// In en, this message translates to:
  /// **'Fours'**
  String get user_detail_fours_title;

  /// No description provided for @user_detail_sixes_title.
  ///
  /// In en, this message translates to:
  /// **'Sixes'**
  String get user_detail_sixes_title;

  /// No description provided for @user_detail_fifties_title.
  ///
  /// In en, this message translates to:
  /// **'50s'**
  String get user_detail_fifties_title;

  /// No description provided for @user_detail_hundreds_title.
  ///
  /// In en, this message translates to:
  /// **'100s'**
  String get user_detail_hundreds_title;

  /// No description provided for @user_detail_ducks_title.
  ///
  /// In en, this message translates to:
  /// **'Ducks'**
  String get user_detail_ducks_title;

  /// No description provided for @user_detail_maidens_title.
  ///
  /// In en, this message translates to:
  /// **'Maidens'**
  String get user_detail_maidens_title;

  /// No description provided for @user_detail_wickets_title.
  ///
  /// In en, this message translates to:
  /// **'Wickets'**
  String get user_detail_wickets_title;

  /// No description provided for @user_detail_eco_title.
  ///
  /// In en, this message translates to:
  /// **'Eco'**
  String get user_detail_eco_title;

  /// No description provided for @user_detail_no_ball_title.
  ///
  /// In en, this message translates to:
  /// **'NB'**
  String get user_detail_no_ball_title;

  /// No description provided for @user_detail_wide_ball_title.
  ///
  /// In en, this message translates to:
  /// **'WB'**
  String get user_detail_wide_ball_title;

  /// No description provided for @user_detail_catches_title.
  ///
  /// In en, this message translates to:
  /// **'Catches'**
  String get user_detail_catches_title;

  /// No description provided for @user_detail_run_out_title.
  ///
  /// In en, this message translates to:
  /// **'Run out'**
  String get user_detail_run_out_title;

  /// No description provided for @user_detail_stumping_title.
  ///
  /// In en, this message translates to:
  /// **'Stumping'**
  String get user_detail_stumping_title;

  /// No description provided for @match_status_yet_to_start_title.
  ///
  /// In en, this message translates to:
  /// **'Yet to start'**
  String get match_status_yet_to_start_title;

  /// No description provided for @match_status_abandoned_title.
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get match_status_abandoned_title;

  /// No description provided for @wicket_type_bowled_title.
  ///
  /// In en, this message translates to:
  /// **'Bowled'**
  String get wicket_type_bowled_title;

  /// No description provided for @wicket_type_caught_title.
  ///
  /// In en, this message translates to:
  /// **'Caught'**
  String get wicket_type_caught_title;

  /// No description provided for @wicket_type_caught_behind_title.
  ///
  /// In en, this message translates to:
  /// **'Caught Behind'**
  String get wicket_type_caught_behind_title;

  /// No description provided for @wicket_type_caught_bowled_title.
  ///
  /// In en, this message translates to:
  /// **'Caught And Bowled'**
  String get wicket_type_caught_bowled_title;

  /// No description provided for @wicket_type_leg_before_wicket_title.
  ///
  /// In en, this message translates to:
  /// **'Leg Before Wicket'**
  String get wicket_type_leg_before_wicket_title;

  /// No description provided for @wicket_type_stumped_title.
  ///
  /// In en, this message translates to:
  /// **'Stumped'**
  String get wicket_type_stumped_title;

  /// No description provided for @wicket_type_hit_wicket_title.
  ///
  /// In en, this message translates to:
  /// **'Hit Wicket'**
  String get wicket_type_hit_wicket_title;

  /// No description provided for @wicket_type_hit_ball_twice_title.
  ///
  /// In en, this message translates to:
  /// **'Hit Ball Twice'**
  String get wicket_type_hit_ball_twice_title;

  /// No description provided for @wicket_type_handled_ball_title.
  ///
  /// In en, this message translates to:
  /// **'Handled Ball'**
  String get wicket_type_handled_ball_title;

  /// No description provided for @wicket_type_obstructing_field_title.
  ///
  /// In en, this message translates to:
  /// **'Obstructing the Field'**
  String get wicket_type_obstructing_field_title;

  /// No description provided for @wicket_type_timed_out_title.
  ///
  /// In en, this message translates to:
  /// **'Timed Out'**
  String get wicket_type_timed_out_title;

  /// No description provided for @wicket_type_retired_title.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get wicket_type_retired_title;

  /// No description provided for @wicket_type_retired_hurt_title.
  ///
  /// In en, this message translates to:
  /// **'Retired Hurt'**
  String get wicket_type_retired_hurt_title;

  /// No description provided for @wicket_type_short_timed_out_title.
  ///
  /// In en, this message translates to:
  /// **'TO'**
  String get wicket_type_short_timed_out_title;

  /// No description provided for @wicket_type_short_retired_title.
  ///
  /// In en, this message translates to:
  /// **'RT'**
  String get wicket_type_short_retired_title;

  /// No description provided for @wicket_type_short_retired_hurt_title.
  ///
  /// In en, this message translates to:
  /// **'RTH'**
  String get wicket_type_short_retired_hurt_title;

  /// No description provided for @match_detail_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Match Detail'**
  String get match_detail_screen_title;

  /// No description provided for @match_detail_commentary_tab_title.
  ///
  /// In en, this message translates to:
  /// **'Commentary'**
  String get match_detail_commentary_tab_title;

  /// No description provided for @match_detail_scorecard_tab_title.
  ///
  /// In en, this message translates to:
  /// **'Scorecard'**
  String get match_detail_scorecard_tab_title;

  /// No description provided for @match_detail_squad_tab_title.
  ///
  /// In en, this message translates to:
  /// **'Squad'**
  String get match_detail_squad_tab_title;

  /// No description provided for @match_detail_match_info_tab_title.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get match_detail_match_info_tab_title;

  /// No description provided for @match_detail_highlight_tab_title.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get match_detail_highlight_tab_title;

  /// No description provided for @match_detail_overs_tab_title.
  ///
  /// In en, this message translates to:
  /// **'Overs'**
  String get match_detail_overs_tab_title;

  /// No description provided for @match_detail_match_not_started_error_title.
  ///
  /// In en, this message translates to:
  /// **'Match has not started yet.'**
  String get match_detail_match_not_started_error_title;

  /// No description provided for @match_detail_error_description_text.
  ///
  /// In en, this message translates to:
  /// **'The detailed will be available after the start of the match.'**
  String get match_detail_error_description_text;

  /// No description provided for @match_detail_highlight_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No highlights currently available.'**
  String get match_detail_highlight_empty_title;

  /// No description provided for @match_detail_highlight_empty_description_text.
  ///
  /// In en, this message translates to:
  /// **'No events recorded yet. Check back later for updates and highlights.'**
  String get match_detail_highlight_empty_description_text;

  /// No description provided for @match_info_match_title.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get match_info_match_title;

  /// No description provided for @match_info_date_title.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get match_info_date_title;

  /// No description provided for @match_info_toss_title.
  ///
  /// In en, this message translates to:
  /// **'Toss'**
  String get match_info_toss_title;

  /// No description provided for @match_info_time_title.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get match_info_time_title;

  /// No description provided for @match_info_umpire_title.
  ///
  /// In en, this message translates to:
  /// **'Umpire'**
  String get match_info_umpire_title;

  /// No description provided for @match_info_referee_title.
  ///
  /// In en, this message translates to:
  /// **'Referee'**
  String get match_info_referee_title;

  /// No description provided for @match_info_date_and_time_title.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get match_info_date_and_time_title;

  /// {name} Squad
  ///
  /// In en, this message translates to:
  /// **'{name} Squad'**
  String match_info_squad_title(String name);

  /// No description provided for @match_info_venue_title.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get match_info_venue_title;

  /// No description provided for @match_info_ground_title.
  ///
  /// In en, this message translates to:
  /// **'Ground'**
  String get match_info_ground_title;

  /// No description provided for @match_info_city_title.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get match_info_city_title;

  /// No description provided for @match_info_captain_short_title.
  ///
  /// In en, this message translates to:
  /// **'(c)'**
  String get match_info_captain_short_title;

  /// {name} won the toss and opt to {decision}
  ///
  /// In en, this message translates to:
  /// **'{name} won the toss and opt to {decision}'**
  String match_info_toss_detail_text(String name, String decision);

  /// {bowler} to {batsman}
  ///
  /// In en, this message translates to:
  /// **'{bowler} to {batsman}'**
  String match_commentary_bowler_to_batsman_text(String bowler, String batsman);

  ///  b {bowler}
  ///
  /// In en, this message translates to:
  /// **' b {bowler}'**
  String match_commentary_b_bowler_text(String bowler);

  ///  c {fielder}
  ///
  /// In en, this message translates to:
  /// **' c {fielder}'**
  String match_commentary_c_fielder_text(String fielder);

  ///  by {fielder}
  ///
  /// In en, this message translates to:
  /// **' by {fielder}'**
  String match_commentary_by_fielder_text(String fielder);

  ///  {run}({ballCount}) [4s-{fours} 6s-{sixes}]
  ///
  /// In en, this message translates to:
  /// **' {run}({ballCount}) [4s-{fours} 6s-{sixes}]'**
  String match_commentary_runs_fours_sixes_text(
      int run, int ballCount, int fours, int sixes);

  /// {run, plural, =0{no} =1{{run} run} other{{run} runs}}
  ///
  /// In en, this message translates to:
  /// **'{run, plural, =0{no runs} =1{{run} run} other{{run} runs}}'**
  String match_commentary_runs_text(int run);

  /// Ov {over}
  ///
  /// In en, this message translates to:
  /// **'Ov {over}'**
  String match_commentary_former_over_short_text(int over);

  /// No description provided for @match_commentary_four_text.
  ///
  /// In en, this message translates to:
  /// **'Four'**
  String get match_commentary_four_text;

  /// No description provided for @match_commentary_six_text.
  ///
  /// In en, this message translates to:
  /// **'Six'**
  String get match_commentary_six_text;

  /// No description provided for @match_commentary_out_text.
  ///
  /// In en, this message translates to:
  /// **'OUT,'**
  String get match_commentary_out_text;

  /// No description provided for @match_commentary_back_to_attack_text.
  ///
  /// In en, this message translates to:
  /// **' is back to attack'**
  String get match_commentary_back_to_attack_text;

  /// No description provided for @match_commentary_end_inning_text_part_1.
  ///
  /// In en, this message translates to:
  /// **' wraps up their innings, leaving '**
  String get match_commentary_end_inning_text_part_1;

  /// No description provided for @match_commentary_end_inning_text_part_2.
  ///
  /// In en, this message translates to:
  /// **' for victory.'**
  String get match_commentary_end_inning_text_part_2;

  /// Inning {count}
  ///
  /// In en, this message translates to:
  /// **'Inning {count}'**
  String match_commentary_inning_count_text(int count);

  /// No description provided for @match_scorecard_fall_of_wicket_text.
  ///
  /// In en, this message translates to:
  /// **'Fall of Wicket'**
  String get match_scorecard_fall_of_wicket_text;

  /// No description provided for @match_scorecard_over_text.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get match_scorecard_over_text;

  /// No description provided for @match_scorecard_run_text.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get match_scorecard_run_text;

  /// No description provided for @match_scorecard_power_play_text.
  ///
  /// In en, this message translates to:
  /// **'PowerPlay'**
  String get match_scorecard_power_play_text;

  /// No description provided for @match_scorecard_run_short_text.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get match_scorecard_run_short_text;

  /// No description provided for @match_scorecard_ball_short_text.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get match_scorecard_ball_short_text;

  /// No description provided for @match_scorecard_fours_short_text.
  ///
  /// In en, this message translates to:
  /// **'4s'**
  String get match_scorecard_fours_short_text;

  /// No description provided for @match_scorecard_sixes_short_text.
  ///
  /// In en, this message translates to:
  /// **'6s'**
  String get match_scorecard_sixes_short_text;

  /// No description provided for @match_scorecard_strike_rate_short_text.
  ///
  /// In en, this message translates to:
  /// **'SR'**
  String get match_scorecard_strike_rate_short_text;

  /// No description provided for @match_scorecard_over_short_text.
  ///
  /// In en, this message translates to:
  /// **'O'**
  String get match_scorecard_over_short_text;

  /// No description provided for @match_scorecard_maiden_short_text.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get match_scorecard_maiden_short_text;

  /// No description provided for @match_scorecard_wicket_short_text.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get match_scorecard_wicket_short_text;

  /// No description provided for @match_scorecard_no_ball_short_text.
  ///
  /// In en, this message translates to:
  /// **'NB'**
  String get match_scorecard_no_ball_short_text;

  /// No description provided for @match_scorecard_wide_ball_short_text.
  ///
  /// In en, this message translates to:
  /// **'WB'**
  String get match_scorecard_wide_ball_short_text;

  /// No description provided for @match_scorecard_economy_short_text.
  ///
  /// In en, this message translates to:
  /// **'ECO'**
  String get match_scorecard_economy_short_text;

  /// No description provided for @match_scorecard_batter_text.
  ///
  /// In en, this message translates to:
  /// **'Batter'**
  String get match_scorecard_batter_text;

  /// No description provided for @match_scorecard_bowler_text.
  ///
  /// In en, this message translates to:
  /// **'Bowler'**
  String get match_scorecard_bowler_text;

  /// No description provided for @match_scorecard_not_out_text.
  ///
  /// In en, this message translates to:
  /// **'Not out'**
  String get match_scorecard_not_out_text;

  /// No description provided for @match_scorecard_did_not_bat_text.
  ///
  /// In en, this message translates to:
  /// **'Did not bat'**
  String get match_scorecard_did_not_bat_text;

  /// b {bowler} c {fielder}
  ///
  /// In en, this message translates to:
  /// **'b {bowler} c {fielder}'**
  String match_scorecard_bowler_catcher_short_text(
      String bowler, String fielder);

  /// No description provided for @match_scorecard_extra_text.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get match_scorecard_extra_text;

  /// No description provided for @match_scorecard_total_text.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get match_scorecard_total_text;

  /// No description provided for @match_scorecard_empty_scorecard_text.
  ///
  /// In en, this message translates to:
  /// **'Scorecard will appear once the match starts'**
  String get match_scorecard_empty_scorecard_text;

  /// b {bye} lb {legBye} w {wide}  nb {noBall} p {penalty}
  ///
  /// In en, this message translates to:
  /// **'b {bye} lb {legBye} w {wide}  nb {noBall} p {penalty}'**
  String match_scorecard_extras_short_text(
      int bye, int legBye, int wide, int noBall, int penalty);

  /// No description provided for @match_scorecard_wicket_over_text.
  ///
  /// In en, this message translates to:
  /// **'{wicket, plural, =0{no wickets} =1{{wicket} wicket} other{{wicket} wickets}} {over} over'**
  String match_scorecard_wicket_over_text(int wicket, double over);

  /// ({over} Ov)
  ///
  /// In en, this message translates to:
  /// **'({over} Ov)'**
  String match_commentary_trailing_over_short_text(double over);

  /// No description provided for @match_squad_playing_title.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get match_squad_playing_title;

  /// No description provided for @match_squad_bench_title.
  ///
  /// In en, this message translates to:
  /// **'Bench'**
  String get match_squad_bench_title;

  /// No description provided for @match_highlight_filter_all_text.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get match_highlight_filter_all_text;

  /// No description provided for @match_highlight_filter_fours_text.
  ///
  /// In en, this message translates to:
  /// **'Fours'**
  String get match_highlight_filter_fours_text;

  /// No description provided for @match_highlight_filter_sixes_text.
  ///
  /// In en, this message translates to:
  /// **'Sixes'**
  String get match_highlight_filter_sixes_text;

  /// No description provided for @score_board_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Score Board'**
  String get score_board_screen_title;

  /// No description provided for @score_board_wicket_short_text.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get score_board_wicket_short_text;

  /// No description provided for @score_board_no_ball_short_text.
  ///
  /// In en, this message translates to:
  /// **'NB'**
  String get score_board_no_ball_short_text;

  /// No description provided for @score_board_wide_ball_short_text.
  ///
  /// In en, this message translates to:
  /// **'WB'**
  String get score_board_wide_ball_short_text;

  /// No description provided for @score_board_leg_bye_short_text.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get score_board_leg_bye_short_text;

  /// No description provided for @score_board_bye_short_text.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get score_board_bye_short_text;

  /// No description provided for @score_board_zero_text.
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get score_board_zero_text;

  /// No description provided for @score_board_one_text.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get score_board_one_text;

  /// No description provided for @score_board_two_text.
  ///
  /// In en, this message translates to:
  /// **'2'**
  String get score_board_two_text;

  /// No description provided for @score_board_three_text.
  ///
  /// In en, this message translates to:
  /// **'3'**
  String get score_board_three_text;

  /// No description provided for @score_board_four_text.
  ///
  /// In en, this message translates to:
  /// **'4'**
  String get score_board_four_text;

  /// No description provided for @score_board_four_title.
  ///
  /// In en, this message translates to:
  /// **'Four'**
  String get score_board_four_title;

  /// No description provided for @score_board_six_text.
  ///
  /// In en, this message translates to:
  /// **'6'**
  String get score_board_six_text;

  /// No description provided for @score_board_six_title.
  ///
  /// In en, this message translates to:
  /// **'Six'**
  String get score_board_six_title;

  /// No description provided for @score_board_five_or_seven_text.
  ///
  /// In en, this message translates to:
  /// **'5, 7'**
  String get score_board_five_or_seven_text;

  /// No description provided for @score_board_five_text.
  ///
  /// In en, this message translates to:
  /// **'5'**
  String get score_board_five_text;

  /// No description provided for @score_board_seven_text.
  ///
  /// In en, this message translates to:
  /// **'7'**
  String get score_board_seven_text;

  /// No description provided for @score_board_out_text.
  ///
  /// In en, this message translates to:
  /// **'OUT'**
  String get score_board_out_text;

  /// No description provided for @score_board_wicket_text.
  ///
  /// In en, this message translates to:
  /// **'WICKET'**
  String get score_board_wicket_text;

  /// No description provided for @score_board_leg_bye_text.
  ///
  /// In en, this message translates to:
  /// **'LB'**
  String get score_board_leg_bye_text;

  /// No description provided for @score_board_bye_text.
  ///
  /// In en, this message translates to:
  /// **'BYE'**
  String get score_board_bye_text;

  /// No description provided for @score_board_undo_title.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get score_board_undo_title;

  /// No description provided for @score_board_player_title.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get score_board_player_title;

  /// No description provided for @score_board_extras_title.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get score_board_extras_title;

  /// No description provided for @score_board_runs_title.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get score_board_runs_title;

  /// No description provided for @score_board_not_from_bat_text.
  ///
  /// In en, this message translates to:
  /// **'Not from bat?'**
  String get score_board_not_from_bat_text;

  /// No description provided for @score_board_is_boundary_text.
  ///
  /// In en, this message translates to:
  /// **'Is that a boundary?'**
  String get score_board_is_boundary_text;

  /// No description provided for @score_board_over_complete_title.
  ///
  /// In en, this message translates to:
  /// **'Over complete'**
  String get score_board_over_complete_title;

  /// No description provided for @score_board_inning_complete_title.
  ///
  /// In en, this message translates to:
  /// **'Inning complete'**
  String get score_board_inning_complete_title;

  /// No description provided for @score_board_match_complete_title.
  ///
  /// In en, this message translates to:
  /// **'Match complete'**
  String get score_board_match_complete_title;

  /// No description provided for @score_board_match_tied_text.
  ///
  /// In en, this message translates to:
  /// **'The match has been tied'**
  String get score_board_match_tied_text;

  /// No description provided for @score_board_match_tied.
  ///
  /// In en, this message translates to:
  /// **'Match tied'**
  String get score_board_match_tied;

  /// No description provided for @score_board_start_next_inning_title.
  ///
  /// In en, this message translates to:
  /// **'Start Next Inning'**
  String get score_board_start_next_inning_title;

  /// No description provided for @score_board_end_inning_title.
  ///
  /// In en, this message translates to:
  /// **'End Inning'**
  String get score_board_end_inning_title;

  /// No description provided for @score_board_current_team_title.
  ///
  /// In en, this message translates to:
  /// **'Current Team'**
  String get score_board_current_team_title;

  /// No description provided for @score_board_team_title.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get score_board_team_title;

  /// No description provided for @score_board_r_title.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get score_board_r_title;

  /// No description provided for @score_board_w_title.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get score_board_w_title;

  /// No description provided for @score_board_o_title.
  ///
  /// In en, this message translates to:
  /// **'O'**
  String get score_board_o_title;

  /// No description provided for @score_board_won_by_title.
  ///
  /// In en, this message translates to:
  /// **' Won By '**
  String get score_board_won_by_title;

  /// No description provided for @score_board_won_title.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get score_board_won_title;

  /// No description provided for @score_board_by_title.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get score_board_by_title;

  /// No description provided for @score_board_choose_opening_batsmen_title.
  ///
  /// In en, this message translates to:
  /// **'Choose opening Batsmen'**
  String get score_board_choose_opening_batsmen_title;

  /// No description provided for @score_board_choose_fielder_title.
  ///
  /// In en, this message translates to:
  /// **'Choose fielder'**
  String get score_board_choose_fielder_title;

  /// No description provided for @score_board_injured_tag_title.
  ///
  /// In en, this message translates to:
  /// **'Injured'**
  String get score_board_injured_tag_title;

  /// No description provided for @score_board_who_on_strike_title.
  ///
  /// In en, this message translates to:
  /// **'Who\'s on Strike?'**
  String get score_board_who_on_strike_title;

  /// No description provided for @score_board_who_got_out_title.
  ///
  /// In en, this message translates to:
  /// **'Who got out'**
  String get score_board_who_got_out_title;

  /// No description provided for @score_board_start_next_over_title.
  ///
  /// In en, this message translates to:
  /// **'Start Next Over'**
  String get score_board_start_next_over_title;

  /// No description provided for @score_board_batsman_title.
  ///
  /// In en, this message translates to:
  /// **'batsMan'**
  String get score_board_batsman_title;

  /// No description provided for @score_board_bowler_title.
  ///
  /// In en, this message translates to:
  /// **'bowler'**
  String get score_board_bowler_title;

  /// No description provided for @score_board_change_striker_title.
  ///
  /// In en, this message translates to:
  /// **'Change striker'**
  String get score_board_change_striker_title;

  /// No description provided for @score_board_free_hit_text.
  ///
  /// In en, this message translates to:
  /// **'FREE HIT'**
  String get score_board_free_hit_text;

  /// No description provided for @score_board_edit_match_title.
  ///
  /// In en, this message translates to:
  /// **'Edit match details'**
  String get score_board_edit_match_title;

  /// No description provided for @score_board_replace_player_title.
  ///
  /// In en, this message translates to:
  /// **'Replace player'**
  String get score_board_replace_player_title;

  /// No description provided for @score_board_replace_player_description.
  ///
  /// In en, this message translates to:
  /// **'Swap a Playing XI player who hasn\'t batted, bowled or fielded yet'**
  String get score_board_replace_player_description;

  /// No description provided for @score_board_replace_team_title.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get score_board_replace_team_title;

  /// No description provided for @score_board_replace_out_title.
  ///
  /// In en, this message translates to:
  /// **'Player going out'**
  String get score_board_replace_out_title;

  /// No description provided for @score_board_replace_in_title.
  ///
  /// In en, this message translates to:
  /// **'Player coming in'**
  String get score_board_replace_in_title;

  /// No description provided for @score_board_replace_no_player_text.
  ///
  /// In en, this message translates to:
  /// **'No eligible players'**
  String get score_board_replace_no_player_text;

  /// No description provided for @score_board_option_end_match.
  ///
  /// In en, this message translates to:
  /// **'End match'**
  String get score_board_option_end_match;

  /// No description provided for @score_board_option_handover_scoring.
  ///
  /// In en, this message translates to:
  /// **'Handover scoring'**
  String get score_board_option_handover_scoring;

  /// No description provided for @score_board_handover_scoring_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Handover scoring control'**
  String get score_board_handover_scoring_empty_title;

  /// No description provided for @score_board_handover_scoring_empty_description.
  ///
  /// In en, this message translates to:
  /// **'Find and select another user to hand over the scoring responsibilities. Keep the game flowing with a quick and easy transfer.'**
  String get score_board_handover_scoring_empty_description;

  /// No description provided for @score_board_can_undo_till_running_over_title.
  ///
  /// In en, this message translates to:
  /// **'Undo is only allowed till running over'**
  String get score_board_can_undo_till_running_over_title;

  /// No description provided for @score_board_undo_last_ball_title.
  ///
  /// In en, this message translates to:
  /// **'Undo Last Ball'**
  String get score_board_undo_last_ball_title;

  /// No description provided for @score_board_undo_last_ball_description_text.
  ///
  /// In en, this message translates to:
  /// **'are you sure you want to undo last ball?'**
  String get score_board_undo_last_ball_description_text;

  /// No description provided for @score_board_pause_scoring_title.
  ///
  /// In en, this message translates to:
  /// **'Pause scoring'**
  String get score_board_pause_scoring_title;

  /// No description provided for @score_board_add_substitute_title.
  ///
  /// In en, this message translates to:
  /// **'Add substitute'**
  String get score_board_add_substitute_title;

  /// No description provided for @score_board_substitute_title.
  ///
  /// In en, this message translates to:
  /// **'Substitute'**
  String get score_board_substitute_title;

  /// No description provided for @score_board_penalty_run_title.
  ///
  /// In en, this message translates to:
  /// **'Penalty run'**
  String get score_board_penalty_run_title;

  /// No description provided for @score_board_awarded_to_text.
  ///
  /// In en, this message translates to:
  /// **'Awarded to - ?'**
  String get score_board_awarded_to_text;

  /// No description provided for @score_board_continue_with_injured_player_title.
  ///
  /// In en, this message translates to:
  /// **'Continue with injured player'**
  String get score_board_continue_with_injured_player_title;

  /// No description provided for @score_board_show_wheel_for_less_run_title.
  ///
  /// In en, this message translates to:
  /// **'Show wheel for 1s, 2s and 3s'**
  String get score_board_show_wheel_for_less_run_title;

  /// No description provided for @score_board_show_wheel_for_dot_ball_title.
  ///
  /// In en, this message translates to:
  /// **'Show wheel for dot balls'**
  String get score_board_show_wheel_for_dot_ball_title;

  /// No description provided for @score_board_select_fielding_position_title.
  ///
  /// In en, this message translates to:
  /// **'Select fielding position'**
  String get score_board_select_fielding_position_title;

  /// No description provided for @score_board_pause_title.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get score_board_pause_title;

  /// No description provided for @score_board_revised_target_title.
  ///
  /// In en, this message translates to:
  /// **'Revised target'**
  String get score_board_revised_target_title;

  /// No description provided for @score_board_enter_manual_target_text.
  ///
  /// In en, this message translates to:
  /// **'Enter your manually calculated target'**
  String get score_board_enter_manual_target_text;

  /// No description provided for @score_board_runs_text.
  ///
  /// In en, this message translates to:
  /// **'Runs :'**
  String get score_board_runs_text;

  /// No description provided for @score_board_in_overs_text.
  ///
  /// In en, this message translates to:
  /// **'in Overs :'**
  String get score_board_in_overs_text;

  /// No description provided for @score_board_confirm_target_text.
  ///
  /// In en, this message translates to:
  /// **'Confirm target'**
  String get score_board_confirm_target_text;

  /// No description provided for @score_board_current_target_text.
  ///
  /// In en, this message translates to:
  /// **'Current target is {run, plural, =0{{run} runs} =1{{run} run} other{{run} runs}} in {over, plural, =0{{over} overs} =1{{over} over} other{{over} overs}}'**
  String score_board_current_target_text(num run, num over);

  /// No description provided for @score_board_target_invalid_input_error.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid target'**
  String get score_board_target_invalid_input_error;

  /// No description provided for @score_board_pause_scoring_description_text.
  ///
  /// In en, this message translates to:
  /// **'are you sure you want to pause scoring?'**
  String get score_board_pause_scoring_description_text;

  /// No description provided for @score_board_end_match_description_text.
  ///
  /// In en, this message translates to:
  /// **'are you sure you want to end match?'**
  String get score_board_end_match_description_text;

  /// No description provided for @score_board_run_sup_script_text.
  ///
  /// In en, this message translates to:
  /// **'{run, select, 1{{extra}} 2{{extra}²} 3{{extra}³} 4{{extra}⁴} 5{{extra}⁵} 6{{extra}⁶} 7{{extra}⁷} 8{{extra}⁸} 9{{extra}⁹} other{{extra}}}'**
  String score_board_run_sup_script_text(String run, Object extra);

  /// Choose Batsman at position {pos}
  ///
  /// In en, this message translates to:
  /// **'Choose Batsman at position {pos}'**
  String score_board_choose_batsman_title(int pos);

  /// Choose Bowler for over {over}
  ///
  /// In en, this message translates to:
  /// **'Choose Bowler for over {over}'**
  String score_board_choose_bowler_for_over_title(int over);

  /// End Of Over {overNumber} by {player}
  ///
  /// In en, this message translates to:
  /// **'End Of Over {overNumber} by {player}'**
  String score_board_end_of_over_by_title(int overNumber, String player);

  /// No description provided for @score_board_need_run_text.
  ///
  /// In en, this message translates to:
  /// **'Need {count, plural, =0{{count} Runs} =1{{count} Run} other{{count} Runs}}'**
  String score_board_need_run_text(num count);

  /// Need {run} in {ball}
  ///
  /// In en, this message translates to:
  /// **'Need {run} in {ball}'**
  String score_board_run_need_in_ball_text(int run, int ball);

  /// No description provided for @fielding_position_deep_mid_wicket_title.
  ///
  /// In en, this message translates to:
  /// **'Deep mid wicket'**
  String get fielding_position_deep_mid_wicket_title;

  /// No description provided for @fielding_position_long_on_title.
  ///
  /// In en, this message translates to:
  /// **'Long on'**
  String get fielding_position_long_on_title;

  /// No description provided for @fielding_position_long_off_title.
  ///
  /// In en, this message translates to:
  /// **'Long off'**
  String get fielding_position_long_off_title;

  /// No description provided for @fielding_position_deep_cover_title.
  ///
  /// In en, this message translates to:
  /// **'Deep cover'**
  String get fielding_position_deep_cover_title;

  /// No description provided for @fielding_position_deep_point_title.
  ///
  /// In en, this message translates to:
  /// **'Deep point'**
  String get fielding_position_deep_point_title;

  /// No description provided for @fielding_position_third_man_title.
  ///
  /// In en, this message translates to:
  /// **'Third man'**
  String get fielding_position_third_man_title;

  /// No description provided for @fielding_position_deep_fine_leg_title.
  ///
  /// In en, this message translates to:
  /// **'Deep fine leg'**
  String get fielding_position_deep_fine_leg_title;

  /// No description provided for @fielding_position_deep_square_leg_title.
  ///
  /// In en, this message translates to:
  /// **'Deep square leg'**
  String get fielding_position_deep_square_leg_title;

  /// No description provided for @side_off_title.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get side_off_title;

  /// No description provided for @side_leg_title.
  ///
  /// In en, this message translates to:
  /// **'LEG'**
  String get side_leg_title;

  /// No description provided for @tab_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tab_profile_title;

  /// No description provided for @edit_profile_create_profile_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get edit_profile_create_profile_screen_title;

  /// No description provided for @edit_profile_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile_screen_title;

  /// No description provided for @edit_profile_select_birth_date_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get edit_profile_select_birth_date_placeholder;

  /// No description provided for @edit_profile_name_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get edit_profile_name_placeholder;

  /// No description provided for @edit_profile_email_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get edit_profile_email_placeholder;

  /// No description provided for @edit_profile_dob_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get edit_profile_dob_placeholder;

  /// No description provided for @edit_profile_player_role_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Player role'**
  String get edit_profile_player_role_placeholder;

  /// No description provided for @edit_profile_gender_male_title.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get edit_profile_gender_male_title;

  /// No description provided for @edit_profile_gender_female_title.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get edit_profile_gender_female_title;

  /// No description provided for @edit_profile_gender_prefer_not_to_say_title.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get edit_profile_gender_prefer_not_to_say_title;

  /// No description provided for @edit_profile_delete_account_btn_title.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get edit_profile_delete_account_btn_title;

  /// No description provided for @edit_profile_delete_account_description_text.
  ///
  /// In en, this message translates to:
  /// **'This can not undone. if you delete your account, your data will be gone forever.'**
  String get edit_profile_delete_account_description_text;

  /// No description provided for @profile_form_create_heading.
  ///
  /// In en, this message translates to:
  /// **'Create your player profile'**
  String get profile_form_create_heading;

  /// No description provided for @profile_form_create_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Takes less than a minute. Name and mobile number are required.'**
  String get profile_form_create_subtitle;

  /// No description provided for @profile_form_edit_heading.
  ///
  /// In en, this message translates to:
  /// **'Your player profile'**
  String get profile_form_edit_heading;

  /// No description provided for @profile_form_edit_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your details up to date so teams can find you.'**
  String get profile_form_edit_subtitle;

  /// No description provided for @profile_form_photo_add.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get profile_form_photo_add;

  /// No description provided for @profile_form_photo_change.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profile_form_photo_change;

  /// No description provided for @profile_form_photo_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get profile_form_photo_remove;

  /// No description provided for @profile_form_photo_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get profile_form_photo_optional;

  /// No description provided for @profile_form_section_basic.
  ///
  /// In en, this message translates to:
  /// **'Basic details'**
  String get profile_form_section_basic;

  /// No description provided for @profile_form_section_personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get profile_form_section_personal;

  /// No description provided for @profile_form_section_cricket.
  ///
  /// In en, this message translates to:
  /// **'Cricket profile'**
  String get profile_form_section_cricket;

  /// No description provided for @profile_form_name_label.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profile_form_name_label;

  /// No description provided for @profile_form_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Arun Kumar'**
  String get profile_form_name_hint;

  /// No description provided for @profile_form_phone_label.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get profile_form_phone_label;

  /// No description provided for @profile_form_phone_private.
  ///
  /// In en, this message translates to:
  /// **'Only you can see your number'**
  String get profile_form_phone_private;

  /// No description provided for @profile_form_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profile_form_email_label;

  /// No description provided for @profile_form_email_hint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get profile_form_email_hint;

  /// No description provided for @profile_form_location_label.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profile_form_location_label;

  /// No description provided for @profile_form_location_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chennai'**
  String get profile_form_location_hint;

  /// No description provided for @profile_form_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get profile_form_optional;

  /// No description provided for @profile_form_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get profile_form_required;

  /// No description provided for @profile_form_dob_label.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profile_form_dob_label;

  /// No description provided for @profile_form_dob_add.
  ///
  /// In en, this message translates to:
  /// **'Add date'**
  String get profile_form_dob_add;

  /// No description provided for @profile_form_gender_label.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profile_form_gender_label;

  /// No description provided for @profile_form_role_label.
  ///
  /// In en, this message translates to:
  /// **'Playing role'**
  String get profile_form_role_label;

  /// No description provided for @profile_form_batting_label.
  ///
  /// In en, this message translates to:
  /// **'Batting'**
  String get profile_form_batting_label;

  /// No description provided for @profile_form_bowling_label.
  ///
  /// In en, this message translates to:
  /// **'Bowling'**
  String get profile_form_bowling_label;

  /// No description provided for @profile_form_choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get profile_form_choose;

  /// No description provided for @profile_form_error_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your name (at least 2 letters)'**
  String get profile_form_error_name;

  /// No description provided for @profile_form_error_phone_empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get profile_form_error_phone_empty;

  /// No description provided for @profile_form_error_phone_invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid {country} mobile number'**
  String profile_form_error_phone_invalid(String country);

  /// No description provided for @profile_form_error_email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email or leave it empty'**
  String get profile_form_error_email;

  /// No description provided for @profile_form_error_photo.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t use that photo. Try another one.'**
  String get profile_form_error_photo;

  /// No description provided for @profile_form_create_btn.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get profile_form_create_btn;

  /// No description provided for @profile_form_save_btn.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profile_form_save_btn;

  /// No description provided for @profile_form_sign_out.
  ///
  /// In en, this message translates to:
  /// **'Not you? Sign out'**
  String get profile_form_sign_out;

  /// No description provided for @profile_form_country_title.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get profile_form_country_title;

  /// No description provided for @profile_form_progress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String profile_form_progress(int done, int total);

  /// No description provided for @transfer_teams_title.
  ///
  /// In en, this message translates to:
  /// **'Before You Go...'**
  String get transfer_teams_title;

  /// No description provided for @transfer_teams_description.
  ///
  /// In en, this message translates to:
  /// **'We\'re sorry to see you go. Before deleting your account, please:\n• Assign new owners and admins for your teams or delete the teams\n• Transfer scoring for ongoing matches\n• Remove any scheduled matches\n•Transfer or assign responsibilities for ongoing tournaments\nThis will ensure everything is properly managed after you leave.'**
  String get transfer_teams_description;

  /// No description provided for @transfer_teams_go_to_my_cricket.
  ///
  /// In en, this message translates to:
  /// **'Go to My Cricket'**
  String get transfer_teams_go_to_my_cricket;

  /// No description provided for @profile_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profile_settings_title;

  /// No description provided for @profile_setting_contact_support.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get profile_setting_contact_support;

  /// No description provided for @profile_setting_privacy_policy_title.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get profile_setting_privacy_policy_title;

  /// No description provided for @profile_setting_terms_and_condition_title.
  ///
  /// In en, this message translates to:
  /// **'Terms and condition'**
  String get profile_setting_terms_and_condition_title;

  /// No description provided for @profile_setting_share_app_title.
  ///
  /// In en, this message translates to:
  /// **'Share app'**
  String get profile_setting_share_app_title;

  /// No description provided for @profile_setting_rate_us_title.
  ///
  /// In en, this message translates to:
  /// **'Rate us'**
  String get profile_setting_rate_us_title;

  /// No description provided for @profile_setting_app_version_text.
  ///
  /// In en, this message translates to:
  /// **'App Version: {version}'**
  String profile_setting_app_version_text(Object version);

  /// No description provided for @profile_setting_scan_to_play_text.
  ///
  /// In en, this message translates to:
  /// **'Scan to play!'**
  String get profile_setting_scan_to_play_text;

  /// No description provided for @profile_setting_scan_to_play_description.
  ///
  /// In en, this message translates to:
  /// **'This QR code allows you to easily add the player to the team.'**
  String get profile_setting_scan_to_play_description;

  /// No description provided for @profile_setting_use_scanner_description.
  ///
  /// In en, this message translates to:
  /// **'Use your phone camera or a QR code app to scan the code above and easily add the player to the team.'**
  String get profile_setting_use_scanner_description;

  /// No description provided for @profile_setting_share_app_message.
  ///
  /// In en, this message translates to:
  /// **'Elevate your cricket scoring game with Sports Tamil! 🏏\n\nEffortlessly score matches, track stats, and manage your teams.\n\n👉 Download Now:\n📱 Android: {androidLink}\n🍎 iOS: {iosLink}\n\nStart scoring smarter today!'**
  String profile_setting_share_app_message(String androidLink, String iosLink);

  /// No description provided for @notification_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notification_title;

  /// No description provided for @notification_turn_on_title.
  ///
  /// In en, this message translates to:
  /// **'It seems that your notifications have been turned off. Turn on notifications to stay updated on your teams and matches.'**
  String get notification_turn_on_title;

  /// No description provided for @notification_turn_on_btn_title.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get notification_turn_on_btn_title;

  /// No description provided for @contact_support_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contact_support_screen_title;

  /// No description provided for @contact_support_title_placeholder_text.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get contact_support_title_placeholder_text;

  /// No description provided for @contact_support_description_placeholder_text.
  ///
  /// In en, this message translates to:
  /// **'Description...'**
  String get contact_support_description_placeholder_text;

  /// No description provided for @contact_support_attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment (if any)'**
  String get contact_support_attachment;

  /// No description provided for @large_attachment_upload_error_text.
  ///
  /// In en, this message translates to:
  /// **'Oops! Your file exceeds the maximum allowed size of 25 MB. Please choose a smaller file and try again.'**
  String get large_attachment_upload_error_text;

  /// No description provided for @profile_complete_your_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profile_complete_your_profile_title;

  /// No description provided for @profile_complete_description_title.
  ///
  /// In en, this message translates to:
  /// **'Enhance your profile with more details to make it better!'**
  String get profile_complete_description_title;

  /// No description provided for @profile_section_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get profile_section_activity;

  /// No description provided for @profile_section_preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profile_section_preferences;

  /// No description provided for @profile_section_support.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get profile_section_support;

  /// No description provided for @profile_section_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profile_section_about;

  /// No description provided for @profile_edit_button.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profile_edit_button;

  /// No description provided for @profile_complete_percent.
  ///
  /// In en, this message translates to:
  /// **'Profile {percent}% complete'**
  String profile_complete_percent(int percent);

  /// No description provided for @profile_complete_finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get profile_complete_finish;

  /// No description provided for @profile_qr_title.
  ///
  /// In en, this message translates to:
  /// **'My player QR'**
  String get profile_qr_title;

  /// No description provided for @profile_qr_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Teammates scan it to add you'**
  String get profile_qr_subtitle;

  /// No description provided for @profile_stats_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Runs, wickets and match history'**
  String get profile_stats_subtitle;

  /// No description provided for @profile_notifications_off_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get profile_notifications_off_title;

  /// No description provided for @profile_notifications_off_body.
  ///
  /// In en, this message translates to:
  /// **'Turn them on to hear about your teams and matches.'**
  String get profile_notifications_off_body;

  /// No description provided for @profile_mascot_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tips and cheers from the tiger'**
  String get profile_mascot_subtitle;

  /// No description provided for @profile_section_player_links.
  ///
  /// In en, this message translates to:
  /// **'Player links'**
  String get profile_section_player_links;

  /// No description provided for @player_claim_title.
  ///
  /// In en, this message translates to:
  /// **'Is this you?'**
  String get player_claim_title;

  /// No description provided for @player_claim_body.
  ///
  /// In en, this message translates to:
  /// **'An organizer added {name} with your mobile number, in {teams} teams and {matches} matches. Link this player to your account to get those matches and stats.'**
  String player_claim_body(String name, int teams, int matches);

  /// No description provided for @player_claim_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes, that\'s me'**
  String get player_claim_yes;

  /// No description provided for @player_claim_no.
  ///
  /// In en, this message translates to:
  /// **'Not me'**
  String get player_claim_no;

  /// No description provided for @player_claim_sent.
  ///
  /// In en, this message translates to:
  /// **'Request sent. The organizer will confirm it.'**
  String get player_claim_sent;

  /// No description provided for @player_claim_request_row.
  ///
  /// In en, this message translates to:
  /// **'{claimant} says they are {player}'**
  String player_claim_request_row(String claimant, String player);

  /// No description provided for @player_claim_request_hint.
  ///
  /// In en, this message translates to:
  /// **'Approving moves this player\'s teams, matches and stats to their account.'**
  String get player_claim_request_hint;

  /// No description provided for @player_claim_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get player_claim_approve;

  /// No description provided for @player_claim_decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get player_claim_decline;

  /// No description provided for @player_claim_approved_toast.
  ///
  /// In en, this message translates to:
  /// **'Linked. {player}\'s matches and stats now belong to {claimant}.'**
  String player_claim_approved_toast(String player, String claimant);

  /// No description provided for @player_claim_waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the organizer to confirm {player}'**
  String player_claim_waiting(String player);

  /// No description provided for @player_claim_declined.
  ///
  /// In en, this message translates to:
  /// **'The organizer didn\'t confirm {player}'**
  String player_claim_declined(String player);

  /// No description provided for @profile_complete_add_profile_picture.
  ///
  /// In en, this message translates to:
  /// **'Add profile picture'**
  String get profile_complete_add_profile_picture;

  /// No description provided for @profile_complete_add_personal_details.
  ///
  /// In en, this message translates to:
  /// **'Add personal details'**
  String get profile_complete_add_personal_details;

  /// No description provided for @profile_complete_add_playing_style.
  ///
  /// In en, this message translates to:
  /// **'Add playing style'**
  String get profile_complete_add_playing_style;

  /// No description provided for @image_picker_choose_option_title.
  ///
  /// In en, this message translates to:
  /// **'Choose an option'**
  String get image_picker_choose_option_title;

  /// No description provided for @image_picker_camera_option_text.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get image_picker_camera_option_text;

  /// No description provided for @image_picker_gallery_option_text.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get image_picker_gallery_option_text;

  /// No description provided for @image_picker_crop_image_title.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get image_picker_crop_image_title;

  /// No description provided for @batting_style_right_hand_bat_title.
  ///
  /// In en, this message translates to:
  /// **'Right hand bat'**
  String get batting_style_right_hand_bat_title;

  /// No description provided for @batting_style_left_hand_bat_title.
  ///
  /// In en, this message translates to:
  /// **'Left hand bat'**
  String get batting_style_left_hand_bat_title;

  /// No description provided for @bowling_style_right_arm_fast_title.
  ///
  /// In en, this message translates to:
  /// **'Right arm fast'**
  String get bowling_style_right_arm_fast_title;

  /// No description provided for @bowling_style_right_arm_medium_title.
  ///
  /// In en, this message translates to:
  /// **'Right arm medium'**
  String get bowling_style_right_arm_medium_title;

  /// No description provided for @bowling_style_left_arm_fast_title.
  ///
  /// In en, this message translates to:
  /// **'Left arm fast'**
  String get bowling_style_left_arm_fast_title;

  /// No description provided for @bowling_style_left_arm_medium_title.
  ///
  /// In en, this message translates to:
  /// **'Left arm medium'**
  String get bowling_style_left_arm_medium_title;

  /// No description provided for @bowling_style_slow_left_arm_orthodox_title.
  ///
  /// In en, this message translates to:
  /// **'Slow left arm orthodox'**
  String get bowling_style_slow_left_arm_orthodox_title;

  /// No description provided for @bowling_style_slow_left_arm_chinaman_title.
  ///
  /// In en, this message translates to:
  /// **'Slow left arm chinaman'**
  String get bowling_style_slow_left_arm_chinaman_title;

  /// No description provided for @bowling_style_right_arm_off_break_title.
  ///
  /// In en, this message translates to:
  /// **'Right arm off break'**
  String get bowling_style_right_arm_off_break_title;

  /// No description provided for @bowling_style_right_arm_leg_break_title.
  ///
  /// In en, this message translates to:
  /// **'Right arm leg break'**
  String get bowling_style_right_arm_leg_break_title;

  /// No description provided for @player_role_top_order_batter_title.
  ///
  /// In en, this message translates to:
  /// **'Top order batter'**
  String get player_role_top_order_batter_title;

  /// No description provided for @player_role_middle_order_batter_title.
  ///
  /// In en, this message translates to:
  /// **'Middle order batter'**
  String get player_role_middle_order_batter_title;

  /// No description provided for @player_role_wicket_keeper_batter_title.
  ///
  /// In en, this message translates to:
  /// **'Wicket keeper batter'**
  String get player_role_wicket_keeper_batter_title;

  /// No description provided for @player_role_wicket_keeper_title.
  ///
  /// In en, this message translates to:
  /// **'Wicket keeper'**
  String get player_role_wicket_keeper_title;

  /// No description provided for @player_role_bowler_title.
  ///
  /// In en, this message translates to:
  /// **'Bowler'**
  String get player_role_bowler_title;

  /// No description provided for @player_role_all_rounder_title.
  ///
  /// In en, this message translates to:
  /// **'All rounder'**
  String get player_role_all_rounder_title;

  /// No description provided for @player_role_lower_order_batter_title.
  ///
  /// In en, this message translates to:
  /// **'Lower order batter'**
  String get player_role_lower_order_batter_title;

  /// No description provided for @player_role_opening_batter_title.
  ///
  /// In en, this message translates to:
  /// **'Opening batter'**
  String get player_role_opening_batter_title;

  /// No description provided for @tournament_teams_title.
  ///
  /// In en, this message translates to:
  /// **'Tournament Teams'**
  String get tournament_teams_title;

  /// No description provided for @tournament_teams_entry_description.
  ///
  /// In en, this message translates to:
  /// **'Pools of teams for each series, like GCPL or PSPL'**
  String get tournament_teams_entry_description;

  /// No description provided for @tournament_teams_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search teams'**
  String get tournament_teams_search_hint;

  /// No description provided for @tournament_teams_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No teams yet'**
  String get tournament_teams_empty_title;

  /// No description provided for @tournament_teams_empty_description.
  ///
  /// In en, this message translates to:
  /// **'Add your first team and its players once, then pick it in any tournament.'**
  String get tournament_teams_empty_description;

  /// No description provided for @tournament_teams_add_first_team.
  ///
  /// In en, this message translates to:
  /// **'Add your first team'**
  String get tournament_teams_add_first_team;

  /// No description provided for @tournament_teams_add_team.
  ///
  /// In en, this message translates to:
  /// **'Add team'**
  String get tournament_teams_add_team;

  /// No description provided for @tournament_teams_edit_team.
  ///
  /// In en, this message translates to:
  /// **'Edit team'**
  String get tournament_teams_edit_team;

  /// No description provided for @tournament_teams_no_search_result.
  ///
  /// In en, this message translates to:
  /// **'No teams match “{query}”'**
  String tournament_teams_no_search_result(Object query);

  /// No description provided for @tournament_teams_player_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No players} =1{1 player} other{{count} players}}'**
  String tournament_teams_player_count(int count);

  /// No description provided for @tournament_teams_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete team?'**
  String get tournament_teams_delete_title;

  /// No description provided for @tournament_teams_delete_description.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from your Tournament Teams.'**
  String tournament_teams_delete_description(Object name);

  /// No description provided for @tournament_teams_in_use_title.
  ///
  /// In en, this message translates to:
  /// **'Team in use'**
  String get tournament_teams_in_use_title;

  /// No description provided for @tournament_teams_in_use_description.
  ///
  /// In en, this message translates to:
  /// **'{name} is part of {count, plural, =1{1 tournament} other{{count} tournaments}}. Remove it from those tournaments before deleting it.'**
  String tournament_teams_in_use_description(Object name, int count);

  /// No description provided for @tournament_team_name_label.
  ///
  /// In en, this message translates to:
  /// **'Team name *'**
  String get tournament_team_name_label;

  /// No description provided for @tournament_team_short_name_label.
  ///
  /// In en, this message translates to:
  /// **'Short name / code'**
  String get tournament_team_short_name_label;

  /// No description provided for @tournament_team_captain_label.
  ///
  /// In en, this message translates to:
  /// **'Captain'**
  String get tournament_team_captain_label;

  /// No description provided for @tournament_team_captain_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Select captain (optional)'**
  String get tournament_team_captain_placeholder;

  /// No description provided for @tournament_team_wicket_keeper_label.
  ///
  /// In en, this message translates to:
  /// **'Wicket-keeper'**
  String get tournament_team_wicket_keeper_label;

  /// No description provided for @tournament_team_add_players.
  ///
  /// In en, this message translates to:
  /// **'Add players'**
  String get tournament_team_add_players;

  /// No description provided for @tournament_team_players_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No players yet'**
  String get tournament_team_players_empty_title;

  /// No description provided for @tournament_team_players_empty_description.
  ///
  /// In en, this message translates to:
  /// **'Add players so this team is ready for matches.'**
  String get tournament_team_players_empty_description;

  /// No description provided for @tournament_team_add_player.
  ///
  /// In en, this message translates to:
  /// **'Add player'**
  String get tournament_team_add_player;

  /// No description provided for @tournament_team_edit_player.
  ///
  /// In en, this message translates to:
  /// **'Edit player'**
  String get tournament_team_edit_player;

  /// No description provided for @tournament_team_player_name_label.
  ///
  /// In en, this message translates to:
  /// **'Player name *'**
  String get tournament_team_player_name_label;

  /// No description provided for @tournament_team_player_role_label.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get tournament_team_player_role_label;

  /// No description provided for @tournament_team_jersey_label.
  ///
  /// In en, this message translates to:
  /// **'Jersey number'**
  String get tournament_team_jersey_label;

  /// No description provided for @tournament_team_make_captain.
  ///
  /// In en, this message translates to:
  /// **'Make captain'**
  String get tournament_team_make_captain;

  /// No description provided for @tournament_team_remove_captain.
  ///
  /// In en, this message translates to:
  /// **'Remove as captain'**
  String get tournament_team_remove_captain;

  /// No description provided for @tournament_team_make_wicket_keeper.
  ///
  /// In en, this message translates to:
  /// **'Make wicket-keeper'**
  String get tournament_team_make_wicket_keeper;

  /// No description provided for @tournament_team_remove_wicket_keeper.
  ///
  /// In en, this message translates to:
  /// **'Remove as wicket-keeper'**
  String get tournament_team_remove_wicket_keeper;

  /// No description provided for @tournament_team_remove_player_title.
  ///
  /// In en, this message translates to:
  /// **'Remove player?'**
  String get tournament_team_remove_player_title;

  /// No description provided for @tournament_team_remove_player_description.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from this team.'**
  String tournament_team_remove_player_description(Object name);

  /// No description provided for @tournament_team_captain_short.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get tournament_team_captain_short;

  /// No description provided for @tournament_team_wicket_keeper_short.
  ///
  /// In en, this message translates to:
  /// **'WK'**
  String get tournament_team_wicket_keeper_short;

  /// No description provided for @tournament_player_role_batsman.
  ///
  /// In en, this message translates to:
  /// **'Batsman'**
  String get tournament_player_role_batsman;

  /// No description provided for @tournament_player_role_bowler.
  ///
  /// In en, this message translates to:
  /// **'Bowler'**
  String get tournament_player_role_bowler;

  /// No description provided for @tournament_player_role_all_rounder.
  ///
  /// In en, this message translates to:
  /// **'All-rounder'**
  String get tournament_player_role_all_rounder;

  /// No description provided for @tournament_player_role_wicket_keeper.
  ///
  /// In en, this message translates to:
  /// **'Wicket-keeper'**
  String get tournament_player_role_wicket_keeper;

  /// No description provided for @tournament_team_picker_title.
  ///
  /// In en, this message translates to:
  /// **'Select teams'**
  String get tournament_team_picker_title;

  /// No description provided for @tournament_team_picker_select_all.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get tournament_team_picker_select_all;

  /// No description provided for @tournament_team_picker_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get tournament_team_picker_clear;

  /// No description provided for @tournament_team_picker_add_new.
  ///
  /// In en, this message translates to:
  /// **'+ Add new team'**
  String get tournament_team_picker_add_new;

  /// No description provided for @tournament_team_picker_min_teams.
  ///
  /// In en, this message translates to:
  /// **'Select at least 2 teams to continue'**
  String get tournament_team_picker_min_teams;

  /// No description provided for @tournament_team_picker_done.
  ///
  /// In en, this message translates to:
  /// **'Continue with {count, plural, =1{1 team} other{{count} teams}}'**
  String tournament_team_picker_done(int count);

  /// No description provided for @tournament_team_picker_selected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String tournament_team_picker_selected(int count);

  /// No description provided for @tournament_team_picker_not_in_pool.
  ///
  /// In en, this message translates to:
  /// **'Not in Tournament Teams'**
  String get tournament_team_picker_not_in_pool;

  /// No description provided for @tournament_team_picker_choose_pool.
  ///
  /// In en, this message translates to:
  /// **'Choose a pool to see its teams'**
  String get tournament_team_picker_choose_pool;

  /// No description provided for @tournament_team_picker_switch_pool_title.
  ///
  /// In en, this message translates to:
  /// **'Clear current selection?'**
  String get tournament_team_picker_switch_pool_title;

  /// No description provided for @tournament_team_picker_switch_pool_description.
  ///
  /// In en, this message translates to:
  /// **'Switching to {name} clears {count, plural, =1{1 selected team} other{{count} selected teams}}.'**
  String tournament_team_picker_switch_pool_description(String name, int count);

  /// No description provided for @tournament_team_picker_switch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get tournament_team_picker_switch;

  /// No description provided for @team_pools_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search pools'**
  String get team_pools_search_hint;

  /// No description provided for @team_pools_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No pools yet'**
  String get team_pools_empty_title;

  /// No description provided for @team_pools_empty_description.
  ///
  /// In en, this message translates to:
  /// **'Create a pool for each tournament series, like “GCPL Teams”, then add its teams and players.'**
  String get team_pools_empty_description;

  /// No description provided for @team_pools_create_first.
  ///
  /// In en, this message translates to:
  /// **'Create your first pool'**
  String get team_pools_create_first;

  /// No description provided for @team_pools_new_pool.
  ///
  /// In en, this message translates to:
  /// **'New pool'**
  String get team_pools_new_pool;

  /// No description provided for @team_pools_add_new.
  ///
  /// In en, this message translates to:
  /// **'+ New pool'**
  String get team_pools_add_new;

  /// No description provided for @team_pools_edit_pool.
  ///
  /// In en, this message translates to:
  /// **'Edit pool'**
  String get team_pools_edit_pool;

  /// No description provided for @team_pools_name_label.
  ///
  /// In en, this message translates to:
  /// **'Pool name *'**
  String get team_pools_name_label;

  /// No description provided for @team_pools_short_name_label.
  ///
  /// In en, this message translates to:
  /// **'Short code'**
  String get team_pools_short_name_label;

  /// No description provided for @team_pools_team_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No teams} =1{1 team} other{{count} teams}}'**
  String team_pools_team_count(int count);

  /// No description provided for @team_pools_no_search_result.
  ///
  /// In en, this message translates to:
  /// **'No pools match “{query}”'**
  String team_pools_no_search_result(String query);

  /// No description provided for @team_pools_ungrouped.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped teams'**
  String get team_pools_ungrouped;

  /// No description provided for @team_pools_ungrouped_description.
  ///
  /// In en, this message translates to:
  /// **'Teams created before pools. Move them into a pool.'**
  String get team_pools_ungrouped_description;

  /// No description provided for @team_pools_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete pool?'**
  String get team_pools_delete_title;

  /// No description provided for @team_pools_delete_description.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and its {count, plural, =0{teams} =1{1 team} other{{count} teams}}? Players are kept.'**
  String team_pools_delete_description(String name, int count);

  /// No description provided for @team_pools_in_use_title.
  ///
  /// In en, this message translates to:
  /// **'Pool in use'**
  String get team_pools_in_use_title;

  /// No description provided for @team_pools_in_use_description.
  ///
  /// In en, this message translates to:
  /// **'{name} has teams in {count, plural, =1{1 tournament} other{{count} tournaments}}. Remove them from those tournaments before deleting the pool.'**
  String team_pools_in_use_description(String name, int count);

  /// No description provided for @team_pools_move_to_pool.
  ///
  /// In en, this message translates to:
  /// **'Move to pool…'**
  String get team_pools_move_to_pool;

  /// No description provided for @team_pools_team_actions.
  ///
  /// In en, this message translates to:
  /// **'Team actions'**
  String get team_pools_team_actions;

  /// No description provided for @team_pools_no_other_pools.
  ///
  /// In en, this message translates to:
  /// **'Create another pool first.'**
  String get team_pools_no_other_pools;

  /// No description provided for @team_pool_teams_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No teams in this pool'**
  String get team_pool_teams_empty_title;

  /// No description provided for @team_pool_teams_empty_description.
  ///
  /// In en, this message translates to:
  /// **'Add the teams and players for this series.'**
  String get team_pool_teams_empty_description;

  /// No description provided for @error_duplicate_team_name.
  ///
  /// In en, this message translates to:
  /// **'A team with this name already exists in this pool.'**
  String get error_duplicate_team_name;

  /// No description provided for @error_duplicate_player_name.
  ///
  /// In en, this message translates to:
  /// **'This player is already in the team.'**
  String get error_duplicate_player_name;

  /// No description provided for @error_duplicate_jersey_number.
  ///
  /// In en, this message translates to:
  /// **'This jersey number is already taken in this team.'**
  String get error_duplicate_jersey_number;

  /// No description provided for @error_team_used_in_tournament.
  ///
  /// In en, this message translates to:
  /// **'This team is used in a tournament and can\'t be deleted.'**
  String get error_team_used_in_tournament;

  /// No description provided for @error_duplicate_pool_name.
  ///
  /// In en, this message translates to:
  /// **'A pool with this name already exists.'**
  String get error_duplicate_pool_name;

  /// No description provided for @error_pool_used_in_tournament.
  ///
  /// In en, this message translates to:
  /// **'This pool has teams used in a tournament and can\'t be deleted.'**
  String get error_pool_used_in_tournament;

  /// No description provided for @tab_play_title.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get tab_play_title;

  /// No description provided for @play_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Play Cricket'**
  String get play_screen_title;

  /// No description provided for @play_guest_title.
  ///
  /// In en, this message translates to:
  /// **'Playing as Guest'**
  String get play_guest_title;

  /// No description provided for @play_guest_description.
  ///
  /// In en, this message translates to:
  /// **'Your scores show as \"Guest\". Sign in to use your name and challenge friends.'**
  String get play_guest_description;

  /// No description provided for @play_guest_challenge_hint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to challenge'**
  String get play_guest_challenge_hint;

  /// No description provided for @play_daily_title.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get play_daily_title;

  /// No description provided for @play_daily_target.
  ///
  /// In en, this message translates to:
  /// **'Chase {target} in 2 overs'**
  String play_daily_target(int target);

  /// No description provided for @play_daily_best.
  ///
  /// In en, this message translates to:
  /// **'Your best today: {score}'**
  String play_daily_best(String score);

  /// No description provided for @play_daily_not_played.
  ///
  /// In en, this message translates to:
  /// **'Same balls for everyone today. Can you chase it?'**
  String get play_daily_not_played;

  /// No description provided for @play_daily_players.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Be the first to play today} =1{1 player today} other{{count} players today}}'**
  String play_daily_players(int count);

  /// No description provided for @play_quick_play.
  ///
  /// In en, this message translates to:
  /// **'Quick Play'**
  String get play_quick_play;

  /// No description provided for @play_quick_play_hint.
  ///
  /// In en, this message translates to:
  /// **'2 overs · 3 wickets'**
  String get play_quick_play_hint;

  /// No description provided for @play_challenge_friend.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get play_challenge_friend;

  /// No description provided for @play_challenge_friend_hint.
  ///
  /// In en, this message translates to:
  /// **'Beat a friend\'s score'**
  String get play_challenge_friend_hint;

  /// No description provided for @play_how_to.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere as the ball reaches the bat. Perfect timing hits a six; miss a ball on the stumps and you\'re bowled.'**
  String get play_how_to;

  /// No description provided for @play_challenges_title.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get play_challenges_title;

  /// No description provided for @play_challenge_incoming.
  ///
  /// In en, this message translates to:
  /// **'{name} challenged you · beat {runs}'**
  String play_challenge_incoming(String name, int runs);

  /// No description provided for @play_challenge_waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} · you scored {score}'**
  String play_challenge_waiting(String name, String score);

  /// No description provided for @play_challenge_result.
  ///
  /// In en, this message translates to:
  /// **'{me} vs {other} · {name}'**
  String play_challenge_result(String me, String other, String name);

  /// No description provided for @play_challenge_play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play_challenge_play;

  /// No description provided for @play_result_won.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get play_result_won;

  /// No description provided for @play_result_lost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get play_result_lost;

  /// No description provided for @play_result_tie.
  ///
  /// In en, this message translates to:
  /// **'Tie'**
  String get play_result_tie;

  /// No description provided for @play_leaderboard_title.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get play_leaderboard_title;

  /// No description provided for @play_leaderboard_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get play_leaderboard_today;

  /// No description provided for @play_leaderboard_week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get play_leaderboard_week;

  /// No description provided for @play_leaderboard_empty.
  ///
  /// In en, this message translates to:
  /// **'No scores yet. Play a game to get on the board!'**
  String get play_leaderboard_empty;

  /// No description provided for @play_recent_title.
  ///
  /// In en, this message translates to:
  /// **'Recent Games'**
  String get play_recent_title;

  /// No description provided for @play_recent_empty.
  ///
  /// In en, this message translates to:
  /// **'Your games will show up here.'**
  String get play_recent_empty;

  /// No description provided for @play_mode_solo.
  ///
  /// In en, this message translates to:
  /// **'Quick Play'**
  String get play_mode_solo;

  /// No description provided for @play_mode_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get play_mode_daily;

  /// No description provided for @play_mode_challenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get play_mode_challenge;

  /// No description provided for @play_balls.
  ///
  /// In en, this message translates to:
  /// **'{count} balls'**
  String play_balls(int count);

  /// No description provided for @play_select_opponent_title.
  ///
  /// In en, this message translates to:
  /// **'Challenge a friend'**
  String get play_select_opponent_title;

  /// No description provided for @play_select_opponent_hint.
  ///
  /// In en, this message translates to:
  /// **'Search players by name'**
  String get play_select_opponent_hint;

  /// No description provided for @play_select_opponent_empty.
  ///
  /// In en, this message translates to:
  /// **'No players found'**
  String get play_select_opponent_empty;

  /// No description provided for @play_game_tap_to_start.
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get play_game_tap_to_start;

  /// No description provided for @play_game_balls_left.
  ///
  /// In en, this message translates to:
  /// **'{count} balls left'**
  String play_game_balls_left(int count);

  /// No description provided for @play_game_need.
  ///
  /// In en, this message translates to:
  /// **'Need {runs} off {balls}'**
  String play_game_need(int runs, int balls);

  /// No description provided for @play_game_vs.
  ///
  /// In en, this message translates to:
  /// **'vs {name}'**
  String play_game_vs(String name);

  /// No description provided for @play_shot_six.
  ///
  /// In en, this message translates to:
  /// **'SIX!'**
  String get play_shot_six;

  /// No description provided for @play_shot_four.
  ///
  /// In en, this message translates to:
  /// **'FOUR!'**
  String get play_shot_four;

  /// No description provided for @play_shot_two.
  ///
  /// In en, this message translates to:
  /// **'2 runs'**
  String get play_shot_two;

  /// No description provided for @play_shot_single.
  ///
  /// In en, this message translates to:
  /// **'1 run'**
  String get play_shot_single;

  /// No description provided for @play_shot_dot.
  ///
  /// In en, this message translates to:
  /// **'Dot ball'**
  String get play_shot_dot;

  /// No description provided for @play_shot_out.
  ///
  /// In en, this message translates to:
  /// **'OUT!'**
  String get play_shot_out;

  /// No description provided for @play_timing_perfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect timing'**
  String get play_timing_perfect;

  /// No description provided for @play_timing_early.
  ///
  /// In en, this message translates to:
  /// **'Early'**
  String get play_timing_early;

  /// No description provided for @play_timing_late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get play_timing_late;

  /// No description provided for @play_timing_left.
  ///
  /// In en, this message translates to:
  /// **'Left alone'**
  String get play_timing_left;

  /// No description provided for @play_end_title.
  ///
  /// In en, this message translates to:
  /// **'Innings over'**
  String get play_end_title;

  /// No description provided for @play_end_score.
  ///
  /// In en, this message translates to:
  /// **'{runs}/{wickets} in {balls} balls'**
  String play_end_score(int runs, int wickets, int balls);

  /// No description provided for @play_end_target_won.
  ///
  /// In en, this message translates to:
  /// **'Target chased!'**
  String get play_end_target_won;

  /// No description provided for @play_end_target_lost.
  ///
  /// In en, this message translates to:
  /// **'Fell short of {target}'**
  String play_end_target_lost(int target);

  /// No description provided for @play_end_challenge_sent.
  ///
  /// In en, this message translates to:
  /// **'Challenge sent to {name}'**
  String play_end_challenge_sent(String name);

  /// No description provided for @play_end_challenge_won.
  ///
  /// In en, this message translates to:
  /// **'You beat {name}!'**
  String play_end_challenge_won(String name);

  /// No description provided for @play_end_challenge_lost.
  ///
  /// In en, this message translates to:
  /// **'{name} wins this one'**
  String play_end_challenge_lost(String name);

  /// No description provided for @play_end_challenge_tie.
  ///
  /// In en, this message translates to:
  /// **'It\'s a tie with {name}'**
  String play_end_challenge_tie(String name);

  /// No description provided for @play_end_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get play_end_saving;

  /// No description provided for @play_again.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get play_again;

  /// No description provided for @play_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get play_done;

  /// No description provided for @play_retry_save.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get play_retry_save;

  /// No description provided for @play_comm_six_0.
  ///
  /// In en, this message translates to:
  /// **'{name} launches it over long-on. That\'s huge!'**
  String play_comm_six_0(String name);

  /// No description provided for @play_comm_six_1.
  ///
  /// In en, this message translates to:
  /// **'Into the crowd! A monster hit from {name}.'**
  String play_comm_six_1(String name);

  /// No description provided for @play_comm_six_2.
  ///
  /// In en, this message translates to:
  /// **'Clean strike from {name}, and that\'s out of the ground!'**
  String play_comm_six_2(String name);

  /// No description provided for @play_comm_four_0.
  ///
  /// In en, this message translates to:
  /// **'{name} finds the gap and it races away to the rope.'**
  String play_comm_four_0(String name);

  /// No description provided for @play_comm_four_1.
  ///
  /// In en, this message translates to:
  /// **'Beautifully timed by {name}. Four runs.'**
  String play_comm_four_1(String name);

  /// No description provided for @play_comm_four_2.
  ///
  /// In en, this message translates to:
  /// **'Through the covers by {name}. Nobody\'s stopping that.'**
  String play_comm_four_2(String name);

  /// No description provided for @play_comm_two_0.
  ///
  /// In en, this message translates to:
  /// **'{name} pushes it into the gap and comes back for two.'**
  String play_comm_two_0(String name);

  /// No description provided for @play_comm_two_1.
  ///
  /// In en, this message translates to:
  /// **'Good running from {name}. Two more.'**
  String play_comm_two_1(String name);

  /// No description provided for @play_comm_two_2.
  ///
  /// In en, this message translates to:
  /// **'Worked away by {name} for a couple.'**
  String play_comm_two_2(String name);

  /// No description provided for @play_comm_single_0.
  ///
  /// In en, this message translates to:
  /// **'{name} nudges it for a quick single.'**
  String play_comm_single_0(String name);

  /// No description provided for @play_comm_single_1.
  ///
  /// In en, this message translates to:
  /// **'Just a single. {name} keeps the board moving.'**
  String play_comm_single_1(String name);

  /// No description provided for @play_comm_single_2.
  ///
  /// In en, this message translates to:
  /// **'Soft hands from {name}. One run.'**
  String play_comm_single_2(String name);

  /// No description provided for @play_comm_dot_0.
  ///
  /// In en, this message translates to:
  /// **'Dot ball. Tight from the bowler.'**
  String get play_comm_dot_0;

  /// No description provided for @play_comm_dot_1.
  ///
  /// In en, this message translates to:
  /// **'{name} can\'t get that one away.'**
  String play_comm_dot_1(String name);

  /// No description provided for @play_comm_dot_2.
  ///
  /// In en, this message translates to:
  /// **'Beaten! That one went past the edge.'**
  String get play_comm_dot_2;

  /// No description provided for @play_comm_out_0.
  ///
  /// In en, this message translates to:
  /// **'Bowled! The stumps are everywhere.'**
  String get play_comm_out_0;

  /// No description provided for @play_comm_out_1.
  ///
  /// In en, this message translates to:
  /// **'Clean bowled! {name} has to walk back.'**
  String play_comm_out_1(String name);

  /// No description provided for @play_comm_out_2.
  ///
  /// In en, this message translates to:
  /// **'Timber! What a ball to get rid of {name}.'**
  String play_comm_out_2(String name);

  /// No description provided for @play_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get play_you;

  /// No description provided for @play_sound_on.
  ///
  /// In en, this message translates to:
  /// **'Sound on'**
  String get play_sound_on;

  /// No description provided for @play_sound_off.
  ///
  /// In en, this message translates to:
  /// **'Sound off'**
  String get play_sound_off;

  /// No description provided for @play_this_over.
  ///
  /// In en, this message translates to:
  /// **'This over'**
  String get play_this_over;

  /// No description provided for @play_hud_overs.
  ///
  /// In en, this message translates to:
  /// **'Overs {overs}/{total}'**
  String play_hud_overs(String overs, int total);

  /// No description provided for @play_hud_target.
  ///
  /// In en, this message translates to:
  /// **'Target {target}'**
  String play_hud_target(int target);

  /// No description provided for @play_mode_match.
  ///
  /// In en, this message translates to:
  /// **'Live match'**
  String get play_mode_match;

  /// No description provided for @play_format_title.
  ///
  /// In en, this message translates to:
  /// **'Pick the format'**
  String get play_format_title;

  /// No description provided for @play_format_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Both of you face the same balls. Highest score wins.'**
  String get play_format_subtitle;

  /// No description provided for @play_format_quick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get play_format_quick;

  /// No description provided for @play_format_classic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get play_format_classic;

  /// No description provided for @play_format_long.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get play_format_long;

  /// No description provided for @play_format_detail.
  ///
  /// In en, this message translates to:
  /// **'{overs, plural, =1{1 over} other{{overs} overs}} · {wickets} wickets'**
  String play_format_detail(int overs, int wickets);

  /// No description provided for @play_send_request.
  ///
  /// In en, this message translates to:
  /// **'Send match request'**
  String get play_send_request;

  /// No description provided for @play_online_now.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get play_online_now;

  /// No description provided for @play_recent_opponents.
  ///
  /// In en, this message translates to:
  /// **'Played before'**
  String get play_recent_opponents;

  /// No description provided for @play_online_label.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get play_online_label;

  /// No description provided for @play_select_opponent_more.
  ///
  /// In en, this message translates to:
  /// **'Type a name to find more players'**
  String get play_select_opponent_more;

  /// No description provided for @play_select_opponent_none_online.
  ///
  /// In en, this message translates to:
  /// **'No one else is on Play right now. Search for a friend and send a request.'**
  String get play_select_opponent_none_online;

  /// No description provided for @play_match_waiting_title.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}'**
  String play_match_waiting_title(String name);

  /// No description provided for @play_match_waiting_body.
  ///
  /// In en, this message translates to:
  /// **'Your match request is on its way. It expires in 10 minutes.'**
  String get play_match_waiting_body;

  /// No description provided for @play_match_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get play_match_cancel;

  /// No description provided for @play_match_declined.
  ///
  /// In en, this message translates to:
  /// **'{name} can\'t play right now.'**
  String play_match_declined(String name);

  /// No description provided for @play_match_cancelled.
  ///
  /// In en, this message translates to:
  /// **'This match request was cancelled.'**
  String get play_match_cancelled;

  /// No description provided for @play_match_expired.
  ///
  /// In en, this message translates to:
  /// **'This match request expired.'**
  String get play_match_expired;

  /// No description provided for @play_match_back.
  ///
  /// In en, this message translates to:
  /// **'Back to Play'**
  String get play_match_back;

  /// No description provided for @play_match_incoming_title.
  ///
  /// In en, this message translates to:
  /// **'{name} challenges you!'**
  String play_match_incoming_title(String name);

  /// No description provided for @play_match_incoming_body.
  ///
  /// In en, this message translates to:
  /// **'Live match · {format}. Ready to play?'**
  String play_match_incoming_body(String format);

  /// No description provided for @play_match_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get play_match_accept;

  /// No description provided for @play_match_decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get play_match_decline;

  /// No description provided for @play_match_section.
  ///
  /// In en, this message translates to:
  /// **'Live matches'**
  String get play_match_section;

  /// No description provided for @play_match_request_from.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to play · {format}'**
  String play_match_request_from(String name, String format);

  /// No description provided for @play_match_request_to.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} · {format}'**
  String play_match_request_to(String name, String format);

  /// No description provided for @play_match_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Live vs {name} · {format}'**
  String play_match_in_progress(String name, String format);

  /// No description provided for @play_match_join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get play_match_join;

  /// No description provided for @play_match_unavailable.
  ///
  /// In en, this message translates to:
  /// **'This match is no longer available.'**
  String get play_match_unavailable;

  /// No description provided for @play_challenge_live_hint.
  ///
  /// In en, this message translates to:
  /// **'Live 1v1 match'**
  String get play_challenge_live_hint;

  /// No description provided for @play_vs.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get play_vs;

  /// No description provided for @play_toss_title.
  ///
  /// In en, this message translates to:
  /// **'Toss time'**
  String get play_toss_title;

  /// No description provided for @play_toss_call_prompt.
  ///
  /// In en, this message translates to:
  /// **'Call it!'**
  String get play_toss_call_prompt;

  /// No description provided for @play_toss_heads.
  ///
  /// In en, this message translates to:
  /// **'Heads'**
  String get play_toss_heads;

  /// No description provided for @play_toss_tails.
  ///
  /// In en, this message translates to:
  /// **'Tails'**
  String get play_toss_tails;

  /// No description provided for @play_toss_waiting_call.
  ///
  /// In en, this message translates to:
  /// **'{name} is calling the toss…'**
  String play_toss_waiting_call(String name);

  /// No description provided for @play_toss_called.
  ///
  /// In en, this message translates to:
  /// **'{name} called {call}'**
  String play_toss_called(String name, String call);

  /// No description provided for @play_toss_won.
  ///
  /// In en, this message translates to:
  /// **'You won the toss!'**
  String get play_toss_won;

  /// No description provided for @play_toss_lost.
  ///
  /// In en, this message translates to:
  /// **'{name} won the toss'**
  String play_toss_lost(String name);

  /// No description provided for @play_toss_choose.
  ///
  /// In en, this message translates to:
  /// **'Bat or bowl first?'**
  String get play_toss_choose;

  /// No description provided for @play_toss_bat.
  ///
  /// In en, this message translates to:
  /// **'Bat first'**
  String get play_toss_bat;

  /// No description provided for @play_toss_bowl.
  ///
  /// In en, this message translates to:
  /// **'Bowl first'**
  String get play_toss_bowl;

  /// No description provided for @play_toss_waiting_choice.
  ///
  /// In en, this message translates to:
  /// **'{name} is choosing…'**
  String play_toss_waiting_choice(String name);

  /// No description provided for @play_bats_first.
  ///
  /// In en, this message translates to:
  /// **'{name} bats first'**
  String play_bats_first(String name);

  /// No description provided for @play_live_your_innings.
  ///
  /// In en, this message translates to:
  /// **'Your innings'**
  String get play_live_your_innings;

  /// No description provided for @play_live_batting.
  ///
  /// In en, this message translates to:
  /// **'{name} is batting'**
  String play_live_batting(String name);

  /// No description provided for @play_live_watch_first.
  ///
  /// In en, this message translates to:
  /// **'Watch live. You chase this score next.'**
  String get play_live_watch_first;

  /// No description provided for @play_live_watch_second.
  ///
  /// In en, this message translates to:
  /// **'Watch live. {name} needs {target} to win.'**
  String play_live_watch_second(String name, int target);

  /// No description provided for @play_live_waiting_ball.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the next ball…'**
  String get play_live_waiting_ball;

  /// No description provided for @play_innings_break.
  ///
  /// In en, this message translates to:
  /// **'Innings break'**
  String get play_innings_break;

  /// No description provided for @play_innings_break_body.
  ///
  /// In en, this message translates to:
  /// **'{name} scored {score}. {chaser} needs {target} to win.'**
  String play_innings_break_body(
      String name, String score, String chaser, int target);

  /// No description provided for @play_countdown_go.
  ///
  /// In en, this message translates to:
  /// **'GO!'**
  String get play_countdown_go;

  /// No description provided for @play_get_ready.
  ///
  /// In en, this message translates to:
  /// **'Get ready'**
  String get play_get_ready;

  /// No description provided for @play_opponent_offline.
  ///
  /// In en, this message translates to:
  /// **'{name} disconnected. Waiting for them to come back…'**
  String play_opponent_offline(String name);

  /// No description provided for @play_claim_win.
  ///
  /// In en, this message translates to:
  /// **'Claim win'**
  String get play_claim_win;

  /// No description provided for @play_leave_title.
  ///
  /// In en, this message translates to:
  /// **'Leave the match?'**
  String get play_leave_title;

  /// No description provided for @play_leave_body.
  ///
  /// In en, this message translates to:
  /// **'You will forfeit and {name} wins.'**
  String play_leave_body(String name);

  /// No description provided for @play_leave_confirm.
  ///
  /// In en, this message translates to:
  /// **'Forfeit'**
  String get play_leave_confirm;

  /// No description provided for @play_leave_stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get play_leave_stay;

  /// No description provided for @play_result_by_runs.
  ///
  /// In en, this message translates to:
  /// **'{name} won by {runs, plural, =1{1 run} other{{runs} runs}}'**
  String play_result_by_runs(String name, int runs);

  /// No description provided for @play_result_by_wickets.
  ///
  /// In en, this message translates to:
  /// **'{name} won by {wickets, plural, =1{1 wicket} other{{wickets} wickets}}'**
  String play_result_by_wickets(String name, int wickets);

  /// No description provided for @play_result_tied.
  ///
  /// In en, this message translates to:
  /// **'It\'s a tie!'**
  String get play_result_tied;

  /// No description provided for @play_result_forfeit.
  ///
  /// In en, this message translates to:
  /// **'{name} won. The other player left.'**
  String play_result_forfeit(String name);

  /// No description provided for @play_result_you_win.
  ///
  /// In en, this message translates to:
  /// **'YOU WIN!'**
  String get play_result_you_win;

  /// No description provided for @play_result_you_lose.
  ///
  /// In en, this message translates to:
  /// **'YOU LOSE'**
  String get play_result_you_lose;

  /// No description provided for @play_result_tie_banner.
  ///
  /// In en, this message translates to:
  /// **'TIE!'**
  String get play_result_tie_banner;

  /// No description provided for @play_scorecard.
  ///
  /// In en, this message translates to:
  /// **'Scorecard'**
  String get play_scorecard;

  /// No description provided for @play_sc_runs.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get play_sc_runs;

  /// No description provided for @play_sc_balls.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get play_sc_balls;

  /// No description provided for @play_sc_fours.
  ///
  /// In en, this message translates to:
  /// **'4s'**
  String get play_sc_fours;

  /// No description provided for @play_sc_sixes.
  ///
  /// In en, this message translates to:
  /// **'6s'**
  String get play_sc_sixes;

  /// No description provided for @play_sc_strike_rate.
  ///
  /// In en, this message translates to:
  /// **'SR'**
  String get play_sc_strike_rate;

  /// No description provided for @play_rematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch'**
  String get play_rematch;

  /// No description provided for @play_xp_earned.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String play_xp_earned(int xp);

  /// No description provided for @play_level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String play_level(int level);

  /// No description provided for @play_xp_progress.
  ///
  /// In en, this message translates to:
  /// **'{xp}/{next} XP'**
  String play_xp_progress(int xp, int next);

  /// No description provided for @play_stat_streak.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{No streak} =1{1-day streak} other{{days}-day streak}}'**
  String play_stat_streak(int days);

  /// No description provided for @play_stat_wins.
  ///
  /// In en, this message translates to:
  /// **'{wins, plural, =1{1 win} other{{wins} wins}}'**
  String play_stat_wins(int wins);

  /// No description provided for @play_stat_best.
  ///
  /// In en, this message translates to:
  /// **'Best {runs}'**
  String play_stat_best(int runs);

  /// No description provided for @play_badges_title.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get play_badges_title;

  /// No description provided for @play_badge_first_six.
  ///
  /// In en, this message translates to:
  /// **'First six'**
  String get play_badge_first_six;

  /// No description provided for @play_badge_six_hitter.
  ///
  /// In en, this message translates to:
  /// **'3 sixes in a game'**
  String get play_badge_six_hitter;

  /// No description provided for @play_badge_thirty.
  ///
  /// In en, this message translates to:
  /// **'30 in a game'**
  String get play_badge_thirty;

  /// No description provided for @play_badge_match_winner.
  ///
  /// In en, this message translates to:
  /// **'Won a live match'**
  String get play_badge_match_winner;

  /// No description provided for @play_badge_daily_streak.
  ///
  /// In en, this message translates to:
  /// **'3-day streak'**
  String get play_badge_daily_streak;

  /// No description provided for @play_badge_century.
  ///
  /// In en, this message translates to:
  /// **'100 career runs'**
  String get play_badge_century;

  /// No description provided for @play_badge_veteran.
  ///
  /// In en, this message translates to:
  /// **'25 games played'**
  String get play_badge_veteran;

  /// No description provided for @play_badge_unlocked.
  ///
  /// In en, this message translates to:
  /// **'Badge unlocked: {badge}'**
  String play_badge_unlocked(String badge);

  /// No description provided for @profile_my_stats.
  ///
  /// In en, this message translates to:
  /// **'My stats'**
  String get profile_my_stats;

  /// No description provided for @tab_auction_title.
  ///
  /// In en, this message translates to:
  /// **'Auction'**
  String get tab_auction_title;

  /// No description provided for @auction_screen_title.
  ///
  /// In en, this message translates to:
  /// **'Player Auctions'**
  String get auction_screen_title;

  /// No description provided for @auction_hero_title.
  ///
  /// In en, this message translates to:
  /// **'Run a player auction'**
  String get auction_hero_title;

  /// No description provided for @auction_hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Register players, set retained players and run live bidding. The tournament is created for you at the end.'**
  String get auction_hero_subtitle;

  /// No description provided for @auction_create_title.
  ///
  /// In en, this message translates to:
  /// **'Create auction'**
  String get auction_create_title;

  /// No description provided for @auction_sign_in_to_create.
  ///
  /// In en, this message translates to:
  /// **'Sign in to create'**
  String get auction_sign_in_to_create;

  /// No description provided for @auction_section_mine.
  ///
  /// In en, this message translates to:
  /// **'My auctions'**
  String get auction_section_mine;

  /// No description provided for @auction_section_live.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get auction_section_live;

  /// No description provided for @auction_section_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get auction_section_upcoming;

  /// No description provided for @auction_section_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get auction_section_completed;

  /// No description provided for @auction_empty.
  ///
  /// In en, this message translates to:
  /// **'No auctions yet.'**
  String get auction_empty;

  /// No description provided for @auction_empty_body.
  ///
  /// In en, this message translates to:
  /// **'Create one to register players and run live bidding.'**
  String get auction_empty_body;

  /// No description provided for @auction_hero_stat_live.
  ///
  /// In en, this message translates to:
  /// **'{count} live'**
  String auction_hero_stat_live(int count);

  /// No description provided for @auction_hero_stat_upcoming.
  ///
  /// In en, this message translates to:
  /// **'{count} upcoming'**
  String auction_hero_stat_upcoming(int count);

  /// No description provided for @auction_hero_stat_completed.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String auction_hero_stat_completed(int count);

  /// No description provided for @auction_not_found.
  ///
  /// In en, this message translates to:
  /// **'This auction doesn\'t exist or isn\'t public yet.'**
  String get auction_not_found;

  /// No description provided for @auction_status_draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get auction_status_draft;

  /// No description provided for @auction_status_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get auction_status_upcoming;

  /// No description provided for @auction_status_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get auction_status_live;

  /// No description provided for @auction_status_paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get auction_status_paused;

  /// No description provided for @auction_status_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get auction_status_completed;

  /// No description provided for @auction_tile_summary.
  ///
  /// In en, this message translates to:
  /// **'{teams} teams · {players} players'**
  String auction_tile_summary(int teams, int players);

  /// No description provided for @auction_progress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} processed'**
  String auction_progress(int done, int total);

  /// No description provided for @auction_progress_label.
  ///
  /// In en, this message translates to:
  /// **'Auction progress'**
  String get auction_progress_label;

  /// No description provided for @auction_pts.
  ///
  /// In en, this message translates to:
  /// **'{amount} pts'**
  String auction_pts(int amount);

  /// No description provided for @auction_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit auction'**
  String get auction_edit_title;

  /// No description provided for @auction_name_label.
  ///
  /// In en, this message translates to:
  /// **'Auction name'**
  String get auction_name_label;

  /// No description provided for @auction_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. GCPL Auction'**
  String get auction_name_hint;

  /// No description provided for @auction_tournament_name_label.
  ///
  /// In en, this message translates to:
  /// **'Tournament name'**
  String get auction_tournament_name_label;

  /// No description provided for @auction_tournament_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. GCPL'**
  String get auction_tournament_name_hint;

  /// No description provided for @auction_tournament_name_help.
  ///
  /// In en, this message translates to:
  /// **'The tournament created when the auction is completed gets this name.'**
  String get auction_tournament_name_help;

  /// No description provided for @auction_description_label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get auction_description_label;

  /// No description provided for @auction_description_hint.
  ///
  /// In en, this message translates to:
  /// **'Season, venue, anything players should know'**
  String get auction_description_hint;

  /// No description provided for @auction_date_label.
  ///
  /// In en, this message translates to:
  /// **'Auction date'**
  String get auction_date_label;

  /// No description provided for @auction_date_pick.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get auction_date_pick;

  /// No description provided for @auction_banner_add.
  ///
  /// In en, this message translates to:
  /// **'Add banner'**
  String get auction_banner_add;

  /// No description provided for @auction_banner_change.
  ///
  /// In en, this message translates to:
  /// **'Change banner'**
  String get auction_banner_change;

  /// No description provided for @auction_rules_title.
  ///
  /// In en, this message translates to:
  /// **'Budget and bidding'**
  String get auction_rules_title;

  /// No description provided for @auction_team_budget.
  ///
  /// In en, this message translates to:
  /// **'Team budget (pts)'**
  String get auction_team_budget;

  /// No description provided for @auction_base_price.
  ///
  /// In en, this message translates to:
  /// **'Starting bid (pts)'**
  String get auction_base_price;

  /// No description provided for @auction_bid_increment.
  ///
  /// In en, this message translates to:
  /// **'Bid increment (pts)'**
  String get auction_bid_increment;

  /// No description provided for @auction_min_squad.
  ///
  /// In en, this message translates to:
  /// **'Min squad (0 = none)'**
  String get auction_min_squad;

  /// No description provided for @auction_max_squad.
  ///
  /// In en, this message translates to:
  /// **'Max squad (0 = no limit)'**
  String get auction_max_squad;

  /// No description provided for @auction_show_budgets.
  ///
  /// In en, this message translates to:
  /// **'Show team budgets on the public screen'**
  String get auction_show_budgets;

  /// No description provided for @auction_teams_title.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get auction_teams_title;

  /// No description provided for @auction_team_name.
  ///
  /// In en, this message translates to:
  /// **'Team {number} name'**
  String auction_team_name(int number);

  /// No description provided for @auction_team_short.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get auction_team_short;

  /// No description provided for @auction_add_team.
  ///
  /// In en, this message translates to:
  /// **'Add team'**
  String get auction_add_team;

  /// No description provided for @auction_teams_locked.
  ///
  /// In en, this message translates to:
  /// **'Teams can\'t change after the auction starts.'**
  String get auction_teams_locked;

  /// No description provided for @auction_admins_title.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get auction_admins_title;

  /// No description provided for @auction_admins_help.
  ///
  /// In en, this message translates to:
  /// **'Admins can edit and run this auction.'**
  String get auction_admins_help;

  /// No description provided for @auction_add_admin.
  ///
  /// In en, this message translates to:
  /// **'Add admin'**
  String get auction_add_admin;

  /// No description provided for @auction_select_admin.
  ///
  /// In en, this message translates to:
  /// **'Select an admin'**
  String get auction_select_admin;

  /// No description provided for @auction_creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get auction_creator;

  /// No description provided for @auction_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get auction_save;

  /// No description provided for @auction_validation_name.
  ///
  /// In en, this message translates to:
  /// **'Enter the auction name and tournament name'**
  String get auction_validation_name;

  /// No description provided for @auction_validation_teams.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 teams with names'**
  String get auction_validation_teams;

  /// No description provided for @auction_validation_team_names.
  ///
  /// In en, this message translates to:
  /// **'Team names must be different'**
  String get auction_validation_team_names;

  /// No description provided for @auction_validation_rules.
  ///
  /// In en, this message translates to:
  /// **'Budget, starting bid and increment must be above 0, and min squad can\'t be more than max squad'**
  String get auction_validation_rules;

  /// No description provided for @auction_players_title.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get auction_players_title;

  /// No description provided for @auction_players_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 player} other{{count} players}}'**
  String auction_players_count(int count);

  /// No description provided for @auction_players_empty.
  ///
  /// In en, this message translates to:
  /// **'No players yet. Add them one by one, paste a list, or upload photos named after the players.'**
  String get auction_players_empty;

  /// No description provided for @auction_player_search.
  ///
  /// In en, this message translates to:
  /// **'Search name, ID or number'**
  String get auction_player_search;

  /// No description provided for @auction_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get auction_filter_all;

  /// No description provided for @auction_player_status_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get auction_player_status_available;

  /// No description provided for @auction_player_status_retained.
  ///
  /// In en, this message translates to:
  /// **'Retained'**
  String get auction_player_status_retained;

  /// No description provided for @auction_player_status_in_auction.
  ///
  /// In en, this message translates to:
  /// **'In auction'**
  String get auction_player_status_in_auction;

  /// No description provided for @auction_player_status_sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get auction_player_status_sold;

  /// No description provided for @auction_player_status_unsold.
  ///
  /// In en, this message translates to:
  /// **'Unsold'**
  String get auction_player_status_unsold;

  /// No description provided for @auction_add_player.
  ///
  /// In en, this message translates to:
  /// **'Add player'**
  String get auction_add_player;

  /// No description provided for @auction_edit_player.
  ///
  /// In en, this message translates to:
  /// **'Edit player'**
  String get auction_edit_player;

  /// No description provided for @auction_add_players_bulk.
  ///
  /// In en, this message translates to:
  /// **'Add many'**
  String get auction_add_players_bulk;

  /// No description provided for @auction_upload_photos.
  ///
  /// In en, this message translates to:
  /// **'Upload photos'**
  String get auction_upload_photos;

  /// No description provided for @auction_bulk_title.
  ///
  /// In en, this message translates to:
  /// **'Add many players'**
  String get auction_bulk_title;

  /// No description provided for @auction_bulk_hint.
  ///
  /// In en, this message translates to:
  /// **'One player per line:\nName, Player ID, Number, Role, Base price\nOnly the name is required. Roles: bat, bowl, all, wk'**
  String get auction_bulk_hint;

  /// No description provided for @auction_bulk_result.
  ///
  /// In en, this message translates to:
  /// **'{added} added, {skipped} duplicates skipped'**
  String auction_bulk_result(int added, int skipped);

  /// No description provided for @auction_player_name.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get auction_player_name;

  /// No description provided for @auction_player_code.
  ///
  /// In en, this message translates to:
  /// **'Player ID'**
  String get auction_player_code;

  /// No description provided for @auction_player_number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get auction_player_number;

  /// No description provided for @auction_player_base.
  ///
  /// In en, this message translates to:
  /// **'Base price'**
  String get auction_player_base;

  /// No description provided for @auction_photo_add.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get auction_photo_add;

  /// No description provided for @auction_photo_change.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get auction_photo_change;

  /// No description provided for @auction_remove_player.
  ///
  /// In en, this message translates to:
  /// **'Remove player'**
  String get auction_remove_player;

  /// No description provided for @auction_remove_player_confirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the auction?'**
  String auction_remove_player_confirm(String name);

  /// No description provided for @auction_photos_title.
  ///
  /// In en, this message translates to:
  /// **'Match photos to players'**
  String get auction_photos_title;

  /// No description provided for @auction_photos_help.
  ///
  /// In en, this message translates to:
  /// **'Photos are matched by file name: player ID, number or name, e.g. P001.jpg, 7.jpg or Arun Kumar.jpg.'**
  String get auction_photos_help;

  /// No description provided for @auction_photos_summary.
  ///
  /// In en, this message translates to:
  /// **'{matched} matched · {unmatched} not matched'**
  String auction_photos_summary(int matched, int unmatched);

  /// No description provided for @auction_photo_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get auction_photo_skip;

  /// No description provided for @auction_photo_new_player.
  ///
  /// In en, this message translates to:
  /// **'New player: {name}'**
  String auction_photo_new_player(String name);

  /// No description provided for @auction_photos_upload.
  ///
  /// In en, this message translates to:
  /// **'Upload {count}'**
  String auction_photos_upload(int count);

  /// No description provided for @auction_photos_done.
  ///
  /// In en, this message translates to:
  /// **'{count} photos uploaded'**
  String auction_photos_done(int count);

  /// No description provided for @auction_pick_player.
  ///
  /// In en, this message translates to:
  /// **'Pick a player'**
  String get auction_pick_player;

  /// No description provided for @auction_retained_title.
  ///
  /// In en, this message translates to:
  /// **'Retained players'**
  String get auction_retained_title;

  /// No description provided for @auction_retained_help.
  ///
  /// In en, this message translates to:
  /// **'Retained players join their team before bidding, skip the auction, and their cost comes out of the team budget.'**
  String get auction_retained_help;

  /// No description provided for @auction_retain_add.
  ///
  /// In en, this message translates to:
  /// **'Retain player'**
  String get auction_retain_add;

  /// No description provided for @auction_retained_none.
  ///
  /// In en, this message translates to:
  /// **'No retained players'**
  String get auction_retained_none;

  /// No description provided for @auction_retain_price.
  ///
  /// In en, this message translates to:
  /// **'Retained cost (pts)'**
  String get auction_retain_price;

  /// No description provided for @auction_release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get auction_release;

  /// No description provided for @auction_budget_line.
  ///
  /// In en, this message translates to:
  /// **'{spent} spent · {remaining} left of {budget}'**
  String auction_budget_line(int spent, int remaining, int budget);

  /// No description provided for @auction_remaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String auction_remaining(int amount);

  /// No description provided for @auction_tab_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get auction_tab_live;

  /// No description provided for @auction_tab_teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get auction_tab_teams;

  /// No description provided for @auction_tab_players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get auction_tab_players;

  /// No description provided for @auction_tab_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get auction_tab_history;

  /// No description provided for @auction_setup_title.
  ///
  /// In en, this message translates to:
  /// **'Get the auction ready'**
  String get auction_setup_title;

  /// No description provided for @auction_setup_details.
  ///
  /// In en, this message translates to:
  /// **'Details and teams'**
  String get auction_setup_details;

  /// No description provided for @auction_setup_players.
  ///
  /// In en, this message translates to:
  /// **'Players ({count})'**
  String auction_setup_players(int count);

  /// No description provided for @auction_setup_retained.
  ///
  /// In en, this message translates to:
  /// **'Retained players ({count})'**
  String auction_setup_retained(int count);

  /// No description provided for @auction_publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get auction_publish;

  /// No description provided for @auction_publish_help.
  ///
  /// In en, this message translates to:
  /// **'Published auctions are visible to everyone, even without signing in.'**
  String get auction_publish_help;

  /// No description provided for @auction_unpublish.
  ///
  /// In en, this message translates to:
  /// **'Back to draft'**
  String get auction_unpublish;

  /// No description provided for @auction_start.
  ///
  /// In en, this message translates to:
  /// **'Start auction'**
  String get auction_start;

  /// No description provided for @auction_starts_on.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String auction_starts_on(String date);

  /// No description provided for @auction_not_started.
  ///
  /// In en, this message translates to:
  /// **'The auction hasn\'t started yet.'**
  String get auction_not_started;

  /// No description provided for @auction_view_only.
  ///
  /// In en, this message translates to:
  /// **'Live view · updates automatically'**
  String get auction_view_only;

  /// No description provided for @auction_player_of.
  ///
  /// In en, this message translates to:
  /// **'Player {current} of {total}'**
  String auction_player_of(int current, int total);

  /// No description provided for @auction_base.
  ///
  /// In en, this message translates to:
  /// **'Base {amount} pts'**
  String auction_base(int amount);

  /// No description provided for @auction_current_bid.
  ///
  /// In en, this message translates to:
  /// **'Current bid'**
  String get auction_current_bid;

  /// No description provided for @auction_no_bids.
  ///
  /// In en, this message translates to:
  /// **'No bids yet'**
  String get auction_no_bids;

  /// No description provided for @auction_bidding_closed.
  ///
  /// In en, this message translates to:
  /// **'Bidding not started'**
  String get auction_bidding_closed;

  /// No description provided for @auction_leading.
  ///
  /// In en, this message translates to:
  /// **'{team} leading'**
  String auction_leading(String team);

  /// No description provided for @auction_paused_banner.
  ///
  /// In en, this message translates to:
  /// **'The auction is paused'**
  String get auction_paused_banner;

  /// No description provided for @auction_prev_player.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get auction_prev_player;

  /// No description provided for @auction_next_player.
  ///
  /// In en, this message translates to:
  /// **'Next player'**
  String get auction_next_player;

  /// No description provided for @auction_start_bidding.
  ///
  /// In en, this message translates to:
  /// **'Start bidding'**
  String get auction_start_bidding;

  /// No description provided for @auction_bid_amount.
  ///
  /// In en, this message translates to:
  /// **'Bid {amount}'**
  String auction_bid_amount(int amount);

  /// No description provided for @auction_undo_bid.
  ///
  /// In en, this message translates to:
  /// **'Undo bid'**
  String get auction_undo_bid;

  /// No description provided for @auction_sell.
  ///
  /// In en, this message translates to:
  /// **'Sell player'**
  String get auction_sell;

  /// No description provided for @auction_mark_unsold.
  ///
  /// In en, this message translates to:
  /// **'Mark unsold'**
  String get auction_mark_unsold;

  /// No description provided for @auction_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get auction_pause;

  /// No description provided for @auction_resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get auction_resume;

  /// No description provided for @auction_reopen_unsold.
  ///
  /// In en, this message translates to:
  /// **'Re-auction unsold ({count})'**
  String auction_reopen_unsold(int count);

  /// No description provided for @auction_all_processed.
  ///
  /// In en, this message translates to:
  /// **'Every player has been processed'**
  String get auction_all_processed;

  /// No description provided for @auction_last_sold.
  ///
  /// In en, this message translates to:
  /// **'{player} → {team} · {amount} pts'**
  String auction_last_sold(String player, String team, int amount);

  /// No description provided for @auction_count_sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get auction_count_sold;

  /// No description provided for @auction_count_unsold.
  ///
  /// In en, this message translates to:
  /// **'Unsold'**
  String get auction_count_unsold;

  /// No description provided for @auction_count_retained.
  ///
  /// In en, this message translates to:
  /// **'Retained'**
  String get auction_count_retained;

  /// No description provided for @auction_count_left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get auction_count_left;

  /// No description provided for @auction_tag_retained.
  ///
  /// In en, this message translates to:
  /// **'RETAINED'**
  String get auction_tag_retained;

  /// No description provided for @auction_tag_sold.
  ///
  /// In en, this message translates to:
  /// **'SOLD'**
  String get auction_tag_sold;

  /// No description provided for @auction_squad_empty.
  ///
  /// In en, this message translates to:
  /// **'No players yet'**
  String get auction_squad_empty;

  /// No description provided for @auction_show_now.
  ///
  /// In en, this message translates to:
  /// **'Put up now'**
  String get auction_show_now;

  /// No description provided for @auction_history_empty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get auction_history_empty;

  /// No description provided for @auction_log_created.
  ///
  /// In en, this message translates to:
  /// **'Auction created'**
  String get auction_log_created;

  /// No description provided for @auction_log_published.
  ///
  /// In en, this message translates to:
  /// **'Auction published'**
  String get auction_log_published;

  /// No description provided for @auction_log_started.
  ///
  /// In en, this message translates to:
  /// **'Auction started'**
  String get auction_log_started;

  /// No description provided for @auction_log_paused.
  ///
  /// In en, this message translates to:
  /// **'Auction paused'**
  String get auction_log_paused;

  /// No description provided for @auction_log_resumed.
  ///
  /// In en, this message translates to:
  /// **'Auction resumed'**
  String get auction_log_resumed;

  /// No description provided for @auction_log_shown.
  ///
  /// In en, this message translates to:
  /// **'{player} is up'**
  String auction_log_shown(String player);

  /// No description provided for @auction_log_bidding_started.
  ///
  /// In en, this message translates to:
  /// **'Bidding open for {player}'**
  String auction_log_bidding_started(String player);

  /// No description provided for @auction_log_bid.
  ///
  /// In en, this message translates to:
  /// **'{team} bid {amount} for {player}'**
  String auction_log_bid(String team, int amount, String player);

  /// No description provided for @auction_log_bid_undone.
  ///
  /// In en, this message translates to:
  /// **'Bid of {amount} by {team} undone'**
  String auction_log_bid_undone(int amount, String team);

  /// No description provided for @auction_log_sold.
  ///
  /// In en, this message translates to:
  /// **'{player} sold to {team} for {amount}'**
  String auction_log_sold(String player, String team, int amount);

  /// No description provided for @auction_log_unsold.
  ///
  /// In en, this message translates to:
  /// **'{player} unsold'**
  String auction_log_unsold(String player);

  /// No description provided for @auction_log_reopened.
  ///
  /// In en, this message translates to:
  /// **'Unsold players back in the pool'**
  String get auction_log_reopened;

  /// No description provided for @auction_log_retained.
  ///
  /// In en, this message translates to:
  /// **'{player} retained by {team} for {amount}'**
  String auction_log_retained(String player, String team, int amount);

  /// No description provided for @auction_log_released.
  ///
  /// In en, this message translates to:
  /// **'{player} released'**
  String auction_log_released(String player);

  /// No description provided for @auction_log_completed.
  ///
  /// In en, this message translates to:
  /// **'Auction completed and tournament created'**
  String get auction_log_completed;

  /// No description provided for @auction_share.
  ///
  /// In en, this message translates to:
  /// **'Copy public link'**
  String get auction_share;

  /// No description provided for @auction_link_copied.
  ///
  /// In en, this message translates to:
  /// **'Public link copied'**
  String get auction_link_copied;

  /// No description provided for @auction_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get auction_edit;

  /// No description provided for @auction_manage_players.
  ///
  /// In en, this message translates to:
  /// **'Manage players'**
  String get auction_manage_players;

  /// No description provided for @auction_manage_retained.
  ///
  /// In en, this message translates to:
  /// **'Retained players'**
  String get auction_manage_retained;

  /// No description provided for @auction_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete auction'**
  String get auction_delete;

  /// No description provided for @auction_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this auction, its history and photos? A tournament already created from it is kept.'**
  String get auction_delete_confirm;

  /// No description provided for @auction_complete.
  ///
  /// In en, this message translates to:
  /// **'Complete auction'**
  String get auction_complete;

  /// No description provided for @auction_complete_message.
  ///
  /// In en, this message translates to:
  /// **'This ends the auction and creates the tournament \"{name}\" with {teams} teams and their players. No matches, fixtures or dates are created.'**
  String auction_complete_message(String name, int teams);

  /// No description provided for @auction_complete_left.
  ///
  /// In en, this message translates to:
  /// **'{count} players were never auctioned. They will be marked unsold.'**
  String auction_complete_left(int count);

  /// No description provided for @auction_complete_blocked.
  ///
  /// In en, this message translates to:
  /// **'A player with bids is still up. Sell them or undo the bids first.'**
  String get auction_complete_blocked;

  /// No description provided for @auction_complete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Complete and create tournament'**
  String get auction_complete_confirm;

  /// No description provided for @auction_tournament_created.
  ///
  /// In en, this message translates to:
  /// **'Tournament created: {name}'**
  String auction_tournament_created(String name);

  /// No description provided for @auction_open_tournament.
  ///
  /// In en, this message translates to:
  /// **'Open tournament'**
  String get auction_open_tournament;

  /// No description provided for @auction_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get auction_home;

  /// No description provided for @auction_create_tournament_retry.
  ///
  /// In en, this message translates to:
  /// **'Create tournament'**
  String get auction_create_tournament_retry;

  /// No description provided for @auction_create_tournament_retry_message.
  ///
  /// In en, this message translates to:
  /// **'The auction is complete but its tournament wasn\'t created. Create \"{name}\" with {teams} teams and their players now. No matches, fixtures or dates are created.'**
  String auction_create_tournament_retry_message(String name, int teams);

  /// No description provided for @auction_error_not_editable.
  ///
  /// In en, this message translates to:
  /// **'This can only be changed before the auction starts.'**
  String get auction_error_not_editable;

  /// No description provided for @auction_error_not_live.
  ///
  /// In en, this message translates to:
  /// **'The auction isn\'t live.'**
  String get auction_error_not_live;

  /// No description provided for @auction_error_paused.
  ///
  /// In en, this message translates to:
  /// **'The auction is paused.'**
  String get auction_error_paused;

  /// No description provided for @auction_error_no_player.
  ///
  /// In en, this message translates to:
  /// **'No player is up.'**
  String get auction_error_no_player;

  /// No description provided for @auction_error_bidding_closed.
  ///
  /// In en, this message translates to:
  /// **'Start bidding first.'**
  String get auction_error_bidding_closed;

  /// No description provided for @auction_error_already_leading.
  ///
  /// In en, this message translates to:
  /// **'Leading'**
  String get auction_error_already_leading;

  /// No description provided for @auction_error_squad_full.
  ///
  /// In en, this message translates to:
  /// **'Squad full'**
  String get auction_error_squad_full;

  /// No description provided for @auction_error_over_budget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get auction_error_over_budget;

  /// No description provided for @auction_error_bid_moved.
  ///
  /// In en, this message translates to:
  /// **'The bid changed. Try again.'**
  String get auction_error_bid_moved;

  /// No description provided for @auction_error_has_bids.
  ///
  /// In en, this message translates to:
  /// **'This player already has bids.'**
  String get auction_error_has_bids;

  /// No description provided for @auction_error_no_bid.
  ///
  /// In en, this message translates to:
  /// **'No bids yet.'**
  String get auction_error_no_bid;

  /// No description provided for @auction_error_player_unavailable.
  ///
  /// In en, this message translates to:
  /// **'This player isn\'t available.'**
  String get auction_error_player_unavailable;

  /// No description provided for @auction_error_no_players_left.
  ///
  /// In en, this message translates to:
  /// **'No players left in the pool.'**
  String get auction_error_no_players_left;

  /// No description provided for @auction_error_no_previous.
  ///
  /// In en, this message translates to:
  /// **'No earlier unsold player to go back to.'**
  String get auction_error_no_previous;

  /// No description provided for @auction_error_need_teams.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 teams.'**
  String get auction_error_need_teams;

  /// No description provided for @auction_error_need_players.
  ///
  /// In en, this message translates to:
  /// **'Add players to the auction first.'**
  String get auction_error_need_players;

  /// No description provided for @auction_error_duplicate_player.
  ///
  /// In en, this message translates to:
  /// **'A player with the same ID, or the same name and number, already exists.'**
  String get auction_error_duplicate_player;

  /// No description provided for @auction_error_invalid_team.
  ///
  /// In en, this message translates to:
  /// **'That team has players assigned. Release them first.'**
  String get auction_error_invalid_team;

  /// No description provided for @auction_error_not_admin.
  ///
  /// In en, this message translates to:
  /// **'Only auction admins can do this.'**
  String get auction_error_not_admin;

  /// No description provided for @auction_error_already_completed.
  ///
  /// In en, this message translates to:
  /// **'The auction is already completed.'**
  String get auction_error_already_completed;

  /// No description provided for @auction_error_incomplete.
  ///
  /// In en, this message translates to:
  /// **'Some players still need to be processed.'**
  String get auction_error_incomplete;

  /// No description provided for @auction_error_too_many_players.
  ///
  /// In en, this message translates to:
  /// **'Too many players for one auction.'**
  String get auction_error_too_many_players;

  /// No description provided for @mascot_setting_title.
  ///
  /// In en, this message translates to:
  /// **'Tiger guide'**
  String get mascot_setting_title;

  /// No description provided for @mascot_welcome_named.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}! Welcome back to Sports Tamil.'**
  String mascot_welcome_named(String name);

  /// No description provided for @mascot_welcome_guest.
  ///
  /// In en, this message translates to:
  /// **'Hi there! Welcome to Sports Tamil. Let\'s play!'**
  String get mascot_welcome_guest;

  /// No description provided for @mascot_sign_in_options.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email, or jump in as a guest to play.'**
  String get mascot_sign_in_options;

  /// No description provided for @mascot_sign_in_required.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in for this. It only takes a moment!'**
  String get mascot_sign_in_required;

  /// No description provided for @mascot_sign_in_to_create.
  ///
  /// In en, this message translates to:
  /// **'Sign in first, then you can create teams, matches and tournaments.'**
  String get mascot_sign_in_to_create;

  /// No description provided for @mascot_email_new_account.
  ///
  /// In en, this message translates to:
  /// **'New here? Let\'s make your account!'**
  String get mascot_email_new_account;

  /// No description provided for @mascot_email_looks_good.
  ///
  /// In en, this message translates to:
  /// **'That email looks good!'**
  String get mascot_email_looks_good;

  /// No description provided for @mascot_password_hidden.
  ///
  /// In en, this message translates to:
  /// **'I\'m not peeking at your password!'**
  String get mascot_password_hidden;

  /// No description provided for @mascot_password_shown.
  ///
  /// In en, this message translates to:
  /// **'Password visible. Make sure nobody\'s watching!'**
  String get mascot_password_shown;

  /// No description provided for @mascot_wrong_password.
  ///
  /// In en, this message translates to:
  /// **'Hmm, that didn\'t work. Forgot your password? Tap \"Forgot password\" and I\'ll send a reset link.'**
  String get mascot_wrong_password;

  /// No description provided for @mascot_email_in_use.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Try signing in instead.'**
  String get mascot_email_in_use;

  /// No description provided for @mascot_enter_email_first.
  ///
  /// In en, this message translates to:
  /// **'Type your email first, then tap \"Forgot password\".'**
  String get mascot_enter_email_first;

  /// No description provided for @mascot_reset_sent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent! Check your inbox and spam folder.'**
  String get mascot_reset_sent;

  /// No description provided for @mascot_something_wrong.
  ///
  /// In en, this message translates to:
  /// **'Oops, something went wrong. Please try again.'**
  String get mascot_something_wrong;

  /// No description provided for @mascot_login_success.
  ///
  /// In en, this message translates to:
  /// **'You\'re in! Let\'s play.'**
  String get mascot_login_success;

  /// No description provided for @mascot_registered.
  ///
  /// In en, this message translates to:
  /// **'Account created! Welcome to the team.'**
  String get mascot_registered;

  /// No description provided for @mascot_guest_joined.
  ///
  /// In en, this message translates to:
  /// **'You\'re playing as Guest. Your scores will show as \"Guest\".'**
  String get mascot_guest_joined;

  /// No description provided for @mascot_profile_intro.
  ///
  /// In en, this message translates to:
  /// **'Tell me your name so your friends can find you.'**
  String get mascot_profile_intro;

  /// No description provided for @mascot_profile_name.
  ///
  /// In en, this message translates to:
  /// **'Nice to meet you, {name}!'**
  String mascot_profile_name(String name);

  /// No description provided for @mascot_profile_created.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Sports Tamil, {name}!'**
  String mascot_profile_created(String name);

  /// No description provided for @mascot_profile_saved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved!'**
  String get mascot_profile_saved;

  /// No description provided for @mascot_profile_required.
  ///
  /// In en, this message translates to:
  /// **'Finish your profile first: just your name and mobile number.'**
  String get mascot_profile_required;

  /// No description provided for @mascot_profile_need_name.
  ///
  /// In en, this message translates to:
  /// **'First tell me your name!'**
  String get mascot_profile_need_name;

  /// No description provided for @mascot_profile_need_phone.
  ///
  /// In en, this message translates to:
  /// **'Add your mobile number. Only you can see it.'**
  String get mascot_profile_need_phone;

  /// No description provided for @mascot_profile_bad_phone.
  ///
  /// In en, this message translates to:
  /// **'That number doesn\'t look right. Check it once more.'**
  String get mascot_profile_bad_phone;

  /// No description provided for @mascot_profile_need_both.
  ///
  /// In en, this message translates to:
  /// **'I need your name and mobile number to create your profile.'**
  String get mascot_profile_need_both;

  /// No description provided for @mascot_profile_bad_email.
  ///
  /// In en, this message translates to:
  /// **'That email doesn\'t look right. Fix it or leave it empty.'**
  String get mascot_profile_bad_email;

  /// No description provided for @mascot_profile_photo_added.
  ///
  /// In en, this message translates to:
  /// **'Great photo! Looking like a hero.'**
  String get mascot_profile_photo_added;

  /// No description provided for @mascot_profile_photo_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t use that photo. Pick another one.'**
  String get mascot_profile_photo_failed;

  /// No description provided for @mascot_fun_six.
  ///
  /// In en, this message translates to:
  /// **'SIX! That ball has left the stadium and gone home!'**
  String get mascot_fun_six;

  /// No description provided for @mascot_fun_four.
  ///
  /// In en, this message translates to:
  /// **'FOUR! Straight to the boundary, what a shot!'**
  String get mascot_fun_four;

  /// No description provided for @mascot_fun_wicket.
  ///
  /// In en, this message translates to:
  /// **'WICKET! The pavilion is waiting, off you go!'**
  String get mascot_fun_wicket;

  /// No description provided for @mascot_fun_dot_ball.
  ///
  /// In en, this message translates to:
  /// **'Dot ball! A little smile for the bowler.'**
  String get mascot_fun_dot_ball;

  /// No description provided for @mascot_fun_perfect_timing.
  ///
  /// In en, this message translates to:
  /// **'Perfect timing! Even with eyes closed you couldn\'t hit it sweeter!'**
  String get mascot_fun_perfect_timing;

  /// No description provided for @mascot_fun_early_shot.
  ///
  /// In en, this message translates to:
  /// **'A bit too early! Let the ball come, then hit.'**
  String get mascot_fun_early_shot;

  /// No description provided for @mascot_fun_late_shot.
  ///
  /// In en, this message translates to:
  /// **'A bit late! The ball is already in the keeper\'s gloves.'**
  String get mascot_fun_late_shot;

  /// No description provided for @mascot_fun_match_won.
  ///
  /// In en, this message translates to:
  /// **'Victory! You\'re the hero today!'**
  String get mascot_fun_match_won;

  /// No description provided for @mascot_fun_match_lost.
  ///
  /// In en, this message translates to:
  /// **'Lost this one, but the next match is ours!'**
  String get mascot_fun_match_lost;

  /// No description provided for @mascot_fun_last_over.
  ///
  /// In en, this message translates to:
  /// **'Last over! Everyone to the edge of your seats!'**
  String get mascot_fun_last_over;

  /// No description provided for @mascot_fun_comeback.
  ///
  /// In en, this message translates to:
  /// **'No worries! A comeback is the real mass. One more time!'**
  String get mascot_fun_comeback;

  /// No description provided for @mascot_fun_team_created.
  ///
  /// In en, this message translates to:
  /// **'New team ready! See you on the field.'**
  String get mascot_fun_team_created;

  /// No description provided for @mascot_fun_tournament_created.
  ///
  /// In en, this message translates to:
  /// **'Tournament ready! Let the fight for the trophy begin.'**
  String get mascot_fun_tournament_created;

  /// No description provided for @mascot_fun_challenge_won.
  ///
  /// In en, this message translates to:
  /// **'Challenge won! Your opponent is speechless now.'**
  String get mascot_fun_challenge_won;

  /// No description provided for @mascot_fun_challenge_lost.
  ///
  /// In en, this message translates to:
  /// **'This challenge slipped away. When\'s the revenge match?'**
  String get mascot_fun_challenge_lost;

  /// No description provided for @mascot_fun_empty_matches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet. Start the first one yourself!'**
  String get mascot_fun_empty_matches;

  /// No description provided for @mascot_fun_no_players.
  ///
  /// In en, this message translates to:
  /// **'No players here yet. Add some people to the team!'**
  String get mascot_fun_no_players;

  /// No description provided for @mascot_fun_internet.
  ///
  /// In en, this message translates to:
  /// **'No internet! Please check your connection.'**
  String get mascot_fun_internet;

  /// No description provided for @mascot_fun_auction_sold.
  ///
  /// In en, this message translates to:
  /// **'SOLD! A new star for the team!'**
  String get mascot_fun_auction_sold;

  /// No description provided for @mascot_fun_auction_unsold.
  ///
  /// In en, this message translates to:
  /// **'Unsold… no worries, the chance will come in the next round!'**
  String get mascot_fun_auction_unsold;

  /// No description provided for @mascot_movie_baasha_style.
  ///
  /// In en, this message translates to:
  /// **'If I hit one six, it\'s like hitting a hundred!'**
  String get mascot_movie_baasha_style;

  /// No description provided for @mascot_movie_padayappa_style.
  ///
  /// In en, this message translates to:
  /// **'My shot, my own style!'**
  String get mascot_movie_padayappa_style;

  /// No description provided for @mascot_movie_mass_entry.
  ///
  /// In en, this message translates to:
  /// **'The Tiger has entered the ground! The game goes to another level now!'**
  String get mascot_movie_mass_entry;

  /// No description provided for @mascot_movie_comedy_scene.
  ///
  /// In en, this message translates to:
  /// **'The fielder is running faster than the ball, it\'s a comedy scene!'**
  String get mascot_movie_comedy_scene;

  /// No description provided for @mascot_movie_climax_scene.
  ///
  /// In en, this message translates to:
  /// **'This is the climax! Don\'t leave your seat till the last ball!'**
  String get mascot_movie_climax_scene;

  /// No description provided for @mascot_movie_hero_intro.
  ///
  /// In en, this message translates to:
  /// **'Hero entry! Raise the bat in slow motion!'**
  String get mascot_movie_hero_intro;

  /// No description provided for @mascot_movie_interval.
  ///
  /// In en, this message translates to:
  /// **'Interval! Have a tea and come back for the second half.'**
  String get mascot_movie_interval;

  /// No description provided for @mascot_movie_dialogue_hint.
  ///
  /// In en, this message translates to:
  /// **'What\'s your dialogue? Let your bat do the talking!'**
  String get mascot_movie_dialogue_hint;

  /// No description provided for @mascot_movie_cool_attitude.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play it cool... the scoreboard will do the talking!'**
  String get mascot_movie_cool_attitude;

  /// No description provided for @mascot_movie_youth_energy.
  ///
  /// In en, this message translates to:
  /// **'Whistles ready? Let the next shot shake the whole ground!'**
  String get mascot_movie_youth_energy;

  /// No description provided for @mascot_movie_mass_punch.
  ///
  /// In en, this message translates to:
  /// **'Our game needs no noise... the scoreboard is enough!'**
  String get mascot_movie_mass_punch;

  /// No description provided for @mascot_fun_match_tied.
  ///
  /// In en, this message translates to:
  /// **'It\'s a tie! Both teams fought right to the last ball!'**
  String get mascot_fun_match_tied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
