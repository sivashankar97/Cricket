import 'package:flutter/cupertino.dart';
import 'package:style/platform.dart';
import 'package:flutter/material.dart';

/// iOS-style action button (bare icon, no background).
///
/// On iOS: [CupertinoButton] with no padding — native feel.
/// On Android: [IconButton] — Material compatible.
Widget actionButton(
  BuildContext context, {
  void Function()? onPressed,
  required Widget icon,
  EdgeInsets padding = EdgeInsets.zero,
  bool shrinkWrap = false,
}) {
  if (isIOS) {
    return CupertinoButton(onPressed: onPressed, padding: padding, child: icon);
  } else {
    return IconButton(
      onPressed: onPressed,
      icon: icon,
      padding: padding,
      style: ButtonStyle(
        tapTargetSize: shrinkWrap
            ? MaterialTapTargetSize.shrinkWrap
            : MaterialTapTargetSize.padded,
      ),
    );
  }
}
