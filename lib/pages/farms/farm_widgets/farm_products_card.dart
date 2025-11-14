import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class FarmProductsCard extends StatefulWidget {
  final Map<String, dynamic> farm;
  final bool isMobile;

  const FarmProductsCard({
    super.key,
    required this.farm,
    this.isMobile = false,
  });

  @override
  State<FarmProductsCard> createState() => _FarmProductsCardState();
}

class _FarmProductsCardState extends State<FarmProductsCard> {
  String? _selectedProduct;
  String? _selectedYear;
  String? _startYear;
  String? _endYear;
  bool _showMonthlyView = false;

  @override
  void initState() {
    super.initState();
    _initializeSelections();
  }

  void _initializeSelections() {
    final products = widget.farm['products'] as List?;

    if (products == null || products.isEmpty) {
      return;
    }

    // Safely get first product name
    final firstProduct = products.first;
    if (firstProduct is! Map<String, dynamic>) {
      return;
    }

    _selectedProduct = firstProduct['name']?.toString();

    // Initialize years
    final yields = (firstProduct['yields'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();

    if (yields != null && yields.isNotEmpty) {
      yields.sort((a, b) => (a['year'] ?? '').compareTo(b['year'] ?? ''));

      _selectedYear = yields.last['year']?.toString();
      _startYear = yields.first['year']?.toString();
      _endYear = yields.last['year']?.toString();
    }
  }

  // Generate random colors from a predefined palette
  List<Color> _generatePaletteColors(int count) {
    final colors = [
      const Color(0xFFFE8111), // Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFE91E63), // Pink
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFFFF9800), // Amber
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFFF6EC7), // Hot Pink
      const Color(0xFF40E0D0), // Turquoise
    ];

    final random = Random();
    return List.generate(count, (index) {
      return colors[random.nextInt(colors.length)];
    });
  }

  @override
  Widget build(BuildContext context) {

// print("farm");
//     print(widget.farm);

    final products = (widget.farm['products'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    return CommonCard(
      child: Padding(
        padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Replace the existing Row with this responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                // Use 600 as a breakpoint between mobile and desktop
                final isDesktop = constraints.maxWidth > 600;

                if (isDesktop) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Farm Products',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (products.isNotEmpty) _buildProductDropdown(products),
                    ],
                  );
                } else {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Farm Products',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (products.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildProductDropdown(products),
                        ],
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              const Center(child: Text('No products recorded')),
            if (products.isNotEmpty && _selectedProduct != null) ...[
              _buildViewToggle(),
              const SizedBox(height: 16),
              _buildDateRangeControls(),
              const SizedBox(height: 16),
              _buildChart(products),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          // This is the correct way to add a child to Container
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => setState(() => _showMonthlyView = false),
              style: TextButton.styleFrom(
                foregroundColor: _showMonthlyView
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                    : Theme.of(context).colorScheme.primary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text('Yearly'),
            ),
            TextButton(
              onPressed: () => setState(() => _showMonthlyView = true),
              style: TextButton.styleFrom(
                foregroundColor: _showMonthlyView
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text('Monthly'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeControls() {
    final selectedProduct = _getSelectedProduct();
    if (selectedProduct == null) return SizedBox();

    final yields = (selectedProduct['yields'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (yields == null || yields.isEmpty) return SizedBox();

    // Get unique years and sort them
    final years = yields
        .map((y) => y['year']?.toString())
        .whereType<String>()
        .toSet() // Remove duplicates
        .toList();
    years.sort();

    // Ensure selected values exist in the years list
    if (_selectedYear != null && !years.contains(_selectedYear)) {
      _selectedYear = years.isNotEmpty ? years.last : null;
    }
    if (_startYear != null && !years.contains(_startYear)) {
      _startYear = years.isNotEmpty ? years.first : null;
    }
    if (_endYear != null && !years.contains(_endYear)) {
      _endYear = years.isNotEmpty ? years.last : null;
    }

    if (_showMonthlyView) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Year: '),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: years.contains(_selectedYear) ? _selectedYear : null,
            items: years.map((year) {
              return DropdownMenuItem<String>(
                value: year,
                child: Text(year),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedYear = newValue;
                });
              }
            },
          ),
        ],
      );
    } else {
      // For yearly view, ensure valid range selections
      final validEndYears = years
          .where(
              (year) => _startYear == null || year.compareTo(_startYear!) >= 0)
          .toList();

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('From: '),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: years.contains(_startYear) ? _startYear : null,
            items: years.map((year) {
              return DropdownMenuItem<String>(
                value: year,
                child: Text(year),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _startYear = newValue;
                  // Ensure end year is not before start year
                  if (_endYear != null &&
                      _startYear!.compareTo(_endYear!) > 0) {
                    _endYear = _startYear;
                  }
                });
              }
            },
          ),
          const SizedBox(width: 16),
          Text('To: '),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: validEndYears.contains(_endYear) ? _endYear : null,
            items: validEndYears.map((year) {
              return DropdownMenuItem<String>(
                value: year,
                child: Text(year),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _endYear = newValue;
                });
              }
            },
          ),
        ],
      );
    }
  }

  Widget _buildChart(List<Map<String, dynamic>> products) {
    final selectedProduct = _getSelectedProduct();
    if (selectedProduct == null)
      return Center(child: Text('No product selected'));

    final yields = (selectedProduct['yields'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (yields == null || yields.isEmpty) {
      return const Center(child: Text('No yield data available'));
    }

    if (_showMonthlyView) {
      return _buildMonthlyChart(yields);
    } else {
      return _buildYearlyChart(yields);
    }
  }

  Widget _buildMonthlyChart(List<Map<String, dynamic>> yields) {
    // Convert selectedYear to same type as stored in yields (int vs String)
    final selectedYear = _selectedYear;
    final selectedYield = yields.firstWhere(
      (y) => y['year'].toString() == selectedYear,
      orElse: () => {'monthly': List.filled(12, 0), 'year': ''},
    );

    final monthlyData =
        selectedYield['monthly'] as List<dynamic>? ?? List.filled(12, 0);

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final chartData = List.generate(12, (index) {
      return _ChartData(
        months[index],
        (monthlyData[index] as num?)?.toDouble() ?? 0,
        0,
      );
    });

    return SizedBox(
      height: 300,
      child: _buildBarChart(
        chartData,
        title: 'Monthly Yield for $_selectedYear (kg)',
      ),
    );
  }

  Widget _buildYearlyChart(List<Map<String, dynamic>> yields) {
    // Group yields by year and sum them
    final Map<String, double> yearlyTotals = {};
    for (final yieldData in yields) {
      final year = yieldData['year']?.toString() ?? 'Unknown';
      final monthly = yieldData['monthly'] as List<dynamic>? ?? [];
      final totalYield = monthly.fold<double>(
          0, (sum, value) => sum + (value is num ? value.toDouble() : 0));

      yearlyTotals.update(year, (value) => value + totalYield,
          ifAbsent: () => totalYield);
    }

    // Filter by date range
    final filteredYears = yearlyTotals.entries.where((entry) {
      return (_startYear == null || entry.key.compareTo(_startYear!) >= 0) &&
          (_endYear == null || entry.key.compareTo(_endYear!) <= 0);
    }).toList();

    // Sort by year
    filteredYears.sort((a, b) => a.key.compareTo(b.key));

    // Prepare chart data
    final chartData = filteredYears.map((entry) {
      return _ChartData(entry.key, entry.value, 0);
    }).toList();

    // Generate one color per year
    final yearColors = _generatePaletteColors(chartData.length);

    return SizedBox(
      height: 300,
      child: _buildBarChart(
        chartData,
        yearColors: yearColors,
      ),
    );
  }

  Widget _buildBarChart(
    List<_ChartData> chartData, {
    String title = '',
    List<Color>? yearColors,
  }) {
    final needsScrolling = widget.isMobile && chartData.length > 5;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final chart = SfCartesianChart(
      plotAreaBorderWidth: 0,
      title: ChartTitle(text: title),
      legend: Legend(isVisible: true, position: LegendPosition.top),
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelRotation: needsScrolling ? -45 : 0,
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        labelFormat: '{value}',
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: const MajorGridLines(width: 1),
        rangePadding: ChartRangePadding.additional,
      ),
      series: <ColumnSeries<_ChartData, String>>[
        ColumnSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          pointColorMapper: yearColors != null
              ? (_ChartData data, int index) => yearColors[index]
              : null,
          color: yearColors == null ? Theme.of(context).primaryColor : null,
          name: 'Yield (kg)',
          width: 0.6,
          spacing: 0.2,
          dataLabelSettings:   DataLabelSettings(
            isVisible: true,
           textStyle: TextStyle(
    fontSize: 10,
    color: Theme.of(context).colorScheme.onPrimary, // Use theme color
    fontWeight: FontWeight.bold,
  ),
          ),
        )
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: '',
        canShowMarker: false,
        textStyle: TextStyle(color: isDark ? Colors.black : Colors.grey),
      ),
    );

    return needsScrolling
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              width: chartData.length * 80.0,
              child: chart,
            ),
          )
        : chart;
  }

  Widget _buildProductDropdown(List<Map<String, dynamic>> products) {
    return PopupMenuButton<String>(
      initialValue: _selectedProduct,
      onSelected: (String value) {
        setState(() {
          _selectedProduct = value;
          _updateYearSelections();
        });
      },
      itemBuilder: (BuildContext context) {
        return products.map((product) {
          final name = product['name']?.toString() ?? 'Unknown';
          return PopupMenuItem<String>(
            value: name,
            child: Row(
              children: [
                Text(name),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selectedProduct ?? 'Select Product'),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  void _updateYearSelections() {
    final selectedProduct = _getSelectedProduct();
    if (selectedProduct == null) return;

    final yields = (selectedProduct['yields'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (yields == null || yields.isEmpty) return;

    // Get unique years and sort them
    final years = yields
        .map((y) => y['year']?.toString())
        .whereType<String>()
        .toSet() // Remove duplicates
        .toList();
    years.sort();

    if (years.isNotEmpty) {
      setState(() {
        _selectedYear = years.last;
        _startYear = years.first;
        _endYear = years.last;
      });
    }
  }

  Map<String, dynamic>? _getSelectedProduct() {
    final products = (widget.farm['products'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (products == null || products.isEmpty) return null;

    return products.firstWhere(
      (p) => p['name'] == _selectedProduct,
      orElse: () => products.first,
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y, this.y2);

  final String x; // Month or Year
  final double y; // Yield value
  final double y2; // Not used in this implementation
}
