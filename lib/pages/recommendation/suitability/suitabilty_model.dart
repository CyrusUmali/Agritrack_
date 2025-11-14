import 'package:flareline/pages/recommendation/api_uri.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flareline/providers/language_provider.dart'; // Import the language provider

class SuitabilityModel extends ChangeNotifier {
  final LanguageProvider languageProvider; // Add this field

  SuitabilityModel({required this.languageProvider}); // Modify constructor

  // Model selection
  String selectedModel = 'Random Forest';
  String? selectedCrop; // Added for crop suitability check
  bool _isStreamingSuggestions = false;

  bool get isStreamingSuggestions => _isStreamingSuggestions;
  // Input parameters

  double soil_ph = 6.2;
  double fertility_ec = 1443;
  double sunlight = 44844;
  double soil_temp = 25.8;
  double humidity = 68;
  double soil_moisture = 63;

  // Results
  bool isLoading = false;
  Map<String, dynamic>? suitabilityResult; // Changed from predictionResult
  String? modelAccuracy;

  // Available models with accuracy
  final Map<String, Map<String, double>> models = {
    'Random Forest': {'accuracy': 0.9924},
    'Decision Tree': {'accuracy': 0.9848},
    'Logistic Regression': {'accuracy': 0.9590},
    'XGBoost': {'accuracy': 0.9590},
    'All Models': {'accuracy': 0.0}, // Will be calculated based on ensemble
  };

  Future<void> checkSuitability() async {
    if (selectedCrop == null) {
      throw Exception('Please select a crop first');
    }

    isLoading = true;
    suitabilityResult = null;
    notifyListeners();

    final uri = Uri.parse(ApiConstants.checkSuitability);
    //  final uri = Uri.parse('http://localhost:8000/api/v1/check-suitability');

    try {
      // Prepare selected models array
      List<String> selectedModels = [];
      if (selectedModel != 'All Models') {
        selectedModels.add(selectedModel);
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "soil_ph": soil_ph,
          "fertility_ec": fertility_ec,
          "humidity": humidity,
          "sunlight": sunlight,
          "soil_temp": soil_temp,
          "soil_moisture": soil_moisture,
          "crop": selectedCrop,
          "selected_models": selectedModels.isEmpty ? null : selectedModels
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        suitabilityResult = data;

        // Calculate average confidence if multiple models were used
        if (selectedModel == 'All Models' && data['model_used'] is List) {
          final modelsUsed = (data['model_used'] as List).length;
          modelAccuracy =
              'Average confidence: ${(data['confidence'] * 100).toStringAsFixed(2)}% (${modelsUsed} models)';
        } else {
          modelAccuracy =
              'Confidence: ${(data['confidence'] * 100).toStringAsFixed(2)}%';
        }
      } else {
        throw Exception('Failed to check suitability: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getSuggestionsStream(
    List<String> deficientParams, {
    required String languageCode,
  }) async {
    _isStreamingSuggestions = true;
    suitabilityResult = {
      ...?suitabilityResult,
      'suggestions': [],
    };
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/get-suggestions-stream');
      final request = http.Request('POST', uri)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          "parameters": {
            "soil_ph": soil_ph,
            "fertility_ec": fertility_ec,
            "humidity": humidity,
            "sunlight": sunlight,
            "soil_temp": soil_temp,
            "soil_moisture": soil_moisture,
            "crop": selectedCrop,
          },
          "deficient_params": deficientParams,
          "language": languageCode, // Add language parameter
        });

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final stream = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        String currentSection = '';
        await for (final chunk in stream) {
          // Check if this chunk starts a new section
          if (chunk.startsWith('- ') && chunk.endsWith(':')) {
            // If we have a current section, add it before starting new one
            if (currentSection.isNotEmpty) {
              suitabilityResult = {
                ...?suitabilityResult,
                'suggestions': [
                  ...(suitabilityResult?['suggestions'] as List),
                  currentSection.trim()
                ],
              };
              notifyListeners();
            }
            currentSection = chunk;
          } else {
            // Append to current section
            currentSection += '\n$chunk';
          }
        }

        // Add the last section if it exists
        if (currentSection.isNotEmpty) {
          suitabilityResult = {
            ...?suitabilityResult,
            'suggestions': [
              ...(suitabilityResult?['suggestions'] as List),
              currentSection.trim()
            ],
          };
          notifyListeners();
        }
      } else {
        throw Exception('Failed to stream suggestions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Stream error: $e');
      suitabilityResult = {
        ...?suitabilityResult,
        'suggestions': ['Error: ${e.toString()}'],
      };
      notifyListeners();
    } finally {
      _isStreamingSuggestions = false;
      notifyListeners();
    }
  }
}
