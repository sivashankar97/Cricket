import 'package:data/storage/app_preferences.dart';
import 'package:data/service/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/country_code_view.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/sign_in/sign_in_with_phone/sign_in_with_phone_view_model.dart';
import 'package:style/button/bottom_sticky_overlay.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';

class SignInWithPhoneScreen extends ConsumerWidget {
  const SignInWithPhoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(signInWithPhoneStateProvider.notifier);
    final state = ref.watch(signInWithPhoneStateProvider);

    _observeActionError(context, ref);
    _observeOtp(context: context, ref: ref);
    _observeSignInSuccess(context: context, ref: ref);

    return AppPage(
      title: "",
      body: Builder(builder: (context) {
        return Stack(
          children: [
            ListView(
              padding: context.mediaQueryPadding +
                  const EdgeInsets.symmetric(horizontal: 16) +
                  BottomStickyOverlay.padding,
              children: [
                Text(
                  context.l10n.sign_in_verify_phone_number_title,
                  style: AppTextStyle.header1
                      .copyWith(color: context.colorScheme.textPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.sign_in_verify_phone_number_description,
                  style: AppTextStyle.subtitle1
                      .copyWith(color: context.colorScheme.textDisabled),
                ),
                _phoneInputField(context, notifier, state),
                const SizedBox(height: 32),
                _dividerWithText(context),
                const SizedBox(height: 16),
                _googleSignInButton(context, ref),
                const SizedBox(height: 12),
                _emailSignInButton(context, ref),
              ],
            ),
            BottomStickyOverlay(
              child: PrimaryButton(
                context.l10n.sign_in_get_otp_btn_text,
                enabled: state.enableBtn && !state.verifying,
                progress: state.verifying,
                onPressed: notifier.verifyPhoneNumber,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _phoneInputField(
    BuildContext context,
    SignInWithPhoneViewNotifier notifier,
    SignInWithPhoneState state,
  ) {
    return MediaQuery.withNoTextScaling(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CountryCodeView(
              countryCode: state.code,
              onCodeChange: notifier.changeCountryCode,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppTextField(
                controller: state.phoneController,
                autoFocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: AppTextStyle.header2.copyWith(
                  color: context.colorScheme.textSecondary,
                ),
                hintStyle: AppTextStyle.header2.copyWith(
                  color: context.colorScheme.outline,
                ),
                hintText: context.l10n.sign_in_phone_number_placeholder,
                backgroundColor: context.colorScheme.containerLowOnSurface,
                borderRadius: BorderRadius.circular(40),
                borderType: AppTextFieldBorderType.outline,
                borderColor: BorderColor(
                    focusColor: Colors.transparent,
                    unFocusColor: Colors.transparent),
                prefixIcon: _inputFieldPrefix(context, state),
                prefixIconConstraints: const BoxConstraints.tightFor(),
                onChanged: (phone) => notifier.onPhoneChange(phone),
                onSubmitted: (value) => (!state.verifying && state.enableBtn)
                    ? notifier.verifyPhoneNumber()
                    : null,
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputFieldPrefix(
    BuildContext context,
    SignInWithPhoneState state,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.code.dialCode,
              style: AppTextStyle.header2
                  .copyWith(color: context.colorScheme.textPrimary),
            ),
            VerticalDivider(
              width: 24,
              color: context.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dividerWithText(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: context.colorScheme.outline,
            thickness: 0.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or',
            style: AppTextStyle.subtitle2
                .copyWith(color: context.colorScheme.textDisabled),
          ),
        ),
        Expanded(
          child: Divider(
            color: context.colorScheme.outline,
            thickness: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _googleSignInButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleGoogleSignIn(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: context.colorScheme.outline),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.g_mobiledata,
              size: 20,
              color: context.colorScheme.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'Continue with Google',
              style: AppTextStyle.subtitle1
                  .copyWith(color: context.colorScheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailSignInButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleEmailSignIn(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: context.colorScheme.outline),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 20,
              color: context.colorScheme.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'Continue with Email',
              style: AppTextStyle.subtitle1
                  .copyWith(color: context.colorScheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (context.mounted) {
        onSignInSuccess(context, ref);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(
          context: context,
          error: e,
        );
      }
    }
  }

  void _handleEmailSignIn(BuildContext context, WidgetRef ref) {
    // Navigate to email login screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _EmailLoginSheet(
        onSignInSuccess: (isSuccess) async {
          if (isSuccess && context.mounted) {
            Navigator.of(sheetContext).pop();
            await Future.delayed(const Duration(milliseconds: 300));
            onSignInSuccess(context, ref);
          }
        },
      ),
    );
  }

  void onSignInSuccess(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserPod);
    if (user?.name == null || user!.name!.trim().isEmpty) {
      AppRoute.editProfile(isToCreateAccount: true).go(context);
    } else {
      AppRoute.main.go(context);
    }
  }

  void _observeActionError(BuildContext context, WidgetRef ref) {
    ref.listen(
        signInWithPhoneStateProvider.select((value) => value.actionError),
        (previous, next) {
      if (next != null) {
        showErrorSnackBar(context: context, error: next);
      }
    });
  }

  void _observeOtp({required BuildContext context, required WidgetRef ref}) {
    ref.listen(
      signInWithPhoneStateProvider.select((value) => value.verificationId),
      (previous, current) async {
        if (current != null) {
          final state = ref.watch(signInWithPhoneStateProvider);
          final bool? success = await AppRoute.verifyOTP(
            countryCode: state.code.dialCode,
            phoneNumber: state.phone,
            verificationId: current,
          ).push<bool>(context);
          if (success != null && success && context.mounted) {
            onSignInSuccess(context, ref);
          }
        }
      },
    );
  }

  void _observeSignInSuccess({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    ref.listen(
      signInWithPhoneStateProvider.select((value) => value.signInSuccess),
      (previous, current) async {
        if (current && context.mounted) onSignInSuccess(context, ref);
      },
    );
  }
}

class _EmailLoginSheet extends ConsumerStatefulWidget {
  final Function(bool) onSignInSuccess;

  const _EmailLoginSheet({required this.onSignInSuccess});

  @override
  ConsumerState<_EmailLoginSheet> createState() => _EmailLoginSheetState();
}

class _EmailLoginSheetState extends ConsumerState<_EmailLoginSheet> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSignUp ? 'Create Account' : 'Sign In with Email',
              style: AppTextStyle.header1
                  .copyWith(color: context.colorScheme.textPrimary),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              hintText: 'Email',
              backgroundColor: context.colorScheme.containerLowOnSurface,
              borderRadius: BorderRadius.circular(40),
              borderType: AppTextFieldBorderType.outline,
              borderColor: BorderColor(
                focusColor: Colors.transparent,
                unFocusColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              hintText: 'Password',
              backgroundColor: context.colorScheme.containerLowOnSurface,
              borderRadius: BorderRadius.circular(40),
              borderType: AppTextFieldBorderType.outline,
              borderColor: BorderColor(
                focusColor: Colors.transparent,
                unFocusColor: Colors.transparent,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: AppTextStyle.subtitle2
                    .copyWith(color: context.colorScheme.textPrimary),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                _isSignUp ? 'Sign Up' : 'Sign In',
                enabled: !_isLoading,
                progress: _isLoading,
                onPressed: _handleEmailAuth,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                  _errorMessage = null;
                });
              },
              child: Center(
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Sign Up',
                  style: AppTextStyle.subtitle2
                      .copyWith(color: context.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _handleEmailAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      if (_isSignUp) {
        await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      widget.onSignInSuccess(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
