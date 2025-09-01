// lib/features/sigin/api/login_api.dart
import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../model/user_login_model.dart';


class LoginApi {
  final Dio _dio;

  LoginApi(this._dio);

  // API call to authenticate user
  Future<UserLoginModel> login({
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _dio.post(
      '${Env.centralAuthBaseUrl}/api/user/login',
      data: {'phone_number': phoneNumber, 'password': password},
    );

    if (response.statusCode == 200) {
      return UserLoginModel.fromJson(response.data);
    } else {
      throw Exception('Failed to login');
    }
  }
}
