import 'package:flareline/core/models/yield_model.dart';
import 'package:flutter/material.dart';

enum DataTableDisplayMode { volume, yieldPerHa }

class MonthlyDataTable extends StatefulWidget {
  final String product;
  final int year;
  final Map<String, Map<String, double>> monthlyData;

  const MonthlyDataTable({
    super.key,
    required this.product,
    required this.year,
    required this.monthlyData,
  });

  @override
  State<MonthlyDataTable> createState() => _MonthlyDataTableState();
}

class _MonthlyDataTableState extends State<MonthlyDataTable> {
  DataTableDisplayMode _displayMode = DataTableDisplayMode.volume;

  bool get _hasAreaData {
    final hasData = widget.monthlyData.values.any((data) => 
      (data['areaHarvested'] ?? 0) > 0
    );
    
    if (!hasData) {
      print('DEBUG: No area data available in monthlyData');
      print('DEBUG: monthlyData keys: ${widget.monthlyData.keys}');
      print('DEBUG: monthlyData values:');
      widget.monthlyData.forEach((month, data) {
        print('  $month: $data');
        if (data['areaHarvested'] == null) {
          print('    -> areaHarvested is null for $month');
        } else if (data['areaHarvested'] == 0) {
          print('    -> areaHarvested is 0 for $month');
        }
      });
    }
    
    return hasData;
  }

  Map<String, double> _getDisplayData() {
    final displayData = <String, double>{};
    
    for (final entry in widget.monthlyData.entries) {
      final month = entry.key;
      final data = entry.value;
      final volume = data['volume'] ?? 0;
      final areaHarvested = data['areaHarvested'] ?? 0;
      
      if (_displayMode == DataTableDisplayMode.volume) {
        displayData[month] = volume;
      } else {
        // Calculate yield per hectare (kg/ha)
        if (areaHarvested <= 0) {
          print('DEBUG: Cannot calculate yield for $month - areaHarvested: $areaHarvested, volume: $volume');
        }
        displayData[month] = areaHarvested > 0 ? volume / areaHarvested : 0;
      }
    }
    
    return displayData;
  }

  String _getTitle() {
    final modeText = _displayMode == DataTableDisplayMode.volume 
        ? 'Production' 
        : 'Yield per Hectare';
    return '  - Monthly $modeText  ';
  }

  @override
  void initState() {
    super.initState();
    // Debug print when widget is first created
    print('DEBUG: MonthlyDataTable created with product: ${widget.product}, year: ${widget.year}');
    print('DEBUG: monthlyData keys: ${widget.monthlyData.keys}');
    print('DEBUG: monthlyData values: ${widget.monthlyData.values}');
  }

  @override
  void didUpdateWidget(MonthlyDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Debug print when widget updates
    if (widget.monthlyData != oldWidget.monthlyData) {
      print('DEBUG: monthlyData updated');
      print('DEBUG: New monthlyData keys: ${widget.monthlyData.keys}');
      print('DEBUG: New monthlyData values: ${widget.monthlyData.values}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayData = _getDisplayData();

    if (displayData.isEmpty || displayData.values.every((v) => v == 0)) {
      print('DEBUG: No display data available or all values are zero');
      print('DEBUG: displayData: $displayData');
      print('DEBUG: _hasAreaData: $_hasAreaData');
      print('DEBUG: _displayMode: $_displayMode');
      
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart,
                  size: 48, color: theme.primaryColor.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                _hasAreaData  
                    ? 'No monthly records available for ${widget.year}'
                    : _displayMode == DataTableDisplayMode.yieldPerHa
                        ? 'No area data available for yield calculation'
                        : 'No monthly records available for ${widget.year}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.primaryColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Ensure all months are shown even if they have 0 values
    final allMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final sortedData = Map.fromEntries(
        allMonths.map((month) => MapEntry(month, displayData[month] ?? 0.0)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.table_chart,
                color: theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_hasAreaData) _buildDisplayModeToggle(theme),
            ],
          ),
        ),
        DataTable(
          headingRowColor:
              MaterialStateProperty.all(theme.primaryColor.withOpacity(0.1)),
          dataRowMaxHeight: 60,
          columns: [
            DataColumn(
              label: Row(
                children: [
                  Icon(Icons.calendar_month, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Month',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            DataColumn(
              label: Row(
                children: [
                  Icon(Icons.scale, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text('${widget.product}   ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              numeric: true,
            ),
          ],
          rows: sortedData.entries.map((entry) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _displayMode == DataTableDisplayMode.volume
                                ? entry.value.toStringAsFixed(0)
                                : entry.value.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDisplayModeToggle(ThemeData theme) {
    return Container(
      decoration: BoxDecoration( 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
        color: theme.brightness == Brightness.dark
            ? theme.primaryColor.withOpacity(0.1)
            : Colors.grey.shade50,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: 'Volume',
            icon: Icons.inventory,
            isSelected: _displayMode == DataTableDisplayMode.volume,
            onTap: () {
              print('DEBUG: Switching to Volume display mode');
              setState(() => _displayMode = DataTableDisplayMode.volume);
            },
            theme: theme,
          ),
          Container(
            width: 1,
            height: 28,
            color: theme.dividerColor,
          ),
          _buildToggleButton(
            label: 'Kg/Ha',
            icon: Icons.agriculture,
            isSelected: _displayMode == DataTableDisplayMode.yieldPerHa,
            onTap: () {
              print('DEBUG: Switching to Yield per Hectare display mode');
              print('DEBUG: _hasAreaData: $_hasAreaData');
              setState(() => _displayMode = DataTableDisplayMode.yieldPerHa);
            },
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? theme.primaryColor
                  : theme.iconTheme.color?.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.primaryColor : null,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}