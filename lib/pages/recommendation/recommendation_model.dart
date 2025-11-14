import 'package:flareline/pages/recommendation/api_uri.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationModel extends ChangeNotifier {
  String selectedModel = 'Random Forest';
  double soil_ph = 6.2;
  double fertility_ec = 1443;
  double sunlight = 44844;
  double soil_temp = 25.8;
  double humidity = 68;
  double soil_moisture = 63;

  String? recommendationResult;
  bool isLoading = false;
  Map<String, dynamic>? predictionResult;
  String? predictedCrop;
  String? modelAccuracy;

  final Map<String, Map<String, double>> models = {
    'Random Forest': {'accuracy': 0.9924},
    'Decision Tree': {'accuracy': 0.9848},
    'Logistic Regression': {'accuracy': 0.9590},
    'XGBoost': {'accuracy': 0.9590},
    'All Models': {'accuracy': 0.0}, // Will be calculated based on ensemble
  };

  Future<void> predictCrop() async {
    isLoading = true;
    predictionResult = null;
    notifyListeners();

    // Add 10-second delay for testing
    // await Future.delayed(const Duration(seconds: 10));

    final uri = Uri.parse(ApiConstants.predict);
    try {
      // Prepare selected models array
      List<String> selectedModels = [];
      if (selectedModel != 'All Models') {
        selectedModels.add(selectedModel);
      }
      // If 'All Models' is selected, we send empty array (API will use all models)

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "request": {
            "soil_ph": soil_ph,
            "fertility_ec": fertility_ec,
            "humidity": humidity,
            "sunlight": sunlight,
            "soil_temp": soil_temp,
            "soil_moisture": soil_moisture,
          },
          "selected_models": selectedModels
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        predictionResult = data;
        // Update based on API response structure
        predictedCrop = data['recommendations'][0]['crop'];
        modelAccuracy = data['model_accuracy'].toString();
      } else {
        ToastHelper.showErrorToast(
          'Failed to load  load prediction',
          'a' as BuildContext,
        );

        throw Exception('Failed to load prediction: ${response.statusCode}');
      }
    } catch (e) {
      // You might want to handle this error in the UI
      print("Error: $e");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
