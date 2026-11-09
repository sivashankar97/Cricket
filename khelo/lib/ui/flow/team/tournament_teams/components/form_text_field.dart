import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';

/// Inline error shown above a form's action button.
class FormErrorText extends StatelessWidget {
  final String message;

  const FormErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style:
            AppTextStyle.subtitle2.copyWith(color: context.colorScheme.alert),
      ),
    );
  }
}

/// Outlined text field used by the Tournament Teams forms.
class FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool autoFocus;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const FormTextField({
    super.key,
    required this.controller,
    required this.label,
    this.autoFocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      autoFocus: autoFocus,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      borderRadius: BorderRadius.circular(12),
      borderType: AppTextFieldBorderType.outline,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      style: AppTextStyle.subtitle3
          .copyWith(color: context.colorScheme.textPrimary),
      borderColor: BorderColor(
        focusColor: context.colorScheme.outline,
        unFocusColor: context.colorScheme.outline,
      ),
    );
  }
}
