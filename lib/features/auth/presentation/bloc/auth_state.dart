import '../../../../core/domain/entities/user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class RegistrationPending extends AuthState {
  final String registrationId;
  final String phone;
  final String message;
  RegistrationPending({
    required this.registrationId,
    required this.phone,
    this.message = '',
  });
  
  // Legacy support - userId can be used as registrationId
  String get userId => registrationId;
}

class Authenticated extends AuthState {
  final User user;
  final DateTime loggedAt;
  Authenticated({required this.user}) : loggedAt = DateTime.now();
}

class AuthSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class Unauthenticated extends AuthState {}

class SessionClosed extends AuthState {}

class AuthSessionValid extends AuthState {}

//forgot password
class ForgotPasswordInProgress extends AuthState {}

class ForgotPasswordSuccess extends AuthState {
  final String message;
  final String userId;
  ForgotPasswordSuccess({required this.message, required this.userId});
}

class ForgotPasswordFailure extends AuthState {
  final String message;
  ForgotPasswordFailure(this.message);
}

class SignInWithPhoneInProgress extends AuthState {}

class SignInWithPhoneSuccess extends AuthState {
  final String message;
  SignInWithPhoneSuccess({required this.message});
}

class SignInWithPhoneFailure extends AuthState {
  final String message;
  SignInWithPhoneFailure(this.message);
}
