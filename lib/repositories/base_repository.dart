import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flareline/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class BaseRepository {
  final ApiService apiService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  BaseRepository({required this.apiService});

  Never handleError(dynamic error,
      {String operation = 'operation', bool skipAuthCheck = false}) {
    if (error is DioException) {
      _handleDioError(error,
          operation: operation, skipAuthCheck: skipAuthCheck);
    } else if (error is FirebaseAuthException) {
      _handleFirebaseAuthError(error, operation: operation);
    } else if (error is TimeoutException) {
      throw Exception(
          'Request timed out. Please check your internet connection and try again.');
    } else if (error is SocketException) {
      throw Exception(
          'No internet connection. Please check your network settings.');
    } else {
      throw Exception('Failed to complete $operation: ${error.toString()}');
    }
  }

  Never _handleDioError(DioException e,
      {required String operation, bool skipAuthCheck = false}) {
    // Network connectivity errors
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw Exception(
          'Network connection failed. Please check your internet connection and try again.');
    }

    // No internet connection
    if (e.type == DioExceptionType.unknown && e.error is SocketException) {
      throw Exception(
          'No internet connection. Please check your network settings.');
    }

    // HTTP status code based errors
    final statusCode = e.response?.statusCode;
    final errorData = e.response?.data;
    final message = errorData?['message']?.toString();

    switch (statusCode) {
      case 400:
        throw Exception(
            message ?? 'Invalid request data. Please check your input.');
      case 401:
        if (!skipAuthCheck) {
          checkAuthentication(); // Only check auth if not skipped
        }
        throw Exception(
            message ?? 'Authentication failed. Please sign in again.');
      case 403:
        throw Exception('You do not have permission to perform this action.');
      case 404:
        throw Exception('Resource not found');
      case 409:
        throw Exception('Resource already exists.');
      case 500:
        throw Exception('Server error. Please try again later.');
      case 503:
        throw Exception(
            'Service temporarily unavailable. Please try again later.');
      default:
        throw Exception('Network error during $operation: ${e.message}');
    }
  }

  Never _handleFirebaseAuthError(FirebaseAuthException e,
      {required String operation}) {
    switch (e.code) {
      case 'wrong-password':
        print('error code');
        print(e.code);
        throw Exception('Current password is incorrect');
      case 'weak-password':
        throw Exception(
            'New password is too weak. Please choose a stronger password.');
      case 'requires-recent-login':
        throw Exception(
            'This operation requires recent authentication. Please sign in again.');
      case 'user-not-found':
        throw Exception('User not found');
      case 'email-already-in-use':
        throw Exception('Email already in use by another user');
      default:
        throw Exception('Authentication error during $operation: ${e.message}');
    }
  }

  void checkAuthentication() {
    if (_firebaseAuth.currentUser == null) {
      throw Exception('User not authenticated. Please sign in first.');
    }
  }

  int getSectorId(String sectorName) {
    const sectorMap = {
      'Fishery': 5,
      'Livestock': 4,
      'Organic': 6,
      'HVC': 3,
      'Corn': 2,
      'Rice': 1,
    };
    return sectorMap[sectorName] ?? 4; // Default to Livestock if not found
  }
}
