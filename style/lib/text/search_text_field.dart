import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_field.dart';

import 'app_text_style.dart';

/// iOS-native search bar using [CupertinoSearchTextField] styling.
///
/// Gray rounded fill, magnifier prefix, no border at rest — exactly
/// matching the iOS system search bar appearance.
class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function() onChange;
  final Widget? suffixIcon;

  const SearchTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChange,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return AppTextField(
      controller: controller,
      borderRadius: BorderRadius.circular(10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderType: AppTextFieldBorderType.outline,
      onChanged: (value) => onChange(),
      // iOS search bar fill: systemGray5 equivalent
      backgroundColor: cs.containerLowOnSurface,
      hintText: hintText,
      style: AppTextStyle.subtitle3.copyWith(
        color: cs.textPrimary,
      ),
      hintStyle: AppTextStyle.subtitle3.copyWith(
        color: cs.textDisabled,
      ),
      borderColor: BorderColor(
        focusColor: Colors.transparent,
        unFocusColor: Colors.transparent,
      ),
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      prefixIcon: Icon(
        CupertinoIcons.search,
        color: cs.textDisabled,
        size: 20,
      ),
      suffixIcon: suffixIcon,
    );
  }
}
