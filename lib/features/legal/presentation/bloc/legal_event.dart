// ABOUTME: This file contains the LegalEvent classes
// ABOUTME: It defines events for legal document operations

abstract class LegalEvent {}

class LoadLegalDocument extends LegalEvent {
  final String type;
  final String language;

  LoadLegalDocument({required this.type, required this.language});
}
