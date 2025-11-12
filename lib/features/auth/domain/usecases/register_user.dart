import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/domain/entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser {
  final AuthRepository repository;

  RegisterUser({required this.repository});

  Future<Either<Failure, User>> call({
    required String name,
    required String phone,
    required String password,
  }) {
    return repository.signUp(name: name, phone: phone, password: password);
  }
}
