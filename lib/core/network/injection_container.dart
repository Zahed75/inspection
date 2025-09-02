
import 'package:dio/dio.dart';

import '../../utils/helpers/print_value.dart';

Dio getDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: '', // <— IMPORTANT: one place to set base url
      connectTimeout: const Duration(seconds: 40),
      receiveTimeout: const Duration(seconds: 40),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        // Log URL & headers
        printValue(options.uri.toString(), tag: 'API URL:');
        printValue(options.headers, tag: 'HEADER:');

        final data = options.data;
        if (data is FormData) {
          // 🔒 Don't jsonEncode FormData — list fields & file names instead
          final fields = data.fields.map((e) => '${e.key}=${e.value}').toList();
          final files = data.files.map((e) {
            final filename = e.value.filename ?? 'file';
            return '${e.key}[$filename]';
          }).toList();
          printValue({
            'fields': fields,
            'files': files,
          }, tag: 'REQUEST BODY (multipart)');
        } else {
          // Safe for JSON/null/primitive bodies
          try {
            printValue(tag: 'REQUEST BODY:', data); // no jsonEncode
          } catch (e) {
            printValue(tag: 'REQUEST BODY ERROR', e.toString());
          }
        }

        // (optional) leave baseUrl blank if you’re always using absolute URLs
        options.baseUrl = "";
        return handler.next(options);
      },

      onResponse: (Response response, ResponseInterceptorHandler handler) {
        printValue(response.data, tag: 'API RESPONSE:');
        printValue(tag: 'HEADER', response.requestOptions.data);
        return handler.next(response);
      },

      onError: (DioException e, ErrorInterceptorHandler handler) {
        printValue('${e.response?.statusCode}', tag: 'STATUS CODE:');
        printValue(e.response?.data ?? e.message ?? '', tag: 'ERROR DATA:');
        return handler.next(e);
      },
    ),
  );

  return dio;
}
