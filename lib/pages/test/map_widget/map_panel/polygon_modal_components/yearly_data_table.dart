import 'package:flutter/material.dart';

enum YearlyDataTableDisplayMode { volume, yieldPerHa }

class YearlyDataTable extends StatefulWidget {
  final Map<String, Map<String, double>> yearlyData;
  final String product;

  const YearlyDataTable({
    super.key,
    required this.yearlyData,
    required this.product,
  });

  @override
  State<YearlyDataTable> createState() => _YearlyDataTableState();
}

class _YearlyDataTableState extends State<YearlyDataTable> {
  YearlyDataTableDisplayMode _displayMode = YearlyDataTableDisplayMode.volume;

  bool get _hasAreaData {
    return widget.yearlyData.values.any((data) => 
      (data['areaHarvested'] ?? 0) > 0
    );
  }

  Map<String, double> _getDisplayData() {
    final displayData = <String, double>{};
    
    for (final entry in widget.yearlyData.entries) {
      final year = entry.key;
      final data = entry.value;
      final volume = data['volume'] ?? 0;
      final areaHarvested = data['areaHarvested'] ?? 0;
      
      if (_displayMode == YearlyDataTableDisplayMode.volume) {
        displayData[year] = volume;
      } else {
        // Calculate yield per hectare (kg/ha)
        displayData[year] = areaHarvested > 0 ? volume / areaHarvested : 0;
      }
    }
    
    return displayData;
  }

  String _getUnit() {
    return _displayMode == YearlyDataTableDisplayMode.volume ? 'kg' : 'kg/ha';
  }

  String _getTitle() {
    final modeText = _displayMode == YearlyDataTableDisplayMode.volume 
        ? 'Production' 
        : 'Yield per Hectare';
    return 'Yearly $modeText';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayData = _getDisplayData();

    if (displayData.isEmpty || displayData.values.every((v) => v == 0)) {
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
                    ? 'No yearly records available for ${widget.product}'
                    : _displayMode == YearlyDataTableDisplayMode.yieldPerHa
                        ? 'No area data available for yield calculation'
                        : 'No yearly records available for ${widget.product}',
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

    final years = displayData.keys.toList()..sort((a, b) => b.compareTo(a));

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
                  Icon(Icons.calendar_today, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Year', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            DataColumn(
              label: Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text('${widget.product}   ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              numeric: true,
            ),
          ],
          rows: years.map((year) {
            final value = displayData[year];
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      year,
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
                            _displayMode == YearlyDataTableDisplayMode.volume
                                ? value?.toStringAsFixed(0) ?? 'N/A'
                                : value?.toStringAsFixed(2) ?? 'N/A',
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
            isSelected: _displayMode == YearlyDataTableDisplayMode.volume,
            onTap: () => setState(() => _displayMode = YearlyDataTableDisplayMode.volume),
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
            isSelected: _displayMode == YearlyDataTableDisplayMode.yieldPerHa,
            onTap: () => setState(() => _displayMode = YearlyDataTableDisplayMode.yieldPerHa),
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