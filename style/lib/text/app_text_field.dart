import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../extensions/context_extensions.dart';
import 'app_text_style.dart';

/// iOS HIG–style text field.
///
/// Default border type is now [AppTextFieldBorderType.outline] with a rounded
/// gray fill (like iOS grouped row inputs). The underline style is retained for
/// backward compat but is rarely used in iOS-first designs.
class AppTextField extends StatelessWidget {
  final String? label;
  final TextStyle? labelStyle;
  final TextEditingController? controller;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextStyle? style;
  final Color? backgroundColor;
  final bool expands;
  final bool enabled;
  final Widget? suffixIcon;
  final BorderRadius? borderRadius;
  final AppTextFieldBorderType borderType;
  final BorderColor? borderColor;
  final double borderWidth;
  final TextInputAction? textInputAction;
  final String? hintText;
  final String? errorText;
  final bool? isDense;
  final EdgeInsetsGeometry? contentPadding;
  final bool? isCollapsed;
  final TextStyle? hintStyle;
  final TextStyle? errorStyle;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool autoFocus;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final TextAlign textAlign;
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Function(PointerDownEvent)? onTapOutside;

  const AppTextField({
    super.key,
    this.label,
    this.labelStyle,
    this.controller,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.style,
    this.backgroundColor,
    this.expands = false,
    this.enabled = true,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    // iOS default: rounded outline with filled gray background
    this.borderType = AppTextFieldBorderType.outline,
    this.borderColor,
    this.borderWidth = 0,
    this.textInputAction,
    this.borderRadius,
    this.hintText,
    this.hintStyle,
    this.errorText,
    this.errorStyle,
    this.contentPadding,
    this.isDense,
    this.isCollapsed,
    this.autoFocus = false,
    this.obscureText = false,
    this.keyboardType,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.textAlign = TextAlign.start,
    this.onTapOutside,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    if (label == null) {
      return _textField(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: labelStyle ??
              AppTextStyle.caption.copyWith(
                color: cs.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
        if (borderType == AppTextFieldBorderType.outline)
          const SizedBox(height: 6),
        _textField(context),
      ],
    );
  }

  Widget _textField(BuildContext context) {
    final cs = context.colorScheme;
    // iOS-style rounded fill when no explicit background is provided
    final fillColor = backgroundColor ?? cs.containerLowOnSurface;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius ?? BorderRadius.circular(10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        enabled: enabled,
        maxLines: maxLines,
        minLines: minLines,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        expands: expands,
        textInputAction: textInputAction,
        autofocus: autoFocus,
        obscureText: obscureText,
        keyboardType: keyboardType,
        focusNode: focusNode,
        onSubmitted: onSubmitted,
        textAlign: textAlign,
        style: style ??
            AppTextStyle.subtitle2.copyWith(
              color: cs.textPrimary,
            ),
        onTapOutside: onTapOutside ??
            (event) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
        buildCounter: (
          context, {
          required currentLength,
          required isFocused,
          required maxLength,
        }) =>
            const SizedBox(),
        maxLength: maxLength,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          isDense: isDense,
          isCollapsed: isCollapsed,
          errorText: errorText,
          errorStyle: errorStyle ??
              AppTextStyle.caption.copyWith(color: cs.alert),
          hintText: hintText,
          hintStyle: hintStyle ??
              AppTextStyle.subtitle3.copyWith(color: cs.textDisabled),
          fillColor: fillColor,
          suffixIcon: suffixIcon,
          prefixIconConstraints: prefixIconConstraints,
          filled: true,
          focusedBorder: _border(context, true),
          enabledBorder: _border(context, false),
          focusedErrorBorder: _border(context, true, isError: true),
          errorBorder: _border(context, false, isError: true),
          contentPadding: contentPadding ??
              (borderType == AppTextFieldBorderType.outline
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
                  : null),
        ),
      ),
    );
  }

  InputBorder _border(
    BuildContext context,
    bool focused, {
    bool isError = false,
  }) {
    final cs = context.colorScheme;
    switch (borderType) {
      case AppTextFieldBorderType.none:
        return const UnderlineInputBorder(borderSide: BorderSide.none);
      case AppTextFieldBorderType.outline:
        return OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(10),
          borderSide: isError
              ? BorderSide(color: cs.alert, width: 1)
              // iOS fields show a visible blue border only when focused
              : focused
                  ? BorderSide(
                      color: borderColor?.focusColor ?? cs.primary,
                      width: 1.5,
                    )
                  : BorderSide(
                      color: borderColor?.unFocusColor ?? Colors.transparent,
                      width: 0,
                    ),
        );
      case AppTextFieldBorderType.underline:
        return UnderlineInputBorder(
          borderSide: BorderSide(
            color: isError
                ? cs.alert
                : focused
                    ? borderColor?.focusColor ?? cs.primary
                    : borderColor?.unFocusColor ?? cs.outline,
            width: borderWidth > 0 ? borderWidth : 0.5,
          ),
        );
    }
  }
}

enum AppTextFieldBorderType { none, outline, underline }

class BorderColor {
  Color? focusColor;
  Color? unFocusColor;

  BorderColor({this.focusColor, this.unFocusColor});
}
