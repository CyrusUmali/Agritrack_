import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportCharts extends StatelessWidget {
  final String reportType;
  final Map<String, dynamic> chartData;

  const ReportCharts({
    super.key,
    required this.reportType,
    required this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visualization',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    switch (reportType) {
      case 'farmers':
        return _buildBarChart();
      case 'farms':
        return _buildPieChart();
      case 'crops':
        return _buildLineChart();
      case 'barangay':
        return _buildBarChart();
      case 'sectors':
        return _buildRadarChart();
      case 'comparison':
        return _buildComparisonChart();
      default:
        return const Center(child: Text('No chart available for this report'));
    }
  }

  Widget _buildBarChart() {
    final List<BarChartGroupData> barGroups = [
      // Sample data - replace with your actual data
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: 8,
            color: Colors.blue,
            width: 15,
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: 10,
            color: Colors.green,
            width: 15,
          ),
        ],
      ),
      // Add more groups as needed
    ];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['Brgy. 1', 'Brgy. 2'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(labels[value.toInt()]),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        gridData: FlGridData(show: false),
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 70,
        sections: [
          PieChartSectionData(
            color: Colors.blue,
            value: 40,
            title: 'Crop',
            radius: 25,
          ),
          PieChartSectionData(
            color: Colors.green,
            value: 30,
            title: 'Livestock',
            radius: 25,
          ),
          PieChartSectionData(
            color: Colors.orange,
            value: 30,
            title: 'Fishery',
            radius: 25,
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 3),
              FlSpot(1, 1),
              FlSpot(2, 4),
              FlSpot(3, 2),
              FlSpot(4, 5),
            ],
            isCurved: true,
            color: Colors.blue,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: [
              RadarEntry(value: 100),
              RadarEntry(value: 80),
              RadarEntry(value: 90),
              RadarEntry(value: 70),
              RadarEntry(value: 85),
            ],
            fillColor: Colors.blue.withOpacity(0.3),
            borderColor: Colors.blue,
            borderWidth: 2,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 12),
        radarBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
        tickCount: 5,
        ticksTextStyle: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
    );
  }

  Widget _buildComparisonChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(toY: 10, color: Colors.blue),
              BarChartRodData(toY: 15, color: Colors.green),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(toY: 12, color: Colors.blue),
              BarChartRodData(toY: 18, color: Colors.green),
            ],
          ),
        ],
        alignment: BarChartAlignment.spaceBetween,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['2022', '2023'];
                return Text(labels[value.toInt()]);
              },
            ),
          ),
        ),
      ),
    );
  }
}
