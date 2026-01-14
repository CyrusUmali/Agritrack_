import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flareline/pages/map/map_widget/pin_style.dart';
import 'package:flareline/pages/map/map_widget/polygon_manager.dart';

import 'package:flareline/services/api_service.dart';


class FarmService {
  final ApiService _apiService;



  // Cache properties
  final Map<String, CacheEntry> _cache = {};
  final Duration _cacheDuration = const Duration(minutes: 15);
  
  // Debouncing properties
  final Duration _debounceDuration = const Duration(seconds: 1);
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, Completer<Map<String, dynamic>>> _activeRequests = {};

  FarmService(this._apiService);




Future<Map<String, dynamic>> generateWeatherSummary({
  required Map<String, dynamic> weatherData,
  List<Map<String, dynamic>>? forecastData,
  Map<String, dynamic>? airQualityData,
   List<String>? products,
  

  String? location,
}) async {
  final requestKey = _createRequestKey(
    weatherData: weatherData,
    forecastData: forecastData,
    airQualityData: airQualityData,
    location: location, 
  );

  // 1. Check cache first
  // final cached = _cache[requestKey];
  // if (cached != null && !cached.isExpired()) {
  //   return cached.data;
  // }

  // 2. Check for debouncing
  final now = DateTime.now();
  final lastRequest = _lastRequestTime[requestKey];
  
  if (lastRequest != null && now.difference(lastRequest) < _debounceDuration) {
    // If there's an active request for this key, return it
    if (_activeRequests.containsKey(requestKey)) {
      return _activeRequests[requestKey]!.future;
    }
  }

  // 3. Check if same request is already in progress
  if (_activeRequests.containsKey(requestKey)) {
    return _activeRequests[requestKey]!.future;
  }

  // 4. Create new request
  final completer = Completer<Map<String, dynamic>>();
  _activeRequests[requestKey] = completer;
  _lastRequestTime[requestKey] = now;

  try {
    final response = await _apiService.post(
      '/auth/weather/reporter-summary',
      data: {
        'weatherData': weatherData,
        'forecastData': forecastData,
        'airQualityData': airQualityData,
        'location': location,
        'products': products,
      },
    );

    if (response.statusCode == 200) {
      // Clean up the summary text
      String rawSummary = response.data['summary'] ?? '';
      String cleanedSummary = _cleanSummaryText(rawSummary);
      
      final result = {
        'success': true,
        'summary': cleanedSummary,
        'rawSummary': rawSummary, // Keep original if needed
        'message': response.data['message'] ?? 'Summary generated successfully',
      };

      // Cache the result
      _cache[requestKey] = CacheEntry(
        data: result,
        timestamp: DateTime.now(),
        duration: _cacheDuration,
      );

      completer.complete(result);
      return result;
    }

    throw Exception('Failed to generate summary: ${response.statusCode}');
  } on DioException catch (e) {
    final error = e.response != null
        ? Exception('Server error: ${e.response!.data['message'] ?? e.response!.statusMessage}')
        : Exception('Network error: ${e.message}');
    completer.completeError(error);
    throw error;
  } catch (e) {
    final error = Exception('Failed to generate summary: ${e.toString()}');
    completer.completeError(error);
    throw error;
  } finally {
    // Clean up after debounce duration
    Future.delayed(_debounceDuration, () {
      _activeRequests.remove(requestKey);
    });
  }


  
}


String _cleanSummaryText(String text) {
  if (text.isEmpty) return text;
  
  // Remove Markdown formatting
  String cleaned = text
      // Remove headers (#, ##, ###)
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      // Remove bold (**text** or __text__)
      .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1) ?? '')
      .replaceAllMapped(RegExp(r'__(.*?)__'), (match) => match.group(1) ?? '')
      // Remove italic (*text* or _text_)
      .replaceAllMapped(RegExp(r'\*(.*?)\*'), (match) => match.group(1) ?? '')
      .replaceAllMapped(RegExp(r'_(.*?)_'), (match) => match.group(1) ?? '')
      // Remove strikethrough (~~text~~)
      .replaceAllMapped(RegExp(r'~~(.*?)~~'), (match) => match.group(1) ?? '')
      // Remove inline code (`code`)
      .replaceAllMapped(RegExp(r'`(.*?)`'), (match) => match.group(1) ?? '')
      // Remove block quotes (> text)
      .replaceAll(RegExp(r'^>\s*', multiLine: true), '')
      // Remove unordered list markers (-, *, +)
      .replaceAll(RegExp(r'^[\-\*\+]\s*', multiLine: true), '')
      // Remove ordered list markers (1., 2., etc.)
      .replaceAll(RegExp(r'^\d+\.\s*', multiLine: true), '')
      // Remove horizontal rules (---, ***, ___)
      .replaceAll(RegExp(r'^\s*[\-\*_]{3,}\s*$', multiLine: true), '')
      // Remove HTML tags (if any)
      .replaceAll(RegExp(r'<[^>]*>'), '')
      // Clean up multiple spaces
      .replaceAll(RegExp(r'\s+'), ' ')
      // Clean up multiple newlines
      .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
      // Trim whitespace
      .trim();

  // Additional cleaning for common formatting patterns
  cleaned = cleaned
      // Remove emoji or special markers like :sunny:, :cloud:, etc.
      .replaceAll(RegExp(r':[a-z_]+:'), '')
      // Remove bullet points (•, ○, ▪, ►, ▶, ◀, ◁)
      .replaceAll(RegExp(r'[•○▪►▶◀◁]'), '')
      // Remove excess punctuation
      .replaceAll(RegExp(r'([.!?])\1+'), r'$1')
      // Ensure proper sentence spacing
      .replaceAll(RegExp(r'\.([A-Z])'), r'. $1');

  return cleaned;
}



  String _createRequestKey({
    required Map<String, dynamic> weatherData,
    List<Map<String, dynamic>>? forecastData,
    Map<String, dynamic>? airQualityData,
    String? location,
  }) {
    // Create a stable key - you might want to use a proper hash function
    return [
      location ?? '',
      _hashMap(weatherData),
      forecastData?.map(_hashMap).join('|') ?? '',
      _hashMap(airQualityData ?? {}),
    ].join('|');
  }

  int _hashMap(Map<String, dynamic> map) {
    return map.toString().hashCode;
  }









  Future<List<Map<String, dynamic>>> fetchFarms() async {
    try {
      final response = await _apiService.get('/farms/farms-view');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['farms']);
      }
      throw Exception('Failed to load farms: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch farms: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchFarmsByFarmerId(
      String farmerId) async {
    try {
      final response = await _apiService.get('/farms/farms', queryParameters: {
        'farmerId': farmerId,
      });

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['farms']);
      }
      throw Exception('Failed to load farms: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch farms by farmer ID: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createFarm(PolygonData polygon) async {
    try {
      final response = await _apiService.post(
        '/farms/farms', // Make sure this matches your backend endpoint
        data: {
          'name': polygon.name,
          'farmerId': polygon.farmerId,
          'vertices': polygon.vertices
              .map((latLng) => [latLng.latitude, latLng.longitude])
              .toList(),
          'area': polygon.area,
          'barangay': polygon.barangay,
          'description': polygon.description,

          // Include other fields as needed
        },
      );

      if (response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true) {
          final farmData = responseData['farm'] as Map<String, dynamic>;

          // Explicitly handle the ID as int
          final farmId = farmData['id'] as int;

          return {
            'id': farmId,
          };
        }
      }
      throw Exception('Failed to create farm: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to create farm: ${e.toString()}');
    }
  }

  Future<void> updateFarm(PolygonData polygon) async {
    final response = await _apiService.put(
      '/farms/farms/${polygon.id}',
      data: {
        'name': polygon.name,
        'owner': polygon.owner,
        'vertices': polygon.vertices
            .map((latLng) => [latLng.latitude, latLng.longitude])
            .toList(),
        'area': polygon.area,
        'barangay': polygon.parentBarangay,
        'farmId': polygon.id,
        'sectorId': pinStyleToNumber(polygon.pinStyle),
        'description': polygon.description,
        'lake': polygon.lake,
        'status': polygon.status
        // 'products': polygon.products,
      },
    );

    if (response.statusCode != 200) {
      // throw 'Failed to update farm: ${response.statusCode}';
    }
  }

  Future<bool> deleteFarm(int farmId) async {
    try {
      final response = await _apiService.delete('/farms/farms/$farmId');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['success'] == true;
      } else if (response.statusCode == 404) {
        throw Exception('Farm not found');
      } else {
        throw Exception('Failed to delete farm: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete farm: ${e.toString()}');
    }
  }
}



class CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final Duration duration;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.duration,
  });

  bool isExpired() {
    return DateTime.now().difference(timestamp) > duration;
  }
}