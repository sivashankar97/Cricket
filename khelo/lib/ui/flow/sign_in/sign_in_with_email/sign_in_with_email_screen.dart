import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/button/bottom_sticky_overlay.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignInWithEmailScreen extends StatefulWidget {
  const SignInWithEmailScreen({super.key});

  @override
  State<SignInWithEmailScreen> createState() => _SignInWithEmailScreenState();
}

class _SignInWithEmailScreenState extends State<SignInWithEmailScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  bool get _emailIsValid {
    final email = _emailController.text.trim();
    final at = email.indexOf('@');
    return at > 0 && email.indexOf('.', at) > at + 1 && !email.contains(' ');
  }

  bool get _codeIsValid => _codeController.text.trim().length == 6;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_busy || !_emailIsValid) return;
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _emailController.text.trim(),
        shouldCreateUser: true,
      );
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _codeController.clear();
      });
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context: context,
          error: error is AuthException ? error.message : error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_busy || !_codeIsValid) return;
    setState(() => _busy = true);
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.email,
        email: _emailController.text.trim(),
        token: _codeController.text.trim(),
      );
      if (response.session == null || response.user == null) {
        throw const AuthException('The code could not be verified. Try again.');
      }
      if (mounted) {
        showSnackBar(
          context,
          context.l10n.sign_in_email_bridge_pending,
          length: SnackBarLength.long,
        );
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context: context,
          error: error is AuthException ? error.message : error,
        );
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
                _codeSent
                    ? context.l10n.sign_in_email_code_title
                    : context.l10n.sign_in_email_title,
                style: AppTextStyle.header1
                    .copyWith(color: context.colorScheme.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                _codeSent
                    ? context.l10n.sign_in_email_code_description(
                        _emailController.text.trim())
                    : context.l10n.sign_in_email_description,
                style: AppTextStyle.subtitle1
                    .copyWith(color: context.colorScheme.textDisabled),
              ),
              const SizedBox(height: 40),
              if (!_codeSent)
                AppTextField(
                  controller: _emailController,
                  autoFocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  hintText: context.l10n.sign_in_email_placeholder,
                  style: AppTextStyle.header4
                      .copyWith(color: context.colorScheme.textSecondary),
                  hintStyle: AppTextStyle.header4
                      .copyWith(color: context.colorScheme.outline),
                  backgroundColor: context.colorScheme.containerLowOnSurface,
                  borderRadius: BorderRadius.circular(12),
                  borderType: AppTextFieldBorderType.outline,
                  borderColor: BorderColor(
                    focusColor: Colors.transparent,
                    unFocusColor: Colors.transparent,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _emailIsValid ? _sendCode() : null,
                )
              else
                AppTextField(
                  controller: _codeController,
                  autoFocus: true,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  hintText: context.l10n.sign_in_email_code_placeholder,
                  style: AppTextStyle.header2.copyWith(
                    color: context.colorScheme.textSecondary,
                    letterSpacing: 16,
                  ),
                  hintStyle: AppTextStyle.header2
                      .copyWith(color: context.colorScheme.outline),
                  backgroundColor: context.colorScheme.containerLowOnSurface,
                  borderRadius: BorderRadius.circular(12),
                  borderType: AppTextFieldBorderType.outline,
                  borderColor: BorderColor(
                    focusColor: Colors.transparent,
                    unFocusColor: Colors.transparent,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _codeIsValid ? _verifyCode() : null,
                ),
              if (_codeSent) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _codeSent = false;
                              _codeController.clear();
                            }),
                    style: TextButton.styleFrom(
                      foregroundColor: context.colorScheme.primary,
                    ),
                    child: Text(context.l10n.sign_in_change_email),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _busy ? null : _sendCode,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colorScheme.primary,
                    ),
                    child: Text(context.l10n.sign_in_resend_code),
                  ),
                ),
              ],
            ],
          ),
          BottomStickyOverlay(
            child: PrimaryButton(
              _codeSent
                  ? context.l10n.sign_in_verify_code
                  : context.l10n.sign_in_send_code,
              enabled: !_busy && (_codeSent ? _codeIsValid : _emailIsValid),
              progress: _busy,
              onPressed: _codeSent ? _verifyCode : _sendCode,
            ),
          ),
        ],
      ),
    );
  }
}
