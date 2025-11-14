import 'package:flutter/material.dart';

class DetailField extends StatelessWidget {
  final String label;
  final String? value;

  const DetailField({
    super.key,
    required this.label,
    required this.value,
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
        Text(
          value ?? 'Not specified',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
