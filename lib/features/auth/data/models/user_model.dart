import '../../../../core/entities/user.dart';
import 'profile_model.dart';

class UserModel extends User {
  @override
  final ProfileModel? profile;

  UserModel({
    super.id,
    super.name,
    super.phone,
    super.email,
    super.image,
    this.profile,
    super.status,
    super.deleted,
    super.google,
    super.createdAt,
    super.updatedAt,
    super.phoneVerificationCode,
    super.phoneVerificationCodeExpiresAt,
    super.imagePublicId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json["_id"],
    name: json["name"],
    phone: json["phone"],
    email: json["email"],
    image: json["image"],
    profile:
        json["profile"] == null ? null : ProfileModel.fromJson(json["profile"]),
    status: json["status"],
    deleted: json["deleted"],
    google: json["google"],
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
    phoneVerificationCode: json["phoneVerificationCode"],
    phoneVerificationCodeExpiresAt: json["phoneVerificationCodeExpiresAt"],
    imagePublicId: json["imagePublicId"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "phone": phone,
    "email": email,
    "image": image,
    "profile": profile?.toJson(),
    "status": status,
    "deleted": deleted,
    "google": google,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "phoneVerificationCode": phoneVerificationCode,
    "phoneVerificationCodeExpiresAt": phoneVerificationCodeExpiresAt,
    "imagePublicId": imagePublicId,
  };
}
