// lib/features/site/api/site_api.dart
import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../../../utils/constants/token_storage.dart';
import '../model/site_model.dart';


class SiteApi {
  final Dio _dio;

  SiteApi(this._dio);

  Future<SiteListModel> getSitesByUser() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Authorization token is missing');
      }

      final response = await _dio.get(
        '${Env.centralAuthBaseUrl}/api/user/get_site_access_by_user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SiteListModel.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch sites: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch sites: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch sites: $e');
    }
  }
}
