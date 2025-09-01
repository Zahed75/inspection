// lib/features/verify_otp/api/verify_otp_repository.dart
import '../../../core/config/env.dart';
import '../../../core/network/dio_helper.dart';
import '../model/verify_otp_model.dart';

class VerifyOtpRepository {
  final DioHelper _dio = DioHelper();

  Future<VerifyOtpModel> verify({
    required String phoneNumber,
    required String otp,
  }) async {
    final body = {
      'phone_number': phoneNumber,
      'otp': int.tryParse(otp) ?? otp, // backend may accept int or string
    };

    final res = await _dio.post(
      url: Env.verifyOtpUrl,
      requestBody: body,
      isAuthRequired: false,
    );

    if (res == null) {
      throw Exception('Network error. Please try again.');
    }
    return VerifyOtpModel.fromJson(res as Map<String, dynamic>);
  }
}
