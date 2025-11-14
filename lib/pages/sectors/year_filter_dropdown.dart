import 'package:flutter/material.dart';

class YearFilterDropdown extends StatelessWidget {
  final int selectedYear;
  final ValueChanged<int?> onYearChanged;

  const YearFilterDropdown({
    super.key,
    required this.selectedYear,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> years =
        List.generate(10, (index) => DateTime.now().year - index);
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerRight, // Maintains right alignment
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Icon(
                Icons.calendar_today,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: selectedYear,
              onChanged: onYearChanged,
              dropdownColor: colorScheme.surfaceContainerLow,
              icon: Icon(
                Icons.arrow_drop_down,
                color: colorScheme.onSurfaceVariant,
              ),
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
              borderRadius: BorderRadius.circular(12),
              elevation: 1,
              items: years.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
