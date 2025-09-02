import 'package:dio/dio.dart';
import 'injection_container.dart'; // <-- use the getDio() that has interceptors

// --- Global headers ---
Map<String, dynamic> headers = {"Authorization": 'Bearer token'};

// --- Helper class ---
class DioHelper {
  // use getDio() from injection_container.dart (has interceptors)
  final Dio dio = getDio();

  final Options baseOptions = Options(
    receiveDataWhenStatusError: true,
    contentType: "application/json",
    sendTimeout: const Duration(seconds: 40),
    receiveTimeout: const Duration(seconds: 40),
    headers: {'accept': 'application/json'},
  );

  // GET

  Future<dynamic> get({
    required String url,
    bool isAuthRequired = false,
    Map<String, dynamic>? query,
    required Map<String, String> headers,
  }) async {
    final opts = baseOptions.copyWith(headers: isAuthRequired ? headers : null);
    try {
      final Response res = await dio.get(
        url,
        queryParameters: query,
        options: opts,
      );
      return res.data;
    } catch (_) {
      return null;
    }
  }

  // POST

  Future<dynamic> post({
    required String url,
    dynamic requestBody,
    bool isAuthRequired = false,
    Map<String, dynamic>? query,
  }) async {
    final opts = baseOptions.copyWith(headers: isAuthRequired ? headers : null);
    try {
      final Response res = await dio.post(
        url,
        data: requestBody,
        queryParameters: query,
        options: opts,
      );
      return res.data;
    } catch (_) {
      return null;
    }
  }



  // PUT
  Future<dynamic> put({
    required String url,
    dynamic requestBody,
    bool isAuthRequired = false,
    Map<String, dynamic>? query,
    required Options options,
  }) async {
    final opts = baseOptions.copyWith(headers: isAuthRequired ? headers : null);
    try {
      final Response res = await dio.put(
        url,
        data: requestBody,
        queryParameters: query,
        options: opts,
      );
      return res.data;
    } catch (_) {
      return null;
    }
  }

  // PATCH

  Future<dynamic> patch({
    required String url,
    dynamic requestBody,
    bool isAuthRequired = false,
    Map<String, dynamic>? query,
  }) async {
    final opts = baseOptions.copyWith(headers: isAuthRequired ? headers : null);
    try {
      final Response res = await dio.patch(
        url,
        data: requestBody,
        queryParameters: query,
        options: opts,
      );
      return res.data;
    } catch (_) {
      return null;
    }
  }

  // DELETE

  Future<dynamic> deleteReq({
    required String url,
    dynamic requestBody,
    bool isAuthRequired = false,
    Map<String, dynamic>? query,
    required Options options,
  }) async {
    final opts = baseOptions.copyWith(headers: isAuthRequired ? headers : null);
    try {
      final Response res = await dio.delete(
        url,
        data: requestBody,
        queryParameters: query,
        options: opts,
      );
      return res.data;
    } catch (_) {
      return null;
    }
  }

  // MULTIPART API

  Future<dynamic> uploadFile({
    required String url,
    Object? requestBody, // expect FormData
    bool isAuthRequired = false,
  }) async {
    // Use multipart for FormData; let Dio set the boundary automatically.
    final options = Options(
      receiveDataWhenStatusError: true,
      contentType: "multipart/form-data",
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'accept': 'application/json'},
    );

    try {
      final Response res = await dio.post(
        url,
        data: requestBody, // FormData.fromMap(...)
        options: options,
      );
      return res.data;
    } catch (e) {
      return null; // consider throwing instead
    }
  }
}
