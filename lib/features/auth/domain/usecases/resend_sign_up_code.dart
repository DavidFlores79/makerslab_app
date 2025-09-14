import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class ResendSignUpCode {
  final AuthRepository repository;
  ResendSignUpCode({required this.repository});

  Future<Either<Failure, void>> call({required String userId}) {
    return repository.resendSignUpCode(userId: userId);
  }
}
