// lib/features/survey/api/survey_api.dart
import 'package:dio/dio.dart';
import '../../../core/config/env.dart';
import '../../../utils/constants/token_storage.dart';
import '../../home/model/survey_list_model.dart';

class SurveyApi {
  final Dio _dio;

  SurveyApi(this._dio);

  // In your getSurveysByUser method, add the siteCode parameter
  // lib/features/survey/api/survey_api.dart
  Future<SurveyListModel> getSurveysByUser({String? siteCode}) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Authorization token is missing');
      }

      // Add site code filtering if provided
      final Map<String, dynamic> queryParams = {};
      if (siteCode != null && siteCode.isNotEmpty) {
        queryParams['site_code'] = siteCode;
      }

      final response = await _dio.get(
        '${Env.surveyBaseUrl}/survey/api/survey_by_user/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SurveyListModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load surveys: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to load surveys: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}