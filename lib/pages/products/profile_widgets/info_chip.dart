import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  final String label;
  final String? value;

  const InfoChip({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox();

    return Chip(
      label: Text('$label: $value'),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
