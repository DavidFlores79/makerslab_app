import '../../../../core/entities/user.dart';

class LoginResponse {
  User? user;
  String? jwt;

  LoginResponse({this.user, this.jwt});
}
