import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline/core/models/assocs_model.dart';

class AssocsBarChart extends StatefulWidget {
  const AssocsBarChart({super.key});

  @override
  State<AssocsBarChart> createState() => _AssocBarChartState();
}

class _AssocBarChartState extends State<AssocsBarChart> {
  @override
  void initState() {
    super.initState();
    // Load associations when widget initializes
    context.read<AssocsBloc>().add(LoadAssocs());
  }

  @override
  Widget build(BuildContext context) {
    final scrollBreakpoint = 600.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final needsScrolling = screenWidth < scrollBreakpoint;
    final useVerticalHeader = screenWidth < 450;

    return BlocBuilder<AssocsBloc, AssocsState>(
      builder: (context, state) {
        if (state is AssocsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AssocsError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is AssocsLoaded) {
          final associations = state.associations;

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
                                  'Association Statistics',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Association Statistics',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                              child: _buildChart(associations),
                            ),
                          )
                        : _buildChart(associations),
                  ),
                ],
              ),
            ),
          );
        }

        return const Center(child: Text('No data available'));
      },
    );
  }

  Widget _buildChart(List<Association> associations) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Limit associations to maximum 7
    final limitedAssociations = associations.take(7).toList();

    final chartData = limitedAssociations
        .map((assoc) => _ChartData(
              assoc.name,
              (assoc.totalMembers != null)
                  ? double.tryParse(assoc.totalMembers!) ?? 0.0
                  : 0.0,
              (assoc.hectare is num ? assoc.hectare as num : 0).toDouble(),
            ))
        .toList();

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      enableSideBySideSeriesPlacement: true,
      title: const ChartTitle(text: ''),
      legend: const Legend(isVisible: true, position: LegendPosition.top),
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelRotation: -45,
        labelIntersectAction: AxisLabelIntersectAction.rotate45,
        labelAlignment: LabelAlignment.center,
        // Use axisLabelFormatter instead of labelFormatter
        axisLabelFormatter: (AxisLabelRenderDetails details) {
          final String name = details.text;
          return ChartAxisLabel(
            name.length > 10 ? '${name.substring(0, 10)}...' : name,
            details.textStyle,
          );
        },
      ),
      primaryYAxis: const NumericAxis(
        axisLine: AxisLine(width: 0),
        labelFormat: '{value}',
        majorTickLines: MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(width: 1),
        rangePadding: ChartRangePadding.additional,
      ),
      series: <ColumnSeries<_ChartData, String>>[
        ColumnSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          color: Color(0xFF4E79A7), // Blue color for members
          name: 'Total Members',
          width: 0.3,
          spacing: 0.1,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(fontSize: 10),
          ),
        ),
        ColumnSeries<_ChartData, String>(
          dataSource: chartData,
          color: Color(0xFFF28E2B), // Orange color for land area
          name: 'Total Land Area (ha)',
          width: 0.3,
          spacing: 0.1,
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y2,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(fontSize: 10),
          ),
        ),
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: '',
        canShowMarker: false,
        textStyle: TextStyle(color: isDark ? Colors.black : Colors.grey),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y, this.y2);

  final String x; // Association name
  final double y; // Total members
  final double y2; // Total land area in hectares
}
