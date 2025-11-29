import 'package:flutter/material.dart';
import 'package:flareline/providers/language_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flareline/pages/recommendation/api_uri.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuitabilityModel extends ChangeNotifier {
  final LanguageProvider languageProvider;

  // Backend URL
  // static const String backendUrl = 'http://localhost:3001/auth';
  static const String backendUrl = 'https://agritrack-server.onrender.com/auth';

  // Model selection
  String selectedModel = 'XGBoost';
  String? selectedCrop;
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
      // print('❌ Error getting auth token: $e');
      return null;
    }
  }

  Future<void> checkSuitability() async {
    if (selectedCrop == null) {
      throw Exception('Please select a crop first');
    }

    isLoading = true;
    suitabilityResult = null;
    notifyListeners();

    final uri = Uri.parse(ApiConstants.checkSuitability);

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
        suitabilityResult = data;

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
      // print("❌ Error: $e");
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

    // print('🌾 Getting suggestions for deficient params: $deficientParams');

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
          'suggestions': ['Walang makabuluhang kakulangan sa mga napiling parameter.'],
        };
        _isStreamingSuggestions = false;
        notifyListeners();
        return;
      }

      // print('📤 Sending request to backend...');
      // print('Crop: $selectedCrop');
      // print('Deficiencies: $deficiencies');

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

      // print('📡 Response status: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        // print('✅ Starting to receive stream...');
        
        String buffer = '';
        final List<String> completedSuggestions = [];
        int chunkCount = 0;

        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          chunkCount++;
          
          final lines = chunk.split('\n');
          
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final jsonData = line.substring(6);
              try {
                final data = json.decode(jsonData);
                
                if (data['error'] == true) {
                  // print('❌ Error in stream: ${data['message']}');
                  throw Exception(data['message'] ?? 'May nangyaring error');
                }
                
                if (data['done'] == true) {
                  // print('✅ Stream complete. Total chunks: $chunkCount');
                  
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
                print('❌ Error parsing SSE data: $e');
              }
            }
          }
        }
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        print('❌ Bad response: $responseBody');
        throw Exception('May problema sa pagkonekta sa server (${streamedResponse.statusCode})');
      }

    } catch (e) {
      print('❌ Stream error: $e');
      suitabilityResult = {
        ...?suitabilityResult,
        'suggestions': ['Error sa pagbuo ng mga rekomendasyon: ${e.toString()}'],
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