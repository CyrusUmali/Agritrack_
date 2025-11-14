import 'package:flutter/material.dart';
import 'recommendation_model.dart';

class RecommendationInputs extends StatelessWidget {
  final RecommendationModel model;
  final bool isMobile;
  final VoidCallback onChanged; // Add this

  const RecommendationInputs({
    super.key,
    required this.model,
    required this.isMobile,
    required this.onChanged, // Add this
  });

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? _buildMobileInputs(context)
        : _buildDesktopInputs(context);
  }

  Widget _buildDesktopInputs(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildSlider(context, 'Soil Ph ', model.soil_ph, 0, 10, (value) {
                model.soil_ph = value;
                onChanged(); // Trigger rebuild
              }),
              const SizedBox(height: 16),
              _buildSlider(
                  context, 'Soil Fertility us/cm', model.fertility_ec, 0, 3000,
                  (value) {
                model.fertility_ec = value;
                onChanged(); // Trigger rebuild
              }),
              const SizedBox(height: 16),
              _buildSlider(
                  context, 'Soil Moisture (%)', model.soil_moisture, 0, 99,
                  (value) {
                model.soil_moisture = value;
                onChanged(); // Trigger rebuild
              }),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildSlider(context, 'Humidity (%)', model.humidity, 0, 99,
                  (value) {
                model.humidity = value;
                onChanged(); // Trigger rebuild
              }),
              const SizedBox(height: 16),
              _buildSlider(context, 'Soil Temp (°C)', model.soil_temp, -10, 50,
                  (value) {
                model.soil_temp = value;
                onChanged(); // Trigger rebuild
              }),
              const SizedBox(height: 16),
              _buildSlider(context, 'Sunlight (lux)', model.sunlight, 0, 100000,
                  (value) {
                model.sunlight = value;
                onChanged(); // Trigger rebuild
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileInputs(BuildContext context) {
    return Column(
      children: [
        _buildSlider(context, 'Soil Ph', model.soil_ph, 0, 10, (value) {
          model.soil_ph = value;
          onChanged(); // Add this
        }),
        const SizedBox(height: 16),
        _buildSlider(context, 'Soil Fertility (%)', model.fertility_ec, 0, 3000,
            (value) {
          model.fertility_ec = value;
          onChanged(); // Add this
        }),
        const SizedBox(height: 16),
        _buildSlider(context, 'Soil Moisture (%)', model.soil_moisture, 0, 99,
            (value) {
          model.soil_moisture = value;
          onChanged(); // Add this
        }),
        const SizedBox(height: 16),
        _buildSlider(context, 'Soil Temp (°C)', model.soil_temp, -10, 50,
            (value) {
          model.soil_temp = value;
          onChanged(); // Add this
        }),
        const SizedBox(height: 16),
        _buildSlider(context, 'Humidity (%)', model.humidity, 0, 99, (value) {
          model.humidity = value;
          onChanged(); // Add this
        }),
        const SizedBox(height: 16),
        _buildSlider(context, 'Sunlight (lux)', model.sunlight, 0, 100000,
            (value) {
          model.sunlight = value;
          onChanged(); // Add this
        }),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context, // Add context parameter here
    String label,
    double currentValue,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    Color activeColor = Colors.blue,
    Color inactiveColor = Colors.grey,
    double trackHeight = 1.0,
    double thumbRadius = 4.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            inactiveTrackColor: inactiveColor,
            trackHeight: trackHeight,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: thumbRadius,
              disabledThumbRadius: thumbRadius,
              elevation: 2.0,
              pressedElevation: 6.0,
            ),
            overlayShape: RoundSliderOverlayShape(
              overlayRadius: thumbRadius * 1.8,
            ),
            thumbColor: activeColor,
            overlayColor: activeColor.withOpacity(0.2),
            valueIndicatorColor: activeColor,
            valueIndicatorTextStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          child: Slider(
            value: currentValue,
            min: min,
            max: max,
            divisions: 100,
            label: currentValue.toStringAsFixed(1),
            onChanged: (value) {
              onChanged(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              min.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              currentValue.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: activeColor,
              ),
            ),
            Text(
              max.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
