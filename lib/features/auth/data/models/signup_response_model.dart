// ABOUTME: This file contains the SignupResponse model for the new OTP registration flow
// ABOUTME: It represents the response from the signup endpoint containing registrationId for OTP verification

class SignupResponseModel {
  final String message;
  final String registrationId;

  SignupResponseModel({required this.message, required this.registrationId});

  factory SignupResponseModel.fromJson(Map<String, dynamic> json) {
    return SignupResponseModel(
      message: json['message'] as String,
      registrationId: json['registrationId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'registrationId': registrationId,
  };
}
