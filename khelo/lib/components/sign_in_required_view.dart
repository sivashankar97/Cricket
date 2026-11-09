import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/empty_screen.dart';
import 'package:khelo/components/mascot/mascot_controller.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';

class SignInRequiredView extends ConsumerStatefulWidget {
  final String title;

  const SignInRequiredView({super.key, required this.title});

  @override
  ConsumerState<SignInRequiredView> createState() => _SignInRequiredViewState();
}

class _SignInRequiredViewState extends ConsumerState<SignInRequiredView> {
  bool _wasActive = false;

  /// Kept-alive tabs turn [TickerMode] off while hidden, so this fires each
  /// time the tab is opened.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (active && !_wasActive) {
      ref.read(mascotProvider.notifier).show(
            MascotPose.help,
            context.l10n.mascot_sign_in_required,
            delay: const Duration(milliseconds: 500),
          );
    }
    _wasActive = active;
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: widget.title,
      body: EmptyScreen(
        title: context.l10n.sign_in_required_title,
        description: context.l10n.sign_in_required_description,
        buttonTitle: context.l10n.sign_in_options_title,
        onTap: () => AppRoute.phoneLogin.push(context),
      ),
    );
  }
}
