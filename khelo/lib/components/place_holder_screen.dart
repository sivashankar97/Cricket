import 'package:flutter/cupertino.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

/// iOS-style placeholder / empty state screen with an illustration.
///
/// Image sits in a 120×120 container for consistent sizing.
/// Heading uses Title 2 weight; subtitle uses Body color.
class PlaceHolderScreen extends StatelessWidget {
  final Widget image;
  final String title;
  final String? message;
  final EdgeInsets padding;
  final String? actionBtnTitle;
  final Widget? messageWidget;
  final VoidCallback? onActionBtnTap;

  const PlaceHolderScreen({
    super.key,
    required this.image,
    required this.title,
    this.message,
    this.messageWidget,
    this.padding = const EdgeInsets.all(32),
    this.actionBtnTitle,
    this.onActionBtnTap,
  }) : assert(
          messageWidget != null || message != null,
          'Cannot provide both a message and a messageWidget',
        );

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Consistent illustration container
              SizedBox(
                height: 120,
                width: 120,
                child: image,
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: AppTextStyle.header3.copyWith(color: cs.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Description or custom widget
              messageWidget ??
                  Text(
                    message ?? '',
                    style: AppTextStyle.body2.copyWith(
                      color: cs.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
              if (actionBtnTitle != null) ...[
                const SizedBox(height: 32),
                PrimaryButton(
                  actionBtnTitle ?? '',
                  edgeInsets: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  expanded: false,
                  onPressed: onActionBtnTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
