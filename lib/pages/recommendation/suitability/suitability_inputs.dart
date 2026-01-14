import 'package:flareline/pages/recommendation/suitability/suitabilty_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 

class SuitabilityInputs extends StatefulWidget {
  final SuitabilityModel model;
  final bool isMobile;
  final VoidCallback onChanged;

  const SuitabilityInputs({
    super.key,
    required this.model,
    required this.isMobile,
    required this.onChanged,
  });

  @override
  State<SuitabilityInputs> createState() => _SuitabilityInputsState();
}

class _SuitabilityInputsState extends State<SuitabilityInputs> {
  // Controllers for each slider's text field
  late Map<String, TextEditingController> _controllers;
  late Map<String, double> _currentValues;
  late Map<String, FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(SuitabilityInputs oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controllers when model values change externally
    if (oldWidget.model != widget.model) {
      _updateControllerValues();
    }
  }

  void _initializeControllers() {
    _controllers = {};
    _currentValues = {};
    _focusNodes = {};
    
    final fields = {
      'soil_ph': widget.model.soil_ph,
      'fertility_ec': widget.model.fertility_ec,
      'soil_moisture': widget.model.soil_moisture,
      'humidity': widget.model.humidity,
      'soil_temp': widget.model.soil_temp,
      'sunlight': widget.model.sunlight,
    };
    
    fields.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value.toStringAsFixed(1));
      _currentValues[key] = value;
      _focusNodes[key] = FocusNode()
        ..addListener(() {
          // When focus is lost, validate and update the value
          if (!_focusNodes[key]!.hasFocus) {
            _validateAndUpdateTextField(key);
          }
        });
    });
  }

  void _updateControllerValues() {
    final fields = {
      'soil_ph': widget.model.soil_ph,
      'fertility_ec': widget.model.fertility_ec,
      'soil_moisture': widget.model.soil_moisture,
      'humidity': widget.model.humidity,
      'soil_temp': widget.model.soil_temp,
      'sunlight': widget.model.sunlight,
    };
    
    fields.forEach((key, value) {
      _controllers[key]?.text = value.toStringAsFixed(1);
      _currentValues[key] = value;
    });
  }

  void _updateValue(String key, double value) {
    if (_currentValues[key] == value) return;
    
    setState(() {
      _currentValues[key] = value;
    });
    
    // Update the text controller
    _controllers[key]?.text = value.toStringAsFixed(1);
    
    // Update the model based on the key
    switch (key) {
      case 'soil_ph':
        widget.model.soil_ph = value;
        break;
      case 'fertility_ec':
        widget.model.fertility_ec = value;
        break;
      case 'soil_moisture':
        widget.model.soil_moisture = value;
        break;
      case 'humidity':
        widget.model.humidity = value;
        break;
      case 'soil_temp':
        widget.model.soil_temp = value;
        break;
      case 'sunlight':
        widget.model.sunlight = value;
        break;
    }
    
    widget.onChanged();
  }

  void _validateAndUpdateTextField(String key) {
    final controller = _controllers[key];
    if (controller == null) return;

    final text = controller.text.trim();
    final numValue = double.tryParse(text);
    final min = _getMinValue(key);
    final max = _getMaxValue(key);

    if (numValue != null) {
      final clampedValue = numValue.clamp(min, max);
      if (_currentValues[key] != clampedValue) {
        _updateValue(key, clampedValue);
      } else {
        // If value hasn't changed, still update the text to ensure correct formatting
        controller.text = clampedValue.toStringAsFixed(1);
      }
    } else {
      // If invalid input, reset to current value
      controller.text = _currentValues[key]!.toStringAsFixed(1);
    }
  }

  double _getMinValue(String key) {
    switch (key) {
      case 'soil_ph': return 0;
      case 'fertility_ec': return 0;
      case 'soil_moisture': return 0;
      case 'humidity': return 0;
      case 'soil_temp': return -10;
      case 'sunlight': return 0;
      default: return 0;
    }
  }

  double _getMaxValue(String key) {
    switch (key) {
      case 'soil_ph': return 10;
      case 'fertility_ec': return 3000;
      case 'soil_moisture': return 99;
      case 'humidity': return 99;
      case 'soil_temp': return 50;
      case 'sunlight': return 100000;
      default: return 100;
    }
  }

  @override
  void dispose() {
    // Dispose all controllers and focus nodes
    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((focusNode) => focusNode.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isMobile
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
              _buildSlider(context, 'Soil Ph', 'soil_ph', 0, 10),
              const SizedBox(height: 16),
              _buildSlider(context, 'Soil Fertility us/cm', 'fertility_ec', 0, 3000),
              const SizedBox(height: 16),
              _buildSlider(context, 'Soil Moisture (%)', 'soil_moisture', 0, 99),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildSlider(context, 'Humidity (%)', 'humidity', 0, 99),
              const SizedBox(height: 16),
              _buildSlider(context, 'Soil Temp (°C)', 'soil_temp', -10, 50),
              const SizedBox(height: 16),
              _buildSlider(context, 'Sunlight (lux)', 'sunlight', 0, 100000),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileInputs(BuildContext context) {
    return Column(
      children: [
        _buildSlider(context, 'Soil Ph', 'soil_ph', 0, 10),
        const SizedBox(height: 16),
      _buildSlider(context, 'Humidity (%)', 'humidity', 0, 99),
        const SizedBox(height: 16),

        _buildSlider(context, 'Soil Fertility us/cm', 'fertility_ec', 0, 3000),
        const SizedBox(height: 16),
         _buildSlider(context, 'Soil Temp (°C)', 'soil_temp', -10, 50),
        const SizedBox(height: 16),
        _buildSlider(context, 'Soil Moisture (%)', 'soil_moisture', 0, 99),
        const SizedBox(height: 16),
       
       
        
        _buildSlider(context, 'Sunlight (lux)', 'sunlight', 0, 100000),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    String key,
    double min,
    double max, {
    Color activeColor = Colors.blue,
    Color inactiveColor = Colors.grey,
    double trackHeight = 1.0,
    double thumbRadius = 4.0,
  }) {
    final currentValue = _currentValues[key] ?? 0;
    final controller = _controllers[key]!;
    final focusNode = _focusNodes[key]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
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
                  _updateValue(key, value);
                },
              ),
            ),
            const SizedBox(height: 4),
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
                SizedBox(
                  width: max >= 10000 ? 100 : 80,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,1}$')),
                    ],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onSubmitted: (value) {
                      _validateAndUpdateTextField(key);
                      focusNode.unfocus();
                    },
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
        ),
      ],
    );
  }
}