import 'package:dartz/dartz.dart';

import '../../../../core/entities/user.dart';
import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class SigninWithPhone {
  final AuthRepository repository;

  SigninWithPhone({required this.repository});

  Future<Either<Failure, User>> call(String phone, String password) {
    return repository.signInWithPhone(phone, password);
  }
}
