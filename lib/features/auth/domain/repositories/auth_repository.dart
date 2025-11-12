import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/domain/entities/user.dart';
import '../../data/models/forgot_password_response_model.dart';
import '../../data/models/login_response_model.dart';
import '../entities/signup_response.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String email, String password);
  Future<Either<Failure, User>> signInWithPhone(String phone, String password);
  Future<Either<Failure, SignupResponse>> signUp({
    required String name,
    required String phone,
    required String password,
  });
  Future<Either<Failure, User>> verifyRegistration({
    required String registrationId,
    required String otp,
  });
  Future<Either<Failure, void>> resendRegistrationCode({
    required String registrationId,
  });
  
  // Legacy methods (kept for backward compatibility)
  Future<Either<Failure, void>> resendSignUpCode({required String userId});
  Future<Either<Failure, LoginResponseModel>> confirmSignUp({
    required String userId,
    required String code,
  });
  
  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  );
  Future<Either<Failure, ForgotPasswordResponseModel>> forgotPassword(
    String phone,
  );
  Future<bool> hasTokenStored();
  Future<Either<Failure, User>> getUserFromCache();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User>> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? image,
  });
}
