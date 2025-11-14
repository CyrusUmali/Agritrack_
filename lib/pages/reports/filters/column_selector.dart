import 'package:flutter/material.dart';
import '../filter_configs/column_options.dart';

import 'package:flareline/services/lanugage_extension.dart';

class ColumnSelector extends StatelessWidget {
  final String reportType;
  final Set<String> selectedColumns;
  final ValueChanged<Set<String>> onColumnsChanged;

  const ColumnSelector({
    super.key,
    required this.reportType,
    required this.selectedColumns,
    required this.onColumnsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final columns = ColumnOptions.reportColumns[reportType] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate('Select Columns'),
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: columns.map((column) {
            final isSelected = selectedColumns.contains(column);

            return FilterChip(
              label: Text(column),
              selected: isSelected,
              onSelected: (selected) {
                final newColumns = Set<String>.from(selectedColumns);
                if (selected) {
                  newColumns.add(column);
                } else {
                  newColumns.remove(column);
                }
                onColumnsChanged(newColumns);
              },
              selectedColor: colorScheme.primary.withOpacity(0.2),
              checkmarkColor: colorScheme.primary,
              backgroundColor: theme.cardTheme.color ?? Colors.grey[200],
              labelStyle: textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      // : theme.dividerColor.withOpacity(0.5),
                      : Theme.of(context).cardTheme.surfaceTintColor ??
                          Colors.grey[300]!,
                  width: 1,
                ),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
