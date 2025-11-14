import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BarangayModel {
  BarangayModel(
    this.name, {
    required this.area,
    required this.yieldData,
    this.farmer,
    this.topProducts = const [],
    Color? color,
  }) : color = color ?? Colors.grey;

  final String name;
  final double area;
  final int? farmer;
  final Map<String, double> yieldData;
  final List<String> topProducts;
  Color color;
} 

class GeoJsonParser {
  static Future<List<String>> getBarangayNamesFromAsset(
      String assetPath) async {
    final String data = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> jsonResult = json.decode(data);

    List<String> barangayNames = [];

    if (jsonResult.containsKey('features')) {
      for (var feature in jsonResult['features']) {
        if (feature['properties'] != null &&
            feature['properties']['name'] != null) {
          barangayNames.add(feature['properties']['name'].toString());
        }
      }
    }

    return barangayNames;
  }
}

Color getColorForIndex(int index, int total) {
  final hue = (index * (360.0 / total)) % 360.0;
  return HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor();
}
