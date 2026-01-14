import 'package:flutter/material.dart';
import 'package:flareline/providers/language_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flareline/pages/recommendation/api_uri.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlternativeCrop {
  final String crop;
  final double confidence;
  final String reason;
  final String? imageUrl;
  final List<String> parameterMismatches;
  final List<String> supportingModels;
  final double modelAgreement;

  AlternativeCrop({
    required this.crop,
    required this.confidence,
    required this.reason,
    this.imageUrl,
    required this.parameterMismatches,
    required this.supportingModels,
    this.modelAgreement = 1.0,
  });

  factory AlternativeCrop.fromJson(Map<String, dynamic> json) {
    try {
      return AlternativeCrop(
        crop: json['crop']?.toString() ?? '',
        confidence: _parseDouble(json['confidence'], 0.0),
        reason: json['reason']?.toString() ?? '',
        imageUrl: json['image_url']?.toString(),
        parameterMismatches: _parseStringList(json['parameter_mismatches']),
        supportingModels: _parseStringList(json['supporting_models']),
        modelAgreement: _parseDouble(json['model_agreement'], 1.0),
      );
    } catch (e) {
      throw FormatException('Failed to parse AlternativeCrop: $e');
    }
  }

  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}

class SuitabilityModel extends ChangeNotifier {
  final LanguageProvider languageProvider;

  static const String backendUrl = 'https://agritrack-server.onrender.com/auth';
    // static const String backendUrl = 'http://localhost:3001/auth';

  // Model selection
  String selectedModel = 'Random Forest';
  String? selectedCrop;
  bool _isStreamingSuggestions = false;

  bool get isStreamingSuggestions => _isStreamingSuggestions;
  
  // Input parameters
  double soil_ph = 6.6;
  double fertility_ec = 535;
  double sunlight = 2600;
  double soil_temp = 28.7;
  double humidity = 75;
  double soil_moisture = 94;

 



  // Results and error state
  bool isLoading = false;
  Map<String, dynamic>? suitabilityResult;
  String? modelAccuracy;
  String? errorMessage;
  bool hasError = false;

  // Available models with accuracy
  final Map<String, Map<String, double>> models = {
    'Random Forest': {'accuracy': 0.9924},
    'Decision Tree': {'accuracy': 0.9848},
    'Logistic Regression': {'accuracy': 0.9590},
    'XGBoost': {'accuracy': 0.9590},
    'All Models': {'accuracy': 0.0},
  };

  SuitabilityModel({required this.languageProvider});

  Future<String?> _getAuthToken() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw AuthenticationException('No user logged in');
      }
      
      final token = await currentUser.getIdToken();
      if (token == null || token.isEmpty) {
        throw AuthenticationException('Failed to retrieve authentication token');
      }
      
      return token;
    } on FirebaseAuthException catch (e) {
      throw AuthenticationException('Firebase authentication error: ${e.message}');
    } catch (e) {
      throw AuthenticationException('Authentication failed: $e');
    }
  }

  Future<void> checkSuitability({
    bool includeAlternatives = true,
    int numAlternatives = 6,
  }) async {
    // Reset state
    isLoading = true;
    hasError = false;
    errorMessage = null;
    suitabilityResult = null;
    notifyListeners();

    try {
      // 1. Validate inputs
      _validateSuitabilityInputs();

      if (selectedCrop == null || selectedCrop!.isEmpty) {
        throw ValidationException('Please select a crop first');
      }

      // 2. Build and validate request
      final queryParams = {
        'include_alternatives': includeAlternatives.toString(),
        'num_alternatives': numAlternatives.toString(),
      };

      if (!_isValidUri(ApiConstants.checkSuitability)) {
        throw ConfigurationException('Invalid API endpoint configuration');
      }

      final uri = Uri.parse(ApiConstants.checkSuitability)
          .replace(queryParameters: queryParams);

      // 3. Prepare request body
      final requestBody = _buildSuitabilityRequestBody();

      // 4. Make API request
      final response = await _makeApiRequest(uri, requestBody);

      // 5. Process response
      await _processSuitabilityResponse(response);

    } on ValidationException catch (e) {
      _handleError(e.message, 'Validation Error');
    } on ConfigurationException catch (e) {
      _handleError(e.message, 'Configuration Error');
    } on AuthenticationException catch (e) {
      _handleError(e.message, 'Authentication Error');
    } on TimeoutException catch (e) {
      _handleError('Request timed out. Please try again.', 'Timeout Error');
    } on SocketException catch (e) {
      _handleError('No internet connection. Please check your network.', 'Connection Error');
    } on http.ClientException catch (e) {
      _handleError('Network error occurred. Please try again.', 'Network Error');
    } on FormatException catch (e) {
      _handleError('Invalid response from server.', 'Format Error');
    } on ApiException catch (e) {
      _handleError(e.message, 'API Error');
    } catch (e) {
      _handleError('An unexpected error occurred.', 'Unexpected Error');
      debugPrint('Unexpected error in checkSuitability: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _validateSuitabilityInputs() {
    // Validate soil pH
    if (soil_ph.isNaN || soil_ph.isInfinite) {
      throw ValidationException('Soil pH must be a valid number');
    }
    if (soil_ph < 0 || soil_ph > 14) {
      throw ValidationException('Soil pH must be between 0 and 14');
    }
    
    // Validate humidity
    if (humidity.isNaN || humidity.isInfinite) {
      throw ValidationException('Humidity must be a valid number');
    }
    if (humidity < 0 || humidity > 100) {
      throw ValidationException('Humidity must be between 0% and 100%');
    }
    
    // Validate soil moisture
    if (soil_moisture.isNaN || soil_moisture.isInfinite) {
      throw ValidationException('Soil moisture must be a valid number');
    }
    if (soil_moisture < 0 || soil_moisture > 100) {
      throw ValidationException('Soil moisture must be between 0% and 100%');
    }
    
    // Validate soil temperature
    if (soil_temp.isNaN || soil_temp.isInfinite) {
      throw ValidationException('Soil temperature must be a valid number');
    }
    if (soil_temp < -10 || soil_temp > 50) {
      throw ValidationException('Soil temperature must be between -10°C and 50°C');
    }
    
    // Validate fertility EC
    if (fertility_ec.isNaN || fertility_ec.isInfinite) {
      throw ValidationException('Fertility EC must be a valid number');
    }
    if (fertility_ec < 0) {
      throw ValidationException('Fertility EC must be a positive number');
    }
    
    // Validate sunlight
    if (sunlight.isNaN || sunlight.isInfinite) {
      throw ValidationException('Sunlight must be a valid number');
    }
    if (sunlight < 0) {
      throw ValidationException('Sunlight must be a positive number');
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

  String _buildSuitabilityRequestBody() {
    try {
      List<String> selectedModels = [];
      if (selectedModel != 'All Models') {
        selectedModels.add(selectedModel);
      }

      return jsonEncode({
        "soil_ph": soil_ph,
        "fertility_ec": fertility_ec,
        "humidity": humidity,
        "sunlight": sunlight,
        "soil_temp": soil_temp,
        "soil_moisture": soil_moisture,
        "crop": selectedCrop,
        "selected_models": selectedModels.isEmpty ? null : selectedModels
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

  Future<void> _processSuitabilityResponse(http.Response response) async {
    switch (response.statusCode) {
      case 200:
        await _handleSuccessSuitabilityResponse(response);
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
        throw ApiException('Unexpected error (${response.statusCode}).');
    }
  }

  Future<void> _handleSuccessSuitabilityResponse(http.Response response) async {
    try {
      final data = jsonDecode(response.body);
      
      if (data == null) {
        throw ApiException('Empty response from server');
      }

      // Parse alternatives with error handling
      List<AlternativeCrop> alternatives = [];
      try {
        if (data['alternatives'] != null && data['alternatives'] is List) {
          alternatives = (data['alternatives'] as List)
              .map((alt) {
                try {
                  return AlternativeCrop.fromJson(alt);
                } catch (e) {
                  debugPrint('Failed to parse alternative crop: $e');
                  return null;
                }
              })
              .where((alt) => alt != null)
              .cast<AlternativeCrop>()
              .toList();
        }
      } catch (e) {
        debugPrint('Error parsing alternatives: $e');
      }

      // Build result
      suitabilityResult = {
        ...data,
        'parsed_alternatives': alternatives,
      };

      // Update model accuracy display
      try {
        if (selectedModel == 'All Models' && data['model_used'] is List) {
          final modelsUsed = (data['model_used'] as List).length;
          final finalConf = _parseDouble(data['final_confidence'], 0.0);
          final paramConf = _parseDouble(data['parameter_confidence'], 0.0);
          modelAccuracy =
              'Final: ${(finalConf * 100).toStringAsFixed(2)}% | Params: ${(paramConf * 100).toStringAsFixed(2)}% ($modelsUsed models)';
        } else {
          final finalConf = _parseDouble(data['final_confidence'], 0.0);
          modelAccuracy = 'Confidence: ${(finalConf * 100).toStringAsFixed(2)}%';
        }
      } catch (e) {
        modelAccuracy = 'Confidence data unavailable';
        debugPrint('Error parsing confidence: $e');
      }

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

  double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Future<void> getSuggestionsStream(List<String> deficientParams) async {
    if (selectedCrop == null || selectedCrop!.isEmpty) {
      throw ValidationException('Please select a crop first');
    }

    _isStreamingSuggestions = true;
    
    suitabilityResult = {
      ...?suitabilityResult,
      'suggestions': [],
      'current_streaming_suggestion': '',
      'suggestions_error': null,
    };
    notifyListeners();

    try {
      // 1. Get authentication token
      final token = await _getAuthToken();

      // 2. Validate and prepare deficiencies
      final paramAnalysis = suitabilityResult?['parameters_analysis'];
      if (paramAnalysis == null) {
        throw ValidationException('Parameter analysis not available');
      }
      
      final deficiencies = <String, Map<String, dynamic>>{};
      for (final param in deficientParams) {
        if (paramAnalysis[param] != null) {
          deficiencies[param] = {
            'current': paramAnalysis[param]['current'],
            'ideal_min': paramAnalysis[param]['ideal_min'],
            'ideal_max': paramAnalysis[param]['ideal_max'],
          };
        }
      }

      if (deficiencies.isEmpty) {
        suitabilityResult = {
          ...?suitabilityResult,
          'suggestions': ['No significant deficiencies in selected parameters.'],
        };
        _isStreamingSuggestions = false;
        notifyListeners();
        return;
      }

      // 3. Create streaming request
      await _performStreamingSuggestionsRequest(token!, deficiencies);

    } on ValidationException catch (e) {
      _handleSuggestionsError(e.message);
    } on AuthenticationException catch (e) {
      _handleSuggestionsError(e.message);
    } on TimeoutException catch (e) {
      _handleSuggestionsError('Request timed out. Please try again.');
    } on SocketException catch (e) {
      _handleSuggestionsError('No internet connection.');
    } on http.ClientException catch (e) {
      _handleSuggestionsError('Network error occurred.');
    } catch (e) {
      _handleSuggestionsError('Failed to generate suggestions.');
      debugPrint('Error in getSuggestionsStream: $e');
    } finally {
      _isStreamingSuggestions = false;
      suitabilityResult = {
        ...?suitabilityResult,
        'current_streaming_suggestion': null,
      };
      notifyListeners();
    }
  }

  Future<void> _performStreamingSuggestionsRequest(
    String token,
    Map<String, Map<String, dynamic>> deficiencies,
  ) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$backendUrl/suitability/suggestions'),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });
      
      request.body = json.encode({
        'crop': selectedCrop,
        'deficiencies': deficiencies,
      });

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Suggestions request timed out');
        },
      );

      if (streamedResponse.statusCode == 200) {
        await _processStreamedSuggestions(streamedResponse);
      } else if (streamedResponse.statusCode == 401) {
        throw AuthenticationException('Session expired. Please login again.');
      } else if (streamedResponse.statusCode >= 500) {
        throw ApiException('Server error. Please try again later.');
      } else {
        throw ApiException('Connection issue (${streamedResponse.statusCode})');
      }

    } catch (e) {
      if (e is TimeoutException) rethrow;
      if (e is SocketException) rethrow;
      if (e is AuthenticationException) rethrow;
      if (e is ApiException) rethrow;
      throw http.ClientException('Failed to stream suggestions: $e');
    }
  }

  Future<void> _processStreamedSuggestions(http.StreamedResponse response) async {
    String buffer = '';
    final List<String> completedSuggestions = [];

    try {
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        
        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final jsonData = line.substring(6);
            try {
              final data = json.decode(jsonData);
              
              if (data['error'] == true) {
                throw ApiException(data['message'] ?? 'An error occurred');
              }
              
              if (data['done'] == true) {
                if (buffer.trim().isNotEmpty) {
                  final cleanedBuffer = _cleanSuggestionText(buffer.trim());
                  if (cleanedBuffer.isNotEmpty) {
                    completedSuggestions.add(cleanedBuffer);
                  }
                }
                
                suitabilityResult = {
                  ...?suitabilityResult,
                  'suggestions': completedSuggestions,
                  'current_streaming_suggestion': null,
                };
                notifyListeners();
                
              } else if (data['chunk'] != null) {
                final text = data['chunk'];
                buffer += text;
                
                final processed = _processStreamingBuffer(buffer);
                buffer = processed.remainingBuffer;
                
                if (processed.newSuggestions.isNotEmpty) {
                  completedSuggestions.addAll(processed.newSuggestions);
                  
                  suitabilityResult = {
                    ...?suitabilityResult,
                    'suggestions': List.from(completedSuggestions),
                    'current_streaming_suggestion': buffer,
                  };
                  notifyListeners();
                } else if (buffer.isNotEmpty) {
                  suitabilityResult = {
                    ...?suitabilityResult,
                    'current_streaming_suggestion': buffer,
                  };
                  notifyListeners();
                }
              }
            } catch (e) {
              debugPrint('Error processing streaming chunk: $e');
            }
          }
        }
      }
    } catch (e) {
      throw ApiException('Stream processing error: $e');
    }
  }

  void _handleSuggestionsError(String message) {
    suitabilityResult = {
      ...?suitabilityResult,
      'suggestions': ['Error: $message'],
      'suggestions_error': message,
    };
    notifyListeners();
  }

  ({List<String> newSuggestions, String remainingBuffer}) _processStreamingBuffer(String buffer) {
    final newSuggestions = <String>[];
    String remainingBuffer = buffer;

    final sectionPattern = RegExp(r'(\n\s*[\d\-•]+\s*[\.\)]?\s*|\n\s*[A-Z][^a-z]*:\s*\n)');
    final matches = sectionPattern.allMatches(buffer);

    if (matches.isNotEmpty) {
      int lastEnd = 0;
      
      for (final match in matches) {
        if (match.start > lastEnd) {
          final section = buffer.substring(lastEnd, match.start).trim();
          if (section.isNotEmpty) {
            final cleanedSection = _cleanSuggestionText(section);
            if (cleanedSection.isNotEmpty) {
              newSuggestions.add(cleanedSection);
            }
          }
          lastEnd = match.start;
        }
      }
      
      remainingBuffer = buffer.substring(lastEnd);
    }

    final paragraphs = remainingBuffer.split('\n\n');
    if (paragraphs.length > 1) {
      for (int i = 0; i < paragraphs.length - 1; i++) {
        final paragraph = paragraphs[i].trim();
        if (paragraph.isNotEmpty) {
          final cleanedParagraph = _cleanSuggestionText(paragraph);
          if (cleanedParagraph.isNotEmpty) {
            newSuggestions.add(cleanedParagraph);
          }
        }
      }
      remainingBuffer = paragraphs.last;
    }

    return (
      newSuggestions: newSuggestions,
      remainingBuffer: remainingBuffer
    );
  }

  String _cleanSuggestionText(String text) {
    if (text.trim().isEmpty) return '';
    
    String cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    cleaned = cleaned
        .replaceAll('**', '') 
        .replaceAll('*', '')
        .replaceAll('__', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll('#', '')
        .replaceAll(RegExp(r'`{1,3}'), '');
    
    if (!cleaned.endsWith('.') && 
        !cleaned.endsWith('!') && 
        !cleaned.endsWith('?') &&
        !cleaned.endsWith(':')) {
      cleaned += '.';
    }
    
    return cleaned;
  }

  void _handleError(String message, String errorType) {
    hasError = true;
    errorMessage = message;
    debugPrint('[$errorType] $message');
  }

  void clearError() {
    hasError = false;
    errorMessage = null;
    notifyListeners();
  }

  void reset() {
    selectedCrop = null;
    soil_ph = 6.6;
    fertility_ec = 535;
    sunlight = 2600;
    soil_temp = 28.7;
    humidity = 75;
    soil_moisture = 94;
    suitabilityResult = null;
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

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
  
  @override
  String toString() => message;
}