import 'package:data/service/auth/auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/button/bottom_sticky_overlay.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';
import 'package:url_launcher/url_launcher.dart';

import 'whatsapp_login.dart';

class SignInOptionsScreen extends ConsumerStatefulWidget {
  const SignInOptionsScreen({super.key});

  @override
  ConsumerState<SignInOptionsScreen> createState() =>
      _SignInOptionsScreenState();
}

class _SignInOptionsScreenState extends ConsumerState<SignInOptionsScreen> {
  bool _hasOpenedWhatsApp = false;
  bool _isVerifyingToken = false;
  bool _isJoiningAsGuest = false;
  final TextEditingController _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(mascotProvider.notifier).show(
            MascotPose.help,
            context.l10n.mascot_sign_in_options,
            delay: const Duration(milliseconds: 600),
            onlyWhenIdle: true,
            lift: MascotController.signInOptionsLift,
          );
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final encodedMessage = Uri.encodeComponent(kWhatsAppPrefillMessage);
    final whatsappUrl =
        Uri.parse('https://wa.me/$kWhatsAppLoginNumber?text=$encodedMessage');

    try {
      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback to direct web URL
        await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
      }

      if (mounted) {
        setState(() {
          _hasOpenedWhatsApp = true;
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context: context,
          error:
              'Could not open WhatsApp. Please check if WhatsApp is installed.',
        );
      }
    }
  }

  Future<void> _verifyManualInput() async {
    final input = _tokenController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isVerifyingToken = true);

    try {
      await signInWithWhatsAppCode(context, ref, whatsAppCodeFromInput(input));
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifyingToken = false);
        showErrorSnackBar(context: context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return AppPage(
      title: '',
      body: Stack(
        children: [
          ListView(
            padding: context.mediaQueryPadding +
                const EdgeInsets.symmetric(horizontal: 20) +
                BottomStickyOverlay.padding,
            children: [
              const SizedBox(height: 12),
              Text(
                context.l10n.sign_in_options_title,
                style: AppTextStyle.header1.copyWith(color: cs.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.sign_in_options_description,
                style: AppTextStyle.subtitle1.copyWith(color: cs.textDisabled),
              ),
              const SizedBox(height: 24),
              if (_hasOpenedWhatsApp) ...[
                _whatsAppConfirmationCard(context),
              ],
            ],
          ),
          BottomStickyOverlay(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _whatsAppButton(context),
                const SizedBox(height: 12),
                PrimaryButton(
                  context.l10n.sign_in_email_option,
                  background: cs.containerLow,
                  foreground: cs.textPrimary,
                  onPressed: () => AppRoute.emailLogin.push(context),
                ),
                if (ref.watch(guestUserIdProvider).valueOrNull == null) ...[
                  const SizedBox(height: 4),
                  _guestButton(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isJoiningAsGuest = true);
    try {
      await ref.read(authServiceProvider).signInAsGuest();
      if (!mounted) return;
      ref.read(mascotProvider.notifier).show(
            MascotPose.celebrate,
            context.l10n.mascot_guest_joined,
            duration: const Duration(seconds: 5),
          );
      context.canPop() ? context.pop() : AppRoute.main.go(context);
    } catch (e) {
      if (mounted) {
        ref.read(mascotProvider.notifier).show(
              MascotPose.error,
              context.l10n.mascot_something_wrong,
              lift: MascotController.signInOptionsLift,
            );
        setState(() => _isJoiningAsGuest = false);
        showErrorSnackBar(context: context, error: e);
      }
    }
  }

  Widget _guestButton(BuildContext context) {
    final cs = context.colorScheme;
    return Column(
      children: [
        _isJoiningAsGuest
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: AppProgressIndicator(
                  size: AppProgressIndicatorSize.small,
                ),
              )
            : TextButton(
                onPressed: _continueAsGuest,
                child: Text(
                  context.l10n.sign_in_guest_option,
                  style: AppTextStyle.button.copyWith(color: cs.primary),
                ),
              ),
        Text(
          context.l10n.sign_in_guest_hint,
          textAlign: TextAlign.center,
          style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
        ),
      ],
    );
  }

  Widget _whatsAppButton(BuildContext context) {
    const whatsAppColor = Color(0xFF25D366);

    return OnTapScale(
      onTap: _openWhatsApp,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: whatsAppColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.chat_bubble_fill,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              context.l10n.sign_in_whatsapp_option,
              style: AppTextStyle.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whatsAppConfirmationCard(BuildContext context) {
    final cs = context.colorScheme;
    const whatsAppColor = Color(0xFF25D366);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: whatsAppColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: whatsAppColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.chat_bubble_fill,
                  color: whatsAppColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.sign_in_whatsapp_opened_title,
                      style: AppTextStyle.subtitle2.copyWith(
                        color: cs.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Sent to $kWhatsAppDisplayNumber',
                      style: AppTextStyle.caption
                          .copyWith(color: cs.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.sign_in_whatsapp_opened_desc,
            style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _tokenController,
                  hintText:
                      context.l10n.sign_in_whatsapp_enter_link_placeholder,
                ),
              ),
              const SizedBox(width: 8),
              if (_isVerifyingToken)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: AppProgressIndicator(
                      size: AppProgressIndicatorSize.small),
                )
              else
                IconButton(
                  onPressed: _verifyManualInput,
                  icon: Icon(Icons.arrow_forward_rounded, color: cs.primary),
                  tooltip: context.l10n.sign_in_whatsapp_submit_token_btn,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _openWhatsApp,
              child: Text(
                context.l10n.sign_in_whatsapp_open_again_btn,
                style: AppTextStyle.caption.copyWith(color: cs.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
