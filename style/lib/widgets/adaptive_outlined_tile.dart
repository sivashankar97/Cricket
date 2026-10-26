import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

/// iOS-style grouped list row (like a Settings row).
///
/// Rounded filled container, disclosure chevron for navigation rows.
/// Uses [CupertinoIcons.chevron_right] as trailing icon matching iOS pattern.
class AdaptiveOutlinedTile extends StatelessWidget {
  final String? headerText;
  final String? headerImage;
  final String? title;
  final int? maxLines;
  final String placeholder;
  final bool showTrailingIcon;
  final bool enabled;
  final String? iconImage;
  final Function()? onTap;

  const AdaptiveOutlinedTile({
    super.key,
    this.headerText,
    this.headerImage,
    this.title,
    this.maxLines,
    required this.placeholder,
    this.enabled = true,
    this.showTrailingIcon = false,
    this.iconImage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // iOS form section header — small caps / caption above the row
        if (headerText != null) ...[
          Row(
            children: [
              if (headerImage != null) ...[
                SvgPicture.asset(
                  headerImage!,
                  colorFilter: ColorFilter.mode(
                    cs.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                headerText!.toUpperCase(),
                style: AppTextStyle.caption.copyWith(
                  color: cs.textSecondary,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        OnTapScale(
          onTap: onTap,
          enabled: enabled,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              // iOS: grouped row background is white on systemGroupedBackground
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title ?? placeholder,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.subtitle3.copyWith(
                      color: title != null ? cs.textPrimary : cs.textDisabled,
                    ),
                  ),
                ),
                if (showTrailingIcon && enabled) ...[
                  const SizedBox(width: 8),
                  // iOS uses the chevron.right for disclosure rows
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: cs.textDisabled,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
