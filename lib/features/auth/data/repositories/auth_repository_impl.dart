import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/domain/entities/user.dart';
import '../../../../core/domain/repositories/base_repository.dart';
import '../../domain/entities/signup_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_token_local_datasource.dart';
import '../datasources/auth_user_local_datasource.dart';
import '../models/forgot_password_response_model.dart';
import '../models/login_response_model.dart';

class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthTokenLocalDataSource tokenLocalDataSource;
  final AuthUserLocalDataSource userLocalDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.tokenLocalDataSource,
    required this.userLocalDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, User>> signIn(String email, String password) {
    return safeCall<User>(() async {
      final response = await remoteDataSource.signIn(email, password);

      await tokenLocalDataSource.cacheTokens(
        accessToken: response.jwt ?? '',
        refreshToken: response.jwt ?? '',
      );

      await userLocalDataSource.saveUser(response.data!);

      return response.data!;
    });
  }

  @override
  Future<Either<Failure, User>> signInWithPhone(String phone, String password) {
    return safeCall<User>(() async {
      final response = await remoteDataSource.phoneSignIn(phone, password);

      await tokenLocalDataSource.cacheTokens(
        accessToken: response.jwt ?? '',
        refreshToken: response.jwt ?? '',
      );

      await userLocalDataSource.saveUser(response.data!);

      return response.data!;
    });
  }

  @override
  Future<Either<Failure, SignupResponse>> signUp({
    required String name,
    required String phone,
    required String password,
  }) {
    return safeCall<SignupResponse>(() async {
      final response = await remoteDataSource.signUp(
        name: name,
        phone: phone,
        password: password,
      );

      // Don't cache tokens yet - user needs to verify OTP first
      // Return SignupResponse with registrationId for OTP verification
      return SignupResponse(
        message: response.message,
        registrationId: response.registrationId,
      );
    });
  }

  @override
  Future<Either<Failure, User>> verifyRegistration({
    required String registrationId,
    required String otp,
  }) {
    return safeCall<User>(() async {
      final response = await remoteDataSource.verifyRegistration(
        registrationId: registrationId,
        otp: otp,
      );

      // Cache tokens after successful OTP verification
      await tokenLocalDataSource.cacheTokens(
        accessToken: response.jwt ?? '',
        refreshToken: response.jwt ?? '',
      );

      // Cache user data
      await userLocalDataSource.saveUser(response.data!);

      return response.data!;
    });
  }

  @override
  Future<Either<Failure, void>> resendRegistrationCode({
    required String registrationId,
  }) {
    return safeCall<void>(() async {
      await remoteDataSource.resendRegistrationCode(
        registrationId: registrationId,
      );
    });
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  ) {
    return safeCall<void>(() async {
      await remoteDataSource.changePassword(oldPassword, newPassword);
    });
  }

  @override
  Future<Either<Failure, ForgotPasswordResponseModel>> forgotPassword(
    String phone,
  ) {
    return safeCall<ForgotPasswordResponseModel>(() async {
      final response = await remoteDataSource.forgotPassword(phone);
      return response;
    });
  }

  @override
  Future<bool> hasTokenStored() async {
    return await tokenLocalDataSource.hasValidTokenStored();
  }

  @override
  Future<Either<Failure, User>> getUserFromCache() {
    return safeCall<User>(() async {
      final userModel = await userLocalDataSource.getUser();
      if (userModel == null) throw CacheException('No user found');

      return User(
        id: userModel.id,
        name: userModel.name,
        phone: userModel.phone,
        email: userModel.email,
        status: userModel.status,
        image: userModel.image,
        profile: userModel.profile,
        deleted: userModel.deleted,
        google: userModel.google,
        createdAt: userModel.createdAt,
        updatedAt: userModel.updatedAt,
      );
    });
  }

  @override
  Future<Either<Failure, void>> logout() {
    return safeCall<void>(() async {
      await tokenLocalDataSource.clearSession();
      await userLocalDataSource.clearUser();
    });
  }

  @override
  Future<Either<Failure, LoginResponseModel>> confirmSignUp({
    required String userId,
    required String code,
  }) {
    debugPrint('>>> confirmSignUp: userId=$userId, code=$code');
    return safeCall<LoginResponseModel>(() async {
      final response = await remoteDataSource.confirmSignUp(
        userId: userId,
        code: code,
      );

      await tokenLocalDataSource.cacheTokens(
        accessToken: response.jwt ?? '',
        refreshToken: response.jwt ?? '',
      );

      await userLocalDataSource.saveUser(response.data!);
      return response;
    });
  }

  @override
  Future<Either<Failure, void>> resendSignUpCode({required String userId}) {
    return safeCall<void>(() async {
      await remoteDataSource.resendSignUpCode(userId: userId);
    });
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? image,
  }) {
    return safeCall<User>(() async {
      final userModel = await remoteDataSource.updateProfile(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        image: image,
      );

      // Update local cache with new user data
      await userLocalDataSource.saveUser(userModel);

      return User(
        id: userModel.id,
        name: userModel.name,
        phone: userModel.phone,
        email: userModel.email,
        status: userModel.status,
        image: userModel.image,
        profile: userModel.profile,
        deleted: userModel.deleted,
        google: userModel.google,
        createdAt: userModel.createdAt,
        updatedAt: userModel.updatedAt,
      );
    });
  }

  /// --- Helpers privados ---

  // Future<Either<Failure, T>> _safeCall<T>(Future<T> Function() action) async {
  //   try {
  //     final result = await action();
  //     return Right(result);
  //   } on CacheException catch (e, stackTrace) {
  //     return Left(CacheFailure(e.message, stackTrace));
  //   } on ApiException catch (e, stackTrace) {
  //     return Left(ServerFailure(e.message, e.statusCode, stackTrace));
  //   } on DioException catch (e, stackTrace) {
  //     final msg = _messageFromDioException(e);
  //     return Left(ServerFailure(msg, e.response?.statusCode, stackTrace));
  //   } catch (e, stackTrace) {
  //     return Left(
  //       ServerFailure(
  //         'Error inesperado. Intenta nuevamente.',
  //         null,
  //         stackTrace,
  //       ),
  //     );
  //   }
  // }

  // String _messageFromDioException(DioException e) {
  //   if (e.type == DioExceptionType.connectionTimeout ||
  //       e.type == DioExceptionType.receiveTimeout ||
  //       e.type == DioExceptionType.sendTimeout) {
  //     return 'Tiempo de espera agotado. Verifica tu conexión.';
  //   }
  //   if (e.type == DioExceptionType.cancel) {
  //     return 'Solicitud cancelada.';
  //   }
  //   if (e.response != null && e.response?.data != null) {
  //     try {
  //       final data = e.response!.data;
  //       if (data is Map &&
  //           (data['message'] != null || data['errors'] != null)) {
  //         if (data['message'] != null) return data['message'].toString();
  //         if (data['errors'] is Iterable) {
  //           final errors =
  //               List.from(data['errors'] as Iterable)
  //                   .map(
  //                     (it) =>
  //                         (it is Map ? (it['msg'] ?? it['message']) : it)
  //                             .toString(),
  //                   )
  //                   .where((s) => s.isNotEmpty)
  //                   .toList();
  //           if (errors.isNotEmpty) return errors.take(3).join(' • ');
  //         }
  //       }
  //     } catch (_) {}
  //   }
  //   return e.message ?? 'Error de red desconocido';
  // }
}
