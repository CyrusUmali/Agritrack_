import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flareline/core/models/user_model.dart';
import 'package:flareline/services/api_service.dart';
import 'package:flareline/repositories/base_repository.dart'; // Import the base repository
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository extends BaseRepository {
  UserRepository({required super.apiService});

  Future<UserModel> getUserById(int userId) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService
          .get('/auth/users/$userId')
          .timeout(const Duration(seconds: 30));

      return _validateAndParseUserResponse(response);
    } catch (e) {
      handleError(e, operation: 'load user'); // Use inherited method
    }
  }

  Future<UserModel> updateUser(UserModel user) async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.put(
        '/auth/users/${user.id}',
        data: {
          'email': user.email,
          'name': user.name,
          'photoUrl': user.photoUrl,
          'role': user.role,
          'fname': user.fname,
          'lname': user.lname,
          'sector': user.sector,
          'phone': user.phone,
          'password': user.password,
          'newPassword': user.newPassword
        },
      ).timeout(const Duration(seconds: 30));

      return _validateAndParseUserResponse(response, method: 'update');
    } catch (e) {
      handleError(e, operation: 'update user'); // Use inherited method
    }
  }

  Future<List<UserModel>> fetchUsers() async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService
          .get('/auth/users')
          .timeout(const Duration(seconds: 30));

      return _validateAndParseUsersResponse(response);
    } catch (e) {
      handleError(e, operation: 'load users'); // Use inherited method
    }
  }

  int _getSectorId(String? sectorName) {
    const sectorMap = {
      'Rice': 1,
      'Corn': 2,
      'HVC': 3,
      'Livestock': 4,
      'Fishery': 5,
      'Organic': 6,
    };

    if (sectorName == null || !sectorMap.containsKey(sectorName)) {
      return 1;
    }

    return sectorMap[sectorName]!;
  }

  Future<UserModel> addUser(UserModel user) async {
    try {
      checkAuthentication(); // Use inherited method

      // Validate required fields
      if (user.email.isEmpty) throw Exception('Email is required');
      if (user.name.isEmpty) throw Exception('Name is required');
      if (user.role.isEmpty) throw Exception('Role is required');

      final requestData = {
        'email': user.email,
        'name': user.name,
        'photoUrl': user.photoUrl ?? "---",
        'role': user.role,
        'fname': user.fname,
        'lname': user.lname,
        'sectorId': _getSectorId(user.sector ?? 'N/A'),
        'barangay': user.barangay,
        'phone': user.phone,
        'password': user.password,
        'idToken': user.idToken,
        'farmerId': user.farmerId
      };

      final response = await apiService
          .post(
            '/auth/users',
            data: requestData,
          )
          .timeout(const Duration(seconds: 30));

      return _validateAndParseUserResponse(response, method: 'add');
    } catch (e) {
      handleError(e, operation: 'add user'); // Use inherited method
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      checkAuthentication(); // Use inherited method

      await apiService
          .delete('/auth/users/$userId')
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      handleError(e, operation: 'delete user'); // Use inherited method
    }
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    print('change passwrod');

    print('currentPassword');
    try {
      // Note: This method uses Firebase Auth directly, so we need to handle it specially
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Reauthenticate first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Then update password
      await user.updatePassword(newPassword);
    } catch (e) {
      handleError(e, operation: 'change password'); // Use inherited method
    }
  }

  // Helper method for response validation (PRESERVED - no changes)
  UserModel _validateAndParseUserResponse(Response response,
      {String method = 'get'}) {
    if (response.data == null) {
      throw Exception('Server returned empty response');
    }

    if (response.data['user'] == null) {
      throw Exception('Invalid user data format received from server');
    }

    return UserModel.fromJson(response.data['user']);
  }

  // Helper method for users list validation (PRESERVED - no changes)
  List<UserModel> _validateAndParseUsersResponse(Response response) {
    if (response.data == null) {
      throw Exception('Server returned empty response');
    }

    if (response.data['users'] == null) {
      throw Exception('Invalid users data format received from server');
    }

    final usersData = response.data['users'] as List;
    return usersData.map((json) => UserModel.fromJson(json)).toList();
  }
}
