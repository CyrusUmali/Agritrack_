import 'package:flutter/material.dart';

class DropdownFilter extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool includeAllOption;

  const DropdownFilter({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.includeAllOption = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: [
              if (includeAllOption)
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All'),
                ),
              ...items
                  .map((item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
            ],
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
