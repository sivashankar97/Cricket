import 'package:data/api/user/user_models.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/confirmation_dialog.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/phone/phone_number.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/profile/profile_view_model.dart';
import 'package:khelo/ui/flow/profile/player_claims.dart';
import 'package:khelo/ui/flow/settings/edit_profile/profile_completion.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/button/toggle_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

import '../../../gen/assets.gen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback changeTabToMyCricket;

  const ProfileScreen({super.key, required this.changeTabToMyCricket});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with WidgetsBindingObserver {
  static const _maxWidth = 640.0;

  final privacyPolicyUrl = "https://khelo.canopas.com/privacy-policy";
  final termsAndConditionsUrl = "https://khelo.canopas.com/terms-and-condition";
  final playStoreLink =
      "https://play.google.com/store/apps/details?id=com.canopas.khelo";
  final appStoreLink = "https://apps.apple.com/app/khelo/id6480175424";

  late ProfileViewNotifier notifier;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    notifier = ref.read(profileStateProvider.notifier);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      notifier.refreshNotificationPermissionStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _observeActionError(BuildContext context) {
    ref.listen(profileStateProvider.select((value) => value.actionError),
        (previous, next) {
      if (next != null) {
        showErrorSnackBar(context: context, error: next);
      }
    });
  }

  void _observeUserSession(BuildContext context) {
    ref.listen(hasUserSession, (previous, next) {
      if (!next) {
        AppRoute.main.go(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileStateProvider);
    final user = state.currentUser;

    _observeActionError(context);
    _observeUserSession(context);
    return AppPage(
      title: context.l10n.tab_profile_title,
      body: Builder(
        builder: (context) {
          return ListView(
            padding: context.mediaQueryPadding +
                const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _centered(_header(context, user)),
              if (state.shouldShowNotificationBanner)
                _centered(_notificationsOffCard(context)),
              _centered(const PlayerLinksSection()),
              _centered(_section(
                context,
                title: context.l10n.profile_section_activity,
                rows: [
                  _row(
                    context,
                    icon: CupertinoIcons.chart_bar_alt_fill,
                    tint: brandRedColor,
                    title: context.l10n.profile_my_stats,
                    subtitle: context.l10n.profile_stats_subtitle,
                    onTap: () => AppRoute.userStats().push(context),
                  ),
                  if (user != null)
                    _row(
                      context,
                      icon: CupertinoIcons.qrcode,
                      tint: context.colorScheme.info,
                      title: context.l10n.profile_qr_title,
                      subtitle: context.l10n.profile_qr_subtitle,
                      trailing: _miniQr(context, user.id),
                      onTap: () => AppRoute.qrCodeView(
                        id: user.id,
                        description: context
                            .l10n.profile_setting_use_scanner_description,
                      ).push(context),
                    ),
                ],
              )),
              _centered(_section(
                context,
                title: context.l10n.profile_section_preferences,
                rows: [
                  _row(
                    context,
                    icon: CupertinoIcons.bell_fill,
                    tint: brandRedDeepColor,
                    title: context.l10n.notification_title,
                    trailing: toggleButton(
                      context,
                      defaultEnabled: state.enableUserNotification,
                      onTap: (_) => notifier.onToggleUserNotificationChange(),
                    ),
                  ),
                  _row(
                    context,
                    icon: Icons.pets_rounded,
                    tint: context.colorScheme.warning,
                    title: context.l10n.mascot_setting_title,
                    subtitle: context.l10n.profile_mascot_subtitle,
                    trailing: toggleButton(
                      context,
                      defaultEnabled: ref.read(mascotEnabledPod),
                      onTap: (enabled) {
                        ref.read(mascotEnabledPod.notifier).state = enabled;
                        if (!enabled) {
                          ref.read(mascotProvider.notifier).hide();
                        }
                      },
                    ),
                  ),
                ],
              )),
              _centered(_section(
                context,
                title: context.l10n.profile_section_support,
                rows: [
                  _row(
                    context,
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    tint: context.colorScheme.info,
                    title: context.l10n.profile_setting_contact_support,
                    onTap: () => AppRoute.contactSupport.push(context),
                  ),
                  _row(
                    context,
                    icon: CupertinoIcons.star_fill,
                    tint: context.colorScheme.warning,
                    title: context.l10n.profile_setting_rate_us_title,
                    onTap: notifier.onRateUs,
                  ),
                  _row(
                    context,
                    icon: CupertinoIcons.square_arrow_up_fill,
                    tint: brandRedColor,
                    title: context.l10n.profile_setting_share_app_title,
                    onTap: () => notifier.onShareApp(context.l10n
                        .profile_setting_share_app_message(
                            playStoreLink, appStoreLink)),
                  ),
                ],
              )),
              _centered(_section(
                context,
                title: context.l10n.profile_section_about,
                rows: [
                  _row(
                    context,
                    icon: CupertinoIcons.hand_raised_fill,
                    tint: context.colorScheme.textSecondary,
                    title: context.l10n.profile_setting_privacy_policy_title,
                    onTap: () => notifier.openUrl(privacyPolicyUrl),
                  ),
                  _row(
                    context,
                    icon: CupertinoIcons.doc_text_fill,
                    tint: context.colorScheme.textSecondary,
                    title:
                        context.l10n.profile_setting_terms_and_condition_title,
                    onTap: () => notifier.openUrl(termsAndConditionsUrl),
                  ),
                ],
              )),
              _centered(_signOutButton(context)),
              _centered(_footer(context, state.appVersion)),
            ],
          );
        },
      ),
    );
  }

  Widget _centered(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: child,
        ),
      );

  // ── Header ───────────────────────────────────────────────────────────────

  Future<void> _openEditProfile(BuildContext context) async {
    final shouldChangeTabToMyCricket =
        await AppRoute.editProfile().push<bool>(context);
    if (context.mounted && shouldChangeTabToMyCricket == true) {
      widget.changeTabToMyCricket();
    }
  }

  Widget _header(BuildContext context, UserModel? user) {
    final phone = PhoneNumber.parse(
        ref.watch(currentUserPhoneProvider).valueOrNull ?? user?.phone);
    final chips = <(IconData, String)>[
      if (user?.player_role != null && user?.player_role != PlayerRole.none)
        (
          CupertinoIcons.sportscourt_fill,
          user!.player_role!.getString(context)
        ),
      if (user?.batting_style != null)
        (Icons.sports_cricket_rounded, user!.batting_style!.getString(context)),
      if (user?.location?.trim().isNotEmpty ?? false)
        (CupertinoIcons.location_solid, user!.location!.trim()),
    ];
    final progress = user?.progress ?? 0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandNavyCardColor, brandNavyColor],
        ),
        boxShadow: context.colorScheme.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: _glow(170, brandRedColor.withValues(alpha: 0.9)),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: _glow(160, Colors.white.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ImageAvatar(
                        size: 76,
                        imageUrl: user?.profile_img_url,
                        initial: user?.nameInitial ?? '?',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? context.l10n.common_anonymous_title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.header3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (phone != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.lock_fill,
                                    size: 12, color: textSecondaryDarkColor),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${phone.country.dial} ${phone.digits}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.body2.copyWith(
                                        color: textSecondaryDarkColor),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          _editButton(context),
                        ],
                      ),
                    ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (icon, label) in chips) _chip(icon, label),
                    ],
                  ),
                ],
                if (progress < 1) ...[
                  const SizedBox(height: 16),
                  _completeness(context, progress),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  Widget _editButton(BuildContext context) {
    return OnTapScale(
      onTap: () => _openEditProfile(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.pencil, size: 14, color: brandRedColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.l10n.profile_edit_button,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption.copyWith(
                  color: brandNavyColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completeness(BuildContext context, double progress) {
    final percent = (progress * 100).round();
    return OnTapScale(
      onTap: () => _openEditProfile(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.profile_complete_percent(percent),
                    style: AppTextStyle.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  context.l10n.profile_complete_finish,
                  style: AppTextStyle.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(CupertinoIcons.chevron_forward,
                    size: 12, color: Colors.white),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(brandRedColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notifications off ────────────────────────────────────────────────────

  Widget _notificationsOffCard(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cs.cardShadow,
      ),
      child: Row(
        children: [
          _iconTile(CupertinoIcons.bell_slash_fill, cs.warning, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.profile_notifications_off_title,
                  style: AppTextStyle.subtitle2.copyWith(
                    color: cs.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.profile_notifications_off_body,
                  style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OnTapScale(
            onTap: () => onRequestPermission(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                context.l10n.notification_turn_on_btn_title,
                style: AppTextStyle.caption.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grouped settings ─────────────────────────────────────────────────────

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> rows,
  }) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Text(
              title.toUpperCase(),
              style: AppTextStyle.caption.copyWith(
                color: cs.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: cs.cardShadow,
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 58,
                      color: cs.outline,
                    ),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconTile(IconData icon, Color color, {double size = 30}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Icon(icon, size: size * 0.56, color: Colors.white),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required Color tint,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final cs = context.colorScheme;
    final content = Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _iconTile(icon, tint),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style:
                        AppTextStyle.caption.copyWith(color: cs.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_forward,
                size: 15, color: cs.textDisabled),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }

  Widget _miniQr(BuildContext context, String userId) {
    return QrImageView(
      data: userId,
      size: 30,
      padding: EdgeInsets.zero,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: context.colorScheme.textPrimary,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: context.colorScheme.textPrimary,
      ),
    );
  }

  Widget _signOutButton(BuildContext context) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showConfirmationDialog(
            context,
            title: context.l10n.common_sign_out_title,
            message: context.l10n.alert_confirm_default_message(
                context.l10n.common_sign_out_title.toLowerCase()),
            confirmBtnText: context.l10n.common_sign_out_title,
            onConfirm: notifier.onSignOutTap,
          ),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Text(
              context.l10n.common_sign_out_title,
              style: AppTextStyle.subtitle2.copyWith(
                color: cs.alert,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, String? version) {
    final cs = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          SvgPicture.asset(Assets.images.appLogoMark, height: 28),
          if (version != null) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.profile_setting_app_version_text(version),
              style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
            ),
          ],
        ],
      ),
    );
  }

  void onRequestPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isPermanentlyDenied) {
      if (context.mounted) openAppSettings();
    } else {
      await Permission.notification.request();
    }
  }
}
