// // lib/features/survey/api/survey_submit_api.dart
// import 'dart:developer';
//
// import 'package:dio/dio.dart';
//
// import '../../../core/config/env.dart';
// import '../../../utils/constants/token_storage.dart';
// import '../model/survey_submit_model.dart';
//
//
// class SurveySubmitApi {
//   final Dio _dio;
//
//   SurveySubmitApi(this._dio);
//
//   Future<SurveySubmitResponseModel> submitSurveyResponse({
//     required int surveyId,
//     required String outletCode,
//     required double? locationLat,
//     required double? locationLon,
//     required List<Map<String, dynamic>> questionResponses,
//     required Map<int, String> imagePaths,
//   }) async {
//     try {
//       final token = await TokenStorage.getToken();
//       if (token == null) {
//         throw Exception('Authorization token is missing');
//       }
//
//       // Create form data
//       final formData = FormData();
//
//       // Add regular fields
//       formData.fields.addAll([
//         MapEntry('survey', surveyId.toString()),
//         MapEntry('outlet_code', outletCode),
//       ]);
//
//       // Add optional location fields
//       if (locationLat != null) {
//         formData.fields.add(MapEntry('location_lat', locationLat.toString()));
//       }
//       if (locationLon != null) {
//         formData.fields.add(MapEntry('location_lon', locationLon.toString()));
//       }
//
//       // Add each question response as individual fields
//       for (var i = 0; i < questionResponses.length; i++) {
//         final response = questionResponses[i];
//         final questionId = response['question'];
//
//         formData.fields.add(
//           MapEntry('question_responses[$i][question]', questionId.toString()),
//         );
//
//         if (response.containsKey('selected_choice')) {
//           final choiceId = response['selected_choice']['id'];
//           formData.fields.add(
//             MapEntry(
//               'question_responses[$i][selected_choice][id]',
//               choiceId.toString(),
//             ),
//           );
//         }
//
//         if (response.containsKey('linear_value')) {
//           final value = response['linear_value'];
//           formData.fields.add(
//             MapEntry('question_responses[$i][linear_value]', value.toString()),
//           );
//         }
//
//         if (response.containsKey('answer_text')) {
//           final text = response['answer_text'];
//           formData.fields.add(
//             MapEntry('question_responses[$i][answer_text]', text),
//           );
//         }
//
//         if (response.containsKey('location_lat') &&
//             response.containsKey('location_lon')) {
//           final lat = response['location_lat'];
//           final lon = response['location_lon'];
//           formData.fields.add(
//             MapEntry('question_responses[$i][location_lat]', lat.toString()),
//           );
//           formData.fields.add(
//             MapEntry('question_responses[$i][location_lon]', lon.toString()),
//           );
//         }
//       }
//
//       // Add image files to form data
//       for (var entry in imagePaths.entries) {
//         if (entry.value.isNotEmpty) {
//           try {
//             final file = await MultipartFile.fromFile(
//               entry.value,
//               filename: 'question_${entry.key}_image.jpg',
//             );
//             formData.files.add(MapEntry('question_${entry.key}_image', file));
//           } catch (e) {
//             throw Exception(
//               'Failed to process image for question ${entry.key}',
//             );
//           }
//         }
//       }
//
//       // Make the request
//       final response = await _dio.post(
//         '${Env.surveyBaseUrl}/survey/api/survey/submit-response/',
//         data: formData,
//         options: Options(
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Accept': 'application/json',
//             'Content-Type': 'multipart/form-data',
//           },
//         ),
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return SurveySubmitResponseModel.fromJson(response.data);
//       } else {
//         throw Exception('Failed to submit survey: ${response.statusCode}');
//       }
//     } on DioException catch (e) {
//       log('Dio error during survey submission: ${e.message}');
//       log('Error type: ${e.type}');
//       log('Error response: ${e.response?.data}');
//       log('Error status: ${e.response?.statusCode}');
//
//       if (e.response != null) {
//         final errorData = e.response?.data;
//         final errorMessage = errorData is Map<String, dynamic>
//             ? errorData['detail'] ??
//                   errorData['message'] ??
//                   'Failed to submit survey. Please try again.'
//             : 'Failed to submit survey. Please try again.';
//
//         throw Exception(errorMessage);
//       } else if (e.type == DioExceptionType.connectionTimeout ||
//           e.type == DioExceptionType.receiveTimeout ||
//           e.type == DioExceptionType.sendTimeout) {
//         throw Exception(
//           'Connection timeout. Please check your internet connection.',
//         );
//       } else {
//         throw Exception(
//           'Network error. Please check your connection and try again.',
//         );
//       }
//     } catch (e) {
//       log('Unexpected error during survey submission: $e');
//       throw Exception('An unexpected error occurred. Please try again.');
//     }
//   }
// }



// lib/features/survey/api/survey_submit_api.dart
import 'dart:convert';
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
      if (token == null || token.isEmpty) {
        throw Exception('Authorization token is missing');
      }

      // Pull current user identity from profile (authoritative), fallback to JWT claims.
      final id = await _resolveIdentity(token);

      // ---------- Build multipart ----------
      final formData = FormData();

      // Required
      formData.fields.addAll([
        MapEntry('survey', surveyId.toString()),
        MapEntry('outlet_code', outletCode),
      ]);

      // Optional geo
      if (locationLat != null) {
        formData.fields.add(MapEntry('location_lat', locationLat.toString()));
      }
      if (locationLon != null) {
        formData.fields.add(MapEntry('location_lon', locationLon.toString()));
      }

      // Identity in BODY (cover every key your backend might look for)
      if ((id.userId ?? '').isNotEmpty) {
        formData.fields.add(MapEntry('user_id', id.userId!));
      }
      if ((id.name ?? '').isNotEmpty) {
        formData.fields.add(MapEntry('submitted_by', id.name!));
      }
      if ((id.phone ?? '').isNotEmpty) {
        formData.fields.add(MapEntry('user_phone', id.phone!));
        formData.fields.add(MapEntry('submitted_user_phone', id.phone!));
      }
      if ((id.username ?? '').isNotEmpty) {
        formData.fields.add(MapEntry('username', id.username!));
      }
      // Provide a single JSON blob too (some backends parse this)
      formData.fields.add(MapEntry(
        'identity',
        jsonEncode({
          'user_id': id.userId,
          'name': id.name,
          'username': id.username,
          'phone_number': id.phone,
          'access': id.access,
          'platform_id': id.platformId,
          'platform_name': id.platformName,
        }),
      ));

      // Answers
      for (var i = 0; i < questionResponses.length; i++) {
        final r = questionResponses[i];
        final qid = r['question'];

        formData.fields.add(
          MapEntry('question_responses[$i][question]', qid.toString()),
        );

        if (r.containsKey('selected_choice')) {
          final cid = r['selected_choice']['id'];
          formData.fields.add(MapEntry(
            'question_responses[$i][selected_choice][id]',
            cid.toString(),
          ));
        }
        if (r.containsKey('linear_value')) {
          final v = r['linear_value'];
          formData.fields.add(
            MapEntry('question_responses[$i][linear_value]', v.toString()),
          );
        }
        if (r.containsKey('answer_text')) {
          formData.fields.add(
            MapEntry('question_responses[$i][answer_text]', r['answer_text']),
          );
        }
        if (r.containsKey('location_lat') && r.containsKey('location_lon')) {
          formData.fields.add(MapEntry(
              'question_responses[$i][location_lat]',
              r['location_lat'].toString()));
          formData.fields.add(MapEntry(
              'question_responses[$i][location_lon]',
              r['location_lon'].toString()));
        }
      }

      // Images
      for (final e in imagePaths.entries) {
        final path = e.value;
        if (path.isEmpty) continue;
        try {
          final file = await MultipartFile.fromFile(
            path,
            filename: 'question_${e.key}_image.jpg',
          );
          formData.files.add(MapEntry('question_${e.key}_image', file));
        } catch (_) {
          throw Exception('Failed to process image for question ${e.key}');
        }
      }

      // Identity in HEADERS (with multiple common key variants)
      final identityHeaders = <String, String>{
        // canonical
        if ((id.userId ?? '').isNotEmpty) 'X-User-Id': id.userId!,
        if ((id.name ?? '').isNotEmpty) 'X-User-Name': id.name!,
        if ((id.phone ?? '').isNotEmpty) 'X-User-Phone': id.phone!,
        if ((id.username ?? '').isNotEmpty) 'X-Username': id.username!,
        if ((id.access ?? '').isNotEmpty) 'X-Access': id.access!,
        if ((id.platformId ?? '').isNotEmpty) 'X-Platform-Id': id.platformId!,
        if ((id.platformName ?? '').isNotEmpty)
          'X-Platform-Name': id.platformName!,

        // lowercase / uppercase fallbacks
        if ((id.userId ?? '').isNotEmpty) 'x-user-id': id.userId!,
        if ((id.name ?? '').isNotEmpty) 'x-user-name': id.name!,
        if ((id.phone ?? '').isNotEmpty) 'x-user-phone': id.phone!,
        if ((id.username ?? '').isNotEmpty) 'x-username': id.username!,
        if ((id.access ?? '').isNotEmpty) 'x-access': id.access!,
        if ((id.platformId ?? '').isNotEmpty) 'x-platform-id': id.platformId!,
        if ((id.platformName ?? '').isNotEmpty)
          'x-platform-name': id.platformName!,

        if ((id.userId ?? '').isNotEmpty) 'X-USER-ID': id.userId!,
        if ((id.name ?? '').isNotEmpty) 'X-USER-NAME': id.name!,
        if ((id.phone ?? '').isNotEmpty) 'X-USER-PHONE': id.phone!,
        if ((id.username ?? '').isNotEmpty) 'X-USERNAME': id.username!,
      };

      final res = await _dio.post(
        '${Env.surveyBaseUrl}/survey/api/survey/submit-response/',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
            ...identityHeaders,
          },
        ),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return SurveySubmitResponseModel.fromJson(res.data);
      }
      throw Exception('Failed to submit survey: ${res.statusCode}');
    } on DioException catch (e) {
      log('Dio error during survey submission: ${e.message}');
      log('Error type: ${e.type}');
      log('Error response: ${e.response?.data}');
      log('Error status: ${e.response?.statusCode}');
      if (e.response != null) {
        final d = e.response?.data;
        final msg = d is Map<String, dynamic>
            ? (d['detail'] ?? d['message'] ?? 'Failed to submit survey.')
            : 'Failed to submit survey.';
        throw Exception(msg);
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else {
        throw Exception('Network error. Please check your connection and try again.');
      }
    } catch (e) {
      log('Unexpected error during survey submission: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // ---------------- helpers ----------------

  Future<_Identity> _resolveIdentity(String token) async {
    // Prefer the central profile (it already works for you)
    try {
      final r = await _dio.get(
        '${Env.centralAuthBaseUrl}/api/user/profile',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (r.statusCode == 200 && r.data is Map) {
        final m = r.data as Map<String, dynamic>;
        final data = m['data'] as Map<String, dynamic>?;
        final user = data?['user'] as Map<String, dynamic>?;

        final id = user?['id']?.toString();
        final username = user?['username']?.toString();
        final phone = user?['phone_number']?.toString();

        // Prefer 'name', fallback to "first last"
        String? name = user?['name']?.toString();
        if (name == null || name.trim().isEmpty) {
          final f = user?['first_name']?.toString() ?? '';
          final l = user?['last_name']?.toString() ?? '';
          final n = ('$f $l').trim();
          if (n.isNotEmpty) name = n;
        }
        final access = user?['access']?.toString();
        final platformId = user?['site']?['platform']?['id']?.toString();
        final platformName = user?['site']?['platform']?['name']?.toString();

        return _Identity(
          userId: id,
          username: username,
          phone: phone,
          name: (name == null || name.isEmpty) ? username : name,
          access: access,
          platformId: platformId,
          platformName: platformName,
        );
      }
    } catch (e) {
      log('Profile fetch failed, fallback to JWT decode: $e');
    }

    // Fallback to JWT (usually only has user_id)
    final p = _decodeJwt(token);
    final uid = p['user_id']?.toString();
    return _Identity(
      userId: uid,
      username: null,
      phone: null,
      name: uid != null ? 'User $uid' : null,
      access: null,
      platformId: null,
      platformName: null,
    );
  }

  Map<String, dynamic> _decodeJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return {};
      final payload = _b64(parts[1]);
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _b64(String input) {
    var out = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (out.length % 4) {
      case 0:
        break;
      case 2:
        out += '==';
        break;
      case 3:
        out += '=';
        break;
      default:
        break;
    }
    return utf8.decode(base64.decode(out));
  }
}

class _Identity {
  final String? userId;
  final String? username;
  final String? phone;
  final String? name;
  final String? access;
  final String? platformId;
  final String? platformName;
  const _Identity({
    required this.userId,
    required this.username,
    required this.phone,
    required this.name,
    required this.access,
    required this.platformId,
    required this.platformName,
  });
}
