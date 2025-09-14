import '../../../../core/entities/profile.dart';

class ProfileModel extends Profile {
  ProfileModel({
    super.id,
    super.name,
    super.status,
    super.deleted,
    super.createdAt,
    super.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json["_id"],
    name: json["name"],
    status: json["status"],
    deleted: json["deleted"],
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "status": status,
    "deleted": deleted,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
  };
}
