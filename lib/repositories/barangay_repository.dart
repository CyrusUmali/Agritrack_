import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flareline/core/models/barangay_model.dart';
import 'package:flareline/services/api_service.dart';

class BarangayRepository {
  final ApiService apiService;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  BarangayRepository({required this.apiService});

  Future<List<Barangay>> fetchBarangays() async {
    try {
      if (_firebaseAuth.currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await apiService.get('/auth/barangays');

      if (response.data == null || response.data['barangays'] == null) {
        throw Exception('Invalid barangays data format');
      }

      final barangaysData = response.data['barangays'] as List;
      return barangaysData.map((json) => Barangay.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('API Error: ${e.response?.statusCode} - ${e.message}');
    } on FirebaseAuthException catch (e) {
      throw Exception('Authentication error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load barangays: $e');
    }
  }
}
