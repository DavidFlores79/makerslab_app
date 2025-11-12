// ABOUTME: This file contains the CountryModel
// ABOUTME: It extends Country entity and adds JSON serialization

import '../../domain/entities/country.dart';

class CountryModel extends Country {
  CountryModel({
    super.uid,
    super.name,
    super.code,
    super.phoneCode,
    super.status,
    super.createdAt,
    super.updatedAt,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
    uid: json["uid"],
    name: json["name"],
    code: json["code"],
    phoneCode: json["phoneCode"],
    status: json["status"],
    createdAt:
        json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
    updatedAt:
        json["updatedAt"] != null ? DateTime.parse(json["updatedAt"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "name": name,
    "code": code,
    "phoneCode": phoneCode,
    "status": status,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
