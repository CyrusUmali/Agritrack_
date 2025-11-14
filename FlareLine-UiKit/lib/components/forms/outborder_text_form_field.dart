// ignore_for_file: prefer_const_constructors

library flareline_uikit;

import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';

class OutBorderTextFormField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final int? maxLines;
  final TextEditingController? controller;
  final bool? enabled;
  final bool showErrorText;
  final Color errorBorderColor;
  final Widget? suffixWidget;
  final bool? obscureText;
  final TextInputType? keyboardType;
  final Widget? icon;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged; // ✅ Added
  final TextStyle? textStyle;
  final int? maxLength;
  final TextStyle? hintStyle;
  final Color? focusColor;
  final TextStyle? errorTextStyle;
  final double? height;
  final double? width;

  const OutBorderTextFormField({
    super.key,
    this.labelText,
    this.initialValue,
    this.hintText,
    this.hintStyle,
    this.showErrorText = true,
    this.errorBorderColor = Colors.redAccent,
    this.maxLines = 1,
    this.enabled,
    this.controller,
    this.suffixWidget,
    this.obscureText,
    this.keyboardType,
    this.icon,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged, // ✅ Added
    this.textStyle,
    this.focusColor,
    this.errorTextStyle,
    this.maxLength,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Widget textField = TextFormField(
      keyboardType: keyboardType,
      obscureText: obscureText ?? false,
      enabled: enabled,
      initialValue: initialValue,
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged, // ✅ Pass down
      style: textStyle,
      maxLength: maxLength,
      decoration: InputDecoration(
        counterStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
        prefixIcon: icon,
        prefixIconConstraints: const BoxConstraints(
          maxWidth: 35,
          maxHeight: 35,
        ),
        suffixIcon: suffixWidget != null
            ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: suffixWidget,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          maxHeight: 24,
          maxWidth: 24,
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: FlarelineColors.border, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: FlarelineColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: (focusColor ?? FlarelineColors.primary),
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: errorBorderColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: errorBorderColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        hintText: hintText,
        hintStyle: hintStyle,
        errorStyle: errorTextStyle ??
            TextStyle(
              color: errorBorderColor,
              fontSize: showErrorText ? 12 : 0,
              fontWeight: FontWeight.w100,
              height: showErrorText ? 1.2 : 0,
            ),
        errorMaxLines: 2,
        isDense: true,
      ),
    );

    if (height != null) {
      textField = SizedBox(
        height: height,
        child: textField,
      );
    }

    if (width != null) {
      textField = SizedBox(
        width: width,
        child: textField,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText ?? '',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
        textField,
      ],
    );
  }
}
