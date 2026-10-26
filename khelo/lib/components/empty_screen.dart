import 'package:flutter/cupertino.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

/// iOS-style empty state screen.
///
/// Matches the iOS HIG empty state pattern: centered layout, large title,
/// secondary description, optional CTA button.
class EmptyScreen extends StatelessWidget {
  final String title;
  final String description;
  final bool isShowButton;
  final String? buttonTitle;
  final VoidCallback? onTap;

  const EmptyScreen({
    super.key,
    required this.title,
    required this.description,
    this.isShowButton = true,
    this.buttonTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: AppTextStyle.header3.copyWith(color: cs.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (isShowButton) ...[
                const SizedBox(height: 28),
                PrimaryButton(
                  buttonTitle ?? '',
                  edgeInsets: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  expanded: false,
                  onPressed: onTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
