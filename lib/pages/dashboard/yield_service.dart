import 'package:flareline/services/api_service.dart';

class YieldService {
  final ApiService _apiService;

  YieldService(this._apiService);

  Future<List<Map<String, dynamic>>> getTopContributors() async {
    try {
      final response = await _apiService.get('/auth/top-contributors');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return List<Map<String, dynamic>>.from(responseData['contributors']);
        }
        throw Exception(
            responseData['message'] ?? 'Failed to fetch top contributors');
      }
      throw Exception('Request failed with status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to get top contributors: ${e.toString()}');
    }
  }
}
