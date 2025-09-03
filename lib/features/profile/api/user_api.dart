// lib/features/profile/api/user_api_service.dart

import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/network/dio_provider.dart';
import '../../../utils/constants/token_storage.dart';
import '../model/user_info_model.dart';

final userApiServiceProvider = Provider<UserApiService>((ref) {
  final dio = ref.read(dioProvider);
  return UserApiService(dio);
});

class UserApiService {
  final Dio _dio;


  UserApiService(this._dio);

  // Add this method to check if token exists before making API calls
  Future<bool> _hasValidToken() async {
    final token = await TokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<GetUserInfoModel> getUserProfile() async {
    // Simple token check before making API call
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      print('❌ No token available for profile fetch');
      throw Exception('Authentication token is missing');
    }

    try {
      final response = await _dio.get(
        '${Env.centralAuthBaseUrl}/api/user/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return GetUserInfoModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token is invalid
        throw Exception('Session expired. Please login again.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}