import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangePickerWidget extends StatelessWidget {
  final DateTimeRange dateRange;
  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final double? width;

  const DateRangePickerWidget({
    super.key,
    required this.dateRange,
    required this.onDateRangeChanged,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: width ?? 150,
                maxHeight: 40,
              ),
              child: _buildDateRangeButton(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeButton(BuildContext context) {
    final dateFormat = DateFormat('MMM yyyy');
    final isRangeSelected = dateRange.start != dateRange.end;

    return SizedBox(
      height: 48,
      width: width ?? 150, // Use the provided width or default to 150
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(
            color: Theme.of(context).cardTheme.surfaceTintColor ??
                Colors.grey[300]!,
          ),
          backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
          foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
          textStyle: const TextStyle(fontSize: 14),
        ),
        onPressed: () async => await _showDatePicker(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment
              .spaceBetween, // This distributes space between children
          children: [
            Expanded(
              // This makes the text take available space but not push the icon
              child: Text(
                isRangeSelected
                    ? '${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}'
                    : 'Select Range',
                overflow: TextOverflow.ellipsis,
                style: TextStyle( 
                  color: Theme.of(context).textTheme.bodyMedium?.color
                       
                ),
              ),
            ),
            Icon(
              isRangeSelected ? Icons.close : Icons.calendar_today,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final currentYear = now.year;
    final years = List.generate(11, (index) => currentYear - 5 + index);

    // Set default values to current year, January to December
    int selectedStartYear = currentYear;
    int selectedEndYear = currentYear;
    int selectedStartMonth = 1; // January
    int selectedEndMonth = 12; // December

    // Only use existing range if it's actually a selected range (not the same day)
    final isExistingRangeSelected = dateRange.start != dateRange.end;
    if (isExistingRangeSelected) {
      selectedStartYear = dateRange.start.year;
      selectedEndYear = dateRange.end.year;
      selectedStartMonth = dateRange.start.month;
      selectedEndMonth = dateRange.end.month;
    }

    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Theme.of(context).cardTheme.color,
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
                maxHeight: 500,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select Date Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Start Year/Month Selection
                    _buildYearMonthSelector(
                      context,
                      title: 'Start',
                      years: years,
                      selectedYear: selectedStartYear,
                      selectedMonth: selectedStartMonth,
                      onYearChanged: (year) {
                        setState(() => selectedStartYear = year);
                        // Ensure end date is not before start date
                        if (selectedStartYear > selectedEndYear ||
                            (selectedStartYear == selectedEndYear &&
                                selectedStartMonth > selectedEndMonth)) {
                          selectedEndYear = selectedStartYear;
                          selectedEndMonth = selectedStartMonth;
                        }
                      },
                      onMonthChanged: (month) {
                        setState(() => selectedStartMonth = month);
                        // Ensure end date is not before start date
                        if (selectedStartYear > selectedEndYear ||
                            (selectedStartYear == selectedEndYear &&
                                selectedStartMonth > selectedEndMonth)) {
                          selectedEndYear = selectedStartYear;
                          selectedEndMonth = selectedStartMonth;
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // End Year/Month Selection
                    _buildYearMonthSelector(
                      context,
                      title: 'End',
                      years: years,
                      selectedYear: selectedEndYear,
                      selectedMonth: selectedEndMonth,
                      onYearChanged: (year) {
                        setState(() => selectedEndYear = year);
                        // Ensure end date is not before start date
                        if (selectedStartYear > selectedEndYear ||
                            (selectedStartYear == selectedEndYear &&
                                selectedStartMonth > selectedEndMonth)) {
                          selectedStartYear = selectedEndYear;
                          selectedStartMonth = selectedEndMonth;
                        }
                      },
                      onMonthChanged: (month) {
                        setState(() => selectedEndMonth = month);
                        // Ensure end date is not before start date
                        if (selectedStartYear > selectedEndYear ||
                            (selectedStartYear == selectedEndYear &&
                                selectedStartMonth > selectedEndMonth)) {
                          selectedStartYear = selectedEndYear;
                          selectedStartMonth = selectedEndMonth;
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(DateTimeRange(
                              start: now,
                              end: now,
                            ));
                          },
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: FlarelineColors.primary,
                          ),
                          onPressed: () {
                            final startDate = DateTime(
                                selectedStartYear, selectedStartMonth, 1);
                            final endDate = DateTime(
                                selectedEndYear,
                                selectedEndMonth + 1,
                                0); // Last day of the month

                            Navigator.of(context).pop(DateTimeRange(
                              start: startDate,
                              end: endDate,
                            ));
                          },
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result != null) {
      onDateRangeChanged(result);
    }
  }

  Widget _buildYearMonthSelector(
    BuildContext context, {
    required String title,
    required List<int> years,
    required int selectedYear,
    required int selectedMonth,
    required ValueChanged<int> onYearChanged,
    required ValueChanged<int> onMonthChanged,
  }) {
    final months = List.generate(12, (index) => index + 1);
    final monthNames = DateFormat.MMMM().dateSymbols.SHORTMONTHS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedYear,
                items: years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                dropdownColor: Theme.of(context).cardTheme.color,
                onChanged: (year) {
                  if (year != null) onYearChanged(year);
                },
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedMonth,
                items: months.map((month) {
                  return DropdownMenuItem(
                    value: month,
                    child: Text(monthNames[month - 1]),
                  );
                }).toList(),
                onChanged: (month) {
                  if (month != null) onMonthChanged(month);
                },
                dropdownColor: Theme.of(context).cardTheme.color,
                decoration: InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
