import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math';

class YieldHistory extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isMobile;

  const YieldHistory({
    super.key,
    required this.product,
    this.isMobile = false,
  });

  @override
  State<YieldHistory> createState() => YieldHistoryState();
}

class YieldHistoryState extends State<YieldHistory> {
  String? _selectedYear;
  String? _startYear;
  String? _endYear;
  bool _showMonthlyView = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // print(widget.product);
    _initializeSelections();
  }

  void _initializeSelections() {
    // Initialize years
    final yields = (widget.product['yields'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (yields != null && yields.isNotEmpty) {
      yields.sort((a, b) => (a['year'] ?? '').compareTo(b['year'] ?? ''));
      _selectedYear = yields.last['year']?.toString();
      _startYear = yields.first['year']?.toString();
      _endYear = yields.last['year']?.toString();
    }
  }

  // Generate random color
  Color _generateRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final yields = (widget.product['yields'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    return CommonCard(
      child: Padding(
        padding: EdgeInsets.all(widget.isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yield Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (yields.isEmpty)
              const Center(child: Text('No yield data recorded')),
            if (yields.isNotEmpty) ...[
              _buildViewToggle(),
              const SizedBox(height: 16),
              _buildDateRangeControls(),
              const SizedBox(height: 16),
              _buildChart(yields),
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
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
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
    final yields = (widget.product['yields'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    if (yields == null || yields.isEmpty) return SizedBox();

    final years =
        yields.map((y) => y['year']?.toString()).whereType<String>().toList();
    years.sort();

    if (_showMonthlyView) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Year: '),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _selectYear(context, isRange: false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedYear ?? 'Select Year'),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('From: '),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _selectYearRange(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_startYear} - ${_endYear}'),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Future<void> _selectYear(BuildContext context,
      {required bool isRange}) async {
    final String? picked = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String tempYear = _selectedYear ?? '';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Year'),
              content: SizedBox(
                height: 300,
                width: 300,
                child: YearPicker(
                  selectedDate: DateTime(tempYear.isNotEmpty
                      ? int.parse(tempYear)
                      : DateTime.now().year),
                  firstDate: DateTime(2018),
                  lastDate: DateTime(2025),
                  onChanged: (DateTime dateTime) {
                    Navigator.pop(context, dateTime.year.toString());
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedYear = picked;
      });
    }
  }

  Future<void> _selectYearRange(BuildContext context) async {
    final List<int>? picked = await showDialog<List<int>>(
      context: context,
      builder: (BuildContext context) {
        int tempFromYear = _startYear != null ? int.parse(_startYear!) : 2020;
        int tempToYear = _endYear != null ? int.parse(_endYear!) : 2025;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Year Range'),
              content: SizedBox(
                height: 400,
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('From Year:'),
                    SizedBox(
                      height: 150,
                      child: YearPicker(
                        selectedDate: DateTime(tempFromYear),
                        firstDate: DateTime(2018),
                        lastDate: DateTime(2025),
                        onChanged: (DateTime dateTime) {
                          setState(() {
                            tempFromYear = dateTime.year;
                            if (tempFromYear > tempToYear) {
                              tempToYear = tempFromYear;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('To Year:'),
                    SizedBox(
                      height: 150,
                      child: YearPicker(
                        selectedDate: DateTime(tempToYear),
                        firstDate: DateTime(tempFromYear),
                        lastDate: DateTime(2025),
                        onChanged: (DateTime dateTime) {
                          setState(() {
                            tempToYear = dateTime.year;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, [tempFromYear, tempToYear]);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null && picked.length == 2) {
      setState(() {
        _startYear = picked[0].toString();
        _endYear = picked[1].toString();
      });
    }
  }

  Widget _buildChart(List<Map<String, dynamic>> yields) {
    if (yields.isEmpty) {
      return const Center(child: Text('No yield data available'));
    }

    if (_showMonthlyView) {
      return _buildMonthlyChart(yields);
    } else {
      return _buildYearlyChart(yields);
    }
  }

  Widget _buildMonthlyChart(List<Map<String, dynamic>> yields) {
    final selectedYield = yields.firstWhere(
      (y) => y['year'] == _selectedYear,
      orElse: () => {
        'monthlyVolume': List.filled(12, 0),
        'monthlyArea': List.filled(12, 0),
        'monthlyYieldPerHectare': List.filled(12, 0),
        'monthlyMetricTons': List.filled(12, 0),
        'year': ''
      },
    );

    final monthlyVolume =
        selectedYield['monthlyVolume'] as List<dynamic>? ?? List.filled(12, 0);
    final monthlyArea =
        selectedYield['monthlyArea'] as List<dynamic>? ?? List.filled(12, 0);
    final monthlyYieldPerHectare =
        selectedYield['monthlyYieldPerHectare'] as List<dynamic>? ??
            List.filled(12, 0);
    final monthlyMetricTons =
        selectedYield['monthlyMetricTons'] as List<dynamic>? ??
            List.filled(12, 0);

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
      final kgPerHaValue =
          (monthlyYieldPerHectare[index] as num?)?.toDouble() ?? 0;
      final mtValue = (monthlyMetricTons[index] as num?)?.toDouble() ?? 0;

      return _ChartData(
        months[index],
        kgPerHaValue,
        mtValue,
        _generateRandomColor(),
      );
    });

    return SizedBox(
      height: 300,
      child: _buildBarChart(
        chartData,
        title: 'Monthly Yield for $_selectedYear',
        isMonthly: true,
      ),
    );
  }

  Widget _buildYearlyChart(List<Map<String, dynamic>> yields) {
    final filteredYields = yields.where((yieldData) {
      final year = yieldData['year']?.toString() ?? '';
      return (_startYear == null || year.compareTo(_startYear!) >= 0) &&
          (_endYear == null || year.compareTo(_endYear!) <= 0);
    }).toList();

    filteredYields.sort((a, b) => (a['year'] ?? '').compareTo(b['year'] ?? ''));

    final chartData = filteredYields.map((yieldData) {
      final year = yieldData['year']?.toString() ?? 'Unknown';

      // Calculate average yield per hectare for the year
      final monthlyYieldPerHectare =
          yieldData['monthlyYieldPerHectare'] as List<dynamic>? ?? [];
      final monthlyMetricTons =
          yieldData['monthlyMetricTons'] as List<dynamic>? ?? [];

      // Calculate yearly averages
      double totalKgPerHa = 0;
      int count = 0;
      double totalMetricTons = 0;

      for (int i = 0; i < monthlyYieldPerHectare.length; i++) {
        final kgPerHa = (monthlyYieldPerHectare[i] as num?)?.toDouble() ?? 0;
        final mt = (monthlyMetricTons[i] as num?)?.toDouble() ?? 0;

        if (kgPerHa > 0) {
          totalKgPerHa += kgPerHa;
          count++;
        }

        totalMetricTons += mt;
      }

      final avgKgPerHa = count > 0 ? totalKgPerHa / count : 0;

      return _ChartData(
        year,
        avgKgPerHa.toDouble(),
        totalMetricTons,
        _generateRandomColor(),
      );
    }).toList();

    return SizedBox(
      height: 300,
      child: _buildBarChart(
        chartData,
        title: 'Yearly Yield (${_startYear} - ${_endYear})',
        isMonthly: false,
      ),
    );
  }

  Widget _buildBarChart(
    List<_ChartData> chartData, {
    String title = '',
    bool isMonthly = true,
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
      series: <CartesianSeries>[
        ColumnSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.yieldKgPerHa,
          color: Color(0xFF12E3D7),
          // pointColorMapper: (_ChartData data, _) => data.color,
          name: 'Yield (t/ha)',
          width: 0.4,
          spacing: 0.2,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(fontSize: 10),
          ),
        ),
        ColumnSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.yieldMetricTons,
          // pointColorMapper: (_ChartData data, _) => data.color.withOpacity(0.7),
          color: Color(0xFFFE8111),

          name: 'Yield (Metric Tons)',
          width: 0.4,
          spacing: 0.2,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(fontSize: 10),
          ),
        )
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: '',
        canShowMarker: false,
        builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
            int seriesIndex) {
          final chartData = data as _ChartData;
          return Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text('${chartData.x}'),
                Text('t/ha: ${chartData.yieldKgPerHa.toStringAsFixed(2)}'),
                Text(
                    'Metric Tons: ${chartData.yieldMetricTons.toStringAsFixed(2)}'),
              ],
            ),
          );
        },
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
}

class _ChartData {
  _ChartData(this.x, this.yieldKgPerHa, this.yieldMetricTons, this.color);

  final String x; // Month or Year
  final double yieldKgPerHa; // Yield efficiency in kg/ha
  final double yieldMetricTons; // Yield value in metric tons
  final Color color; // Individual color for each bar
}
