import 'package:flutter/material.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/button/bottom_sticky_overlay.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

class SignInOptionsScreen extends StatelessWidget {
  const SignInOptionsScreen({super.key});

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
                context.l10n.sign_in_options_title,
                style: AppTextStyle.header1
                    .copyWith(color: context.colorScheme.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.sign_in_options_description,
                style: AppTextStyle.subtitle1
                    .copyWith(color: context.colorScheme.textDisabled),
              ),
            ],
          ),
          BottomStickyOverlay(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  context.l10n.sign_in_email_option,
                  onPressed: () => AppRoute.emailLogin.push(context),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(context.l10n.sign_in_whatsapp_option),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.sign_in_whatsapp_unavailable,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.caption.copyWith(
                    color: context.colorScheme.textDisabled,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
