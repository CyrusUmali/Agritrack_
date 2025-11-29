import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/widget/network_error.dart';
import 'package:flareline/pages/sectors/sector_service.dart';

class SectorBarChart extends StatefulWidget {
  const SectorBarChart({super.key});

  @override
  State<SectorBarChart> createState() => _SectorBarChartState();
}

class _SectorBarChartState extends State<SectorBarChart> {
  int selectedYear = DateTime.now().year;

  Future<void> _selectYear(BuildContext context) async {
    final int? picked = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int tempYear = selectedYear;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Year'),
              content: SizedBox(
                height: 300,
                width: 300,
                child: YearPicker(
                  selectedDate: DateTime(tempYear),
                  firstDate: DateTime(2018),
                  lastDate: DateTime(2025),
                  onChanged: (DateTime dateTime) {
                    setState(() {
                      tempYear = dateTime.year;
                    });
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, tempYear);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedYear = picked;
      });
    }
  }

  Future<void> _retryFetchData() async {
    setState(() {
      // Trigger rebuild which will call the FutureBuilder again
    });
  }

  @override
  Widget build(BuildContext context) {
    final scrollBreakpoint = 600.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final needsScrolling = screenWidth < scrollBreakpoint;
    final useVerticalHeader = screenWidth < 450;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: RepositoryProvider.of<SectorService>(context)
          .fetchSectors(year: selectedYear),
      builder: (context, snapshot) {
        // Loading state wrapped in CommonCard
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CommonCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: useVerticalHeader
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'Sector Performance',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.center,
                                child: _buildYearSelector(context),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Sector Performance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _buildYearSelector(context),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading sector data...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return CommonCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: NetworkErrorWidget(
                error: snapshot.error.toString(),
                onRetry: _retryFetchData,
                errorColor: Colors.red,
                iconSize: 40,
                fontSize: 14,
                retryButtonText: 'Try Again',
                padding: const EdgeInsets.all(20),
              ),
            ),
          );
        }

        // Success state
        final sectors = snapshot.data ?? [];

        return CommonCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: useVerticalHeader
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Sector Performance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.center,
                              child: _buildYearSelector(context),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sector Performance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildYearSelector(context),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: needsScrolling
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            width: scrollBreakpoint,
                            child: _buildChart(sectors),
                          ),
                        )
                      : _buildChart(sectors),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearSelector(BuildContext context) {
    return InkWell(
      onTap: () => _selectYear(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedYear.toString()),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> sectors) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final chartData = sectors
        .map((sector) => _ChartData(
              sector['name'] ?? 'Unknown',
              (sector['stats']?['totalAreaHarvested'] ?? 0).toDouble(),
              ((sector['stats']?['totalYieldVolume'] ?? 0) / 1000)
                  .toDouble(), // kg → MT
            ))
        .toList();

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      enableSideBySideSeriesPlacement: true,
      title: const ChartTitle(text: ''),
      legend: const Legend(isVisible: true, position: LegendPosition.top),
      primaryXAxis: const CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: const NumericAxis(
        axisLine: AxisLine(width: 0),
        labelFormat: '{value}',
        majorTickLines: MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(width: 1),
        rangePadding: ChartRangePadding.additional,
      ),
      series: <CartesianSeries<_ChartData, String>>[
        ColumnSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          color: Color(0xFFFE8111),
          name: 'Area harvested (ha)',
          width: 0.3,
          spacing: 0.1,
          dataLabelSettings:   DataLabelSettings(
            isVisible: true,
           textStyle: TextStyle(
      fontSize: 10,
      color: Theme.of(context).colorScheme.onPrimary, // Use theme color
      fontWeight: FontWeight.bold,
    ),
          ),
        ),
        ColumnSeries<_ChartData, String>(
          dataSource: chartData,
          color: Color(0xFF12E3D7),
          name: 'Yield (Metric Tons)',
          width: 0.3,
          spacing: 0.1,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y2,
  dataLabelSettings: DataLabelSettings(
    isVisible: true,
    textStyle: TextStyle(
      fontSize: 10,
      color: Theme.of(context).colorScheme.onPrimary, // Use theme color
      fontWeight: FontWeight.bold,
    ),
  ),
        ),
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: '',
        canShowMarker: false,
        textStyle: TextStyle(color: isDark ? Colors.white : Colors.grey),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y, this.y2);

  final String x; // Sector name
  final double y; // Farm area in hectares
  final double y2; // Number of farms
}