import '../../data/models/user_model.dart';

abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

class SigninWithPhoneRequested extends AuthEvent {
  final String phone;
  final String password;
  SigninWithPhoneRequested(this.phone, this.password);
}

class LogoutRequested extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String phone;
  final String password;
  final String confirmPassword;
  final String firstName;
  final String firstSurname;
  final String? secondSurname;
  RegisterRequested({
    required this.phone,
    required this.password,
    required this.firstName,
    required this.firstSurname,
    this.secondSurname,
    required this.confirmPassword,
  });
}

class ChangePasswordRequested extends AuthEvent {
  final String confirmPassword;
  final String newPassword;
  ChangePasswordRequested(this.confirmPassword, this.newPassword);
}

class ForgotPasswordRequested extends AuthEvent {
  final String phone;
  ForgotPasswordRequested(this.phone);
}

class CheckAuthStatus extends AuthEvent {}

class RegistrationConfirmed extends AuthEvent {
  final UserModel user;
  final String token;
  RegistrationConfirmed({required this.user, required this.token});
}

class AuthUserChanged extends AuthEvent {
  final UserModel? user;
  AuthUserChanged(this.user);
}
