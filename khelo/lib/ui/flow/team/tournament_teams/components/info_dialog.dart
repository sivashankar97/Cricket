import 'package:flutter/material.dart';
import 'package:khelo/components/confirmation_dialog.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';

/// Single-button informational dialog, e.g. when a delete is blocked.
void showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showAdaptiveDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        adaptiveAction(
          dialogContext,
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(context.l10n.common_okay_title),
        ),
      ],
    ),
  );
}
