import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/forgot_password_response_model.dart';
import '../repositories/auth_repository.dart';

class ForgotPassword {
  final AuthRepository repository;

  ForgotPassword({required this.repository});

  Future<Either<Failure, ForgotPasswordResponseModel>> call(String email) {
    return repository.forgotPassword(email);
  }
}
