// ABOUTME: This file contains the ResendRegistrationCode use case for OTP resending
// ABOUTME: It requests a new OTP code to be sent to the user's phone number

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class ResendRegistrationCode {
  final AuthRepository repository;

  ResendRegistrationCode({required this.repository});

  Future<Either<Failure, void>> call({required String registrationId}) {
    return repository.resendRegistrationCode(registrationId: registrationId);
  }
}
