// lib/features/survey/api/survey_submit_api.dart
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../../../utils/constants/token_storage.dart';
import '../model/survey_submit_model.dart';


class SurveySubmitApi {
  final Dio _dio;

  SurveySubmitApi(this._dio);

  Future<SurveySubmitResponseModel> submitSurveyResponse({
    required int surveyId,
    required String outletCode,
    required double? locationLat,
    required double? locationLon,
    required List<Map<String, dynamic>> questionResponses,
    required Map<int, String> imagePaths,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Authorization token is missing');
      }

      // Create form data
      final formData = FormData();

      // Add regular fields
      formData.fields.addAll([
        MapEntry('survey', surveyId.toString()),
        MapEntry('outlet_code', outletCode),
      ]);

      // Add optional location fields
      if (locationLat != null) {
        formData.fields.add(MapEntry('location_lat', locationLat.toString()));
      }
      if (locationLon != null) {
        formData.fields.add(MapEntry('location_lon', locationLon.toString()));
      }

      // Add each question response as individual fields
      for (var i = 0; i < questionResponses.length; i++) {
        final response = questionResponses[i];
        final questionId = response['question'];

        formData.fields.add(
          MapEntry('question_responses[$i][question]', questionId.toString()),
        );

        if (response.containsKey('selected_choice')) {
          final choiceId = response['selected_choice']['id'];
          formData.fields.add(
            MapEntry(
              'question_responses[$i][selected_choice][id]',
              choiceId.toString(),
            ),
          );
        }

        if (response.containsKey('linear_value')) {
          final value = response['linear_value'];
          formData.fields.add(
            MapEntry('question_responses[$i][linear_value]', value.toString()),
          );
        }

        if (response.containsKey('answer_text')) {
          final text = response['answer_text'];
          formData.fields.add(
            MapEntry('question_responses[$i][answer_text]', text),
          );
        }

        if (response.containsKey('location_lat') &&
            response.containsKey('location_lon')) {
          final lat = response['location_lat'];
          final lon = response['location_lon'];
          formData.fields.add(
            MapEntry('question_responses[$i][location_lat]', lat.toString()),
          );
          formData.fields.add(
            MapEntry('question_responses[$i][location_lon]', lon.toString()),
          );
        }
      }

      // Add image files to form data
      for (var entry in imagePaths.entries) {
        if (entry.value.isNotEmpty) {
          try {
            final file = await MultipartFile.fromFile(
              entry.value,
              filename: 'question_${entry.key}_image.jpg',
            );
            formData.files.add(MapEntry('question_${entry.key}_image', file));
          } catch (e) {
            throw Exception(
              'Failed to process image for question ${entry.key}',
            );
          }
        }
      }

      // Make the request
      final response = await _dio.post(
        '${Env.surveyBaseUrl}/survey/api/survey/submit-response/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SurveySubmitResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to submit survey: ${response.statusCode}');
      }
    } on DioException catch (e) {
      log('Dio error during survey submission: ${e.message}');
      log('Error type: ${e.type}');
      log('Error response: ${e.response?.data}');
      log('Error status: ${e.response?.statusCode}');

      if (e.response != null) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['detail'] ??
                  errorData['message'] ??
                  'Failed to submit survey. Please try again.'
            : 'Failed to submit survey. Please try again.';

        throw Exception(errorMessage);
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else {
        throw Exception(
          'Network error. Please check your connection and try again.',
        );
      }
    } catch (e) {
      log('Unexpected error during survey submission: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }
}
