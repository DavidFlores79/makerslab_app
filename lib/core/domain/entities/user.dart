import 'profile.dart';

class User {
  String? id;
  String? name;
  String? phone;
  String? email;
  String? image;
  Profile? profile;
  bool? status;
  bool? deleted;
  bool? google;
  String? createdAt;
  String? updatedAt;
  String? phoneVerificationCode;
  String? phoneVerificationCodeExpiresAt;
  String? imagePublicId;

  User({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.image,
    this.profile,
    this.status,
    this.deleted,
    this.google,
    this.createdAt,
    this.updatedAt,
    this.phoneVerificationCode,
    this.phoneVerificationCodeExpiresAt,
    this.imagePublicId,
  });
}
