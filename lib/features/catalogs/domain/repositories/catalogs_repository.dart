// ABOUTME: This file contains the CatalogsRepository interface
// ABOUTME: It defines methods for fetching catalog data like countries

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/country_model.dart';

abstract class CatalogsRepository {
  Future<Either<Failure, List<CountryModel>>> getCountries({
    int? limit,
    int? offset,
    String? search,
  });
}
