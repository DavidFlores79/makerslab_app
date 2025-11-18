// ABOUTME: This file contains the GetLegalDocument use case
// ABOUTME: It fetches legal documents (terms/privacy policy) with language support

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/legal_document.dart';
import '../repositories/legal_repository.dart';

class GetLegalDocument {
  final LegalRepository legalRepository;

  GetLegalDocument({required this.legalRepository});

  Future<Either<Failure, LegalDocument>> call({
    required String type,
    required String language,
  }) async {
    return await legalRepository.getLegalDocument(
      type: type,
      language: language,
    );
  }
}
