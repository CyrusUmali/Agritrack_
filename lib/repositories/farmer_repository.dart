import 'package:dio/dio.dart';
import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/services/api_service.dart';
import 'package:flareline/repositories/base_repository.dart'; // Import the base repository

class FarmerRepository extends BaseRepository {
  FarmerRepository({required super.apiService});

  Future<Farmer> getFarmerById(int farmerId) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.get('/farmers/farmers/$farmerId');
      return _validateAndParseFarmerResponse(response);
    } catch (e) {
      handleError(e, operation: 'load farmer'); // Use inherited method
    }
  }

  Future<Farmer> updateFarmer(Farmer farmer) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.put(
        '/farmers/farmers/${farmer.id}',
        data: _buildFarmerUpdateData(farmer),
      );

      return _validateAndParseFarmerResponse(response);
    } catch (e) {
      handleError(e, operation: 'update farmer'); // Use inherited method
    }
  }

  // Helper method to build update data
  Map<String, dynamic> _buildFarmerUpdateData(Farmer farmer) {
    return {
      'name': farmer.name,
      'firstname': farmer.firstname,
      'middlename': farmer.middlename,
      'surname': farmer.surname,
      'extension': farmer.extension, 
      'email': farmer.email,
      'phone': farmer.phone,
      'address': farmer.address,
      'sex': farmer.sex,
      'barangay': farmer.barangay,
      'sectorId': getSectorId(farmer.sector!), // Use inherited method
      'imageUrl': farmer.imageUrl,
      'farm_name': farmer.farmName,
      'association': farmer.association,
      'birthday': farmer.birthday?.toIso8601String(),
      'total_land_area': farmer.hectare?.toString(),
      'house_hold_head': farmer.house_hold_head,
      'civil_status': farmer.civilStatus,
      'spouse_name': farmer.spouseName,
      'religion': farmer.religion,
      'household_num': farmer.householdNum,
      'male_members_num': farmer.maleMembersNum,
      'female_members_num': farmer.femaleMembersNum,
      'mother_maiden_name': farmer.motherMaidenName,
      'person_to_notify': farmer.personToNotify,
      'ptn_contact': farmer.ptnContact,
      'ptn_relationship': farmer.ptnRelationship,
      'accountStatus': farmer.accountStatus
    };
  }

  Future<List<Farmer>> fetchFarmers() async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.get('/farmers/farmers');
      return _validateAndParseFarmersResponse(response);
    } catch (e) {
      handleError(e, operation: 'load farmers'); // Use inherited method
    }
  }

  Future<Farmer> addFarmer(Farmer farmer) async {
    try {
      checkAuthentication(); // Use inherited method
      _validateFarmerRequiredFields(farmer);

      final requestData = _buildFarmerAddData(farmer);
      final response = await apiService.post('/farmers/farmers', data: requestData);

      return _validateAndParseFarmerResponse(response);
    } catch (e) {
      handleError(e, operation: 'add farmer'); // Use inherited method
    }
  }

  // Helper method for farmer validation (PRESERVED - no changes)
  void _validateFarmerRequiredFields(Farmer farmer) {
    if (farmer.name == null || farmer.name!.isEmpty) {
      throw Exception('Farmer name is required');
    }
    if (farmer.barangay == null || farmer.barangay!.isEmpty) {
      throw Exception('Barangay is required');
    }
    if (farmer.sector == null) {
      throw Exception('Sector is required');
    }
  }

  // Helper method to build add data (PRESERVED - no changes)
  Map<String, dynamic> _buildFarmerAddData(Farmer farmer) {
    return {
      'name': farmer.name!,
      'email': farmer.email ?? "---",
      'phone': farmer.phone ?? "---",
      'barangay': farmer.barangay!,
      'sectorId': getSectorId(farmer.sector!), // Use inherited method
      'imageUrl': farmer.imageUrl ?? "---",
      // Add other optional fields if needed
    };
  }

  Future<void> deleteFarmer(int farmerId) async {
    try {
      checkAuthentication(); // Use inherited method
      await apiService.delete('/farmers/farmers/$farmerId');
    } catch (e) {
      handleError(e, operation: 'delete farmer'); // Use inherited method
    }
  }

  // Helper method for response validation (PRESERVED - no changes)
  Farmer _validateAndParseFarmerResponse(Response response) {
    if (response.data == null) {
      throw Exception('Server returned empty response');
    }
    
    if (response.data['farmer'] == null) {
      throw Exception('Invalid farmer data format received from server');
    }

    print(response.data['farmer']);

    return Farmer.fromJson(response.data['farmer']);
  }

  // Helper method for farmers list validation (PRESERVED - no changes)
  List<Farmer> _validateAndParseFarmersResponse(Response response) {
    if (response.data == null) {
      throw Exception('Server returned empty response');
    }
    
    if (response.data['farmers'] == null) {
      throw Exception('Invalid farmers data format received from server');
    }

    final farmersData = response.data['farmers'] as List;
    return farmersData.map((json) => Farmer.fromJson(json)).toList();
  }
}