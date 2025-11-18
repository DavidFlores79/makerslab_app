// ABOUTME: This file contains the LegalRepository interface
// ABOUTME: It defines the contract for fetching legal documents from remote sources

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/legal_document.dart';

abstract class LegalRepository {
  Future<Either<Failure, LegalDocument>> getLegalDocument({
    required String type,
    required String language,
  });
}
