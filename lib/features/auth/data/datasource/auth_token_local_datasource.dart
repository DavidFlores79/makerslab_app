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
  Future<bool> hasTokenStored();
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
  Future<bool> hasTokenStored() async {
    final token = await secureStorage.read(SecureStorageKeys.accessToken);
    debugPrint(">>> hasTokenStored: $token");
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(SecureStorageKeys.refreshToken);
  }
}
