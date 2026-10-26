import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/extensions/column_extensions.dart';
import 'package:style/text/app_text_style.dart';

import '../gen/assets.gen.dart';

/// Shows an iOS-style action sheet as a modal bottom sheet.
///
/// Top-radius 20pt, drag handle gutter, hairline separators between rows —
/// matching UIAlertController action sheet appearance.
Future<T?> showActionBottomSheet<T>({
  required BuildContext context,
  required List<BottomSheetAction> items,
  bool useRootNavigator = true,
  bool showDragHandle = true,
  double? heightFactor,
}) async {
  HapticFeedback.mediumImpact();
  return await showModalBottomSheet<T>(
    backgroundColor: context.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    showDragHandle: showDragHandle,
    useSafeArea: true,
    context: context,
    builder: (context) => FractionallySizedBox(
      heightFactor: heightFactor,
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            color: context.colorScheme.surface,
          ),
          padding: EdgeInsets.only(
            bottom: context.mediaQueryPadding.bottom,
          ),
          child: ColumnBuilder.separated(
            // iOS uses 0.5pt hairline separators, not full 1pt
            separatorBuilder: (index) => Container(
              height: 0.5,
              color: context.colorScheme.outline,
              margin: const EdgeInsets.only(left: 16),
            ),
            itemBuilder: (index) => items[index],
            itemCount: items.length,
            mainAxisSize: MainAxisSize.min,
          ),
        ),
      ),
    ),
  );
}

/// A single action row in an iOS action sheet.
class BottomSheetAction extends StatelessWidget {
  final Widget? icon;
  final String title;
  final Widget? child;
  final bool enabled;
  final String? subTitle;
  final bool showCheck;
  final VoidCallback? onTap;

  const BottomSheetAction({
    super.key,
    this.icon,
    required this.title,
    this.enabled = true,
    this.showCheck = false,
    this.child,
    this.subTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return OnTapScale(
      enabled: enabled,
      onTap: onTap,
      child: Padding(
        // iOS action rows: 16pt horizontal, 14pt vertical
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.body2.copyWith(
                      color: enabled ? cs.textPrimary : cs.textDisabled,
                    ),
                  ),
                  if (subTitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subTitle ?? '',
                      style: AppTextStyle.caption.copyWith(
                        color: cs.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showCheck)
              SvgPicture.asset(
                Assets.images.icCheck,
                colorFilter: ColorFilter.mode(
                  cs.primary,
                  BlendMode.srcATop,
                ),
              ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}
