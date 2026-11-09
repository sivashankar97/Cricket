import 'package:data/errors/app_error.dart';
import 'package:data/service/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/button/bottom_sticky_overlay.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';

class SignInWithEmailScreen extends ConsumerStatefulWidget {
  const SignInWithEmailScreen({super.key});

  @override
  ConsumerState<SignInWithEmailScreen> createState() =>
      _SignInWithEmailScreenState();
}

class _SignInWithEmailScreenState extends ConsumerState<SignInWithEmailScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _createAccount = false;
  bool _obscurePassword = true;
  bool _busy = false;
  bool _canSubmit = false;

  bool get _emailIsValid {
    final email = _emailController.text.trim();
    final at = email.indexOf('@');
    return at > 0 && email.indexOf('.', at) > at + 1 && !email.contains(' ');
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);
    _passwordController.addListener(_onChanged);
    _passwordFocus.addListener(_onPasswordFocus);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  MascotController get _mascot => ref.read(mascotProvider.notifier);

  bool _emailWasValid = false;

  void _onChanged() {
    final canSubmit = _emailIsValid && _passwordController.text.length >= 6;
    if (canSubmit != _canSubmit) setState(() => _canSubmit = canSubmit);

    final emailValid = _emailIsValid;
    if (emailValid && !_emailWasValid && !_passwordFocus.hasFocus) {
      _mascot.show(
        MascotPose.success,
        context.l10n.mascot_email_looks_good,
        delay: const Duration(milliseconds: 700),
        duration: const Duration(milliseconds: 2500),
      );
    }
    _emailWasValid = emailValid;
  }

  void _onPasswordFocus() {
    if (_passwordFocus.hasFocus && _obscurePassword) {
      _mascot.show(
        MascotPose.error,
        context.l10n.mascot_password_hidden,
        onceKey: 'password_peek',
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
    if (!_obscurePassword) {
      _mascot.show(
        MascotPose.search,
        context.l10n.mascot_password_shown,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _toggleCreateAccount() {
    setState(() => _createAccount = !_createAccount);
    if (_createAccount) {
      _mascot.show(MascotPose.welcome, context.l10n.mascot_email_new_account);
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
      _mascot.show(
        MascotPose.warning,
        context.l10n.mascot_wrong_password,
        duration: const Duration(seconds: 7),
      );
    } else if (code == 'email-already-in-use') {
      _mascot.show(MascotPose.thinking, context.l10n.mascot_email_in_use);
    } else {
      _mascot.show(MascotPose.error, context.l10n.mascot_something_wrong);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_canSubmit) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
            createAccount: _createAccount,
          );
      if (!mounted) return;
      _mascot.show(
        _createAccount ? MascotPose.registered : MascotPose.loginSuccess,
        _createAccount
            ? context.l10n.mascot_registered
            : context.l10n.mascot_login_success,
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
      _mascot.show(MascotPose.warning, context.l10n.mascot_enter_email_first);
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
        _mascot.show(MascotPose.notification, context.l10n.mascot_reset_sent);
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

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '',
      body: Stack(
        children: [
          ListView(
            padding: context.mediaQueryPadding +
                const EdgeInsets.symmetric(horizontal: 16) +
                BottomStickyOverlay.padding,
            children: [
              Text(
                _createAccount
                    ? context.l10n.sign_in_email_create_title
                    : context.l10n.sign_in_email_title,
                style: AppTextStyle.header1
                    .copyWith(color: context.colorScheme.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                _createAccount
                    ? context.l10n.sign_in_email_create_description
                    : context.l10n.sign_in_email_description,
                style: AppTextStyle.subtitle1
                    .copyWith(color: context.colorScheme.textDisabled),
              ),
              const SizedBox(height: 40),
              _field(
                context,
                controller: _emailController,
                hint: context.l10n.sign_in_email_placeholder,
                autoFocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _field(
                context,
                controller: _passwordController,
                focusNode: _passwordFocus,
                hint: context.l10n.sign_in_password_placeholder,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                  onPressed: _togglePasswordVisibility,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: context.colorScheme.textDisabled,
                  ),
                ),
              ),
              if (!_createAccount)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _forgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colorScheme.primary,
                    ),
                    child: Text(context.l10n.sign_in_forgot_password),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _toggleCreateAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: context.colorScheme.primary,
                  ),
                  child: Text(_createAccount
                      ? context.l10n.sign_in_email_switch_to_sign_in
                      : context.l10n.sign_in_email_switch_to_create),
                ),
              ),
            ],
          ),
          BottomStickyOverlay(
            child: PrimaryButton(
              _createAccount
                  ? context.l10n.sign_in_email_create_btn
                  : context.l10n.sign_in_email_sign_in_btn,
              enabled: !_busy && _canSubmit,
              progress: _busy,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    bool autoFocus = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    Widget? suffixIcon,
  }) {
    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      autoFocus: autoFocus,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      suffixIcon: suffixIcon,
      hintText: hint,
      style: AppTextStyle.header4
          .copyWith(color: context.colorScheme.textSecondary),
      hintStyle:
          AppTextStyle.header4.copyWith(color: context.colorScheme.outline),
      backgroundColor: context.colorScheme.containerLowOnSurface,
      borderRadius: BorderRadius.circular(12),
      borderType: AppTextFieldBorderType.outline,
      borderColor: BorderColor(
        focusColor: Colors.transparent,
        unFocusColor: Colors.transparent,
      ),
    );
  }
}
