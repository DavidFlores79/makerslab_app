import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_keys.dart';
import '../../../../core/storage/secure_storage_service.dart';

abstract class AuthTokenLocalDataSource {
  Future<void> cacheTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearSession();
  Future<bool> hasValidTokenStored();
}

class AuthTokenLocalDataSourceImpl implements AuthTokenLocalDataSource {
  final ISecureStorageService secureStorage;

  AuthTokenLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<void> cacheTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await secureStorage.write(SecureStorageKeys.accessToken, accessToken);
    await secureStorage.write(SecureStorageKeys.refreshToken, refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    return await secureStorage.read(SecureStorageKeys.accessToken);
  }

  @override
  Future<void> clearSession() async {
    await secureStorage.deleteAll();
  }

  @override
  Future<bool> hasValidTokenStored() async {
    final token = await secureStorage.read(SecureStorageKeys.accessToken);
    debugPrint(">>> hasTokenStored: $token");
    if (token == null || token.isEmpty) return false;
    return !_isJwtExpired(token);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(SecureStorageKeys.refreshToken);
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = utf8.decode(base64Url.decode(_normalize(parts[1])));
      final Map<String, dynamic> map = json.decode(payload);
      final exp = map['exp'];
      if (exp == null) return true;
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        exp * 1000,
        isUtc: true,
      );
      return expiry.isBefore(DateTime.now().toUtc());
    } catch (e) {
      debugPrint('Error decodificando JWT: $e');
      return true;
    }
  }

  String _normalize(String input) {
    return input
        .padRight((input.length + 3) ~/ 4 * 4, '=')
        .replaceAll('-', '+')
        .replaceAll('_', '/');
  }
}
