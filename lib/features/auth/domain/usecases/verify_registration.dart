// ABOUTME: This file contains the VerifyRegistration use case for OTP verification
// ABOUTME: It verifies the OTP code and completes user registration, returning user data and JWT

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class VerifyRegistration {
  final AuthRepository repository;

  VerifyRegistration({required this.repository});

  Future<Either<Failure, User>> call({
    required String registrationId,
    required String otp,
  }) {
    return repository.verifyRegistration(
      registrationId: registrationId,
      otp: otp,
    );
  }
}
