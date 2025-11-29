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
  final ValueChanged<String>? onChanged;
  final TextStyle? textStyle;
  final int? maxLength;
  final TextStyle? hintStyle;
  final Color? focusColor;
  final TextStyle? errorTextStyle;
  final double? height;
  final double? width;

  // Error positioning
  final double? errorLeft;
  final double? errorTop;
  final double? errorRight;
  final double? errorBottom;
  final AlignmentGeometry errorAlignment;

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
    this.onChanged,
    this.textStyle,
    this.focusColor,
    this.errorTextStyle,
    this.maxLength,
    this.height,
    this.width,
    this.errorLeft,
    this.errorTop,
    this.errorRight,
    this.errorBottom,
    this.errorAlignment = Alignment.topLeft,
  });

  @override
  Widget build(BuildContext context) {
    // ValueNotifier to track error messages
    final errorNotifier = ValueNotifier<String?>(null);

    // Default positioning values
    final double effectiveErrorLeft = errorLeft ?? 12;
    final double effectiveErrorRight = errorRight ?? 12;
    final double effectiveErrorBottom = errorBottom ?? -5;

    Widget textField = TextFormField(
      keyboardType: keyboardType,
      obscureText: obscureText ?? false,
      enabled: enabled,
      initialValue: initialValue,
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        final msg = validator != null ? validator!(value) : null;
        errorNotifier.value = msg;
        return msg;
      },
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      style: textStyle,
      maxLength: maxLength,
      decoration: InputDecoration(
        counterStyle: TextStyle(fontSize: 12, color: Colors.grey),
        prefixIcon: icon,
        prefixIconConstraints: const BoxConstraints(maxWidth: 35, maxHeight: 35),
        suffixIcon: suffixWidget != null
            ? Container(padding: const EdgeInsets.only(right: 12.0), child: suffixWidget)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: FlarelineColors.border, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: FlarelineColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: (focusColor ?? FlarelineColors.primary), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: errorBorderColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: errorBorderColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        hintText: hintText,
        hintStyle: hintStyle,
        errorStyle: TextStyle(fontSize: 0, height: 0), // Hide default error
        isDense: true,
      ),
    );

    if (height != null) {
      textField = SizedBox(height: height, child: textField);
    }
    if (width != null) {
      textField = SizedBox(width: width, child: textField);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(labelText ?? '', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
        ],
        Stack(
          clipBehavior: Clip.none,
          children: [
            textField,
            if (showErrorText)
              Positioned(
                left: effectiveErrorLeft,
                top: errorTop,
                right: effectiveErrorRight,
                bottom: effectiveErrorBottom,
                child: Align(
                  alignment: errorAlignment,
                  child: ValueListenableBuilder<String?>(
                    valueListenable: errorNotifier,
                    builder: (context, error, _) {
                      return error != null && error.isNotEmpty
                          ? Text(
                              error,
                              style: errorTextStyle ??
                                  TextStyle(
                                    color: errorBorderColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w100,
                                    height: 1.2,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : SizedBox.shrink();
                    },
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
