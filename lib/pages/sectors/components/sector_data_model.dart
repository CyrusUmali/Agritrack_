import 'package:flareline/core/models/yield_model.dart';
import 'package:flutter/material.dart';

class SectorData {
  final String name;
  final Color color;
  final List<Map<String, dynamic>> data;
  final Map<String, String>? annotations;

  SectorData({
    required this.name,
    required this.color,
    required this.data,
    this.annotations,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color, 
      'data': data,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color.value.toRadixString(16),
      'data': data,
      'annotations': annotations,
    };
  }

  @override
  String toString() {
    return 'SectorData(name: $name, color: $color, data: $data, annotations: $annotations)';
  }
}

// 8 fixed colors
const List<Color> fixedColors = [
  Colors.blue, 
  Colors.red,
  Colors.green,
  Colors.yellow,
  Colors.purple,
  Colors.orange,
  Colors.teal,
  Colors.pink,
];

Map<String, List<SectorData>> sectorData = {
  // We'll build this dynamically from yieldData
};

Map<String, List<SectorData>> buildSectorDataFromYields(List<Yield> yields) {
  // First filter the yields to only include Accepted records
  final acceptedYields =
      yields.where((yield) => yield.status == 'Accepted').toList();

  final sectorMap = <String, List<SectorData>>{};
  int colorIndex = 0; // Index for fixed colors

  // First group by sector
  final yieldsBySector = <String, List<Yield>>{};
  for (final yield in acceptedYields) {
    // Use filtered yields here
    final sector = yield.sector ?? 'Unknown';
    yieldsBySector.putIfAbsent(sector, () => []).add(yield);
  }

  // Then for each sector, group by product and create SectorData objects
  yieldsBySector.forEach((sector, sectorYields) {
    final productsMap =
        <String, Map<String, double>>{}; // product -> year -> total volume
    final productColors = <String, Color>{};

    // Group yields by product and aggregate by year
    for (final yield in sectorYields) {
      final productName = yield.productName ?? 'Unknown';
      final year = yield.harvestDate?.year.toString() ?? '2023';
      final volume = yield.volume ?? 0;

      // Initialize product map if not exists
      if (!productsMap.containsKey(productName)) {
        productsMap[productName] = {};

        // Assign color from fixed colors, cycling through them
        productColors[productName] = fixedColors[colorIndex % fixedColors.length];
        colorIndex++;
      }

      // Aggregate volumes by year
      productsMap[productName]!.update(
        year,
        (value) => value + volume,
        ifAbsent: () => volume,
      );
    }

    // Create SectorData objects for each product
    final sectorDataList = productsMap.entries.map((entry) {
      // Convert the year-volume map to data points
      final dataPoints = entry.value.entries.map((yearVolume) {
        return {
          'x': yearVolume.key,
          'y': yearVolume.value,
        };
      }).toList();

      // Sort by year in ascending order
      dataPoints.sort((a, b) {
        final aYear = int.tryParse(a['x']?.toString() ?? '0') ?? 0;
        final bYear = int.tryParse(b['x']?.toString() ?? '0') ?? 0;
        return aYear.compareTo(bYear);
      });

      return SectorData(
        name: entry.key,
        color: productColors[entry.key]!,
        data: dataPoints,
      );
    }).toList();

    sectorMap[sector] = sectorDataList;
  });

  return sectorMap;
}