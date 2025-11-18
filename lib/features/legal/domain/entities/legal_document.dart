// ABOUTME: This file contains the LegalDocument entity
// ABOUTME: It represents a legal document (terms/privacy policy) in the domain layer

class LegalDocument {
  String? id;
  String? type;
  String? language;
  String? title;
  String? content;
  String? version;
  DateTime? effectiveDate;
  DateTime? createdAt;
  DateTime? updatedAt;

  LegalDocument({
    this.id,
    this.type,
    this.language,
    this.title,
    this.content,
    this.version,
    this.effectiveDate,
    this.createdAt,
    this.updatedAt,
  });
}
