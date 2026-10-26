import 'package:flutter/cupertino.dart';
import 'package:style/extensions/context_extensions.dart';

/// iOS-style sheet drag handle — 36×4pt rounded pill, systemGray4 color.
/// Matches exactly what UIKit renders for [UISheetPresentationController].
Widget dragHandle(BuildContext context) {
  return Align(
    alignment: Alignment.topCenter,
    child: Container(
      height: 4,
      width: 36,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.colorScheme.textDisabled,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
