import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/entities/user.dart';
import '../../data/models/login_response_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String email, String password);
  Future<Either<Failure, User>> signInWithPhone(String phone, String password);
  Future<Either<Failure, User>> signUp({
    required String phone,
    required String password,
    String? firstName,
    String? firstSurname,
    String? secondSurname,
    required String confirmPassword,
  });
  Future<Either<Failure, void>> resendSignUpCode({required String userId});
  Future<Either<Failure, LoginResponseModel>> confirmSignUp({
    required String userId,
    required String code,
  });
  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  );
  Future<Either<Failure, void>> forgotPassword(String email);
  Future<bool> hasTokenStored();
  Future<Either<Failure, User>> getUserFromCache();
  Future<Either<Failure, void>> logout();
}
