import 'dart:async';
import 'dart:io';

import 'package:flareline/pages/recommendation/api_uri.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationModel extends ChangeNotifier {
  String selectedModel = 'Random Forest';
  double soil_ph = 6.6;
  double fertility_ec = 535;
  double sunlight = 2600;
  double soil_temp = 28.7;
  double humidity = 75;
  double soil_moisture = 94;
 
  String? recommendationResult;
  bool isLoading = false;
  Map<String, dynamic>? predictionResult;
  String? predictedCrop;
  String? modelAccuracy;
  String? errorMessage;
  bool hasError = false;

  final Map<String, Map<String, double>> models = {
    'Random Forest': {'accuracy': 0.9924},
    'Decision Tree': {'accuracy': 0.9848},
    'Logistic Regression': {'accuracy': 0.9590},
    'XGBoost': {'accuracy': 0.9590},
    'All Models': {'accuracy': 0.0},
  };

  Future<void> predictCrop({BuildContext? context}) async {
    // Reset state before starting
    isLoading = true;
    hasError = false;
    errorMessage = null;
    predictionResult = null;
    notifyListeners();

    try {
      // 1. Validate input parameters first
      final validationError = _validateInputs();
      if (validationError != null) {
        throw ValidationException(validationError);
      }

      // 2. Check API URI is valid
      if (!_isValidUri(ApiConstants.predict)) {
        throw ConfigurationException('Invalid API endpoint configuration');
      }

      final uri = Uri.parse(ApiConstants.predict);
      
      // 3. Prepare request body with error handling
      final requestBody = _buildRequestBody();

      // 4. Make API call with timeout
      final response = await _makeApiRequest(uri, requestBody);

      // 5. Process response
      await _processResponse(response, context);

    } on ValidationException catch (e) {
      _handleError(e.message, 'Validation Error', context);
    } on ConfigurationException catch (e) {
      _handleError(e.message, 'Configuration Error', context);
    } on TimeoutException catch (e) {
      _handleError(
        'Request timed out. Please check your connection and try again.',
        'Timeout Error',
        context,
      );
    } on SocketException catch (e) {
      _handleError(
        'No internet connection. Please check your network.',
        'Connection Error',
        context,
      );
    } on http.ClientException catch (e) {
      _handleError(
        'Network error occurred. Please try again.',
        'Network Error',
        context,
      );
    } on FormatException catch (e) {
      _handleError(
        'Invalid response from server. Please contact support.',
        'Format Error',
        context,
      );
    } on ApiException catch (e) {
      _handleError(e.message, 'API Error', context);
    } catch (e) {
      _handleError(
        'An unexpected error occurred. Please try again.',
        'Unexpected Error',
        context,
      );
      // Log unexpected errors for debugging
      debugPrint('Unexpected error in predictCrop: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _isValidUri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  String _buildRequestBody() {
    try {
      return jsonEncode({
        "request": {
          "soil_ph": soil_ph,
          "fertility_ec": fertility_ec,
          "humidity": humidity,
          "sunlight": sunlight,
          "soil_temp": soil_temp,
          "soil_moisture": soil_moisture,
        },
        "selected_models": selectedModel != 'All Models' ? [selectedModel] : []
      });
    } catch (e) {
      throw FormatException('Failed to create request body: $e');
    }
  }

  Future<http.Response> _makeApiRequest(Uri uri, String body) async {
    try {
      return await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );
    } catch (e) {
      if (e is TimeoutException) rethrow;
      if (e is SocketException) rethrow;
      if (e is http.ClientException) rethrow;
      throw http.ClientException('Failed to make API request: $e');
    }
  }

  Future<void> _processResponse(http.Response response, BuildContext? context) async {
    // Handle different HTTP status codes
    switch (response.statusCode) {
      case 200:
        await _handleSuccessResponse(response);
        break;
      case 400:
        throw ApiException('Invalid request. Please check your input values.');
      case 401:
        throw ApiException('Authentication failed. Please login again.');
      case 403:
        throw ApiException('Access denied. Please check your permissions.');
      case 404:
        throw ApiException('Service not found. Please contact support.');
      case 422:
        _handleValidationError(response);
        break;
      case 429:
        throw ApiException('Too many requests. Please wait and try again.');
      case 500:
      case 502:
      case 503:
      case 504:
        throw ApiException('Server error. Please try again later.');
      default:
        throw ApiException('Unexpected error (${response.statusCode}). Please try again.');
    }
  }

  Future<void> _handleSuccessResponse(http.Response response) async {
    try {
      final data = jsonDecode(response.body);
      
      // Validate response structure
      if (data == null) {
        throw ApiException('Empty response from server');
      }
      
      if (data['recommendations'] == null || 
          !(data['recommendations'] is List) ||
          data['recommendations'].isEmpty) {
        throw ApiException('No crop recommendations found');
      }
      
      
      // Extract and validate recommendation data
      final recommendations = data['recommendations'] as List;
      if (recommendations[0]['crop'] == null) {
        throw ApiException('Crop information missing in recommendation');
      }

      // Set successful result
      predictionResult = data;
      predictedCrop = recommendations[0]['crop'].toString();
      modelAccuracy = data['model_accuracy'].toString();
      hasError = false;
      errorMessage = null;
      
    } on FormatException catch (e) {
      throw FormatException('Invalid JSON response from server');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to process server response');
    }
  }

  void _handleValidationError(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      final detail = errorData['detail'];
      
      if (detail is String) {
        throw ApiException(detail);
      } else if (detail is List && detail.isNotEmpty) {
        throw ApiException(detail[0]['msg'] ?? 'Validation error occurred');
      } else {
        throw ApiException('Invalid input values provided');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Invalid input values provided');
    }
  }

  void _handleError(String message, String errorType, BuildContext? context) {
    hasError = true;
    errorMessage = message;
    
    // Log error for debugging
    debugPrint('[$errorType] $message');
    
    // Show toast if context is available
    if (context != null && context.mounted) {
      ToastHelper.showErrorToast(message, context);
    }
  }

  String? _validateInputs() {
    // Validate soil pH (typically 0-14)
    if (soil_ph.isNaN || soil_ph.isInfinite) {
      return 'Soil pH must be a valid number';
    }
    if (soil_ph < 0 || soil_ph > 14) {
      return 'Soil pH must be between 0 and 14';
    }
    
    // Validate humidity (0-100%)
    if (humidity.isNaN || humidity.isInfinite) {
      return 'Humidity must be a valid number';
    }
    if (humidity < 0 || humidity > 100) {
      return 'Humidity must be between 0% and 100%';
    }
    
    // Validate soil moisture (0-100%)
    if (soil_moisture.isNaN || soil_moisture.isInfinite) {
      return 'Soil moisture must be a valid number';
    }
    if (soil_moisture < 0 || soil_moisture > 100) {
      return 'Soil moisture must be between 0% and 100%';
    }
    
    // Validate soil temperature (reasonable range for agriculture)
    if (soil_temp.isNaN || soil_temp.isInfinite) {
      return 'Soil temperature must be a valid number';
    }
    if (soil_temp < -10 || soil_temp > 50) {
      return 'Soil temperature must be between -10°C and 50°C';
    }
    
    // Validate fertility EC (typical range)
    if (fertility_ec.isNaN || fertility_ec.isInfinite) {
      return 'Fertility EC must be a valid number';
    }
    if (fertility_ec < 0) {
      return 'Fertility EC must be a positive number';
    }
    
    // Validate sunlight (typical range in W/m²)
    if (sunlight.isNaN || sunlight.isInfinite) {
      return 'Sunlight must be a valid number';
    }
    if (sunlight < 0) {
      return 'Sunlight must be a positive number';
    }
    
    return null;
  }

  void clearError() {
    hasError = false;
    errorMessage = null;
    notifyListeners();
  }

  void reset() {
    soil_ph = 6.6;
    fertility_ec = 535;
    sunlight = 2600;
    soil_temp = 28.7;
    humidity = 75;
    soil_moisture = 94;
    predictionResult = null;
    predictedCrop = null;
    modelAccuracy = null;
    hasError = false;
    errorMessage = null;
    notifyListeners();
  }
}

// Custom Exception Classes
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}

class ConfigurationException implements Exception {
  final String message;
  ConfigurationException(this.message);
  
  @override
  String toString() => message;
}