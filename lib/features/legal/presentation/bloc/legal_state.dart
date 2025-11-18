// ABOUTME: This file contains the LegalState classes
// ABOUTME: It defines states for legal document loading and display

import '../../domain/entities/legal_document.dart';

abstract class LegalState {}

class LegalInitial extends LegalState {}

class LegalLoading extends LegalState {}

class LegalLoaded extends LegalState {
  final LegalDocument document;

  LegalLoaded({required this.document});
}

class LegalFailure extends LegalState {
  final String error;

  LegalFailure({required this.error});
}
