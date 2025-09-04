// lib/features/result/api/result_api_service.dart
import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import '../../../core/config/env.dart';
import '../../../core/network/dio_provider.dart';
import '../../../utils/constants/token_storage.dart';
import '../model/survey_result_model.dart';

final resultApiServiceProvider = Provider<ResultApiService>((ref) {
  final dio = ref.read(dioProvider);
  return ResultApiService(dio);
});

class ResultApiService {
  final Dio _dio;

  ResultApiService(this._dio);

  Future<SurveyResultModel> getSurveyResult(int responseId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Authorization token is missing');
      }

      print('🔍 Fetching survey result for responseId: $responseId');

      // Use the full URL with Env.surveyBaseUrl like your SiteApi does
      final response = await _dio.get(
        '${Env.surveyBaseUrl}/survey/survey-result/$responseId/by-category/',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('✅ API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return SurveyResultModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load survey result: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioError: ${e.message}');
      print('❌ Error Type: ${e.type}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status Code: ${e.response?.statusCode}');

      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} - ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}
