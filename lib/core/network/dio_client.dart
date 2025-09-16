// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
// import 'interceptors/logging_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../../core/utils/env.dart';

class DioClient {
  final Dio dio;

  DioClient({required FlutterSecureStorage secureStorage, String? baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ) {
    // Interceptors order: Auth -> Logging -> Error (ajusta como prefieras)
    dio.interceptors.add(AuthInterceptor(secureStorage));
    // dio.interceptors.add(SimpleLoggingInterceptor());
    dio.interceptors.add(ErrorInterceptor());
    // Opcional: dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
}
