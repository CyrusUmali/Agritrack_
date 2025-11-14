import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';

class EditableField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  const EditableField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            // Copied border style from OutBorderTextFormField
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: FlarelineColors.border, width: 1),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: FlarelineColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
            errorMaxLines: 2,
            errorStyle: TextStyle(
              color: Colors.red, // Explicit red color
              fontSize: 12, // Optional: adjust font size
            ),
            // Using the error border style from OutBorderTextFormField
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
