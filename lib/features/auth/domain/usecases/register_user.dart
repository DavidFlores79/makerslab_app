import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;

  RegisterUser({required this.repository});

  Future<Either<Failure, User>> call({
    required String phone,
    required String password,
    String? firstName,
    String? firstSurname,
    String? secondSurname,
    required String confirmPassword,
  }) {
    return repository.signUp(
      phone: phone,
      password: password,
      firstName: firstName,
      firstSurname: firstSurname,
      secondSurname: secondSurname,
      confirmPassword: confirmPassword,
    );
  }
}
