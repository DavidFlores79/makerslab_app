import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/mocks/mock_data.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<LoginResponseModel> signIn(String phone, String password);
  Future<LoginResponseModel> signUp({
    required String phone,
    required String password,
    required String confirmPassword,
    String? firstName,
    String? firstSurname,
    String? secondSurname,
  });
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<void> forgotPassword(String phone);
  Future<void> resendSignUpCode({required String userId});
  Future<LoginResponseModel> confirmSignUp({
    required String userId,
    required String code,
  });
  Future<List<UserModel>> getUsers();
}

class AuthLocalDataSourceMockImpl implements AuthLocalDataSource {
  final ISecureStorageService secureStorage;
  final Logger logger;

  AuthLocalDataSourceMockImpl({
    required this.secureStorage,
    required this.logger,
  });

  String? _jwt;
  String otpCode = '123456';

  @override
  Future<LoginResponseModel> signIn(String phone, String password) async {
    try {
      // Mock data
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Haciendo Login localmente...");

      debugPrint('$phone ------- $password');

      final user = users.firstWhere(
        (u) => u['phone'] == '52$phone' && u['password'] == password,
        orElse: () => throw Exception('Invalid credentials'),
      );
      _jwt = 'token_${Random().nextInt(999999)}';

      return LoginResponseModel.fromJson({'jwt': _jwt, 'user': user});
    } catch (e, stackTrace) {
      logger.e(
        'Error haciendo Login localmente...',
        error: e,
        stackTrace: stackTrace,
      );
      throw CacheException(
        'Usuario o contraseña no válidos. Por favor ingresar la información correctamente...',
        stackTrace,
      );
    }
  }

  @override
  Future<LoginResponseModel> signUp({
    required String phone,
    required String password,
    required String confirmPassword,
    String? firstName,
    String? firstSurname,
    String? secondSurname,
  }) async {
    try {
      // Mock data
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Haciendo Registro localmente...");
      if (users.any((u) => u['phone'] == phone)) {
        throw Exception('Phone already exists');
      }
      final id = Random().nextInt(99999).toString();

      final user =
          UserModel.fromJson({
            "id": id,
            "firstName": firstName ?? '',
            "secondName": '',
            "firstSurname": firstSurname ?? '',
            "secondSurname": secondSurname ?? '',
            "email": '',
            "phone": '52$phone',
            "password": password,
            "status": "pending",
            "verified": false,
            "isProfileCompleted": false,
            "createdAt": DateTime.now().toIso8601String(),
            "updatedAt": DateTime.now().toIso8601String(),
          }).toJson();
      users.add(user);

      //add balance with this userId
      final balanceId = Uuid().v4();
      final newClabe = 'clabe_${Random().nextInt(999999)}';
      balances.add({
        "id": balanceId,
        "userId": id,
        "currentBalance": "0.00",
        "currency": "MXN",
        "lastUpdatedAt": DateTime.now().toIso8601String(),
        "createdAt": DateTime.now().toIso8601String(),
        "updatedAt": DateTime.now().toIso8601String(),
      });
      // Map CLABE to Balance ID
      clabeToBalanceIdMock[newClabe] = balanceId;

      _jwt = 'token_${Random().nextInt(999999)}';
      return LoginResponseModel.fromJson({'jwt': _jwt, 'user': user});
    } catch (e, stackTrace) {
      logger.e(
        'Error haciendo Registro localmente...',
        error: e,
        stackTrace: stackTrace,
      );
      throw CacheException(
        e.toString().replaceFirst('Exception: ', ''),
        stackTrace,
      );
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      // Mock data
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Cambiando contraseña localmente...");

      final index = users.indexWhere((u) => u['password'] == oldPassword);
      if (index == -1) throw Exception('Old password is incorrect');
      users[index]['password'] = newPassword;
    } catch (e, stackTrace) {
      logger.e(
        'Error haciendo Cambio de contraseña localmente...',
        error: e,
        stackTrace: stackTrace,
      );
      throw CacheException(
        'Error al hacer Cambio de contraseña localmente...',
        stackTrace,
      );
    }
  }

  @override
  Future<void> forgotPassword(String phone) async {
    try {
      // Mock data
      await Future.delayed(const Duration(milliseconds: 500));
      logger.i("Recuperando contraseña localmente...");

      if (!users.any((u) => u['phone'] == '52$phone')) {
        throw Exception('Phone not found');
      }
    } catch (e, stackTrace) {
      logger.e(
        'Error haciendo Recuperación de contraseña localmente...',
        error: e,
        stackTrace: stackTrace,
      );
      throw CacheException(
        'Error al hacer Recuperación de contraseña localmente...',
        stackTrace,
      );
    }
  }

  @override
  Future<LoginResponseModel> confirmSignUp({
    required String userId,
    required String code,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    if (code != otpCode) {
      throw CacheException('Invalid OTP code');
    }

    _jwt = 'token_${Random().nextInt(999999)}';
    final user = users.last;
    logger.i("Confirmando registro localmente...");

    return LoginResponseModel.fromJson({"jwt": _jwt, "user": user});
  }

  @override
  Future<void> resendSignUpCode({required String userId}) async {
    await Future.delayed(Duration(milliseconds: 500));
    logger.i("Reenviando código de registro localmente...");
    unawaited(
      Future.delayed(Duration(milliseconds: 500), () {
        otpCode = '111111';
        // aquí podrías loggear o hacer la llamada real cuando integres la API
        return;
      }),
    );
  }

  //return users
  @override
  Future<List<UserModel>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return users.map((u) => UserModel.fromJson(u)).toList();
  }
}
