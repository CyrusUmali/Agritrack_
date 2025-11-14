import 'package:dio/dio.dart';
import 'package:flareline/core/models/assocs_model.dart';
import 'package:flareline/repositories/base_repository.dart'; // Import the base repository

class AssociationRepository extends BaseRepository {
  AssociationRepository({required super.apiService});

  Future<Association> getAssociationById(int associationId) async {
    try {
      // checkAuthentication(); // Use inherited method

      final response =
          await apiService.get('/assocs/associations/$associationId');
      return _validateAndParseAssociationResponse(response);
    } catch (e) {
      handleError(e,
          operation: 'load associations',
          skipAuthCheck: true); // Skip auth check
    }
  }

  Future<Association> updateAssociation(Association association) async {
    try {
      // checkAuthentication(); // Use inherited method
      _validateAssociationRequiredFields(association);

      final response = await apiService.put(
        '/assocs/associations/${association.id}',
        data: _buildAssociationData(association),
      );

      return _validateAndParseAssociationResponse(response);
    } catch (e) {
      handleError(e, operation: 'update association'); // Use inherited method
    }
  }

  Future<List<Association>> fetchAssociations(int? year) async {
    try {
      // print('here1');

      // Build query parameters
      final Map<String, dynamic> queryParams = {};
      if (year != null) {
        queryParams['year'] = year;
      }

      final response = await apiService.get(
        '/assocs/associations',
        queryParameters: queryParams,
      );

      return _validateAndParseAssociationsResponse(response);
    } on DioException catch (e) {
      // Handle DioException specifically without auth check
      handleError(e, operation: 'load associations', skipAuthCheck: true);
    } catch (e) {
      // For non-DioException errors, also skip auth check
      handleError(e, operation: 'load associations', skipAuthCheck: true);
    }
  }

  Future<void> deleteAssociation(int associationId) async {
    try {
      // checkAuthentication(); // Use inherited method
      await apiService.delete('/assocs/associations/$associationId');
    } catch (e) {
      handleError(e, operation: 'delete association'); // Use inherited method
    }
  }

  Future<Association> createAssociation({
    required String name,
    required String description,
  }) async {
    try {
      // checkAuthentication(); // Use inherited method
      _validateCreateAssociationFields(name, description);

      final response = await apiService.post(
        '/assocs/associations',
        data: _buildCreateAssociationData(name, description),
      );

      return _validateAndParseAssociationResponse(response);
    } catch (e) {
      handleError(e, operation: 'create association'); // Use inherited method
    }
  }

  // Helper method for association validation
  void _validateAssociationRequiredFields(Association association) {
    if (association.name == null || association.name!.isEmpty) {
      throw Exception('Association name is required');
    }
  }

  // Helper method for create association validation
  void _validateCreateAssociationFields(String name, String description) {
    if (name.isEmpty) {
      throw Exception('Association name is required');
    }
    if (description.isEmpty) {
      throw Exception('Association description is required');
    }
  }

  // Helper method to build association data for update
  Map<String, dynamic> _buildAssociationData(Association association) {
    return {
      'name': association.name,
      'description': association.description,
    };
  }

  // Helper method to build association data for create
  Map<String, dynamic> _buildCreateAssociationData(
      String name, String description) {
    return {
      'name': name,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Helper method for response validation
  Association _validateAndParseAssociationResponse(Response response) {
    if (response.data == null) {
      throw Exception('Server returned empty response');
    }

    if (response.data['association'] == null) {
      throw Exception('Invalid association data format received from server');
    }

    return Association.fromJson(response.data['association']);
  }

  // Helper method for associations list validation
  List<Association> _validateAndParseAssociationsResponse(Response response) {
    if (response.data == null) {
      throw Exception('Server returned empty response');
    }

    if (response.data['associations'] == null) {
      throw Exception('Invalid associations data format received from server');
    }

    final associationsData = response.data['associations'] as List;
    return associationsData.map((json) => Association.fromJson(json)).toList();
  }
}
