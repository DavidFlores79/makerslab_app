abstract class OtpEvent {}

class OtpStartTimer extends OtpEvent {
  final int seconds;
  OtpStartTimer({this.seconds = 300}); // 5 minutes default
}

class OtpTick extends OtpEvent {
  final int secondsLeft;
  OtpTick(this.secondsLeft);
}

class OtpResendPressed extends OtpEvent {
  final String id;
  OtpResendPressed({required this.id});
}

class OtpCodeChanged extends OtpEvent {
  final String code;
  OtpCodeChanged(this.code);
}

class OtpConfirmPressed extends OtpEvent {
  final String id;
  final String code;
  OtpConfirmPressed({required this.id, required this.code});
}

// New events for registration flow
class OtpVerifyRegistration extends OtpEvent {
  final String registrationId;
  final String otp;
  OtpVerifyRegistration({required this.registrationId, required this.otp});
}

class OtpResendRegistrationCode extends OtpEvent {
  final String registrationId;
  OtpResendRegistrationCode({required this.registrationId});
}
