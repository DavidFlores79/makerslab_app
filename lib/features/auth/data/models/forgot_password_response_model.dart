import 'dart:convert';

ForgotPasswordResponseModel forgotPasswordResponseFromJson(String str) =>
    ForgotPasswordResponseModel.fromJson(json.decode(str));

String forgotPasswordResponseToJson(ForgotPasswordResponseModel data) =>
    json.encode(data.toJson());

class ForgotPasswordResponseModel {
  String? resetRequestId;
  String? message;

  ForgotPasswordResponseModel({this.resetRequestId, this.message});

  factory ForgotPasswordResponseModel.fromJson(Map<String, dynamic> json) =>
      ForgotPasswordResponseModel(
        resetRequestId: json["resetRequestId"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
    "resetRequestId": resetRequestId,
    "message": message,
  };
}
