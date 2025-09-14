import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasource/auth_local_datasource.dart';
import '../datasource/auth_token_local_datasource.dart';
import '../datasource/auth_user_local_datasource.dart';
import '../models/login_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthTokenLocalDataSource tokenLocalDataSource;
  final AuthUserLocalDataSource userLocalDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.tokenLocalDataSource,
    required this.userLocalDataSource,
  });

  @override
  Future<Either<Failure, User>> signIn(String email, String password) async {
    try {
      final response = await localDataSource.signIn(email, password);

      await tokenLocalDataSource.cacheTokens(
        accessToken: response.jwt ?? '',
        refreshToken: response.jwt ?? '',
      );

      await userLocalDataSource.saveUser(response.data!);

      return Right(response.data!);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String phone,
    required String password,
    String? firstName,
    String? firstSurname,
    String? secondSurname,
    required String confirmPassword,
  }) async {
    try {
      final response = await localDataSource.signUp(
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
        firstName: firstName,
        firstSurname: firstSurname,
        secondSurname: secondSurname,
      );

      // await tokenLocalDataSource.cacheTokens(
      //   accessToken: response.jwt ?? '',
      //   refreshToken: response.jwt ?? '',
      // );

      // await userLocalDataSource.saveUser(response.user!);

      return Right(response.data!);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      await localDataSource.changePassword(oldPassword, newPassword);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await localDataSource.forgotPassword(email);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<bool> hasTokenStored() async {
    return await tokenLocalDataSource.hasTokenStored();
  }

  @override
  Future<Either<Failure, User>> getUserFromCache() async {
    try {
      final userModel = await userLocalDataSource.getUser();
      if (userModel == null) throw CacheException('No user found');

      // Convertir UserModel -> User
      final user = User(
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

      return Right(user);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  // implementar logout
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await tokenLocalDataSource.clearSession();
      await userLocalDataSource.clearUser();
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, LoginResponseModel>> confirmSignUp({
    required String userId,
    required String code,
  }) async {
    debugPrint('>>> confirmSignUp: userId=$userId, code=$code');
    try {
      final response = await localDataSource.confirmSignUp(
        userId: userId,
        code: code,
      );

      await tokenLocalDataSource.cacheTokens(
        accessToken: response.jwt ?? '',
        refreshToken: response.jwt ?? '',
      );

      await userLocalDataSource.saveUser(response.data!);

      return Right(response);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> resendSignUpCode({
    required String userId,
  }) async {
    try {
      await localDataSource.resendSignUpCode(userId: userId);
      return const Right(null);
    } on CacheException catch (e, stackTrace) {
      return Left(CacheFailure(e.message, stackTrace));
    }
  }
}
