// ABOUTME: This file contains the LegalDocumentModel
// ABOUTME: It extends LegalDocument entity and adds JSON serialization

import 'dart:convert';

import '../../domain/entities/legal_document.dart';

class LegalDocumentModel extends LegalDocument {
  LegalDocumentModel({
    super.id,
    super.type,
    super.language,
    super.title,
    super.content,
    super.version,
    super.effectiveDate,
    super.createdAt,
    super.updatedAt,
  });

  factory LegalDocumentModel.fromRawJson(String str) =>
      LegalDocumentModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory LegalDocumentModel.fromJson(
    Map<String, dynamic> json,
  ) => LegalDocumentModel(
    id: json["id"] ?? json["_id"],
    type: json["type"],
    language: json["language"],
    title: json["title"],
    content: json["content"],
    version: json["version"],
    effectiveDate:
        json["effectiveDate"] != null
            ? DateTime.parse(json["effectiveDate"])
            : null,
    createdAt:
        json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
    updatedAt:
        json["updatedAt"] != null ? DateTime.parse(json["updatedAt"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type,
    "language": language,
    "title": title,
    "content": content,
    "version": version,
    "effectiveDate": effectiveDate?.toIso8601String(),
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
