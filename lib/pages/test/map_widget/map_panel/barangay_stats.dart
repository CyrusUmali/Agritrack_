import 'package:flutter/material.dart';
import '../polygon_manager.dart';

class BarangayStats {
  static Widget build({
    required PolygonData barangay,
    required List<PolygonData> farms,
    required ThemeData theme,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatItem('Total Farms', farms.length.toString(), theme),
            // if (barangay.area != null)
            //   _buildStatItem('Total Area',
            //       '${barangay.area!.toStringAsFixed(2)} ha', theme),
            // Add more stats as needed
          ],
        ),
      ),
    );
  }

  static Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}
