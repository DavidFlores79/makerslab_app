// ABOUTME: This file contains the SignupResponse entity for the domain layer
// ABOUTME: It represents the signup response with registrationId for OTP verification

class SignupResponse {
  String? message;
  String? registrationId;

  SignupResponse({
    this.message,
    this.registrationId,
  });
}
