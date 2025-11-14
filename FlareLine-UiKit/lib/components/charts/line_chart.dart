// ignore_for_file: unnecessary_string_interpolations, unnecessary_brace_in_string_interps

import 'dart:math';

import 'package:flareline_uikit/core/mvvm/base_viewmodel.dart';
import 'package:flareline_uikit/core/mvvm/base_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter/material.dart';

import 'package:syncfusion_flutter_charts/charts.dart';

// ignore: must_be_immutable
class LineChartWidget extends BaseWidget<LineChartProvider> {
  final String title;

  final List<Map<String, dynamic>> datas;

  final bool? isDropdownToggle;

  final List<String> dropdownItems;

  final ValueChanged<String>? onDropdownChanged;

  LineChartWidget(
      {super.key,
      required this.title,
      required this.datas,
      this.isDropdownToggle,
      required this.dropdownItems,
      this.onDropdownChanged}) {
    if (dropdownItems.isNotEmpty) {
      valueNotifier = ValueNotifier(dropdownItems[0]);
    } else {
      valueNotifier = ValueNotifier('');
    }
  }

  late ValueNotifier<String> valueNotifier;

  @override
  Widget bodyWidget(
      BuildContext context, LineChartProvider viewModel, Widget? child) {
    return Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            SfCartesianChart(
              annotations: [
                CartesianChartAnnotation(
                  widget: Container(
                    child: Column(
                      children: [
                        Icon(Icons.info, color: Colors.red, size: 20),
                        Text('Drought', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  coordinateUnit: CoordinateUnit.point,
                  x: '2020',
                  y: 19,
                  horizontalAlignment: ChartAlignment.near,
                ),
                // Add more annotations as needed
              ],
              plotAreaBorderWidth: 0,
              title: ChartTitle(
                  text: title,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  alignment: ChartAlignment.near),
              legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.top,
                  textStyle: TextStyle(fontWeight: FontWeight.normal)),
              primaryXAxis: const CategoryAxis(
                labelStyle: TextStyle(fontWeight: FontWeight.normal),
              ),
              primaryYAxis: const NumericAxis(
                  labelStyle: TextStyle(fontWeight: FontWeight.normal),
                  labelFormat: '{value}kg',
                  axisLine: AxisLine(width: 0),
                  majorTickLines: MajorTickLines(color: Colors.transparent)),
              series: _getDefaultLineSeries(context, viewModel),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                header: '',
                canShowMarker: true,
                builder: (dynamic data, dynamic point, dynamic series,
                    int pointIndex, int seriesIndex) {
                  final note = series.dataSource[pointIndex]['note'];
                  return Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${data['x']}: ${data['y']}'),
                        if (note != null)
                          Text(note, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (!(isDropdownToggle ?? false)) dateToggleWidget(context),
            if (isDropdownToggle ?? false) dropdownDateToggleWidget(context)
          ],
        ));
  }

  @override
  LineChartProvider viewModelBuilder(BuildContext context) {
    return LineChartProvider(context);
  }

  Widget dropdownDateToggleWidget(BuildContext context) {
    // Get the current screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Align(
      alignment: Alignment.topRight,
      child: PopupMenuButton<String>(
        onSelected: (String newValue) {
          valueNotifier.value = newValue;
          if (onDropdownChanged != null) {
            onDropdownChanged!(newValue);
          }
        },
        itemBuilder: (BuildContext context) {
          return dropdownItems.map((String item) {
            return PopupMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 8),
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? 100 : 150,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  valueNotifier.value,
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
              Icon(Icons.arrow_drop_down, size: isSmallScreen ? 16 : 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget dateToggleWidget(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.topRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              color: isDark
                  ? FlarelineColors.darkBackground
                  : FlarelineColors.gray,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: dropdownItems.map((item) {
                    return ValueListenableBuilder(
                        valueListenable: valueNotifier,
                        builder: (c, selectedValue, child) {
                          return InkWell(
                              onTap: () {
                                valueNotifier.value = item;
                                if (onDropdownChanged != null) {
                                  onDropdownChanged!(item);
                                }
                              },
                              child: Container(
                                  // ignore: prefer_const_constructors
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: selectedValue == item
                                          ? Theme.of(context)
                                              .appBarTheme
                                              .backgroundColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(2),
                                      border: selectedValue == item
                                          ? Border.all(
                                              width: 1,
                                              color: FlarelineColors.border)
                                          : null),
                                  child: Text(
                                    '${item}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: (isDark
                                            ? Colors.white
                                            : FlarelineColors.darkBackground)),
                                  )));
                        });
                  }).toList()))
        ],
      ),
    );
  }

  List<SplineSeries<dynamic, String>> _getDefaultLineSeries(
      BuildContext context, LineChartProvider viewModel) {
    return datas.map((item) {
      return SplineSeries<dynamic, String>(
        dataSource: item['data'],
        xValueMapper: (dynamic sales, _) => sales['x'],
        yValueMapper: (dynamic sales, _) => sales['y'],
        name: item['name'],
        color: item['color'],
        markerSettings: MarkerSettings(
          isVisible: true,
          shape: DataMarkerType.circle,
          width: 6,
          height: 6,
          borderWidth: 2,
          borderColor: item['color'],
        ),
        // Add special markers for important points
        pointColorMapper: (dynamic data, _) {
          // Highlight specific points (e.g., min/max values)
          final values =
              (item['data'] as List).map((d) => d['y'] as int).toList();
          if (data['y'] == values.reduce(max) ||
              data['y'] == values.reduce(min)) {
            return Colors.red; // Highlight color for min/max points
          }
          return item['color'];
        },
        dataLabelSettings: DataLabelSettings(
          isVisible: false, // We'll use tooltips instead
        ),
        onPointTap: (ChartPointDetails details) {
          // Show a dialog or tooltip when a point is tapped
          final data = details.dataPoints![details.pointIndex!].data;
          _showPointInfo(context, data['note'], data['x'], data['y']);
        },
        onPointDoubleTap: (ChartPointDetails details) {
          // Optional: Handle double tap
        },
        onPointLongPress: (ChartPointDetails details) {
          // Optional: Handle long press
        },
      );
    }).toList();
  }

  void _showPointInfo(BuildContext context, String note, String x, num y) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Point Details ($x)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Value: $y"),
            SizedBox(height: 10),
            Text("Note: $note"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}

class LineChartProvider extends BaseViewModel {
  LineChartProvider(super.context);
}
