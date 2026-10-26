import 'package:flutter/material.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/empty_screen.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';

class SignInRequiredView extends StatelessWidget {
  final String title;

  const SignInRequiredView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: title,
      body: EmptyScreen(
        title: context.l10n.sign_in_required_title,
        description: context.l10n.sign_in_required_description,
        buttonTitle: context.l10n.sign_in_options_title,
        onTap: () => AppRoute.phoneLogin.push(context),
      ),
    );
  }
}
