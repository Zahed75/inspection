// lib/features/signup/api/signup_repository.dart


import '../../../core/config/env.dart';
import '../../../core/network/dio_helper.dart';
import '../model/register_user_model.dart';

class SignupRepository {
  static final DioHelper _dio = DioHelper();

  Future<RegisterUserModel> register({
    required String name,
    required String phoneNumber,
    required String password,
    required String email,
    required String staffId,
    required String designation,
  }) async {
    final url = Env.registerUrl; // absolute URL from Env

    final body = {
      'name': name,
      'phone_number': phoneNumber,
      'password': password,
      'email': email,
      // your backend shows staff_id numeric; send int if parsable
      'staff_id': int.tryParse(staffId) ?? staffId,
      'designation': designation,
    };

    final res = await _dio.post(
      url: url,
      requestBody: body,
      isAuthRequired: false,
    );

    if (res == null) {
      throw Exception('Signup failed (network or server error).');
    }

    // your DioHelper returns `res.data`; for success it should be Map
    return RegisterUserModel.fromJson(res as Map<String, dynamic>);
  }
}
