// lib/data/network/refresh_token_service.dart
import 'package:dio/dio.dart';

class RefreshResult {
  final String accessToken;
  final String refreshToken;
  RefreshResult({required this.accessToken, required this.refreshToken});
}

class RefreshTokenService {
  final Dio _plainDio;
  final String baseUrl;

  RefreshTokenService({required Dio plainDio, required this.baseUrl})
    : _plainDio = plainDio;

  Future<RefreshResult> refresh(String refreshToken) async {
    final resp = await _plainDio.post(
      '$baseUrl/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (resp.statusCode == 200) {
      final data = resp.data as Map<String, dynamic>;
      return RefreshResult(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    }

    throw Exception('Refresh token failed: ${resp.statusMessage ?? resp.data}');
  }
}
