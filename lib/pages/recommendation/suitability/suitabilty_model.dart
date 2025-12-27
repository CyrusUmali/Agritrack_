import 'package:flutter/material.dart';
import 'package:flareline/providers/language_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flareline/pages/recommendation/api_uri.dart';
import 'package:firebase_auth/firebase_auth.dart';




class AlternativeCrop {
  final String crop;
  final double confidence;
  final String reason;
  final String? imageUrl;
  final List<String> parameterMismatches;
  final List<String> supportingModels; // Add this field
  final double modelAgreement; // Optional: percentage of models that recommended this

  AlternativeCrop({
    required this.crop,
    required this.confidence,
    required this.reason,
    this.imageUrl,
    required this.parameterMismatches,
    required this.supportingModels, // Add to constructor
    this.modelAgreement = 1.0,
  });

  factory AlternativeCrop.fromJson(Map<String, dynamic> json) {
    return AlternativeCrop(
      crop: json['crop'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      reason: json['reason'] ?? '',
      imageUrl: json['image_url'],
      parameterMismatches: (json['parameter_mismatches'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      supportingModels: (json['supporting_models'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [], // Parse from JSON
      modelAgreement: (json['model_agreement'] ?? 1.0).toDouble(),
    );
  }
}



class SuitabilityModel extends ChangeNotifier {
  final LanguageProvider languageProvider;

  // Backend URL
  static const String backendUrl = 'https://agritrack-server.onrender.com/auth';

  // Model selection
  String selectedModel = 'Random Forest';
  String? selectedCrop;
  bool _isStreamingSuggestions = false;

  bool get isStreamingSuggestions => _isStreamingSuggestions;
  
  // Input parameters
  // double soil_ph = 5.9;
  // double fertility_ec = 390;
  // double sunlight = 1500;
  // double soil_temp = 27.8;
  // double humidity = 82;
  // double soil_moisture = 80;


    double soil_ph = 6.6;
  double fertility_ec = 535;
  double sunlight = 2600;
  double soil_temp = 28.7;
  double humidity = 75;
  double soil_moisture = 94;

  // Results
  bool isLoading = false;
  Map<String, dynamic>? suitabilityResult;
  String? modelAccuracy;

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
      if (currentUser != null) {
        return await currentUser.getIdToken();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> checkSuitability({
    bool includeAlternatives = true,
    int numAlternatives = 6,
  }) async {
    if (selectedCrop == null) {
      throw Exception('Please select a crop first');
    }

    isLoading = true;
    suitabilityResult = null;
    notifyListeners();

    // Build query parameters
    final queryParams = {
      'include_alternatives': includeAlternatives.toString(),
      'num_alternatives': numAlternatives.toString(),
    };

    final uri = Uri.parse(ApiConstants.checkSuitability)
        .replace(queryParameters: queryParams);

    try {
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
        
        // Parse alternatives if present
        List<AlternativeCrop> alternatives = [];
        if (data['alternatives'] != null && data['alternatives'] is List) {
          alternatives = (data['alternatives'] as List)
              .map((alt) => AlternativeCrop.fromJson(alt))
              .toList();
        }

        // Add parsed alternatives to result
        suitabilityResult = {
          ...data,
          'parsed_alternatives': alternatives,
        };

        // Update model accuracy display based on new confidence metrics
        if (selectedModel == 'All Models' && data['model_used'] is List) {
          final modelsUsed = (data['model_used'] as List).length;
          final finalConf = data['final_confidence'] ?? 0.0;
          final paramConf = data['parameter_confidence'] ?? 0.0;
          modelAccuracy =
              'Final: ${(finalConf * 100).toStringAsFixed(2)}% | Params: ${(paramConf * 100).toStringAsFixed(2)}% (${modelsUsed} models)';
        } else {
          final finalConf = data['final_confidence'] ?? 0.0;
          modelAccuracy = 'Confidence: ${(finalConf * 100).toStringAsFixed(2)}%';
        }
      } else {
        throw Exception('Failed to check suitability: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getSuggestionsStream(List<String> deficientParams) async {
    if (selectedCrop == null) {
      throw Exception('Please select a crop first');
    }

    _isStreamingSuggestions = true;
    
    // Initialize suggestions as empty list
    suitabilityResult = {
      ...?suitabilityResult,
      'suggestions': [],
      'current_streaming_suggestion': '',
    };
    notifyListeners();

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final paramAnalysis = suitabilityResult?['parameters_analysis'] ?? {};
      
      // Filter only the requested deficient parameters
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

      // Call backend endpoint
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

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        String buffer = '';
        final List<String> completedSuggestions = [];

        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final jsonData = line.substring(6);
              try {
                final data = json.decode(jsonData);
                
                if (data['error'] == true) {
                  throw Exception(data['message'] ?? 'An error occurred');
                }
                
                if (data['done'] == true) {
                  // Process any remaining buffer
                  if (buffer.trim().isNotEmpty) {
                    final cleanedBuffer = _cleanSuggestionText(buffer.trim());
                    if (cleanedBuffer.isNotEmpty) {
                      completedSuggestions.add(cleanedBuffer);
                    }
                  }
                  
                  // Final update
                  suitabilityResult = {
                    ...?suitabilityResult,
                    'suggestions': completedSuggestions,
                    'current_streaming_suggestion': null,
                  };
                  notifyListeners();
                  
                } else if (data['chunk'] != null) {
                  final text = data['chunk'];
                  buffer += text;
                  
                  // Process the buffer to extract complete sections
                  final processed = _processStreamingBuffer(buffer);
                  buffer = processed.remainingBuffer;
                  
                  // Update the UI with current progress
                  if (processed.newSuggestions.isNotEmpty) {
                    completedSuggestions.addAll(processed.newSuggestions);
                    
                    suitabilityResult = {
                      ...?suitabilityResult,
                      'suggestions': List.from(completedSuggestions),
                      'current_streaming_suggestion': buffer,
                    };
                    notifyListeners();
                  } else if (buffer.isNotEmpty) {
                    // Still streaming current section
                    suitabilityResult = {
                      ...?suitabilityResult,
                      'current_streaming_suggestion': buffer,
                    };
                    notifyListeners();
                  }
                }
              } catch (e) {
                // Silent error handling for streaming chunks
              }
            }
          }
        }
      } else {
        throw Exception('Connection issue (${streamedResponse.statusCode})');
      }

    } catch (e) {
      suitabilityResult = {
        ...?suitabilityResult,
        'suggestions': ['Error generating recommendations: ${e.toString()}'],
      };
      notifyListeners();
    } finally {
      _isStreamingSuggestions = false;
      // Clear the streaming buffer
      suitabilityResult = {
        ...?suitabilityResult,
        'current_streaming_suggestion': null,
      };
      notifyListeners();
    }
  }

  // Helper method to process streaming buffer and extract complete sections
  ({List<String> newSuggestions, String remainingBuffer}) _processStreamingBuffer(String buffer) {
    final newSuggestions = <String>[];
    String remainingBuffer = buffer;

    // Look for section separators
    final sectionPattern = RegExp(r'(\n\s*[\d\-•]+\s*[\.\)]?\s*|\n\s*[A-Z][^a-z]*:\s*\n)');
    final matches = sectionPattern.allMatches(buffer);

    if (matches.isNotEmpty) {
      int lastEnd = 0;
      
      for (final match in matches) {
        if (match.start > lastEnd) {
          // Extract the section before this match
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
      
      // Update remaining buffer
      remainingBuffer = buffer.substring(lastEnd);
    }

    // Also check for complete paragraphs within the remaining content
    final paragraphs = remainingBuffer.split('\n\n');
    if (paragraphs.length > 1) {
      // All but the last paragraph are complete
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

  // Clean and format suggestion text
  String _cleanSuggestionText(String text) {
    if (text.trim().isEmpty) return '';
    
    // Remove excessive whitespace
    String cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Remove markdown formatting but keep basic structure
    cleaned = cleaned
        .replaceAll('**', '') 
        .replaceAll('*', '')
        .replaceAll('__', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll('#', '')
        .replaceAll(RegExp(r'`{1,3}'), '');
    
    // Ensure proper sentence structure
    if (!cleaned.endsWith('.') && 
        !cleaned.endsWith('!') && 
        !cleaned.endsWith('?') &&
        !cleaned.endsWith(':')) {
      cleaned += '.';
    }
    
    return cleaned;
  }
}