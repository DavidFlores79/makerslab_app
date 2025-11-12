import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/data/services/logger_service.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/forgot_password_response_model.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> signIn(String email, String password);
  Future<LoginResponseModel> phoneSignIn(String phone, String password);
  Future<LoginResponseModel> signUp({
    required String name,
    required String phone,
    required String password,
  });
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<ForgotPasswordResponseModel> forgotPassword(String phone);
  Future<void> resendSignUpCode({required String userId});
  Future<LoginResponseModel> confirmSignUp({
    required String userId,
    required String code,
  });
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? image,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final ILogger logger;

  AuthRemoteDataSourceImpl({required this.dio, required this.logger});

  @override
  Future<LoginResponseModel> signIn(String email, String password) async {
    debugPrint('POST ${ApiConfig.signInEndpoint} -> email: $email');
    final response = await _safePost(
      ApiConfig.signInEndpoint,
      data: {'email': email, 'password': password},
    );

    return LoginResponseModel.fromJson(_ensureMap(response.data));
  }

  @override
  Future<LoginResponseModel> phoneSignIn(String phone, String password) async {
    debugPrint('POST ${ApiConfig.phoneSignInEndpoint} -> phone: $phone');
    final response = await _safePost(
      ApiConfig.phoneSignInEndpoint,
      data: {'phone': '+52$phone', 'password': password},
    );

    return LoginResponseModel.fromJson(_ensureMap(response.data));
  }

  @override
  Future<LoginResponseModel> signUp({
    required String name,
    required String phone,
    required String password,
  }) async {
    logger.info(
      'POST ${ApiConfig.signUpEndpoint} -> name: $name, phone: $phone',
    );

    try {
      final response = await _safePost(
        ApiConfig.signUpEndpoint,
        data: {'name': name, 'phone': phone, 'password': password},
      );

      logger.info('Sign up successful for user: $name');
      return LoginResponseModel.fromJson(_ensureMap(response.data));
    } catch (e, stackTrace) {
      logger.error('Sign up failed', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> changePassword(
    String confirmPassword,
    String newPassword,
  ) async {
    await _safePost(
      ApiConfig.changePasswordEndpoint,
      data: {'confirmPassword': confirmPassword, 'newPassword': newPassword},
    );
  }

  @override
  Future<ForgotPasswordResponseModel> forgotPassword(String phone) async {
    debugPrint('POST ${ApiConfig.forgotPasswordEndpoint} -> phone: +52$phone');

    final response = await _safePost(
      ApiConfig.forgotPasswordEndpoint,
      data: {'phone': '+52$phone'},
    );

    debugPrint('>>> forgotPassword response: ${response.data}');

    return ForgotPasswordResponseModel.fromJson(response.data);
  }

  @override
  Future<void> resendSignUpCode({required String userId}) async {
    await _safePost(
      ApiConfig.resendSignUpCodeEndpoint,
      data: {'resetRequestId': userId},
    );
  }

  @override
  Future<LoginResponseModel> confirmSignUp({
    required String userId,
    required String code,
  }) async {
    final response = await _safePost(
      ApiConfig.confirmSignUpEndpoint,
      data: {'resetRequestId': userId, 'otp': code},
    );

    return LoginResponseModel.fromJson(_ensureMap(response.data));
  }

  @override
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? image,
  }) async {
    debugPrint('PUT ${ApiConfig.usersEndpoint}/$userId');

    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (image != null) data['image'] = image;

    final response = await _safePut(
      '${ApiConfig.usersEndpoint}/$userId',
      data: data,
    );

    final responseData = _ensureMap(response.data);
    if (responseData.containsKey('data')) {
      return UserModel.fromJson(responseData['data']);
    }

    return UserModel.fromJson(responseData);
  }

  /// --- Helpers ---

  Future<Response> _safePost(
    String path, {
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.post(
        path,
        data: data,
        cancelToken: cancelToken,
        options: Options(validateStatus: (s) => s != null && s < 500),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response;
      }

      final message = _extractMessageFromResponse(response);
      throw ApiException(message, statusCode: response.statusCode);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow; // nunca llega aquí, pero por typing
    }
  }

  Future<Response> _safePut(
    String path, {
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.put(
        path,
        data: data,
        cancelToken: cancelToken,
        options: Options(validateStatus: (s) => s != null && s < 500),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response;
      }

      final message = _extractMessageFromResponse(response);
      throw ApiException(message, statusCode: response.statusCode);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  void _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw ApiException('Tiempo de espera agotado. Verifica tu conexión.');
    }

    if (e.type == DioExceptionType.cancel) {
      throw ApiException('Solicitud cancelada por el usuario.');
    }

    if (e.response != null) {
      final message = _extractMessageFromResponse(e.response!);
      throw ApiException(message, statusCode: e.response?.statusCode);
    }

    throw ApiException(e.message ?? 'Error de red desconocido');
  }

  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw ApiException('Formato de respuesta inesperado');
  }
}

/// --- Error extractor ---
String _extractMessageFromResponse(Response response) {
  try {
    final d = response.data;
    if (d == null) return 'Respuesta vacía del servidor';

    if (d is Map<String, dynamic>) {
      if (d.containsKey('message')) {
        return d['message']?.toString() ?? 'Error desconocido';
      }
      if (d.containsKey('error')) {
        return d['error']?.toString() ?? 'Error desconocido';
      }
      if (d.containsKey('detail')) {
        return d['detail']?.toString() ?? 'Error desconocido';
      }

      if (d.containsKey('errors') && d['errors'] is Iterable) {
        final errors = List.from(d['errors'] as Iterable);
        final msgs =
            errors
                .map((e) {
                  if (e is Map && (e['msg'] != null || e['message'] != null)) {
                    return (e['msg'] ?? e['message']).toString();
                  }
                  return e.toString();
                })
                .where((s) => s.isNotEmpty)
                .toList();

        if (msgs.isNotEmpty) {
          return msgs.length == 1 ? msgs.first : msgs.take(3).join(' • ');
        }
      }

      return d.keys.take(3).map((k) => '$k:${d[k]}').join(', ');
    }

    return d.toString();
  } catch (_) {
    return 'Error al parsear el mensaje de error';
  }
}
