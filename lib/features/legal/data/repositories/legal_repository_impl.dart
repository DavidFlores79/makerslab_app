// ABOUTME: This file contains the LegalRepositoryImpl
// ABOUTME: It implements LegalRepository using remote datasource and error handling

import 'package:dartz/dartz.dart';

import '../../../../core/domain/repositories/base_repository.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/legal_document.dart';
import '../../domain/repositories/legal_repository.dart';
import '../datasources/legal_remote_datasource.dart';

class LegalRepositoryImpl extends BaseRepository implements LegalRepository {
  final LegalRemoteDataSource remoteDataSource;

  LegalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, LegalDocument>> getLegalDocument({
    required String type,
    required String language,
  }) {
    return safeCall<LegalDocument>(() async {
      return await remoteDataSource.getLegalDocument(
        type: type,
        language: language,
      );
    });
  }
}
