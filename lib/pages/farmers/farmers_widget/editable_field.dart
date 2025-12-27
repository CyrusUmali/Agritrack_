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
    // ValueNotifier to track error messages
    final errorNotifier = ValueNotifier<String?>(null);
    
    // Run validator immediately if value is empty/invalid
    if (validator != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final error = validator!(value);
        if (error != null) {
          errorNotifier.value = error;
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        
        // Text Field
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          keyboardType: keyboardType,
          validator: (val) {
            final msg = validator != null ? validator!(val) : null;
            errorNotifier.value = msg;
            return msg;
          },
          style: Theme.of(context).textTheme.bodyMedium,
          autovalidateMode: AutovalidateMode.always,  // Force validation to run
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            
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
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 1),
            ),
            
            // Hide default error text (we'll show our own)
            errorStyle: const TextStyle(fontSize: 0, height: 0),
            
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        
        // Dedicated error text space
        SizedBox(
          height: 20,
          child: ValueListenableBuilder<String?>(
            valueListenable: errorNotifier,
            builder: (context, error, _) {
              if (error != null && error.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 2, left: 0),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }
}