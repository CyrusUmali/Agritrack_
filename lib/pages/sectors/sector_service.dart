import 'package:dio/dio.dart';
import 'package:flareline/core/models/assocs_model.dart';
import 'package:flareline/core/models/yield_model.dart';
import 'package:flareline/services/api_service.dart';

class SectorService {
  final ApiService _apiService;

  SectorService(this._apiService);

  Future<List<Yield>> fetchSectorYieldData(
      {required String sectorId, int? year}) async {
    try {
      final Map<String, dynamic> queryParams = {'sectorId': sectorId};
      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get(
        '/sectors/yield-data-by-sector', // Endpoint for sector yield data
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Assuming the response contains a 'yields' key with the list of yield data
        final List<dynamic> yieldData = response.data['yields'];
        return yieldData.map((data) => Yield.fromJson(data)).toList();
      }

      throw Exception(
          'Failed to load sector yield data: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch sector yield data: ${e.toString()}');
    }
  }

  Future<List<Yield>> fetchAssocYieldData(
      {required String assocId, int? year}) async {
    try {
      final Map<String, dynamic> queryParams = {'assocId': assocId};
      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get(
        '/assocs/yield-data', // Endpoint for association yield data
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Assuming the response contains a list of yield data
        final List<dynamic> yieldData =
            response.data['yields'] ?? response.data;
        return yieldData.map((data) => Yield.fromJson(data)).toList();
      }

      throw Exception(
          'Failed to load association yield data: ${response.statusCode}');
    } catch (e) {
      throw Exception(
          'Failed to fetch association yield data: ${e.toString()}');
    }
  }

  /// Fetch associations for a given year (optional)
  Future<List<Association>> fetchAssociations2({int? year}) async {
    // print('called here');
    try {
      final Map<String, dynamic> queryParams = {};
      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get(
        '/assocs/associationsList',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Assuming the response contains an 'associations' key
        final List<dynamic> associationsData = response.data['associations'];
       
        return associationsData
            .map((data) => Association.fromJson(data))
            .toList();
      }

      throw Exception('Failed to load associations: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch associations: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAssociations({int? year}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get(
        '/assocs/associations', // Changed endpoint to associations
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Assuming the response structure is similar to sectors but for associations
        return List<Map<String, dynamic>>.from(response.data['associations']);
      }

      throw Exception('Failed to load associations: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch associations: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSectors({int? year}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get('/sectors/sectors',
          queryParameters: queryParams);

      if (response.statusCode == 200) {
        // Extract just the sectors list from the response to maintain compatibility
        return List<Map<String, dynamic>>.from(response.data['sectors']);
      }

      throw Exception('Failed to load sectors: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch sectors: ${e.toString()}');
    }
  }

  /// Fetches all annotations
  ///
  ///
  ///
  Future<List<Map<String, dynamic>>> fetchAnnotations() async {
    try {
      final response = await _apiService.get(
          '/sectors/annotations'); // Also fixed the URL path (removed '/auth')

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['annotations']);
      } else {
        throw Exception('Failed to load annotations: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch annotations: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createAnnotation(
      Map<String, dynamic> annotationData) async {
    try {
      final response = await _apiService.post(
        '/sectors/annotations',
        data: annotationData,
      );

      if (response.statusCode == 201) {
        // Fix: Return the entire response data, not response.data['data']
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to create annotation: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to create annotation: ${e.toString()}');
    }
  }

  /// Updates an existing annotation
  Future<Map<String, dynamic>> updateAnnotation(
      int id, Map<String, dynamic> updatedData) async {
    try {
      final response = await _apiService.put(
        '/sectors/annotations/$id',
        data: updatedData,
      );

      if (response.statusCode == 200) {
        // return Map<String, dynamic>.from(response.data['data']);
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to update annotation: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to update annotation: ${e.toString()}');
    }
  }

  /// Deletes an annotation
  Future<void> deleteAnnotation(int id) async {
    try {
      // print('delete annot' + id);
      final response = await _apiService.delete('/sectors/annotations/$id');

      if (response.statusCode != 204) {
        throw Exception('Failed to delete annotation: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to delete annotation: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> fetchShiValues(
      {int? year, String? farmerId}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (year != null) {
        queryParams['year'] = year.toString();
      }
      if (farmerId != null) {
        queryParams['farmerId'] = farmerId;
      }

      final response = await _apiService.get(
        '/sectors/shi-values',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data['data']);
      } else {
        throw Exception('Failed to load SHI values: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch SHI values: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to fetch SHI values: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> fetchYieldStatistics(
      {int? year, int? farmerId}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (year != null) {
        queryParams['year'] = year.toString();
      }
      if (farmerId != null) {
        queryParams['farmerId'] = farmerId;
      }

      final response = await _apiService.get(
        '/yields/yield-statistics',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data['statistics']);
      } else {
        throw Exception(
            'Failed to load yield statistics: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch yield statistics: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to fetch yield statistics: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getFarmerYieldDistribution({
    required String farmerId,
    int? year,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'farmerId': farmerId,
      };

      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get(
        '/yields/farmer-yield-distribution',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Return the raw response data

        // print(response.data);
        return response.data;
      } else {
        throw Exception(
            'Failed to load farmer product distribution: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
          'Network error fetching product distribution: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch product distribution: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> fetchFarmerStatistics({int? year}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get(
        '/farmers/farmer-statistics',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data['statistics']);
      } else {
        throw Exception(
            'Failed to load farmer statistics: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch farmer statistics: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to fetch farmer statistics: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> fetchUserStatistics({int? year}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get(
        '/auth/user-statistics',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data['statistics']);
      } else {
        throw Exception(
            'Failed to load user statistics: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch user statistics: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to fetch user statistics: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> fetchFarmStatistics({int? year}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get(
        '/farms/farm-statistics',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data['statistics']);
      } else {
        throw Exception(
            'Failed to load farm statistics: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch farm statistics: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to fetch farm statistics: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> fetchSectorDetails(
      {required int sectorId, int? year}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get(
        '/sectors/sectors/$sectorId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data['sector']);
      } else if (response.statusCode == 404) {
        throw Exception('Sector not found');
      } else {
        throw Exception(
            'Failed to load sector details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Sector not found');
      }
      throw Exception('Failed to fetch sector details: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to fetch sector details: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchYieldDistribution({
    int? sectorId,
    int? year,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (sectorId != null) {
        queryParams['sectorId'] = sectorId.toString();
      }

      if (year != null) {
        queryParams['year'] = year.toString();
      }

      final response = await _apiService.get(
        '/yields/yield-distribution',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data
            .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (response.statusCode == 400) {
        throw Exception(
            response.data['message'] ?? 'Invalid request parameters');
      } else {
        throw Exception(
            'Failed to load yield distribution: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(
            e.response?.data['message'] ?? 'Invalid request parameters');
      }
      throw Exception('Failed to fetch yield distribution: ${e.toString()}');
    } catch (e) {
      throw Exception('Failed to fetch yield distribution: ${e.toString()}');
    }
  }
}
