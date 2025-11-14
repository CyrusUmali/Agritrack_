import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../components/sector_data_model.dart';

// Enhanced annotation data structure
class AnnotationData {
  final String text;
  final dynamic x;
  final dynamic y;
  final CoordinateUnit coordinateUnit;
  final AnnotationRegion region;
  final ChartAlignment horizontalAlignment;
  final ChartAlignment verticalAlignment;
  final IconData? icon;
  final Color? color;

  const AnnotationData({
    required this.text,
    required this.x,
    required this.y,
    this.coordinateUnit = CoordinateUnit.point,
    this.region = AnnotationRegion.chart,
    this.horizontalAlignment = ChartAlignment.center,
    this.verticalAlignment = ChartAlignment.center,
    this.icon,
    this.color,
  });
}

class SectorLineChartWidget extends StatelessWidget {
  final String title;
  final List<SectorData> datas;
  final List<String> dropdownItems;
  final List<CartesianChartAnnotation>? annotations;
  final List<AnnotationData>? annotationData;
  final String unit;

  const SectorLineChartWidget({
    super.key,
    required this.title,
    required this.datas,
    required this.dropdownItems,
    this.annotations,
    this.annotationData,
    this.unit = 'mt',
  });

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      annotations: _getAllAnnotations(),
      plotAreaBorderWidth: 0,
      title: ChartTitle(
        text: title,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        alignment: ChartAlignment.near,
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.right,
        orientation: LegendItemOrientation.vertical,
        overflowMode: LegendItemOverflowMode.scroll,
        itemPadding: 8,
        height: '300',
      ),
      primaryXAxis: CategoryAxis(
        labelStyle: const TextStyle(fontWeight: FontWeight.normal),
        majorGridLines: const MajorGridLines(
            width: 1, color: Color.fromARGB(255, 230, 229, 229)),
        majorTickLines: const MajorTickLines(width: 0),
        axisLine: const AxisLine(width: 1, color: Colors.black),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Production ($unit)'),
        labelFormat: '{value}',
        numberFormat: NumberFormat("#,###"),
        axisLine: const AxisLine(width: 1, color: Colors.black),
        majorGridLines: const MajorGridLines(
            width: 1, color: Color.fromARGB(255, 230, 229, 229)),
        majorTickLines: const MajorTickLines(width: 0),
      ),
      series: _getLineSeries(),
      tooltipBehavior: _buildTooltipBehavior(),
    );
  }

  List<CartesianChartAnnotation> _getAllAnnotations() {
    final allAnnotations = <CartesianChartAnnotation>[];
    int annotationCounter = 0;

    // Handle new annotation data structure
    if (annotationData != null) {
      for (final annotation in annotationData!) {
        allAnnotations.add(
          CartesianChartAnnotation(
            widget:
                _buildAnnotationWidgetFromData(annotation, annotationCounter++),
            coordinateUnit: annotation.coordinateUnit,
            region: annotation.region,
            x: annotation.x,
            y: annotation.y,
            horizontalAlignment: annotation.horizontalAlignment,
            verticalAlignment: annotation.verticalAlignment,
          ),
        );
      }
    }

    // Handle legacy annotations
    if (annotations != null) {
      for (final annotation in annotations!) {
        allAnnotations.add(
          CartesianChartAnnotation(
            widget: annotation.widget, // Keep original widget
            coordinateUnit: annotation.coordinateUnit,
            region: annotation.region,
            x: annotation.x,
            y: annotation.y,
            horizontalAlignment: annotation.horizontalAlignment,
            verticalAlignment: annotation.verticalAlignment,
          ),
        );
      }
    }

    return allAnnotations;
  }

  Widget _buildAnnotationWidgetFromData(AnnotationData annotation, int index) {
    return Container(
      key: ValueKey('annotation_$index'),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: annotation.color ?? Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Icon(
        annotation.icon ?? Icons.info,
        color: Colors.white,
        size: 12,
      ),
    );
  }

  List<LineSeries<Map<String, dynamic>, String>> _getLineSeries() {
    return datas.map((sector) {
      return LineSeries<Map<String, dynamic>, String>(
        name: sector.name,
        color: sector.color,
        dataSource: sector.data,
        xValueMapper: (Map<String, dynamic> data, _) => data['x'] as String,
        yValueMapper: (Map<String, dynamic> data, _) => data['y'] as num,
        markerSettings: const MarkerSettings(isVisible: true),
        // Add this to enable tooltips for the series points
        enableTooltip: true,
      );
    }).toList();
  }

  TooltipBehavior _buildTooltipBehavior() {
    return TooltipBehavior(
      enable: true,
      header: '',
      canShowMarker: true,
      // Add this to ensure tooltips work properly
      shouldAlwaysShow: false,
      activationMode: ActivationMode.singleTap,
       color: Colors.black,
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
          int seriesIndex) {
        final note = series.dataSource[pointIndex]['note'];
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${data['x']}: ${NumberFormat("#,###").format(data['y'])} $unit',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (note != null)
                Text(
                  note,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        );
      },
    );
  }
}
