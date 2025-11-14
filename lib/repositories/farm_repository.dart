import 'package:dio/dio.dart';
import 'package:flareline/core/models/farms_model.dart';
import 'package:flareline/services/api_service.dart';
import 'package:flareline/repositories/base_repository.dart'; // Import the base repository

class FarmRepository extends BaseRepository {
  FarmRepository({required super.apiService});

  Future<Farm> getFarmById(int farmId) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.get('/farms/farms/$farmId');

      if (response.data == null || response.data['farm'] == null) {
        throw Exception('Invalid farm data format');
      }

      return Farm.fromJson(response.data['farm']);
    } catch (e) {
      handleError(e, operation: 'load farm'); // Use inherited method
    }
  }

  Future<List<Farm>> getFarmsByProductId(int productId) async {
    try {
      checkAuthentication(); // Use inherited method

      final response =
          await apiService.get('/farms/farms/by-product/$productId');
 

      if (response.data == null || response.data['farms'] == null) {
        throw Exception('Invalid farm data format');
      }

      final farmsData = response.data['farms'] as List;
 
      return farmsData.map((json) => Farm.fromJson2(json)).toList();
    } catch (e) {
      handleError(e,
          operation: 'load farms by product'); // Use inherited method
    }
  }

  Future<Farm> updateFarm(Farm farm) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.put(
        '/farms/farmsProfile/${farm.id}',
        data: {
          'name': farm.name,
          'owner': farm.owner,
          'description': farm.description,
          'barangay': farm.barangay,
          'farmId': farm.id,
          'sectorId': farm.sectorId,
          'status': farm.status,
          'farmerId': farm.farmerId,
          'products': farm.products,
          'hectare': farm.hectare?.toString(),
        },
      );

      if (response.data == null || response.data['farm'] == null) {
        throw Exception('Invalid farm data format');
      }

      return Farm.fromJson(response.data['farm']);
    } catch (e) {
      handleError(e, operation: 'update farm'); // Use inherited method
    }
  }

  Future<List<Farm>> fetchFarms({int? farmerId}) async {
    try {
      checkAuthentication(); // Use inherited method

      final Map<String, dynamic> queryParams = {};
      if (farmerId != null) {
        queryParams['farmerId'] = farmerId.toString();
      }

      final response =
          await apiService.get('/farms/farms', queryParameters: queryParams);

      if (response.data == null || response.data['farms'] == null) {
        throw Exception('Invalid farms data format');
      }

      final farmsData = response.data['farms'] as List;
      return farmsData.map((json) => Farm.fromJson(json)).toList();
    } catch (e) {
      handleError(e, operation: 'load farms'); // Use inherited method
    }
  }

  Future<void> deleteFarm(int farmId) async {
    try {
      checkAuthentication(); // Use inherited method
      await apiService.delete('/farms/farms/$farmId');
    } catch (e) {
      handleError(e, operation: 'delete farm'); // Use inherited method
    }
  }

  Future<List<Farm>> getFarmsByOwnerId(int ownerId) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.get('/farms/farms/owner/$ownerId');

      if (response.data == null || response.data['farms'] == null) {
        throw Exception('Invalid farms data format');
      }

      final farmsData = response.data['farms'] as List;
      return farmsData.map((json) => Farm.fromJson(json)).toList();
    } catch (e) {
      handleError(e, operation: 'load farms by owner'); // Use inherited method
    }
  }
}
