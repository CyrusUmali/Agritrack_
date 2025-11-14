import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';

class YieldPredictionCard extends StatelessWidget {
  final String cropName;
  final String predictedYield;
  final String season;
  final String confidence;

  const YieldPredictionCard({
    super.key,
    required this.cropName,
    required this.predictedYield,
    required this.season,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Clean padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yield Prediction',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildRow(context, 'Crop:', cropName),
            const SizedBox(height: 12),
            _buildRow(context, 'Predicted Yield:', predictedYield),
            const SizedBox(height: 12),
            _buildRow(context, 'Season:', season),
            const SizedBox(height: 12),
            _buildRow(context, 'Confidence Level:', confidence),
            const SizedBox(height: 24),
            Text(
              'Select Crop for Prediction',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildCropOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropOptions(BuildContext context) {
    final crops = [
      {'label': 'Corn', 'icon': Icons.grass},
      {'label': 'Rice', 'icon': Icons.rice_bowl},
      {'label': 'Wheat', 'icon': Icons.eco},
      {'label': 'Tomato', 'icon': Icons.local_pizza},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: crops.map((crop) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(
                    crop['icon'] as IconData,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  crop['label'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
