import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUser {
  final AuthRepository repository;

  LoginUser({required this.repository});

  Future<Either<Failure, User>> call(String email, String password) {
    return repository.signIn(email, password);
  }
}
