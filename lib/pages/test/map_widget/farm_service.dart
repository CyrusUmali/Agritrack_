import 'package:dio/dio.dart';
import 'package:flareline/pages/test/map_widget/pin_style.dart';
import 'package:flareline/pages/test/map_widget/polygon_manager.dart';

import 'package:flareline/services/api_service.dart';

class FarmService {
  final ApiService _apiService;

  FarmService(this._apiService);

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
