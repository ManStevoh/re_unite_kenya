import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._storage, {String? baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? defaultApiBaseUrl(),
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage _storage;
  late final Dio dio;

  ApiException mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        Map<String, List<String>>? errors;
        final raw = data['errors'];
        if (raw is Map) {
          errors = raw.map(
            (key, value) => MapEntry(
              '$key',
              value is List ? value.map((e) => '$e').toList() : ['$value'],
            ),
          );
        }
        return ApiException(
          '${data['message']}',
          statusCode: error.response?.statusCode,
          errors: errors,
        );
      }
      return ApiException(
        error.message ?? 'Network error',
        statusCode: error.response?.statusCode,
      );
    }
    return ApiException(error.toString());
  }
}
