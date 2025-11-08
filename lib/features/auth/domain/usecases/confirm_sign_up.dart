import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/login_response_model.dart';
import '../repositories/auth_repository.dart';

class ConfirmSignUp {
  final AuthRepository repository;
  ConfirmSignUp({required this.repository});

  Future<Either<Failure, LoginResponseModel>> call({
    required String userId,
    required String code,
  }) {
    return repository.confirmSignUp(userId: userId, code: code);
  }
}
