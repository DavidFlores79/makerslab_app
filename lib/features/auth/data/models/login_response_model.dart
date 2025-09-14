// To parse this JSON data, do
//
//     final loginResponseModel = loginResponseModelFromJson(jsonString);

import 'dart:convert';
import 'user_model.dart';

LoginResponseModel loginResponseModelFromJson(String str) =>
    LoginResponseModel.fromJson(json.decode(str));

String loginResponseModelToJson(LoginResponseModel data) =>
    json.encode(data.toJson());

class LoginResponseModel {
  String? message;
  UserModel? data;
  String? jwt;

  LoginResponseModel({this.message, this.data, this.jwt});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        message: json["message"],
        data: json["data"] == null ? null : UserModel.fromJson(json["data"]),
        jwt: json["jwt"],
      );

  Map<String, dynamic> toJson() => {
    "message": message,
    "data": data?.toJson(),
    "jwt": jwt,
  };
}
