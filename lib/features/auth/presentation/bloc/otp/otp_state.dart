import '../../../data/models/user_model.dart';

abstract class OtpState {}

class OtpInitial extends OtpState {
  final int secondsLeft;
  final String code;
  final bool canResend;
  OtpInitial({
    required this.secondsLeft,
    this.code = '',
    this.canResend = false,
  });
}

class OtpLoading extends OtpState {}

class OtpResendSent extends OtpState {}

class OtpConfirmSuccess extends OtpState {
  final String token;
  final UserModel user;
  OtpConfirmSuccess({required this.token, required this.user});
}

class OtpFailure extends OtpState {
  final String message;
  OtpFailure(this.message);
}
