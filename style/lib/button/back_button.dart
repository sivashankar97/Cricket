import 'package:flutter/cupertino.dart';
import 'package:style/button/action_button.dart';
import 'package:style/extensions/context_extensions.dart';

/// iOS back button using the native chevron icon instead of a Material arrow.
Widget backButton(
  BuildContext context, {
  VoidCallback? onPressed,
}) {
  return actionButton(
    context,
    onPressed: onPressed,
    icon: Icon(
      CupertinoIcons.chevron_back,
      color: context.colorScheme.primary,
      size: 22,
    ),
  );
}
