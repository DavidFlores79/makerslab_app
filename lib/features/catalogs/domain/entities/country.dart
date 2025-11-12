// ABOUTME: This file contains the Country entity
// ABOUTME: It represents a country with phone code for international calls

class Country {
  String? uid;
  String? name;
  String? code;
  String? phoneCode;
  bool? status;
  DateTime? createdAt;
  DateTime? updatedAt;

  Country({
    this.uid,
    this.name,
    this.code,
    this.phoneCode,
    this.status,
    this.createdAt,
    this.updatedAt,
  });
}
