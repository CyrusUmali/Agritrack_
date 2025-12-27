import 'package:flutter/material.dart';

/// Helper class containing reusable utility methods for suitability analysis
class SuitabilityHelpers {
  // Status info with colors
  static ({Color color, Color backgroundColor, Color borderColor}) getStatusInfo(
      String status, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    switch (status) {
      case 'low':
        return (
          color: isDark ? Colors.orange[400]! : Colors.orange[600]!,
          backgroundColor:
              isDark ? Colors.orange[900]!.withOpacity(0.2) : Colors.orange[50]!,
          borderColor: isDark ? Colors.orange[800]! : Colors.orange[200]!,
        );
      case 'high':
        return (
          color: isDark ? Colors.red[400]! : Colors.red[600]!,
          backgroundColor:
              isDark ? Colors.red[900]!.withOpacity(0.2) : Colors.red[50]!,
          borderColor: isDark ? Colors.red[800]! : Colors.red[200]!,
        );
      default: // 'optimal'
        return (
          color: isDark ? Colors.green[400]! : Colors.green[600]!,
          backgroundColor:
              isDark ? Colors.green[900]!.withOpacity(0.2) : Colors.green[50]!,
          borderColor: isDark ? Colors.green[800]! : Colors.green[200]!,
        );
    }
  }

  // Get icon for parameter
  static IconData getParameterIcon(String parameter) {
    switch (parameter.toLowerCase()) {
      case 'fertility_ec':
        return Icons.eco;
      case 'sunlight':
        return Icons.sunny;
      case 'soil_temp':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'soil_ph':
        return Icons.science;
      case 'soil_moisture':
        return Icons.cloud;
      default:
        return Icons.analytics;
    }
  }

  // Format parameter name for display
  static String formatParameterName(String param) {
    final Map<String, String> paramNames = {
      'soil_ph': 'Soil pH',
      'humidity': 'Humidity',
      'fertility_ec': 'Soil Fertility',
      'soil_moisture': 'Soil Moisture',
      'soil_temp': 'Soil Temperature',
      'sunlight': 'Sunlight',
    };
    return paramNames[param] ?? param;
  }

  // Get overall score color
 static Color getOverallScoreColor(dynamic optimal, [int? total]) {
    if (optimal is double) {
      // Decimal confidence mode (0.0 to 1.0)
      return _getColorFromDecimal(optimal);
    } else if (optimal is int && total != null) {
      // Counts mode
      if (total == 0) return Colors.grey[600]!;
      final percentage = optimal / total;
      return _getColorFromDecimal(percentage);
    }
    return Colors.grey[600]!;
  }

   static Color _getColorFromDecimal(double confidence) {
    if (confidence >= 0.8) return Colors.green[600]!;
    if (confidence >= 0.6) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  // Get confidence color
  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green[600]!;
    if (confidence >= 0.6) return Colors.orange[600]!;
    return Colors.red[600]!;
  } 

  // Calculate progress value for progress bar
  static double calculateProgressValue(double current, double min, double max) {
    final range = max - min;
    if (range == 0) return 1.0;
    if (current < min) return (current / min).clamp(0.0, 0.3);
    if (current > max) return ((current - max) / max + 1.0).clamp(0.7, 1.0);
    return ((current - min) / range).clamp(0.3, 0.7);
  }

  // Get progress bar color
  static Color getProgressBarColor(double current, double min, double max) {
    if (current < min * 0.8) return Colors.orange[400]!;
    if (current > max * 1.2) return Colors.red[500]!;
    if (current < min || current > max) return Colors.deepOrange[400]!;
    return Colors.green[600]!;
  }
}