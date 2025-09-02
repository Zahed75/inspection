// // lib/features/site/api/site_api.dart
// import 'package:dio/dio.dart';
//
// import '../../../core/config/env.dart';
// import '../../../utils/constants/token_storage.dart';
// import '../model/site_model.dart';
//
//
// class SiteApi {
//   final Dio _dio;
//
//   SiteApi(this._dio);
//
//   Future<SiteListModel> getSitesByUser() async {
//     try {
//       final token = await TokenStorage.getToken();
//       if (token == null) {
//         throw Exception('Authorization token is missing');
//       }
//
//       final response = await _dio.get(
//         '${Env.centralAuthBaseUrl}/api/user/get_site_access_by_user',
//         options: Options(
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Accept': 'application/json',
//           },
//         ),
//       );
//
//       if (response.statusCode == 200) {
//         return SiteListModel.fromJson(response.data);
//       } else {
//         throw Exception('Failed to fetch sites: ${response.statusCode}');
//       }
//     } on DioException catch (e) {
//       throw Exception('Failed to fetch sites: ${e.message}');
//     } catch (e) {
//       throw Exception('Failed to fetch sites: $e');
//     }
//   }
// }






// lib/features/site/api/site_api.dart
import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../../../utils/constants/token_storage.dart';
import '../model/site_model.dart';

class SiteApi {
  final Dio _dio;

  SiteApi(this._dio);

  Future<SiteListModel> getSitesByUser({int page = 1, int pageSize = 50}) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Authorization token is missing');
      }

      final response = await _dio.get(
        '${Env.centralAuthBaseUrl}/api/user/get_site_access_by_user',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
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

  // Method to fetch all sites by making multiple paginated requests
  // lib/features/site/api/site_api.dart
  Future<List<Sites>> getAllSites() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Authorization token is missing');
      }

      List<Sites> allSites = [];
      int currentPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        final response = await _dio.get(
          '${Env.centralAuthBaseUrl}/api/user/get_site_access_by_user',
          queryParameters: {
            'page': currentPage,
            'page_size': 100, // Fetch 100 per page to reduce requests
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          final siteList = SiteListModel.fromJson(response.data);
          if (siteList.sites != null && siteList.sites!.isNotEmpty) {
            allSites.addAll(siteList.sites!);
          }

          // Check if there are more pages - use proper null check
          hasMorePages = siteList.next != null && siteList.next!.isNotEmpty;
          currentPage++;

          // Add a small delay to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 100));
        } else {
          throw Exception('Failed to fetch sites: ${response.statusCode}');
        }
      }

      return allSites;
    } on DioException catch (e) {
      throw Exception('Failed to fetch sites: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch sites: $e');
    }
  }
}