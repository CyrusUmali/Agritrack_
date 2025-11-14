// report_generator.dart
import 'dart:math';

import 'package:flareline/services/report_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportGenerator {
  // Helper method to capitalize first character of each word

  static String _capitalizeColumnName(String columnName) {
    if (columnName.isEmpty) return columnName;

    // Handle common abbreviations and special cases
    final specialCases = {
      'id': 'ID',
      'uuid': 'UUID',
      'gps': 'GPS',
      'ha': 'Hectares',
      'kg': 'Kilograms',
    };

    if (specialCases.containsKey(columnName.toLowerCase())) {
      return specialCases[columnName.toLowerCase()]!;
    }

    // Check if the column name contains special formatting patterns like '(Mt | Heads)'
    // and preserve them as-is
    final specialFormattingPattern = RegExp(r'\([^)]+\|[^)]+\)');
    if (specialFormattingPattern.hasMatch(columnName)) {
      return columnName; // Return as-is without modification
    }

    // Split by common separators and capitalize each word
    final words = columnName.split(RegExp(r'[_\s]+'));
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return word;

      // Handle camelCase by detecting capital letters
      if (word.contains(RegExp(r'[a-z][A-Z]'))) {
        // Insert space before capital letters in camelCase
        final separated = word.replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
            (match) => '${match.group(1)} ${match.group(2)}');
        return separated.split(' ').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');
      }

      // Standard word capitalization
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return capitalizedWords.join(' ');
  }

  // Method to format all column names in a data row
  static Map<String, dynamic> _formatColumnNames(Map<String, dynamic> row) {
    final formattedRow = <String, dynamic>{};

    row.forEach((key, value) {
      final formattedKey = _capitalizeColumnName(key);
      formattedRow[formattedKey] = value;
    });

    return formattedRow;
  }

  // Method to format entire dataset
  static List<Map<String, dynamic>> _formatDataset(
      List<Map<String, dynamic>> data) {
    return data.map(_formatColumnNames).toList();
  }

  static Future<List<Map<String, dynamic>>> generateReport({
    required BuildContext context,
    required String reportType,
    DateTimeRange? dateRange,
    required String selectedBarangay,
    required String selectedSector,
    required String selectedView,
    required String selectedProduct,
    required String selectedAssoc,
    required String selectedFarm,
    required String selectedCount,
    required selectedFarmer,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    print(reportType);

    List<Map<String, dynamic>> rawData;

    switch (reportType) {
      case 'farmers':
        rawData = await _generateFarmersData(
          context: context,
          selectedBarangay:
              selectedBarangay.isNotEmpty ? selectedBarangay : null,
          selectedSector: selectedSector.isNotEmpty ? selectedSector : null,
          selectedAssoc: selectedAssoc.isNotEmpty ? selectedAssoc : null,
          selectedCount: selectedCount.isNotEmpty ? selectedCount : null,
        );
        break;
      case 'farmer':
        rawData = await _generateFarmerYieldData(
          context: context,
          farmerId: selectedFarmer.isNotEmpty ? selectedFarmer : null,
          productId: selectedProduct.isNotEmpty ? selectedProduct : null,
          farmId: selectedFarm.isNotEmpty ? selectedFarm : null,
          startDate: dateRange?.start.toString(),
          endDate: dateRange?.end.toString(),
          viewBy: selectedView.isNotEmpty ? selectedView : null,
          selectedAssoc: selectedAssoc.isNotEmpty ? selectedAssoc : null,
          selectedCount: selectedCount.isNotEmpty ? selectedCount : null,
        );
        break;
      case 'products':
        rawData = await _generateProductsData(
          context: context,
          dateRange: dateRange,
          selectedBarangay: selectedBarangay,
          selectedSector: selectedSector,
          selectedView: selectedView,
          selectedProduct: selectedProduct,
          selectedCount: selectedCount.isNotEmpty ? selectedCount : null,
        );
        break;
      case 'barangay':
        rawData = await _generateBarangayData(
          context: context,
          dateRange: dateRange,
          selectedBarangay: selectedBarangay,
          selectedSector: selectedSector,
          selectedView: selectedView,
          selectedProduct: selectedProduct,
          selectedCount: selectedCount.isNotEmpty ? selectedCount : null,
        );
        break;
      case 'sectors':
        rawData = await _generateSectorsData(
          context: context,
          dateRange: dateRange,
          selectedSector: selectedSector,
          selectedView: selectedView,
          selectedCount: selectedCount.isNotEmpty ? selectedCount : null,
        );
        break;
      default:
        rawData = [];
        break;
    }

    // Format column names before returning
    return _formatDataset(rawData);
  }

  static Future<List<Map<String, dynamic>>> _generateSectorsData({
    required BuildContext context,
    DateTimeRange? dateRange,
    String? selectedSector,
    String? selectedView,
    String? selectedCount,
  }) async {
    final reportService = RepositoryProvider.of<ReportService>(context);

    final data = await reportService.fetchSectorYields(
        viewBy: selectedView,
        sectorId: selectedSector,
        startDate: dateRange?.start.toString(),
        endDate: dateRange?.end.toString(),
        count: selectedCount);

    return data;
  }

  static Future<List<Map<String, dynamic>>> _generateBarangayData({
    required BuildContext context,
    DateTimeRange? dateRange,
    String? selectedBarangay,
    String? selectedSector,
    String? selectedView,
    String? selectedProduct,
    String? selectedCount,
  }) async {
    final reportService = RepositoryProvider.of<ReportService>(context);

    final data = await reportService.fetchBarangayYields(
        viewBy: selectedView,
        productId: selectedProduct,
        sectorId: selectedSector,
        barangay: selectedBarangay,
        startDate: dateRange?.start.toString(),
        endDate: dateRange?.end.toString(),
        count: selectedCount);

    return data;
  }

  static Future<List<Map<String, dynamic>>> _generateProductsData({
    required BuildContext context,
    DateTimeRange? dateRange,
    String? selectedBarangay,
    String? selectedSector,
    String? selectedView,
    String? selectedProduct,
    String? selectedCount,
  }) async {
    final reportService = RepositoryProvider.of<ReportService>(context);

    final data = await reportService.fetchProductYields(
        viewBy: selectedView,
        productId: selectedProduct,
        sectorId: selectedSector,
        startDate: dateRange?.start.toString(),
        endDate: dateRange?.end.toString(),
        count: selectedCount);

    return data;
  }

  static Future<List<Map<String, dynamic>>> _generateFarmerYieldData({
    required BuildContext context,
    String? farmerId,
    String? productId,
    String? farmId,
    String? selectedAssoc,
    String? startDate,
    String? endDate,
    String? viewBy,
    String? selectedCount,
  }) async {
    final reportService = RepositoryProvider.of<ReportService>(context);
    final data = await reportService.fetchYields(
        farmerId: farmerId,
        productId: productId,
        farmId: farmId,
        startDate: startDate,
        endDate: endDate,
        association: selectedAssoc,
        viewBy: viewBy,
        count: selectedCount);

    return data;
  }

  static Future<List<Map<String, dynamic>>> _generateFarmersData({
    required BuildContext context,
    String? selectedAssoc,
    String? selectedBarangay,
    String? selectedSector,
    String? selectedCount,
  }) async {
    try {
      final reportService = RepositoryProvider.of<ReportService>(context);
      final farmers = await reportService.fetchFarmers(
          association: selectedAssoc,
          barangay: selectedBarangay,
          sector: selectedSector,
          count: selectedCount);

      return farmers;
    } catch (e) {
      print('Error fetching farmers: $e');
      return [];
    }
  }

  static String buildReportTitle(String reportType, DateTimeRange dateRange) {
    String title =
        '${reportType[0].toUpperCase()}${reportType.substring(1).replaceAll('_', ' ')} Report';

    if (dateRange.start.year != 1970 && dateRange.end.year != 1970) {
      title += ' from ${dateRange.start.toLocal().toString().split(' ')[0]}';
      title += ' to ${dateRange.end.toLocal().toString().split(' ')[0]}';
    }

    return title;
  }
}
