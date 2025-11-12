// ABOUTME: This file contains the CatalogsRepositoryImpl
// ABOUTME: It implements the CatalogsRepository interface and handles catalog data operations

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/domain/repositories/base_repository.dart';
import '../../domain/repositories/catalogs_repository.dart';
import '../datasources/catalogs_remote_datasource.dart';
import '../models/country_model.dart';

class CatalogsRepositoryImpl extends BaseRepository
    implements CatalogsRepository {
  final CatalogsRemoteDataSource remoteDataSource;

  CatalogsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CountryModel>>> getCountries({
    int? limit,
    int? offset,
    String? search,
  }) {
    return safeCall<List<CountryModel>>(() async {
      return await remoteDataSource.getCountries(
        limit: limit,
        offset: offset,
        search: search,
      );
    });
  }
}
