// lib/core/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../storage/secure_storage_keys.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage secureStorage;
  AuthInterceptor(this.secureStorage);

  final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await secureStorage.read(
        key: SecureStorageKeys.accessToken,
      );
      debugPrint(">>> Adding auth token to request $token");
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // ignore storage errors — request proceeds without token
    }
    return handler.next(options);
  }

  // Opcional: manejar 401 para intentar refresh (depende de tu backend)
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si tienes refresh token logic, aquí podrías implementarla:
    // - comprobar err.response?.statusCode == 401

    if (err.response?.statusCode == 401) {
      /// delete stored tokens and redirect to login
      // await secureStorage.delete(key: SecureStorageKeys.accessToken);
      // await secureStorage.delete(key: SecureStorageKeys.refreshToken);
      // Lógica para refrescar el token
      debugPrint(">>> Unauthorized! Token might be expired.");
    }

    // - bloquear nuevas requests, invocar endpoint refresh, actualizar storage
    // - repetir request original con nuevo token
    return handler.next(err);
  }
}
