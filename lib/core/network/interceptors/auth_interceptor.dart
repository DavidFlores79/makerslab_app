// lib/core/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/api_config.dart';
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
    // List of endpoints that don't require authentication
    final publicEndpoints = [
      ApiConfig.signInEndpoint,
      ApiConfig.phoneSignInEndpoint,
      ApiConfig.signUpEndpoint,
      ApiConfig.verifyRegistrationEndpoint,
      ApiConfig.forgotPasswordEndpoint,
      ApiConfig.resendCodeEndpoint,
      ApiConfig.confirmSignUpEndpoint,
      ApiConfig.countriesEndpoint,
      ApiConfig.legalDocumentsEndpoint,
    ];

    // Check if this is a public endpoint
    final isPublicEndpoint = publicEndpoints.any(
      (endpoint) => options.path.contains(endpoint),
    );

    // Only add auth token for non-public endpoints
    if (!isPublicEndpoint) {
      try {
        final token = await secureStorage.read(
          key: SecureStorageKeys.accessToken,
        );
        debugPrint(
          ">>> Adding auth token to request: ${token?.substring(0, 20)}...",
        );
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        // ignore storage errors — request proceeds without token
      }
    } else {
      debugPrint(">>> Public endpoint, skipping auth token: ${options.path}");
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
