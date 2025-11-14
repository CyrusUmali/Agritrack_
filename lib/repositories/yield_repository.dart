import 'package:dio/dio.dart';
import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flareline/repositories/base_repository.dart'; // Import the base repository

class YieldRepository extends BaseRepository {
  YieldRepository({required super.apiService});

  Future<List<Yield>> getYieldByLake(String lake) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.get('/yields/lake/$lake');

      if (response.data == null || response.data['yields'] == null) {
        throw Exception('Invalid yield data format');
      }

      final yieldsData = response.data['yields'] as List;

      print('lake:');
      print('lake: $lake');
      print('yieldsData: $yieldsData');
      return yieldsData.map((json) => Yield.fromJson(json)).toList();
    } catch (e) {
      handleError(e,
          operation: 'load yields for lake $lake'); // Use inherited method
    }
  }

  Future<List<Yield>> getYieldByBarangay(String barangay) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.get('/yields/barangay/$barangay');

      if (response.data == null || response.data['yields'] == null) {
        throw Exception('Invalid yield data format');
      }

      final yieldsData = response.data['yields'] as List;
      return yieldsData.map((json) => Yield.fromJson(json)).toList();
    } catch (e) {
      handleError(e,
          operation:
              'load yields for barangay $barangay'); // Use inherited method
    }
  }

  Future<List<Yield>> getYieldByFarmId(int farmId) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.get('/yields/yields/farm/$farmId');

      if (response.data == null || response.data['yields'] == null) {
        throw Exception('Invalid yield data format');
      }

      final yieldsData = response.data['yields'] as List;
      return yieldsData.map((json) => Yield.fromJson(json)).toList();
    } catch (e) {
      handleError(e,
          operation: 'load yields for farm $farmId'); // Use inherited method
    }
  }

  Future<List<Yield>> fetchYields() async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.get('/yields/farmer-yields');

      if (response.data == null || response.data['yields'] == null) {
        throw Exception('Invalid yields data format');
      }

      final yieldsData = response.data['yields'] as List;
      return yieldsData.map((json) => Yield.fromJson(json)).toList();
    } catch (e) {
      handleError(e, operation: 'load yields'); // Use inherited method
    }
  }

  Future<Yield> updateYield(Yield yieldRecord) async {
    try {
      checkAuthentication(); // Use inherited method
      _validateYieldRequiredFields(yieldRecord);

      final response = await apiService.put(
        '/yields/yields/${yieldRecord.id}',
        data: _buildYieldData(yieldRecord),
      );

      if (response.data == null || response.data['yield'] == null) {
        throw Exception('Invalid yield data format');
      }

      return Yield.fromJson(response.data['yield']);
    } catch (e) {
      handleError(e, operation: 'update yield'); // Use inherited method
    }
  }

  Future<List<Yield>> fetchYieldsByFarmer(int farmerId) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.get('/yields/farmer-yields/$farmerId');

      if (response.data == null || response.data['yields'] == null) {
        throw Exception('Invalid yields data format');
      }

      final yieldsData = response.data['yields'] as List;
      return yieldsData.map((json) => Yield.fromJson(json)).toList();
    } catch (e) {
      handleError(e,
          operation:
              'load yields for farmer $farmerId'); // Use inherited method
    }
  }

  Future<List<Yield>> fetchYieldsByProduct(int productId) async {
    try {
      checkAuthentication(); // Use inherited method

      final response =
          await apiService.get('/yields/yields/product/$productId');

      if (response.data == null || response.data['yields'] == null) {
        throw Exception('Invalid yields data format');
      }

      final yieldsData = response.data['yields'] as List;
      return yieldsData.map((json) => Yield.fromJson(json)).toList();
    } catch (e) {
      handleError(e,
          operation:
              'load yields for product $productId'); // Use inherited method
    }
  }

  Future<Yield> addYield(Yield yieldRecord) async {
    try {
      checkAuthentication(); // Use inherited method
      _validateYieldRequiredFields(yieldRecord);

      final response = await apiService.post(
        '/yields/yields',
        data: _buildYieldData(yieldRecord),
      );

      if (response.data == null || response.data['yield'] == null) {
        throw Exception('Invalid yield data format');
      }

      return Yield.fromJson(response.data['yield']);
    } catch (e) {
      handleError(e, operation: 'add yield'); // Use inherited method
    }
  }

  // Helper method for yield validation
  void _validateYieldRequiredFields(Yield yieldRecord) {
    if (yieldRecord.farmerId == null) {
      throw Exception('Farmer ID is required');
    }
    if (yieldRecord.productId == null) {
      throw Exception('Product ID is required');
    }
    if (yieldRecord.harvestDate == null) {
      throw Exception('Harvest date is required');
    }
    if (yieldRecord.volume == null) {
      throw Exception('Volume is required');
    }
  }

  // Helper method to build yield data
  Map<String, dynamic> _buildYieldData(Yield yieldRecord) {
    return {
      'farmer_id': yieldRecord.farmerId,
      'product_id': yieldRecord.productId,
      'harvest_date': yieldRecord.harvestDate!.toIso8601String(),
      'status': yieldRecord.status,
      'area_harvested': yieldRecord.areaHarvested,
      'farm_id': yieldRecord.farmId,
      'volume': yieldRecord.volume,
      'notes': yieldRecord.notes,
      'value': yieldRecord.value,
      'images': yieldRecord.images,
    };
  }

  Future<void> deleteYield(int yieldId) async {
    try {
      checkAuthentication(); // Use inherited method
      await apiService.delete('/yields/yields/$yieldId');
    } catch (e) {
      handleError(e, operation: 'delete yield'); // Use inherited method
    }
  }
}
