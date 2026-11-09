import 'package:data/errors/app_error.dart';
import 'package:data/service/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/components/mascot/mascot_reactions.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/gen/assets.gen.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/app_animations.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';

/// Email sign in / create account, plus "Continue as guest" for Play.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  static const _minPasswordLength = 6;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _createAccount = false;
  bool _obscurePassword = true;
  bool _busy = false;
  bool _joiningAsGuest = false;
  bool _emailWasValid = false;

  bool get _emailIsValid {
    final email = _emailController.text.trim();
    final at = email.indexOf('@');
    return at > 0 && email.indexOf('.', at) > at + 1 && !email.contains(' ');
  }

  bool get _passwordIsLongEnough =>
      _passwordController.text.length >= SignInScreen._minPasswordLength;

  bool get _canSubmit => _emailIsValid && _passwordIsLongEnough;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(() => setState(() {}));
    _passwordFocus.addListener(_onPasswordFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _say(
        MascotPose.help,
        mascotText.mascot_sign_in_options,
        delay: const Duration(milliseconds: 600),
        onlyWhenIdle: true,
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _say(
    MascotPose pose,
    String message, {
    Duration? duration,
    Duration delay = Duration.zero,
    String? onceKey,
    bool onlyWhenIdle = false,
  }) {
    ref.read(mascotProvider.notifier).show(
          pose,
          message,
          duration: duration,
          delay: delay,
          onceKey: onceKey,
          onlyWhenIdle: onlyWhenIdle,
          top: true,
          allowFun: false,
        );
  }

  void _onEmailChanged() {
    setState(() {});
    final emailValid = _emailIsValid;
    if (emailValid && !_emailWasValid && !_passwordFocus.hasFocus) {
      _say(
        MascotPose.success,
        mascotText.mascot_email_looks_good,
        delay: const Duration(milliseconds: 700),
        duration: const Duration(milliseconds: 2500),
      );
    }
    _emailWasValid = emailValid;
  }

  void _onPasswordFocus() {
    if (_passwordFocus.hasFocus && _obscurePassword) {
      _say(
        MascotPose.error,
        mascotText.mascot_password_hidden,
        onceKey: 'password_peek',
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
    if (!_obscurePassword) {
      _say(
        MascotPose.search,
        mascotText.mascot_password_shown,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _setCreateAccount(bool createAccount) {
    if (_busy || createAccount == _createAccount) return;
    setState(() => _createAccount = createAccount);
    if (createAccount) {
      _say(MascotPose.welcome, mascotText.mascot_email_new_account);
    }
  }

  void _reactToError(Object error) {
    final code = error is AppError ? error.statusCode : null;
    if (const [
      'wrong-password',
      'invalid-credential',
      'invalid-login-credentials',
      'user-not-found',
    ].contains(code)) {
      _say(
        MascotPose.warning,
        mascotText.mascot_wrong_password,
        duration: const Duration(seconds: 7),
      );
    } else if (code == 'email-already-in-use') {
      _say(MascotPose.thinking, mascotText.mascot_email_in_use);
    } else {
      _say(MascotPose.error, mascotText.mascot_something_wrong);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_canSubmit) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
            createAccount: _createAccount,
          );
      if (!mounted) return;
      ref.read(mascotProvider.notifier).show(
            _createAccount ? MascotPose.registered : MascotPose.loginSuccess,
            _createAccount
                ? mascotText.mascot_registered
                : mascotText.mascot_login_success,
            allowFun: false,
          );
      AppRoute.main.go(context);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorSnackBar(context: context, error: error);
        _reactToError(error);
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (_busy) return;
    if (!_emailIsValid) {
      showSnackBar(context, context.l10n.sign_in_reset_enter_email);
      _say(MascotPose.warning, mascotText.mascot_enter_email_first);
      return;
    }
    setState(() => _busy = true);
    try {
      final email = _emailController.text.trim();
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        showSnackBar(
          context,
          context.l10n.sign_in_reset_email_sent(email),
          length: SnackBarLength.long,
        );
        _say(MascotPose.notification, mascotText.mascot_reset_sent);
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context: context, error: error);
        _reactToError(error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _joiningAsGuest = true);
    try {
      await ref.read(authServiceProvider).signInAsGuest();
      if (!mounted) return;
      ref.read(mascotProvider.notifier).show(
            MascotPose.celebrate,
            mascotText.mascot_guest_joined,
            duration: const Duration(seconds: 5),
          );
      context.canPop() ? context.pop() : AppRoute.main.go(context);
    } catch (error) {
      if (mounted) {
        setState(() => _joiningAsGuest = false);
        _say(MascotPose.error, mascotText.mascot_something_wrong);
        showErrorSnackBar(context: context, error: error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final showGuest = ref.watch(guestUserIdProvider).valueOrNull == null;

    return AppPage(
      title: '',
      body: ListView(
        padding: context.mediaQueryPadding +
            const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SvgPicture.asset(
                        Assets.images.appLogoWordmark,
                        height: 36,
                        theme: SvgTheme(currentColor: cs.textPrimary),
                        semanticsLabel: 'Sports Tamil',
                      ),
                    ),
                    const SizedBox(height: 28),
                    _header(context),
                    const SizedBox(height: 24),
                    _ModeSwitch(
                      createAccount: _createAccount,
                      onChanged: _setCreateAccount,
                    ),
                    const SizedBox(height: 24),
                    _form(context),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      _createAccount
                          ? context.l10n.sign_in_email_create_btn
                          : context.l10n.sign_in_email_sign_in_btn,
                      enabled: !_busy && _canSubmit,
                      progress: _busy,
                      onPressed: _submit,
                    ),
                    if (showGuest) ...[
                      const SizedBox(height: 28),
                      _guest(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final cs = context.colorScheme;
    return AnimatedSwitcher(
      duration: AppAnimations.normal,
      child: Column(
        key: ValueKey(_createAccount),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              _createAccount
                  ? context.l10n.sign_in_email_create_title
                  : context.l10n.sign_in_email_title,
              style: AppTextStyle.header1.copyWith(color: cs.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _createAccount
                ? context.l10n.sign_in_email_create_description
                : context.l10n.sign_in_email_description,
            style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    final cs = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          context,
          label: context.l10n.sign_in_email_label,
          controller: _emailController,
          hint: context.l10n.sign_in_email_placeholder,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 16),
        _field(
          context,
          label: context.l10n.sign_in_password_label,
          controller: _passwordController,
          focusNode: _passwordFocus,
          hint: _createAccount
              ? context.l10n.sign_in_password_create_placeholder
              : context.l10n.sign_in_password_placeholder,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          autofillHints: [
            _createAccount ? AutofillHints.newPassword : AutofillHints.password
          ],
          suffixIcon: IconButton(
            onPressed: _togglePasswordVisibility,
            tooltip: _obscurePassword
                ? context.l10n.sign_in_show_password
                : context.l10n.sign_in_hide_password,
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: cs.textDisabled,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_createAccount)
          _PasswordRule(
            text: context.l10n.sign_in_password_rule,
            met: _passwordIsLongEnough,
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _forgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(
                context.l10n.sign_in_forgot_password,
                style: AppTextStyle.subtitle2.copyWith(color: cs.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _field(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    Iterable<String>? autofillHints,
    Widget? suffixIcon,
  }) {
    final cs = context.colorScheme;
    return AppTextField(
      label: label,
      labelStyle: AppTextStyle.subtitle2
          .copyWith(color: cs.textPrimary, fontWeight: FontWeight.w600),
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      suffixIcon: suffixIcon,
      enabled: !_busy,
      hintText: hint,
      style: AppTextStyle.subtitle3.copyWith(color: cs.textPrimary),
      hintStyle: AppTextStyle.subtitle3.copyWith(color: cs.textDisabled),
      backgroundColor: cs.containerLow,
      borderRadius: BorderRadius.circular(12),
      borderType: AppTextFieldBorderType.outline,
      borderWidth: 1.5,
      borderColor: BorderColor(
        focusColor: cs.primary,
        unFocusColor: Colors.transparent,
      ),
    );
  }

  Widget _guest(BuildContext context) {
    final cs = context.colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: cs.outline, height: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                context.l10n.sign_in_or,
                style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
              ),
            ),
            Expanded(child: Divider(color: cs.outline, height: 1)),
          ],
        ),
        const SizedBox(height: 12),
        _joiningAsGuest
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: AppProgressIndicator(
                  size: AppProgressIndicatorSize.small,
                ),
              )
            : TextButton(
                onPressed: _busy ? null : _continueAsGuest,
                style: TextButton.styleFrom(foregroundColor: cs.primary),
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
}

/// Two-segment "Sign in | Create account" switch, styled like the app's tabs.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.createAccount, required this.onChanged});

  final bool createAccount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Semantics(
      label: context.l10n.sign_in_mode_label,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.containerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            _segment(context, context.l10n.sign_in_email_sign_in_btn, false),
            _segment(context, context.l10n.sign_in_email_create_btn, true),
          ],
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, String text, bool value) {
    final cs = context.colorScheme;
    final selected = createAccount == value;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: OnTapScale(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            curve: AppAnimations.curve,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: AppTextStyle.subtitle2.copyWith(
                color: selected ? cs.onPrimary : cs.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  const _PasswordRule({required this.text, required this.met});

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final color = met ? cs.positive : cs.textSecondary;
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyle.caption.copyWith(color: color)),
      ],
    );
  }
}
