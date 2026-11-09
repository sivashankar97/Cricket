import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_style.dart';

import 'whatsapp_login.dart';

class WhatsAppLoginRedirectScreen extends ConsumerStatefulWidget {
  final String? code;

  const WhatsAppLoginRedirectScreen({super.key, this.code});

  @override
  ConsumerState<WhatsAppLoginRedirectScreen> createState() =>
      _WhatsAppLoginRedirectScreenState();
}

class _WhatsAppLoginRedirectScreenState
    extends ConsumerState<WhatsAppLoginRedirectScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleLogin());
  }

  Future<void> _handleLogin() async {
    final code = widget.code;
    if (code == null || code.isEmpty) {
      setState(() => _error = 'This login link is incomplete.');
      return;
    }
    try {
      await signInWithWhatsAppCode(context, ref, code);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        showErrorSnackBar(context: context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return AppPage(
      title: 'WhatsApp Login',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error == null) ...[
                const AppProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Authenticating via WhatsApp...',
                  style: AppTextStyle.subtitle1.copyWith(color: cs.textPrimary),
                ),
              ] else ...[
                Icon(Icons.error_outline, size: 48, color: cs.alert),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTextStyle.body1.copyWith(color: cs.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => AppRoute.phoneLogin.go(context),
                  child: const Text('Back to Sign In'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
