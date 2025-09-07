// lib/features/survey/api/survey_submit_api.dart
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../../../utils/constants/token_storage.dart';
import '../../profile/api/user_api.dart';
import '../model/survey_submit_model.dart';

class SurveySubmitApi {
  final Dio _dio;
  final UserApiService _userApi;

  SurveySubmitApi(this._dio, this._userApi);

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
      if (token == null || token.isEmpty) {
        throw Exception('Authorization token is missing');
      }

      // 👉 Fetch the user profile FIRST (same token you already have)
      //    so we can pass identity along with the submit request.
      final profile = await _userApi.getUserProfile();
      final user = profile.data?.user;

      // Safe fallbacks
      final userId = user?.id?.toString() ?? '';
      final userName = (user?.name ?? user?.firstName ?? '').trim();
      final userPhone = (user?.phoneNumber ?? user?.username ?? '')
          .trim(); // phone stored in username sometimes
      final usernameForAudit = (user?.username ?? userPhone).trim();
      final access = (user?.access ?? '').trim();
      final platformId = user?.site?.platform?.id != null
          ? user!.site!.platform!.id!.toString()
          : '';
      final platformName = (user?.site?.platform?.name ?? '').trim();

      // Build a compact identity blob as well (your backend can ignore it if it wants)
      final identityJson = jsonEncode({
        'user_id': userId,
        'name': userName,
        'username': usernameForAudit,
        'phone_number': userPhone,
        'access': access,
        'platform_id': platformId,
        'platform_name': platformName,
      });

      // ---------- Create FormData ----------
      final formData = FormData();

      // Required fields
      formData.fields.addAll([
        MapEntry('survey', surveyId.toString()),
        MapEntry('outlet_code', outletCode),
      ]);

      // Optional location fields
      if (locationLat != null) {
        formData.fields.add(MapEntry('location_lat', locationLat.toString()));
      }
      if (locationLon != null) {
        formData.fields.add(MapEntry('location_lon', locationLon.toString()));
      }

      // 🔐 Identity fields (the ones you said the backend can accept)
      // These do not change UI/UX; they just travel with the request.
      if (userId.isNotEmpty) formData.fields.add(MapEntry('user_id', userId));
      if (userName.isNotEmpty)
        formData.fields.add(MapEntry('submitted_by', userName));
      if (userPhone.isNotEmpty) {
        formData.fields.add(MapEntry('user_phone', userPhone));
        formData.fields.add(MapEntry('submitted_user_phone', userPhone));
      }
      if (usernameForAudit.isNotEmpty) {
        formData.fields.add(MapEntry('username', usernameForAudit));
      }
      formData.fields.add(MapEntry('identity', identityJson));

      // Question responses -> individual multipart fields
      for (var i = 0; i < questionResponses.length; i++) {
        final response = questionResponses[i];
        final qid = response['question'];

        formData.fields.add(
          MapEntry('question_responses[$i][question]', qid.toString()),
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
          formData.fields.add(
            MapEntry(
              'question_responses[$i][linear_value]',
              response['linear_value'].toString(),
            ),
          );
        }

        if (response.containsKey('answer_text')) {
          formData.fields.add(
            MapEntry(
              'question_responses[$i][answer_text]',
              response['answer_text'].toString(),
            ),
          );
        }

        if (response.containsKey('location_lat') &&
            response.containsKey('location_lon')) {
          formData.fields.add(
            MapEntry(
              'question_responses[$i][location_lat]',
              response['location_lat'].toString(),
            ),
          );
          formData.fields.add(
            MapEntry(
              'question_responses[$i][location_lon]',
              response['location_lon'].toString(),
            ),
          );
        }
      }

      // Image files
      for (final entry in imagePaths.entries) {
        final qId = entry.key;
        final path = entry.value;
        if (path.isEmpty) continue;

        try {
          final file = await MultipartFile.fromFile(
            path,
            filename: 'question_${qId}_image.jpg',
          );
          formData.files.add(MapEntry('question_${qId}_image', file));
        } catch (_) {
          throw Exception('Failed to process image for question $qId');
        }
      }

      // ---------- Headers ----------
      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        // Pass identity in headers, too (backend may read either)
        if (userId.isNotEmpty) 'X-User-Id': userId,
        if (userName.isNotEmpty) 'X-User-Name': userName,
        if (userPhone.isNotEmpty) 'X-User-Phone': userPhone,
        if (usernameForAudit.isNotEmpty) 'X-Username': usernameForAudit,
        if (access.isNotEmpty) 'X-Access': access,
        if (platformId.isNotEmpty) 'X-Platform-Id': platformId,
        if (platformName.isNotEmpty) 'X-Platform-Name': platformName,
      };

      // ---------- DEBUG LOGS (keep your style) ----------
      // URL
      // ignore: avoid_print
      print(
        'PRINT OUTPUT: API URL: ${Env.surveyBaseUrl}/survey/api/survey/submit-response/',
      );
      // ignore: avoid_print
      print('\n[log] JSON OUTPUT: HEADER: ${jsonEncode(headers)}\n');

      // Pretty-print a snapshot of fields without files
      final previewFields = formData.fields
          .map((e) => '"${e.key}=${e.value}"')
          .toList();
      // ignore: avoid_print
      print(
        '[log] JSON OUTPUT: REQUEST BODY (multipart) {\n'
        '"fields": [\n${previewFields.map((l) => '  $l').join(',\n')}\n],\n'
        '"files": [${formData.files.map((f) => '"${f.key}[${f.value.filename}]"').join(', ')}]\n'
        '}\n',
      );

      // ---------- Request ----------
      final response = await _dio.post(
        '${Env.surveyBaseUrl}/survey/api/survey/submit-response/',
        data: formData,
        options: Options(headers: headers),
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
            ? (errorData['detail'] ??
                  errorData['message'] ??
                  'Failed to submit survey. Please try again.')
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
