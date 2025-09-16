// lib/core/network/interceptors/error_interceptor.dart
import 'package:dio/dio.dart';
import '../api_exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      final code = response.statusCode ?? 0;
      final message =
          response.data != null && response.data is Map
              ? (response.data['message'] ??
                  response.data['error'] ??
                  response.data.toString())
              : err.message;

      if (code == 400) {
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: BadRequestException(message),
          ),
        );
      }
      if (code == 401) {
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: UnauthorizedException(message),
          ),
        );
      }
      if (code == 404) {
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NotFoundException(message),
          ),
        );
      }
      if (code >= 500) {
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ServerException(message),
          ),
        );
      }
    }

    // Fallback
    return handler.next(err);
  }
}
