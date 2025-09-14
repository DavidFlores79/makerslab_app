import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class ForgotPassword {
  final AuthRepository repository;

  ForgotPassword({required this.repository});

  Future<Either<Failure, void>> call(String email) {
    return repository.forgotPassword(email);
  }
}
