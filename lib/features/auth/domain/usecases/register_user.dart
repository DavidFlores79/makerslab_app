// ABOUTME: This file contains the RegisterUser use case for the new OTP registration flow
// ABOUTME: It initiates user registration and returns a registrationId for OTP verification

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/signup_response.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;

  RegisterUser({required this.repository});

  Future<Either<Failure, SignupResponse>> call({
    required String name,
    required String phone,
    required String password,
  }) {
    return repository.signUp(name: name, phone: phone, password: password);
  }
}
