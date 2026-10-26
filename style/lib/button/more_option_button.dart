import 'package:flutter/cupertino.dart';
import 'package:style/button/action_button.dart';
import 'package:style/extensions/context_extensions.dart';

/// iOS-style "more" button using the native ellipsis icon.
Widget moreOptionButton(
  BuildContext context, {
  Function()? onPressed,
  double size = 20,
  Color? tintColor,
  Color? backgroundColor,
}) {
  return actionButton(
    context,
    onPressed: onPressed,
    icon: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colorScheme.containerLowOnSurface,
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.ellipsis,
        size: size,
        color: tintColor ?? context.colorScheme.textSecondary,
      ),
    ),
  );
}
